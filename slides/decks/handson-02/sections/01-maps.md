---
routeAlias: maps
layout: section
---

###### Step 01 · 12 min

# Read the maps

Speed down the side, manifold pressure across the top: find 90 km/h, read its fuel.

[page: step 01](../handson/lecture-02/#maps) · data `data/engine/torque_Nm.csv`, `fuel_gps.csv`, `lambda.csv`

<!--
**Say:** Before any model, the data. Three tables, all on the same grid, measured on a test bench
by the US EPA and scaled to our 1.5 liter engine. We find the 90 km/h cruise point in them by
hand. Step 05 measures the same point in the car; if the two agree, the car is right.

**Timing:** 12 minutes: 4 of theory (the next slide), 8 in the REPL. This step runs while
step 00's download finishes for slow machines.
-->

---
routeAlias: speed-density
---

## Speed × manifold pressure

<div class="grid grid-cols-2 gap-8">
<div>

The ECU knows two things about the engine's state at every instant:

- **Engine speed *N*** — from the crankshaft sensor (lecture section 04).
- **Manifold pressure *p<sub>m</sub>*** — from the MAP sensor. It says how full each cylinder
  gets: more pressure, more air, more fuel, more torque.

Every map is a grid over those two: 26 speeds (500–6750 rpm) × 43 pressures (0–105 kPa).

</div>
<div>

| Map | Gives | Unit |
| --- | --- | --- |
| `torque_Nm` | brake torque *T<sub>e</sub>* | N·m |
| `fuel_gps` | fuel flow *ṁ<sub>f</sub>* | g/s |
| `lambda` | air-fuel ratio / 14.6 | — |

> **Why pressure, not pedal?**
>
> The pedal says what the driver wants. The pressure says what the cylinders actually get —
> a moment later, once the manifold has filled.

</div>
</div>

<!--
**Say:** Two numbers fix the engine's state: how fast it turns and how much air each cylinder
gets. The air per cylinder is set by the pressure in the manifold, because the cylinder fills
from it at that pressure. This is called speed-density, and it is how an ECU without an air-mass
meter works.

**Point at:** the callout. That "moment later" is step 02.

**Where the maps come from:** US EPA ALPHA package, 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L at
constant BMEP and BSFC; re-gridded from a torque axis to a manifold-pressure axis by
`scripts/alpha_engine_maps.jl`. Citation and every assumption in `data/engine/README.md`.

**They get wrong:** reading kPa as gauge pressure. These are absolute: 101 kPa is wide open, 33 kPa
at idle is a strong vacuum.
-->

---
routeAlias: cruise-on-paper
---

## 90 km/h, from the table alone

<div class="grid grid-cols-3 gap-6">
<div>

#### Where on the map?

Lecture 1 (step 05): 90 km/h is **3080 rpm** and needs **31.1 N·m**.

The 3000 rpm row of `torque_Nm` crosses 31.1 between 47.5 kPa (30.7) and 50 kPa (35.6):

- ***p<sub>m</sub>* ≈ 47.7 kPa**

</div>
<div>

#### How much fuel?

Same row, same pressure, in `fuel_gps`: between 0.816 and 0.895 g/s.

- **≈ 0.82 g/s**
- λ there: **1.00**

</div>
<div>

#### Per 100 km

0.82 g/s × 3600 / 745 g/L = 4.0 L/h

4.0 L/h ÷ 90 km/h × 100

- **≈ 4.4 L/100 km**
- at 3080 rpm exactly: **4.6**

</div>
</div>

<!--
**Do it on the board, one column at a time.**

1. **Where:** 90 km/h = 25 m/s; ÷ 0.31 × 4 × 60/2π = 3080 rpm. Holding torque 31.08 N·m (Lecture 1
   step 05: drag 236 N + rolling 165 N = 401 N; × 0.31 / 4). Use the 3000 rpm row, the nearest.
   30.66 at 47.5 kPa, 35.63 at 50 kPa; (31.08 − 30.66) / 4.97 × 2.5 = 0.21 → 47.7 kPa.
2. **Fuel:** 0.816 + 0.085 × (0.895 − 0.816) = 0.823 g/s.
3. **Per distance:** 0.823 × 3.6 / 0.745 = 3.98 L/h; ÷ 90 × 100 = 4.4 L/100 km. Interpolating
   between the 3000 and 3250 rpm rows to 3080 rpm gives 47.8 kPa and 0.849 g/s = 4.10 L/h =
   **4.56 L/100 km**, the plan's predicted anchor; CO2 3.09 × 0.849 / 25 m/s × 1000 = **105 g/km**.

**Say:** We have not built anything, and we already know what the car burns at 90. Step 05 checks
it.

**Lecturer's choice:** whether to reveal the 50 and 130 km/h numbers now (3.4 and 7.0 L/100 km)
or let step 05 find them. The guide shows only 90 km/h.
-->

---

## Plot the maps

<div class="grid grid-cols-[1.3fr_1fr] gap-8">
<div>

```julia [Julia REPL]
using DelimitedFiles, Plots, VehicleSystemsComponents
dir = joinpath(pkgdir(VehicleSystemsComponents), "data", "engine")
function engine_map(name)
    M, head = readdlm(joinpath(dir, name), ','; header = true)
    return parse.(Float64, vec(head)[2:end]), M[:, 1], M[:, 2:end]
end
kpa, rpm, T = engine_map("torque_Nm.csv")
heatmap(kpa, rpm, T; xlabel = "p_m [kPa]", ylabel = "N [rpm]")
```

Then `fuel_gps.csv` and `lambda.csv` the same way, and
`T[rpm .== 3000, :]` for the row.

</div>
<div>

> **Checkpoint**
>
> - torque up to **≈ 150 N·m** near 4000 rpm, 100 kPa
> - 3000 rpm row: 31.1 N·m at **≈ 47.7 kPa**
> - fuel there **≈ 0.82 g/s**
> - λ = **1** up to about 80 kPa; **0.87** at 3000 rpm, 100 kPa

</div>
</div>

Page: [Read the maps](../handson/lecture-02/#maps)

<!--
**Say:** Torque rises across the map with pressure, almost in a straight line: more air, more
torque. Fuel does the same. Lambda is 1 almost everywhere: the ECU holds the mixture at
stoichiometric for the catalyst, the λ loop of lecture section 07. Only near full load does it
richen, to cool the exhaust.

**Point at:** the torque map's left edge. At low pressure torque is negative: the engine is
pumping air against a vacuum, and that costs work. Step 06 uses it to brake the car.

**They get wrong:** `heatmap(rpm, kpa, T)`, axes swapped: Plots wants x, y, then a matrix with one
row per y. The rows of the file are speeds, so speeds go on y.

**Full-load cap, for step 03:** the map holds torque up to 105 kPa, above what the engine can
reach. `full_load.csv` holds the real ceiling per speed, 148.4 N·m at 3000 rpm against the map's
163 at 100 kPa.

**TODO (screenshot):** `step01-torque-map.png` and `step01-fuel-map.png`, with the 90 km/h point
marked. Not on this slide yet: the room sees their own.
-->
