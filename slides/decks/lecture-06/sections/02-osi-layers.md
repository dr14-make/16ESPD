---
routeAlias: osi-layers
layout: section
---

###### Section 02

# The OSI model

The seven layers one by one, each mapped onto CAN and onto the meeting room. CAN fills three of them.

<!--
Section 02: the OSI model. Network engineers describe every network with the same seven-layer model, the
OSI model. We go through it layer by layer: what each layer does, what CAN puts there, and what it
is in the meeting room. Then one table for all seven, and one picture you should drop.
-->

---
routeAlias: osi-model
---

## The OSI model

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

<img src="/pptx/slide07-osi-model.jpg" alt="The seven OSI layers as colored boxes, from 1 Physical at the bottom, access to media, through 2 Data Link, local delivery, 3 Network, routing to destination, 4 Transport, delivery and sequencing, 5 Session, establish connection, 6 Presentation, encryption and formatting, to 7 Application at the top, data generation." style="max-height: 22rem"/>

<div class="caption">From the source deck, slide 7</div>

</div>
<div>

**Open Systems Interconnection**: a model of how data gets from a program on one machine to a
program on another, cut into seven layers.

- Each layer does **one job**, and talks only to the layer above and below.
- A layer can be **changed** without touching the others: a new cable, the same programs.
- A layer can be hardware or software.
- The model **does nothing** itself; it is a way to sort the jobs every network must do.

Going down, each layer **wraps** the data in its own control information; going up, each layer
unwraps it again.

> For each layer we ask three questions: what is its job, what does CAN put there, and what is it
> in the meeting room?

</div>
</div>

<!--
Network engineers describe every network with the same model: OSI, Open Systems Interconnection.
It describes how data gets from a program running on one machine to a program running on another,
and it cuts that journey into seven layers. The picture from the source deck lists them, from the
physical layer at the bottom to the application at the top.

The rules on the right are what make the model useful. Each layer does one job, and it talks only
to its neighbors: the one above and the one below. So you can change one layer without touching
the others. Your laptop can move from a cable to Wi-Fi, and your browser does not notice. A layer
can be hardware, like a cable, or software. And the model itself does nothing; it is a way to sort
the jobs that every network has to do.

On the way down, at the sender, each layer wraps the data in its own control information: an
address, a length, a checksum. On the way up, at the receiver, each layer unwraps what its partner
layer added.

From now on, for each layer we ask the same three questions. What is its job? What does CAN put
there? And what is it in the meeting room from section 01? We go from the bottom up.
-->

---
routeAlias: osi-1-physical
---

## Layer 1 — Physical

<div class="grid grid-cols-3 gap-6">
<div>

### The job

Put **bits** on a medium: connectors, cable, voltage or light levels, timing, bit rate.

Data unit: the **bit**.

Elsewhere: an Ethernet cable and its RJ45 plug, a Wi-Fi radio, an optical fiber.

</div>
<div>

### In CAN

- A **twisted pair**, CAN_H and CAN_L
- **Dominant** = 0, driven; **recessive** = 1, not driven
- 500 kbit/s; **120 Ω** at each end
- A **transceiver** chip in every ECU (ISO 11898-2)

→ section 04

</div>
<div>

### In the room

- The **air** carries the sound
- A **clap** is 0, **silence** is 1; a clap drowns out silence
- Everyone keeps **the same pace**: the bit rate

The room stops here: it has no wires, no volts, no terminations.

</div>
</div>

<!--
Layer 1, physical. Its job is to put bits onto a medium. It defines the connectors, the cable, the
voltage or light levels that mean one and zero, the timing, and the bit rate. Its unit of data is
the single bit. Outside cars: an Ethernet cable with its RJ45 plug, the radio in a Wi-Fi card, an
optical fiber.

In CAN, layer 1 is the twisted pair of CAN high and CAN low. A zero is dominant: a transceiver
actively drives the two lines apart. A one is recessive: nobody drives, and the lines rest
together. The bit rate in a car is usually 500 kilobits per second, and the bus has a 120-ohm
resistor at each end. Every ECU has a transceiver chip that does this, defined in ISO 11898-2.
Section 04 shows it in detail.

In the meeting room, layer 1 is the air that carries the sound. A clap is a zero and silence is a
one, and a clap drowns out silence, just as one dominant transmitter overrides everyone else.
Everyone keeps the same pace, which is the bit rate. But here the room stops being useful: it has no
wires, no voltages, no terminations. For those we need the electrical picture.
-->

---
routeAlias: osi-2-data-link
---

## Layer 2 — Data link

<div class="grid grid-cols-3 gap-6">
<div>

### The job

Group bits into **frames**, decide **who may use** the medium, **detect errors**, and deliver to
the right node on the local link.

