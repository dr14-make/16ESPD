# Brake system implementation plan: hydraulics, vacuum booster, valve-level ABS

This plan turns `reports/Passenger car brake system modeling.md` (the research) into models,
tests and Lecture 3 notebooks. The work has three steps, each split into increments. Do not start
an increment until the previous one simulates **and** passes its completion criteria. That is the
same rule `docs/lecture-03-preparation.md` uses for the 2D vehicle.

Background documents:
- `reports/Passenger car brake system modeling.md`: physics, equations, parameter sources, and
  why each default was chosen. The component tables in its last section are the component spec
  for this plan.
- `research_notes/Passenger car brake system modeling/`: the source notes behind the report.
- `docs/abs-controller-spec.md`: the torque-level ABS. It is already implemented as
  `ABSModulator` and `ABSControllerWheelOnly`, and it stays the reference that step 3 is
  compared against.

## Ground rules

1. **Existing components stay unchanged.** `BrakedWheel`, `BrakeActuator`, `SlipWheel1D`,
   `IdealEngine`, `VehicleBody` and the ABS blocks keep their behavior, because Lecture 1 and the
   current `01-abs` notebook depend on them. Hydraulics feed the wheel through `BrakedWheel.tau_cmd`
   with the harness setting `BrakedWheel(T_brake = 0.005, tau_max = 1e5)`. Both are existing
   parameters, so nothing is edited.
2. **New sublibrary `dyad/Vehicle/Brake/`**, laid out like `dyad/Vehicle/Wheel/`.
3. **Use physical connectors so the diagram looks like the real system.** Mechanical parts
   (pedal, booster pushrods, master-cylinder piston) use translational `Flange`s. Fluid parts
   use `HydraulicComponents.Interfaces.Port` with the brake-fluid medium set once per harness
   through `continuity`, as `TestForceChain` does. The stdlib has no orifice, line, caliper,
   valve, check valve, accumulator or pump, so each one is a custom component on those ports.
   Keep the R–C split inside them: capacitance components (caliper, accumulator) own a volume
   state and set port pressure, and resistance components (line, valve, orifice) set mass flow
   from the pressure difference. RealInput/RealOutput is used only for true signals: driver
   force commands, valve commands, sensor outputs, and published diagnostics like `p_mc`.
   Step 2's booster needs a pneumatic port, which does not exist yet. Decide in increment 2b
   whether to write a minimal gas connector or keep the chamber air internal to the booster and
   expose only a vacuum-supply port.
4. **SI units inside components.** Bar, cm³ and inHg appear only in docstrings, tests and plots.
5. **Keep every hydraulic time constant at 1 ms or more.** Use laminar regularization
   `Δp_cr ≈ 1 bar` on orifices and drop line inertance, so the explicit Tsit5 solver the tire model
   prefers still works. Budget: a 6 s stop takes 10⁵ solver steps or fewer.
6. **Mark every default by where it comes from**, in its docstring: `(PATH)`, `(MathWorks)`,
   `(Hella)`, `(EDC)`, `(derived)` or `(assumed)`, using the same tags as the report tables.
   Students should be able to see which numbers are measured and which are guesses.
7. **Memory states** (ABS latches, pump on/off) use the continuous-latch pattern from
   `ABSModulator`. Switching uses `ifelse`, `min` and `max`, never events.

## How testing works

There are three layers, all run by `test/runtests.jl`:

| Layer | Where | What it checks |
|---|---|---|
| Component regression | Dyad `tests` metadata on each `test component` (same style as `SlipWheel1D`) → `generated/tests.jl` | initial and final values of key signals, so refactors cannot silently change results |
| Plausibility checks | new `test/brake_plausibility.jl`, included from `runtests.jl` | derived metrics (rise time, rates, cycle frequency, stopping distance) sit inside the **real-world bands** below |
| Visual | the Lecture 3 notebooks | shapes a number cannot capture: hysteresis loops, pressure staircases, pedal kickback |

`test/brake_plausibility.jl` gets small helpers that each suite reuses: `rise_time(t, y, frac)`,
`max_rate(t, y)`, `cycle_frequency(t, y)` (zero crossings of the detrended signal), and
`stop_distance(sol)` (distance from pedal application until `v < 0.5 m/s`).

