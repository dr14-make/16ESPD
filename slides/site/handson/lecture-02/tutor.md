---
title: Lecture 2 hands-on — tutor guide
---

[← Vehicle Systems & Components](../../index.html) · [Student guide](./) · [Projector deck →](../../handson-02/index.html){target="_self"}

# Lecture 2 hands-on: tutor guide

What to say, how long each part takes, where students stall, and the answer models

Students follow the [student guide](./): it holds every instruction, the theory in its **Why** boxes, and the checkpoints. The [projector deck](../../handson-02/index.html){target="_self"} shows one slide per step: the goal, the finished model, the checkpoint numbers and the time budget. This page is for you. Read it once before the session and keep it open beside the deck; each slide's speaker note links to its section here.

## Before the session {#before}

- **Screens.** Deck on the projector, Dyad Studio on your laptop with your own `MyCar` from hands-on 1 open on `main`. Open **presenter mode** from the deck's nav bar.
- **On the board:** the link to the student guide, `handson/lecture-02/` on the course site.
- **Where this sits.** After the engine lecture. Its last section, "The mapped engine", promised what we do today: a pedal, a throttle, a manifold pressure, and measured maps that return torque, fuel and CO₂. Today students build it into the car they built in hands-on 1.
- **Deep links** into the deck are by name: `#/cruise` is step 05, `#/map-engine` step 03.

### Time

About 90 minutes. Step 07 is a bonus task for after the session.

| Step | Min | Split |
| --- | --: | --- |
| 00 Set up | 8 | the add downloads and precompiles; talk through step 01's maps while it runs |
| 01 Read the maps | 12 | 4 of theory, 8 in the REPL |
| 02 Manifold | 15 | 4 of theory, 3 to paste, 5 to draw the bench, 3 to run twice |
| 03 Map engine | 20 | 3 of theory, 8 to draw the engine, 3 to paste the bench, 3 for runs 1 and 2, 3 for the fuel-cut paste and its run |
| 04 Mapped car | 12 | 2 of theory, 7 to duplicate, swap engine and driveline and rewire, 3 for the full-pedal run |
| 05 Cruise | 12 | 3 of theory, 2 to paste the bench, 4 for three runs, 3 to fill the table and compare |
| 06 Coast and brake | 8 | 4 for the coast-down, 4 for the brake |
| Hand in | 3 | |

**Where the time really goes.** In rehearsal, step 03 E, the fuel-cut paste and its run, took about **12 minutes** against its 3-minute budget. Plan for it: if the room is behind at the end of 03 D, demonstrate E on the projector and let students paste it while you talk.

**If time runs short:** cut step 06's brake stop first, then step 02's 3000 rpm run. Do not cut step 05: the cruise numbers are the session's result.

### Answer models

Every finished model a student builds in steps 02–06 is in the course library, `dyad/HandsOn02/`, under the guide's names. Students see them under **+** in the `HandsOn02` folder; the guide tells them to build their own and open these only to compare.

| Step | Component | Analysis |
| --- | --- | --- |
| 02 | `HandsOn02.Manifold`, `HandsOn02.AirPathStep` | `HandsOn02.AirPathStepTransient` |
| 03 A–D | `HandsOn02.MapEngine`, `HandsOn02.MapEngineDyno` | `HandsOn02.MapEngineDynoTransient` |
| 03 E | `HandsOn02.MapEngineFuelCut`, `HandsOn02.MapEngineFuelCutDyno` | `HandsOn02.MapEngineFuelCutDynoTransient` |
| 04 | `HandsOn02.MappedCar`, `HandsOn02.MappedCarWOT` | `HandsOn02.MappedCarWOTTransient` |
| 05 | `HandsOn02.MappedCarCruise` | `HandsOn02.MappedCarCruiseTransient` |
| 06 A | `HandsOn02.MappedCarCoast` | `HandsOn02.MappedCarCoastTransient` |
| 06 B | `HandsOn02.MappedCarWithBrake`, `HandsOn02.MappedCarBrakeStop` | `HandsOn02.MappedCarBrakeStopTransient` |

The given parts of steps 04–06 are `Vehicle.CVTDriveline` (with `CentrifugalClutch` and `ControlledVariator`) and `Vehicle.RoadBrake`. Students edit their one `MappedCar` in place; the library keeps it before and after the brake, as `MappedCar` and `MappedCarWithBrake`, and their `MappedCarCoast` after part B is `MappedCarBrakeStop`.

