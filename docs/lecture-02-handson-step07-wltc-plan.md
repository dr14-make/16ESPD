# Lecture 2 hands-on, step 07 — WLTC: the test cycle

The plan behind step 07 of `slides/site/handson/lecture-02/index.md`, the optional last step
("if time allows"). It fills scope B of `lecture-02-mapped-engine-plan.md` (M7-B, task 6) and the
step 07 slot of `lecture-02-handson-plan.md`. It is written for the CVT car being built on
`feat/handson02-cvt` (a `CVTDriveline` with a centrifugal launch clutch and a pedal-scheduled
target engine speed), because the one-gear car cannot start from rest and hits the rev limiter.
A stepped gearbox is the fallback; where it changes the plan, the change is marked **Stepped:**.

## 1. Goal and checkpoints

**Goal.** Drive the student's own car, with its own `MapEngine`, over the WLTC class 3b trace with
a speed-following driver, and read the number on a car's label: L/100 km and g CO₂/km over the
whole cycle. Then compare it with step 05's steady cruise and with a real 1.5 L petrol car's label.

The arc in one line: step 05 showed that L/100 km is undefined at a standstill and depends on speed,
so the label is measured over a fixed 30-minute trace; this step drives that trace.

**Checkpoint 1 — the car follows the trace.**

- Plot `car.v_kmh` over `trace.v_kmh` for the 1800 s. The car stays inside the regulation's band,
  ±2 km/h and ±1 s around the trace (EU 2017/1151 Annex XXI Sub-Annex 6 §1.2.6.6, as cited by
  MathWorks), everywhere except, at most, the first second of each launch.
- Measured: the largest speed error and the RMS speed error over the cycle, in km/h. The reference
  sets the expected value; a working PI driver should be well under 2 km/h RMS (the repo's own
  driver criterion, `lecture-02-dyad-tasks.md`, task 8).
- Measured: total distance at 1800 s is **23.27 km** (the trace's own distance, 23 266 m;
  DieselNet). A car that drives the trace and ends far from that has not followed it.

**Checkpoint 2 — the label number.**

- Measured: fuel burned over the cycle in liters, `fuel_L` at 1800 s (the integral of the car's
  `fuel_lph` / 3600).
- Computed by hand, as in step 05: L/100 km = L / km × 100 and g CO₂/km = 2302 × L / km.
- Expected (section 4): about **5.0–5.6 L/100 km**, **115–130 g CO₂/km** for the CVT car, against
  the Mazda2 1.5 Skyactiv-G label, **5.3 L/100 km, 120 g/km** (WLTP combined).
- Optional, from the reference only: the four phase figures (Low, Medium, High, Extra-high), read
  off the integrals at t = 589, 1022, 1477 and 1800 s. Low is the worst per kilometer (idling at
  stops, launches); High is the best.

## 2. Built vs given

Budget about 15 minutes of student work, plus one long run. Everything that is control design or
data handling is given; the student does what they did in steps 04–06: change their car, draw a
bench, read numbers off a run.

| Part | Built or given | Why |
|---|---|---|
| WLTC class 3b trace, `assets/data/drive_cycles/wltc_class3b.csv` | given (library data) | 1801 numbers from a regulation; typing them teaches nothing. Shared with Lecture 2 task 8 (`DriveCycle`). |
| `Vehicle.DriveCycles.WLTCClass3b` — time in, `v_ref` [m/s] and `v_ref_kmh` out | given, `Vehicle` | Wraps `BlockComponents.Tables.Interpolation` on the CSV; one block for students to place. |
| `CVTDriveline` (centrifugal clutch, scheduled ratio) | given, from `feat/handson02-cvt` | Another agent's work; its interface is assumed below and must be confirmed. |
| `Vehicle.RoadBrake` — brake force that opposes motion and holds the car at rest | given, `Vehicle` | Step 06's `Force` source pushes the car backwards once it stops; the cycle has 242 s of standstill (DieselNet). The fix is a regularized Coulomb law, which is plumbing. |
| `HandsOn02.WLTCDriver` — PI from speed error to pedal and brake | given, `HandsOn02` | Lecture 1's `CruiseController` with D off and limits ±1, split by sign. Students recognize it; tuning it over 1800 s does not fit 15 minutes. |
| `WLTCCar` — the student's `MappedCar` with `driveline` swapped for `CVTDriveline` and the brake swapped for `RoadBrake` | **built** (duplicate, two swaps, one wire) | It stays their car and their engine; the milestone of the session goes on the cycle. |
| Bench `WLTCRun` — trace → driver → car, a fuel integrator; analysis `WLTCRunTransient`, `stop = 1800` | **built** (pasted code or drawn: 4 blocks, 5 wires) | Same pattern as every bench so far. |
| Phase split and plots | given, a REPL snippet on the page | Reading `sol(t)` at four instants is not the lesson. |

