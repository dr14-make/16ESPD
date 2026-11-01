---
routeAlias: machines
layout: section
---

###### Section 03

# Machines in real EVs

Brushless machines, why field-oriented control makes a permanent-magnet machine behave like step
01's, and the other machines in one slide.

<!--
Section 03, machines in real electric cars. There is no build in this section. We look at brushless
machines and at why field-oriented control makes a permanent-magnet machine behave like build 01's,
because that is the machine we build. The other machines get one slide that names them. We stay
with concepts and one animation: the transforms that field-oriented control computes, a model of
the machine in its rotating frame, and the other machines in depth are in the extra session.
-->

---
routeAlias: brushless
---

## Why brushless (1/2): turn it inside out

<div class="grid grid-cols-2 gap-4">
<div>

![Cross-section of a two-pole brushed DC machine. The housing carries two permanent magnets, N on the left and S on the right. Inside the air gap the armature has twelve slots: the conductors under the N pole carry current into the page, those under the S pole out of it, the two at top and bottom are being reversed; the torque is counterclockwise. Heat marks sit in the rotor. An inset shows the commutator further along the shaft: twelve copper segments with a carbon brush at top (+) and bottom (−), the sliding contacts circled.](/diagrams/03-brushed-cut.svg)

</div>
<div>

![Cross-section of a two-pole brushless DC machine at the same scale and orientation. The water-cooled housing holds the stator iron with six slots, labeled A+, C−, B+, A−, C+, B− around the bore; at this step current flows into phase A and out of phase B, so the left slots carry current into the page and the right slots out of it, phase C is off. The rotor carries surface magnets, N on the left and S on the right; the torque is counterclockwise. Three Hall sensors H1 to H3 sit 120 degrees apart at the bore and report the rotor position to an inverter, which drives the leads A, B and C from the pack. Heat arrows run from the stator slots into the housing; no sliding contact.](/diagrams/03-brushless-cut.svg)

</div>
</div>

Same scale, same orientation: the magnets and the windings swap places, and the commutator becomes
an inverter.

<!--
Two cuts through two machines, drawn at the same scale and the same way round: two poles each, N on
the left, S on the right, and the torque counterclockwise in both.

Start on the left, the brushed machine of the last section. On the outside is the housing, which
also carries the magnetic flux from one pole to the other. On it sit the two permanent magnets, the
stator. Inside, across a narrow air gap, the armature: a rotor of iron with twelve slots, and a
conductor in each. The current comes in through the carbon brush at the top of the inset, which is
the commutator, further along the same shaft. The commutator is a ring of copper segments, each
joined to a coil end, and the brushes press on it from top and bottom. It routes the current so that
every conductor under the N pole carries it into the page and every conductor under the S pole
carries it out. The field crosses from N to S, so the left conductors are pushed down and the right
ones up, and the rotor turns counterclockwise, exactly the force on a wire from the last section.
The two conductors at the top and the bottom are the ones being turned around: their segments are
passing under the brushes right now. Two things to look for. The heat: it is made in that winding,
deep inside the rotor, and to leave it must cross the air gap. And the red circles: the brushes slide
on the turning commutator, so they rub, wear and spark.

Now the right-hand cut, and swap the two parts. The magnets have moved onto the rotor, still N on
the left and S on the right. The windings have moved into the stator: six slots, two for each of
three phases, A, B and C, each phase a coil whose two sides sit opposite each other, A plus and A
minus. At the moment drawn, the inverter drives current into phase A and out of phase B, and phase C
rests. So the two slots on the left carry current into the page and the two on the right out of it,
the same pattern as before, only now in the stator. The force on those conductors pushes on the
stator, and its reaction turns the rotor counterclockwise. After sixty degrees of rotation the
inverter moves on to the next pair of phases; it knows when because three Hall sensors, a third of
a turn apart at the bore, read the magnets passing. That is the job the commutator did, done by
electronics; the inverter itself is section 05.

The two notes at the bottom are the reason electric cars use this. The heat is now made in the
stator winding, right against the housing, which can carry a water jacket, so it has a short way
out. And nothing slides: only cables leave the stator.
-->