The guide's *Stuck? The full model* boxes hold the code of steps 02 and 03, and step 04's code tabs the car's. Every checkpoint is tested in `test/engine_plausibility.jl`: steps 01–03 in the testsets "Hands-on 02 map engine", "Hands-on 02 manifold", "Hands-on 02 cruise table" and "Hands-on 02 fuel cut"; steps 04–06 in "Hands-on 02 CVT", "Hands-on 02 CVT cruise", "Hands-on 02 CVT coast and brake" and "Vehicle road brake".

### Opening

**Say:** Hands-on 1 ended with a promise. Our car reached 246 km/h, and we said the number was wrong: a real engine gives its torque only in the middle of its speed range. The engine lecture showed what a real engine control unit does instead: it measures the engine speed and the pressure in the intake manifold, and looks both up in tables. Today we use real tables, measured by the US EPA on a Mazda engine.

**Ask the room:** what does a car's sticker say about fuel? *(Liters per 100 km and grams of CO₂ per km. By the end of today they have both for their own car at three speeds.)*

**Point at** the overview diagram on the title slide, and follow the air: the pedal opens the throttle, air fills the manifold, the cylinders draw it out. The manifold pressure is what is left: a state, which takes time to change. The maps are read at speed and that pressure. Students build the manifold (step 02) and a small map engine (step 03); the throttle and the cylinders come finished from the course library, physics the lecture stated, not what today teaches. The booster hose port, `vacuum`, stays unconnected today, which caps it; the brake lecture connects it.

**Say:** the same rhythm as hands-on 1: predict a number, build, check the model gives it. Step 01 predicts the day's most important number, the fuel at 90 km/h, from the tables alone, for hands-on 1's single gear; step 05 measures the CVT car, which runs at another point of the same map, and compares. Step 04 is the milestone: the same car with a real engine and a CVT, and it no longer reaches 246. Keep the names the guide gives, `engine`, `car`, `p_m`, `fuel_lph`: the plot commands use them.

## 00 Set up {#setup}

**Say:** today's engine uses parts you will not build: the throttle, the cylinders' air flow, the map tables and the fuel-cut logic. They live in the course library, `VehicleSystemsComponents`. One line in the REPL adds it, like the standard libraries in hands-on 1, and its parts appear under **+**.

**Rehearsed:** `Pkg.add(url = …)` plus **Dyad: Compile** is enough: the library shows under **+** in a diagram.

**Where students stall:**

- **Branching from `main`,** which holds only the empty library: step 04 then has no `Car` to duplicate. Check a few status bars.
- **Pkg's yellow warning** after the add, "different versions are currently loaded … Restart julia". Harmless; carry on.
- **Looking for the library in the left Components tree.** It shows only under **+**; that is expected.
- **The `HandsOn02` folder and the `Test…` components** under **+** are the reference answers. Build your own.
- **A network error during the add:** pair the student with a neighbor.

**Open:** pin the add to a tag once the course library's branch merges, so students get the engine the checkpoints were read from.

## 01 Read the maps {#maps}

**Say:** before any model, the data. Three tables on the same grid, measured on a test bench by the US EPA and scaled to our 1.5 L engine. We find the 90 km/h point in them by hand; step 05 measures the same point in the car, and if the two agree the car is right. Then the guide's *Why speed and manifold pressure* box: speed and pressure fix the engine's state; the "moment later" is step 02.

**Do it on the board**, one column at a time, from the guide's *Details* box under step 01: where on the map, how much fuel, per 100 km. We have not built anything, and we already know what the car burns at 90.

**Point at** the torque map's left edge: negative torque at low pressure, the engine pumping against a vacuum. Step 06 uses it to brake the car. λ is 1 almost everywhere, for the catalyst; rich only near full load.

**Where students stall:**

- **Reading kPa as gauge pressure.** They are absolute: 101 kPa is wide open, 33 kPa at idle a strong vacuum.
- **`kpa, rpm, T = engine_map("fuel_gps.csv")`,** which overwrites the torque map in `T`. The guide names the others `F` and `L`.
- **`heatmap(rpm, kpa, T)`, axes swapped.** Plots wants x, y, then a matrix with one row per y. The file's rows are speeds, so speeds go on y.
- **Which pressure.** 47.7 kPa is the 3000 rpm row; the 90 km/h point itself, at 3080 rpm, is 47.8 kPa. The plot marker goes at 3080 rpm, 47.8 kPa.

