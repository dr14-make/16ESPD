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
electric car with a chemical power plant on board instead of a big battery. Before we fill it with
hydrogen, we need to know what the hydrogen turns into, and at what efficiency. One curve answers
that, the polarization curve, as the torque-speed curve answered it for the motor. Then the stack,
and the machinery around it.

*[show photo]* The first Mirai's stack in its cast housing, under the floor of a cut-away show car
in São Paulo. Photograph by the user Mariordo, Wikimedia Commons.
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
*[show figure]* One cell of a proton-exchange-membrane fuel cell, PEM, the kind every fuel-cell car
uses. Hydrogen enters on the anode side, on the left. A platinum catalyst splits each molecule into
two protons and two electrons. The membrane in the middle passes protons but not electrons, so the
electrons take the long way, through the external circuit: that is our current. On the cathode
side, oxygen from the air meets the protons and the electrons and makes water. A battery that never
runs flat, as long as you feed it.

The voltages on the right are the references for everything that follows. The reversible voltage
at 25 degrees is 1.229 volts. If all of hydrogen's lower heating value turned into electricity, the
cell would show 1.253 volts: the heating value over two Faraday constants, because each molecule
moves two electrons. Counting the heat of condensing the water too, the higher heating value, 1.481.
The membrane in the model we use next is Nafion 117, about 0.13 millimeters thick; remember the
thickness, because it is where the Mirai gains most. A real cell runs well below all three. How far below is the next slide.
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
Deck 8 lists five types of fuel cell, named after their electrolyte. Only the first matters for
cars: the proton-exchange membrane, a thin polymer film. The Mirai's spec sheet calls its stack
polymer electrolyte, and the model we use next is a PEM stack too.

*[ask]* Why PEM, for a car? Think of what a car asks of its power source. *[pause]* It must start in
seconds on a cold morning, follow the driver's foot, and fit under the floor. The PEM cell runs
cool, near 80 degrees in the model we use, so it starts quickly and needs no furnace. It is compact
and it changes power fast.

The others answer different questions. The alkaline cell flew in space; it needs air without carbon
dioxide, which a car on a road cannot offer. The phosphoric acid cell is a stationary power plant.
Molten carbonate and solid oxide cells run hot, which suits a building or a factory that runs for
months and can use the heat, not a car that is parked most of the day. Deck 8's table gives their
operating temperatures and efficiencies if you want to compare.

And within PEM the progress has been fast. Toyota says the first Mirai's stack reached 2.4 times
the current density of its 2008 model, through three changes: a finer flow field for the gas, a
new platinum-cobalt catalyst, and a thinner membrane. The second Mirai raised the output per cell by
another 26 percent, and so needed 330 cells instead of 370. Argonne's measurement of the first
Mirai's stack gave 3.1 kilowatts per liter; Toyota quotes 5.4 for the second, excluding end plates.

So from here on, a fuel cell means a PEM cell, and its characteristic is the next slide.
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
The polarization curve is the fuel cell's characteristic. Across, current density, amperes per
square centimeter of cell; up, cell voltage. The black curve is the Pukrushpan model, the standard
automotive model, fitted to Ford's 75 kilowatt P2000 stack at 80 degrees and 2.5 bar.

It starts at 0.950 volts with no current and subtracts three losses, shaded in the figure; the
three labels on the curve are deck 8's names for its shape: a rapid initial fall, a fairly linear
middle, and a fall that speeds up at high current.
Activation, the price of driving the reaction at the catalyst: it rises fast and saturates at 0.178
volts. Ohmic, the membrane's resistance: a straight line. Concentration: at high current the gas
cannot reach the catalyst fast enough, and the curve dives toward 2.2 amperes per square
centimeter, the limiting current.

The table reads the curve: 0.82 volts at 0.1, 0.69 at 0.5, 0.58 at 1. Power, voltage times current,
peaks at about 1.4; past that, more current gives less power.

*[show figure]* The red dots are the real 2017 Mirai's stack, measured by Argonne. At about 1 ampere
per square centimeter it holds 0.74 volts against the model's 0.58. The P2000 is a 1999-era stack
with a thick membrane; most of the gap is the ohmic line, and Toyota names a thinner membrane as one
reason for its gain.

*[ask]* The right-hand scale says efficiency. Where on this curve is the cell most efficient?
*[pause]* At the left: light load. The next slide says why.
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
A fuel cell's efficiency is its voltage. Every hydrogen molecule delivers two electrons, whatever the
voltage, so the energy out per molecule is proportional to the cell voltage while the energy in is
fixed. Divide by 1.253 volts and multiply by the fuel utilization, the share of the hydrogen that
reacts rather than being purged.