Student budget: duplicate and swap 5 min, bench 5 min, run (wall time unknown, section 5) and read
5 min. If the run takes longer than a few minutes, the page offers the "Stuck?" path: run the
reference `HandsOn02.WLTCRunTransient` instead and do only the reading.

**Stepped:** `CVTDriveline` becomes a `SteppedDriveline` (5 ratios and a shift schedule) and a
launch clutch; both given. The student's part is unchanged. The shift schedule is one more given
block (gear from speed and pedal), and the driver needs a pedal cut during shifts if the gearbox
models shift time.

## 3. Reference models

All in `dyad/HandsOn02/` unless marked `Vehicle`. Names follow the existing `MappedCar*` pattern.

### Library parts (given)

- `Vehicle.DriveCycles.WLTCClass3b`
  - `BlockComponents.Tables.Interpolation(interpolation_type = LinearInterpolation(),
    extrapolation_type = Constant(), dataset = DyadTimeseries("dyad://VehicleSystemsComponents/data/drive_cycles/wltc_class3b.csv",
    independent_var = "t_s", dependent_vars = ["v_kmh"]))`, input `time`.
  - `dyad://<Package>/<path>` resolves under the package's `assets/` folder (DyadData
    `parse_uri` docstring), so the file lives at `assets/data/drive_cycles/wltc_class3b.csv`; the
    stdlib test `BlockComponents/Tables/Tests/InterpolationFile.dyad` is the pattern.
  - Outputs `v_ref_kmh` and `v_ref = v_ref_kmh / 3.6`.
  - Parameter `t_preview::Time = 0` (see the driver): reads the trace at `time + t_preview`.
  - Fallback if file loading misbehaves once the library is added by URL: a script-generated
    `WLTCClass3bData` with the 1801 speeds inline as a structural array and `InterpolatedTable`,
    as `Engine.EngineMapData` and `SpeedCurve` already do.
- `Vehicle.RoadBrake`: flanges `flange` (body) and `support` (ground), input `F_cmd ≥ 0` [N];
  `f = -F_cmd * tanh(v / v_reg)` with `v_reg = 0.05 m/s` (assumed). Same regularization idea as
  the CVT branch's `CentrifugalClutch` (`tanh(w_slip / w_regularization)`).

### Driver: `HandsOn02.WLTCDriver`

- Inputs `v_ref_kmh`, `v_kmh` (the trace's and the car's existing outputs, so the bench needs no
  unit gains); outputs `pedal` ∈ [0, 1], `F_brake` ≥ 0 [N].
- Core: `Lecture1.CruiseController(with_D = false, k = k, Ti = Ti, y_max = 1, y_min = -1)`. Its
  clamping anti-windup (freeze the integrator when saturated and the error pushes further) is
  already tested in Lecture 1 and covers hard launches and stops.
- Split by sign, as MathWorks' Longitudinal Driver does (positive effort to the accelerator,
  negative to the brake): `pedal = max(y, 0)`, `F_brake = F_brake_max * max(-y - y_dead, 0) /
  (1 - y_dead)`.
  - `F_brake_max = 6000 N` (assumed): the trace's hardest deceleration is 1.5 m/s² (computed from
    the trace, t = 278 s), 2100 N on 1400 kg, plus margin.
  - `y_dead = 0.02` (assumed): a small band where neither pedal nor brake acts, so the car coasts
    on engine braking and the controller does not toggle between them (and the fuel cut) near
    zero effort.
