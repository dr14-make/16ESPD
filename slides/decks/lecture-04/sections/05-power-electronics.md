---
routeAlias: power-electronics
layout: section
---

###### Section 05

# Power electronics

DC regulation, the step-down and step-up choppers, the H-bridge, pulse-width modulation and its
harmonics, the three-phase bridge; the DC-DC for 12 V and the charger.

`notebooks/lecture04/02-switching.pluto.jl`

<!--
Budget: about 20 minutes, no build: a demo on the switching models. Deck 7 slides 27 to 33. The
notebook regenerates slides 28, 30 and 31 from running models; slides 29 (boost) and 32
(three-phase bridge) stay diagrams.

Same rule as Lecture 2's: never stack time scales. A switching edge lasts a microsecond, a WLTC
1800 seconds. The car carries the average converter of section 04; the switched models run beside
it, for a few milliseconds, to show what the average hides.
-->

---
routeAlias: dc-regulation
---

## DC regulation

<div class="grid grid-cols-2 gap-8">
<div>

The voltage of every source moves (deck): with time, temperature and load. The pack of step 03
sags by *R*₀ · *i* under load. Electronics need a steady voltage.

**Two ways to drop a voltage**

- a **dropping** device: a resistance or a linear regulator. It burns the difference as heat.
- a **switching** device: a switch that is fully on or fully off, many thousand times a second.
  Averaged, the output is the duty times the input.

</div>
<div>

**An ideal switch loses nothing:** on, no voltage across it; off, no current through it.

$$
\overline{v}_{out} = d \cdot V_{in}
$$

A real one loses a little while on (conduction) and a little at every edge (switching).

The model's switch is a resistance the gate moves between 10 mΩ and 1 MΩ: the stdlib has no
switch.

</div>
</div>

<!--
Deck 7 slide 27. Why regulate at all: the battery's voltage moves with its state of charge, its
temperature and its current; the motor and the electronics want a voltage that suits them.

A linear regulator would turn the difference into heat: dropping 350 volts to 100 at 100 amperes
would burn 25 kW. A switch that is either fully on or fully off has, ideally, zero voltage across
it or zero current through it, and dissipates nothing. Switch it fast enough and the inductance of
the load smooths the pulses: the load sees the average, d times the input.

The notebook's switch: the standard library has none, so a power transistor is a resistance the
gate moves between 10 milliohms and 1 megaohm, with a finite edge time, and a 1 nanofarad output
capacitance so the solver can follow the switching node.
-->

---
routeAlias: buck
---

## The step-down chopper

<div class="grid grid-cols-[1fr_1.25fr] gap-6 items-center">
<div>

![Buck chopper: a 48 V supply, switch S, freewheeling diode D from ground to the switch node, inductor L, 0.7 Ω load. Switch on, the supply drives L; switch off, L keeps the current flowing through D. Average output d times V_in.](/diagrams/05-buck.svg)

</div>
<div>

![Three switching periods of the buck chopper in steady state: the supply current flows only while the switch is on (shaded), the diode current only while it is off, and the load current, their sum, is continuous with a small ripple.](/figures/05-buck-currents.svg)

</div>
</div>

48 V to 13 V at 20 kHz, about 250 W: the converter that feeds a 12 V bus from a 48 V mild-hybrid
battery.

<!--
Deck 7 slide 28, regenerated. The circuit on the left, the three currents on the right, from
notebook 02 section 1, "Three currents": the library's `Vehicle.Electric.BuckChopper`, three
periods in steady state.

While the switch is on, the supply drives current through the inductor into the load: the top
trace, the supply current, flows only in the shaded intervals. When the switch opens, the inductor
keeps the current going, and the freewheeling diode gives it a path from ground: the middle trace.
The load sees their sum, bottom: continuous, with a ripple. The inductor current never stops; it
rises while the switch is on and falls while it is off, around the average the duty sets.

The design point is assumed: 48 to 13 volts, about 250 watts, 20 kHz, a 0.7 ohm load. The diode is
the library's exponential diode, 0.6 volts at 3.3 amperes and 0.8 at 20: the deck's "0.6 times I".
-->

---
routeAlias: buck-losses
---

## Where a chopper loses

<div class="grid grid-cols-2 gap-6 items-center">
<div>

