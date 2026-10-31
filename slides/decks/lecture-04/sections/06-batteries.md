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
Section 06, batteries, simply. We keep the battery as simple as it can be and still be useful: V
equals E minus I R, charge and energy, specific energy and specific power, and the deck's comparison
of chemistries. Then you build it, build 03. The figure comes from notebook 04. The deck's tour of
the individual chemistries, the fuel cells, and a more detailed cell model, with its charging,
state-of-charge estimation and balancing, are in the extra session.
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

The pack: *E* = **350 V**, *R*₀ = **0.1 Ω**.

**E is constant here.** Nothing stops SoC at zero. The extra session's cell reads *E* from
SoC.

</div>
</div>

<!--
Start with the text on the right. A cell turns chemical energy into DC electricity through two
electrodes in an electrolyte; a battery is many cells in series and in parallel. The Leaf ZE1 has
192 cells, wired as 96 in series of 2 in parallel: 96s2p.

The model is the formula: the terminal voltage v equals E minus R0 times i. E is the open-circuit
voltage, the voltage the chemistry sets when no current flows, in volts. i is the discharge current
in amperes, positive when the battery delivers. R0 is the internal resistance in ohms. Current has
to cross the electrolyte, the electrodes and every busbar between the cells, and that costs a
voltage R0 times i, which is lost as heat. So the terminal voltage sags the moment a load comes on.

Our pack has E equal to 350 volts and R0 equal to 0.1 ohm. Where does 0.1 come from? A ZE1-class
cell of about 56 ampere-hours has about 2 milliohms, and 96 of them in series, 2 in parallel, give
about 0.1 ohm. Idaho National Laboratory measured 0.11 to 0.145 ohm on a 2013 Leaf pack at mid
charge, and about half again near empty.

The figure is notebook 04, section 3: the library's twin of the bench you build in step 03. The pack
stands open for one minute, then carries a constant load for half an hour. The horizontal axis is
time in minutes. Top panel: the terminal voltage in volts, with the gray dashed line at E, 350
volts. Bottom panel: the state of charge, 1 for full and 0 for empty. Blue is a 100 ampere load, a
car cruising; orange is 330 amperes, about the machine's full 110 kilowatts.

At 100 amperes the voltage drops at once from 350 to 340.0, 10 volts, and stays there, because
nothing in the model changes E. At 330 amperes it drops 33 volts, to 317.0. The power at the
terminals is then 317 times 330, 104.6 kilowatts, and the power lost in R0, R0 i squared, is 10.9
kilowatts.

The bottom panel is the trap, and the last line of the slide: E is constant here, and nothing stops
the state of charge at zero. It falls on a straight line: at 100 amperes from 0.9 to 0.4625. At 330
amperes it passes zero after about 19 minutes and ends at minus 0.54. Nothing in v equals E minus R0
i knows that the pack is empty. A real pack's voltage collapses near empty, to 296 volts at 3
percent in Idaho's test of a 2013 Leaf pack, and its battery management system cuts the current long
before. The extra session's cell model reads E from the state of charge and fixes this.
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
current. **Coulomb counting**, whose drift the extra session corrects:

$$
\frac{d\,SoC}{dt} = -\frac{i}{Q_{nom}}
$$

100 A for half an hour is 50 A·h: **0.4375** of the pack.

</div>
</div>

<!--
Charge and energy. On the left, capacity, from the deck. Capacity is charge, measured in
ampere-hours: a 10 ampere-hour cell gives 1 ampere for 10 hours, ideally. In practice it gives less
at high current, because of side reactions. One ampere-hour is one ampere for 3600 seconds, 3600
coulombs.

Energy is that charge times the voltage it is delivered at. So the first formula: the nominal charge
of our pack, Q nom, is 40 kilowatt-hours divided by 350 volts, 114.3 ampere-hours, which is 411 429
coulombs. And 1 watt-hour, a watt for an hour, is 3600 joules.

On the right, the state of charge. Nothing in a battery measures it directly. The battery management
system counts it: it measures the current and integrates it. That is coulomb counting, the second
formula: the rate of change of SoC equals minus the current i over the nominal charge Q nom, in
coulombs, per second. Discharging, i is positive and SoC falls; charging, it rises. Our model's SoC
is exactly that integral. A real count drifts, and the extra session shows how a battery management
system corrects it.

The number at the bottom is build 03's checkpoint, worked out: 100 amperes for half an hour is 50
ampere-hours, and 50 over 114.3 is 0.4375 of the pack. Starting at 0.9, the state of charge ends at
0.4625.
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

<div class="handson">In the model: charge efficiency 100 %, energy efficiency set by R₀ alone.
Build 03 measures it at 100 A.</div>

</div>
</div>

<!--
Three numbers a battery designer trades, from the deck. Specific energy: watt-hours per kilogram of
battery. Energy density: watt-hours per liter. And specific power: watts per kilogram. Specific
energy decides how much range each kilogram of battery buys; specific power decides how fast it can
give energy out and take it back in, for acceleration and for regenerative braking.

A cell built for energy stores a lot and gives it out slowly; a cell built for power gives it fast
and stores less. High specific power normally costs specific energy.

On the right, the deck's two efficiencies. Charge efficiency is the charge you get back over the
charge you put in, always below 100 percent. Energy efficiency is the energy you get back over the
energy needed to recharge, and it includes the voltage drop across the internal resistance, both
ways. The deck also lists self-discharge, temperature and cooling, and the number of deep cycles a
battery survives. Those are real, and they are outside our model, which runs at a warm operating
temperature.