---
routeAlias: bldc
---

## Why brushless (2/2)

<div class="grid grid-cols-2 gap-8">
<div>

**A brushed machine** switches each coil's current with a commutator, through carbon brushes
(deck):

- friction between brushes and commutator,
- the brushes wear,
- the heat is made in the rotor, where it is hard to remove.

**Turn it inside out.** Magnets on the rotor, windings in the stator, and the commutator replaced
by electronics: an inverter, switching the stator currents in step with the rotor's position.

</div>
<div>

**The brushless DC machine (BLDC)** (deck)

- Hall sensors tell the inverter where the rotor is.
- The phases are switched in blocks, so the back-EMF and the currents are trapezoidal.
- Its back-EMF grows with speed and opposes the current: torque falls as speed rises, as in step
  01.
- It is a generator as it stands.

> A "brushless DC" machine is an **AC machine** with its own inverter. Seen from the battery, it
> behaves like a DC machine.

</div>
</div>

<!--
The same comparison in words, to keep. On the left, the price of the brushed machine: friction
between brushes and commutator, brushes that wear out, and heat made in the rotor, where it is hard
to remove. Turning it inside out pays that price off, and the inverter takes over the commutator's
work, switching the stator currents in step with the rotor's position.

On the right, the deck's brushless DC machine, BLDC for short. Hall sensors tell the inverter where
the rotor is. The phases are switched in blocks, so the back-EMF and the currents have a trapezoidal
shape. As in build 01, the back-EMF grows with speed and opposes the current, so the torque falls as
the speed rises. And because the back-EMF is there whenever the rotor turns, the machine is a
generator as it stands, with no change.

The box at the bottom: the name is historical. A brushless DC machine is an AC machine, each stator
phase carries an alternating current, with its own inverter. Seen from the battery, the pair behaves
like a DC machine.
-->

---
routeAlias: pmsm
---

## BLDC and PMSM: the same machine, two ways to drive it

<div class="grid grid-cols-2 gap-8">
<div class="tight">

| | BLDC | PMSM |
|---|---|---|
| rotor | permanent magnets | permanent magnets |
| back-EMF | trapezoidal | sinusoidal |
| currents | blocks, two phases at a time | three sines |
| rotor position | Hall sensors, a step every 60° electrical | resolver or encoder, continuous |
| torque | ripples at each switch | smooth |
| where | fans, pumps, e-bikes | traction motors |

</div>
<div>

The **Leaf's** motor is a permanent-magnet synchronous machine: 8 poles, magnets buried in the
rotor (interior PM), 48 slots (ORNL, first-generation motor).

**Synchronous:** the rotor turns with the stator's rotating field, never slipping behind it.

What *trapezoidal* and *sinusoidal* mean, and why the currents follow: next slide.

</div>
</div>

<!--
A BLDC and a permanent-magnet synchronous machine, PMSM for short, are built the same way: permanent
magnets on the rotor, windings in the stator. The difference is how they are driven. Read the table
row by row. The rotor: permanent magnets in both. The back-EMF: trapezoidal in the BLDC, sinusoidal
in the PMSM. The currents: blocks, two phases at a time, in the BLDC; three sines in the PMSM. The
rotor position: the BLDC reads it from three Hall sensors, one of which changes state every 60
electrical degrees, so six steps make one electrical turn, as Microchip's application note AN885
puts it; the PMSM needs it continuously, from a resolver or an encoder. So the BLDC's torque
ripples at each switching instant, and the PMSM's is smooth. That is why BLDCs drive fans, pumps and e-bikes, and PMSMs are
traction motors.

On the right, the Leaf. Its motor is a permanent-magnet synchronous machine. Oak Ridge National
Laboratory took apart the first-generation motor of the 2012 car: 8 poles, magnets buried inside the
rotor iron, which is called interior permanent magnet, 48 stator slots, and about 56 kilograms.
Buried magnets add a second kind of torque, reluctance torque, which our model leaves out.