**Where the numbers come from:** US EPA ALPHA, 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L at constant BMEP and BSFC, and re-gridded from a torque axis to a manifold-pressure axis by `scripts/alpha_engine_maps.jl`; citation and every assumption in `data/engine/README.md`. The three cruise rows, 50 · 90 · 130 km/h, are checked to the digit in the "Hands-on 02 cruise table" testset.

**For step 03:** the map holds torque up to 105 kPa, above what the engine reaches. `full_load.csv` holds the real ceiling: 148.4 N·m at 3000 rpm against the map's 163.0 at 99.9 kPa.

## 02 Manifold {#manifold}

**Say:** the one equation this session is about. Hands-on 1 had a 0.3 s lag "because the manifold has to fill". Today the manifold is a real volume, and the lag comes out of it, different at every speed. Then the guide's bathtub box: the throttle is the tap, the cylinders the drain, and the drain pulls harder the fuller the tub.

**Built or given:** students paste the manifold, one equation, and draw the bench. The throttle (a choked-flow orifice) and the cylinders' air flow (a volumetric efficiency that must match the maps exactly) are given from `Vehicle.Engine`; neither is today's lesson.

**Point at** the feedback wire: `p_m` goes back into the throttle and the cylinders, because both flows depend on it. That loop is what makes the pressure settle.

**Say, on the runs:** at idle the pressure pulls down from the outside air to 33 kPa, and a tiny throttle opening lifts it to 37. At 3000 rpm with the throttle closed it pulls down much further, to 13.5: overrun, the vacuum the brake booster loves. Wide open, it is back near the outside pressure.

**Where students stall:**

- **Ports stacked in the middle of `manifold`.** They pasted a block without the `{"Dyad": …}` port placements, and the bench cannot be wired: paste the guide's block again.
- **Search results.** "Manifold" also offers the course's `IntakeManifold`; "Throttle" offers four throttles. Take their own `MyCar › Manifold` and the plain `Vehicle › Engine › Throttle`.
- **Default names.** The parts arrive with default names (`step`, a `constant…`, `throttle`, `cylinderairflow`, `manifold`): set parameters first, then rename to the guide's names.
- **The square port on `manifold`.** That is `vacuum`, the hose to the brake booster, a `GasPort`: pressure and air flow in one connector, as a spline carries angle and torque. Left unconnected it is capped and carries no air, so the bench needs nothing on it.
- **Which input is which.** The icons do not name their inputs: hover a port. `Throttle` has `u_thr` on top, `p_m` below; `CylinderAirflow` has `p_m` on top, `omega` below.
- **Parameter fields.** Click, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd>, type, <kbd>Enter</kbd>. <kbd>Ctrl</kbd>+<kbd>A</kbd> selects the whole Studio page, and a triple-click does not select the old value.
- **The `initial` line** forgotten, or put after `metadata`. It goes after the last `connect`; without it the solver does not know the manifold starts full of outside air.
- **`UndefVarError: AirPathStepTransient not defined`** in a REPL opened before the component existed. Run once with ▷ on the analysis tab, which loads it, or restart the REPL.
- **Reading 33 000 as wrong.** The plot is in pascals; divide by 1000.
- **Reading τ on the first fall from 101 kPa.** That fall is not a straight lag; its 1/e time is about 0.10 s. The 0.15 s is the small step at 1 s.
- **Expecting 0 kPa with the throttle closed.** A closed throttle still leaks, and the cylinders stop pulling once the pressure is low.

**Where the numbers come from:** the test cases of `Vehicle.Engine.TestAirPath` (idle 32955.7 Pa, idle step 37270 Pa, overrun 13482.4 Pa, tip-in 99889.9 Pa), and the "Hands-on 02 manifold" testset on `HandsOn02.AirPathStepTransient`. A student manifold with the given parts is the same equation, so it must give the same numbers. The τ derivation is in the guide's *Details* box.

## 03 Map engine on a dynamometer {#map-engine}

