---
routeAlias: timing
layout: section
---

###### Section 08

# Timing

Message periods, latency, bus load and worst-case response time; what they cost a control loop.

<!--
Section 08, timing. In section 01 we said that a bus trades wires for time. Now we put numbers on
the time. Where does the delay come from? How full is the bus? How long can a frame wait at worst?
And what does a delay do to a controller like the ABS?
-->

---
routeAlias: where-delay-comes-from
---

## Where the delay comes from

<div class="diagram-wide">

<img src="/diagrams/08-latency-chain.svg" alt="Timeline in three lanes, sender ECU, bus and receiver ECU, not to scale. The value changes at the left; stage 1, in the sender lane, a long bar: it waits for the next frame, up to one period. Stages 2 and 3, short bars in the bus lane: the frame waits in the queue, then is on the wire, together under a millisecond. Stage 4, a long bar in the receiver lane: it waits for the receiving task, up to its period, and then the control law uses it."/>

</div>

<div>

| Stage | Up to | Set by |
|---|---|---|
| 1. The value waits for the sender's next frame | one **period** | the message's cycle time: 10 ms, 20 ms, 100 ms |
| 2. The frame waits for the bus | the **queuing** time | higher-priority frames, and one lower frame already on the wire |
| 3. The frame is on the wire | the **transmission** time | its length and the bit rate: ≤ 270 µs for 8 bytes at 500 kbit/s |
| 4. The receiver's software picks it up | one **task period** | the receiving ECU's control cycle |

</div>

> Stages 1 and 4 are milliseconds; stages 2 and 3 are fractions of a millisecond. **The period
> dominates.**

<!--
The delay from the moment a value changes to the moment the receiver uses it is called the latency.
The picture shows it as a timeline with three lanes: the sender ECU, the bus and the receiver ECU.
It has four stages, and the table lists them.

Stage 1, the long bar in the sender lane. The value waits for the sender's next frame. The time
between two frames of a message is its period. If the period is 10 milliseconds, the value can wait
up to 10 milliseconds.

Stage 2, in the bus lane. The frame waits for the bus. It waits for frames with higher priority, and
for one frame of lower priority that is already on the wire, because a frame in progress is never
interrupted. This is the queuing time.

Stage 3. The frame is on the wire. For 8 bytes at 500 kilobits per second that takes at most 270
microseconds, from section 05.

Stage 4, the long bar in the receiver lane. The software in the receiving ECU runs in a fixed cycle,
called its task. It picks up the new value at its next cycle.

The box is the key fact. Stages 1 and 4 take milliseconds. Stages 2 and 3, the bus itself, take
fractions of a millisecond. So the period dominates. And the period is a choice of the car maker.

The next two slides look closer at stages 2 and 3.
-->

---
routeAlias: bus-load
---

## Bus load

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

$$U = \sum_i \frac{C_i}{T_i}$$

- *C*<sub>i</sub>: worst-case transmission time of frame *i* (section 05)
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
Bus load is the share of time during which the bus is busy. In the room, it is the share of the time
in which somebody is speaking.

The formula on the left says how to get it. For each frame, take C, its longest transmission time,
and divide by T, its period. Then add up all frames. The result is U, the bus load.

The table on the right is a small example: three frames of 8 bytes at 500 kilobits per second. Each
takes at most 0.27 milliseconds. The frame "ABS active" is sent every 10 milliseconds. 0.27 divided
by 10 is 2.7 percent. The vehicle speed frame is the same: 2.7 percent. The dashboard frame is sent
every 100 milliseconds: 0.27 percent. The sum is 5.67 percent. So this bus is busy less than 6
percent of the time.

The sentence on the left says to keep the load well below 100 percent, for two reasons. After an
error, frames are sent again, and that needs free time. And next year's model of the car will add
messages to the same bus.

Bus load is an average. The next slide asks about the worst case.
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
A brake engineer does not ask about the average. The question is: how long can my frame take in the
worst case? That is the worst-case response time, R.

The first formula says: R is C plus w. C is the frame's own transmission time. w is the time it
waits in the queue.

