---
routeAlias: batteries
layout: section
---

###### Section 06

# Batteries, simply

V = E − IR, charge and energy, specific energy and power, and the deck's comparison of
chemistries.

`notebooks/lecture04/04-machine-battery-regen.pluto.jl`

<!--
Budget: about 18 minutes, of which build 03 takes about 8: cells and V = E − IR 3, A·h and W·h 2,
specific energy and power 3, the summary table 2, build 03 8. Deck 8 slides 3 to 6 and 14 to 16.
The chemistry tour, slides 7 to 13, and the fuel cells are in the extra pack, with the Thevenin
cell, CC-CV charging, SoC estimation and balancing.
-->

---
routeAlias: v-equals-e-minus-ir
class: big-figure
---

## V = E − R₀ i

<div class="grid grid-cols-[1.55fr_1fr] gap-6 items-center">
<div>

![Terminal voltage and state of charge of the 350 V, 0.1 Ω pack, open circuit for a minute and then a constant load for half an hour. At 100 A the voltage drops at once from 350 to 340.0 V and stays there; SoC falls on a straight line from 0.9 to 0.4625. At 330 A the voltage drops to 317.0 V and SoC passes zero after about 19 minutes, ending at −0.5438.](/figures/06-battery-discharge.svg)

</div>
<div class="text-[0.95rem]">

A cell turns chemical energy into DC through two electrodes in an electrolyte (deck); a battery
is cells in series and parallel. The Leaf ZE1: **192 cells, 96s2p**.

$$
v = E - R_0\, i
$$

Current crosses the electrolyte, the electrodes and every busbar: **R₀ · i** is lost as heat, and
the terminal voltage sags the moment the load comes on.

**E is constant here.** Nothing stops SoC at zero.

</div>
</div>

<!--
Deck 8 slides 3 and 4. The figure is notebook 04 section 3, the library's `BatteryTransient`, the
bench of build 03: open circuit for a minute, then a constant load for 30 minutes. Blue is 100
amperes, a car cruising; red 330 amperes, about the machine's 110 kW.

The pack: E, the open-circuit voltage, 350 volts, constant; R0 0.1 ohm, about 2 milliohms per
56 ampere-hour cell, 96 in series over 2 in parallel. INL measured 0.11 to 0.145 ohm on a 2013
Leaf pack at mid charge, and about 50 percent more near empty.

At 100 amperes the terminal voltage drops 10 volts the instant the load comes on, and stays
there: nothing in the model changes E. At 330 amperes the sag is 33 volts. The power the load
gets is v times i, the power lost is R0 i squared: at 330 amperes 104.6 kW reach the terminals
and 10.9 kW heat the pack.

The bottom panel is the trap. SoC falls in a straight line, and at 330 amperes it passes zero
after 19 minutes and goes on to minus 0.54: nothing in V = E minus I R knows the pack is empty. A
real pack's voltage collapses near empty, to 296 volts at 3 percent in INL's test, and the battery
management system cuts the current long before. The extra pack's cell reads E from SoC and fixes
this.
-->

---
routeAlias: charge-and-energy
---

## Charge and energy: A·h and W·h

<div class="grid grid-cols-2 gap-8">
<div>

**Capacity** is charge (deck): a 10 A·h cell gives 1 A for 10 h, ideally. In practice less at
high current: side reactions.

**Energy** is that charge times the voltage it is delivered at:

$$
Q_{nom} = \frac{40\ \text{kWh}}{350\ \text{V}} = 114.3\ \text{A·h}
\qquad 1\ \text{Wh} = 3600\ \text{J}
$$

</div>
<div>

**State of charge** is counted, not measured: the battery management system integrates the
current. **Coulomb counting:**

$$
\frac{d\,SoC}{dt} = -\frac{i}{Q_{nom}}
$$

100 A for half an hour is 50 A·h: **0.4375** of the pack.

</div>
</div>

<!--
Deck 8 slide 4. The ampere-hour is a unit of charge: 1 ampere for 1 hour is 3600 coulombs. The
deck's warning: a 10 ampere-hour cell does not give 10 amperes for exactly an hour, because side
reactions grow with the current. The model ignores that.

