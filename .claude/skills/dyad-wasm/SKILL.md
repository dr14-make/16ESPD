---
name: dyad-wasm
description: Compile a model of this library to a WebAssembly co-simulation unit with DyadWasm, check it against the native solve, and drive it in Node or a browser page.
disable-model-invocation: true
argument-hint: <model function or Library.Module.Component>
---

# Dyad models to WebAssembly

Build $ARGUMENTS into a `dyad-cosim-1` unit: a module a page steps live, setting its inputs between
steps. The toolchain is pre-release and moves weekly: dyad-lang #2621 (`dyad export`, which pins the
environment) and DyadWasm #103 (`build_component`, the JS runtime). This recipe is what built the
full planar BEV on 2026-10-31 (dyad-lang d62a79d, DyadWasm fb9fd63, WasmCodegen 7a44976). Where the
upstream code has moved on, trust it over this file, and say so in the report.

Every finding behind this recipe, with the exact errors, is in
[`reference/blockers.md`](reference/blockers.md). Read it when a step fails or a build runs long.

## 1. Environment, once per machine

1. Plain Julia **1.13.2**, not a juliaup Dyad channel: `dyad-3.5.0` is a sysimage with packages,
   which the pinned env rightly refuses. Download the official tarball into the scratchpad rather than
   changing the user's juliaup channels.
2. `git clone --filter=blob:none -b pg/dyad-export-first-take https://github.com/JuliaComputing/dyad-lang.git`
   and copy `apps/cli/julia/env/` to a sibling directory: the copy is the build env, the original
   stays as pinned.
3. In a plain shell set `JULIA_PKG_SERVER=https://juliahub.com` and `JULIA_PKG_USE_CLI_GIT=true`
   (private repos authenticate through `gh`).
4. In the copy: `Pkg.instantiate()`, then `Pkg.develop(path = <this library's worktree>; preserve = Pkg.PRESERVE_ALL)`,
   then `Pkg.precompile()`. If instantiate stops on `Did not find tree_hash … for <Pkg>`, the pinned
   commit is missing from the bare clone: `git -C ~/.julia/clones/<hash> fetch origin <rev>` for that
   `[sources]` entry, and rerun.
5. Node **24** for checks (system Node 22 lacks exception references): the env ships one, find it
   with `ls ~/.julia/artifacts/*/bin/node` and `--version`.

Done when `Pkg.status()` in the copy lists the library from the worktree path and no pinned version
moved (`PRESERVE_ALL` only adds packages). Expect about 10 minutes, not the hour the toolchain's
author quotes: most of that hour is already in the package images.

## 2. The model and its ports

`build_component` takes an **uncompiled** ModelingToolkit `System`, so it needs no Dyad compiler:
a component function from `generated/`, or a Julia function wiring compiled components the way a
`.dyad` file would (`sim/plant.jl` on the `feat/dualsense-driver` branch is one).

- **Inputs**: what the page sets between steps. A top-level `RealInput` is picked up by default; a
  tunable parameter named in `expose_inputs` becomes an input too (a `Constant(k = …)` source's `k`
  is the usual way to make a driver command).
- **Outputs**: what the page reads. Name every signal it draws, observed variables included.

Done when the input and output lists are written down, each a path the native `System` resolves.

## 3. A native reference, before any wasm

Run the same model natively on the Dyad 3.5.0 distribution under a scripted input (a launch, a
maneuver, a stop) and write the outputs to CSV at the communication step the page will use
(10 ms). That CSV is the **native reference** every wasm build is judged against.

Done when the CSV exists and the run's retcode is `Success`.

## 4. A capped build

Build with [`scripts/build_unit.jl`](scripts/build_unit.jl) under
[`scripts/run_capped.sh`](scripts/run_capped.sh). The build script includes
[`scripts/patches.jl`](scripts/patches.jl) before `build_component`, and limits the exposed
parameters to the inputs (`KEEP_TUNABLE`).

Every build is a **capped build**: a wall-clock cap and a memory cap, so a runaway compile is
stopped by the cap rather than by earlyoom taking other work with it. One build at a time.

Healthy: the full planar BEV (34 unknowns, a DAE, a 5 ms clock) took about 14 minutes and 3.9 GB.
Stuck: `inference of do_step … exceeding 2501 frames` followed by RSS climbing steadily; that is the
parameter blow-up, and a longer cap will not finish it (blockers #6).

Done when the module and its manifest are written and the log ends `exit 0`.

## 5. Check it against the native reference

Run the unit in Node 24 through DyadWasm's `cosim.mjs` (`createSystem`, `set`, `advance`) under the
same scripted input, and compare every output with the native reference.

Done when every compared output agrees within a stated tolerance (the BEV agreed to 6 mm in position
over 18 s), and the real-time factor is reported. A build that loads but disagrees is a failed build.

## 6. A page

Copy `cosim.mjs` and `loader-wcg.mjs` from DyadWasm's `ts/src/` unchanged. Step the unit in a timer
loop paced to the wall clock, separate from `requestAnimationFrame`, so a slow frame rate never
slows the model; set the inputs before each `advance`. It needs WebAssembly GC and exception
references: current Chrome, Edge or Firefox, or Safari 18.4+.

To publish it as a claude.ai artifact: a supporting file may be at most 15 MB, so split a larger
module into `.wasm`-named parts (`split -b 8300000`), fetch both and concatenate before
`createSystem`. The artifact frame allows WebAssembly; the BEV held real time there.

Done when the page loads with no console errors and its real-time factor stays at 1.

## Report

Module size, build time and peak memory, the comparison against the native reference, the
real-time factor in Node and the browser, and every place the toolchain needed a patch beyond
`patches.jl` or no longer needed one. Add new findings to `reference/blockers.md` in its format.
