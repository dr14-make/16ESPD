# Lecture 2 hands-on, step 07 — WLTC bonus task

The plan behind step 07 of `slides/site/handson/lecture-02/index.md`. It fills scope B of
`lecture-02-mapped-engine-plan.md` (M7-B, task 6) and the step 07 row of
`lecture-02-handson-plan.md`.

Every number below is from the reference bench `HandsOn02.MappedCarWLTC` (§3) and its testset
"Hands-on 02 WLTC bonus" in `test/engine_plausibility.jl`. The student guide, the tutor guide and
the deck quote the same figures.

## 1. The decision

Step 07 is an **extra task for extra points**, not part of the 90-minute session. Students who
finished step 06 do it at home or after the session and hand it in with their pull request.

They drive their own CVT car from steps 04–06 (`MappedCar`, with the `F_brake` input of step 06 B)
over the WLTC class 3b trace with their own `CruiseController` from Lecture 1, and report the two
numbers on a car's label: L/100 km and g CO₂/km over the cycle.

The arc in one line: step 05 showed that L/100 km is undefined at a standstill and depends on
speed, so the label is measured over a fixed 30-minute trace; this task drives that trace with the
two things the students built in this course, the controller and the car.

## 2. The bench

```text
trace (km/h) ──► u_s ┐
                     CruiseController (y_min = −1, y_max = 1) ──► y
car.v_kmh ────► u_m ┘                                             │
                                  ┌───────────────────────────────┤
                       Limiter [0, 1] ──► car.pedal               │
                       Limiter [−1, 0] ──► Gain(−F_brake_max) ──► car.F_brake
car.fuel_lph ──► Integrator(k = 1/3600) ──► fuel_L   [L]
car.v_kmh    ──► Integrator(k = 1/3600) ──► dist_km  [km]
```

- **Controller.** The student's own `CruiseController` from Lecture 1 step 6d: P, I and filtered D
  on the measurement, a `limiter` with `y_min`/`y_max`, clamping anti-windup. Here its output is a
  normalized effort, −1 full brake to +1 full pedal, so `y_min = −1`, `y_max = 1`. The gains change
  units: Lecture 1's `k = 56` was N·m per km/h; here `k` is pedal per km/h, two orders of
  magnitude smaller. The reference uses `k = 0.14`, `Ti = 3.5`, `Td = 0.7`, `xd0 = xi0 = 0`. On
  the full cycle its effort stays between −0.67 and +0.29, so neither limit binds and the clamp
  never acts.
- **Output split by sign**, as MathWorks' Longitudinal Driver does: the positive part goes to
  `car.pedal`, the negative part, times `F_brake_max`, to `car.F_brake`. `RoadBrake` takes a
  positive force command and acts against the motion, so the gain is `−F_brake_max`. Never both at
  once, by construction.
- **Fuel accounting.** `fuel_L` integrates `fuel_lph`; `dist_km` integrates `v_kmh`. The label
  figure is **L/100 km = 100 · fuel_L / dist_km** and **g CO₂/km = 2302 · fuel_L / dist_km**, both
  read at the end of the run, with the distance the car actually drove, not the trace's 23.27 km.

## 3. Given vs built

| Part | Built or given | Why |
|---|---|---|
| WLTC class 3b trace, `assets/data/drive_cycles/wltc_class3b.csv` | given (library data, committed and checked, see its README) | 1801 numbers from a regulation. |
| Trace block `Vehicle.DriveCycle` — target km/h out | given, `Vehicle` | One block on a file-backed interpolation of `time`: no input, output `y` in km/h. Structural parameter `file`, by default the packaged WLTC class 3b CSV; linear between the 1 Hz points, constant past the end. |
| `Vehicle.CVTDriveline` | given, already in the student's car since step 04 | Centrifugal launch clutch (engages around 1300 rpm), ratio 12.0–2.8, engine speed scheduled from the pedal, 1800–6000 rpm, 0.5 s lag. No driveline swap is needed. |
| `Vehicle.RoadBrake` | given, already in the student's car since step 06 B | `F_cmd · tanh(v / 0.05 m/s)` between body and road; stops the car and holds it at the cycle's 242 s of standstill. |
| `CruiseController` | **built** in Lecture 1; reused unchanged, only parameters set | The bonus is to see their own controller do a real job. |
| `MappedCar` with `F_brake` | **built** in steps 04–06; reused unchanged | The label number is for their car. |
| Bench `MappedCarWLTC` — trace, controller, output split, two integrators; analysis `MappedCarWLTCTransient`, `stop = 1800` | **built** | The wiring and the fuel accounting are the task. |
| Plots and the band check | **built**, from a REPL snippet on the page | The band check is a few lines of Julia; the page gives a starting point. |