## Reality anchors

Every step is checked against these bands. They come from the research, and the tag says how
solid each one is. A model that lands outside a band is wrong, or needs a stated reason, even if
it runs cleanly.

| Quantity | Real-world band | Source |
|---|---|---|
| Line pressure for a 1 g stop | 60–100 bar | report §2 (derived from cited caliper sizes) |
| Pedal force for a hard stop (~1 g) | 150–300 N, and never more than 500 N | FMVSS 135 ceiling; the 150–300 N band is derived |
| Pedal travel at a hard stop | 25–60 mm | derived from report §2 fluid demand (assumed pedal ratio) |
| Total fluid demand at 60 bar | 3–5 cm³ | report §2 (assumed P–V, textbook magnitude) |
| Booster run-out line pressure | 80–100 bar | report §2 (PATH area, assumed servo ratio) |
| Idle manifold pressure | 27–45 kPa abs (16–20 inHg vacuum) | MOTOR, AA1Car |
| Wide-open-throttle manifold pressure | > 90 kPa abs | AA1Car |
| Manifold time constant at 800 rpm | 0.08–0.2 s | derived from MathWorks defaults |
| Booster rear-chamber rise, driver apply | 0.1–0.4 s | PATH measured traces |
| Assisted stops left after engine off | 2–3 | Brake & Front End service rule |
| Electric pump, 3.2 L volume to 50 kPa | ≤ 6 s | Hella UP28 data |
| ABS pressure build rate (fast) | 300–1000 bar/s | EDC 345 bar/s; spec-derived 580 bar/s |
| ABS slow build rate | 30–150 bar/s | EDC 34.5 bar/s; spec-derived 116 bar/s |
| ABS dump rate | 400–1000 bar/s | EDC (690 bar/s reading) |
| ABS cycle frequency | 2–15 Hz | abs-controller-spec criterion 5 |
| Low-pressure accumulator pressure | 4–10 bar | US5015043 |
| Mean wheel pressure during ABS | ≈ µ × 62 bar ± 25 % | derived: friction-limited torque / 68.9 N·m/bar |
| Dry stop from 100 km/h with ABS, from pedal application | 40–48 m | ideal `v²/2µg` = 39.3 m at µ = 1, plus 0.2–0.3 s of pressure build. Road tests of modern cars give 34–40 m on tires with µ > 1 |
| Dry locked-wheel stop from 100 km/h | 56–62 m | `v²/2µ_S g` = 56.2 m at µ_S = 0.7, plus build time |

---

## Step 1: Hydraulic brake circuit

Goal: show how a pedal force becomes brake torque, with realistic pressures, fluid volumes and
pedal travel. The booster is static in this step. Component equations and defaults are in the
report's Step 1 table.

### 1a. Static force chain: pedal → booster → master cylinder

**Build:**
- `BrakePedal`: `i_p = 3.5`. Outputs `F_rod`; takes `x_rod` back to report `x_ped`.
- `StaticBooster`: dead zone, jump-in, servo ratio, run-out. Takes `p_vac` as a parameter.
- `TandemMasterCylinder`: `p_mc` from force; integrates `V_disp` from the circuit flows; outputs
  `x_rod = s_dead + V_disp/A_mc`. The two circuits share `p_mc` (quasi-static tandem).

**Test component** `TestForceChain`: pedal-force ramp from 0 to 500 N over 5 s, master cylinder
fed into a fixed test volume. Expected values, hand-computed from the defaults (±2 %):

| Pedal force | `p_mc` |
|---|---|
| 50 N | 19.5 bar |
| 100 N | 37.3 bar |
| 170 N | 62.3 bar |
| 232 N (run-out) | 84.3 bar |
| 500 N | 103.4 bar |

**Done when:**
- The table values are reproduced within ±2 %.
- Below 40 N / i_p the output is 0 bar, with a visible jump-in step at cut-in.
- The slope changes at run-out, from `SR·i_p/A_mc` to `i_p/A_mc`.
- Setting `p_vac = p_atm` (no vacuum) gives `p_mc = (i_p·F_ped − 315 N)/A_mc`, so 500 N gives
  about 29 bar. The 315 N is the booster return spring plus the master-cylinder spring and seal
  friction. This is the unassisted case and should be enough for roughly 0.45 g.

