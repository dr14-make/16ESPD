# Lecture 1 — Studio screenshots

Capture these while you rehearse the build in this worktree, after Dyad agent tasks 1–4. The list
follows the build, so it doubles as a rehearsal script. Save the files to
`slides/images/lecture-01/` under the names given. Step numbers match the table in
`docs/lecture-01-live-build-plan.md`.

The hands-on deck's conventions apply to every capture:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- Keep the default zoom across one model's states, so successive shots line up when the deck
  steps through them.
- Plots use Studio's plot view with the legend visible and the signals named. Crop to the plot.
- Same window size for every shot. About 1600 × 1000 matches the hands-on images.

The recap reuses the hands-on images `step05-car.png`, `step07-grade-body.png` and
`step09-slip-wheel.png`, so the list does not repeat them.

## Section 01 — the car you built

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step01-step-test.png` | `CarStepTest` | Diagram: torque step source, `plant` (`Car`). |
| `step01-step-test-plot.png` | `CarStepTestTransient` | `plant.v_kmh` from 90 to 110 km/h, with the step at 50 s. |
| `step01-gradecar.png` | `HandsOn.GradeCar` | Finished diagram. The `grade` input is wired to `body.grade`. |

## Section 02 — closing the loop

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step02-loop.png` | `CruiseLoopStep` | The whole loop: `demand` step, `controller`, `plant` (`GradeCar`), `road`. This is the picture that never changes. |
| `step02-controller-shell.png` | `CruiseController`, in progress | Ports `u_s`, `u_m`, `y` and the `error` block only, before any gain. Show the parameter panel of `error` with `k1 = 1`, `k2 = -1`. |

## Section 03 — proportional

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step03-gain.png` | `CruiseController`, in progress | `error` → `gain` → `y`. |
| `step03-p-plot.png` | `CruiseLoopTransient`, P checkpoint | `loop.plant.v_kmh` settling at about 109.3 against `demand.y` at 110: the steady-state error. |

## Section 04 — proportional-integral

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step04-integrator.png` | `CruiseController`, in progress | `add_pid` (`Add3`) between `error` and `gain`. `integrator` on `u3`; the `Constant(0)` placeholder on `u2`. |
| `step04-pi-plot.png` | `CruiseLoopTransient`, `with_I = true` | `loop.plant.v_kmh` reaching 110, with `loop.controller.integrator.y` on a second axis. |

## Section 05 — PID

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step05-derivative.png` | `CruiseController`, in progress | `add_d` → `derivative` on `u2`. Show the parameter panel of `derivative`: `k = Td`, `T = Td/Nd`. |
| `step05-pid-plot.png` | `CruiseLoopTransient`, PID checkpoint | `loop.plant.v_kmh` and `loop.controller.y`. |

## Section 06 — windup

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step06-tmax.png` | `HandsOn.GradeCar` | The parameter panel with `T_max`, and `engine` selected so its `T_max = T_max` binding shows. |
| `step06-limiter.png` | `CruiseController`, in progress | `gain` → `limiter` → `y`. |
| `step06-climb.png` | `CruiseClimb` | The climb harness: `GradeProfile` driving `road`. |
| `step06-windup-plot.png` | `CruiseClimbTransient` | Speed, `loop.controller.y` and `loop.controller.integrator.y` through the climb and after it: the overshoot after the crest. |
| `step06-clamping-code.png` | `CruiseController`, code view | The `integrator.u = ifelse(...)` equation, scrolled so the whole equation fits. |
| `step06-clamping-plot.png` | `ClampingCruiseClimbTransient` | The same three signals as `step06-windup-plot.png`, on the same axes. |

## Section 07 — derivative and noise

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step07-noise-loop.png` | `NoisyCruiseStep` | `noise` inserted between `plant.v_kmh` and `controller.u_m`. |
| `step07-noisy-plot.png` | `NoisyCruiseTransient`, `wd = 1` | `loop.controller.y` chattering. |
| `step07-wd0-plot.png` | `NoisyCruiseTransient`, `wd = 0` | The same plot, on the same axes, with the setpoint kick gone. |

## Section 08 — tuning

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step08-params.png` | `HandsOn.GradeCar` | The parameter panel with `m` and `theta_e` exposed. |

## Section 09 — discretization (demo)

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step09-sampler.png` | `SampledCruiseLoop` | Clock, the two samplers, `DiscretePIDStandard`, the zero-order hold, `plant`. |

## Section 10 — wheel and slip

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step10-slip-loop.png` | `SlipCruiseIcePatch` | The loop with `plant` as `SlipCar`, and the friction profile on `mu_scale`. |
| `step10-ice-patch-plot.png` | `SlipCruiseTransient` | `plant.v_kmh` against `plant.wheel_kmh` across the patch: wheelspin is the gap between them. |
