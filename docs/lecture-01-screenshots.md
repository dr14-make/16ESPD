# Lecture 1 — Studio screenshots

The diagrams are Studio screenshots of the `Lecture1.StepNN` models, which hold the student's
components exactly as they stand after each step, under the names the guide gives them. The one
exception is section 09, a demo on the reference `SampledCruiseLoop`. The plots are not
screenshots: `notebooks/lecture01/step-plots.jl` renders them from the same models in the
hands-on plot style, so a model change is one re-run away from new figures. The list follows the
build, so it doubles as a rehearsal script. Save the files to `slides/images/lecture-01/` under
the names given. Step numbers match the table in `docs/lecture-01-live-build-plan.md`.

The hands-on deck's conventions apply to every diagram:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- Every controller state uses the same fit, scroll and crop box, so successive shots line up.
- A shot that needs a parameter panel shows it over the diagram, with the toolbar masked out.
- Same window size for every shot. About 1600 × 1000 matches the hands-on images.

The recap reuses the hands-on images `step05-car.png`, `step07-grade-body.png` and
`step09-slip-wheel.png`, so the list does not repeat them.

## Section 01 — the car you built

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step01-step-test.png` | `CarStepTest` | Diagram: torque step source, `plant` (`Car`). |
| `step01-step-test-plot.png` | `CarStepTestTransient` | `plant.v_kmh` from 90 to 110 km/h, with the step at 50 s. |
| `step01-gradecar.png` | `GradeCar` | Finished diagram. The `grade` input is wired to `body.grade`. |

## Section 02 — closing the loop

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step02-loop.png` | `CruiseLoopStep` | The student loop, flat: `demand` step, `controller` (`CruiseController`), `plant` (`GradeCar`), `road` constant, and the feedback wire `plant.v_kmh → controller.u_m`. This is the picture that never changes. |
| `step02-controller-shell.png` | `CruiseController`, in progress | Ports `u_s`, `u_m`, `y` and the `error` block only, before any gain. Show the parameter panel of `error` with `k1 = 1`, `k2 = -1`. |

## Section 03 — proportional

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step03-gain.png` | `CruiseController`, in progress | `error` → `gain` → `y`. |
| `step03-p-plot.png` | `CruiseLoopTransient`, P checkpoint | `plant.v_kmh` settling at about 109.3 against `demand.y` at 110: the steady-state error. |

## Section 04 — proportional-integral

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step04-integrator.png` | `CruiseController`, in progress | `add_pid` (`Add3`) between `error` and `gain`. `integrator` on `u3`; the `Constant(0)` placeholder on `u2`. |
| `step04-pi-plot.png` | `CruiseLoopTransient`, `with_I = true` | `plant.v_kmh` reaching 110, with `controller.integrator.y` on a second axis. |

## Section 05 — PID

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step05-derivative.png` | `CruiseController`, in progress | `add_d` → `derivative` on `u2`. Show the parameter panel of `derivative`: `k = Td`, `T = Td/Nd`. |
| `step05-pid-plot.png` | `CruiseLoopTransient`, PID checkpoint | `plant.v_kmh` and `controller.y`. |

## Section 06 — windup

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step06-tmax.png` | `GradeCar`, right after step 6a | The parameter panel with `T_max` as the only exposed parameter, and `engine` selected so its `T_max = T_max` binding shows. |
| `step06-limiter.png` | `CruiseController`, in progress | `gain` → `limiter` → `y`. |
| `step06-climb.png` | `CruiseClimb` | The climb harness: `road` is the `Pulse`, wired to `plant.grade`; `demand` is the `Constant(k = 130)`. |
| `step06-windup-plot.png` | `CruiseClimbTransient` | `plant.v_kmh`, `controller.y` and `controller.integrator.y` through the climb and after it: the overshoot after the crest. |
| `step06-clamping-code.png` | `CruiseController`, code view | The `integrator.u = ifelse(...)` equation, scrolled so the whole equation fits. |
| `step06-clamping-plot.png` | `CruiseClimbTransient`, re-run after step 6d | The same three signals as `step06-windup-plot.png`, on the same axes, with clamping. |

