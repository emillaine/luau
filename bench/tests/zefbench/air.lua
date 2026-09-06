-- forward declarations (no hoisted globals)
Inst_forEachArg = null
Inst_hash = null
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()


-- Air benchmark - Lua port
-- Compatible with: Lua 5.5, LuaJIT 2.x, Lute

-- -------------------------------------------------------------------------
-- 32-bit arithmetic helpers
-- -------------------------------------------------------------------------
C = {
    MOD32 = 4294967296,
    GP = 0,
    FP = 1,
    Ptr = 64,
    Locked = 0,
    Spill = 1,
    Normal = 0,
    Rare = 1,
    Equal = 4,
    NotEqual = 5,
    Above = 7,
    AboveOrEqual = 3,
    Below = 2,
    BelowOrEqual = 6,
    GreaterThan = 15,
    GreaterThanOrEqual = 13,
    LessThan = 12,
    LessThanOrEqual = 14,
    Overflow = 0,
    Signed = 8,
    PositiveOrZero = 9,
    Zero = 4,
    NonZero = 5,
    DoubleNotEqual = 5,
    DoubleGreaterThan = 7,
    DoubleGreaterThanOrEqual = 3,
    DoubleEqualOrUnordered = 4,
    DoubleLessThanOrUnordered = 2,
    DoubleLessThanOrEqualOrUnordered = 6,
    AbsDouble = 0,
    AbsFloat = 1,
    Add16 = 2,
    Add32 = 3,
    Add64 = 4,
    Add8 = 5,
    AddDouble = 6,
    AddFloat = 7,
    And32 = 8,
    And64 = 9,
    AndDouble = 10,
    AndFloat = 11,
    Branch32 = 12,
    Branch64 = 13,
    Branch8 = 14,
    BranchAdd32 = 15,
    BranchAdd64 = 16,
    BranchDouble = 17,
    BranchFloat = 18,
    BranchMul32 = 19,
    BranchMul64 = 20,
    BranchNeg32 = 21,
    BranchNeg64 = 22,
    BranchSub32 = 23,
    BranchSub64 = 24,
    BranchTest32 = 25,
    BranchTest64 = 26,
    BranchTest8 = 27,
    CCall = 28,
    CeilDouble = 29,
    CeilFloat = 30,
    ColdCCall = 31,
    Compare32 = 32,
    Compare64 = 33,
    CompareDouble = 34,
    CompareFloat = 35,
    ConvertDoubleToFloat = 36,
    ConvertFloatToDouble = 37,
    ConvertInt32ToDouble = 38,
    ConvertInt32ToFloat = 39,
    ConvertInt64ToDouble = 40,
    ConvertInt64ToFloat = 41,
    CountLeadingZeros32 = 42,
    CountLeadingZeros64 = 43,
    Div32 = 44,
    Div64 = 45,
    DivDouble = 46,
    DivFloat = 47,
    FloorDouble = 48,
    FloorFloat = 49,
    Jump = 50,
    Lea = 51,
    Load16 = 52,
    Load16SignedExtendTo32 = 53,
    Load8 = 54,
    Load8SignedExtendTo32 = 55,
    Lshift32 = 56,
    Lshift64 = 57,
    Move = 58,
    Move32 = 59,
    Move32ToFloat = 60,
    Move64ToDouble = 61,
    MoveConditionally32 = 62,
    MoveConditionally64 = 63,
    MoveConditionallyDouble = 64,
    MoveConditionallyFloat = 65,
    MoveConditionallyTest32 = 66,
    MoveConditionallyTest64 = 67,
    MoveDouble = 68,
    MoveDoubleConditionally32 = 69,
    MoveDoubleConditionally64 = 70,
    MoveDoubleConditionallyDouble = 71,
    MoveDoubleConditionallyFloat = 72,
    MoveDoubleConditionallyTest32 = 73,
    MoveDoubleConditionallyTest64 = 74,
    MoveDoubleTo64 = 75,
    MoveFloat = 76,
    MoveFloatTo32 = 77,
    MoveZeroToDouble = 78,
    Mul32 = 79,
    Mul64 = 80,
    MulDouble = 81,
    MulFloat = 82,
    MultiplyAdd32 = 83,
    MultiplyAdd64 = 84,
    MultiplyNeg32 = 85,
    MultiplyNeg64 = 86,
    MultiplySub32 = 87,
    MultiplySub64 = 88,
    Neg32 = 89,
    Neg64 = 90,
    NegateDouble = 91,
    Nop = 92,
    Not32 = 93,
    Not64 = 94,
    Oops = 95,
    Or32 = 96,
    Or64 = 97,
    Patch = 98,
    Ret32 = 99,
    Ret64 = 100,
    RetDouble = 101,
    RetFloat = 102,
    Rshift32 = 103,
    Rshift64 = 104,
    Shuffle = 105,
    SignExtend16To32 = 106,
    SignExtend32ToPtr = 107,
    SignExtend8To32 = 108,
    SqrtDouble = 109,
    SqrtFloat = 110,
    Store16 = 111,
    Store8 = 112,
    StoreZero32 = 113,
    Sub32 = 114,
    Sub64 = 115,
    SubDouble = 116,
    SubFloat = 117,
    Swap32 = 118,
    Swap64 = 119,
    Test32 = 120,
    Test64 = 121,
    Urshift32 = 122,
    Urshift64 = 123,
    X86ConvertToDoubleWord32 = 124,
    X86ConvertToQuadWord64 = 125,
    X86Div32 = 126,
    X86Div64 = 127,
    Xor32 = 128,
    Xor64 = 129,
    XorDouble = 130,
    XorFloat = 131,
    ZeroExtend16To32 = 132,
    ZeroExtend8To32 = 133,
    ArgInvalid = 0,
    ArgTmp = 1,
    ArgImm = 2,
    ArgBigImm = 3,
    ArgBitImm = 4,
    ArgBitImm64 = 5,
    ArgAddr = 6,
    ArgStack = 7,
    ArgCallArg = 8,
    ArgIndex = 9,
    ArgRelCond = 10,
    ArgResCond = 11,
    ArgDoubleCond = 12,
    ArgSpecial = 13,
    ArgWidth = 14,
    ArgRole_Use = 0,
    ArgRole_ColdUse = 1,
    ArgRole_LateUse = 2,
    ArgRole_LateColdUse = 3,
    ArgRole_Def = 4,
    ArgRole_ZDef = 5,
    ArgRole_UseDef = 6,
    ArgRole_UseZDef = 7,
    ArgRole_EarlyDef = 8,
    ArgRole_Scratch = 9,
    ArgRole_UseAddr = 10,
}
function int32(x)
    x = x % C.MOD32
    if x >= 2147483648 then x = x - C.MOD32 end
    return x
end
function uint32(x) return x % C.MOD32 end

-- -------------------------------------------------------------------------
-- Type / kind / frequency constants
-- -------------------------------------------------------------------------



-- -------------------------------------------------------------------------
-- Relational conditions (values == relCondCode output)
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- Result conditions (values == resCondCode output)
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- Double conditions (values == doubleCondCode output)
-- -------------------------------------------------------------------------
DoubleEqual                        = 36  -- 4|0x20
DoubleLessThan                     = 23  -- 7|0x10
DoubleLessThanOrEqual              = 19  -- 3|0x10
DoubleNotEqualOrUnordered          = 37  -- 5|0x20
DoubleGreaterThanOrUnordered       = 18  -- 2|0x10
DoubleGreaterThanOrEqualOrUnordered= 22  -- 6|0x10

-- -------------------------------------------------------------------------
-- Opcode constants (== opcodeCode values)
-- -------------------------------------------------------------------------


-- -------------------------------------------------------------------------
-- ArgKind constants (== Arg.kindCode values)
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- ArgRole constants
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- ArgRole predicates
-- -------------------------------------------------------------------------
function Arg_isAnyUse(role)
    return role==0 or role==1 or role==2 or role==3 or role==6 or role==7 or role==9
end
function Arg_isEarlyUse(role)
    return role==0 or role==1 or role==6 or role==7
end
function Arg_isLateUse(role)
    return role==2 or role==3 or role==9
end
function Arg_isAnyDef(role)
    return role==4 or role==5 or role==6 or role==7 or role==8 or role==9
end
function Arg_isEarlyDef(role)
    return role==8 or role==9
end
function Arg_isLateDef(role)
    return role==4 or role==5 or role==6 or role==7
end
function Arg_isZDef(role)
    return role==5 or role==7
end

-- -------------------------------------------------------------------------
-- Registers (global singleton tables)
-- -------------------------------------------------------------------------
function makeReg(index, rtype, name, isCalleeSave)
    return {index=index, type=rtype, name=name, isCalleeSave=isCalleeSave or false,
            isReg=true}
end
function Reg_hash(reg)
    if reg.type == C.GP then return 1 + reg.index else return -1 - reg.index end
end

Reg_rax = makeReg(0,  C.GP, "rax")
Reg_rcx = makeReg(1,  C.GP, "rcx")
Reg_rdx = makeReg(2,  C.GP, "rdx")
Reg_rbx = makeReg(3,  C.GP, "rbx", true)
Reg_rsp = makeReg(4,  C.GP, "rsp")
Reg_rbp = makeReg(5,  C.GP, "rbp", true)
Reg_rsi = makeReg(6,  C.GP, "rsi")
Reg_rdi = makeReg(7,  C.GP, "rdi")
Reg_r8  = makeReg(8,  C.GP, "r8")
Reg_r9  = makeReg(9,  C.GP, "r9")
Reg_r10 = makeReg(10, C.GP, "r10")
Reg_r11 = makeReg(11, C.GP, "r11")
Reg_r12 = makeReg(12, C.GP, "r12", true)
Reg_r13 = makeReg(13, C.GP, "r13", true)
Reg_r14 = makeReg(14, C.GP, "r14", true)
Reg_r15 = makeReg(15, C.GP, "r15", true)
Reg_xmm0  = makeReg(0,  C.FP, "xmm0")
Reg_xmm1  = makeReg(1,  C.FP, "xmm1")
Reg_xmm2  = makeReg(2,  C.FP, "xmm2")
Reg_xmm3  = makeReg(3,  C.FP, "xmm3")
Reg_xmm4  = makeReg(4,  C.FP, "xmm4")
Reg_xmm5  = makeReg(5,  C.FP, "xmm5")
Reg_xmm6  = makeReg(6,  C.FP, "xmm6")
Reg_xmm7  = makeReg(7,  C.FP, "xmm7")
Reg_xmm8  = makeReg(8,  C.FP, "xmm8")
Reg_xmm9  = makeReg(9,  C.FP, "xmm9")
Reg_xmm10 = makeReg(10, C.FP, "xmm10")
Reg_xmm11 = makeReg(11, C.FP, "xmm11")
Reg_xmm12 = makeReg(12, C.FP, "xmm12")
Reg_xmm13 = makeReg(13, C.FP, "xmm13")
Reg_xmm14 = makeReg(14, C.FP, "xmm14")
Reg_xmm15 = makeReg(15, C.FP, "xmm15")

Reg_gprs = {Reg_rax,Reg_rcx,Reg_rdx,Reg_rbx,Reg_rsp,Reg_rbp,Reg_rsi,Reg_rdi,
                  Reg_r8,Reg_r9,Reg_r10,Reg_r11,Reg_r12,Reg_r13,Reg_r14,Reg_r15}
Reg_fprs = {Reg_xmm0,Reg_xmm1,Reg_xmm2,Reg_xmm3,Reg_xmm4,Reg_xmm5,
                  Reg_xmm6,Reg_xmm7,Reg_xmm8,Reg_xmm9,Reg_xmm10,Reg_xmm11,
                  Reg_xmm12,Reg_xmm13,Reg_xmm14,Reg_xmm15}
Reg_callFrameRegister   = Reg_rbp
Reg_stackPointerRegister= Reg_rsp

-- -------------------------------------------------------------------------
-- StackSlot
-- -------------------------------------------------------------------------
function StackSlot_new(index, byteSize, kind)
    return {index=index, byteSize=byteSize, kind=kind, offsetFromFP=null}
end
function StackSlot_alignment(slot)
    b = slot.byteSize
    if b <= 1 then return 1
    else if b <= 2 then return 2
    else if b <= 4 then return 4
    else return 8 end
end
function StackSlot_hash(slot)
    v = (slot.kind==C.Spill and 1 or 0) + slot.byteSize*3
              + (slot.offsetFromFP and slot.offsetFromFP*7 or 0)
    return uint32(v)
end
function StackSlot_setOffsetFromFP(slot, val)
    slot.offsetFromFP = val
end

-- StackSlot.forEach: only acts on Stack args
function StackSlot_forEach(arg, role, type, width, func)
    if arg.kind != C.ArgStack then return null end
    replacement = func(arg.slot, role, type, width)
    if replacement then
        return {kind=C.ArgStack, slot=replacement, offset=arg.offset}
    end
    return null
end

-- -------------------------------------------------------------------------
-- BasicBlock / FrequentedBlock
-- -------------------------------------------------------------------------
function BasicBlock_new(index, frequency)
    return {index=index, frequency=frequency, insts={}, successors={}, predecessors={}}
end
function BasicBlock_size(bb) return #bb.insts end
function BasicBlock_at(bb, idx) return bb.insts[idx+1] end  -- 0-based
function BasicBlock_get(bb, idx)  -- 0-based, returns null if out of range
    if idx < 0 or idx >= #bb.insts then return null end
    return bb.insts[idx+1]
