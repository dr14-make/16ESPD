---
routeAlias: osi-layers
layout: section
---

###### Section 02

# The OSI model

The seven layers one by one, each mapped onto CAN and onto the meeting room. CAN fills three of them.

<!--
Section 02. A network has many jobs: moving bits, taking turns, checking for errors, giving the data
a meaning. Engineers sort these jobs into seven layers. This sorting is called the OSI model. We
take the layers one at a time and ask what CAN does there, and what the meeting room does there. You
will see that CAN fills only three of the seven.
-->

---
routeAlias: osi-model
---

## The OSI model

<div class="grid grid-cols-[1.5fr_1fr] gap-8 items-center">
<div>

<img src="/diagrams/02-osi-stack.svg" alt="The seven OSI layers as a stack, each with its job: 7 Application, what the data means; 6 Presentation, how values are written; 5 Session, open and close a dialogue; 4 Transport, split, order, confirm; 3 Network, addresses and routes; 2 Data link, frames, access, errors; 1 Physical, bits on a medium. Layers 1, 2 and 7 are shaded as the ones classic CAN fills. Beside the stack, the data on its way down: layer 4 adds header H4, layer 3 adds H3, layer 2 adds H2 and a trailer T2, and layer 1 sends the result as bits."/>

</div>
<div>

**Open Systems Interconnection**: a model of how data gets from a program on one machine to a
program on another, cut into seven layers.

- Each layer does **one job**, and talks only to the layer above and below.
- A layer can be **changed** without touching the others: a new cable, the same programs.
- A layer can be hardware or software.
- The model **does nothing** itself; it is a way to sort the jobs every network must do.
- Going down, each layer **wraps** the data in its own header; going up, it is unwrapped.

> For each layer we ask three questions: what is its job, what does CAN put there, and what is it
> in the meeting room?

</div>
</div>

<!--
OSI stands for Open Systems Interconnection. The model describes how data gets from a program on one
machine to a program on another, and it cuts that journey into seven layers. The picture on the left
stacks them, from layer 1, the physical layer, at the bottom, to layer 7, the application layer, at
the top. The shaded layers, 1, 2 and 7, are the ones CAN fills.

The bullets on the right explain why the model is useful. Each layer does one job and talks only to
the layer above and the layer below. So one layer can change without the others noticing. Your
laptop can switch from a cable to Wi-Fi, and your browser works as before. A layer can be hardware
or software. And the model itself does nothing. It is only a way to sort the jobs.

The right side of the picture shows the data on its way down at the sender. Each layer wraps the
data in its own control information, called a header. Layer 2 also adds a trailer at the end. Layer
1 then sends everything as bits. At the receiver, each layer unwraps what its partner added.

For each layer we now ask the three questions in the box. What is its job? What does CAN put there?
What is it in the meeting room? We start at the bottom.
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
Layer 1, the physical layer. Its job, in the left column, is to put bits on a medium. It defines the
cable, the connectors, the voltage or light level that means one or zero, and the bit rate. The bit
rate is the number of bits sent per second. Examples outside the car are an Ethernet cable, a Wi-Fi
radio and an optical fiber.

The middle column is CAN. The medium is the twisted pair, CAN high and CAN low. A zero is dominant:
an ECU actively drives the two wires. A one is recessive: nobody drives them. A typical bit rate in
a car is 500 kilobits per second, which is 500 thousand bits each second. Each end of the bus has a
120-ohm resistor. And every ECU has a small chip, the transceiver, that connects it to the two
wires. Section 04 covers all of this.

The right column is the room. The air carries the sound. A clap is a zero and silence is a one, and
a clap drowns out silence. Everyone keeps the same pace, which is the bit rate. And the room stops
here: it has no wires, no volts and no terminations.
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
Layer 2, the data link layer. Its job is to group bits into frames, to decide who may use the
medium, and to detect errors. Office Ethernet has this layer too. There, each frame carries the
hardware address of the receiver, called a MAC address.

The middle column says that this layer is the heart of CAN. It holds five things, and each has a
partner in the room on the right.

