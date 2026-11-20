---
routeAlias: errors
layout: section
---

###### Section 07

# Errors

The five error checks, the error frame, the error counters and bus-off; and what `check_can` catches
instead.

<!--
Section 07: errors. The real mechanism behind the "STOP!" shout and the strikes from section 01.
Then a warning: the model checks something different, and you should not confuse the two.
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
CAN checks every frame five ways. Two checks are done by the sender, three by every receiver.

The sender reads back every bit it sends. If it reads something different, outside arbitration and
the acknowledgement slot, where a difference is normal, that is a bit error. The sender also checks
that someone acknowledged: if the ACK slot stays recessive, that is an acknowledgement error.

Every receiver counts equal bits. Six in a row inside the stuffed part cannot happen in a correct
frame, from section 05: stuff error. Every receiver computes the CRC over what it received and
compares: CRC error. And every receiver checks the bits that always have the same value, the
delimiters and the end of frame: form error.

The caption gives the result. The Bosch specification puts the probability that a corrupted frame
slips through all five checks below 4.7 times ten to the minus eleven, times the rate at which frames
get corrupted: roughly one in twenty billion corrupted frames.
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
Here is the "STOP!" shout on the wire. A node that detects an error sends an error flag: six
dominant bits in a row. That breaks the stuffing rule on purpose, so every other node now sees a
stuff error, if it had not seen an error already, and sends its own flag. The flags overlap, so the
bus is dominant for six to twelve bits. Then eight recessive bits, the error delimiter, and the
usual three bits of intermission. Every node throws the frame away, and the sender sends it again,
arbitrating like any other frame.

The right column: one node's doubt destroys the frame for all, so all nodes always hold the same
data. The price of one error is short, about twenty to thirty bit times plus the repeated frame,
which is why section 08 keeps a margin on the bus load.

And the last line leads to the next slide. A node with too many errors may only send a passive error
flag, six recessive bits. Recessive bits change nothing on the bus, so that node can no longer
destroy anyone else's frame. That is the whisper from the meeting room.
-->

---
routeAlias: fault-confinement
---

## Error counters and bus-off

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
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

| State | When | Behavior |
|---|---|---|
| **Error active** | TEC and REC ≤ 127 | normal; active error flags (six dominant) |
| **Error passive** | TEC or REC > 127 | passive error flags (six recessive); waits 8 extra bits before sending again |
| **Bus off** | TEC > 255 | takes no part in the bus at all |

From bus off, a node may come back after it has seen **128 × 11 recessive bits**: the bus has been
quiet and healthy long enough. Counters restart at zero.

</div>
</div>

<!--
Here are the strikes, exactly. Each node keeps two counters: the transmit error counter, TEC, and
the receive error counter, REC. An error while sending adds eight to TEC. An error while receiving
mostly adds one to REC. Every correct frame takes one off again. So a sender pays eight times more
for its errors than a receiver, which makes sense: if the fault is in one node, it is most likely
the one sending when errors happen.

On the right, the three states. While both counters stay at 127 or below, the node is error active:
it works normally and sends active error flags. When either counter passes 127, it becomes error
passive: its error flags are recessive, so it cannot destroy other frames, and after sending it
waits eight extra bits, so healthy nodes get the bus first. When TEC passes 255, the node goes bus
off: it neither sends nor acknowledges.

That is not necessarily forever. The standard lets a node return after it has seen 128 times 11
consecutive recessive bits, proof that the bus has been quiet and healthy for a while; its counters
then restart at zero. Some ECUs wait for their software to allow the restart. Either way, a broken
node takes itself off the bus instead of jamming it for everyone.
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
CAN's error handling is strong, but it only protects frames on the wire. This table is what it
cannot see, and what the car does instead.

A sender that goes silent produces no frame and therefore no error. Every receiver needs a timeout,
section 05. A sender that keeps repeating a stale value sends valid frames; counters reveal it,
section 06. A sensor that measures nonsense sends a perfectly valid frame; the receiving ECU checks
it against other signals. The ESP from Lecture 3 compares the yaw rate with what the steering angle
and speed predict, for example.

A broken ECU that floods the bus with a high-priority identifier wins every arbitration and starves
everyone else. It is rare, and transceivers at least stop a node from holding the bus dominant
forever. And anyone on the bus may send any identifier, including an attacker with access to the
diagnostic socket or a hacked infotainment unit. Gateways filter what passes between buses, and
SecOC authenticates the frames that matter.
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
Now the warning I promised. The model you build has no error frames and no error counters. Its bus
never corrupts a bit. What can go wrong in the model is how you wire it, and the compiler's messages
for those mistakes are cryptic: "structurally singular", or an undefined variable with a strange
name.

So the course library has a function, check_can, that inspects the model before it compiles and
says in plain words what is wrong. The table lists the mistakes it catches. A bus without its one
termination block. Two transmitters on the same slot of the model's bus. A receiver reading a slot
that nobody sends on. One identifier given two different periods. And more than eight bytes packed
into one identifier, which classic CAN cannot carry.

Notice that these are not CAN protocol errors; a real bus would show none of them as error frames.
They are modeling mistakes, some of which correspond to design mistakes in a real network, such as
two ECUs claiming the same identifier.

Build 02 starts from a model with one of these mistakes in it.
-->
