# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./bigints,
  ../primitives/constant_time,
  ../config/common,
  ../io/io_bigints

# Precomputed constants
# ############################################################

# ############################################################
#
#                   Modular primitives
#
# ############################################################
#
# Those primitives are intended to be compile-time only
# Those are NOT tagged compile-time, using CTBool seems to confuse the VM

# We don't use distinct types here, they confuse the VM
# Similarly, using addC / subB confuses the VM

func dbl(a: var BigInt): bool =
  ## In-place multiprecision double
  ##   a -> 2a

  # Handling carries in the VM/without intrinsics is a pain ...
  for i in 0 ..< a.limbs.len:
    let carry = BaseType(result)
    let ai = BaseType(a.limbs[i])
    var new_a = ai
    new_a += carry
    result = new_a < ai
    new_a += ai
    result = result or (new_a < ai)
    a.limbs[i] = Word(new_a)

func csub(a: var BigInt, b: BigInt, ctl: bool): bool =
  ## In-place optional substraction
  ##
  ## It is NOT constant-time and is intended
  ## only for compile-time precomputation
  ## of non-secret data.

  # Handling borrow in the VM/without intrinsics is a pain ...
  for i in 0 ..< a.limbs.len:
    let ai = BaseType(a.limbs[i])
    let bi = BaseType(b.limbs[i])
    let borrow = BaseType(result)
    var new_a = ai
    result = bi > ai
    new_a -= bi
    result = result or (borrow > ai) # if bi + borrow overflow
    new_a -= borrow
    a.limbs[i] = if ctl: Word(new_a)
                 else: a.limbs[i]

func doubleMod(a: var BigInt, M: BigInt) =
  ## In-place modular double
  ##   a -> 2a (mod M)
  ##
  ## It is NOT constant-time and is intended
  ## only for compile-time precomputation
  ## of non-secret data.
  var ctl = dbl(a)
  ctl = ctl or not a.csub(M, false)
  discard csub(a, M, ctl)

# ############################################################
#
#          Montgomery Magic Constants precomputation
#
# ############################################################

func checkOddModulus(M: BigInt) =
  doAssert bool(BaseType(M.limbs[0]) and 1), "Internal Error: the modulus must be odd to use the Montgomery representation."

func checkValidModulus(M: BigInt) =
  const expectedMsb = M.bits-1 - WordBitWidth * (M.limbs.len - 1)
  let msb = log2(BaseType(M.limbs[^1]))

  doAssert msb == expectedMsb, "Internal Error: the modulus must use all declared bits and only those"

func useNoCarryMontyMul*(M: BigInt): bool =
  ## Returns if the modulus is compatible
  ## with the no-carry Montgomery Multiplication
  ## from https://hackmd.io/@zkteam/modular_multiplication
  # Indirection needed because static object are buggy
  # https://github.com/nim-lang/Nim/issues/9679
  BaseType(M.limbs[^1]) < high(BaseType) shr 1

