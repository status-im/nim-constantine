# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  # Standard library
  std/macros,
  # Internal
  ../config/common,
  ../primitives

# ############################################################
#
#        Assembly implementation of bigints
#
# ############################################################

# Note: We can refer to at most 30 registers in inline assembly
#       and "InputOutput" registers count double
#       They are nice to let the compiler deals with mov
#       but too constraining so we move things ourselves.

static: doAssert UseASM_X86_32

# Copy
# ------------------------------------------------------------
macro ccopy_gen[N: static int](a: var Limbs[N], b: Limbs[N], ctl: SecretBool): untyped =
  ## Generate an optimized conditional copy kernel
  result = newStmtList()

  var ctx = init(Assembler_x86, BaseType)

  let
    arrA = init(OperandArray, nimSymbol = a, N, PointerInReg, InputOutput)
    arrB = init(OperandArray, nimSymbol = b, N, PointerInReg, Input)
    # If N is too big, we need to spill registers. TODO.
    arrT = init(OperandArray, nimSymbol = ident"t", N, ElemsInReg, Output_EarlyClobber)

    control = Operand(
      desc: OperandDesc(
        asmId: "[ctl]",
        nimSymbol: ctl,
        rm: Reg,
        constraint: Input,
        cEmit: "ctl"
      )
    )

  ctx.test control, control
  for i in 0 ..< N:
    ctx.mov arrT[i], arrA[i]
    ctx.cmovnz arrT[i], arrB[i]
    ctx.mov arrA[i], arrT[i]

  let t = arrT.nimSymbol
  let c = control.desc.nimSymbol
  result.add quote do:
    var `t` {.noInit.}: typeof(`a`)
  result.add ctx.generate()

func ccopy_asm*(a: var Limbs, b: Limbs, ctl: SecretBool) {.inline.}=
  ## Constant-time conditional copy
  ## If ctl is true: b is copied into a
  ## if ctl is false: b is not copied and a is untouched
  ## Time and memory accesses are the same whether a copy occurs or not
  ccopy_gen(a, b, ctl)

# Addition
# ------------------------------------------------------------

macro add_gen[N: static int](carry: var Carry, r: var Limbs[N], a, b: Limbs[N]): untyped =
  ## Generate an optimized out-of-place addition kernel

  result = newStmtList()

  var ctx = init(Assembler_x86, BaseType)
  let
    arrR = init(OperandArray, nimSymbol = r, N, PointerInReg, InputOutput)
    arrA = init(OperandArray, nimSymbol = a, N, PointerInReg, Input)
    arrB = init(OperandArray, nimSymbol = b, N, PointerInReg, Input)

  var # Swappable registers to break dependency chains
    t0 = Operand(
      desc: OperandDesc(
        asmId: "[t0]",
        nimSymbol: ident"t0",
        rm: Reg,
        constraint: Output_EarlyClobber,
        cEmit: "t0"
      )
    )

    t1 = Operand(
      desc: OperandDesc(
        asmId: "[t1]",
        nimSymbol: ident"t1",
        rm: Reg,
        constraint: Output_EarlyClobber,
        cEmit: "t1"
      )
    )

  # Addition
  for i in 0 ..< N:
    ctx.mov t0, arrA[i]
    if i == 0:
      ctx.add t0, arrB[0]
    else:
      ctx.adc t0, arrB[i]
    ctx.mov arrR[i], t0
    swap(t0, t1)
  ctx.setToCarryFlag(carry)

  # Codegen
  let t0sym = t0.desc.nimSymbol
  let t1sym = t1.desc.nimSymbol
  result.add quote do:
    var `t0sym`{.noinit.}, `t1sym`{.noinit.}: BaseType
  result.add ctx.generate

func add_asm*(r: var Limbs, a, b: Limbs): Carry =
  ## Constant-time addition
  add_gen(result, r, a, b)

# Substraction
# ------------------------------------------------------------

macro sub_gen[N: static int](borrow: var Borrow, r: var Limbs[N], a, b: Limbs[N]): untyped =
  ## Generate an optimized out-of-place addition kernel

  result = newStmtList()

  var ctx = init(Assembler_x86, BaseType)
  let
    arrR = init(OperandArray, nimSymbol = r, N, PointerInReg, InputOutput)
    arrA = init(OperandArray, nimSymbol = a, N, PointerInReg, Input)
    arrB = init(OperandArray, nimSymbol = b, N, PointerInReg, Input)

  var # Swappable registers to break dependency chains
    t0 = Operand(
      desc: OperandDesc(
        asmId: "[t0]",
        nimSymbol: ident"t0",
        rm: Reg,
        constraint: Output_EarlyClobber,
        cEmit: "t0"
      )
    )

    t1 = Operand(
      desc: OperandDesc(
        asmId: "[t1]",
        nimSymbol: ident"t1",
        rm: Reg,
        constraint: Output_EarlyClobber,
        cEmit: "t1"
      )
    )

  # Substraction
  for i in 0 ..< N:
    ctx.mov t0, arrA[i]
    if i == 0:
      ctx.sub t0, arrB[0]
    else:
      ctx.sbb t0, arrB[i]
    ctx.mov arrR[i], t0
    swap(t0, t1)
  ctx.setToCarryFlag(borrow)

  # Codegen
  let t0sym = t0.desc.nimSymbol
  let t1sym = t1.desc.nimSymbol
  result.add quote do:
    var `t0sym`{.noinit.}, `t1sym`{.noinit.}: BaseType
  result.add ctx.generate

func sub_asm*(r: var Limbs, a, b: Limbs): Borrow =
  ## Constant-time addition
  sub_gen(result, r, a, b)