The reference is `HandsOn02.MappedCarWLTC` (on `MappedCarWithBrake`), built on
`feat/handson02-wltc-bonus`. It holds the guide's parts under the guide's names (`trace`, `driver`,
`to_pedal`, `brake_part`, `to_brake`, `car`, `fuel_L`, `dist_km`), and its `driver` is
`Lecture1.Step06d.CruiseController`, the controller students built, not the course's copy with the
`with_I`/`with_D` switches. Full brake is `F_brake_max = 4000` N, step 06's firm stop.

**Initial state.** As step 04's bench: car at rest, engine idling behind the open clutch, the
flywheel's and the clutch output's angles set. The reference starts the engine at the idle step 06's brake stop
settles at, **775 rpm and 33 600 Pa** (step 04 uses 900 rpm and 101 325 Pa). The controller's derivative filter must start consistent with a car at
rest: with `wd = 0` that is `xd0 = 0`, not Lecture 1's −90.

## 4. Grading

Three criteria, each with its evidence in the pull request:

1. **Tracking.** The car stays inside the WLTP band — ±2 km/h around the trace and ±1 s in time
   (EU 2017/1151 Annex XXI Sub-Annex 6 §1.2.6.6) — for most of the cycle. Evidence: a plot of
   `car.v_kmh` over the target, a plot of the speed error, and the share of time inside the band.
   Pass mark, proposed, for the lecturer to confirm: **at least 95 %** (the reference: 98.5 %).
2. **The label numbers.** L/100 km and g CO₂/km inside a band around the reference:
   reference **5.22 L/100 km, 120 g/km**; proposed band, for the lecturer to confirm,
   **±0.25 L/100 km**: 4.97–5.47 L/100 km and 114–126 g/km. Not the reference's own gain sweep
   (5.16–5.22, §5): students' own `MapEngine` and gains move the figure more than that. The
   distance driven is handed in too; it
   should be 23.27 km within about 1 % if criterion 1 holds.
3. **The comparison.** One paragraph on why the figure differs from the Mazda2 1.5 Skyactiv-G
   label, **5.3 L/100 km, 120 g/km** WLTP combined. Expected points: the CVT never lets the engine
   below 1800 rpm, so the Low phase burns more than a manual would (step 05 showed it at 50 km/h,
   3.7 against 3.3 L/100 km); the maps are a 2.0 L engine scaled, not the Mazda2's; a hot start
   (the test starts cold); a lossless CVT; no auxiliaries; 1400 kg against the real car's mass.

**Fallback scope.** If an 1800 s run is too slow in Studio, the Low and Medium phases only,
**0–1022 s**, 7.851 km, for partial credit: `stop = 1022`, same three criteria on the shorter
trace. The reference on that run: 7.85 km, **5.59 L/100 km**, 129 g/km, 98.6 % inside the band;
the band is again ±0.25 L/100 km, 5.34–5.84, and 95 %. Run time, measured in the Julia REPL (the
same Julia as Studio): about 56 s for a first run of either length, almost all compilation, then
6 s for the full cycle and 5 s for the fallback.

The lecturer's brief says "Low + Medium (0–589 s)", but 0–589 s is Low alone (3.10 km); Low and
Medium end at 1022 s. The page and the reference take the phase names: `stop = 1022`. Low alone,
`stop = 589` (3.10 km, 6.30 L/100 km), is the page's wiring check, not a graded scope.

## 5. Expected numbers

### Class of the car

- Rated power from `data/engine/full_load.csv`: max of T·ω is **86.8 kW at 6000 rpm**.
- PMR = 86 800 / 1325 = **65.5 W/kg** (EU definition, running order minus 75 kg) > 34 W/kg →
  **class 3**; v_max 205 km/h (step 04) ≥ 120 km/h → **class 3b**.
