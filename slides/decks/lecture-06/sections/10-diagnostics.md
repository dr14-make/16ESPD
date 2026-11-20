---
routeAlias: diagnostics
layout: section
---

###### Section 10

# Diagnostics

How a workshop talks to the car over CAN: finding a broken wire, OBD-II, UDS and ISO-TP.

<!--
Section 10: diagnostics. Two questions a workshop asks. Is the network itself healthy? And what do
the ECUs report about the car? The second one uses the only parts of CAN traffic that fill layers 4
and 5 of the OSI table.
-->

---
routeAlias: broken-wire
---

## Finding a broken wire

<div class="grid grid-cols-[1.4fr_1fr] gap-8 items-center">
<div>

<img src="/pptx/slide34-broken-wire.png" alt="A CAN network with automatic transmission, engine control, ABS, a smart service module, body control, diagnostic socket, climate, airbag, and the electric power steering with the dashboard behind it on one branch, which is cut. Below, a table: each row is an ECU reporting whether it receives each other ECU's messages. Every ECU that reports marks the dashboard and the power steering not OK; the dashboard and power steering rows are hatched because they cannot report. The result row: dashboard and power steering not OK, everything else OK."/>

<div class="caption">From the source deck, slide 34</div>

</div>
<div>

- Every ECU **watches** the messages it expects; a message that stops arriving is a **timeout**,
  stored as a fault.
- The tester asks each ECU it can reach: **whose messages do you still receive?**
- The missing senders are all behind the same cut: here the **power steering and the dashboard**.

> First checks with a meter: **60 Ω** across CAN_H and CAN_L with the ignition off, and both lines
> near **2.5 V** at idle.

</div>
</div>

<!--
The source deck's last slide is a real workshop method. The network at the top has a cut wire: the
branch to the electric power steering, EPS, and the dashboard behind it is disconnected.

Every ECU watches the messages it expects, as we said in section 06. If a message stops arriving for
longer than its timeout, the ECU stores a fault: "no message from the dashboard". So the tester at
the diagnostic socket asks every ECU it can reach: whose messages do you still receive?

Read the table. Each row is one ECU's answer. The engine control, the ABS, the body controller, the
airbag: all of them say OK for everyone except the dashboard and the EPS. Those two rows are
hatched, because they cannot answer at all; the tester cannot reach them. The result row at the
bottom puts it together: the dashboard and the EPS are not OK, everything else is fine. The fault
is on the wire to those two.

The box gives the first checks with a meter. With the ignition off, CAN high to CAN low should read
60 ohms, the two terminations in parallel, from section 05. With the bus idle, both lines should sit
near 2.5 volts. A line stuck at zero or at battery voltage is a short.
-->

---
routeAlias: obd-ii
---

## OBD-II: the socket every car has

<div class="grid grid-cols-2 gap-8">
<div>

- A 16-pin socket under the dashboard (SAE J1962); **CAN_H on pin 6, CAN_L on pin 14**.
- Required for emissions checks: USA from 1996, EU from 2001 (petrol) and 2004 (diesel); on CAN
  (ISO 15765-4) in the USA since 2008.
- The same few services in every car: live data, stored fault codes, clear codes, the VIN.
- The tester asks on **7DFh**, to every emissions ECU; the engine ECU answers on **7E8h**.

</div>
<div>

### Asking for vehicle speed

| | ID | Data bytes |
|---|---|---|
| request | 7DF | `02` `01` `0D` |
| answer | 7E8 | `03` `41` `0D` `57` |

- `02`, `03`: how many bytes follow
- `01` show live data; `0D` vehicle speed
- `41` = `01` + 40h: a positive answer
- `57`h = **87 km/h**

</div>
</div>

<div class="caption text-left">Diagnostics is the one place where CAN works with requests and
answers: the identifiers 7DFh and 7E0–7EFh are reserved for these conversations</div>

<!--
Every car sold since the late nineties has an OBD-II socket under the dashboard: 16 pins, with CAN
high on pin 6 and CAN low on pin 14. OBD means on-board diagnostics. It was made law for emissions:
in the USA from 1996, in the EU from 2001 for petrol and 2004 for diesel cars, and in the USA every
car must speak it over CAN since 2008. So every car offers the same few services: live data such as
speed and engine speed, the stored fault codes, clearing them, and the vehicle identification
number.

On the right, a real exchange. The tester sends on identifier 7DF, which every emissions-related
ECU listens to. The data bytes: 02, two bytes follow; 01, show live data; 0D, the item number for
vehicle speed. The engine ECU answers on 7E8: 03, three bytes follow; 41, which is the request 01
plus hexadecimal 40, the sign of a positive answer; 0D, the item it answers; and 57. Hexadecimal 57
is 87. The car is driving at 87 kilometers per hour, our topic from section 02.

