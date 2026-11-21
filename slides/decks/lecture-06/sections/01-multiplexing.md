---
routeAlias: multiplexing
layout: section
---

###### Section 01

# Multiplexing

One wire per signal, or one shared medium for all of them: three ways to share it, the meeting room that explains CAN's way, and what it saves.

<!--
We start with the basic idea. Multiplexing means sending many signals over one shared medium. The
medium is whatever carries the signals: a wire, or the air. This section shows three ways to share a
medium, then the meeting room that explains CAN's way, and finally what sharing saves in a car.
-->

---
routeAlias: three-ways-to-share
---

## Three ways to share one medium

| Sharing by | Each sender gets | Example | In a car |
|---|---|---|---|
| **Frequency** | its own frequency band | FM radio | the radio, not the ECU network |
| **Code** | its own spreading code | GPS, 3G phones | navigation |
| **Time** | the whole medium, one at a time | CAN, LIN, FlexRay, Ethernet | **every ECU network** |

CAN shares by time **with no master**: whoever wants to talk waits for the bus to be quiet and
starts; if two start together, a rule settles who goes on without losing the message
(section 05).

<div class="caption text-left">The network name: carrier sense, multiple access, collision
resolution (CSMA/CR) — listen first, anyone may talk, clashes are resolved, not destroyed</div>

<!--
The table shows three ways to share one medium.

First row, by frequency. Every sender gets its own frequency band, the way each FM radio station has
its own place on the dial. Second row, by code. All senders send at once, and each marks its signal
with its own code. GPS satellites do this. Third row, by time. One sender at a time gets the whole
medium. Look at the last column: every network between the ECUs of a car shares by time.

Sharing by time raises one question: who decides whose turn it is? In some networks one device, the
master, hands out the turns. CAN has no master. An ECU that wants to send waits until the bus is
quiet, and then starts. If two start at the same moment, a rule decides which one goes on, and its
message is not damaged. Section 05 shows that rule on the wire.

The caption gives the engineering name: carrier sense, multiple access, collision resolution. In
plain words: listen first, anyone may send, and a clash is resolved without losing the message.

On the next three slides, each kind of sharing runs as a small model.
-->

---
routeAlias: frequency-division
layout: default
class: big-figure
---

## Frequency: each sender its own band

<img src="/figures/01-fdm.svg" alt="Frequency-division bench. Top: the shared wire over 100 ms, the sum of a 100 Hz and a 300 Hz carrier whose amplitudes follow two slow signals. Middle: the wire's spectrum, two narrow lines at 100 Hz and 300 Hz. Bottom: vehicle speed and engine speed as sent, dashed, and as recovered by multiplying with each carrier and low-pass filtering, solid, about 22 ms late."/>

<div class="caption"><code>dyad/Lecture6/FrequencyDivisionBench</code> · carriers 100 and 300 Hz · receiver: multiply by its
own carrier, 10 Hz low-pass filter</div>

<!--
This is sharing by frequency. Two slow signals stand for vehicle speed and engine speed. Each one
rides on its own carrier. A carrier is a steady, fast wave, and the signal sets how strong that wave
is. One carrier swings 100 times per second, which is 100 hertz. The other is at 300 hertz. Both
waves are simply added on one wire.

The top plot shows that wire for a tenth of a second. It looks like a mess. The middle plot sorts
the same wire by frequency. Now you see two narrow lines, one at 100 hertz and one at 300. Each
sender owns its own line.

To get one signal back, the receiver multiplies the wire by its own carrier and smooths away
everything fast. That smoothing is called a low-pass filter. The bottom plot shows both signals as
sent, dashed, and as recovered, solid. They match, but the recovered ones are about 22 milliseconds
late. The filter causes that delay.

Radio stations share the air this way. Car networks do not, because every signal would need its own
wave generator and its own filter.
-->

---
routeAlias: time-division
layout: default
class: big-figure
---

## Time: each sender its own slot

<img src="/figures/01-tdm.svg" alt="Time-division bench. Top: the shared wire over one second, alternating 50 ms slots colored by sender. Middle: each receiver samples in the middle of its own slot and rebuilds its signal as a staircase that follows the original. Bottom: the same receiver with its clock 2.5 percent fast: its samples drift into the other sender's slot, and the two signals come out mixed and then swapped."/>

<div class="caption"><code>dyad/Lecture6/TimeDivisionBench</code> · two 50 ms slots per 100 ms frame · bottom: receiver
clock 2.5 % fast</div>

<!--
This is sharing by time. A switch gives the wire to each sender in turn: 50 milliseconds for vehicle
speed, then 50 for engine speed, again and again. Each turn is called a slot. The top plot shows the
wire, colored by whose slot it is.