- No downscaling: required-power ratio at t = 1566 s is 38.9 / 86.8 = **0.45**, below the
  class 3 threshold r0 = 0.867 (Sub-Annex 1 §8.3). No capping: v_max > 131.3 km/h.

### The cycle (DieselNet; matched by the committed file)

| Phase | s | Stop s | km | Max km/h |
|---|---|---|---|---|
| Low 3 | 0–589 | 156 | 3.095 | 56.5 |
| Medium 3b | 590–1022 | 48 | 4.756 | 76.6 |
| High 3b | 1023–1477 | 31 | 7.162 | 97.4 |
| Extra-high 3 | 1478–1800 | 7 | 8.254 | 131.3 |
| Total | 1800 | 242 | 23.266 | 131.3 |

Hardest acceleration 1.67 m/s² (t = 1029 s), hardest deceleration 1.5 m/s² (t = 278 s): 2100 N of
brake on 1400 kg before road load helps. Step 04's car does 0–100 km/h in 10.4 s, 2.7 m/s² on
average, so full pedal has margin over the trace everywhere.

### A lower bound, not a prediction

An earlier quasi-static estimate for this plan put an **ideal CVT** on the map's minimum-fuel line
(ratio 2–16, ≥ 1200 rpm, lossless, hot, no auxiliaries) and got **4.93 L/100 km, 113 g CO₂/km**.
The course's `CVTDriveline` does not follow that line: it schedules engine speed from the pedal and
never goes below 1800 rpm. So 4.93 is only a **sanity floor**: a reference run below it means the
accounting is wrong (fuel lost, or distance overcounted). The reference run's figure is
**5.22 L/100 km, 120 g/km**, 6 % above the floor.

### The reference run

| | Full cycle | Low + Medium |
|---|---|---|
| Distance | 23.27 km | 7.85 km |
| Fuel | 1.214 L | 0.439 L |
| L/100 km | 5.22 | 5.59 |
| g CO₂/km | 120 | 129 |
| Inside ±2 km/h, ±1 s | 98.5 % | 98.6 % |
| Inside ±2 km/h alone | 86 % | 84 % |
| Worst error | 6.4 km/h (961 s) | 6.4 km/h |

By phase: Low 6.30, Medium 5.14, High 4.59, Extra High 5.41 L/100 km. The ±2 km/h alone is not
the criterion: on the trace's ramps, a second behind is several km/h, which the ±1 s takes up.

Gain sweep on the full cycle, same bench:

| `k`, `Ti`, `Td` | L/100 km | Inside the band |
|---|---|---|
| 0.14, 3.5, 0.7 (reference) | 5.22 | 98.5 % |
| 0.10, 5, 0.5 | 5.19 | 99.0 % |
| 0.07, 7, 0.3 | 5.16 | 99.4 % |

The gentler gains do slightly better on the band. The reference keeps 0.14, 3.5, 0.7, tuned first,
since all three clear 95 % with room.

The same estimate's 5-speed (5.26) and fixed-gear (5.63, not drivable: it lacks torque for 116 s
of launches) rows are not comparable with this car and are dropped.

### The label to compare against

- Mazda2 1.5 Skyactiv-G 90 PS, manual, 2020–2023, Euro 6d: **5.3 L/100 km, 120 g CO₂/km** WLTP
  combined (Autotijd). Same engine family as the ALPHA map (2.0 L Skyactiv-G scaled to 1.5 L, M4).
- A production push-belt CVT is about 84.6 % efficient against about 96 % for a manual (TU Crete,
  MED 2013); the model's CVT is lossless, which pulls its figure down. The 1800 rpm floor pushes it
  up. Which wins is what criterion 3 asks the student to argue from their own run.

## 6. Risks in the design

- **Run time.** 1800 s with fuel-cut latches and the CVT's ratio lag, under a PI that moves the
  pedal continuously, may take minutes in Studio. Measured on the reference: about 56 s for the
  first run, almost all compilation, then 6 s. The solver matters more: the default (`Auto`) stops
  with `MaxIters` at 1190 s of the full cycle (it finishes the 1022 s fallback); `Rodas5P` runs it
  through. Fallback scope above.
