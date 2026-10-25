# Lecture 3: ESP active pressure build

How ESP brakes a wheel nobody is braking. TCS uses the same hardware on a driven wheel.

An ABS-only unit cannot raise wheel pressure above the master cylinder's: its return pump only
returns fluid the inlet valves let through. An ESP/TCS unit adds two valves per circuit. With
them the return pump can draw fluid from the reservoir and push it into one caliper while the
pedal is released.

## The bench

`Lecture3.ESPActiveBuildBench` is one circuit and one front wheel. Analyses:
`Lecture3.ESPActiveBuildTransient` (warm, `nu` and `energize_valves` exposed) and
`Lecture3.ESPActiveBuildColdTransient` (−40 °C). Test: `test/esp_active_build.jl`.

```
reservoir 0 bar ── line_mc (0.5 m) ──┬── switchover valve (NO, 140 bar limit) ──┬── inlet valve (NO) ──┬── line (1.5 m) ── caliper
  (pedal released, the master        │                                         │                      │
   cylinder open to its reservoir)   └── high-pressure valve (NC) ──┐          │ pump discharge       outlet valve (NC)
                                                                    │          │                      │
                                                                    └─ suction ┴── return pump        low-pressure accumulator
                                                                         └──── check valve ───────────┘
```

New parts in `Vehicle.Brake`:

- `SwitchoverValve`: normally open, between the master cylinder and the inlet valves. When it is
  energized (closed), its seat lifts once the pump side exceeds the master-cylinder side by
  `dp_limit`, which caps what the pump can build. A check valve always passes the driver's
  pressure to the wheels.
- `HighPressureValve`: normally closed, from the master-cylinder side to the pump suction.
- `PrimingReturnPump`: averaged pump with a motor run-up lag and a suction fill fraction. The
  fill drops to zero as the suction pressure nears −0.8 bar gauge, so a restrictive or cold
  suction path limits the flow before the displacement does.
- `AccumulatorCheckValve`: from the accumulator to the pump suction. It is closed at the
  accumulator's empty stop.
- `ESPHydraulicCircuit`: composes these with the existing `InletValve`, `OutletValve`,
  `LowPressureAccumulator` and three `ValveBlockVolume` galleries. `HydraulicModulator` could not
  be reused: its pump draws only from its own accumulator, through no outside port, and its
  `ReturnPump` needs at least 5 bar at the suction.

Schedule (`ESPActiveBuildProfile`), pedal force zero throughout:

| phase | warm, s | switchover | high-pressure | inlet | outlet | pump |
|---|---|---|---|---|---|---|
| idle | 0–0.05 | open | closed | open | closed | off |
| build | 0.05–0.75 | **closed** | **open** | open | closed | **on** |
| hold | 0.75–1.0 | closed | closed | **closed** | closed | off |
| release | 1.0–1.4 | open | closed | closed | **open** | on (empties the accumulator) |
| off | 1.4– | open | closed | open | closed | off |

The cold run uses the same plant and the same order of phases. Only `nu` changes, and the build is
stretched to 14 s so that it completes.

## Results

Times are from the build command at 0.05 s. The lock pressure is 52.2 bar (see below).

| metric | warm, 10 mm²/s (DOT 4, 20 °C) | cold, 1800 mm²/s (FMVSS 116 DOT 4 limit, −40 °C) | 750 mm²/s (ISO 4925 class 6, −40 °C) |
|---|---|---|---|
| time to 50 bar | 0.336 s | 7.06 s | 2.99 s |
| time to lock pressure, 52.2 bar | **0.340 s** | **7.17 s** | 3.03 s |
| time to 100 bar | 0.415 s | 8.96 s | 3.79 s |
| mean build rate, 0–100 bar | 241 bar/s | 11 bar/s | 26 bar/s |
| build rate, 50–100 bar | 627 bar/s | 26 bar/s | 62 bar/s |
| peak pressure | 140.2 bar (capped by the switchover valve) | 140.2 bar | — |
| pump fill fraction during the build | 1.0 (suction −0.2 bar) | 0.042 (suction at the −0.8 bar limit) | — |

The class 6 column comes from one run of the cold analysis with `nu = 750e-6`; the test does not
check it. All the valves de-energized with the pump running: peak 3·10⁻⁷ bar, so nothing builds.

**The curve.** About 0.15 s pass before the pressure is noticeable: motor run-up (40 ms) and the
caliper's 0.25 cm³ clearance take-up. The rise then steepens as the caliper stiffens, flattens on
the 140 bar limit, holds flat once the inlet valve closes, and falls in about 0.1 s on release.

## Against the targets