Data unit: the **frame**.

Elsewhere: an Ethernet frame with the receiver's hardware (MAC) address.

</div>
<div>

### In CAN — the heart of it

- The **frame**: identifier, length, data, CRC, ACK
- **Arbitration**: lowest identifier wins
- **Bit stuffing**, **error frames**, error counters
- **Filtering** by identifier, not by address
- All of it in the **CAN controller** silicon

→ sections 05 and 07

</div>
<div>

### In the room

The **speaking rules**:

- one clap to start; clap the topic number to decide who speaks
- never five equal beats in a row
- end with a check number; any listener **nods**
- garbled: shout **"STOP!"**; troublemakers collect **strikes**
- ignore topics you do not need

</div>
</div>

<!--
Layer 2, data link. Its job is to group bits into frames, to decide who may use the medium when
several want it, to detect transmission errors, and to deliver frames to the right node on the
local link. Its unit is the frame. In office Ethernet, a frame carries the hardware address of the
receiving network card, its MAC address.

For CAN this layer is the heart of the protocol. The frame with its identifier, length, data, CRC
and acknowledgement slot. Arbitration, where the lowest identifier wins. Bit stuffing, error
frames and the error counters. And filtering: a receiver keeps a frame because of its identifier,
not because of an address, and here CAN differs from the source deck's general description, which
mentions a destination address. CAN frames have none. All of this runs in the CAN controller, a
piece of silicon in every ECU, without any software involved. Sections 05 and 07 cover it.

In the room, layer 2 is the speaking rules from section 01. One clap to start, and clapping the
topic number to decide who speaks. Never five equal beats in a row, so everyone keeps the beat. A
check number at the end of each sentence, and any one listener nods. Anyone who heard it garbled
shouts "STOP!", and troublemakers collect strikes. And each listener ignores the topics they do not
need.
-->

---
routeAlias: osi-3-network
---

## Layer 3 — Network

<div class="grid grid-cols-3 gap-6">
<div>

### The job

**Addresses** across many networks, and **routing**: finding a path from one network to another.

Data unit: the **packet**.

Elsewhere: the IP address, and the routers that forward packets toward it.

</div>
<div>

### In CAN — empty

- One bus: **no addresses**, nothing to route
- Between buses, a **gateway** copies chosen messages, e.g. vehicle speed from the powertrain bus
  to the body bus
- The gateway decides by **meaning**, so it is really layer 7

</div>
<div>

### In the room

- One room: **nobody needs directions**
- Between two rooms, an **interpreter in the doorway** repeats chosen topics into the next room

</div>
</div>

<!--
Layer 3, network. Its job is addressing across many networks, and routing: finding a path from one
network to another. Its unit is the packet. On the internet, that is the IP address, and the
routers that forward each packet toward it, network by network.

In classic CAN this layer is empty. A bus is one network, there are no addresses, and there is
nothing to route. A car has several buses, joined by a gateway, which copies chosen messages from
one bus to another: the vehicle speed from the powertrain bus onto the body bus for the dashboard,
for example. But the gateway decides by what a message means, not by an address, so strictly it
works at layer 7.

In the room: one room, so nobody needs directions. Between two rooms, there is an interpreter in
the doorway who listens to one room and repeats chosen topics into the other.
-->

---
routeAlias: osi-4-transport
---

## Layer 4 — Transport

<div class="grid grid-cols-3 gap-6">
<div>

### The job

**Split** long data into pieces, put them back **in order**, control the **flow**, and confirm
**delivery** if asked.

Data unit: the **segment**.

Elsewhere: TCP, which confirms delivery; UDP, which does not. For a letter: the signed receipt.

</div>
<div>

### In CAN — mostly empty

- A signal fits in **8 bytes**: nothing to split
- Delivery is not confirmed to a receiver: the ACK says only that *someone* got it
- **Except diagnostics**: ISO-TP splits up to 4095 bytes into numbered frames, with flow control

→ section 09

</div>
<div>

### In the room

- Normal topics are **one sentence**: nothing to split
- A long report is told in **numbered installments**; the listener says *"go on, five more"*

</div>
</div>

<!--
Layer 4, transport. Its job is to split long data into pieces, to put the pieces back together in
the right order, to control the flow so a slow receiver is not flooded, and, if asked, to confirm
delivery. Its unit is the segment. On the internet, TCP confirms every piece, and UDP sends without
confirmation. The source deck's notes give the post office version: the signed receipt for a
letter is a transport-layer service.

In CAN this layer is mostly empty. A signal fits into the eight bytes of a frame, so there is
nothing to split. And delivery is not confirmed to any particular receiver: the acknowledgement
only says that someone received the frame correctly. The exception is diagnostics. A workshop
tester reads long blocks, such as the vehicle identification number or a whole fault memory, and
the ISO-TP protocol splits up to 4095 bytes into numbered frames, with flow control from the
receiver. Section 09 shows it.