### 1b. Calipers, lines and torque (3 hydraulic states)

**Build:**
- `CaliperNode` (front axle, rear axle): piecewise P–V, state `V`, publishes `p`.
- `BrakeLine`: laminar `R(ν)` with `ν` as a parameter, so temperature is chosen by passing ν.
- `CaliperTorque`: `τ = K_f·max(0, p_f − p₀) + K_r·max(0, p_r − p₀)`, output to `BrakedWheel.tau_cmd`.
- `HydraulicBrakeSystem`: composition of pedal → booster → master cylinder → 2 lines → 2 calipers →
  torque, with ports `F_ped` (in) and `tau` and `x_ped` (out). This is the block the lecture drops
  into vehicle harnesses.

**Tests:**
- `TestCaliperPV` (static, prescribed pressure ramp). Hand-computed from the defaults:

  | p | V front axle | V rear axle | pedal travel |
  |---|---|---|---|
  | 20 bar | 1.67 cm³ | 0.77 cm³ | 26 mm |
  | 40 bar | 2.18 cm³ | 0.97 cm³ | 31 mm |
  | 62 bar | 2.55 cm³ | 1.12 cm³ | 34 mm |

- `TestLineStep`: a master-cylinder pressure step of 60 bar into one caliper through its line.
  Measure the 10–90 % rise time.
- `HydraulicStopTransient`: `HydraulicBrakeSystem` + `BrakedWheel` + `VehicleBody`, v0 = 25 m/s,
  pedal step of 150 N at 0.5 s. That is about 55 bar, deliberately below the 62 bar friction limit.

**Done when:**
- The P–V table is matched within ±3 %, and total fluid at 60 bar is 3–5 cm³.
- At 20 °C (ν = 10 mm²/s) the line rise time is 1–30 ms. At −40 °C, DOT 4 (1800 mm²/s) is slower
  than DOT 4 LV (750 mm²/s) by a ratio of 1.8–2.6, and DOT 4 takes longer than 0.3 s.
- In the stop: steady `p_mc` about 55 bar, torque about 3760 N·m (±3 %), deceleration
  0.85–0.90 g, no wheel lock (`|kappa| < 0.04` after the transient), stop distance 36–40 m after
  brake application, and no solver-step budget violation. A 170 N pedal (62 bar, about 4250 N·m)
  sits exactly on the µ = 1 friction limit, so it is not used as a pass/fail case.
- At pedal 300 N (past run-out, about 89 bar, over the friction limit) the wheel locks, as the
  existing `LockedBrakeTransient` does.

### 1c. Brake-force distribution

**Build:** `ProportioningValve` (knee 45 bar, slope 0.43) on the rear branch, with a Boolean-like
parameter `enabled`. Expose axle torques `tau_f` and `tau_r` separately on `CaliperTorque`.

**Tests:**
- `TestProportioningValve`: ramp input 0–100 bar. Output equals input below 45 bar and is
  `45 + 0.43·(p − 45)` above it (±0.5 bar).
- Notebook-side static computation (not a simulation): ideal front share `φ_f(z) = (l_r + z·h)/l`
  against the installed 71/29 split, with and without the valve.

**Done when:**
- The valve matches the formula.
- At 62 bar, total torque with the valve is about 4060 N·m (±2 %), against about 4250 N·m without.
- The distribution plot shows the installed and ideal curves crossing at about 0.52 g, with the
  valve moving the rear curve below the ideal up to at least 0.9 g.
- Because the one-wheel plant can't lock the rear alone, the notebook only states the
  consequence ("rear locks first above z_crit"). This is noted as a limitation to fix in the
  2D vehicle.

### 1d. Notebook `notebooks/lecture03/02-brake-hydraulics.pluto.jl`

