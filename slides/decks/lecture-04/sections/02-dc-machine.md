---
routeAlias: dc-machine
layout: section
---

###### Section 02

# The DC machine

From the force on a wire to T = KΦI and E = KΦω; the losses, the efficiency, and the two ways to
control it.

`notebooks/lecture04/04-machine-battery-regen.pluto.jl`

<!--
Budget: about 30 minutes, of which build 01 takes about 15: force on a wire 3, the machine as a
circuit 3, the fixed supply 3, losses 4, control 2, build 01 15. Deck 7 slides 22 to 26.

Why a DC machine, when no electric car has one? Because a permanent-magnet machine under
field-oriented control, the machine in most electric cars, behaves exactly like it from the
outside: torque proportional to one current, back-EMF proportional to speed. Section 03 shows
why. So the DC machine is the honest model, and its two equations are the ones to remember.
-->

---
routeAlias: force-on-a-wire
---

## From F = BIL to T = KΦI

<div class="grid grid-cols-[1fr_1.1fr] gap-8 items-center">
<div>

![A coil of radius r between a north and a south pole, field B from left to right. The left conductor carries current into the page and is pushed down, the right one carries it out of the page and is pushed up, each with F = B I l; together they turn the coil: T = 2r B I l = KΦ I.](/diagrams/02-conductor-in-field.svg)

</div>
<div>

A wire of length *l* carrying current *I* across a field *B*: **F = B I l**.

Wound on a rotor of radius *r*, with *n* turns:

$$
T = 2 n r B l \cdot I = K\Phi \cdot I
$$

The same conductors moving at *ωr* through the same field:

$$
E = 2 n r B l \cdot \omega = K\Phi \cdot \omega
$$

**One constant does both jobs.** So the power balance closes:

$$
E\, i = K\Phi\, \omega\, i = T\, \omega
$$

</div>
</div>

<!--
Deck 7 slides 22 and 23. Read the picture: the field B runs from the north pole to the south
pole. The left conductor carries current into the page, the right one out of it. Each feels
F = B I l, at right angles to both the field and the wire: the left one down, the right one up.
Together they turn the coil, with a torque of the force times the radius, twice.

Everything in 2 n r B l is fixed by the build: the number of turns, the radius, the field, the
length. Call it K Phi. Then torque is K Phi times current. The deck writes T = Km Phi I.

The same conductors move through the same field at a speed omega r, so a voltage is induced in
them: the back-EMF, E = K Phi omega, with the same K Phi. That is not a coincidence, it is energy
conservation: the electrical power E times i that disappears into the back-EMF comes out as
mechanical power T omega.

A real machine has many coils and a field shaped so the torque stays constant as the rotor turns;
in a brushed machine the commutator switches each coil's current as it passes the poles. The two
equations stay.
-->

---
routeAlias: machine-as-a-circuit
---

## The machine as a circuit

<div class="diagram-wide">

![The DCMachine component: from terminal p, the armature resistance R 0.05 Ω (copper loss), the inductance L 0.5 mH and the back-EMF source E = KΦω, T = KΦi, a RotationalEMF, back to terminal n. The EMF drives the shaft: the rotor inertia J, then four loss torques on the housing (friction T_f, iron K_i, windage k_w ω², constant C/ω), out to the spline.](/diagrams/02-dc-machine.svg)

</div>

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

$$
v = R\,i + L\frac{di}{dt} + K\Phi\,\omega \qquad T_{em} = K\Phi\, i
$$

</div>
<div class="tight">

| *R* | *L* | *K*Φ | *T*<sub>f</sub>, *K*<sub>i</sub> | *C* |
|---|---|---|---|---|
| 0.05 Ω | 0.5 mH | 0.9697 N·m/A | 0.5, 1.0 N·m | 200 W |

</div>
</div>

<!--
This is the machine you paste in build 01, `DCMachine`, drawn. The armature is a chain from the
positive terminal: the resistance of the windings, their inductance, and the back-EMF source. The
stdlib's `RotationalEMF` is that source: it turns current into torque on its rotor and speed into
voltage, both through one constant k, which is K Phi.

On the shaft: the rotor's inertia, then four parts that each take a torque that depends only on
the speed, pushing back against the housing. They are the terms of the deck's loss formula, next
slides.

