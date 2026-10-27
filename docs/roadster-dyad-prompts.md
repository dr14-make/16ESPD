# Dyad agent prompts — Roadster hands-on

There are four tasks, for issue #64. Each prompt is self-contained: hand it to a fresh agent as
it is, with the preamble pasted above it.

**Order.** Task 3 depends on nothing and can run alongside tasks 1 and 2. Task 2 builds on task 1,
and task 4 needs both 2 and 3. Check the reported numbers against the bands in
`docs/roadster-dyad-tasks.md` before starting a dependent task.

**Merging.** Each task works on its own branch off `feat/roadster-plausibility` and stops at a
report. Merging back into `feat/roadster-plausibility` is a human step after reading the report.

> **Preamble.** Repository: `/home/dr14/CVUT/VehicleSystemsComponents`. Work in your own worktree,
> branched from the session branch:
> `wt switch --create feat/roadster-<short-task-name> --base feat/roadster-plausibility`.
> `wt` prints the worktree path rather than entering it, so work there by path.
>
> Read `docs/roadster-dyad-tasks.md`: its "Read before the first compile", its "Ground rules", and
> the section for your task. Sources and back-of-envelope numbers are in
> `docs/research_notes/Roadster plausibility/sources.md`.
>
> Dyad language: `agent_resources/skills/dyad-language/SKILL.md`. Stdlib source:
> `agent_resources/stdlib_reference/<Library>/<Path>.dyad`.
>
> Compile with `npx -y @juliacomputing/dyad-cli@3.5.0 compile .`, and confirm your change appears
> in `generated/` before trusting a test. Run the tests with
> `cd test && julia +dyad-3.5.0 --project=.. runtests.jl`.
>
> Stage files by name, never `git add -A`. Use Conventional Commits with `Refs #64`, and US
> English. Do not push, and do not merge.
>
> Report every acceptance number you measured, and say plainly if one misses its band. Do not
> move a band.

---

## Task 1 — Validate, verify and fix the tire-only launch

Section: "Task 1" of `docs/roadster-dyad-tasks.md`.

**Scope.** Commit f5c0990 holds an unreviewed draft:
- `dyad/Roadster/PowerLimitedMotor.dyad`
- `dyad/Roadster/AxleLoad.dyad`
- `dyad/Roadster/RoadsterLaunch.dyad`
- `dyad/Vehicle/Wheel/LoadedSlipWheel1D.dyad`

Its first runs gave 3.33 s for rear-wheel drive and 2.27 s for all-wheel drive. Do not assume
the draft is right. Check each equation and sign convention against the stdlib components it
mirrors, and work through every item under "Review these" in the task section.

**Changes.** Change whatever is wrong or unclear. Each change goes in its own commit, with the
problem and the reason in the body.

**Add.**
- A test component with Dyad test cases for both drive layouts.
- `test/roadster_plausibility.jl` with the closed-form checks from the acceptance table, included
  from `test/runtests.jl`.

**Done when** every acceptance row passes and the full suite is green.

**Report.**
- t60 for both drive layouts.
- The mass-sweep spread.
- Drive power at 26.82 m/s.
- The slip range.
- A verdict on each review item: kept or changed, and why.
- The suite's assertion count. A count near 70 means it ran from the wrong directory.

---

## Task 2 — Suction fan and the suction launch

Section: "Task 2". Depends on task 1. Branch from `feat/roadster-plausibility` after task 1 is
merged into it.

**Build.**
- `dyad/Roadster/SuctionFan.dyad`, with the interface and defaults in the task section.
- An inverted-hold test component.

**Wire the fan into `RoadsterLaunch`.** With the fan command at 0 it must reproduce task 1's
results exactly; check that before anything else. Start the fan at its target pressure drop
before the launch. Decide whether downforce loads the rolling resistance, and document the
choice in the docstring.

**Analyses.** Expose the fan command and the skirt gap on the launch analysis. Add the closed-form
checks to `test/roadster_plausibility.jl`.

**Report.**
- The pressure drop at 4,700 kgf.
- Fan power at the 3 mm and 10 mm gaps.
- The least pressure drop for inverted hold, and its power.
- t60 at full suction for both layouts, and which limit binds over the run (tire, torque or
  power).
- The `T_max` sweep.
- One paragraph on the teaching point: suction moves the limit from the tire to the drive.

---

## Task 3 — Cold-gas tank and nozzle

Section: "Task 3". Independent of tasks 1 and 2, so it can start now.

**Before writing anything,** search the stdlib for a compressible-gas connector or tank. If there
is none, use a pair of signals for the tank state, and say which you chose.

**Build.**
- `dyad/Roadster/AirTank.dyad`: polytropic blowdown with index `n`, 1.4 by default.
- `dyad/Roadster/ColdGasNozzle.dyad`: a choked orifice with ideal expansion, valve command 0 to 1,
  and thrust at a translational flange.
- A thrust-stand test component that runs the tank empty with the valve wide open.

**Below choking** (p/p_a < 1.893), either model the subsonic branch or close the valve below
2 bar. Document which.

**Add** the closed-form checks to `test/roadster_plausibility.jl`. The total-impulse reference is
a quadrature of `v_e dm` over the blowdown, written in the test, not copied as a constant.

**Report.**
- The initial air mass, thrust, ṁ and v_e.
- The pressure at half mass.
- Total impulse and air used for `n = 1.4` and for `n = 1`.
- The time the tank takes to fall below 80 % and 50 % of its initial thrust.

---

## Task 4 — Thrust launch and "can it fly?"

Section: "Task 4". Depends on tasks 2 and 3. Branch from `feat/roadster-plausibility` after both
are merged into it.

**Thrust launch.** Add the tank and the rear nozzles to `RoadsterLaunch`. With the valves shut it
must reproduce task 2's results exactly; check that first. Run three configurations:
- tires + thrust
- tires + suction + thrust
- all three with a 200 L tank

**Add `down_fraction`**: the share of thrust pushing the car down into `AxleLoad.downforce`
instead of forward. Sweep it from 0 to 1 for rear-wheel and all-wheel drive, each with suction off
and with full suction.

**Build `dyad/Roadster/VerticalHop.dyad`.** It has the car's mass, gravity, an `ElastoGap`-style
ground contact, and the tank with four downward nozzles sized to match the rear set. Add two
analyses:
- **Hop:** open-loop full thrust for `t_b`. Find `t_b` for an 8 m apex.
- **Hover:** a PI altitude hold at 2 m from a standing start, run until the valve saturates and
  altitude is lost.

**Add** the closed-form checks to `test/roadster_plausibility.jl`.

**Report.**
- t60 and air used to 60 mph, for each launch configuration, compared with Tesla's 0.81 s and
  under-0.59 s claims.
- The best `down_fraction` in each of the four cases, with its t60 curve, and one sentence on
  why: pushing down only pays while the tire is the limit and each newton gains more than one
  newton of drive.
- `t_b` and the air used for the 8 m hop.
- Hover time at the defaults, with the sweeps over mass (1,700–2,350 kg) and p0 (300–690 bar).
- One sentence each for the verdicts of steps 3 and 4.
