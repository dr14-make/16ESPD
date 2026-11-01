---
routeAlias: envelope
layout: section
---

###### Section 04

# The envelope

Constant torque, field weakening and constant power; the efficiency map, and where the WLTC
drives on it.

`notebooks/lecture04/01-efficiency-map.pluto.jl`

<!--
Section 04, the envelope. Every electric car's spec sheet shows the same shape: constant torque up
to a base speed, then constant power, with the torque falling as the speed rises. In this section we
see where that shape comes from: the converter's current limit, its voltage limit, and field
weakening. Then we compute the efficiency map of our machine, compare it with a measured Leaf, and
see where the WLTC drives on it. The figures come from notebook 01, the efficiency-map notebook, and
you build the converter at the end.
-->

---
routeAlias: average-converter
---

## The converter, averaged

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

Between the pack and the machine sits the inverter; section 05 opens up its switches. Averaged
over one switching period it is one number, the **duty** *d*:

$$
v_{out} = d\, v_{in} \qquad i_{in} = d\, i_{out} + \frac{P_{loss}}{v_{in}}
$$

with two limits:

$$
|i_{out}| \le I_{max} \qquad |d| \le d_{max} = 1
$$

and the deck's switch losses:

$$
P_{loss} = V_{on}\,|i_{out}| + f_s\, t_{sw}\, v_{in}\,|i_{out}|
$$

</div>
<div class="tight">

| | Value | From |
|---|---|---|
| *I*<sub>max</sub> | 332.2 A | 320 N·m at base speed |
| *d*<sub>max</sub> | 1 | no more than the pack's voltage |
| *T*<sub>i</sub> | 1 ms | current loop |
| *V*<sub>on</sub> | 1.2 V | two devices, 0.6 V each (deck) |
| *f*<sub>s</sub>, *t*<sub>sw</sub> | 5 kHz, 1 µs | ORNL ran the Leaf inverter at 5 kHz |

At 350 V out and 332.2 A: **99.2 %** efficient.

</div>
</div>

<!--
Between the pack and the machine sits the inverter. Section 05 opens it up; here we average it. Over
one switching period, 200 microseconds at 5 kilohertz, the switches give the machine the fraction d
of the pack voltage. d is the duty, a number between 0 and 1. That is the first formula: v out
equals d times v in. The input current, the second formula, is d times the output current, plus the
loss power divided by the input voltage: the extra current that pays for the losses. Without its
losses the converter is a DC transformer: power in equals power out.

Then the two limits. The output current is at most I max, in either direction, and the duty is at
most d max, which is 1.

And the deck's switch losses, the last formula. A conduction loss, V on times the current, where V
on is the voltage across the devices that carry it. Plus a switching loss, f s times t sw times v in
times the current, where f s is the switching frequency and t sw the time each edge takes: every
edge costs a little energy, so this loss grows with the switching frequency.

The table says where each number comes from. I max, 332.2 amperes, is the current at which build
01's machine gives 320 newton meters at base speed. d max is 1: the converter cannot give the
machine more than the pack's voltage. T i, 1 millisecond, is the time constant of the inverter's
current loop: the output current follows its command with a lag that short. V on is 1.2 volts: at
any instant two devices carry the current, 0.6 volts each, the deck's number. And f s and t sw are 5
kilohertz and 1 microsecond. Oak Ridge ran the Leaf's inverter at 5 kilohertz, and 1 microsecond
edges put the converter's efficiency in the 96 to 99 percent Oak Ridge measured.

The number at the bottom: at 350 volts out and 332.2 amperes, the loss is 332.2 amperes times 1.2
volts plus 5000 times 1 microsecond times 350 volts, that is 332.2 times 2.95 volts, 0.98 kilowatts.
Out of 117.25 kilowatts in, that is 99.2 percent.

In the car this is `Vehicle.Electric.Converter`, and you build it in step 02.
-->

---
routeAlias: base-speed
class: big-figure
---

## Where the voltage runs out

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Shaft torque and power against machine speed along the envelope: 320 N·m from standstill to the base speed of 3283 rpm, then torque falling as 1/ω while the power holds near 110 kW, field weakening marked above base speed.](/figures/04-envelope.svg)

</div>
<div class="text-[0.95rem]">

**Up to base speed:** the current is at its limit, the duty rises with the back-EMF:

$$
d\,V = K\Phi\,\omega + R\,I_{max}
$$

At **3283 rpm**, *d* = 1: the voltage has run out. That is **base speed**, the envelope's
corner.

**Above it:** hold *V* and *I*<sub>max</sub>, turn Φ down as 1/ω: torque ∝ 1/ω, power
**110.75 kW** in the air gap.

| rpm | field | shaft torque |
|---:|---:|---:|
| 5000 | 0.66 | 209 N·m |
| 10 000 | 0.328 | 103.8 N·m |

</div>
</div>

<!--
Where does the voltage run out? The figure is notebook 01's envelope: build 02's converter driving
build 01's machine at the current limit, from standstill to the machine's top speed. Two panels
share the horizontal axis, the machine speed in rpm. The top panel is the shaft torque in newton
meters, the bottom one the shaft power in kilowatts. The black dashed vertical line is base speed,
the dotted one at the right the maximum speed, 10 100 rpm. The blue-tinted region left of base speed
is labeled constant torque, full field, duty rising. The orange-tinted region right of it is labeled
field weakening, constant power, duty at 1, field falling as 1 over omega. The thin gray dashed
curve in the top panel is a pure 1 over omega curve, for comparison.

Below base speed the converter is asked for more than its 332.2 amperes and gives its limit. To push
that current, the machine needs its back-EMF plus the drop across R, and that is the formula on the
right: d times V equals K Phi omega plus R times I max. The converter sets its duty to give exactly
that. At standstill there is no back-EMF, so it takes only 0.05 times 332.2, 16.6 volts, a duty of
0.047. As the speed rises, the duty rises with the back-EMF. The torque is flat: 322.1 newton meters
in the air gap, 320 at the shaft. The small dip just above standstill is the constant 200 watt loss,
a torque C over omega, which is large at very low speed; below about 95 rpm the model fades it out,
so a machine at standstill has no infinite drag.

At 3283 rpm the duty reaches 1: the converter gives the machine all of the pack's 350 volts, and the
voltage has run out. That is base speed, the envelope's corner, as the slide says, and the dashed
line in the figure.

Above base speed the only way to keep the current flowing is to lower the back-EMF, and the only
part of K Phi omega left to lower is Phi: field weakening. Hold 350 volts and 332.2 amperes, and K
Phi omega must stay at 350 minus 16.6, 333.4 volts. So Phi falls as 1 over omega, the torque, K Phi
times I, falls as 1 over omega with it, and the power in the air gap, E times I, 333.4 volts times
332.2 amperes, stays at 110.75 kilowatts. That is the constant-power hyperbola. The table gives two
points on it: at 5000 rpm the field is 0.66 and the shaft gives 209 newton meters; at 10 000 rpm the
field is 0.328 and the shaft gives 103.8. In the bottom panel the shaft power is 110.0 kilowatts at
base speed and slips to 108.7 at 10 000 rpm, because friction, iron loss and windage grow with speed
while the air-gap power stays put.

Nissan's spec sheet says exactly this: 320 newton meters from 0 to 3283 rpm, and 110 kilowatts from
3283 to 9795 rpm.
-->

---
routeAlias: efficiency-map
class: big-figure
---

## The efficiency map

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Contours of machine-plus-converter efficiency over shaft speed and torque, inside the envelope: highest at mid speed and mid torque, lower at low speed and high torque, and falling steeply toward zero torque.](/figures/04-efficiency-map.svg)

</div>
<div class="text-[0.95rem]">

Sweep the machine of steps 01–02 over torque and speed, and read η = *P*<sub>shaft</sub> /
*P*<sub>in</sub> from its own parts.

- **Mid speed, mid torque:** the peak.
- **Low speed, high torque:** copper loss, ∝ *T*².
- **Near zero torque:** the fixed losses dominate a small output.

Nothing is looked up: the copper loss is in the resistor, the rest in the shaft parts.

</div>
</div>

<!--
The efficiency map. Notebook 01 runs build 02's machine and converter on the dyno once for each
output current, from minus 332 to plus 332 amperes, 63 ramps in all. Every saved point is a steady
operating point, and at each one the efficiency is computed from the model's own powers: shaft power
over the power drawn from the DC link while motoring, and the other way round while generating. That
is the first sentence on the right: eta equals P shaft over P in, read from the machine's own parts.

