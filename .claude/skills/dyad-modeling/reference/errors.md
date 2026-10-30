# Dyad errors and the fix that works

Most common first in each table.

## Compile (`dyad compile`) errors

Almost all are fixed by reading the reference instead of guessing. When the same
`file:line - code` comes back a second time, stop editing around it and read the doc it points to.

| Diagnostic | Cause | Fix |
|---|---|---|
| `unknown-element: The name 'x' was not found in component 'C'` | Name typo, or a variable of a subcomponent referenced without its path | Use the full path `sub.x`; check the subcomponent's declaration |
| `unknown-element: No element named x found in analysis, options were ...` | Test metadata or analysis referring to a variable that is not a top-level element | Reference `body.mass.v`, not `v`; the "options were" list is the set of legal roots |
| `parse-error: The 'component' block needs to be closed with an 'end' keyword, but I found 'relations'` | Two `relations` blocks, or a declaration after `relations` | One `relations` section per component; declarations go before it |
| `lookup-failed: Unable to resolve type 'X' in 'Pkg.Sub'` | Type in another sublibrary, or a missing package | Fully qualify (`VehicleSystemsComponents.Vehicle.X`); add the package to `Project.toml` |
| `unknown-element: Modification for 'p' on c ... does not match any parameter name` | Overriding a parameter the component does not declare | Read the component (`stdlib_reference/<Lib>/...dyad`) for the real parameter names |
| `invalid-type: Element x found in definition C isn't a component type` | Arrays or functions declared like subcomponents | See `docs/arrays.md`, `docs/functions.md` |
| `parse-error: ... unexpected token '{' ... 'component_metadata'` / extra content `metadata` | Metadata block in the wrong place or wrong syntax | Copy the shape from `agent_resources/docs/metadata.md` or an existing test component |
| `parse-error: ... expecting a name ... found 'output'` | `output` used as an identifier | Rename; `input`/`output` are keywords |
| `parse-error: The '...' block needs to be closed with an 'end' keyword, but I found 'switch'` | A reserved word used as a name (`switch`, `input`, `output`, …) | Rename (`sw`, `transistor`); the message names the word, not the cause |
| `incompatible-connector-types` | A variable passed to `connect` | `connect` takes connectors only |
| `invalid-entity: Unknown symbol Any` | Julia types in a Dyad declaration | Use Dyad types (`Real`, unit types) |
| `urn:properties:unknown-modification-target` | Overriding a parameter after a rename | Read the component for its current parameter names |
| `invalid-common-set: variables are connected to both a local common variable AND external connectors` | A `path` declared inside a component that is also continued to its ports | Declare the medium once per harness with `continuity`, or keep it internal; confirm against `docs/modeling_fluid_systems.md` |
| `missing-initialization: ... final parameter` | `final` parameter without a value | Give it a value or drop `final` |
| `repeated-definition` | Two files define the same name (e.g. `_v2` copies) | Delete the copy |

## Julia-side errors (running the compiled library)

The common ones are API misuse around generated code, not physics; solver failures are rare.

| Error | Cause | Fix |
|---|---|---|
| `UndefVarError: XTransient not defined in VehicleSystemsComponents` | Analysis lives in a sublibrary module, or the file was not recompiled | `VehicleSystemsComponents.<Dir>.XTransient`; the sublibrary is the directory under `dyad/`. `grep -rn "XTransient" generated/` to find it |
| `SystemError: opening file ".../test/xyz.jl"` / `cd("test")` failed | Relative paths resolved from the wrong directory (foreground and background) | Absolute paths; run tests from `test/` (`cd test && julia --project=.. runtests.jl <group>`) |
| `ArgumentError: System S: variable p does not exist` | Passing a parameter the analysis does not declare; or the analysis forwards to a `structural parameter`, or forwards an expression, which an analysis cannot do | Add the parameter to the analysis and forward it to the model (house rule: scenario parameters are forwarded, never nested-overridden). For a structural switch, write a test component that `extends` the bench with the switch set, and give it its own analysis |
| NaN in the Jacobian, or `Unstable` at a standstill or a turning point | A regularized stdlib law (`sqrt`, `exp`) evaluated outside its range: at exactly zero slip, or a speed past the law's intended sign | Read the solver's Jacobian-analysis block, which names the equation rows; read the law's equations in `stdlib_reference`, and keep the model in the range it was written for (a start offset, a driver that cannot reverse) rather than adding creep everywhere |
| `MethodError: no method matching XTransientSpec(; p=...)` | Same, through the Spec constructor | Same |
| `... not able to use mass matrices` | An explicit solver (`Tsit5`) handed a DAE | A stiff DAE solver: `Rodas5P` or `FBDF` |
| `MethodError` mentioning `DiffEqArray` from `sol(range, idxs = x)` | Interpolating one variable over a range | `sol[x]` on the saved points, or `[sol(t, idxs = x) for t in range]` |
| Deprecation warning from `sol[p]` on a parameter | Parameters are not indexed like states | `sol.ps[p]` |
| `r."$x"` or `getproperty(r, :sym)` fails on a model path | `r."path"` takes a string literal only | Write the literal path; for a path chosen at run time, walk `m = symbolic_container(r)` one name at a time, `foldl(getproperty, Symbol.(split("body.mass.v", '.')); init = m)` |
| `Package GR not found` (from Plots) | The Dyad 3.5 distribution ships Plots with PlotlyBase and PlotlyKaleido, not GR | `setup(backend = :plotly)`; see `notebooks.md` |
| `HybridSystemNotSupportedException` from `mtkcompile` | A model with clocked parts compiled by hand | Take the compiled system from an analysis result, `r.sys`, which the analysis builds with the clock handling |
| `Package X not found in current path` | `using OrdinaryDiffEq`, `NonlinearSolve`, `SciMLBase` etc. not in the project | Use what the project has (`OrdinaryDiffEqDefault`, `DyadInterface`); add a package only when the task needs it |
| `ArgumentError: The name keyword must be provided` | Calling a component constructor bare | `@named sys = Lib.Comp()` |
| `overrides: [c] don't match names found in model` | Nested override with the wrong spelling | Constructor overrides use `sub__param` (`discretepidstandard__Ts = 0.1`), not `sub = (param = ...)` |
| `ExtraVariablesSystemException` / `ExtraEquationsSystemException` (unbalanced) | Missing or duplicate equation, usually a connector left floating or a double `continuity` | `equations(expand_connections(sys))` on the unsimplified model; count per variable. See the forensic-debugging skill |
| `InvalidSystemException: structurally singular` | Algebraic loop with no state at a node | Add the missing physics (compliance, inertia, capacitance), do not reshape inputs |
| `retcode = MaxIters` | Step budget exhausted, usually chattering `ifelse` or a stiff fast state under Tsit5 | Smooth the switch or slow the fastest time constant (house rule: hydraulic time constants >= 1 ms); do not raise `maxiters` blindly |
| `Unstable` / `InitialFailure` | Rare | forensic-debugging skill |
| Julia killed (no error, process gone) | Out of memory; `earlyoom` prefers `julia` | `free -g`, one Julia at a time, run tests by group |
| `Initialization system is overdetermined` (warning) | Conflicting `initial` lines or initial values on algebraic variables | Drop the redundant `initial`. When an algebraic equation has more than one solution, check the initial values against an anchor first: initialization may have chosen the wrong root (SKILL.md, traps) |
