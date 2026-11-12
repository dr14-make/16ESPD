---
routeAlias: thevenin-cell
layout: section
---

###### Section 02

# The Thevenin cell

An open-circuit voltage that follows the state of charge, R₀, and one RC pair: the instant drop,
the slow sag and the recovery after a current pulse.

<!--
Section 02, the Thevenin cell. Lecture 4's battery was a constant voltage behind a resistor. Here
we add the two things it missed: an open-circuit voltage that depends on the state of charge, and
one resistor-capacitor pair that makes the voltage sag slowly under load and recover slowly after
it. Then we look at what a current pulse does to it.
-->

---
routeAlias: what-l4-missed
skipInCut: true
---

## What Lecture 4's battery got wrong

<div class="grid grid-cols-2 gap-8">
<div>

**Lecture 4:** *v* = *E* − *R*₀ *i*, *E* = 350 V fixed.

1. **E does not move.** A full and an empty pack show the same voltage.
2. **The sag is instant only.** No slow drop under load, no recovery after it.
3. **SoC runs through zero.** At 330 A it ended at −0.54.

</div>
<div>

**A real Leaf pack, C/3 discharge (2013 car, INL):**

| SoC | 100 % | 47 % | 12 % | 3 % |
|---|---:|---:|---:|---:|
| Pack V | 400 | 372 | 347 | **296** |

The voltage falls with the charge, and collapses near empty.

<div class="caption text-left">Loaded voltage at 22 A, read from INL Fig. 1, ±3 V
(`teaching_materials.md` §3.2, [INL-5045])</div>

</div>
</div>

<!--
Lecture 4's battery, again, with its three faults numbered. One: E does not move, so the model
cannot tell a full pack from an empty one by its voltage. Two: the voltage drop is instant only;
a real cell keeps sagging for tens of seconds under a steady load, and recovers slowly after it.
Three: nothing stops the state of charge at zero; at 330 amperes it ended at minus 0.54.

On the right, what a real pack does. Idaho National Laboratory discharged a 2013 Leaf pack at
22 amperes, about a third of its capacity per hour, and logged the voltage. I read the table off
their figure, to about plus or minus 3 volts. Full, the pack shows 400 volts. At 47 percent, 372.
At 12 percent, 347. At 3 percent it has collapsed to 296 volts. These are loaded voltages; the
open-circuit voltage is about 0.03 volts per cell higher.

So the voltage carries information about the charge. The next slide plots it.
-->

---
routeAlias: ocv-of-soc
skipInCut: true
---

## The open-circuit voltage follows the charge

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

<img src="/figures/02-ocv-soc.svg" alt="Voltage per cell against state of charge, 0 to 100 percent. Solid: the NMC 811 cell (LG M50) OCV, derived from PyBaMM Chen2020: 2.500 V at 0 %, 3.296 at 10 %, 3.581 at 30 %, 3.751 at 50 %, 3.948 at 70 %, 4.097 at 90 % and 4.200 at 100 %. Dashed: the 2013 Leaf's loaded voltage per series element at C/3, INL: 4.17 V at 100 %, 3.88 at 47 %, 3.61 at 12 %, 3.08 at 3 % and 2.49 at 0 %. The 10 to 90 % window is shaded."/>

<div class="caption">NMC 811: [CHEN-2020] via PyBaMM, derived; a smooth curve through the 10 % points · Leaf:
[INL-5045] Fig. 1, read by eye (±0.03 V), loaded, not OCV.</div>

</div>
<div class="text-[0.95rem]">

**NMC 811 cell, OCV (derived from a published parameter set):**

<div class="tight">

| SoC % | 0 | 10 | 30 | 50 | 70 | 90 | 100 |
|---|---|---|---|---|---|---|---|
| OCV, V | 2.500 | 3.296 | 3.581 | 3.751 | 3.948 | 4.097 | 4.200 |

</div>

**The knee below 10 %** is why the Leaf's usable window stops there: 10–90 % SoC is
**3.2–4.1 V** per cell.

**LFP is flatter:** ΔOCV/ΔSoC **0.148 V** for an LFP cell against **0.583 V** for an NMC cell.

<div class="caption text-left">[CHEN-2020] via PyBaMM, derived · window: [GAO-2024] · slopes:
[NEJAD-2016] Fig. 3 annotation (`bms.md` §2)</div>

</div>
</div>

<!--
The figure plots the open-circuit voltage of one cell against its state of charge. Across: state
of charge in percent, empty on the left. Up: volts per cell. The solid line is an NMC 811 cell, the
LG M50; its curve is computed from a published model parameter set, so it is a derived curve, not
a measurement, and we use it for shape. The second line is the Leaf's loaded voltage per cell from
the previous slide.

Read the table: 2.5 volts empty, 3.3 at 10 percent, 3.58 at 30, 3.75 at 50, 3.95 at 70, 4.10 at 90,
4.2 full. Between 10 and 90 percent the curve climbs steadily, about 0.8 volts. Below 10 percent
there is a knee: the voltage drops fast. That is why the usable window stops at about 10 percent:
for the first-generation Leaf cell, the second-life study by Gao and colleagues gives 10 to 90
percent as 3.2 to 4.1 volts.