- Gains (assumed, to be tuned on the reference): start `k = 0.14` pedal per km/h (0.5 per m/s),
  `Ti = 3 s`.
  Reasoning: the pedal-to-tractive-force gain of this engine at low pedal is roughly
  2000–3000 N per unit pedal (step 03 cruise pedals 0.044–0.190 for 18–51 N·m, through the CVT's
  ratio); with m = 1400 kg, k = 0.5 gives a loop time constant near 1–1.5 s, fast enough for the
  trace's 1.67 m/s² peak acceleration (t = 1029 s) without fighting the manifold's 0.15 s lag.
  MathWorks' defaults (Kp = 10, Ki = 5, normalized by v_nom = 5 m/s, anti-windup Kaw = 1, error
  filter 0.01 s) are a cross-check of the order of magnitude, not a value to copy.
- Optional preview: drive the controller from `v_ref(t + 0.5 s)`. A real test driver looks ahead
  on the screen; 0.5 s stays inside the ±1 s time tolerance and removes most of the PI's lag. Use
  only if the plain PI misses the band.
- Reference test: `TestWLTCDriver` on a point mass (no engine): a ramp and a stop give the
  expected pedal and brake signs and no integrator windup.

### Car and bench

- `HandsOn02.WLTCCar` = `HandsOn02.MappedCar` (step 04, on `MapEngineFuelCut` with the 0.15 kg·m²
  flywheel) with
  - `driveline = CVTDriveline(...)`; `pedal` also wired to the CVT's schedule input (assumed
    interface: the same four mechanical ports as `Driveline` plus `RealInput pedal`; confirm on
    `feat/handson02-cvt`).
  - `brake = Vehicle.RoadBrake()` in place of step 06's `Force`, input `F_brake`.
  - Unchanged parameters (hands-on 1 `Body`): m = 1400 kg, CdA = 0.63 m², f_r = 0.012,
    ρ = 1.2 kg/m³, r = 0.31 m; engine: `data/engine/` maps, fuel cut 1300/1000 rpm, rev limiter
    6500/6300 rpm (`FuelCutLogic` defaults, assumed).
- `HandsOn02.WLTCRun`: `trace = Vehicle.DriveCycles.WLTCClass3b()`, `driver = WLTCDriver()`,
  `car = WLTCCar()`, `fuel_L = BlockComponents.Continuous.Integrator(k = 1 / 3600)` on
  `car.fuel_lph` (L/h → L). Wires: `trace.v_ref_kmh` → `driver.v_ref_kmh`, `car.v_kmh` →
  `driver.v_kmh`, `driver.pedal` → `car.pedal`, `driver.F_brake` → `car.F_brake`,
  `car.fuel_lph` → `fuel_L.u`.
  - `initial car.body.mass.s = 0`, `initial car.body.mass.v = 0`,
    `initial car.engine.air.manifold.p = 33000` (idle, step 02), and the engine's flywheel at idle
    speed, 800 rpm, behind the open launch clutch (the initial lines the CVT branch settles).
- `HandsOn02.WLTCRunTransient`: `extends TransientAnalysis(stop = 1800)`; `dtmax = 0.5` or
  `tstops` at every whole second if the analysis exposes it, because the linear trace has a corner
  every second.
- `HandsOn02.WLTCRunLowTransient`: the same bench, `stop = 589` (Low phase only), for tests and
  for students whose run is too slow.
- **Stepped:** `WLTCCarStepped` with `SteppedDriveline`; gear ratios assumed (for example
  3.45/1.94/1.38/1.03/0.84 with a 4.1 final drive, typical small-car values, to be sourced);
  upshift when the engine would stay above about 1600 rpm accelerating or 1250 rpm cruising with
  15 % torque reserve (assumed, the rule used for the estimate in section 4).

### Trace data file and license

- Content: WLTC class 3b, 1 Hz, t = 0…1800 s, 1801 speeds in km/h to one decimal. Two columns,
  header `t_s,v_kmh`, no comment lines: `DyadData` reads CSVs with `header = 1`, so a comment line
  would become the header. Provenance goes in `assets/data/drive_cycles/README.md`.
