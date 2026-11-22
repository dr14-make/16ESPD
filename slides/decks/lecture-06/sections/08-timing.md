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
routeAlias: what-a-receiver-sees
layout: default
class: big-figure
---

## What a receiver sees

<img src="/figures/08-sample-hold.svg" alt="Vehicle speed during a braking as a smooth falling curve, and below or over it what a receiver holds when the speed is sent every 10, 20 and 40 ms: three staircases that follow the curve, each one late by up to its period, with longer and coarser steps the longer the period."/>

<div class="caption">Vehicle speed during a braking, and what a receiver holds when it is sent every 10, 20
and 40 ms</div>

> Over the bus a signal arrives **late**, **in steps**, and only **once per period**. The longer the
> period, the worse all three.

<!--
Before any formula, one picture of what this section is about. The smooth curve is the vehicle
speed while the car brakes. That is what the brake ECU measures.

The staircases are what a receiver, for example the dashboard or the engine ECU, holds. The brake ECU
sends the speed once per period. Between two frames the receiver has nothing new, so it holds the
last value. That makes the steps.

There are three staircases, for periods of 10, 20 and 40 milliseconds. Compare them with the curve.
Each one is late: a step starts only when a new frame comes in. Each one moves in steps, not
smoothly. And each one changes only once per period. The longer the period, the later and the
coarser the staircase.

That is the box: late, in steps, once per period. The rest of this section puts numbers on the
delay, and then asks what it costs a controller.
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
| vehicle speed | 1A0h | 10 ms | 0.27 ms | 2.7 % |
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

$$w_i = B_i + \sum_{j \in hp(i)} \left\lceil \frac{w_i + t_\text{bit}}{T_j} \right\rceil C_j$$

- *B*<sub>i</sub>: the longest **lower**-priority frame, which may just have started
- *hp(i)*: the frames with a **lower identifier**
- *t*<sub>bit</sub>: one bit time
- Iterate from *w* = *B*; the simple form holds only while the bus clears this frame and every
  higher-priority one within its period

</div>
<div>

### The same three frames

| Frame | *B* | *w* | *R* |
|---|---:|---:|---:|
| 070h ABS active | 0.27 | 0.27 | **0.54 ms** |
| 1A0h vehicle speed | 0.27 | 0.54 | **0.81 ms** |
| 300h dashboard | 0 | 0.54 | **0.81 ms** |

Even the lowest priority is delivered in under a millisecond, far inside every period.

</div>
</div>

<div class="caption text-left">Tindell et al. (1994, 1995) · valid while the frame's busy period ends
within its period <i>T</i>; near full load even <i>R</i> ≤ <i>T</i> is not enough, and Davis, Burns, Bril and
Lukkien (2007) give the general form · <code>can_schedule(model)</code> computes this
simple form for the model's bus</div>

<!--
A brake engineer does not ask about the average. The question is: how long can my frame take in the
worst case? That is the worst-case response time, R.

The first formula says: R is C plus w. C is the frame's own transmission time. w is the time it
waits in the queue.

The second formula gives the waiting time. It has two parts. The first part is B, the blocking time.
A frame of lower priority may have started just before ours, and a frame in progress is never
interrupted. So we wait for the longest such frame. The second part is the sum. Every frame with a
lower identifier has a higher priority and goes before us, once for each time it is sent while we
wait. The small t with "bit" is one bit time. Because w is on both sides, you calculate in rounds: start with
w equal to B, and repeat until w stops changing.

The table on the right does this for the three frames from the last slide. All times are in
milliseconds. The ABS frame has the highest priority. Only one lower frame can block it. It waits
0.27, and with its own 0.27, R is 0.54. The vehicle speed frame can be blocked once and can lose to
the ABS frame once. It waits 0.54, and R is 0.81. The dashboard frame has no frame below it, so B is
zero. It can lose to both others. It waits 0.54, and R is 0.81.

