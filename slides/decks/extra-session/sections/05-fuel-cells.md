---
routeAlias: fuel-cells
layout: section
---

###### Section 05

# Fuel cells

Deck 8's principles and losses as one polarization curve, the voltage as the efficiency, the stack,
and the balance of plant around it.

<!--
Section 05, fuel cells, after the break. We follow deck 8: how a cell works, the types, and the
losses. But we gather all the losses into one curve, the polarization curve, and read the
efficiency straight off its voltage. Then the stack of cells in series, and the machinery around it
that the deck calls the balance of plant.
-->

---
routeAlias: pem-principle
skipInCut: true
---

## How a PEM fuel cell works

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

<div class="placeholder">

**Diagram** `/diagrams/05-pem-cell.svg`

Cross-section of one PEM cell: anode flow field with H₂ in, catalyst layer, the proton-exchange
membrane, catalyst layer, cathode flow field with air in and water out. H₂ → 2H⁺ + 2e⁻ at the anode;
protons through the membrane; electrons through the external load; ½O₂ + 2H⁺ + 2e⁻ → H₂O at the
cathode. Hand-drawn, after deck 8.

</div>

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
(`pem-polarization.md` §5)</div>

</div>
</div>

<!--
The diagram is one cell of a proton-exchange-membrane fuel cell, the kind fuel-cell cars use.
Hydrogen enters on the anode side, on the left. A platinum catalyst splits each hydrogen molecule
into two protons and two electrons. The membrane in the middle lets protons through but not
electrons, so the electrons take the long way, through the external circuit: that is our current.
On the cathode side, on the right, oxygen from the air meets the protons and the electrons and
makes water.

The ideal voltage. The reversible cell voltage at 25 degrees is 1.229 volts, the value in the
Pukrushpan model we use next. If all of hydrogen's lower heating value turned into electricity,
the cell would show 1.253 volts: that is the heating value divided by two Faraday constants,
because each hydrogen molecule moves two electrons. With the higher heating value, which counts the
water's heat of condensation, 1.481 volts. These are reference voltages for efficiency; the next
slide shows how far below them a real cell runs.
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

TODO(deck 8): operating temperatures and efficiencies from deck 8's summary table; not in the
research notes.

<!--
Deck 8 lists five types of fuel cell, named after their electrolyte. Only the first matters for
cars: the proton-exchange membrane, PEM, a polymer film. The Mirai's spec sheet calls its stack
polymer electrolyte, and the Pukrushpan model we use next is a PEM stack too. The
alkaline cell flew in space and needs air without carbon dioxide. Phosphoric acid, molten carbonate
and solid oxide cells are stationary power plants; the last two run hot.

The operating temperatures and efficiencies come from deck 8's own table; they are not in our
research notes yet.
-->

---
routeAlias: polarization-curve
---

## The polarization curve

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-start">
<div>

<div class="placeholder">

**Figure** `/figures/05-polarization.svg`

Formula plot, notebook: cell voltage (V) against current density (A/cm², 0–2.2) for the P2000
model at 80 °C, 2.5 bar, λ_m = 14 (`pem-polarization.md` §1, "recommended slide curve"), with the
three losses shaded between 0.950 V and the curve (activation, ohmic, concentration); the measured
2017 Mirai stack points (ANL, ±0.014 V/cell, `pem-polarization.md` §4.1) overlaid as dots; a
second axis η_LHV = V / 1.253.

</div>

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
The polarization curve is the fuel cell's characteristic, as the torque-speed curve was the
machine's. Across: current density, amperes per square centimeter of cell area. Up: cell voltage.
The curve is a formula plot of the Pukrushpan model, a standard automotive model fitted to the 75
kilowatt Ford P2000 stack, at 80 degrees and 2.5 bar, fully humidified. The research note checked one
coefficient against the original thesis; the journal paper has a misprint, and we use the thesis
value.

The formula has four parts. 0.950 volts is the starting point at zero current. Then three losses,
shaded in the figure. Activation: the energy needed to drive the reaction at the catalyst; it rises
fast at small currents and saturates at 0.178 volts. Ohmic: the membrane's resistance, 0.1575 ohm
square centimeters, a straight line. Concentration: at high current the gases cannot reach the
catalyst fast enough, and the curve bends down toward the 2.2 ampere limit.

