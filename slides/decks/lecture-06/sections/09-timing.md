---
routeAlias: timing
layout: section
---

###### Section 09

# Timing

Message periods, latency, bus load and worst-case response time; what they cost a control loop.

<!--
Section 09: timing. This is the price of the bus from section 01, in numbers. Where the delay comes
from, how full the bus is, how long a frame can wait in the worst case, and what a delay does to a
control loop. Then you measure it on the ABS.
-->

---
routeAlias: where-delay-comes-from
---

## Where the delay comes from

| Stage | Up to | Set by |
|---|---|---|
| 1. The value waits for the sender's next frame | one **period** | the message's cycle time: 10 ms, 20 ms, 100 ms |
| 2. The frame waits for the bus | the **queuing** time | higher-priority frames, and one lower frame already on the wire |
| 3. The frame is on the wire | the **transmission** time | its length and the bit rate: ≤ 270 µs for 8 bytes at 500 kbit/s |
| 4. The receiver's software picks it up | one **task period** | the receiving ECU's control cycle |

> Stages 1 and 4 are milliseconds; stages 2 and 3 are fractions of a millisecond. **The period
> dominates.**

<!--
A value measured in one ECU reaches the software of another in four stages.

First, the value waits for the sender's next frame. If the message is sent every 10 milliseconds,
a new value can wait up to 10 milliseconds before it is sent at all. Second, the frame waits for the
bus: for frames of higher priority, and for one lower-priority frame that may already be on the
wire, because a frame is never interrupted. Third, the frame travels: at 500 kilobits per second, an
eight-byte frame takes at most 270 microseconds, from section 06. Fourth, the receiving ECU's
software reads the new value at its next control cycle.

The box is the key fact. Stages 1 and 4 are milliseconds. Stages 2 and 3, the part that is actually
the bus, are fractions of a millisecond on a lightly loaded bus. So the delay a signal sees is
mostly set by how often it is sent, and that is a design choice of the car maker.
-->

---
routeAlias: bus-load
---

## Bus load

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

$$U = \sum_i \frac{C_i}{T_i}$$

- *C*<sub>i</sub>: worst-case transmission time of frame *i* (section 06)
- *T*<sub>i</sub>: its period
- *U*: the share of time the bus is busy

Keep it well below 100 %: errors need room for retransmissions, and next year's model needs room
for new messages.

</div>
<div>

### Three 8-byte frames at 500 kbit/s

| Frame | ID | *T* | *C* | *C/T* |
|---|---|---:|---:|---:|
| ABS active | 070h | 10 ms | 0.27 ms | 2.7 % |
| vehicle speed | 080h | 10 ms | 0.27 ms | 2.7 % |
| dashboard | 300h | 100 ms | 0.27 ms | 0.27 % |
| **bus load** | | | | **5.67 %** |

</div>
</div>

<!--
Bus load is the share of time the bus is busy. For each frame, divide its worst-case transmission
time C by its period T, and add them up.

On the right, a small example with three eight-byte frames at 500 kilobits per second. Each takes
at most 0.27 milliseconds, from the stuffing formula in section 06. The ABS-active frame and the
vehicle-speed frame are sent every 10 milliseconds: 2.7 percent each. The dashboard frame every 100
milliseconds: 0.27 percent. Together, 5.67 percent.

A real powertrain bus carries dozens of frames and runs at a much higher load. Car makers keep a
clear margin below 100 percent, for two reasons on the left: after an error, frames are sent again
and need room; and the next version of the car will add messages to the same bus.
-->

---
routeAlias: response-time
---

## Worst-case response time

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

$$R_i = C_i + w_i$$

$$w_i = B_i + \sum_{j \in hp(i)} \left\lceil \frac{w_i + \tau}{T_j} \right\rceil C_j$$

- *B*<sub>i</sub>: the longest **lower**-priority frame, which may just have started
- *hp(i)*: the frames with a **lower identifier**
- *τ*: one bit time
- Iterate from *w* = *B*; if *R* > *T*, the frame can miss its own period

</div>
<div>

### The same three frames

| Frame | *B* | *w* | *R* |
|---|---:|---:|---:|
| 070h ABS active | 0.27 | 0.27 | **0.54 ms** |
| 080h vehicle speed | 0.27 | 0.54 | **0.81 ms** |
| 300h dashboard | 0 | 0.54 | **0.81 ms** |

Even the lowest priority is delivered in under a millisecond, a tenth of its period.

</div>
</div>

<div class="caption text-left">Tindell, Burns and Wellings (1995), corrected by Davis, Burns, Bril
and Lukkien (2007) · <code>can_schedule(model)</code> computes this for the model's bus</div>