*[show figure]* Three cells, at 0.6, 0.7 and 0.8 volts: of the hydrogen's energy, 48, 56 and 64
percent leave as electricity, the rest as heat. On the last slide's right-hand scale, the four
points of the curve read 66 percent at light load, 55 at half an ampere, 46 at 1, 34 at 1.5. So
a fuel cell is most efficient at light load and least at full power: the opposite of the engine of
Lecture 2, which was worst at light load and in town.

The measured lines on the left check the real car. Argonne measured the 2017 Mirai at 66.0 percent peak for the
stack, 63.7 for the whole system. 66 percent means about 0.83 volts per cell, which is what Argonne
saw at low load.

The grams under each flow are Faraday's law per kilowatt-hour: 63 grams of hydrogen at 0.6 volts,
47 at 0.8.
Higher voltage, less hydrogen.
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
One cell gives under a volt, so a car stacks hundreds in series. Every cell carries the same
current, and the voltages add. *[show figure]* Left, the naive way: cells joined at their edges,
so the electrons must run across the whole face of each electrode to reach the wire. Middle, the
real way: a bipolar plate, hydrogen channels on one face and air on the other, carries the current
straight through the face from one cell to the next. Right, one cell's layers, with the gaskets
that seal the gas at the edge.

The formula is Faraday's law for the stack: each cell uses one hydrogen molecule per two electrons,
and every cell sees the full current. So the hydrogen flow is the number of cells times the current
times the molar mass over twice the Faraday constant. For the Mirai's 330 cells: 12.41 grams per hour
for every ampere; the first Mirai's 370 cells, 13.92; Ford's P2000 model stack, 381 cells, 14.33. The check: the Mirai's official 0.79 kilograms per 100 kilometers is
63.7 ampere-hours of stack current.

In the middle, the Mirai's stack from Toyota, and on the right the first Mirai's, in its housing: 330 cells, 128 kilowatts, up from 114 with 370 cells in
the first generation. Fewer cells, more power: each cell now gives 388 watts. And 52 kilograms for
the whole stack. The model stack of the polarization slide, Ford's P2000, had 381 cells of 280
square centimeters, with a limiting current of 2.2 amperes per square centimeter.

*[3 h: give the room five minutes on take-home exercise 3: the stack current and hydrogen flow at 30
kilowatts with cells at 0.7 volts. Take one answer for the current and one for the flow.]*
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
The stack does not run on its own. *[show figure]* The machinery around it is what deck 8 calls the
balance of plant: four loops.

Air: a compressor sets the cathode's pressure and flow, supplying twice the oxygen the reaction needs
so the far end of each channel is not starved. Hydrogen: a regulator drops the tank pressure;
unreacted gas is pumped back round, and a purge valve vents the nitrogen and water that collect.
Water: the membrane conducts only when wet, so the air is humidified, but the product water must get
out or it floods the cells. Heat: a coolant loop holds the stack near 80 degrees, which is harder
than it sounds. And power: a DC-DC converter matches the falling stack voltage to the car's bus.

The price of all this: 66.0 percent for the stack, 63.7 for the system.

*[90 min, last slide of the section:]* That is the car's side of the nozzle. Section 06 is the other
side: what it takes to push five kilograms of hydrogen into a tank in three minutes.
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
1.253 volts minus the cell voltage, times the current. That assumes the water leaves as vapor,
which is why we use the lower heating value.

*[ask]* At 0.6 volts per cell, how does the heat compare with the electrical output? *[pause]* 1.253
minus 0.6 is 0.65, against 0.6 out: the heat is about as large as the electricity.

And that heat is harder to get rid of than an engine's. An engine throws much of its heat out with a
hot exhaust, and its coolant runs hotter. A PEM stack runs near 80 degrees and its exhaust carries
little heat, so almost all of it goes through a radiator working on a small temperature difference
to the outside air.

*[ask]* And at 0.7 volts, a cell running more efficiently? *[pause]* 0.55 of heat for 0.7 of
electricity: still almost as much heat as power. Running the stack at light load helps the radiator
as well as the hydrogen bill.

Argonne saw the consequence on the first Mirai. Climbing a 25 percent grade at about 22 degrees
outside, the stack peaked at 111.6 kilowatts, then derated to about 73 after six minutes, to protect
itself. Argonne tested the same car on a dynamometer from minus 18 to plus 35 degrees outside, and
the stack's maximum varied with the thermal conditions, from about 110 to 114 kilowatts. That is the
fuel cell's rapidgate: like the Leaf's battery, the stack is limited by heat, not
by its chemistry.

That is the car's side of the nozzle. Section 06 is the other side: what it takes to push five
kilograms of hydrogen into a tank in three minutes.
-->
