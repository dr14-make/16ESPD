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
Section 02, the DC machine. We go from the force on a single wire to the two equations of the
machine, T equals K Phi I and E equals K Phi omega; then its losses, its efficiency, and the two
ways to control it. The figures come from notebook 04, and the section ends with build 01.

Why a DC machine, when no electric car has one? Because a permanent-magnet machine under
field-oriented control, the kind of machine that drives most electric cars, behaves exactly like a
DC machine from the outside: its torque is proportional to one current, and its back-EMF is
proportional to its speed. Section 03 shows why. So the DC machine is an honest model of a traction
motor, and its two equations are the ones to remember from today.
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
Let us start with one wire. Read the picture on the left: a north pole on the left and a south pole
on the right, and the field B runs from north to south, left to right. Between them sits a coil of
radius r. Its left conductor carries the current into the page, its right conductor carries it out
of the page. A wire of length l carrying a current I across a field B feels a force, F equals B I l,
at right angles to both the field and the wire. So the left conductor is pushed down and the right
one up. Both forces act at the radius r, and together they turn the coil: the torque is twice r
times B I l.

That is the first formula on the right, F equals B I l: B in tesla, I in amperes, l in meters, F in
newtons. Wind the coil with n turns and every turn adds the same, so the torque is T equals 2 n r B
l, times I. Everything in 2 n r B l is fixed when the machine is built: the number of turns, the
radius, the field, the length. We give it one name, K Phi: K for the winding and Phi for the
magnetic flux. Then the torque is K Phi times the current, and K Phi is in newton meters per ampere.

The second formula. The same conductors move through the same field, at a speed omega times r. A
conductor moving through a field has a voltage induced in it, B times l times its speed. Add it up
over the turns and you get E equals 2 n r B l, times omega: the back-EMF, in volts, with omega in
radians per second. And it is the same K Phi. K Phi in newton meters per ampere is the same number
as K Phi in volts per radian per second.

That is the bold line: one constant does both jobs. It is not a coincidence, it is energy
conservation, the third formula. The electrical power that disappears into the back-EMF, E times i,
is K Phi omega times i, and that is exactly T times omega, the mechanical power at the shaft.
Electrical power in becomes mechanical power out.

A real machine has many coils, and in a brushed DC machine a commutator switches each coil's current
as it passes the poles, so that the torque keeps its direction. The two equations stay the same.
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
This is the machine you paste in build 01, the `DCMachine` component, drawn as a circuit. Read the
top from left to right, starting at the terminal p. First the armature resistance R, 0.05 ohm, where
the copper loss, R i squared, is made. Then the armature inductance L, 0.5 millihenry. Then the
back-EMF source: E equals K Phi omega, and T equals K Phi i. In the standard library that source is
the `RotationalEMF`: it turns current into torque on its rotor and speed into voltage, both through
one constant, which is K Phi. From there the circuit returns to the terminal n.

The EMF drives the shaft, drawn below it. First the rotor inertia J. Then four loss parts, each a
braking torque that depends only on the speed and pushes back against the housing: friction T f,
iron loss K i, windage k w omega squared, and the constant loss, C over omega. At the right end is
the spline, the output shaft.

The formulas say the same thing. The voltage equation: the terminal voltage v equals R i, the drop
across the resistance, plus L di by dt, the drop across the inductance while the current changes,
plus K Phi omega, the back-EMF. The torque equation: the electromagnetic torque T em equals K Phi i,
before the shaft losses are taken off.

The table gives the numbers. R is 0.05 ohm, chosen so that the efficiency lands on the motor map Oak
Ridge National Laboratory measured on the Leaf. L is 0.5 millihenry, so L over R is 10 milliseconds,
the time constant of the current. T f and K i, friction and iron loss, are 0.5 and 1.0 newton
meters. They are torques, so their power grows with speed: half a kilowatt and 1 kilowatt at 9550
rpm. The constant loss C is 200 watts at any speed. Windage is not in the table; it is set to 300
watts at the motor's top speed of 10 100 rpm. And K Phi, 0.9697 newton meters per ampere, is not
chosen at all. It is derived, so that at 350 volts and 3283 rpm the shaft gives exactly 320 newton
meters, the Leaf's corner point. In the code it is written as the formula it comes from, so if you
change R or a loss, the machine still meets that point.

One consequence to remember: the copper loss lives in the resistor. That is why the efficiency map
in section 04 is computed from this machine and never looked up. A measured map on top of it would
count the copper loss twice.
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
What does this machine do on a fixed supply, with a voltage source wired straight to its terminals
and nothing in between? The figure is from notebook 04, section 1: the library's dyno bench, the
same bench you build in step 01, run twice. The horizontal axis is the machine speed in rpm, the
vertical axis the shaft torque in newton meters. The blue line is a 350 volt supply: the dyno holds
3283 rpm, then ramps the speed up to 3600. The orange line is a 200 volt supply, ramped from 1500 to
2200 rpm. The gray dashed line is the Leaf's peak torque, 320 newton meters, and the thin black line
is zero torque.