- Authoritative source: UN GTR No. 15, Annex 1, and its EU transposition, Regulation (EU)
  2017/1151, Annex XXI, Sub-Annex 1: Low 3 in Table A1/7, Medium 3b in A1/9, High 3b in A1/11,
  Extra-high 3 in A1/12, and 1 Hz checksums in A1/13 (per the consolidated text on gesetze.legal).
- License: EU legislation on EUR-Lex may be reused for any purpose unless stated otherwise (EUR-Lex
  legal notice; Commission Decision 2011/833/EU); attribute the source and say the tables were
  reformatted to CSV. Transcribe from the EUR-Lex tables, so the committed file derives from the
  regulation and needs no third-party license.
- Cross-check copy (do not commit): JRC's `wltp` project, `wltp/cycles/V_class3b.txt` on
  github.com/JRCSTU/wltp, © European Commission (JRC), **EUPL 1.1**, which is copyleft. This plan
  checked that copy: 1801 samples, max 131.3 km/h, distance 23 266 m, phase distances 3095 / 4756 /
  7162 / 8254 m, all equal to DieselNet's table. DieselNet's `wltp3b.txt` carries no license
  ("Copyright ECOpoint Inc."), so it is a reference, not a source to commit.
- Test the committed file against Table A1/13's checksums and the phase distances.

## 4. Expected numbers and tests

### Class of the car

- Rated power from `data/engine/full_load.csv`: max of T·ω is **86.8 kW at 6000 rpm**
  (138.1 N·m).
- PMR = P / mass: 86 800 / 1400 = **62 W/kg**; with the EU definition (mass in running order minus
  75 kg, 2017/1151 Sub-Annex 1 §1–2) and 1400 kg taken as running order, 86 800 / 1325 =
  **65.5 W/kg**. Either way > 34 W/kg → **class 3**.
- v_max ≈ 190 km/h (step 04, the rev limiter) ≥ 120 km/h → **class 3b** (Sub-Annex 1; DieselNet).
- No downscaling: the required-power ratio at t = 1566 s (111.9 km/h, 0.5 m/s²;
  P = (f0·v + f2·v³ + 1.03·m·v·a) / 3600) is 38.9 kW / 86.8 kW = **0.45**, below the class 3
  threshold r0 = 0.867 (Sub-Annex 1 §8.3). No capping: v_max > 131.3 km/h.

### The cycle (DieselNet, matched by the JRC copy)

| Phase | s | Stop s | km | Max km/h |
|---|---|---|---|---|
| Low 3 | 589 | 156 | 3.095 | 56.5 |
| Medium 3b | 433 | 48 | 4.756 | 76.6 |
| High 3b | 455 | 31 | 7.162 | 97.4 |
| Extra-high 3 | 323 | 7 | 8.254 | 131.3 |
| Total | 1800 | 242 | 23.266 | 131.3 |

- Positive tractive work at the wheel on this car (computed from the trace, this plan): **3.10 kWh**
  over the cycle, **133 Wh/km**; peak wheel power **38.7 kW** at t = 1566 s; hardest acceleration
  1.67 m/s², hardest deceleration 1.5 m/s².

### Fuel and CO₂, predicted before any model runs

Quasi-static, backward-facing estimate made for this plan from `data/engine/` and the hands-on 1
body (method: 1 Hz trace, mid-step speed and acceleration, road load plus `m·a` plus the flywheel
reflected through the ratio; torque inverted to `p_m` on `torque_Nm.csv` by bisection, capped at
`full_load.csv`, fuel read on `fuel_gps.csv`; idle fuel at standstill; zero fuel when the demanded
torque is below `closed_throttle.csv` above 1000 rpm; lossless driveline; hot start, no
auxiliaries). It is a band for the reference, not a checkpoint value.

| Driveline | Low | Medium | High | Extra-high | Combined L/100 km | g CO₂/km |
|---|---|---|---|---|---|---|
| Fixed gear 4.0, slipping clutch below 1000 rpm | 6.66 | 5.16 | 4.97 | 6.09 | 5.63 | 130 |
| 5-speed, rule in section 3 | 6.16 | 4.91 | 4.67 | 5.63 | 5.26 | 121 |
| Ideal CVT on the minimum-fuel line, ratio 2–16, ≥ 1200 rpm | 5.86 | 4.77 | 4.33 | 5.19 | **4.93** | **113** |

