# ABS controller family — specification

Three anti-lock brake controllers for the lumped straight-line braking model, from idealized to
realistic, plus the harnesses that compare them against a locked-wheel baseline.

| Variant | Measures | Purpose |
|---|---|---|
| **Ideal** | true contact slip `kappa`, true vehicle speed | benchmark: best achievable stop, no estimation error |
| **Wheel-only** | wheel angular speed `omega` | a basic ABS: everything inferred from wheel speed |
| **Wheel + accelerometer** | `omega` + body longitudinal acceleration | 4WD/ESC-class ABS: reference speed from an inertial sensor |

All three share one plant (`BrakedWheel` + `VehicleBody`) and one output contract, so their
stopping distances and slip traces are directly comparable.

## Context: what already exists

- `dyad/Vehicle/Wheel/BrakeActuator.dyad` — takes `tau_cmd` (Nm), saturates to `[0, tau_max]`,
  first-order hydraulic lag `T = 0.03 s`. **Do not change.** It is the valve/caliper plant.
- `dyad/Vehicle/Wheel/BrakedWheel.dyad` — inertia + brake + `SlipWheel1D`; publishes
  `kappa` (true slip, **negative while braking**). **Do not change.**
- `dyad/Vehicle/Wheel/SlipWheel1D.dyad` — triple-S friction curve: peak `mu_A = 1.0` at
  `|kappa| = sAdhesion = 0.04`, sliding plateau `mu_S = 0.7` from `|kappa| = sSlide = 0.12`.
  Every slip threshold below is tuned to this curve, **not** to the textbook 0.2.
- `dyad/Vehicle/ABSController.dyad` — current wheel-acceleration-only modulator. Known defect:
  a wheel that has already locked (or slips at a steady speed) has zero acceleration, so the
  controller reapplies full demand and the wheel stays locked. The wheel-only variant below
  replaces it.
- `dyad/Vehicle/ABSBrakeTest.dyad` — lumped test with `abs_enabled` switch; to be reworked
  into the harness set below.

Plant numbers for sanity checks (defaults): `m = 1400 kg`, `F_z = 13729 N`, `r = 0.31 m`,
`J_w = 4 kg·m²`, `v0 = 25 m/s`, `brake_demand = 6000 Nm`. The friction-limited brake torque
at `mu = 1` is `F_z·mu_A·r ≈ 4256 Nm`, so a 6000 Nm demand locks the wheel without ABS.

## What an ABS may do to the brake signal

Physical constraint, not a design choice: the ABS sits between the master cylinder and the
caliper and has an inlet and an outlet valve per wheel. It can **only** do three things:

| Action | Rate of `p` (brake torque state) |
|---|---|
| increase | `+k_inc` (fast before the first cycle, slow after) |
| hold | `0` |
| decrease | `-k_dec` |

Hence the shared output contract, binding on every variant:

1. `0 ≤ tau_cmd ≤ max(demand, 0)` at all times — ABS never adds braking.
2. When ABS is inactive, `tau_cmd` tracks `demand` (to within the pressure-state dynamics).
3. The controller output is the integral of a three/four-level rate, clipped — never a
   proportional/continuous gain on an error.

## Architecture

Split each controller into reusable blocks so the three variants differ only in the
estimation front end. Suggested names; keep them if nothing in the repo conflicts.

```
                     ┌──────────────────────────┐
 omega ─────────────►│ ReferenceSpeed estimator │── v_ref ──┐
 (a_x) ─────────────►│  (WheelOnly | Accel)     │           │
                     └──────────────────────────┘           ▼
 omega ──► WheelAccelEstimator ── a_w ──────────────► ABSModulator ──► tau_cmd
                                                      ▲          ▲
                             lambda_hat = f(omega,v_ref)   demand
```

- `ABSModulator` — phase logic + pressure-state integrator. Shared by wheel-only and accel
  variants.
- `ABSIdealController` — its own small block (no estimators, no phase logic).
- `ABSControllerWheelOnly`, `ABSControllerAccel` — compositions of the blocks above.

Place new controllers under `dyad/Vehicle/ABS/` (a new sublibrary) or next to the existing
`ABSController.dyad`, matching how `Wheel/` is organized. Delete or replace the old
`ABSController` only once the wheel-only variant passes its tests; update `ABSBrakeTest`
references accordingly.

### Sign conventions (all blocks)

- `omega` > 0 forward rolling. `v_w = omega·radius` is wheel surface speed.
- `a_w = radius·d(omega)/dt` — wheel **surface** acceleration in m/s², negative while braking.
  Expressing it in m/s² (not rad/s²) makes thresholds comparable to vehicle deceleration in g.
