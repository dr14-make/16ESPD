# Lecture 3 brake models: cost against fidelity

Measurements for the comparison slide. Every model stops one wheel of the 1400 kg hands-on car
from 25 m/s (90 km/h); the brake goes on at 0.5 s. Distance is `Vehicle.braking_distance` (from 0.5 s until
`v < 0.5 m/s`). Measured on 2026-10-25 with Dyad 3.4.0 (`julia +dyad-3.4.0`, Julia 1.12.7), one
Julia process at a time, on the lecturer's laptop.

## Cost at µ = 1.0, pedal 0.6

| Model | Solver | States | Accepted steps | Warm wall-clock [s] |
|---|---|---:|---:|---:|
| `HandsOn03.PedalStop` | Tsit5 | 7 | 31 802 | 0.14 |
| `HandsOn03.ABSStop` | Tsit5 | 12 | 33 972 | 0.17 |
| `HandsOn03.ABSStopWheelOnly` | Tsit5 | 13 | 29 512 | 0.58 |
| `HandsOn03.HydraulicABSStop` | Rodas5P | 21 | 201 550 | 33.5 |
| `Lecture3.VacuumPedalStop` | Tsit5 | 12 | 30 712 | 0.22 |
| `Lecture3.FullBrakeABSStop` | Rodas5P | 26 | 9 413 | 2.56 |
| `Lecture3.FullCarABSStop` (map engine, CVT, `stop = 4.5`) | Rodas5P | 32 | 10 884 | 3.70 |
| `Vehicle.ABSBrakeTransient` (torque-level ABS) | default (`CompositeAlgorithm`) | 5 | 2 941 | 17.2 |

- States are the unknowns after `mtkcompile` (`length(unknowns(symbolic_container(result)))`).
- Warm wall-clock is the fastest of three repeated analysis calls in a process that has already
  run the analysis once. It covers the whole call, problem build and solve.
- `Vehicle.ABSBrakeTransient` has a 5 ms sampled controller, so its time is dominated by the
  clock events, not the 5 states.
- `HydraulicABSStop` at µ = 1.0 takes 200 k steps where µ = 0.5 and 0.3 take 15 k and 18 k
  (2.9 s and 3.4 s). The cause was not investigated.
- First call of `Lecture3.FullBrakeABSStopTransient()` in a fresh process: `using
  VehicleSystemsComponents` 1.3 s, then 61.1 s for the first analysis call (compile plus run),
  63.4 s for the whole process, 2.7 GB peak RSS.
- `FullCarABSStop` is measured over its analysis default `stop = 4.5` (at rest at 3.75 s), not 6 s:
  about a second into standstill `RefSpeedEstimator`'s `ifelse` chatters about zero and the run
  slows sharply (47 k steps to 5 s, 194 k to 7 s). Its µ = 0.3 report run (`stop = 11`) takes
  173 k steps and 53 s warm, against 26 s for `FullBrakeABSStop`.

## Distance and mean front pressure, pedal 0.6

Mean front pressure is `wheel.caliper_f.p` averaged from 0.5 s until the car stops.
`Vehicle.ABSBrakeTransient` commands brake torque directly and has no hydraulics.

| Model | d µ = 1.0 [m] | d µ = 0.5 [m] | d µ = 0.3 [m] | p̄_f µ = 1.0 [bar] | p̄_f µ = 0.5 [bar] | p̄_f µ = 0.3 [bar] |
|---|---:|---:|---:|---:|---:|---:|
| `HandsOn03.PedalStop` (no ABS, locks) | 43.708 | 85.06 | 136.75 | 89.1 | 89.1 | 89.2 |
| `HandsOn03.ABSStop` | 34.212 | 64.60 | 106.05 | 63.1 | 37.6 | 27.5 |
| `HandsOn03.ABSStopWheelOnly` | 38.516 | 78.01 | 130.55 | 47.8 | 22.4 | 16.4 |
| `HandsOn03.HydraulicABSStop` | 39.111 | 65.79 | 108.66 | 49.1 | 31.8 | 29.6 |
| `Lecture3.VacuumPedalStop` (no ABS, locks) | 44.079 | 85.25 | 136.85 | 85.6 | 86.9 | 87.5 |
| `Lecture3.FullBrakeABSStop` (idle) | 41.808 | 77.83 | 116.59 | 47.8 | 28.7 | 28.4 |
| `Lecture3.FullCarABSStop` (90 km/h cruise) | 41.53 | 78.89 | 121.36 | 49.4 | 28.7 | 34.8 |
| `Vehicle.ABSBrakeTransient` | 38.698 | 83.19 | 141.27 | n/a | n/a | n/a |

