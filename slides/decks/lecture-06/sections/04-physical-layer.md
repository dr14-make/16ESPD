---
routeAlias: physical-layer
layout: section
---

###### Section 04

# Physical layer

CAN_H and CAN_L, dominant and recessive, the 120 Ω terminations, topology, and how every node
samples the same bit.

<!--
Section 04: the physical layer. Here we leave the meeting room, because a room has no wires. We look
at the two signal lines, their voltage levels, the resistors at the two ends, how the bus may be
laid out, and the timing inside one bit.
-->

---
routeAlias: dominant-and-recessive
---

## Dominant and recessive on high-speed CAN

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

<img src="/diagrams/04-hs-levels.svg" alt="High-speed CAN levels over three bits, recessive, dominant, recessive. Top: in the recessive bits CAN_H and CAN_L both sit at 2.5 V; in the dominant bit CAN_H rises to 3.5 V and CAN_L falls to 1.5 V. Bottom: their difference is 0 V recessive and 2 V dominant, with the band between 0.5 and 0.9 V marked undefined: a receiver reads above 0.9 V as dominant and below 0.5 V as recessive."/>

<div class="caption">Redrawn from the source deck, slide 22, with the receiver's thresholds</div>

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
recessive, the bus is dominant. That is the clap drowning out silence from section 01, done by the
electronics. Engineers call it a wired-AND: the bus is a one only if every node sends a one.
-->

---
routeAlias: low-speed-levels
---

## Low-speed fault-tolerant CAN

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

<img src="/diagrams/04-ls-levels.svg" alt="Low-speed fault-tolerant CAN levels over three bits, recessive, dominant, recessive. Top: recessive has CAN_L near 5 V and CAN_H near 0 V; in the dominant bit the lines swap sides, CAN_H to 3.6 to 4 V and CAN_L to 1 to 1.4 V. Bottom: the difference CAN_H minus CAN_L is minus 5 V recessive and plus 2.2 to plus 3 V dominant."/>

<div class="caption">Redrawn from the source deck, slide 22 · ISO 11898-3 levels</div>

</div>
<div>

- Recessive: CAN_H low, CAN_L high, **−5 V** apart.
- Dominant: they swap sides, **+2.2 to +3 V** apart.
- The large swing lets a transceiver detect a broken or shorted wire and carry on **on the remaining
  wire alone**, against ground.
- The price: at most **125 kbit/s**.

</div>
</div>

<!--
For comparison, low-speed fault-tolerant CAN. In a recessive bit, CAN high sits near zero volts and
CAN low near five: the difference is minus five volts. In a dominant bit they swap sides: CAN high
rises to between 3.6 and 4 volts, CAN low falls to between 1 and 1.4. The difference is plus 2.2 to
plus 3 volts.

The large swing has a purpose. If one wire breaks or shorts to ground or to the battery, the
transceiver notices and carries on using the remaining wire alone, measured against ground. The
car keeps working, with less protection against noise. The price is speed: at most 125 kilobits per
second.
-->

---
routeAlias: termination
---

## The 120 Ω terminations

<img src="/diagrams/04-termination.svg" class="w-full" style="max-height: 24rem" alt="A high-speed CAN bus, CAN_H and CAN_L, between the engine ECU and the gearbox ECU at its two ends, each with a 120 ohm resistor across the lines. The ABS ECU hangs off the bus on a short stub with no resistor. An ohmmeter across the lines reads 60 ohms, 120 in parallel with 120; 120 ohms would mean one end is missing. An inset shows split termination at an end node: two 60 ohm resistors in series between CAN_H and CAN_L, with a 4.7 nF capacitor from their midpoint to ground."/>

<div class="caption">Redrawn from the source deck, slide 23, with the ohmmeter check</div>

<div class="grid grid-cols-2 gap-8">
<div>

- One **120 Ω** resistor across CAN_H and CAN_L at **each end**, matching the cable's impedance;
  without it, every edge **reflects** from the cable ends and blurs the next bits.
- Together they pull the lines together for the recessive level.

</div>
<div>

> The workshop check: with the ignition off, an ohmmeter across CAN_H and CAN_L reads **60 Ω**.
> 120 Ω means one termination is missing.

</div>
</div>

<!--
The bus needs a resistor at each end: 120 ohms between CAN high and CAN low. In the picture they sit
inside the engine ECU and the gearbox ECU, at the two ends. The ABS in the middle
hangs off the bus on a short stub and has none.

Why are they needed? A twisted pair has a characteristic impedance of about 120 ohms. A signal edge
travelling down the cable, reaching an open end, reflects back, and the reflection mixes with the
following bits. A resistor equal to the cable's impedance absorbs the edge instead. The two
resistors also do the job from the previous slide: they pull the two lines together when nobody
drives, which makes the recessive level.

The inset shows split termination: the 120 ohms split into two 60 ohm halves, with a small
capacitor from the midpoint to ground. It drains common-mode noise, noise that lifts both wires
together.

And the workshop check, drawn between the lines and repeated in the box. Two 120 ohm resistors in parallel make 60 ohms. With the ignition
off, an ohmmeter between CAN high and CAN low at the diagnostic socket should read 60 ohms. If it
reads 120, one termination is missing or one end of the bus is disconnected.
-->

---
routeAlias: topology
---

## Topology: a line with short stubs

<div class="diagram-wide">

<img src="/diagrams/04-topology.svg" alt="Three bus layouts side by side. Linear: one line with an ECU marked R for termination at each end and three ECUs on short stubs. Mixed: the bus runs into two ECUs and out again, with no stub, plus one short stub, terminated at both ends. Star: five ECUs on branches from one central point, two of them marked R; every branch reflects."/>

</div>