The first formula explains the shape. With the supply voltage V fixed, the current is whatever the
gap between the supply and the back-EMF drives through the armature resistance: i equals V minus K
Phi omega, over R. The torque is K Phi times that current, so it is a straight line that falls with
speed. Its slope is K Phi squared over R: 0.9697 squared over 0.05 is 18.8 newton meters per radian
per second, which is 1.97 newton meters per rpm. That is steep, because R is small. The line reaches
zero torque at V over K Phi, the speed at which the back-EMF has caught up with the supply. On 350
volts that is 3447 rpm, as the title says.

Follow the blue line. Its dot at 3283 rpm is 320.0 newton meters for 332.2 amperes, by construction:
that is how K Phi was chosen. The line crosses zero near 3447 rpm. And at its right end, at 3600
rpm, the back-EMF is 365.6 volts, above the 350 volt supply. The current reverses: minus 312
amperes, and the shaft takes minus 304 newton meters. The motor has become a generator and pushes
energy back into the supply. That is the sentence in the middle of the slide, and it is regenerative
braking, already in this first model.

Now the orange line. It has the same slope and sits lower in speed, crossing zero near 1969 rpm.
Lowering the voltage is the deck's first way to control a DC motor. But look at its dot: at 1500
rpm, 922 newton meters for 953 amperes, nearly three times the current the machine draws at the
Leaf's 320 newton meters. A fixed supply cannot give full torque at low speed without enormous
currents. The deck notes that in real machines the low-speed torque is limited by the controller or
by the battery's internal resistance. That is exactly what we add next: step 02's converter lowers
the voltage and caps the current, and step 03's battery adds its resistance.
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
Where does the machine lose energy? On the right is the deck's loss formula, and in our model each
term is a part with its own power. Copper loss, R i squared: the resistance in ohms times the
current squared, in watts. The current is proportional to the torque, so this loss goes with the
torque squared. Friction in the bearings, T f omega: a constant torque times the speed. Iron loss, K
i omega: hysteresis and eddy currents in the iron, which the deck also takes proportional to the
speed. Windage, k w omega cubed: the air drag on the spinning rotor, growing with the cube of the
speed. And a constant, C, lost at any speed.

The efficiency, the second formula, is the mechanical power out, T omega, over the power in, which
is T omega plus all the losses.

The figure is notebook 04, section 2. The machine runs along its whole envelope at the converter's
current limit, 332.2 amperes, from standstill to 10 000 rpm, on build 02's converter bench, and each
loss is read from its own part. The horizontal axis is the machine speed in rpm. The vertical axis
is the loss in watts, on a logarithmic scale: each grid line is ten times the one below it. The gray
dashed vertical line is base speed, 3283 rpm. The legend names the five curves. Copper, at the top,
is flat at 5.52 kilowatts at every speed, because the current is the same everywhere. Iron and
friction rise in proportion to speed, to about 1 kilowatt and half a kilowatt at the right edge. The
constant loss is flat at 200 watts. Windage starts tiny and rises with the cube of the speed, to
about 300 watts at 10 000 rpm.

So at full current the copper loss dominates at every speed. At base speed the others are iron 344
watts, friction 172, the constant 200 and windage 10: together 0.73 kilowatts of shaft losses,
against 5.52 of copper. At the Leaf's corner point, 320 newton meters at 3283 rpm, the shaft gives
110.0 kilowatts and the electrical input is 116.3 kilowatts: 94.6 percent, the number at the bottom
of the slide.

At part load the picture changes. The current falls with the torque, and the copper loss with its
square: halve the torque and the copper loss drops to a quarter, while the speed terms stay where
they are. That is why a machine is least efficient at very light load, and why the efficiency map in
section 04 collapses near zero torque.

The model has no thermal part: every number in it is for a machine at its warm operating
temperature.
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
The deck gives two ways to control a DC motor, one per column.

On the left, by the voltage. The formula is the fixed-supply line from two slides back, written as a
torque: T equals K Phi over R, times V minus K Phi omega. Lower the voltage V and the whole line
moves down in speed, with the same slope, as the 200 volt line did. At low speed the back-EMF is
small, so a low voltage is all it takes to drive the rated current. That is what step 02's converter
does: it gives the machine a voltage d times the pack voltage, where the duty d is a number between
0 and 1, and below base speed it sets d just high enough to hold the current at its limit.

On the right, by the flux. Lower Phi and two things happen: the machine makes less torque per
ampere, and less back-EMF per rpm. The second is the useful one: with less back-EMF per rpm, the
same voltage drives the machine faster. In the deck's version, the permanent magnets are replaced by
field coils, and their current is turned down.

In step 02 this is the second knob. Once the converter gives the machine all of the pack's voltage,
at base speed, the only way to go faster at full current is to turn the field down. That is field
weakening, and it gives the constant-power part of the envelope in section 04, the part of every
electric car's spec sheet where the torque falls as the speed rises.