- **300–360 ms conventional-ESP time to lock** (derived from Continental MK C1 "150 ms, twice as
  fast" and Bosch iBooster "120 ms, three times faster"; see `esp-tcs-plausibility-research.md`
  §2). The warm 0.340 s is in the band, **but that agreement is an input, not a result.**
  The pump displacement `q_max` was chosen so the warm build lands there, the same way
  `InletValve`'s seat was derived from 580 bar/s. Neither the band nor the pump has a primary
  source.
- **What the bench shows on its own:**
  - the cold slowdown: 21× at the DOT 4 limit, 9× for a class 6 fluid;
  - the 140 bar cap from the switchover valve (Bosch US 8,579,385: "up to 140 bar");
  - that nothing builds while the valves are de-energized;
  - the delay-then-ramp shape of the curve.
- **The planar model's 0.1 s.** `PlanarBrakedWheel` uses a 30 ms first-order lag (`T_brake`), so
  it reaches 95 % of a step at 0.09 s. That is about 3.7 times faster than the hydraulic build.
- **Cold.** No source gives a cold build time. The patents only say that a viscous fluid
  "impairs" the build (US 8,579,385; US 6,807,848, from a search excerpt). In the model, the cold
  suction hits its −0.8 bar limit and the pump fills only 4 % of its displacement. The number is
  therefore set almost entirely by the laminar resistance of the master-cylinder-to-unit line,
  which scales as `L/D⁴` (0.5 m × 3 mm, assumed), and by the assumed suction limit. Read 7 s as
  "seconds, not tenths", not as a prediction.

## Parameters

| parameter | value | source |
|---|---|---|
| switchover limit `dp_limit` | 140 bar | Bosch US 8,579,385 |
| switchover regulation band, seat | 5 bar, 1.0 mm | assumed |
| high-pressure valve seat, laminar transition | 1.5 mm, 0.1 bar | assumed |
| valve lags | 3 ms | assumed, as the ABS valves |
| pump displacement flow `q_max` | 4 cm³/s | **fitted** to the 300–360 ms band |
| pump motor run-up `T_motor` | 40 ms | assumed |
| suction fill limit `p_cav`, `dp_fill` | −0.8 bar gauge, 0.1 bar | assumed (outgassing before vapor pressure) |
| master-cylinder-to-unit line | 0.5 m, 3 mm | assumed |
| unit-to-caliper line | 1.5 m, 3 mm | `BrakeLine` default |
| fluid viscosity | 10 / 1800 mm²/s | `BrakeLine` default / FMVSS 116 S5.1.3 |
| one front caliper | K = 24.5 N·m/bar, V0 = 0.25 cm³, K1 = 2·10¹² Pa/m³, K3 = 3.84·10²⁴ Pa/m⁹ | half of `HydraulicBrakedWheel`'s front axle (49.0 N·m/bar, two calipers); the same pressure at half the volume doubles K1 and gives 8× K3 |
| accumulator, inlet and outlet valves | as `HydraulicModulator` | US5015043 / derived |

**Is 4 cm³/s realistic?** It works out to 0.04 cm³ per revolution at 6000 rpm, for example one
6 mm piston with a 1.5 mm stroke per circuit. No figure for an ESP pump's displacement or motor
speed was found, so **this is assumed**. It also disagrees with `ReturnPump`'s 10 cm³/s, which is
assumed too and was sized only to empty the accumulator. In a real unit both are the same pump.

**Lock pressure.** A `PlanarCar` front wheel at static load (h_cg = 0, as `QuasiStaticLoads`)
carries `N = m g b / (2(a + b)) = 1500 · 9.81 · 1.5 / 5.4 = 4087 N`. At µ_A = 1.0 and r = 0.31 m,
the lock torque is 1267 N·m. With 24.5 N·m/bar above the 0.5 bar pad-contact pressure, that needs
**52.2 bar** (`ESPActiveBuildBench.p_lock`).

## Recommendation for the planar brake channels

Use the warm **0–52 bar time of 0.34 s** as the time an ESP-requested front brake torque needs to
reach lock (1267 N·m) from zero.

- **Rate limit (preferred):** 1267 N·m / 0.34 s ≈ **3.7 kN·m/s**. That is 152 bar/s × 24.5 N·m/bar
  over the 51.7 bar above pad contact. Apply it to rising torque only. Release takes about 0.1 s,
  and the driver's own pedal pressure does not go through the pump.
- **First-order lag (alternative):** a lag that reaches 95 % of a step to lock in 0.34 s has
  **T ≈ 0.11 s** (= 0.34 / 3), against today's `T_brake = 0.03 s`. A lag rises fastest at the
  start, while the hydraulic build is slowest there, so it overstates the torque in the first
  0.15 s. A rate limit is closer to the bench curve, and a 0.1 s dead time plus a steeper rate
  would be closer still.
- **Cold:** the same rule at −40 °C gives about 180 N·m/s at the DOT 4 limit, about 420 N·m/s
  for a class 6 fluid. Use it only to show the trend.
