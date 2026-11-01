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
Section 05, power electronics. There is no build here, but a demonstration on switching models from
notebook 02. We cover DC regulation, the step-down and step-up choppers, the H-bridge, pulse-width
modulation and its harmonics, and the three-phase bridge; then the two other converters in the car,
the DC-DC for the 12 volt network and the charger.

One rule runs through this section, the same rule as in Lecture 2: never stack time scales. A
switching edge lasts a microsecond; a WLTC lasts 1800 seconds. So the car carries the average
converter of section 04, and the switching models run beside it, for a few milliseconds, to show
what the average hides. The notebook regenerates three of the deck's figures from running models:
the step-down chopper, the H-bridge and pulse-width modulation. The step-up chopper and the
three-phase bridge stay diagrams.
-->

---
routeAlias: dc-regulation
---

## DC regulation

<div class="grid grid-cols-2 gap-8">
<div>

The voltage of every source moves (deck): with time, temperature and load; the pack sags under
load (section 06). Electronics need a steady voltage.

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
Why regulate a voltage at all? The deck: the voltage of every source moves, with time, with
temperature and with load. Our own pack sags the moment it is loaded, as section 06 shows.
Electronics and motors need a voltage that suits them.

There are two ways to drop a voltage. A dropping device, a resistance or a linear regulator, burns
the difference as heat: to take 350 volts down to 100 at 100 amperes, it would turn 250 volts times
100 amperes, 25 kilowatts, into heat. The other way is a switching device: a switch that is either
fully on or fully off, many thousand times a second. Averaged over a period, the output is the duty
times the input. That is the formula on the right: the mean output voltage equals d times V in,
where d is the fraction of each period the switch is on.

An ideal switch loses nothing. When it is on there is no voltage across it, when it is off no
current through it, so the power in it, the product of the two, is always zero. A real switch loses
a little while it is on, the conduction loss, and a little at every edge, while it passes through
the middle and carries current and voltage at once, the switching loss.

The last line is about the notebook. The standard library has no switch, so the notebook's power
transistor is a resistance that the gate moves between 10 milliohms and 1 megaohm. The move takes a
finite time, which is where the switching loss comes from, and the switch has a 1 nanofarad output
capacitance so that the solver can follow the switching node.
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
The step-down chopper, also called a buck converter. On the left, the circuit: a 48 volt supply,
then the switch S, then the inductor L and the 0.7 ohm load. The freewheeling diode D runs from
ground up to the node between the switch and the inductor. When the switch is on, the supply drives
current through the inductor into the load. When it is off, the inductor keeps the current flowing,
because an inductor's current cannot stop suddenly, and the diode gives it a path up from ground.
The average output is d times V in.

On the right, the notebook's run of the library's `BuckChopper`, three switching periods in steady
state at 20 kilohertz, so each period is 50 microseconds, and the time axis is in microseconds.
Three panels, all in amperes. Top: the source current, through the switch. It flows only while the
switch is on, in the shaded intervals. Middle: the diode current. It flows only while the switch is
off. Bottom: the load current, their sum. It is continuous, with a small ripple: it rises while the
switch is on and falls while it is off, around the average the duty sets.

The line under the figures gives the design point: 48 volts down to 13 at 20 kilohertz, about 250
watts. That is the kind of converter that feeds a 12 volt bus from a 48 volt mild-hybrid battery.
The design point is assumed, not taken from a product. The duty is 0.3, so the textbook output would
be 14.4 volts; the simulated output sits lower, at about 13, because of the diode's drop during the
off time and the resistive drops. The diode is the library's exponential diode, 0.6 volts at 3.3
amperes and 0.8 volts at 20 amperes, the deck's 0.6 volt diode.
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
Where does a chopper lose its energy? Both figures are from notebook 02, section 1.