Read the figure. The horizontal axis is the machine speed in rpm, the vertical axis the shaft torque
in newton meters. Above zero the machine is motoring, below zero it is generating, and the two
halves are nearly mirror images. The color is the combined efficiency of machine and converter in
percent, from dark purple at 70 to yellow at the top, on the color bar at the right. The thin black
lines are contours, each labeled with its efficiency, from 70 up to 95 percent. The heavy black
curves are the envelope from the last slide, at the top and at the bottom; outside it the map is
white.

Three regions, each explained by section 02's losses. Mid speed and mid torque: the peak, just under
96 percent. Low speed and high torque, the lower left of the upper half: the current is high and the
output power small, and the copper loss, proportional to the torque squared, wins. Near zero torque,
the band along the zero line: the output is small but the friction, iron, windage and constant
losses are not, so the efficiency collapses.

The last line on the right is the point of the map: nothing is looked up. The copper loss is in the
resistor, the rest in the shaft parts. The map is a result of the model, not an input to it.
-->

---
routeAlias: against-ornl
class: big-figure
---

## Against a measured Leaf

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![The model's efficiency contours beside ORNL's measured motor-and-inverter map of the 2012 Leaf: the same shape, the peak at mid speed and mid torque, lower at low speed and high torque and near zero torque.](/figures/04-ornl-comparison.svg)

</div>
<div class="text-[0.95rem] tight">

| ORNL, motor + inverter | Measured |
|---|---|
| peak, mid speed, mid torque | 94–96 % |
| low speed, high torque | ≈ 80 % |
| near-zero torque | 70–80 % |

ORNL measured the **first-generation 80 kW, 280 N·m** motor (2012 Leaf), not the 110 kW ZE1. The
comparison is of **shape and level, not a fit**.

</div>
</div>

<!--
How does this compare with a real Leaf? Oak Ridge National Laboratory benchmarked the 2012 Leaf's
motor and inverter on a dyno and published their combined efficiency map, measured at a 375 volt DC
link, 5 kilohertz switching, and coolant at 65 degrees Celsius.

The figure has two panels with the same axes, machine speed in rpm and shaft torque in newton
meters, and the same colors and contour levels as the last slide, motoring only. Left: our model,
machine plus average converter, at 350 volts. Right: Oak Ridge's map, redrawn from values digitized
from their published figure and smoothed a little to wash out the contour labels. The heavy black
line on the right is the edge of what Oak Ridge tested. The gray dashed curve in both panels is the
80 kilowatt line, the first-generation motor's power.

The table gives the three bands the plan reads from Oak Ridge's map: 94 to 96 percent at mid speed
and mid torque; about 80 percent at low speed and high torque; 70 to 80 percent near zero torque.
Those points were read by eye from the contour labels, to within about a percentage point.

The shapes agree. The efficiency climbs steeply out of the low-speed, high-torque corner; a plateau
above 90 percent covers most of the map from about 2000 rpm; and it collapses toward the zero-torque
axis. In the middle of the map the two agree to about a point. The differences are worth a look. Oak
Ridge's 96 percent island sits at 6000 to 9000 rpm, just under the 80 kilowatt line, where the model
gives 94; the model's own peak, 95.8 percent, sits at 3000 to 4500 rpm, because its iron loss and
windage grow with speed with nothing to offset them. At low speed and high torque the model is 4 to
6 points better than Oak Ridge: our converter's losses track only the current, while a real inverter
does worse at low output voltage. At 1900 rpm and light load the model is 8 points worse: its
constant 200 watts, friction and iron loss weigh heavily against 2 kilowatts of output. And our
machine is larger, 320 newton meters and 110 kilowatts against 280 and 80, so its envelope is wider.

The caveat on the slide matters. Oak Ridge measured the first-generation motor, 80 kilowatts and 280
newton meters, not the 110 kilowatt ZE1 machine our model is sized for. So we compare shape and
level, where the peak sits and how it falls off, and not the contours point by point. It is not a
fit: R was chosen so that the levels land in Oak Ridge's range, and that is all.
-->

---
routeAlias: wltc-on-the-map
class: big-figure
---