Synchronous means that the rotor turns with the stator's rotating field and never slips behind it.
The induction machine, further on, is the one that slips.

The two words in the back-EMF row, trapezoidal and sinusoidal, carry the whole difference, and the
next slide shows what they mean.
-->

---
routeAlias: trap-vs-sine
---

## Trapezoidal or sinusoidal: the back-EMF sets the current

![Two columns over one electrical revolution, 0 to 360 degrees. Left, the BLDC: the three back-EMFs A, B and C are trapezoids, flat at plus or minus 1 for 120 degrees and sloping in between, 120 degrees apart; the currents are blocks of plus or minus 1, each 120 degrees long under a flat top, so two phases conduct at a time, in six 60-degree steps labeled A+ B−, A+ C−, B+ C−, B+ A−, C+ A−, C+ B−; the torque of ideal blocks is flat at 1, and with winding inductance it dips to about 0.55 at each of the six steps and recovers within about 20 degrees. Right, the PMSM: the back-EMFs are three sines 120 degrees apart, the currents three sines in phase with them, and the torque is flat at 1.](/figures/03-bldc-pmsm-waveforms.svg)

<div class="grid grid-cols-3 gap-6 text-sm">
<div>

**The shape is built in.** Trapezoidal and sinusoidal name how a phase's back-EMF varies with rotor
angle. The layout of magnets and windings sets it: wide magnets and concentrated coils give flat
tops, distributed windings a sine.

</div>
<div>

**The current must match it.** Each phase gives torque e·i/ω. For a steady total, a flat-topped EMF
needs a constant current while it is flat: 120° blocks, two phases at a time. A sine EMF needs a
sine current in phase with it.

</div>
<div>

**What follows.** Blocks switch at six angles per electrical turn, which three Hall sensors mark.
Sines need the angle at every instant. A block cannot jump through the winding's inductance, so the
BLDC's torque dips at each step; the sines' is smooth.

</div>
</div>

<!--
This slide answers what trapezoidal and sinusoidal actually mean. Both columns cover one electrical
revolution of the rotor, from 0 to 360 electrical degrees, and every value is in per unit of its
peak. The left column is the BLDC, the right column the PMSM. The phases have the colors of the
animation on the next slide: A blue, B orange, C green.

Start at the top row. If you turn either machine at a constant speed with nothing connected and
measure the voltage of each phase, you get its back-EMF. In the BLDC each phase gives a trapezoid:
it rises, stays flat for 120 electrical degrees, falls, stays flat at the negative value for
another 120 degrees, and rises again. In the PMSM each phase gives a sine. The three phases are the
same curve shifted by 120 degrees. That shape is not chosen by the controller. It is built into the
machine, by how the magnets and the windings are laid out. Wide magnets with concentrated coils give
the flat tops; windings distributed over many slots, and magnets shaped to match, give a sine.

The middle row is the current the drive puts in, and the reason it has to look like this is in one
formula. The power a phase converts is its back-EMF times its current, so its torque is e times i
over omega, and the machine's torque is the sum over the three phases. For the BLDC, look at any
60-degree step: exactly two phases sit on a flat top, one at plus 1 and one at minus 1. Drive a
constant current into the first and out of the second, and the sum, e times i plus e times i, is
constant. So the BLDC's currents are blocks 120 degrees long, lined up with the flat tops, and only
two phases conduct at any time. The labels along the top give the pair: A plus B minus, then A plus
C minus, and so on, six steps per electrical turn. For the PMSM, put a sine current in each phase,
in phase with its back-EMF. Each phase's torque is then a sine squared, which pulses, but three sine
squares 120 degrees apart add up to exactly one and a half, a constant.