The numbers. R is 0.05 ohm, chosen so the efficiency lands on ORNL's measured Leaf motor map. L is
0.5 millihenry, so L over R is 10 milliseconds: the current settles within a few of those.
Friction and iron loss are 0.5 and 1.0 newton meters, windage 300 watts at the top speed, a
constant 200 watts at any speed. K Phi is not chosen: it is derived so that at 350 volts and
3283 rpm the shaft gives 320 newton meters. Solved, 0.9697 newton meters per ampere.

The copper loss lives in the resistor. That is why the efficiency map in section 04 is computed
from this machine and never looked up: a measured map on top would count the copper loss twice.
-->

---
routeAlias: fixed-supply
class: big-figure
---

## On a fixed supply: a straight line

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Shaft torque against machine speed on two fixed supplies. 350 V: from 320.0 N·m at 3283 rpm and 332.2 A the line falls to −304 N·m and −312 A at 3600 rpm, generating. 200 V: from 922 N·m at 1500 rpm and 953 A it falls with the same slope through zero near 1969 rpm. The Leaf's 320 N·m peak is a dashed line.](/figures/02-torque-speed.svg)

</div>
<div>

$$
i = \frac{V - K\Phi\,\omega}{R}
$$

The torque falls by (*K*Φ)²/*R* = **1.97 N·m per rpm**, to zero at **V/KΦ**: there the
back-EMF has caught up with the supply.

Faster than that, *E* > *V*: the current reverses and **the motor is a generator**.

On 200 V, at 1500 rpm: **922 N·m for 953 A**, three times the current at the Leaf's 320 N·m.

</div>
</div>

<!--
The figure is notebook 04, section 1, "The DC machine on a fixed supply": the library's
`DCMachineTransient`, the same dyno as build 01, twice. On 350 volts the dyno holds 3283 rpm, then
ramps to 3600. On 200 volts it ramps from 1500 to 2200.

Read the formula: with the supply fixed, the current is whatever the gap between supply and
back-EMF drives through the armature resistance. Torque is K Phi times that, so it is a straight
line in speed. Its slope is K Phi squared over R: 0.9697 squared over 0.05 is 18.8 newton meters
per radian per second, 1.97 per rpm. Steep: R is small.

At 350 volts the line passes the Leaf's 320 newton meters at 3283 rpm, by construction, and
reaches zero near 350 over K Phi, 3447 rpm. At 3600 rpm the back-EMF is 365.6 volts, above the
supply: the current is minus 312 amperes, the shaft takes minus 304 newton meters, and the machine
pushes energy back into the supply. That is regenerative braking, already in the first model.

The 200 volt line has the same slope and sits lower in speed. That is the deck's first way to
control a DC motor, by the voltage. But look at the current: at 1500 rpm, 953 amperes for 922
newton meters. A fixed supply cannot give the full torque at low speed without enormous current;
the converter of step 02 lowers the voltage and caps the current both.

The deck's slide 23 notes that real machines' low-speed torque is limited by the controller or by
the battery's internal resistance: that is exactly what steps 02 and 03 add.
-->

---
routeAlias: losses
class: big-figure
---

## Losses and efficiency

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Machine losses against speed on a log scale, at the converter's current limit of 332.2 A from standstill to 10 000 rpm: copper constant at 5.52 kW; iron and friction rising in proportion to speed, to about 1 kW and 0.5 kW; the constant loss flat at 200 W; windage rising as the cube of speed to about 300 W. Base speed 3283 rpm dashed.](/figures/02-losses.svg)

</div>
<div class="text-[0.95rem]">

The deck's loss formula, each term a part:

$$
P_{loss} = \underbrace{R\, i^2}_{\text{copper} \,\propto\, T^2} + \underbrace{T_f\,\omega}_{\text{friction}} + \underbrace{K_i\,\omega}_{\text{iron}} + \underbrace{k_w\,\omega^3}_{\text{windage}} + C
$$

$$
\eta = \frac{T\omega}{T\omega + P_{loss}}
$$

At 320 N·m and 3283 rpm: copper **5.52 kW**, shaft losses **0.73 kW**, **94.6 %**.

</div>
</div>

<!--
Deck 7 slide 24, the loss formula, term by term. Copper loss, the resistance of the windings: R
i squared, and since the current is proportional to the torque, the deck writes it Kc T squared.
Iron loss, hysteresis and eddy currents in the laminations: the deck takes it proportional to
speed. Friction in the bearings, also proportional to speed as a power. Windage, air drag on the
rotor, as the cube. And a constant, the power the electronics and the cooling take.

The figure is notebook 04, section 2: the machine run along its whole envelope at the current
limit, 332.2 amperes, on build 02's converter bench, with each loss read from its own part. The
axis is logarithmic. At full current the copper loss dominates everywhere: 5.52 kilowatts. The
speed terms grow under it: at base speed iron 344 watts, friction 172, the constant 200, windage
10; at 10 000 rpm windage has grown to 300 watts.

At part load the picture changes: the current falls with the torque, and the copper loss with its
square. Halve the torque and the copper loss is a quarter; the speed terms stay. That is why a
machine is least efficient at very light load, and why the efficiency map in section 04 collapses
near zero torque.

The efficiency at the corner: 110.0 kW at the shaft, 116.3 kW in, 94.6 percent.

Deck slide 25, briefly: larger motors are more efficient, faster ones too, since for the same
power they need less torque and so less current; liquid cooling keeps the windings cool and their
resistance low. The model has no temperature: all its numbers are warm.
-->

---
routeAlias: dc-control
---

## Two ways to control a DC motor

<div class="grid grid-cols-2 gap-8">
<div>

### By the voltage

$$
T = \frac{K\Phi}{R}\,\bigl(V - K\Phi\,\omega\bigr)
$$

Lower *V*: the line moves down in speed, same slope. At low speed a low voltage is all it takes
to drive the rated current.

**Step 02:** a converter sets *V* = *d* · *V*<sub>pack</sub>, and caps the current.

</div>
<div>

### By the flux

Lower Φ: less torque per ampere, and less back-EMF per rpm, so the machine **runs faster on the
same voltage**.

Deck: replace the permanent magnets by field coils, and turn their current down.

**Step 02:** when the voltage runs out, the converter turns the field down. That is **field
weakening**, and it gives the envelope of section 04.

</div>
</div>

<!--
Deck 7 slide 26. With a fixed field, the voltage sets where the line sits: lower voltage, lower
no-load speed, same slope. The converter in step 02 does this: it gives the machine d times the
pack voltage, and below base speed it lowers d to keep the current at its limit.

The second way is the flux. The deck: the permanent magnets are replaced by coils, and if the flux
is reduced, the maximum torque falls. True, but it also lowers the back-EMF per rpm, so the same
voltage drives the machine faster. Above the speed where the converter runs out of voltage, that
is the only knob left, and it gives the constant-power part of every EV's spec sheet.

A permanent-magnet machine cannot turn its magnets down. Its inverter weakens the field with a
current that opposes the magnets: section 03 shows how. In our model the machine gets a field
input, the flux as a fraction of full, which the converter sets.
-->

---
routeAlias: build-machine
---

## Build 01: the machine, on a dyno

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<div class="placeholder">

Screenshot to capture: `images/lecture-04/step01-dyno.png`, the finished `DCMachineDyno`
diagram: `voltage` → `supply`, `machine`, `ground`, `speed` → `dyno`, `mounts`

</div>

*New `DCMachine`: paste the code from the guide · new `DCMachineDyno`: parameters `V` 350,
`rpm_start` 3283, `rpm_end` 3600 · `voltage` Constant → `supply` VoltageSource → `machine` →
`ground` · `speed` Ramp → `dyno` VelocitySource · `mounts` Fixed · two `initial` lines and
`DCMachineDynoTransient` in code · ▷ once, then plot*

**Given:** the stdlib's `RotationalEMF`, `Resistor`, `Inductor` and the speed-dependent loss
torques

[page: step 01](../lecture/lecture-04/#step-01) · reference `dyad/HandsOn04/DCMachineDyno.dyad`

</div>
<div class="stack">

```julia
r = MyCar.DCMachineDynoTransient();
rpm = r.sol[r."machine.w"] .* 30 ./ pi;
plot(rpm[101:end], r.sol[r."machine.tau"][101:end])
r.sol[r."machine.P_cu"][101], 0.05 * r.sol[r."machine.i"][101]^2
r = MyCar.DCMachineDynoTransient(V = 200.0,
        rpm_start = 1500.0, rpm_end = 2200.0);
```

<div class="handson">✓ 350 V, 3283 rpm: <b>320.0 N·m</b>, 110.0 kW · <code>machine.i</code>
<b>332.2 A</b>, <code>machine.E</code> 333.4 V · <code>P_cu</code> <b>5.52 kW</b> = 0.05 × 332.2²
· shaft losses 0.73 kW: <b>94.6 %</b></div>

<div class="handson">✓ the ramp: <b>−1.97 N·m per rpm</b>, zero at about <b>3446 rpm</b>,
<b>−304 N·m</b> and −312 A at 3600 rpm: generating · 200 V: <b>922 N·m</b> for <b>953 A</b> at
1500 rpm</div>

</div>
</div>

<!--
Fifteen minutes: paste one component, place seven blocks, two code lines, an analysis, two runs.
The guide page, step 01, has every line.

1. New component `DCMachine`: right-click MyCar, Add Component, toggle to code, select all, paste
   the guide's block, save. It is the circuit of two slides back: `extends TwoPin` gives the
   electrical pins, the armature is resistor, inductor, emf, the rotor inertia and four loss
   parts sit on the emf's rotor. `k` is written as the formula it comes from, so changing R or a
   loss keeps the machine at 320 newton meters at 3283 rpm on 350 volts.
   Keep the names: step 02 adds a field input to this machine, and step 04 reads `machine.k`.

2. New component `DCMachineDyno`: three parameters through Edit Parameters, `V`, `rpm_start`,
   `rpm_end`; seven blocks from the guide's table, renamed. Wire: voltage to supply, supply p to
   machine p, machine n to supply n and ground, speed to dyno, machine spline to dyno spline, both
   supports to mounts.

3. Code: `initial dyno.phi = 0` and `initial machine.inductor.i = 0`, then the analysis
   `DCMachineDynoTransient`: 12 seconds, Rodas5P, tstops at 1 and 11 to land on the ramp's
   corners.

4. Run Analysis once, then the snippet. Points 1 to 100 are the first second, while the current
   rises from zero: the armature's time constant is 10 milliseconds, so it reaches 332 amperes
   within 50.

Expected, from `HandsOn04.DCMachineDynoTransient`: for the first second 3283 rpm, 320.0 newton
meters, 110.0 kW; 332.2 amperes, back-EMF 333.4 volts; copper loss 5.52 kW, exactly 0.05 times
332.2 squared; the shaft losses add 0.73 kW, 94.6 percent efficient. Along the ramp the torque
falls 1.97 newton meters per rpm, crosses zero at about 3446 rpm, just below V over K Phi, 3447,
and ends at minus 304 newton meters and minus 312 amperes at 3600. Along the ramp the torque sits
0.46 above the steady line: the inductance holds the current 0.64 amperes behind. Losses at base
speed: friction 172 watts, iron 344, windage 10, constant 200.

200 volts: the line crosses zero at 1968 rpm; at 1500 rpm 922 newton meters for 953 amperes.

Stall: a torque that starts at zero and climbs for a second is not a bug, it is the inductance;
the snippet starts at point 101. A compile error at `k` usually means a renamed parameter.
Testsets: `test/machine_plausibility.jl`.
-->

---

## Summary of section 02

- A wire in a field: **F = BIL**. Wound on a rotor, **T = KΦ·I** and **E = KΦ·ω**, one constant
  for both, so *E·i* = *T·ω*.
- On a fixed supply the torque is a steep line in speed; past *V*/*K*Φ the machine generates.
- Losses: copper *R i²* ∝ *T*², friction and iron ∝ ω, windage ∝ ω³, a constant. At the
  Leaf's corner, **94.6 %**.
- Control by the voltage, and by the flux: field weakening.
- On your dyno: **320.0 N·m at 3283 rpm, 332.2 A**; generating at 3600 rpm.

### Next: why this machine stands in for the ones in real cars. <Link to="machines">→ 03, machines in real EVs</Link>

<!--
One minute. If one picture stays, the straight torque-speed line with the motor turning into a
generator where it crosses zero: regenerative braking is already in the first model.
-->
