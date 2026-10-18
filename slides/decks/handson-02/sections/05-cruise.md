---
routeAlias: cruise
layout: section
---

###### Step 05 · 12 min

# Cruise: fuel and CO₂

Hold 50, 90 and 130 km/h; read liters per hour; turn them into the numbers on a car's sticker.

[page: step 05](../handson/lecture-02/#cruise)

<!--
**Say:** The session's result. Three steady speeds, three fuel figures. Step 01 predicted the 90
km/h one from the table; now the car gives it.

**Built or given:** students build one bench and run it three times with a different pedal value
and starting speed.

**Timing:** 12 minutes: 2 of theory, 3 for the bench, 5 for three runs, 2 to fill the table.

**TODO (reference):** the student `HandsOn02.MappedCarCruise`, on the car with the student's
`MapEngine`. Add the reference file to the line above.
-->

---
routeAlias: per-distance
---

## From L/h to the sticker

<div class="grid grid-cols-2 gap-8">
<div>

$$ \text{L/100 km} \;=\; \frac{\text{L/h}}{\text{km/h}} \times 100 $$

$$ \text{g CO}_2\text{/km} \;=\; \frac{\text{L/h} \times 2302}{\text{km/h}} $$

**2302 g of CO₂ per liter**: 745 g of petrol × 3.09.

</div>
<div>

> **Predict from step 01**
>
> 90 km/h: 4.11 L/h
>
> → 4.11 / 90 × 100 = **4.6 L/100 km**
>
> → 4.11 × 2302 / 90 = **105 g CO₂/km**

</div>
</div>

<!--
**Say:** The engine gives liters per hour. The car covers kilometers per hour. Divide, and the
hours cancel: liters per kilometer, times 100. CO2 the same way, with 2.3 kilograms of CO2 for
every liter burned.

**Ask the room:** a car at idle, standing still. What is its L/100 km? *(Infinite: fuel flows,
distance does not. That is why the sticker uses a driving cycle, step 07.)*
-->

---

## One bench, three runs

<div class="grid grid-cols-[1fr_1.15fr] gap-8">
<div>

**Bench `MappedCarCruise`**

- `pedal` = `Constant(k = 0.1)` → `car.pedal`; speed creeps up, lower it; down, raise it
- `initial car.body.mass.v` = 13.89, 25 or 36.11 m/s
- run **60 s**; read `car.v_kmh`, `car.fuel_lph`, `car.p_m` at the end

```julia [Julia REPL]
r = MyCar.MappedCarCruiseTransient()
plot(r; idxs = [r."car.v_kmh", r."car.fuel_lph"])
```

</div>
<div>

> **Checkpoint**
>
> | km/h | `p_m` kPa | L/h | L/100 km | g CO₂/km |
> | --: | --: | --: | --: | --: |
> | 50 | 41.9 | 1.67 | **3.3** | **77** |
> | 90 | 47.8 | 4.11 | **4.6** | **105** |
> | 130 | 60.8 | 9.14 | **7.0** | **162** |
>
> λ = 1 at all three.

Page: [Cruise](../handson/lecture-02/#cruise)

</div>
</div>

<!--
**Say:** Start the car at the speed you want and give it the pedal that holds it there. If the
speed stays put for a minute, the engine's fuel flow is the cruise consumption.

**Where the numbers come from:** the plan's predicted anchors (`lecture-02-mapped-engine-plan.md`),
computed from the maps before any model existed; reproduced from the CSVs by bilinear
interpolation at 1710, 3080 and 4450 rpm and the holding torques 18.4, 31.1 and 51.0 N·m, and
checked to the digit in the "Hands-on 02 cruise table" testset. 50 km/h is 3.34 L/100 km, so 3.3.

**Point at:** 130 against 50. 2.6 × the speed, 5.5 × the fuel per hour, 2.1 × the fuel per
kilometer. Drag goes with v².

**Point at:** `p_m`. Even at 130 the manifold is at 61 kPa: a cruising petrol engine is throttled
hard, and pumping against that vacuum is part of why it is inefficient at part load.

**Why below a real car's label:** steady speed, one gear, warm engine, no auxiliaries. Step 07
(WLTC) is where the comparison is fair.

**TODO (actions):** the pedal values that hold 50, 90 and 130 km/h, to three decimals, from
`HandsOn02.MappedCarCruise`. Once known, put them on this slide and the guide page in place of the
search, which costs several runs per speed. Confirm the speed holds within ±1 km/h over 60 s. The
car runs the student's `MapEngine`, whose pedal drives the throttle directly: on the dynamometer it
holds the three cruise torques at 0.044 / 0.103 / 0.190, so the search starts at 0.1.

**Until then, the search:** the car's time constant is about a minute (hands-on 1, step 05), so a
wrong pedal shows as a slow drift, not a jump. Steps of 0.01 are fine enough.

**TODO (screenshots):** `step05-cruise-bench.png`, `step05-cruise-90-plot.png`.
-->