An LFP cell is much flatter in the middle. Nejad and colleagues' 2016 review annotates its OCV
curves with the slope: 0.148 volts for their LFP cell against 0.583 for their NMC cell, about four
times flatter. Their text does not say over which span of charge the slope was taken, so use the
ratio rather than the absolute values. Both are 18650 laboratory cells, not car cells. Section 03
shows what the flat curve costs the battery management system.
-->

---
routeAlias: thevenin-circuit
---

## The Thevenin cell: R₀ plus one RC pair

<div class="grid grid-cols-[1fr_1.1fr] gap-8 items-center">
<div>

![Circuit of the Thevenin cell. On the left a voltage source, the open-circuit voltage as a function of state of charge, plus at the top. From its plus side the top wire runs through the resistor R0, then through a parallel pair of the resistor R1 and the capacitor C1, to the plus terminal; the voltage v1 is marked across the parallel pair, plus on the left. The bottom wire runs straight from the source's minus side to the minus terminal. The current i is marked flowing out of the plus terminal, and v is the voltage between the terminals.](/diagrams/02-thevenin.svg)

</div>
<div>

$$
v = \mathrm{OCV}(\mathrm{SoC}) - R_0\, i - v_1
$$

$$
\frac{dv_1}{dt} = -\frac{v_1}{R_1 C_1} + \frac{i}{C_1},
\qquad
\frac{d\,\mathrm{SoC}}{dt} = -\frac{i}{Q_\text{nom}}
$$

- **R₀:** the instant drop — electrolyte, contacts, busbars.
- **R₁ ‖ C₁:** the slow sag, time constant *τ*₁ = *R*₁*C*₁.
- **2013 Leaf cell (33.1 Ah), ≈ 60 % SoC, 25 °C:** *R*₀ = **1.60 mΩ**, *R*₁ = **1.34 mΩ**,
  *τ*₁ = **25.7 s**, *C*₁ ≈ **19 kF**; *τ*₁ "about 20 s" over 100–20 % SoC.
- **New Leaf cell (Gen 3, 56.3 Ah):** *R*₀ ≈ 1 mΩ, *R*₁ ≈ 1 mΩ.

<div class="caption text-left">Leaf 2013: fit to ORNL's HPPC data, derived, not a published table
[ORNL-LEAF-ECM] (`bms.md` §1) · Gen 3: [GAO-2024] §2.3</div>

</div>
</div>

<!--
The circuit on the left is the Thevenin cell, the standard equivalent circuit of a battery cell. A
voltage source, the open-circuit voltage, now a function of the state of charge. In series with it
R0, as in Lecture 4. And in series again one resistor R1 in parallel with a capacitor C1.

The first formula: the terminal voltage v is the open-circuit voltage at the present state of
charge, minus R0 times the current, minus v1, the voltage across the RC pair. The second: v1 is a
first-order lag. When a current flows, C1 charges through R1 and v1 rises toward R1 times i, with
time constant tau1 equal to R1 times C1. The third is Lecture 4's coulomb counter, unchanged.

What do the parts stand for? R0 is the ohmic part: the electrolyte, the contacts, the busbars;
it acts at once. The RC pair lumps the slow processes at the electrodes, charge transfer and
diffusion; it acts over tens of seconds.

The first set of numbers is a 2013 Leaf cell, 33.1 ampere-hours, at about 60 percent charge and 25
degrees: R0 1.60 milliohms, R1 1.34 milliohms, tau1 25.7 seconds, so C1 about 19 kilofarads. Be
clear where these come from: Oak Ridge published the raw pulse-test log of this cell, and the
research note fitted one RC pair to it. So they are derived, a fit, not values printed in a paper.
Over the pulses from full down to about 20 percent, R0 stays near 1.6 milliohms and the time
constant comes out between about 16 and 29 seconds depending on how it is fitted: call it about 20
seconds. Below 10 percent one RC pair no longer fits.

The second line is Gao and colleagues' 2024 study: a new third-generation 56.3 ampere-hour Leaf
cell has R0 about 1 milliohm and R1 about 1 milliohm. In both cells about half the resistance is the
slow part.
-->

---
routeAlias: pulse-response
---

## A current pulse: the drop, the sag, the recovery

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

<img src="/figures/02-pulse-response.svg" alt="Top: current, 30 A discharge from 0 to 30 s, rest until 70 s, 22.5 A regen from 70 to 80 s. Bottom: terminal voltage minus the OCV of 3.949 V, in mV, for the Leaf cell with R0 1.60 mΩ, R1 1.34 mΩ and τ1 25.7 s: an instant drop of 48 mV, sagging to −75.7 mV by 30 s; at release a step back to −27.7 mV and an exponential recovery to −5.8 mV by 70 s; during regen +30 mV rising to +42 mV; then a recovery toward zero. Dashed: Lecture 4's E − R0 i, −48 mV during discharge and +36 mV during regen."/>

<div class="caption">Formula plot of the 1-RC cell, [ORNL-LEAF-ECM] pulse-5 fit (derived), through the [USABC-EV-R4]
profile at 30 A; OCV held at 3.949 V.</div>

</div>
<div>

During the pulse, current *I*:

$$
v(t) = \mathrm{OCV} - R_0 I - R_1 I\,\bigl(1 - e^{-t/\tau_1}\bigr)
$$

After it, current 0:

$$
v(t) = \mathrm{OCV} - v_1(t_\text{off})\, e^{-(t - t_\text{off})/\tau_1}
$$

- **The test:** 30 s at *I*, 40 s rest, 10 s regen at 0.75 *I* — at every 10 % of depth of discharge.
- **At 30 A:** *R*₀*I* = **48 mV** at once; *R*₁*I*(1 − e<sup>−30/25.7</sup>) = **27.7 mV** more by
  30 s; **75.7 mV** model vs **75.9 mV** measured.
- **Fitting:** *R*₀ off the step, *R*₁ and *τ*₁ off the tail.

<div class="caption text-left">[USABC-EV-R4] verified · numbers: fit to [ORNL-LEAF-ECM], derived</div>

</div>
</div>

<!--
The figure is a formula plot of the standard pulse test from the USABC and Idaho
battery test manual for electric vehicles: 30 seconds of discharge, 40 seconds of rest, then 10
seconds of charging, regen, at three quarters of the current, repeated at every 10 percent of depth
of discharge. Here it is the Leaf cell from the last slide at about 60 percent, at 30 amperes. The top
panel is the current; the bottom panel is the terminal voltage.

Follow the bottom trace. When the current switches on, the voltage drops at once by R0 times I:
that is all Lecture 4's model did, and it is the dashed line. Then the voltage keeps sagging, along
an exponential with time constant tau1, toward a further R1 times I below. When the current
switches off, the voltage jumps back up by the same R0 times I at once, and then creeps back to the
open-circuit voltage along the same exponential. Over a long pulse the open-circuit voltage itself
falls a little too, because charge has left.

The formulas on the right are the two halves. During the pulse, v equals OCV minus R0 I minus R1 I
times one minus e to the minus t over tau1. After it, the remaining v1 decays to zero with the same
tau1.

The bullets put numbers on it, from the fit to Oak Ridge's log, so derived. At 30 amperes the
instant drop is 30 times 1.60 milliohms, 48 millivolts. In the 30 seconds that follow the RC pair
adds another 27.7 millivolts. Together the model gives 75.7 millivolts; the cell measured 75.9. The
regen pulse at the end does the same in the other direction, above the open-circuit voltage.

This is also how the parameters are measured: R0 from the instant step, R1 and tau1 from the shape
of the tail, at every 10 percent step, which is why the test manual specifies it. The relaxation
matters for section 03: after a pulse the terminal voltage is not yet the open-circuit voltage, so
the BMS must wait before it reads one.
-->

---
routeAlias: what-it-fixes
skipInCut: true
---

## What the Thevenin cell fixes, and what it still leaves out

<div class="tight">

| Lecture 4's fault | Thevenin cell | Still left out |
|---|---|---|
| *E* fixed at 350 V | OCV(SoC) from a table | hysteresis between charge and discharge |
| sag only at once | *R*₀ at once, *R*₁*C*₁ slowly | more RC pairs, diffusion |
| SoC through zero | voltage collapses below 10 %; cutoff **2.50 V** per cell | the BMS stops it first (section 03) |
| *R* constant | per-cell *R*₀, *R*₁ | **temperature**: R changes about 50–60 % over 15–35 °C |
| one pack | one cell × 96s2p | cell-to-cell spread (section 03) |

</div>

<div class="caption text-left">Leaf cell range 2.50–4.20 V: [INL-5045] · temperature: LMO/graphite
50 Ah cell, preprint, search summary (`teaching_materials.md` §3.3)</div>

<!--
The table sets the two models side by side. Left column, Lecture 4's faults; middle, how the
Thevenin cell answers each; right, what it still leaves out.

E fixed at 350 volts becomes an open-circuit voltage read from a table against the state of charge.
It still ignores hysteresis: the curve on charge sits slightly above the curve on discharge. The
instant-only sag becomes R0 at once plus the RC pair slowly; more pairs, or a diffusion model, would
fit better. The state of charge running through zero is caught because the voltage now collapses
below 10 percent and reaches the cutoff: 2.50 volts per cell for the Leaf's cell, from Idaho's test
report. In a car the BMS stops the current before that.

The resistance is still one number per part, but real resistance depends on temperature. The
figure in the table, about 50 to 60 percent over 15 to 35 degrees, is for a similar LMO cell, from a
preprint we have only as a search summary, so take it as reported, not checked. And the pack is
still one cell multiplied by 96 in series and 2 in parallel; real cells differ, which is the
balancing problem of section 03.
-->
