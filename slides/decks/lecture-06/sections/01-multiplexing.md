---
routeAlias: multiplexing
layout: section
---

###### Section 01

# Multiplexing

One wire per signal, or one shared medium for all of them: three ways to share it, the meeting room that explains CAN's way, and what it saves.

<!--
Section 01: multiplexing. Multiplexing means sending many signals over one shared medium. We see
the three ways to share a medium, then the picture we use all lecture long to explain CAN's way, a
meeting room with strict speaking rules, and finally what it saves in a car.
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
There are three ways to share one medium. By frequency: every sender gets its own band, as FM radio
stations do. By code: everyone sends at once on the same band, each with its own code, as GPS
satellites do. And by time: one sender at a time gets the whole medium.

Every network between the ECUs of a car shares by time. The question is who decides whose turn it
is. In some networks a master hands out turns. CAN has no master. An ECU that wants to talk waits
until the bus is quiet and starts. If two start at the same moment, a rule decides who carries on,
and the winner's message is not damaged at all. We see that rule in section 05.

Network people call this carrier sense, multiple access, collision resolution: listen before
talking, anyone may talk, and a clash is resolved instead of destroying both messages. Ethernet,
the office network, detects a collision and both senders start again. CAN resolves it.

The source deck explained this with a railway and a television. Both break down on CAN's most
important rules, so we use one picture instead, for the rest of the lecture: a meeting room with
strict speaking rules.
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
Here is frequency sharing, run as a Dyad model. Two slow signals, standing for vehicle speed and
engine speed, each ride on their own carrier: one at 100 hertz, one at 300. The two modulated
carriers simply add on one wire.

The top plot is that wire over a tenth of a second: it looks like a mess. The middle plot is its
spectrum, and there the mess sorts itself out: two narrow lines, one at 100 hertz and one at 300.
Each sender owns its band.

To get a signal back, the receiver multiplies the wire by its own carrier and filters out
everything fast. The bottom plot shows both signals as sent, dashed, and as recovered, solid. They
match, about 22 milliseconds late, which is the filter. This is how radio stations share the air.
No car network works this way: it needs an oscillator and a filter per channel.
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
Time sharing. A switch gives the wire to each sender in turn: 50 milliseconds for vehicle speed,
50 for engine speed, again and again. The top plot is the wire, colored by whose slot it is.

The receiver has a switch on the same clock. It samples the wire in the middle of its own slot and
holds the value until the next one. The middle plot: each signal comes back as a staircase that
follows the original. Each value is late and refreshed only once per frame: late, rounded in time,
periodic, the price from the previous slide.

The bottom plot is the warning. The same receiver with its clock 2.5 percent fast. Its sampling
instants slide, and after a second it reads the other sender's slot: the two signals come out mixed,
then swapped. Time sharing works only if everyone agrees on the time. That is exactly why every CAN
node resynchronizes on every edge, in section 04.
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
Code sharing. Both senders talk at the same time, on the same wire. Each multiplies its bits by its
own code, a fast pattern of plus and minus ones, four chips per bit. The codes are chosen to be
orthogonal: multiply two different codes chip by chip and average, and you get zero.

The wire carries the sum, which takes only the values minus two, zero and plus two and looks like
noise. The receiver multiplies the wire by its own code and averages over one bit. Its own bits come
back at plus or minus one; the other sender's contribution averages to zero. The last trace is a
receiver using a third code that nobody sent: it reads almost nothing.

That is how GPS satellites all send on the same frequency. And it shows the contrast with CAN: here
everyone talks at once and the math separates them; on CAN only one talks at a time, and the rules
decide who.
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
Here is the room. Everyone sits in one room and hears every word, as every ECU on a CAN bus
receives every frame. A frame is CAN's word for one message on the wire.

The second line is the most important one. A speaker never says "to the brakes: the speed is 87".
They announce a topic: "Vehicle speed: 87". On CAN, the number at the front of a frame, its
identifier, names what the frame contains, not who it is for. Each listener decides for themselves
whether the topic concerns them. The ABS keeps vehicle speed; the radio ignores it.

You only start talking when the room is quiet. If two people start at the same moment, the one
with the lower topic number goes on, and the other stops and waits for the next quiet moment.
Nobody's sentence is lost. Next slide shows how.

When a sentence ends, any one listener nods, to say "somebody heard you". Not the one it was meant
for; there is no such person. If anyone heard the sentence garbled, they shout "STOP!", everyone
throws the sentence away, and the speaker says it again.

