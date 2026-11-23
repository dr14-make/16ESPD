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

---
routeAlias: fabia-sim
---

## Demo: the simulated car drives the cluster

<div class="grid grid-cols-[0.85fr_1.15fr] gap-8 items-start text-sm">
<div>

### Bring up the bus, then start the car

```sh
sudo ip link set can0 type can bitrate 500000
sudo ip link set can0 up
candump can0          # cluster talks: 320h 420h 520h

mise run fabia        # scripted 36 s drive
mise run fabia:hand   # drive it yourself in a window
```

The model runs in real time; at each period the Fabia encoder turns the car's signals into the
frames a real Fabia II sends to its cluster. Add `vcan0` to stream to a virtual bus instead.

</div>
<div>

### What we send, and why

| ID | Frame | Every | Carries |
|---|---|---:|---|
| 280h | Motor_1 | 10 ms | engine speed → rev counter |
| 288h | Motor_2 | 10 ms | coolant temperature (multiplexed) |
| 480h | Motor_5 | 20 ms | MIL, EPC, glow lamps + XOR checksum |
| 1A0h | Bremse_1 | 10 ms | vehicle speed, ABS/ASR/brake lamps + counter |
| 4A0h, 5A0h | Bremse_3, _2 | 10 ms | wheel speeds, odometer pulses |
| 470h | BSG_Kombi | 50 ms | turn signals, hazard, charging, dimming |
| 570h | BSG_Last | 100 ms | battery voltage 13.8 V |
| 050h | Airbag_1 | 20 ms | airbag lamp + counter + checksum |
| 5D8h, 5D0h | Verbauliste, Systeminfo | 100 ms | which modules are fitted |

> The cluster watches every frame: a missing one raises a lamp. Without the fitted-modules list it
> ignores the ABS, brake and airbag lamps.

</div>
</div>

<!--
Before the lecture: plug the PCAN-USB into the cluster, bring the interface up at 500 kilobits
per second and check with candump that the cluster is alive. It sends its own frames, 320, 420 and
520 hex, even with nothing else on the bus.

mise run fabia plays a 36-second scripted drive: the needle climbs, the turn signals blink, the
lamps come on. mise run fabia:hand opens the window and lets you drive with the keyboard or the
pad.

The table is the whole car as the cluster sees it. Engine and brake frames go every 10
milliseconds, because the needles must move smoothly. Lamps and the turn signals can wait 50 or
100 milliseconds. Some frames carry a message counter and an XOR checksum: the cluster checks them,
and a frame that repeats or is corrupted counts as missing. The last two frames tell the cluster
which control units the car has; without them it does not trust the ABS, brake and airbag lamps.
This is the timeout and plausibility monitoring from the errors section, in a real control unit.
-->

---
routeAlias: savvycan
---

## Demo: watch the bus and send a frame by hand

<div class="grid grid-cols-2 gap-8 items-start text-sm">
<div>

### Open SavvyCAN on `can0`

1. `./SavvyCAN-*.AppImage`
2. **Connection → Open Connection Window → Add New Device**
3. **QT SerialBus Devices** · type `socketcan` · port `can0` · **Create New Connection**
4. Untick **Listen Only**, or nothing is sent
5. **RE Tools → Sniffer**: one row per ID, changing bytes highlighted

### Turn signals: BSG_Kombi, 470h, 5 bytes

| Byte 0 | Lamp |
|---|---|
| `01` | left |
| `02` | right |
| `0B` | hazard: both + hazard bit 3 |

Bytes 1–4: `00 00 00 FF`

</div>
<div>

### Send it: Send Frames → Custom

| Bus | ID | Len | Data | Trigger | Modifications |
|---|---|---|---|---|---|
| 0 | `0x470` | 5 | `01 00 00 00 FF` | `50ms` | |
| 0 | `0x470` | 5 | `01 00 00 00 FF` | `330ms` | `D0 = D0 ^ 1` |

Tick **En** on one row: the first holds the lamp on, the second blinks it.

### Or from a terminal

```sh
cansend can0 470#01000000FF   # left on
cansend can0 470#00000000FF   # off
while true; do
  for i in {1..7}; do cansend can0 470#01000000FF; sleep 0.05; done
  for i in {1..7}; do cansend can0 470#00000000FF; sleep 0.05; done
done
```

> The cluster does not blink by itself: the sender toggles the bit every 0.33 s.

</div>
</div>

<!--
SavvyCAN is a free sniffer and sender; the AppImage runs without installing. Connect through Qt
SerialBus with the socketcan plugin on can0, not the peakcan plugin: the PEAK adapter already runs
as can0 through the kernel driver. Untick Listen Only, or SavvyCAN only watches.

In the sniffer, show the room the cluster's own frames, then start mise run fabia and watch the
engine and brake rows change while the needles move.

Stop the simulation, then send the turn-signal frame by hand. 470 hex is BSG_Kombi, five bytes;
bit 0 of the first byte is the left lamp, bit 1 the right, bit 3 says hazard. The cluster has no
flasher of its own: whoever sends the frame switches the bit on and off every third of a second.
The second row in the sender does that by flipping bit 0 at every send. If the arrow drops out,
the cluster wants the frame more often: use the 50 millisecond row or the shell loop, which keeps
the 50 millisecond period and toggles every seven frames.

Never do this on a real car: a wrong frame on a live bus can raise faults in other control units.
-->