The bottom row is that torque, scaled so its mean is 1. On the right it is flat. On the left the
dashed line is the ideal block currents, also flat. The solid line is what a real winding does. A
winding has inductance, so its current cannot jump: at every step the outgoing phase's current needs
time to fall to zero and the incoming one needs time to build up, and the torque dips. That is a
dip every 60 electrical degrees, and it is the torque ripple in the table. The solid line is
computed, not drawn by hand: a six-step drive with the winding's resistance and inductance, the
inverter's pulse-width modulation averaged out, at a speed where the back-EMF uses up most of the
battery voltage. How deep the dip is depends on the speed and the inductance; the commutation
torque ripple was analyzed by Carlson, Lajoie-Mazenc and Fagundes in 1992. The trapezoids with
exactly flat tops and the perfect sines are the textbook idealization; a real machine's back-EMF is
rounded at the corners and carries some harmonics, and Krishnan's book on permanent-magnet drives
treats both machines this way.

The consequences are on the right of the slide. The block currents change only at six angles per
electrical turn, at the dotted lines. Three Hall sensors, each changing state every 180 degrees and
offset by 120, mark exactly those six instants, as Microchip's application note AN885 shows. That is
cheap and enough for a BLDC. Sine currents need the rotor angle at every instant, so a PMSM carries
a resolver or an encoder. To make smooth torque from three sine currents, the inverter must place
them right relative to the magnets at every instant. That is field-oriented control, the next slide.
-->

---
routeAlias: foc
---

## Field-oriented control

<div class="grid grid-cols-[1.45fr_1fr] gap-6 items-start">
<div>

<FocMachine />

<div class="caption">Drawn with one pole pair. The red arrow is the stator current; d points along the
magnets, q a quarter turn ahead.</div>

</div>
<div class="text-[0.95rem]">

The inverter measures the rotor angle and places the stator current **a quarter turn ahead of the
magnets**, on the **q** axis: there every ampere makes torque.

The stator carries three **alternating** currents. Seen from the rotor, they are **two steady
numbers**:

- *i*<sub>q</sub>, the torque current: *T* ∝ *i*<sub>q</sub>
- *i*<sub>d</sub>, along the magnets: zero, until the voltage runs out

**Field weakening on:** part of the current turns against the magnets and weakens their field;
less is left for torque. Why and how: next slide.

</div>
</div>

<!--
Field-oriented control. On the left is an animation built into this deck; it is a drawing, not a
simulation. It shows a machine with one pole pair: the rotor in the middle, its north half red and
its south half blue, turning inside a three-phase stator. The three dashed lines labeled a, b and c
are the axes of the three stator windings, 120 degrees apart. Two black dashed lines turn with the
rotor: d points along the magnets, through the north pole, and q points a quarter turn ahead of it.
The thick red arrow, labeled i, is the stator current: the combined effect of the three phase
currents, drawn as one vector.

Watch the red arrow as the rotor turns. The inverter measures the rotor angle and keeps the current
a quarter turn ahead of the magnets, on the q axis. There every ampere makes torque, as in the
picture of the conductor in the field: the force is largest when the current is at right angles to
the field.

On the right, the top plot is labeled the stator carries: three alternating currents. These are the
three phase currents, a in blue, b in orange and c in green, over one electrical revolution. They
alternate at the rotor's electrical frequency, and the red cursor moves with the rotor. Below them,
labeled the rotor sees: two steady numbers, is the same current seen from the rotor: one bar for i
d, along the magnets, and one for i q, across them. They do not change at all as the rotor turns.
That is the whole trick of field-oriented control: in the rotor's frame an AC machine has DC
quantities, and the controller can regulate them as such. As the slide says, i q is the torque
current, and the torque is proportional to it. i d, along the magnets, is zero until the voltage
runs out.

[click the field weakening button]

Now the current vector swings back, toward the south pole: part of it points against the magnets.
The i d bar goes negative, and that negative d current opposes the magnets' flux and weakens their
field. The length of the vector stays the same, at the inverter's current limit, so what is left for
the q part, and for the torque, shrinks: in the animation i d is minus 0.6 of the limit, and i q
drops to 0.8. That is the last paragraph of the slide, and it is what the Leaf's inverter does above
base speed, and what our converter does with its field input. Why it is needed, and how far it
goes, is the next slide.
-->

---
routeAlias: field-weakening
---

## Field weakening: why, and how

