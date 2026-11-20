---
routeAlias: physical-layer
layout: section
---

###### Section 05

# Physical layer

CAN_H and CAN_L, dominant and recessive, the 120 Ω terminations, topology, and how every node
samples the same bit.

<!--
Section 05: the physical layer. Here we leave the meeting room, because a room has no wires. We look
at the two signal lines, their voltage levels, the resistors at the two ends, how the bus may be
laid out, and the timing inside one bit.
-->

---
routeAlias: dominant-and-recessive
---

## Dominant and recessive on high-speed CAN

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

<img src="/pptx/slide22-hs-levels.png" alt="High-speed CAN levels: during a recessive bit both CAN High and CAN Low sit at 2.5 V and the differential voltage is 0 V; during a dominant bit CAN High rises to 3.5 V and CAN Low falls to 1.5 V, a differential voltage of 2 V."/>

<div class="caption">From the source deck, slide 22</div>

</div>
<div>

- **Recessive (1)**: nobody drives; the terminations pull both lines to 2.5 V. Difference **0 V**.
- **Dominant (0)**: a transceiver drives CAN_H up and CAN_L down. Difference **2 V**.
- A receiver reads only the **difference**: above 0.9 V is dominant, below 0.5 V recessive.
- Noise hits both twisted wires alike and **cancels** in the difference.

> One node driving dominant beats any number of nodes leaving the bus recessive. That is the clap
> drowning out silence, in hardware.

</div>
</div>

<!--
Here are the voltages on high-speed CAN. The idle state, and a logical one, is called recessive. In
a recessive bit nobody drives the bus at all; the termination resistors pull both lines to the same
voltage, about 2.5 volts. The difference between them is zero.

A logical zero is called dominant. A transceiver, the chip between the CAN controller and the
wires, actively pushes CAN high up to about 3.5 volts and CAN low down to about 1.5. The difference
is 2 volts.

A receiver looks only at the difference. Above 0.9 volts it reads dominant, below 0.5 it reads
recessive. That is why the two wires are twisted: electrical noise from an ignition coil or a motor
hits both wires almost equally, and in the difference it cancels.

The box at the bottom is the most important fact on this slide. Recessive means nobody drives.
Dominant means someone drives. So if one node drives dominant while all the others leave the bus
recessive, the bus is dominant. That is the clap drowning out silence from section 02, done by the
electronics. Engineers call it a wired-AND: the bus is a one only if every node sends a one.
-->

---
routeAlias: low-speed-levels
---

## Low-speed fault-tolerant CAN

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

<img src="/pptx/slide22-ls-levels.png" alt="Low-speed fault-tolerant CAN levels: recessive has CAN Low near 5 V and CAN High near 0 V, a differential of minus 5 V; dominant has CAN High near 4 V and CAN Low near 1 V, a differential of plus 3 V."/>

<div class="caption">From the source deck, slide 22</div>

</div>
<div>

- Recessive: CAN_H low, CAN_L high, **−5 V** apart.
- Dominant: they swap sides, **+3 V** apart.
- The large swing lets a transceiver detect a broken or shorted wire and carry on **on the remaining
  wire alone**, against ground.
- The price: at most **125 kbit/s**.

</div>
</div>

<!--
For comparison, low-speed fault-tolerant CAN. In a recessive bit, CAN high sits near zero volts and
CAN low near five: the difference is minus five volts. In a dominant bit they swap sides, to about
four and one volts: plus three volts.

The large swing has a purpose. If one wire breaks or shorts to ground or to the battery, the
transceiver notices and carries on using the remaining wire alone, measured against ground. The
car keeps working, with less protection against noise. The price is speed: at most 125 kilobits per
second.
-->

---
routeAlias: termination
---

## The 120 Ω terminations

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

<img src="/pptx/slide23-termination.png" alt="A high-speed CAN bus between the engine controller and the automatic transmission, each with a 120 ohm resistor across CAN High and CAN Low, and the ABS unit on a stub in between without a resistor. An inset shows split termination: two 60 ohm resistors in series between CAN High and CAN Low, with a 4.7 nF capacitor from their midpoint to ground."/>

<div class="caption">From the source deck, slide 23</div>

</div>
<div>

- One **120 Ω** resistor across CAN_H and CAN_L at **each end** of the bus, matching the cable's
  impedance.
- Without it, every edge **reflects** from the cable ends and blurs the next bits.
- Together they pull the lines together for the recessive level.
- **Split termination**: 2 × 60 Ω with a capacitor to ground also filters common-mode noise.

> The workshop check: with the ignition off, an ohmmeter across CAN_H and CAN_L reads **60 Ω**.
> 120 Ω means one termination is missing.

</div>
</div>

<!--
The bus needs a resistor at each end: 120 ohms between CAN high and CAN low. In the picture they sit
inside the engine controller and the automatic transmission, at the two ends. The ABS in the middle
hangs off the bus on a short stub and has none.

