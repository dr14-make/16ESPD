# Dyad agent prompts — Lecture 1 refactor onto the hands-on car

Six tasks, in order. Hand them over one at a time and check the reported numbers before you
start the next. The rationale is in `docs/lecture-01-live-build-plan.md`.

These rules apply to every task:

- **The test expectations are the contract.** Every existing `tests` block keeps its
  `expect.initial` and `expect.final` values, and its `atol`. If a value moves, stop and report
  it; do not edit the expectation. The hands-on plants match `Vehicle.*` block for block, so a
  moved value means a wiring or parameter mistake.
- Keep the instance names `plant` and `controller` in every loop. The notebooks read paths like
  `loop.plant.v_kmh`, `loop.plant.engine.lag.x` and `loop.plant.body.mass.v`.
- Do not touch `dyad/Vehicle/`. Lectures 2 and 3 use it. The one exception is
  `FrictionProfile` in task 0, which only Lecture 1 uses.
- Compile and run the tests after each task, and commit the regenerated `generated/` files with
  the `.dyad` changes.
- Comments state constraints and invariants only, with no history ("previously", "was renamed
  from"). Write in US English.

---

## Task 0 — `FrictionProfile` raises grip instead of lowering it

`Vehicle.FrictionProfile` is `Pulse(amplitude = low, offset = 1.0, ...)`. A pulse outputs
`offset + amplitude` while it is on, so the "low-grip patch" outputs `1 + low`: with
`low = 0.05` the patch raises the friction multiplier to 1.05. This is why
`SlipCruiseIcePatch`'s `ice_patch` test barely moves (final speed 89.99954 km/h against a
90 km/h setpoint, slip 0.0016).

1. Set `amplitude = low - 1.0`, so the output is 1 outside the patch and `low` on it.
2. `TestFrictionProfile` only checks the output before and after the patch. Add a second test
   case that stops inside the patch (`stop = 0.75` with the existing `start_time = 0.5`,
   `duration = 0.5`) and expects `sink.y` = 0.2 there.
3. Re-run `SlipCruiseIcePatch`. Its `ice_patch` expectations are the one place in this whole
   refactor where values are meant to change. Update them to the new run and report the old and
   new values side by side: final `loop.plant.v_kmh`, final `loop.plant.kappa`, and the peak
   slip on the patch.

**Done when** both `TestFrictionProfile` cases pass, and on the patch the run shows wheelspin
(slip well above `sAdhesion = 0.04`) followed by recovery after the patch.

---

## Task 1 — Hands-on plants get parameters, and `GradeCar`

1. **`HandsOn.GradeCar`** (new file `dyad/HandsOn/GradeCar.dyad`). It is `HandsOn.Car` with
   `body = GradeBody(...)` in place of `Body()` and a `RealInput grade` wired to `body.grade`.
   Ports: `tau_cmd`, `grade`, `v_kmh`. Parameters, passed down to the parts:
   `structural parameter theta_e::Time = 0.3` and `parameter T_max::Torque = 150` to `engine`;
   `parameter m::Dyad.Mass = 1400` and `parameter CdA::Area = 0.63` to `body`. Give the diagram
   the same placements as `Car`, with the `grade` input on the left under `tau_cmd`.
   Tests: `flat` (grade 0, the same full-throttle-from-rest scenario as `Car`'s `case1`, with
   the same final speed 246.388 km/h) and `climb` (a constant grade of 0.1, reporting the
   terminal speed).

2. **`HandsOn.SlipCar`**: add `structural parameter theta_e` and `parameter T_max` passed to
   `engine`, and `parameter CdA` passed to `body`. Defaults stay unchanged. Do not add output
   ports; the slip ratio is read as `wheel.kappa`.

3. **`HandsOn.WheeledCar`**: add `theta_e`, `T_max`, `m`, `CdA` and `J_w`, passed down. Defaults
   stay unchanged.

4. Leave `HandsOn.Car` as it is. It is the model the students finished the hands-on with.

**Done when** every existing HandsOn test passes unchanged and `GradeCar`'s `flat` test
reproduces 246.388 km/h. Report `climb`'s terminal speed.

---

## Task 2 — `ClampingPID` becomes `CruiseController`

Rename `dyad/Lecture1/ClampingPID.dyad` to `CruiseController.dyad`, the component to
`CruiseController`, and the test component to `TestCruiseController`. Then make it read the way
the students build it:

1. Remove feed-forward entirely: the `u_ff` input, `add_ff` and `k_ff`. Remove `wp` and the
   unity `proportional` gain.
2. Rename `add_p` to `error` (`Add(k1 = 1, k2 = -1)`, from `u_s` and `u_m`) and `gain_pid` to
   `gain`. Chain: `error.y` → `add_pid.u1`; `add_pid.y` → `gain` → `limiter` → `y`.
3. Keep `add_d` (`Add(k1 = wd, k2 = -1)`), `derivative`, `integrator`, `zero_d`, `zero_i`,
   `limiter`, the `with_I`/`with_D` switches, `xi0`, `xd0`, and the clamping equation on
   `integrator.u`, with `control_error = error.y`.