The second formula gives the waiting time. It has two parts. The first part is B, the blocking time.
A frame of lower priority may have started just before ours, and a frame in progress is never
interrupted. So we wait for the longest such frame. The second part is the sum. Every frame with a
lower identifier has a higher priority and goes before us, once for each time it is sent while we
wait. The small tau is one bit time. Because w is on both sides, you calculate in rounds: start with
w equal to B, and repeat until w stops changing.

The table on the right does this for the three frames from the last slide. All times are in
milliseconds. The ABS frame has the highest priority. Only one lower frame can block it. It waits
0.27, and with its own 0.27, R is 0.54. The vehicle speed frame can be blocked once and can lose to
the ABS frame once. It waits 0.54, and R is 0.81. The dashboard frame has no frame below it, so B is
zero. It can lose to both others. It waits 0.54, and R is 0.81.

So even the frame with the lowest priority arrives in under a millisecond.

You do not calculate this by hand. The function can_schedule does it for your model.
-->

---
routeAlias: delay-in-a-loop
---

## What a delay does to a control loop

<div class="grid grid-cols-2 gap-8 items-center">
<div>

<img src="/figures/08-phase-lag.svg" alt="Phase lag in degrees against frequency from 0 to 10 Hz, one straight line through the origin for each delay. At 10 Hz the lag is 18 degrees for 5 ms, 36 for 10 ms, 72 for 20 ms and 144 for 40 ms."/>

</div>
<div>

A pure delay *τ* does not change a signal's size, only **when** it arrives. At frequency *f* it costs
$\varphi = 360° \cdot f \cdot \tau$ of phase.

- A feedback loop has a **phase margin**; every degree of delay is taken from it.
- Fast loops suffer most: a **wheel locks in tens of milliseconds**, so the ABS reacts at several
  hertz.
- Slow loops barely notice: the dashboard, the climate control, the cruise control.

> This is why the wheel-speed sensors are wired straight into the ABS ECU, and the dashboard gets its
> speed from the bus.

</div>
</div>

<!--
Why do a few milliseconds matter? A controller such as the ABS works in a loop: measure, decide,
act, measure again. That is a control loop.

The text on the right starts with the basic fact. A pure delay does not change the size of a signal.
It changes only when the signal arrives. For a signal that swings back and forth, we express the
delay as a part of one full swing. One full swing is 360 degrees. This is called phase lag. The
formula says: phase lag is 360 degrees times the frequency times the delay.

The plot on the left draws this: phase lag against frequency, one line per delay. Read the right
edge, at 10 hertz, ten swings per second. A delay of 5 milliseconds costs 18 degrees. 10
milliseconds cost 36. 20 milliseconds cost 72. And 40 milliseconds cost 144 degrees, four tenths of
a full swing. With that much lag, a controller still pushes when it should already let go.

The bullets draw the conclusion. Every control loop tolerates only a limited phase lag before it
starts to swing by itself. That reserve is the phase margin, and every degree of delay comes out of
it. Fast loops suffer most. A wheel locks within tens of milliseconds, so the ABS must react at
several hertz. Slow loops hardly notice a delay: the dashboard, the climate control, the cruise
control.

The box gives a design rule that you can now explain. The wheel-speed sensors are wired directly
into the ABS ECU, with no bus in between. The dashboard gets its speed from the bus.
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
Last in this section: how the model treats timing, so that you know what your numbers mean. The
table compares a real bus with the model, row by row.

Row one. On a real bus, a value waits up to one period for its frame. In the model, the CanTx block
reads its input once per period.

Row two. On a real bus, the frame then queues, travels, and waits for the receiver's task. The model
replaces all three with one fixed delay of one period.

Row three. Arbitration and queuing are not simulated. The function can_schedule calculates them.

Row four. In a real car, the clocks of the ECUs are not synchronized, and their timing varies a
little, which is called jitter. The model leaves that out. All periods start on the same time grid.

The sentence below the table sums it up. In the model, a change reaches the receiver between one and
two periods later. The model does not show the short bus time under a millisecond. It shows the cost
of the period, which is the part that dominates.

The green box names the two builds. In build 03 you change the period of the chassis messages and
measure the ABS stopping distance. In build 04 you run can_schedule on your car and read its bus
load and response times.
-->
