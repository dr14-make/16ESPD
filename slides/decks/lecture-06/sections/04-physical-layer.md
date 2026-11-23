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
routeAlias: inside-a-node
---

## Inside one node: from software to the wires

<div class="grid grid-cols-[2fr_1fr] gap-8 items-center">
<div>

<img src="/diagrams/04-ecu-stack.svg" class="w-full" alt="One ECU as three stacked parts. The microcontroller runs the software and packs signals into messages, OSI layer 7. It passes messages, an identifier and data bytes, to the CAN controller, which handles frames, arbitration, CRC, ACK and error counters, OSI layer 2. The controller sends bits to the transceiver on TXD and reads back what the bus carries on RXD. The transceiver turns bits into voltages on CAN_H and CAN_L, OSI layer 1, and is wired to the two bus lines. Two more ECUs hang on the same lines; every node has the same three parts."/>

</div>
<div>

- **Microcontroller**: the ECU's processor; its software decides what to send.
- **CAN controller**: builds and checks frames, takes part in arbitration.
- **Transceiver**: turns bits into voltages and back.
- The controller **reads back** every bit it sends, on RXD: that is how it notices it lost
  arbitration.

</div>
</div>

<div class="caption text-left">TXD: transmit data · RXD: receive data · the CAN controller is often
built into the microcontroller chip; the transceiver is a separate small chip</div>

<!--
Before the voltages, one picture of what sits inside every node. A node is any ECU on the bus. It
has three parts, stacked from the software down to the wires.

At the top is the microcontroller. It is the ECU's processor, a small computer on one chip. Its
software computes, for example, the vehicle speed, and decides which messages to send. In the OSI
model from section 02, that is layer 7.

In the middle is the CAN controller. The microcontroller hands it a message: an identifier and some
data bytes. The controller builds the frame, adds the check number, takes part in arbitration,
waits for the acknowledgement and counts errors. That is layer 2. The controller is often built into
the same chip as the microcontroller.

At the bottom is the transceiver, a separate small chip. Its name joins transmitter and receiver. It
turns the controller's bits into voltages on CAN high and CAN low, and turns the voltages back into
bits. That is layer 1, and it is the subject of this section.

Look at the two arrows between controller and transceiver. TXD carries the bits to send. RXD carries
back what is really on the bus. The controller compares the two for every bit. If it sent a one,
recessive, and reads back a zero, dominant, another node is sending a lower identifier. It has lost
arbitration and stops. That is the clap that you hear while you stay silent.

On the right, two more ECUs hang on the same two lines. Every node has the same three parts.
-->

---
routeAlias: dominant-and-recessive
---

## Dominant and recessive on high-speed CAN

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

<img src="/diagrams/04-hs-levels.svg" alt="High-speed CAN levels over three bits: recessive = 1, left alone; dominant = 0, driven; recessive = 1. Top, on a 0 to 5 V scale: in the recessive bits CAN_H and CAN_L both sit at 2.5 V; in the dominant bit CAN_H rises to 3.5 V and CAN_L falls to 1.5 V. Bottom, on a scale from minus 5 to plus 3 V: their difference is 0 V recessive and 2 V dominant, with the band between 0.5 and 0.9 V marked undefined: a receiver reads above 0.9 V as dominant and below 0.5 V as recessive. Typical values."/>

<div class="caption">ISO 11898-2 levels, typical values, with the receiver's thresholds</div>

</div>
<div>

| typical | CAN_H | CAN_L | difference | bit |
|---|---:|---:|---:|---:|
| **dominant** | 3.5 V | 1.5 V | 2 V | **0** |
| **recessive** | 2.5 V | 2.5 V | 0 V | **1** |

- **Dominant = 0 is driven**: the sender pushes CAN_H up and CAN_L down.
- **Recessive = 1 is left alone**: the terminations pull the lines together.
- A receiver reads only the **difference**: above 0.9 V dominant, below 0.5 V recessive. Noise hits
  both twisted wires alike and **cancels**.

