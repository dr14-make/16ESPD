# Engine maps for the Lecture 2 mapped engine

Tables for a 1.5 L naturally aspirated four-cylinder (lecture plan S4), indexed by engine speed
and intake manifold pressure (mapped-engine plan M3–M5). Every file here is written by

    julia +dyad-3.4.0 --project=. scripts/alpha_engine_maps.jl [--figures data/engine/figures]

which also prints the reality-anchor checks, marking each miss. Do not edit the CSVs by hand;
change the script and rerun it.

## Source

`alpha/engine_2014_Mazda_Skyactiv_2L0_LEVIII.m` is file `7- engine_2014_Mazda_Skyactiv_2L0_LEVIII.m`
of the EPA ALPHA package, unchanged apart from the file name. Citation, as the package requires:

> 2014 Mazda 2.0L SKYACTIV Engine LEV III Fuel - ALPHA Map Package. Version 2018-02. Ann Arbor
> MI: US EPA National Vehicle and Fuel Emissions Laboratory, National Center for Advanced
> Technology, 2018.

Downloaded from
<https://www.epa.gov/sites/default/files/2018-04/2014-mazda-2.0l-skyactiv-engine-tier-2-fuel-alpha-map-package-03-29-18.zip>
(the URL says Tier 2; the archive holds the LEV III fuel files). SHA-256 of the archive:
e8402b148782984c98958a061e01b1b1e0ae8291748a10bca688d2673f8ea40f.

The script reads the `.m` file as text and accepts only numeric literals from it; it is never
run as MATLAB. The package's `.xlsx` carries the same fuel map and is not used.

## Files

Grids are rpm rows × kPa columns: the first row is the `p_m` axis (0–105 kPa, 2.5 kPa step),
the first column the speed axis (500–6750 rpm, 250 rpm step). `data[i, j]` is the value at
`(rpm[i], p_m[j])`, the layout `BlockComponents.Tables.InterpolatedTable` expects with
`u1 = N`, `u2 = p_m`. Units are engineering units, as in the file names.

| File | Content | Provenance |
|---|---|---|
| `torque_Nm.csv` | brake torque `T_e(N, p_m)`, fueled | (EPA ALPHA), (derived) |
| `fuel_gps.csv` | fuel mass flow `ṁ_f(N, p_m)`, g/s | (derived) |
| `lambda.csv` | air-fuel equivalence ratio `λ(N, p_m)` | (assumed) |
| `eta_v.csv` | volumetric efficiency `η_v(N, p_m)` | (derived) |
| `eta_v_coeffs.csv` | the closed form behind `eta_v.csv` and `lambda.csv` | (derived), (assumed) |
| `hc_gps.csv`, `co_gps.csv`, `nox_gps.csv` | engine-out emission flows, g/s | **(assumed)** |
| `full_load.csv` | full-load torque with its `p_m`, `λ` and `η_v`, on ALPHA's breakpoints | (EPA ALPHA), (derived) |
| `closed_throttle.csv` | closed-throttle (fuel-cut, motored) torque | (EPA ALPHA) |

CO₂ has no table: it is `3.09 · ṁ_f` (derived, carbon balance at full oxidation).

## The air path these maps assume

The maps and the air path must agree on how much air the cylinders draw, or λ in the model is
not the λ in `lambda.csv`. **`Engine.CylinderAirflow` uses exactly this `η_v`**, from
`eta_v_coeffs.csv` (or `eta_v.csv` on the same grid), with the same `R`, `T_m` and `V_d`:

    ν        = clamp(N, n_min, n_max) / 1000 rpm
    η_fl(N)  = c0 + c1 ν + c2 ν²
    η_v      = η_fl(N) · (1 − k + k · p_m / p_ref)
    ṁ_cyl    = η_v · p_m · V_d · N / (120 R T_m)                  (N in rpm)
    λ        = 1 − Δλ(N) · clamp((p_m / p_ref − x_rich) / (1 − x_rich), 0, 1)
    ṁ_f      = ṁ_cyl / (AFR_s · λ)

| Symbol | Value | Tag |
|---|---|---|
| `c0`, `c1`, `c2` | 0.7770, 0.1488, −0.02045 | (derived) least-squares fit to the ALPHA full-load fuel at `p_ref` |
| `k` | 0.8989 | (derived) zero brake torque at 800 rpm falls at 33 kPa |
| `p_ref` | 95 kPa | (assumed) full-load manifold pressure, mid-band of 90–98 kPa |
| `x_rich` | 0.85 | (assumed) enrichment starts at 85 % of `p_ref` |
| `Δλ(N)` | 0.10 at ≤ 1500 rpm, 0.14 at 3500, 0.20 at ≥ 6000, linear between | (assumed) |
| `R`, `T_m`, `V_d`, `AFR_s` | 287.05 J/(kg·K), 298.15 K, 1.5 L, 14.6 | (textbook), (MathWorks), (MathWorks), (deck slide 23) |

