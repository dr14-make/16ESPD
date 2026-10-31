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
Budget: about 30 minutes, of which build 02 takes about 15: the converter 3, base speed and field
weakening 4, the efficiency map 3, against ORNL 2, WLTC on the map 3, build 02 15. New material:
deck 7 has no envelope slide; the plan adds it because every EV spec sheet has one.
-->

---
routeAlias: average-converter
---

## The converter, averaged

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

Between the pack and the machine sits the inverter. Averaged over one switching period it is one
number, the **duty** *d*:

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
The switching inverter of section 05, averaged. Over one switching period of 200 microseconds the
switches give the machine the fraction d of the pack voltage, and draw the fraction d of the
machine current from the pack. Without losses it is a DC transformer: power in equals power out.

The current limit, 332.2 amperes, is the current at which step 01's machine gives 320 newton
meters at base speed. The duty limit, 1, says the converter cannot give more than the pack's
voltage. The current follows its command through a first-order lag of a millisecond: the
inverter's current loop.

The losses are the deck's: two devices carry the current at any instant, 0.6 volts each, the
conduction loss; and each edge costs a little energy, the switching loss, proportional to the
switching frequency. ORNL ran the Leaf's inverter at 5 kHz; 1 microsecond edges put the efficiency
in ORNL's measured 96 to 99 percent. At the corner point, 350 volts and 332.2 amperes: 0.98 kW
lost of 117.25 kW in, 99.2 percent.

In the car this is `Vehicle.Electric.Converter`; the switching models of section 05 justify it.
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

At **3283 rpm**, *d* = 1: the voltage has run out.

**Above it:** hold *V* and *I*<sub>max</sub>, turn Φ down as 1/ω: torque ∝ 1/ω, power
**110.75 kW** in the air gap.

| rpm | field | shaft torque |
|---:|---:|---:|
| 5000 | 0.66 | 209 N·m |
| 10 000 | 0.328 | 103.8 N·m |

</div>
</div>

<!--
The figure is notebook 01, the efficiency-map notebook, its envelope plot: build 02's converter
driving build 01's machine at the current limit, from standstill to 10 000 rpm. It lands with the
efficiency-map notebook.

Below base speed: the converter is asked for more than 332.2 amperes and gives its limit. To push
that current the machine needs K Phi omega plus R I max volts, and the converter lowers its duty
to give exactly that: at standstill 16.6 volts, a duty of 0.047; at 1900 rpm 0.60. The torque is
flat: 322.1 newton meters in the air gap, 320 at the shaft.

At 3283 rpm the duty reaches 1. That is the base speed, the corner of the envelope.

Above it, the only way to keep the current flowing is to lower the back-EMF, and the only part of
it left is Phi: field weakening. Hold 350 volts and 332.2 amperes, and K Phi omega must stay at
333.4 volts, so Phi falls as 1 over omega, the torque with it, and the power E times I stays at
110.75 kW: the constant-power hyperbola. At 5000 rpm the field is 0.66 and the shaft gives 209
newton meters; at 10 000, 0.328 and 103.8. The shaft power slips from 110.0 to 108.7 kW as
friction, iron and windage grow with speed.

The Leaf's spec sheet says exactly this: 320 newton meters from 0 to 3283 rpm, 110 kW from 3283 to
9795 rpm.
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
The figure is notebook 01, the efficiency map: build 02's machine and converter held at each
point of a grid of torque and speed inside the envelope, with the efficiency computed from the
model's own powers. It lands with the efficiency-map notebook.

Three regions, each explained by section 02's losses. At low speed and high torque the current is
high and the output small: the copper loss, proportional to torque squared, wins. At very light
load the output is small and the friction, iron, windage and constant losses are not: the
efficiency collapses. In between, at mid speed and mid torque, the peak.

The map is a result, not an input. That is the plan's decision S3: since the copper loss lives in
the armature resistance, a measured map on top would count it twice.
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
The figure is notebook 01: the model's map beside the anchor points read from Oak Ridge National
Laboratory's benchmark of the 2012 Leaf's motor and inverter, 375 volts DC link, 5 kHz, coolant
at 65 degrees. It lands with the efficiency-map notebook.

The anchors, from the plan: combined motor and inverter 94 to 96 percent at mid speed and torque;
about 80 at low speed and high torque; 70 to 80 near zero torque. ORNL's points were read by eye
from contour labels, plus or minus one percentage point.

