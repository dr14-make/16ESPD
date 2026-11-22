---
routeAlias: wrap-up
layout: section
---

###### Section 10

# Wrap-up

A real Škoda Fabia cluster on the simulated bus; what you measured and what the model leaves out.

<!--
Section 10, the wrap-up. First the simulated car drives a real instrument cluster. Then we sum up
what you measured today, what the model leaves out, and what to take home.
-->

---
routeAlias: fabia-demo
---

## A real cluster on the simulated bus

<div class="grid grid-cols-2 gap-8">
<div>

### The chain

1. Dyad simulates `PlanarBEVFabiaScriptedDrive` in real time
2. a stream encodes the cluster's frames: 1A0h speed, 280h engine speed, lamps, indicators
3. SocketCAN sends them through a USB-to-CAN adapter (`can0`) at 500 kbit/s
4. the Fabia cluster reads them as if it sat in the car

`candump can0` listens on the same bus.

</div>
<div>

### What to watch

| Time | Car | Cluster |
|---|---|---|
| 0–9 s | full throttle | speed and tachometer rise |
| 12–18 s | left indicator | arrow blinks |
| 14–17 s | lane change | — |
| from 24 s | full brake, ABS | ESP/ASR lamp flashes; hazards at a hard stop |

</div>
</div>

<div class="caption">The cluster has no idea the car is simulated: it gets the frames, periods,
counters and checksums it expects.</div>

<!--
Now the demo. The list on the left is the chain from the model to the real hardware.

One: Dyad simulates a car on a scripted drive, in real time, so one second of simulation takes one
second on the clock.

Two: a small program turns the simulated values into the frames this cluster expects. 1A0h carries
the vehicle speed, the same frame as in section 06. 280h carries the engine speed for the
tachometer. Other frames carry the lamps and the indicators.

Three: Linux sends these frames through its CAN interface, called SocketCAN, to a USB-to-CAN adapter.
The bus runs at 500 kilobits per second, like the real car's.

Four: the instrument cluster from a Škoda Fabia reads the frames as if it sat in the car.

Below the list: a program called candump listens on the same bus and prints every frame it sees.

The table on the right says what to watch. From 0 to 9 seconds the car accelerates at full
throttle: the speedometer and the tachometer rise. Our car is electric and has no engine, so the
tachometer shows half the motor speed. From 12 to 18 seconds the left indicator is on, and the arrow
on the cluster blinks. Between 14 and 17 seconds the car changes lane. From 24 seconds the driver
brakes as hard as possible, and the ABS works. The ESP lamp flashes while the brake system
intervenes, as in a real car. When the car decelerates very hard, the hazard lights come on by
themselves.

The caption is the point of the demo. The cluster cannot tell that the car is simulated. It
receives the frames, the periods, the counters and the checksums that it expects, so it works.
-->

---
routeAlias: reading-candump
---

## Reading candump

<div class="text-3xl font-mono my-6 whitespace-pre">can0  1A0   [8]  00 00 <b>10 27</b> FE FE 00 03</div>

| Field | Bits | Raw | Value |
|---|---|---|---|
| vehicle speed | 17–31, Intel | bytes 2–3 = 2710h, drop bit 16 → 1388h = 5000 | × 0.01 km/h = **50.00 km/h** |
| ABS, ASR, brake lamps | 8–10 | byte 1 = 00h | all off |
| counter | 56–59 | byte 7 = 03h | 3, then 4, 5, … 15, 0 |

<div class="caption">The DBC line from section 06: <code>SG_ Geschwindigkeit : 17|15@1+ (0.01,0)</code>.</div>

<!--
This is one line of candump output. Read it from the left. can0 is the interface. 1A0 is the
identifier, in hexadecimal: Bremse_1, from the brake ECU. The 8 in brackets is the number of data
bytes. Then come the eight bytes, byte 0 first.

The table decodes the line with the DBC line from section 06, shown in the caption. The vehicle speed
starts at bit 17 and is 15 bits long, in Intel byte order. Bytes 2 and 3 together, low byte first,
read 2710 hexadecimal. Bit 16 belongs to the byte but not to the signal, so we drop it: shift right
by one, which gives 1388 hexadecimal, or 5000. Times the factor 0.01 km/h gives 50.00 km/h.

The second row: bits 8 to 10 are the ABS, ASR and brake lamps. Byte 1 is zero, so all three are off.
During the hard stop, the ASR bit flips on and off and the lamp flashes.

The third row is the counter from section 06. It counts from 0 to 15 and wraps around, one step per
frame. If the cluster sees the counter jump or stand still, it knows that frames are missing or that
a sender has hung, and it warns.
-->

---
routeAlias: what-you-measured
---

## What you measured