**Say:** this is the lecture's engine as a picture you draw. The pedal opens the throttle, the air path gives the manifold pressure, and two maps read at speed and pressure give torque and fuel; CO₂ is fuel × 3.09. The pedal goes straight to the throttle: no pedal curve, no actuator, so the only thing between pedal and torque is the manifold of step 02.

**Built or given:** students draw `MapEngine` from six given blocks: `AirPath` (step 02's bench, packaged), `TorqueMap` and `FuelMap` (their tables inside, from the course library's `EngineMapData`; they take rad/s and Pa and convert to the tables' rpm and kPa), a speed sensor, a gain and a torque source. The only number they type is 3.09. The dyno bench is pasted. At the end they paste fuel cut into their own engine; that engine goes into their car in step 04.

**The tight part is the 15-wire drawing.** If the room is slow, hand out the guide's *Stuck?* code and keep the runs.

**Ask the room**, before run 2: what does the engine do with the pedal closed at 3000 rpm? *(13.5 kPa from step 02; the map there says −18.2 N·m and still 0.097 g/s of fuel. Keep the answer: it opens E.)*

**Point at, run 1:** the time between the pedal step and the torque. The pedal jumps; the torque takes about 50 ms, because the manifold has to fill to the new pressure. That is the state of step 02, not Lecture 1's fixed lag. **Run 2:** wide open, the torque rises 10–90 % in about 2 ms; a big throttle opening fills the manifold almost at once and hides the lag, which is why run 1 is a small step.

**Where students stall, A–D:**

- **The shaft.** The speed sensor's circle goes to `spline`, the same port as the torque source's, or the sensor reads a shaft nobody drives. There is no flywheel: on the dynamometer the bench sets the speed.
- **Ports.** Drop each one from **+** straight onto the outline, in `MapEngine`'s own diagram. To move or rename one, click just outside it (a click on it starts a wire), then drag, or **Edit Parameters** → pencil.
- **Port names.** Hover to read them: `air` has `u_thr`, the square hose port `vacuum` and `omega` down its left edge and `mdot_thr`, `p_m`, `mdot_cyl` out; the maps have `omega` on top, `p_m` below.
- **The `vacuum` port.** It is a `GasPort` from the course library, not a `Dyad` port. If **+** does not offer it as a port, the guide's fallback is one code line, `vacuum = VehicleSystemsComponents.Vehicle.GasPort()`.
- **The last wire lost.** Save twice after it: one <kbd>Ctrl</kbd>+<kbd>S</kbd> can miss it, a known Studio bug. Then check the **Problems** tab is empty.
- **The pasted bench piles up in a corner** if its `{"Dyad": …}` placements were left out: paste the guide's block again.
- **Fuel read in kg/s.** The plot shows 0.00085, which is 0.85 g/s; wide open, 0.00375.

**E, the fuel-cut paste: the rehearsal's traps.**

- **▷ before the REPL.** The REPL keeps the `MapEngine` and `MapEngineDyno` it loaded before the paste and runs them without an error. A student who skips ▷ sees a speed that never ramps down, so the fuel never comes back; a REPL left open since step 00 shows no cut at all. One ▷ on `MapEngineDynoTransient` loads the edited ones.
- **The selection trap.** The paste blocks end without a line break; the site's copy button copies no trailing newline. A student who selects whole lines from the margin gets the next line joined onto the paste's last one. The guide says where to click and when to press <kbd>Enter</kbd>.
- **Diagonal wires.** The four new wires carry waypoints drawn for `HandsOn02.MapEngineFuelCut`'s layout, so on a student's own drawing they may cut diagonally across blocks. The connections are right. Dropping the waypoints is worse: Studio then draws straight diagonals across the whole diagram.
- **Nothing moves.** The two new map blocks have their ports where `TorqueMap`'s and `FuelMap`'s are, so retyping the two lines moves no wire.
- **Run 2 again, after the paste,** starts in the cut: 0 fuel and −18.7 N·m. The engine starts above 1300 rpm with the pedal closed. Runs 1 and 2 stop at 2 s, before the ramp, so they are otherwise unchanged.

**Say, on E:** the guide's *Why fuel cut* box: on overrun there is no reason to inject anything; the cut saves fuel, keeps unburned fuel out of the catalyst and brakes the car a little harder; it ends near idle so the engine does not stall. Two speeds, 1300 and 1000 rpm, so the injectors do not chatter: hysteresis, like a thermostat. Run 2's closed pedal read −18.2 N·m from the map; the cut gives −18.7, the closed-throttle curve: the 0.5 N·m is what the 0.097 g/s was still giving.

**Against `MappedEngine`:** the same −18.7 N·m after the same release, because it uses the same `FuelCutLogic` and curve. Its fuel goes a little later: its 50 ms throttle actuator keeps the manifold full a moment longer. In the cut the torque does not depend on `p_m`.

**Where the numbers come from:** run 1 starts at step 01's 90 km/h point (31.1 N·m, 47.8 kPa, 0.85 g/s; the pedal 0.1034 was found by bisection) and ends at 1.02 g/s. Run 2's pressures are `TestAirPath`'s at 3000 rpm, and the torques and fuel are the maps read there: `torque_Nm` at (3000, 99.9) = 163.0, capped by `full_load.csv` at 148.4; `fuel_gps` 3.75 g/s, × 3.09 = 11.6 g/s; closed, −18.2 N·m and 0.097 g/s. E's numbers are from `HandsOn02.MapEngineFuelCutDynoTransient`; the cut and resume speeds are `FuelCutLogic`'s defaults, 1300, 1000, 6500 and 6300 rpm, assumed. All are in the "Hands-on 02 map engine" and "Hands-on 02 fuel cut" testsets.

## 04 The car with a mapped engine {#mapped-car}

**Say:** the milestone. Same body; the engine changes to theirs, and with it the input: a pedal from 0 to 1, not a torque. Hands-on 1 ended on this question: what would you add to get a believable top speed? A torque curve. But a mapped engine cannot sit on hands-on 1's single gear: at a standstill it would turn at 0 rpm and give nothing, and flat out it would hit the rev limiter at 190 km/h. So the driveline becomes a given CVT with a launch clutch. Then the guide's *Why a CVT* box: the clutch grips with engine speed, around 1300 rpm; the ratio runs from 12.0 to 2.8; the pedal picks the engine speed, 1800 to 6000 rpm, and the CVT picks the ratio that gets it there.

**Built or given:** students duplicate their car, swap in their engine and the given `CVTDriveline`, add the flywheel and the two outputs, leave the engine's `vacuum` hose port capped, and add one parameter line in code. The bench is pasted.

**Duplicate, do not edit:** their hands-on 1 car stays as it was, and Lecture 1's cruise control still runs on it.

**Point at** the gain: fuel comes out in kilograms per second, a tiny number; 3600 / 0.745 = 4832.2 turns it into liters per hour. The flywheel: on the dynamometer the bench set the speed; in the car the crankshaft and flywheel resist every change of engine speed. And the pedal wire that goes to the driveline: the CVT reads the pedal too.

**Point at, on the plot:** the engine sits at 1300 rpm for the first second while the clutch slips; that is a centrifugal clutch launching. Then it runs up past 6000 rpm, peaks at 6390 and settles at 6000: up to about 58 km/h the ratio is on its 12.0 stop, so it cannot hold the engine back. The rev limiter never acts.

**Derivation, if asked:** at top speed the CVT holds 6000 rpm and passes all the power to the wheels. Wide open at 6000 rpm the manifold reaches 98.8 kPa and the map gives 126.5 N·m, 79.5 kW. The road takes (0.378 v² + 165) v; 79.5 kW at 57.0 m/s, 205 km/h. The full-load curve says 138 N·m at 6000 rpm, but it needs 106 kPa, more than the air path can reach without a turbocharger.

**Ask the room:** why does the engine not settle at its 6500 rpm limit? *(The controller asks for 6000 rpm floored, 500 under the limiter, and the ratio follows it.)*

**Where students stall:**

- **`driveline.pedal` left unconnected.** The model then has an input nobody drives and does not compile: the same "unbalanced" error as hands-on 1's missing support. The engine's `vacuum` port is different: it is a hose, not an input, and left open it is capped.
- **The two driveline supports.** `CVTDriveline` has `support_r` and `support_t` at its bottom, as the old one: rotational to `rot_ground`, translational to `trans_ground`.
- **An empty diagram after Duplicate,** "Unknown entity MappedCar" behind the red ⓘ, and the copy missing from **Components**: Studio has not read the new file yet. Open `mappedcar.dyad` once with <kbd>Ctrl</kbd>+<kbd>P</kbd>, then the diagram from the tree. Same in step 06 for `MappedCarCoast`.
- **Two strings in a row.** The rename keeps hands-on 1's `"Commanded engine torque"` above `pedal`; the `ratio_initial` lines added under it give a syntax error. Replace that line.
- **`UndefVarError: MappedCarWOTTransient not defined`:** the REPL from step 00 does not know components made since. ▷ on the analysis tab first, in steps 05 and 06 too.
- **The `ratio_initial` edit forgotten.** Step 04's bench runs without it; step 05's bench then fails with an override that matches nothing. Add the parameter line and the `ratio_initial = ratio_initial` in the `driveline` line.
- **Ports renamed on an instance.** Rename and place `MappedCar`'s ports in its own diagram, not on a `car` in a bench.
- **Reading rad/s as rpm.** `car.engine.speed.w` is rad/s: 1300 rpm is 136, 6000 rpm is 628.

**Where the numbers come from:** `HandsOn02.MappedCarWOTTransient`, the "Hands-on 02 CVT" testset: clutch lock at 1.33 s, 13.7 km/h, 1414 rpm; 0–100 km/h in 10.4 s; peak 6390 rpm at 6.4 s; 197 km/h at 60 s, 205 km/h at 120 s, 205.3 km/h at 300 s with ratio 3.41. The CVT and clutch calibration (12.0–2.8, 1800–6000 rpm, 0.5 s, 1300 ± 120 rpm, 230 N·m) are assumed values for a small-car belt CVT, documented in `Vehicle.ControlledVariator` and `Vehicle.CentrifugalClutch`.

## 05 Cruise: fuel and CO₂ {#cruise}

**Say:** the session's result. Three steady speeds, three fuel figures. The bench starts the car steady, at the speed, engine speed and ratio its pedal settles them, so if the speed stays put for a minute, the fuel flow is the cruise consumption. The engine gives liters per hour, the car covers kilometers per hour: divide, and the hours cancel.

**Ask the room:** a car at idle, standing still. What is its L/100 km? *(Infinite: fuel flows, distance does not. That is why the sticker uses a driving cycle, step 07.)*

**Then ask:** step 01 predicted 4.6 L/100 km at 90 km/h for the fixed gear. Will the CVT car burn more or less? *(Less at 90 and 130, more at 50; the guide's Why box explains it.)*

**Point at** the table's last column. Same road, same power, a different point on the map. At 90 and 130 the CVT runs the engine slower and less throttled: 3.9 against 4.6, 6.0 against 7.0. At 50 its controller will not go below 1800 rpm, so the engine runs faster than the fixed gear's 1710 and more throttled: 3.7 against 3.3. The controller follows the pedal, not the map; a fuel-optimal schedule would follow the map's lowest-consumption line. That is an extension, not built.

**Point at** 130 against 50: 2.6 × the speed, 4.2 × the fuel per hour, 1.6 × the fuel per kilometer; drag goes with v². Why below a real car's label: steady speed, warm engine, a lossless CVT, no auxiliaries; step 07 is where the comparison is fair.

**Where students stall:**

- **The override error** "don't match names found in model: ratio_initial": step 04's parameter line is missing in their `MappedCar`.
- **A speed that drifts** a few km/h: a pedal typed with too few digits. The values are given to five; 0.049 instead of 0.04878 drifts visibly in 60 s.
- **Reading kg/s or Pa.** `car.fuel_lph` is already L/h; `car.p_m` is Pa.

**Where the numbers come from:** `HandsOn02.MappedCarCruiseTransient` at the three pedals, the "Hands-on 02 CVT cruise" testset: each holds its speed within 0.25 km/h over 60 s, and every number in the guide's table is checked to the digit shown. The testset also reads the fuel map at the CVT's rpm and `p_m` and gets the same fuel flow. The fixed-gear column is step 01's, checked in "Hands-on 02 cruise table".

## 06 Coast-down and a brake stop {#coast-brake}

**Say:** two things a driver does a hundred times a day, both invisible from the seat. Lift your foot at 90: the throttle closes, the manifold empties, and the engine control unit cuts the fuel, to zero, not to idle. The engine is now an air pump driven by the wheels, and pumping against that vacuum brakes the car. Then the brake: a brake booster's vacuum side is connected to this manifold, and the deeper the vacuum while you brake, the more it helps your foot.

**Ask the room:** with one gear the fuel came back at 29 km/h, where the engine fell below 1000 rpm. Where does it come back with the CVT? *(About 11 km/h: released, the CVT raises the ratio to hold the engine near 1800 rpm until the ratio runs out near 15 km/h. Coasting from 90 burns nothing for a minute.)*

**Point at** the coast plot's engine panel: flat near 1750 rpm while the car slows from 75 to 20 km/h, the ratio doing the work. Then the clutch lets go at 1140 rpm, the engine drops under 1000 and the fuel comes back; the car rolls on to rest in neutral, as it were, at 0.12 m/s², rolling resistance alone.

**Derivation:** at the release the engine turns 2150 rpm and gives −16.7 N·m on the closed-throttle curve; × 2.81 / 0.31 = 151 N at the wheel, less what the slowing flywheel gives back: about 140 N. With 401 N of road load, 541 N / 1400 kg = 0.39 m/s²; in neutral 0.29. `p_m` falls to 17.1 kPa, not step 02's 13.5: the engine turns slower than 3000 rpm.

**The brake.** Students place the given `RoadBrake`, friction between body and road. A plain `Force` source pushes the car backwards once it stops, and its sign depends on the wiring; `RoadBrake` fades to zero over the last 0.05 m/s, so it stops the car and holds it, either way round. With 4000 N the car stops in 7.9 s, the engine idles behind the open clutch, and `p_m` never rises above 34 kPa.

**If short of time,** do only the coast-down.

**Where students stall:**

- **Benches that stop compiling** after `F_brake` is added: every other car bench now has an input nobody drives, and the run stops with "The system is unbalanced … 78 highest order derivative variables and 77 equations". Each needs a `Constant(k = 0)` into `car.F_brake`.
- **The coast run ending at 20 s** after part B: the brake is now in their `MappedCarCoast`, and `stop = 20` is passed in the REPL. The coast-down itself stays in the course library as `HandsOn02.MappedCarCoast`.
- **Reading the fuel's return on the speed panel.** It is on the fuel panel, where the engine panel crosses 1000 rpm.

**Where the numbers come from:** `HandsOn02.MappedCarCoastTransient` and `HandsOn02.MappedCarBrakeStopTransient`, the "Hands-on 02 CVT coast and brake" testset: coast cut at 5.0 s, `p_m` 17.1 kPa, 0.39 m/s², clutch open at 66.0 s / 11.2 km/h / 1140 rpm, fuel back at 66.3 s / 10.8 km/h / 27.4 kPa, idle 775 rpm / 33.6 kPa / 0.47 L/h, at rest at 91 s; brake 3.2 m/s², 25 km/h at 10.7 s, at rest at 12.9 s, `p_m` 17.6–33.7 kPa, no stall. `RoadBrake` is checked both ways round in the "Vehicle road brake" testset.

## Hand in {#hand-in}

**Say:** same as last time. The description carries the cruise table: three speeds, L/100 km and g CO₂/km.

**Where students stall:** a base of `main` while hands-on 1's pull request is still open: the pull request then shows hands-on 1's commits too. The base is the branch `handson-02` was created from.

## 07 Bonus: drive the WLTC {#wltc}

**Not in the session.** An extra task for extra points, done after step 06 and handed in with the same pull request. Announce it at the hand-in and point at the guide; take questions in the next session.

**Say:** the label is not a cruise number, it is a 30-minute trace. Drive it with two things you built: Lecture 1's cruise controller as the driver, your car as the car. The controller's output is an effort from −1 to +1; above zero it is the pedal, below zero the brake.

**How it is graded,** each from the pull request's `Bonus: WLTC` section:

1. **Tracking:** the speed-and-target plot and the error plot, and the share of the run inside ±2 km/h, ±1 s: at least 95 % (the reference: 98.5 %).
2. **Label numbers:** L/100 km and g CO₂/km within ±0.25 L/100 km of the reference, 4.97–5.47 L/100 km and 114–126 g/km, with fuel and distance stated. The distance should be 23.27 km within about 1 %; far off, criterion 1 cannot hold either.
3. **The paragraph:** credit for any two of the CVT's 1800 rpm floor (step 05 at 50 km/h: 3.7 against 3.3 L/100 km), maps from another engine, a hot start where the test starts cold; lossless CVT, no auxiliaries and the car's mass are fine extras.

A run of the Low and Medium phases only (`stop = 1022`) earns partial credit, on the same 95 % and 5.34–5.84 L/100 km.

**Proposed, for the lecturer to confirm:** the 95 % and ±0.25 L/100 km marks above. They are not the spread of the reference's own gain sweep (5.16–5.22 L/100 km, 98.5–99.4 % in the band): students' own `MapEngine` and gains move the figure more than that. The lower edge, 4.97, sits just above the 4.93 L/100 km floor below.

**Common failures:**

- **The run stops at 1190 s with `MaxIters`.** The analysis kept the default solver. The page's step 5 puts `alg = ODEAlg.Rodas5P()` in the `extends` line.
- **No brake path.** Only the positive part wired, or `F_brake` held at `Constant(0)` from step 06. The car cannot slow as fast as the trace (1.5 m/s² at 278 s); it overshoots every deceleration and the error plot shows negative spikes before each stop.
- **`y_min = 0` from Lecture 1's bench.** The output never goes negative, so the brake path never gets a command: the same symptom as no brake path.
- **A late start after every stop.** Expected, not a fault: while the brake holds the car at rest the integrator keeps a negative value, down to −4.8 on the reference (an effort of −0.67, about 2700 N), and 2 s into the next launch the car is up to 3.7 km/h behind the trace. It stays inside the ±1 s tolerance: none of the reference's band misses is at a launch. The clamp does not act here, since the effort never reaches −1. Credit conditional integration or an integrator reset at standstill as an extra; do not require it.
- **Grading themselves on ±2 km/h alone.** The reference is inside ±2 km/h for only 86 % of the run: on the steep ramps a second behind is several km/h. The ±1 s is part of the criterion, and the page's snippet checks both. The reference's 1.5 % outside the band is 13 short stretches, mostly at 10–25 km/h with the car 2–4 km/h behind.
- **Dividing by 23.27 km** instead of the distance driven. A lagging car drives less and looks more frugal; ask for `dist_km`.
- **Lecture 1's gains and seeds.** `k = 56` was N·m per km/h; on a ±1 effort it slams pedal and brake. And `xd0 = -90` was the seed for a 90 km/h cruise; from rest it is 0, else the first instant carries a large D kick. `Td` must stay above zero: the filter's time constant is `Td / Nd`.
- **The sign of the brake gain.** `to_brake` takes the negative part, so its gain is −`F_brake_max`; a positive gain gives a negative force, which `RoadBrake` treats as released.

**Where the numbers come from:** the course's reference bench (not in the library students install, so they build it themselves) on `MappedCarWithBrake`, with the step 6d controller (`Lecture1.Step06d.CruiseController`, `k = 0.14`, `Ti = 3.5`, `Td = 0.7`, `xd0 = xi0 = 0`, limits ±1) and 4000 N of brake, started at 775 rpm and 33.6 kPa; the "Hands-on 02 WLTC bonus" testset. Full cycle: 23.27 km, 1.214 L, 5.22 L/100 km, 120 g/km, 98.5 % inside the band (86 % inside ±2 km/h alone, worst error 6.4 km/h), effort between −0.67 and +0.29. Low and Medium (`stop = 1022`): 7.85 km, 5.59 L/100 km, 98.6 %. Gain sweep, full cycle: `k = 0.07, Ti = 7, Td = 0.3` gives 5.16 and 99.4 %; `0.10, 5, 0.5` gives 5.19 and 99.0 %. Run time in the Julia REPL: about a minute for the first run, mostly compilation, then 5–7 s; the default solver stops with `MaxIters` at 1190 s of the full cycle, hence `alg = ODEAlg.Rodas5P()` on the page (the 1022 s run finishes either way). A quasi-static estimate with an ideal CVT on the minimum-fuel line gives 4.93 L/100 km; a figure below that means the accounting is wrong. Plan: `docs/lecture-02-handson-step07-wltc-plan.md`.

## Wrap-up {#wrap-up}

**Say:** steps 01–03's numbers were known before any model ran, and where their run agreed, the model is right. The CVT car's numbers are the same map read at other points: the fuel map at the CVT's rpm and pressure gives exactly the fuel the car burned. **Point at** step 05: those are the numbers on a car's sticker, computed from a table measured on a test bench and a force balance they wrote in hands-on 1; and the gearbox alone moves them by 12–15 %.
