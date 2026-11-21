---
routeAlias: diagnostics
layout: section
---

###### Section 09

# Diagnostics

How a workshop talks to the car over CAN: finding a broken wire, OBD-II, UDS and ISO-TP.

<!--
Section 09, diagnostics: how a workshop talks to the car over CAN. A workshop asks two questions. Is
the network itself healthy? And what do the ECUs report about the car? The second question uses
layers 4 and 5 of the OSI model, the two layers that normal CAN traffic leaves empty.
-->

---
routeAlias: broken-wire
---

## Finding a broken wire

<img src="/diagrams/09-broken-wire.svg" class="w-full" style="max-height: 28rem" alt="Left: a CAN network. AT, engine, USM and ABS on one line; from the USM the bus runs through the BCM to the tester socket, the climate unit and the airbag. A branch from the tester's junction to the EPS, with the dashboard behind it, is cut. Right: a table, one row per ECU the tester asks, one column per sender, saying whose messages it still receives. Every row that answers marks the dashboard and the EPS NOK and the others OK; blank cells are senders that ECU does not listen to. The dashboard and EPS rows are hatched: they cannot answer. The result row: OK for all but the dashboard and the EPS."/>

<div class="caption">Redrawn from the source deck, slide 34</div>

<div class="grid grid-cols-2 gap-8">
<div>

- Every ECU **watches** the messages it expects; one that stops arriving is a **timeout** fault.
- The tester asks each ECU it can reach: **whose messages do you still receive?**
- The missing senders sit behind one cut: the **EPS and the dashboard**.

</div>
<div>

> First checks with a meter: **60 Ω** across CAN_H and CAN_L with the ignition off, and both lines
> near **2.5 V** at idle.

</div>
</div>

<!--
The first question: is the network healthy? The picture on the left shows a CAN network with a
fault. One branch is cut. Behind the cut are the electric power steering, EPS, and the dashboard.

The bullets say how the workshop finds it. Every ECU watches the messages it expects. When one stops
arriving, the ECU stores a timeout fault. The tester, the workshop's diagnostic device, is plugged
into the car's diagnostic socket. It asks each ECU it can reach: whose messages do you still
receive?

The table on the right shows the answers. Each row is one ECU that is asked. Each column is one
sender. OK means "I still receive its messages". NOK means "not OK". A blank cell means that this
ECU never listens to that sender. Look down the columns for the dashboard and the EPS: every ECU
that answers says NOK. All other columns say OK. The rows of the dashboard and the EPS are hatched,
because these two cannot answer at all.

The result row at the bottom sums it up: everything is OK except the dashboard and the EPS. Both sit
behind the same piece of wire. So that is where the cut is.

The box gives the first checks with a meter. With the ignition off, the resistance between CAN high
and CAN low should be 60 ohms, the two terminations from section 04. And with the bus idle, both
wires should be near 2.5 volts.
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
The second question: what do the ECUs report? Every car has a socket for this, the OBD-II socket.
OBD stands for on-board diagnostics.

The bullets on the left give the facts. The socket has 16 pins and sits under the dashboard. CAN
high is on pin 6 and CAN low on pin 14. The law requires it, so that emissions can be checked: in
the USA since 1996, in the EU since 2001 for petrol cars and 2004 for diesel cars. Every car offers
the same few services: live data, stored fault codes, clearing the codes, and the VIN, the vehicle
identification number.

The table on the right shows one exchange: the tester asks for the vehicle speed. All numbers are
hexadecimal. The tester sends a frame with identifier 7DF. All ECUs that deal with emissions listen
to it. The data bytes are 02, 01, 0D. 02 means two bytes follow. 01 means "show live data". 0D is
the number for vehicle speed.

The engine ECU answers with identifier 7E8. The data bytes are 03, 41, 0D, 57. 03 means three bytes
follow. 41 is the request 01 plus 40, which marks a positive answer. 0D repeats the question. And 57
is the value. Hexadecimal 57 is 87 in decimal. The car drives at 87 kilometers per hour.

