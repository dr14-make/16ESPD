# ABS braking distance — findings and fix plan

The wheel-speed-only ABS (`ABSControllerWheelOnly`) prevents wheel lock but **stops the car
later than a locked wheel** on every road surface. That breaks acceptance criterion 4 of
[`abs-controller-spec.md`](abs-controller-spec.md) (`d_wheel_only < d_locked`). Criterion 5
(a 2–15 Hz limit cycle) also fails: the controller cycles at about 1.4 Hz.

Reproduce with `notebooks/lecture03/01-abs.pluto.jl` (runtime: `dyad-3.4.0`).

## The numbers

Braking distance from 25 m/s (90 km/h), measured from brake application (0.5 s) until the
vehicle speed falls below 0.5 m/s. Default harness: `brake_demand = 6000 Nm`, `a_ref = 10`,
`k_inc_slow = 8000`.

| road µ | ABS | locked | ideal (`v0²/2µ·µ_A·g`) | sliding (`v0²/2µ·µ_S·g`) |
|---:|---:|---:|---:|---:|
| 1.0 | 55.7 m | 43.7 m | 31.9 m | 45.5 m |
| 0.5 | 98.2 m | 85.1 m | 63.7 m | 91.0 m |
| 0.2 | 228.6 m | 196.5 m | 159.3 m | 227.6 m |

The tire curve has the same shape on every surface (`road_mu` scales both `µ_A = 1.0` and
`µ_S = 0.7`), so an ABS that holds the adhesion peak should beat the locked wheel by 20–27%
everywhere. The plant allows it; the controller does not achieve it.

At µ = 1 the mean deceleration is 5.6 m/s² with ABS, 6.9 m/s² locked, and 9.8 m/s² possible.
Across the stop:

- 42% of the time the brake torque is below 2000 Nm, less than half of the tire's peak
  capacity of 4256 Nm (`F_z·µ_A·r`).
- 17% of the time the wheel is in the sliding region (`|κ| > 0.12`).
- Only 27% of the time is the slip near the peak (`0.02 ≤ |κ| ≤ 0.08`).

The two tuning knobs exposed by `ABSBrakeTransient` barely move the result. The best combination
(`k_inc_slow = 40000`, `a_ref = 6`) gives 52.3 m at µ = 1. At µ = 0.2, lowering `a_ref` to
`1.2·µ·g = 2.4` gives 231 m (worse than the 228.6 m default).

## One cycle, traced

µ = 1, t = 1.35–2.15 s. `λ̂` is the controller's slip estimate, `κ` the true slip.
`tau_cmd` is what the controller asks for; `tau_act` is the torque at the caliper, which
lags it by 30 ms.

| t [s] | phase | κ | λ̂ | a_w [m/s²] | tau_cmd [Nm] | tau_act [Nm] | what happens |
|---:|---|---:|---:|---:|---:|---:|---|
| 1.350 | increase | −0.032 | −0.003 | −12 | 4437 | 4197 | ramping toward the peak |
| 1.388 | hold | −0.041 | −0.011 | −17 | 4728 | 4501 | `a_w` spike → pre-hold, at the peak |
| 1.420 | release | −0.097 | −0.067 | −78 | 4669 | 4648 | release starts: **detection is in time** |
| 1.450 | release | −0.269 | −0.241 | −105 | 3469 | 4220 | caliper still ~4200 Nm; wheel dives |
| 1.500 | release | −0.352 | −0.322 | +16 | 1469 | 2584 | wheel turns around, release continues |
| 1.528 | hold | −0.238 | −0.198 | +98 | **362** | 1515 | `λ̂ > −0.2` ends release, 4300 Nm dumped |
| 1.574 | increase | −0.004 | +0.005 | +3 | 371 | 611 | wheel recovered, slow rebuild |
| 2.100 | increase | −0.035 | −0.004 | −12 | 4579 | 4339 | **0.53 s later** back at the peak |
| 2.144 | release | −0.092 | −0.061 | −66 | 4729 | 4628 | next cycle |