> One node driving dominant beats any number of nodes leaving the bus recessive: the clap drowning
> out silence, in hardware.

</div>
</div>

<!--
The picture shows three bits on high-speed CAN: recessive, dominant, recessive. The top plot shows
the voltage on each wire. Remember, voltage is the electrical level of a wire, measured in volts.

First the two names, because the whole lecture uses them. Dominant is the logic value zero.
Recessive is the logic value one. And the one sentence to remember: dominant is driven, recessive is
left alone. A dominant bit needs a node that actively pushes the wires. A recessive bit is what the
bus does when no node pushes at all.

In a recessive bit, a one, nobody drives the bus. The terminations, two resistors we meet in two
slides, pull the wires together. The transceivers hold both near 2.5 volts, half of their 5-volt
supply. So both wires rest at the same level, and the bottom plot shows the difference between the
two wires: 0 volts.

In a dominant bit, a zero, the transceiver of the sending ECU pushes CAN high up to 3.5 volts and
CAN low down to 1.5 volts. The transceiver is the chip between the ECU and the wires. The difference
is now 2 volts. The table on the right lists the same numbers. They are typical values; the standard
allows a range around them.

A receiver looks only at the difference. Above 0.9 volts it reads dominant. Below 0.5 volts it reads
recessive. The band in between is undefined.

This is the reason for twisting the wires. A disturbance from outside, for example from an electric
motor, hits both wires almost equally. Both voltages move together, so their difference does not
change. The disturbance cancels.

The box is the key fact of this slide. Because recessive means nobody drives and dominant means
somebody drives, one node that drives dominant beats any number of nodes that leave the bus
recessive. That is the clap that drowns out silence, built in hardware.
-->

---
routeAlias: low-speed-levels
---

## High-speed and low-speed CAN side by side

<div class="grid grid-cols-2 gap-6">
<div>

<img src="/diagrams/04-hs-levels.svg" style="max-height: 14rem" class="mx-auto" alt="High-speed CAN levels, the same plot as on the previous slide: recessive = 1 with both lines at 2.5 V and a difference of 0 V; dominant = 0 with CAN_H at 3.5 V, CAN_L at 1.5 V and a difference of 2 V."/>

<div class="caption">High-speed, ISO 11898-2: a small swing around 2.5 V</div>

</div>
<div>

<img src="/diagrams/04-ls-levels.svg" style="max-height: 14rem" class="mx-auto" alt="Low-speed fault-tolerant CAN levels on the same voltage scale, over three bits: recessive = 1, left alone; dominant = 0, driven; recessive = 1. Top: recessive has CAN_L near 5 V and CAN_H near 0 V; in the dominant bit the lines swap sides, CAN_H to at least 3.6 V and CAN_L to at most 1.4 V. Bottom: the difference CAN_H minus CAN_L is minus 5 V recessive and at least plus 2.2 V, typically about plus 3 V, dominant."/>

<div class="caption">Low-speed fault-tolerant, ISO 11898-3: the lines swap sides</div>

</div>
</div>

| | Speed | Termination | Voltage swing | One wire broken or shorted |
|---|---|---|---|---|
| **High-speed** | ≤ 1 Mbit/s | 120 Ω at each end, matched to the cable | 2 V, fast edges | the bus stops |
| **Low-speed** | **≤ 125 kbit/s** | none matched: a resistor in every node | about 8 V, slow edges | **single-wire mode**, keeps working |

<!--
This slide puts the two kinds of CAN from section 03 next to each other, on the same voltage scale.
On the left is high-speed CAN from the last slide. On the right is low-speed fault-tolerant CAN, the
kind used in doors and seats. The names are the same on both: dominant is zero and is driven,
recessive is one and is left alone.

Look at the right plot. In a recessive bit, CAN high is near 0 volts and CAN low is near 5 volts. The
difference is minus 5 volts. In a dominant bit the two wires swap sides. CAN high rises to at least
3.6 volts, and CAN low falls to at most 1.4 volts. The difference is at least plus 2.2 volts,
typically about plus 3 volts. Compare that with the left plot: the high-speed lines move only one
volt each, around 2.5 volts.

