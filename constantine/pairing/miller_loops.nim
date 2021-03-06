# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ../elliptic/[
    ec_shortweierstrass_affine,
    ec_shortweierstrass_projective
  ],
  ../isogeny/frobenius,
  ./lines_projective,
  ./mul_fp6_by_lines, ./mul_fp12_by_lines

# ############################################################
#                                                            #
#                 Basic Miller Loop                          #
#                                                            #
# ############################################################

template basicMillerLoop*[FT, F1, F2](
       f: var FT,
       T: var ECP_ShortW_Prj[F2, OnTwist],
       line: var Line[F2],
       P: ECP_ShortW_Aff[F1, NotOnTwist],
       Q, nQ: ECP_ShortW_Aff[F2, OnTwist],
       ate_param: untyped,
       ate_param_isNeg: untyped
    ) =
  ## Basic Miller loop iterations
  mixin pairing # symbol from zoo_pairings

  static:
    doAssert FT.C == F1.C
    doAssert FT.C == F2.C

  f.setOne()

  template u: untyped = pairing(C, ate_param)
  var u3 = pairing(C, ate_param)
  u3 *= 3
  for i in countdown(u3.bits - 2, 1):
    square(f)
    line_double(line, T, P)
    mul(f, line)

    let naf = bit(u3, i).int8 - bit(u, i).int8 # This can throw exception
    if naf == 1:
      line_add(line, T, Q, P)
      mul(f, line)
    elif naf == -1:
      line_add(line, T, nQ, P)
      mul(f, line)

  when pairing(C, ate_param_isNeg):
    # In GT, x^-1 == conjugate(x)
    # Remark 7.1, chapter 7.1.1 of Guide to Pairing-Based Cryptography, El Mrabet, 2017
    conj(f)

func millerCorrectionBN*[FT, F1, F2](
       f: var FT,
       T: var ECP_ShortW_Prj[F2, OnTwist],
       Q: ECP_ShortW_Aff[F2, OnTwist],
       P: ECP_ShortW_Aff[F1, NotOnTwist],
       ate_param_isNeg: static bool
     ) =
  ## Ate pairing for BN curves need adjustment after basic Miller loop
  static:
    doAssert FT.C == F1.C
    doAssert FT.C == F2.C

  when ate_param_isNeg:
    T.neg()
  var V {.noInit.}: typeof(Q)
  var line {.noInit.}: Line[F2]

  V.frobenius_psi(Q)
  line.line_add(T, V, P)
  f.mul(line)

  V.frobenius_psi(Q, 2)
  V.neg()
  line.line_add(T, V, P)
  f.mul(line)