Energy is charge times voltage: 40 kWh at 350 volts is 114.3 ampere-hours, 411 429 coulombs.

Nothing in a battery measures its state of charge directly. The BMS counts it: it measures the
current and integrates it, the charge taken out over the charge the pack holds. That is the
second equation, and the model's `SoC` is exactly that. Real systems correct the count's drift
with the voltage at rest; the extra pack does that.

The checkpoint arithmetic: 100 amperes for 0.5 hours is 50 ampere-hours, 50 over 114.29 is
0.4375 of the pack: SoC from 0.9 to 0.4625.
-->

---
routeAlias: specific-energy
---

## Specific energy, specific power, efficiency

<div class="grid grid-cols-2 gap-8">
<div>

**Specific energy** (deck): Wh per kilogram of battery. **Energy density:** Wh per liter.
**Specific power:** W per kilogram.

A cell built for energy stores a lot and gives it slowly; one built for power gives it fast and
stores less. **High specific power normally costs specific energy.**

</div>
<div>

**Charge efficiency** (deck): the charge you get back over the charge you put in, always below
100 %. **Energy efficiency:** the energy back over the energy needed to recharge.

**Also:** self-discharge, temperature and cooling, the number of deep cycles.

<div class="handson">Step 03 at 100 A: of the 17.5 kWh that left the cells, <b>17.0 kWh</b>
reached the load, <b>0.5 kWh</b> heated R₀: 97 %.</div>

</div>
</div>

<!--
Deck 8 slides 5 and 6. The three densities are what a car designer trades. Specific energy decides
range per kilogram, specific power decides acceleration and regen per kilogram. They pull against
each other: thin electrodes give power, thick ones give energy. A hybrid's small pack is built for
power, a battery-electric car's for energy.

The efficiency definitions: charge efficiency is ampere-hours out over in; energy efficiency is
watt-hours out over in, and also includes the voltage drop across R0 both ways. In our model the
charge efficiency is 100 percent, coulomb counting with no side reactions, and the energy
efficiency is set by R0 alone.

The green box is step 03's number: at 100 amperes, 350 volts times 50 ampere-hours is 17.5 kWh
out of the cells, 340 volts times 100 amperes for half an hour is 17.0 at the terminals, and 0.5
kWh, 1 kW for half an hour, heated the pack. Argonne measured the 2013 Leaf's battery round trip
at 95 to 98 percent.

Self-discharge, temperature, cycle life: real, and outside the model. No thermal model in this
lecture: every number is at a warm operating temperature.
-->

---
routeAlias: battery-table
---

## The deck's comparison of chemistries

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div class="tight">

| Battery | Wh/kg | Wh/L | W/kg | Cost |
|---|---:|---:|---:|---:|
| Lead acid | 30 | 75 | 250 | 0.5 |
| NiCad | 50 | 80 | 150 | 1.5 |
| NiMH | 65 | 150 | 200 | 2 |
| Zebra | 100 | 150 | 150 | 2 |
| Li ion | 150 | 150 | 300 | 3 |
| Zinc–air | 230 | 270 | 105 | ? |

<div class="caption">Deck 8, after Larminie and Lowry. Cost in arbitrary units; every figure a
broad guideline only.</div>

</div>
<div>

**The deck's conclusions**

- Lead acid suits only short-range vehicles.
- Lithium has the energy density for medium range and charges quickly: ideal for hybrids.
- None yet lets a pure EV match an engine for range and versatility; specific energy was
  predicted to rise.

The Leaf ZE1's pack is lithium-ion: NMC cells, 40 kWh.

</div>
</div>

<!--
Deck 8 slides 14 to 16, the summary table, kept as the deck has it. The numbers are Larminie and
Lowry's guideline values from the early 2000s and the cost column is relative; the slide says so.
Lithium-ion has moved on since: its specific energy has risen well above the 150 in the table, as
the deck's last line predicted. That progress is what made 40 kWh in a family car possible.

The deck's chemistry tour, lead acid, nickel-cadmium, sodium, lithium, metal-air, is in the
extra pack.