![Left: the i_d–i_q plane of an illustrative per-unit PMSM. The current limit is a black circle of radius 1 around the origin. The voltage limit is a circle centered at minus psi_PM over L_d, about −1.11, drawn for base speed, 1.5, 2.5 and 4 times base speed; it shrinks as the speed rises. The operating point sits at i_d = 0, i_q = 1 at base speed and slides along the current circle toward negative i_d, a red arc: about (−0.56, 0.83) at 1.5 times, (−0.85, 0.54) at 2.5 times and (−0.94, 0.33) at 4 times base speed. Right: torque, proportional to i_q, flat at 1 up to base speed and then falling, close to a 1/ω curve; power, proportional to ω times i_q, rising to 1 at base speed and then staying near 1.25 to 1.35.](/figures/03-field-weakening.svg)

<div class="grid grid-cols-2 gap-8 text-sm">
<div>

**Why.** The back-EMF grows with speed, *E* = ω ψ<sub>PM</sub>, and magnets cannot be switched
off. The inverter's voltage is capped by the battery. At **base speed** *E* plus the winding's drop
reaches the cap; faster, the inverter can no longer push *i*<sub>q</sub> in, and the torque
collapses.

In our model: the DC machine's field Φ turned down (step 02).

</div>
<div>

**How.** Drive a **negative *i*<sub>d</sub>**: its flux *L*<sub>d</sub>*i*<sub>d</sub> opposes the
magnets', so the voltage needed stays at the cap:
$v \approx \omega\sqrt{(\psi_\mathrm{PM} + L_d i_d)^2 + (L_q i_q)^2}$.
The current is capped too, $i_d^2 + i_q^2 \le I_\mathrm{max}^2$: what goes into −*i*<sub>d</sub>
is lost to *i*<sub>q</sub>. Torque falls about as 1/ω, power stays roughly level: the
envelope's <Link to="base-speed">constant-power part</Link>. The price: *i*<sub>d</sub> makes
copper loss, no torque.

</div>
</div>

<!--
The last slide switched field weakening on with a button. This one says why a permanent-magnet
machine needs it, and how the inverter does it.

Why first, in the left column. The magnets' flux, psi PM, is fixed, so the back-EMF grows in
proportion to the speed: E equals omega times psi PM, with omega the electrical speed. The inverter
can only make a voltage up to a limit set by the battery: with space-vector modulation, the peak
phase voltage is at most the DC voltage over the square root of three. Below base speed the inverter
has voltage to spare, and it drives the full current into the q axis, where every ampere makes
torque. At base speed the back-EMF plus the drop across the winding reaches the limit. Go faster,
and the inverter has no voltage left to push the q current against the back-EMF, so without doing
anything the current and the torque collapse. And the magnets cannot be switched off.

Now the picture, the left panel. It is a generic machine in per unit, not the Leaf: the axes are the
d and q currents as fractions of the current limit, i d horizontal, negative meaning against the
magnets, and i q vertical. The black circle is the current limit: the inverter and the winding allow
any current inside it, i d squared plus i q squared at most I max squared. The colored circles are
the voltage limit. Neglecting the resistance, the voltage the machine needs is omega times the
length of the flux vector: the magnets' flux plus L d times i d along d, and L q times i q along q.
That is the formula on the right. So at a given speed the allowed currents lie inside a circle
centered at minus psi PM over L d, the point marked with a cross, where the stator flux would cancel
the magnets' exactly. I take L d equal to L q here, as our model does; with buried magnets, as in
the Leaf, L q is larger and the circle becomes an ellipse. The radius is the voltage limit over omega
L, so the circle shrinks as the speed rises: blue at base speed, then orange at one and a half
times, green at two and a half times and purple at four times base speed. The machine must sit
inside both circles.

