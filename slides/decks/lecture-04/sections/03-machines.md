---
routeAlias: machines
layout: section
---

###### Section 03

# Machines in real EVs

Brushless machines, why field-oriented control makes a permanent-magnet machine behave like step
01's, the induction machine and the switched-reluctance machine.

<!--
Budget: about 15 minutes, no build. Deck 7 slides 34 to 39, extended with the PMSM under
field-oriented control. Concepts and the animation only: no Clarke or Park algebra (plan S3). A dq
model of the PMSM is in the extra pack.
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
Deck 7 slides 34 and 35. The brushed machine's commutator is a mechanical switch: it reverses each
coil's current as the coil passes the poles, so the torque keeps its direction. The price is
friction, wear and a hot rotor.

Swap the parts: magnets on the rotor, windings on the stator, where a cooling jacket can reach
them. Now something must switch the stator currents as the rotor turns, and that is the inverter
of section 05, told the rotor's position by Hall sensors.

The deck's point: the back-EMF of the approaching magnet grows with speed and opposes the current,
so the torque falls as the speed rises, exactly as on step 01's line. And because the back-EMF is
there whenever the rotor turns, the machine is a generator without any change.

The name is historical. It is an AC machine: each stator phase carries an alternating current.
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
| rotor position | Hall sensors, every 60° | resolver or encoder, continuous |
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
A BLDC and a PMSM are built the same way; the difference is the shape of the back-EMF and how the
inverter drives it. The BLDC is switched in blocks from three Hall sensors, cheap and good enough
for a fan, with a torque ripple at every switching instant. The traction machine is driven with
three sinusoidal currents and needs the rotor angle continuously, from a resolver.

The Leaf's motor, as ORNL measured the 2012 car: an 8-pole interior permanent-magnet machine, 48
stator slots, about 56 kilograms. Interior PM means the magnets sit in pockets inside the rotor
iron, which adds a reluctance torque; our model leaves that out (known limits).

Synchronous means the rotor turns exactly with the rotating field of the stator. The induction
machine, two slides on, is the one that slips.
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
The animation is a component of this deck, not a simulation: a two-pole rotor, red north, blue
south, turning inside a three-phase stator, a, b, c. Press play or pause; the second button turns
field weakening on.

Watch the red arrow, the stator current. The inverter keeps it at a fixed angle to the magnets: a
quarter turn ahead, on the axis called q. The force on the rotor is largest there, as in the
picture of the conductor in the field: current at right angles to the field.

On the right: the three phase currents the stator actually carries. They alternate, at the
rotor's electrical frequency, and the cursor follows the rotor. Below them: the same current seen
from the rotor. It does not change at all: one number along the magnets, d, one across them, q.
That is the whole trick of field-oriented control: in the rotor's frame the AC machine has DC
quantities, and the controller regulates them with two ordinary PI loops, like Lecture 1's.

Now turn field weakening on. The current vector swings back, toward the south pole: a negative d
current, which opposes the magnets' flux. The magnitude stays at the inverter's limit, so the q
part, and the torque, shrinks. That is what the Leaf's inverter does above base speed, and what
our converter does with its field input.

No transforms on this slide: Clarke and Park, which compute the d and q currents from the three
phase currents, are in the extra pack with the dq model of the machine.
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
The table is the justification of the whole build. Left, the machine you pasted. Right, the
machine in the Leaf, driven by its inverter. Row by row: the armature current is the q current;
torque is proportional to it, through a constant set by the magnets and the winding, which plays
K Phi; the back-EMF is proportional to speed through the same constant; the commutator's job is
done by the inverter with the rotor angle; turning the field down is done with a negative d
current.

So from the outside, from the battery's terminals and from the shaft, a PMSM under FOC is a DC
machine. That is the plan's decision S3: the car carries the DC-equivalent machine, physical, with
its losses as parts, and the efficiency map is computed from it.

Be honest about what is lost. An interior-magnet machine also makes a reluctance torque from the
d current, which the model has not. Field weakening in a real PMSM costs copper loss, because the
d current flows in the windings; in our model the field input is free. And the d and q currents
have their own millisecond dynamics. None of these changes a WLTC energy bill by much; all three
are in the extra pack.
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
Deck 7 slides 37 and 38. The induction machine is the oldest and most robust: a stator like the
PMSM's, and a rotor that is just a cage of conducting bars. The rotating field induces currents in
the bars, and those currents in that field give the force: the rotor chases the field.

It can never catch it: at the field's speed the bars would see no change in flux, no current, no
torque. The difference is the slip, a few percent, growing with the load. That is why the deck says
the frequency does not precisely control the speed: the drive measures the speed and closes the
loop.

Under field-oriented control it also looks like a DC machine. The difference that matters for an
EV: the rotor field has to be made by the stator, with a magnetizing current that always flows
and always heats the windings, and the rotor bars carry current too, with their own copper loss.
A PMSM gets its field free from the magnets. That is the efficiency gap, largest at light load.

The other side: no magnets. No rare-earth cost or supply risk, no demagnetization when hot, and an
unpowered induction machine has no field and no drag.
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
Deck 7 slide 36. Reluctance is the magnetic analogue of resistance: flux prefers iron to air. A
piece of iron in a field turns to line up with it, the way a compass needle does, but without
being a magnet.

The SRM uses only that. Its rotor has teeth of laminated iron; the stator energizes the pole pairs
in sequence, each pulling the nearest rotor tooth into line. The current through each coil only
needs to flow one way, so the power electronics are simple.

The deck's drawbacks are the reason it has stayed rare in cars: the torque comes in pulses, which
makes noise and vibration, and the control needs the rotor angle precisely. The deck's "higher
speed is possible" holds because there is no magnet back-EMF to fight at high speed.
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

**Why some all-wheel-drive cars pair one of each:** the axle that drives all the time carries the
efficient PMSM; the axle that helps only for acceleration and grip carries an induction machine,
which can coast along unpowered without drag.

**Machines for hybrids** (deck): a short, wide machine on the crankshaft (Honda Insight), and
the same "inside-out" layout in wheel-hub motors: Lecture 5.

</div>
</div>

<!--
The comparison the plan asks for. The PMSM's field is free; the induction machine has to make
its own, and its rotor cage carries current: both cost copper loss, most noticeable at light
load, where most of the WLTC is driven (section 04 shows where).

The PMSM's weakness is its magnets: rare-earth neodymium, often with dysprosium for heat
resistance, costly and concentrated in few suppliers. And they never turn off. A PMSM dragged along
unpowered still has its rotor field sweeping past the stator iron: iron loss, a drag torque, and
at high speed a back-EMF that the inverter must hold below the pack voltage by field weakening.

An induction machine with its inverter off has no field and spins freely. Hence the pairing in
dual-motor cars: the efficient PMSM on the axle that drives all the time, the induction machine
on the axle that helps only when needed; Tesla's dual-motor Model 3 and Model Y are built this
way, with the induction machine at the front.

Deck 7 slide 39 on machines for hybrids: Honda's Insight had a thin machine directly on the
crankshaft, a BLDC type; the same short and wide layout is used in wheel-hub motors. The P0 to P4
positions are Lecture 5.
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
One minute. The bridge to step 02: the inverter that does field-oriented control is, averaged
over a switching period, a converter with a duty and a field. That converter is the next build.
-->
