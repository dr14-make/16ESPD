---
routeAlias: machines
layout: section
---

###### Section 03

# Machines in real EVs

Brushless machines, why field-oriented control makes a permanent-magnet machine behave like step
01's, the induction machine and the switched-reluctance machine.

<!--
Section 03, machines in real electric cars. There is no build in this section. We look at brushless
machines, at why field-oriented control makes a permanent-magnet machine behave like build 01's, and
at the two machines without magnets, the induction machine and the switched-reluctance machine. We
stay with concepts and one animation: the transforms that field-oriented control computes, and a
model of the machine in its rotating frame, are in the extra pack.
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
The induction machine, two slides on, is the one that slips.

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
routeAlias: induction
---

## The induction machine

<div class="grid grid-cols-2 gap-8">
<div>

**Build** (deck): three stator windings make a **rotating field**; the rotor is a cage of copper or
aluminum bars, short-circuited at the ends.

**How it pulls:** the field sweeps across the bars, induces currents in them, and the force on
those currents drags the rotor after the field.

**Slip:** at the field's speed nothing would be induced and there would be no torque. So the
rotor always runs a little slower: the slip grows with the torque.

</div>
<div>

**Control** (deck): the supply frequency sets the field's speed; the slip means it does not set
the rotor's exactly, so the speed is measured and fed back.

With field-oriented control an induction machine too behaves like a DC machine; but its field is
not free. The inverter must **magnetize the rotor with a d current**, and that current costs copper
loss at every operating point.

**No magnets:** no rare earths, and with the inverter off there is no field at all.

</div>
</div>

<!--
The induction machine, from the deck. On the left, how it is built: three stator windings, as in the
PMSM, make a rotating field. The rotor is a cage: bars of copper or aluminum, short-circuited at
both ends.

How it pulls: the field sweeps across the bars and induces currents in them, and the force of the
field on those currents drags the rotor along after the field.

Slip: if the rotor turned exactly at the field's speed, the bars would see no change of flux,
nothing would be induced, and there would be no torque. So the rotor always runs a little slower
than the field, and that difference, the slip, grows with the torque.

On the right, control. The supply frequency sets the speed of the field. Because of the slip, it
does not set the speed of the rotor exactly, so the speed is measured and fed back.

With field-oriented control an induction machine also behaves like a DC machine from the outside.
But its field is not free. It has no magnets, so the inverter must magnetize the rotor itself, with
a d current, and that current flows at every operating point and costs copper loss there.

And the last line, the other side of the coin: no magnets. No rare-earth materials, and when the
inverter is off there is no field at all.
-->

---
routeAlias: srm
---

## The switched-reluctance machine

<div class="grid grid-cols-2 gap-8">
<div>

**Reluctance** (deck): a magnetic field is "reluctant" to cross an air gap. A rotor of soft iron,
out of line with the field, is pulled into line to shorten the gap.

The SRM's rotor is **only laminated iron**: no magnets, no windings, no cage. The stator poles are
switched on one after another, and the rotor follows them.

</div>
<div>

**For it** (deck)

- very simple, potentially cheap, robust;
- high speeds: no back-EMF from magnets to limit it;
- the current need not alternate.

**Against it** (deck)

- the switching must be timed precisely to the rotor position;
- the torque pulses: **noisy**, with vibration.

Used in industry and appliances; in cars it has stayed rare.

</div>
</div>

<!--
The switched-reluctance machine. The left column explains the name. Reluctance is the magnetic
counterpart of resistance: a magnetic field is reluctant to cross an air gap and prefers iron. So a
rotor of soft iron that is out of line with a field is pulled into line, to shorten the gap, as a
compass needle turns into line, but without being a magnet itself.

The SRM uses only that. Its rotor is just laminated iron: no magnets, no windings, no cage. The
stator poles are switched on one after another, each pulling the rotor into line with it, and the
rotor follows them around.