The table reads the curve. 0.822 volts at 0.1 amperes per square centimeter; 0.690 at 0.5; 0.583
at 1; 0.430 at 1.5. The last row is power per square centimeter, voltage times current: it rises to
0.64 watts at 1.5, and the maximum lies near there. Past it, more current gives less power.

The dots are the real 2017 Mirai's stack, measured by Argonne and read off their figure. At about
1 ampere per square centimeter the Mirai holds about 0.74 volts against the model's 0.58. The P2000
is a 1999-era stack with a thick membrane; most of the gap is the ohmic term, and Toyota names a
thinner membrane as one of three causes of its gain. Argonne's current density assumes a cell area
of 237 square centimeters from a DOE cost study, not a Toyota figure.
-->

---
routeAlias: voltage-is-efficiency
---

## The voltage is the efficiency

<div class="grid grid-cols-2 gap-8">
<div>

$$
\eta_\text{LHV} = \mu_f\, \frac{V_\text{cell}}{1.253\ \text{V}}
$$

*μ*<sub>f</sub>: fuel utilization, the share of the hydrogen that reacts.

| *V*<sub>cell</sub> | 0.822 | 0.690 | 0.583 | 0.430 |
|---|---:|---:|---:|---:|
| *η*<sub>LHV</sub> | 65.6 % | 55.1 % | 46.5 % | 34.3 % |

**Low load is efficient**, high load is powerful: the opposite of an engine.

</div>
<div>

**Measured, 2017 Mirai (ANL):**

- stack peak efficiency **66.0 %**
- system peak efficiency **63.7 %**
- 66.0 % ↔ *μ*<sub>f</sub> *V* ≈ **0.83 V**, matching the 0.78–0.85 V cells at low load

**Hydrogen per kWh of electricity:**

| *V*<sub>cell</sub> | 0.6 V | 0.7 V | 0.8 V |
|---|---:|---:|---:|
| g H₂/kWh | 62.7 | 53.7 | 47.0 |

<div class="caption text-left">[LOHSE-BUSCH-IJHE-2020] verified · g/kWh derived
(`pem-polarization.md` §5)</div>

</div>
</div>

<!--
A fuel cell's efficiency is its voltage. Every hydrogen molecule delivers two electrons whatever
the voltage, so the energy out per molecule is proportional to the cell voltage, and the energy in
is fixed. Divide by 1.253 volts, the voltage that would turn all of the lower heating value into
electricity, and multiply by the fuel utilization, the share of the hydrogen that actually reacts
rather than being purged or crossing the membrane.

The table takes the four points of the curve, with utilization 1: 65.6 percent at light load, 55
at half an ampere per square centimeter, 46.5 at 1, 34 at 1.5. So a fuel cell is most efficient at
light load and least at full power, the opposite of the engine in Lecture 2, which was worst at
light load.

The right column checks it against the real car. Argonne measured the 2017 Mirai: 66.0 percent peak
efficiency for the stack, 63.7 for the whole system, which pays for its compressor and pumps. 66.0
percent corresponds to about 0.83 volts times utilization, which matches the 0.78 to 0.85 volt
cells Argonne saw at low load.

The second table turns it around: grams of hydrogen per kilowatt-hour of electricity. 62.7 grams
at 0.6 volts, 53.7 at 0.7, 47.0 at 0.8. That is Faraday's law, independent of the number of cells.
-->

---
routeAlias: the-stack
---

## The stack

<div class="grid grid-cols-2 gap-8">
<div>

**Cells in series:** the same current through all, voltages add.

$$
\dot m_{\mathrm{H_2}} = N\, I\, \frac{M_{\mathrm{H_2}}}{2F}
$$

| Stack | *N* | g/h per A |
|---|---:|---:|
| Mirai gen 2 | 330 | **12.41** |
| Mirai gen 1 | 370 | 13.92 |
| Ford P2000 | 381 | 14.33 |

**Check:** 0.79 kg/100 km = **63.7 A·h** of stack current per 100 km.

</div>
<div>

**Toyota Mirai gen 2 stack (FCB130):**

- **330 cells**, polymer electrolyte
- **128 kW** max, up from 114 kW (370 cells)
- **5.4 kW/L** excluding end plates; 52 kg
- 128 kW / 330 = **388 W per cell**

**P2000 model stack:** 381 cells, **280 cm²**, *i*<sub>max</sub> **2.2 A/cm²**