The strength of low-speed CAN is in its transceiver. A wire can break. It can also touch the car body
or the battery voltage by mistake, which is called a short. The transceiver watches both wires and
detects both cases. It then switches to single-wire mode: it carries on with the remaining wire alone
and measures that wire against ground, the car body. The functions on that bus keep working. That is
the last column of the table.

The price is the first column: at most 125 kilobits per second. There are three reasons, one per
middle column and one from the last. First, termination. Low-speed CAN has no 120-ohm resistor
matched to the cable at the ends. Instead every node carries its own resistors, which pull the
lines to their recessive levels. Without matched ends, every edge reflects, and the reflections must
die out before the bit is read, which needs long bits. Second, the voltage swing. The difference
jumps by about 8 volts, from minus 5 to plus 3, and the transceiver makes these edges slow on
purpose, so that the wires do not radiate interference. A slow edge needs a long bit. Third, in
single-wire mode the bus is measured against ground. There is no second wire any more, so a
disturbance no longer cancels in the difference. The bits must be long enough to survive the noise.

High-speed CAN makes the opposite choice: matched ends, a small fast swing, and noise cancellation,
which buys 1 megabit per second, but one broken wire stops it. For the rest of the lecture we stay
with high-speed CAN.
-->

---
routeAlias: termination
---

## The 120 Ω terminations

<img src="/diagrams/04-termination.svg" class="w-full" style="max-height: 24rem" alt="A high-speed CAN bus, CAN_H and CAN_L, between the engine ECU and the gearbox ECU at its two ends, each with a 120 ohm resistor across the lines. The ABS ECU hangs off the bus on a short stub with no resistor. An ohmmeter across the lines reads 60 ohms, 120 in parallel with 120; 120 ohms would mean one end is missing. An inset shows split termination at an end node: two 60 ohm resistors in series between CAN_H and CAN_L, with a 4.7 nF capacitor from their midpoint to ground."/>

<div class="caption">Two terminations at the ends, none on the stub, and the ohmmeter check</div>

<div class="grid grid-cols-2 gap-8">
<div>

- One **120 Ω** resistor across CAN_H and CAN_L at **each end**, matching the cable's impedance;
  without it, every edge **reflects** from the cable ends and blurs the next bits.
- Together they pull the lines together when nobody drives: difference 0 V, recessive (1). The
  transceivers keep both lines near 2.5 V.

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
pull the two wires to the same level when nobody drives. That gives the recessive level, the logic
one, a difference of zero. The transceivers set where that level sits, near 2.5 volts.

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

<div class="caption text-left">R: a 120 Ω termination · short: about 0.3 m at 1 Mbit/s (ISO 11898-2
guidance)</div>

<!--
How may the bus be laid out? The layout of a network is called its topology. The picture shows
three. The letter R marks a termination.

On the left, linear. One line, a termination at each end, and the other ECUs on short stubs. This is
the standard layout for high-speed CAN. How short is short? At 1 megabit per second, the standard's
guidance is about 30 centimeters per stub. A slower bus tolerates longer stubs.

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
must come back within the propagation segment, **before the sample point**: the moment each node
reads the bit, 75–87.5 % into the bit time $T_\text{bit}$. Using the whole span up to the sample
point gives an upper bound.

$$2 L \cdot 5\,\tfrac{\text{ns}}{\text{m}} + 350\ \text{ns} \le \text{sample point} \times T_\text{bit}$$

| Rule of thumb | 40 m | 100 m | 250 m | 500 m |
|---|---:|---:|---:|---:|
| bit rate, kbit/s | 1000 | 500 | 250 | 125 |

A longer bus needs a longer bit.

</div>
</div>