# ############################################################
#                                                            #
#                 Optimized Miller Loops                     #
#                                                            #
# ############################################################
#
# - Software Implementation, Algorithm 11.2 & 11.3
#   Aranha, Dominguez Perez, A. Mrabet, Schwabe,
#   Guide to Pairing-Based Cryptography, 2015
#
# - Physical Attacks,
#   N. El Mrabet, Goubin, Guilley, Fournier, Jauvart, Moreau, Rauzy, Rondepierre,
#   Guide to Pairing-Based Cryptography, 2015
#
# - Pairing Implementation Revisited
#   Mike Scott, 2019
#   https://eprint.iacr.org/2019/077.pdf
#
# Fault attacks:
# To limit exposure to some fault attacks (flipping bits with a laser on embedded):
# - changing the number of Miller loop iterations
# - flipping the bits in the Miller loop
# we hardcode unrolled addition chains.
# This should also contribute to performance.
#
# Multi-pairing discussion:
# Aranha & Scott proposes 2 different approaches for multi-pairing.
#
# -----
# Scott
#
# Algorithm 2: Calculate and store line functions for BLS12 curve
# Input: Q ∈ G2, P ∈ G1 , curve parameter u
# Output: An array g of blog2(u)c line functions ∈ Fp12
#   1 T ← Q
#   2 for i ← ceil(log2(u)) − 1 to 0 do
#   3   g[i] ← lT,T(P), T ← 2T
#   4   if ui = 1 then
#   5     g[i] ← g[i].lT,Q(P), T ← T + Q
#   6 return g
#
# And to accumulate lines from a new (P, Q) tuple of points
#
# Algorithm 4: Accumulate another set of line functions into g
# Input: The array g, Qj ∈ G2 , Pj ∈ G1 , curve parameter u
# Output: Updated array g of ceil(log2(u)) line functions ∈ Fp12
#   1 T ← Qj
#   2 for i ← blog2 (u)c − 1 to 0 do
#   3   t ← lT,T (Pj), T ← 2T
#   4   if ui = 1 then
#   5     t ← t.lT,Qj (Pj), T ← T + Qj
#   6   g[i] ← g[i].t
#   7 return g
#
# ------
# Aranha
#
# Algorithm 11.2 Explicit multipairing version of Algorithm 11.1.
# (we extract the Miller Loop part only)
# Input : P1 , P2 , . . . Pn ∈ G1 ,
#         Q1 , Q2, . . . Qn ∈ G2
# Output: (we focus on the Miller Loop)
#
# Write l in binary form, l = sum(0 ..< m-1)
# f ← 1, l ← abs(AteParam)
# for j ← 1 to n do
#   Tj ← Qj
# end
#
# for i = m-2 down to 0 do
#   f ← f²
#   for j ← 1 to n do
#     f ← f gTj,Tj(Pj), Tj ← [2]Tj
#     if li = 1 then
#       f ← f gTj,Qj(Pj), Tj ← Tj + Qj
#     end
#   end
# end
#
# -----
# Assuming we have N tuples (Pj, Qj) of points j in 0 ..< N
# and I operations to do in our Miller loop:
# - I = HammingWeight(AteParam) + Bitwidth(AteParam)
#   - HammingWeight(AteParam) corresponds to line additions
#   - Bitwidth(AteParam) corresponds to line doublings
#
# Scott approach is to have:
# - I Fp12 accumulators `g`
# - 1 G2 accumulator `T`
# and then accumulating each (Pj, Qj) into their corresponding `g` accumulator.
#
# Aranha approach is to have:
# - 1 Fp12 accumulator `f`
# - N G2 accumulators  `T`
# and accumulate N points per I.
#
# Scott approach is fully "online"/"streaming",
# while Aranha's saves space.
# For BLS12_381,
# I = 68 hence we would need 68*12*48 = 39168 bytes (381-bit needs 48 bytes)
# G2 has size 3*2*48 = 288 bytes (3 proj coordinates on Fp2)
# and we choose N (which can be 1 for single pairing or reverting to Scott approach).
#
# In actual use, "streaming pairings" are not used, pairings to compute are receive
# by batch, for example for blockchain you receive a batch of N blocks to verify from one peer.
# Furthermore, 39kB would be over L1 cache size and incurs cache misses.
# Additionally Aranha approach would make it easier to batch inversions
# using Montgomery's simultaneous inversion technique.
# Lastly, while a higher level API will need to store N (Pj, Qj) pairs for multi-pairings
# for Aranha approach, it can decide how big N is depending on hardware and/or protocol.
#
# Regarding optimizations, as the Fp12 accumulator is dense
# and lines are sparse (xyz000 or xy000z) Scott mentions the following costs:
# - squaring                 is 11m
# - Dense-sparse             is 13m
# - sparse-sparse            is 6m
# - Dense-(somewhat sparse)  is 17m
# Hence when accumulating lines from multiple points:
# - 2x Dense-sparse is 26m
# - sparse-sparse then Dense-(somewhat sparse) is 23m
# a 11.5% speedup
#
# We can use Aranha approach but process lines function 2-by-2 merging them
# before merging them to the dense Fp12 accumulator.
#
# In benchmarks though, the speedup doesn't work for BN curves but does for BLS curves.
#
# For single pairings
# Unfortunately, it's BN254_Snarks which requires a lot of addition in the Miller loop.
# BLS12-377 and BLS12-381 require 6 and 7 line addition in their Miller loop,
# the saving is about 150 cycles per addition for about 1000 cycles saved.
# A full pairing is ~2M cycles so this is only 0.5% for significantly
# more maintenance and bounds analysis complexity.
#
# For multipairing it is interesting since for a BLS signature verification (double pairing)
# we would save 1000 cycles per Ate iteration so ~70000 cycles, while a Miller loop is ~800000 cycles.

