---
routeAlias: fuel-cells
layout: section
---

###### Section 05

# Fuel cells

Deck 8's principles and losses as one polarization curve, the voltage as the efficiency, the stack,
and the balance of plant around it.

<img class="hero" src="/photos/05-mirai-stack.jpg" alt="The first-generation Toyota Mirai fuel-cell stack in its grey cast housing, seen from above through the cut-away blue floor of a show car, a label Fuel Cell Stack on top."/>

<div class="caption">Mirai (gen 1) stack · Mariordo, CC BY-SA 4.0</div>

<!--
Welcome back. Before the break: the plug, 18 to 43 minutes. Now the nozzle. A fuel-cell car is an
electric car that makes its electricity on board from hydrogen, instead of carrying a big battery.
The polarization curve shows what the hydrogen turns into and how efficiently. Then the stack, and
the machines around it.

*[show photo]* The first Mirai's stack under a cut-away show car. Photograph by Mariordo, Wikimedia
Commons.
-->

---
routeAlias: pem-principle
---

## How a PEM fuel cell works

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Cross-section of one PEM fuel cell, layers from left to right: anode flow plate with gas channels, gas diffusion layer, catalyst layer, the membrane, catalyst layer, gas diffusion layer, cathode flow plate. Hydrogen enters the anode plate from the left; air enters the cathode plate from the right, and water leaves it with the spent air. Protons, H plus, cross the membrane from anode to cathode. Electrons leave the anode plate through an external wire, pass through the load and return to the cathode plate. Below the anode: H2 gives 2 H plus and 2 electrons. Below the cathode: half O2 plus 2 H plus plus 2 electrons gives H2O.](/diagrams/05-pem-cell.svg)

<div class="caption">Orange: electrons · blue: gases · black: protons</div>

</div>
<div>

**Anode:** H₂ → 2H⁺ + 2e⁻

**Cathode:** ½ O₂ + 2H⁺ + 2e⁻ → H₂O

**Ideal voltage:**

- reversible, 25 °C: **1.229 V**
- all of the LHV as electricity: **1.253 V**
- all of the HHV: **1.481 V**

Two electrons per H₂, through every cell in series.

<div class="caption text-left">[PUKRUSHPAN-JDSMC-2004] · LHV, HHV: derived, *E* = Δ*H* / 2*F*
(<code>pem-polarization.md</code> §5)</div>

</div>
</div>

<!--
*[show figure]* One cell of a proton exchange membrane fuel cell, PEM, the kind every fuel-cell car
uses. A platinum catalyst splits hydrogen into protons and electrons. The membrane lets only the
protons through, so the electrons take the outside circuit: our current. At the cathode, air's
oxygen meets both, making water. A battery that never runs flat, as long as you feed it.

On the right, the ideal voltages. 1.229 volts is the reversible voltage, the theoretical maximum.
1.253 is hydrogen's lower heating value over two Faraday constants; 1.481 uses the higher heating
value. A real cell runs well below all three, as the next slide shows.
-->

---
routeAlias: fuel-cell-types
skipInCut: true
---

## The fuel-cell types, briefly

<div class="tight">

| Type | Electrolyte | In vehicles |
|---|---|---|
| **PEM** (proton exchange membrane) | polymer membrane | fuel-cell cars: the Mirai's FCB130 |
| AFC (alkaline) | potassium hydroxide | space; needs CO₂-free air |
| PAFC (phosphoric acid) | phosphoric acid | stationary |
| MCFC (molten carbonate) | molten carbonate salt | stationary, high temperature |
| SOFC (solid oxide) | ceramic | stationary, high temperature |

</div>

<!--
Deck 8 lists five types of fuel cell, each named after its electrolyte. Only the first matters for
cars: the proton exchange membrane, a thin plastic film. The Mirai's spec sheet calls its stack
polymer electrolyte, and the model we use next is a PEM stack too.

*[ask]* Why PEM, for a car? Think of what a car asks of its power source. *[pause]* It must start in
seconds on a cold morning, follow the driver's foot, and fit under the floor. The PEM cell runs
cool, near 80 degrees in the model we use. So it starts quickly. It is compact, and it changes power
fast.

The other types suit other uses. The alkaline cell was used in space. It needs air free of carbon
dioxide, which a car on a road cannot get. The phosphoric acid cell is a stationary power plant.
Molten carbonate and solid oxide cells run hot. That suits a building or factory that runs for
months and uses the heat, not a car parked most of the day. Deck 8's table gives their operating
temperatures and efficiencies if you want to compare.