end
function BasicBlock_last(bb) return bb.insts[#bb.insts] end
function BasicBlock_append(bb, inst) bb.insts[#bb.insts+1] = inst end

-- FrequentedBlock
function FrequentedBlock_new(block, frequency)
    return {block=block, frequency=frequency}
end

-- -------------------------------------------------------------------------
-- Code
-- -------------------------------------------------------------------------
function Code_new()
    return {blocks={}, stackSlots={}, gpTmps={}, fpTmps={},
            callArgAreaSize=0, frameSize=0}
end
function Code_addBlock(code, frequency)
    frequency = frequency or 1
    bb = BasicBlock_new(#code.blocks, frequency)
    code.blocks[#code.blocks+1] = bb
    return bb
end
function Code_addStackSlot(code, byteSize, kind)
    slot = StackSlot_new(#code.stackSlots, byteSize, kind)
    code.stackSlots[#code.stackSlots+1] = slot
    return slot
end
function Code_newTmp(code, type)
    arr = (type == C.GP) and code.gpTmps or code.fpTmps
    tmp = {index=#arr, type=type, isReg=false}
    arr[#arr+1] = tmp
    return tmp
end
function Code_requestCallArgAreaSize(code, size)
    aligned = math.ceil(size / 16) * 16
    if aligned > code.callArgAreaSize then code.callArgAreaSize = aligned end
end
function Code_setFrameSize(code, fs) code.frameSize = fs end
function Code_hash(code)
    result = 0
    for _, block in ipairs(code.blocks) do
        result = result * 1000001
        result = int32(result)
        for _, inst in ipairs(block.insts) do
            result = result * 97
            result = int32(result)
            result = result + Inst_hash(inst)
            result = int32(result)
        end
        for _, fb in ipairs(block.successors) do
            result = result * 7
            result = int32(result)
            result = result + fb.block.index
            result = int32(result)
        end
    end
    for _, slot in ipairs(code.stackSlots) do
        result = result * 101
        result = int32(result)
        result = result + StackSlot_hash(slot)
        result = int32(result)
    end
    return uint32(result)
end

-- -------------------------------------------------------------------------
-- Arg factory functions
-- -------------------------------------------------------------------------
function Arg_createTmp(tmp)
    return {kind=C.ArgTmp, tmp=tmp}
end
function Arg_createImm(value)
    return {kind=C.ArgImm, value=value}
end
function Arg_createBigImm(lowValue, highValue)
    return {kind=C.ArgBigImm, lowValue=lowValue, highValue=highValue or 0}
end
function Arg_createBitImm(value)
    return {kind=C.ArgBitImm, value=value}
end
function Arg_createBitImm64(lowValue, highValue)
    return {kind=C.ArgBitImm64, lowValue=lowValue, highValue=highValue or 0}
end
function Arg_createAddr(base, offset)
    return {kind=C.ArgAddr, base=base, offset=offset or 0}
end
function Arg_createStack(slot, offset)
    return {kind=C.ArgStack, slot=slot, offset=offset or 0}
end
function Arg_createCallArg(offset)
    return {kind=C.ArgCallArg, offset=offset}
end
function Arg_createIndex(base, idx, scale, offset)
    return {kind=C.ArgIndex, base=base, index_reg=idx, scale=scale or 1, offset=offset or 0}
end
function Arg_createRelCond(condition)
    return {kind=C.ArgRelCond, condition=condition}
end
function Arg_createResCond(condition)
    return {kind=C.ArgResCond, condition=condition}
end
function Arg_createDoubleCond(condition)
    return {kind=C.ArgDoubleCond, condition=condition}
end
function Arg_createSpecial()
    return {kind=C.ArgSpecial}
end
function Arg_createWidth(width)
    return {kind=C.ArgWidth, width=width}
end
function Arg_createStackAddr(offsetFromFP, frameSize, width)
    -- isValidAddrForm always returns true, so always use callFrameRegister
    return Arg_createAddr(Reg_callFrameRegister, offsetFromFP)
end

-- -------------------------------------------------------------------------
-- Arg hash
-- -------------------------------------------------------------------------
function Arg_hash(arg)
    result = arg.kind  -- kindCode == kind value
    k = arg.kind
    if k == C.ArgTmp then
        t = arg.tmp
        if t.isReg then result = result + Reg_hash(t)
        else result = result end  -- Tmp.hash() never called for virtual tmps
        result = int32(result)
    else if k == C.ArgImm or k == C.ArgBitImm then
        result = result + arg.value
        result = int32(result)
    else if k == C.ArgBigImm or k == C.ArgBitImm64 then
        result = result + arg.lowValue
        result = int32(result)
        result = result + arg.highValue
        result = int32(result)
    else if k == C.ArgCallArg then
        result = result + arg.offset
        result = int32(result)
    else if k == C.ArgRelCond then
        result = result + arg.condition  -- condition IS the relCondCode
        result = int32(result)
    else if k == C.ArgResCond then
        result = result + arg.condition  -- condition IS the resCondCode
        result = int32(result)
    else if k == C.ArgDoubleCond then
        result = result + arg.condition  -- condition IS the doubleCondCode
        result = int32(result)
    else if k == C.ArgWidth then
        result = result + arg.width
        result = int32(result)
    else if k == C.ArgAddr then
        result = result + arg.offset
        result = int32(result)
        result = result + Reg_hash(arg.base)
        result = int32(result)
    else if k == C.ArgIndex then
        result = result + arg.offset
        result = int32(result)
        result = result + arg.scale
        result = int32(result)
        result = result + Reg_hash(arg.base)
        result = int32(result)
        result = result + Reg_hash(arg.index_reg)
        result = int32(result)
    else if k == C.ArgStack then
        result = result + arg.offset
        result = int32(result)
        result = result + arg.slot.index
        result = int32(result)
    end
    return uint32(result)
end

-- -------------------------------------------------------------------------
-- Inst
-- -------------------------------------------------------------------------
function Inst_new(opcode)
    return {opcode=opcode, args={}}
end
function Inst_clear(inst)
    inst.opcode = C.Nop
    inst.args = {}
end
function Inst_hash(inst)
    result = inst.opcode  -- opcodeCode == opcode value
    for _, arg in ipairs(inst.args) do
        result = result + Arg_hash(arg)
        result = int32(result)
    end
    return uint32(result)
end
function Inst_visitArg(inst, index, func, role, type, width)
    -- index is 1-based
    replacement = func(inst.args[index], role, type, width)
    if replacement then inst.args[index] = replacement end
end

-- Allow OOP-style calls: inst:visitArg(...)
Inst_mt = {__index = {
    visitArg = Inst_visitArg,
    append = function(self, ...) for _,v in ipairs({...}) do self.args[#self.args+1]=v end end,
}}

-- We don't actually set metatables; instead use module-style calls below.
-- But for payload code which calls inst:visitArg, we need metatables.
-- Set up so all Inst tables get the methods:
Inst_proto = {}
Inst_proto.visitArg = function(self, index, func, role, type, width)
    replacement = func(self.args[index], role, type, width)
    if replacement then self.args[index] = replacement end
end
Inst_proto.forEachArg = function(self, func)
    Inst_forEachArg(self, func)
end

-- We'll set metatables on each new inst:
Inst_meta = {__index = Inst_proto}
function Inst_new(opcode)
    return setmetatable({opcode=opcode, args={}}, Inst_meta)
end

-- -------------------------------------------------------------------------
-- PatchCustom
-- -------------------------------------------------------------------------
function PatchCustom_forEachArg(inst, func)
    for i = 1, #inst.args do
        pd = inst.patchArgData[i]
        inst:visitArg(i, func, pd.role, pd.type, pd.width)
    end
end
function PatchCustom_hasNonArgNonControlEffects(inst)
    return inst.patchHasNonArgEffects
end

-- CCall/ColdCCall stubs (not used in payloads but needed for completeness)
function CCallCustom_forEachArg(inst, func) end
function ColdCCallCustom_forEachArg(inst, func) end
function CCallCustom_hasNonArgNonControlEffects(inst) return true end
function ColdCCallCustom_hasNonArgNonControlEffects(inst) return true end
function ShuffleCustom_hasNonArgNonControlEffects(inst) return false end

Inst_forEachArg_dispatch = {}
Inst_forEachArg_dispatch[C.Nop] = function(inst, func)
end

Inst_forEachArg_dispatch[C.Add32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Add8] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 8)
end

Inst_forEachArg_dispatch[C.Add16] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 16)
end

Inst_forEachArg_dispatch[C.Add64] = function(inst, func)
    n = #inst.args
    if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    else if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.AddDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.AddFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.Sub32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Sub64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.SubDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.SubFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.Neg32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Neg64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.NegateDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Mul32] = function(inst, func)
    n = #inst.args
    if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    else if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Mul64] = function(inst, func)
    n = #inst.args
    if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    else if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.MultiplyAdd32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.MultiplyAdd64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.MultiplySub32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.MultiplySub64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.MultiplyNeg32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.MultiplyNeg64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.Div32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Div64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.MulDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.MulFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.DivDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.DivFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.X86ConvertToDoubleWord32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.X86ConvertToQuadWord64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.X86Div32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseZDef, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
end

Inst_forEachArg_dispatch[C.X86Div64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseZDef, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
end

Inst_forEachArg_dispatch[C.Lea] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseAddr, C.GP, C.Ptr)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, C.Ptr)
end

Inst_forEachArg_dispatch[C.And32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.And64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.AndDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.AndFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.XorDouble] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 64)
    end
end

Inst_forEachArg_dispatch[C.XorFloat] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Def, C.FP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.FP, 32)
    end
end

Inst_forEachArg_dispatch[C.Lshift32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Lshift64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.Rshift32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Rshift64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.Urshift32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Urshift64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.Or32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Or64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.Xor32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Xor64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Def, C.GP, 64)
    else if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.Not32] = function(inst, func)
    n = #inst.args
    if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 1 then
    inst:visitArg(1, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.Not64] = function(inst, func)
    n = #inst.args
    if n == 2 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 64)
    else if n == 1 then
    inst:visitArg(1, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.AbsDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.AbsFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.CeilDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.CeilFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.FloorDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.FloorFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.SqrtDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.SqrtFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.ConvertInt32ToDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.ConvertInt64ToDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.ConvertInt32ToFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.ConvertInt64ToFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.CountLeadingZeros32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.CountLeadingZeros64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.ConvertDoubleToFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.ConvertFloatToDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Move] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, C.Ptr)
end

Inst_forEachArg_dispatch[C.Swap32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseDef, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Swap64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_UseDef, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_UseDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.Move32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.StoreZero32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
end

Inst_forEachArg_dispatch[C.SignExtend32ToPtr] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, C.Ptr)
end

Inst_forEachArg_dispatch[C.ZeroExtend8To32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.SignExtend8To32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.ZeroExtend16To32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.SignExtend16To32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.MoveFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.MoveDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveZeroToDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Move64ToDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Move32ToFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.FP, 32)
end

Inst_forEachArg_dispatch[C.MoveDoubleTo64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 64)
end

Inst_forEachArg_dispatch[C.MoveFloatTo32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Load8] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Store8] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 8)
end

Inst_forEachArg_dispatch[C.Load8SignedExtendTo32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Load16] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Load16SignedExtendTo32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Store16] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 16)
    inst:visitArg(2, func, C.ArgRole_Def, C.GP, 16)
end

Inst_forEachArg_dispatch[C.Compare32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Compare64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Test32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Test64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.CompareDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.CompareFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Branch8] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 8)
end

Inst_forEachArg_dispatch[C.Branch32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Branch64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
end

Inst_forEachArg_dispatch[C.BranchTest8] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 8)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 8)
end

Inst_forEachArg_dispatch[C.BranchTest32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
end

Inst_forEachArg_dispatch[C.BranchTest64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
end

Inst_forEachArg_dispatch[C.BranchDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 64)
end

Inst_forEachArg_dispatch[C.BranchFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 32)
end

Inst_forEachArg_dispatch[C.BranchAdd32] = function(inst, func)
    n = #inst.args
    if n == 4 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_UseZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.BranchAdd64] = function(inst, func)
    n = #inst.args
    if n == 4 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 64)
    else if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_UseDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.BranchMul32] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_UseZDef, C.GP, 32)
    else if n == 4 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_ZDef, C.GP, 32)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Scratch, C.GP, 32)
    inst:visitArg(5, func, C.ArgRole_Scratch, C.GP, 32)
    inst:visitArg(6, func, C.ArgRole_ZDef, C.GP, 32)
    end
end

Inst_forEachArg_dispatch[C.BranchMul64] = function(inst, func)
    n = #inst.args
    if n == 3 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_UseZDef, C.GP, 64)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Scratch, C.GP, 64)
    inst:visitArg(5, func, C.ArgRole_Scratch, C.GP, 64)
    inst:visitArg(6, func, C.ArgRole_ZDef, C.GP, 64)
    end
end

Inst_forEachArg_dispatch[C.BranchSub32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_UseZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.BranchSub64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_UseDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.BranchNeg32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 32)
end

Inst_forEachArg_dispatch[C.BranchNeg64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_UseZDef, C.GP, 64)
end

Inst_forEachArg_dispatch[C.MoveConditionally32] = function(inst, func)
    n = #inst.args
    if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveConditionally64] = function(inst, func)
    n = #inst.args
    if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveConditionallyTest32] = function(inst, func)
    n = #inst.args
    if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveConditionallyTest64] = function(inst, func)
    n = #inst.args
    if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    else if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveConditionallyDouble] = function(inst, func)
    n = #inst.args
    if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    else if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveConditionallyFloat] = function(inst, func)
    n = #inst.args
    if n == 6 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(6, func, C.ArgRole_Def, C.GP, C.Ptr)
    else if n == 5 then
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.GP, C.Ptr)
    inst:visitArg(5, func, C.ArgRole_UseDef, C.GP, C.Ptr)
    end
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionally32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionally64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionallyTest32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionallyTest64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.GP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionallyDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.MoveDoubleConditionallyFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
    inst:visitArg(2, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(3, func, C.ArgRole_Use, C.FP, 32)
    inst:visitArg(4, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(5, func, C.ArgRole_Use, C.FP, 64)
    inst:visitArg(6, func, C.ArgRole_Def, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Jump] = function(inst, func)
end

Inst_forEachArg_dispatch[C.Ret32] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 32)
end

Inst_forEachArg_dispatch[C.Ret64] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.GP, 64)
end

Inst_forEachArg_dispatch[C.RetFloat] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 32)
end

Inst_forEachArg_dispatch[C.RetDouble] = function(inst, func)
    inst:visitArg(1, func, C.ArgRole_Use, C.FP, 64)
end

Inst_forEachArg_dispatch[C.Oops] = function(inst, func)
end

Inst_forEachArg_dispatch[C.Shuffle] = function(inst, func)
    PatchCustom_forEachArg(inst, func)  -- NOTE: Shuffle not fully impl
    -- ShuffleCustom not needed for payloads
end

Inst_forEachArg_dispatch[C.Patch] = function(inst, func)
    PatchCustom_forEachArg(inst, func)
end

Inst_forEachArg_dispatch[C.CCall] = function(inst, func)
    CCallCustom_forEachArg(inst, func)
end

Inst_forEachArg_dispatch[C.ColdCCall] = function(inst, func)
    ColdCCallCustom_forEachArg(inst, func)
end

function Inst_hasNonArgEffects(inst)
    op = inst.opcode
    if op == C.Branch8 or
        op == C.Branch32 or
        op == C.Branch64 or
        op == C.BranchTest8 or
        op == C.BranchTest32 or
        op == C.BranchTest64 or
        op == C.BranchDouble or
        op == C.BranchFloat or
        op == C.BranchAdd32 or
        op == C.BranchAdd64 or
        op == C.BranchMul32 or
        op == C.BranchMul64 or
        op == C.BranchSub32 or
        op == C.BranchSub64 or
        op == C.BranchNeg32 or
        op == C.BranchNeg64 or
        op == C.Jump or
        op == C.Ret32 or
        op == C.Ret64 or
        op == C.RetFloat or
        op == C.RetDouble or
        op == C.Oops then
        return true
    else if op == C.Shuffle then
        return ShuffleCustom_hasNonArgNonControlEffects(inst)
    else if op == C.Patch then
        return PatchCustom_hasNonArgNonControlEffects(inst)
    else if op == C.CCall then
        return CCallCustom_hasNonArgNonControlEffects(inst)
    else if op == C.ColdCCall then
        return CCallCustom_hasNonArgNonControlEffects(inst)
    end
    return false
end

-- -------------------------------------------------------------------------
-- Inst_forEach helpers (for StackSlot liveness)
-- -------------------------------------------------------------------------
function Inst_forEachArg(inst, func)
    d = Inst_forEachArg_dispatch[inst.opcode]
    if d then d(inst, func)
    else end
end

function Inst_forEach_StackSlot(inst, callback)
    Inst_forEachArg(inst, function(arg, role, type, width)
        if arg.kind == C.ArgStack then
            callback(arg.slot, role, type, width)
        end
    end)
end

function Inst_forEachDef_StackSlot(prevInst, nextInst, callback)
    if prevInst then
        Inst_forEach_StackSlot(prevInst, function(value, role, type, width)
            if Arg_isLateDef(role) then callback(value, role, type, width) end
        end)
    end
    if nextInst then
        Inst_forEach_StackSlot(nextInst, function(value, role, type, width)
            if Arg_isEarlyDef(role) then callback(value, role, type, width) end
        end)
    end
end

-- -------------------------------------------------------------------------
-- Liveness
-- -------------------------------------------------------------------------
function mergeIntoSet(target, source)
    didAdd = false
    for v, _ in pairs(source) do
        if not target[v] then
            target[v] = true
            didAdd = true
        end
    end
    return didAdd
end