## Root cause

Detection is not the problem: the pre-hold fires at the adhesion peak and the release starts
at `κ ≈ −0.10`. The loss comes from what the modulator does after that.

1. **The release ends on a wheel condition, not on a torque condition.** Rule 1 keeps
   releasing while `λ̂ < −lambda_lock` (0.20). The wheel only starts to recover once the caliper
   torque falls below the sliding limit (`µ_S·F_z·r ≈ 2980 Nm`). The caliper lags the command
   by 30 ms, and the wheel then needs time to spin back up. Throughout that delay, `k_dec`
   keeps draining the command at 40 000 Nm/s. It ends at about 360 Nm, far below the 2980 Nm
   that would have been enough.
2. **The reapply starts from the bottom every cycle.** After the dump, `k_inc_slow` rebuilds
   the whole way from about 360 Nm to the peak at 8000 Nm/s, which takes 0.53 s of a 0.73 s
   cycle. The controller already learned where the peak is (the torque at release onset,
   about 4700 Nm) and throws that information away.
3. **Raising `k_inc_slow` alone does not help much.** A faster ramp shortens the under-braked
   phase but produces more cycles, and each one still dives to `κ ≈ −0.3` and dumps to near
   zero.

A secondary contributor is that `λ̂` reads about 0.03 less slip than the true value while
braking, because `v_ref` falls at `a_ref` and trails the car by about 0.3 m/s. This delays the
release by a few milliseconds and does not explain the distance.

## Ruling causes in and out

One parameter changed at a time in the wheel-only harness, at µ = 1. Plant and controller
parameters are overridden at run time; no Dyad source changed. Columns:

- `f` — releases per second.
- near peak / sliding — share of the stop at `0.02 ≤ |κ| ≤ 0.08` / at `|κ| ≥ 0.12`.
- mean torque — mean caliper torque; the tire limit is 4256 Nm.

| change | ABS | locked | `f` [Hz] | near peak | sliding | mean torque [Nm] |
|---|---:|---:|---:|---:|---:|---:|
| none (baseline) | 55.7 m | 43.7 m | 1.5 | 27% | 17% | 2403 |
| `k_dec` 40000 → 10000 | 47.4 m | | 1.2 | 26% | 42% | 2992 |
| `k_dec` 40000 → 5000 | 45.1 m | | 1.3 | 21% | 60% | 3303 |
| `lambda_lock` 0.20 → 0.40 | 47.1 m | | 1.7 | 31% | 22% | 2771 |
| `a_minus` 16 → 12 | 51.0 m | | 1.6 | 33% | 17% | 2621 |
| `T_brake` 30 → 10 ms | 43.9 m | 43.7 m | 2.2 | 40% | 20% | 3036 |
| `T_brake` 30 → 3 ms | 40.9 m | 43.7 m | 2.3 | 47% | 24% | 3271 |
| `sSlide` 0.12 → 0.30 (wider peak) | 42.5 m | 43.5 m | 1.8 | 45% | 14% | 3011 |
| `mu_S` 0.7 → 0.9 | 37.7 m | 34.5 m | 2.6 | 67% | 18% | 3677 |
| `mu_S` 0.7 → 1.0 (no drop after the peak) | 34.2 m | 31.3 m | 4.3 | 74% | 7% | 4184 |
| `J_w` 4 → 10 kg·m² | 46.4 m | | 1.4 | 34% | 20% | 2942 |

What this rules out and in:

- **Not the static-to-sliding friction switch.** The tire has no discrete switch: `µ` is one
  continuous function of slip (`TireFrictionCurve`). Removing the drop after the peak entirely
  (`mu_S = µ_A = 1.0`) still leaves ABS 3 m behind the locked wheel. A steeper drop punishes each
  overshoot harder, but the controller loses even when the drop is gone.
