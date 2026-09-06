# AGENTS.md — fork context and workflow

## Git workflow

- Start each task on a feature branch created from the latest local `master`:
  `git checkout -b <short-kebab-case-name> master`. If already on a
  task-specific feature branch based on recent `master`, keep using it.
- Commit each coherent change as its own commit as you go: one logical change
  (code plus its tests, `.luau` migrations, and snapshot updates) is one commit;
  unrelated fixes are separate commits.
- Leave the feature branch checked out with `git status` clean, ready for review.

## What this repo is

This is a **breaking-change fork of Luau** (`luau-lang/luau`), not upstream Luau.

- There are **no legacy users / scripts to support**. Backwards compatibility with
  Lua 5.1, upstream Luau, or earlier commits of this fork is **not a goal**.
- Prefer clean, simple language design over migration paths. When removing syntax,
  there is no need for deprecation periods or compat flags.
- `README.md` and upstream docs (`luau.org`, compatibility notes) are **stale**;
  do not treat them as constraints.
- Every `.luau` file in the repo must move with the language — including `bench/`,
  even though CI doesn't execute it. Migrate them in the same commit as the change.

Intentional divergences so far (see `git log`):

- `~=` → `!=`
- `elseif` removed, use `else if`
- `::` cast → `as`
- `#` length operator → `.count` property
- `then` / `do` may be omitted before a newline

Expect more changes in this spirit.

## Old type solver is dead — do not maintain it

- **New solver** (the only one that matters): `Analysis/src/ConstraintGenerator.cpp`,
  `Analysis/src/ConstraintSolver.cpp`, `Analysis/src/TypeChecker2.cpp`, plus
  supporting files (`Normalize.cpp`, `Subtyping.cpp`, `Unifier2.cpp`, etc.).
- **Old solver**: `Analysis/src/TypeInfer.cpp` (`SolverMode::Old`,
  `FFlag::DebugLuauForceOldSolver`). **Do not fix bugs in it. Do not add features
  to it. Do not evolve it to match new syntax.**
- If a change only breaks tests under `--fflags=DebugLuauForceOldSolver` or in
  tests guarded by `DOES_NOT_PASS_NEW_SOLVER_GUARD()` / `if (FFlag::DebugLuauForceOldSolver)`,
  the correct fix is to **update or delete the old-solver-only expectation**, never to
  add old-solver logic. Long term the old solver and its test scaffolding should be removed.
- When touching the type system, only update the new solver, `BuiltinDefinitions.cpp`,
  and new-solver test expectations.

## How to land a syntax change

Changing or removing syntax touches many layers. Expect to update all of:

- `Ast/` (`Lexer.cpp`, `Parser.cpp` — helpful error naming the replacement, with recovery
  so only one error is reported; `Ast.h`/`Ast.cpp`, `PrettyPrinter.cpp`),
  `Analysis/src/AstJsonEncoder.cpp`
- `Compiler/` (`Compiler.cpp`, `ConstantFolding.cpp`, `Types.cpp`, `CostModel` if affected)
- `VM/` interpreter (`lvmexecute.cpp` fast paths, `lvmutils.cpp` helpers)
- `CodeGen/` native fallbacks (`CodeGenUtils::execute*` — native fast paths often bypass
  the `luaV_*` helpers, so semantics must be duplicated there), plus `IrTranslation.cpp` /
  `BytecodeAnalysis.cpp` if result typing matters
- `Analysis/` new-solver files + `Linter.cpp` (including warning strings)
- `fuzz/luau.proto`, `fuzz/protoprint.cpp`
- Every `.luau` file using the old syntax: inline snippets in `tests/*.test.cpp`
  (including fuzz seeds), `tests/conformance/*.luau`, `tests/require/**/*.luau`,
  `bench/**/*.luau`

Before editing, check an occurrence really is the syntax being removed. String literals,
error-message text, format strings, and comments that merely contain the same characters
are not syntax and must stay.

Snapshot tests (`Compiler.test.cpp`, `IrLowering.test.cpp`, CodeGen header/dump tests) compare
exact bytecode/IR strings. Any bytecode change shifts live ranges and fallback ids —
re-run the specific failing test, copy the **actual** output into the expectation, and
sanity-check that the diff is explained by your change.

## CI: practical local gate

The full matrix lives in `.github/workflows/build.yml` (`unix` job); CI runs all of it.
Running everything locally on every change is slow, so for routine changes this smaller
set is the local gate — it catches practically everything CI would:

```sh
CC=clang CXX=clang++ make -j2 config=sanitize werror=1 native=1 luau-tests
./luau-tests
./luau-tests --fflags=true
./luau-tests -ts=Conformance -O2 --fflags=true
./luau-tests -ts=Conformance --codegen -O2 --fflags=true
make -j2 config=sanitize werror=1 luau luau-analyze luau-compile
./luau tests/conformance/assert.luau
./luau-analyze tests/conformance/assert.luau
./luau-compile tests/conformance/assert.luau
```

Notes:

- One `sanitize` + `werror=1` + `native=1` build covers warnings, ASAN, and the native path.
- `./luau-tests` plus `--fflags=true` covers default and all-flags behavior.
- The two `-O2 --fflags=true` conformance runs (interpreter + native) subsume the weaker
  `-O2` / `--codegen` / default-flag combinations for practical purposes.
- Deliberately skipped locally: `--fflags=DebugLuauForceOldSolver*` (old solver is dead —
  fix red old-solver jobs by deleting/updating the stale expectation, not the code) and
  `DebugCodegenChaosA64` / `DebugCodegenLimitRegs` (regalloc stress flags).
- `windows` and `configurations` (LongJmp / Vector4 / VectorDouble) jobs also exist in CI;
  keep changes portable even though you only run the `unix` gate locally.
- `make test` / `ctest` are not the CI gate — use the commands above.
- Full `./luau-tests` runs 5720 cases; when iterating, filter first
  (e.g. `./build/sanitize/luau-tests -ts=IrLowering`), then run the practical set.
- If you touched `VM/` or `CodeGen/`, run the full `unix` matrix from the workflow
  instead of the subset — that's where the skipped combinations actually bite.