Left: a horizontal bar chart of the average losses in watts at the design point, 256 watts out and
93.6 percent efficient. The deck lists four losses, and in the model each one is a part with its own
power. From the largest: the diode, about 0.8 volts times the current, 10.62 watts; the inductor's
winding resistance, R L i squared, 3.66 watts; the switching loss, 2.08 watts; and the switch's
conduction loss, R on i squared, 1.07 watts.

The diode is the largest, and the text under the figures says why: 0.8 volts is a lot against a 13
volt output, and the diode conducts for 70 percent of every period, because the switch is on for
only 30. That is why low-voltage converters replace the diode with a second switch, which is called
synchronous rectification: at 10 milliohms and 19 amperes it drops 0.2 volts instead of 0.8. Notice
also that the switching loss already exceeds the switch's conduction loss at 20 kilohertz.

Right: the frequency sweep, 5 to 100 kilohertz on a logarithmic axis. The left panel is the current
ripple, peak to peak, in amperes. It falls as 1 over the switching frequency, the gray dashed line:
double the frequency and the ripple halves, or the inductor can be half the size. The right panel is
the losses in watts. The switching loss, in orange, is a fixed energy per edge, so it grows with the
frequency. The other three together, in gray, fall a little. The efficiency falls from 94.5 percent
at 5 kilohertz to 90.3 percent at 100. That is the designer's trade-off: a faster switch shrinks the
ripple and the inductor, and costs switching loss.
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
The step-up chopper, or boost converter. This one is a diagram; the notebook has no switched boost
model. It uses the same three parts, rearranged: the supply, then the inductor L; from the node
after the inductor, the switch S down to ground; and from that node the diode D to the output
capacitor C and the load.

When the switch is on, the supply drives a rising current through the inductor to ground, and the
inductor stores energy. When the switch opens, the inductor's current has to go on, and the only
path is through the diode into the capacitor. Now the inductor's voltage adds to the supply's, so
the output sits above the supply. Averaged, the output voltage is V in divided by 1 minus d. A duty
of one half doubles the voltage, and the closer d gets to 1, the higher the output.

Run it backwards, with the energy flowing from the high side to the low side, and a boost is a buck.
So one bidirectional converter can do both.

The last line: the Leaf has none. In the 2012 Leaf that Oak Ridge took apart, the inverter sits
straight on the pack, with no boost converter, and so does our car's converter.
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
The H-bridge turns DC into AC. On the left, four switches in the shape of an H, on a 350 volt DC
link, the Leaf pack's voltage. A and B are the upper switches, C and D the lower ones, and each has
a freewheeling diode across it. The load sits across the middle, between the midpoints a and b: 10
ohms in series with 10 millihenry, an assumed stand-in for a motor winding. With A and D on, a is at
the positive rail and b at the negative one, so the load sees plus 350 volts. With B and C on, it
sees minus 350. The two switches of one leg must never be on together: that would short the pack.
The diodes give the inductive current a path whenever its switch opens.

On the right, the notebook's run of the library's `HBridge` in square-wave operation at 50 hertz,
over two cycles, with time in milliseconds. Top: the output voltage in volts, jumping between plus
and minus 350 every half cycle. The blue-shaded halves are A and D on, the red-shaded halves B and C
on. Bottom: the load current in amperes. In each half cycle it climbs toward 350 volts over 10 ohms,
35 amperes, with the load's time constant, L over R, 1 millisecond, so it rises and falls in
exponential curves.

That is the sentence under the figures: hold each pair on for half a cycle and you get a square
wave, and the load's inductance rounds its current. It is the crudest AC. Its fundamental is the
largest a bridge can make, but every odd harmonic comes with it: the third at a third of the
fundamental, the fifth at a fifth. A motor sees them as torque ripple and extra loss, and
pulse-width modulation, next, removes them. In the notebook this square wave is that same modulation
with its reference pushed far beyond 1, so the pulses merge.
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
Pulse-width modulation makes a sine out of the same bridge. Both figures are from notebook 02,
section 3, with a carrier of 1 kilohertz so that the pulses are visible, and a modulation index m of
0.8.

