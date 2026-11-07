---
title: Lecture 5 — compose a P2 hybrid powertrain
---

[← Vehicle Systems & Components](../../index.html)

# Lecture 5: compose a P2 hybrid powertrain

Rehearsed in Dyad Studio 3.5.1. Code-view work is called out below; the revised powertrain diagram will be checked after these fixes land.

**What you build.** A transmission-input P2 hybrid from existing library parts: mapped engine → disconnect clutch K0 → machine shaft → controlled variator → differential → front wheels. Step 2 adds the operating-line lookup and speed-commanded variator. Steps 3 and 4 add the energy manager, clutch starts and charge-sustaining comparison.

**Working module.** In `VehicleSystemsComponents`, create a module named `MyCar` (right-click the library › **Add Module**). Add a component with the **+** on its row. If the empty module does not appear, create `P2Powertrain` at the library root, move its `.dyad` file into `dyad/MyCar/`, then use **F1 › Dyad: Compile**. The name box takes `P2Powertrain`, not `MyCar.P2Powertrain`. Create the remaining components and analyses with the module row's **+**. `MyCar` in listings means this module; `HandsOn05` is the fallback answer.

**How each step works.** As in HandsOn04, use the instance names below, build the diagram, then compare with the checkpoint before going on. The parts tables give library paths; names in code use dots instead of ›. Parameters with physical units use **Real** in Studio's **Add parameter** form, with the unit entered separately. **Code view required** labels mark declarations, conditional structure, nested modifiers, equations and initialization that are not diagram wiring. Save edits and wait for compilation before running; a source change alone is not a new simulation. In the Julia REPL, `solution` is the result of the most recent Studio analysis run: capture it immediately as `r = solution` before running another analysis.

**Checkpoint sampling.** Unless a value is a parameter or an endpoint meter reading, evaluate it on the uniform grid `t = 0:0.01:T`, where `T` is 589 s for Low and 1800 s for the full cycle. Use dense solution interpolation, `at(x) = s(t, idxs=x).u`. Sampled extrema are not continuous-time bounds. Use trapezoids for sampled energy; read the fuel and energy integrators at `T`. Count an engine-on sample when `at(m.manager.engine_on) > 0.5`; start/stop times are the left grid points of Boolean transitions.

**Fell behind?** The reference answers under `dyad/HandsOn05/` are self-contained copies of the `P2Powertrain.dyad`, `P2WLTC.dyad`, `P2OperatingLineWLTC.dyad`, `P2HybridWLTC.dyad` and `TorqueToPedal.dyad` compositions, with references between them localized to `HandsOn05`. They still use the existing library parts. Compare them with `Vehicle.P2Powertrain`, `Lecture5.P2WLTC`, `Lecture5.P2OperatingLineWLTC`, `Lecture5.P2HybridWLTC` and `Vehicle.TorqueToPedal`; do not claim that a wrapper around those answers is your own composition.

