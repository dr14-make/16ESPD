---
routeAlias: thevenin-cell
layout: section
---

###### Section 02

# The Thevenin cell

An open-circuit voltage that follows the state of charge, R₀, and one RC pair: the instant drop,
the slow sag and the recovery after a current pulse.

<img class="hero" src="/photos/02-leaf-pack.jpg" alt="An opened first-generation Nissan Leaf battery pack on a stand: silver modules in stacks inside an orange-sealed tray, orange high-voltage cables and connectors at the front."/>

<div class="caption">Nissan Leaf pack, 2010 · Gereon Meyer, CC BY-SA 4.0</div>

<!--
Your Lecture 4 battery had one voltage, 350 volts, full or empty. But the charger, the BMS and the
range display all read the cell's voltage to learn what is inside it. So the cell needs a voltage
that follows the state of charge, and a slow part that lags behind the current: the Thevenin cell.

*[show photo]* A first-generation Leaf pack, opened: 192 cells your Lecture 4 model lumped into one
source and one resistor.
-->

---
routeAlias: what-l4-missed
skipInCut: true
---

## What Lecture 4's battery got wrong

<div class="diagram-wide">

![Two circuits side by side. Left, Lecture 4: inside a dashed box labeled battery, a fixed source E in series with a resistor R, feeding a load at the terminals; current i, terminal voltage v; v = E − R i, E and R fixed. Right, this session: the Thevenin cell, a source OCV(SoC), the resistor R0 and a parallel pair R1 and C1 with voltage v1, to the terminals; v = OCV(SoC) − R0 i − v1.](/diagrams/02-before-after.svg)

</div>

<div class="caption">Left: deck 8, after Larminie and Lowry, redrawn · right: the section 02 Thevenin cell.</div>

<div class="grid grid-cols-2 gap-8 mt-2 text-[0.95rem]">
<div>

**Lecture 4, *E* = 350 V fixed:**

1. **E does not move.** A full and an empty pack show the same voltage.
2. **The sag is instant only.** No slow drop under load, no recovery after it.
3. **SoC runs through zero.** At 330 A it ended at −0.54.

</div>
<div>

**A real Leaf pack, C/3 discharge (2013 car, INL):**

<div class="tight">

| SoC | 100 % | 47 % | 12 % | 3 % |
|---|---:|---:|---:|---:|
| Pack V | 400 | 372 | 347 | **296** |

</div>

<div class="caption text-left">Loaded voltage at 22 A, read from INL Fig. 1, ±3 V
(<code>teaching_materials.md</code> §3.2, [INL-5045])</div>

</div>
</div>

<!--
*[show figure]* Lecture 4's battery, with its three faults numbered. One: E does not move, so the
model cannot tell full from empty by its voltage. Two: the voltage drops only at the instant the
current changes, while a real cell keeps sagging for tens of seconds and recovers slowly. Three:
nothing stops the state of charge at zero.

*[ask]* Your pack at 330 amperes ran to minus 0.54. What would a real pack have done long before
that? *[pause]* Its voltage would have collapsed, and its BMS would have cut the current.

On the right, the evidence: Idaho National Laboratory discharged a whole 2013 Leaf pack at about a
third of its capacity per hour, read off their figure to about 3 volts. Full, 400 volts. At 47
percent, 372. At 12 percent, 347. At 3 percent, 296. Your Lecture 4 pack at 330 amperes passed zero
after about 19 minutes and kept going; the real pack would have announced the end by collapsing by
50 volts first.

Read the row again: 28 volts lost between full and half, 25 between half and 12 percent, then 51 in
the last nine percent. The voltage carries the charge, and near empty it carries it very loudly.
The next slide plots it per cell.
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
[NEJAD-2016] Fig. 3 annotation (<code>bms.md</code> §2)</div>

</div>
</div>

<!--
*[show figure]* The open-circuit voltage of one cell against its state of charge. The solid line is
an NMC 811 cell, computed from a published parameter set, so use it for the shape. The second line
is the Leaf's loaded voltage per cell from the last slide.

