---
routeAlias: why-multiplexing
layout: section
---

###### Section 01

# Why multiplexing

One wire per signal, or one shared pair of wires for all of them.

<!--
Section 01: why multiplexing. Multiplexing means sending many signals over one shared medium. We
start with the problem it solves: a car whose ECUs are wired to each other signal by signal.
-->

---
routeAlias: wires-grow
---

## Wiring every ECU to every other

<div class="grid grid-cols-2 gap-8">
<div>

### Point to point

Every signal has its own wire. If each of *n* ECUs talks to every other, that takes

$$\frac{n(n-1)}{2}\ \text{links}$$

| ECUs | 5 | 10 | 30 | 70 |
|---|---:|---:|---:|---:|
| links | 10 | 45 | 435 | 2415 |

and each link is often several wires, each with two connector pins.

</div>
<div>

### One bus

Every ECU hangs off **one twisted pair**. Adding an ECU adds one stub, and adding a signal adds no
wire at all: it is one more message.

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
(section 06).

<div class="caption text-left">The network name: carrier sense, multiple access, collision
resolution (CSMA/CR) — listen first, anyone may talk, clashes are resolved, not destroyed</div>

<!--
There are three ways to share one medium. By frequency: every sender gets its own band, as FM radio
stations do. By code: everyone sends at once on the same band, each with its own code, as GPS
satellites do. And by time: one sender at a time gets the whole medium.

Every network between the ECUs of a car shares by time. The question is who decides whose turn it
is. In some networks a master hands out turns. CAN has no master. An ECU that wants to talk waits
until the bus is quiet and starts. If two start at the same moment, a rule decides who carries on,
and the winner's message is not damaged at all. We see that rule in section 06.

Network people call this carrier sense, multiple access, collision resolution: listen before
talking, anyone may talk, and a clash is resolved instead of destroying both messages. Ethernet,
the office network, detects a collision and both senders start again. CAN resolves it.
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
