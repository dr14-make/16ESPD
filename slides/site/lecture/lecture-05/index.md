---
title: Lecture 5 — compose a P2 hybrid powertrain
---

[← Vehicle Systems & Components](../../index.html)

# Lecture 5: compose a P2 hybrid powertrain

**Draft — Studio rehearsal unverified.** This guide describes task #111's reference composition and reported numerical checks, not a rehearsed Studio walkthrough. The electric-only Low checkpoint has measured results; the engine-only checkpoint is **blocked**. Do not treat the existence of an analysis as a passing run.

**What you build.** A transmission-input P2 hybrid from existing library parts: mapped engine → disconnect clutch K0 → machine shaft → controlled variator → differential → front wheels. No new constitutive model, launch device, operating-line controller or energy manager is introduced.

**How each step works.** As in HandsOn04, use the instance names below, build the diagram, then compare with the checkpoint before going on. The parts tables give library paths; names in code use dots instead of ›. Parameters with physical units use **Real** in Studio's **Add parameter** form, with the unit entered separately.

**Fell behind?** The reference answers under `dyad/HandsOn05/` are self-contained copies of the `P2Powertrain.dyad` and `P2WLTC.dyad` compositions, with references between them localized to `HandsOn05`. They still use the existing library parts. Compare them with `Vehicle.P2Powertrain` and `Lecture5.P2WLTC`; do not claim that a wrapper around those answers is your own composition.