`η_fl(N)` is the full-load breathing curve: 0.84 at 500 rpm, peak 1.05 near 3600 rpm, 0.85 at
6750 rpm. The load factor `1 − k + k·p_m/p_ref` lowers `η_v` at part load, as late intake-valve
closing and residual gas do on the Skyactiv: `η_v` ≈ 0.37 at idle. Because `0 < k < 1`, the
cylinder air flow `η_v · p_m` rises strictly with `p_m`, so every fuel flow has one manifold
pressure. λ is 1 below 85 % load and falls to 0.90–0.80 at full load, richer at high speed for
exhaust-component protection.

## How the tables are derived

1. **Scale 1.998 L → 1.5 L** at constant BMEP and BSFC: torque and fuel flow × 1.5/1.998 at
   equal speed (derived). Peak torque becomes 150.2 N·m.
2. **Fit the air path**: `η_fl` to the ALPHA full-load fuel at `p_ref` with the full-load λ,
   then `k` to the idle condition, as above.
3. **Torque axis → manifold pressure.** Each fired ALPHA point (N, T, ṁ_f) gets the `p_m` at
   which the air path above burns ṁ_f.
4. **Re-grid.** At fixed speed fuel rises strictly with `p_m`, so each ALPHA column is a
   monotone torque-vs-`p_m` curve. Columns are interpolated linearly in `p_m`, extrapolated past
   their ends as ALPHA itself extrapolates, then linearly in speed onto the grid. `fuel_gps.csv`
   is the air path above in table form.

Because `η_fl` is smooth and the ALPHA full-load curve is not, four full-load breakpoints land
outside 90–98 kPa: 1901 and 2000 rpm at 100.0 kPa (ALPHA's torque steps up 15 N·m between 1700
and 1900 rpm), 6000 rpm at 106.5 kPa (ALPHA's full-load BSFC jumps to 343 g/kWh there) and
6562 rpm at 88.9 kPa. At wide-open throttle the model therefore delivers slightly less than
ALPHA's full-load torque at those speeds.

## Fuel cut is a mode, not a table entry

ALPHA's lowest torque row carries zero fuel (fuel cut) and so has no manifold pressure; it is
dropped. The tables describe fueled operation only: fuel goes to zero as `p_m` goes to zero,
and below the lowest fired point torque is extrapolated toward `p_m = 0` and floored at the
closed-throttle torque, so the table never brakes harder than the motored engine. ALPHA's
fueled points below the closed-throttle curve are unreachable and fall under that floor.

**The mapped engine must implement deceleration fuel cut.** On overrun (closed throttle above
idle speed) it switches to `closed_throttle.csv` for torque, with zero fuel and zero
emissions. Without it a closed throttle at speed still reads a fueled, near-zero torque from
`torque_Nm.csv` and the car engine-brakes far less than the motored engine.

## Emissions are assumed, not sourced

ALPHA holds no emissions, and no open engine-out map was found. `hc_gps`, `co_gps` and
`nox_gps` are an emission index (g per kg fuel) times the fuel table. The shapes follow the
textbook trends (Heywood ch. 11); the magnitudes are typical engine-out levels, chosen, not
measured. With `x = min(p_m / p_ref, 1)` (load), `v` the speed fraction of the grid and λ from
`lambda.csv`:

| Species | Emission index, g/kg fuel | Trend it encodes |
|---|---|---|
| NOx | `(3 + 32 x² (0.8 + 0.2 v)) · max(0.2, 1 − 4 (1 − λ))` | rises with load (burned-gas temperature), falls when rich |
| HC | `7 + 15 (1 − x)² (1 − 0.5 v) + 50 (1 − λ)` | highest at light load and low speed, up when rich |
| CO | `60 + 40 (1 − x)² + 3000 (1 − λ)` | low at λ = 1, steeply up under enrichment (oxygen-starved) |

This reads as HC / CO / NOx ≈ 3.5 / 117 / 3.9 g/kWh at full load, 3000 rpm (λ 0.87), and
3.0 / 21 / 3.1 g/kWh on the 90 km/h cruise (λ 1). Use these tables for trends only, and say so
wherever they are shown.