<div class="grid grid-cols-3 gap-6">
<div class="caption"><b>Linear</b>: terminations at the two ends, short stubs — the standard
layout for high-speed CAN</div>
<div class="caption"><b>Mixed</b>: the bus loops through some ECUs, which keeps the stubs short</div>
<div class="caption"><b>Star</b>: every branch is an unterminated end; only with care, short
branches and a low bit rate</div>
</div>

<div class="caption text-left">R: a 120 Ω termination · redrawn from the source deck, slide 24</div>

<!--
How may the bus be laid out? The source deck shows three choices.

On the left, linear: one line with a termination at each end, and the other ECUs on short stubs.
That is the layout the high-speed standard is designed for. In the middle, mixed: the bus loops
into some ECUs and out again, which keeps the stubs short. On the right, a star: all ECUs joined at
one point. Every branch of a star is an unterminated end that reflects, so a star works only with
short branches, a low bit rate and careful design. It is not an equal choice for high-speed CAN.
-->

---
routeAlias: bus-length
---

## How long the bus may be

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

<img src="/figures/04-bus-length.svg" alt="Log-log plot of the longest bus in meters against the bit rate from 100 to 1000 kbit/s. A shaded band between two falling curves, sample point at 75 percent below and 87.5 percent above, runs from about 700 to 850 m at 100 kbit/s down to 40 to 52 m at 1000 kbit/s. Orange dots mark the rule of thumb, 500 m at 125, 250 m at 250, 100 m at 500 and 40 m at 1000 kbit/s, on or below the band."/>

</div>
<div>

During arbitration a dominant bit from one end must reach the far end, and the far node's own bit
must come back, **before the sample point**:

$$2 L \cdot 5\,\tfrac{\text{ns}}{\text{m}} + 350\ \text{ns} \le \text{sample point} \times T_\text{bit}$$

| Rule of thumb | 40 m | 100 m | 250 m | 500 m |
|---|---:|---:|---:|---:|
| bit rate, kbit/s | 1000 | 500 | 250 | 125 |

A longer bus needs a longer bit.

</div>
</div>

<div class="caption text-left">Assumed: 5 ns/m in the cable; per node a transceiver loop delay of
150 ns (typical datasheet value) and 25 ns in the controller; the band spans sample points of 75 to
87.5 % · the rule of thumb keeps a margin for clock tolerance, stubs and synchronization</div>

<!--
Why does the bus length depend on the bit rate? Because of arbitration. While two nodes compare
bits, a dominant bit sent at one end must reach the far end, and that node's own bit must travel
back, before the sample point of the same bit. Otherwise the sender would sample its own recessive
bit before the other node's dominant one arrives, and two nodes would both believe they won.

So the round trip along the whole bus must fit before the sample point. The signal travels about
5 nanoseconds per meter of cable, there and back. On top come the electronics: two transceivers,
each about 150 nanoseconds from its transmit pin through the bus and back to its receive pin, and
the two controllers. About 350 nanoseconds in all.

The plot solves that inequality for the length. The band is the range of usual sample points, 75 to
87.5 percent of the bit. At one megabit per second a bit lasts one microsecond, and the bus can be
40 to 50 meters. At 500 kilobits, a bit of 2 microseconds, over 100 meters. At 125 kilobits, more
than 500. The orange dots are the rule of thumb from the source deck and the standards' application
notes; they sit at or below the band, because a real design also keeps a margin for the clock
tolerance of each node, for stubs, and for synchronization.

That is also why CAN FD switches to its faster rate only after arbitration is over: the data phase
has only one sender, so no round trip has to fit in its bits.
-->

---
routeAlias: bit-timing
---

## Inside one bit

<div class="diagram-wide">

<img src="/diagrams/04-bit-timing.svg" alt="One bit cut into 16 time quanta: a one-quantum Sync segment, where a recessive-to-dominant edge is expected, a seven-quantum Propagation segment that covers the round trip on the bus, Phase 1 of five quanta, lengthened for a late edge, and Phase 2 of three quanta, shortened for an early one. The sample point sits between Phase 1 and Phase 2, at 75 to 87.5 percent of the bit."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

- **Hard synchronization** on the falling edge of the start-of-frame bit: every node restarts its bit
  clock together.
- **Resynchronization** on every recessive-to-dominant edge after that; **bit stuffing**
  (section 05) guarantees one at least every 10 bits.

</div>
<div>

> This is why the clapping works: all nodes sample the **same** bit at the **same** instant, with
> clocks that drift by fractions of a percent.

</div>
</div>

<div class="caption text-left">tq: time quantum · at 500 kbit/s a bit lasts 2 µs</div>

<!--
Here is the answer to the first place where the meeting room failed: how do all nodes clap in sync?

Every node divides one bit into time quanta, small ticks of its own clock, typically 8 to 25 per
bit. The bit has four segments. The sync segment, one quantum long, is where an edge is expected.
The propagation segment covers the time a signal needs to cross the bus and come back. Then two
phase segments. The node reads the bit at the sample point, between phase 1 and phase 2, typically
three quarters to seven eighths of the way through the bit, when the level has settled.

The bullets are how the clocks stay together. At the start of every frame, all nodes see the
falling edge of the start-of-frame bit and restart their bit clocks together: hard synchronization.
After that, on every edge from recessive to dominant, a node checks where the edge fell. If it
came early or late, the node stretches phase 1 or shrinks phase 2 by a few quanta, and so follows
the sender. For that to work there must be edges often enough, and bit stuffing, in the next
section, makes sure there is one at least every ten bits.

So the oscillators of the nodes can drift by fractions of a percent, and still every node samples
the same bit at the same instant. That is what makes bitwise arbitration possible.
-->
