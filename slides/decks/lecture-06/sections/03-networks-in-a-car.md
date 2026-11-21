---
routeAlias: networks-in-a-car
layout: section
---

###### Section 03

# Networks in a car

High-speed and low-speed CAN, LIN and gateways; and what came after: CAN FD, CAN XL, FlexRay,
automotive Ethernet.

<!--
Section 03. A real car has not one bus but several. They run at different speeds, and gateways join
them. We look at where CAN comes from, at the networks of two real cars, and at the faster networks
that came after CAN.
-->

---
routeAlias: can-in-brief
---

## CAN in brief

<div class="grid grid-cols-2 gap-8">
<div>

### History

| Year | |
|---|---|
| 1983 | Bosch starts developing CAN |
| 1986 | presented at the SAE congress |
| 1987 | first controller chips (Intel, Philips) |
| 1991 | first production car with CAN: Mercedes-Benz S-Class (W140) |
| 1993 | **ISO 11898**: an open international standard |
| 2012 | CAN FD; in ISO 11898-1 since 2015 |

</div>
<div>

### Properties

- Serial, on one **twisted pair**: CAN_H and CAN_L
- **Multi-master**: any node may send when the bus is idle
- **Non-destructive arbitration** by identifier priority
- Classic CAN: up to **1 Mbit/s**, **0–8 bytes** per frame
- Error detection, automatic retransmission, and a faulty node switches itself off
- Every node **resynchronizes** on the edges of the signal, bit by bit

</div>
</div>

<div class="caption text-left">Bit rates in cars: 500 kbit/s for powertrain and chassis, 125 to
250 kbit/s for body and comfort · the number of nodes per bus is a car maker's design rule; the
high-speed standard requires at least 30</div>

<!--
First, CAN in brief. On the left is its history. Bosch started developing CAN in 1983 and presented
it in 1986. The first chips came in 1987. The first production car with CAN was the Mercedes-Benz
S-Class of 1991. Since 1993 CAN has been an open international standard, ISO 11898, so any company
may build it. In 2012 a faster version followed, CAN FD. We meet it at the end of this section.

On the right are the properties. One new word: a node is any ECU connected to a bus.

CAN is serial: the bits travel one after another on one twisted pair. It is multi-master, which
means it needs no master: any node may send when the bus is idle. Arbitration is non-destructive:
the frame with the highest priority gets through undamaged. The original version, called classic
CAN, sends at most 1 megabit per second, a million bits each second, and one frame carries 0 to 8
bytes of data. Errors are detected, the frame is sent again automatically, and a faulty node
switches itself off. That is the strike rule from the room. The last bullet uses the word edge. An
edge is a change of level on the wire, and every node uses the edges to keep its timing in step.
Section 04 shows how.

The caption gives typical bit rates. Powertrain and chassis, which means drive, brakes and steering,
run at 500 kilobits per second. Body and comfort functions run at 125 to 250. How many nodes go on
one bus is the car maker's own rule. The standard requires that at least 30 are possible.
-->

---
routeAlias: two-kinds-of-can
---

## Two kinds of CAN, and LIN beside them

| | High-speed CAN | Low-speed fault-tolerant CAN | LIN |
|---|---|---|---|
| Standard | ISO 11898-2 | ISO 11898-3 | ISO 17987 |
| Bit rate | up to 1 Mbit/s; 500 kbit/s typical | up to 125 kbit/s | up to 20 kbit/s |
| Wires | twisted pair | twisted pair | **one wire** |
| Access | multi-master, arbitration | multi-master, arbitration | **one master** polls its slaves |
| One wire broken or shorted | the bus stops | **keeps working** on the other wire | the bus stops |
| Used for | engine, gearbox, ABS/ESP, steering | doors, seats, lights, climate | window motors, mirrors, rain sensor, seat switches |

<div class="caption text-left">LIN exists because a CAN node costs too much for a mirror motor: one
wire, a cheap controller, and no arbitration because only the master starts a message</div>