## `FullBrakeABSStop` across vacuum supplies, pedal 0.6

"Store used up" starts the booster at `p_vac0 = 100 kPa` (1.3 kPa below ambient). ABS active is
the share of the braking time (v > 1.5 m/s) the controller spends out of its inactive phase.

| µ | Supply | d [m] | p_mc peak / mean [bar] | p_f peak / mean [bar] | ABS active | ABS cycle [Hz] | Steps | Wall [s] |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1.0 | idle | 41.81 | 104.2 / 83.5 | 88.5 / 47.8 | 86 % | 7.1 | 9 413 | 2.2 |
| 1.0 | WOT, store full | 43.06 | 97.2 / 77.4 | 78.9 / 46.7 | 84 % | 5.5 | 9 218 | 2.4 |
| 1.0 | WOT, store used up | 137.63 | 15.1 / 14.4 | 15.1 / 14.4 | 0 | none | 126 284 | 13 s run |
| 1.0 | engine off, store used up | 143.63 | 15.0 / 13.9 | 14.8 / 13.9 | 0 | none | 41 291 | 8.4 |
| 1.0 | EV pump | 43.02 | 106.8 / 83.1 | 96.4 / 47.1 | 84 % | 6.5 | 9 713 | 2.4 |
| 0.5 | idle | 77.83 | 101.7 / 85.7 | 87.5 / 28.7 | 89 % | 7.7 | 22 978 | 4.9 |
| 0.5 | WOT, store full | 78.24 | 99.5 / 79.9 | 77.7 / 28.2 | 89 % | 7.6 | 46 328 | 9.2 |
| 0.5 | WOT, store used up | 137.65 | 15.1 / 14.4 | 15.1 / 14.4 | 0 | none | 44 217 | 8.8 |
| 0.5 | engine off, store used up | 143.65 | 15.0 / 13.9 | 14.8 / 13.9 | 0 | none | 40 892 | 8.4 |
| 0.5 | EV pump | 78.08 | 104.5 / 88.9 | 96.6 / 29.9 | 87 % | 7.9 | 30 698 | 6.3 |
| 0.3 | idle | 116.59 | 101.7 / 86.7 | 88.5 / 28.4 | 80 % | 6.8 | 135 629 | 26.1 |
| 0.3 | WOT, store full | 117.18 | 99.5 / 80.4 | 76.7 / 27.1 | 79 % | 6.7 | 129 141 | 25.4 |
| 0.3 | WOT, store used up | 137.69 | 15.1 / 14.4 | 15.1 / 14.4 | 0 | none | see note | see note |
| 0.3 | engine off, store used up | 143.68 | 15.0 / 13.9 | 14.8 / 13.9 | 0 | none | 41 066 | 9.0 |
| 0.3 | EV pump | 117.00 | 103.6 / 93.1 | 101.5 / 31.1 | 79 % | 7.1 | 129 538 | 25.5 |
| 1.0 | idle, pedal 0.3, ABS off | 38.43 | 56.2 / 53.7 | 56.2 / 53.6 | 0 | none | 6 225 | 1.5 |

- With the store used up the master cylinder sees only the driver's unassisted force, about
  15 bar. The wheel never locks, so ABS never activates, and the stop is the same 138–144 m on
  every road.