- **The pedal is two inputs at once.** In this car the pedal opens the throttle and schedules the
  CVT's engine speed. Every correction of the controller also moves the ratio, through a 0.5 s lag,
  and the flywheel's speed change takes or returns energy. A high-gain controller will rock the
  ratio; the reference gains should be the gentlest that hold the band.
- **Fuel-cut chatter.** The cut arms when the pedal is ≤ 1e-4 above 1300 rpm, and the output split
  gives exactly 0 whenever the controller asks to brake or coast. Near zero effort the controller
  can toggle between a little pedal and a little brake, and the fuel with it. The reference runs
  through with `Rodas5P` and no dead band, so none is given.
- **Parked integrator at stops.** `RoadBrake`'s regularized friction holds the car only with a
  creep, so at rest the error stays slightly negative and the integrator keeps winding down. On
  the reference it reaches −4.8 (an effort of −0.67, about 2700 N), and 2 s into the next launch
  the car is up to 3.7 km/h behind the trace (2.1 on average). That is inside the ±1 s tolerance:
  none of the reference's 13 band misses is within 14 s of a launch. They sit mostly at 10–25 km/h
  with the car 2–4 km/h behind. No preview of the trace is needed; the page names conditional
  integration or a reset at standstill as an optional extra.
- **The derivative branch.** Lecture 1's controller has no `with_D` switch, and `Td = 0` makes its
  filter time constant zero. Students keep D with the reference's `Td` and `Nd`, or set a small
  `Td`; they must set `xd0 = 0`, else the first instant carries a large D kick.
- **Distance from the car.** `MappedCar` has no distance output, hence the second integrator;
  `car.body.mass.s / 1000` gives the same number and is a cross-check.

## 7. Checks the reference should carry

What the reference carries, on the Dyad branch:

- `Vehicle.TestDriveCycle`: the trace block's linear interpolation against a snapshot;
- testset "Hands-on 02 WLTC bonus" in `test/engine_plausibility.jl`: the Low and Medium run
  (`stop = 1022`) and the full cycle, each to the digits the page shows: distance, L/100 km, and
  the share inside the ±2 km/h, ±1 s band; g CO₂/km for the full cycle. The full cycle reuses the
  first run's compilation, so it adds about 6 s to the suite;
- pedal and brake never act together by construction (two limiters on one signal), so no test.

## 8. Sources

- **DieselNet, "Worldwide Harmonized Light Vehicles Test Cycle (WLTC)"**,
  <https://dieselnet.com/standards/cycles/wltp.php>. Class thresholds, PMR, phase table,
  downscaling and capping. © ECOpoint Inc.: cite, do not copy data.
- **Regulation (EU) 2017/1151, Annex XXI, Sub-Annex 1** (WLTC), via
  <https://gesetze.legal/eu/vo_eu_2017_1151/unteranhang_1>. The committed trace's source; its
  provenance and checks are in `assets/data/drive_cycles/README.md`.
- **MathWorks, "Track Drive Cycle Errors"**,
  <https://www.mathworks.com/help/autoblks/ug/track-drive-cycle-errors.html>. WLTP tolerance
  ±2.0 km/h and ±1.0 s, citing 2017/1151 §1.2.6.6.
- **MathWorks, "Longitudinal Driver"**,
  <https://www.mathworks.com/help/autoblks/ref/longitudinaldriver.html>. PI driver, sign split into
  accelerator and brake.
- **TU Crete Robolab, CVT efficiency paper, MED 2013**,
  <https://www.robolab.tuc.gr/fileadmin/users_data/robolab/publications/2013_publications/2013_On_the_Efficiency__Variable_Transmission.pdf>.
  Belt CVT about 84.6 % overall, manual about 96 %.
- **Autotijd, Mazda2 Skyactiv-G 1.5 90 PS manual (2020–2023)**,
  <https://autotijd.be/en/consumption/mazda/mazda2/skyactiv-g-15-90-hp-manual-2245>. WLTP combined
  5.3 L/100 km, 120 g/km. Secondary; replace with an official figure if one is found.
- **In this repository:** `dyad/Vehicle/CVTDriveline.dyad`, `RoadBrake.dyad`;
  `dyad/HandsOn02/MappedCarWithBrake.dyad`; `dyad/Lecture1/Step06d/CruiseController.dyad` (the
  controller students built, which the reference uses); `dyad/HandsOn02/MappedCarWLTC.dyad` (the
  reference bench).