<!--
Cars use two kinds of CAN, and next to them a simpler bus called LIN. The table compares the three,
one per column.

High-speed CAN is the one we model today. It runs at up to 1 megabit per second, typically 500
kilobits per second, on a twisted pair. It serves the engine, the gearbox, ABS and ESP, and the
steering. Look at the row "one wire broken or shorted": the bus stops.

Low-speed fault-tolerant CAN runs at up to 125 kilobits per second. Its strength is in the same row:
with one wire broken or shorted, it keeps working on the other wire. It is used in doors, seats,
lights and climate control, where cables bend and wear.

LIN stands for Local Interconnect Network. It uses only one wire and runs at up to 20 kilobits per
second. Its access rule is different. One node is the master, and it asks the other nodes, called
slaves, one after the other. Only the master starts a message, so LIN needs no arbitration.

The caption says why LIN exists. A CAN node costs too much for a mirror motor or a window motor. LIN
is the cheap solution for those.
-->

---
routeAlias: a-2004-network
---

## Two networks from 2004

<div class="grid grid-cols-2 gap-6 items-start">
<div>

<img src="/pptx/slide20-peugeot-407.png" alt="Network of the Peugeot 407: a 500 kbit/s high-speed powertrain CAN joining engine ECU, gearbox, ESP, steering, gyro and suspension; a body-control unit called BSI acting as gateway to a 125 kbit/s low-speed body network and a 125 kbit/s comfort network with cluster, radio, climate and seats, a diagnostic CAN to the diagnostic socket, and a LIN bus to the wipers."/>

<div class="caption">Peugeot 407 · the BSI in the middle is the gateway</div>

</div>
<div>

<img src="/pptx/slide21-bmw-e87.png" alt="Network of the BMW 1 Series E87: a 500 kbit/s powertrain CAN for chassis and engine, a 100 kbit/s body CAN for comfort and safety units with LIN sub-buses, a MOST optical ring for multimedia, all joined through a central body controller."/>

<div class="caption">BMW 1 Series (E87) · MOST ring for multimedia, since replaced by Ethernet</div>

</div>
</div>

<div class="handson">Every bus runs at the speed its functions need, and a <b>gateway</b> passes chosen
messages between them: vehicle speed goes from the powertrain bus to the dashboard on the body
bus.</div>

<!--
Here are the networks of two real cars from around 2004.

On the left is the Peugeot 407. The red boxes at the top are on the high-speed powertrain CAN at 500
kilobits per second: the engine ECU, the gearbox, the ESP and others. The orange box in the middle,
labeled BSI, is Peugeot's body control unit. It is the gateway. Two low-speed networks at 125
kilobits per second hang on it. The blue boxes are the body network, with the airbag, the alarm and
the rain sensor. The green boxes are the comfort network, with the instrument cluster, the radio,
the climate controls and the seats. The gray box, DIAG, is the diagnostic socket. And at the bottom
left, the front wipers hang on a LIN bus.

On the right is the BMW 1 Series. The red block is the powertrain CAN for chassis and engine, at 500
kilobits per second. The green block is the body CAN at 100 kilobits per second, for body, safety
and comfort. The small box between them, BC1, is the gateway. The blue block is a ring called MOST,
a fiber-optic network for audio and video. MOST is no longer used. A network called automotive
Ethernet replaced it.

The green line under the pictures gives the lesson. Every bus runs at the speed its functions need,
and a gateway passes chosen messages between them. The vehicle speed goes from the powertrain bus to
the dashboard on the body bus. In the meeting room, that is the interpreter in the doorway.
-->

---
routeAlias: after-classic-can
---

## When classic CAN runs out