- Slip `lambda = (v_w - v)/max(v, v_eps)` — **negative while braking**, same sign as the
  plant's `kappa`. Thresholds are given as positive magnitudes and compared as `lambda < -λ1`.

## Block specifications

### 1. `ABSIdealController`

Bang-bang slip control on the true slip (MathWorks "Model an Anti-Lock Braking System"
structure), tuned to this tire.

Ports: `kappa` (RealInput, true slip), `v` (RealInput, true vehicle speed, m/s),
`demand` (RealInput, Nm), `tau_cmd` (RealOutput, Nm).

Parameters (defaults):

| Name | Default | Meaning |
|---|---|---|
| `lambda_target` | 0.05 | slip magnitude to hold; just past the 0.04 peak |
| `k_inc` | 20000 Nm/s | apply rate |
| `k_dec` | 40000 Nm/s | release rate |
| `v_min` | 1.5 m/s | below this ABS is off and `tau_cmd` follows demand |
| `T_track` | 0.01 s | how fast `p` follows a falling demand |

Behavior:

```
rate = kappa < -lambda_target ? -k_dec : +k_inc        # too much slip → release
active = v > v_min
der(p) = active ? clipped(rate) : (demand - p)/T_track
tau_cmd = clamp(p, 0, max(demand, 0))
```

`clipped(rate)` = the integrator anti-windup: no increase while `p ≥ demand`, no decrease
while `p ≤ 0`, and when `p > demand` (driver eased off) pull `p` down with
`(demand - p)/T_track`. Same helper is used in `ABSModulator`; write it once (a partial
component or a shared block) rather than twice.

Initial: `p = 0`.

### 2. `WheelAccelEstimator`

Filtered differentiator on wheel speed, output in m/s².

Ports: `omega` (RealInput), `a_w` (RealOutput). Parameters: `radius`, `T_filter = 0.005 s`,
`omega0` (initial filter state — set from `v0/radius` in the harness so the estimator does not
see a start-up step).

`a_w = radius·(omega - omega_f)/T_filter`, `der(omega_f) = (omega - omega_f)/T_filter`.
This is exactly the existing `ABSController` differentiator, scaled to m/s²;
`BlockComponents.Continuous.Derivative` (params `T`, `k`) is an acceptable substitute if it
initializes cleanly.

### 3. `ReferenceSpeedWheelOnly`

Estimates vehicle speed from wheel speed alone. Real ECUs follow the fastest of four wheels
and slope-limit the fall; with one lumped wheel there is only one to follow.

Ports: `omega` (RealInput), `v_ref` (RealOutput). Parameters:

| Name | Default | Meaning |
|---|---|---|
| `radius` | 0.31 m | |
| `a_ref` | 10.0 m/s² | maximum plausible vehicle deceleration; `v_ref` may fall no faster |
| `T_up` | 0.01 s | how fast `v_ref` catches a wheel that is faster than it |
| `v_ref0` | — | initial value; harness sets `v0` |

```
v_w = omega·radius
der(v_ref) = v_w > v_ref ? (v_w - v_ref)/T_up        # wheel faster → it is the truth
           : v_ref > 0  ? -a_ref                      # wheel slower → assume it is slipping
           : 0
```

Why this lets the controller detect lock: a locking wheel's `v_w` collapses within tens of
ms, while `v_ref` keeps descending at `a_ref`, so `lambda_hat` grows large.

Known limitation (document it in the docstring): on low-µ roads the true deceleration is
`≈ mu·g`, much less than `a_ref`, so `v_ref` falls too fast, `lambda_hat` under-reads, and the
wheel runs deeper into slip than intended. The harness exposes `a_ref` so this can be
demonstrated; see "Stretch: adaptive a_ref" below for the ECU-style fix.

### 4. `ReferenceSpeedAccel`

Same port set plus `a_x` (RealInput, measured body longitudinal acceleration, m/s², negative
when braking).

```
v_w = omega·radius
der(v_ref) = a_x + (v_w > v_ref ? (v_w - v_ref)/T_up : 0)
```

`v_ref` integrates the accelerometer and is only ever pulled **up** by the wheel — a braked
wheel is never faster than the car, so it is a valid upper-bound correction. Clamp `v_ref ≥ 0`.

Parameters: `radius`, `T_up = 0.05 s` (slower than wheel-only: the accelerometer is now the
primary source), `v_ref0`.

Sensor model belongs in the harness, not here (see harness section): the accelerometer reads
`a_x = der(body.mass.v) + g·sin(grade) + bias`, low-pass filtered. With a negative bias the
estimate drifts low; the wheel correction bounds it from above only — document that.

### 5. `ABSModulator` — phase logic