- The fixed gear runs out of torque for **116 s** of the cycle (launches), so its figure is not
  achievable; it is shown to make the point of the CVT.
- The CVT branch schedules engine speed from the pedal, not along the minimum-fuel line, so its
  car should land between the ideal CVT and the 5-speed: **about 4.9–5.3 L/100 km,
  113–122 g CO₂/km**. A dynamic run with a PI driver adds a little (overshoot, small brake
  applications); the checkpoint band in section 1 (5.0–5.6, 115–130) allows for that.
- The model's CVT is lossless. A production push-belt CVT is about 84.6 % efficient overall
  against about 96 % for a manual (TU Crete paper, MED 2013, in Sources), so a real CVT car pays
  roughly 10 % more fuel than this model; say so when comparing with the label.
- Compared with step 05: the WLTC figure sits above the 50 and 90 km/h cruise figures (3.3 and
  4.6) and below 130 km/h (7.0), because of idling, accelerations and braking losses.

### The label to compare against

- Mazda2 1.5 Skyactiv-G 90 PS, manual, 2020–2023, Euro 6d: **5.3 L/100 km, 120 g CO₂/km** WLTP
  combined (Autotijd consumption database). Same engine family as the ALPHA map (2.0 L Skyactiv-G
  scaled to 1.5 L, M4).
- Context: the 2023 EU new-car fleet average was 106.4 g/km WLTP (EEA), all fuels and BEVs
  included.
- Why the model may still read low: no cold start (the certification test starts with a cold,
  soaked engine), no auxiliaries, lossless driveline, and a lighter real car would read lower
  still (1400 kg is heavier than a Mazda2; its kerb mass should be read off the CoC).

### Tests to add (`test/engine_plausibility.jl`, testset "Hands-on 02 WLTC")

- **Trace file:** 1801 rows, `t_s` = 0…1800 step 1, max 131.3 km/h, total distance 23 266 ± 1 m,
  phase distances 3095 / 4756 / 7162 / 8254 ± 1 m, and Table A1/13's checksums.
- **Trace block:** `WLTCClass3b` returns the CSV value at whole seconds and the mean of neighbors
  at half seconds.
- **`RoadBrake`:** a mass at rest with `F_cmd = 4000 N` stays at rest (|v| < 0.05 m/s); at 10 m/s
  it decelerates at F/m.
- **`TestWLTCDriver`:** pedal ∈ [0, 1], brake ≥ 0, never both active; integrator held while
  saturated.
- **`WLTCRunLowTransient` (fast):** |v − v_ref| ≤ 2 km/h after the first second of each launch;
  distance 3.095 km ± 1 %; Low-phase L/100 km in the band set by the reference.
- **`WLTCRunTransient` (slow, opt-in like other long runs):** distance 23.27 km ± 0.5 %; RMS speed
  error < 2 km/h; combined L/100 km and g CO₂/km to the digit the page shows; zero fuel during
  overrun segments above 1300 rpm.
- Dyad `metadata` tests on `WLTCRunLowTransient` with `atol` on `fuel_L` and `car.body.mass.s`,
  as the other `HandsOn02` benches do.

## 5. Risks and open questions for the lecturer

- Run time: an 1800 s run with fuel-cut latches (0.01 s) and a PI driver may take minutes; measure
  on the reference before promising it in class, else students run the Low phase only.
- Fuel-cut chatter: the decel latch arms when the pedal is ≤ 1e-4; the driver's dead band should
  stop it toggling, but confirm the solver does not stall on it.
- Launch: depends on the CVT branch's centrifugal clutch and initial lines; the cycle has 9
  launches from rest to verify.
- Interface: `CVTDriveline`'s ports and schedule input are assumed here; confirm before writing the
  page.
- File loading: does `dyad://VehicleSystemsComponents/data/...` resolve when students add the
  library by URL (step 00)? If not, use the inline-array fallback.
