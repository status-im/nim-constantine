# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ../config/[common, curves, type_ff],
  ../towers,
  ../elliptic/[
    ec_shortweierstrass_affine,
    ec_shortweierstrass_projective
  ],
  ../isogeny/frobenius,
  ../curves/zoo_pairings,
  ./cyclotomic_fp12,
  ./lines_common,
  ./miller_loops

# ############################################################
#
#                 Optimal ATE pairing for
#                      BLS12 curves
#
# ############################################################

# - Efficient Final Exponentiation
#   via Cyclotomic Structure for Pairings
#   over Families of Elliptic Curves
#   Daiki Hayashida and Kenichiro Hayasaka
#   and Tadanori Teruya, 2020
#   https://eprint.iacr.org/2020/875.pdf
#
# - Improving the computation of the optimal ate pairing
#   for a high security level.
#   Loubna Ghammam, Emmanuel Fouotsa
#   J. Appl. Math. Comput.59, 21–36 (2019)
#
# - Faster Pairing Computations on Curves with High-Degree Twists
#   Craig Costello, Tanja Lange, and Michael Naehrig, 2009
#   https://eprint.iacr.org/2009/615.pdf

# Generic pairing implementation
# ----------------------------------------------------------------

func millerLoopGenericBLS12*[C](
       f: var Fp12[C],
       P: ECP_ShortW_Aff[Fp[C], NotOnTwist],
       Q: ECP_ShortW_Aff[Fp2[C], OnTwist]
     ) {.meter.} =
  ## Generic Miller Loop for BLS12 curve
  ## Computes f{u,Q}(P) with u the BLS curve parameter

  var
    T {.noInit.}: ECP_ShortW_Prj[Fp2[C], OnTwist]
    line {.noInit.}: Line[Fp2[C]]
    nQ{.noInit.}: typeof(Q)

  T.projectiveFromAffine(Q)
  nQ.neg(Q)

  basicMillerLoop(
    f, T, line,
    P, Q, nQ,
    ate_param, ate_param_isNeg
  )

func finalExpGeneric[C: static Curve](f: var Fp12[C]) =
  ## A generic and slow implementation of final exponentiation
  ## for sanity checks purposes.
  f.powUnsafeExponent(C.pairing(finalexponent), window = 3)

func pairing_bls12_reference*[C](
       gt: var Fp12[C],
       P: ECP_ShortW_Aff[Fp[C], NotOnTwist],
       Q: ECP_ShortW_Aff[Fp2[C], OnTwist]) =
  ## Compute the optimal Ate Pairing for BLS12 curves
  ## Input: P ∈ G1, Q ∈ G2
  ## Output: e(P, Q) ∈ Gt
  ##
  ## Reference implementation
  gt.millerLoopGenericBLS12(P, Q)
  gt.finalExpGeneric()

# Optimized pairing implementation
# ----------------------------------------------------------------

func finalExpHard_BLS12*[C](f: var Fp12[C]) {.meter.} =
  ## Hard part of the final exponentiation
  ## Specialized for BLS12 curves
  ##
  # - Efficient Final Exponentiation
  #   via Cyclotomic Structure for Pairings
  #   over Families of Elliptic Curves
  #   Daiki Hayashida and Kenichiro Hayasaka
  #   and Tadanori Teruya, 2020
  #   https://eprint.iacr.org/2020/875.pdf
  #
  # p14: 3 Φ₁₂(p(x))/r(x) = (x−1)² (x+p) (x²+p²−1) + 3
  #
  # with
  # - Eₓ being f^x
  # - Eₓ/₂ being f^(x/2)
  # - M₁₂ being mul in Fp12
  # - S₁₂ being cyclotomic squaring
  # - Fₙ being n Frobenius applications

  var v0 {.noInit.}, v1 {.noInit.}, v2 {.noInit.}: Fp12[C]

  # Save for f³ and (x−1)²
  v2.cyclotomic_square(f)      # v2 = f²

  # (x−1)²
  when C.pairing(ate_param).isEven.bool:
    v0.pow_xdiv2(v2)           # v0 = (f²)^(x/2) = f^x
  else:
    v0.pow_x(f)
  v1.cyclotomic_inv(f)         # v1 = f^-1
  v0 *= v1                     # v0 = f^(x-1)
  v1.pow_x(v0)                 # v1 = (f^(x-1))^x
  v0.cyclotomic_inv()          # v0 = (f^(x-1))^-1
  v0 *= v1                     # v0 = (f^(x-1))^(x-1) = f^((x-1)*(x-1)) = f^((x-1)²)

  # (x+p)
  v1.pow_x(v0)                 # v1 = f^((x-1)².x)
  v0.frobenius_map(v0)         # v0 = f^((x-1)².p)
  v0 *= v1                     # v0 = f^((x-1)².(x+p))

  # + 3
  f *= v2                      # f = f³

  # (x²+p²−1)
  v2.pow_x(v0, invert = false)
  v1.pow_x(v2, invert = false) # v1 = f^((x-1)².(x+p).x²)
  v2.frobenius_map(v0, 2)      # v2 = f^((x-1)².(x+p).p²)
  v0.cyclotomic_inv()          # v0 = f^((x-1)².(x+p).-1)
  v0 *= v1                     # v0 = f^((x-1)².(x+p).(x²-1))
  v0 *= v2                     # v0 = f^((x-1)².(x+p).(x²+p²-1))

  # (x−1)².(x+p).(x²+p²−1) + 3
  f *= v0

func pairing_bls12*[C](
       gt: var Fp12[C],
       P: ECP_ShortW_Aff[Fp[C], NotOnTwist],
       Q: ECP_ShortW_Aff[Fp2[C], OnTwist]) {.meter.} =
  ## Compute the optimal Ate Pairing for BLS12 curves
  ## Input: P ∈ G1, Q ∈ G2
  ## Output: e(P, Q) ∈ Gt
  gt.millerLoopGenericBLS12(P, Q)
  gt.finalExpEasy()
  gt.finalExpHard_BLS12()
