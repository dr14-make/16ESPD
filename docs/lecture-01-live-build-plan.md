# Lecture 1 — live PID build on the hands-on car

Lecture 1 is reworked so the students build the cruise controller block by block, live, on top of
the car they built in the hands-on session. Every plot in the lecture then comes from a diagram
the students have on their own screen.

Companion documents:

- `docs/lecture-01-refactor-dyad-prompts.md` — the Dyad agent tasks that refactor the models.
- `docs/lecture-01-screenshots.md` — the Studio screenshots the deck and the guide page need.

## Decisions

**Format.** Three hours. All eleven deck sections stay. Students build every step along with the
lecturer; the only demo-only section is 09 (discretization).

**Recap.** It opens section 01, in three parts:

1. A map of the hands-on models: Engine → Driveline → Body → Car, with GradeBody and SlipCar as
   branches. Each model has its key equation and its step response.
2. The four Studio moves the build repeats: duplicate a component; add a parameter and pass it
   down; wire causal (`RealInput`/`RealOutput`) versus acausal (`Flange`/`Spline`) connectors;
   run and plot a transient analysis.
3. The plant numbers the later sections lean on (0.3 s Padé delay, 0.3 s torque lag, 150 N·m
   ceiling, 31.08 N·m holding torque at 90 km/h) are not a slide of their own: the front
   matter's parameter slide already shows them, and its notes say where each comes back.

Section 01's existing step test and K/τ/θ reading follow, run on `HandsOn.Car`. Before a section
brings in a new plant, one reminder slide recaps that plant.

**Plant.** Students build `GradeCar` at the end of section 01: duplicate `Car` and swap `Body`
for their `GradeBody`, then add a `grade` input. Section 02's hill needs it, and the loop runs on
`GradeCar` from then until section 10, which swaps in `SlipCar`. Plant parameters are added when
the story first needs them: `T_max` in 06, `m` and `theta_e` in 08. The reference `GradeCar`
carries all of them. All of Lecture 1 moves off `Vehicle.CarPlant` and the `Lecture1.*Plant`
duplicates onto the hands-on plants. `Vehicle.*` stays the library for lectures 2 and 3.

**Controller.** Its own component, `Lecture1.CruiseController`, with ports `u_s`, `u_m`, `y`.
The loop diagram (setpoint, controller, plant, road) is built once in 02 and never changes;
every later step happens inside the controller. The reference is today's `ClampingPID`, renamed,
with feed-forward and `wp` removed and `wd` kept. Its `with_I`/`with_D` switches give the two
catch-up checkpoints: P (end of 03) and PID (end of 05). `LimPID` survives only as the
back-calculation comparison in 06.

## Build steps

| Step | Section | Students do | Reference after the step |
| ---- | ------- | ----------- | ------------------------ |
| 1a | 01 | Run the step test on their `Car` | `HandsOn.Car`, `Lecture1.CarStepTest` |
| 1b | 01 | `GradeCar`: duplicate `Car`, `Body` → `GradeBody`, add a `grade` input | `Lecture1.Step01.GradeCar` |
| 2 | 02 | Loop: setpoint step, `CruiseController` shell, `GradeCar`, road constant. In the shell, `error = Add(k1=+1, k2=-1)` | — |
| 3 | 03 | `Gain(k)` from `error` to `y` | checkpoint **P**: `CruiseLoop(with_I=false, with_D=false)` |
| 4 | 04 | `Add3` between `error` and the gain; `Integrator(k=1/Ti)` on `u3`; `Constant(0)` holds the derivative slot on `u2` | — |
| 5 | 05 | Replace the `Constant(0)` with `Add(k1=wd, k2=-1)` → `Derivative(k=Td, T=Td/Nd)` | checkpoint **PID**: `CruiseLoop` |
| 6a | 06 | `T_max` parameter on `GradeCar`, passed to the engine | — |
| 6b | 06 | `Limiter(y_max, y_min)` between the gain and `y` | — |
| 6c | 06 | Climb harness with `Vehicle.GradeProfile`; watch the integrator wind up | `CruiseClimb` (LimPID) for comparison |
| 6d | 06 | Replace the `error → integrator` connection with the clamping equation | `ClampingCruiseClimb` |
| 7 | 07 | Insert `MeasurementNoise` between `plant.v_kmh` and `u_m`; then `wd = 0`, then vary `Nd` | `NoisyCruiseLoop` |
| 8 | 08 | Expose `m` and `theta_e` on `GradeCar` for the robustness sweep | `Lecture1.Step08.GradeCar` |
| 9 | 09 | Demo only | `SampledCruiseLoop` |
| 10 | 10 | Swap `GradeCar` → `SlipCar`, add a friction profile on `mu_scale` | `SlipCruiseLoop` |

Students use the reference instance names (`plant`, `controller`, `error`, `integrator`,
`derivative`, `limiter`), so a student's diagram and the notebooks read the same signal paths.

## Slides and notes

- Each build step has one build slide. It shows a Studio screenshot, a one-line recipe in the
  hands-on deck's style, and a link to that step on the guide page.
- The speaker notes on that slide carry the full instructions for the lecturer: what to drag in,
  which parameters to set, what to wire, and what the plot must show before moving on.
- The guide page is a new VitePress page, `slides/site/lecture/lecture-01/`. It has one anchored
  section per step: blocks, parameters, connections, the expected plot, and a pointer to the
  catch-up checkpoint.
- The speaker-note timings are rebalanced to 180 minutes.
- The intro deck's schedule (`intro/sections/04-schedule.md`) is reordered so the hands-on comes
  before this lecture.

## Notebooks

They are updated and re-run last. Their figures are regenerated and compared with the current
ones. The hands-on plants match `Vehicle.*` block for block, so any changed curve means the
refactor broke something. The old models are deleted only once every notebook passes.

Paths the notebooks read that change with the controller:

- `05-pid`: `loop.controller.proportional.y` → `loop.controller.error.y`.
- `06-windup`: `loop.controller.add_ff.y` (the pre-limiter command) → `loop.controller.gain.y`.
- `10-wheel-and-slip`: `plant.kappa` → `plant.wheel.kappa`; `wheel_rpm` → `wheel_kmh`.

## Order of work

1. Docs (this file, the prompts, the shot list), committed first.
2. Dyad agent tasks 1–4.
3. Rehearse the build in Studio, capturing the screenshots on the way.
4. Deck sections, speaker notes, guide page, schedule fix.
5. Notebooks re-run and figures compared.
6. Dyad agent task 5: delete the superseded models.

If step 5 runs out of time before the lecture, the current figures remain valid and the old
models stay in place.