- [1a · Wire the P2 powertrain](#step-1a)
- [1b · Electric-only WLTC Low](#step-1b)
- [1c · Engine-only WLTC — blocked](#step-1c)

## 1a · Wire the P2 powertrain {#step-1a}

#### Given

`Vehicle.P2Powertrain` has four signal inputs: `engine_pedal`, `engage`, `tau_ref` and `cvt_pedal`; mechanical ports `spline` and `support`; and outputs `engine_speed`, `engine_torque`, `mdot_fuel`, `machine_torque`, `position`, `SoC`, `E` and `i`. Engine speed is in rad/s, torques in N·m, fuel flow in kg/s, `E` in V and `i` in A (positive discharge). `position` is K0 actuator position, not vehicle distance.

#### Parts

Create your own `P2Powertrain` component and expose the same interface. Place:

| Name | Library path | Set |
| --- | --- | --- |
| `engine` | VehicleSystemsComponents › Vehicle › Engine › MappedEngine | existing engine map |
| `k0` | VehicleSystemsComponents › Vehicle › DisconnectClutch | `position_start = position_start` |
| `drive` | VehicleSystemsComponents › Vehicle › Electric › HybridDrive | existing hybrid defaults |
| `variator` | VehicleSystemsComponents › Vehicle › ControlledVariator | existing speed schedule and final drive |
| `hold` | RotationalComponents › Components › Fixed | present only when `engine_stopped` |

Add structural Boolean `engine_stopped = false` and Real `position_start = 0.0`. `variator` must remain a distinct child: it is the replacement seam for #112, **not** a Dyad language-level `replaceable` feature. `ControlledVariator` already includes the final drive. Do not substitute `CVTDriveline`: that assembly also contains a centrifugal launch clutch and an ideal rolling wheel.

#### Do this

1. In Studio, place `engine`, `k0`, `drive` and `variator` from left to right. Wire the shafts:

   ```dyad
   connect(engine.spline, k0.spline_a)
   connect(k0.spline_b, drive.spline, variator.spline_a)
   connect(variator.spline_b, spline)
   connect(engine.support, k0.support, drive.support, variator.support, support)
   ```

   The machine shares the transmission-input shaft; it is not another gear in series.
2. Wire `engine_pedal` to `engine.pedal`, `engage` to `k0.engage`, `tau_ref` to `drive.tau_ref`, and `cvt_pedal` to `variator.pedal`.
3. Export `engine.speed.w`, `engine.tau_e` and `engine.mdot_fuel`; `drive.machine.tau`; `k0.position`; `drive.SoC`; and `drive.battery.E` and `drive.battery.i` to the corresponding outputs above.
4. Reproduce the reference initialization: engine manifold pressure `101325.0` Pa and machine rotor angle `0.0`. With `engine_stopped = false`, initialize engine crankshaft speed and angle to `0.0`.
5. For the fixed electric fixture only, conditionally place `hold` and connect `engine.spline` to `hold.spline`. Set `MappedEngine`'s `fuel_cut_rpm = -2.0` and `fuel_resume_rpm = -1.0` in this configuration; otherwise retain `1300.0` and `1000.0`. At zero pedal and held zero speed, the electric fixture initializes `cut = 1`, so fuel is cut without events. This is a fixed test configuration, not engine stopping, starting or mode-switching logic.
6. Create your own `P2WLTC` fixture using the reference `Lecture5.P2WLTC` for the planar car, road load, cycle and driver. Keep structural Boolean `electric = false`, mass `m = 1500.0` kg and `dv_wheel = 0.01` m/s. Pass `engine_stopped = electric` and `position_start = ifelse(electric, 0.0, 1.0)` to `powertrain`.
7. Wire `powertrain.spline` to `differential.flange_b`, and the differential's `flange_left` and `flange_right` to `car.spin_fl` and `car.spin_fr`. Ground `powertrain.support` with `mount`, a `RotationalComponents.Components.Fixed`. Retain the reference's straight steering, flat road, speed feedback and wheel/brake initial conditions.

::: tip Checkpoint 1a — wiring

Trace engine → K0 → shared machine/variator input → variator → differential → front wheels. All powertrain supports reach `mount`; there is one final drive and no launch clutch. The four commands and eight outputs remain accessible on `powertrain`. This is a structural checkpoint, not evidence that the engine-only car can launch.

:::

#### Fell behind?

Compare the connections and initial conditions with `Vehicle.P2Powertrain` and `Lecture5.P2WLTC`. The `HandsOn05` answers copy these compositions, rather than hiding the wiring behind an inherited reference powertrain.

## 1b · Electric-only WLTC Low {#step-1b}

#### Given

`Lecture5.P2ElectricWLTC` wraps `P2WLTC(electric = true)`: K0 open, engine held stopped, zero engine pedal, machine torque from the driver. The 30 kW, 205 N·m hybrid drive is not the Lecture 4 Leaf drive.

#### Do this

1. Use `Vehicle › Electric › TorqueSplit` as `split`, with `ratio = 1.0`: the PI driver's request is already at the transmission input. Connect driver output to `split.tau_ref`, vehicle speed in km/h to `split.v`, and `split.tau_motor` to `powertrain.tau_ref`.
2. Set `powertrain.engine_pedal = 0.0` and `powertrain.engage = 0.0`. Retain the instantaneous CVT schedule:

   ```dyad
   powertrain.cvt_pedal = min(max(driver.y / 150.0, 0.0), 1.0)
   car.tau_fl = split.tau_brake * powertrain.variator.ratio
   car.tau_fr = car.tau_fl
   ```

   `split.tau_brake` already includes division by two for the front wheels. Multiply by the instantaneous CVT ratio, but do **not** divide by two again. Keep rear brake commands zero for this fixture.
3. Use `P2ElectricWLTCTransient`: stop `589.0` s (WLTC Low), `alg = ODEAlg.Rodas5P()`, `dtmax = 1.0`, `optimize = OptimizationLevel.None()`. Keep the reference's `dv_wheel = 0.01` m/s and mass `1500.0` kg.
4. Run the analysis from Studio before using the Julia REPL to inspect it. Plot target and actual speed, fuel flow, SoC and machine rpm; compare the whole interval, not only the endpoint.

::: tip Checkpoint 1b — measured reference run

| Quantity | Measured WLTC Low result |
| --- | --- |
| Duration | 589 s |
| Maximum absolute speed error | 1.502735 km/h |
| Distance | 3094.989 m |
| Fuel | 0 |
| SoC | 0.6 → 0.4008309 |
| Maximum machine speed | 3545.66 rpm |

These are reported reference measurements, not newly measured Studio results or full-WLTC results. The existing hybrid-drive dyno validates operation to 4000 rpm; its field-weakening corner is 1397.46 rpm. The Low run therefore uses field weakening while remaining within that tested speed range. Zero fuel is not zero energy consumption: the battery loses charge.

:::

#### Fell behind?

Compare with `Lecture5.P2ElectricWLTC` and `Lecture5.P2ElectricWLTCTransient`, then inspect the electric branch of `P2WLTC`. A successful Low run does not validate electric operation for all 1800 s.

## 1c · Engine-only WLTC — BLOCKED {#step-1c}

#### Given

`Lecture5.P2EngineWLTCTransient` selects `P2WLTC()` with structural `electric = false` and requests the full **1800 s** cycle. Its solver settings are also `Rodas5P`, `dtmax = 1.0`, and `OptimizationLevel.None()`. K0 is commanded closed and starts at position 1; machine torque is zero.

#### Do this

1. Inspect the engine branch: engine and CVT pedals follow `min(max(driver.y / 150.0, 0.0), 1.0)`, `engage = 1.0`, and `tau_ref = 0.0`.
2. Notice that the engine-only braking equation is different from the split output:

   ```dyad
   car.tau_fl = -min(driver.y, 0.0) * powertrain.variator.ratio / 2.0
   car.tau_fr = car.tau_fl
   ```

   Here division by two is explicit because `driver.y`, not `split.tau_brake`, supplies the brake request.
3. Record the launch limitation below. Do not tune a fictitious passing result, add a launch device, or report fuel per distance from a stalled run.

::: warning Checkpoint 1c — blocked, not passed

The existing full-load engine map gives zero torque at rest. With K0 closed, the 230 N·m clutch load stalls the engine; even a trial initial engine speed of 800 rpm did not solve the launch problem. The reference composition therefore **does not pass the engine-only WLTC checkpoint**. Defining a full-cycle analysis is not a completed full-cycle simulation.

There is no valid raw consumption comparison against H0's **5.22 L/100 km**. Do not invent an engine-only fuel result or compare the electric Low run's zero fuel with that full-cycle baseline.

:::

#### Fell behind?

The reference engine fixture has the same limitation. Preserve this blocked checkpoint rather than presenting it as a solution. Resolving launch needs a separate modeling decision; this task adds no constitutive model or launch device.

## Where this stops

Task #111 establishes the composition and fixed-mode checks. Task #112 will address the operating line through the distinct `variator` seam; task #113 will address the energy manager. Neither controller is part of this guide. Studio build steps still need rehearsal before this draft can be used as a verified classroom walkthrough.

The unchanged variator schedules **1800–6000 rpm**, above the machine's 1397 rpm corner;
field weakening supplies the constant-power region. Low reached 3546 rpm. The existing dyno
tests through 4000 rpm, so the scheduled 6000 rpm endpoint is not validated here.
An exploratory full electric run first exceeded the ±2 km/h band at **795.22 s**
(58.57 km/h reference), reaching a 7.62 km/h maximum error. Its final SoC was negative:
the constant-voltage battery has no depletion cutoff, so this is a saturation diagnostic,
not a usable full-cycle battery result.
