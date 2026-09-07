#!strict

# ARM64 Linux Emulator - CLI entry point.
# Usage: lute emu/main.luau <binary> [args...]

Emu = require("./emu")

process = require("@lute/process")
fs = require("@lute/fs")

args = process.args
if args.count < 2 then
    print("Usage: lute emu/main.luau <binary> [args...]")
    process.exit(1)
end

binaryPath = args[2]

f = fs.open(binaryPath, "r")
elfData = fs.read(f)
fs.close(f)

# Build argv: program name + remaining args
argv = {}
for idx = 2, args.count do
    table.insert(argv, args[idx])
end

exitCode = Emu.run(elfData, argv, print)

process.exit(exitCode)