The receiver has a switch that runs on the same clock. It reads the wire in the middle of its own
slot and holds that value until its next slot. The middle plot shows the result. Each signal comes
back as a staircase that follows the dashed original. So each value arrives late, and it is
refreshed only once per round. That is the price from the title slide.

The bottom plot is a warning. It is the same receiver, but its clock runs 2.5 percent fast. Its
reading moments slide out of its own slot and into the other sender's slot. The two signals come out
mixed, and then swapped.

So sharing by time works only if everyone agrees on the time. CAN solves this: every ECU keeps
correcting its clock while it listens. Section 04 shows how.
-->

---
routeAlias: code-division
layout: default
class: big-figure
---

## Code: each sender its own key

<img src="/figures/01-cdm.svg" alt="Code-division bench over eight bit periods. Two senders each multiply their bits by their own four-chip code; the codes are orthogonal. The summed wire takes only the values minus 2, 0 and plus 2 and looks like noise. Each receiver multiplies the wire by its own code and averages over one bit: A and B recover their bits at plus or minus one; a receiver using a third code that nobody sent reads almost zero."/>

<div class="caption"><code>dyad/Lecture6/CodeDivisionBench</code> · orthogonal 4-chip codes A = + − + −, B = + + − −; a
receiver on C = + − − + reads ≈ 0</div>

<!--
This is sharing by code. First one word. A bit is the smallest piece of data: a one or a zero. Here
a one is sent as plus one and a zero as minus one.

Both senders send at the same time on the same wire. Each sender multiplies every bit by its own
code. A code is a fast pattern of four plus and minus ones. Each step of the pattern is called a
chip. The caption shows the codes: A is plus, minus, plus, minus. B is plus, plus, minus, minus.
They are chosen so that they cancel each other: multiply A by B step by step, add up the results,
and you get zero. Codes like that are called orthogonal.

The wire carries the sum of both senders. It takes only the values minus two, zero and plus two, and
it looks like noise. Each receiver multiplies the wire by its own code and averages over one bit.
Its own bits come back as plus one or minus one. The other sender's part averages to zero. The last
trace is a receiver that uses a third code, C, which nobody sent. It reads almost zero.

GPS satellites share one frequency this way. CAN is the opposite. Here everyone sends at once, and
arithmetic separates them. On CAN only one ECU sends at a time, and rules decide which one. The next
slide gives those rules as a picture.
-->

---
routeAlias: rules-of-the-room
---

## A meeting with strict speaking rules

<div class="grid grid-cols-[1fr_1fr] gap-6 items-center">
<div>

<img src="/diagrams/01-meeting-room.svg" alt="A meeting table seen from above. A speaker at one end says &quot;Vehicle speed: 87&quot;, a topic and not a name. Around the table the ABS, the dashboard and the motor each keep the topic, marked with a check; the radio and the seats ignore it. The dashboard nods: heard it."/>

</div>
<div>

| In the room | On CAN |
|---|---|
| everyone hears every word | every ECU receives every frame |
| a speaker announces a **topic**, never a name | the **identifier** names the content, not a receiver |
| each listener keeps what concerns them | each ECU **filters** by identifier |
| speak only when the room is quiet | send only when the bus is idle |
| two start together: the **lower topic number** goes on | **arbitration**: the lower identifier wins |
| any one listener **nods** | any receiver sends the **acknowledgement** |
| garbled: anyone shouts **"STOP!"**, the speaker repeats | **error frame**, then retransmission |
| some report on a fixed beat | **periodic** messages |

</div>
</div>

<!--
This is the picture for the rest of the lecture: a meeting with strict speaking rules. The people at
the table are the ECUs. The table on the right pairs each rule in the room with its name on CAN.

Everyone hears every word. On CAN, every ECU receives every frame. A frame is one complete message
on the bus.

The second row is the most important one. Look at the speech bubble: "Vehicle speed: 87". The
speaker names a topic, never a person. On CAN, every frame starts with a number, the identifier, ID
for short. The identifier says what the frame contains. It does not say who the frame is for.

Third row. Each listener keeps only what concerns them. In the picture, the ABS, the dashboard and
the motor keep the speed. The radio and the seats ignore it. On CAN this is called filtering.

You speak only when the room is quiet. If two people start together, the one with the lower topic
number goes on, and the other waits. On CAN this contest is called arbitration. The next slide shows
how it works.

When a sentence ends, any one listener nods. The nod says "somebody heard you". On CAN it is the
acknowledgement, ACK for short.

If a listener hears a garbled sentence, they shout "STOP!", and the speaker repeats it. On CAN the
shout is called an error frame.