Why are they needed? A twisted pair has a characteristic impedance of about 120 ohms. A signal edge
travelling down the cable, reaching an open end, reflects back, and the reflection mixes with the
following bits. A resistor equal to the cable's impedance absorbs the edge instead. The two
resistors also do the job from the previous slide: they pull the two lines together when nobody
drives, which makes the recessive level.

The inset shows split termination: the 120 ohms split into two 60 ohm halves, with a small
capacitor from the midpoint to ground. It drains common-mode noise, noise that lifts both wires
together.

And the workshop check in the box. Two 120 ohm resistors in parallel make 60 ohms. With the ignition
off, an ohmmeter between CAN high and CAN low at the diagnostic socket should read 60 ohms. If it
reads 120, one termination is missing or one end of the bus is disconnected.
-->

---
routeAlias: topology
---

## Topology: a line with short stubs

<div class="grid grid-cols-3 gap-6 items-end">
<div>

<img src="/pptx/slide24-topology-linear.png" alt="Linear topology: five ECUs on one line, the two end ECUs marked R for the terminations, the middle ECUs on short stubs."/>

<div class="caption"><b>Linear</b>: terminations at the two ends, short stubs — the standard
layout for high-speed CAN</div>

</div>
<div>

<img src="/pptx/slide24-topology-mixed.png" alt="Mixed topology: a line where some ECUs are reached by looping the bus through the ECU and back, others by stubs."/>

<div class="caption"><b>Mixed</b>: the bus loops through some ECUs, which keeps the stubs short</div>

</div>
<div>

<img src="/pptx/slide24-topology-star.png" alt="Star topology: five ECUs joined at one central point, two of them marked R."/>

<div class="caption"><b>Star</b>: every branch reflects; only with care, short branches and a
low bit rate</div>

</div>
</div>

| Bus length, rule of thumb | ≈ 40 m | ≈ 100 m | ≈ 500 m |
|---|---:|---:|---:|
| bit rate | 1 Mbit/s | 500 kbit/s | 125 kbit/s |

<div class="caption text-left">During arbitration a bit must reach the far end of the bus and the
answer come back before the sample point, so a longer bus needs a longer bit</div>

<!--
How may the bus be laid out? The source deck shows three choices.

On the left, linear: one line with a termination at each end, and the other ECUs on short stubs.
That is the layout the high-speed standard is designed for. In the middle, mixed: the bus loops
into some ECUs and out again, which keeps the stubs short. On the right, a star: all ECUs joined at
one point. Every branch of a star is an unterminated end that reflects, so a star works only with
short branches, a low bit rate and careful design. It is not an equal choice for high-speed CAN.

The table gives the rule of thumb for bus length. The reason is arbitration. While two nodes compare
bits, a dominant bit sent at one end must reach the far end, and that node's own bit must travel
back, before the sample point of the same bit. So the round trip along the whole bus must fit
inside part of one bit time. At one megabit per second a bit lasts one microsecond, and the bus can
be about 40 meters. At 500 kilobits, about 100. At 125 kilobits, about 500. That is also why CAN FD
switches to its faster rate only after arbitration is over.
-->

---
routeAlias: bit-timing
---

## Inside one bit

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

A bit is cut into **time quanta**, typically 8 to 25 ticks of the node's own clock:

| Sync | Propagation | Phase 1 | Phase 2 |
|:-:|:-:|:-:|:-:|
| 1 tq | covers the bus delay | can grow | can shrink |

The node reads the bit at the **sample point**, between Phase 1 and Phase 2, typically at **75–87.5 %**
of the bit.

</div>
<div>

- **Hard synchronization** on the falling edge of the start-of-frame bit: every node restarts its bit
  clock together.
- **Resynchronization** on every recessive-to-dominant edge after that: a node whose edge comes early
  or late stretches Phase 1 or shrinks Phase 2.
- **Bit stuffing** (section 06) guarantees such an edge at least every 10 bits.

</div>
</div>

> This is why the clapping works: all nodes sample the **same** bit at the **same** instant, with
> clocks that drift by fractions of a percent.

<div class="caption text-left">tq: time quantum · at 500 kbit/s a bit lasts 2 µs</div>

<!--
Here is the answer to the first place where the meeting room failed: how do all nodes clap in sync?

Every node divides one bit into time quanta, small ticks of its own clock, typically 8 to 25 per
bit. The bit has four segments. The sync segment, one quantum long, is where an edge is expected.
The propagation segment covers the time a signal needs to cross the bus and come back. Then two
phase segments. The node reads the bit at the sample point, between phase 1 and phase 2, typically
three quarters to seven eighths of the way through the bit, when the level has settled.

The right column is how the clocks stay together. At the start of every frame, all nodes see the
falling edge of the start-of-frame bit and restart their bit clocks together: hard synchronization.
After that, on every edge from recessive to dominant, a node checks where the edge fell. If it
came early or late, the node stretches phase 1 or shrinks phase 2 by a few quanta, and so follows
the sender. For that to work there must be edges often enough, and bit stuffing, in the next
section, makes sure there is one at least every ten bits.

So the oscillators of the nodes can drift by fractions of a percent, and still every node samples
the same bit at the same instant. That is what makes bitwise arbitration possible.
-->