The caption points out what is different here. Normal CAN traffic is announcements to the whole
room. Diagnostics is a question and an answer. A block of identifiers is reserved for these
conversations.
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
OBD-II is the small part that the law requires. A workshop tester mostly uses a larger protocol,
UDS, Unified Diagnostic Services. The first bullet on the right says that every car maker uses it,
for every ECU. Its standard is ISO 14229.

The table on the left lists the main services. Each service has a number, written in hexadecimal.

Service 10 switches the ECU to another session, extended or programming. This is layer 5 of the OSI
model, the private consultation from section 02.

Services 22 and 2E read and write a value by its number. Writing a setting is called coding.

Services 19 and 14 read and clear the stored faults. Each fault comes with the conditions at the
moment it occurred, called freeze-frame data.

Service 27 unlocks protected functions. The ECU sends a random number, the seed. The tester must
reply with the matching key.

Service 31 starts a routine, for example bleeding the ABS or calibrating the steering angle sensor.

Services 34, 36 and 37 load new software into the ECU. This is called flashing.

Service 3E is "tester present". It means "I am still here" and keeps the session open.

The second bullet on the right gives the rule for answers. A positive answer is the service number
plus 40, as in OBD-II. A negative answer starts with 7F, then the service number and a code for the
reason.

The last bullet leads on. Many answers, and all software, are longer than the 8 bytes of one frame.
They need help from layer 4: ISO-TP.
-->

---
routeAlias: iso-tp
---

## ISO-TP: a long answer in installments

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

Reading the VIN: request `22 F1 90`, answer `62 F1 90` + 17 characters = **20 bytes**.

<img src="/diagrams/09-iso-tp.svg" alt="Sequence diagram between the tester, sending on 7E0h, and the engine ECU, answering on 7E8h. Tester to ECU: 03 22 F1 90, a single frame, the request. ECU to tester: 10 14 62 F1 90 c1 c2 c3, the first frame, 20 bytes coming. Tester to ECU, highlighted: 30 00 00, flow control, send all with no pause. ECU to tester: 21 c4 to c10, consecutive frame 1. ECU to tester: 22 c11 to c17, consecutive frame 2, the last 7."/>

</div>
<div>

- **Single frame**: up to 7 bytes fit in one frame, no flow control.
- The **first frame** announces the length (up to 4095 bytes).
- **Flow control** sets how many frames before the next pause, and the minimum gap between them.
- **Consecutive frames** carry a sequence number 1, 2, … F, 0, 1, … so a lost frame is noticed.

</div>
</div>

<div class="caption text-left">ISO 15765-2 · VIN: vehicle identification number, 17 characters,
c1 to c17 · F190h: the UDS identifier for the VIN · 7E0h/7E8h: the engine ECU's diagnostic pair</div>

<!--
ISO-TP is the transport protocol on top of CAN. It splits a long message into numbered frames. In
the room, that was the long report in installments.

The example reads the VIN. The line above the diagram gives the sizes. The request is three bytes:
22, F1, 90. 22 is the UDS service "read data", and F190 is the number of the VIN. The answer is 62,
F1, 90 and then the 17 characters of the VIN: 20 bytes. That is too long for one frame.

Follow the diagram from top to bottom. The tester sends on identifier 7E0, and the engine ECU
answers on 7E8.

First arrow. The request fits in one frame, called a single frame. Its first byte, 03, says that
three bytes follow.

Second arrow. The ECU sends a first frame. It begins with 10 14. The 1 marks a first frame, and
hexadecimal 14 is 20: twenty bytes are coming. The frame also carries 62, F1, 90 and the first three
characters.

Third arrow, highlighted. The tester answers with a flow control frame: 30, 00, 00. It means: go on,
send all the rest, with no pause between frames.

Last two arrows. The ECU sends two consecutive frames. They start with 21 and 22, which are the
sequence numbers 1 and 2. Each carries seven characters. Three plus seven plus seven is seventeen.

The bullets on the right give the general rules. Up to 7 bytes fit in a single frame. The first
frame can announce up to 4095 bytes. With flow control, the receiver sets the pace. And the sequence
number lets the receiver notice a lost frame.

That is the theory. In the wrap-up we connect the simulated car to real hardware.
-->