Last row. Some people report on a fixed beat, for example the speed every 10 milliseconds. Those are
periodic messages, and that beat is where the price of the bus comes from.
-->

---
routeAlias: clapping-the-topic
---

## Two start together: clap the topic number

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

Speakers clap their topic number in binary, highest bit first: **clap = 0**, **silence = 1**.
Whoever stayed silent and heard a clap stops.

<img src="/diagrams/01-clapping.svg" alt="Three speakers clap identifiers 711h, 2A0h and 265h beat by beat, bits 10 to 6. A clap, drawn as a star, is 0; silence, an empty circle, is 1. At bit 10, 711h is silent while the others clap: it stops. At bit 7, 2A0h is silent while 265h claps: it stops. 265h goes on and wins. The bottom row, what the room hears, is exactly 265h's beats: 0, 1, 0, 0, 1."/>

</div>
<div>

- The **lowest number wins**, because its first 0 comes earliest.
- The winner's sentence is **not damaged**: the room heard exactly its number.
- The losers retry as soon as the room is quiet again.
- So the topic number is also a **priority**: brake messages get low numbers.

</div>
</div>

<div class="caption text-left">The identifiers are the source deck's worked example ·
h: hexadecimal · 0 is called dominant, 1 recessive</div>

<!--
What happens when two speakers start together? The room has a rule. Each speaker claps out their
topic number in binary. Binary means the number is written with only ones and zeros, the bits. There
is one beat per bit, and the highest bit comes first. For a zero you clap. For a one you stay
silent. A clap drowns out silence, so if anyone claps, the whole room hears a clap.

Every speaker listens while clapping. If you stay silent and still hear a clap, somebody else has a
zero where you have a one. Their number is lower. You stop at once.

Follow the picture. Three speakers start with the topics 711, 2A0 and 265. These numbers are written
in hexadecimal, a short way to write binary numbers. The small h marks it. A star is a clap, and an
empty circle is silence. At bit 10, the first beat, 711 is silent, but the other two clap. 711
stops. At bits 9 and 8 the two remaining speakers do the same thing. At bit 7, 2A0 is silent and 265
claps. 2A0 stops. 265 goes on alone. The bottom row is what the room hears: exactly the beats of
265.

The bullets say what follows. The lowest number wins. The winner's sentence is not damaged, so no
time is lost. The losers try again when the room is quiet. And the topic number is also a priority:
brake messages get low numbers.

The caption gives two words you will hear all day. On CAN a zero is called dominant, because it
wins. A one is called recessive, because it gives way.
-->

---
routeAlias: strikes
---

## Shouting "STOP!", and the troublemaker

<div class="grid grid-cols-2 gap-8">
<div>

### Every sentence is all or nothing

Anyone who hears a garbled sentence shouts **"STOP!"**. **Everyone** throws the sentence away,
even those who heard it fine, and the speaker repeats it.

So every listener always holds **the same** information.

</div>
<div>

### Strikes

Whoever keeps causing stops collects **strikes**; a good sentence wipes some off.

1. Few strikes: speaks and shouts normally — **error active**
2. Many strikes: may only **whisper** objections — **error passive**
3. Too many: **leaves the room** — **bus off**

A broken ECU silences itself instead of jamming the bus.

</div>
</div>

<!--
Now the errors. On the left: anyone who hears a garbled sentence shouts "STOP!". Then everyone
throws the sentence away, even the people who heard it correctly, and the speaker repeats it.

In a real meeting, those who heard it correctly would keep it. CAN does not allow that, for a good
reason. All ECUs must work with the same data. If the ABS kept a speed value and the motor
controller threw it away, the two would disagree. So a frame is accepted by everyone or by no one.

On the right is the rule that protects the meeting from one broken member. Whoever keeps causing
stops collects strikes. A good sentence removes some strikes again. There are three stages, and the
slide gives their CAN names. With few strikes you speak and shout as normal: error active. With many
strikes you may only whisper your objections, so you can no longer interrupt others: error passive.
With too many strikes you leave the room: bus off.

So a broken ECU silences itself and does not block the bus for the others. Section 07 gives the
exact counting rules.
-->

---
routeAlias: where-the-room-stops
---

## Where the room stops working

<div class="grid grid-cols-2 gap-8">
<div>

### People do not clap in sync

CAN nodes do: every node samples the same bit at the same instant, because they all resynchronize
on every edge. Arbitration is exact and decided within one bit time, every time.

→ section 04, bit timing

</div>
<div>

### A room has no wires

Nothing in the room matches CAN_H and CAN_L, the voltage levels or the 120 Ω terminations at the
ends of the bus.