<div class="caption text-left">Assumed: 5 ns/m in the cable; per node a transceiver loop delay of
150 ns (typical datasheet value) and 25 ns in the controller; the band spans sample points of 75 to
87.5 %, an upper bound, since phase segment 1 is kept for clock errors · the rule of thumb keeps a
margin for clock tolerance, stubs and synchronization</div>

<!--
How long may the bus be? The answer depends on the bit rate, and the reason is arbitration.

During arbitration, two nodes at opposite ends of the bus compare their bits. A node reads each bit
at one fixed moment inside the bit, called the sample point. A dominant bit from one end must reach
the far end, and the far node's own bit must travel back, before that moment. Otherwise both nodes
could believe they won. Strictly, the round trip must fit in the part of the bit before the
sample point that is not kept for clock errors, so the band we compute is an upper bound.

The formula on the right says this. On the left of the inequality is the round trip: twice the
length L, at 5 nanoseconds per meter, plus 350 nanoseconds for the electronics of the two nodes. On
the right is the sample point times the bit time, T bit, which is the duration of one bit.
At 500 kilobits per second a bit lasts 2 microseconds. The sample point is written as a fraction of the
bit, for example 0.875. The next slide shows the sample point inside the bit.

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

<img src="/diagrams/04-bit-timing.svg" alt="One bit cut into 16 time quanta: a one-quantum Sync segment, where a recessive-to-dominant (1 → 0) edge is expected, a seven-quantum Propagation segment that covers the round trip on the bus, Phase 1 of five quanta, lengthened for a late edge, and Phase 2 of three quanta, shortened for an early one. The sample point sits between Phase 1 and Phase 2, at 75 to 87.5 percent of the bit."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

- **NRZ** (non-return-to-zero): a bit holds its level for its whole time; only edges carry timing.
- **Hard synchronization** on the falling edge of the start-of-frame bit: every node restarts its bit
  clock together.
- **Resynchronization** on every recessive-to-dominant (1 → 0) edge: Phase 1 longer or Phase 2 shorter, by
  at most the **SJW** (synchronization jump width). **Bit stuffing** (section 05) guarantees an
  edge at least every 10 bits.

</div>
<div>

> This is why the clapping works: all nodes sample the **same** bit at the **same** instant, with
> clocks that drift by fractions of a percent.

</div>
</div>

<div class="caption text-left">tq: time quantum · at 500 kbit/s a bit lasts 2 µs · SJW: typically
1 to 4 tq, never more than the shorter phase segment</div>

<!--
In section 01 we said that people cannot clap in time, but CAN nodes can. This slide shows how.

Each node has its own clock. It divides one bit into small equal steps called time quanta. In the
picture, one bit has 16 of them, in four segments. The first is the sync segment, one quantum long.
This is where the node expects an edge. The second, seven quanta long, is the propagation segment.
It covers the round trip on the bus from the last slide. Then come phase 1, five quanta, and phase
2, three quanta. The node reads the bit at the sample point, between phase 1 and phase 2. That is at
75 to 87.5 percent of the bit, when the voltage has settled.

The bullets on the left say how the clocks stay together. The first is a name. CAN is NRZ, short
for non-return-to-zero: each bit holds its level for the whole bit time. So a run of equal bits has
no edges at all, and only the edges tell a node where a bit begins. Every frame starts with one dominant bit,
a zero, the start of frame. On its edge, all nodes restart their bit clocks together. That is hard
synchronization. After that, each node checks every edge from recessive to dominant, from one to zero. If the edge
comes late, the node lengthens phase 1. If it comes early, the node shortens phase 2. That is
resynchronization. The correction per edge is limited to a few quanta, the synchronization jump
width, SJW for short. The caption gives typical values. It needs edges often enough, and a rule called bit stuffing guarantees one at
least every 10 bits. The next section explains that rule.

The box gives the result. The clocks of the nodes differ by fractions of a percent, and still all
nodes read the same bit at the same moment. That is why the clapping works.

We now know how one bit crosses the bus. Next: how the bits form a frame.
-->