Inputs: `a_w` (m/s²), `v_ref` (m/s), `omega` (to form `lambda_hat`), `demand` (Nm).
Output: `tau_cmd`. Computes `lambda_hat = (omega·radius - v_ref)/max(v_ref, v_eps)`.

Parameters (defaults tuned for this plant — expose all of them):

| Name | Default | Bosch name | Meaning |
|---|---|---|---|
| `a_minus` | 16.0 m/s² | −a | wheel-decel spike: incipient lock. Must exceed the max vehicle decel (≈ 9.8 at µ = 1) |
| `a_plus` | 5.0 m/s² | +a | wheel is re-accelerating |
| `lambda_1` | 0.06 | λ1 | slip at which release starts (past the 0.04 peak) |
| `lambda_lock` | 0.20 | — | unconditional release: catches an already-locked wheel with `a_w ≈ 0` |
| `k_dec` | 40000 Nm/s | | release rate |
| `k_inc_fast` | 40000 Nm/s | | initial apply rate, before ABS has cycled |
| `k_inc_slow` | 8000 Nm/s | | re-apply rate after the first cycle |
| `v_min` | 1.5 m/s | | ABS off below this `v_ref`; demand passes through |
| `v_eps` | 0.5 m/s | | slip denominator floor, same as `SlipWheel1D` |
| `T_track`, `radius` | 0.01 s, 0.31 m | | |

Phases (priority order — first match wins):

| # | Condition | Phase | Rate | Latch effect |
|---|---|---|---|---|
| 0 | `v_ref < v_min` or `demand ≤ 0` | OFF | track demand | reset `active`, `recovering` |
| 1 | `lambda_hat < -lambda_lock`, or (`a_w < -a_minus` and `lambda_hat < -lambda_1`) | DECREASE | `-k_dec` | set `active`, set `recovering` |
| 2 | `a_w < -a_minus` (spike, slip still small) | HOLD (pre-hold) | 0 | — |
| 3 | `recovering` | HOLD (wheel spinning back up) | 0 | reset `recovering` when `lambda_hat > -lambda_1` **and** `a_w < a_plus` |
| 4 | otherwise, `active` | INCREASE slow | `+k_inc_slow` | — |
| 5 | otherwise | INCREASE fast | `+k_inc_fast` | — |

Then `der(p) = clipped(rate)` and `tau_cmd = clamp(p, 0, max(demand, 0))` exactly as in the
ideal controller.

Rule 1's `lambda_lock` branch is what fixes the current controller's locked-wheel defect.
Rule 3 is what stops the controller reapplying while the wheel is still deep in slip.

Publish the phase as an observable variable (`phase::Real`: −1 decrease, 0 hold, +1 increase,
2 off) so plots show the cycle.

#### Implementing the latches (`active`, `recovering`)

Phase memory needs state; `ifelse` alone is memoryless. The Dyad docs in
`agent_resources/docs/` show no `when`/`pre`/event syntax and the stdlib has no hysteresis
block, so the default is a **continuous latch**: a fast first-order state that relaxes toward
1 when set, 0 when reset, and toward its own rounded value otherwise:

```
target = set ? 1 : (reset ? 0 : (q > 0.5 ? 1 : 0))
der(q) = (target - q)/T_latch            # T_latch = 1 ms
latched = q > 0.5
```

If the Dyad compiler/MTK route does support discrete events (check `dyad-language` skill and
`agent_resources/docs/syntax.md` first), use them instead and say which in the docstring.
Either way the solver will see a discontinuous RHS; the existing models already use
`ifelse`-switched `der()` the same way, and `SlipWheel1D` notes that explicit RK solvers
handle this plant better than BDF.

### 6. Compositions

- `ABSControllerWheelOnly` — ports `omega`, `demand`, `tau_cmd`. Contains
  `WheelAccelEstimator` + `ReferenceSpeedWheelOnly` + `ABSModulator`. Parameters `radius`,
  `a_ref`, `omega0`/`v_ref0`, and pass-throughs for the modulator thresholds.
- `ABSControllerAccel` — ports `omega`, `a_x`, `demand`, `tau_cmd`. Same, with
  `ReferenceSpeedAccel`.

## Test harnesses

Rework `ABSBrakeTest` into a `partial component ABSBrakeTestBase` holding the plant, the
demand step, the road-µ source and all initial conditions (the current file's content minus
the controller). Then one concrete harness per variant, each adding its controller and
wiring `wheel.tau_cmd`:

| Harness | Controller input wiring |
|---|---|
| `ABSBrakeTestLocked` | `wheel.tau_cmd = demand.y` (no ABS) |
| `ABSBrakeTestIdeal` | `kappa ← wheel.kappa`, `v ← der(body.mass.s)` (or the body speed variable) |
| `ABSBrakeTestWheelOnly` | `omega ← wsensor.w` |
| `ABSBrakeTestAccel` | `omega ← wsensor.w`, `a_x ← accelerometer` |

Accelerometer model in `ABSBrakeTestAccel`: body acceleration (`der(body.mass.v)` or the
mass's acceleration variable) + `g·grade` + `accel_bias` (default 0), through a
`BlockComponents.Continuous.FirstOrder(T = 0.01)`. Expose `accel_bias` as a harness parameter.

The `abs_enabled` switch in the current harness goes away — the variant is chosen by harness,
not by a runtime multiplier.

Harness parameters to expose: `v0`, `brake_demand`, `brake_time`, `road_mu`, and for
wheel-only `a_ref`. Analyses: one `TransientAnalysis(stop = 6.0)` per harness with a
`road_mu` parameter, matching the current `ABSBrakeTransient` style.

## Acceptance criteria

Run every harness at `road_mu ∈ {1.0, 0.5, 0.2}` (lower µ may need a longer `stop`; the vehicle
must reach `v < 0.5 m/s` before the end).

Stopping distance `d = s(stop) - s(brake_time)`. Rough hand estimates at µ = 1: ideal ≈ 32 m
(`v0²/(2·mu_A·g)`), locked ≈ 45 m (`v0²/(2·mu_S·g)`).

1. **Output contract.** Every variant: `0 ≤ tau_cmd ≤ demand` over the whole run.
2. **Pass-through.** With `brake_demand = 2000 Nm` (below the µ = 1 friction limit) the wheel-only
   and accel controllers never leave INCREASE/OFF, and `tau_cmd` equals the demand once
   settled. Negative guarantee: ABS does not intervene when it is not needed.
3. **No lock.** For ideal / wheel-only / accel at µ = 1.0 and 0.5: while `v > v_min`,
   `|wheel.kappa| < lambda_lock` except for excursions shorter than 0.15 s.
4. **Ordering.** `d_ideal ≤ d_accel ≤ d_wheel_only < d_locked` at µ = 1.0 and 0.5. At µ = 0.2
   the wheel-only variant may break this with the default `a_ref`; that is the documented
   limitation. It must still hold with `a_ref = 0.2·9.81·1.2`.
5. **Controlled-stop performance.** At every road µ, `d < d_locked`. At µ ≥ 0.5, stopping
   distance is within 15% of the peak-friction bound, and `|κ| ≤ 0.08` for at least 95% of the
   controlled stop. Report release frequency as a diagnostic, but do not gate acceptance on it.
6. **Locked-wheel recovery.** Start the wheel-only harness with `initial wheel.inertia.w = 0`
   (wheel already locked at `v0`): the controller must release and the wheel must spin back up
   within 0.3 s. The current `ABSController` fails this; it is the regression test for the
   defect.

Criteria 2 and 6 are events a plot does not prove on its own — encode them as `Dyad.tests`
metadata expectations or harness-level checks. The rest are visual comparisons; one
comparison plot (four variants, `v`, `wheel.kappa`, `tau_cmd`) at µ = 1.0 is enough.

## Stretch: adaptive `a_ref`

Real wheel-speed-only ECUs learn the road: during stable phases (INCREASE, wheel following
`v_ref`), `-a_w` ≈ the true vehicle deceleration. Low-pass it and set
`a_ref = clamp(1.2·a_hat, 1.0, 12.0)`. This should make criterion 4 hold at µ = 0.2 with
the default settings. Do it only after criteria 1–6 pass.

## Out of scope

- Per-axle / four-wheel model and load transfer (would enable real "fastest wheel" reference).
- Sampled ECU loop (5–10 ms) and valve on/off PWM; the continuous rate integrator stands in.
- Brake-pressure (bar) domain: torque is the state throughout.
- Split-µ, yaw moment limitation, EBD.

## References

- MathWorks, *Model an Anti-Lock Braking System* —
  https://www.mathworks.com/help/simulink/slref/modeling-an-anti-lock-braking-system.html
- x-engineer, *ABS modeling and simulation (Xcos)* —
  https://x-engineer.org/anti-lock-braking-system-abs-modeling-simulation-xcos/
- US5332301A, *ABS pressure reduction when wheel deceleration exceeds a threshold relative to
  vehicle deceleration* — https://patents.google.com/patent/US5332301A/en
- Gerard, Pasillas-Lépine et al., *Improvements to a five-phase ABS algorithm for experimental
  validation*, Vehicle System Dynamics 50(10), 2012 —
  https://www.tandfonline.com/doi/abs/10.1080/00423114.2012.693188