| | Classic CAN | CAN FD | CAN XL | FlexRay | Automotive Ethernet |
|---|---|---|---|---|---|
| Since | 1991 | 2012 (ISO 2015) | CiA 610 (ISO 2024) | 2006 | ≈ 2013 |
| Bit rate | ≤ 1 Mbit/s | 0.5–1 arbitration, **2–8 data** | **≤ 20 data** | 10 Mbit/s, two channels | 10 / 100 / 1000 Mbit/s |
| Payload | 8 bytes | **64 bytes** | **2048 bytes** | 254 bytes | ≈ 1500 bytes |
| Access | arbitration | arbitration | arbitration | **fixed time slots** | switched, point to point (10BASE-T1S: shared) |
| Used for | most ECUs | ECUs that outgrew 8 bytes, flashing software | zonal links | chassis, X-by-wire (fading) | cameras, infotainment, the backbone |

<div class="caption text-left">CAN FD keeps arbitration at the classic rate, then switches to a faster
rate for the data · FlexRay's slots make timing exact, at the price of a schedule fixed in advance ·
Ethernet standards: IEEE 802.3bw (100BASE-T1), 802.3bp (1000BASE-T1), 802.3cg (10BASE-T1S)</div>

<!--
Classic CAN has two limits: 1 megabit per second, and 8 bytes per frame. The table shows what came
after it, one network per column. One word in the row labels is new: the payload is the useful data
that one frame carries.

CAN FD means flexible data rate. A CAN FD frame starts at the classic speed, because during
arbitration every node must hear every bit in time. Once one sender has won, it switches to a faster
rate for the data: 2 to 8 megabits per second. And the payload grows from 8 to 64 bytes. CAN XL goes
further: up to 20 megabits per second and 2048 bytes.

FlexRay works differently. It has no arbitration. Every message has its own fixed time slot in a
repeating schedule, like the time-sharing model in section 01. So the timing is exact, but the
schedule must be fixed in advance. FlexRay runs at 10 megabits per second on two channels. It was
used for chassis functions and is fading out.

Automotive Ethernet is the car version of the office network. It runs at 10, 100 or 1000 megabits
per second, with a payload of about 1500 bytes. In most versions, each cable joins only two devices,
and boxes called switches pass the frames on. It carries the large data: cameras, infotainment, and
the main links of the car's network, called the backbone.

Look at the bottom row. Classic CAN is still used for most ECUs.
-->

---
routeAlias: zonal
---

## From domains to zones

<div class="diagram-wide">

<img src="/diagrams/03-domain-zonal.svg" style="max-height: 25rem" alt="Two cars seen from above. Left, domains: a central gateway with four buses, powertrain, chassis, body and multimedia, each a different color and line style, each running across the whole car to reach its ECUs. Right, zones: a central computer joined by a thick Ethernet backbone to four zone controllers, one per corner of the car, each wired over short CAN FD or LIN links to the sensors and actuators near it."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

**Domains** (the 2004 cars): one bus per **function**, wherever its ECUs sit; gateways between the
buses.

</div>
<div>

**Zones** (cars from ≈ 2020): a few **central computers**; a **zone controller** per area wires the
sensors near it over **CAN FD and LIN**; **Ethernet** between zones and center.

</div>
</div>

> The goal is the one from section 01: fewer and shorter wires. CAN does not disappear; it moves to
> the edge of the network.

<!--
One last trend, which shows where CAN is going. The picture shows two cars from above.

On the left is the layout of the 2004 cars, called domains. A domain is a group of functions:
powertrain, chassis, body or multimedia. Each domain has its own bus, drawn in its own color. Each
bus runs across the whole car to reach its ECUs, and a central gateway joins the buses.

On the right is the layout of cars from about 2020, called zones. A few central computers run the
functions. Each area of the car has a zone controller, one per corner in the picture. The zone
controller connects the sensors and the actuators near it, whatever function they belong to. A
sensor measures something. An actuator moves something, like a motor or a valve. Those short links
use CAN FD and LIN. The thick line between the zone controllers and the central computer is an
Ethernet backbone.

The box at the bottom gives the reason, and it is the one from section 01: fewer and shorter wires.
CAN does not disappear. It moves to the edge of the network, close to the sensors and motors.

So CAN stays. Now we open it up, starting with the wires.
-->