The idea is in the text under the figures. Compare the wanted voltage with a triangle at the
switching frequency, the carrier. The switch is on while the carrier is below the wanted value, so
in each carrier period it is on for a fraction equal to that value.

Left, the gate pattern over one 50 hertz cycle, 20 milliseconds. The top panel shows the size of the
reference, the black curve, u equals m times the sine of 2 pi 50 t, against the gray triangular
carrier. Below it are four panels, one per switch, each either on or off. While u is positive, D
stays on and A pulses, with a duty equal to u. While u is negative, B stays on and C pulses. The
pulses are wide near the peak of the sine and narrow near its zero crossings.

Right, the result. Top: the output voltage in volts. It pulses between 0 and plus or minus 350,
wider near the peaks. The orange dashed curve is its fundamental, the 50 hertz sine inside it: 280
volts amplitude, which is m times 350, 0.8 times 350. Bottom: the load current in amperes, nearly a
clean sine of 26.7 amperes amplitude with a small ripple, because the inductance averages the
pulses.

So, averaged over each carrier period, the output is the sine. That is what the average converter of
section 04 says in one line: v out equals d times v in. A real inverter switches at 5 to 20
kilohertz rather than 1.
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
What happens to the rest of the pulse train? The deck: any periodic waveform is a fundamental sine
plus harmonics, which Fourier analysis finds, and higher harmonics increase the iron losses in the
motor. Both figures are from notebook 02, section 3.

Left, the spectrum over two cycles. The horizontal axis is frequency in kilohertz. The top panel, in
blue, is the amplitude of each frequency in the output voltage, in volts; the bottom panel, in red,
the same for the load current, in amperes. First the fundamental: 280 volts at 50 hertz. Then
nothing until the carrier: the switching harmonics sit in clusters around 1 kilohertz and its
multiples. The largest are 119 and 102 volts, at the carrier plus and minus 50 hertz. In the current
they shrink to 2.0 and 1.5 amperes, against the 26.7 ampere fundamental. The inductance filters
them: its impedance, 2 pi f L, is 63 ohms at 1 kilohertz, against 3 ohms at 50 hertz.

Right, the load current over one cycle at two carrier frequencies. Top: 1 kilohertz, with visible
ripple; the largest switching harmonic is 1.97 amperes, and the bridge loses 13.0 watts. Bottom: 10
kilohertz, a clean sine; the largest harmonic is 0.18 amperes, and the bridge loses 25.9 watts.

That is the text under the figures. Pulse-width modulation pushes the unwanted energy up to the
carrier and its multiples, where the winding's inductance blocks it. Ten times the carrier frequency
puts the harmonics ten times higher, where the inductance is ten times the impedance, so the ripple
falls about tenfold. The price is ten times as many edges, and the losses double. Electric-car
inverters settle at 5 to 20 kilohertz, above hearing and before the switching loss dominates. What
ripple is left still heats the motor's iron, as the deck warns.
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
The three-phase bridge. This one is a diagram; the notebook has no switched three-phase model. Three
legs, a, b and c, on the 350 volt pack. Each leg has an upper and a lower switch, a plus and a
minus, each with its freewheeling diode, and each leg's midpoint feeds one winding. The three
windings meet at a star point.

As the deck says, it is six switches with freewheeling diodes, and each leg is half an H-bridge: its
midpoint is connected to the positive or to the negative rail, never both. Modulate the three legs
with three sine references, 120 degrees apart, and the windings carry three-phase AC. Section 03's
field-oriented control chooses the amplitude and the phase of those three sines, from the rotor
angle, so that the current sits on the q axis, or turns against the magnets above base speed.

On the right: this is the inverter in the car. Averaged over a switching period, it is section 04's
converter: v equals d times V pack, a current limit, and a field. Oak Ridge measured the 2012 Leaf's
inverter: 18 IGBT and 18 diode dies, three per switch, tested at 375 volts DC and 5 kilohertz, with
a peak efficiency above 99 percent at high speed. Our average converter's 5 kilohertz and 1
microsecond edges put it in that range.
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
The switching models, live, in `notebooks/lecture04/02-switching.pluto.jl`. The table lists the
controls and what each one shows. The figures on the last slides are the notebook's outputs at its
default settings.