A permanent-magnet machine cannot turn its magnets down. Its inverter weakens the field with a
current that opposes the magnets, and section 03 shows how. In our model the machine simply gets a
field input, the flux as a fraction of full, and the converter sets it.
-->

---
routeAlias: build-machine
---

## Build 01: the machine, on a dyno

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<img src="/img/lecture-04/step01-dyno.png" class="mx-auto" style="max-height: 21rem" alt="The finished DCMachineDyno in Studio: voltage into supply on the left with ground below it; machine at the top right, p and n on its left edge, its shaft wired to dyno; speed into dyno below; both supports to mounts."/>

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
Build 01: the machine, on a dyno. On the left is the finished bench in Studio. A constant block
named voltage feeds an ideal voltage source named supply, with the ground below it. The machine sits
at the top right, with its two electrical pins, p and n, on its left edge, and its shaft wired to
the dyno. Below, a ramp block named speed sets the dyno's speed. Both housings, the machine's and
the dyno's, go to the fixed mounts.

The steps are in the italic line. First, a new component `DCMachine`: right-click `MyCar`, Add
Component, toggle to code, select everything, and paste the code from the guide. It is the circuit
from two slides back: the resistor, the inductor and the EMF in the armature, the rotor inertia and
the four loss parts on the shaft. Keep its names: step 02 adds a field input to this machine, and
step 04 reads `machine.k`.

Second, a new component `DCMachineDyno`, with three parameters: V, 350; rpm start, 3283; rpm end,
3600. Place the seven blocks from the guide's table and rename each one: voltage, a `Constant`, into
supply, a `VoltageSource`; the machine; ground; speed, a `Ramp`, into dyno, a `VelocitySource`; and
mounts, a `Fixed`. The voltage source stands in for the pack: a stiff supply with nothing in
between. The velocity source is the dynamometer: it forces the shaft to the speed it is asked for,
and absorbs or supplies whatever torque that takes. Wire them as in the picture; the code view
should show eight connect lines.

Third, in code: two initial lines, so that the dyno's angle and the armature current start at zero,
and the analysis `DCMachineDynoTransient`: 12 seconds, the Rodas5P solver, and tstops at 1 and 11
seconds so that the solver lands on the corners of the ramp. The speed ramp holds 3283 rpm for a
second, ramps to 3600 over ten seconds, and holds again. Then click Run Analysis once, and paste the
snippet.

The snippet on the right runs the analysis, converts the speed to rpm, and plots the shaft torque
against speed from point 101 on. Why 101? Points are saved every hundredth of a second, so the first
hundred points are the first second, while the current rises from zero. The armature's time constant
is 10 milliseconds, so the current reaches its 332 amperes within about 50. The fourth line compares
the copper loss the resistor reports with 0.05 times the current squared: the two must be equal. The
last line runs the same bench on 200 volts, from 1500 to 2200 rpm.

The first green box is what you should see on 350 volts. During the first second, at 3283 rpm, the
shaft gives 320.0 newton meters, 110.0 kilowatts. The current, `machine.i`, is 332.2 amperes, and
the back-EMF, `machine.E`, 333.4 volts. The copper loss, `P_cu`, is 5.52 kilowatts, exactly 0.05
times 332.2 squared. The shaft losses add 0.73 kilowatts, so the machine is 94.6 percent efficient
there.

The second green box is the ramp. The torque falls 1.97 newton meters per rpm, crosses zero at about
3446 rpm, just below V over K Phi, 3447, and ends at minus 304 newton meters and minus 312 amperes
at 3600 rpm: generating. Along the ramp the torque sits 0.46 newton meters above the steady line,
because the inductance holds the current 0.64 amperes behind the falling back-EMF. On 200 volts, at
1500 rpm: 922 newton meters for 953 amperes, and the line crosses zero at 1968 rpm.

If your torque starts at zero and climbs for the first second, that is not a bug, it is the
inductance: plot from point 101. And a compile error at k usually means a parameter was renamed.
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
Section 02 in five lines. A wire in a field feels F equals B I L. Wound on a rotor, that gives T
equals K Phi I, and the same conductors moving give E equals K Phi omega: one constant for both, so
E times i equals T times omega. On a fixed supply the torque is a steep straight line in speed, and
past V over K Phi the machine generates. The losses: copper, R i squared, which goes with the torque
squared; friction and iron, proportional to omega; windage, omega cubed; and a constant. At the
Leaf's corner the machine is 94.6 percent efficient. It is controlled by the voltage, and by the
flux: field weakening. And on your dyno: 320.0 newton meters at 3283 rpm for 332.2 amperes, and
generating at 3600 rpm.

If one picture stays with you, let it be the straight torque-speed line, with the motor turning into
a generator where it crosses zero: regenerative braking is already in the very first model.

Next: why this machine stands in for the machines in real electric cars.
-->