- Run past the stop at WOT with the store used up, the manifold and the booster front chamber
  settle at the same pressure and Rodas5P hits `MaxIters` at standstill (µ = 1.0 at 23.6 s, µ =
  0.3 likewise). The stop itself is complete by 10.5 s, so those runs use `stop = 13.0`.
- The booster lag against `HydraulicABSStop`'s static booster: `p_mc` reaches 50 % of its peak
  0.18 s and 90 % 0.42 s after application, against instantly, and ABS first activates 0.34 s
  after application (when `p_mc` reaches the controller's 70 bar `p_activate`), against 5 ms.

## `FullCarABSStop`, the whole car, pedal 0.6

The Hands-on 02 map engine (fuel cut), flywheel and CVT (centrifugal clutch, variator) drive the
braked wheel from a steady 90 km/h cruise; at 0.5 s the throttle pedal is released and the brake
applied. The booster store starts at the cruise manifold pressure, 54.4 kPa. "Clutch opens" is
the clutch input first falling below its 1300 rpm engagement speed; "fuel back" is the fuel cut
ending (engine below 1000 rpm); "re-engaged" is the time after that the clutch capacity is above
half its 230 N·m maximum again. Engine speed never falls below 774 rpm, its closed-throttle idle.

| µ | ABS | d [m] | t [s] | Clutch opens [s] | Fuel back [s] | Re-engaged [s] | Peak rpm after opening | p_m min [kPa] | Store at stop [kPa] | p_f while cycling [bar] | ABS cycle [Hz] |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.0 | on | 41.53 | 3.25 | 2.50 | 3.22 | 0.27 | 1 340 | 22.3 | 27.4 | 24.4–69.9 | 8.5 |
| 0.5 | on | 78.89 | 5.98 | 0.74 | 0.91 | 3.24 | 2 207 | 20.5 | 24.2 | 5.4–69.9 | 6.8 |
| 0.3 | on | 121.36 | 9.67 | 0.70 | 0.86 | 5.28 | 2 765 | 18.1 | 24.5 | 5.0–69.9 | 5.7 |
| 1.0 | off | 45.40 | 3.53 | 0.91 | 1.07 | 0 | 1 294 | 27.9 | 31.6 | locked, 70–91 | none |
| 0.5 | off | 86.64 | 6.82 | 0.74 | 0.91 | n/m | n/m | 30.4 | 32.8 | locked, 70–91 | none |
| 0.3 | off | 138.64 | 10.99 | 0.70 | 0.86 | n/m | n/m | 30.3 | 33.7 | locked, 70–91 | none |

`FullBrakeABSStop` at idle with ABS off, for comparison: 44.12 / 85.30 / 136.90 m on µ 1.0 / 0.5
/ 0.3 (n/m: not measured).

- Both start at 25 m/s, so the start speed is not a difference. With the wheel locked the full
  car stops 1.3–1.7 m longer: the lock comes 0.04–0.06 s later (0.93 s against 0.89 s on µ 1.0)
  because the store starts at 54.4 kPa instead of 33 kPa and the flywheel adds 0.15·i² ≈ 1.2
  kg·m² (i = 2.83) to the 4 kg·m² wheel until the clutch opens.
- On low µ the first ABS cycle lets the wheel almost stop (0.77 s on µ 0.3, the bench does the
  same), which drags the engine below 1300 rpm and opens the clutch within 0.2 s of the brake.
  The variator follows the stalled wheel toward its launch ratio. When the wheel spins back up,
  the clutch output turns several times faster than the engine, the tanh tail of the clutch
  capacity (about 1.5–4 N·m at 1000–1050 rpm) pulls the engine back over 1300 rpm, and the
  clutch locks again: the engine, in fuel cut once more, is driven up to 2 200–2 800 rpm and
  its inertia (0.15·i², 2–3 kg·m² at i ≈ 4) and motoring torque sit on the cycling wheel for most
  of the stop. That is the main difference on µ 0.3 (121.4 m against 116.6 m): the cycle rate
  drops from 6.8 to 5.7 Hz. The re-engagement needs the engine to be on that tail when the wheel
  recovers: started at `p_vac0 = 33 kPa` the engine is at 960 rpm instead of 1020 rpm at 1.0 s,
  the clutch stays open, and the stop is 117.44 m; the bench started at 54.4 kPa gives 117.26 m.
- Engine braking itself is small: the closed-throttle motoring torque is 15–18 N·m at 1400–2800
  rpm, under 75 N·m at the wheel through i ≈ 2.8–4, against a few kN·m of brake torque.

### Open: the clutch re-engagement is a model artifact

The µ 0.5 and 0.3 ABS-on distances above include it, so they overstate the full car by about
1 m (µ 0.5) and 4–5 m (µ 0.3). A real centrifugal clutch transmits nothing below its engagement
speed; `CentrifugalClutch`'s `0.5·(1 + tanh((N_a − engage_rpm)/engage_width_rpm))` ramp still
passes about 1.5 % of `tau_max` (3.6 N·m) 250 rpm below it, enough to spin a fuel-cut engine back up.

Fixes, none applied:

1. **In this model only:** `clutch = CentrifugalClutch(engage_width_rpm = 40)` in
   `FullCarABSStop`. The tail at 1000–1050 rpm falls to a few 10⁻⁶ of `tau_max`. Hands-on 02 is
   untouched. Check that the dry stop and the locked runs move by no more than a few cm, and the
   1 ms rule (a narrower ramp stiffens the clutch's engagement).
2. **In the library:** a capacity that is exactly zero below an engagement start, e.g.
   `tau_max · clamp((N_a − N_start)/(N_full − N_start), 0, 1)²` with `min`/`max`, no events.
   More faithful, but it changes every Hands-on 02 launch result, its tests and its screenshots.

After either fix, re-run the table, the `FullCarABSStop` tests in `test/hydraulic_abs_valves.jl`
and the cost row above.

## Commands

```sh
npx -y @juliacomputing/dyad-cli@3.4.0 compile .
# tables 1 and 2
julia +dyad-3.4.0 --project=. compare.jl
# table 3
julia +dyad-3.4.0 --project=. fb_runs.jl
# first call in a fresh process
/usr/bin/time -f "wall=%e maxrss_kB=%M" julia +dyad-3.4.0 --project=. firstcall.jl
```

The scripts were throwaway scratchpad files. Their core, for one model `f` (an analysis
function such as `VehicleSystemsComponents.Lecture3.FullBrakeABSStopTransient`):

```julia
using VehicleSystemsComponents, Statistics
using DyadInterface: symbolic_container
using ModelingToolkit: unknowns

f(pedal = 0.6)                                   # compile
times = [(GC.gc(); @elapsed r = f(pedal = 0.6)) for _ in 1:3]
warm = minimum(times)
steps = r.sol.stats.naccept
states = length(unknowns(symbolic_container(r)))
solver = nameof(typeof(r.sol.alg))
for (mu, stop) in ((1.0, 6.0), (0.5, 9.0), (0.3, 16.0))
    run = f(pedal = 0.6, road_mu = mu, stop = stop)
    m = symbolic_container(run)
    d = VehicleSystemsComponents.Vehicle.braking_distance(run)
    t, v = run.sol.t, run.sol[m.body.mass.v]
    i = findfirst(k -> t[k] >= 0.5 && v[k] < 0.5, eachindex(t))
    p_mean = mean(run.sol[m.wheel.caliper_f.p][(t .>= 0.5) .& (eachindex(t) .<= i)]) / 1e5
end
```

`ABSStopWheelOnlyTransient` and `Vehicle.ABSBrakeTransient` take no `pedal` argument; they run
at their defaults (pedal 0.6 and 6000 N·m demand).