Move the duty d: the buck's output voltage follows d times 48 volts, a little below it. Change the
switching frequency from 5 to 100 kilohertz: the ripple shrinks as 1 over f s, and the
switching-loss bar grows in proportion to f s. In section 3, move the modulation index m between 0.1
and 1: the fundamental of the bridge's output follows m times 350 volts. Change the carrier from 1
to 10 kilohertz: the spectrum's clusters move up, the current turns into a clean sine, and the
losses rise.

The quote box is the rule from the start of the section: never stack time scales. The car's
converter is an average. These switching models settle in a millisecond, and a WLTC lasts half an
hour.

The last lines say what the switching models leave out. Diode reverse recovery: the library diode
stops conducting the instant its voltage reverses, where a real one first conducts backwards for a
moment, which adds to the turn-on loss. Dead time: the deck's gate pattern never turns on both
switches of a leg together, so it needs none. Heat: the switches dissipate into a fixed temperature.
The DC-link capacitor: the DC link here is a stiff source. And the switch's edge is an effective
time: the resistance ramp gives the textbook switching energy of an edge 0.22 times t sw long, so t
sw is not a datasheet number.
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

**On the road** (EU): from the end of 2025, a pool of at least 400 kW, with a 150 kW point, every
60 km of the EU's core roads; 600 kW by the end of 2027.

</div>
</div>

<div class="handson">Section 08 uses that efficiency to put the bill at the wall.</div>

<!--
The two remaining converters in the energy chain, which we do not model in detail.

Left, the DC-DC converter. Lights, pumps and electronics still run on 12 volts. An electric car has
no alternator, so an isolated DC-DC converter steps the pack's 350 volts down to 12 and takes its
place. In the model it is one part, `AuxLoad`: a constant 300 watt draw on the pack, the whole 12
volt network. Over the WLTC that is 6.4 watt-hours per kilometer: 300 watts for the cycle's half
hour, spread over its 23.27 kilometers. That is more than the converter's 2.1 and the battery
resistance's 3.1 together.

Right, the charger. It takes AC from the grid, rectifies it and brings it to the pack's voltage. For
AC charging it sits on board; for DC fast charging it sits in the charging station. In the model it
is a single efficiency. Argonne National Laboratory measured the 2013 Leaf's on-board charger at 86
to 87 percent, and the whole chain, from the AC plug to the DC energy out of the battery, at 82 to
85 percent. The energy bill counts 13 percent lost on the way in.

The last lines on the right are the road. The EU's Alternative Fuels Infrastructure Regulation,
2023/1804, requires along the core trans-European roads a charging pool every 60 kilometers in each
direction: from the end of 2025 at least 400 kilowatts in total with at least one 150 kilowatt
point, and from the end of 2027 600 kilowatts with two such points. Those are DC chargers, with the
rectifier and the converter in the station, feeding the pack directly.

The green box points ahead: section 08 uses that efficiency to put the bill at the wall, 54.3
megajoules per 100 kilometers against 47.2 at the battery. It is also why official consumption
figures, which are measured at the wall, sit 10 to 15 percent above what a model integrates at its
battery.
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
Section 05 in five lines. A switch is ideally lossless, and averaged, v equals d times V in. The
buck steps down and the boost steps up, both with a switch, a diode and an inductor. Real switches
lose at every edge and while conducting, and in a buck the diode can be the largest loss. The
H-bridge makes AC, and pulse-width modulation shapes it into a sine and pushes the harmonics up to
the carrier, where the winding's inductance blocks them. Three legs make the three-phase inverter,
which, averaged, is section 04's converter. And the 12 volt network is a 300 watt draw on the pack,
the charger one efficiency.

With the switching out of the way, the converter in the car is one average model. Behind it sits the
pack, the last link of the chain to build.
-->
