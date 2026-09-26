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

## Fix plan

### Step 1 — ideal-controller benchmark (spec §1, `ABSIdealController`)

Implement the idealized controller from the spec: true `κ`, bang-bang around
`lambda_target = 0.05`. Add it to the notebook as a third line.

- **Why first:** it proves that this plant and actuator lag can reach close to the ideal
  distance with a slip-holding controller. That gives step 2 a concrete target and separates
  "plant limitation" from "controller defect".
- **Done when:** `d_ideal` at µ ∈ {1.0, 0.5, 0.2} is within 15% of `v0²/(2µ·µ_A·g)` and below
  `d_locked`.

### Step 2 — fix the modulator: remember the lock torque, release to a fraction of it

The standard ECU pattern (Bosch-style phase control). In `ABSModulator`:

1. **Record `tau_lock`**, the torque command at release onset. It is a sample-and-hold state:
   it follows `p` while not releasing and freezes when rule 1 fires. The same continuous-latch
   technique the modulator already uses works here.
2. **End the release on torque:** release only until `p ≤ alpha_rel·tau_lock`
   (`alpha_rel ≈ 0.6`, just below the sliding limit), then HOLD while the wheel recovers. Do not
   keep draining pressure while waiting for the wheel.
3. **Fast step, then slow ramp:** once recovered, reapply at `k_inc_fast` up to
   `beta_reapply·tau_lock` (`beta_reapply ≈ 0.85`), then `k_inc_slow` from there so the wheel
   approaches the peak slowly.
4. Expose `alpha_rel` and `beta_reapply` as parameters, and pass them through
   `ABSControllerWheelOnly` and the harness.

Expected effect: each cycle spends most of its time between 0.85 and 1.0 of the peak torque
instead of ramping up from near zero. That should raise the cycle frequency into the spec's
2–15 Hz and pull the mean torque toward the tire limit.

**Done when:**
- `d_wheel_only < d_locked` at µ ∈ {1.0, 0.5} (spec criterion 4);
- the `tau_cmd` limit cycle is between 2 and 15 Hz (criterion 5);
- criteria 1, 2, 3 and 6 still pass, in particular locked-wheel recovery
  (`ABSLockedWheelRecoveryTransient`).

### Step 3 — low-µ reference speed (only if step 2 leaves µ = 0.2 behind)

At µ = 0.2 the car decelerates at about 2 m/s², while `v_ref` assumes up to `a_ref = 10`. Two
options from the spec, in order of cost:

- **Adaptive `a_ref`** (spec "Stretch"): learn the deceleration during stable phases and set
  `a_ref = clamp(1.2·a_hat, 1, 12)`. This stays wheel-speed-only.
- **Accelerometer reference** (spec §4, `ABSControllerAccel`): removes the estimation error
  entirely; it models an ESC-class ECU.

**Done when:** `d_wheel_only < d_locked` at µ = 0.2 with default parameters.

## Out of scope here

- Re-tuning the existing parameters (`k_dec`, `lambda_lock`, `a_minus`) without the
  structural change in step 2. Only `k_inc_slow` and `a_ref` were swept (above); the other
  parameters are not exposed by the harness and were not tested. With the release still ending
  on wheel recovery, a slower `k_dec` would dump less but also let the wheel slide longer.
- Loose-surface behavior (gravel, deep snow), where a locked wheel's plowing makes ABS stop
  longer in real cars. The tire model has no such effect.
