# ABS switching frequency: why the ideal controller loses, and what the controller needs

Research note answering two questions. First, why does even the true-slip `ABSIdealController`
stop the car later than a locked wheel? Second, what switching or modulation frequency does an ABS
need: 30 Hz valve switching, a ~15 Hz slip cycle, or something else?

The note has three kinds of evidence:

- **Literature** sections cite their sources.
- **Simulation** sections use a plain-Julia replica of `ABSIdealBrakeTest`. It reproduces the Dyad
  results exactly (53.7 / 97.5 / 201.1 m ideal and 43.7 / 85.1 / 196.5 m locked). The key rows were
  rerun in the Dyad model through parameter overrides; those rows are marked **(Dyad)**.
- Statements I could not verify are marked as such.

## Summary

1. **Real ABS frequencies.**
   - A production ABS runs its full slip and pressure cycle at **about 2–6 cycles per second**.
     That is measured Bosch ABS: 2–4/s on the front wheels on high µ, 4–6/s on the rear and on ice.
   - Inside each cycle, the valves pulse the pressure in steps of a few milliseconds.
   - Bosch's "up to 40 times per second" counts those pressure modulations. It is not the slip
     cycle. That is where the user's "~30 Hz" comes from.
   - I found no primary source for a PWM carrier frequency, a pressure rate in bar/s, or a
     caliper time constant.
2. **Plant realism.**
   - **Tire curve: unrealistically harsh.** It peaks at |κ| = 0.04 and is down to 0.70·µ_A by
     0.12. Burckhardt's dry-asphalt curve peaks at 0.17 and is still at 98% of its peak at 0.12.
     NHTSA measured a slide/peak ratio of 0.76–0.89 on paved surfaces.
   - **Wheel inertia: realistic.** J_w = 4 kg·m² is four wheels lumped, so 1 kg·m² per wheel.
   - **Brake demand: plausible.** It is 1.4× the lock torque.
   - **30 ms lag: plausible but not well sourced.**
   - Real ABS beats a locked wheel by about **10–13% on dry pavement and 11–23% on wet**
     (NHTSA, 9 cars).
3. **Why the ideal controller loses.**
   - `lambda_target = 0.05` sits **past the tire peak (0.04), on the unstable branch**.
   - A relay acting through an integrator and a 30 ms lag, on an unstable slip dynamic, has no
     small limit cycle. Each cycle grows until the saturations stop it: the wheel goes to full
     lock (κ ≈ −0.99), then the brake dumps to 0 Nm. That happens at 2.6 Hz.
   - Most of the lost distance (14.8 of about 22 m) is the under-braked rebuild from 0 Nm, not the
     sliding.
   - Moving the target just below the peak (**`lambda_target = 0.035`**) gives **35.6 m against
     43.7 m locked (Dyad)**. That controller cycles at 13 Hz.
   - The numerics are not misleading. I did find one real model defect: a pressure-integrator trap
     that locks the brake on when `k_inc` is large.
4. **Frequency study.**
   - With the target past the peak, no combination of `k_inc`, `k_dec`, hysteresis or
     `T_brake` ≤ 50 ms beats the locked wheel. The frequency stays at 0.8–4.4 Hz.
   - With the target before the peak, the relay settles into a small limit cycle. Its frequency
     is set by the plant, about √(a/T)/2π, which gives 13–18 Hz at T = 30 ms and 61 Hz at
     T = 3 ms.
   - **Frequency is an outcome, not a lever.** Faster rates on the same structure make results
     worse, not better.
5. **Structures that work with the 30 ms lag.** All three below beat the locked wheel at
   µ = 1.0, 0.5 and 0.2:
   - a relay on **predicted slip** κ + T_p·κ̇ with T_p ≈ T;
   - a **three-level increase/hold/decrease with lock-torque memory** triggered on predicted slip;
   - a continuous PI slip controller, used as the benchmark.

   They come within 2–12% of the drag-inclusive peak-friction bound. Pressure memory triggered on
   slip alone (κ < −0.05) only matches or narrowly beats the locked wheel.
6. **Recommendation.**
   - **Neither 30 Hz valve switching nor a 15 Hz slip-cycle target.** Do not specify a frequency.
     Specify phase lead (release on predicted slip or wheel deceleration), a shallow release with
     pressure memory, and a fast first build.
   - Keep valve pulses as an actuator detail, sized so one pulse is ≤ about 10% of the lock torque.
   - Fix the integrator trap.
   - Make the tire curve realistic, then retune the slip thresholds to the new peak.

## 1. Real ABS frequencies (literature)