The Leaf's pack: 192 AESC pouch cells, nickel-manganese-cobalt cathode chemistry per EV Database,
a secondary source; the 2012 car used a manganese-spinel chemistry.
-->

---
routeAlias: build-battery
---

## Build 03: the battery

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<div class="placeholder">

Screenshot to capture: `images/lecture-04/step03-battery-discharge.png`, the finished
`BatteryDischarge`: `load_profile` → `load` CurrentSource, `battery`, `ground`

</div>

*New `Battery`: paste from the guide · new `BatteryDischarge`: parameter `I_load` 100 ·
`load_profile` Step at 60 s → `load` CurrentSource across `battery` · `ground` ·
`BatteryDischargeTransient`, 1860 s, tstops at 60 · ▷ once, then plot*

[page: step 03](../lecture/lecture-04/#step-03) · reference `dyad/HandsOn04/BatteryDischarge.dyad`

</div>
<div class="stack">

```julia
r = MyCar.BatteryDischargeTransient();
plot(r; idxs = [r."battery.v", r."battery.i",
     r."battery.SoC"], layout = (3, 1))
r.sol[r."battery.SoC"][end]
r = MyCar.BatteryDischargeTransient(I_load = 330.0);
```

<div class="handson">✓ 100 A: <code>battery.v</code> <b>350 V</b> for the first minute, <b>340 V</b>
from 60 s: a sag of <b>10 V</b> · <code>battery.SoC</code> <b>0.9</b> → <b>0.4625</b> at 1860 s ·
<b>17.0 kWh</b> to the load, <b>0.5 kWh</b> in R₀</div>

<div class="handson">✓ −20 A, charging: <b>352 V</b>, SoC to <b>0.9875</b> · 330 A: <b>317 V</b>,
104.6 kW at the terminals, 10.9 kW in R₀, SoC ends at <b>−0.544</b></div>

</div>
</div>

<!--
Eight minutes: one paste, a bench of four blocks, three runs.

1. `Battery`: paste from the guide. Pins p and n, an output SoC; inside, a constant voltage
   source E behind a resistor R0, and the coulomb counter, `der(SoC) = -i / Q_nom`. The
   parameters are named for the extra pack's Thevenin cell, which replaces this one without
   rewiring: E, R0, Q_nom, SoC0.
2. `BatteryDischarge`: a step of `I_load` at 60 seconds drives a current source across the
   battery. The analysis runs 1860 seconds with a tstop at 60, so the counted charge is exact.
3. Run, then the snippet: voltage, current and SoC in three panels.

Expected, from `HandsOn04.BatteryDischargeTransient`: 350 volts for the first minute, 340 from
60 seconds, the sag R0 i = 10 volts, exactly, as long as the current flows. SoC 0.9 until the
load, then a straight line to 0.4625 at 1860 seconds: 50 ampere-hours out of 114.3. Of the 17.5
kWh that left the cells, 17.0 reached the load and 0.5 heated R0.

Minus 20 amperes, charging: the terminals rise above E, to 352 volts: a charger has to push
against E and R0 both. SoC climbs to 0.9875.

330 amperes: 317 volts, 104.6 kW at the terminals, 10.9 kW lost. SoC passes zero after 19
minutes and ends at minus 0.544. Ask the room why nothing stops it: E is constant, and nothing in
the model knows the pack is empty.

Testsets: `test/battery_plausibility.jl`.
-->

---

## Summary of section 06

- A pack is cells in series and parallel: **v = E − R₀ i**. The sag is lost as heat.
- Capacity is charge, A·h; energy is charge times voltage: **40 kWh at 350 V is 114.3 A·h**.
- SoC is counted from the current: coulomb counting.
- Specific energy and specific power trade against each other; lithium-ion made the
  battery-electric car practical.
- On your bench: **10 V** of sag at 100 A, SoC **0.9 → 0.4625** in half an hour.

### Next: put the chain in the car, and brake with it. <Link to="car-and-regen">→ 07, the car and regen</Link>

<!--
One minute. The three links are built: machine, converter, battery. Next they go into the planar
car, and the machine learns to brake.
-->