## Section 07 — derivative and noise

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step07-noise-loop.png` | `NoisyCruiseStep` | `noise` inserted between `plant.v_kmh` and `controller.u_m`. |
| `step07-noisy-plot.png` | `NoisyCruiseTransient`, `wd = 1` | `controller.y` chattering. |
| `step07-wd0-plot.png` | `NoisyCruiseTransient`, `wd = 0` | The same plot, on the same axes, with the setpoint kick gone. |

## Section 08 — tuning

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step08-params.png` | `GradeCar`, right after adding `m` and `theta_e` | The parameter panel with `T_max`, `m` and `theta_e` exposed. |

## Section 09 — discretization (demo)

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step09-sampler.png` | `SampledCruiseLoop` | Clock, the two samplers, `DiscretePIDStandard`, the zero-order hold, `plant`. |

## Section 10 — wheel and slip

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step10-slip-loop.png` | `SlipCruiseIcePatch` | The loop with `plant` as `SlipCar`, `demand` as `Constant(k = 90)`, and the `friction` pulse wired to `plant.mu_scale`. |
| `step10-ice-patch-plot.png` | `SlipCruiseTransient` | `plant.v_kmh` against `plant.wheel_kmh` across the ice patch from 4 to 12 s, `stop = 45`: wheelspin is the gap between them. |

## Where each state lives

Each build step has its own subpackage, `dyad/Lecture1/StepNN/`, holding the student's
components exactly as they stand at the end of that step, under the guide's names. Open the
component below in Studio for the diagram, or run the analysis for the plot. Blocks keep their
coordinates from step to step, so successive shots of one component line up. The same
subpackages are the catch-up checkpoints for every step.

| File | Component | Analysis |
| ---- | --------- | -------- |
| `step01-step-test.png` | `Lecture1.Step01.CarStepTest` | — |
| `step01-step-test-plot.png` | — | `Lecture1.Step01.CarStepTestTransient` |
| `step01-gradecar.png` | `Lecture1.Step01.GradeCar` | — |
| `step02-loop.png` | `Lecture1.Step02.CruiseLoopStep` | — |
| `step02-controller-shell.png` | `Lecture1.Step02.CruiseController` | — |
| `step03-gain.png` | `Lecture1.Step03.CruiseController` | — |
| `step03-p-plot.png` | — | `Lecture1.Step03.CruiseLoopTransient` |
| `step04-integrator.png` | `Lecture1.Step04.CruiseController` | — |
| `step04-pi-plot.png` | — | `Lecture1.Step04.CruiseLoopTransient` |
| `step05-derivative.png` | `Lecture1.Step05.CruiseController` | — |
| `step05-pid-plot.png` | — | `Lecture1.Step05.CruiseLoopTransient` |
| `step06-tmax.png` | `Lecture1.Step06a.GradeCar` | — |
| `step06-limiter.png` | `Lecture1.Step06b.CruiseController` | `Lecture1.Step06b.CruiseLoopTransient` for the re-run |
| `step06-climb.png` | `Lecture1.Step06c.CruiseClimb` | — |
| `step06-windup-plot.png` | — | `Lecture1.Step06c.CruiseClimbTransient` |
| `step06-clamping-code.png` | `Lecture1.Step06d.CruiseController`, code view | — |
| `step06-clamping-plot.png` | — | `Lecture1.Step06d.CruiseClimbTransient` |
| `step07-noise-loop.png` | `Lecture1.Step07.NoisyCruiseStep` | — |
| `step07-noisy-plot.png` | — | `Lecture1.Step07.NoisyCruiseTransient`, with `controller` set to `wd = 1`, `xd0 = 0` |
| `step07-wd0-plot.png` | — | `Lecture1.Step07.NoisyCruiseTransient` as shipped (`wd = 0`, `xd0 = -90`) |
| `step08-params.png` | `Lecture1.Step08.GradeCar` | — |
| `step09-sampler.png` | `Lecture1.SampledCruiseLoop`, the reference | — |
| `step10-slip-loop.png` | `Lecture1.Step10.SlipCruiseIcePatch` | — |
| `step10-ice-patch-plot.png` | — | `Lecture1.Step10.SlipCruiseTransient` |

`Step02.CruiseLoopTransient` exists, as it does for the students, but does not run: in step 2
`controller.y` has nothing driving it.
