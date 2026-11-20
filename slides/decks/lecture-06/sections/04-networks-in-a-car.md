---
routeAlias: networks-in-a-car
layout: section
---

###### Section 04

# Networks in a car

High-speed and low-speed CAN, LIN and gateways; and what came after: CAN FD, CAN XL, FlexRay,
automotive Ethernet.

<!--
Section 04: networks in a car. A car does not have one bus, it has several, at different speeds,
joined by gateways. We look at two real networks from around 2004, and then at the buses that took
over where CAN runs out of speed.
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
CAN in brief. Bosch started developing it in 1983 and presented it in 1986. The first controller
chips came the year after. The first production car with CAN was the Mercedes-Benz S-Class in 1991.
And since 1993 CAN has been an international standard, ISO 11898, which anyone may implement. It is
not a Bosch-only protocol. In 2012 Bosch presented CAN FD, the faster version, which joined the
standard in 2015.

On the right are the properties you need. One twisted pair, CAN high and CAN low. Any node may send
when the bus is idle; there is no master. Clashes are settled by priority without losing the
winning frame. Classic CAN runs at up to one megabit per second and carries zero to eight bytes per
frame. Errors are detected and the frame is sent again automatically, and a node that keeps
failing switches itself off. That is the strike system from section 02.

The last line corrects a word you may find in older material: CAN is sometimes called asynchronous
because there is no separate clock wire. But the receivers do not run freely. Every node readjusts
its timing on the edges of the signal, bit by bit. Section 05 shows how.

At the bottom: real cars run 500 kilobits per second for powertrain and chassis, and 125 to 250 for
body and comfort. Limits like "16 ECUs per bus" that you sometimes read are a car maker's own
design rules. The high-speed standard requires transceivers that can drive at least 30 nodes.
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
Cars use two kinds of CAN and, beside them, LIN.

High-speed CAN is the one we model today. It runs up to one megabit per second, usually 500
kilobits, on a twisted pair. It carries the engine, the gearbox, the ABS and ESP, and the steering.
Its weakness: if one of the two wires breaks or shorts, the bus stops.

Low-speed fault-tolerant CAN runs up to 125 kilobits per second. Its advantage is in the name: if
one wire breaks or shorts, it carries on with the other one. That is why it was used for the body,
in doors and seats, where cables flex and wear. It is being replaced by high-speed CAN and CAN FD in
newer cars.

LIN, the Local Interconnect Network, is the cheap end. One wire, up to 20 kilobits per second, and
one master that asks its slaves in turn, so there is no arbitration at all. It exists because a
full CAN node costs too much for a window motor or a mirror. A door ECU typically sits on CAN and
runs a small LIN bus to the motors and switches in that door.
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
Here are two real networks from the source deck, both from around 2004.

On the left, the Peugeot 407. At the top, in red, the high-speed powertrain CAN at 500 kilobits per
second: engine ECU, gearbox, ESP, steering and suspension. In the middle, the orange box called BSI,
Peugeot's body-control unit. It is the gateway. Below it, the low-speed body network in blue and
the comfort network in green, both at 125 kilobits: the instrument cluster, the radio, the climate
control, the seats. A separate CAN goes to the diagnostic socket, and a LIN bus to the wipers.

On the right, the BMW 1 Series of the same years. A powertrain CAN for chassis and engine, a body
CAN for comfort and safety, LIN sub-buses hanging off body units, and a MOST ring in blue for the
multimedia. MOST was a fiber-optic bus for audio and video; it is obsolete now, replaced by
automotive Ethernet.

The green box is the point. Every bus runs at the speed its functions need, and a gateway passes
chosen messages between them. The vehicle speed is measured on the powertrain bus, by the ABS, and
the gateway repeats it onto the body bus for the dashboard. In the meeting room, that is the
interpreter in the doorway.
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
Classic CAN has two limits: one megabit per second, and eight bytes per frame. Here is what came
after.

CAN FD, flexible data rate, keeps arbitration at the classic speed, because every node must still
hear every bit within one bit time. Once a single sender has won, it switches to a faster rate for
the data, usually two to five, up to eight megabits per second, and it carries up to 64 bytes.
Most new ECUs use it. CAN XL goes further: up to 20 megabits for the data and up to 2048 bytes.

FlexRay is different in kind. Instead of arbitration, every message has a fixed time slot in a
repeating cycle, so its timing is exact. It ran at 10 megabits on two channels and appeared first in
the BMW X5 in 2006, for the adaptive dampers. It is fading out; few new designs use it.

Automotive Ethernet carries the big data: cameras, infotainment and, more and more, the backbone
between central computers. It runs over a single twisted pair at 100 megabits or a gigabit, point
to point through switches. There is also a 10 megabit version, 10BASE-T1S, where several nodes
share one pair, much like CAN.

Notice what does not change: inside a door, a seat or a brake unit, CAN and LIN stay.
-->

---
routeAlias: zonal
---

## From domains to zones

<div class="grid grid-cols-2 gap-8">
<div>

### Domain architecture (the 2004 cars)

- One bus per **function**: powertrain, chassis, body, multimedia
- ECUs sit where their function needs them; wires run across the car to their bus
- Gateways between the buses

</div>
<div>

### Zonal architecture (cars from ≈ 2020)

- A few **central computers** run the functions
- **Zone controllers**, one per area of the car, connect the nearby sensors and actuators
- **Ethernet** backbone between zones and center; **CAN FD and LIN** inside each zone

</div>
</div>

> The goal is the one from section 01: fewer and shorter wires. CAN does not disappear; it moves to
> the edge of the network.

<!--
One last trend. The 2004 cars have a domain architecture: one bus per function, powertrain,
chassis, body, multimedia. An ECU sits wherever its function needs it, and its wires run across the
car to its bus.

Newer cars move toward a zonal architecture. A few central computers run the functions. Each area
of the car, front left, rear right and so on, gets a zone controller, which connects the sensors
and actuators near it, whatever function they belong to. Between the zones and the center runs an
Ethernet backbone; inside each zone, CAN FD and LIN.

The motivation is the one from section 01: fewer and shorter wires. And CAN does not disappear; it
moves to the edge, where the sensors and motors are.
-->