First, the frame: the identifier, the length, the data, a check number called the CRC, and the ACK.
In the room: one clap to start, a check number at the end, and the nod.

Second, arbitration, where the lowest identifier wins. In the room: clapping the topic number.

Third, bit stuffing. It keeps long runs of equal bits off the wire. In the room: after five equal
beats in a row, the speaker adds one opposite beat, so that everyone keeps the beat. Section 05
explains it.

Fourth, error frames and error counters. In the room: "STOP!" and the strikes.

Fifth, filtering by identifier. In the room: ignore the topics you do not need. CAN filters by
identifier, not by address. A CAN frame carries no address at all.

All of this runs inside a chip in every ECU, the CAN controller. Sections 05 and 07 give the
details.
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
Layer 3, the network layer. Its job is to give every machine an address that works across many
networks, and to find a route from one network to another. On the internet this is the IP address,
and the routers that pass each packet of data on toward it.

In CAN this layer is empty. One bus is one network. There are no addresses, and there is nothing to
route.

A car does have several buses, and they are joined by a gateway. A gateway is an ECU that is
connected to two buses and copies chosen messages from one to the other. The slide gives an example:
the vehicle speed is copied from the powertrain bus, the bus of the drive system, to the body bus,
the bus of lights, doors and dashboard. The gateway chooses by what a message means, not by an
address. So it really works at layer 7.

In the room: there is one room, so nobody needs directions. Between two rooms, an interpreter stands
in the doorway. The interpreter listens in one room and repeats chosen topics into the other.
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
Layer 4, the transport layer. Its job is to split long data into pieces, to put the pieces back in
the right order, to slow the sender down when the receiver is not ready, and to confirm delivery if
asked. On the internet a protocol called TCP does this. A protocol is an agreed set of rules. In the
post, the signed receipt for a letter is the same service.

In CAN this layer is mostly empty. A frame carries up to 8 bytes of data. A byte is a group of eight
bits, enough for a number from 0 to 255. A signal fits into those 8 bytes, so there is nothing to
split. And delivery is not confirmed to a particular receiver. The ACK only says that someone
received the frame.

There is one exception: diagnostics, when a workshop reads data out of the car. Those messages can
be long. A protocol called ISO-TP splits up to 4095 bytes into numbered frames, and the receiver
controls the pace. Section 09 shows it.

In the room: a normal topic is one sentence, so there is nothing to split. A long report is told in
numbered installments, and the listener says "go on, five more".
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
Layer 5, the session layer. Its job is to open, keep and close a dialogue. A dialogue can last
longer than one connection.

The left column explains this with a phone. You and a colleague agree to work on subject X. That
opens a session. Your colleague calls: that is a connection. You hang up to look something up. The
connection is gone, but the session is still open. You call back. Only when the problem is solved
does the session close.

In CAN this layer is empty for normal traffic. Topics are announced, not discussed, so there is no
dialogue.

The exception is again diagnostics. The workshop's diagnostic device is called the tester. It speaks
a protocol called UDS, Unified Diagnostic Services. With UDS the tester opens a session with one
ECU. There are three kinds: default, extended and programming. The tester keeps the session open by
regularly sending a message called "tester present". Section 09 comes back to it.

In the room: normal topics are announcements. A session is a private consultation with the chair of
the meeting. It stays open as long as you keep saying "still here".
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
Layer 6, the presentation layer. Its job is how values are written down: the number format, the
units, compression, encryption. Outside the car, think of JPEG for pictures, or the encryption
behind the padlock in your browser.

The CAN standard does not define this layer. In practice a file does the job: the DBC file, the
signal database of a bus. For each signal it lists the length in bits and three more things. The
factor and the offset turn the number in the frame into a physical value. The byte order says in
which order the bytes are sent. Section 06 explains each of them.

The second bullet is SecOC, Secure Onboard Communication. It adds a short code, made with a secret
key, to important frames. A receiver can then tell that the frame is genuine.

In the room, this layer is the agreed units. When someone says "vehicle speed: 87", everyone knows
that it means kilometers per hour, with no decimals. And everyone counts in the same language.
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
Layer 7, the application layer, at the top. Its job is what the data means to the program that uses
it. On your computer, that is the web browser or the e-mail program.