<div class="caption text-left">[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024],
[PUKRUSHPAN-2003] verified · per-cell and Faraday: derived (`hydrogen.md` §4, §6)</div>

</div>
</div>

<!--
One cell gives under a volt, so a car stacks hundreds in series. In series every cell carries the
same current, and the voltages add.

The formula is Faraday's law for the stack: the hydrogen mass flow is the number of cells, times
the current, times the molar mass of hydrogen over twice the Faraday constant. Each cell consumes
one hydrogen molecule per two electrons, and every cell sees the full current. The table evaluates
it: 12.41 grams per hour per ampere for the Mirai's 330 cells, 13.92 for the first Mirai's 370, 14.33
for the P2000's 381. The check at the bottom: the Mirai's official 0.79 kilograms per 100 kilometers
is 790 grams, which is 63.7 ampere-hours of stack current.

On the right, the Mirai's stack from Toyota's spec sheet. 330 cells of polymer electrolyte. 128
kilowatts, up from 114 in the first generation, with 40 fewer cells. 5.4 kilowatts per liter
excluding the end plates, 52 kilograms. Per cell: 128 kilowatts over 330 is 388 watts. One flag:
Toyota's own spec sheet also prints a stack volume of 4 liters, which contradicts 5.4 kilowatts per
liter, so we do not quote a volume.

For comparison, the model stack: 381 cells of 280 square centimeters, with a current limit of 2.2
amperes per square centimeter.
-->

---
routeAlias: balance-of-plant
---

## Balance of plant

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

<div class="placeholder">

**Diagram** `/diagrams/05-balance-of-plant.svg`

Block diagram around the stack: hydrogen tank → pressure regulator → anode, with a recirculation
loop and a purge valve; air filter → compressor → humidifier → cathode, exhaust back through the
humidifier; a coolant loop with pump and radiator; the stack's DC out to a boost converter. Hand-
drawn, after deck 8.

</div>

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
The stack does not run on its own. The machinery around it is what deck 8 calls the balance of
plant, and the diagram shows its four loops.

Air. A compressor pushes air into the cathode and sets its pressure and flow. The Pukrushpan model
holds the oxygen excess ratio at 2, twice the oxygen the reaction consumes, so that the cells at the
far end of each channel are not starved.

Hydrogen. A regulator drops the tank pressure to the anode pressure. Unreacted hydrogen is pumped
back round, and a purge valve vents now and then to clear nitrogen and water that collect on the
anode side: that purge is part of the fuel utilization below 1.

Water. The membrane conducts protons only when it is wet, so the incoming air is humidified, often
with the outgoing wet air; but the product water must also get out, or it floods the cells.

Heat. A coolant loop holds the stack temperature; the model assumes 80 degrees. The next slide is
about this loop.

And power. The stack's voltage falls with load, so a DC-DC converter matches it to the car's
high-voltage bus. Section 07 places it in the car.

The price of all this: Argonne's 66.0 percent for the stack drops to 63.7 for the system.
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

**Small temperature lift:** the stack runs near 80 °C, so its radiator works on a far smaller
difference to the air than an engine's.

</div>
<div>

**Measured, 2017 Mirai, 25 % grade at 72 °F (ANL):**

- peak **111.6 kW**
- down to about **73 kW** after about **6 minutes**: thermal derating

<div class="caption text-left">[ANL-MIRAI-AMR-2018] verified · heat formula: derived from
*E*<sub>LHV</sub> (`pem-polarization.md` §5)</div>

</div>
</div>

<!--
Everything the cell does not turn into electricity turns into heat. Per cell, the heat is roughly
the difference between 1.253 volts and the cell voltage, times the current; that assumes the water
leaves as vapor, which is why we use the lower heating value. At 0.6 volts the heat is about as large
as the electrical output.

That heat is harder to reject than an engine's. An engine throws most of its heat out with the hot
exhaust, and its coolant runs hotter. A PEM stack runs near 80 degrees, its exhaust carries little
heat, so almost all of it goes through a radiator working on a small temperature difference to the
outside air.

Argonne saw the consequence on the first Mirai: climbing a 25 percent grade at 72 Fahrenheit, about
22 degrees Celsius, the stack peaked at 111.6 kilowatts, then derated to about 73 kilowatts after
about six minutes, to protect itself from overheating. It is the fuel cell's rapidgate.
-->