# Miller Loop - single pairing
# ----------------------------------------------------------------------------

func miller_init_double_then_add*[FT, F1, F2](
       f: var FT,
       T: var ECP_ShortW_Prj[F2, OnTwist],
       Q: ECP_ShortW_Aff[F2, OnTwist],
       P: ECP_ShortW_Aff[F1, NotOnTwist],
       numDoublings: static int
     ) =
  ## Start a Miller Loop with
  ## - `numDoubling` doublings
  ## - 1 add
  ##
  ## f is overwritten
  ## T is overwritten by Q
  static:
    doAssert f.c0 is Fp4
    doAssert FT.C == F1.C
    doAssert FT.C == F2.C
    doAssert numDoublings >= 1

  {.push checks: off.} # No OverflowError or IndexError allowed
  var line {.noInit.}: Line[F2]

  # First step: 0b10, T <- Q, f = 1 (mod p¹²), f *= line
  # ----------------------------------------------------
  T.projectiveFromAffine(Q)

  # f.square() -> square(1)
  line.line_double(T, P)

  # Doubling steps: 0b10...00
  # ----------------------------------------------------

  # Process all doublings, the second is special cased
  # as:
  # - The first line is squared (sparse * sparse)
  # - The second is (somewhat-sparse * sparse)
  when numDoublings >= 2:
    f.mul_sparse_sparse(line, line)
    line.line_double(T, P)
    f.mul(line)
    for _ in 2 ..< numDoublings:
      f.square()
      line.line_double(T, P)
      f.mul(line)

  # Addition step: 0b10...01
  # ------------------------------------------------

  # If there was only a single doubling needed,
  # we special case the addition as
  # - The first line and second are sparse (sparse * sparse)
  when numDoublings == 1:
    # TODO: sparse * sparse
    # f *= line <=> f = line for the first iteration
    # With Fp2 -> Fp4 -> Fp12 towering and a M-Twist
    # The line corresponds to a sparse xy000z Fp12
    var line2 {.noInit.}: Line[F2]
    line2.line_add(T, Q, P)
    f.mul_sparse_sparse(line, line2)
  else:
    line.line_add(T, Q, P)
    f.mul(line)

  {.pop.} # No OverflowError or IndexError allowed

func miller_accum_double_then_add*[FT, F1, F2](
       f: var FT,
       T: var ECP_ShortW_Prj[F2, OnTwist],
       Q: ECP_ShortW_Aff[F2, OnTwist],
       P: ECP_ShortW_Aff[F1, NotOnTwist],
       numDoublings: int,
       add = true
     ) =
  ## Continue a Miller Loop with
  ## - `numDoubling` doublings
  ## - 1 add
  ##
  ## f and T are updated
  #
  # `numDoublings` and `add` can be hardcoded at compile-time
  # to prevent fault attacks.
  # But fault attacks only happen on embedded
  # and embedded is likely to want to minimize codesize.
  # What to do?
  {.push checks: off.} # No OverflowError or IndexError allowed

  var line {.noInit.}: Line[F2]
  for _ in 0 ..< numDoublings:
    f.square()
    line.line_double(T, P)
    f.mul(line)

  if add:
    line.line_add(T, Q, P)
    f.mul(line)

# Miller Loop - multi-pairing
# ----------------------------------------------------------------------------
