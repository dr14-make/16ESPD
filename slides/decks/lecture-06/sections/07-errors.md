---
routeAlias: errors
layout: section
---

###### Section 07

# Errors

The five error checks, the error frame, the error counters and bus-off; and what `check_can` catches
instead.

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
nobody made the ACK slot dominant.

Three checks belong to every receiver. The stuff error: six equal bits in a row in the stuffed part
of the frame. The CRC error: the receiver calculates the check number, and it differs from the one
in the frame. The form error: a bit that must always be recessive, such as a delimiter or the end of
frame, is dominant.

The caption says how good these checks are together. The chance that a damaged frame passes all five
unnoticed is below 4.7 times ten to the minus eleven. That is about one in twenty billion damaged
frames.

Next: what a node does when one of these checks fails.
-->

---
routeAlias: error-frame
---

## The error frame

<div class="grid grid-cols-2 gap-8">
<div>

1. A node detects an error and sends an **error flag**: **six dominant bits**.
2. Six equal bits break the stuffing rule, so **every other node** now detects an error too and
   sends its own flag: together 6 to 12 dominant bits.
3. An **error delimiter** of 8 recessive bits, then the intermission.
4. Every node **throws the frame away**; the sender **sends it again**.

</div>
<div>

- One node's doubt destroys the frame **for everyone**: all nodes keep the same data.
- The cost of one error: about 20 to 30 bit times plus the repeated frame.
- A node that is **error passive** sends six **recessive** bits instead: it can no longer destroy
  other nodes' frames (next slide).

</div>
</div>

<!--
This is the "STOP!" shout on the wire. Follow the four steps on the left.

One. A node detects an error and sends an error flag: six dominant bits in a row.

Two. Six equal bits break the stuffing rule. So every other node now detects an error as well and
sends its own flag. The flags overlap. Together the bus is dominant for 6 to 12 bits.

Three. Then come 8 recessive bits, the error delimiter, and the intermission.

Four. Every node throws the frame away, and the sender sends it again.

The whole sequence is called an error frame.

Now the right column. The first bullet is the rule from the room: when one node doubts the frame, it
is destroyed for everyone. So all nodes always hold the same data. The second bullet is the cost:
one error takes about 20 to 30 bit times, plus the time to repeat the frame. That is little, but it
needs free time on the bus. We come back to that in section 08.

The last bullet is the whisper. A node in the state error passive sends six recessive bits as its
flag. Recessive bits change nothing on the bus. So that node can no longer destroy the frames of
others. The next slide shows how a node gets into that state.
-->

---
routeAlias: fault-confinement
---

## Error counters and bus-off

<div class="grid grid-cols-[1fr_1.6fr] gap-8 items-center">
<div>

Each node keeps two counters:

| Event | TEC | REC |
|---|---:|---:|
| error while **sending** | **+8** | |
| error while **receiving** | | **+1** (mostly) |
| frame sent correctly | −1 | |
| frame received correctly | | −1 |

<div class="caption text-left">TEC: transmit error counter · REC: receive error counter</div>

</div>
<div>

<img src="/diagrams/07-error-states.svg" alt="State diagram of a CAN node. Error active: normal, error flag of 6 dominant bits. When TEC or REC exceeds 127 it moves to error passive: error flag of 6 recessive bits, waits 8 extra bits before sending. When both are back at 127 or below it returns to error active. When TEC exceeds 255 it moves to bus off: sends nothing, acknowledges nothing. From bus off it returns to error active after 128 times 11 recessive bits, with both counters back at 0."/>

</div>
</div>

<!--
These are the strikes, with exact numbers. Each node keeps two counters. TEC is the transmit error
counter. REC is the receive error counter.

The table on the left gives the rules. An error while sending adds 8 to TEC. An error while
receiving adds 1 to REC in most cases. Each frame sent correctly takes 1 off TEC, and each frame
received correctly takes 1 off REC. So an error while sending counts eight times as much. That is
fair: a node that fails while it is sending is the most likely cause of the fault.

The diagram on the right shows the three states. A node starts as error active. It works normally,
and its error flag is six dominant bits. When TEC or REC goes above 127, the node becomes error
passive. Its error flag is now six recessive bits, and it waits 8 extra bits before it sends again.
When both counters are back at 127 or below, it returns to error active.

When TEC goes above 255, the node goes bus off. It sends nothing and acknowledges nothing. This need
not last forever. The arrow back says: after 128 times 11 recessive bits on the bus, the node may
return to error active, with both counters at zero.

So a broken node takes itself off the bus, and the other nodes keep working. In the room: strikes,
whisper, leave the room.
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
| A broken ECU floods the bus at high priority | it wins every arbitration | rare; transceivers limit how long a node can hold the bus dominant |
| Someone **forges** a frame | anyone may send any identifier | gateways filter; **SecOC** authenticates |

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

Row four. A broken ECU floods the bus with a high-priority frame. It wins every arbitration, and the
others cannot send. This is rare, and transceivers limit how long one node can hold the bus
dominant.

Row five. Someone forges a frame. On CAN, anyone may send any identifier. So gateways filter what
passes from one bus to another, and SecOC proves that a frame is genuine.

All these defenses sit in the software of the ECUs, above the CAN rules.
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
