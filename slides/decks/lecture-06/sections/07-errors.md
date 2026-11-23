---
routeAlias: errors
layout: section
---

###### Section 07

# Errors

The five error checks, the error frame, the error counters and bus-off, what CAN cannot see, and
what `check_can` catches instead.

<!--
Section 07, errors. In section 01, a listener shouted "STOP!", and troublemakers collected strikes.
Now we see how CAN really does both. At the end comes a warning: the check in our model tests
something else.
-->

---
routeAlias: five-checks
---

## Five checks

| Error | Checked by | Detected when |
|---|---|---|
| **Bit** | the sender | it reads back a different bit than it sent (outside arbitration and the ACK slot) |
| **Stuff** | every receiver | six equal bits in a row inside the stuffed part of the frame |
| **CRC** | every receiver | the CRC it computes differs from the one received |
| **Form** | every receiver | a fixed bit is wrong: a delimiter or the end of frame is dominant |
| **Acknowledgement** | the sender | nobody drove the ACK slot dominant |

<div class="caption text-left">Residual error probability: below 4.7 × 10<sup>−11</sup> times the
rate of corrupted frames (Bosch CAN 2.0 specification)</div>

<!--
CAN checks every frame in five ways. The table lists them, with who checks and when the error is
detected.

Two checks belong to the sender. The first row is the bit error. The sender reads back every bit. If
it reads a different bit than it sent, that is an error. There are two exceptions: during
arbitration and in the ACK slot, a difference is normal. The last row is the acknowledgement error:
nobody made the ACK slot dominant, logic zero.

Three checks belong to every receiver. The stuff error: six equal bits in a row in the stuffed part
of the frame. The CRC error: the receiver calculates the check number, and it differs from the one
in the frame. The form error: a bit that must always be recessive, such as a delimiter or the end of
frame, is dominant, logic zero, instead of recessive, logic one.

The caption says how good these checks are together. The chance that a damaged frame passes all five
unnoticed is below 4.7 times ten to the minus eleven. That is about one in twenty billion damaged
frames.

Next: what a node does when one of these checks fails.
-->

---
routeAlias: error-frame
---

## The error frame

<div class="diagram-wide">

<img src="/diagrams/07-error-frame.svg" style="max-height: 14rem" alt="Timeline of the bus, low dominant, logic 0, high recessive, logic 1. A frame runs, then is cut off where one node detects an error. That node sends 6 dominant bits, its error flag. The other nodes see six equal bits, a stuff error, and send their own flags, up to 6 more dominant bits, so the bus is dominant for 6 to 12 bits. Then 8 recessive bits, the error delimiter, and 3 recessive bits of intermission; then the sender starts the frame again with a start of frame. A bracket marks the error frame and intermission: 17 to 23 bit times."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

1. A node detects an error and, **on the next bit**, wherever it is in the frame, sends an
   **error flag**: **six dominant bits** (0). Only a **CRC error** waits until after the ACK
   delimiter.
2. Six equal bits break the stuffing rule, so **every other node** now detects an error too and
   sends its own flag: together 6 to 12 dominant bits.
3. An **error delimiter** of 8 recessive bits, then the 3-bit intermission.
4. Every node **throws the frame away**; the sender **sends it again**.

</div>
<div>

- One node's doubt destroys the frame **for everyone**: all nodes keep the same data.
- The cost of one error: **17 to 23 bit times** plus the repeated frame.
- A node that is **error passive** sends six **recessive** bits instead: it can no longer destroy
  other nodes' frames (next slide).

</div>
</div>

<!--
This is the "STOP!" shout on the wire. The picture shows the bus as a timeline. Low is dominant,
logic zero; high is recessive, logic one. Follow the four steps on the left along it.

One. A node detects an error, at the dashed line. It does not wait for the frame to end. On the
very next bit, wherever that is in the frame, it sends an error flag: six dominant bits in a row.
The frame is cut off there. This holds for four of the five checks from the last slide: the bit,
stuff, form and acknowledgement errors. The CRC error is the exception. A receiver knows that the
check number is wrong only once the whole CRC has arrived. The standard then lets the
acknowledgement field pass first: after a CRC error, the flag starts on the bit after the ACK
delimiter.

Two. Six equal bits break the stuffing rule. So every other node now detects an error as well and
sends its own flag. The flags overlap. If all nodes notice at once, the bus is dominant for 6 bits.
If the others notice only at the end of the first flag, their flags follow it, and the bus is
dominant for 12 bits. The picture shows that longest case.

Three. Then come 8 recessive bits, the error delimiter, and the 3 recessive bits of the
intermission.

Four. Every node throws the frame away, and the sender sends it again. On the right of the picture
it starts over with a start of frame.

The whole sequence, from the flag to the end of the delimiter, is called an error frame.