![Bar chart of the buck chopper's average losses at 256 W out: diode about 0.8 V times i 10.62 W, winding R_L i² 3.66 W, switching 2.08 W, conduction R_on i² 1.07 W; efficiency 93.6 %.](/figures/05-buck-losses.svg)

</div>
<div>

![Left: the current ripple, peak to peak, falls as 1 over the switching frequency. Right: the losses against switching frequency, the switching loss growing with it: efficiency 94.5 % at 5 kHz and 90.3 % at 100 kHz.](/figures/05-buck-frequency.svg)

</div>
</div>

The deck's four losses, each a part with its own power. **The diode is the largest**: 0.8 V against
a 13 V output, for 70 % of every period. A faster switch shrinks the ripple and the inductor, and
costs switching loss.

<!--
The figures are notebook 02 section 1, the losses bar and the frequency sweep.

Left: at the design point, 256 watts out, 93.6 percent. The deck's list in the order of size: the
diode, 10.62 watts, because 0.8 volts is large against a 13 volt output and the diode conducts for
70 percent of the period; the winding resistance, 3.66; the switching loss, 2.08; the switch's
conduction, 1.07. The switching loss already exceeds the conduction loss at 20 kHz. Low-voltage
converters therefore replace the diode by a second switch, synchronous rectification.

Right: the frequency sweep. The ripple falls as 1 over f s, dashed; the switching loss grows with
f s, so the efficiency falls from 94.5 percent at 5 kHz to 90.3 at 100 kHz. The deck's "over 90
percent" holds over the whole range. The trade is the size of the inductor against the losses.
-->

---
routeAlias: boost
---

## The step-up chopper

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Boost chopper: supply, inductor L, then a switch S from the node to ground and a diode D to the output capacitor C and the load. Switch on, L charges from the supply; switch off, L adds its voltage to the supply's. Average output V_in divided by 1 minus d.](/diagrams/05-boost.svg)

</div>
<div>

The same three parts, rearranged. With the switch on, the inductor charges from the supply; with it
off, the inductor's voltage **adds** to the supply's, through the diode into the capacitor:

$$
\overline{v}_{out} = \frac{V_{in}}{1 - d}
$$

Run backwards, a boost is a buck: one bidirectional converter does both.

The Leaf has none: its inverter sits straight on the pack (ORNL).

</div>
</div>

<!--
Deck 7 slide 29, a diagram: the notebook has no switched boost model (plan S4).

The boost uses the inductor the other way. While the switch is on, the supply drives a rising
current through the inductor to ground, storing energy. When the switch opens, the inductor's
current must go on, and it can only go through the diode into the capacitor: the inductor's
voltage adds to the supply's, so the output sits above it. Averaged, V in over 1 minus d: a duty
of one half doubles the voltage.

Swap the roles of the switch and the diode, and energy flows from the high side to the low side:
the same hardware bucks the other way. Bidirectional DC-DC converters do exactly that.

Some cars put a boost between the pack and the inverter, to run the machine at a higher voltage
than the pack. The 2012 Leaf that ORNL took apart has one inverter on the pack and no boost: our
car's converter is that inverter.
-->

---
routeAlias: h-bridge
---

## The H-bridge: DC to AC

<div class="grid grid-cols-[1fr_1.25fr] gap-6 items-center">
<div>

![H-bridge: four switches A, B (upper) and C, D (lower), each with a freewheeling diode, on a 350 V DC link; the load, 10 Ω plus 10 mH, between the midpoints a and b. A and D on gives plus V_dc across the load; B and C on gives minus V_dc.](/diagrams/05-h-bridge.svg)

</div>
<div>

![H-bridge in square-wave operation: the output voltage switches between plus and minus 350 V every half cycle at 50 Hz, A and D on, then B and C; the load current rises and falls exponentially through 10 Ω and 10 mH.](/figures/05-hbridge-square.svg)

</div>
</div>

Hold each pair on for half a cycle: a **square wave**. The load's inductance rounds its current.

<!--
Deck 7 slide 30, regenerated: notebook 02 section 2, the library's `Vehicle.Electric.HBridge`.

Four switches in an H, the load across the middle. A and D on: the left side at the positive
rail, the right at the negative, the load sees plus 350 volts. B and C on: minus 350. The DC link
is the Leaf pack's 350 volts; the load, 10 ohms and 10 millihenry, is a motor winding's R-L,
assumed.

Never both switches of one leg at once: that is a short circuit across the pack. Each switch has a
freewheeling diode across it, so the inductive current has a path when its switch opens.

The square wave is the crudest AC: its fundamental is right, but it carries large odd harmonics.
The notebook makes it as PWM with the reference pushed far beyond 1, so the pulses merge.
-->

---
routeAlias: pwm
---

## Pulse-width modulation

<div class="grid grid-cols-2 gap-6 items-center">
<div>

![Sine PWM at 1 kHz with modulation index 0.8 over one 50 Hz cycle: the absolute reference against the triangular carrier, and the gates: A pulses while D holds during the positive half, C pulses while B holds during the negative half.](/figures/05-pwm-gates.svg)

</div>
<div>

![The output voltage pulses between 0 and plus or minus 350 V, wider near the peaks; its fundamental, dashed, is 280 V; the load current is close to a 26.7 A sine with a small ripple.](/figures/05-pwm-current.svg)

</div>
</div>

Compare the wanted voltage with a triangle at the switching frequency: the switch is on while the
carrier is below it. Averaged over each carrier period, the output **is** the sine: 0.8 × 350 V =
**280 V**.

<!--
Deck 7 slide 31, regenerated: notebook 02 section 3.

Left: the gate pattern. The wanted voltage u is m sine of 2 pi 50 t, with m = 0.8. While u is
positive, D stays on and A pulses with the duty u; while negative, B stays on and C pulses. The
pulse width follows the sine: wide near the peak, narrow near the zero crossing. The carrier here
is 1 kHz, so the pulses are visible; a real inverter runs at 5 to 20 kHz.

Right: the output pulses between 0 and plus or minus 350 volts, and averaged over each carrier
period it is u times 350: a fundamental of 280 volts, dashed. The load current, 26.7 amperes, is
nearly a clean sine: the inductance averages the pulses.

That is what the average converter of section 04 says in one line: v out = d v in.
-->

---
routeAlias: harmonics
---

## Harmonics, and the switching frequency

<div class="grid grid-cols-2 gap-6 items-center">
<div>

![Spectrum of the PWM output over two cycles: the 280 V fundamental at 50 Hz, then clusters of switching harmonics around multiples of 1 kHz, the largest 119 V and 102 V at the carrier plus and minus 50 Hz. The current spectrum: 26.7 A at 50 Hz and only 2.0 A and 1.5 A in the switching harmonics, filtered by the inductance.](/figures/05-pwm-spectrum.svg)

</div>
<div>

![The load current over one cycle at two carrier frequencies. 1 kHz: visible ripple, largest switching harmonic 1.97 A, losses 13.0 W. 10 kHz: a clean sine, largest harmonic 0.18 A, losses 25.9 W.](/figures/05-pwm-carrier.svg)

</div>
</div>

PWM pushes the unwanted energy up to the carrier and its multiples, where the winding's inductance
blocks it. **Ten times the carrier:** a tenth of the ripple, and **twice the losses**.

<!--
The deck: any periodic waveform is a fundamental plus harmonics, found by Fourier analysis, and
higher harmonics increase the iron losses. Notebook 02 section 3, the spectrum and the carrier.

Left: the voltage spectrum. The fundamental, 280 volts at 50 Hz. Nothing until the carrier: the
switching harmonics sit in clusters around 1 kHz and its multiples, the largest 119 and 102 volts
at the carrier plus and minus 50 Hz. In the current they shrink to 2.0 and 1.5 amperes against the
26.7 ampere fundamental, because the inductance is a large impedance there: 63 ohms at 1 kHz
against 3 at 50 Hz.

Right: the same bridge at 1 and 10 kHz. Ten times the carrier puts the harmonics ten times higher,
where the inductance is ten times the impedance: the largest switching harmonic falls from 1.97 to
0.18 amperes. The price is ten times as many edges: the losses double, 13.0 to 25.9 watts. EV
inverters settle at 5 to 20 kHz, above hearing and before the switching loss dominates. What is
left still heats the motor's iron, as the deck warns.
-->

---
routeAlias: three-phase-bridge
---

## The three-phase bridge

<div class="diagram-wide">

![Three-phase bridge: three legs a, b and c on the 350 V pack, each with an upper and a lower switch and their freewheeling diodes; the leg midpoints feed the three windings, joined at a star point.](/diagrams/05-three-phase-bridge.svg)

</div>

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

Six switches with freewheeling diodes (deck): **each leg is half an H-bridge**. Three sine
references 120° apart make three-phase AC; field-oriented control chooses their amplitude and
phase.

</div>
<div>

This is the inverter in the car. Averaged over a switching period, it is section 04's converter:
*v* = *d* · *V*<sub>pack</sub>, a current limit, a field. ORNL ran the Leaf's at **5 kHz**.

</div>
</div>

<!--
Deck 7 slide 32, a diagram: no switched three-phase model in the notebook.

Three legs, one per phase. Each leg is half of the H-bridge: its midpoint is connected to the
positive or the negative rail, never both. The three windings meet at a star point, so the three
phase voltages only need to be set relative to each other. Three sine references, 120 degrees
apart, PWM'd as on the last slides: three sinusoidal currents in the windings.

Section 03's field-oriented control decides the amplitude and the phase of those three sines, from
the rotor angle, so the current sits on the q axis, or turns against the magnets above base speed.

The Leaf's inverter, as ORNL measured the 2012 car: 18 IGBT and 18 diode dies, three per switch,
tested at 375 volts DC and 5 kHz, peak efficiency above 99 percent at high speed. Our average
converter's 5 kHz and 1 microsecond edges land in that range.
-->

---
routeAlias: switching-demo
---

## Demo: the switching models

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

`notebooks/lecture04/02-switching.pluto.jl`

| Control | What to show |
|---|---|
| duty `d` | the buck's output follows *d* · 48 V |
| switching frequency | ripple ∝ 1/*f*<sub>s</sub>, switching loss ∝ *f*<sub>s</sub> |
| modulation index `m` | the fundamental follows *m* · 350 V |
| carrier frequency | harmonics move up, current cleans up, losses rise |

</div>
<div>

> **Never stack time scales.** The car's converter is an average; these models settle in a
> millisecond, and a WLTC lasts half an hour.

**Left out:** diode reverse recovery, dead time, heat, and the DC-link capacitor; the switch's edge
is an effective time, not a datasheet one.

</div>
</div>

<!--
Five minutes, live, if the room has time; otherwise the figures on the last slides are the
notebook's outputs at their defaults.

Open the notebook in Pluto. Move the duty: the buck's output voltage follows d times 48. Move the
switching frequency from 5 to 100 kHz: the ripple shrinks, the switching loss bar grows. In
section 3, the modulation index: the fundamental of the bridge's output follows m times 350
volts; push m to 20 and the pulses merge into section 2's square wave. The carrier from 1 to 10
kHz: the spectrum's clusters move up, the current turns into a clean sine, the loss doubles.

The notebook's own list of what the models leave out: the diode stops conducting the instant its
voltage reverses, with no reverse recovery; the deck's gate pattern needs no dead time; the
switches dissipate into a fixed temperature; the DC link is a stiff source rather than a
capacitor. And the switching-loss shape: the resistance ramp gives the textbook V I t over 2 of an
edge 0.22 t sw long, so t sw is an effective edge time.
-->

---
routeAlias: dcdc-and-charger
---

## The 12 V DC-DC, and the charger

<div class="grid grid-cols-2 gap-8">
<div>

### DC-DC: the pack feeds the 12 V network

Lights, pumps, electronics run on 12 V. An isolated DC-DC converter steps the pack's 350 V down
to it, and replaces the alternator.

**In the model:** a constant **300 W** draw on the pack, `AuxLoad`. On WLTC: **6.4 Wh/km**, more
than the converter and the battery's resistance together.

</div>
<div>

### The charger: the grid fills the pack

AC from the grid, rectified and stepped to the pack's voltage: on board for AC charging, in the
station for DC fast charging.

**In the model:** one efficiency. ANL measured **86–87 %** for the 2013 Leaf's on-board charger;
the bill counts **13 %** lost on the way in.

</div>
</div>

<div class="handson">Section 08 shows the bill at the battery and at the wall: 47.2 against 54.3 MJ/100 km.</div>

<!--
The two converters the plan places in the energy chain without modeling them in detail (S4).

The DC-DC: every car still has a 12 volt network for lights, wipers, pumps, the ECUs. An electric
car has no alternator; an isolated DC-DC converter takes the pack's voltage down to 12 and charges
a small 12 volt battery. In the model it is the constant 300 watt `AuxLoad` on the pack. Over the
WLTC's half hour that is 6.4 Wh per kilometer: more than the converter's 2.1 and the battery's
3.1 together. A heater at 3 kW would add 64.

The charger: AC from the grid, rectified, power-factor corrected and converted to the pack's
voltage. Argonne measured the 2013 Leaf's on-board charger at 86 to 87 percent, and the overall
AC to DC-out chain at 82 to 85. The energy bill assumes 13 percent charging loss to put the car at
the wall. That is also why official consumption figures, measured at the wall, sit 10 to 15
percent above a model's battery energy.
-->

---

## Summary of section 05

- A switch is ideally lossless; averaged, **v = d · V<sub>in</sub>**. The buck steps down, the
  boost steps up, both with a switch, a diode and an inductor.
- Real switches lose at every edge and while conducting; a buck's diode can be the largest loss.
- The H-bridge makes AC; **PWM** shapes it into a sine and pushes the harmonics up to the carrier,
  where the winding's inductance blocks them.
- Three legs make the three-phase inverter: **section 04's converter**, averaged.
- The 12 V network is a 300 W draw on the pack; the charger, one efficiency.

### Next: the source behind the converter. <Link to="batteries">→ 06, batteries, simply</Link>

<!--
One minute. The switching detail is now out of the way: in the car it is one average converter.
Behind it sits the pack, the last link of the chain to build.
-->