The green box is our model. Its charge efficiency is exactly 100 percent, because coulomb counting
has no side reactions, and its energy efficiency is set by R0 alone. Build 03 measures it at 100
amperes for half an hour: E, 350 volts, times 50 ampere-hours is 17.5 kilowatt-hours out of the
cells; the terminals, at 340 volts, deliver 340 volts times 100 amperes for half an hour, 17.0
kilowatt-hours; and the difference, 0.5 kilowatt-hours, is R0 i squared, 1 kilowatt for half an
hour, heating the pack. That is 97 percent. For comparison, Argonne measured the 2013 Leaf's battery
round trip at 95 to 98 percent.
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
The deck's comparison of chemistries, kept as the deck has it, after Larminie and Lowry. Six battery
types in rows. The columns are specific energy in watt-hours per kilogram, energy density in
watt-hours per liter, specific power in watts per kilogram, and cost in arbitrary units. As the
caption says, every figure is a broad guideline only.

Lead acid: 30 watt-hours per kilogram, 75 per liter, 250 watts per kilogram, cost 0.5.
Nickel-cadmium: 50, 80, 150, cost 1.5. Nickel-metal hydride: 65, 150, 200, cost 2. The Zebra
battery, a sodium battery: 100, 150, 150, cost 2. Lithium-ion: 150, 150, 300, cost 3. Zinc-air: 230,
270, 105, cost unknown. Lithium-ion is the only one high in both specific energy and specific power;
zinc-air stores more, but gives it out slowly.

The deck's conclusions, on the right. Lead acid suits only short-range vehicles. Lithium has the
energy density for medium range and charges quickly, which makes it ideal for hybrids. And none of
them yet lets a pure electric car match an engine car for range and versatility, though specific
energy was predicted to rise.

The Leaf ZE1's pack is lithium-ion, 40 kilowatt-hours, with nickel-manganese-cobalt cells according
to the EV Database, a secondary source. The first-generation Leaf of 2012 used a lithium manganese
oxide chemistry.
-->

---
routeAlias: build-battery
---

## Build 03: the battery

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<img src="/img/lecture-04/step03-battery-discharge.png" class="mx-auto" style="max-height: 21rem" alt="The finished BatteryDischarge in Studio: load_profile into the top of load; load across battery, p to p on the left and n to n on the right; battery.n to ground."/>

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
Build 03: the battery. On the left, the finished bench in Studio. A step block named load profile
feeds the top of a current source named load. The load sits across the battery, p to p on the left
and n to n on the right, and the battery's n goes to ground.

The steps, in the italic line. First, a new component `Battery`: paste the code from the guide. It
has two pins, p and n, and one output, SoC. Inside are the two equations of the last slides: v
equals E minus R0 i, and the coulomb counter, the derivative of SoC equals minus i over Q nom. Its
parameters are named E, R0, Q nom and SoC0 on purpose: the extra session's more detailed cell keeps
those names and replaces this one without rewiring. Second, a new component `BatteryDischarge`, with
one parameter, I load, 100 amperes. The load profile is a `Step` block that switches I load on at 60
seconds. The load is an ideal current source: it forces exactly that current out of the battery's
positive terminal, whatever the voltage, as a motor drive does when it is asked for a fixed torque.
Add the ground. Third, the analysis `BatteryDischargeTransient`, 1860 seconds long, with a tstop at
60 so that the solver lands exactly on the load step; without it the solver strides across the
switch-on, misses about half a second of current, and the final state of charge comes out slightly
off. Then click Run Analysis once and plot.

The snippet plots the terminal voltage, the current and the state of charge in three panels, and
reads the final state of charge. The last line runs the full-power case, 330 amperes.

The first green box is the default, 100 amperes. The battery voltage is 350 volts for the first
minute, then 340 from 60 seconds on: a sag of exactly 10 volts, R0 times i, for as long as the
current flows. The state of charge stays at 0.9 until the load comes on, then falls on a straight
line to 0.4625 at 1860 seconds: 50 of the 114.3 ampere-hours. Of the 17.5 kilowatt-hours that left
the cells, 17.0 reached the load and 0.5 heated R0.

The second green box, two variations. Minus 20 amperes is charging: the terminals rise above E, to
352 volts, because a charger has to push against both E and R0, and the state of charge climbs to
0.9875. And 330 amperes: 317 volts, 104.6 kilowatts at the terminals, 10.9 kilowatts lost in R0, and
the state of charge ends at minus 0.544. Ask yourselves why nothing stops it. E is constant, and
nothing in the model knows that the pack is empty.
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
Section 06 in five lines. A pack is cells in series and in parallel, and its terminal voltage is v
equals E minus R0 i; the sag is lost as heat. Capacity is charge, in ampere-hours, and energy is
charge times voltage: 40 kilowatt-hours at 350 volts is 114.3 ampere-hours. The state of charge is
counted from the current, by coulomb counting. Specific energy and specific power trade against each
other, and lithium-ion made the battery-electric car practical. And on your bench: a 10 volt sag at
100 amperes, and the state of charge from 0.9 to 0.4625 in half an hour.

Three links are built: the machine, the converter and the battery. Next they go into the planar car,
and the machine learns to brake.
-->