PEM cells have improved fast. Toyota says the first Mirai's stack reached 2.4 times the current
density of its 2008 model, that is, current per square centimeter. Three changes did it: finer gas
channels, a new platinum-cobalt catalyst, and a thinner membrane. The second Mirai raised the power
per cell by another 26 percent, so it needed 330 cells instead of 370. Argonne National Laboratory
measured the first Mirai's stack at 3.1 kilowatts per liter. Toyota quotes 5.4 for the second,
without the end plates.

From here on, a fuel cell means a PEM cell. The next slide shows how it behaves.
-->

---
routeAlias: polarization-curve
---

## The polarization curve

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-start">
<div>

<img src="/figures/05-polarization.svg" alt="Cell voltage against current density, 0 to 2.2 A/cm². Black: the P2000 model at 80 °C and 2.5 bar, 0.950 V at zero current, 0.822 V at 0.1, 0.690 at 0.5, 0.583 at 1.0, 0.430 at 1.5 and 0.09 at 2.2 A/cm². Shaded between the 0.950 V line and the curve: the activation loss, saturating at 0.178 V; the ohmic loss, 0.1575 Ω·cm² times the current density; and the concentration loss, growing toward 2.2 A/cm². Red dots with ±0.014 V bars: the 2017 Mirai stack per cell, ANL: 0.85 V at 0.05, 0.78 at 0.32, 0.74 at 0.95, 0.71 at 1.27, 0.65 at 1.64 and 0.68 at about 1.8 A/cm². A right-hand scale gives the efficiency η_LHV = V / 1.253 V, 0 to 70 %. Labels on the curve, after Larminie and Lowry: a rapid initial fall, a fairly linear middle, and a voltage that falls faster at high current."/>

<div class="caption">Formula plot: [PUKRUSHPAN-2003] with b₁₁ = 0.005139, the recommended slide curve, derived ·
dots: [ANL-MIRAI-2018], read from figure, on ANL's assumed 237 cm² · right scale: η<sub>LHV</sub> =
<i>V</i> / 1.253 V at μ<sub>f</sub> = 1 · shape labels: deck 8, after Larminie and Lowry.</div>

</div>
<div class="text-[0.85rem]">

$$
\begin{aligned}
V_\text{cell} = 0.950 &- 0.178\,(1 - e^{-10 i}) \\
&- 0.1575\, i - i\,(0.390\, i / 2.2)^2
\end{aligned}
$$

activation · ohmic · concentration, *i* in A/cm²

<div class="tight">

| *i*, A/cm² | 0.1 | 0.5 | 1.0 | 1.5 |
|---|---:|---:|---:|---:|
| *V*, V | 0.822 | 0.690 | 0.583 | 0.430 |
| *p*, W/cm² | 0.08 | 0.35 | 0.58 | 0.64 |

</div>

At ≈ 1 A/cm²: **Mirai gen 1 ≈ 0.74 V** vs **P2000 model 0.58 V** — mostly the thinner membrane.

<div class="caption text-left">Model: [PUKRUSHPAN-2003] with b₁₁ = 0.005139, derived · Mirai:
[ANL-MIRAI-2018], read from figure</div>

</div>
</div>

<!--
The polarization curve shows the cell voltage at each current density, the current per square
centimeter. The black curve is Pukrushpan's model, fitted to Ford's P2000 stack.

It starts at 0.950 volts minus three shaded losses. Activation loss, the voltage spent to drive the
reaction at the catalyst, levels off at 0.178 volts. Ohmic loss is the membrane's resistance, a
straight line. Concentration loss: at high current gas cannot reach the catalyst, and the curve
drops toward 2.2 amperes per square centimeter.

The table: 0.82 volts at 0.1, 0.69 at 0.5, 0.58 at 1. Power, voltage times current, peaks at about
1.4. Beyond that, more current gives less power.

*[show figure]* The red dots are the real 2017 Mirai, measured by Argonne National Laboratory: 0.74
volts at about 1 ampere per square centimeter, against the model's 0.58. Most of the gap is ohmic.
Toyota names a thinner membrane as one reason.

*[ask]* The right-hand scale says efficiency. Where is the cell most efficient? *[pause]* At the
left: light load. The next slide says why.
-->

---
routeAlias: voltage-is-efficiency
---

## The voltage is the efficiency

<div class="grid grid-cols-[1fr_1.5fr] gap-8 items-start">
<div>

$$
\eta_\text{LHV} = \mu_f\, \frac{V_\text{cell}}{1.253\ \text{V}}
$$

*μ*<sub>f</sub>: fuel utilization, the share of the hydrogen that reacts.

**Low load is efficient**, high load is powerful: the opposite of an engine.

**Measured, 2017 Mirai (ANL):**

- stack peak efficiency **66.0 %**
- system peak efficiency **63.7 %**
- 66.0 % ↔ *μ*<sub>f</sub> *V* ≈ **0.83 V**, matching the 0.78–0.85 V cells at low load