At base speed the blue circle passes exactly through the top of the current circle, the blue dot:
full current, all of it on q. Faster, that point falls outside the shrinking voltage circle, and the
best the inverter can do is the crossing of the two circles. That is the red arc: the operating
point slides along the current limit toward negative i d. At one and a half times base speed it
sits at minus 0.56 on d and 0.83 on q; at two and a half times at minus 0.85 and 0.54, which is the
red arrow; at four times at minus 0.94 and 0.33. That is how field weakening is done: a negative d
current, whose flux L d times i d opposes the magnets' flux, so that the flux the winding sees,
psi PM plus L d i d, is smaller, and the voltage the machine needs stays at the limit.

The right panel is what that costs. The current's length stays at the limit, so whatever goes into
minus i d is lost to i q, and the torque is proportional to i q. The solid line is the torque: flat
at 1 up to base speed, then falling to 0.83, 0.54 and 0.33 at the three marked speeds, close to the
dotted 1 over omega curve. The dashed line is the power, omega times i q: it rises with the speed up
to base speed and then stays roughly level, between about 1.25 and 1.35 of its base-speed value in
this machine. That is the constant-power region of section 04's envelope. It is not exactly flat in
a real machine; the course model makes it exactly flat.

The price is in the last line: the d current flows in the winding, so it makes copper loss, R i
squared, but no torque. Our model leaves that loss out, as the next slide says. And the tie to our
model is the line on the left: in step 02, the DC machine's field Phi is simply turned down above
base speed. Negative i d is how a PMSM turns its field down.
-->

---
routeAlias: foc-is-step-1
---

## Why a PMSM under FOC is step 01's machine

<div class="tight">

| Step 01's DC machine | A PMSM under field-oriented control |
|---|---|
| armature current *i* | torque current *i*<sub>q</sub> |
| *T* = *K*Φ · *i* | *T* ∝ magnet flux × *i*<sub>q</sub> |
| *E* = *K*Φ · ω | back-EMF amplitude ∝ magnet flux × ω |
| commutator | inverter + rotor-angle sensor |
| field weakening: turn Φ down | negative *i*<sub>d</sub> against the magnets |
| copper loss *R i*² | copper loss in three phases |

</div>

<div class="grid grid-cols-2 gap-8 mt-4 text-[0.95rem]">
<div>

From the battery and the shaft, the two are **the same two equations**. So the car carries the
DC-equivalent machine, and its torque, current and losses are the PMSM's.

</div>
<div>

**What it leaves out:** the reluctance torque of buried magnets, the copper loss of *i*<sub>d</sub>
during field weakening, and the d and q dynamics. A dq model is in the extra pack.

</div>
</div>

<!--
This table is why we can build the car with build 01's machine. On the left, the DC machine you
pasted. On the right, a PMSM driven by its inverter under field-oriented control.

Row by row. The armature current corresponds to the torque current, i q. The DC machine's torque is
K Phi times i; the PMSM's torque is proportional to the magnet flux times i q, through a constant
set by the magnets and the winding, which plays the role of K Phi. The DC machine's back-EMF is K
Phi omega; the PMSM's back-EMF amplitude is proportional to the magnet flux times omega, through the
same constant. The commutator's job is done by the inverter together with the rotor-angle sensor.
Field weakening, turning Phi down, is done by a negative i d against the magnets. And the copper
loss, R i squared, becomes the copper loss in the three phases.

So, bottom left: seen from the battery and from the shaft, the two machines obey the same two
equations. The car therefore carries the DC-equivalent machine, and its torque, its current and its
losses are the PMSM's.

Bottom right, what this leaves out. A machine with buried magnets also makes reluctance torque,
which our model does not have. Field weakening in a real PMSM costs copper loss, because the d
current flows in the windings; in our model the field input is free. And the d and q currents have
their own dynamics. A model of the machine in d and q is in the extra pack.
-->

---
routeAlias: other-machines
---

## The other machines, in one slide

<div class="grid grid-cols-[1.25fr_1fr] gap-8">
<div class="tight">