- [1a · Wire the P2 powertrain](#step-1a)
- [1b · Electric-only WLTC Low](#step-1b)
- [1c · Engine-only WLTC through K0](#step-1c)
- [2 · Hold the engine on its operating line](#step-2)
- [3 · Let the energy manager split the demand](#step-3)
- [4 · Compare at equal battery charge](#step-4)

## 1a · Wire the P2 powertrain {#step-1a}

#### Given

`Vehicle.P2Powertrain` has four signal inputs: `engine_pedal`, `engage`, `tau_ref` and `cvt_pedal`; mechanical ports `spline` and `support`; and outputs `engine_speed`, `engine_torque`, `available_torque`, `mdot_fuel`, `machine_torque`, `position`, `SoC`, `E` and `i`. Engine speed is in rad/s, torques in N·m, fuel flow in kg/s, `E` in V and `i` in A (positive discharge). `position` is K0 actuator position, not vehicle distance.

#### Parts

Create `P2Powertrain` in your module. Add its ports with **+ › Dyad › RealInput / RealOutput / Spline**, then use **Edit Parameters › pencil** to rename each to the interface above. Place:

| Name | Library path | Set |
| --- | --- | --- |
| `engine` | VehicleSystemsComponents › Vehicle › Engine › MappedEngine | existing engine map |
| `k0` | VehicleSystemsComponents › Vehicle › DisconnectClutch | `position_start = position_start` |
| `drive` | VehicleSystemsComponents › Vehicle › Electric › HybridDrive | existing hybrid defaults |
| `variator` | VehicleSystemsComponents › Vehicle › ControlledVariator | existing speed schedule and final drive |
| `hold` | RotationalComponents › Components › Fixed | present only when `engine_stopped` |

Add structural Boolean `engine_stopped = false`, Real `position_start = 0.0`, and angular velocity `engine_speed_start = 800.0 * pi / 30` rad/s (800 rpm idle). `variator` must remain a distinct child: it is the replacement seam for #112, **not** a Dyad language-level `replaceable` feature. `ControlledVariator` already includes the final drive. Do not substitute `CVTDriveline`: that assembly also contains a centrifugal launch clutch and an ideal rolling wheel.

#### Do this

**Code view required:** structural declarations, conditional parts, equations and initial conditions below must be entered in the component source. Use the diagram for placement and the explicit `connect(...)` wiring.

1. In Studio, place `engine`, `k0`, `drive` and `variator` from left to right. Wire the shafts:

   ```dyad
   connect(engine.spline, k0.spline_a)
   connect(k0.spline_b, drive.spline, variator.spline_a)
   connect(variator.spline_b, spline)
   connect(engine.support, k0.support, drive.support, variator.support, support)
   ```

   The machine shares the transmission-input shaft; it is not another gear in series.
2. Wire `engine_pedal` to `engine.pedal`, `engage` to `k0.engage`, `tau_ref` to `drive.tau_ref`, and `cvt_pedal` to `variator.pedal`.
3. Wire the ports `engine.tau_e` → `engine_torque`, `engine.mdot_fuel` → `mdot_fuel` and `drive.SoC` → `SoC`. **Code view required:** the other exports are variables, not drawable connector endpoints:

   ```dyad
   engine_speed = engine.speed.w
   available_torque = engine.torque_map.full_load.y
   machine_torque = drive.machine.tau
   position = k0.position
   E = drive.battery.E
   i = drive.battery.i
   ```

   Never put these variable paths inside `connect(...)`.
4. **Code view required:** put these lines in `relations`:

   ```dyad
   initial engine.air.manifold.p = 101325.0
   initial drive.machine.rotor.phi = 0.0
   if !engine_stopped
     initial engine.crankshaft.w = engine_speed_start
     initial engine.crankshaft.phi = 0.0
   end
   ```

   The listing below combines the last conditional with the stopped-engine connection; use one form, not both.
5. **Code view required:** for the fixed electric fixture only, conditionally place `hold` and connect `engine.spline` to `hold.spline`. Set `MappedEngine`'s `fuel_cut_rpm = -2.0` and `fuel_resume_rpm = -1.0` in this configuration; otherwise retain `1300.0` and `1000.0`. At zero pedal and held zero speed, the electric fixture initializes `cut = 1`, so fuel is cut without events. This is a fixed test configuration, not engine stopping, starting or mode-switching logic.
   The declarations and conditional relation are:

   ```dyad
   structural parameter engine_stopped::Boolean = false
   hold = RotationalComponents.Components.Fixed() if engine_stopped
   engine = VehicleSystemsComponents.Vehicle.Engine.MappedEngine(fuel_cut_rpm = ifelse(engine_stopped, -2.0, 1300.0), fuel_resume_rpm = ifelse(engine_stopped, -1.0, 1000.0))
   ```

   In `relations`:

   ```dyad
   if engine_stopped
     connect(engine.spline, hold.spline)
   end
   ```

6. **Code view required:** create your own `P2WLTC` test fixture using the complete listing below for the planar car, road load, cycle and driver. Keep structural Boolean `electric = false`, mass `m = 1500.0` kg and `dv_wheel = 0.01` m/s. Pass `engine_stopped = electric`, `position_start = 0.0` to `powertrain`. Keep PI gain `k = 50.0` in electric mode; use `110.0` and `Ti = 1.0` s in engine-only mode (electric keeps `Ti = 2.0` s). Set the nested `powertrain.drive.P_aux` to `300.0` W in electric mode and `0.0` in engine-only mode so the conventional baseline draws no battery energy. In engine-only mode also set the nested drive's `T_f`, `K_i`, `k_w`, `C` and `J` to zero; retain all hybrid-drive defaults in electric mode.
7. Wire `powertrain.spline` to `differential.flange_b`, and the differential's `flange_left` and `flange_right` to `car.spin_fl` and `car.spin_fr`. Ground `powertrain.support` with `mount`, a `RotationalComponents.Components.Fixed`. Retain the reference's straight steering, flat road, speed feedback and wheel/brake initial conditions.

::: tip Checkpoint 1a — wiring

Trace engine → K0 → shared machine/variator input → variator → differential → front wheels. All powertrain supports reach `mount`; there is one final drive and no launch clutch. The four fixed-mode commands and nine outputs remain accessible on `powertrain`. This is a structural checkpoint, not evidence that the engine-only car can launch.

:::

#### Code view required — your powertrain and fixture

**Every connection and Initialization for step 1a:** the `P2WLTC` listing below includes the complete shaft, road, driver and meter wiring, both fixed-mode branches, and all body, wheel, brake and converter initial conditions. Build this fixture here, before step 1b; no step-2 fixture is needed.

Create `MyCar.P2Powertrain` and the **separate test component** `MyCar.P2WLTC`; a powertrain with undriven inputs is not an analysis fixture. The speed-commanded option below prepares step 2; leave it false for all of step 1. `available_torque` prepares step 3 and needs no extra input. Diagram placement metadata is omitted.

```dyad
"""
P2 transmission-input hybrid with a pedal- or speed-commanded total CVT ratio.
MappedEngine drives K0 and the HybridDrive shaft. Connect the housing support to ground.
`engine_stopped` holds the engine with fuel cut for fixed electric-only tests.
"""
component P2Powertrain
  "Engine pedal, 0 to 1 (derived; MappedEngine)"
  engine_pedal = RealInput() {^engine_pedal}
  "K0 engagement request (derived; DisconnectClutch)"
  engage = RealInput() {^engage}
  "Machine torque request [N.m] (derived; HybridDrive)"
  tau_ref = RealInput() {^tau_ref}
  "Variator speed-schedule pedal (derived; ControlledVariator)"
  cvt_pedal = RealInput() if !speed_commanded {^cvt_pedal}
  "Target transmission input speed [rpm]"
  N_ref = RealInput() if speed_commanded {^N_ref}
  "Select speed-commanded CVT scheduling"
  structural parameter speed_commanded::Boolean = false
  "Output to planar differential (derived; P2 layout)"
  spline = Spline() {^spline}
  "Stationary housing (assumed; planar bench)"
  support = Spline() {^support}
  "Engine speed [rad/s] (derived; crank sensor)"
  engine_speed = RealOutput() {^engine_speed}
  "Engine brake torque [N.m] (derived; map)"
  engine_torque = RealOutput() {^engine_torque}
  "Available full-load engine torque at the measured speed [N.m]"
  available_torque = RealOutput() {^available_torque}
  "Fuel flow [kg/s] (derived; map)"
  mdot_fuel = RealOutput() {^mdot_fuel}
  "Net machine shaft torque [N.m] (derived; DCMachine)"
  machine_torque = RealOutput() {^machine_torque}
  "K0 actuator position (derived; actuator)"
  position = RealOutput() {^position}
  "Battery state of charge (derived; coulomb count)"
  SoC = RealOutput() {^SoC}
  "Battery open-circuit voltage [V] (derived; HybridDrive)"
  E = RealOutput() {^E}
  "Battery current, positive discharge [A] (derived; Battery)"
  i = RealOutput() {^i}
  "Hold engine stopped with fuel cut for an electric-only fixture (assumed; no start dynamics)"
  structural parameter engine_stopped::Boolean = false
  "Initial K0 position (assumed; fixed-mode bench)"
  parameter position_start::Real = 0.0
  "Initial running-engine speed [rad/s] (assumed; 800 rpm idle for launch)"
  parameter engine_speed_start::AngularVelocity = 800.0 * pi / 30
  engine = VehicleSystemsComponents.Vehicle.Engine.MappedEngine(fuel_cut_rpm = ifelse(engine_stopped, -2.0, 1300.0), fuel_resume_rpm = ifelse(engine_stopped, -1.0, 1000.0)) {^engine}
  k0 = VehicleSystemsComponents.Vehicle.DisconnectClutch(position_start = position_start) {^k0}
  drive = VehicleSystemsComponents.Vehicle.Electric.HybridDrive() {^drive}
  variator = VehicleSystemsComponents.Vehicle.ControlledVariator() if !speed_commanded {^variator}
  speed_variator = VehicleSystemsComponents.Vehicle.SpeedCommandedVariator() if speed_commanded {^speed_variator}
  hold = RotationalComponents.Components.Fixed() if engine_stopped {^hold}
relations
  initial engine.air.manifold.p = 101325.0
  initial drive.machine.rotor.phi = 0.0
  connect(engine_pedal, engine.pedal)
  connect(engage, k0.engage)
  connect(tau_ref, drive.tau_ref)
  if speed_commanded
    connect(N_ref, speed_variator.N_ref)
    connect(k0.spline_b, drive.spline, speed_variator.spline_a)
    connect(speed_variator.spline_b, spline)
    connect(speed_variator.support, support)
  else
    connect(cvt_pedal, variator.pedal)
    connect(k0.spline_b, drive.spline, variator.spline_a)
    connect(variator.spline_b, spline)
    connect(variator.support, support)
  end
  connect(engine.spline, k0.spline_a)
  connect(engine.support, k0.support, drive.support, support)
  engine_speed = engine.speed.w
  connect(engine.tau_e, engine_torque)
  available_torque = engine.torque_map.full_load.y
  connect(engine.mdot_fuel, mdot_fuel)
  connect(drive.SoC, SoC)
  machine_torque = drive.machine.tau
  position = k0.position
  E = drive.battery.E
  i = drive.battery.i
  if engine_stopped
    connect(engine.spline, hold.spline)
  else
    initial engine.crankshaft.w = engine_speed_start
    initial engine.crankshaft.phi = 0.0
  end
end
```

Use this current `HandsOn05.P2WLTC` composition as your fixture listing, with the two local paths changed to `MyCar`. It owns the car, driver, loads, metering and fixed-mode branches; it is not an `extends Lecture5.P2WLTC` shortcut. Save this fixture before creating its analyses.

```dyad
"Planar P2 fixed-mode WLTC fixture (derived; PlanarBEVWLTC, Lecture 5 step 1)."
test component P2WLTC
  "Electric-only fixed configuration; no mode switching (assumed; step 1)"
  structural parameter electric::Boolean = false
  "Vehicle and road-load mass (assumed; shared planar benchmark)"
  parameter m::Mass = 1500.0
  "Wheel radius (derived; planar benchmark)"
  parameter radius::Length = 0.31
  "PI gain, input-shaft N.m per km/h: 50 for the electric fixture, 110 shared by the engine and hybrid comparisons"
  parameter k::Real = ifelse(electric, 50.0, 110.0)
  "PI integral time: 2 s for the electric fixture, 1 s for the shared Lecture 5 driver (assumed)"
  parameter Ti::Time = ifelse(electric, 2.0, 1.0)
  "Positive driver ceiling [N.m], pedal saturation or machine peak"
  parameter tau_max::Torque = ifelse(electric, 205.0, 150.0)
  "Initial wheel surface speed offset (assumed; MultibodyComponents #185)"
  parameter dv_wheel::Velocity = 0.01
  "Center of K0 launch engagement [rpm] (assumed; CentrifugalClutch)"
  parameter engage_rpm::Real = 1300.0
  "Width of K0 launch engagement [rpm] (assumed; CentrifugalClutch)"
  parameter engage_width_rpm::Real(min = eps(Float64)) = 120.0
  "Negative PI limit [N.m], independent of propulsion saturation"
  parameter tau_brake::Torque = 205.0
  "Total wheel brake torque per negative driver N.m, launch ratio reference"
  parameter brake_gain::Real = 12.0
  "Center of machine-side K0 lock-up ramp [rpm]; open at 800 rpm idle, closed by 880 rpm"
  parameter lock_rpm::Real = 840.0
  "Width of machine-side K0 lock-up ramp [rpm]"
  parameter lock_width_rpm::Real(min = eps(Float64)) = 12.0
  trace = VehicleSystemsComponents.Vehicle.DriveCycle() {^trace}
  driver = BlockComponents.Continuous.LimPID(with_D = false, k = k, Ti = Ti, y_max = tau_max, y_min = -tau_brake) {^driver}
  no_ff = BlockComponents.Sources.Constant(k = 0.0) {^no_ff}
  kmh = VehicleSystemsComponents.Vehicle.ToKmPerHour() {^kmh}
  powertrain = VehicleSystemsComponents.MyCar.P2Powertrain(engine_stopped = electric, position_start = 0.0, drive(P_aux = ifelse(electric, 300.0, 0.0), T_f = ifelse(electric, 0.5 * (30.0e3 / 110.0e3), 0.0), K_i = ifelse(electric, 1.0 * (30.0e3 / 110.0e3), 0.0), k_w = ifelse(electric, 300.0 / (10100.0 * pi / 30.0) ^ 3 * (30.0e3 / 110.0e3), 0.0), C = ifelse(electric, 200.0 * (30.0e3 / 110.0e3), 0.0), J = ifelse(electric, 0.05 * (30.0e3 / 110.0e3), 0.0))) {^powertrain}
  differential = MultibodyComponents.PlanarMechanics.DifferentialGear() {^differential}
  mount = RotationalComponents.Components.Fixed() {^mount}
  straight = RotationalComponents.Components.Fixed() {^straight}
  flat = BlockComponents.Sources.Constant(k = 0.0) {^flat}
  car = VehicleSystemsComponents.Vehicle.Planar.PlanarCar(m = m, radius = radius) {^car}
  motion = VehicleSystemsComponents.Vehicle.Planar.BusMotion() {^motion}
  roadload = VehicleSystemsComponents.Vehicle.Planar.PlanarRoadLoad(m = m) {^roadload}
  split = VehicleSystemsComponents.Vehicle.Electric.TorqueSplit(ratio = 1.0) {^split}
  meter = VehicleSystemsComponents.Vehicle.SoCCorrectedFuel() {^meter}
relations
  connect(car.bus, motion.bus)
  connect(trace.y, driver.u_s)
  connect(motion.vx, kmh.u, meter.speed)
  connect(kmh.y, driver.u_m, split.v)
  connect(no_ff.y, driver.u_ff)
  connect(powertrain.spline, differential.flange_b)
  connect(differential.flange_left, car.spin_fl)
  connect(differential.flange_right, car.spin_fr)
  connect(powertrain.support, mount.spline)
  connect(car.steering, straight.spline)
  connect(flat.y, roadload.grade)
  connect(car.chassis, roadload.chassis)
  connect(driver.y, split.tau_ref)
  connect(powertrain.mdot_fuel, meter.mdot_fuel)
  meter.P_stored = powertrain.E * powertrain.i
  if electric
    powertrain.cvt_pedal = min(max(driver.y / 150.0, 0.0), 1.0)
    powertrain.engine_pedal = 0.0
    powertrain.engage = 0.0
    connect(split.tau_motor, powertrain.tau_ref)
    car.tau_fl = split.tau_brake * powertrain.variator.ratio
    car.tau_fr = car.tau_fl
  else
    powertrain.engine_pedal = min(max(driver.y / tau_max, 0.0), 1.0)
    powertrain.cvt_pedal = powertrain.engine_pedal
    powertrain.engage = max(0.5 * (1 + tanh((powertrain.engine_speed * 30 / pi - engage_rpm) / engage_width_rpm)), 0.5 * (1 + tanh((powertrain.variator.w_a * 30 / pi - lock_rpm) / lock_width_rpm)))
    powertrain.tau_ref = 0.0
    car.tau_fl = -min(driver.y, 0.0) * brake_gain / 2.0
    car.tau_fr = car.tau_fl
  end
  car.tau_rl = 0.0
  car.tau_rr = 0.0
  initial car.body.r = [0, 0]
  initial car.body.v = [0, 0]
  initial car.body.phi = 0.0
  initial car.body.w = 0.0
  initial car.fl.inertia.w = dv_wheel / radius
  initial car.fr.inertia.w = dv_wheel / radius
  initial car.rl.inertia.w = dv_wheel / radius
  initial car.rr.inertia.w = dv_wheel / radius
  initial car.fl.inertia.phi = 0.0
  initial car.fr.inertia.phi = 0.0
  initial car.rl.inertia.phi = 0.0
  initial car.rr.inertia.phi = 0.0
  initial car.fl.brake.tau_actual = 0.0
  initial car.fr.brake.tau_actual = 0.0
  initial car.rl.brake.tau_actual = 0.0
  initial car.rr.brake.tau_actual = 0.0
  initial powertrain.drive.converter.i_out = 0.0
end

"Engine-only full WLTC (derived; Lecture 5 step 1)."
analysis P2EngineWLTCTransient
  extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
  model = P2WLTC()
end

"Electric-only fixed fixture (derived; P2WLTC with stopped engine)."
test component P2ElectricWLTC
  extends VehicleSystemsComponents.MyCar.P2WLTC(electric = true)
end

"Electric-only WLTC Low phase (derived; UNECE phase boundary 589 s)."
analysis P2ElectricWLTCTransient
  extends TransientAnalysis(stop = 589.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
  model = P2ElectricWLTC()
end
```

#### Fell behind?

Open `HandsOn05.P2Powertrain` and `HandsOn05.P2WLTC` as code-view comparisons. Keep your fixture's `powertrain = VehicleSystemsComponents.MyCar.P2Powertrain(...)` so your wiring is what the analyses exercise.

## 1b · Electric-only WLTC Low {#step-1b}

#### Given

Your `MyCar.P2ElectricWLTC` extends your `P2WLTC(electric = true)`: K0 open, engine held stopped, zero engine pedal, machine torque from the driver. The 30 kW, 205 N·m hybrid drive is not the Lecture 4 Leaf drive.

#### Do this

1. Use `Vehicle › Electric › TorqueSplit` as `split`, with `ratio = 1.0`: the PI driver's request is already at the transmission input. Connect driver output to `split.tau_ref`, vehicle speed in km/h to `split.v`, and `split.tau_motor` to `powertrain.tau_ref`.
2. **Code view required:** in the fixture's electric branch, set `powertrain.engine_pedal = 0.0` and `powertrain.engage = 0.0`. Retain the instantaneous CVT schedule:

   ```dyad
   powertrain.cvt_pedal = min(max(driver.y / 150.0, 0.0), 1.0)
   car.tau_fl = split.tau_brake * powertrain.variator.ratio
   car.tau_fr = car.tau_fl
   ```

   `split.tau_brake` already includes division by two for the front wheels. Multiply by the instantaneous CVT ratio, but do **not** divide by two again. Keep rear brake commands zero for this fixture.
3. **Code view required:** an analysis cannot override the structural `electric` parameter. The step-1a listing therefore declares `test component P2ElectricWLTC` with `extends VehicleSystemsComponents.MyCar.P2WLTC(electric = true)`, and uses `model = P2ElectricWLTC()` in its analysis. Create that wrapper first, then use your `MyCar.P2ElectricWLTCTransient`: stop `589.0` s (WLTC Low), `alg = ODEAlg.Rodas5P()`, `dtmax = 1.0`, `optimize = OptimizationLevel.None()`. Keep the reference's `dv_wheel = 0.01` m/s and mass `1500.0` kg.
4. Run the analysis from Studio before using the Julia REPL to inspect it. Plot target and actual speed, fuel flow, SoC and machine rpm; compare the whole interval, not only the endpoint.

::: tip Checkpoint 1b — measured reference run

| Quantity | Measured WLTC Low result |
| --- | --- |
| Duration | 589 s |
| Maximum absolute speed error | 1.502830 km/h |
| Distance | 3094.989 m |
| Fuel | 0 |
| SoC | 0.6 → 0.3864 |
| Maximum machine speed | 3545.66 rpm |

These are WLTC Low reference measurements, reproduced during the Studio rehearsal; they are not full-WLTC results. The existing hybrid-drive dyno validates operation to 4000 rpm; its loaded field-weakening corner is 1412 rpm. The Low run therefore uses field weakening while remaining within that tested speed range. Zero fuel is not zero energy consumption: the battery loses charge.

:::

#### Inspect the Studio result

Immediately after the electric run, use the REPL (do not run a second analysis just to plot):

```julia
using DyadInterface: symbolic_container
using Plots
r = solution
m, s = symbolic_container(r), r.sol
T = 589.0
t = 0:0.01:T
at(x) = s(t, idxs=x).u
plot(t, [at(m.trace.y) 3.6 .* at(m.car.bus.vx)], label=["target" "actual"],
     xlabel="Time [s]", ylabel="Speed [km/h]")
plot(t, at(m.powertrain.mdot_fuel), ylabel="Fuel [kg/s]", label="fuel")
plot(t, at(m.powertrain.SoC), ylabel="SoC", label="SoC")
plot(t, at(m.powertrain.drive.machine.w) .* (30/pi), ylabel="Machine [rpm]", label="machine")
```

For step 1c, run your engine analysis in Studio, capture its new `r = solution`, and repeat the setup with `T = 1800.0`. Plot `m.powertrain.engine_speed` (multiply by `30/pi` for rpm), `m.powertrain.position`, `m.powertrain.k0.w_slip` (rad/s), and `m.meter.fuel_raw` / `m.meter.fuel_corr`. The result variable belongs to the last analysis run; do not reuse the electric result for H0.

#### Fell behind?

Compare with `Lecture5.P2ElectricWLTC` and `Lecture5.P2ElectricWLTCTransient`, then inspect the electric branch of `P2WLTC`. A successful Low run does not validate electric operation for all 1800 s.

[![Electric-only WLTC Low plots of target and actual speed, zero fuel, battery SoC and machine speed](/lecture/lecture-05/img/step01-electric-wltc-low.png)](/lecture/lecture-05/img/step01-electric-wltc-low.png)

## 1c · Engine-only WLTC through K0 {#step-1c}

#### Given

H0 is Lecture 5's conventional baseline: Lecture 2's mapped engine and CVT on the same
1500 kg planar car as the hybrid. Compare hybrid results against this H0, not Lecture 2's
5.22 L/100 km from a different 1D bench (quoted only for scale).
Your `MyCar.P2EngineWLTCTransient` runs `P2WLTC(electric = false)` for **1800 s**, with
`Rodas5P`, `dtmax = 1.0` and `OptimizationLevel.None()`.

#### Do this

1. Start the engine at **800 rpm** and K0 at `position_start = 0.0`. The P2 layout has no
   separate launch clutch: in engine-only mode K0 does that job. Closing it from rest would
   pull the engine down to the stopped wheels, where the map supplies no launch torque.
2. **Code view required:** in the fixture's engine branch, add bench parameters `engage_rpm = 1300.0` and `engage_width_rpm = 120.0` (rpm), matching
   `CentrifugalClutch`. Add the machine-side lock-up ramp `lock_rpm = 840`,
   `lock_width_rpm = 12` (rpm): the request is 0.001 at the 800 rpm idle and 0.999 at 880 rpm,
   so K0 opens before a decelerating shaft drags the engine below idle. Add `brake_gain = 12`. Set the PI to `k = 110`, `Ti = 1`, `y_max = 150`, `y_min = -205`. Feed `powertrain.engine_speed` (rad/s) into the smooth engagement signal:

   ```dyad
   powertrain.engage = max(0.5 * (1 + tanh((powertrain.engine_speed * 30 / pi - engage_rpm) / engage_width_rpm)), 0.5 * (1 + tanh((powertrain.variator.w_a * 30 / pi - lock_rpm) / lock_width_rpm)))
   ```

   K0's existing actuator follows this request; it slips during launch and approaches closed
   above the ramp. No state-triggered branch or event is needed. At the final idle stop K0
   opens again, rather than remaining closed against stopped wheels.
3. Keep `tau_ref = 0.0`; engine and CVT pedals follow
   `min(max(driver.y / tau_max, 0.0), 1.0)`, so pedal saturation stays equal to the PI's
   positive limit if you override `tau_max`. Use the engine-only front brake split:

   ```dyad
   car.tau_fl = -min(driver.y, 0.0) * brake_gain / 2.0
   car.tau_fr = car.tau_fl
   ```

   Division by two is explicit because `driver.y`, not `split.tau_brake`, supplies the request.
4. Plot target and actual speed, engine rpm, K0 position and slip, raw and corrected fuel.
   Confirm the full cycle follows within ±2 km/h and covers the cycle distance.

::: tip Checkpoint 1c — measured H0 reference run

| Quantity | Full WLTC result |
| --- | --- |
| Duration | 1800 s |
| Maximum absolute speed error | 1.167635 km/h |
| Distance | 23266.405 m |
| Raw fuel | 5.717536 L/100 km |
| SoCCorrectedFuel `fuel_corr` | 5.717536 L/100 km |
| Energy | 184.8651 MJ/100 km |
| K0 slip energy, integrated over cycle | approximately 0.11246 MJ |
| Peak engine torque on cycle / maximum K0 capacity | 123.372 / 229.885 N·m |

H0 removes the absent machine's bearing friction, iron loss, windage, constant loss and rotor
inertia through bench-level drive modifiers (`T_f = K_i = k_w = C = J = 0`). The same P2
composition remains; electric-only retains the hybrid defaults.

Battery current is zero and SoC stays at 0.6, so raw and corrected fuel are equal. On level
stretches of the trace above 12 km/h, K0 position stays above 0.99. Wherever K0 position exceeds
0.5, the sampled engine-speed minimum is 785.1 rpm on `0:0.01:1800` (not a continuous-time lower bound). The lock-up ramp releases K0 during stops; the engine can dip below its nominal 800 rpm idle.
The map's full-load peak is 150.234 N·m, also below K0's 230 N·m nominal capacity
(229.885 N·m after endpoint rounding). Slip heat is mechanical launch loss, not a separately
measured fuel increment; its fuel cost is already included in H0's consumption.

:::

#### Fell behind?

Compare the engine branch and initial conditions with `Lecture5.P2WLTC` and the self-contained
`HandsOn05` reference. Retain the electric branch's machine sizing and regen mapping. These measurements validate the
numerical reference and the rehearsed fixed-mode composition.


[![Engine-only WLTC speed tracking, engine speed, K0 position and slip, and fuel consumption](/lecture/lecture-05/img/step01-engine-only-wltc.png)](/lecture/lecture-05/img/step01-engine-only-wltc.png)

## 2 · Hold the engine on its operating line {#step-2}

#### Goal

Replace the pedal-based CVT speed schedule with the Lecture 2 map's best-BSFC speed for the
engine power. Keep the same engine, K0 launch, car, road load and front brakes. Measure fuel
rather than assuming that an efficiency target saves fuel everywhere.

#### Given

Use `P2Powertrain(speed_commanded = true)` and `Lecture5.P2OperatingLineWLTC`.
The structural choice exposes only `N_ref` or `cvt_pedal`, with conditional children named
`speed_variator` and `variator`. The default remains pedal-commanded.

The driver's pedal requests `P_req = pedal * 85000` W. A fixed peak-power reference gives
an open-loop CVT schedule independent of realized engine torque or power. The engine still
uses its progressive pedal/manifold chain: requested and realized power need not agree.
Consequently this schedule does not guarantee operation on the best-BSFC line.

#### Parts

Use the shared `P2Powertrain` with its structural speed-command option. Create only the
`P2OperatingLineWLTC` fixture; omit the electric branch and `TorqueSplit`.

| Name | Library path | Set |
| --- | --- | --- |
| `line` | VehicleSystemsComponents › Vehicle › OperatingLine | default best-BSFC CSV |
| `powertrain` | P2Powertrain(speed_commanded = true) | `position_start = 0`; drive `P_aux = T_f = K_i = k_w = C = J = 0`; its internal `speed_variator` (SpeedCommandedVariator) keeps defaults: 12 → 2.8, 0.5 s lag, 50 rpm floor |
| `trace`, `driver`, `no_ff`, `kmh` | step 1 cycle, LimPID, Constant, ToKmPerHour | `k = 110`, `Ti = 1`, `y_max = 150`, `y_min = -205`, `with_D = false`; zero feedforward |
| `car`, `motion`, `roadload` | Vehicle › Planar › PlanarCar, BusMotion, PlanarRoadLoad | mass 1500 kg, radius 0.31 m, flat road |
| `differential` | MultibodyComponents › PlanarMechanics › DifferentialGear | unchanged |
| `mount`, `straight` | RotationalComponents › Components › Fixed | unchanged |
| `flat` | BlockComponents › Sources › Constant | zero grade |
| `meter` | VehicleSystemsComponents › Vehicle › SoCCorrectedFuel | unchanged |

H0 and the line use the same PI gain 110, integral time 1 s, positive limit 150 and
negative limit −205 N·m. Friction braking uses a fixed gain of 12, the launch ratio,
not the instantaneous variator ratio. Propulsion saturation therefore matches pedal saturation.

#### Code view required — add to P2Powertrain {#step-2-powertrain}

If you used the step-1a listing, these declarations and relations already exist: inspect them, do not duplicate them. Otherwise change `cvt_pedal` and `variator` to conditional declarations and add:

```dyad
structural parameter speed_commanded::Boolean = false
cvt_pedal = RealInput() if !speed_commanded
N_ref = RealInput() if speed_commanded
variator = VehicleSystemsComponents.Vehicle.ControlledVariator() if !speed_commanded
speed_variator = VehicleSystemsComponents.Vehicle.SpeedCommandedVariator() if speed_commanded
```

Replace the unconditional variator connections in `relations` with the conditional block below. If your common support connection includes `variator.support`, remove that endpoint and retain `connect(engine.support, k0.support, drive.support, support)` outside the conditional:

```dyad
if speed_commanded
  connect(N_ref, speed_variator.N_ref)
  connect(k0.spline_b, drive.spline, speed_variator.spline_a)
  connect(speed_variator.spline_b, spline)
  connect(speed_variator.support, support)
else
  connect(cvt_pedal, variator.pedal)
  connect(k0.spline_b, drive.spline, variator.spline_a)
  connect(variator.spline_b, spline)
  connect(variator.support, support)
end
```

#### Code view required — fixture parameters

Declare these once, before `relations`, in `P2OperatingLineWLTC`:

```dyad
parameter m::Mass = 1500.0
parameter radius::Length = 0.31
parameter dv_wheel::Velocity = 0.01
parameter tau_max::Torque = 150.0
parameter tau_brake::Torque = 205.0
parameter P_peak::Power = 85000.0
parameter N_locked::Real = 1000.0
parameter engage_rpm::Real = 1300.0
parameter engage_width_rpm::Real(min = eps(Float64)) = 120.0
parameter lock_rpm::Real = 840.0
parameter lock_width_rpm::Real(min = eps(Float64)) = 12.0
parameter brake_gain::Real = 12.0
parameter k::Real = 110.0
parameter Ti::Time = 1.0
```

#### Every connection

`speed_commanded = true` replaces the powertrain's internal `variator` with `speed_variator`
and its `cvt_pedal` input with `N_ref`; the powertrain connects it to the same shafts and
housing. The fixture adds no variator of its own; it drives `powertrain.N_ref`.

In the fixture, wire:

```dyad
connect(car.bus, motion.bus)
connect(trace.y, driver.u_s)
connect(motion.vx, kmh.u, meter.speed)
connect(kmh.y, driver.u_m)
connect(no_ff.y, driver.u_ff)
connect(powertrain.spline, differential.flange_b)
connect(differential.flange_left, car.spin_fl)
connect(differential.flange_right, car.spin_fr)
connect(powertrain.support, mount.spline)
connect(car.steering, straight.spline)
connect(flat.y, roadload.grade)
connect(car.chassis, roadload.chassis)
connect(powertrain.mdot_fuel, meter.mdot_fuel)
```

Declare `variable N_target::Real`, the commanded input speed, and add the signal equations
(Studio's code view):

```dyad
meter.P_stored = powertrain.E * powertrain.i
line.P = powertrain.engine_pedal * P_peak
N_target = max(line.N, N_locked)
powertrain.N_ref = N_target
powertrain.engine_pedal = min(max(driver.y / tau_max, 0.0), 1.0)
powertrain.engage = max(0.5 * (1 + tanh((powertrain.engine_speed * 30 / pi - engage_rpm) / engage_width_rpm)), 0.5 * (1 + tanh((powertrain.speed_variator.w_a * 30 / pi - lock_rpm) / lock_width_rpm)))
powertrain.tau_ref = 0.0
car.tau_fl = -min(driver.y, 0.0) * brake_gain / 2.0
car.tau_fr = car.tau_fl
car.tau_rl = 0.0
car.tau_rr = 0.0
```

Use `engage_rpm = 1300`, `engage_width_rpm = 120`, `lock_rpm = 840`,
`lock_width_rpm = 12` rpm, the same as H0, so the two benches differ only in the CVT schedule.
The machine-side ramp reads `speed_variator.w_a`, the shaft speed `variator.w_a` gives in H0.
The launch ramp retains launch slip; the machine-side ramp closes K0 on shaft speed once
moving and opens it before the shaft falls to idle. At stops
both requests fall. No events or state-dependent branches are used. The 1000 rpm
`N_locked` floor is above 800 rpm idle and replaces the line's rows below 1000 rpm;
those requests no longer target the unconstrained line minimum. `P_peak = 85000` W.

#### Initialization

Retain step 1: body position and velocity `[0, 0]`, heading and yaw rate zero; all four wheel
angles zero and angular speeds `dv_wheel / radius`, with `dv_wheel = 0.01` m/s; all four
`brake.tau_actual` zero; `powertrain.drive.converter.i_out` zero. The powertrain initializes
manifold pressure to 101325 Pa, rotor angle zero, engine crank angle zero and speed 800 rpm.
The variator starts at ratio 12; K0 position starts at zero. Do not initialize the car at
exact rolling rest: the stdlib wheel Jacobian has the known zero-slip singularity.

#### Run and plot

Create your local `MyCar.P2OperatingLineWLTCTransient` from the listing below, stop 1800 s, Rodas5P, `dtmax = 1`,
`optimize = OptimizationLevel.None()`. Run it once from Studio, then open the Julia REPL:

```julia
using DyadInterface: symbolic_container
using Plots
r = solution  # just-completed Studio P2OperatingLineWLTCTransient result
m, s = symbolic_container(r), r.sol
T = 1800.0
t = 0:0.01:T
at(x) = s(t, idxs=x).u
plot(t, [at(m.trace.y) 3.6 .* at(m.car.bus.vx)], label=["target" "actual"],
     xlabel="Time [s]", ylabel="Speed [km/h]")
scatter(at(m.powertrain.engine_speed) .* (30/pi), at(m.powertrain.engine_torque),
        markersize=1, label="WLTC", xlabel="Engine speed [rpm]", ylabel="Torque [N·m]")
using VehicleSystemsComponents
# Resolve the map from the installed course package, not the REPL working directory.
rows = [parse.(Float64, split(l, ',')) for l in
        readlines(joinpath(pkgdir(VehicleSystemsComponents), "assets", "data", "engine", "bsfc_line.csv"))[2:end]]
line = reduce(vcat, permutedims.(rows))
plot!(line[:,2], line[:,3], label="best-BSFC line", linewidth=2)
plot(t, [at(m.powertrain.engine_speed) .* (30/pi) at(m.N_target)],
     label=["engine" "commanded max(line.N, N_locked)"], xlabel="Time [s]", ylabel="Speed [rpm]")
plot(t, at(m.powertrain.speed_variator.ratio), label="total ratio")
plot(t, [at(m.meter.fuel_raw) at(m.meter.fuel_corr)],
     label=["raw" "SoC-corrected"], ylabel="L/100 km")
```

::: tip Checkpoint 2 — measured reference run

| Quantity | Full WLTC |
| --- | --- |
| Maximum speed error | 1.167747 km/h (<2) |
| Distance | 23266.405 m |
| Raw / corrected fuel | 5.437445 / 5.437445 L/100 km |
| H0 pedal-schedule fuel | 5.717536 L/100 km |
| Difference | −0.280092 L/100 km (−4.899%) |
| Energy | 175.8089 MJ/100 km |
| Battery current / SoC | zero / 0.6 throughout |

The lower speed, higher load moves part of the cycle toward better BSFC. The measured net
fuel reduction uses the same driver, brake mapping and K0 lock-up as H0; it is not a universal hybrid
saving and uses no machine assistance or regen.

:::

::: warning Instructor note — operating-point diagnostics, not a student checkpoint

These diagnostics are instructor context, not student acceptance criteria. They use the same 0.01 s grid as the checkpoints. At each sample define `power = rpm .* torque .* (pi/30/1000)` in kW and interpolate CSV rpm at that actual brake power (clamp beyond the CSV endpoints). Let `cmd = at(m.powertrain.speed_variator.i_command)` and `deviation = abs.(rpm .- target)`. Classes are applied in this order: `idle = (power .< 1) .| (at(m.driver.y) .<= 0)`; `launch = .!idle .& (cmd .>= 11.999)`; `overdrive = .!idle .& (cmd .<= 2.801)`; `eligible = .!idle .& .!launch .& .!overdrive`; `on = eligible .& (deviation .<= 150)`. Point shares count samples; fuel shares sum sampled fuel flow with half weight at the first and last samples.

**Line band:** compare actual engine rpm against CSV rpm at actual brake power, within
**±150 rpm**. This fixed rpm band avoids a broad tolerance on the steep line sections.
For positive demand, power ≥1 kW and command inside `(2.801, 11.999)`, only **16.40%**
of eligible points meet it. Maximum in-range deviation outside launch saturation is
**1541.15 rpm**, bounded by 1600 rpm in the test. Including overdrive saturation, the maximum
outside launches is 2307.37 rpm (test bound 2400 rpm). The open-loop pedal calibration is
not an inverse engine map; most points are not on the line.

Uniform 0.01 s samples, trapezoidal fuel weights:

| Classification | All points | All fuel |
| --- | --- | --- |
| In range, within ±150 rpm | 5.527% | 16.748% |
| Idle/braking | 47.143% | 8.669% |
| Launch limit | 3.671% | 6.007% |
| Overdrive limit | 15.478% | 25.350% |
| In range, outside band | 28.182% | 43.226% |
| Total off line | 94.473% | 83.252% |

Idle/braking takes precedence over saturation. On level stretches of the trace above 12 km/h,
K0's sampled minimum position is 0.98846; where it is closed, the maximum regularized slip
is 0.29977 rad/s, which is not an open clutch. Decelerating, the variator's 0.5 s ratio lag
lets the shaft fall below the 1000 rpm floor, and at low vehicle speed its 50 rpm output-speed floor reduces shaft speed enough to open K0 during stops:
37.38 s above 10 km/h, with 4.78 g of fuel burned meanwhile. Wherever K0 position exceeds 0.5, the
sampled engine-speed minimum is 815.95 rpm on `0:0.01:1800`, not a continuous-time lower bound.

**Instructor note:** The shallow-slope cruise mask resumes at **54.01 s**, immediately after deceleration, while the variator's **0.5 s** ratio lag is still settling. At **12.043 km/h**, the driver is still braking (pedal zero), the target is floored at **1000 rpm**, and the shaft is near **867 rpm**. K0 is recovering through its lock-up ramp: position is **0.98846**, with about **0.004 rad/s** slip. The `0:0.01:1800` grid includes **0.06 s** below 0.99 in this mask; the old 0.1 s grid missed that transition and read 0.99380. Expect this brief near-closure dip, not a loss of lock throughout steady cruise; the physical check allows position above **0.98**.

:::

[![Studio diagram of the operating-line WLTC fixture with driver, powertrain, differential, planar car and road load](/lecture/lecture-05/img/step02-operating-line-diagram.png)](/lecture/lecture-05/img/step02-operating-line-diagram.png)

#### Fell behind?

The step-2 additions and complete line fixture follow. **Code view required:** create `MyCar.P2OperatingLineWLTC` as a new test component, retaining step 1 unchanged. The listing already uses your local powertrain path.

**Code view required — step-2 powertrain option.** Inspect the [powertrain declarations and conditional relations above](#step-2-powertrain); the step-1a listing already includes them, so do not paste duplicate declarations. They select the corresponding pedal/speed input, shafts and support. Set `speed_commanded = true` only on the new fixture's powertrain instance, as below. Do not add another variator to the fixture. No start/stop controls are added until step 3.

```dyad
"""
Engine-only operating-line WLTC with pedal-based power demand and shaft-speed K0 lock-up.
The line target is floored above idle. Machine torque, losses and inertia are zero.
"""
test component P2OperatingLineWLTC
  "Vehicle and road-load mass (assumed; shared planar benchmark)"
  parameter m::Mass = 1500.0
  "Wheel radius (derived; planar benchmark)"
  parameter radius::Length = 0.31
  "PI gain [N.m per km/h], shared with H0"
  parameter k::Real = 110.0
  "PI integral time (assumed; shared Lecture 5 driver)"
  parameter Ti::Time = 1.0
  "Positive PI ceiling [N.m], pedal saturation"
  parameter tau_max::Torque = 150.0
  "Initial wheel surface speed offset (assumed; MultibodyComponents #185)"
  parameter dv_wheel::Velocity = 0.01
  "Center of K0 launch engagement [rpm] (assumed; CentrifugalClutch)"
  parameter engage_rpm::Real = 1300.0
  "Width of K0 launch engagement [rpm] (assumed; CentrifugalClutch)"
  parameter engage_width_rpm::Real(min = eps(Float64)) = 120.0
  "Negative PI limit [N.m], independent of propulsion saturation"
  parameter tau_brake::Torque = 205.0
  "Total wheel brake torque per negative driver N.m, launch ratio reference"
  parameter brake_gain::Real = 12.0
  "Center of machine-side K0 lock-up ramp [rpm]; open at 800 rpm idle, closed by 880 rpm"
  parameter lock_rpm::Real = 840.0
  "Width of machine-side K0 lock-up ramp [rpm]"
  parameter lock_width_rpm::Real(min = eps(Float64)) = 12.0
  trace = VehicleSystemsComponents.Vehicle.DriveCycle() {^trace}
  driver = BlockComponents.Continuous.LimPID(with_D = false, k = k, Ti = Ti, y_max = tau_max, y_min = -tau_brake) {^driver}
  no_ff = BlockComponents.Sources.Constant(k = 0.0) {^no_ff}
  kmh = VehicleSystemsComponents.Vehicle.ToKmPerHour() {^kmh}
  powertrain = VehicleSystemsComponents.MyCar.P2Powertrain(speed_commanded = true, position_start = 0.0, drive(P_aux = 0.0, T_f = 0.0, K_i = 0.0, k_w = 0.0, C = 0.0, J = 0.0)) {^powertrain}
  differential = MultibodyComponents.PlanarMechanics.DifferentialGear() {^differential}
  mount = RotationalComponents.Components.Fixed() {^mount}
  straight = RotationalComponents.Components.Fixed() {^straight}
  flat = BlockComponents.Sources.Constant(k = 0.0) {^flat}
  car = VehicleSystemsComponents.Vehicle.Planar.PlanarCar(m = m, radius = radius) {^car}
  motion = VehicleSystemsComponents.Vehicle.Planar.BusMotion() {^motion}
  roadload = VehicleSystemsComponents.Vehicle.Planar.PlanarRoadLoad(m = m) {^roadload}
  meter = VehicleSystemsComponents.Vehicle.SoCCorrectedFuel() {^meter}
  "Full-pedal requested power [W], mapped engine peak"
  parameter P_peak::Power = 85000.0
  "Minimum locked engine speed [rpm]; replaces lower line rows"
  parameter N_locked::Real = 1000.0
  line = VehicleSystemsComponents.Vehicle.OperatingLine() {^line}
  "Commanded transmission input speed [rpm], line speed floored at N_locked"
  variable N_target::Real
relations
  connect(car.bus, motion.bus)
  connect(trace.y, driver.u_s)
  connect(motion.vx, kmh.u, meter.speed)
  connect(kmh.y, driver.u_m)
  connect(no_ff.y, driver.u_ff)
  connect(powertrain.spline, differential.flange_b)
  connect(differential.flange_left, car.spin_fl)
  connect(differential.flange_right, car.spin_fr)
  connect(powertrain.support, mount.spline)
  connect(car.steering, straight.spline)
  connect(flat.y, roadload.grade)
  connect(car.chassis, roadload.chassis)
  connect(powertrain.mdot_fuel, meter.mdot_fuel)
  meter.P_stored = powertrain.E * powertrain.i
  line.P = powertrain.engine_pedal * P_peak
  N_target = max(line.N, N_locked)
  powertrain.N_ref = N_target
  powertrain.engine_pedal = min(max(driver.y / tau_max, 0.0), 1.0)
  powertrain.engage = max(0.5 * (1 + tanh((powertrain.engine_speed * 30 / pi - engage_rpm) / engage_width_rpm)), 0.5 * (1 + tanh((powertrain.speed_variator.w_a * 30 / pi - lock_rpm) / lock_width_rpm)))
  powertrain.tau_ref = 0.0
  car.tau_fl = -min(driver.y, 0.0) * brake_gain / 2.0
  car.tau_fr = car.tau_fl
  car.tau_rl = 0.0
  car.tau_rr = 0.0
  initial car.body.r = [0, 0]
  initial car.body.v = [0, 0]
  initial car.body.phi = 0.0
  initial car.body.w = 0.0
  initial car.fl.inertia.w = dv_wheel / radius
  initial car.fr.inertia.w = dv_wheel / radius
  initial car.rl.inertia.w = dv_wheel / radius
  initial car.rr.inertia.w = dv_wheel / radius
  initial car.fl.inertia.phi = 0.0
  initial car.fr.inertia.phi = 0.0
  initial car.rl.inertia.phi = 0.0
  initial car.rr.inertia.phi = 0.0
  initial car.fl.brake.tau_actual = 0.0
  initial car.fr.brake.tau_actual = 0.0
  initial car.rl.brake.tau_actual = 0.0
  initial car.rr.brake.tau_actual = 0.0
  initial powertrain.drive.converter.i_out = 0.0
end

"Full WLTC operating-line analysis (derived; Lecture 5 step 2)."
analysis P2OperatingLineWLTCTransient
  extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
  model = P2OperatingLineWLTC()
end
```

[![Engine operating points on the best-BSFC line and full-load map for the operating-line WLTC](/lecture/lecture-05/img/step02-operating-points.png)](/lecture/lecture-05/img/step02-operating-points.png)

## 3 · Let the energy manager split the demand {#step-3}

Start from `P2OperatingLineWLTC`, naming the new bench `P2HybridWLTC`. Restore the full
`HybridDrive` defaults: its losses, inertia, 30 kW machine and 1.4 kWh battery are included.
The reference solution is in `HandsOn05.P2HybridWLTC`.

Add `Vehicle.EnergyManager` as `manager` and `Vehicle.TorqueToPedal` as `map`.
Set `manager.mapped_limits = true`. The driver's signed demand is at the transmission
input, not the wheels. Keep the chassis, differential, supports, road load, meter and initial
conditions from step 2. Replace the step-2 signal wiring with the following.

### Code view required — add start/stop to your powertrain

In `MyCar.P2Powertrain`, add the following declarations before `relations`. Do not remove the step-2 speed-commanded option or the public `available_torque` output:

```dyad
structural parameter start_stop::Boolean = false
engine_on = RealInput() if start_stop
engine_torque_ref = RealInput() if start_stop
parameter firing_rpm::Real = 400.0
parameter firing_width::Real(min = eps(Float64)) = 300.0
variable firing_fraction::Real if start_stop
variable start_compensation::Torque if start_stop
variable machine_limit::Torque if start_stop
```

Add `fuel_controlled = start_stop` to the existing `engine = VehicleSystemsComponents.Vehicle.Engine.MappedEngine(...)` modifiers, retaining its fuel-cut thresholds. **Replace** `connect(tau_ref, drive.tau_ref)` with:

```dyad
if start_stop
  machine_limit = min(drive.T_max, drive.P_rated / max(abs(drive.machine.w), 1.0))
  firing_fraction = min(max((engine.N - firing_rpm) / firing_width, 0.0), 1.0)
  engine.fuel_enable = engine_on * firing_fraction^2 * (3.0 - 2.0 * firing_fraction)
  start_compensation = engine_torque_ref - k0.tau
  drive.tau_ref = min(max(tau_ref + start_compensation, -machine_limit), machine_limit)
else
  connect(tau_ref, drive.tau_ref)
end
```

### Code view required — change the fixture declarations

Copy only the step-2 test component (not its analysis) to `MyCar.P2HybridWLTC`, renaming the component header accordingly. Replace its powertrain declaration (remove the zero-loss nested drive modifiers), add the manager, inverse map and second operating line, and change the two existing driver-limit parameter defaults:

```dyad
parameter tau_max::Torque = 150.233567 + 205.0
parameter tau_brake::Torque = tau_max
powertrain = VehicleSystemsComponents.MyCar.P2Powertrain(speed_commanded = true, start_stop = true, position_start = 0.0, engine_speed_start = 0.0)
manager = VehicleSystemsComponents.Vehicle.EnergyManager(mapped_limits = true, SoC_on = 0.52, SoC_off = 0.55, P_line_max = 30.0e3)
map = VehicleSystemsComponents.Vehicle.TorqueToPedal()
demand_line = VehicleSystemsComponents.Vehicle.OperatingLine()
```

Keep the existing `line` and `N_target`; do not declare them twice. Remove the step-2 equations for `line.P`, `N_target`, engine pedal, engagement, machine request and front brakes, plus the old `connect(kmh.y, driver.u_m)`. Also remove `powertrain.N_ref = N_target` and the rear-brake equations; they are repeated in the replacement block. Replace them with the table and equations below; the table represents `connect(...)` statements. All unchanged mechanical, meter and initialization relations remain.

### Every connection changed or added in step 3

| From | To |
| --- | --- |
| `driver.y` | `manager.tau_dem` |
| `powertrain.SoC` | `manager.SoC` |
| `powertrain.engine_speed` | `manager.engine_speed`, `map.omega` |
| `powertrain.available_torque` | `manager.available_torque` |
| `kmh.y` | `driver.u_m`, `manager.v` |
| `manager.P_engine` | `line.P` |
| `manager.tau_engine` | `map.tau`, `powertrain.engine_torque_ref` |
| `map.pedal` | `powertrain.engine_pedal` |
| `manager.engine_on` | `powertrain.engine_on` |
| `manager.tau_machine` | `powertrain.tau_ref` |

In the Relations editor, set the remaining signal equations (replace the old line target,
engagement and brake equations rather than keeping both):

```dyad
manager.w_shaft = powertrain.speed_variator.w_a
demand_line.P = manager.P_drive
N_target = max(manager.engine_on * line.N + (1.0 - manager.engine_on) * demand_line.N, N_locked)
powertrain.N_ref = N_target
powertrain.engage = manager.engage * max(0.5 * (1 + tanh((powertrain.engine_speed * 30 / pi - engage_rpm) / engage_width_rpm)), 0.5 * (1 + tanh((powertrain.speed_variator.w_a * 30 / pi - lock_rpm) / lock_width_rpm)))
car.tau_fl = manager.tau_friction * powertrain.speed_variator.ratio / 2.0
car.tau_fr = car.tau_fl
car.tau_rl = 0.0
car.tau_rr = 0.0
```

The added `demand_line` uses the existing `variable N_target::Real`. Set `powertrain.start_stop = true`,
`powertrain.engine_speed_start = 0.0` and `powertrain.position_start = 0.0`.
The available-torque connection is required when mapped limits are enabled; it uses the
powertrain's public output, not an internal engine block.

- Feed `manager.P_engine` to `line.P`. Feed `manager.tau_engine` to `map.tau`, measured
  engine speed to `map.omega`, and `map.pedal` to the engine pedal.
- Enable `powertrain.start_stop`; connect `manager.engine_on` to `powertrain.engine_on`
  and `manager.tau_engine` to `powertrain.engine_torque_ref`.
- Feed `manager.tau_machine` to `powertrain.tau_ref`. The powertrain adds the difference
  between assumed engine torque and measured K0 transmission, including cranking drag,
  then clamps the sum to the machine torque/power envelope. Over the first 3 s
  of starts, the unclamped excess peaks at 123.34 N·m for 2.57 s total; the
  maximum speed error there is 0.996 km/h. The final request peaks at 205 N·m.
  No start inhibition
  is needed for the measured tracking band.
- Multiply `manager.engage` by the maximum of step 2's engine launch and shaft lock-up
  ramps. Fuel permission rises smoothly from 400 to 700 rpm; with fuel off, regularized
  drag lets the engine settle at rest. No fixed hold or event stops the engine.
- Multiply `manager.tau_friction` by the current CVT ratio, then split it equally between
  the front brakes. Regen has already been subtracted; do not subtract it again.
- In electric mode, a second `OperatingLine` follows positive demand power. Blend its
  speed toward the engine-request line using `engine_on`, then floor the target at 1000 rpm.

Set the signed driver limits to `±(150.233567 + 205.0)` N·m: mapped engine peak plus machine limit. Use the shared Lecture 5 driver, `k=110`, `Ti=1`; its maximum error is 1.32 km/h. Use `mapped_limits=true`: during a CVT transient,
the manager must not subtract engine torque above the mapped full-load envelope from the
machine demand. Set `SoC_on=0.52`, `SoC_off=0.55` to leave room for late-cycle regen, and
`P_line_max=30000` W. With these settings the run uses 4.08634 corrected L/100 km,
finishes at SoC 0.61221 and uses all four modes. These measurements apply to the
specified cap and SoC window, not the manager's defaults.

Electric mode carries low demand with K0 open. On-line mode starts the engine and follows
the efficient-speed target. Charging raises engine load and generates the surplus. Boost
adds machine torque above the 30 kW line cap. During deceleration the existing regen blend
uses the machine first and sends the remainder to friction brakes.

### Code view required — energy accounting and analysis

Add these declarations before `relations`:

```dyad
variable E_charge::Energy
variable E_regen::Energy
variable E_friction::Energy
```

Add these relations so the energy boundaries in the checkpoint are observable:

```dyad
der(E_charge) = max(-meter.P_stored, 0.0)
der(E_regen) = manager.tau_regen * max(manager.w_shaft, 0.0)
der(E_friction) = car.fl.brake.tau_friction * car.fl.brake.w + car.fr.brake.tau_friction * car.fr.brake.w + car.rl.brake.tau_friction * car.rl.brake.w + car.rr.brake.tau_friction * car.rr.brake.w
initial E_charge = 0.0
initial E_regen = 0.0
initial E_friction = 0.0
```

Create and run this analysis in your library:

```dyad
analysis P2HybridWLTCTransient
  extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
  model = P2HybridWLTC()
end
```

In the REPL capture `r = solution`, then use `m, s = symbolic_container(r), r.sol` and `t = 0:0.01:1800.0`. Plot speed tracking, engine rpm, K0 position, SoC and the manager's four mode fractions (`manager.ev`, `manager.on_line`, `manager.charging`, `manager.boosting`) over the complete cycle; inspect the first start as well as settled operation. Read `E_charge`, `E_regen` and `E_friction` at 1800 s, not from the last plotted time window.

::: tip Checkpoint 3 — measured full WLTC
The run has **44 starts**, minimum on-time **1.87 s**, mean on-time **14.72 s**, and maximum
speed error **1.32 km/h**. Settled off periods have zero fuel and engine speed within 3 rpm
of rest. K0 dissipates **111.21 kJ** over the run (2.53 kJ per start, including other slip).
The four mode fractions sum to one; all four occur.

Fractions blend during starts and stops; the small electric-mode fuel allocation comes from
those transitions, not settled electric operation. Requested shaft regen is **3.119 MJ**;
actual friction-brake dissipation is **0.0536 MJ**. The battery accepts **3.920 MJ** in total,
including engine-driven charging. These quantities have different measurement boundaries.
:::

[![Hybrid WLTC speed tracking, engine starts, K0 position, battery SoC and energy-manager modes](/lecture/lecture-05/img/step03-hybrid-wltc.png)](/lecture/lecture-05/img/step03-hybrid-wltc.png)

## 4 · Compare at equal battery charge {#step-4}

H0, the line car and the hybrid share `k=110`, `Ti=1 s`. H0 uses
5.717536 L/100 km and the line car 5.437445 L/100 km. Their maximum speed errors are
1.168 and 1.168 km/h. The `±(150.233567 + 205.0)` N·m limits apply only to the hybrid; H0
and the line car retain their pedal-sized propulsion limits.

Keep `meter.P_stored = powertrain.E * powertrain.i`: the correction uses stored energy,
not terminal energy. Read the meter only after the complete 1800 s cycle. The hybrid starts
at **0.60000**, finishes at **0.61221**, and stays between **0.51295** and **0.61252**.

| Car | Raw L/100 km | SoC-corrected L/100 km | MJ/100 km |
|---|---:|---:|---:|
| Conventional H0 | 5.718 | 5.718 | 184.87 |
| Step-2 line car | 5.437 | 5.437 | 175.81 |
| Charge-sustaining P2 hybrid | 4.114 | 4.086 | 132.12 |
| Lecture-4 BEV | — | — | 47.25 |

The BEV value is battery DC electrical energy; the other rows are corrected gasoline energy.
These are vehicle energy inputs, not a well-to-wheel comparison.

::: tip Checkpoint 4 — charge-sustaining comparison
The hybrid ends **1.22 percentage points** above its starting SoC, within ±2 percentage
points. Its corrected fuel is **28.53%** below H0.
:::

::: warning Instructor note — power-error and fuel-band diagnostics
These diagnostics are instructor context, not acceptance criteria. On the 0.01 s grid, let on-age be the duration since `engine_on > 0.5` became true (zero while off). For `(on_age .> 3) .& (at(m.manager.on_line) .> 0.9)`, compute `abs.(at(m.powertrain.engine_torque) .* at(m.powertrain.engine_speed) .- at(m.manager.P_engine))`. Its sample mean and maximum define the power errors below. The fuel-band share is `sum(fuel[abs.(at(m.powertrain.engine.N) .- at(m.line.N)) .<= 150]) / sum(fuel)`, with `fuel = at(m.powertrain.mdot_fuel)`. Outside the first 3 s of each start,
on-line-mode engine power has mean absolute error **171 W**, maximum **3298 W**. Across
the whole run, **58.92%** of fuel is burned within ±150 rpm of the line, versus step 2's 16.75%.
The inverse map needs no PI trim; steady analytic torque round trips are within 1e-7 N·m.
:::

## Limits of this reference

The corrected `P2Powertrain` diagram still needs a post-merge Studio check. The torque inverse assumes
unchanged default engine and air-path calibration. Start compensation remains subject to
the machine's current and power limits; it cannot guarantee full driver demand at every start.
The [homework](./homework) takes the same car to a series hybrid.

The unchanged variator schedules **1800–6000 rpm**, above the machine's 1412 rpm loaded corner;
field weakening supplies the constant-power region. Low reached 3546 rpm. The existing dyno
tests through 4000 rpm, so the scheduled 6000 rpm endpoint is not validated here.
The electric-only fixture validates Low only. The constant-voltage battery has no depletion
cutoff, so it is not a usable full-cycle battery model.