- Which label: Mazda2 1.5 manual (5.3 L/100 km, 120 g/km, secondary source) or a CVT car to match
  the model's gearbox? An official CoC or EEA dataset figure would be a better citation.
- Student build vs demo: is 15 minutes plus the run realistic at the end of a 90-minute session, or
  should step 07 be a tutor demo with the students reading the result?
- Phase table: show per-phase figures on the page, or only the combined number?
- Stepped gearbox: keep it as a documented fallback only, or build it too to compare with the CVT?
- Cold start and auxiliaries: mention only, or add a 500 W auxiliary load (task 8's `P_aux`,
  assumed) to close part of the gap to the label?

## 6. Sources

- **DieselNet, "Worldwide Harmonized Light Vehicles Test Cycle (WLTC)"**,
  <https://dieselnet.com/standards/cycles/wltp.php>. Class thresholds, PMR definition and the EU's
  running-order note, phase table (durations, stops, distances, max speeds), downscaling and
  capping. © ECOpoint Inc., no reuse license: cite, do not copy data.
- **Regulation (EU) 2017/1151, Annex XXI, Sub-Annex 1** (WLTC), on EUR-Lex; read via the
  consolidated text at <https://gesetze.legal/eu/vo_eu_2017_1151/unteranhang_1>. PMR with running
  order minus 75 kg, class 3a/3b at 120 km/h, tables A1/7–A1/13, downscaling §8 (r0 = 0.867 for
  class 3). Authoritative source for the committed trace. Reuse allowed with attribution:
  **EUR-Lex legal notice**, <https://eur-lex.europa.eu/content/legal-notice/legal-notice.html>;
  **Commission Decision 2011/833/EU**, <https://eur-lex.europa.eu/eli/dec/2011/833/oj>.
- **UN GTR No. 15 (WLTP)**, UNECE. The original of the EU text; not fetched for this plan, the EU
  text was used instead.
- **JRC `wltp` project**, <https://github.com/JRCSTU/wltp>, `wltp/cycles/V_class3b.txt` and
  `class3.py`. © 2013–2020 European Commission (JRC), **EUPL 1.1**. Machine-readable 1 Hz trace
  used here to verify the phase distances; copyleft, so not to be committed into this unlicensed
  repository.
- **MathWorks, "Track Drive Cycle Errors"**,
  <https://www.mathworks.com/help/autoblks/ug/track-drive-cycle-errors.html>. WLTP tolerance
  ±2.0 km/h and ±1.0 s, citing 2017/1151 §1.2.6.6. Documentation; cite only.
- **MathWorks, "Longitudinal Driver"**,
  <https://www.mathworks.com/help/autoblks/ref/longitudinaldriver.html>. PI driver structure,
  sign split into accelerator and brake, anti-windup gain, default gains. Documentation; cite only.
- **TU Crete Robolab, CVT efficiency paper, 21st Mediterranean Conference on Control & Automation
  (MED 2013)**,
  <https://www.robolab.tuc.gr/fileadmin/users_data/robolab/publications/2013_publications/2013_On_the_Efficiency__Variable_Transmission.pdf>.
  Belt CVT about 84.6 % overall, manual about 96 %. Cite only.
- **Autotijd, Mazda2 Skyactiv-G 1.5 90 PS manual (2020–2023)**,
  <https://autotijd.be/en/consumption/mazda/mazda2/skyactiv-g-15-90-hp-manual-2245>. WLTP combined
  5.3 L/100 km, 120 g/km. Secondary database; replace with an official figure if one is found.
- **EEA, "CO₂ emissions performance of new passenger cars in Europe"**,
  <https://www.eea.europa.eu/ims/co2-performance-of-new-passenger>. 2023 EU average 106.4 g/km
  WLTP. CC BY 4.0.
- **In this repository:** `data/engine/` (EPA ALPHA, cited in its README) for the maps and the
  86.8 kW rated power; `dyad/HandsOn/Body.dyad` and `Driveline.dyad` for the car;
  `dyad/Lecture1/CruiseController.dyad` for the PI with clamping anti-windup;
  `BlockComponents/Tables/Tests/InterpolationFile.dyad` and DyadData's `parse_uri` docstring for
  file-backed interpolation.