So even the frame with the lowest priority arrives in under a millisecond, far inside its period of
100 milliseconds, and the others far inside their 10.

One warning about the formula, in the caption. It is the original analysis, first published in 1994.
It looks only at the first frame after the worst moment. That is safe only if the bus is done with
this frame and all frames of higher priority before the next copy of it is queued. That stretch of
busy bus is called the busy period. In 2007 Davis and colleagues showed that the simple form can be
too optimistic near full load, even when every response time is shorter than the period, and gave a
longer, general form. Our busy period is under a millisecond and our periods are 10 milliseconds or
more, so the simple form is fine.

You do not calculate this by hand. The function can_schedule does it for your model. It uses
exactly this simple form. If a frame's response time would exceed its period, it does not try the
general form; it reports infinity, so you know that frame can miss its period.
-->

---
routeAlias: worst-case-drawn
layout: default
class: big-figure
---

## The worst case, drawn

<img src="/figures/08-worst-case.svg" alt="Timeline at 500 kbit/s of the worst case for each of the three frames 070h, 1A0h and 300h, with a lower-priority blocker frame already on the wire. Bars show when each frame waits and when it is on the wire; brackets mark the blocking time B, the waiting time w and the response time R: 0.54 ms for 070h, 0.81 ms for 1A0h and 0.81 ms for 300h."/>

<div class="caption">The three frames of the table at 500 kbit/s · B blocking, w waiting, R response time
· R = 0.54 ms (070h), 0.81 ms (1A0h), 0.81 ms (300h)</div>

> A frame waits for **one** lower frame already on the wire, then for **every** higher frame queued
> with it.

<!--
This is the table from the last slide as a timeline. Time runs to the right. Each bar is a frame on
the wire, and the brackets mark the three quantities: B, the blocking; w, the whole waiting time; and
R, the response time.

Start with the ABS frame, 070. At the worst moment, a frame of lower priority has just started.
Nobody can interrupt it, so 070 waits for it: that is B. Then 070 wins the next arbitration and goes
onto the wire. Its response time is 0.54 milliseconds.

The vehicle speed frame, 1A0, is queued at the same worst moment. It waits for the same blocker, then
loses the arbitration to 070, then goes. Its response time is 0.81 milliseconds.

The dashboard frame, 300, has no frame below it, so nothing blocks it. But it loses to both 070 and
1A0. It also ends at 0.81 milliseconds.

The box sums up the rule that the formula writes in symbols: wait for one lower frame that is already
on the wire, then for every higher frame queued with you. In the room: you wait for the current
speaker to finish, and then for everybody who outranks you.
-->

---
routeAlias: load-vs-bitrate
layout: default
class: big-figure
---

## Bus load and bit rate

<img src="/figures/08-load-vs-bitrate.svg" alt="Bus load and worst-case response time of the three frames 070h, 1A0h and 300h plotted against the bit rate, 125, 250, 500 and 1000 kbit/s. Both fall as the bit rate rises: every frame takes half as long when the bit rate doubles."/>

<div class="caption">The same three frames at 125, 250, 500 and 1000 kbit/s, computed with the
<code>can_schedule</code> formula</div>

> Halve the bit rate and every frame takes twice as long: the load **and** the response times double.
> A slower bus allows a longer cable, and it fills up sooner.

<!--
How does all this depend on the bit rate? This plot takes the same three frames and computes them
at four bit rates: 125, 250, 500 and 1000 kilobits per second. It uses the same formulas as
can_schedule.

Read it from right to left. At each step down, the bit rate halves. Every bit then takes twice as
long, so every frame takes twice as long on the wire. The bus load is frame time divided by period,
so it doubles too. And the worst-case response time is made of frame times, so it doubles as well.

Why would anyone pick a slow bus, then? Section 04 gave the main reason: a slower bus allows a
longer cable. Comfort buses for doors and seats often run at 125 kilobits per second or less. The price is that the bus fills up sooner, and the reserve for retransmissions
and new messages shrinks.