<!--
Bus load says how busy the bus is on average. The question a brake engineer asks is different: how
long can my frame wait in the worst case? Real-time researchers answered it in the nineties, and the
formula on the left is the standard result.

The response time R of frame i is its own transmission time C plus its queuing time w. The queuing
time has two parts. B is blocking: a lower-priority frame may have started a moment before, and a
frame is never interrupted, so we may have to wait for the longest one. Then every frame with a
lower identifier, a higher priority, can win the bus ahead of us, as often as it is sent during our
wait: that is the sum with the ceiling. The little tau, one bit time, covers the moment of
arbitration. Since w appears on both sides, you iterate: start with w equal to B, put it in, repeat
until it stops changing.

On the right, the three frames from the last slide. The ABS frame has the highest priority. It can
only be blocked by one lower frame already on the wire: 0.27 milliseconds, plus its own 0.27: 0.54.
Vehicle speed can be blocked once and can lose to the ABS frame once: 0.81. The dashboard frame has
nothing below it, so no blocking, but it can lose to both others: also 0.81 milliseconds.

The caption gives the sources. The original analysis from 1995 had a flaw that Davis and colleagues
corrected in 2007; the function can_schedule in our library uses the corrected version.
-->

---
routeAlias: delay-in-a-loop
---

## What a delay does to a control loop

<div class="grid grid-cols-2 gap-8">
<div>

A pure delay *τ* does not change a signal's size, only **when** it arrives. At frequency *f* it costs

$$\varphi = 360° \cdot f \cdot \tau$$

of phase.

| *τ* | at 2 Hz | at 5 Hz | at 10 Hz |
|---|---:|---:|---:|
| 10 ms | 7° | 18° | 36° |
| 20 ms | 14° | 36° | 72° |

</div>
<div>

- A feedback loop has a **phase margin**; every degree of delay is taken from it.
- Fast loops suffer most: a **wheel locks in tens of milliseconds**, so the ABS reacts at several
  hertz.
- Slow loops barely notice: the dashboard, the climate control, the cruise control.

> This is why the wheel-speed sensors are wired straight into the ABS ECU, and the dashboard gets its
> speed from the bus.

</div>
</div>

<!--
Why does a few milliseconds of delay matter? A pure delay leaves a signal's size unchanged; it only
shifts it in time. For an oscillation at frequency f, a delay tau costs a phase of 360 degrees times
f times tau. The table works it out: 10 milliseconds at 5 hertz is 18 degrees; 20 milliseconds at 10
hertz is 72 degrees.

Every feedback loop has a phase margin, the phase it can lose before it oscillates. Every degree of
delay is taken from that margin. Fast loops suffer most. A wheel goes from rolling to locked in
tens of milliseconds, so the ABS works at several hertz, and a delay of a message period is a large
part of its cycle. Slow loops barely notice: the dashboard, the climate control, cruise control.

The box is the design rule you can now explain. The ABS reads its wheel-speed sensors on its own
wires, with no bus in between. What it sends on the bus, the vehicle speed, goes to the slow
receivers: the dashboard, the motor controller.
-->

---
routeAlias: timing-in-the-model
---

## Timing in the model

| Real bus | Model |
|---|---|
| a value waits up to one period for its frame | sampled every `period` |
| queuing + transmission + receiver task | **one fixed period** of delay |
| arbitration, queuing | calculated by `can_schedule`, not simulated |
| clock jitter, unsynchronized ECUs | not modeled: every period starts on the same grid |

So the model's delay is between one and two periods, never the sub-millisecond bus time: it shows
the cost of the **period**, the part that dominates.

<div class="handson">Build 03: sweep the chassis messages' period against the ABS stopping distance.
Build 04: run <code>can_schedule</code> on your car and read its load and response times.</div>

<!--
Last, how the model handles timing, so you know what your numbers mean. A CanTx block samples its
input once per period, and the value arrives one full period later. That fixed delay stands for the
queuing, the transmission and the receiver picking it up. Together with the sampling, a change
reaches the receiver between one and two periods later.

Arbitration and queuing are not simulated; can_schedule calculates them from the identifiers,
periods and frame lengths. And the model's ECUs all run on the same clock grid, with no jitter. A
real car's ECUs drift against each other.

So the model shows the cost of the period, which is the part that dominates, from the first slide of
this section. Build 03 sweeps the period of the chassis messages and measures the ABS stopping
distance. Build 04 runs can_schedule on your car and reads its bus load and response times.
-->
