--!strict

-- ARM64 Linux Emulator - core run function.
-- Takes an ELF binary (as a string), argv, and an output callback, then runs the program.

Int = require("./integer")
MemMod = require("./memory")
CPU = require("./cpu")
ELF = require("./elf")
Decode = require("./decode")
Syscall = require("./syscall")

M = {}

function M.run(elfData: string, argv: { string }, outputLine: (string) -> ()): number
    -- Parse ELF headers
    elfInfo = ELF.parse(elfData)

    -- Create memory and load segments
    mem = MemMod.new()
    highAddr = ELF.load(elfInfo, elfData, mem)

    -- Initialize syscall subsystem
    Syscall.init(highAddr, outputLine)

    -- Set up the initial stack (Linux kernel ABI).
    STACK_TOP = Int.fromHex("800000000")
    STACK_SIZE = 8 * 1024 * 1024
    stackBase = Int.sub(STACK_TOP, Int.from(STACK_SIZE))
    mem:zeroFill(stackBase, STACK_SIZE)

    sp = STACK_TOP

    -- Write strings to stack top area
    stringArea = Int.sub(STACK_TOP, Int.from(4096))
    stringPos = stringArea

    function pushString(s: string): integer
        addr = stringPos
        mem:writeString(stringPos, s .. "\0")
        stringPos = Int.add(stringPos, Int.from(#s + 1))
        return addr
    end

    -- argv
    argvAddrs = {}
    for _, arg in argv do
        table.insert(argvAddrs, pushString(arg))
    end

    -- Environment
    envAddrs = {}
    table.insert(envAddrs, pushString("PATH=/usr/bin"))
    table.insert(envAddrs, pushString("STINKY=OOF"))

    -- Random bytes for AT_RANDOM
    randomAddr = stringPos
    for idx = 0, 15 do
        mem:writeU8(Int.add(stringPos, Int.from(idx)), (idx * 17 + 42) % 256)
    end
    stringPos = Int.add(stringPos, Int.from(16))

    -- Platform string
    platformAddr = pushString("aarch64")

    -- Build stack frame
    stackEntries = {}

    table.insert(stackEntries, Int.from(#argvAddrs))
    for _, addr in argvAddrs do
        table.insert(stackEntries, addr)
    end
    table.insert(stackEntries, Int.ZERO)
    for _, addr in envAddrs do
        table.insert(stackEntries, addr)
    end
    table.insert(stackEntries, Int.ZERO)

    -- Auxiliary vector
    function auxv(atype: number, aval: integer)
        table.insert(stackEntries, Int.from(atype))
        table.insert(stackEntries, aval)
    end

    auxv(3, elfInfo.phdrAddr)       -- AT_PHDR
    auxv(4, Int.from(elfInfo.phdrEntSize)) -- AT_PHENT
    auxv(5, Int.from(elfInfo.phdrCount))   -- AT_PHNUM
    auxv(6, Int.from(4096))         -- AT_PAGESZ
    auxv(9, elfInfo.entry)          -- AT_ENTRY
    auxv(11, Int.from(1000))        -- AT_UID
    auxv(12, Int.from(1000))        -- AT_EUID
    auxv(13, Int.from(1000))        -- AT_GID
    auxv(14, Int.from(1000))        -- AT_EGID
    auxv(15, platformAddr)          -- AT_PLATFORM
    auxv(16, Int.from(0))           -- AT_HWCAP
    auxv(26, Int.from(0))           -- AT_HWCAP2
    auxv(17, Int.from(100))         -- AT_CLKTCK
    auxv(25, randomAddr)            -- AT_RANDOM
    auxv(0, Int.ZERO)               -- AT_NULL

    -- Place stack entries in memory (16-byte aligned)
    totalBytes = #stackEntries * 8
    sp = Int.sub(stringArea, Int.from(totalBytes))
    sp = Int.band(sp, Int.bnot(Int.from(0xF)))

    for idx, val in stackEntries do
        mem:writeU64(Int.add(sp, Int.from((idx - 1) * 8)), val)
    end

    -- Create CPU and run
    cpu = CPU.new(mem)
    cpu.SP = sp
    cpu.PC = elfInfo.entry

    while Decode.step(cpu) do end

    Syscall.flush()

    return cpu.exitCode
end

return M