| Machine | Where its field comes from | In one line |
|---|---|---|
| **PMSM** (this lecture) | magnets on the rotor, free | the traction machine of most EVs; step 01's machine under FOC |
| brushed DC (deck) | a field winding or magnets | step 01's equations; brushes and commutator wear |
| induction (deck) | a d current the inverter drives into a cage rotor | no magnets; the rotor slips behind the field |
| wound-rotor synchronous | a rotor winding, fed through slip rings | no magnets; the field is a second current to control |
| switched reluctance (deck) | none: an iron rotor pulled into line | simplest rotor; torque pulses, noisy |

</div>
<div>

**What the build needs from this:** a magnet's field costs nothing, so a PMSM loses least at
**light load**, where the WLTC drives (section 04). A machine without magnets pays a current for
its field at every point, but drags nothing when it is switched off: Audi's Q4 e-tron quattro
drives on its rear PMSM and adds a front induction machine only for more power (Audi).

The extra session takes these machines one by one: how each makes torque, how it is controlled,
and the d-q model.

</div>
</div>

<!--
The other machines, all on one slide. We build one machine today, and this table says where it
sits among the others. The first column names the machine, the second says where its magnetic field
comes from, and the third gives it one line.

The first row is the one we build: the permanent-magnet synchronous machine. Its field comes from
magnets on the rotor, so it is free. It is the traction machine of most electric cars, and under
field-oriented control it is build 01's machine, as the last slide showed.

The brushed DC machine, from the course's deck: its field comes from a field winding or from
magnets. It gave us build 01's two equations, but its brushes and commutator wear, which is why
cars left it.

The induction machine, also in the deck. It has no magnets: the inverter drives a d current that
magnetizes the rotor, a cage of short-circuited bars, and the rotor always turns a little slower
than the field. That difference is called slip.

The wound-rotor synchronous machine: no magnets either. Its rotor carries a winding, fed through
slip rings, and that winding makes the field. So the field is a second current the controller can
set, at the price of the copper loss in that winding.

And the switched-reluctance machine, the last one in the deck. Its rotor is just laminated iron,
pulled into line with whichever stator pole is switched on. It has the simplest rotor of all, but
its torque comes in pulses, so it is noisy, and it has stayed rare in cars.

On the right, what the build needs from all this. A magnet's field costs nothing, so a PMSM loses
least at light load, and light load is where the WLTC drives, as section 04 shows on the efficiency
map. A machine without magnets pays a current for its field at every operating point, but when it
is switched off it has no field and drags nothing. That is why Audi's Q4 e-tron quattro, in Audi's
own press kit, drives on a permanent-magnet machine on the rear axle in moderate driving, and
switches in an induction machine on the front axle only when the driver asks for more power; while
it is off, its drag losses are minimal.

How each of these machines makes torque, how it is controlled, and the model of a machine in d and
q, are the extra session's topics. Today we stay with the one we build.
-->

---

## Summary of section 03

- Brushless machines move the windings to the stator and the commutator into an inverter.
- A PMSM under field-oriented control keeps its stator current a quarter turn ahead of the
  magnets: in the rotor's frame, **two steady currents**, *i*<sub>q</sub> for torque and
  *i*<sub>d</sub> for the field.
- From outside, that is **step 01's machine**: *T* ∝ *i*<sub>q</sub>, *E* ∝ ω, field weakening
  by a negative *i*<sub>d</sub>.
- Machines without magnets (induction, wound rotor, SRM) pay for their field or pulse; the
  extra session covers them.

### Next: what the converter does to that machine. <Link to="envelope">→ 04, the envelope</Link>

<!--
Section 03 in four lines. Brushless machines move the windings into the stator and the commutator
into an inverter. A PMSM under field-oriented control keeps its stator current a quarter turn ahead
of the magnets, so in the rotor's frame there are two steady currents: i q for torque, and i d for
the field. From the outside, that is build 01's machine: torque proportional to i q, back-EMF
proportional to omega, and field weakening by a negative i d. The machines without magnets, the
induction machine, the wound-rotor machine and the switched-reluctance machine, either pay a
current for their field or deliver their torque in pulses; the extra session covers them.

The inverter that does field-oriented control is, averaged over a switching period, a converter with
a duty and a field. That converter is the next build.
-->