→ section 04, physical layer

</div>
</div>

> **One trap.** The topic number names **what** is said, not **who** says it. Two ECUs may never
> send the same identifier.

<!--
Every comparison stops working somewhere. The meeting room stops in two places.

On the left: people cannot clap exactly in time with each other. ECUs can. Every ECU reads each bit
at the same moment, because each one keeps correcting its clock while it listens. So the contest
between two senders is decided exactly, bit by bit. Section 04 shows how the clocks stay together.

On the right: a room has no wires. Nothing in the room matches the two wires of the bus, which are
called CAN high and CAN low. Nothing matches the voltages on them. A voltage is the electrical level
of a wire, measured in volts. And nothing matches the two 120-ohm resistors at the ends of the bus,
which are called terminations. Section 04 explains all three.

The box at the bottom warns about one trap. The topic number says what is said, not who says it.
Each identifier belongs to one kind of content, and only one ECU sends it. If two ECUs sent the same
identifier, both would win the clapping contest together, and their sentences would then collide.

Those are the rules. Now back to the car: what does a bus save?
-->

---
routeAlias: wires-grow
---

## Wiring every ECU to every other

<div class="diagram-wide">

<img src="/diagrams/01-mesh-vs-bus.svg" alt="Left: six ECUs wired point to point, every one to every other, fifteen links crossing each other. Right: the same six ECUs on one twisted pair, each on its own short stub."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

### Point to point

*n* ECUs that all talk to each other need *n*(*n*−1)/2 links:

| ECUs | 5 | 10 | 30 | 70 |
|---|---:|---:|---:|---:|
| links | 10 | 45 | 435 | 2415 |

and each link is often several wires, each with two connector pins.

</div>
<div>

### One bus

Adding an ECU adds one stub; adding a signal adds no wire at all, only one more message.

The price: the ECUs **take turns**. A signal waits for its message, is rounded to the message's
resolution and is refreshed only as often as the message is sent.

</div>
</div>

<div class="caption text-left">ECU: electronic control unit, a small computer running one car
function · twisted pair: two wires twisted together, so interference hits both alike</div>

<!--
The picture on the left shows six ECUs wired point to point: every ECU has a link to every other
one. That takes fifteen links. The table below shows how fast this grows. Five ECUs need 10 links.
Ten need 45. Thirty need 435, and seventy need 2415. A current car has around seventy ECUs. Not
every ECU talks to every other one, but the table shows where this kind of wiring leads. And one
link is often several wires, each with two connector pins.

The picture on the right shows the same six ECUs on one bus. The bus is a twisted pair: two wires
twisted around each other. An electrical disturbance from outside then hits both wires in the same
way. Section 04 shows why that helps. Each ECU connects through a stub, a short side branch. A new
ECU adds one stub. A new signal adds no wire at all, only one more message.

The right column names the price, and it is the theme of today. On a bus the ECUs take turns. So a
signal waits for its message. It is rounded to the step size of the message. And the receiver gets a
new value only as often as the message is sent. Remember these three words: late, rounded, periodic.
-->

---
routeAlias: our-car-wired
---

## Our car, wired and bused

<div class="grid grid-cols-2 gap-8">
<div>

### Point to point: `PlanarBEVDrive`

The car from Lectures 3 and 4. Speed, steering angle, yaw rate, brake demand, the ABS flag and the
motor request each run on their own wire between the ECUs.

</div>
<div>

### On the bus: `PlanarBEVCanDrive`

The same car. Every ECU publishes its messages on one bus connection, and every ECU reads what it
needs from it. One switch, `ideal`, makes the bus perfect, so the two cars can be compared run for
run.

</div>
</div>

<div class="handson">In build 01 you move the car's signals onto the bus yourself and count the
wires before and after.</div>

<!--
Now the same idea on our own car. On the left is the car you know from Lectures 3 and 4, wired point
to point. Six signals each run on their own wire between the ECUs: the vehicle speed, the steering
angle, the yaw rate, the brake demand, the flag that says the ABS is active, and the torque request
to the motor.

On the right is the same car on a bus. Every ECU puts its messages on one bus connection, and every
ECU reads what it needs from that connection.

The bused model has one switch, called ideal. With ideal switched on, the bus is perfect: every
value arrives at once and exactly. Then the bused car must drive exactly like the wired car. With
ideal switched off, the bus behaves like a real one: late, rounded, periodic. So you can compare the
two cars run for run.

The green box announces the first build. You move the car's signals onto the bus yourself, and you
count the wires before and after.

Before we build, we need a map of the jobs a network has to do. That is the next section.
-->
