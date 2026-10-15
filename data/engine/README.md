# Engine maps for the Lecture 2 mapped engine

Tables for a 1.5 L naturally aspirated four-cylinder (lecture plan S4), indexed by engine speed
and intake manifold pressure (mapped-engine plan M3–M5). Every file here is written by

    julia +dyad-3.4.0 --project=. scripts/alpha_engine_maps.jl [--figures data/engine/figures]

which also prints the reality-anchor checks and exits nonzero if a banded one fails. Do not edit
the CSVs by hand; change the script and rerun it.

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
| `torque_Nm.csv` | brake torque `T_e(N, p_m)` | (EPA ALPHA), (derived) |
| `fuel_gps.csv` | fuel mass flow `ṁ_f(N, p_m)`, g/s | (derived) |
| `hc_gps.csv`, `co_gps.csv`, `nox_gps.csv` | engine-out emission flows, g/s | **(assumed)** |
| `full_load.csv` | full-load torque and its `p_m`, on ALPHA's breakpoints | (EPA ALPHA), (derived) |
| `closed_throttle.csv` | closed-throttle (fuel-cut, motored) torque | (EPA ALPHA) |
| `eta_v.csv` | volumetric efficiency knots used for the conversion | (assumed), calibrated |

CO₂ has no table: it is `3.09 · ṁ_f` (derived, carbon balance at full oxidation).

## How the tables are derived

1. **Scale 1.998 L → 1.5 L** at constant BMEP and BSFC: torque and fuel flow × 1.5/1.998 at
   equal speed (derived). Peak torque becomes 150.2 N·m.
2. **Torque axis → manifold pressure.** At λ = 1 the air flow is `14.6 · ṁ_f` (AFR, deck slide
   23), and speed-density in its rpm form inverts it:
   `p_m = 120 R T_m ṁ_air / (η_v V_d N)`, with R = 287.05 J/(kg·K) (textbook),
   T_m = 298.15 K (MathWorks), V_d = 1.5 L. Scaling cancels out of `p_m`.
3. **η_v(N)** is the one assumption. One knot per ALPHA full-load breakpoint from 1039 to
   6562 rpm, each set so the full-load fuel is drawn at 95 kPa (mid-band of the 90–98 kPa
   anchor); linear between knots and held beyond the ends. Because the conversion assumes
   λ = 1, the knots are `η_v / λ`: they run 0.87–1.45, above 1 wherever ALPHA's full-load fuel
   is richer than stoichiometric (most clearly 6000 rpm, where full-load BSFC rises to
   343 g/kWh). Treat them as an apparent volumetric efficiency, not a breathing figure.
4. **Re-grid.** At fixed speed `p_m` is proportional to fuel, so each fired ALPHA column is a
   monotone torque-vs-`p_m` curve. Columns are interpolated linearly in `p_m`, extrapolated past
   their ends as ALPHA itself extrapolates, then linearly in speed onto the grid. The fuel table
   is speed-density in table form: `ṁ_f = p_m η_v V_d N / (120 R T_m · 14.6)`.

**Motoring and fuel cut.** ALPHA's lowest torque row carries zero fuel (fuel cut) and so has no
manifold pressure; it is dropped. The tables describe fueled operation only: fuel goes to zero
as `p_m` goes to zero, and below the lowest fired point torque is extrapolated toward
`p_m = 0` and floored at the closed-throttle torque, so the table never brakes harder than the
motored engine. ALPHA's fueled points below the closed-throttle curve (its −17 N·m row at
860–2500 rpm, scaled) are unreachable and fall under that floor. Deceleration fuel cut is a mode
switch: when the ECU cuts fuel, torque is `closed_throttle.csv` and fuel is zero.

## Emissions are assumed, not sourced

ALPHA holds no emissions, and no open engine-out map was found. `hc_gps`, `co_gps` and
`nox_gps` are an emission index (g per kg fuel) times the fuel table. The shapes follow the
textbook trends (Heywood ch. 11); the magnitudes are typical stoichiometric engine-out levels,
chosen, not measured. With `x = p_m / 95 kPa` (load) and `v` the speed fraction of the grid:

| Species | Emission index, g/kg fuel | Trend it encodes |
|---|---|---|
| NOx | `3 + 32 x² (0.8 + 0.2 v)` | rises with load (burned-gas temperature), peaks at stoichiometric high load |
| HC | `7 + 15 (1 − x)² (1 − 0.5 v)` | highest at light load and low speed (crevices, residuals, wall quench) |
| CO | `60 + 40 (1 − x)²` | low and flat at λ = 1, up at light load |

This reads as HC / CO / NOx ≈ 1.8 / 15.5 / 8.1 g/kWh at full load, 3000 rpm, and
4.2 / 25.2 / 1.4 g/kWh on the 90 km/h cruise. Full-load enrichment is not modeled (the fuel
conversion is λ = 1 throughout), so there is no enrichment CO rise. Use these tables for trends
only, and say so wherever they are shown.