- **Not the switching frequency as such.** Frequency moves with the result in some rows and
  against it in others: `k_dec = 5000` cycles slower than baseline and stops 10 m shorter. It is
  a symptom of how each cycle is shaped, not a cause.
- **The distance follows the mean brake torque.** On the standard tire, more mean caliper torque
  means a shorter stop, with exceptions where the extra torque goes into a sliding wheel, which
  passes on only `µ_S`. The baseline controller brakes at about 55% of the tire's capacity on
  average, and that is where the distance goes.
- **The 30 ms actuator lag is what the controller fails to handle.** Cutting the lag to 3 ms
  makes the same logic beat the locked wheel (40.9 vs 43.7 m). Real brake hydraulics do lag
  tens of milliseconds, so the plant is right; the controller must work with the lag, not
  against it. Its release command keeps draining while the caliper catches up.
- **Parameter tuning is not a fix.** The parameter changes that shorten the stop do it by
  letting the wheel slide more (`k_dec = 5000`: 60% of the stop sliding). They approach the
  locked wheel from above without ever beating it, and they give up the steerability ABS exists
  for.

These results support step 2 below: end the release on torque, not on wheel recovery, and
reapply quickly to a remembered level.

## Fix plan

Three steps. Only step 2 changes the real controller; step 1 measures the target and step 3 is
conditional.

| step | what it does | fixes the controller? |
|---|---|---|
| 1. Ideal controller | A benchmark that reads the true slip. It shows the best stop this plant reaches with the 30 ms brake lag. | No. It sets the target for step 2. |
| 2. Modulator fix | The wheel-speed-only ABS stops releasing at a torque level and rebuilds quickly to a remembered level. | **Yes, on dry and wet roads.** This is the defect behind 55.7 m vs 43.7 m. |
| 3. Low-µ reference speed | Corrects the vehicle-speed estimate on slippery roads. | Only if step 2 leaves µ = 0.2 behind the locked wheel. |

Expected outcome: step 2 should beat the locked wheel at µ = 1.0 and 0.5. This is not yet proven.
The strongest evidence is that the current logic already beats the locked wheel when the brake
lag is cut to 3 ms (40.9 vs 43.7 m); step 2 targets that result with the real 30 ms lag. The
done-conditions below settle it, and step 1 shows how close to ideal it gets.

Run the steps in order. Steps 1 and 2 both edit `dyad/Vehicle/ABSController.dyad`, and step 2
measures itself against step 1.

### Step 1 — ideal-controller benchmark (spec §1, `ABSIdealController`)

Implement the idealized controller from the spec: true `κ`, bang-bang around
`lambda_target = 0.05`. Add it to the notebook as a third line.

- **Why first:** it shows whether this plant and actuator lag can come close to the ideal
  distance with a slip-holding controller. That gives step 2 a concrete target and separates
  "plant limitation" from "controller defect".
- **Done when:** `d_ideal` at µ ∈ {1.0, 0.5, 0.2} is within 15% of `v0²/(2µ·µ_A·g)` and below
  `d_locked`.