In CAN this is the car maker's communication matrix. It is the list that says which identifier
carries vehicle speed, which ECU sends it, which ECUs receive it, and how often. Every car maker
writes its own.

The second bullet lists ready-made standards for this layer. J1939 is used in trucks. CANopen is
used in industrial machines. OBD-II and UDS are used for diagnostics, and we meet them in section
09.

In the room, layer 7 is the agenda: the list of topics with their numbers, who reports each topic,
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
This table puts all seven layers on one slide. Keep it as your summary.

Read the fourth column, classic CAN, from the bottom. Layer 1 is filled: the two wires, dominant and
recessive, the bit rate, the termination. Layer 2 is filled: the frame and all its rules. Then look
at layers 3, 4 and 5. Each starts with a dash: they are empty in normal traffic. Layer 6 is not
defined by CAN; the DBC file does its job. Layer 7 is filled: the meaning of each identifier.

The caption says why the middle is empty: everyone is in one room and speaks one language. Layers 4
and 5 appear only in diagnostics, with ISO-TP and UDS. And a gateway between two buses works at
layer 7, like the interpreter in the doorway.

The last column is the meeting room again. At layer 1 it reminds you that the room stops there.

One more slide on this model, about a picture you may already have in your head.
-->

---
routeAlias: not-a-post-office
---

## CAN is not a post office

<div class="diagram-wide">

<img src="/diagrams/02-post-office.svg" alt="Left, the post office: a sender posts an envelope addressed To: ABS; it is delivered to the ABS only, the dashboard and the radio never see it, and the ABS signs a receipt back to the sender. Right, CAN: a sender puts a frame tagged 1A0h vehicle speed on one bus; the ABS, the dashboard, the radio and the seats all receive it; the ABS and the dashboard keep it, the others ignore it."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

### The post office

- The letter carries the **recipient's address** (layer 3) and is **routed** to that one door.
- The recipient **signs for it** (layer 4): the sender knows *who* got it.

</div>
<div>

### CAN

- A frame carries a **topic**, no address; it goes to **everyone**, each ECU decides.
- **Any** receiver acknowledges: the sender knows *someone* got it, not who.

</div>
</div>

> If you picture CAN as letters between ECUs, you will look for a receiver address that does not
> exist.

<!--
Networks are often explained with a post office: letters, addresses, receipts. For CAN that picture
is wrong, and this slide shows why.

On the left is the post office. The sender writes the recipient's address on the envelope: "To:
ABS". The post delivers it to that one door. The dashboard and the radio never see it. And the ABS
signs a receipt, so the sender knows exactly who got the letter. The address is a layer 3 job, and
the receipt is a layer 4 job.

On the right is CAN. The sender puts one frame on the bus, marked 1A0, vehicle speed. That is a
topic, not an address. The ABS, the dashboard, the radio and the seats all receive it. The ABS and
the dashboard keep it; the others ignore it. And any receiver acknowledges it. So the sender knows
that someone got the frame, but not who.

The box gives the consequence. If you picture CAN as letters between ECUs, you will look for a
receiver address, and there is none. Picture the meeting room.
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
The last slide of this section applies the layers to the Dyad model you build today. A model always
leaves things out, and you should know which before you trust its numbers. Read the table from the
top.

Layer 7: you choose the signal. You wire it into a block called CanTx at the sender, and you read it
from a block called CanRx at the receiver.

Layer 6: the block has a scale, an offset and a raw range. It rounds the value to the scale and
limits it to the range. Limiting is called clamping. A real message does the same.

Layer 2 has three rows. Timing: the block reads its input once per period and delivers the value one
period later. That gives you late and periodic. Load: on a real bus, arbitration decides the order
of the frames. The model does not simulate that. A function called can_schedule calculates the
result. Errors: not modeled. The function check_can checks how you wired the model. It does not
check the CAN rules.

Layer 1, the electrical side, is not modeled.

The caption explains why arbitration is only calculated. In the model, every signal has its own
place on the bus, called a slot. So two frames never compete.

That is the map. Next we look at the networks in real cars.
-->