| Build | Result |
|---|---|
| 01 put the car on the bus | ideal bus = point to point, **28.2 m**; signal wires 22 → 19 nets in the starter |
| 01 one message by hand | regen request: ID 110h, 10 ms, 0.1 N·m per bit; same stop |
| 02 a bus wired wrongly | `check_can` names the two transmitters on one slot |
| 03 period against stopping distance | real layout 28.9 / 29.5 / 30.2 m at 10 / 20 / 40 ms; brake request on the bus up to 33.6 m |
| 04 bus load | **13.5 %** at 500 kbit/s, 26.9 % at 250; every frame on the wire within 1.5 ms |

<div class="caption">A bus trades wires for time. The time is in the periods, not on the wire.</div>

<!--
Here is what you measured in the four builds.

Build 01: you moved the car's signals onto the bus. With an ideal bus, the car stops in 28.2 meters,
exactly like the wired car. The starter's top level went from 22 signal connections to 19, and in a
real car the saving is far larger, because every extra ECU adds wires to each partner but only one
bus connection. Then you built one message by hand: the regen request, identifier 110 hexadecimal,
sent every 10 milliseconds, with 0.1 newton-meters per bit. The car stopped as before.

Build 02: you ran check_can on a bus with two transmitters on one slot, and it named the mistake.

Build 03: you swept the period. In the real layout the stop grows from 28.9 to 30.2 meters as the
period grows from 10 to 40 milliseconds. With the brake request on the bus it reaches 33.6 meters on
average, with a wide spread.

Build 04: the bus is 13.5 percent full at 500 kilobits per second, twice that at 250, and every
frame is on the wire within one and a half milliseconds.

The caption is the sentence of the day. A bus trades wires for time, and the time sits in the
periods, not in the fraction of a millisecond a frame spends on the wire.
-->

---
routeAlias: what-the-model-leaves-out
---

## What the model leaves out

| Real bus | In our model |
|---|---|
| arbitration, bit stuffing, queuing | calculated by `can_schedule`, not simulated |
| error frames, error counters, bus-off | theory only (section 07) |
| unsynchronized ECU clocks | one grid per run; the pedal-timing sweep stands in |
| several buses joined by gateways | one bus |
| message authentication | none; CAN has none either without SecOC |
| motor torque reported back to the brake ECU | not modeled |

<div class="caption">The model shows the cost of the period, the part that dominates. Everything
else needs a protocol-level simulator or a real bus.</div>

<!--
Every model leaves things out. Here is what ours leaves out, so you know what your numbers mean.

Row one: arbitration, bit stuffing and queuing are not simulated. The function can_schedule
calculates their worst case instead.

Row two: error frames, error counters and bus-off exist only in the theory of section 07. In the
model, every frame arrives.

Row three: in a real car, every ECU has its own clock. In one model run, all periods start on the
same grid. The sweep over pedal timings in build 03 stands in for that.

Row four: a real car has several buses joined by gateways. Our model has one.

Row five: our messages carry no proof of who sent them. Neither does plain CAN. Carmakers add it on
top, with a scheme called SecOC.

Row six: in a real car, the motor reports back how much it actually brakes, and the brake ECU makes
up the difference with the discs. Our model leaves that loop out.

The caption sums up. The model shows the cost of the period, the part that dominates. For the rest
you need a simulator of the protocol itself, or a real bus like the one in the demo.
-->

---
routeAlias: take-home
---

## Take home

<div class="text-2xl leading-relaxed">

1. A bus trades **wires for time**: every signal on it arrives late, rounded and on a schedule.
2. The **identifier** is the priority; the lowest wins arbitration without losing a bit.
3. A signal is **bits plus a scale**: start bit, length, byte order, factor, offset.
4. The delay is the **period**, one to two periods per hop; priority only orders the queue.
5. A closed loop stays **where its sensors and actuators are**; the bus carries coordination.
6. A workshop reads the same bus through **OBD-II and UDS**.

</div>

<!--
Six sentences to take home.

One: a bus trades wires for time. Every signal on it arrives late, rounded, and on a schedule.

Two: the identifier of a message is its priority. The lowest identifier wins arbitration, and the
winner's frame is not damaged or delayed by the contest; the others wait for the next gap.

Three: a signal is bits plus a scale. You need its start bit, its length, its byte order, its factor
and its offset to read it, as we did with candump.

Four: the delay comes from the period, one to two periods for every hop over the bus. Priority only
decides the order in the queue.

Five: a closed loop stays where its sensors and actuators are. The ABS reads its wheel sensors and
drives its valves on its own wires. The bus carries coordination.

Six: the workshop reads the same bus, through OBD-II and UDS.

That is the lecture. Thank you.
-->
