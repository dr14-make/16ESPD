---
name: dyad-modeling
description: The Dyad modeling loop — edit, compile, simulate and check against anchors in one warm Julia session.
disable-model-invocation: true
---

# Dyad modeling

The language lives in the repo's `agent_resources/` (skills `dyad-language`, `multibody`,
`forensic-debugging`, `package-management`; `docs/`; `stdlib_reference/`). Read the matching doc
before writing each construct: most compile failures are guesses that doc would have prevented. Build commands, versions and gotchas are in `docs/HANDOVER.md`; the task's plan doc
holds its anchors and house rules. Both win over this file.

## Setup, once per task

1. `free -g`, and run **one heavy process at a time**: a warm session at work, a test group, a
   compile, a render. Never two in parallel or one in the background beside another. An idle warm
   session may stay open through a compile or a render; `exit()` it before a test group. A Julia
   that vanishes without an error was killed for memory.
2. Open one **warm session** and run every Julia step of the task in it. A cold `julia` pays the
   library load on every call; a warm re-run of a model takes a fraction of a second.
   - Inside Herdr (`HERDR_ENV=1`): follow [`reference/warm-session.md`](reference/warm-session.md).
   - Elsewhere: one script per compile, holding every check for that compile, run in one `julia`
     process.

## The loop, per component

Each component reaches step 6 before the next one starts.

1. **Read.** The plan doc, the nearest existing component of the same kind (copy its shape), and
   `stdlib_reference/<Lib>/...dyad` for every connector, base class and part you reuse, its
   equations included: a reused part's regularization, cutoff or sign is your model's behavior.
   Take sign conventions from the connector. Before changing an existing component, `grep -rn
   <Name> dyad/ test/ slides/` for every user: benches, tests, and the guides, which hold copies
   of the code students paste. Check every path and location the brief names against the
   repo; follow the repo where they disagree, and say so in the report.
   *Done when* every connector, base class and part you will use has been read.
2. **Write the anchors** before simulating: steady state, a time constant, an energy or force
   balance, a band from the plan's reality-anchor table. Build each anchor formula from every
   part's equations — a loss or inertia term left out of the hand formula fails the test, not the
   model.
   - **An energy balance is a test only when every term is measured.** Integrate each term on its
     own, `der(E_i) = P_i` from that part's own power, and never define one term as the remainder
     of the others: that balance closes by construction. Put the change in stored energy into the
     balance, and keep out stored energy that reaches the sink without passing the measured path.
   *Done when* each check in step 6 has a number and a tolerance to meet.
3. **Write the component with its `test component` and `analysis`.** Every parameter a scenario
   varies is declared on the analysis and forwarded to the model.
   - **Reuse first:** `extends` the stdlib interface that already declares the connectors and
     their balance (`ElectricalComponents.Analog.Interfaces.TwoPin`,
     `RotationalComponents.Interfaces.PartialTorque`, …) — `find agent_resources/stdlib_reference
     -path '*Interfaces*'` before writing a pin. `PartialTorque` fits a bare torque source; a
     part with inertia between its source and its shaft composes an `Inertia` and declares its own
     `spline` and `support`.
   - **Derived defaults stay formulas:** `Q_nom = 40.0e3 * 3600.0 / 350.0`, not `411428.6`, so the
     derivation is checkable where its tag says `(derived)`.
   - **Compose a sub-assembly** from what every one of its users needs, and leave what varies
     between them (the driver, the scenario, the load) in the bench. A command converted into
     what a component actually imposes is computed from that component's present state, not from
     a constant taken at one operating point.
   - **Extend an existing component without breaking its users:** a new connector goes behind a
     structural flag that defaults to the old behavior, so every bench, test and guide copy runs
     unchanged (`agent_resources/docs` does not cover this):
     ```
     structural parameter use_u::Boolean = false
     u = RealInput() if use_u {^u}
     relations
       if use_u
         connect(u, inner.u) {^id8}
       else
         inner.u = 1.0
       end
     ```
     A change in what the component computes by default, one that would move a number a guide,
     test or other bench publishes, goes into a new sibling block instead, and the old one stays
     as it is.
   - **A clamped state** (an integrator with anti-windup): clamp its derivative,
     `der(x) = min(K * e, (x_max - x) / T)`, rather than the state itself.
   - **Lay out the diagram:** every part and port gets a `diagram` placement in the `_links`
     metadata, so the component opens laid out in Studio rather than stacked at the origin.
4. **Compile** all edits of the increment at once, with the CLI version HANDOVER names. Fix each
   diagnostic by reading the doc it points to; [`reference/errors.md`](reference/errors.md) maps
   diagnostics to causes. A diagnostic that returns unchanged means read, not edit.
   *Done when* the compile exits 0 (the license banner on stderr is not an error).
5. **Check `generated/` is fresh**: `git diff --stat generated/`, and `grep -rn <NewName>
   generated/` for each new name. A stale `generated/` runs the old model and passes.
   *Done when* every new or changed name appears there. A new sublibrary directory adds
   `include` lines to its parent's `module.jl` and `tests.jl`; any other change in a file you did
   not touch is compiler drift — stop and report it.