| quantity | value | source | trust |
|---|---|---|---|
| Slip/pressure cycle, high µ | 2–4 cycles/s front, 4–6 rear | Day & Roberts, SAE 2002-01-0559, "Comparison with experiment" (measured on a Bosch ABS 5.2 car) [1] | primary, read |
| Slip/pressure cycle, ice | ~4–6 cycles/s front, slightly higher rear | [1] | primary, read |
| What sets the cycle rate | "The cycle frequency is a natural consequence of the wheel spin dynamics" | [1] | primary, read |
| Pressure modulation, Bosch | "reduces the brake pressure and raises it again up to 40 times per second" | Bosch milestones, 1978 [2] | primary, marketing |
| Pedal pulsation during regulation | 0.5–~6 Hz | Bosch patent US8186770 [3] | primary |
| ECU wheel-speed evaluation interval | 3 ms (Bosch); 6 ms program cycle (Aisin) | US5244258 [4]; US6606548 [5] | primary |
| Pressure-increase pulse width | 3 ms when ΔP > 10 MPa, longer when ΔP is small | US6606548 [5] | primary |
| Valve increase/decrease cycle | 24 ms cycle, 6 ms increase, 1–3 ms decrease | Toyota CRD US6182001 [6] | primary |
| Dump pulse / hold on low µ | ~10 ms dump, ~30 ms hold | Bosch US5499867 [7] | primary |
| Bosch 8-phase cycle | apply → hold at −a → dump at slip threshold → hold until +A (≈10·(+a)) → fast reapply → hold → slow stepped reapply at ~1/10 of the fast rate → dump; learns the lock-up slip | [1], Fig. 3, after Bosch *Driving-safety systems*, 2nd ed. | primary (reproduced figure) |
| Simulation thresholds | −a = −175 rad/s², +a = 50 rad/s², max slip 0.15 | [1], Appendix I | primary, but simulation defaults |
| Pressure rates | apply 5000 psi/s (~345 bar/s), slow apply 500 psi/s, release 10000 psi/s | [1], Appendix I | simulation defaults; the kPa column is inconsistent |
| PWM carrier of linearized inlet valves | not found | — | **unverified** |
| Hydraulic lag | first order plus delay is the standard model; values seen only in snippets (12 Hz bandwidth with 5 ms delay; 10 ms delay; 70 ms time constant) | Politecnico di Milano papers, not opened | **unverified** |

**Three frequencies, not one.** These are different quantities:

- **(a) Slip cycle.** One release-and-reapply of the wheel, at 2–6 Hz in production systems.
- **(b) Valve and pressure-step activity.** Pulses of 3–10 ms on a cycle of about 24 ms or more,
  which works out to tens per second. This is what the "40 times per second" counts.
- **(c) Hydraulic response.** The time constant or delay of the caliper pressure, tens of
  milliseconds. I found no well-sourced number for it.

The "~30 Hz" in the question is (b). Both the Dyad agent's 15–30 Hz PWM figure and the spec's
2–15 Hz range for (a) are reasonable as orders of magnitude. Only the 2–6 Hz slip-cycle figure is
measured.

## 2. Plant realism

| parameter | model | literature | verdict |
|---|---|---|---|
| Peak slip | 0.04 | Burckhardt: dry asphalt 0.17, wet asphalt 0.13, snow 0.06, computed from the parameters in [8]; "typical optimal slip λ* = 0.15" [8] | **too early** for pavement; snow-like |
| Drop after the peak | 0.70·µ_A at κ = 0.12 | Burckhardt dry: 0.98·µ* at 0.12, 0.87·µ* at 3λ*, 0.65·µ* at lock | **far too steep** |
| Slide/peak ratio | 0.70 | NHTSA skid numbers: dry concrete 0.83, dry asphalt 0.89, wet asphalt 0.76 [9]; Burckhardt at lock 0.64–0.68 | plausible in level, wrong in where it is reached |
| Wheel inertia | 4 kg·m² for 4 wheels = 1 per wheel | ~1.1–1.6 kg·m² per wheel and tire (secondary) | realistic |
| Brake lag | first order, T = 30 ms | first order plus delay is standard; numbers unverified | plausible, not well sourced |
| Brake demand vs. lock torque | 6000 / 4256 Nm = 1.41 | panic stops overshoot lock pressure | fine |

A note on wheel inertia: the literature helper reported J_w as "3× typical". That compared the
lumped 4 kg·m² against one wheel, so it does not hold.

**ABS benefit in real tests.** NHTSA tested 9 vehicles (SAE 1999-01-1287, Table 2) [9]. ABS
shortened the stop against the best ABS-disabled stop by:

- 9.8–12.7% on dry concrete;
- 11.4–17.2% on wet asphalt;
- 16.7–23.1% on wet polished concrete.

On loose gravel ABS stopped about 27% longer. The baseline included driver-modulated
"best effort" stops, so the gain over a purely locked wheel is at least this large.

**How the tire curve affects the comparison.**

- The triple-S curve gives a slip window only about 0.04 wide. Any overshoot past the peak costs
  30% of the friction.
- Its peak-µ/lock-µ gap of 30% makes the theoretical ABS gain 27%. That is about twice the
  measured real gain, so a good ABS should win comfortably on this plant.
- At the same time the narrow, early peak makes the controller much harder to tune than on a
  real tire.
- It also means `lambda_target = 0.05`, a sensible value for asphalt, lands on the falling branch
  here.

## 3. Why the idealized controller loses

### Mechanism

The slip dynamics, linearized around a slip λ, are

`δṡ = (r/(J·v))·δτ − a·δs`, with `a = r²·F_z·µ'(λ)/(J·v)`, where `s = |κ|`.

- **Before the peak** (µ' > 0) the slip is a fast stable lag. At λ = 0.03 and v = 25 m/s,
  a ≈ 220 rad/s.
- **At the peak** (µ' = 0) it is a pure integrator.
- **After the peak** it is unstable. At λ = 0.05, a ≈ −32 rad/s.

The ideal controller's loop is relay → integrator (p) → lag 1/(Ts+1) → slip.

- **Target before the peak.** The loop phase crosses −180° at ω ≈ √(a/T). That gives
  ≈ 13–20 Hz at T = 30 ms over the speed range. The describing function then predicts a small
  relay limit cycle, with a slip amplitude of order 10⁻³.
- **Target past the peak.** The phase is −270° − atan(ωT) + atan(ω/|a|). That never reaches −180°,
  so no small limit cycle exists. The oscillation grows until the saturations bound it:
  - the tire falls to µ_S;
  - p is clipped at 0 and at the demand.

  The result is a large cycle of full lock followed by a full dump.

The simulation matches both predictions:

- **Before the peak.** The cycle frequency scales as T^−½: 61 / 33 / 22.5 / 18.1 / 13.3 / 10.1 Hz
  for T = 3 / 10 / 20 / 30 / 50 / 80 ms at λ = 0.03. It also scales roughly with √µ.
- **Past the peak.** The baseline traces out the large cycle (µ = 1, t = 1.60–1.77 s):

| t [s] | κ | p (cmd) [Nm] | caliper τ [Nm] | µ used | phase |
|---:|---:|---:|---:|---:|---|
| 1.60 | −0.040 | 5166 | 4566 | 1.00 | apply; p leads τ by k_inc·T ≈ 600 Nm |
| 1.61 | −0.053 | 5266 | 4763 | 0.98 | release starts, τ is 500 Nm above the 4256 Nm limit |
| 1.63 | −0.158 | 4466 | 4792 | 0.70 | caliper still rising (lag); wheel dives |
| 1.69 | −0.426 | 2066 | 3148 | 0.70 | deepest slip; τ only now nears the 2980 Nm sliding limit |
| 1.75 | −0.156 | 0 | 892 | 0.70 | release kept draining while the wheel recovered: dumped to 0 |
| 1.77 | −0.003 | 216 | 493 | 0.12 | wheel recovered; ~0.24 s rebuild at 20000 Nm/s follows |

**Where the distance goes.** Each region's share is ∫(F_peak − |F_x|) ds / F_peak, at µ = 1:

| controller | distance | initial build | before peak, under-braked | past the peak (0.04–0.12) | sliding (≥ 0.12) | below v_min |
|---|---:|---:|---:|---:|---:|---:|
| ideal, `lambda_target` 0.05 (baseline) | 53.7 m | 3.47 m | **14.81 m** | 0.35 m | 4.64 m | 0.04 m |
| ideal, `lambda_target` 0.035 | 35.6 m | 3.47 m | 1.41 m | 0 | 0 | 0.03 m |
| predicted-slip relay (§5) | 34.4 m | 3.46 m | 0.19 m | 0 | 0 | 0.04 m |
| three-level with predicted slip (§5) | 34.9 m | 1.27 m | 2.85 m | 0 | 0 | 0.03 m |

The losses add up to more than d − d_bound because drag and rolling resistance recover about
1.5 m. The baseline loses most of its distance rebuilding from 0 Nm after each dump, not while
sliding. The initial 20000 Nm/s ramp from zero costs another 3.5 m, which a fast first build cuts
to about 1.3 m.

### Model checks

| suspect | finding |
|---|---|
| Integration accuracy | The replica uses fixed-step RK4. dt = 5, 10 and 20 µs all give 53.7 m. The Dyad Auto solver at tolerance 1e-6 gives the same distances (table §4). Not a factor. |
| `v_eps` = 0.5 m/s slip floor | Only acts below 0.5 m/s, after the measurement ends. Not a factor. |
| `w0` = 0.2 rad/s brake regularization | Acts only near a stopped wheel. It does not change the lock torque balance. Not a factor. |
| ABS cut-off `v_min` = 1.5 m/s | Costs 0.03–0.04 m in every controller. Not a factor. |
| `tau_max = brake_demand` saturation | Caps the brake at 6000 Nm, the same for every controller. Not a factor. |
| Initial transient | The 20000 Nm/s ramp from p = 0 costs about 3.5 m. It matters, but it is not the cause. |
| **`ABSPressureIntegrator` trap** | **Real defect.** The branch `p > demand → (demand − p)/T_track` outranks a release request. Its exponential pull-down never brings p back to ≤ demand. When the solver overshoots p past the demand, release is ignored for the rest of the stop. **(Dyad)** with `controller.k_inc = 80000`, p − demand = +0.28 Nm at t = 0.58 s and +1e-12 at t = 1.5 s, while `rate = −40000` and κ = −0.999: the wheel stays locked, giving 44.4 m and 0 releases. `ABSModulator` shares this integrator. Fix: in that branch use `min((demand − p)/T_track, requested_rate)`. All later experiments use this fix. |

## 4. Frequency study (simulation)

Defaults unless a row says otherwise:

- Plant: µ = 1, T_brake = 30 ms, triple-S tire.
- Ideal controller: `k_inc = 20000`, `k_dec = 40000` Nm/s, `v_min = 1.5`, continuous time.
- Locked wheel: 43.7 m. Drag-inclusive peak-friction bound: 31.2 m.

Column meanings:

- `f`: release onsets per second while v > 1.5 m/s.
- `F/F_pk`: mean tire force over the peak force.
- `near`: share of time at 0.02 ≤ |κ| ≤ 0.08.
- `slide`: share of time at |κ| ≥ 0.12.
- `κmax`: the deepest |κ|.

**`lambda_target`** (the stability boundary sits at the tire peak):

| `lambda_target` | d [m] | f [Hz] | F/F_pk | near | slide | κmax |
|---:|---:|---:|---:|---:|---:|---:|
| 0.02 | 47.4 | 24.3 | 0.68 | 0.33 | 0 | 0.021 |
| 0.025 | 40.9 | 21.5 | 0.80 | 0.97 | 0 | 0.027 |
| 0.03 **(Dyad 37.2 m, 18.1 Hz)** | 37.2 | 18.1 | 0.89 | 0.97 | 0 | 0.033 |
| 0.035 **(Dyad 35.6 m, 12.8 Hz)** | **35.6** | 12.9 | 0.94 | 0.97 | 0 | 0.045 |
| 0.04 **(Dyad 53.8 m)** | 53.8 | 2.6 | 0.58 | 0.24 | 0.27 | 0.992 |
| 0.05 (default) **(Dyad 53.7 m)** | 53.7 | 2.6 | 0.58 | 0.23 | 0.31 | 0.994 |
| 0.08 | 53.3 | 2.3 | 0.58 | 0.21 | 0.35 | 0.995 |

The best target depends on µ.

- **µ = 0.5** (locked 85.1 m): `lambda_target` 0.03 gives 70.9 m **(Dyad 71.0)**; 0.035 gives
  79.2 m; 0.05 gives 97.5 m.
- **µ = 0.2** (locked 196.5 m): `lambda_target` 0.03 gives 182.7 m **(Dyad 182.7)**; 0.035 gives
  189.2 m; 0.05 gives 201.1 m.

The fixed rates are too large compared with the lower lock torque, so the safe margin below the
peak shrinks.

**Rates.** These runs use the fixed integrator. Each cell is distance [m] / frequency [Hz].

With `lambda_target` = 0.05 (past the peak):

| | k_dec 10k | 40k | 160k | 640k |
|---|---|---|---|---|
| k_inc 5k | 52.7 / 0.8 | 59.9 / 0.9 | 55.8 / 1.0 | 61.6 / 0.9 |
| k_inc 20k | 47.5 / 1.8 | 53.7 / 2.6 | 55.5 / 3.2 | 53.7 / 3.5 |
| k_inc 80k | 48.0 / 3.4 (with k_dec 40k) | | | |
| k_inc 320k | 44.4 / 4.0 (with k_dec 40k) | | | |

The k_inc = 80k and 320k rows were run only with k_dec = 40k. Every regime with the target past
the peak loses. The best of them come close to the locked wheel only by sliding more (61–70% of
the time).

With `lambda_target` = 0.035 (before the peak):

| | k_dec 10k | 40k | 160k |
|---|---|---|---|
| k_inc 5k | 42.5 / 10.4 | 42.9 / 7.4 | 44.0 / 4.6 |
| k_inc 10k | 37.5 / 13.0 | 38.1 / 10.7 | 39.9 / 6.8 |
| k_inc 20k | 47.0 / 1.8 | **35.6 / 12.9** | 38.2 / 9.3 |
| k_inc 40k | 46.1 / 1.8 | 50.8 / 3.5 | 38.1 / 11.2 |
| k_inc 80k | 45.0 / 1.6 | 48.2 / 3.7 | 43.6 / 7.6 |

If the caliper overshoot (about k_inc·T) exceeds the margin between τ(λ) and the peak torque, the
loop falls back into the large cycle. At λ = 0.035 that margin is only about 100 Nm, and the
frequency collapses to 2–4 Hz.

**Actuator lag** (`wheel.T_brake`). Each cell is d [m] / f [Hz].

| T_brake | λ = 0.05 | λ = 0.03 | locked |
|---:|---:|---:|---:|
| 3 ms | 43.8 / 4.1 | 36.5 / 61 | 43.7 |
| 10 ms | 48.1 / 3.5 | 36.7 / 33 **(Dyad 36.7 / 33.1)** | — |
| 30 ms | 53.7 / 2.6 | 37.2 / 18 | 43.7 |
| 50 ms | 54.0 / 2.1 | 37.6 / 13 | — |
| 80 ms | 46.5 / 0.3 (mostly locked) | 38.2 / 10 | 43.8 |

With the target before the peak, the lag barely matters: going from 3 ms to 80 ms costs 1.7 m.
With the target past the peak, even 3 ms only ties the locked wheel.

**Hysteresis** (release at λ, reapply above λ − h):

| | h = 0 | 0.005 | 0.01 | 0.02 | 0.03 |
|---|---|---|---|---|---|
| λ = 0.035 | 35.6 m / 12.9 Hz | 36.9 / 7.5 | 38.9 / 5.6 | 46.0 / 3.3 | 56.4 / 2.7 |
| λ = 0.05 | 53.7 / 2.6 | 53.7 / 2.6 | 53.8 / 2.6 | 53.8 / 2.6 | 53.9 / 2.6 |

Hysteresis lowers the frequency and lengthens the stop. It does not help.

**ECU sample time** (controller zero-order hold at Ts):

| Ts | ideal λ = 0.035 | ideal λ = 0.03 | predicted-slip relay |
|---:|---:|---:|---:|
| 0 | 35.6 m / 12.9 Hz | 37.2 / 18.1 | 34.4 / 29 |
| 5 ms | 35.8 / 12.4 | 37.2 / 19.7 | 34.6 / 22 |
| 10 ms | 43.4 / 4.0 | 36.8 / 17.1 | 35.0 / 17 (κmax 0.7) |
| 20 ms | 40.7 / 8.0 | — | 38.9 / 7.6 |

A 3–6 ms loop, as in the patents, is enough. At 10–20 ms the loop delay starts to eat the margin.

**Answer to Q4.**

- No regime of the existing structure with `lambda_target` ≥ 0.04 beats the locked wheel at
  T_brake = 30 ms.
- With the target below the peak it wins by 15–19% at µ = 1.
- "Faster" is not better in itself. Larger rates raise the frequency only while the loop stays
  in the small cycle; beyond the margin they collapse it. Shorter lags raise the frequency with
  almost no change in distance.

## 5. Controller structures that work with a 30 ms lag

These controllers are prototypes in the replica (`freq/absim.jl`). They use true κ and v and the
fixed integrator.

- **Predicted-slip relay.** `release = κ + T_p·κ̇ < −λ`, with κ̇ from a filtered derivative
  (T_f = 3 ms), `k_inc = 20000`, `k_dec = 40000`.
- **Three-level with predicted slip** ("3-level-PS"):
  - first build at 80000 Nm/s;
  - on κ + T_p·κ̇ < −λ (T_p = 30 ms), remember `tau_lock = p` and release at 80000 Nm/s until
    p ≤ α·tau_lock;
  - hold until κ_pred > −`l_rec`, or for at most 60 ms before releasing further;
  - reapply at 80000 Nm/s to β·tau_lock;
  - ramp at `k_slow`.
- **Three-level with slip only** ("3-level-S"): the same logic triggered on raw κ < −`l_rel`. This
  is the findings-doc step 2 with ideal sensing.
- **PI slip.** A torque command `Kp·e + Ki∫e` with e = κ + λ_ref, clamped to [0, demand] with
  conditional integration. This is the benchmark the spec forbids for the real controller.
- **Known µ.** A constant 0.98 × the peak tire torque. An unrealizable reference.

Results are braking distances in metres, with the cycle rate in Hz in brackets.

| controller (parameters) | µ = 1.0 | µ = 0.5 | µ = 0.2 |
|---|---:|---:|---:|
| locked | 43.7 | 85.1 | 196.5 |
| drag-inclusive peak bound | 31.2 | 61.2 | 144.5 |
| ideal as shipped (λ = 0.05) | 53.7 (2.6) | 97.5 (3.8) | 201.1 (5.0) |
| ideal, λ = 0.03 | 37.2 (18) | 70.9 (14) | 182.7 (9.5) |
| **predicted-slip relay**, λ = 0.04, T_p = 0.03 | **34.4** (30) | **63.4** (27) | **149.4** (22) |
| predicted-slip relay, λ = 0.035, T_p = 0.02 | 35.1 (44) | 64.8 (35) | 154.0 (24) |
| **3-level-PS**, λ = 0.04, l_rec = 0.03, α = 0.6, β = 0.85, k_slow = 8000 | **34.9** (8.6) | **65.1** (16) | **151.0** (27) |
| 3-level-PS, same with α = 0.8, β = 0.95, k_slow = 4000 | 33.0 (13) | 67.7 (21) | 154.4 (23) |
| 3-level-PS, same with α = 0.85, β = 0.95, k_slow = 8000 | 36.9 (18) | 67.7 (26) | 151.4 (17) |
| 3-level-S, l_rel = 0.05, l_rec = 0.02, α = 0.6, β = 0.85, k_slow = 8000 | 42.4 (7.0) | 79.7 (9.7) | 189.8 (12.5) |
| 3-level-S, l_rel = 0.04, same | 39.6 (6.2) | 76.0 (11) | 167.6 (13) |
| PI, λ_ref = 0.035, Kp = 5e4, Ki = 2e6 | 32.8 | 62.6 | 146.5 |
| PI, λ_ref = 0.04, Kp = 1e5, Ki = 5e6 | 31.5 | 61.5 | 145.5 |
| known µ, 0.98·peak torque | 33.2 | 64.3 | 150.7 |

Two notes on the table:

- At µ = 0.2 some distances fall below the bound. That is because the bound is computed for
  constant peak force from 25 m/s down to 0.5 m/s, while the slow-speed tail is
  rolling-resistance dominated. Treat it as approximate.
- The gains over the locked wheel are 20–24% for the predicted-slip designs. On this tire the
  theoretical gain is about 27%.

What the results show:

- **Phase lead decides it.** T_p ≈ T_brake cancels the hydraulic lag. Triggering on raw slip at
  or past the peak (3-level-S) carries the wheel to κ ≈ −0.86 to −0.999 every cycle, even with
  pressure memory.
- **Wheel-speed equivalent.** κ̇ = (r·ω̇ − v̇)/v, so "κ_pred < −λ" is a threshold on wheel
  deceleration in excess of vehicle deceleration. That is the Bosch −a threshold, and it is what
  `ABSModulator`'s `a_minus` provides. The pre-hold is the right idea; the release must also be
  driven by it.
- **Pressure memory.** Release to α ≈ 0.6–0.8 of the lock torque, then reapply fast to
  β ≈ 0.85–0.95. This keeps the mean caliper torque at 0.91–0.97 of the tire limit. It is also
  more tolerant of sample time: 35.4 m at Ts = 10 ms, against 43.4 m for the plain relay.
- **Rates should scale with the lock torque at low µ.** With rates fixed for µ = 1, 3-level-PS
  with k_slow = 16000 degrades to 182 m at µ = 0.2.

**Valve PWM test.** The 3-level-PS slow ramp (λ = 0.04, l_rec = 0.03, α = 0.85, β = 0.95,
k_slow = 8000 average) is replaced by on/off pulses at 80000 Nm/s with duty 0.1.

| PWM | continuous | 5 Hz | 10 Hz | 15 Hz | 30 Hz | 60 Hz | 120 Hz |
|---|---:|---:|---:|---:|---:|---:|---:|
| µ = 1.0 | 36.9 | 38.0 | 36.7 | 36.4 | 36.7 | 36.8 | 36.8 |
| µ = 0.2 | 151.4 | 212.2 | 192.0 | 191.8 | 174.0 | 153.3 | 151.8 |

At µ = 1 the PWM rate is irrelevant from 10 Hz up, because the 30 ms lag smooths the pulses. At
µ = 0.2 it matters only through the **torque step per pulse**, k_slow/f:

- 30 Hz gives 267 Nm per pulse, 31% of the 852 Nm lock torque.
- 60 Hz gives 133 Nm, which is acceptable.

The requirement is pulse size, not frequency: one pulse should add ≤ about 10–15% of the lock
torque on the lowest-µ surface.

**A realistic tire changes the picture.** Burckhardt curves from [8] at µ_scale = 1. Each cell is
d [m], with frequency in Hz where relevant.

| surface (λ*, µ*) | locked | ideal as shipped (λ = 0.05) | predicted-slip relay, λ = λ*, rates ×(lock torque/4256) | 3-level-PS, λ = λ*, l_rec = 0.75λ*, α = 0.6, β = 0.85 | PI, λ_ref = 0.9λ* | bound |
|---|---:|---:|---:|---:|---:|---:|
| dry asphalt (0.17, 1.17) | 38.7 | 39.2 (13.5) | 30.2 (10) | 28.9 (8) | 27.2 | 26.8 |
| wet asphalt (0.13, 0.80) | 58.5 | 49.4 (11) | 42.3 (9) | 40.9 (8) | 39.3 | 38.8 |
| snow (0.06, 0.19) | 209.1 | 177.9 (6) | 155.0 (7) | 152.8 (21, µ = 1 rates) | 153.2 | 151.3 |

- A fixed `lambda_target = 0.05` sits far below the asphalt peak. It under-brakes and still loses
  on dry asphalt. A fixed slip target is wrong on some surface whichever value is chosen. That is
  why production ABS combines deceleration thresholds with learning the lock slip [1].
- With the gentler post-peak slope, the cycles slow to 7–10 Hz, closer to the measured 2–6 Hz.
- Burckhardt's lock/peak ratio of 0.65 still overstates the ABS gain (25–30%) compared with
  NHTSA's 10–13% on dry pavement. Real slide/peak ratios are 0.83–0.89 [9].

## 6. Recommendation

**Answer to the Dyad agent: target neither 30 Hz valve switching nor a 15 Hz slip cycle.**

- The slip-cycle rate is an emergent property of the tire slope, the inertia, the lag and the
  release logic. On this plant a correct design cycles at 9–30 Hz; on a realistic tire, 7–10 Hz.
  Production systems measure 2–6 Hz.
- Valve switching at tens per second is how a real valve block produces an average pressure rate.
  The integrated-rate model (`p` with ±k) already represents that average.
- If valve pulses are modeled, size them by torque step, not by frequency.
- **Replace spec acceptance criterion 5** (a 2–15 Hz limit cycle) with criteria that measure
  quality:
  - d < d_locked at every µ;
  - d within 15% of the drag-inclusive bound at µ ≥ 0.5;
  - |κ| ≤ 2·λ_peak for 95% of the controlled stop.
- Report the frequency without gating on it.

**Controller structure.** Fix `ABSModulator` with the following, in order of impact:

1. **Release on predicted slip, not on slip.** Start DECREASE when
   `lambda_hat + T_p·d(lambda_hat)/dt < −lambda_1`, or equivalently when
   `a_w − a_ref_est < −a_minus`. Use T_p ≈ T_brake = 0.03 s.
   - Target values on the current tire: `lambda_1` ≈ 0.04, at the peak; `a_minus` near
     v·0.04/T_p ≈ 30 m/s² at 25 m/s.
   - Rescale both if the tire changes.
2. **Shallow release with lock-torque memory.**
   - `tau_lock = p` at release onset.
   - Release at 80000 Nm/s to `alpha_rel = 0.6` (0.6–0.8 works).
   - Hold until predicted slip recovers past `l_rec = 0.03`, with `T_hold_max = 0.06` s.
   - Reapply at 80000 Nm/s to `beta_reapply = 0.85` (0.85–0.95).
   - Then ramp at `k_inc_slow = 4000–8000` Nm/s.
3. **Fast first build** at 80000 Nm/s until the first release. This saves about 2.2 m at µ = 1.
4. **Scale the rates with `tau_lock`** so low-µ steps stay small. Use `k_inc_slow` ≈ 1–2·tau_lock
   per second and `k_dec`, `k_inc_fast` ≈ 10–20·tau_lock per second.
5. **Fix the `ABSPressureIntegrator` trap** (§3). It also affects `ABSIdealController`.
6. Keep the ECU loop at ≤ 5 ms if the controller is ever sampled.

For `ABSIdealController` as a benchmark:

- On the current tire, set `lambda_target` to 0.03. At 0.035 it does better at µ = 1 (35.6 m) but
  worse at µ = 0.5 and 0.2.
- Better, add the predicted-slip term with T_p = 0.03 and λ = 0.04. That gives 34.4 / 63.4 /
  149.4 m against locked 43.7 / 85.1 / 196.5 m.

**Plant changes, only where the literature says the current value is unrealistic.**

- **Tire curve.** Move the peak to dry-asphalt-like values and flatten the drop:
  - `sAdhesion` ≈ 0.12–0.15;
  - `sSlide` ≈ 0.5–1.0;
  - `mu_S/mu_A` ≈ 0.75–0.85 for dry pavement, from NHTSA slide/peak 0.83–0.89 [9]. Burckhardt's
    0.65 at lock is harsher.

  This is the one parameter set clearly out of line with the literature. Retune
  `lambda_target`, `lambda_1` and `lambda_lock` to the new peak.
- **Keep:** J_w = 4 kg·m² (realistic for four wheels), `brake_demand` = 6000 Nm, and
  T_brake = 30 ms.
  - The lag is plausible but unsourced. The right controller is insensitive to it: 36.5 m at
    3 ms, 38.2 m at 80 ms.
- **Expected outcome on a realistic tire.** A correct ABS should beat the locked wheel by roughly
  10–25%, depending on `mu_S/mu_A`. On the current tire it wins by 20–24%.

## Reproduce

All files are in the session scratchpad, under `.../scratchpad/freq/`:

- `absim.jl`: the replica plant, the controllers and the metrics.
- `sweep1.jl` – `sweep6.jl` and `loss.jl`: the tables above.
- `dyadcheck.jl` and `trapcheck.jl`: the Dyad override checks on `ABSIdealBrakeTest`.

Run the replica with the default `julia`. Run the Dyad checks with `julia +dyad-3.4.0`.

## Sources

1. Day, T. D., Roberts, S. G., "A Simulation Model for Vehicle Braking Systems Fitted with ABS",
   SAE 2002-01-0559. https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf (read; cycle rates,
   phase description, Appendix I)
2. Bosch Mobility, company milestones (1978 ABS entry).
   https://www.bosch-mobility.com/en/company/milestones/ (read). Also the Bosch press release of
   19 May 2020: https://us.bosch-press.com/pressportal/us/en/press-release-10958.html (seen by the
   literature helper)
3. US8186770B2 (Bosch), pedal motion 0.5–6 Hz during regulation.
   https://patents.google.com/patent/US8186770B2/en
4. US5244258A (Bosch), 3 ms evaluation interval, pulsed build-up.
   https://patents.google.com/patent/US5244258A/en
5. US6606548B2 (Aisin), 6 ms program cycle, 3 ms increase pulses.
   https://patents.google.com/patent/US6606548B2/en
6. US6182001B1 (Toyota CRD), 24 ms valve cycle. https://patents.google.com/patent/US6182001B1/en
7. US5499867A (Bosch), ~10 ms dump, ~30 ms hold on low µ.
   https://patents.google.com/patent/US5499867A/en
8. Crocetti et al., arXiv:2211.02558 and arXiv:2211.10336: Burckhardt parameters (dry, wet, snow)
   after Burckhardt 1993 and Kiencke & Nielsen; "typical λ* = 0.15".
   https://arxiv.org/abs/2211.02558, https://arxiv.org/abs/2211.10336
9. Forkenbrock, Flick, Garrott, "A Test Track Study of Light Vehicle ABS Performance Over a Broad
   Range of Surfaces and Maneuvers", NHTSA, SAE 1999-01-1287, Tables 1–2.
   https://web.archive.org/web/20250822053247id_/https://www.nhtsa.gov/sites/nhtsa.gov/files/sae1999-01-1287.pdf

The literature helper, not I, read sources 3–9. Source [1] and the Bosch milestones page I checked
myself.

**Not accessible:** Bosch Automotive Handbook and the Reif *Brakes, Brake Control and Driver
Assistance Systems*, Savaresi & Tanelli, Rajamani, Gillespie, Kiencke & Nielsen, and the
limit-cycle papers (Tanelli et al. CDC 2007; Pasillas-Lépine VSD 2006). Their content is not cited
here beyond abstracts.