For our three frames every bit rate is fine. For a real bus with dozens of frames, this is the
first number a network designer checks.
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

- **Phase margin** (Lecture 1): the extra lag a loop can take before it starts to oscillate. Every
  degree of delay comes out of it.
- Fast loops suffer most: the ABS of Lecture 3 decides every **5 ms** and cycles the brake several
  times per second. Slow loops, such as the dashboard, barely notice.
- The delay is not the period: in the model a message arrives **1 to 2 periods** late, **1.5 on
  average**. A 20 ms period costs ≈ 30 ms: **108°** at 10 Hz, not 72°.

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
formula says: phase lag is 360 degrees times the frequency times the delay, tau. Here tau is a
delay, not the bit time of the last slides.

The plot on the left draws this: phase lag against frequency, one line per delay. Read the right
edge, at 10 hertz, ten swings per second. A delay of 5 milliseconds costs 18 degrees. 10
milliseconds cost 36. 20 milliseconds cost 72. And 40 milliseconds cost 144 degrees, four tenths of
a full swing. With that much lag, a controller still pushes when it should already let go.

The first bullet recalls a word from Lecture 1. Every control loop tolerates only a limited extra
phase lag before it starts to swing by itself. That reserve is the phase margin, and every degree of
delay comes out of it.

The second bullet: fast loops suffer most. Remember the ABS controller from Lecture 3. It makes a
decision every 5 milliseconds, and it releases and reapplies the brake several times per second
while the wheel is close to locking. A delay of tens of milliseconds is a large part of one such cycle.
Slow loops hardly notice a delay: the dashboard, the climate control, the cruise control.

The third bullet is a trap to avoid. The delay is not the same as the message period. A value can
change just after a frame left, so it waits almost a whole period for the next one, and then the
receiver picks it up one period later. In our model a message arrives between one and two periods
late, one and a half periods on average. So a message sent every 20 milliseconds is about 30
milliseconds late on average. At 10 hertz that costs 108 degrees, not the 72 you would read for 20
milliseconds in the plot.

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
| unsynchronized ECUs | one grid per run; shifting the pedal press over a period stands in for it |

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

Row four. In a real car, the clocks of the ECUs are not synchronized. Where an event falls between
two frames changes from one stop to the next. In one model run, all periods start on the same time
grid. So we repeat the stop several times and shift the moment the driver presses the pedal across
one period. That gives a spread of results instead of one lucky or unlucky number.

The sentence below the table sums it up. In the model, a change reaches the receiver between one and
two periods later. The model does not show the short bus time under a millisecond. It shows the cost
of the period, which is the part that dominates.

The green box names the two builds. In build 03 you change the period of the chassis messages and
measure the ABS stopping distance. In build 04 you run can_schedule on your car and read its bus
load and response times.
-->

---
routeAlias: where-the-brake-request-lives
---

## Where the brake request lives

<img src="/diagrams/08-brake-layouts.svg" style="max-height: 24rem" alt="Two versions of the same car on one CAN bus. Left, brake request on the bus: the pedal node sends the pedal request onto the bus (1); a blend ECU reads it, decides how much the motor and the discs brake, sends the regen request to the VCU and the friction request to the brake ECU over the bus (2); the brake ECU sends the ABS-active flag back over the bus (3) and drives the calipers. Right, a real EV: the brake pedal is wired to the brake ECU, which blends and runs the ABS and drives the calipers on its own wires; it sends only the regen request, the speed and the ABS status onto the bus, read by the VCU and the cluster; the accelerator is wired to the VCU."/>

<div class="caption">Same estimator, same ABS controller, same bus periods; only where the brake demand
is split differs. <code>PlanarBEVCanBusBrake</code> left, <code>PlanarBEVCanDrive</code> right.</div>

<!--
Before we measure, look at two ways to put the same car on a bus.

