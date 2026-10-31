# Blockers on the way to a wasm unit

Found building the full planar BEV (34 unknowns, a DAE, 4 callbacks, a 5 ms ABS clock) on dyad-lang
#2621's env v3.4 (d62a79d: DyadWasm fb9fd63, WasmCodegen 7a44976), plain Julia 1.13.2, x86_64 Linux.
Numbers are stable references: `patches.jl`, the build script and reports cite them.

Each entry: the symptom as it appears, the cause, what `scripts/patches.jl` does about it, and the
upstream fix that would retire the patch. Check upstream first: a patch for something already fixed
can hide the fix or break on the new code (`patches.jl` errors out if the line it rewrites in
`cosim.jl` has changed).

## Setup

**1. Pinned commits not found.** `ERROR: Did not find tree_hash … for LinearSolve [7ed4a6bd]` (then
SynchToolkit). The commits exist and are tagged `combined-2026-10-26-v3.4`, but Pkg's update of an
existing bare clone in `~/.julia/clones` did not fetch them. Fix: `git -C ~/.julia/clones/<hash(url)>
fetch origin <rev>` per `[sources]` entry, then instantiate again.

**2. Julia version.** The env needs plain Julia 1.13.2. juliaup offered 1.13 rc4, 1.13.3 and the
`dyad-3.5.0` sysimage; `julia-combined` refuses the last. Use the official tarball.

**3. Package server.** `JULIA_PKG_SERVER` is unset in a plain shell (the Dyad distribution sets it
internally): set `https://juliahub.com`. `JULIA_PKG_USE_CLI_GIT=true` authenticates the private repos.

**4. Node.** System Node 22 lacks exception references; Node 24 (the env's `NodeJS_24_jll`) runs
the units.

## Build

**5. `MTKParameters` convert under `FullSpecialize`** (cosim.jl:80, `init(prob, alg)`):

    MethodError: Cannot `convert` an object of type
      MTKParameters{…,Tuple{BlockedArray{Float64,1,…,Tuple{BlockedOneTo{Int64,SVector{1, Int64}}}}},Tuple{Vector{Bool}},…}
    to an object of type
      MTKParameters{…,Tuple{BlockedArray{Float64,1,…,Tuple{BlockedOneTo{Int64,Vector{Int64}}}}},Tuple{BitVector},…}

From `integrator.p = p` in OrdinaryDiffEqCore's `_initialize_dae!`: MTK's initialization returns
`SVector` block axes and a `Vector{Bool}` constant buffer. Reproduces with
`ODEProblem{true, FullSpecialize}(sys, [], tspan)` alone. Patch: a buffer-by-buffer `convert`
(build time only, for clocked units).

**6. Tunable parameters blow up inference and memory (the main one).** `build_component` exposes
every tunable that is not an input as an FMI parameter: a `(getp, setp)` pair each, in a tuple
walked recursively with `Base.tail`. The bare PlanarCar has 2615 scalar tunables, the full car 3815
(multibody geometry and MTK's `Initial(x)` parameters).

    info: inference of do_step(Int32, Float64, Float64, Int32) from do_step(…) exceeding 2501 frames (may be slow).

Then 20+ minutes at 100 % CPU with RSS climbing about 130 MB/min until a memory kill; when a run
did finish, `620 unsupported constructs`, mostly `splatting into a call of argtail`. Nothing in the
output names the parameter count. Patch: a one-argument `tunable_parameters` returning only
`KEEP_TUNABLE` (the inputs); the bare car went from a 20-minute timeout at 9.9 GB to 131 s and
3 GB. MTK's `subset_tunables` does not work for clocked models: SynchToolkit's clock runtime is
generated against the full buffer (`BoundsError: attempt to access 9-element Vector{Float64} at index
[281]` on the first tick). Upstream: expose parameters by index into `p.tunable`, opt in to the set,
leave out `Initial(x)`.

**7. Diagnostics print whole types.** `emit_stmt_or_trap!` records each unsupported statement with
its full type: megabytes per record for integrator types, and a 620-item failure spent a 20-minute
cap printing. Patch: `:limit` printing, each item logged to stderr as it happens.

**8. Inlined linear SCCs.** `simplify_model` inlines linear SCCs; the generated RHS solves them with
`ModelingToolkitTearing.numeric_ldiv!`, whose LinearSolve cache lives in `task_local_storage()`:
`a dynamic call of getproperty with argument types (Any, Symbol)` in `solve_into!`. Turning
inlining off compiles but leaves algebraic equations that are 0/0 at standstill: `InitialFailure`
at t = 0, natively too. Patch: keep inlining, solve by Gaussian elimination with partial pivoting,
generic in the element type. Upstream: a cache-free generic solve for these small blocks.

**9. In-module initialization (units without callbacks).** `cut_initdata` reads
`initializeprob.u0`, but MTK builds an `SCCNonlinearProblem` (`FieldError: … has no field u0`);
forcing a plain `NonlinearProblem` (patch, `WASM_PLAIN_INIT=1`) then fails in NonlinearSolve's trust
region, and `get_initial_values` → `MTKParametersReconstructor` is not type-stable. Clock-free units
of this car do not build; clocked units start from the baked initialization and avoid it.

**10. `BrownFullBasicInit` on a monolithic DAE unit.** `nlsolve = nothing` means NonlinearSolve's
default polyalgorithm: dynamic calls and Krylov's LAPACK `the foreign call dgeqrf_64_`. Patch:
default it to `NewtonRaphson(AutoForwardDiff(chunksize = 1), LUFactorization())`.

**11. The manifest step fails after the compile, and the module is lost.** At cosim.jl:343,
`"start" => Float64(outs[i](view0(1)))`, after 13 minutes of compiling:

    MethodError: … The applicable method may be too new: running in world age 40496, while current world is 41837.

An observed output's getter is `eval`ed inside `build_component` and needs `invokelatest`. The next
build failed in the same place on `NaN not allowed to be written in JSON spec`: an observed output
(lateral acceleration) is NaN at standstill. Patch: `invokelatest` and `finite_or_nothing` on the
start values. Upstream: both, and write the module before the manifest so a manifest error costs
seconds, not a rebuild.

**12. No progress output.** A healthy and a hung build look the same for an hour. On Linux,
`SIGUSR1` is not a stack dump (it killed the `time` wrapper). Judge by the RSS trend and the #6
warning instead.

## Docs

`pg/wasmcodegen-reset` has no `SUPPORT.md` or `compile/proto/ABI.md`; the limits live in dyad-lang's
`apps/cli/julia/DESIGN.md` §4.3. `build_component`'s docstring says "a tunable parameter becomes an
input" but not that every other tunable becomes an FMI parameter (#6).