The table reads the solid line: 2.5 volts empty, 3.3 at 10 percent, 3.75 at half, 4.10 at 90, 4.2
full. Between 10 and 90 percent it climbs steadily, about 0.8 volts. Below 10 percent there is a
knee, and the voltage falls away. That knee is why the usable window stops at about 10 percent; for
the first-generation Leaf cell, Gao and colleagues give the 10 to 90 percent window as 3.2 to 4.1
volts, and their aged cells add anchor points: 3.6 volts at about 20 percent, 4.15 at about 92.

*[ask]* If you had to tell the state of charge from this voltage, where would you trust it, and
where not? *[pause]* In the steep middle, yes: a few millivolts per percent. At the flat top and in
the knee, much less.

The bottom line on the right: an LFP cell is about four times flatter, 0.148 volts against 0.583 for
NMC on Nejad's curves. Trust the ratio rather than the values. A curve four times flatter means a
voltage reading four times less informative; section 03 shows what that costs the BMS.
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
  *τ*₁ = **25.7 s**, *C*₁ ≈ **19 kF**; *τ*₁ 16–29 s over 100–20 % SoC, depending on the fit.
- **A newer 56.3 Ah Leaf cell:** *R*₀ ≈ 1 mΩ, *R*₁ ≈ 1 mΩ.

<div class="caption text-left">Leaf 2013: fit to ORNL's HPPC data, derived, not a published table
[ORNL-LEAF-ECM] (<code>bms.md</code> §1) · Gen 3: [GAO-2024] §2.3</div>

</div>
</div>

<!--
The Thevenin cell, the standard equivalent circuit. The OCV, now a function of state of charge. In
series, R0, as in Lecture 4. And R1 in parallel with C1.

The terminal voltage is the OCV minus R0 i minus v1; v1 lags toward R1 i with time constant tau1, R1
times C1. R0 acts at once; the RC pair lumps the slow processes at the electrodes.

The numbers: a 2013 Leaf cell at about 60 percent, fitted to Oak Ridge's pulse-test log. R0 1.60
milliohms, R1 1.34, tau1 25.7 seconds.

Scaled to your Lecture 4 pack, 96 in series and 2 in parallel: 77 milliohms at once, 141 after half a
minute. Idaho measured 0.136 to 0.145 ohm on a whole pack with 30-second pulses. Your 0.1 ohm sat between the two: a fair single number, but only one.
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
*[ask]* Before I show the trace: Lecture 4's model drops 48 millivolts at once at 30 amperes and
stays there. What does a real cell do in the next 30 seconds? *[pause]*

*[show figure]* The standard pulse test: 30 seconds of discharge, 40 of rest, 10 of regen. At
switch-on, 48 millivolts at once, R0 times I. Then it keeps sagging, another 27.7 by 30 seconds:
75.7 in all, against 75.9 measured. At switch-off it jumps back by 48, then creeps toward the OCV.
That is how the parameters are measured: R0 from the step, R1 and tau1 from the tail.

After the current stops, the terminal voltage is not yet the OCV. A BMS that wants to read the
charge from the voltage has to wait. Section 03 is how long.
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
50 Ah cell, preprint, search summary (<code>teaching_materials.md</code> §3.3)</div>

<!--
The two models side by side: Lecture 4's faults, how the Thevenin cell answers each, and what it
still leaves out.

E fixed at 350 volts becomes an OCV table against state of charge. It still ignores hysteresis: the
charge curve sits a little above the discharge curve, worst for LFP. The instant-only sag becomes R0
at once plus the RC pair slowly; more pairs, or a diffusion model, fit better. The state of charge
running through zero is caught, because the voltage collapses below 10 percent and reaches the 2.50
volt cutoff; in a car the BMS stops the current first.

The resistance is still one number per part, but real resistance depends on temperature: 50 to 60
percent over 15 to 35 degrees for a similar manganese cell, from a preprint we could not check, so
take it as an indication. Cold makes everything tonight slower; section 04 comes back to that.

*[ask]* The last row: the pack is one cell times 96 in series and 2 in parallel. What does that
assume about the 192 cells? *[pause]* That they are identical. They are not, and the BMS has to deal
with that too.

So the cell now has a voltage that tells the truth, slowly. Section 03 is the electronics that
listen to it.
-->