On the left, the brake request rides the bus. Follow the numbers. One: the driver's pedal goes onto
the bus. A separate ECU, the blend ECU, reads it and decides how much the motor brakes and how much
the discs brake. Two: it sends the request for the discs over the bus again, to the brake ECU, which
drives the calipers. So the request crosses the bus twice. Each crossing makes it one to two periods late, and it arrives in
steps, one new value per frame. Three: the flag that says the ABS is active has to travel back over
the bus before the motor stops braking.

On the right is how a real electric car does it. The brake pedal pushes brake fluid, and a sensor
on the pedal is wired to the brake ECU. The brake ECU decides the split itself and drives the
calipers directly. Over the bus it sends only one braking message: the regen request, which tells
the motor how hard to brake. The vehicle speed, the wheel speeds and the ABS status also go on the
bus, for the dashboard and anyone else who needs them.

The caption is the important part. Both cars use the same speed estimator, the same ABS controller
and the same bus periods. The only difference is where the brake demand is split. On the next slide
we measure what that difference costs.
-->

---
routeAlias: what-the-bus-costs-the-abs
---

## What the bus costs the ABS

Hard ABS stop from 80 km/h. Mean over six pedal timings, range in brackets.

| Chassis period | 10 ms | 20 ms | 40 ms |
|---|---:|---:|---:|
| ideal bus = point to point | 28.1 m | 28.1 m | 28.1 m |
| real EV layout | 28.9 m (28.6–29.1) | 29.5 m (29.0–30.0) | 30.2 m (30.0–30.4) |
| brake request on the bus | 30.1 m (28.8–30.7) | 29.6 m (29.3–29.9) | 33.6 m (31.8–35.8) |

- Latency costs meters: about 2 m at 40 ms even in the real layout.
- With the brake request on the bus, **where the press falls between frames** decides the stop: up to
  4 m apart on the same car.
- A higher priority would not help: every frame is on the wire within 1.5 ms at 13 % load. The
  **period** is the delay.

**A closed loop stays where its sensors and actuators are. The bus carries coordination.**

<!--
Here are the numbers. Every run is the same hard stop from 80 kilometers per hour with ABS. For each
bus period we repeated the stop six times and moved the moment the driver presses the pedal by up to
40 milliseconds. The table shows the mean distance and, in brackets, the shortest and the longest.

Row one is the reference. With an ideal bus, the car stops in 28.1 meters, exactly like the wired car.

Row two is the real layout. It gets a little longer as the bus gets slower: 28.9, 29.5, 30.2 meters.
About 2 meters at 40 milliseconds. That is the honest price of the bus here: the motor keeps
regenerating a little longer because its regen request arrives late. And the spread is small, half
a metre at most.

Row three puts the brake request on the bus. At 40 milliseconds it needs 33.6 meters on average,
five and a half meters more than the ideal bus. And look at the brackets: the same car stops anywhere
between 31.8 and 35.8 meters, depending only on where the pedal press fell between two frames. If
the first brake squeeze comes in a bad step, the ABS sees the wheel slip too much, lets go of far
more pressure than it needs to, and takes about half a second to build it up again. Notice also that
20 milliseconds came out better than 10 here. That is luck, not physics: inside the spread, one
stop can beat another.

The first bullet: latency costs meters, about 2 at 40 milliseconds even in the good layout.

The second bullet: when a control loop runs over the bus, timing luck shows up in the result.

The third bullet answers a natural question: why not give the brake message the highest priority?
Because priority only decides who waits in the queue, and on this bus every frame is on the wire
within one and a half milliseconds at 13 percent load. The delay comes from the period, ten to forty
milliseconds, and priority does not change the period.

The caption is the rule to take home. A closed loop stays where its sensors and actuators are. The
ABS reads the wheel sensors and drives the valves on its own wires. The bus carries coordination:
speeds, requests, status.
-->