<div class="caption text-left">[LOHSE-BUSCH-IJHE-2020] verified</div>

</div>
<div>

![Three energy-flow (Sankey) diagrams, one per cell voltage, each starting from 100 % of the hydrogen's lower heating value and splitting into electricity (orange) and heat (red), with η = V / 1.253 V and all fuel reacting. 0.6 V: electricity 47.9 %, heat 52.1 %, 62.7 g H₂ per kWh. 0.7 V: 55.9 % and 44.1 %, 53.7 g/kWh. 0.8 V: 63.8 % and 36.2 %, 47.0 g/kWh.](/diagrams/05-cell-sankey.svg)

<div class="caption">Deck 8, after Larminie and Lowry, redrawn as energy flows · η<sub>LHV</sub> = μ<sub>f</sub> V / 1.253 V
at μ<sub>f</sub> = 1 and g H₂/kWh from Faraday's law [<code>pem-polarization.md</code> §5], derived.</div>

</div>
</div>

<!--
A fuel cell's efficiency is its voltage. Every hydrogen molecule gives two electrons, whatever the
voltage, so the energy per molecule is proportional to the voltage. Divide by 1.253 volts, and
multiply by the fuel utilization.

*[show figure]* At 0.6, 0.7 and 0.8 volts, 48, 56 and 64 percent leave as electricity, the rest as
heat. On the last slide's right-hand scale, the curve reads 66 percent at light load, 55 at half an
ampere, 46 at 1, 34 at 1.5. A fuel cell is most efficient at light load and least at full power: the
opposite of the engine of Lecture 2.

Argonne measured the 2017 Mirai at 66.0 percent peak for the stack, 63.7 for the system. That is
about 0.83 volts per cell, at low load. In grams: 63 of hydrogen per kilowatt-hour at 0.6 volts, 47
at 0.8.
-->

---
routeAlias: the-stack
---

## The stack

<div class="diagram-wide">

![Three panels. Left, cells joined at the edge: three cells, each cathode, electrolyte and anode, wired in series over their top edges through a load; an arrow shows electrons running up the whole face of an anode to its edge, from a circled region at the bottom. Middle, bipolar plates, joined through the face: a stack in section, end plate, membrane electrode assembly, bipolar plate, MEA, bipolar plate, MEA, end plate, minus at the left and plus at the right; each bipolar plate has hydrogen channels on one face and air channels on the other, and an arrow shows electrons passing straight through, cell to cell. Note: Mirai gen 2, 330 cells in series, 128 kW. Right, one cell's layers exploded: gasket, anode, membrane, cathode, gasket; the gaskets seal the gas at the edge.](/diagrams/05-stack.svg)

</div>

<div class="caption">Deck 8, after Larminie and Lowry, redrawn · Mirai: [TOYOTA-UK-MIRAI-SPECS-2024].</div>

<div class="grid grid-cols-[1fr_1fr_auto] gap-6 items-center mt-2 text-[0.9rem]">
<div>

**Cells in series:** the same current through all, voltages add.

$$
\dot m_{\mathrm{H_2}} = N\, I\, \frac{M_{\mathrm{H_2}}}{2F}
$$

Mirai gen 2: **12.41 g/h per A**; 0.79 kg/100 km = **63.7 A·h** per 100 km.

</div>
<div>

**Mirai gen 2 stack (FCB130):** **330 cells**, **128 kW** (gen 1: 114 kW, 370 cells), **5.4 kW/L**
excluding end plates, 52 kg; **388 W per cell**.

<div class="caption text-left">[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024] verified ·
per-cell and Faraday: derived (<code>hydrogen.md</code> §4, §6)</div>

</div>
<div>

<img class="photo" src="/photos/05-mirai-stack.jpg" style="height: 9rem" alt="The first-generation Toyota Mirai fuel-cell stack in its grey cast housing, seen from above through the cut-away blue floor of a show car, a label Fuel Cell Stack on top."/>

<div class="caption">Mirai (gen 1) stack · Mariordo, CC BY-SA 4.0</div>

</div>
</div>

<!--
One cell gives under a volt, so a car stacks hundreds in series. The same current flows through
every cell, and the voltages add. *[show figure]* A bipolar plate, with hydrogen channels on one
face and air on the other, carries the current straight through from one cell to the next.

The formula is Faraday's law for the stack: one hydrogen molecule for two electrons, in every cell.
For the Mirai's 330 cells, 12.41 grams per hour for every ampere. Check: the official 0.79 kilograms
per 100 kilometers is 63.7 ampere-hours of stack current.

The second Mirai has 330 cells and 128 kilowatts; the first had 370 and 114. Fewer cells, more
power: 388 watts each, in 52 kilograms. The model stack of the polarization slide, Ford's P2000, had
381 cells of 280 square centimeters, maximum current 2.2 amperes per square centimeter.

*[3 h: give the room five minutes on take-home exercise 3, the stack current and hydrogen flow at 30
kilowatts and 0.7 volts.]*
-->

---
routeAlias: balance-of-plant
---

## Balance of plant

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

![Block diagram of the balance of plant around the fuel-cell stack, which is split into anode and cathode. Hydrogen: the H2 tank feeds a pressure regulator, then the anode; unreacted hydrogen leaving the anode is recirculated back into the feed, and a purge valve on that loop vents nitrogen and water. Air: from the right through a filter, a compressor and a humidifier into the cathode; the cathode exhaust returns through the humidifier and leaves as air and water. Coolant: from the stack to a radiator, a pump, and back to the stack, holding it near 80 degrees Celsius in the model. Power: the stack's DC output goes through a boost DC-DC converter to the bus.](/diagrams/05-balance-of-plant.svg)

<div class="caption">Black: gas · blue: coolant · orange: electric</div>

</div>
<div>

- **Air:** a compressor sets cathode pressure and flow; the model holds oxygen excess ratio **2**.
- **Hydrogen:** regulated from the tank, unreacted gas recirculated, impurities purged.
- **Water:** the membrane must stay humid; product water must leave.
- **Heat:** a coolant loop holds the stack near **80 °C** (model).
- **Power:** a DC-DC converter matches the stack to the bus.

**The price:** stack peak 66.0 %, system peak 63.7 %.

</div>
</div>

<!--
The stack cannot run alone. *[show figure]* Around it is the balance of plant, the equipment that
keeps it running: four loops. Air: a compressor supplies twice the oxygen the reaction needs.
Hydrogen: unused gas goes back in, and a purge valve lets out nitrogen and water. Water: the
membrane must stay wet but must not flood. Heat: a coolant loop holds the stack near 80 degrees. And
a DC-DC converter matches the stack voltage to the bus.

The price: 66.0 percent for the stack, 63.7 for the system.

*[90 min, last slide of the section:]* That is the car's side of the nozzle. Section 06 is the other
side: five kilograms of hydrogen into a tank in three minutes.
-->

---
routeAlias: fuel-cell-heat
skipInCut: true
---

## Heat: the stack's other output

<div class="grid grid-cols-2 gap-8">
<div>

Per cell, at current *I* (LHV, water leaving as vapor):

$$
\dot Q \approx (1.253 - V_\text{cell})\, I
$$

At **0.6 V**: heat ≈ electricity.

**Small temperature difference:** the stack runs near 80 °C, so its radiator works on a far smaller
difference to the air than an engine's.

</div>
<div>

**Measured, 2017 Mirai, 25 % grade at 72 °F (ANL):**

- peak **111.6 kW**
- down to about **73 kW** after about **6 minutes**: thermal derating

<div class="caption text-left">[ANL-MIRAI-AMR-2018] verified · heat formula: derived from
*E*<sub>LHV</sub> (<code>pem-polarization.md</code> §5)</div>

</div>
</div>

<!--
Everything the cell does not turn into electricity turns into heat. Per cell, the heat is roughly
1.253 volts minus the cell voltage, times the current. That assumes the water leaves as vapor, which
is why we use the lower heating value.

*[ask]* At 0.6 volts per cell, how does the heat compare with the electrical output? *[pause]* 1.253
minus 0.6 is 0.65, against 0.6 out: the heat is about as large as the electricity.

This heat is harder to get rid of than an engine's. An engine sends much of its heat out with the
hot exhaust, and its coolant runs hotter. A PEM stack runs near 80 degrees, and its exhaust carries
little heat. So almost all of it goes through a radiator, with only a small temperature difference
to the outside air.

*[ask]* And at 0.7 volts, a cell running more efficiently? *[pause]* 0.55 of heat for 0.7 of
electricity: still almost as much heat as power. Light load helps both the radiator and the hydrogen
bill.

Argonne saw the result on the first Mirai. Climbing a 25 percent grade at about 22 degrees outside,
the stack peaked at 111.6 kilowatts. After six minutes it cut its power to about 73, to protect
itself. Argonne also tested the car on a dynamometer, a rolling road, from minus 18 to plus 35
degrees outside. The stack's maximum changed with the temperature, from about 110 to 114 kilowatts.
This is the fuel cell's rapidgate. Like the Leaf's battery, the stack is limited by heat, not by its
chemistry.

That is the car's side of the nozzle. Section 06 is the other side: what it takes to push five
kilograms of hydrogen into a tank in three minutes.
-->
