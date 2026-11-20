---
routeAlias: osi-layers
layout: section
---

###### Section 03

# Layers

The OSI model, mapped onto CAN and onto the meeting room. CAN fills three of the seven layers.

<!--
Section 03: layers. Network engineers describe every network with the same seven-layer model, the
OSI model. We use it to sort what we have seen: each layer, what CAN puts there, and what the
meeting room puts there.
-->

---
routeAlias: seven-layers
---

## Seven layers, three of them filled

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
Here are the seven layers, read from the bottom up, because data goes down the layers at the
sender and up at the receiver.

Layer 1, physical, puts bits on a medium. For CAN that is the pair of wires, CAN high and CAN low,
the dominant and recessive levels, the bit rate and the terminations. In the room it is clapping,
silence and the pace everyone keeps. This is also where the analogy stops.

Layer 2, data link, is the heart of CAN: how a frame is built, who may send, how errors are caught
and how receivers filter. In the room these are the speaking rules from section 02.

Layers 3 to 6 are empty in classic CAN, and that is the point of the slide. Layer 3, network,
gives addresses and finds routes. CAN has no addresses, and on one bus there is nothing to route:
everyone is in one room. A gateway, which passes chosen messages from one bus to another, works on
the meaning of the messages, at layer 7. It is an interpreter in the doorway who repeats some
topics into the next room. Layer 4, transport, splits long data and confirms delivery; a CAN signal
fits in eight bytes, so normal traffic needs none. Diagnostics is the exception: a workshop tester
reads long blocks of data, and the ISO-TP protocol splits them into numbered pieces, like a long
report told in installments. Layer 5, session, is used only by diagnostics, which opens special
sessions with an ECU. Layer 6, presentation, says how values are encoded; CAN leaves that to the
signal database, the DBC, with its scaling and byte order.

Layer 7, application, is what the data means: which identifier is vehicle speed, in which unit.
In the room, that is the agenda that everyone agreed on before the meeting.
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