Sections:
1. Force chain, with a pedal-force slider and `p_mc`, torque and deceleration read out.
2. Pedal feel: `F_ped` against `x_ped`, showing clearance take-up and stiffening.
3. Cold-fluid comparison: pressure rise at 20 °C, −40 °C DOT 4 and −40 °C DOT 4 LV.
4. Distribution: ideal against installed, with and without proportioning.
5. Optional: circuit failure (zero one axle's gain) showing lost deceleration and longer travel.

**Done when** the notebook runs top to bottom in a fresh session, every number shown sits inside
the reality-anchor bands, and each plot's claim is stated in one sentence under it.

---

## Step 2: Engine vacuum and a dynamic vacuum booster

Goal: show where the assist comes from and when it disappears (wide-open throttle, engine off,
diesel or EV). Component equations and defaults are in the report's Step 2 table. `IdealEngine`
is not touched; the manifold is a separate component driven by prescribed throttle angle and
engine speed.

### 2a. `IntakeManifold`

**Build:** one state `p_m`, with inputs throttle angle `θ`, engine speed `N` and booster inflow
`ṁ_bst`, and output `p_m`. Compressible throttle flow with the Π > 0.95 linearization, and
speed-density cylinder flow in its rpm form. `A_idle = 13 mm²`. Do not copy MathWorks' 1 cm²
leakage default, and do not use the `ω·V_d·p/(2RT)` cylinder-flow form (it is off by 2π).

**Tests** (`TestIntakeManifold`, prescribed inputs):
- Idle: θ = 0, N = 800 rpm, held for 3 s.
- Tip-in: θ steps to wide open at 3000 rpm.
- Overrun: θ = 0 at 3000 rpm.
- Step response at idle to measure the time constant.

**Done when:**
- Idle `p_m` is 30–36 kPa (calibrated to 33 kPa).
- Wide open throttle gives `p_m` > 90 kPa.
- Overrun gives `p_m` below the idle value.
- Idle time constant is 0.08–0.2 s (predicted 0.125 s).
- Mass flow never goes negative through the choked throttle.

### 2b. `VacuumBooster` at constant vacuum

**Build:** two chamber pressures `p_f` and `p_r`, a static valve with dead band and 20 N smoothing,
and the flow coefficients read **per kPa** (report §3 explains why). It replaces `StaticBooster`
behind the same port set, so `HydraulicBrakeSystem` gains a `booster` choice. Implement it as two
compositions if a runtime switch is awkward.

**Tests:**
- `TestBoosterPATH`: vacuum source held at 33 kPa, slow pushrod-force ramp to 375 N and back.
- `TestBoosterCharacteristic`: slow triangle ramp. Plot `F_out` against `F_in`.
- `TestBoosterStep`: 200 N step. Measure the rear-chamber 10–90 % rise time.

**Done when:**
- Both chambers start at 33 kPa (±1).
- The 375 N ramp lifts `p_r` to 70–76 kPa, and `p_f` rises to 35–41 kPa and then recovers. These
  are PATH's measured values.
- The rear-chamber rise time is 0.1–0.4 s.
- The slow-ramp characteristic matches `StaticBooster` within 5 % in the boosted region, with a
  hysteresis loop that stays open on release.
- Run-out lands at 80–100 bar master-cylinder pressure.

### 2c. Manifold + booster + check valve, and vacuum reserve

**Build:** wire `ṁ_bst = C_vm·max(0, p_f − p_m)`; the `max` is the check valve. Add the optional
`ElectricVacuumPump`, which has hysteresis on/off using the continuous latch.

**Tests:**
- `BrakeVacuumIdleTransient`: engine idling, one full application and release.
- `BrakeVacuumReserveTransient`: engine off (manifold held at ambient), booster starting at
  33 kPa, five full apply-and-release cycles at 400 N.
- `BrakeVacuumWOTTransient`: throttle held wide open during repeated stops.
- `EVVacuumPumpTransient`: no engine, pump only, booster starting at ambient.

**Done when:**
- On release at idle, `p_m` shows a visible bump and returns to idle ±2 kPa within 2 s.
- Engine off: peak assist falls 3.6 → 2.4 → 1.6 → 1.0 kN (±15 %), giving 2–3 useful stops.
- WOT behaves like engine off while the throttle stays open.
- The EV pump takes the 2.83 L booster to 50 kPa in 5–7.5 s (6.3 s predicted) and cycles
  between its thresholds.
- Full-vehicle check: a 150 N pedal step at idle stops the car (v0 = 25 m/s) within 10 % of the
  step 1b distance, with a slower pressure build that comes from the booster instead of the 30 ms
  `BrakeActuator` lag.

### 2d. Notebook `notebooks/lecture03/03-vacuum-booster.pluto.jl`

Sections:
1. Manifold pressure against throttle and speed (idle, cruise, WOT) with sliders.
2. Booster static characteristic: jump-in, servo ratio, run-out and hysteresis, with a vacuum-level
   slider (altitude).
3. The booster lag in a driver-apply transient.
4. Reserve after engine stop: assist per stop.
5. Diesel, EV or iBooster: why the pump exists, and what an electromechanical booster changes
   (text plus the pump run).

**Done when** it runs clean and every shown value is inside the anchors.

---

## Step 3: ABS drives the hydraulic valves

Goal: the same ABS phase logic, now opening and closing valves. "ABS never adds braking" becomes
physically true, and pressure traces look like real ABS traces. Component equations and defaults
are in the report's Step 3 table.

### 3a. `HydraulicModulator`, driven open loop

**Build:**
- One per axle, inserted between `BrakeLine` and `CaliperNode`.
- Inlet valve with bypass check valve, outlet valve, 3 ms valve lags.
- Low-pressure accumulator (5 bar preload, 10 bar full, 5.3 cm³).
- Averaged pump flow returned to the master cylinder, which reduces `V_disp` and pushes the pedal
  back.
- Seat area calibrated to 580 bar/s at 55 bar Δp. Seat diameter is a parameter.

**Tests** (`TestModulatorOpenLoop`): master cylinder held at 60 bar, prescribed valve schedule
build → hold → dump → hold → slow build (duty 0.2) → full build; then the same with the pump off.

**Done when:**
- Fast build is 300–1000 bar/s and dump 400–1000 bar/s, both measured at 60 bar.
- Slow build at duty 0.2 is 30–150 bar/s.
- Hold drifts less than 1 bar/s.
- `p_w ≤ p_mc + 0.2 bar` at every instant.
- `p_lpa` stays within 4–10.5 bar.
- With the pump off, a second full dump from 60 bar leaves `p_w` above `p_lpa`, because the
  accumulator is full and dumping stops. With the pump on, it does not.
- The 1.0 mm seat sensitivity case gives rates at least 10× higher. Document it; it is not a
  failure.

### 3b. `ABSValveModulator`

**Build:** extract the phase table and latches from `ABSModulator` into a partial,
`ABSPhaseLogic`, with no behavior change. Confirm by rerunning the existing ABS tests unchanged.
`ABSValveModulator` extends it and maps phases to `(inlet, outlet, motor)` commands. The OFF
condition becomes `p_mc < 0.7 bar`. `ABSControllerWheelOnly` gets a valve-output sibling,
`ABSValveControllerWheelOnly`.

**Tests:**
- The existing ABS regression tests pass unchanged after the extraction. This is the
  "no behavior change" proof.
- `TestValveModulatorPhases`: prescribed `a_w`, `v_ref` and `omega` traces walk the logic through
  every phase. Assert the valve commands per phase:
  - DECREASE → (0, 1)
  - HOLD → (0, 0)
  - slow INCREASE → (duty, 0)
  - fast INCREASE and OFF → (1, 0)
  - motor on once active
- Negative test: with slip and deceleration below every threshold, the valves stay at (1, 0) for
  the whole run.

**Done when** all assertions hold and the torque-level `ABSBrakeTransient` results are
unchanged to within solver tolerance.

### 3c. Closed-loop hydraulic ABS stop

**Build:** harness `HydraulicABSBrakeTest`: `HydraulicBrakeSystem` (vacuum booster, idle
manifold) + one `HydraulicModulator` per axle + `ABSValveControllerWheelOnly` + `BrakedWheel` +
`VehicleBody`, with a 300 N pedal step. Analyses: `HydraulicABSTransient(road_mu)` and
`HydraulicLockedTransient(road_mu)`.

**Tests:** rerun the six acceptance criteria in `docs/abs-controller-spec.md` on this plant at
µ ∈ {1.0, 0.5, 0.2}, plus:
- **Pressure realism:** mean wheel pressure during ABS is about µ·62 bar ±25 %, so about 62, 31 and
  12 bar.
- **Cycle realism:** 2–15 Hz, with a visible build/hold/dump sawtooth and a slow-build staircase.
- **Agreement:** stopping distance within ±10 % of the torque-level `ABSBrakeTransient` at the
  same µ.
- **100 km/h anchor:** v0 = 27.8 m/s at µ = 1. The ABS stop from pedal application is 40–48 m;
  the locked stop is 56–62 m.
- **Pedal kickback:** `x_ped` oscillates by at least 0.5 mm while ABS cycles.
- **Negative test:** at µ = 0.2 with the pump disabled, the accumulator fills, dumping stops, and
  the wheel locks for good. Assert that `|kappa| > 0.5` at the end, and that the lock time falls
  within ±30 % of the prediction from accumulator volume and dump flow.

**Done when:**
- All six spec criteria and every added test pass.
- Criterion 1 ("never exceed demand") holds without any clip in the controller.
- The run stays within the solver budget.

### 3d. Notebook `notebooks/lecture03/04-abs-hydraulics.pluto.jl`

Sections:
1. Valve states: what the inlet and outlet do per phase.
2. An open-loop pressure trace showing build, hold, dump and the staircase.
3. Closed-loop stop, torque-level ABS against valve ABS against locked, with a µ slider.
4. Pressure, valve commands and slip on one time axis.
5. Accumulator and pump: the pump-off failure.
6. Pedal kickback.

**Done when** it runs clean, the three stops share one plot, and the valve-ABS stop sits inside
the 100 km/h anchor.

---

## Order of delivery

Each increment is one branch and PR, per the repo's worktree convention:

| # | Increment | Depends on |
|---|---|---|
| 1 | 1a force chain | none |
| 2 | 1b calipers, lines, stop | 1 |
| 3 | 1c distribution + 1d notebook | 2 |
| 4 | 2a manifold | none (can run in parallel with 1) |
| 5 | 2b booster at constant vacuum | 1 |
| 6 | 2c coupling + reserve + pump, 2d notebook | 4, 5 |
| 7 | 3a modulator open loop | 2 |
| 8 | 3b phase-logic extraction + valve modulator | none (can run in parallel) |
| 9 | 3c closed loop + 3d notebook | 6, 7, 8 |

## Where the numbers come from

Every number in this plan belongs to one of three groups. Treat them differently when a test
fails: a group 1 number is evidence, a group 2 number follows from assumptions, and a group 3
number is a judgment call that can be argued with.

**1. Cited sources**. The report links each one.

| Number | Source | How solid |
|---|---|---|
| Booster diaphragm 0.0533 m², chambers 2.4 L / 0.43 L, return spring 97 N + 2411 N/m, valve thresholds 50 N, flow coefficients; master cylinder 25 mm bore, 138 N spring, 80 N seal friction | PATH UCB-ITS-PRR-97-21 (1997), Table 2.1 | Good: measured test car. The flow coefficients are read per kPa to match PATH's own traces (report §3) |
| Booster idle 33 kPa, rear chamber 72–74 kPa at 375 N, response 0.1–0.4 s | PATH measured traces | Good |
| Manifold 1 L, displacement 1.5 L, throttle 50 mm | MathWorks Simscape Air Intake defaults | Generic defaults |
| Idle MAP 27 kPa, idle vacuum 16–20 inHg, WOT vacuum about 0 | MOTOR magazine, AA1Car | Moderate |
| Electric pump: 3.2 L to 500 mbar in ≤ 6 s | Hella UP28 data sheet | Good |
| Pedal force ceiling 500 N | FMVSS 135 | Good |
| ABS build 345 bar/s, slow build 34.5 bar/s, 50 ms apply delay | Day & Roberts, SAE 2002-01-0559 (EDC) | Moderate: the dump rate is stated two inconsistent ways |
| Accumulator preload 4–6 bar, about 10 bar full | US5015043 | Moderate |
| Accumulator 5.3 ml, valve seats 0.74–1.16 mm | Cai et al., EMEIT-2012 | Weak: the paper contains a known typo |
| Proportioning knee 41–48 bar, slope 0.43 | Wilwood, Brakes-shop (aftermarket) | Weak: not OEM data |
| DOT 4 at −40 °C ≤ 1800 mm²/s, DOT 4 LV ≤ 750 mm²/s | Brake-fluid specs, via Wikipedia | Good |
| Hose swell 0.33 cm³/ft | SAE J1401 limit, quoted in US7748412 | Moderate |

**2. Assumed parameters and the values computed from them.** These are exact for the model and
only as real as their assumptions.

- **Assumed** (textbook-typical, no readable source): pedal ratio 3.5, servo ratio 5, jump-in
  500 N, cut-in 40 N, caliper pistons 57/38 mm, pad µ 0.40, effective radii 0.12/0.11 m, caliper
  pressure–volume coefficients, fluid viscosity 10 mm²/s at 20 °C, 3 mm lines of 1.5/4 m, vehicle
  geometry (2.6 m wheelbase, 60 % front, 0.55 m CG height), valve lag 3 ms, pump flow 10 cm³/s,
  laminar transition Δp_cr 1 bar.
- **Computed from the defaults**, hand-checked before writing this plan:
  - master-cylinder pressure 19.5 / 37.3 / 62.3 / 84.3 / 103.4 bar at 50 / 100 / 170 / 232 /
    500 N pedal force
  - booster run-out at 232 N pedal force
  - axle fluid volumes and pedal travel in the 1b table
  - 55 bar / 3760 N·m / 0.88 g at 150 N pedal force
  - torque gains 49.0 + 19.9 N·m/bar
  - line time constants 1–8 ms
  - electric pump 6.3 s to 50 kPa
  - manifold time constant 0.125 s at 800 rpm
  - idle air area 13 mm²
  - booster reserve 3.6 / 2.4 / 1.6 / 1.0 kN
  - ideal stopping distances from `v²/(2µg)` with the tire's µ_A = 1.0 and µ_S = 0.7: 31.9 and
    45.5 m from 25 m/s, 39.3 and 56.2 m from 100 km/h
  - valve-rate equivalents of the spec's torque rates: 580 and 116 bar/s

**3. Engineering judgment.** These have no source.

- Band edges in the reality-anchor table: pedal force 150–300 N, pedal travel 25–60 mm, fluid
  3–5 cm³, run-out 80–100 bar, ABS build 300–1000 bar/s and dump 400–1000 bar/s. Each band is
  widened around the one or two cited points available.
- All test tolerances (±2 %, ±3 %, ±10 %, ±15 %, ±25 %, ±30 %).
- "Mean wheel pressure during ABS ≈ µ × 62 bar": derived from the friction limit, not measured.
- "Modern cars stop from 100 km/h in 34–40 m": general knowledge of published road tests, not
  from the research.

The weakest defaults are the caliper P–V curve, servo ratio and jump-in, pump displacement and
valve seat area, where the sources disagree on valve rates by 15–30×. To tighten them, harvest
values from the MathWorks "ABS Open Loop Test Bench" and "Vacuum Boosted Tandem Primary Cylinder"
models or from Breuer & Bill, *Brake Technology Handbook*.

## Known limits of this plan

- **Lumped single wheel.** No per-axle lock, split-circuit yaw, EBD, or "fastest wheel"
  reference speed. All of those wait for the 2D vehicle in `docs/lecture-03-preparation.md`.
- **Assumed parameters.** Caliper P–V, servo ratio, jump-in, pump displacement and valve seat
  area are assumed. The bands above are wide enough to absorb them. Tighten the defaults from the
  MathWorks "ABS Open Loop Test Bench" and "Vacuum Boosted Tandem Primary Cylinder" models, or
  from Breuer & Bill, when they become available.
- **Valve rates.** They are calibrated to EDC and the spec's rates rather than taken from
  hardware data. The report records a 15–30× disagreement between sources.
- **The engine does not feel the booster.** The manifold is driven by prescribed θ and N, so a
  large booster bleed changes MAP but not idle speed. Coupling to engine speed needs an engine
  with a speed state, which is out of scope here.
