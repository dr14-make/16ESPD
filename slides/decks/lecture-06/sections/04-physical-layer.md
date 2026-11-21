---
routeAlias: physical-layer
layout: section
---

###### Section 04

# Physical layer

CAN_H and CAN_L, dominant and recessive, the 120 Ω terminations, topology, and how every node
samples the same bit.

<!--
Section 04, the physical layer. Here we leave the meeting room, because a room has no wires. We look
at the two wires of the bus and the voltages on them, at the resistors at the two ends, at how the
bus is laid out and how long it may be, and at the timing inside one bit.
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
The picture shows three bits on high-speed CAN: recessive, dominant, recessive. The top plot shows
the voltage on each wire. Remember, voltage is the electrical level of a wire, measured in volts.

In a recessive bit, a one, nobody drives the bus. Both wires rest at the same level, 2.5 volts. The
bottom plot shows the difference between the two wires: 0 volts.

In a dominant bit, a zero, the transceiver of the sending ECU pushes CAN high up to 3.5 volts and
CAN low down to 1.5 volts. The transceiver is the chip between the ECU and the wires. The difference
is now 2 volts.

A receiver looks only at the difference. Above 0.9 volts it reads dominant. Below 0.5 volts it reads
recessive. The band in between is undefined.

This is the reason for twisting the wires. A disturbance from outside, for example from an electric
motor, hits both wires almost equally. Both voltages move together, so their difference does not
change. The disturbance cancels.

The box is the key fact of this slide. Recessive means nobody drives. Dominant means somebody
drives. So one node that drives dominant beats any number of nodes that leave the bus recessive.
That is the clap that drowns out silence, built in hardware.
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
For comparison, this is low-speed fault-tolerant CAN, the kind used in doors and seats.

In a recessive bit, CAN high is near 0 volts and CAN low is near 5 volts. The bottom plot shows the
difference: minus 5 volts. In a dominant bit the two wires swap sides. CAN high rises to between 3.6
and 4 volts, and CAN low falls to between 1 and 1.4 volts. The difference is plus 2.2 to plus 3
volts.

This large swing has a purpose. A wire can break. It can also touch the car body or the battery
voltage by mistake, which is called a short. The transceiver detects both cases. It then carries on
with the remaining wire alone and measures that wire against ground, the car body. The functions on
that bus keep working.

The price is speed: at most 125 kilobits per second. For the rest of the lecture we stay with
high-speed CAN.
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
A high-speed CAN bus needs a resistor at each end. A resistor is a component that lets a limited
current flow between two points. Its size is given in ohms. Here it is 120 ohms, connected between
CAN high and CAN low. This resistor is called the termination. In the picture the two terminations
sit in the engine ECU and the gearbox ECU, at the two ends of the bus. The ABS ECU in the middle
hangs on a short stub and has no resistor.

The first bullet says why. An edge travels along the cable. At an open cable end it would bounce
back, like a wave off a wall, and disturb the following bits. That is a reflection. A 120-ohm
resistor matches the cable and absorbs the edge. The second bullet is the other job: the resistors
pull the two wires to the same level when nobody drives. That gives the recessive level.

The box on the right is a check that every workshop uses. An ohmmeter measures resistance. Two
120-ohm resistors side by side measure as 60 ohms. So with the ignition off, the meter between CAN
high and CAN low reads 60 ohms. If it reads 120, one termination is missing or one end of the bus is
disconnected.

The small inset shows a variant, split termination. The 120 ohms are divided into two halves of 60,
with a small capacitor from the middle to ground. It removes disturbances that lift both wires
together.
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
How may the bus be laid out? The layout of a network is called its topology. The picture shows
three. The letter R marks a termination.

On the left, linear. One line, a termination at each end, and the other ECUs on short stubs. This is
the standard layout for high-speed CAN.

In the middle, mixed. The bus runs into some ECUs and out again, so those ECUs need no stub. The two
ends are still terminated.

On the right, a star. Five ECUs sit on branches from one central point. Only two branches carry a
termination, so every other branch is an open end, and open ends cause reflections. A star works
only with short branches, a low bit rate and careful design.

So for high-speed CAN, remember the title: a line with short stubs.
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
How long may the bus be? The answer depends on the bit rate, and the reason is arbitration.

During arbitration, two nodes at opposite ends of the bus compare their bits. A node reads each bit
at one fixed moment inside the bit, called the sample point. A dominant bit from one end must reach
the far end, and the far node's own bit must travel back, before that moment. Otherwise both nodes
could believe they won.

The formula on the right says this. On the left of the inequality is the round trip: twice the
length L, at 5 nanoseconds per meter, plus 350 nanoseconds for the electronics of the two nodes. On
the right is the sample point times the duration of one bit.

The plot shows the result: the longest bus, in meters, against the bit rate. The shaded band is the
range for sample points between 75 and 87.5 percent of the bit. At 1000 kilobits per second the bus
may be 40 to 52 meters long. At 100 kilobits per second, about 700 to 850 meters. The orange dots
are the rule of thumb from the table: 40 meters at 1000 kilobits per second, 100 meters at 500, 250
at 250, and 500 at 125. The dots lie on or below the band, because a real design keeps a safety
margin.

The line under the table sums it up: a longer bus needs a longer bit. This also explains CAN FD from
the last section. It speeds up only after arbitration, when only one node is sending and no round
trip has to fit into a bit.
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
In section 01 we said that people cannot clap in time, but CAN nodes can. This slide shows how.

Each node has its own clock. It divides one bit into small equal steps called time quanta. In the
picture, one bit has 16 of them, in four segments. The first is the sync segment, one quantum long.
This is where the node expects an edge. The second, seven quanta long, is the propagation segment.
It covers the round trip on the bus from the last slide. Then come phase 1, five quanta, and phase
2, three quanta. The node reads the bit at the sample point, between phase 1 and phase 2. That is at
75 to 87.5 percent of the bit, when the voltage has settled.

The bullets on the left say how the clocks stay together. Every frame starts with one dominant bit,
the start of frame. On its edge, all nodes restart their bit clocks together. That is hard
synchronization. After that, each node checks every edge from recessive to dominant. If the edge
comes late, the node lengthens phase 1. If it comes early, the node shortens phase 2. That is
resynchronization. It needs edges often enough, and a rule called bit stuffing guarantees one at
least every 10 bits. The next section explains that rule.

The box gives the result. The clocks of the nodes differ by fractions of a percent, and still all
nodes read the same bit at the same moment. That is why the clapping works.

We now know how one bit crosses the bus. Next: how the bits form a frame.
-->
