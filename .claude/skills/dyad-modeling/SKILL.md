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

1. `free -g`, and keep to one model-loading Julia process: a Julia that vanishes without an error
   was killed for memory.
2. Open one **warm session** and run every Julia step of the task in it. A cold `julia` pays the
   library load on every call; a warm re-run of a model takes a fraction of a second.
   - Inside Herdr (`HERDR_ENV=1`): follow [`reference/warm-session.md`](reference/warm-session.md).
   - Elsewhere: one script per compile, holding every check for that compile, run in one `julia`
     process.

## The loop, per component

Each component reaches step 6 before the next one starts.

1. **Read.** The plan doc, the nearest existing component of the same kind (copy its shape), and
   `stdlib_reference/<Lib>/...dyad` for every connector and base class you extend. Take sign
   conventions from the connector.
   *Done when* every connector and base class you will use has been read.
2. **Write the anchors** before simulating: steady state, a time constant, an energy or force
   balance, a band from the plan's reality-anchor table.
   *Done when* each check in step 6 has a number and a tolerance to meet.
3. **Write the component with its `test component` and `analysis`.** Every parameter a scenario
   varies is declared on the analysis and forwarded to the model.
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
   r = VehicleSystemsComponents.<Sub>.<Name>Transient(p = 0.3)   # <Sub> = directory under dyad/
   m = symbolic_container(r)                                     # the model: m.body.mass.v
   r.sol.retcode, r.sol[m.body.mass.v][end], r.sol(1.0, idxs = m.wheel.kappa)
   r.sol.ps[m.battery.R0]                                        # a parameter's value
   ```
   The result carries `spec`, `sol`, `sys`, `u0` and `p`.
   Vary scenarios through analysis keywords in the session; edit a default only when the model's
   own value is wrong. Prove a fix (initial value, guess, solver option) in the session before
   writing it into the `.dyad`.
   *Done when* every anchor from step 2 is met within its tolerance — `retcode == Success` alone
   is not a pass.
7. **Tests.** Add the `tests` metadata and plausibility assertions the plan asks for. A new
   test file gets its own group in the `GROUPS` table of `test/runtests.jl`.
   - A new sublibrary's generated cases alone: from `test/`, include
     `generated/test_internals.jl`, then `generated/<Sub>/tests.jl`, in a fresh module. The
     `generated` group is the whole library's suite.
   - Groups: `exit()` the warm session, then `mise run test:group <group>` in the background;
     wait for its notification.

   Snapshot `.ref` files change only when the task says so, each with the change that moved its
   curve named.
   *Done when* every group you touched passes.

## Traps no error message names

- **FBDF can report success on a frozen run.** Use the solver the plan names (Tsit5 or Rodas5P
  with `dtmax`), and check distance or state against an anchor.
- **Repeated identical algebraic blocks on Dyad 3.5** share a buffer under the default optimizer;
  HANDOVER says when an analysis needs `optimize = OptimizationLevel.None()`.
- **Clocked variables** read back as their last value; read the held side.
- **A step input makes integrated states drift** at the default 1e-6 tolerance: the integrator
  steps across the edge and counts input that never flowed (`tstops` alone does not cure it).
  Set `abstol`/`reltol` around 1e-10 on the analysis and the test case, and anchor the
  integrated state. `automatic_discontinuity_detection = true` fails on Dyad's `ifelse`.
- **`rm` prompts on this machine** and does nothing without a TTY; delete files you created with
  `\rm -f`.

## Debugging

Unbalanced, singular, initialization or retcode failures: load the `forensic-debugging` skill and
trace backward in the warm session.
