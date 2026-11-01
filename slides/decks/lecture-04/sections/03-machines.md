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

## Why brushless

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
Why do electric cars use brushless machines? Start on the left, with the brushed machine of the last
section. Its commutator is a mechanical switch: carbon brushes slide on it and reverse each coil's
current as the coil passes the poles, so that the torque keeps its direction. The deck lists the
price: friction between the brushes and the commutator, brushes that wear out, and heat made in the
rotor, where it is hard to remove.

So turn the machine inside out. Put the magnets on the rotor and the windings in the stator, where
the heat is easier to take away. Now nothing turns the current around mechanically any more, so
electronics must do it: an inverter, switching the stator currents in step with the rotor's
position. The inverter is section 05.

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

To make smooth torque from three sinusoidal currents, the inverter must place them right
relative to the magnets, at every instant. That is **field-oriented control**, next.

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
The induction machine, three slides on, is the one that slips.

To make smooth torque from three sinusoidal currents, the inverter must place those currents right
relative to the magnets, at every instant. That is field-oriented control, the next slide.
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
less is left for torque.

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
base speed, and what our converter does with its field input.
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