The caveat is on the slide and matters: ORNL measured the first-generation motor, 80 kW and 280
newton meters, not the 110 kW ZE1 machine the model is sized for. So we compare the shape, where
the peak sits and how it falls off, and the level, not the contours point by point. The model's R
was chosen so the levels land in ORNL's range.
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

The driver never asks for more than **117 N·m** on WLTC, a third of the peak; braking, at most
**87 N·m**.

At 131 km/h the machine turns **9260 rpm**, the field down to **0.36**.

> **Light-load efficiency matters more than peak efficiency.** The car spends the cycle where the
> fixed losses count.

</div>
</div>

<!--
The figure is notebook 01: the efficiency map with the operating points of step 04's car over the
WLTC on top. It lands with the efficiency-map notebook.

Read where the dots are. The WLTC is a gentle cycle: the driver in step 04 never asks for more
than 117 newton meters, about a third of the 320 the machine can give; under braking at most 87
newton meters (step 05). Most of the cycle is cruising and gentle acceleration at a few tens of
newton meters, well below the peak island.

So the number that decides the energy bill is not the peak efficiency in the brochure; it is the
efficiency at light load, where the fixed losses, friction, iron, windage, constant, weigh most.
That is also the PMSM's advantage over the induction machine from section 03.

Speed: below about 48 km/h the field is full; at the cycle's top speed of 131 km/h the machine
turns 9260 rpm with the field at 0.36.
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
Fifteen minutes: three code pastes, a bench of eight blocks, one long run, a few variations. The
guide page, step 02, has every line; the snippet on the slide is shortened.

1. `FieldEMF`: the stdlib EMF with a field input, so E = field times K Phi omega and T = field
   times K Phi i. Paste from the guide.
2. `DCMachine` gets a `field_weakening` switch and a `field` input wired to the new EMF. With the
   switch off it is step 01's machine, unchanged.
3. `Converter`: paste. The current loop, `T_i der(i_out) = i_cmd - i_out`, with the command
   clipped to plus or minus I max; the duty is whatever the machine needs to carry that current;
   and the either-or relation: either the field is full or the duty is at its limit. It is
   written with the corner of min rounded by 1e-4, so the solver meets no kink at base speed.
4. `ConverterDyno`: the step 01 dyno with the converter in between and a constant current command
   of 500 amperes, more than the limit, so the converter gives its 332.2. The dyno ramps from 0 to
   10 000 rpm over 100 seconds.

Expected, from `HandsOn04.ConverterDynoTransient`: 332.2 amperes from the first milliseconds. At
standstill d is 0.047: 16.6 volts push 332.2 amperes through 0.05 ohm. Up to base speed the field
stays 1, the duty rises in a straight line, 0.60 at 1900 rpm; the air-gap torque holds 322.1, the
shaft gives 319.1 at 1900 rpm, the losses and the 0.52 newton meters the dyno spends accelerating
the rotor taken off. Near 95 rpm the shaft torque dips to 300: the constant 200 watt loss is a
torque C over omega, 20 newton meters there.

The duty reaches 1 at 3283 rpm and the field starts to fall: 0.66 at 5000 rpm, 209 newton meters;
0.328 at 10 000, 103.8. The air-gap power is 110.75 kW all the way; the shaft's slips from 110.0
to 108.7. At the end P in 117.25 kW, P out 116.27, P loss 0.98, 99.2 percent. Held at 3283 rpm,
rpm start equal to rpm end: 320.0 newton meters, 110.0 kW.

Variations in the guide: 300 volts moves the corner to 2791 rpm and the power to 94.1 kW in the
air gap, as a sagging pack will in step 03. 150 amperes: 145.5 newton meters up to 3373 rpm.
Minus 500 amperes, braking: above 3610 rpm the converter weakens the field here too; at 10 000
rpm P in is minus 115.3 kW, power flowing back into the supply; at standstill the supply pays the
copper loss, plus 6.5 kW.

Testsets: `test/converter_plausibility.jl`.
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

### Next: what is inside the converter. <Link to="power-electronics">→ 05, power electronics</Link>

<!--
One minute. The converter in the car is an average. The next section opens it up: switches,
diodes, pulse-width modulation, on a microsecond time scale, beside the car rather than in it.
-->