The line at the bottom matters for the meeting room. Normal CAN traffic is topics broadcast to
everyone. Diagnostics is a conversation: a request and an answer. It still uses ordinary
identifiers, but a block of them is reserved for these conversations, so the pairs work like
addresses. In the room, it is a private exchange with topic numbers kept free for it.
-->

---
routeAlias: uds
---

## UDS: what the workshop tester really uses

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

| Service | | What it does |
|---|---|---|
| 10h | Diagnostic session control | switch to an extended or programming **session** (layer 5) |
| 22h / 2Eh | Read / write data by identifier | read a value, write a setting (coding) |
| 19h / 14h | Read / clear fault information | stored codes with their freeze-frame data |
| 27h | Security access | unlock protected services with a seed and key |
| 31h | Routine control | run a test: bleed the ABS, calibrate the steering angle |
| 34h, 36h, 37h | Download | **flash new software** into the ECU |
| 3Eh | Tester present | "I am still here", keeps the session open |

</div>
<div>

- ISO 14229, used by every car maker for every ECU, far beyond the emissions set.
- Positive answer: service + 40h. Negative: `7F`, the service, and a reason code.
- Answers and software images are often **longer than 8 bytes**: they need ISO-TP.

</div>
</div>

<!--
OBD-II is the small, legally required part. What a dealer's workshop tester really speaks is UDS,
Unified Diagnostic Services, ISO 14229. Every car maker uses it for every ECU.

The table lists the services you meet most. Service 10 switches the ECU into a session: the default
session, an extended one for the workshop, or a programming session for new software. That is the
OSI session layer, layer 5, which normal CAN traffic never uses. Services 22 and 2E read and write
data by an identifier number: read a sensor value, or write a setting, which workshops call coding.
19 and 14 read and clear fault codes, with the freeze-frame data stored at the moment of the fault.
27 unlocks protected services: the ECU sends a random number, the seed, and the tester must answer
with the right key. 31 runs routines, such as bleeding the ABS hydraulics or calibrating the steering
angle sensor. 34, 36 and 37 download new software into the ECU's flash memory. And 3E simply says
"I am still here", so the ECU does not drop back to the default session.

The answers follow the OBD rule: a positive answer is the service number plus 40. A negative answer
is 7F, the service, and a code that says why: wrong session, security locked, and so on.

Many answers, and certainly a software image, are much longer than the eight bytes of a CAN frame.
That needs layer 4: ISO-TP.
-->

---
routeAlias: iso-tp
---

## ISO-TP: a long answer in installments

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

Reading the VIN: request `22 F1 90`, answer `62 F1 90` + 17 characters = **20 bytes**.

| From | First byte | Frame | Carries |
|---|---|---|---|
| ECU | `10 14` | **first frame** | "20 bytes coming", `62 F1 90` and 3 characters |
| tester | `30 00 00` | **flow control** | "go on: all of it, no pause needed" |
| ECU | `21` | **consecutive frame 1** | 7 characters |
| ECU | `22` | **consecutive frame 2** | the last 7 characters |

</div>
<div>

- **Single frame**: up to 7 bytes fit in one frame, no flow control.
- The **first frame** announces the length (up to 4095 bytes).
- **Flow control** sets how many frames before the next pause, and the minimum gap between them.
- **Consecutive frames** carry a sequence number 1, 2, … F, 0, 1, … so a lost frame is noticed.

</div>
</div>

<div class="caption text-left">ISO 15765-2 · VIN: vehicle identification number, 17 characters ·
F190h: the UDS identifier for the VIN</div>

<!--
ISO-TP, ISO 15765-2, is CAN's transport layer, layer 4, used for diagnostics. It splits a long
message into numbered installments, like the long report in the meeting room.

The example reads the vehicle identification number. The tester sends service 22, read data, with
identifier F1 90, which means the VIN. The answer is 62, the positive answer to 22, then F1 90, then
the 17 characters of the VIN: 20 bytes, too long for one frame.

So the ECU sends a first frame. Its first byte, 1, says "first frame", and together with the next
byte, 0 14 hexadecimal, it announces 20 bytes. The rest of the frame carries 62 F1 90 and the first
three characters. Then the ECU waits. The tester answers with a flow control frame: 30 means "go
on", the next 00 means "send everything without waiting for me again", and the last 00 means no
minimum pause between frames. Then the ECU sends consecutive frames, numbered 21 and 22, each
carrying seven characters. Three plus seven plus seven makes seventeen.

The right column has the rules. Up to seven bytes fit in a single frame, with no flow control. The
first frame announces up to 4095 bytes. Flow control lets a slow receiver set the pace. And the
sequence number in each consecutive frame counts 1 to F and wraps to 0, so a missing frame is
noticed.
-->