Now the right column. The first bullet is the rule from the room: when one node doubts the frame, it
is destroyed for everyone. So all nodes always hold the same data. The second bullet is the cost.
Add it up from the picture: 6 to 12 flag bits, 8 delimiter bits and 3 intermission bits. That is 17
to 23 bit times, plus the time to repeat the frame. That is little, but it needs free time on the
bus. We come back to that in section 08.

The last bullet is the whisper. A node in the state error passive sends six recessive bits as its
flag. Recessive bits change nothing on the bus. So that node can no longer destroy the frames of
others. The next slide shows how a node gets into that state.
-->

---
routeAlias: fault-confinement
---

## Error counters and bus-off

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div class="tight">

| Event | TEC | REC |
|---|---:|---:|
| error while **sending** | **+8** | |
| error while **receiving** | | **+1** |
| a dominant bit right after the receiver's **own** flag | | **+8** more |
| frame sent / received without error | −1 | −1 |

| Who saw the error | Flags (last slide's picture) | Counters |
|---|---|---|
| **every** receiver at once: noise all of them see | overlap: **6** dominant bits | sender +8, each receiver +1 |
| **one** receiver alone: its own fault | staggered: up to **12** | that receiver **+1 +8**, the others +1, sender +8 |

</div>
<div>

<img src="/diagrams/07-error-states.svg" alt="State diagram of a CAN node. Error active: normal, error flag of 6 dominant bits, logic 0; when TEC or REC reaches 96 it warns the ECU's software but stays error active. When TEC or REC reaches 128 it moves to error passive: error flag of 6 recessive bits, logic 1, waits 8 extra bits before sending. When TEC and REC are both back below 128, falling by 1 per good frame, it returns to error active. When TEC reaches 256 it moves to bus off: sends nothing, acknowledges nothing. From bus off it returns to error active once it has listened to 128 frame ends, 128 times 11 consecutive recessive bits, with both counters reset to 0."/>

</div>
</div>

<div class="caption text-left">TEC: transmit error counter · REC: receive error counter · ≥ 96: a
warning only · 11 recessive bits = ACK delimiter 1 + end of frame 7 + intermission 3, the end of
every frame; 128 × 11 = 1408 bit times, at least 2.8 ms at 500 kbit/s · many controllers start the
recovery only when software asks; in AUTOSAR the CAN state manager (CanSM) does · Bosch CAN 2.0,
Part A, ch. 7</div>

<!--
These are the strikes, with exact numbers. Each node keeps two counters. TEC is the transmit error
counter. REC is the receive error counter.

The first table gives the rules. An error while sending adds 8 to TEC. An error while receiving adds
1 to REC. The third row is the special case: a receiver sends its error flag, and the very next bit
is still dominant. Then it adds 8 more. Each frame sent without error takes 1 off TEC, and each
frame received without error takes 1 off REC.

Why the special case? The second table explains it, with the picture from the last slide, the 6 or
12 dominant bits.

Row one: noise that every receiver sees. All receivers detect the error at the same bit and send
their flags together. The flags overlap, and the bus is dominant for only 6 bits. When a receiver's
flag ends, the bus goes recessive at once. So each receiver adds 1, and the sender adds 8.

Row two: one receiver sees an error that nobody else sees, for example because its own clock or its
own transceiver is bad. It sends its flag alone. The others notice only the six equal bits of that
flag, and answer with their own flags right after it. That is the staggered case, up to 12
dominant bits. When the lonely receiver's flag ends, the bus is still dominant, because the others
are still shouting. That dominant bit is the special case: the lonely receiver adds 1 and then 8
more, 9 in all. The other receivers add only 1. The sender still adds 8, because it sent an error
flag; the rules cannot tell that the fault was not its own.

That is how CAN finds the troublemaker. The lonely receiver collects 9 per error, the sender 8, the
others 1. If both start at zero, after 15 such errors the lonely receiver is at 135 and turns error
passive, while the sender is at 120 at most and stays error active. From then on the troublemaker
only whispers, and the frames get through again. And if the sender itself is the one with the fault,
its own plus 8 per failed frame takes care of it.

The diagram on the right shows the three states. A node starts as error active. It works normally,
and its error flag is six dominant bits, logic zero. When TEC or REC reaches 96, nothing changes on
the bus yet. The CAN controller only raises a warning to the software of its ECU, the host. It is a
yellow card: the software can log a fault before things get worse. When TEC or REC reaches 128, the
node becomes error passive. Its error flag is now six recessive bits, logic one, and it waits 8
extra bits before it sends again. The dashed arrow back: TEC and REC both fall by 1 per good frame,
and when both are below 128, the node is error active again. One detail: a receive counter above
127 drops straight back to between 119 and 127 after one good frame.

When TEC reaches 256, the node goes bus off. It sends nothing and acknowledges nothing. This need
not last forever. The long arrow back says: once the node has listened to 128 frame ends, its
counters are reset to zero and it is error active again. The caption explains what a frame end
means here. Every frame ends with 11 recessive bits in a row: the ACK delimiter, 1 bit, the end of
frame, 7 bits, and the intermission, 3 bits. Nowhere else in a correct frame are there 11 recessive
bits in a row, because of bit stuffing. So the node counts 128 times 11 recessive bits, 1408 bit
times. At 500 kilobits per second a bit takes 2 microseconds, so that is 2.8 milliseconds if the bus
is idle. With traffic it is 128 frames, which takes longer.

The last part of the caption is how real ECUs do it. Many CAN controllers do not start this
recovery on their own. They wait until the software tells them to. In AUTOSAR, the standard
software architecture of most ECUs, a module called the CAN state manager handles this. It restarts
the controller, keeps the node's own messages off the bus for a configured time, and if the node
keeps going bus off, it switches to a longer wait.

So a broken node takes itself off the bus, and the other nodes keep working. In the room: strikes,
whisper, leave the room.
-->

---
routeAlias: tec-over-time
layout: default
class: big-figure
---

## The transmit counter over time

<img src="/figures/07-tec.svg" alt="Transmit error counter TEC of one sending node against transmission attempts, with horizontal lines at 96, the warning level, 128, error passive, and 256, bus off. A node with a permanent fault fails every send, so TEC climbs by 8 per attempt and crosses all three lines, reaching bus off after 32 failures. A node with an intermittent fault fails now and then: each failure adds 8, each success takes 1 off, and TEC hovers at a low level without reaching the lines."/>

<div class="caption">TEC of one sender: +8 per failed send, −1 per good one · lines at 96 (warning), 128
(error passive), 256 (bus off) · a permanent fault reaches bus off after 32 failures</div>

> A node with a **real fault** takes itself off the bus; a node with an **occasional** error stays on
> it.

<!--
This plot follows the transmit error counter, TEC, of one sending node over time. To the right are
its attempts to send, one after the other. Up is the counter. The three horizontal lines are the
levels from the last slide: 96, where the controller warns its software; 128, where the node becomes
error passive; and 256, where it goes bus off.

The first line is a node with a permanent fault, for example a broken transceiver. Every send fails.
Each failure adds 8, so the counter climbs in a straight line. It passes the warning, then error
passive. After 32 failures it reaches 256, and the node goes bus off. 32 times 8 is 256.

The second line is a node with an intermittent fault: it fails now and then, for example from a loose
connector. Each failure adds 8. But every good frame takes 1 off. As long as there are many more good
frames than bad ones, the counter goes up and down and hovers low. The node stays on the bus.

That is the point of the box. The rule plus 8, minus 1 sorts the nodes for us. A node with a real
fault removes itself, and quickly. A node that only has bad luck now and then keeps working. In the
room: three strikes and you leave, but a strike now and then is forgiven.
-->

---
routeAlias: what-can-does-not-catch
---

## What CAN does not catch

| Fault | Why CAN cannot see it | What the car does |
|---|---|---|
| A sender goes **silent** | no frame, no error | **timeouts** in every receiver (section 05) |
| A sender repeats a **stale** value | the frames are valid | **counters** (section 06) |
| A sensor sends a **wrong** value | the frame is valid | **plausibility** checks against other signals |
| A broken ECU **floods** the bus at high priority | it wins every arbitration, and every frame is valid | nothing in the protocol; gateways limit rates, a bus guardian can cut the node off |
| Someone **forges** a frame | anyone may send any identifier | gateways filter; **SecOC** authenticates (next slide) |

<!--
The five checks protect a frame on the wire. They cannot see everything. Each row of this table is a
fault that CAN does not see, with what the car does about it.

Row one. A sender goes silent. No frame means no error. So every receiver uses a timeout, from
section 05.

Row two. A sender repeats an old value. The frames are valid. The counter from section 06 reveals
it.

Row three. A sensor sends a wrong value in a valid frame. The receiver compares the value with other
signals to see whether it is believable. That is a plausibility check. The ESP from Lecture 3, for
example, compares the measured yaw rate with what the steering angle and the speed predict.

Row four. A broken ECU floods the bus with a high-priority frame, one valid frame after another. It
wins every arbitration, and the others cannot send. The CAN rules have no defense against this: every
frame is correct, so no error counter rises. The defense sits outside the protocol. A gateway, the ECU
that connects two buses, passes only so many frames per second from one bus to the other. And a bus
guardian, a small circuit next to the transceiver, can cut off a node that sends far more than its
schedule allows. Careful: transceivers do have a time-out for a line that is stuck dominant, but it
only stops one endless dominant level. It does not stop a node that floods the bus with valid
frames.

Row five. Someone forges a frame. On CAN, anyone may send any identifier. So gateways filter what
passes from one bus to another. And SecOC, Secure Onboard Communication from the AUTOSAR software
standard, proves that a frame is genuine. The next slide is about this row.

Almost all these defenses sit in the software of the ECUs, above the CAN rules.
-->

---
routeAlias: security
---

## No locks on the bus

<div class="grid grid-cols-2 gap-8">
<div>

### The weakness

- Any node may send **any identifier**. A receiver cannot tell **who** sent a frame.
- One ECU that is reachable from outside, through the radio, the phone link or the OBD socket, can
  speak for all of them.
- **2015, Jeep Cherokee**: researchers reached the infotainment unit over the mobile network, then
  sent CAN frames to the brakes, the steering and the engine, from miles away. 1.4 million cars were
  recalled.

</div>
<div>

### The answers

- **Gateways** split the car into domains and pass only the frames each domain needs.
- **SecOC** (Secure Onboard Communication, AUTOSAR): the sender adds a short code computed with a
  secret key, plus a counter so an old frame cannot be replayed. A frame without the right code is
  dropped.
- **UNECE R155**: since July 2024 every new car sold in the EU needs a certified cybersecurity
  management system.

</div>
</div>

<div class="caption text-left">Miller and Valasek, "Remote Exploitation of an Unaltered Passenger
Vehicle" (2015) · UN Regulation No. 155 on cyber security and cyber security management systems</div>

<!--
Row five of the last table deserves its own slide, because it was not a problem when CAN was
designed. In the 1980s, a car's ECUs were a closed group of boxes, and nobody from outside could
reach the bus.

The left column is the weakness. Any node may send any identifier. A frame carries no name of its
sender, so a receiver cannot tell who sent it. In the room: everyone recognizes the topic of a
message, but nobody checks the speaker's face.

Today some ECUs talk to the outside world: the radio and navigation unit, the phone link, the
diagnostic socket. If an attacker takes over one of them, that ECU can send any frame onto the bus.

The third bullet shows that this is not theory. In 2015, two researchers, Charlie Miller and Chris
Valasek, attacked a Jeep Cherokee over the mobile phone network. They reached its infotainment unit,
the radio and navigation box, and from there sent CAN frames, while sitting miles away. On a
highway they cut the engine's power of the car while a journalist drove it. In a parking lot they
disabled the brakes and turned the steering wheel. The car maker recalled 1.4 million cars to fix
it.

The right column is the answer. First, gateways. The car's buses are split into domains, for
example infotainment and chassis, and a gateway between them passes only the frames that each side
needs. A radio has no business sending brake frames.

Second, SecOC, Secure Onboard Communication, part of the AUTOSAR software standard. The sender
calculates a short code from the data and a secret key that only the right ECUs know. It also adds
a counter, so that an attacker cannot simply record an old frame and send it again later. The
receiver calculates the code again. A frame without the right code is dropped. The price is bytes:
the code and the counter take part of the 8 data bytes.

Third, the law. The United Nations regulation R155 requires every car maker to run a certified
cybersecurity management system. In the EU it applies to every new car sold since July 2024.

So the bus itself stays as it is. Security is added on top, in the gateways and in the software.
-->

---
routeAlias: check-can
---

## `check_can` checks the model, not the protocol

The model has no error frames and no counters. What can go wrong is **how the model is wired**, and
the compiler's messages for that are cryptic. `check_can(model)` runs first and says it plainly:

| Mistake | `check_can` says |
|---|---|
| no `CanTermination` on a bus | the bus containing … needs a CanTermination |
| two transmitters on one slot | … and … both transmit on slot 3 |
| a receiver on a slot nobody sends | … receives slot 5, but nobody transmits on it |
| one identifier with two periods | identifier 128 has two periods |
| more than 8 bytes in one identifier | identifier … exceeds the classic CAN eight-byte payload |

<div class="handson">Build 02 starts here: a starter with one of these mistakes in it.</div>

<!--
Now the warning. The model you build has no error frames and no error counters. Its bus never
damages a bit. What can go wrong is how you wire the model. The compiler is the program that
translates your model, and its messages for these mistakes are hard to read. So there is a function,
check_can. You run it first, and it names the mistake in plain words.

The table lists what it finds. A bus without a CanTermination block. Two transmitters on one slot. A
receiver on a slot where nobody transmits. One identifier with two different periods. And more than
8 bytes under one identifier, which a classic CAN frame cannot carry.

Be careful with the name CanTermination. It is a block that every bus in the model needs. It is not
the 120-ohm resistor from section 04.

None of these are CAN errors like the five checks. A real bus would not send an error frame for any
of them. They are mistakes in the model. Some match design mistakes in a real network, for example
two ECUs that claim the same identifier.

The green box: build 02 starts here, with a model that contains one of these mistakes.
-->