function Liveness_new(code)
    liveAtHead = {}
    liveAtTail = {}

    for _, block in ipairs(code.blocks) do
        liveAtHead[block] = {}
        lat = {}
        liveAtTail[block] = lat
        -- Seed from late uses of last instruction
        lastInst = block.insts[#block.insts]
        if lastInst then
            Inst_forEach_StackSlot(lastInst, function(value, role, type, width)
                if Arg_isLateUse(role) then lat[value] = true end
            end)
        end
    end

    dirtyBlocks = {}
    for _, b in ipairs(code.blocks) do dirtyBlocks[b] = true end

    changed = null
    repeat
        changed = false
        for blockIndex = #code.blocks, 1, -1 do
            block = code.blocks[blockIndex]
            if dirtyBlocks[block] then
                dirtyBlocks[block] = null

                -- Build local liveSet starting from liveAtTail
                liveSet = {}
                for v, _ in pairs(liveAtTail[block]) do liveSet[v] = true end

                -- Run backward through instructions
                for instIndex = #block.insts, 1, -1 do
                    inst = block.insts[instIndex]

                    -- Early defs of NEXT instruction kill from liveSet
                    nextInst = block.insts[instIndex + 1]
                    if nextInst then
                        Inst_forEach_StackSlot(nextInst, function(value, role, type, width)
                            if Arg_isEarlyDef(role) then liveSet[value] = null end
                        end)
                    end

                    -- Late defs of current instruction kill from liveSet
                    Inst_forEach_StackSlot(inst, function(value, role, type, width)
                        if Arg_isLateDef(role) then liveSet[value] = null end
                    end)

                    -- Early uses of current instruction add to liveSet
                    Inst_forEach_StackSlot(inst, function(value, role, type, width)
                        if Arg_isEarlyUse(role) then liveSet[value] = true end
                    end)

                    -- Late uses of PREVIOUS instruction add to liveSet
                    prevInst = block.insts[instIndex - 1]
                    if prevInst then
                        Inst_forEach_StackSlot(prevInst, function(value, role, type, width)
                            if Arg_isLateUse(role) then liveSet[value] = true end
                        end)
                    end
                end

                -- Handle early defs of first instruction (line 69-74 in liveness.js)
                -- liveSet.remove() is never triggered per analysis, skip

                lah = liveAtHead[block]
                if mergeIntoSet(lah, liveSet) then
                    for _, pred in ipairs(block.predecessors) do
                        if mergeIntoSet(liveAtTail[pred], lah) then
                            dirtyBlocks[pred] = true
                            changed = true
                        end
                    end
                end
            end
        end
    until not changed

    return {liveAtHead=liveAtHead, liveAtTail=liveAtTail,
            localCalc=function(self, block)
                liveSet = {}
                for v, _ in pairs(self.liveAtTail[block]) do liveSet[v] = true end
                return {
                    liveSet = liveSet,
                    execute = function(lcSelf, instIndex)
                        -- instIndex is 0-based (JS convention)
                        inst = block.insts[instIndex + 1]
                        nextInst = block.insts[instIndex + 2]  -- instIndex+1+1
                        prevInst = block.insts[instIndex]      -- instIndex-1+1

                        if nextInst then
                            Inst_forEach_StackSlot(nextInst, function(value, role, type, width)
                                if Arg_isEarlyDef(role) then lcSelf.liveSet[value] = null end
                            end)
                        end
                        Inst_forEach_StackSlot(inst, function(value, role, type, width)
                            if Arg_isLateDef(role) then lcSelf.liveSet[value] = null end
                        end)
                        Inst_forEach_StackSlot(inst, function(value, role, type, width)
                            if Arg_isEarlyUse(role) then lcSelf.liveSet[value] = true end
                        end)
                        if prevInst then
                            Inst_forEach_StackSlot(prevInst, function(value, role, type, width)
                                if Arg_isLateUse(role) then lcSelf.liveSet[value] = true end
                            end)
                        end
                    end
                }
            end}
end

-- -------------------------------------------------------------------------
-- InsertionSet
-- -------------------------------------------------------------------------
function InsertionSet_new()
    return {insertions={}}
end

function InsertionSet_append(iset, index, element)
    iset.insertions[#iset.insertions+1] = {index=index, element=element}
end

function bubbleSort(arr, lessThan)
    function swap(i,j) arr[i],arr[j]=arr[j],arr[i] end
    begin_i = 1
    end_i = #arr
    while true do
        changed = false
        limit = end_i - begin_i
        for i = limit, 1, -1 do
            if lessThan(arr[begin_i+i], arr[begin_i+i-1]) then
                swap(begin_i+i, begin_i+i-1)
                changed = true
            end
        end
        if not changed then return end
        begin_i = begin_i + 1
        changed = false
        limit = end_i - begin_i
        for i = 1, limit do
            if lessThan(arr[begin_i+i], arr[begin_i+i-1]) then
                swap(begin_i+i, begin_i+i-1)
                changed = true
            end
        end
        if not changed then return end
        end_i = end_i - 1
    end
end

function InsertionSet_execute(iset, target)
    -- target is a 1-based Lua array
    -- insertion.index is 0-based (JS convention)
    bubbleSort(iset.insertions, function(a,b) return a.index < b.index end)
    numInsertions = #iset.insertions
    if numInsertions == 0 then return 0 end
    originalTargetSize = #target
    -- extend target
    for i = 1, numInsertions do target[originalTargetSize + i] = false end
    lastIndex = originalTargetSize + numInsertions  -- 1-based last index (exclusive end in JS)

    for indexInInsertions = numInsertions, 1, -1 do
        ins = iset.insertions[indexInInsertions]
        -- JS: let firstIndex = insertion.index + indexInInsertions;  (0-based)
        -- Lua 1-based: firstIndex_1 = ins.index + indexInInsertions (because indexInInsertions is already 1-based offset)
        -- Wait: in JS, indexInInsertions goes numInsertions-1 down to 0
        -- We go numInsertions down to 1, so (indexInInsertions - 1) is the JS value
        js_iii = indexInInsertions - 1  -- 0-based
        firstIndex_js = ins.index + js_iii  -- 0-based
        firstIndex_1 = firstIndex_js + 1    -- 1-based
        indexOffset = js_iii + 1            -- JS indexOffset
        -- JS: for (let i = lastIndex; --i > firstIndex;) target[i] = target[i - indexOffset]
        -- i runs from lastIndex-1 down to firstIndex+1 (exclusive) in JS 0-based
        -- In 1-based: i runs from lastIndex (which = lastIndex_js) down to firstIndex_1+1
        for i = lastIndex, firstIndex_1 + 1, -1 do
            target[i] = target[i - indexOffset]
        end
        target[firstIndex_1] = ins.element
        lastIndex = firstIndex_1
    end
    iset.insertions = {}
    return numInsertions
end

-- -------------------------------------------------------------------------
-- Utility
-- -------------------------------------------------------------------------
function rangesOverlap(leftMin, leftMax, rightMin, rightMax)
    if leftMin == leftMax then return false end
    if rightMin == rightMax then return false end
    if leftMin <= rightMin and leftMax > rightMin then return true end
    if rightMin <= leftMin and rightMax > leftMin then return true end
    return false
end

function removeAllMatching(array, pred)
    dst = 1
    for src = 1, #array do
        if not pred(array[src]) then
            array[dst] = array[src]
            dst = dst + 1
        end
    end
    while #array >= dst do array[#array] = null end
end

-- -------------------------------------------------------------------------
-- allocateStack
-- -------------------------------------------------------------------------
function allocateStack(code)
    if code.frameSize != 0 then error("Frame size already determined") end

    function roundUpToMultipleOf(amount, value)
        return math.ceil(value / amount) * amount
    end

    function attemptAssignment(slot, offsetFromFP, otherSlots)
        if offsetFromFP > 0 then error("Expect negative offset") end
        offsetFromFP = -roundUpToMultipleOf(StackSlot_alignment(slot), -offsetFromFP)
        for _, otherSlot in ipairs(otherSlots) do
            if otherSlot.offsetFromFP then
                overlap = rangesOverlap(
                    offsetFromFP, offsetFromFP + slot.byteSize,
                    otherSlot.offsetFromFP, otherSlot.offsetFromFP + otherSlot.byteSize)
                if overlap then return false end
            end
        end
        slot.offsetFromFP = offsetFromFP
        return true
    end

    function assign(slot, otherSlots)
        if attemptAssignment(slot, -slot.byteSize, otherSlots) then return end
        for _, otherSlot in ipairs(otherSlots) do
            if otherSlot.offsetFromFP then
                if attemptAssignment(slot, otherSlot.offsetFromFP - slot.byteSize, otherSlots) then
                    return
                end
            end
        end
        error("Assignment failed")
    end

    -- Partition escaped (Locked) slots
    assignedEscapedStackSlots = {}
    escapedStackSlotsWorklist = {}
    for _, slot in ipairs(code.stackSlots) do
        if slot.kind == C.Locked then
            if slot.offsetFromFP then
                assignedEscapedStackSlots[#assignedEscapedStackSlots+1] = slot
            else
                escapedStackSlotsWorklist[#escapedStackSlotsWorklist+1] = slot
            end
        else
            if slot.offsetFromFP then error("Offset already assigned") end
        end
    end

    while #escapedStackSlotsWorklist > 0 do
        slot = table.remove(escapedStackSlotsWorklist)
        assign(slot, assignedEscapedStackSlots)
        assignedEscapedStackSlots[#assignedEscapedStackSlots+1] = slot
    end

    -- Spill slot liveness / interference
    liveness = Liveness_new(code)
    interference = {}
    for _, slot in ipairs(code.stackSlots) do
        interference[slot] = {}
    end

    for _, block in ipairs(code.blocks) do
        localCalc = liveness:localCalc(block)

        function interfere(instIndex)
            -- instIndex is 0-based
            Inst_forEachDef_StackSlot(
                BasicBlock_get(block, instIndex),
                BasicBlock_get(block, instIndex + 1),
                function(slot, role, type, width)
                    if slot.kind != C.Spill then return end
                    for otherSlot, _ in pairs(localCalc.liveSet) do
                        interference[slot][otherSlot] = true
                        interference[otherSlot][slot] = true
                    end
                end)
        end

        for instIndex = #block.insts - 1, 0, -1 do
            inst = block.insts[instIndex + 1]
            if not Inst_hasNonArgEffects(inst) then
                ok = true
                Inst_forEachArg(inst, function(arg, role, type, width)
                    if Arg_isEarlyDef(role) then ok = false; return end
                    if not Arg_isLateDef(role) then return end
                    if arg.kind != C.ArgStack then ok = false; return end
                    slot = arg.slot
                    if slot.kind != C.Spill then ok = false; return end
                    if localCalc.liveSet[slot] then ok = false; return end
                end)
                if ok then Inst_clear(inst) end
            end
            interfere(instIndex)
            localCalc:execute(instIndex)
        end
        interfere(-1)

        removeAllMatching(block.insts, function(inst) return inst.opcode == C.Nop end)
    end

    -- Assign spill slots
    for _, slot in ipairs(code.stackSlots) do
        if not slot.offsetFromFP then
            others = {}
            for k, _ in pairs(interference[slot]) do others[#others+1] = k end
            -- Also include assignedEscapedStackSlots
            combined = {}
            for _, s in ipairs(assignedEscapedStackSlots) do combined[#combined+1] = s end
            for _, s in ipairs(others) do combined[#combined+1] = s end
            assign(slot, combined)
        end
    end

    -- Frame size for stack slots
    frameSizeForStackSlots = 0
    for _, slot in ipairs(code.stackSlots) do
        neg = -slot.offsetFromFP
        if neg > frameSizeForStackSlots then frameSizeForStackSlots = neg end
    end
    frameSizeForStackSlots = math.ceil(frameSizeForStackSlots / 16) * 16

    -- CallArg area
    for _, block in ipairs(code.blocks) do
        for _, inst in ipairs(block.insts) do
            for _, arg in ipairs(inst.args) do
                if arg.kind == C.ArgCallArg then
                    if arg.offset < 0 then error("Negative callArg offset") end
                    Code_requestCallArgAreaSize(code, arg.offset + 8)
                end
            end
        end
    end

    Code_setFrameSize(code, frameSizeForStackSlots + code.callArgAreaSize)

    -- Transform Stack/CallArg args to Addr
    insertionSet = InsertionSet_new()
    for _, block in ipairs(code.blocks) do
        for instIndex = 1, #block.insts do
            inst = block.insts[instIndex]
            Inst_forEachArg(inst, function(arg, role, type, width)
                if arg.kind == C.ArgStack then
                    slot = arg.slot
                    if Arg_isZDef(role) and slot.kind == C.Spill
                        and slot.byteSize > width/8 then
                        if slot.byteSize != 8 then error("Bad spill slot size for ZDef") end
                        if width != 32 then error("Bad width for ZDef") end
                        InsertionSet_append(insertionSet, instIndex,  -- 0-based = instIndex (1-based lua index)
                            Inst_new(C.StoreZero32))
                        newInst = insertionSet.insertions[#insertionSet.insertions].element
                        newInst.args[1] = Arg_createStackAddr(arg.offset + 4 + slot.offsetFromFP, code.frameSize, width)
                    end
                    return Arg_createStackAddr(arg.offset + slot.offsetFromFP, code.frameSize, width)
                else if arg.kind == C.ArgCallArg then
                    return Arg_createStackAddr(arg.offset - code.frameSize, code.frameSize, width)
                end
                return null
            end)
        end
        InsertionSet_execute(insertionSet, block.insts)
    end
end

-- -------------------------------------------------------------------------
-- Main benchmark runner
-- -------------------------------------------------------------------------
payloads = {}

function runIteration()
    for _, payload in ipairs(payloads) do
        code = payload.generate()
        hash = Code_hash(code)
        if hash != payload.earlyHash then
            error("Wrong early hash for " .. payload.name .. ": got " .. hash .. " expected " .. payload.earlyHash)
        end
        allocateStack(code)
        hash = Code_hash(code)
        if hash != payload.lateHash then
            error("Wrong late hash for " .. payload.name .. ": got " .. hash .. " expected " .. payload.lateHash)
        end
    end
    -- print("All hashes passed!")
end

function createPayloadGbemuExecuteIteration()
    code = Code_new()
    bb0 = Code_addBlock(code)
    bb1 = Code_addBlock(code)
    bb2 = Code_addBlock(code)
    bb3 = Code_addBlock(code)
    bb4 = Code_addBlock(code)
    bb5 = Code_addBlock(code)
    bb6 = Code_addBlock(code)
    bb7 = Code_addBlock(code)
    bb8 = Code_addBlock(code)
    bb9 = Code_addBlock(code)
    bb10 = Code_addBlock(code)
    bb11 = Code_addBlock(code)
    bb12 = Code_addBlock(code)
    bb13 = Code_addBlock(code)
    bb14 = Code_addBlock(code)
    bb15 = Code_addBlock(code)
    bb16 = Code_addBlock(code)
    bb17 = Code_addBlock(code)
    bb18 = Code_addBlock(code)
    bb19 = Code_addBlock(code)
    bb20 = Code_addBlock(code)
    bb21 = Code_addBlock(code)
    bb22 = Code_addBlock(code)
    bb23 = Code_addBlock(code)
    bb24 = Code_addBlock(code)
    bb25 = Code_addBlock(code)
    bb26 = Code_addBlock(code)
    bb27 = Code_addBlock(code)
    bb28 = Code_addBlock(code)
    bb29 = Code_addBlock(code)
    bb30 = Code_addBlock(code)
    bb31 = Code_addBlock(code)
    bb32 = Code_addBlock(code)
    bb33 = Code_addBlock(code)
    bb34 = Code_addBlock(code)
    bb35 = Code_addBlock(code)
    bb36 = Code_addBlock(code)
    bb37 = Code_addBlock(code)
    bb38 = Code_addBlock(code)
    bb39 = Code_addBlock(code)
    bb40 = Code_addBlock(code)
    bb41 = Code_addBlock(code)
    bb42 = Code_addBlock(code)
    slot0 = Code_addStackSlot(code, 64, C.Locked)
    slot1 = Code_addStackSlot(code, 8, C.Spill)
    slot2 = Code_addStackSlot(code, 8, C.Spill)
    slot3 = Code_addStackSlot(code, 8, C.Spill)
    slot4 = Code_addStackSlot(code, 8, C.Spill)
    slot5 = Code_addStackSlot(code, 8, C.Spill)
    slot6 = Code_addStackSlot(code, 8, C.Spill)
    slot7 = Code_addStackSlot(code, 8, C.Spill)
    slot8 = Code_addStackSlot(code, 8, C.Spill)
    slot9 = Code_addStackSlot(code, 8, C.Spill)
    slot10 = Code_addStackSlot(code, 8, C.Spill)
    slot11 = Code_addStackSlot(code, 8, C.Spill)
    slot12 = Code_addStackSlot(code, 40, C.Locked)
    StackSlot_setOffsetFromFP(slot12, -40)
    T = {}  -- temp pool table (register pressure)

    T.tmp190 = Code_newTmp(code, C.GP)
    T.tmp189 = Code_newTmp(code, C.GP)
    T.tmp188 = Code_newTmp(code, C.GP)
    T.tmp187 = Code_newTmp(code, C.GP)
    T.tmp186 = Code_newTmp(code, C.GP)
    T.tmp185 = Code_newTmp(code, C.GP)
    T.tmp184 = Code_newTmp(code, C.GP)
    T.tmp183 = Code_newTmp(code, C.GP)
    T.tmp182 = Code_newTmp(code, C.GP)
    T.tmp181 = Code_newTmp(code, C.GP)
    T.tmp180 = Code_newTmp(code, C.GP)
    T.tmp179 = Code_newTmp(code, C.GP)
    T.tmp178 = Code_newTmp(code, C.GP)
    T.tmp177 = Code_newTmp(code, C.GP)
    T.tmp176 = Code_newTmp(code, C.GP)
    T.tmp175 = Code_newTmp(code, C.GP)
    T.tmp174 = Code_newTmp(code, C.GP)
    T.tmp173 = Code_newTmp(code, C.GP)
    T.tmp172 = Code_newTmp(code, C.GP)
    T.tmp171 = Code_newTmp(code, C.GP)
    T.tmp170 = Code_newTmp(code, C.GP)
    T.tmp169 = Code_newTmp(code, C.GP)
    T.tmp168 = Code_newTmp(code, C.GP)
    T.tmp167 = Code_newTmp(code, C.GP)
    T.tmp166 = Code_newTmp(code, C.GP)
    T.tmp165 = Code_newTmp(code, C.GP)
    T.tmp164 = Code_newTmp(code, C.GP)
    T.tmp163 = Code_newTmp(code, C.GP)
    T.tmp162 = Code_newTmp(code, C.GP)
    T.tmp161 = Code_newTmp(code, C.GP)
    T.tmp160 = Code_newTmp(code, C.GP)
    T.tmp159 = Code_newTmp(code, C.GP)
    T.tmp158 = Code_newTmp(code, C.GP)
    T.tmp157 = Code_newTmp(code, C.GP)
    T.tmp156 = Code_newTmp(code, C.GP)
    T.tmp155 = Code_newTmp(code, C.GP)
    T.tmp154 = Code_newTmp(code, C.GP)
    T.tmp153 = Code_newTmp(code, C.GP)
    T.tmp152 = Code_newTmp(code, C.GP)
    T.tmp151 = Code_newTmp(code, C.GP)
    T.tmp150 = Code_newTmp(code, C.GP)
    T.tmp149 = Code_newTmp(code, C.GP)
    T.tmp148 = Code_newTmp(code, C.GP)
    T.tmp147 = Code_newTmp(code, C.GP)
    T.tmp146 = Code_newTmp(code, C.GP)
    T.tmp145 = Code_newTmp(code, C.GP)
    T.tmp144 = Code_newTmp(code, C.GP)
    T.tmp143 = Code_newTmp(code, C.GP)
    T.tmp142 = Code_newTmp(code, C.GP)
    T.tmp141 = Code_newTmp(code, C.GP)
    T.tmp140 = Code_newTmp(code, C.GP)
    T.tmp139 = Code_newTmp(code, C.GP)
    T.tmp138 = Code_newTmp(code, C.GP)
    T.tmp137 = Code_newTmp(code, C.GP)
    T.tmp136 = Code_newTmp(code, C.GP)
    T.tmp135 = Code_newTmp(code, C.GP)
    T.tmp134 = Code_newTmp(code, C.GP)
    T.tmp133 = Code_newTmp(code, C.GP)
    T.tmp132 = Code_newTmp(code, C.GP)
    T.tmp131 = Code_newTmp(code, C.GP)
    T.tmp130 = Code_newTmp(code, C.GP)
    T.tmp129 = Code_newTmp(code, C.GP)
    T.tmp128 = Code_newTmp(code, C.GP)
    T.tmp127 = Code_newTmp(code, C.GP)
    T.tmp126 = Code_newTmp(code, C.GP)
    T.tmp125 = Code_newTmp(code, C.GP)
    T.tmp124 = Code_newTmp(code, C.GP)
    T.tmp123 = Code_newTmp(code, C.GP)
    T.tmp122 = Code_newTmp(code, C.GP)
    T.tmp121 = Code_newTmp(code, C.GP)
    T.tmp120 = Code_newTmp(code, C.GP)
    T.tmp119 = Code_newTmp(code, C.GP)
    T.tmp118 = Code_newTmp(code, C.GP)
    T.tmp117 = Code_newTmp(code, C.GP)
    T.tmp116 = Code_newTmp(code, C.GP)
    T.tmp115 = Code_newTmp(code, C.GP)
    T.tmp114 = Code_newTmp(code, C.GP)
    T.tmp113 = Code_newTmp(code, C.GP)
    T.tmp112 = Code_newTmp(code, C.GP)
    T.tmp111 = Code_newTmp(code, C.GP)
    T.tmp110 = Code_newTmp(code, C.GP)
    T.tmp109 = Code_newTmp(code, C.GP)
    T.tmp108 = Code_newTmp(code, C.GP)
    T.tmp107 = Code_newTmp(code, C.GP)
    T.tmp106 = Code_newTmp(code, C.GP)
    T.tmp105 = Code_newTmp(code, C.GP)
    T.tmp104 = Code_newTmp(code, C.GP)
    T.tmp103 = Code_newTmp(code, C.GP)
    T.tmp102 = Code_newTmp(code, C.GP)
    T.tmp101 = Code_newTmp(code, C.GP)
    T.tmp100 = Code_newTmp(code, C.GP)
    T.tmp99 = Code_newTmp(code, C.GP)
    T.tmp98 = Code_newTmp(code, C.GP)
    T.tmp97 = Code_newTmp(code, C.GP)
    T.tmp96 = Code_newTmp(code, C.GP)
    T.tmp95 = Code_newTmp(code, C.GP)
    T.tmp94 = Code_newTmp(code, C.GP)
    T.tmp93 = Code_newTmp(code, C.GP)
    T.tmp92 = Code_newTmp(code, C.GP)
    T.tmp91 = Code_newTmp(code, C.GP)
    T.tmp90 = Code_newTmp(code, C.GP)
    T.tmp89 = Code_newTmp(code, C.GP)
    T.tmp88 = Code_newTmp(code, C.GP)
    T.tmp87 = Code_newTmp(code, C.GP)
    T.tmp86 = Code_newTmp(code, C.GP)
    T.tmp85 = Code_newTmp(code, C.GP)
    T.tmp84 = Code_newTmp(code, C.GP)
    T.tmp83 = Code_newTmp(code, C.GP)
    T.tmp82 = Code_newTmp(code, C.GP)
    T.tmp81 = Code_newTmp(code, C.GP)
    T.tmp80 = Code_newTmp(code, C.GP)
    T.tmp79 = Code_newTmp(code, C.GP)
    T.tmp78 = Code_newTmp(code, C.GP)
    T.tmp77 = Code_newTmp(code, C.GP)
    T.tmp76 = Code_newTmp(code, C.GP)
    T.tmp75 = Code_newTmp(code, C.GP)
    T.tmp74 = Code_newTmp(code, C.GP)
    T.tmp73 = Code_newTmp(code, C.GP)
    T.tmp72 = Code_newTmp(code, C.GP)
    T.tmp71 = Code_newTmp(code, C.GP)
    T.tmp70 = Code_newTmp(code, C.GP)
    T.tmp69 = Code_newTmp(code, C.GP)
    T.tmp68 = Code_newTmp(code, C.GP)
    T.tmp67 = Code_newTmp(code, C.GP)
    T.tmp66 = Code_newTmp(code, C.GP)
    T.tmp65 = Code_newTmp(code, C.GP)
    T.tmp64 = Code_newTmp(code, C.GP)
    T.tmp63 = Code_newTmp(code, C.GP)
    T.tmp62 = Code_newTmp(code, C.GP)
    T.tmp61 = Code_newTmp(code, C.GP)
    T.tmp60 = Code_newTmp(code, C.GP)
    T.tmp59 = Code_newTmp(code, C.GP)
    T.tmp58 = Code_newTmp(code, C.GP)
    T.tmp57 = Code_newTmp(code, C.GP)
    T.tmp56 = Code_newTmp(code, C.GP)
    T.tmp55 = Code_newTmp(code, C.GP)
    T.tmp54 = Code_newTmp(code, C.GP)
    T.tmp53 = Code_newTmp(code, C.GP)
    T.tmp52 = Code_newTmp(code, C.GP)
    T.tmp51 = Code_newTmp(code, C.GP)
    T.tmp50 = Code_newTmp(code, C.GP)
    T.tmp49 = Code_newTmp(code, C.GP)
    T.tmp48 = Code_newTmp(code, C.GP)
    T.tmp47 = Code_newTmp(code, C.GP)
    T.tmp46 = Code_newTmp(code, C.GP)
    T.tmp45 = Code_newTmp(code, C.GP)
    T.tmp44 = Code_newTmp(code, C.GP)
    T.tmp43 = Code_newTmp(code, C.GP)
    T.tmp42 = Code_newTmp(code, C.GP)
    T.tmp41 = Code_newTmp(code, C.GP)
    T.tmp40 = Code_newTmp(code, C.GP)
    T.tmp39 = Code_newTmp(code, C.GP)
    T.tmp38 = Code_newTmp(code, C.GP)
    T.tmp37 = Code_newTmp(code, C.GP)
    T.tmp36 = Code_newTmp(code, C.GP)
    T.tmp35 = Code_newTmp(code, C.GP)
    T.tmp34 = Code_newTmp(code, C.GP)
    T.tmp33 = Code_newTmp(code, C.GP)
    T.tmp32 = Code_newTmp(code, C.GP)
    T.tmp31 = Code_newTmp(code, C.GP)
    T.tmp30 = Code_newTmp(code, C.GP)
    T.tmp29 = Code_newTmp(code, C.GP)
    T.tmp28 = Code_newTmp(code, C.GP)
    T.tmp27 = Code_newTmp(code, C.GP)
    T.tmp26 = Code_newTmp(code, C.GP)
    T.tmp25 = Code_newTmp(code, C.GP)
    T.tmp24 = Code_newTmp(code, C.GP)
    T.tmp23 = Code_newTmp(code, C.GP)
    T.tmp22 = Code_newTmp(code, C.GP)
    T.tmp21 = Code_newTmp(code, C.GP)
    T.tmp20 = Code_newTmp(code, C.GP)
    T.tmp19 = Code_newTmp(code, C.GP)
    T.tmp18 = Code_newTmp(code, C.GP)
    T.tmp17 = Code_newTmp(code, C.GP)
    T.tmp16 = Code_newTmp(code, C.GP)
    T.tmp15 = Code_newTmp(code, C.GP)
    T.tmp14 = Code_newTmp(code, C.GP)
    T.tmp13 = Code_newTmp(code, C.GP)
    T.tmp12 = Code_newTmp(code, C.GP)
    T.tmp11 = Code_newTmp(code, C.GP)
    T.tmp10 = Code_newTmp(code, C.GP)
    T.tmp9 = Code_newTmp(code, C.GP)
    T.tmp8 = Code_newTmp(code, C.GP)
    T.tmp7 = Code_newTmp(code, C.GP)
    T.tmp6 = Code_newTmp(code, C.GP)
    T.tmp5 = Code_newTmp(code, C.GP)
    T.tmp4 = Code_newTmp(code, C.GP)
    T.tmp3 = Code_newTmp(code, C.GP)
    T.tmp2 = Code_newTmp(code, C.GP)
    T.tmp1 = Code_newTmp(code, C.GP)
    T.tmp0 = Code_newTmp(code, C.GP)
    T.ftmp7 = Code_newTmp(code, C.FP)
    T.ftmp6 = Code_newTmp(code, C.FP)
    T.ftmp5 = Code_newTmp(code, C.FP)
    T.ftmp4 = Code_newTmp(code, C.FP)
    T.ftmp3 = Code_newTmp(code, C.FP)
    T.ftmp2 = Code_newTmp(code, C.FP)
    T.ftmp1 = Code_newTmp(code, C.FP)
    T.ftmp0 = Code_newTmp(code, C.FP)
    inst = null
    arg = null
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb2, C.Normal)
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb1, C.Normal)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286904960, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Scratch, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(2, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(21)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_rbx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286506544, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot10, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286455168, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot4, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287131344, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot6, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot3, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286474592, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot2, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287209728, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot11, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287112728, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, 65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot9, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287112720, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286506192, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot7, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(862)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    bb1.successors[#bb1.successors+1] = FrequentedBlock_new(bb41, C.Normal)
    bb1.successors[#bb1.successors+1] = FrequentedBlock_new(bb3, C.Normal)
    bb1.predecessors[#bb1.predecessors+1] = bb0
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(881)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    bb2.successors[#bb2.successors+1] = FrequentedBlock_new(bb41, C.Normal)
    bb2.successors[#bb2.successors+1] = FrequentedBlock_new(bb3, C.Normal)
    bb2.predecessors[#bb2.predecessors+1] = bb0
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb2, inst)
    bb3.successors[#bb3.successors+1] = FrequentedBlock_new(bb5, C.Normal)
    bb3.successors[#bb3.successors+1] = FrequentedBlock_new(bb4, C.Normal)
    bb3.predecessors[#bb3.predecessors+1] = bb1
    bb3.predecessors[#bb3.predecessors+1] = bb40
    bb3.predecessors[#bb3.predecessors+1] = bb39
    bb3.predecessors[#bb3.predecessors+1] = bb2
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1144)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb6, C.Normal)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb7, C.Normal)
    bb4.predecessors[#bb4.predecessors+1] = bb3
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    bb5.successors[#bb5.successors+1] = FrequentedBlock_new(bb6, C.Normal)
    bb5.predecessors[#bb5.predecessors+1] = bb3
    inst = Inst_new(C.Move)
    arg = Arg_createImm(7)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 232)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 256)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 248)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.And32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.And32)
    arg = Arg_createImm(31)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 240)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb5, inst)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb7, C.Normal)
    bb6.predecessors[#bb6.predecessors+1] = bb4
    bb6.predecessors[#bb6.predecessors+1] = bb5
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1144)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb6, inst)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb9, C.Normal)
    bb7.predecessors[#bb7.predecessors+1] = bb4
    bb7.predecessors[#bb7.predecessors+1] = bb6
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 240)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb9, C.Normal)
    bb8.predecessors[#bb8.predecessors+1] = bb7
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286455168, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286455168, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb8, inst)
    bb9.successors[#bb9.successors+1] = FrequentedBlock_new(bb12, C.Normal)
    bb9.successors[#bb9.successors+1] = FrequentedBlock_new(bb10, C.Normal)
    bb9.predecessors[#bb9.predecessors+1] = bb7
    bb9.predecessors[#bb9.predecessors+1] = bb8
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 304)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 128)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(80)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r8, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_rax, Reg_rsi, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(23)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot7, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    bb10.successors[#bb10.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb10.successors[#bb10.successors+1] = FrequentedBlock_new(bb13, C.Normal)
    bb10.predecessors[#bb10.predecessors+1] = bb9
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot10, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    bb11.successors[#bb11.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb11.predecessors[#bb11.predecessors+1] = bb10
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 344)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(502)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Load8)
    arg = Arg_createIndex(Reg_rsi, Reg_rax, 1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb11, inst)
    bb12.successors[#bb12.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb12.predecessors[#bb12.predecessors+1] = bb9
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 336)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 456)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(502)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Load8)
    arg = Arg_createIndex(Reg_rsi, Reg_rax, 1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb12, inst)
    bb13.predecessors[#bb13.predecessors+1] = bb10
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb13, inst)
    bb14.successors[#bb14.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    bb14.successors[#bb14.successors+1] = FrequentedBlock_new(bb16, C.Normal)
    bb14.predecessors[#bb14.predecessors+1] = bb11
    bb14.predecessors[#bb14.predecessors+1] = bb12
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.ZeroExtend16To32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 128)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 216)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    bb15.predecessors[#bb15.predecessors+1] = bb14
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb15, inst)
    bb16.successors[#bb16.successors+1] = FrequentedBlock_new(bb18, C.Normal)
    bb16.successors[#bb16.successors+1] = FrequentedBlock_new(bb17, C.Normal)
    bb16.predecessors[#bb16.predecessors+1] = bb14
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, -1752)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdx, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Load8)
    arg = Arg_createIndex(Reg_rax, Reg_rcx, 1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 272)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287112720, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(80)
    inst.args[#inst.args+1] = arg
    arg = Arg_createBigImm(287112720, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287112728, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_rax, Reg_rcx, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287112720, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, -1088)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 272)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 280)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Rshift32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdx, -1088)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, -88)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, -1176)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(80)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_rax, Reg_rdx, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(23)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 272)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 280)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Rshift32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1048)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1048)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1072)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    bb17.successors[#bb17.successors+1] = FrequentedBlock_new(bb19, C.Normal)
    bb17.predecessors[#bb17.predecessors+1] = bb16
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb17, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb17, inst)
    bb18.successors[#bb18.successors+1] = FrequentedBlock_new(bb19, C.Normal)
    bb18.predecessors[#bb18.predecessors+1] = bb16
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb18, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb18, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb18, inst)
    bb19.successors[#bb19.successors+1] = FrequentedBlock_new(bb20, C.Normal)
    bb19.successors[#bb19.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb19.predecessors[#bb19.predecessors+1] = bb17
    bb19.predecessors[#bb19.predecessors+1] = bb18
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.AddDouble)
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.MoveDoubleTo64)
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, 65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1072)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1080)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1080)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1104)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    bb20.successors[#bb20.successors+1] = FrequentedBlock_new(bb21, C.Normal)
    bb20.successors[#bb20.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb20.predecessors[#bb20.predecessors+1] = bb19
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1096)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1096)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1112)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    bb21.successors[#bb21.successors+1] = FrequentedBlock_new(bb23, C.Normal)
    bb21.predecessors[#bb21.predecessors+1] = bb20
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 344)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r12, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(502)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r12, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_r12, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.BelowOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(65286)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 232)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 256)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb21, inst)
    bb22.successors[#bb22.successors+1] = FrequentedBlock_new(bb23, C.Normal)
    bb22.predecessors[#bb22.predecessors+1] = bb30
    bb22.predecessors[#bb22.predecessors+1] = bb31
    bb22.predecessors[#bb22.predecessors+1] = bb29
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb22, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb22, inst)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb25, C.Normal)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb24, C.Normal)
    bb23.predecessors[#bb23.predecessors+1] = bb21
    bb23.predecessors[#bb23.predecessors+1] = bb22
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rsi, -1096)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Load8)
    arg = Arg_createAddr(Reg_rdi, 65285)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.BelowOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(65285)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    bb24.successors[#bb24.successors+1] = FrequentedBlock_new(bb26, C.Normal)
    bb24.successors[#bb24.successors+1] = FrequentedBlock_new(bb30, C.Normal)
    bb24.predecessors[#bb24.predecessors+1] = bb23
    inst = Inst_new(C.Store8)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 65285)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(256)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    bb25.successors[#bb25.successors+1] = FrequentedBlock_new(bb26, C.Normal)
    bb25.successors[#bb25.successors+1] = FrequentedBlock_new(bb30, C.Normal)
    bb25.predecessors[#bb25.predecessors+1] = bb23
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(256)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb25, inst)
    bb26.successors[#bb26.successors+1] = FrequentedBlock_new(bb28, C.Normal)
    bb26.successors[#bb26.successors+1] = FrequentedBlock_new(bb27, C.Normal)
    bb26.predecessors[#bb26.predecessors+1] = bb24
    bb26.predecessors[#bb26.predecessors+1] = bb25
    inst = Inst_new(C.Load8)
    arg = Arg_createAddr(Reg_rdi, 65286)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb26, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.BelowOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(65285)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb26, inst)
    bb27.successors[#bb27.successors+1] = FrequentedBlock_new(bb28, C.Normal)
    bb27.predecessors[#bb27.predecessors+1] = bb26
    inst = Inst_new(C.Store8)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 65285)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb27, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb27, inst)
    bb28.successors[#bb28.successors+1] = FrequentedBlock_new(bb29, C.Normal)
    bb28.successors[#bb28.successors+1] = FrequentedBlock_new(bb31, C.Normal)
    bb28.predecessors[#bb28.predecessors+1] = bb26
    bb28.predecessors[#bb28.predecessors+1] = bb27
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 248)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.Or32)
    arg = Arg_createImm(4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 248)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb28, inst)
    bb29.successors[#bb29.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb29.successors[#bb29.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb29.predecessors[#bb29.predecessors+1] = bb28
    inst = Inst_new(C.And32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb29, inst)
    inst = Inst_new(C.And32)
    arg = Arg_createImm(31)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb29, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb29, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 240)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb29, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb29, inst)
    bb30.successors[#bb30.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb30.successors[#bb30.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb30.predecessors[#bb30.predecessors+1] = bb24
    bb30.predecessors[#bb30.predecessors+1] = bb25
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb30, inst)
    bb31.successors[#bb31.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb31.successors[#bb31.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb31.predecessors[#bb31.predecessors+1] = bb28
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb31, inst)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb33, C.Normal)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb34, C.Normal)
    bb32.predecessors[#bb32.predecessors+1] = bb19
    bb32.predecessors[#bb32.predecessors+1] = bb20
    bb32.predecessors[#bb32.predecessors+1] = bb30
    bb32.predecessors[#bb32.predecessors+1] = bb31
    bb32.predecessors[#bb32.predecessors+1] = bb29
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rsi, -1120)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    bb33.predecessors[#bb33.predecessors+1] = bb32
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb33, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb33, inst)
    bb34.successors[#bb34.successors+1] = FrequentedBlock_new(bb36, C.Normal)
    bb34.successors[#bb34.successors+1] = FrequentedBlock_new(bb35, C.Normal)
    bb34.predecessors[#bb34.predecessors+1] = bb32
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 136)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    bb35.successors[#bb35.successors+1] = FrequentedBlock_new(bb37, C.Normal)
    bb35.successors[#bb35.successors+1] = FrequentedBlock_new(bb38, C.Normal)
    bb35.predecessors[#bb35.predecessors+1] = bb34
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb35, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(C.DoubleGreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb35, inst)
    bb36.successors[#bb36.successors+1] = FrequentedBlock_new(bb37, C.Normal)
    bb36.successors[#bb36.successors+1] = FrequentedBlock_new(bb38, C.Normal)
    bb36.predecessors[#bb36.predecessors+1] = bb34
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb36, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb36, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(C.DoubleGreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb36, inst)
    bb37.successors[#bb37.successors+1] = FrequentedBlock_new(bb38, C.Normal)
    bb37.predecessors[#bb37.predecessors+1] = bb35
    bb37.predecessors[#bb37.predecessors+1] = bb36
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286474592, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286474592, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb37, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb37, inst)
    bb38.successors[#bb38.successors+1] = FrequentedBlock_new(bb39, C.Normal)
    bb38.successors[#bb38.successors+1] = FrequentedBlock_new(bb40, C.Normal)
    bb38.predecessors[#bb38.predecessors+1] = bb35
    bb38.predecessors[#bb38.predecessors+1] = bb37
    bb38.predecessors[#bb38.predecessors+1] = bb36
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(881)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, -1824)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdx, -1824)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdx, -1832)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb38, inst)
    bb39.successors[#bb39.successors+1] = FrequentedBlock_new(bb42, C.Normal)
    bb39.successors[#bb39.successors+1] = FrequentedBlock_new(bb3, C.Normal)
    bb39.predecessors[#bb39.predecessors+1] = bb38
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286474592, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(286474592, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Or32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287131344, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287131344, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(287209728, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb39, inst)
    bb40.successors[#bb40.successors+1] = FrequentedBlock_new(bb42, C.Normal)
    bb40.successors[#bb40.successors+1] = FrequentedBlock_new(bb3, C.Normal)
    bb40.predecessors[#bb40.predecessors+1] = bb38
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 224)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb40, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb40, inst)
    bb41.predecessors[#bb41.predecessors+1] = bb1
    bb41.predecessors[#bb41.predecessors+1] = bb2
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb41, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb41, inst)
    bb42.predecessors[#bb42.predecessors+1] = bb40
    bb42.predecessors[#bb42.predecessors+1] = bb39
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb42, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb42, inst)
    return code
end


function createPayloadImagingGaussianBlurGaussianBlur()
    code = Code_new()
    bb0 = Code_addBlock(code)
    bb1 = Code_addBlock(code)
    bb2 = Code_addBlock(code)
    bb3 = Code_addBlock(code)
    bb4 = Code_addBlock(code)
    bb5 = Code_addBlock(code)
    bb6 = Code_addBlock(code)
    bb7 = Code_addBlock(code)
    bb8 = Code_addBlock(code)
    bb9 = Code_addBlock(code)
    bb10 = Code_addBlock(code)
    bb11 = Code_addBlock(code)
    bb12 = Code_addBlock(code)
    bb13 = Code_addBlock(code)
    bb14 = Code_addBlock(code)
    bb15 = Code_addBlock(code)
    bb16 = Code_addBlock(code)
    bb17 = Code_addBlock(code)
    bb18 = Code_addBlock(code)
    bb19 = Code_addBlock(code)
    bb20 = Code_addBlock(code)
    bb21 = Code_addBlock(code)
    bb22 = Code_addBlock(code)
    bb23 = Code_addBlock(code)
    bb24 = Code_addBlock(code)
    bb25 = Code_addBlock(code)
    bb26 = Code_addBlock(code)
    bb27 = Code_addBlock(code)
    bb28 = Code_addBlock(code)
    bb29 = Code_addBlock(code)
    bb30 = Code_addBlock(code)
    bb31 = Code_addBlock(code)
    bb32 = Code_addBlock(code)
    bb33 = Code_addBlock(code)
    bb34 = Code_addBlock(code)
    bb35 = Code_addBlock(code)
    bb36 = Code_addBlock(code)
    slot0 = Code_addStackSlot(code, 40, C.Locked)
    slot1 = Code_addStackSlot(code, 8, C.Spill)
    slot2 = Code_addStackSlot(code, 8, C.Spill)
    slot3 = Code_addStackSlot(code, 4, C.Spill)
    slot4 = Code_addStackSlot(code, 8, C.Spill)
    slot5 = Code_addStackSlot(code, 8, C.Spill)
    slot6 = Code_addStackSlot(code, 40, C.Locked)
    StackSlot_setOffsetFromFP(slot6, -40)
    T = {}  -- temp pool table (register pressure)

    T.tmp141 = Code_newTmp(code, C.GP)
    T.tmp140 = Code_newTmp(code, C.GP)
    T.tmp139 = Code_newTmp(code, C.GP)
    T.tmp138 = Code_newTmp(code, C.GP)
    T.tmp137 = Code_newTmp(code, C.GP)
    T.tmp136 = Code_newTmp(code, C.GP)
    T.tmp135 = Code_newTmp(code, C.GP)
    T.tmp134 = Code_newTmp(code, C.GP)
    T.tmp133 = Code_newTmp(code, C.GP)
    T.tmp132 = Code_newTmp(code, C.GP)
    T.tmp131 = Code_newTmp(code, C.GP)
    T.tmp130 = Code_newTmp(code, C.GP)
    T.tmp129 = Code_newTmp(code, C.GP)
    T.tmp128 = Code_newTmp(code, C.GP)
    T.tmp127 = Code_newTmp(code, C.GP)
    T.tmp126 = Code_newTmp(code, C.GP)
    T.tmp125 = Code_newTmp(code, C.GP)
    T.tmp124 = Code_newTmp(code, C.GP)
    T.tmp123 = Code_newTmp(code, C.GP)
    T.tmp122 = Code_newTmp(code, C.GP)
    T.tmp121 = Code_newTmp(code, C.GP)
    T.tmp120 = Code_newTmp(code, C.GP)
    T.tmp119 = Code_newTmp(code, C.GP)
    T.tmp118 = Code_newTmp(code, C.GP)
    T.tmp117 = Code_newTmp(code, C.GP)
    T.tmp116 = Code_newTmp(code, C.GP)
    T.tmp115 = Code_newTmp(code, C.GP)
    T.tmp114 = Code_newTmp(code, C.GP)
    T.tmp113 = Code_newTmp(code, C.GP)
    T.tmp112 = Code_newTmp(code, C.GP)
    T.tmp111 = Code_newTmp(code, C.GP)
    T.tmp110 = Code_newTmp(code, C.GP)
    T.tmp109 = Code_newTmp(code, C.GP)
    T.tmp108 = Code_newTmp(code, C.GP)
    T.tmp107 = Code_newTmp(code, C.GP)
    T.tmp106 = Code_newTmp(code, C.GP)
    T.tmp105 = Code_newTmp(code, C.GP)
    T.tmp104 = Code_newTmp(code, C.GP)
    T.tmp103 = Code_newTmp(code, C.GP)
    T.tmp102 = Code_newTmp(code, C.GP)
    T.tmp101 = Code_newTmp(code, C.GP)
    T.tmp100 = Code_newTmp(code, C.GP)
    T.tmp99 = Code_newTmp(code, C.GP)
    T.tmp98 = Code_newTmp(code, C.GP)
    T.tmp97 = Code_newTmp(code, C.GP)
    T.tmp96 = Code_newTmp(code, C.GP)
    T.tmp95 = Code_newTmp(code, C.GP)
    T.tmp94 = Code_newTmp(code, C.GP)
    T.tmp93 = Code_newTmp(code, C.GP)
    T.tmp92 = Code_newTmp(code, C.GP)
    T.tmp91 = Code_newTmp(code, C.GP)
    T.tmp90 = Code_newTmp(code, C.GP)
    T.tmp89 = Code_newTmp(code, C.GP)
    T.tmp88 = Code_newTmp(code, C.GP)
    T.tmp87 = Code_newTmp(code, C.GP)
    T.tmp86 = Code_newTmp(code, C.GP)
    T.tmp85 = Code_newTmp(code, C.GP)
    T.tmp84 = Code_newTmp(code, C.GP)
    T.tmp83 = Code_newTmp(code, C.GP)
    T.tmp82 = Code_newTmp(code, C.GP)
    T.tmp81 = Code_newTmp(code, C.GP)
    T.tmp80 = Code_newTmp(code, C.GP)
    T.tmp79 = Code_newTmp(code, C.GP)
    T.tmp78 = Code_newTmp(code, C.GP)
    T.tmp77 = Code_newTmp(code, C.GP)
    T.tmp76 = Code_newTmp(code, C.GP)
    T.tmp75 = Code_newTmp(code, C.GP)
    T.tmp74 = Code_newTmp(code, C.GP)
    T.tmp73 = Code_newTmp(code, C.GP)
    T.tmp72 = Code_newTmp(code, C.GP)
    T.tmp71 = Code_newTmp(code, C.GP)
    T.tmp70 = Code_newTmp(code, C.GP)
    T.tmp69 = Code_newTmp(code, C.GP)
    T.tmp68 = Code_newTmp(code, C.GP)
    T.tmp67 = Code_newTmp(code, C.GP)
    T.tmp66 = Code_newTmp(code, C.GP)
    T.tmp65 = Code_newTmp(code, C.GP)
    T.tmp64 = Code_newTmp(code, C.GP)
    T.tmp63 = Code_newTmp(code, C.GP)
    T.tmp62 = Code_newTmp(code, C.GP)
    T.tmp61 = Code_newTmp(code, C.GP)
    T.tmp60 = Code_newTmp(code, C.GP)
    T.tmp59 = Code_newTmp(code, C.GP)
    T.tmp58 = Code_newTmp(code, C.GP)
    T.tmp57 = Code_newTmp(code, C.GP)
    T.tmp56 = Code_newTmp(code, C.GP)
    T.tmp55 = Code_newTmp(code, C.GP)
    T.tmp54 = Code_newTmp(code, C.GP)
    T.tmp53 = Code_newTmp(code, C.GP)
    T.tmp52 = Code_newTmp(code, C.GP)
    T.tmp51 = Code_newTmp(code, C.GP)
    T.tmp50 = Code_newTmp(code, C.GP)
    T.tmp49 = Code_newTmp(code, C.GP)
    T.tmp48 = Code_newTmp(code, C.GP)
    T.tmp47 = Code_newTmp(code, C.GP)
    T.tmp46 = Code_newTmp(code, C.GP)
    T.tmp45 = Code_newTmp(code, C.GP)
    T.tmp44 = Code_newTmp(code, C.GP)
    T.tmp43 = Code_newTmp(code, C.GP)
    T.tmp42 = Code_newTmp(code, C.GP)
    T.tmp41 = Code_newTmp(code, C.GP)
    T.tmp40 = Code_newTmp(code, C.GP)
    T.tmp39 = Code_newTmp(code, C.GP)
    T.tmp38 = Code_newTmp(code, C.GP)
    T.tmp37 = Code_newTmp(code, C.GP)
    T.tmp36 = Code_newTmp(code, C.GP)
    T.tmp35 = Code_newTmp(code, C.GP)
    T.tmp34 = Code_newTmp(code, C.GP)
    T.tmp33 = Code_newTmp(code, C.GP)
    T.tmp32 = Code_newTmp(code, C.GP)
    T.tmp31 = Code_newTmp(code, C.GP)
    T.tmp30 = Code_newTmp(code, C.GP)
    T.tmp29 = Code_newTmp(code, C.GP)
    T.tmp28 = Code_newTmp(code, C.GP)
    T.tmp27 = Code_newTmp(code, C.GP)
    T.tmp26 = Code_newTmp(code, C.GP)
    T.tmp25 = Code_newTmp(code, C.GP)
    T.tmp24 = Code_newTmp(code, C.GP)
    T.tmp23 = Code_newTmp(code, C.GP)
    T.tmp22 = Code_newTmp(code, C.GP)
    T.tmp21 = Code_newTmp(code, C.GP)
    T.tmp20 = Code_newTmp(code, C.GP)
    T.tmp19 = Code_newTmp(code, C.GP)
    T.tmp18 = Code_newTmp(code, C.GP)
    T.tmp17 = Code_newTmp(code, C.GP)
    T.tmp16 = Code_newTmp(code, C.GP)
    T.tmp15 = Code_newTmp(code, C.GP)
    T.tmp14 = Code_newTmp(code, C.GP)
    T.tmp13 = Code_newTmp(code, C.GP)
    T.tmp12 = Code_newTmp(code, C.GP)
    T.tmp11 = Code_newTmp(code, C.GP)
    T.tmp10 = Code_newTmp(code, C.GP)
    T.tmp9 = Code_newTmp(code, C.GP)
    T.tmp8 = Code_newTmp(code, C.GP)
    T.tmp7 = Code_newTmp(code, C.GP)
    T.tmp6 = Code_newTmp(code, C.GP)
    T.tmp5 = Code_newTmp(code, C.GP)
    T.tmp4 = Code_newTmp(code, C.GP)
    T.tmp3 = Code_newTmp(code, C.GP)
    T.tmp2 = Code_newTmp(code, C.GP)
    T.tmp1 = Code_newTmp(code, C.GP)
    T.tmp0 = Code_newTmp(code, C.GP)
    T.ftmp74 = Code_newTmp(code, C.FP)
    T.ftmp73 = Code_newTmp(code, C.FP)
    T.ftmp72 = Code_newTmp(code, C.FP)
    T.ftmp71 = Code_newTmp(code, C.FP)
    T.ftmp70 = Code_newTmp(code, C.FP)
    T.ftmp69 = Code_newTmp(code, C.FP)
    T.ftmp68 = Code_newTmp(code, C.FP)
    T.ftmp67 = Code_newTmp(code, C.FP)
    T.ftmp66 = Code_newTmp(code, C.FP)
    T.ftmp65 = Code_newTmp(code, C.FP)
    T.ftmp64 = Code_newTmp(code, C.FP)
    T.ftmp63 = Code_newTmp(code, C.FP)
    T.ftmp62 = Code_newTmp(code, C.FP)
    T.ftmp61 = Code_newTmp(code, C.FP)
    T.ftmp60 = Code_newTmp(code, C.FP)
    T.ftmp59 = Code_newTmp(code, C.FP)
    T.ftmp58 = Code_newTmp(code, C.FP)
    T.ftmp57 = Code_newTmp(code, C.FP)
    T.ftmp56 = Code_newTmp(code, C.FP)
    T.ftmp55 = Code_newTmp(code, C.FP)
    T.ftmp54 = Code_newTmp(code, C.FP)
    T.ftmp53 = Code_newTmp(code, C.FP)
    T.ftmp52 = Code_newTmp(code, C.FP)
    T.ftmp51 = Code_newTmp(code, C.FP)
    T.ftmp50 = Code_newTmp(code, C.FP)
    T.ftmp49 = Code_newTmp(code, C.FP)
    T.ftmp48 = Code_newTmp(code, C.FP)
    T.ftmp47 = Code_newTmp(code, C.FP)
    T.ftmp46 = Code_newTmp(code, C.FP)
    T.ftmp45 = Code_newTmp(code, C.FP)
    T.ftmp44 = Code_newTmp(code, C.FP)
    T.ftmp43 = Code_newTmp(code, C.FP)
    T.ftmp42 = Code_newTmp(code, C.FP)
    T.ftmp41 = Code_newTmp(code, C.FP)
    T.ftmp40 = Code_newTmp(code, C.FP)
    T.ftmp39 = Code_newTmp(code, C.FP)
    T.ftmp38 = Code_newTmp(code, C.FP)
    T.ftmp37 = Code_newTmp(code, C.FP)
    T.ftmp36 = Code_newTmp(code, C.FP)
    T.ftmp35 = Code_newTmp(code, C.FP)
    T.ftmp34 = Code_newTmp(code, C.FP)
    T.ftmp33 = Code_newTmp(code, C.FP)
    T.ftmp32 = Code_newTmp(code, C.FP)
    T.ftmp31 = Code_newTmp(code, C.FP)
    T.ftmp30 = Code_newTmp(code, C.FP)
    T.ftmp29 = Code_newTmp(code, C.FP)
    T.ftmp28 = Code_newTmp(code, C.FP)
    T.ftmp27 = Code_newTmp(code, C.FP)
    T.ftmp26 = Code_newTmp(code, C.FP)
    T.ftmp25 = Code_newTmp(code, C.FP)
    T.ftmp24 = Code_newTmp(code, C.FP)
    T.ftmp23 = Code_newTmp(code, C.FP)
    T.ftmp22 = Code_newTmp(code, C.FP)
    T.ftmp21 = Code_newTmp(code, C.FP)
    T.ftmp20 = Code_newTmp(code, C.FP)
    T.ftmp19 = Code_newTmp(code, C.FP)
    T.ftmp18 = Code_newTmp(code, C.FP)
    T.ftmp17 = Code_newTmp(code, C.FP)
    T.ftmp16 = Code_newTmp(code, C.FP)
    T.ftmp15 = Code_newTmp(code, C.FP)
    T.ftmp14 = Code_newTmp(code, C.FP)
    T.ftmp13 = Code_newTmp(code, C.FP)
    T.ftmp12 = Code_newTmp(code, C.FP)
    T.ftmp11 = Code_newTmp(code, C.FP)
    T.ftmp10 = Code_newTmp(code, C.FP)
    T.ftmp9 = Code_newTmp(code, C.FP)
    T.ftmp8 = Code_newTmp(code, C.FP)
    T.ftmp7 = Code_newTmp(code, C.FP)
    T.ftmp6 = Code_newTmp(code, C.FP)
    T.ftmp5 = Code_newTmp(code, C.FP)
    T.ftmp4 = Code_newTmp(code, C.FP)
    T.ftmp3 = Code_newTmp(code, C.FP)
    T.ftmp2 = Code_newTmp(code, C.FP)
    T.ftmp1 = Code_newTmp(code, C.FP)
    T.ftmp0 = Code_newTmp(code, C.FP)
    inst = null
    arg = null
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb2, C.Normal)
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb1, C.Rare)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(144305904, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Scratch, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547168, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547184, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547192, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547200, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547208, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547216, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547224, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547232, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(142547240, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(DoubleEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    bb1.successors[#bb1.successors+1] = FrequentedBlock_new(bb2, C.Normal)
    bb1.predecessors[#bb1.predecessors+1] = bb0
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb1, inst)
    bb2.successors[#bb2.successors+1] = FrequentedBlock_new(bb4, C.Normal)
    bb2.successors[#bb2.successors+1] = FrequentedBlock_new(bb3, C.Rare)
    bb2.predecessors[#bb2.predecessors+1] = bb0
    bb2.predecessors[#bb2.predecessors+1] = bb1
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(DoubleEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb2, inst)
    bb3.successors[#bb3.successors+1] = FrequentedBlock_new(bb4, C.Normal)
    bb3.predecessors[#bb3.predecessors+1] = bb2
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb3, inst)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb6, C.Normal)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb5, C.Rare)
    bb4.predecessors[#bb4.predecessors+1] = bb2
    bb4.predecessors[#bb4.predecessors+1] = bb3
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(DoubleEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    bb5.successors[#bb5.successors+1] = FrequentedBlock_new(bb6, C.Normal)
    bb5.predecessors[#bb5.predecessors+1] = bb4
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb5, inst)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb7, C.Rare)
    bb6.predecessors[#bb6.predecessors+1] = bb4
    bb6.predecessors[#bb6.predecessors+1] = bb5
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(DoubleEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb7.predecessors[#bb7.predecessors+1] = bb6
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb7, inst)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb10, C.Normal)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb9, C.Rare)
    bb8.predecessors[#bb8.predecessors+1] = bb6
    bb8.predecessors[#bb8.predecessors+1] = bb7
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(117076488, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Move64ToDouble)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.BranchDouble)
    arg = Arg_createDoubleCond(DoubleEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    bb9.successors[#bb9.successors+1] = FrequentedBlock_new(bb10, C.Normal)
    bb9.predecessors[#bb9.predecessors+1] = bb8
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.ConvertInt32ToDouble)
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb9, inst)
    bb10.successors[#bb10.successors+1] = FrequentedBlock_new(bb18, C.Normal)
    bb10.predecessors[#bb10.predecessors+1] = bb8
    bb10.predecessors[#bb10.predecessors+1] = bb9
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(144506584, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_r9, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(144506544, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(80)
    inst.args[#inst.args+1] = arg
    arg = Arg_createBigImm(144506544, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(144506552, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot2, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_rdi, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot3, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.MoveZeroToDouble)
    arg = Arg_createTmp(Reg_xmm7)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot4, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(2, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb10, inst)
    bb11.successors[#bb11.successors+1] = FrequentedBlock_new(bb13, C.Normal)
    bb11.predecessors[#bb11.predecessors+1] = bb35
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb11, inst)
    bb12.successors[#bb12.successors+1] = FrequentedBlock_new(bb13, C.Normal)
    bb12.predecessors[#bb12.predecessors+1] = bb34
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb12, inst)
    bb13.successors[#bb13.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    bb13.predecessors[#bb13.predecessors+1] = bb11
    bb13.predecessors[#bb13.predecessors+1] = bb12
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm7)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm7)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm7)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm7)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb13, inst)
    bb14.successors[#bb14.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    bb14.predecessors[#bb14.predecessors+1] = bb31
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb14, inst)
    bb15.successors[#bb15.successors+1] = FrequentedBlock_new(bb28, C.Normal)
    bb15.successors[#bb15.successors+1] = FrequentedBlock_new(bb16, C.Normal)
    bb15.predecessors[#bb15.predecessors+1] = bb13
    bb15.predecessors[#bb15.predecessors+1] = bb14
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    bb16.successors[#bb16.successors+1] = FrequentedBlock_new(bb29, C.Normal)
    bb16.successors[#bb16.successors+1] = FrequentedBlock_new(bb17, C.Normal)
    bb16.predecessors[#bb16.predecessors+1] = bb15
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(267)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb16, inst)
    bb17.successors[#bb17.successors+1] = FrequentedBlock_new(bb18, C.Normal)
    bb17.predecessors[#bb17.predecessors+1] = bb16
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb17, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb17, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb17, inst)
    bb18.successors[#bb18.successors+1] = FrequentedBlock_new(bb20, C.Normal)
    bb18.successors[#bb18.successors+1] = FrequentedBlock_new(bb19, C.Rare)
    bb18.predecessors[#bb18.predecessors+1] = bb10
    bb18.predecessors[#bb18.predecessors+1] = bb17
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb18, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb18, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(400)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb18, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb18, inst)
    bb19.successors[#bb19.successors+1] = FrequentedBlock_new(bb20, C.Normal)
    bb19.predecessors[#bb19.predecessors+1] = bb18
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb19, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb19, inst)
    bb20.successors[#bb20.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb20.predecessors[#bb20.predecessors+1] = bb18
    bb20.predecessors[#bb20.predecessors+1] = bb19
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Rshift32)
    arg = Arg_createImm(31)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Xor32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot3, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot2, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_rsi, Reg_rdi, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rdi, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(79)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rdi, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_r12, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb20, inst)
    bb21.successors[#bb21.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb21.predecessors[#bb21.predecessors+1] = bb27
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb21, inst)
    bb22.successors[#bb22.successors+1] = FrequentedBlock_new(bb25, C.Normal)
    bb22.successors[#bb22.successors+1] = FrequentedBlock_new(bb23, C.Normal)
    bb22.predecessors[#bb22.predecessors+1] = bb20
    bb22.predecessors[#bb22.predecessors+1] = bb21
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb22, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb22, inst)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb26, C.Normal)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb24, C.Normal)
    bb23.predecessors[#bb23.predecessors+1] = bb22
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(400)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    bb24.successors[#bb24.successors+1] = FrequentedBlock_new(bb27, C.Normal)
    bb24.predecessors[#bb24.predecessors+1] = bb23
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createIndex(Reg_r9, Reg_r15, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Rshift32)
    arg = Arg_createImm(31)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Xor32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createIndex(Reg_r12, Reg_rbx, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MulDouble)
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.AddDouble)
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MulDouble)
    arg = Arg_createIndex(Reg_r9, Reg_rsi, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.AddDouble)
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MulDouble)
    arg = Arg_createIndex(Reg_r9, Reg_r15, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.AddDouble)
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.MulDouble)
    arg = Arg_createIndex(Reg_r9, Reg_r14, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.AddDouble)
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb24, inst)
    bb25.successors[#bb25.successors+1] = FrequentedBlock_new(bb27, C.Normal)
    bb25.predecessors[#bb25.predecessors+1] = bb22
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb25, inst)
    bb26.successors[#bb26.successors+1] = FrequentedBlock_new(bb27, C.Normal)
    bb26.predecessors[#bb26.predecessors+1] = bb23
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb26, inst)
    bb27.successors[#bb27.successors+1] = FrequentedBlock_new(bb21, C.Normal)
    bb27.successors[#bb27.successors+1] = FrequentedBlock_new(bb30, C.Normal)
    bb27.predecessors[#bb27.predecessors+1] = bb24
    bb27.predecessors[#bb27.predecessors+1] = bb26
    bb27.predecessors[#bb27.predecessors+1] = bb25
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb27, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb27, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(7)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb27, inst)
    bb28.successors[#bb28.successors+1] = FrequentedBlock_new(bb31, C.Normal)
    bb28.predecessors[#bb28.predecessors+1] = bb15
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb28, inst)
    bb29.successors[#bb29.successors+1] = FrequentedBlock_new(bb31, C.Normal)
    bb29.predecessors[#bb29.predecessors+1] = bb16
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb29, inst)
    bb30.successors[#bb30.successors+1] = FrequentedBlock_new(bb31, C.Normal)
    bb30.predecessors[#bb30.predecessors+1] = bb27
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb30, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb30, inst)
    bb31.successors[#bb31.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb31.successors[#bb31.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb31.predecessors[#bb31.predecessors+1] = bb30
    bb31.predecessors[#bb31.predecessors+1] = bb29
    bb31.predecessors[#bb31.predecessors+1] = bb28
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb31, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb31, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(7)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb31, inst)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb34, C.Normal)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb33, C.Rare)
    bb32.predecessors[#bb32.predecessors+1] = bb31
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(400)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    bb33.successors[#bb33.successors+1] = FrequentedBlock_new(bb34, C.Normal)
    bb33.predecessors[#bb33.predecessors+1] = bb32
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb33, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb33, inst)
    bb34.successors[#bb34.successors+1] = FrequentedBlock_new(bb12, C.Normal)
    bb34.successors[#bb34.successors+1] = FrequentedBlock_new(bb35, C.Normal)
    bb34.predecessors[#bb34.predecessors+1] = bb32
    bb34.predecessors[#bb34.predecessors+1] = bb33
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(4)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.DivDouble)
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createDoubleCond(DoubleNotEqualOrUnordered)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createIndex(Reg_r9, Reg_rsi, 8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.DivDouble)
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createDoubleCond(DoubleNotEqualOrUnordered)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createIndex(Reg_r9, Reg_rdi, 8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Add32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.DivDouble)
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createDoubleCond(DoubleNotEqualOrUnordered)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createIndex(Reg_r9, Reg_rsi, 8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.DivDouble)
    arg = Arg_createTmp(Reg_xmm6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createDoubleCond(DoubleNotEqualOrUnordered)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.FP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.MoveDouble)
    arg = Arg_createTmp(Reg_xmm5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createIndex(Reg_r9, Reg_rax, 8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(400)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    bb35.successors[#bb35.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb35.successors[#bb35.successors+1] = FrequentedBlock_new(bb36, C.Normal)
    bb35.predecessors[#bb35.predecessors+1] = bb34
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb35, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb35, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(267)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb35, inst)
    bb36.predecessors[#bb36.predecessors+1] = bb35
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(144506576, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb36, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb36, inst)
    return code
end


function createPayloadTypescriptScanIdentifier()
    code = Code_new()
    bb0 = Code_addBlock(code)
    bb1 = Code_addBlock(code)
    bb2 = Code_addBlock(code)
    bb3 = Code_addBlock(code)
    bb4 = Code_addBlock(code)
    bb5 = Code_addBlock(code)
    bb6 = Code_addBlock(code)
    bb7 = Code_addBlock(code)
    bb8 = Code_addBlock(code)
    bb9 = Code_addBlock(code)
    bb10 = Code_addBlock(code)
    bb11 = Code_addBlock(code)
    bb12 = Code_addBlock(code)
    bb13 = Code_addBlock(code)
    bb14 = Code_addBlock(code)
    bb15 = Code_addBlock(code)
    bb16 = Code_addBlock(code)
    bb17 = Code_addBlock(code)
    bb18 = Code_addBlock(code)
    bb19 = Code_addBlock(code)
    bb20 = Code_addBlock(code)
    bb21 = Code_addBlock(code)
    bb22 = Code_addBlock(code)
    bb23 = Code_addBlock(code)
    bb24 = Code_addBlock(code)
    bb25 = Code_addBlock(code)
    bb26 = Code_addBlock(code)
    bb27 = Code_addBlock(code)
    bb28 = Code_addBlock(code)
    bb29 = Code_addBlock(code)
    bb30 = Code_addBlock(code)
    bb31 = Code_addBlock(code)
    bb32 = Code_addBlock(code)
    bb33 = Code_addBlock(code)
    bb34 = Code_addBlock(code)
    slot0 = Code_addStackSlot(code, 56, C.Locked)
    slot1 = Code_addStackSlot(code, 8, C.Spill)
    slot2 = Code_addStackSlot(code, 8, C.Spill)
    slot3 = Code_addStackSlot(code, 8, C.Spill)
    slot4 = Code_addStackSlot(code, 8, C.Spill)
    slot5 = Code_addStackSlot(code, 4, C.Spill)
    slot6 = Code_addStackSlot(code, 8, C.Spill)
    slot7 = Code_addStackSlot(code, 8, C.Spill)
    slot8 = Code_addStackSlot(code, 8, C.Spill)
    slot9 = Code_addStackSlot(code, 40, C.Locked)
    StackSlot_setOffsetFromFP(slot9, -40)
    T = {}  -- temp pool table (register pressure)

    T.tmp98 = Code_newTmp(code, C.GP)
    T.tmp97 = Code_newTmp(code, C.GP)
    T.tmp96 = Code_newTmp(code, C.GP)
    T.tmp95 = Code_newTmp(code, C.GP)
    T.tmp94 = Code_newTmp(code, C.GP)
    T.tmp93 = Code_newTmp(code, C.GP)
    T.tmp92 = Code_newTmp(code, C.GP)
    T.tmp91 = Code_newTmp(code, C.GP)
    T.tmp90 = Code_newTmp(code, C.GP)
    T.tmp89 = Code_newTmp(code, C.GP)
    T.tmp88 = Code_newTmp(code, C.GP)
    T.tmp87 = Code_newTmp(code, C.GP)
    T.tmp86 = Code_newTmp(code, C.GP)
    T.tmp85 = Code_newTmp(code, C.GP)
    T.tmp84 = Code_newTmp(code, C.GP)
    T.tmp83 = Code_newTmp(code, C.GP)
    T.tmp82 = Code_newTmp(code, C.GP)
    T.tmp81 = Code_newTmp(code, C.GP)
    T.tmp80 = Code_newTmp(code, C.GP)
    T.tmp79 = Code_newTmp(code, C.GP)
    T.tmp78 = Code_newTmp(code, C.GP)
    T.tmp77 = Code_newTmp(code, C.GP)
    T.tmp76 = Code_newTmp(code, C.GP)
    T.tmp75 = Code_newTmp(code, C.GP)
    T.tmp74 = Code_newTmp(code, C.GP)
    T.tmp73 = Code_newTmp(code, C.GP)
    T.tmp72 = Code_newTmp(code, C.GP)
    T.tmp71 = Code_newTmp(code, C.GP)
    T.tmp70 = Code_newTmp(code, C.GP)
    T.tmp69 = Code_newTmp(code, C.GP)
    T.tmp68 = Code_newTmp(code, C.GP)
    T.tmp67 = Code_newTmp(code, C.GP)
    T.tmp66 = Code_newTmp(code, C.GP)
    T.tmp65 = Code_newTmp(code, C.GP)
    T.tmp64 = Code_newTmp(code, C.GP)
    T.tmp63 = Code_newTmp(code, C.GP)
    T.tmp62 = Code_newTmp(code, C.GP)
    T.tmp61 = Code_newTmp(code, C.GP)
    T.tmp60 = Code_newTmp(code, C.GP)
    T.tmp59 = Code_newTmp(code, C.GP)
    T.tmp58 = Code_newTmp(code, C.GP)
    T.tmp57 = Code_newTmp(code, C.GP)
    T.tmp56 = Code_newTmp(code, C.GP)
    T.tmp55 = Code_newTmp(code, C.GP)
    T.tmp54 = Code_newTmp(code, C.GP)
    T.tmp53 = Code_newTmp(code, C.GP)
    T.tmp52 = Code_newTmp(code, C.GP)
    T.tmp51 = Code_newTmp(code, C.GP)
    T.tmp50 = Code_newTmp(code, C.GP)
    T.tmp49 = Code_newTmp(code, C.GP)
    T.tmp48 = Code_newTmp(code, C.GP)
    T.tmp47 = Code_newTmp(code, C.GP)
    T.tmp46 = Code_newTmp(code, C.GP)
    T.tmp45 = Code_newTmp(code, C.GP)
    T.tmp44 = Code_newTmp(code, C.GP)
    T.tmp43 = Code_newTmp(code, C.GP)
    T.tmp42 = Code_newTmp(code, C.GP)
    T.tmp41 = Code_newTmp(code, C.GP)
    T.tmp40 = Code_newTmp(code, C.GP)
    T.tmp39 = Code_newTmp(code, C.GP)
    T.tmp38 = Code_newTmp(code, C.GP)
    T.tmp37 = Code_newTmp(code, C.GP)
    T.tmp36 = Code_newTmp(code, C.GP)
    T.tmp35 = Code_newTmp(code, C.GP)
    T.tmp34 = Code_newTmp(code, C.GP)
    T.tmp33 = Code_newTmp(code, C.GP)
    T.tmp32 = Code_newTmp(code, C.GP)
    T.tmp31 = Code_newTmp(code, C.GP)
    T.tmp30 = Code_newTmp(code, C.GP)
    T.tmp29 = Code_newTmp(code, C.GP)
    T.tmp28 = Code_newTmp(code, C.GP)
    T.tmp27 = Code_newTmp(code, C.GP)
    T.tmp26 = Code_newTmp(code, C.GP)
    T.tmp25 = Code_newTmp(code, C.GP)
    T.tmp24 = Code_newTmp(code, C.GP)
    T.tmp23 = Code_newTmp(code, C.GP)
    T.tmp22 = Code_newTmp(code, C.GP)
    T.tmp21 = Code_newTmp(code, C.GP)
    T.tmp20 = Code_newTmp(code, C.GP)
    T.tmp19 = Code_newTmp(code, C.GP)
    T.tmp18 = Code_newTmp(code, C.GP)
    T.tmp17 = Code_newTmp(code, C.GP)
    T.tmp16 = Code_newTmp(code, C.GP)
    T.tmp15 = Code_newTmp(code, C.GP)
    T.tmp14 = Code_newTmp(code, C.GP)
    T.tmp13 = Code_newTmp(code, C.GP)
    T.tmp12 = Code_newTmp(code, C.GP)
    T.tmp11 = Code_newTmp(code, C.GP)
    T.tmp10 = Code_newTmp(code, C.GP)
    T.tmp9 = Code_newTmp(code, C.GP)
    T.tmp8 = Code_newTmp(code, C.GP)
    T.tmp7 = Code_newTmp(code, C.GP)
    T.tmp6 = Code_newTmp(code, C.GP)
    T.tmp5 = Code_newTmp(code, C.GP)
    T.tmp4 = Code_newTmp(code, C.GP)
    T.tmp3 = Code_newTmp(code, C.GP)
    T.tmp2 = Code_newTmp(code, C.GP)
    T.tmp1 = Code_newTmp(code, C.GP)
    T.tmp0 = Code_newTmp(code, C.GP)
    inst = null
    arg = null
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb5, C.Normal)
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb4, C.Normal)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(177329888, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Scratch, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(2, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(21)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(2540)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 72)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Compare32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(92)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(154991936, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(80)
    inst.args[#inst.args+1] = arg
    arg = Arg_createBigImm(154991936, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(154991944, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createAddr(Reg_r12, -8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_r12, Reg_rax, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Xor64)
    arg = Arg_createImm(6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot2, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(129987312, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot4, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(108418352, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    bb1.predecessors[#bb1.predecessors+1] = bb6
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb1, inst)
    bb2.predecessors[#bb2.predecessors+1] = bb23
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb2, inst)
    bb3.predecessors[#bb3.predecessors+1] = bb32
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb3, inst)
    bb4.predecessors[#bb4.predecessors+1] = bb0
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb4, inst)
    bb5.successors[#bb5.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb5.successors[#bb5.successors+1] = FrequentedBlock_new(bb6, C.Rare)
    bb5.predecessors[#bb5.predecessors+1] = bb0
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 56)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, -24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r10, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb1, C.Rare)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb7, C.Normal)
    bb6.predecessors[#bb6.predecessors+1] = bb5
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 36)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot8, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot7, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot6, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot7, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot6, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(129987312, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb7.predecessors[#bb7.predecessors+1] = bb6
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb7, inst)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb8.predecessors[#bb8.predecessors+1] = bb5
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb8, inst)
    bb9.successors[#bb9.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb9.predecessors[#bb9.predecessors+1] = bb15
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb9, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb9, inst)
    bb10.successors[#bb10.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb10.predecessors[#bb10.predecessors+1] = bb18
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb10, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb10, inst)
    bb11.successors[#bb11.successors+1] = FrequentedBlock_new(bb12, C.Normal)
    bb11.successors[#bb11.successors+1] = FrequentedBlock_new(bb16, C.Normal)
    bb11.predecessors[#bb11.predecessors+1] = bb7
    bb11.predecessors[#bb11.predecessors+1] = bb10
    bb11.predecessors[#bb11.predecessors+1] = bb9
    bb11.predecessors[#bb11.predecessors+1] = bb8
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 40)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.Overflow)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_UseZDef, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateColdUse, type=C.GP, width=32}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThan)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb11, inst)
    bb12.successors[#bb12.successors+1] = FrequentedBlock_new(bb13, C.Normal)
    bb12.successors[#bb12.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb12.predecessors[#bb12.predecessors+1] = bb11
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r10, 12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r10, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    inst = Inst_new(C.BranchTest32)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb12, inst)
    bb13.successors[#bb13.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    bb13.predecessors[#bb13.predecessors+1] = bb12
    inst = Inst_new(C.Load8)
    arg = Arg_createIndex(Reg_r9, Reg_rdx, 1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb13, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb13, inst)
    bb14.successors[#bb14.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    bb14.predecessors[#bb14.predecessors+1] = bb12
    inst = Inst_new(C.Load16)
    arg = Arg_createIndex(Reg_r9, Reg_rdx, 2, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb14, inst)
    bb15.successors[#bb15.successors+1] = FrequentedBlock_new(bb9, C.Normal)
    bb15.successors[#bb15.successors+1] = FrequentedBlock_new(bb17, C.Normal)
    bb15.predecessors[#bb15.predecessors+1] = bb14
    bb15.predecessors[#bb15.predecessors+1] = bb13
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Add64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 72)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.AboveOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createIndex(Reg_r12, Reg_rax, 8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.MoveConditionallyTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Xor64)
    arg = Arg_createImm(6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    bb16.predecessors[#bb16.predecessors+1] = bb11
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb16, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb16, inst)
    bb17.successors[#bb17.successors+1] = FrequentedBlock_new(bb18, C.Normal)
    bb17.successors[#bb17.successors+1] = FrequentedBlock_new(bb19, C.Normal)
    bb17.predecessors[#bb17.predecessors+1] = bb15
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(48)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb17, inst)
    bb18.successors[#bb18.successors+1] = FrequentedBlock_new(bb10, C.Normal)
    bb18.successors[#bb18.successors+1] = FrequentedBlock_new(bb19, C.Normal)
    bb18.predecessors[#bb18.predecessors+1] = bb17
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.LessThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(57)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb18, inst)
    bb19.successors[#bb19.successors+1] = FrequentedBlock_new(bb20, C.Normal)
    bb19.successors[#bb19.successors+1] = FrequentedBlock_new(bb21, C.Normal)
    bb19.predecessors[#bb19.predecessors+1] = bb17
    bb19.predecessors[#bb19.predecessors+1] = bb18
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.GreaterThanOrEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(128)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb19, inst)
    bb20.predecessors[#bb20.predecessors+1] = bb19
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb20, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb20, inst)
    bb21.successors[#bb21.successors+1] = FrequentedBlock_new(bb22, C.Normal)
    bb21.successors[#bb21.successors+1] = FrequentedBlock_new(bb23, C.Normal)
    bb21.predecessors[#bb21.predecessors+1] = bb19
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    BasicBlock_append(bb21, inst)
    inst = Inst_new(C.Branch32)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(92)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb21, inst)
    bb22.predecessors[#bb22.predecessors+1] = bb21
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot5, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb22, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb22, inst)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb2, C.Rare)
    bb23.successors[#bb23.successors+1] = FrequentedBlock_new(bb24, C.Normal)
    bb23.predecessors[#bb23.predecessors+1] = bb21
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 48)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(155021568, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r11)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(155041288, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, -1336)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r13, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 36)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(108356304, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot3, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(129987312, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb23, inst)
    bb24.successors[#bb24.successors+1] = FrequentedBlock_new(bb25, C.Normal)
    bb24.successors[#bb24.successors+1] = FrequentedBlock_new(bb26, C.Normal)
    bb24.predecessors[#bb24.predecessors+1] = bb23
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb24, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb24, inst)
    bb25.successors[#bb25.successors+1] = FrequentedBlock_new(bb27, C.Normal)
    bb25.successors[#bb25.successors+1] = FrequentedBlock_new(bb26, C.Normal)
    bb25.predecessors[#bb25.predecessors+1] = bb24
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb25, inst)
    inst = Inst_new(C.And64)
    arg = Arg_createImm(-9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb25, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb25, inst)
    bb26.successors[#bb26.successors+1] = FrequentedBlock_new(bb29, C.Normal)
    bb26.successors[#bb26.successors+1] = FrequentedBlock_new(bb28, C.Normal)
    bb26.predecessors[#bb26.predecessors+1] = bb24
    bb26.predecessors[#bb26.predecessors+1] = bb25
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb26, inst)
    bb27.successors[#bb27.successors+1] = FrequentedBlock_new(bb30, C.Normal)
    bb27.predecessors[#bb27.predecessors+1] = bb25
    inst = Inst_new(C.Move)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb27, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb27, inst)
    bb28.successors[#bb28.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb28.predecessors[#bb28.predecessors+1] = bb26
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb28, inst)
    bb29.successors[#bb29.successors+1] = FrequentedBlock_new(bb30, C.Normal)
    bb29.predecessors[#bb29.predecessors+1] = bb26
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb29, inst)
    bb30.successors[#bb30.successors+1] = FrequentedBlock_new(bb34, C.Normal)
    bb30.successors[#bb30.successors+1] = FrequentedBlock_new(bb31, C.Normal)
    bb30.predecessors[#bb30.predecessors+1] = bb29
    bb30.predecessors[#bb30.predecessors+1] = bb27
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb30, inst)
    inst = Inst_new(C.And64)
    arg = Arg_createImm(-9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb30, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb30, inst)
    bb31.successors[#bb31.successors+1] = FrequentedBlock_new(bb32, C.Normal)
    bb31.predecessors[#bb31.predecessors+1] = bb30
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb31, inst)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb3, C.Rare)
    bb32.successors[#bb32.successors+1] = FrequentedBlock_new(bb33, C.Normal)
    bb32.predecessors[#bb32.predecessors+1] = bb28
    bb32.predecessors[#bb32.predecessors+1] = bb31
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 36)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(154991632, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createBigImm(108356304, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_xmm0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.FP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(129987312, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(-1)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb32, inst)
    bb33.predecessors[#bb33.predecessors+1] = bb32
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb33, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb33, inst)
    bb34.predecessors[#bb34.predecessors+1] = bb30
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(153835296, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(3)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb34, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb34, inst)
    return code
end


function createPayloadAirJSACLj8C()
    code = Code_new()
    bb0 = Code_addBlock(code)
    bb1 = Code_addBlock(code)
    bb2 = Code_addBlock(code)
    bb3 = Code_addBlock(code)
    bb4 = Code_addBlock(code)
    bb5 = Code_addBlock(code)
    bb6 = Code_addBlock(code)
    bb7 = Code_addBlock(code)
    bb8 = Code_addBlock(code)
    bb9 = Code_addBlock(code)
    bb10 = Code_addBlock(code)
    bb11 = Code_addBlock(code)
    bb12 = Code_addBlock(code)
    bb13 = Code_addBlock(code)
    bb14 = Code_addBlock(code)
    bb15 = Code_addBlock(code)
    slot0 = Code_addStackSlot(code, 160, C.Locked)
    slot1 = Code_addStackSlot(code, 8, C.Spill)
    slot2 = Code_addStackSlot(code, 8, C.Spill)
    slot3 = Code_addStackSlot(code, 8, C.Spill)
    slot4 = Code_addStackSlot(code, 40, C.Locked)
    StackSlot_setOffsetFromFP(slot4, -40)
    T = {}  -- temp pool table (register pressure)

    T.tmp61 = Code_newTmp(code, C.GP)
    T.tmp60 = Code_newTmp(code, C.GP)
    T.tmp59 = Code_newTmp(code, C.GP)
    T.tmp58 = Code_newTmp(code, C.GP)
    T.tmp57 = Code_newTmp(code, C.GP)
    T.tmp56 = Code_newTmp(code, C.GP)
    T.tmp55 = Code_newTmp(code, C.GP)
    T.tmp54 = Code_newTmp(code, C.GP)
    T.tmp53 = Code_newTmp(code, C.GP)
    T.tmp52 = Code_newTmp(code, C.GP)
    T.tmp51 = Code_newTmp(code, C.GP)
    T.tmp50 = Code_newTmp(code, C.GP)
    T.tmp49 = Code_newTmp(code, C.GP)
    T.tmp48 = Code_newTmp(code, C.GP)
    T.tmp47 = Code_newTmp(code, C.GP)
    T.tmp46 = Code_newTmp(code, C.GP)
    T.tmp45 = Code_newTmp(code, C.GP)
    T.tmp44 = Code_newTmp(code, C.GP)
    T.tmp43 = Code_newTmp(code, C.GP)
    T.tmp42 = Code_newTmp(code, C.GP)
    T.tmp41 = Code_newTmp(code, C.GP)
    T.tmp40 = Code_newTmp(code, C.GP)
    T.tmp39 = Code_newTmp(code, C.GP)
    T.tmp38 = Code_newTmp(code, C.GP)
    T.tmp37 = Code_newTmp(code, C.GP)
    T.tmp36 = Code_newTmp(code, C.GP)
    T.tmp35 = Code_newTmp(code, C.GP)
    T.tmp34 = Code_newTmp(code, C.GP)
    T.tmp33 = Code_newTmp(code, C.GP)
    T.tmp32 = Code_newTmp(code, C.GP)
    T.tmp31 = Code_newTmp(code, C.GP)
    T.tmp30 = Code_newTmp(code, C.GP)
    T.tmp29 = Code_newTmp(code, C.GP)
    T.tmp28 = Code_newTmp(code, C.GP)
    T.tmp27 = Code_newTmp(code, C.GP)
    T.tmp26 = Code_newTmp(code, C.GP)
    T.tmp25 = Code_newTmp(code, C.GP)
    T.tmp24 = Code_newTmp(code, C.GP)
    T.tmp23 = Code_newTmp(code, C.GP)
    T.tmp22 = Code_newTmp(code, C.GP)
    T.tmp21 = Code_newTmp(code, C.GP)
    T.tmp20 = Code_newTmp(code, C.GP)
    T.tmp19 = Code_newTmp(code, C.GP)
    T.tmp18 = Code_newTmp(code, C.GP)
    T.tmp17 = Code_newTmp(code, C.GP)
    T.tmp16 = Code_newTmp(code, C.GP)
    T.tmp15 = Code_newTmp(code, C.GP)
    T.tmp14 = Code_newTmp(code, C.GP)
    T.tmp13 = Code_newTmp(code, C.GP)
    T.tmp12 = Code_newTmp(code, C.GP)
    T.tmp11 = Code_newTmp(code, C.GP)
    T.tmp10 = Code_newTmp(code, C.GP)
    T.tmp9 = Code_newTmp(code, C.GP)
    T.tmp8 = Code_newTmp(code, C.GP)
    T.tmp7 = Code_newTmp(code, C.GP)
    T.tmp6 = Code_newTmp(code, C.GP)
    T.tmp5 = Code_newTmp(code, C.GP)
    T.tmp4 = Code_newTmp(code, C.GP)
    T.tmp3 = Code_newTmp(code, C.GP)
    T.tmp2 = Code_newTmp(code, C.GP)
    T.tmp1 = Code_newTmp(code, C.GP)
    T.tmp0 = Code_newTmp(code, C.GP)
    inst = null
    arg = null
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb1, C.Normal)
    bb0.successors[#bb0.successors+1] = FrequentedBlock_new(bb15, C.Normal)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276424800, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbp, 16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbp)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Scratch, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 72)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 64)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 56)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 48)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(2, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbp, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(0, -65536)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276327648, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r8, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(21)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r12, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(372)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r12, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, -40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276321024, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 72)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 64)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 56)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 48)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 40)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Xor64)
    arg = Arg_createImm(6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot2, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot3, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb0, inst)
    bb1.successors[#bb1.successors+1] = FrequentedBlock_new(bb3, C.Normal)
    bb1.successors[#bb1.successors+1] = FrequentedBlock_new(bb2, C.Normal)
    bb1.predecessors[#bb1.predecessors+1] = bb0
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_r8, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(468)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r8, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276741160, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, 8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb1, inst)
    bb2.predecessors[#bb2.predecessors+1] = bb1
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r8)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb2, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb2, inst)
    bb3.successors[#bb3.successors+1] = FrequentedBlock_new(bb4, C.Normal)
    bb3.successors[#bb3.successors+1] = FrequentedBlock_new(bb7, C.Normal)
    bb3.predecessors[#bb3.predecessors+1] = bb1
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_r8, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(23)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(275739616, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    inst = Inst_new(C.Branch64)
    arg = Arg_createRelCond(C.Equal)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rbx, 24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb3, inst)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb5, C.Normal)
    bb4.successors[#bb4.successors+1] = FrequentedBlock_new(bb6, C.Normal)
    bb4.predecessors[#bb4.predecessors+1] = bb3
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rbx, 16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createAddr(Reg_rax, 32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot0, 8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276645872, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276646496, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Xor64)
    arg = Arg_createImm(6)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(-2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb4, inst)
    bb5.successors[#bb5.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb5.predecessors[#bb5.predecessors+1] = bb4
    inst = Inst_new(C.Move)
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_LateUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rcx, 0)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(419)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createBigImm(276168608, 1)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createStack(slot1, 0)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb5, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb5, inst)
    bb6.successors[#bb6.successors+1] = FrequentedBlock_new(bb8, C.Normal)
    bb6.predecessors[#bb6.predecessors+1] = bb4
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb6, inst)
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb6, inst)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb12, C.Normal)
    bb7.successors[#bb7.successors+1] = FrequentedBlock_new(bb9, C.Normal)
    bb7.predecessors[#bb7.predecessors+1] = bb3
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rbx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move32)
    arg = Arg_createImm(5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_r13)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rsi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(48)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rdi)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(56)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(8)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(16)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(24)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(32)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(40)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(48)
    inst.args[#inst.args+1] = arg
    arg = Arg_createCallArg(56)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r14)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Def, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb7, inst)
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb7, inst)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb13, C.Normal)
    bb8.successors[#bb8.successors+1] = FrequentedBlock_new(bb10, C.Normal)
    bb8.predecessors[#bb8.predecessors+1] = bb6
    bb8.predecessors[#bb8.predecessors+1] = bb5
    inst = Inst_new(C.BranchTest64)
    arg = Arg_createResCond(C.NonZero)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r15)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb8, inst)
    bb9.successors[#bb9.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb9.predecessors[#bb9.predecessors+1] = bb7
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb9, inst)
    bb10.successors[#bb10.successors+1] = FrequentedBlock_new(bb11, C.Normal)
    bb10.predecessors[#bb10.predecessors+1] = bb8
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb10, inst)
    bb11.predecessors[#bb11.predecessors+1] = bb9
    bb11.predecessors[#bb11.predecessors+1] = bb10
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.Below)
    inst.args[#inst.args+1] = arg
    arg = Arg_createAddr(Reg_rax, 5)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(20)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=8}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb11, inst)
    inst = Inst_new(C.Oops)
    BasicBlock_append(bb11, inst)
    bb12.successors[#bb12.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb12.predecessors[#bb12.predecessors+1] = bb7
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb12, inst)
    bb13.successors[#bb13.successors+1] = FrequentedBlock_new(bb14, C.Normal)
    bb13.predecessors[#bb13.predecessors+1] = bb8
    inst = Inst_new(C.Jump)
    BasicBlock_append(bb13, inst)
    bb14.predecessors[#bb14.predecessors+1] = bb12
    bb14.predecessors[#bb14.predecessors+1] = bb13
    inst = Inst_new(C.Move)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.And64)
    arg = Arg_createImm(-9)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Patch)
    arg = Arg_createSpecial()
    inst.args[#inst.args+1] = arg
    arg = Arg_createRelCond(C.NotEqual)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rcx)
    inst.args[#inst.args+1] = arg
    arg = Arg_createImm(2)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_r12)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    inst.patchHasNonArgEffects = true
    inst.patchArgData = {}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=32}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_Use, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    inst.patchArgData[#inst.patchArgData+1] = {role=C.ArgRole_ColdUse, type=C.GP, width=64}
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb14, inst)
    bb15.predecessors[#bb15.predecessors+1] = bb0
    inst = Inst_new(C.Move)
    arg = Arg_createImm(10)
    inst.args[#inst.args+1] = arg
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    inst = Inst_new(C.Ret64)
    arg = Arg_createTmp(Reg_rax)
    inst.args[#inst.args+1] = arg
    BasicBlock_append(bb15, inst)
    return code
end



-- Register payloads and run
payloads[1] = {generate=createPayloadGbemuExecuteIteration,              name="gbemu",      earlyHash=632653144,  lateHash=372715518}
payloads[2] = {generate=createPayloadImagingGaussianBlurGaussianBlur,    name="imaging",    earlyHash=3677819581, lateHash=1252116304}
payloads[3] = {generate=createPayloadTypescriptScanIdentifier,           name="typescript", earlyHash=1914852601, lateHash=837339551}
payloads[4] = {generate=createPayloadAirJSACLj8C,                        name="airjs",      earlyHash=1373599940, lateHash=3981283600}

for i = 1, 100 do
    runIteration()
end

end

bench.runCode(test, "air")