In the room: a normal topic is one sentence, so there is nothing to split. A long report is told
in numbered installments, and the listener says "go on, five more" when ready.
-->

---
routeAlias: osi-5-session
---

## Layer 5 — Session

<div class="grid grid-cols-3 gap-6">
<div>

### The job

Open, keep and close a **dialogue**, which can outlive a single connection.

The source deck's example, by phone: open the session *"work on subject X"*; call, hang up to
search, call back; the session closes only when the problem is solved.

</div>
<div>

### In CAN — empty

- Normal traffic has **no dialogue**: topics are announced, not discussed
- **Except diagnostics**: UDS opens a *default*, *extended* or *programming* **session**, kept
  open by *"tester present"*

→ section 09

</div>
<div>

### In the room

- Normal topics: **no conversation**, just announcements
- A **private consultation**: *"the chair and I now discuss calibration"*, open as long as you keep
  saying *"still here"*

</div>
</div>

<!--
Layer 5, session. Its job is to open, keep and close a dialogue, and a dialogue can outlive a
single connection. The source deck explains it with a telephone. You and a colleague have to work
on subject X: that opens a session. Your colleague calls: a connection opens. You need to look
something up, so you hang up: the connection closes, but the session "work on subject X" is still
open. You call back: a new connection. You find the solution and hang up: now the connection and the
session both close.

In CAN this layer is empty for normal traffic. There is no dialogue: topics are announced, not
discussed. The exception is again diagnostics. A workshop tester opens a session with an ECU, the
default, an extended one for workshop functions, or a programming session for new software, and
keeps it open by sending "tester present" regularly. Section 09.

In the room: normal topics are announcements, not conversations. A private consultation with the
chair, "we now discuss calibration", is a session: it stays open as long as you keep saying "still
here".
-->

---
routeAlias: osi-6-presentation
---

## Layer 6 — Presentation

<div class="grid grid-cols-3 gap-6">
<div>

### The job

**How** values are written: encoding, number formats, units, compression, encryption.

Elsewhere: JPEG for pictures, UTF-8 for text, TLS encryption.

</div>
<div>

### In CAN — not in the standard

- The **DBC file** does the job: length, **factor**, **offset**, **byte order** of each signal
- **SecOC** adds a cryptographic code to frames that matter

→ section 06

</div>
<div>

### In the room

- The **agreed units**: "87" means km/h, with no decimals
- Everyone counts **in the same language**

</div>
</div>

<!--
Layer 6, presentation. Its job is how values are written down: the encoding, the number format,
the units, compression, encryption. Outside cars: JPEG for pictures, UTF-8 for text, the TLS
encryption behind the padlock in your browser.

The CAN standard does not define this layer at all. In practice the signal database, the DBC file,
does its job: for each signal, its length in bits, its factor and offset, and its byte order. And
in newer cars, SecOC adds a short cryptographic code to the frames that matter, which is the
encryption side of this layer. Section 06 covers it.

In the room: the agreed units. When someone says "vehicle speed: 87", everyone knows it means
kilometers per hour, with no decimals. And everyone counts in the same language.
-->

---
routeAlias: osi-7-application
---

## Layer 7 — Application

<div class="grid grid-cols-3 gap-6">
<div>

### The job

What the data **means** to the program that uses it.

Elsewhere: the web browser, the e-mail program.

</div>
<div>

### In CAN

- The car maker's **communication matrix**: which identifier is vehicle speed, who sends it, who
  receives it, how often
- Standard higher layers: **J1939** (trucks), **CANopen** (industry), **OBD-II** and **UDS**
  (diagnostics)

</div>
<div>

### In the room

The **agenda**: the list of topics with their numbers, who reports which topic, and how often.

</div>
</div>

<!--
Layer 7, application, at the top. Its job is what the data means to the program that uses it. On
your computer: the web browser, the e-mail program.

In CAN, this is the car maker's communication matrix: which identifier carries vehicle speed, which
ECU sends it, which ECUs receive it, and how often. Each car maker writes its own. There are also
standard application layers on top of CAN: J1939 for trucks and buses, CANopen for industrial
machines, and OBD-II and UDS for diagnostics, which we meet in section 09.

In the room, layer 7 is the agenda: the list of topics with their numbers, who reports which topic,
and how often.
-->

---
routeAlias: seven-layers
---

## All seven at a glance: three of them filled