The deck's case for it, top right. It is very simple, potentially cheap, and robust. It can run at
high speed, because there is no back-EMF from magnets to limit it. And the current in each coil need
not alternate: it only has to flow one way.

The case against it: the switching has to be timed precisely to the rotor's position, and the torque
comes in pulses, so the machine is noisy and vibrates. That is why it is used in industry and in
appliances, but has stayed rare in cars.
-->

---
routeAlias: pmsm-vs-induction
---

## PMSM or induction?

<div class="grid grid-cols-[1.2fr_1fr] gap-8">
<div class="tight">

| | PMSM | Induction |
|---|---|---|
| field | free, from the magnets | made by a d current, costs copper loss |
| rotor losses | small | currents in the cage |
| efficiency at light load | higher | lower |
| magnets | rare earths: cost, supply | none |
| unpowered, coasting | magnets still spin: iron loss, back-EMF | no field, no drag |
| at high speed | field weakening needed | field simply reduced |

</div>
<div>

**Why some all-wheel-drive cars pair one of each** (Audi, Q4 e-tron quattro): the PMSM on the rear
axle drives alone in moderate driving, for efficiency; the induction machine on the front axle
switches in when the driver asks for more power, and has minimal drag losses when inactive.

**Machines for hybrids** (deck): a short, wide machine on the crankshaft (Honda Insight), and
the same "inside-out" layout in wheel-hub motors: Lecture 5.

</div>
</div>

<!--
So, PMSM or induction? The table on the left compares them row by row.

The field: the PMSM's comes free, from its magnets; the induction machine makes it with a d current,
which costs copper loss. Rotor losses: small in the PMSM; in the induction machine, currents flow in
the cage. So the efficiency at light load is higher for the PMSM and lower for the induction
machine, and light load is where most of the WLTC is driven, as section 04 shows. Magnets: the PMSM
needs rare earths, with their cost and their supply risk; the induction machine needs none.
Unpowered and coasting: the PMSM's magnets still spin past the stator, so it still has iron loss and
a back-EMF; the induction machine has no field and no drag. And at high speed the PMSM needs field
weakening, to hold its back-EMF below the pack voltage, while the induction machine's field is
simply made smaller.

On the right, why some all-wheel-drive cars pair one of each. Audi's press kit for the Q4 e-tron
describes it. A permanent-magnet synchronous machine drives the rear axle, and in moderate driving
it drives the car alone, for efficiency. The quattro models add an induction machine on the front
axle, which switches in when the driver asks for more power than the rear can give; while it is
inactive, its drag losses are minimal, because it has no magnets.

And the deck's machines for hybrids: a short, wide machine sitting directly on the crankshaft, as in
the Honda Insight, and the same inside-out layout in wheel-hub motors. The hybrids are next lecture.
-->

---

## Summary of section 03

- Brushless machines move the windings to the stator and the commutator into an inverter.
- A PMSM under field-oriented control keeps its stator current a quarter turn ahead of the
  magnets: in the rotor's frame, **two steady currents**, *i*<sub>q</sub> for torque and
  *i*<sub>d</sub> for the field.
- From outside, that is **step 01's machine**: *T* ∝ *i*<sub>q</sub>, *E* ∝ ω, field weakening
  by a negative *i*<sub>d</sub>.
- Induction machines need no magnets but pay for their field; SRMs need neither but pulse.

### Next: what the converter does to that machine. <Link to="envelope">→ 04, the envelope</Link>

<!--
Section 03 in four lines. Brushless machines move the windings into the stator and the commutator
into an inverter. A PMSM under field-oriented control keeps its stator current a quarter turn ahead
of the magnets, so in the rotor's frame there are two steady currents: i q for torque, and i d for
the field. From the outside, that is build 01's machine: torque proportional to i q, back-EMF
proportional to omega, and field weakening by a negative i d. Induction machines need no magnets but
pay for their field; switched-reluctance machines need neither, but their torque pulses.

The inverter that does field-oriented control is, averaged over a switching period, a converter with
a duty and a field. That converter is the next build.
-->