## Where the WLTC drives

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![The efficiency map with the WLTC's operating points of the Leaf-class car on top: most of them at low torque, well below the peak region, spread over speed.](/figures/04-efficiency-map-wltc.svg)

</div>
<div class="text-[0.95rem]">

On WLTC the driver never asks for more than **117 N·m** (step 04's car), a third of the peak;
braking, at most **87 N·m** (step 05's car, the one on the map).

At 131 km/h the machine turns **9260 rpm**, the field down to **0.36**.

> **Light-load efficiency matters more than peak efficiency.** The car spends the cycle where the
> fixed losses count.

</div>
</div>

<!--
Where does the car actually drive on this map? Notebook 01 runs the finished car of build 05 over
the WLTC class 3b and reads the machine's speed and torque once a second. Each dot is one second of
the cycle: white dots while driving, orange-red dots while regenerating. Behind them is the 350 volt
map from two slides back, with the same axes and colors.

Look where the dots are. They spread over speed, but they hug the bottom of the map. The WLTC is a
gentle cycle: on build 04's car the driver never asks the machine for more than 117 newton meters,
about a third of the 320 it can give, and on build 05's car, the one these dots come from, braking
asks for at most 87 newton meters. Most of the cycle
is cruising and gentle acceleration at a few tens of newton meters, well below the peak region,
where the fixed losses take their share.

The speed: below about 48 kilometers per hour the field is full. At the cycle's top speed, 131
kilometers per hour, the machine turns 9260 rpm, with the field down to 0.36.

So the number that decides the energy bill is not the peak efficiency in the brochure. It is the
efficiency at light load, where friction, iron loss, windage and the constant loss weigh most. That
is the quote box, and it is also the PMSM's advantage over the machines without magnets from
section 03.
-->

---
routeAlias: fast-machine
---

## Why a fast machine behind a reduction

<img src="/figures/04-power-lines.svg" class="mx-auto" style="max-height: 20rem" alt="Left: the motoring half of the efficiency map with three constant-power lines, 10, 30 and 60 kW, falling as 1 over speed. Right: the combined efficiency along each line against speed: it climbs steeply out of low speed, peaks at 92.6 % near 2150 rpm for 10 kW and at 95.5 % near 3400 rpm for 30 and 60 kW, and falls slowly above."/>

<div class="grid grid-cols-2 gap-8 text-[0.9rem]">
<div>

**Same power, more speed, less torque:** less current, and copper loss ∝ *T*². At 30 kW:
**84.0 %** at 1000 rpm, **95.5 %** at 3400, 91.5 % at 10 000 (derived). Torque, not power, sizes a
machine, so a fast one behind **8.193** is smaller for the same power.

</div>
<div>

**Peak is not continuous:** 110 kW for seconds; **85 kW** rated output (Nissan), 90 kW continuous
in the Dutch register (RDW). Heat sets the difference, and the model has none: section 09.

</div>
</div>

<!--
Why does an electric car use a fast machine behind a reduction gear, rather than a slow machine
driving the wheels directly? The figure is notebook 01's efficiency map again, with lines of
constant power drawn on it.

Left panel: the motoring half of the map from three slides back, machine speed in rpm across, shaft
torque in newton meters up, the same colors and contours, the black envelope on top. The three
colored curves are constant power: white 10 kilowatts, red 30, blue 60. Power is torque times speed,
so at constant power the torque falls as 1 over the speed, and each line is a hyperbola. Each line
starts where it leaves the envelope: 60 kilowatts needs more than 320 newton meters below about
1800 rpm.

Right panel: the combined efficiency of machine and converter along each line, read from the
swept map, against the same speed axis, in percent. The dot marks each line's best point. Read the
red one, 30 kilowatts. At 1000 rpm the machine has to give about 290 newton meters, and the
efficiency is 84.0 percent. At 3400 rpm the same 30 kilowatts takes only 84 newton meters, and the
efficiency is 95.5 percent, the line's best. Above that it falls slowly, to 91.5 percent at 10 000
rpm. The 60 kilowatt line has its best, also 95.5 percent, at the same 3400 rpm; the 10 kilowatt
line peaks at 92.6 percent near 2150 rpm. These are model numbers, read from the map in the
notebook, so I tag them derived.

Why the steep climb? Same power, more speed, means less torque, less current, and the copper loss
goes with the current squared, so with the torque squared. Halve the torque and the copper loss
drops to a quarter. Past the best point, the iron loss and windage, which grow with speed, take
some of it back, which is why the lines bend down slowly; a real machine's peak sits higher in
speed, as Oak Ridge's map showed.

The last sentence on the left is the design argument. A machine's size is set by its torque: the
current its windings carry and the magnetic flux its iron holds. Power is torque times speed, so
for the same power a fast machine needs less torque and is smaller and lighter. The reduction gear
then turns the high speed into wheel torque: 8.193 times. That is why the Leaf's machine turns up
to about 10 000 rpm.

On the right, a second point about ratings. The 110 kilowatts on the spec sheet is a peak, which the
machine can give for seconds, not for half an hour. What it can give continuously is set by heat:
how fast the windings and magnets shed their losses into the coolant. Nissan's Japanese
specification sheet for the 40 kilowatt-hour Leaf lists a rated output, teikaku shutsuryoku, of 85
kilowatts beside the 110 kilowatt maximum. The Dutch vehicle register, RDW, records 90 kilowatts as
the nominal continuous maximum power for most registered Leaf 40 kilowatt-hour cars. The two
sources do not say which test they follow, and they do not agree, so read both as roughly 85 to 90
kilowatts. For type approval in Europe the test is UN Regulation 85, whose maximum 30 minutes power
is the average power a drive train holds for 30 minutes. And Oak Ridge ran the first-generation 80
kilowatt motor at its full 80 kilowatts continuously at 7000 rpm, with the stator temperature
leveling out at about 135 degrees Celsius.

Our model has no temperatures at all, so it would hold 110 kilowatts forever. That is one of the
known limits in section 09.
-->

---
routeAlias: build-converter
---

## Build 02: the converter, and field weakening

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<img src="/img/lecture-04/step02-converter-dyno.png" class="mx-auto" style="max-height: 21rem" alt="The finished ConverterDyno in Studio: current into the top of converter; supply into converter.p_in, converter.p_out into machine.p; converter.n, machine.n, supply.n and ground on one node; converter.field into machine.field; speed into dyno, both supports to mounts."/>

*New `FieldEMF` and `Converter`: paste from the guide · give `DCMachine` its field input ·
new `ConverterDyno`: `V` 350, `I_ref` 500, `rpm_start` 0, `rpm_end` 10 000 · `ConverterDynoTransient`,
102 s · ▷ once, then plot*

[page: step 02](../lecture/lecture-04/#step-02) · reference `dyad/HandsOn04/ConverterDyno.dyad`

</div>
<div class="stack">

```julia
r = MyCar.ConverterDynoTransient();
rpm = r.sol[r."machine.w"] .* 30 ./ pi;
plot(rpm[21:end], r.sol[r."machine.tau"][21:end])
plot(rpm[21:end], [r.sol[r."converter.d"][21:end]
     r.sol[r."converter.field"][21:end]]; label = ["d" "field"])
r.sol[r."converter.P_in"][end], r.sol[r."converter.P_loss"][end]
```

<div class="handson">✓ <code>converter.i_out</code> <b>332.2 A</b> throughout · <code>d</code>
<b>0.047</b> at standstill, 0.60 at 1900 rpm, <b>1 at 3283 rpm</b> · field 1 below it, <b>0.66</b>
at 5000 rpm, <b>0.328</b> at 10 000 · shaft <b>209 N·m</b> at 5000, <b>103.8 N·m</b> at 10 000 ·
air gap <b>110.75 kW</b></div>

<div class="handson">✓ at the end: <code>P_in</code> <b>117.25 kW</b>, <code>P_out</code> 116.27,
<code>P_loss</code> 0.98: <b>99.2 %</b> · held at 3283 rpm: <b>320.0 N·m</b>, 110.0 kW · 300 V:
corner at <b>2791 rpm</b></div>

</div>
</div>

<!--
Build 02: the converter, and field weakening. On the left, the finished bench in Studio. A constant
block named current feeds the converter's current command at the top. The supply feeds the
converter's input, p in, and the converter's output, p out, feeds the machine's p. The converter's
n, the machine's n, the supply's n and the ground all share one node, one negative rail. The
converter's field output goes into the machine's new field input. The speed ramp drives the dyno,
and both housings go to the mounts, as in step 01.

The steps, in the italic line. First, paste `FieldEMF` from the guide: the standard library's
rotational EMF with one more input, field, so that E equals field times K Phi omega and the torque
equals field times K Phi i. With field equal to 1 it is the element you had. Second, give your
`DCMachine` its field input: the new code has a switch, `field_weakening`, which creates the input
only when it is true. Left false, it is build 01's machine, unchanged. Third, paste `Converter`. Its
key lines are the current loop, T i times the derivative of the output current equals the command
minus the output current, with the command clipped to plus or minus I max; the duty, which is
whatever the machine needs to carry that current; and an either-or relation: either the field is
full, or the duty is at its limit. That relation is written with the corner of a minimum rounded off
by 10 to the minus 4, so that the solver meets no kink at base speed. Fourth, a new `ConverterDyno`:
the step 01 dyno with the converter in between. Its parameters are V, 350 volts; I ref, 500 amperes,
more than the converter gives, so that it delivers its limit and every point is a point of the
envelope; rpm start, 0; and rpm end, 10 000. The dyno holds standstill for a second, then sweeps to
10 000 rpm in 100 seconds, so the analysis, `ConverterDynoTransient`, runs 102 seconds. Run it once,
then plot.

The snippet plots the shaft torque against speed, then the duty and the field against speed, from
point 21 on: points are saved every 0.05 seconds, so the first 20 are the first second at
standstill. The last line reads the converter's input power and its loss at the end of the run.

The first green box is the envelope. The converter's output current is 332.2 amperes throughout. The
duty is 0.047 at standstill, 0.60 at 1900 rpm, and reaches 1 at 3283 rpm. The field is 1 below that,
0.66 at 5000 rpm, and 0.328 at 10 000. The shaft gives 209 newton meters at 5000 rpm and 103.8 at 10
000. And the air-gap power, the electromagnetic torque times the speed, stays at 110.75 kilowatts
above base speed.

The second green box. At the end of the run the input power is 117.25 kilowatts, the output 116.27,
the loss 0.98: 99.2 percent. If you hold the dyno at 3283 rpm, with rpm start equal to rpm end, the
shaft gives 320.0 newton meters, 110.0 kilowatts. And on 300 volts the voltage runs out sooner: the
corner moves down to 2791 rpm, and the air-gap power above it drops to 94.1 kilowatts. A sagging
pack does exactly that, as step 03 shows.

The guide has two more variations. At 150 amperes, the torque is 145.5 newton meters in the air gap
up to 3373 rpm, a slightly later corner, because less current needs less voltage across R. At minus
500 amperes, braking, the converter weakens the field above 3610 rpm too, and at 10 000 rpm the
input power is minus 115.3 kilowatts: power flowing back into the supply. At standstill there is no
back-EMF to brake with, so the supply pays the copper loss, 6.5 kilowatts.

One detail you may notice: near 95 rpm the shaft torque dips to 300 newton meters. That is build
01's constant 200 watt loss, a torque C over omega, 20 newton meters at that speed.
-->

---

## Summary of section 04

- The inverter, averaged: *v*<sub>out</sub> = *d* · *v*<sub>in</sub>, with a current limit and a
  duty limit; **99.2 %** at the corner.
- **Base speed** is where the duty reaches 1: 3283 rpm. Below it, constant torque; above it,
  **field weakening**: torque ∝ 1/ω, power constant.
- The efficiency map is computed from the machine's parts: peak at mid load, low at low speed and
  high torque, collapsing near zero torque. Against ORNL: shape and level.
- WLTC drives at light load: **light-load efficiency** decides the bill.
- At a given power, more speed means less torque and less copper loss: a fast machine behind a
  reduction. 110 kW is a peak; the continuous rating is set by heat.

### Next: what is inside the converter. <Link to="power-electronics">→ 05, power electronics</Link>

<!--
Section 04 in four lines. The inverter, averaged, is v out equals d times v in, with a current limit
and a duty limit, and 99.2 percent efficient at the corner. Base speed is where the duty reaches 1,
at 3283 rpm: below it, constant torque; above it, field weakening, with the torque falling as 1 over
omega and the power constant. The efficiency map is computed from the machine's own parts: its peak
at mid load, lower at low speed and high torque, collapsing near zero torque, and it matches Oak
Ridge's measured Leaf in shape and level. The WLTC drives at light load, so light-load efficiency
decides the bill. And at a given power, more speed means less torque and less copper loss, which
is why the machine is fast and sits behind a reduction; its 110 kilowatts is a peak, and what it
can give continuously is set by heat.

The converter in the car is an average. The next section opens it up: switches, diodes and
pulse-width modulation, on a microsecond time scale, beside the car rather than in it.
-->