| # | Layer | Its job | Classic CAN | Meeting room |
|---|---|---|---|---|
| 7 | Application | what the data means | signal definitions (DBC), J1939, CANopen, OBD-II, UDS | the **agenda**: topic 1A0h is vehicle speed |
| 6 | Presentation | how values are encoded | not defined; the DBC's factor, offset and byte order | the **agreed units**: "87" is km/h |
| 5 | Session | open and close a conversation | — (UDS sessions in diagnostics) | — (a private consultation) |
| 4 | Transport | split long data, confirm delivery | — (ISO-TP in diagnostics) | — (a long report in installments) |
| 3 | Network | addresses and routes | **— no addresses, no routes** | one room: no directions needed |
| 2 | Data link | frames, access, errors | frame, arbitration, stuffing, CRC, ACK, error frames, filtering | the **speaking rules** |
| 1 | Physical | bits on a medium | CAN_H/CAN_L, dominant and recessive, bit rate, termination | clap and silence, pace — **the room stops here** |

<div class="caption text-left">Layers 3 to 6 are empty because everyone is in one room speaking one
language · a gateway between two buses works at layer 7: an interpreter in the doorway</div>

<!--
Here are all seven layers again in one table, to keep as a summary.

Read the bold entries. CAN fills layer 1, the wires, layer 2, the frame and its rules, and layer 7,
the meaning of each identifier. Layers 3 to 6 are empty in normal traffic, because everyone is in
one room speaking one language. Layer 6's job is done by the DBC file, and layers 4 and 5 appear
only in diagnostics. A gateway between buses works on meaning, at layer 7: the interpreter in the
doorway.
-->

---
routeAlias: not-a-post-office
---

## CAN is not a post office

<div class="grid grid-cols-2 gap-8">
<div>

### The post office

- Every letter carries the **recipient's address** (layer 3).
- The post **routes** it to that one door.
- The recipient **signs for it** (layer 4): the sender knows *who* got it.
- Nobody else sees the letter.

</div>
<div>

### CAN

- A frame carries a **topic**, no address.
- It goes to **everyone**; each ECU decides whether to keep it.
- **Any** receiver acknowledges: the sender knows *someone* got it, not who.
- Every ECU sees every frame.

</div>
</div>

> If you picture CAN as letters between ECUs, you will look for a receiver address that does not
> exist.

<!--
One contrast, because most of you already carry this picture in your head. The post office is the
classic way to explain networks: a letter in an envelope, the envelope in a mail sack, the sack on
a truck.

On the left, what the post office does. Every letter carries the recipient's address, which is
layer 3. The post routes it to that one door. The recipient signs for it, which is layer 4's
confirmed delivery, so the sender knows exactly who got it. And nobody else sees the letter.

On the right, CAN does none of that. A frame carries a topic and no address. It goes to everyone,
and each ECU decides whether to keep it. Any receiver acknowledges it, so the sender learns that
someone got it, but not who. And every ECU sees every frame.

So if you picture CAN as letters between ECUs, you will look for a receiver address that does not
exist. Picture the meeting room instead.
-->

---
routeAlias: what-the-model-covers
---

## What our Dyad blocks model, layer by layer

| Layer | On a real bus | In the Dyad model |
|---|---|---|
| 7 Application | signal meaning | the signal you wire into a `CanTx` block, read from a `CanRx` |
| 6 Presentation | factor, offset, raw range | `scale`, `offset`, `raw_min`, `raw_max`: the value is rounded and clamped |
| 2 Data link — timing | a frame every period, then queuing | `period`: sampled every period, delivered one period late |
| 2 Data link — load | arbitration decides the order | `can_schedule`: bus load and worst-case response time, **calculated, not simulated** |
| 2 Data link — errors | error frames, error counters | **not modeled**; `check_can` checks the model's wiring, not the protocol |
| 1 Physical | volts, bits, termination | **not modeled** |

<div class="caption text-left">Each signal has its own slot on the model's bus, so no two frames
ever compete; that is why arbitration is calculated, not simulated</div>

<!--
Now the same layers for the model you build today. It is important to know what a model leaves
out before you trust its numbers.

At layer 7, you choose the signal: you wire it into a CanTx block at the sender and read it from a
CanRx block at the receiver. At layer 6, the block applies the message's scaling: a scale and an
offset, and a raw range. The value is rounded to the scale and clamped to the range, exactly as a
real message rounds it.

At layer 2, the model does the timing. Every message is sampled once per period and delivered one
period later. That is the late and the periodic from section 01. Arbitration, who goes first when
two frames want the bus, is not simulated. The function can_schedule calculates it instead: how
full the bus is, and how long each frame waits in the worst case. Errors are not modeled at all.
The function check_can catches mistakes in how you wired the model, not CAN protocol errors.

Layer 1, the electrical side, is not modeled.

The line at the bottom says why arbitration is calculated: in the model each signal has its own
slot on the bus, so two frames never actually compete.
-->