And some people report on a fixed beat: the speed every 10 milliseconds, the dashboard every 100.
That beat is where the price of the bus comes from.
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
Here is the rule for two speakers who start together. Everyone claps their topic number in
binary, one beat per bit, highest bit first. A zero is a clap, a one is silence. A clap drowns out
silence, so if anyone claps, the whole room hears a clap.

Each speaker listens while clapping. If you stayed silent for a one, and you hear a clap, someone
else has a zero where you have a one. Their number is lower. You stop at once.

Follow the picture. Three speakers start with topics 711, 2A0 and 265, in hexadecimal. At bit 10,
711 has a one and stays silent, but the others clap. 711 hears the clap and drops out. Bits 9 and 8
are the same for the remaining two. At bit 7, 2A0 has a one, stays silent, hears 265 clap, and
drops out. 265 carries on alone and finishes its sentence.

Three things follow. The lowest number always wins. The winner's sentence is not damaged at all:
the room heard exactly the winner's number, so no time is lost. And the topic number is a
priority, so a car maker gives the brake messages low numbers and the comfort messages high ones.

On the wire, a zero is called dominant and a one recessive. You will see those words again in
section 04.
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
Errors. In the room, anyone who hears a garbled sentence shouts "STOP!". That is CAN's error flag.
Now the surprising part: everyone throws the sentence away, even the people who heard it fine. In a
real meeting they would keep it. On CAN they do not, and for a good reason: every ECU must hold the
same data. If the ABS kept a speed value that the motor controller threw away, the two would
disagree. So a frame is all or nothing, and the sender simply sends it again.

The right column is what stops one broken ECU from ruining the meeting. Whoever keeps causing
stops collects strikes, and a good sentence wipes some of them off. With few strikes you speak and
object normally: error active. With many, you may only whisper your objections, so you cannot
destroy other people's sentences any more: error passive. With too many, you leave the room: bus
off. A broken ECU takes itself off the bus instead of jamming it for everyone. Section 07 gives the
real counters and thresholds.
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
Every analogy breaks somewhere, and it is better to say where. Two places.

First, people do not clap in sync. CAN nodes do. Every node samples each bit at the same instant,
because every node readjusts its clock on every change of level on the wire. So arbitration is
not a matter of who claps louder; it is decided exactly, bit by bit, within one bit time. We see
how in section 04.

Second, a room has no wires. Nothing in the room corresponds to the two signal lines, CAN high and
CAN low, to their voltage levels, or to the 120-ohm resistors at the two ends of the bus. For that
we leave the room and look at the electrical picture, also in section 04.

And one trap. Some explanations say the topic number is like introducing yourself. It is not. The
identifier names the content, not the sender. That is also why two ECUs must never send the same
identifier: if they did, both would win arbitration together and then clash in the data.
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
Imagine a car where every ECU that needs a signal gets its own wire from the ECU that has it. With
five ECUs that all talk to each other, that is ten links. With ten it is forty-five. The number
grows with the square: n times n minus one, over two. A current car has somewhere around seventy
ECUs. Not all of them talk to all others, but the table shows where point-to-point wiring goes.
And a link is rarely one wire: a signal often needs a pair, and every wire ends in two connector
pins, which are the parts that corrode and fail.

The bus turns this around. Every ECU hangs off one twisted pair, two wires twisted together so
that electrical noise hits both the same way. A new ECU adds one short stub. A new signal adds no
wire at all; it is one more message on the same pair.

The right column also says the price, and it is the theme of today. On a bus the ECUs take turns.
A signal has to wait for its message. It is rounded to the resolution the message gives it. And
the receiver sees a new value only as often as the sender sends the message. Keep those three
things in mind: late, rounded, periodic.
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
Here is the same idea on our own car. On the left, the point-to-point car you know from Lectures 3
and 4. The vehicle speed, the steering angle, the yaw rate, the brake demand, the flag that says
the ABS is acting and the torque request to the motor each run on their own wire between the ECUs.

On the right, the same car on a bus. Every ECU publishes its messages on one bus connection, and
every ECU reads from it what it needs. The model has one switch, called ideal. With ideal on, the
bus delivers every value at once and exactly, so the bused car must drive exactly like the wired
one. With ideal off, the bus behaves like a real one: late, rounded, periodic.

In the first build you move the signals onto the bus yourself and count the wires before and
after.
-->
