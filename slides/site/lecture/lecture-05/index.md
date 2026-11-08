---
title: Lecture 5 — compose a P2 hybrid powertrain
---

[← Vehicle Systems & Components](../../index.html)

# Lecture 5: compose a P2 hybrid powertrain

Written for Dyad Studio 3.5.1.

**What you do.** You take the library's P2 hybrid powertrain (engine → disconnect clutch K0 →
electric machine → CVT → front wheels), put it in a car and drive the full WLTC three times: as a
conventional car (H0), with the engine held on its best-efficiency line, and as a full hybrid
under an energy manager. Then you compare the fuel at equal battery charge.

| Step | You place and wire | Time |
| --- | --- | --- |
| [0 · Setup](#step-0) | open the workspace, compile, start the Julia REPL | 10 min |
| [1 · The P2 layout](#step-1) | trace `Vehicle.P2Powertrain`; 7 wires into the step-1 starter; run H0 | 20 min |
| [2 · Operating line](#step-2) | place `OperatingLine`, 2 wires, one flag and 3 equations; run | 20 min |
| [3 · Energy manager](#step-3) | place `TorqueToPedal`, 7 wires, one flag; run | 30 min |
| [4 · Compare](#step-4) | read the fuel of the three cars | 10 min |

An optional [Go further](#go-further) section at the end builds the powertrain from its parts and
holds the instructor diagnostics.

**Starters.** Each step opens a starter model in `HandsOn05`: `Step1EngineWLTC`,
`Step2OperatingLineWLTC` and `Step3HybridWLTC`. A starter already holds the car, drive cycle,
driver, road load, fuel meter, initial conditions and everything that can only be written as
code. You add only what the step lists: a library block or two and a few wires. Each starter
comes with its analysis (`Step1EngineWLTCTransient` and so on), so you do not create one. Your
finished starter gives the same numbers as the step's reference, so compare them with the
checkpoint. The starters do not depend on each other: if you fall behind, start the next
step from its own starter.

**Working in Studio.**

- Open a model: in COMPONENTS, click it once, then press Enter.
- Place a block: **+** on the canvas toolbar, type part of its name, check the library path in the
  result, then drag the row onto the canvas. Rename it with **Edit Parameters** › pencil.
- Wire: hover a port to read its name, then drag from port to port. Click empty canvas between
  two wires; the drag right after a wire is sometimes ignored. The powertrain block's ports sit
  close together: zoom in (toolbar) before wiring them.
- After you edit in code view, close the diagram and reopen it before you touch the canvas again;
  otherwise later canvas edits draw but are not saved.
- Save (Ctrl+S) and wait for compilation to finish before you run.
- Each run solves the full 1800 s WLTC and takes a few minutes. Close the "Julia Plots" tab that
  opens after a run: it costs memory.

**Reading results in the REPL.** `solution` always holds the most recent run. Right after each
run, keep it under its own name (`r1 = solution` in step 1, `r2` in step 2, `r3` in step 3), then
set up:

```julia
using DyadInterface: symbolic_container
using Plots
r = r1                      # or r2, r3
m, s = symbolic_container(r), r.sol
t = 0:0.01:1800.0
at(x) = s(t, idxs=x).u
```

**Checkpoint sampling.** Unless a value is a parameter or a meter reading at the end of the cycle,
it is evaluated on the grid `t = 0:0.01:1800` with `at(x)` above. Sampled extremes are not exact
continuous-time bounds. Read the fuel meter at `T = 1800 s`. An engine-on sample is one with
`at(m.manager.engine_on) > 0.5`.

## 0 · Setup — 10 min {#step-0}

Start this before the talk ends: the first compile and the first REPL start take several minutes.

1. Open the course repository folder in Dyad Studio. At the trust prompt, choose "Yes, I trust
   the authors".
2. Open the Dyad sidebar (its icon in the left activity bar). COMPONENTS lists
   `VehicleSystemsComponents`.
3. Press F1 › **Dyad: Compile** and wait until it finishes.
4. Press F1 › **Dyad: Open Julia REPL**. Leave it loading while you start step 1.

::: tip Checkpoint 0

COMPONENTS shows `HandsOn05` with `Step1EngineWLTC`, `Step2OperatingLineWLTC` and
`Step3HybridWLTC`, and the REPL panel shows a `julia>` prompt.

:::

## 1 · The P2 layout — 20 min {#step-1}

#### Look at the powertrain (5 min)

Open `Vehicle › P2Powertrain`. Trace the shaft from left to right:

| Part | What it is |
| --- | --- |
| `engine` | the Lecture 2 mapped engine |
| `k0` | disconnect clutch K0 between engine and machine |
| `drive` | the 30 kW, 205 N·m machine with its converter and 1.4 kWh battery |
| `variator` | CVT, final drive included; pedal-scheduled or speed-commanded |
| `command` | adds start compensation to the machine torque request (step 3 only) |
| `hold` | holds the engine shaft for an electric-only run; no torque otherwise |

The machine sits on the transmission input shaft, between K0 and the CVT: it is not another gear
in series. With K0 open the machine drives the car alone; with K0 closed the engine and the
machine add their torques on one shaft. There is no separate launch clutch: in an engine-only car
K0 does that job.

Three structural flags change the powertrain's structure, so they are set where the powertrain is
placed, not by an analysis: `speed_commanded` (CVT follows `N_ref` instead of the pedal schedule,
step 2), `start_stop` (energy manager may start and stop the engine, step 3) and
`engine_stopped` (electric-only run).

[![Studio diagram of the P2 powertrain: command inputs on the left; engine, K0 and variator on one shaft with the hold hanging from it; the hybrid drive below, joining the shaft between K0 and the variator and fed by the torque command; every export wired from engine, K0 and drive to an output port on the right, the spline beside the variator, all housings wired to the support at the bottom](/lecture/lecture-05/img/step01-p2-powertrain.png)](/lecture/lecture-05/img/step01-p2-powertrain.png)

::: tip Checkpoint 1 — structure

On the canvas, trace engine → K0 → shared machine/variator input → variator → `spline`. All
housings reach `support`. There is one final drive (inside the variator) and no launch clutch.

:::

#### Wire it into the car (10 min)

Open `HandsOn05 › Step1EngineWLTC`. The powertrain is already placed in the middle, set up as the
conventional car H0. Its engine pedal and K0 request are set in code; no port is wired on the
canvas yet. Wire:

| From | To |
| --- | --- |
| `powertrain.spline` | `differential.flange_b` |
| `powertrain.support` | `mount.spline` |
| `powertrain.mdot_fuel` | `meter.mdot_fuel` |
| `pedal_command.y` | `powertrain.cvt_pedal` |
| `machine_gate.y` | `powertrain.tau_ref` |
| `unused_command.y` | `powertrain.N_ref` |
| `unused_command.y` | `powertrain.engine_torque_ref` |

The first two put the powertrain on the front wheels and on the ground. In H0 the CVT follows the
pedal schedule, so `N_ref` is ignored; the gate keeps the machine request at zero; the engine
torque target is used only with start/stop. The zero constant keeps every ignored input driven.

What the starter already does, in code: the pedal is the PI driver's output divided by 150 N·m;
K0 closes smoothly as the engine passes 1300 rpm (a launch, like a centrifugal clutch) and opens
again when the shaft falls toward the 800 rpm idle, so the engine does not stall at stops; front
friction brakes take the negative driver output; and the machine's losses and inertia are zeroed,
so H0 is a conventional car with the same mass. Leave `electric = false`.

#### Run H0 (5 min)

Save. With the starter's diagram focused, press ▷ (Run Analysis) and pick
`Step1EngineWLTCTransient`. In the REPL, `r1 = solution`, run the setup block above, then plot:

```julia
plot(t, [at(m.trace.y) 3.6 .* at(m.car.bus.vx)], label=["target" "actual"],
     xlabel="Time [s]", ylabel="Speed [km/h]")
plot(t, at(m.powertrain.engine_speed) .* (30/pi), ylabel="Engine [rpm]", label="engine")
plot(t, at(m.powertrain.position), ylabel="K0 position", label="K0")
plot(t, [at(m.meter.fuel_raw) at(m.meter.fuel_corr)], label=["raw" "SoC-corrected"], ylabel="L/100 km")
```

::: tip Checkpoint 1 — H0, full WLTC

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

Battery current is zero and SoC stays at 0.6, so raw and corrected fuel are equal. On level
stretches above 12 km/h, K0 position stays above 0.99. Wherever K0 position exceeds 0.5, the
sampled engine-speed minimum is 785.1 rpm: K0 opens during stops, and the engine can dip below
its nominal 800 rpm idle. The map's full-load peak, 150.234 N·m, stays below K0's 230 N·m
capacity. Slip heat is launch loss; its fuel cost is already inside H0's consumption.

H0 is the Lecture 5 baseline: the Lecture 2 engine and CVT on the same 1500 kg planar car as
the hybrid. Compare the hybrid against this H0, not against Lecture 2's 5.22 L/100 km from a
different bench.

:::

[![Studio diagram of the finished step-1 fixture: drive cycle, PI driver, torque split and machine gate in one line into the powertrain's torque request; a zero constant wired to the unused N_ref and engine-torque inputs and the pedal limiter to the CVT pedal; the powertrain turns the planar car's front wheels through the differential, with road load below the car, vehicle-speed feedback to the driver and split, and the fuel meter beside the powertrain](/lecture/lecture-05/img/step01-p2wltc-fixture.png)](/lecture/lecture-05/img/step01-p2wltc-fixture.png)

[![Engine-only WLTC speed tracking, engine speed, K0 position and slip, and fuel consumption](/lecture/lecture-05/img/step01-engine-only-wltc.png)](/lecture/lecture-05/img/step01-engine-only-wltc.png)

The same fixture with `electric = true` drives WLTC Low on the battery alone; the instructor
shows that run.

#### Fell behind?

`HandsOn05.P2WLTC` is the finished step-1 fixture; run `HandsOn05.P2EngineWLTCTransient`.

## 2 · Operating line — 20 min {#step-2}

#### Goal

Replace the pedal-based CVT schedule with a speed command: the speed on the Lecture 2 map's
best-BSFC line for the requested engine power. Everything else stays as in H0: the same engine,
K0 launch, car, road load and brakes. Then measure whether it saves fuel.

#### Given

`HandsOn05 › Step2OperatingLineWLTC` is the H0 car without the electric-only option, with its
powertrain still pedal-scheduled (`speed_commanded = false`). It already declares the full-pedal
power `P_peak = 85000` W, the floor `N_locked = 1000` rpm and the variable `N_target`, the
commanded transmission input speed.

#### Do this

1. Place one block and rename it:

   | Name | Library path |
   | --- | --- |
   | `line` | VehicleSystemsComponents › Vehicle › OperatingLine |

   `OperatingLine` turns a requested power `P` [W] into the best-BSFC engine speed `N` [rpm].
2. Wire the zero constant to the two inputs the speed-commanded powertrain ignores:

   | From | To |
   | --- | --- |
   | `unused_command.y` | `powertrain.cvt_pedal` |
   | `unused_command.y` | `powertrain.engine_torque_ref` |

3. Open code view (⇄). In the `powertrain = ...` line, change `speed_commanded = false` to
   `speed_commanded = true`. Then add these three lines to `relations`:

   ```dyad
   line.P = powertrain.engine_pedal * P_peak
   N_target = max(line.N, N_locked)
   powertrain.N_ref = N_target
   ```

   These are equations, not wires: the line's input is a product (pedal × 85 kW) and the target
   is floored at 1000 rpm, above the 800 rpm idle; no port carries either value.
4. Save, close the diagram, reopen it, press ▷ and pick `Step2OperatingLineWLTCTransient`. In
   the REPL, `r2 = solution`, rerun the setup block with `r = r2`, then plot the operating
   points over the line:

```julia
scatter(at(m.powertrain.engine_speed) .* (30/pi), at(m.powertrain.engine_torque),
        markersize=1, label="WLTC", xlabel="Engine speed [rpm]", ylabel="Torque [N·m]")
using VehicleSystemsComponents
rows = [parse.(Float64, split(l, ',')) for l in
        readlines(joinpath(pkgdir(VehicleSystemsComponents), "assets", "data", "engine", "bsfc_line.csv"))[2:end]]
line = reduce(vcat, permutedims.(rows))
plot!(line[:,2], line[:,3], label="best-BSFC line", linewidth=2)
plot(t, [at(m.powertrain.engine_speed) .* (30/pi) at(m.N_target)],
     label=["engine" "commanded"], xlabel="Time [s]", ylabel="Speed [rpm]")
```

The pedal asks for a power, `pedal × 85 kW`, and the CVT sets the speed for that power. This is
open loop: the engine still makes whatever torque its pedal and air path give at that speed, so
requested and delivered power need not agree, and most points do not land exactly on the line.

::: tip Checkpoint 2 — full WLTC

| Quantity | Full WLTC |
| --- | --- |
| Maximum speed error | 1.167747 km/h (<2) |
| Distance | 23266.405 m |
| Raw / corrected fuel | 5.437444 / 5.437444 L/100 km |
| H0 pedal-schedule fuel | 5.717536 L/100 km |
| Difference | −0.280092 L/100 km (−4.899%) |
| Energy | 175.8089 MJ/100 km |
| Battery current / SoC | zero / 0.6 throughout |

Lower speed at higher load moves part of the cycle toward better BSFC. The saving uses the same
driver, brakes and K0 lock-up as H0, and no machine assistance or regen.

:::

[![Studio diagram of the finished step-2 fixture: drive cycle, PI driver, operating-line table and a zero constant wired to the powertrain's ignored CVT pedal and engine-torque inputs; the P2 powertrain turns the planar car through the differential, with road load, speed feedback and fuel meter](/lecture/lecture-05/img/step02-operating-line-diagram.png)](/lecture/lecture-05/img/step02-operating-line-diagram.png)

[![Engine operating points on the best-BSFC line and full-load map for the operating-line WLTC](/lecture/lecture-05/img/step02-operating-points.png)](/lecture/lecture-05/img/step02-operating-points.png)

#### Fell behind?

`HandsOn05.P2OperatingLineWLTC` is the finished step-2 fixture; run
`HandsOn05.P2OperatingLineWLTCTransient`.

## 3 · Energy manager — 30 min {#step-3}

#### Goal

Let a rule-based energy manager split the driver's demand between engine and machine, start and
stop the engine, and keep the battery charged over the cycle.

#### Given

`HandsOn05 › Step3HybridWLTC` carries the full hybrid drive with its losses, inertia and battery.
The `manager` (`Vehicle.EnergyManager`) is placed and already reads the driver's demand, vehicle
speed, SoC, engine speed and available engine torque, but none of its commands are wired yet. The
powertrain is speed-commanded with start/stop still off (`start_stop = false`). The starter
already holds, in code: the CVT target (the engine's line speed while it runs, a second line
`demand_line` following the demand power while it is off), K0 engagement gated by the manager,
the friction-brake split, and driver limits of ±(150.233567 + 205.0) N·m, engine peak plus
machine limit. The manager is set to `SoC_on = 0.52`, `SoC_off = 0.55` and `P_line_max = 30 kW`.

#### Do this

1. Open code view (⇄). In the `powertrain = ...` line, change `start_stop = false` to
   `start_stop = true`, and save. This adds the powertrain's `engine_on` input and lets fuel
   flow only when the manager asks for the engine; fuel fades in as the engine spins up from 400
   to 700 rpm. Close the diagram and reopen it before the canvas work.
2. Place one block and rename it:

   | Name | Library path |
   | --- | --- |
   | `map` | VehicleSystemsComponents › Vehicle › TorqueToPedal |

   `TorqueToPedal` is the inverse engine map: the pedal that gives a torque `tau` at speed `omega`.
3. Wire the manager's commands:

   | From | To |
   | --- | --- |
   | `manager.P_engine` | `line.P` |
   | `manager.tau_engine` | `map.tau` |
   | `powertrain.engine_speed` | `map.omega` |
   | `map.pedal` | `powertrain.engine_pedal` |
   | `manager.tau_engine` | `powertrain.engine_torque_ref` |
   | `manager.engine_on` | `powertrain.engine_on` |
   | `manager.tau_machine` | `powertrain.tau_ref` |

4. Save, press ▷ and pick `Step3HybridWLTCTransient`. In the REPL, `r3 = solution`, rerun the
   setup block with `r = r3`, then plot:

```julia
plot(t, [at(m.trace.y) 3.6 .* at(m.car.bus.vx)], label=["target" "actual"], ylabel="Speed [km/h]")
plot(t, at(m.powertrain.engine_speed) .* (30/pi), ylabel="Engine [rpm]", label="engine")
plot(t, at(m.powertrain.SoC), ylabel="SoC", label="SoC")
plot(t, [at(m.manager.ev) at(m.manager.on_line) at(m.manager.charging) at(m.manager.boosting)],
     label=["electric" "on line" "charging" "boost"], xlabel="Time [s]")
```

What the wires do. The manager picks one of four modes. **Electric** carries low demand with K0
open and the engine off. **On line** starts the engine and asks it for `P_engine` at the line
speed. **Charging** raises engine load when SoC is low and stores the surplus. **Boost** adds
machine torque above the 30 kW line cap. `tau_engine` becomes a pedal through `map`, and the
powertrain uses it to compensate the torque K0 transmits while the engine starts.
`tau_machine` is what is left of the demand for the machine. While braking, the machine
recovers energy first and the friction brakes take the rest.

::: tip Checkpoint 3 — full WLTC

| Quantity | Full WLTC |
| --- | --- |
| Engine starts | 44 |
| Minimum / mean engine on-time | 1.87 s / 14.72 s |
| Maximum speed error | 1.32 km/h |
| K0 slip energy | 111.21 kJ (2.53 kJ per start) |
| Corrected fuel | 4.08634 L/100 km |
| SoC start → end | 0.6 → 0.61221 |

All four modes occur and their fractions sum to one. While stopped, the engine burns no fuel
and its speed stays within 3 rpm of rest. Mode fractions blend during starts and stops, so a
small amount of fuel is booked to electric mode; settled electric operation burns none.

:::

[![Studio diagram of the finished step-3 fixture: driver demand into the energy manager, whose outputs drive the torque-to-pedal map and the powertrain; engine speed, available torque and SoC loop back under the manager; operating-line tables above; a zero constant below the powertrain feeds its ignored CVT pedal; planar car, road load and fuel meter as in step 2](/lecture/lecture-05/img/step03-hybrid-diagram.png)](/lecture/lecture-05/img/step03-hybrid-diagram.png)

[![Hybrid WLTC speed tracking, engine starts, K0 position, battery SoC and energy-manager modes](/lecture/lecture-05/img/step03-hybrid-wltc.png)](/lecture/lecture-05/img/step03-hybrid-wltc.png)

#### Fell behind?

`HandsOn05.P2HybridWLTC` is the finished step-3 fixture; run `HandsOn05.P2HybridWLTCTransient`.

## 4 · Compare — 10 min {#step-4}

A hybrid can save fuel by draining its battery, so compare at equal charge: the meter's
`fuel_corr` converts the change in stored battery energy into fuel. Read it only after the full
1800 s. If your three results are still in the REPL:

```julia
[r.sol[symbolic_container(r).meter.fuel_corr][end] for r in (r1, r2, r3)]
```

The hybrid starts at SoC **0.60000**, finishes at **0.61221**, and stays between **0.51295** and
**0.61252**.

| Car | Raw L/100 km | SoC-corrected L/100 km | MJ/100 km |
|---|---:|---:|---:|
| Conventional H0 | 5.718 | 5.718 | 184.87 |
| Step-2 line car | 5.437 | 5.437 | 175.81 |
| Charge-sustaining P2 hybrid | 4.114 | 4.086 | 132.12 |
| Lecture-4 BEV | — | — | 47.25 |

H0, the line car and the hybrid share the same driver gains (`k = 110`, `Ti = 1 s`); the wider
±(150.233567 + 205.0) N·m driver limits apply only to the hybrid. The BEV value is battery DC
energy; the other rows are corrected gasoline energy. These are vehicle energy inputs, not a
well-to-wheel comparison.

::: tip Checkpoint 4 — charge-sustaining comparison

The hybrid ends **1.22 percentage points** above its starting SoC, within ±2 percentage points.
Its corrected fuel is **28.53%** below H0.

:::

The [homework](./homework) takes the same car to a series hybrid.

## Go further (optional) {#go-further}

#### Electric-only WLTC Low

`Lecture5.P2ElectricWLTCTransient` runs the step-1 fixture with `electric = true` for the 589 s
WLTC Low phase: K0 open, engine held stopped with fuel cut, the machine driven by the PI driver
(`k = 50`, `Ti = 2 s`) through `TorqueSplit`. An analysis cannot set the structural `electric`
flag, so `P2ElectricWLTC` is a test component that `extends P2WLTC(electric = true)`.

| Quantity | Measured WLTC Low result |
| --- | --- |
| Maximum absolute speed error | 1.502830 km/h |
| Distance | 3094.989 m |
| Fuel | 0 |
| SoC | 0.6 → 0.3864 |
| Maximum machine speed | 3545.66 rpm |

Zero fuel is not zero energy: the battery loses charge. The hybrid-drive dyno validates the
machine to 4000 rpm; the variator schedules up to 6000 rpm, which is not validated here. The
constant-voltage battery has no depletion cutoff, so this is not a full-cycle battery model.

#### Build the powertrain from its parts

`HandsOn05.P2Powertrain` is the same powertrain as `Vehicle.P2Powertrain`, written out as a
build you can redo in a module of your own (right-click the library › **Add Module**, then the
**+** on the module's row). Place `engine` (Vehicle › Engine › MappedEngine), `k0` (Vehicle ›
DisconnectClutch), `drive` (Vehicle › Electric › HybridDrive), `variator` (Vehicle ›
P2Variator), `command` (Vehicle › P2TorqueCommand) and `hold` (Vehicle › OptionalShaftHold).
What to watch:

- The machine shares the shaft between K0 and the variator: `connect(k0.spline_b, drive.spline,
  variator.spline_a)`. All housings go to `support`.
- `P2Variator` already includes the final drive. Do not use `CVTDriveline`: it adds a
  centrifugal launch clutch and an ideal rolling wheel.
- Wire every output from a port of the owning part (`engine.engine_speed`, `drive.SoC`,
  `k0.measured_position`, …). A `connect` to an inner variable such as `engine.speed.w` stops
  Studio from drawing the diagram.
- Structural flags, conditional declarations (`engine_on = RealInput() if start_stop`), the
  `ifelse` fuel-cut thresholds and the initial conditions are code-view work. With the engine
  held stopped, the fuel-cut thresholds move to −2 / −1 rpm: at the normal 1300 / 1000 rpm the
  held shaft at 0 rpm would keep resuming fuel.

Compare your build line by line with `HandsOn05/P2Powertrain.dyad`, then point a copy of a
step-1 fixture at your own powertrain.

#### Energy accounting in step 3

The step-3 fixture integrates three energies; read them at 1800 s with `s[m.E_regen][end]` and
so on. Requested shaft regen `E_regen` is **3.119 MJ**; actual friction-brake dissipation
`E_friction` is **0.0536 MJ**. The battery accepts `E_charge` = **3.920 MJ** in total, including
engine-driven charging. These quantities have different measurement boundaries.

#### Start compensation

Over the first 3 s of starts, the unclamped start-compensation excess peaks at 123.34 N·m for
2.57 s total; the maximum speed error there is 0.996 km/h. The final machine request peaks at
205 N·m. The powertrain clamps the sum to the machine's torque and power envelope, so start
compensation cannot guarantee full driver demand at every start. The torque inverse assumes the
default engine and air-path calibration.

::: warning Instructor note — operating-point diagnostics for step 2

These diagnostics are instructor context, not student acceptance criteria. They use the same
0.01 s grid as the checkpoints. At each sample define `power = rpm .* torque .* (pi/30/1000)` in kW
and interpolate CSV rpm at that actual brake power (clamp beyond the CSV endpoints). Let
`cmd = at(m.powertrain.variator.i_command)` and `deviation = abs.(rpm .- target)`. Classes are
applied in this order: `idle = (power .< 1) .| (at(m.driver.y) .<= 0)`;
`launch = .!idle .& (cmd .>= 11.999)`; `overdrive = .!idle .& (cmd .<= 2.801)`;
`eligible = .!idle .& .!launch .& .!overdrive`; `on = eligible .& (deviation .<= 150)`. Point
shares count samples; fuel shares sum sampled fuel flow with half weight at the first and last
samples.

**Line band:** compare actual engine rpm against CSV rpm at actual brake power, within
**±150 rpm**. For positive demand, power ≥1 kW and command inside `(2.801, 11.999)`, only
**16.40%** of eligible points meet it. Maximum in-range deviation outside launch saturation is
**1541.15 rpm**, bounded by 1600 rpm in the test. Including overdrive saturation, the maximum
outside launches is 2307.37 rpm (test bound 2400 rpm). The open-loop pedal calibration is not an
inverse engine map; most points are not on the line.

| Classification | All points | All fuel |
| --- | --- | --- |
| In range, within ±150 rpm | 5.527% | 16.748% |
| Idle/braking | 47.143% | 8.669% |
| Launch limit | 3.671% | 6.007% |
| Overdrive limit | 15.478% | 25.350% |
| In range, outside band | 28.182% | 43.226% |
| Total off line | 94.473% | 83.252% |

Idle/braking takes precedence over saturation. On level stretches of the trace above 12 km/h,
K0's sampled minimum position is 0.98846; where it is closed, the maximum regularized slip is
0.29977 rad/s, which is not an open clutch. Decelerating, the variator's 0.5 s ratio lag lets the
shaft fall below the 1000 rpm floor, and at low vehicle speed its 50 rpm output-speed floor
reduces shaft speed enough to open K0 during stops: 37.38 s above 10 km/h, with 4.78 g of fuel
burned meanwhile. Wherever K0 position exceeds 0.5, the sampled engine-speed minimum is
815.95 rpm, not a continuous-time lower bound.

The shallow-slope cruise mask resumes at **54.01 s**, right after a deceleration, while the
variator's **0.5 s** ratio lag is still settling. At **12.043 km/h** the driver is still braking
(pedal zero), the target is floored at **1000 rpm**, and the shaft is near **867 rpm**. K0 is
recovering through its lock-up ramp: position **0.98846**, about **0.004 rad/s** slip, for
**0.06 s** below 0.99. Expect this brief dip, not a loss of lock in steady cruise; the physical
check allows position above **0.98**.

:::

::: warning Instructor note — power-error and fuel-band diagnostics for step 3

These diagnostics are instructor context, not acceptance criteria. On the 0.01 s grid, let on-age
be the duration since `engine_on > 0.5` became true (zero while off). For
`(on_age .> 3) .& (at(m.manager.on_line) .> 0.9)`, compute
`abs.(at(m.powertrain.engine_torque) .* at(m.powertrain.engine_speed) .- at(m.manager.P_engine))`.
Its sample mean and maximum define the power errors below. The fuel-band share is
`sum(fuel[abs.(at(m.powertrain.engine.N) .- at(m.line.N)) .<= 150]) / sum(fuel)`, with
`fuel = at(m.powertrain.mdot_fuel)`. Outside the first 3 s of each start, on-line-mode engine
power has mean absolute error **171 W**, maximum **3298 W**. Across the whole run, **58.92%** of
fuel is burned within ±150 rpm of the line, versus step 2's 16.75%. The inverse map needs no PI
trim; steady analytic torque round trips are within 1e-7 N·m.

:::