4. Rewrite the docstring as a description of the controller, without comparing it to `LimPID`.
   Keep the two clamping conditions and why the same-sign condition matters.
5. Lay the diagram out left to right: `error`, then the three branches (P straight, `integrator`
   in the middle, `add_d` → `derivative` below) into `add_pid`, then `gain` → `limiter` → `y`.
   Put `zero_d` and `zero_i` next to the slot they fill.

**Done when** `TestCruiseController`'s `clamp_freeze` test passes with the values
`ClampingPID`'s had (y 3.0 → 5.0, integrator 0.0 → 2.0).

---

## Task 3 — `CruiseLoop` on `CruiseController` and `GradeCar`

In `dyad/Lecture1/CruiseLoop.dyad`:

1. `plant = VehicleSystemsComponents.HandsOn.GradeCar(theta_e, T_max, m, CdA)`.
2. `controller = VehicleSystemsComponents.Lecture1.CruiseController(with_I, with_D, k, Ti, Td,
   Nd, y_max, y_min, wd, xi0, xd0)`. Delete `zero_ff` and the `u_ff` connection. Remove the
   `Ni` and `wp` parameters from `CruiseLoop`, `CruiseLoopStep` and `CruiseLoopTransient`; they
   belonged to `LimPID`.
3. Keep the `xd0 = (wd - 1) * m0` seeding and its comment, and check that `Derivative(x0 = xd0)`
   seeds the same state `LimPID` did. If it does not, report it rather than guessing.
4. Rewrite the docstring: the loop around the students' car and controller, with `with_I` and
   `with_D` selecting the P checkpoint (end of section 03) and the PID checkpoint (end of
   section 05).

**Done when** `CruiseLoopStep`'s `p_only` test passes unchanged (final `loop.plant.v_kmh`
109.3). Then run `CruiseLoopTransient` with `with_I = true, with_D = true` at the defaults and
report the final speed and the peak of `loop.controller.y`.

---

## Task 4 — The remaining Lecture 1 models move onto the hands-on plants

Each item below swaps the plant, and the controller where one exists. Keep every test
expectation.

1. **`CarStepTest`**, **`WideOpenThrottle`**: `plant = HandsOn.Car()`. `Car` has no `grade`
   input, so delete the `road` source.
2. **`FeedforwardCruise`**: `plant = HandsOn.GradeCar(m, CdA)`.
3. **`WindupClimb.dyad`**:
   - Delete `ClampingCruiseLoop`. `ClampingCruiseClimb` now drives `CruiseLoop`, whose
     controller already clamps.
   - `CruiseClimb` is the back-calculation comparison. Give it its own loop,
     `BackCalcCruiseLoop`, which is today's `CruiseLoop` (with `LimPID`, `Ni`, `wp`, `zero_ff`)
     but with `plant = HandsOn.GradeCar(...)`.
   - Tests `backcalc` and `clamping` keep their values.
4. **`NoisyCruiseLoop`**: `GradeCar` plus `CruiseController`. Drop `Ni`, `wp` and `zero_ff` as
   in task 3. The `filtered_derivative` test keeps its values.
5. **`Sampler.dyad`** (`SampledCruiseLoop`): `plant = HandsOn.GradeCar(...)`. The
   `DiscretePIDStandard` controller stays; section 09 is a demo of the library's discrete
   controller.
6. **`SlipCruiseLoop`**: `plant = HandsOn.SlipCar(theta_e, T_max, m, CdA)` plus
   `CruiseController`. `SlipCar` reports `wheel_kmh`, not `wheel_rpm` or `kappa`, so update any
   test signal paths to `plant.wheel_kmh` and `plant.wheel.kappa`. Keep the `ice_patch`
   expectations task 0 set.
7. **`WheeledCruiseStep`** (in `WheeledCarPlant.dyad`): `plant = HandsOn.WheeledCar(T_max, J_w)`
   plus `CruiseController`. Move this component and its analysis into a new
   `dyad/Lecture1/WheeledCruiseStep.dyad`.

**Done when** every Lecture 1 test passes with unchanged expectations, and nothing under
`dyad/Lecture1/` except `BackCalcCruiseLoop`, `WheeledCarPlant` and `SlipCarPlant` references
`Vehicle.CarPlant` or `LimPID`. Report every test with its final values.

---

## Task 5 — Delete the superseded models

Run this only after the notebooks have been updated and re-run against tasks 1–4.

Delete `dyad/Lecture1/WheeledCarPlant.dyad` and `dyad/Lecture1/SlipCarPlant.dyad` with their
`generated/` files. Then grep `dyad/`, `notebooks/` and `slides/` for `ClampingPID`,
`ClampingCruiseLoop`, `WheeledCarPlant` and `SlipCarPlant`, and report every remaining hit.

**Done when** the package compiles, every test passes, and the grep is empty.