Agent prompt: [Prompt — step 1](#prompt--step-1-ideal-controller-benchmark).

### Step 2 — fix the modulator: remember the lock torque, release to a fraction of it

The standard ECU pressure-memory pattern (Bosch-style phase control). In `ABSModulator`:

1. **Lock torque memory `tau_lock`**, the value of `p` at the most recent release onset. It
   tracks `p` during the slow increase phase and before the first release, and is frozen from
   release onset until the fast reapply (item 3) completes. Without the freeze through the fast
   reapply, `tau_lock` would follow `p` down and the "reapply to `beta_reapply·tau_lock`" target
   would collapse onto `p` itself.
2. **End the release on torque:** release only until `p ≤ alpha_rel·tau_lock`
   (`alpha_rel ≈ 0.6`, just below the sliding limit), then HOLD while the wheel recovers. Do not
   keep draining pressure while waiting for the wheel.
3. **Fast step, then slow ramp:** once recovered, reapply at `k_inc_fast` up to
   `beta_reapply·tau_lock` (`beta_reapply ≈ 0.85`), then `k_inc_slow` from there so the wheel
   approaches the peak slowly.
4. **Hold-trap fallback.** On a slippery road `alpha_rel·tau_lock` can still exceed the sliding
   torque: at µ = 0.2 the margin is about 540 Nm against 596 Nm. The wheel would then never
   recover and would stay locked in HOLD. If the wheel has not started to recover within
   `T_hold_max` of entering HOLD (≈ 0.06 s, about twice the actuator lag), resume releasing.
5. Expose `alpha_rel`, `beta_reapply` and `T_hold_max` as parameters, and pass them through
   `ABSControllerWheelOnly`.

Expected effect: each cycle spends most of its time between 0.85 and 1.0 of the peak torque
instead of ramping up from near zero. That should raise the cycle frequency into the spec's
2–15 Hz and pull the mean torque toward the tire limit.

**Done when:**
- `d_wheel_only < d_locked` at µ ∈ {1.0, 0.5} (spec criterion 4);
- the `tau_cmd` limit cycle is between 2 and 15 Hz at µ = 1 (criterion 5);
- no sustained lock at µ = 0.2 (beating the locked wheel there is step 3);
- criteria 1, 2, 3 and 6 still pass, in particular locked-wheel recovery
  (`ABSLockedWheelRecoveryTransient`).

Agent prompt: [Prompt — step 2](#prompt--step-2-modulator-fix).

### Step 3 — low-µ reference speed (only if step 2 leaves µ = 0.2 behind)

At µ = 0.2 the car decelerates at about 2 m/s², while `v_ref` assumes up to `a_ref = 10`. Two
options from the spec, in order of cost:

- **Adaptive `a_ref`** (spec "Stretch"): learn the deceleration during stable phases and set
  `a_ref = clamp(1.2·a_hat, 1, 12)`. This stays wheel-speed-only.
- **Accelerometer reference** (spec §4, `ABSControllerAccel`): removes the estimation error
  entirely; it models an ESC-class ECU.

**Done when:** `d_wheel_only < d_locked` at µ = 0.2 with default parameters.

No prompt yet: write one only if step 2's results call for it.

## Out of scope here

- Re-tuning the existing parameters (`k_dec`, `lambda_lock`, `a_minus`) without the
  structural change in step 2. See "Ruling causes in and out": every tuning gain comes from more
  sliding, not from braking nearer the peak.
- Loose-surface behavior (gravel, deep snow), where a locked wheel's plowing makes ABS stop
  longer in real cars. The tire model has no such effect.

## Agent prompts

Copy each prompt to the Dyad agent as written. Run step 2 only after step 1 has landed.

### Prompt — step 1: ideal-controller benchmark

```text
Implement the idealized ABS benchmark, `ABSIdealController`, as specified in
`docs/abs-controller-spec.md` §1. Background: `docs/abs-braking-distance-findings.md`. The
wheel-speed-only ABS currently stops in 55.7 m vs 43.7 m for a locked wheel at µ = 1. We need a
benchmark that shows what this plant can achieve with good slip control, before we fix the real
controller.

Controller. Add `ABSIdealController` next to the existing controllers in
`dyad/Vehicle/ABSController.dyad`.
- Ports: `kappa` (RealInput, true contact slip, negative while braking), `v` (RealInput,
  vehicle speed, m/s), `demand` (RealInput, Nm), `tau_cmd` (RealOutput, Nm).
- Parameters: `lambda_target = 0.05`, `k_inc = 20000` Nm/s, `k_dec = 40000` Nm/s,
  `v_min = 1.5` m/s, `T_track = 0.01` s.
- Behavior: `rate = kappa < -lambda_target ? -k_dec : +k_inc`. Below `v_min`, `p` tracks the
  demand with time constant `T_track`; otherwise `der(p)` is the anti-windup-clipped rate: no
  increase while `p ≥ demand`, no decrease while `p ≤ 0`, and when `p > demand` pull `p` down
  with `(demand - p)/T_track`. Output `tau_cmd = clamp(p, 0, max(demand, 0))`; start from
  `p = 0`.
- The clipping logic is the same as in `ABSModulator`. Factor it out (a partial component or a
  small block) rather than copying it.

Harness.
- Add an ideal variant of the braking test. Wire `kappa ← wheel.kappa` and `v ←` the body speed
  (`body.mass.v`).
- Prefer the spec's `partial component ABSBrakeTestBase` holding the plant, demand step, road-µ
  source and initial conditions, with concrete harnesses for locked, wheel-only and ideal.
- Add an analysis `IdealBrakeTransient` with parameter `road_mu` (default 1.0), like the
  existing ones.

Constraints.
- Keep `ABSBrakeTransient` (parameters `road_mu`, `a_ref`, `k_inc_slow`) and
  `LockedBrakeTransient` (`road_mu`) working with unchanged names and behavior.
  `notebooks/lecture03/01-abs.pluto.jl` calls them and passes `stop=` as a keyword.
- Do not change the plant: `BrakeActuator`, `BrakedWheel`, `SlipWheel1D`, `TireFrictionCurve`,
  `VehicleBody`.
- Do not touch `ABSModulator` / `ABSControllerWheelOnly`; fixing them is a separate step.
- Runtime is the `dyad-3.4.0` Julia channel.

Tests. Add `Dyad.tests` metadata for the ideal harness covering:
- (a) the output contract `0 ≤ tau_cmd ≤ demand`;
- (b) no lock: at µ = 1.0 and 0.5, while `v > v_min`, `|wheel.kappa| < 0.2` except excursions
  shorter than 0.15 s;
- (c) a pass-through case with `brake_demand = 2000` Nm, below the friction limit, where
  `tau_cmd` equals the demand once settled.

Done when, reported as a table:
- Braking distance at µ ∈ {1.0, 0.5, 0.2} for ideal, wheel-only and locked. Measure from brake
  application (0.5 s) until `body.mass.v < 0.5` m/s; use a `stop` long enough to reach that,
  about 25 s at µ = 0.2.
- At every µ, `d_ideal < d_locked`, and `d_ideal` is within 15% of `v0²/(2·µ·µ_A·g)` (31.9 m at
  µ = 1).
- The `tau_cmd` switching frequency of the ideal controller at µ = 1.

If `d_ideal` misses the 15% band, do not tune the plant. Report the slip and torque traces so
we can see whether the actuator lag is the limit.
```

### Prompt — step 2: modulator fix

```text
Fix `ABSModulator` so the wheel-speed-only ABS stops shorter than a locked wheel. Read
`docs/abs-braking-distance-findings.md` first, especially "One cycle, traced", "Root cause"
and "Ruling causes in and out". This task is step 2 of its fix plan.

The defect.
- Detection is fine: the pre-hold fires at the adhesion peak, and the release starts at
  slip ≈ −0.10.
- The release ends on a wheel condition (`lambda_hat > -lambda_lock`). The caliper lags the
  command by 30 ms (`BrakeActuator`, `T = 0.03`) and the wheel needs time to spin back up, so
  the command keeps draining at `k_dec` throughout. It ends near 360 Nm when about 2980 Nm (the
  sliding limit) would do.
- It then rebuilds from there at `k_inc_slow`, which takes 0.53 s of each 0.73 s cycle.
- Mean caliper torque is about 2400 Nm against a 4256 Nm tire limit. With the 30 ms lag reduced
  to 3 ms, the same logic beats the locked wheel, so the lag handling is what needs fixing.
- Parameter tuning was tested and does not fix it: every gain came from more sliding.

The change. This is standard ECU pressure-memory logic, implemented in `ABSModulator`.
1. Lock torque memory `tau_lock`. It holds the value of `p` at the most recent release onset.
   Implement it as a state that tracks `p` (time constant `T_latch`) while in the slow INCREASE
   phase or before the first release. Freeze it from release onset until the fast reapply
   (item 3) completes. Use the same continuous-latch technique the modulator already uses for
   `active` and `recovering`.
2. End the release on torque. DECREASE stops once `p ≤ alpha_rel·tau_lock` (default
   `alpha_rel = 0.6`). The modulator then HOLDs, using the existing `recovering` latch and its
   exit condition (`lambda_hat > -lambda_1` and `a_w < a_plus`).
3. Fast reapply to a remembered level. After recovery, INCREASE at `k_inc_fast` while
   `p < beta_reapply·tau_lock` (default `beta_reapply = 0.85`), then at `k_inc_slow`.
4. Hold-trap fallback (required). On a slippery road, `alpha_rel·tau_lock` can still exceed the
   sliding torque. At µ = 0.2 the margin is about 540 Nm vs 596 Nm. The wheel would then never
   recover and stay locked in HOLD. Add a timeout: if the wheel has not started to recover
   within `T_hold_max` of entering HOLD (default 0.06 s, about twice the actuator lag), resume
   DECREASE. A timer state that integrates during HOLD and resets otherwise is fine.
   Alternatively, use an equivalent rule that guarantees release continues while the wheel is
   still locked.
5. Expose `alpha_rel`, `beta_reapply` and `T_hold_max` as `ABSModulator` parameters. Pass them
   through `ABSControllerWheelOnly`, the way the existing thresholds are passed.

Keep.
- The phase encoding (−1 decrease, 0 hold, 1 increase, 2 off).
- The output contract (`0 ≤ tau_cmd ≤ max(demand, 0)`, an integrated rate, never a
  proportional gain).
- Rule 1's `lambda_lock` branch, which is the locked-wheel recovery fix.
- The analysis names and parameters `ABSBrakeTransient(road_mu, a_ref, k_inc_slow)`,
  `LockedBrakeTransient(road_mu)`, the ideal-controller analysis, and `stop=` as a keyword.
  `notebooks/lecture03/01-abs.pluto.jl` depends on them.

Do not change. The plant (`BrakeActuator`, `BrakedWheel`, `SlipWheel1D`, `TireFrictionCurve`,
`VehicleBody`) or `ABSIdealController`.

Tests. All existing ABS tests must still pass, including `TestABSModulatorLocked` and
`ABSLockedWheelRecoveryTransient` (spec criterion 6). Add `Dyad.tests` cases for:
- (a) the hold trap: at µ = 0.2 the wheel does not stay locked, meaning `|wheel.kappa| < 0.2`
  while `v > v_min` except excursions shorter than 0.15 s;
- (b) pass-through: with `brake_demand = 2000` Nm the controller never leaves INCREASE/OFF.

Runtime is the `dyad-3.4.0` Julia channel.

Done when, reported as a table for µ ∈ {1.0, 0.5, 0.2} with ideal, wheel-only (before and after)
and locked:
- braking distance, measured from 0.5 s until `body.mass.v < 0.5` m/s, with `stop` long enough
  to reach it (about 25 s at µ = 0.2);
- mean caliper torque (`wheel.brake.tau_actual`) and the share of the stop near the peak
  (`0.02 ≤ |κ| ≤ 0.08`);
- release frequency.

Pass criteria:
- `d_wheel_only < d_locked` at µ = 1.0 and 0.5;
- the `tau_cmd` limit cycle is between 2 and 15 Hz at µ = 1;
- no sustained lock at µ = 0.2. Beating the locked wheel there is not required; that is step 3,
  the reference-speed fix.

If the defaults miss, tune `alpha_rel`, `beta_reapply`, `k_inc_slow` and `T_hold_max` only, and
report what you changed. Do not tune the plant.
```