func negInvModWord*(M: BigInt): BaseType =
  ## Returns the Montgomery domain magic constant for the input modulus:
  ##
  ##   µ ≡ -1/M[0] (mod Word)
  ##
  ## M[0] is the least significant limb of M
  ## M must be odd and greater than 2.
  ##
  ## Assuming 63-bit words:
  ##
  ## µ ≡ -1/M[0] (mod 2^63)

  # We use BaseType for return value because static distinct type
  # confuses Nim semchecks [UPSTREAM BUG]
  # We don't enforce compile-time evaluation here
  # because static BigInt[bits] also causes semcheck troubles [UPSTREAM BUG]

  # Modular inverse algorithm:
  # Explanation p11 "Dumas iterations" based on Newton-Raphson:
  # - Cetin Kaya Koc (2017), https://eprint.iacr.org/2017/411
  # - Jean-Guillaume Dumas (2012), https://arxiv.org/pdf/1209.6626v2.pdf
  # - Colin Plumb (1994), http://groups.google.com/groups?selm=1994Apr6.093116.27805%40mnemosyne.cs.du.edu
  # Other sources:
  # - https://crypto.stackexchange.com/questions/47493/how-to-determine-the-multiplicative-inverse-modulo-64-or-other-power-of-two
  # - https://mumble.net/~campbell/2015/01/21/inverse-mod-power-of-two
  # - http://marc-b-reynolds.github.io/math/2017/09/18/ModInverse.html

  # For Montgomery magic number, we are in a special case
  # where a = M and m = 2^WordBitWidth.
  # For a and m to be coprimes, a must be odd.

  # We have the following relation
  # ax ≡ 1 (mod 2^k) <=> ax(2 - ax) ≡ 1 (mod 2^(2k))
  #
  # To get  -1/M0 mod LimbSize
  # we can either negate the resulting x of `ax(2 - ax) ≡ 1 (mod 2^(2k))`
  # or do ax(2 + ax) ≡ 1 (mod 2^(2k))
  #
  # To get the the modular inverse of 2^k' with arbitrary k' (like k=63 in our case)
  # we can do modInv(a, 2^64) mod 2^63 as mentionned in Koc paper.

  checkOddModulus(M)
  checkValidModulus(M)

  let
    M0 = BaseType(M.limbs[0])
    k = log2(uint32(sizeof(BaseType)))

  result = M0                 # Start from an inverse of M0 modulo 2, M0 is odd and it's own inverse
  for _ in 0 ..< k:           # at each iteration we get the inverse mod(2^2k)
    result *= 2 + M0 * result # x' = x(2 + ax) (`+` to avoid negating at the end)

func r_powmod(n: static int, M: BigInt): BigInt =
  ## Returns the Montgomery domain magic constant for the input modulus:
  ##
  ##   R ≡ R (mod M) with R = (2^WordBitWidth)^numWords
  ##   or
  ##   R² ≡ R² (mod M) with R = (2^WordBitWidth)^numWords
  ##
  ## Assuming a field modulus of size 256-bit with 63-bit words, we require 5 words
  ##   R² ≡ ((2^63)^5)^2 (mod M) = 2^630 (mod M)

  # Algorithm
  # Bos and Montgomery, Montgomery Arithmetic from a Software Perspective
  # https://eprint.iacr.org/2017/1057.pdf
  #
  # For R = r^n = 2^wn and 2^(wn − 1) ≤ N < 2^wn
  # r^n = 2^63 in on 64-bit and w the number of words
  #
  # 1. C0 = 2^(wn - 1), the power of two immediately less than N
  # 2. for i in 1 ... wn+1
  #      Ci = C(i-1) + C(i-1) (mod M)
  #
  # Thus: C(wn+1) ≡ 2^(wn+1) C0 ≡ 2^(wn + 1) 2^(wn - 1) ≡ 2^(2wn) ≡ (2^wn)^2 ≡ R² (mod M)

  checkOddModulus(M)
  checkValidModulus(M)

  const
    w = M.limbs.len
    msb = M.bits-1 - WordBitWidth * (w - 1)
    start = (w-1)*WordBitWidth + msb
    stop = n*WordBitWidth*w

  result.limbs[^1] = Word(BaseType(1) shl msb) # C0 = 2^(wn-1), the power of 2 immediatly less than the modulus
  for _ in start ..< stop:
    result.doubleMod(M)

func r2mod*(M: BigInt): BigInt =
  ## Returns the Montgomery domain magic constant for the input modulus:
  ##
  ##   R² ≡ R² (mod M) with R = (2^WordBitWidth)^numWords
  ##
  ## Assuming a field modulus of size 256-bit with 63-bit words, we require 5 words
  ##   R² ≡ ((2^63)^5)^2 (mod M) = 2^630 (mod M)
  r_powmod(2, M)

func montyOne*(M: BigInt): BigInt =
  ## Returns "1 (mod M)" in the Montgomery domain.
  ## This is equivalent to R (mod M) in the natural domain
  r_powmod(1, M)

func primeMinus2_BE*[bits: static int](
       P: BigInt[bits]
     ): array[(bits+7) div 8, byte] {.noInit.} =
  ## Compute an input prime-2
  ## and return the result as a canonical byte array / octet string
  ## For use to precompute modular inverse exponent.

  var tmp = P
  discard tmp.csub(BigInt[bits].fromRawUint([byte 2], bigEndian), true)

  result.exportRawUint(tmp, bigEndian)