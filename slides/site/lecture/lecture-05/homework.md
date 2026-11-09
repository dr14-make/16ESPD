---
title: Lecture 5 homework — a series hybrid on prepared ground
---

[← Vehicle Systems & Components](../../index.html) · [Lecture 5 build guide](./)

# Lecture 5 homework: a series hybrid

In a series hybrid only the electric motor drives the wheels. The engine turns a generator that
feeds the battery's DC bus, so it is free of the road: it can run at its best point, or not at
all. You build one on the Lecture 5 planar car, drive it through the WLTC charge-sustaining, and
compare its SoC-corrected fuel with the conventional car H0 from the
[build guide](./#step-1).

**What you build.** The series powertrain on a prepared ground: battery, traction drive and
engine-generator on one DC bus, the engine held on its best-BSFC line, and an **SoC
thermostat** of your own that turns the engine-generator on when the state of charge is low and
off when it is high.

**What you are given.** The car, the cycle, the driver and the fuel meter, in a ground you extend,
and every powertrain part. You write no new physics: the work is the wiring and the thermostat.

- [The task](#task)
- [The ground](#ground)
- [The parts](#parts)
- [Rules](#rules)
- [Targets](#targets)
- [How to measure](#measure)
- [Hand in](#hand-in)

## The task {#task}

1. In your `MyCar` library, on a new branch `homework-05`, open the Julia REPL and move the
   course library to the Lecture 5 version for Dyad 3.5. Your `Manifest.toml` still holds the
   Lecture 4 version, which has no `Lecture5`; the same line adds the library if `MyCar` has
   none yet.

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "lecture-05-dyad-3.5")
   ```

   Skipped Lecture 4? Also add the two packages your code names directly:

   ```julia
   Pkg.add(["ElectricalComponents", "MultibodyComponents"])
   ```

   Then <kbd>F1</kbd> → **Dyad: Restart Language Server** if you added the two packages, and
   <kbd>F1</kbd> → **Dyad: Compile**.
2. Create a test component `SeriesWLTC` that
   `extends VehicleSystemsComponents.Lecture5.SeriesWLTCGround`.
3. Add the battery, the auxiliaries, the traction drive and the engine-generator, and wire them
   to one DC bus and to the ground's open ends.
4. Feed the engine-generator its speed command from the best-BSFC operating line.
5. Write the SoC thermostat that sets the engine-generator's power command.
6. Write an analysis that runs the full WLTC, choose your thermostat's numbers, and meet every
   [target](#targets).

The design choices are yours: the power the engine-generator delivers when on, the two SoC
thresholds, and how the command moves between off and on. Write down why you chose them.

## The ground {#ground}

`Lecture5.SeriesWLTCGround` is a `partial component`: it cannot run by itself. It holds the
Lecture 5 planar car (1500 kg) on a flat road with its road load, the WLTC trace, the PI driver,
the torque split onto the front friction brakes, and the `SoCCorrectedFuel` meter with its speed
input wired. These are the ends it leaves open for you:

| Open end | You connect |
| --- | --- |
| `split.tau_motor` | the traction machine's torque request [N·m], at the machine shaft |
| `differential.flange_b` | the traction drive's output shaft, which turns the front wheels |
| `mount.spline` | every powertrain housing (`support`) |
| `meter.mdot_fuel` | the engine's fuel mass flow [kg/s] |
| `meter.P_stored` | the power out of the battery's store [W], by an equation, not a wire |

`meter.P_stored` has no port on the battery to wire to: write it as an equation in your
component's `relations`, `meter.P_stored = battery.E * battery.i`, with `battery` your pack's
name.

Its parameters, which you leave at their defaults: driver `k = 50` N·m per km/h, `Ti = 2` s,
`tau_max = 250` N·m (the traction machine's peak torque); split `ratio = 8.193` (the traction
drive's reduction) and `v_fade = 10` km/h. `tau_max` and `ratio` have to equal your traction
drive's `T_max` and `ratio`, and nothing checks it for you; see the
[TractionDrive](#traction-drive) interface. The wheels start 0.01 m/s ahead of the body, as on
every planar bench.

`Lecture5.SeriesGroundElectric` is the ground driven electric-only through WLTC Low, with no
engine: use it to see that the ground and the traction drive run, not as a series hybrid.

## The parts {#parts}

All of them are in `VehicleSystemsComponents`. Read each part's docstring in Studio for the
full contract; the interfaces are:

### `Vehicle.Electric.TractionDrive` {#traction-drive}

Converter, a DC-equivalent machine and the 8.193 reduction, on an external bus. Create it from
the ground's parameters, `TractionDrive(T_max = tau_max, ratio = ratio)`, so that the driver's
limit and the brake split match the drive.

The machine gives 250 N·m and is rated 80 kW at 220 V, but what it delivers depends on the bus.
On the homework pack alone it gets at most about 50 kW at the shaft: the pack cannot give more
than E²/(4 R0) = 55 kW, and its voltage falls to about 140 V when it does. More traction power
has to come from the engine-generator on the same bus. `Lecture5.TractionDrivePackDynoTransient`
shows the envelope on the pack alone.

| Port | Meaning |
| --- | --- |
| `tau_ref` (input) | electromagnetic torque asked of the machine [N·m], positive driving, negative braking into the bus; the shaft gets it less the machine's losses |
| `p`, `n` | DC bus pins; the drive does not ground `n` |
| `spline` | reduction output shaft |
| `support` | machine housing and gear case |
| `P_elec` (output) | power drawn from the bus [W], positive driving |

Initialize its converter current, `drive.converter.i_out`, to zero.

### `Vehicle.EngineGenerator`

Lecture 2's mapped engine and a 60 kW generator on one shaft, with the converter that delivers
its power to a DC bus. It holds two commands with two loops of its own.

| Port | Meaning |
| --- | --- |
| `P_ref` (input) | electrical power to deliver at the pins [W], zero or positive |
| `N_ref` (input) | engine speed [rpm] |
| `p`, `n` | DC bus pins; the bus must set its own voltage, as a battery does |
| `support` | engine mounts and generator housing |
| `mdot_fuel` (output) | fuel mass flow [kg/s] |
| `N` (output) | shaft speed [rpm] |
| `P_elec` (output) | electrical power delivered [W] |
| `P_shaft` (output) | engine power the unit needs in steady state for `P_ref` [W] |

The unit has no engine stop: at `P_ref = 0` the engine keeps running unloaded and burns its idle
fuel. A command past the engine's full load gets what the engine makes at full load, a little
under the commanded speed.
The two benches `Lecture5.EngineGeneratorBench` and `Lecture5.EngineGeneratorBatteryBench` show
it on a resistor and on a battery.

### `Vehicle.OperatingLine`

| Port | Meaning |
| --- | --- |
| `P` (input) | requested engine power [W] |
| `N` (output) | engine speed on the best-BSFC line [rpm]; 800 rpm at or below 1 kW |

### `Vehicle.Electric.Battery` and `Vehicle.Electric.AuxLoad`

Use the 2011 Sonata pack that `HybridDrive` carries: `E = 270` V, `Q_nom = 1.4e3 * 3600 / 270`
C (1.4 kWh), `R0 = 0.33` Ω, `SoC0 = 0.6`. Put an `AuxLoad` with `P_aux = 300` W on the same bus,
and one `ElectricalComponents.Analog.Basic.Ground` on `n`. `battery.SoC` is the output your
thermostat reads.

### `Vehicle.Engine.HysteresisLatch`, if you want it

A continuous set/reset latch: inputs `set` and `reset` (0 or 1), output `y` from 0 to 1, which
relaxes toward the latched value with `latch_time`. You may use it, or write your own latch.

## Rules {#rules}

- No events: no `when` clauses and no event handling. Switch through a continuous latch, such
  as `HysteresisLatch`, and smooth blends (`tanh`, a smooth clamp), as every controller in the
  course library does.
- The thermostat decides the engine-generator's power command only. The driver, the split and
  the brakes stay as the ground has them.
- "Off" is `P_ref = 0`: the engine idles. Its idle fuel counts, and it is part of what you
  trade.
- Run the full cycle, not a phase.

## Targets {#targets}

Your run has to meet every row.

| Quantity | Target |
| --- | --- |
| Run | the full 1800 s WLTC, `retcode` Success |
| Speed tracking | trace minus car speed within ±2 km/h everywhere (WLTP's band) |
| Charge sustaining | SoC at the end within ±0.02 of its start, 0.6 |
| Pack window | SoC between 0.25 and 0.85 throughout |
| SoC-corrected fuel | at most 5.60 L/100 km, which is 181.1 MJ/100 km at the meter's 0.745 kg/L and 43.4 MJ/kg |
| Matches the ground | your drive's `T_max` and `ratio` equal the ground's `tau_max` and `ratio` |
| Thermostat | at most 30 engine-generator starts; every on and every off period at least 5 s |

For comparison, H0 on the same car burns 5.7 L/100 km and the Lecture 4 BEV draws 47 MJ/100 km at
its battery terminals. Meeting the fuel target means beating the conventional car by a few
percent, not by the 12–25 % of the parallel hybrids in the lecture's studies: say in your
report where the series car loses the rest.

## How to measure {#measure}

The analysis:

```dyad
analysis SeriesWLTCTransient
  extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
  model = SeriesWLTC()
end
```

`optimize = OptimizationLevel.None()` is required on the planar car. Press ▷ on the analysis
once in Studio, then read the results in the Julia REPL:

```julia
using VehicleSystemsComponents, MyCar
using DyadInterface: symbolic_container
r = MyCar.SeriesWLTCTransient()
m, s = symbolic_container(r), r.sol
ts = 0.0:0.1:1800.0
at(x) = s(ts, idxs = x).u

s.retcode                                        # Success
s[m.meter.fuel_corr][end]                        # L/100 km
s[m.meter.energy_corr][end]                      # MJ/100 km
soc = at(m.battery.SoC)
soc[end] - soc[1], extrema(soc)                  # charge sustaining, pack window
maximum(abs.(at(m.trace.y) .- at(m.kmh.y)))      # km/h
s.ps[m.drive.machine.T_max] == s.ps[m.tau_max]   # your drive's name in place of drive
s.ps[m.drive.reduction.ratio] == s.ps[m.ratio]
```

Count starts and on and off periods from the power the engine-generator delivers: call it on
where `P_elec` is above half of your on power. Read the corrected fuel at the end of the run
only; earlier it is a total spread over a short distance.

## Hand in {#hand-in}

A pull request on your `MyCar` repository that asks to merge `homework-05` into the branch you
started from, titled `Lecture 5 homework`. Do not merge it. In the description:

1. The targets table with your numbers in a third column.
2. Your thermostat's numbers and why you chose them.
3. One plot over the cycle: SoC, and the engine-generator's `P_elec` and speed `N`.
4. A paragraph: where the series car's fuel goes, compared with H0 and with the BEV, and what it
   would take to beat H0 by more.