6. **Simulate in the warm session**, starting with `Revise.revise()` (restart instead after a
   deletion or rename):
   ```julia
   r = VehicleSystemsComponents.<Sub>.<Name>Transient(p = 0.3)   # <Sub>: dyad/Vehicle/Electric → Vehicle.Electric
   m = symbolic_container(r)                                     # the model: m.body.mass.v
   r.sol.retcode, r.sol[m.body.mass.v][end], r.sol(1.0, idxs = m.wheel.kappa)
   r.sol.ps[m.battery.R0]                                        # a parameter's value
   ```
   The result carries `spec`, `sol`, `sys`, `u0` and `p`. A `test component` has no analysis;
   run its cases with their assertions by including `generated/test_internals.jl` and then its
   `generated/<Sub>/<Name>_test.jl`.
   Vary scenarios through analysis keywords in the session; edit a default only when the model's
   own value is wrong. Prove a fix (initial value, guess, solver option) in the session before
   writing it into the `.dyad`.
   *Done when* every anchor from step 2 is met within its tolerance — `retcode == Success` alone
   is not a pass.
7. **Tests.** Add the `tests` metadata and plausibility assertions the plan asks for. A new
   test file gets its own group in the `GROUPS` table of `test/runtests.jl`.
   - Iterate in the warm session until the file passes, with the step doing what `run_group`
     does — the test files rely on the helpers being loaded first, and every path is absolute:
     ```julia
     using Test; cd("<worktree>/test")
     @testset "<group>" begin
         include("<worktree>/test/plausibility_helpers.jl")
         include("<worktree>/test/<file>.jl")
     end
     ```
   - A new sublibrary's generated cases alone: from `test/`, include
     `generated/test_internals.jl`, then `generated/<Sub>/tests.jl`, in a fresh module. The
     `generated` group is the whole library's suite; it earns its run only when a component
     carries `tests` metadata, which fills its `generated/**/<Name>_test.jl`.
   - Last, the groups, one at a time: `exit()` the warm session, then `mise run test:group
     <group>` in the foreground with the Bash timeout at its 600000 ms maximum. A group that
     outlasts it runs in the background with its output in a log, and nothing else heavy starts
     until it ends: wait with Monitor on an until-loop over the log that matches the summary line
     and the failure lines alike.

   Snapshot `.ref` files change only when the task says so, each with the change that moved its
   curve named.
   *Done when* every group you touched passes.
8. **Leave the lesson.** A gotcha the task cost you that no doc names — a solver trap, an API
   surprise, a convention — goes into `docs/HANDOVER.md` in the same commit, with the numbers that
   showed it.
   *Done when* each such gotcha has its HANDOVER entry, or the report says there was none.

## Traps no error message names

- **A regularized law has an operating envelope.** Tire slip, rolling resistance and friction laws
  in the stdlib regularize near zero and can overflow outside the range they were written for (the
  course's `RollingResistance` overflows below −0.71 m/s). Before choosing a driver or a start
  state, read the law's equations and keep the run inside that envelope; test it at the envelope's
  edges, such as a stop and a reversal.
- **A wall-clock criterion** (a run under 10 s) is measured and reported, or asserted with a
  wide margin: a shared machine makes a tight timing test flaky.

- **FBDF can report success on a frozen run.** Use the solver the plan names (Tsit5 or Rodas5P
  with `dtmax`), and check distance or state against an anchor.
- **Repeated identical algebraic blocks on Dyad 3.5** share a buffer under the default optimizer;
  HANDOVER says when an analysis needs `optimize = OptimizationLevel.None()`.
- **A clocked block** reads back as its last value (read the held side) and forces a solver step
  every sample period: on a long run, bypass it or confine it to the short analysis that needs it.
- **An algebraic equation with more than one solution** lets initialization settle on the wrong
  root and run on it with `Success`. A `guess` helps only on the variable the solver picks as the
  unknown, not on one it eliminated. Remove the wrong root: a small lag state in front of the
  variable (`T * der(x) = x_cmd - x`, with `T` well below the fastest time of interest) or a bound
  that excludes it. Anchor the initial value to catch it.
- **A step input makes integrated states drift**: sources switch with `ifelse` on `time`, which
  is no event, so the solver strides across the edge and counts input that never flowed. Put the
  edge in the analysis' `tstops` and drive it with a `Step` (a `Pulse` still misreads the edge);
  HANDOVER has the numbers. Anchor the integrated state to catch it.
- **A step that forces an instantaneous algebraic jump** aborts the solver at the edge even with
  the edge in `tstops`: the jump has no state to absorb it, which is a different fault from the
  missed edge above. Ramp the input over a time well below the fastest time constant.
- **A fast periodic source** (PWM, a chopper, thousands of edges a run) has no event per edge:
  write each edge as a ramp in `time`, keep `dtmax` below the shortest ramp, and show a result
  stays put when `dtmax` halves. Take averages and losses from energy states (`der(E) = P`); a
  sum over `saveat` aliases with the switching frequency.
- **`rm` prompts on this machine** and does nothing without a TTY; delete files you created with
  `\rm -f`.

## Refactors

A change whose bar is "the numbers do not move" — extracting a part, renaming, regrouping: follow
[`reference/refactor.md`](reference/refactor.md) before the first edit; its baseline has to be
captured from the old code.

## Notebooks, figures and guides

A notebook, an exported figure, a guide or a reference copy of a component: follow
[`reference/notebooks.md`](reference/notebooks.md).

## Debugging

Unbalanced, singular, initialization or retcode failures: load the `forensic-debugging` skill and
trace backward in the warm session.
