#!strict

# ELF64 loader for ARM64 Linux static binaries.
# Parses the ELF header and program headers, loads PT_LOAD segments into memory.

Int = require("./integer")
MemMod = require("./memory")

ELF = {}

export type ProgramHeader = {
    pType: number,
    pFlags: number,
    pOffset: number,
    pVaddr: integer,
    pFilesz: number,
    pMemsz: number,
    pAlign: number,
}

export type ELFInfo = {
    entry: integer,
    phdrs: { ProgramHeader },
    phdrAddr: integer,
    phdrCount: number,
    phdrEntSize: number,
}

# Read a little-endian u16 from a string at 1-based position.
function readU16(data: string, pos: number): number
    b0 = string.byte(data, pos)
    b1 = string.byte(data, pos + 1)
    return b0 + b1 * 256
end

# Read a little-endian u32 from a string at 1-based position.
function readU32(data: string, pos: number): number
    b0 = string.byte(data, pos)
    b1 = string.byte(data, pos + 1)
    b2 = string.byte(data, pos + 2)
    b3 = string.byte(data, pos + 3)
    return b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
end

# Read a little-endian u64 from a string at 1-based position.
function readU64(data: string, pos: number): integer
    lo = readU32(data, pos)
    hi = readU32(data, pos + 4)
    return Int.bor(Int.from(lo), Int.shl(Int.from(hi), 32))
end

function ELF.parse(data: string): ELFInfo
    # Verify ELF magic
    assert(string.byte(data, 1) == 0x7F and string.sub(data, 2, 4) == "ELF",
        "Not an ELF file")

    # Verify 64-bit, little-endian, ARM64
    assert(string.byte(data, 5) == 2, "Not 64-bit ELF")
    assert(string.byte(data, 6) == 1, "Not little-endian ELF")

    e_machine = readU16(data, 19)
    assert(e_machine == 0xB7, "Not ARM64 (aarch64) ELF")

    e_entry = readU64(data, 25)
    e_phoff = Int.toNumber(readU64(data, 33))
    e_phentsize = readU16(data, 55)
    e_phnum = readU16(data, 57)

    # Parse program headers
    phdrs = {}
    for idx = 0, e_phnum - 1 do
        base = e_phoff + idx * e_phentsize + 1 # 1-based
        phdr = {
            pType = readU32(data, base),
            pFlags = readU32(data, base + 4),
            pOffset = Int.toNumber(readU64(data, base + 8)),
            pVaddr = readU64(data, base + 16),
            pFilesz = Int.toNumber(readU64(data, base + 32)),
            pMemsz = Int.toNumber(readU64(data, base + 40)),
            pAlign = Int.toNumber(readU64(data, base + 48)),
        }
        table.insert(phdrs, phdr)
    end

    # Compute where phdrs are loaded in memory (usually at file offset e_phoff
    # which is within the first LOAD segment)
    phdrAddr = Int.ZERO
    for _, ph in phdrs do
        if ph.pType == 1 then # PT_LOAD
            segStart = ph.pOffset
            segEnd = segStart + ph.pFilesz
            if e_phoff >= segStart and e_phoff < segEnd then
                phdrAddr = Int.add(ph.pVaddr, Int.from(e_phoff - segStart))
                break
            end
        end
    end

    return {
        entry = e_entry,
        phdrs = phdrs,
        phdrAddr = phdrAddr,
        phdrCount = e_phnum,
        phdrEntSize = e_phentsize,
    }
end

# Load PT_LOAD segments into memory.
function ELF.load(info: ELFInfo, data: string, mem: MemMod.Memory): integer
    highAddr = Int.ZERO

    for _, phdr in info.phdrs do
        if phdr.pType == 1 then # PT_LOAD
            # Load file content
            if phdr.pFilesz > 0 then
                segment = string.sub(data, phdr.pOffset + 1, phdr.pOffset + phdr.pFilesz)
                mem:loadString(phdr.pVaddr, segment)
            end
            # Zero-fill BSS (memsz > filesz)
            if phdr.pMemsz > phdr.pFilesz then
                bssStart = Int.add(phdr.pVaddr, Int.from(phdr.pFilesz))
                bssSize = phdr.pMemsz - phdr.pFilesz
                mem:zeroFill(bssStart, bssSize)
            end
            # Track highest loaded address for brk
            endAddr = Int.add(phdr.pVaddr, Int.from(phdr.pMemsz))
            if Int.ugt(endAddr, highAddr) then
                highAddr = endAddr
            end
        end
    end

    return highAddr
end

return ELF
