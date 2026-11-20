---
routeAlias: frame-and-arbitration
layout: section
---

###### Section 05

# Frame and arbitration

The fields of a frame, bit stuffing, the arbitration example on the wire, and the acknowledgement.

<!--
Section 05: the frame and arbitration. We take one data frame apart field by field, see the bit
stuffing rule that keeps the clocks together, replay the clapping example as voltages on the bus,
and finish with the acknowledgement.
-->

---
routeAlias: data-frame
---

## The data frame

<img src="/diagrams/05-data-frame.svg" class="w-full" alt="Classic CAN base data frame as a row of fields, left to right, with each field's bits and level: bus idle; start of frame, 1 bit, dominant; identifier, 11 bits, and RTR, 1 bit, dominant, together the arbitration field; IDE and r0, 1 bit each, dominant, and DLC, 4 bits, the control field; data, 0 to 64 bits, 0 to 8 bytes; CRC, 15 bits, and its delimiter, 1 recessive bit; ACK slot, sent recessive and driven dominant by the receivers, and ACK delimiter, recessive; end of frame, 7 recessive bits; intermission, 3 recessive bits; bus idle. A bracket marks start of frame to the end of the CRC, 34 plus 8n bits, as stuffed; the rest is fixed form, never stuffed. In all, 47 plus 8n bits for n data bytes before stuffing."/>

<div class="caption">Redrawn from the source deck, slide 26, with the 3-bit intermission</div>

<div>

| Field | Bits | Job |
|---|---:|---|
| Start of frame | 1 | one dominant bit; every node hard-synchronizes on its edge |
| Identifier + RTR | 11 + 1 | the topic, and the priority in arbitration; RTR dominant = data frame |
| IDE, r0, DLC | 1 + 1 + 4 | base format, reserved, and the number of data bytes (0–8) |
| Data | 0–64 | the signals |
| CRC + delimiter | 15 + 1 | checksum over everything before it |
| ACK slot + delimiter | 1 + 1 | the sender leaves it recessive; **any** correct receiver drives it dominant |
| End of frame, intermission | 7 + 3 | recessive; the 3-bit gap before the next frame may start |

</div>

<!--
Here is a classic CAN data frame in the base format, with an 11-bit identifier.

It starts with one dominant bit, the start of frame. Its edge is where every node hard-synchronizes.
Then the arbitration field: the 11-bit identifier, our topic number, and the RTR bit, which is
dominant for a data frame. Then the control field: the IDE bit, dominant for the base format, a
reserved bit, and four bits of data length code, which say how many data bytes follow, from zero to
eight.

Then the data, up to 64 bits. Then a 15-bit CRC, a checksum computed over everything before it,
with a recessive delimiter. Then the acknowledgement slot, which we look at at the end of this
section. Seven recessive bits end the frame, and three more recessive bits, the intermission, must
pass before anyone may start the next frame.

Count it up for eight data bytes: 108 bits from start of frame to end of frame, plus three of
intermission, plus the stuff bits from the next slide. Only 64 of those bits are your data, a bit
more than half.
-->

---
routeAlias: frame-variants
---

## Other formats and other frames

<div class="grid grid-cols-2 gap-8">
<div>

### Extended format

- **29-bit identifier**: the 11 base bits, then SRR and IDE (both recessive), then 18 more bits.
- Common in trucks (SAE J1939), rare in passenger-car powertrain buses.
- An 11-bit frame beats a 29-bit frame with the same first 11 bits.

</div>
<div>

### Four kinds of frame

| Frame | Sent by | When |
|---|---|---|
| **Data** | the owner of the signal | periodically or on change |
| **Remote** | a node that wants data | rarely used in cars |
| **Error** | any node | it detected an error (section 07) |
| **Overload** | a receiver | asks for a delay before the next frame; modern controllers almost never send it |

</div>
</div>

<!--
Two more things about frames.

On the left, the extended format. When eleven bits are not enough identifiers, a frame can carry 29.
After the first eleven bits come two recessive bits, SRR and IDE, then eighteen more identifier bits.
Trucks use it, in the SAE J1939 standard; passenger-car buses mostly use eleven bits. Because SRR
and IDE are recessive where a base frame has dominant bits, a base frame wins arbitration against an
extended frame that starts with the same eleven bits.

On the right, the four kinds of frame. Data frames carry the signals; almost all traffic is data
frames. A remote frame asks another node to send its data; cars rarely use it, because the data is
sent periodically anyway. An error frame is the "STOP!" shout; section 07 covers it. An overload
frame lets a receiver ask for a short delay before the next frame. Modern controllers are fast
enough that they practically never send one.
-->

---
routeAlias: bit-stuffing
---

## Bit stuffing

After **five equal bits** in a row, the sender inserts **one opposite bit**; the receivers remove it.
From the start of frame to the end of the CRC only.

<img class="w-full" style="max-height: 14rem" src="/diagrams/05-bit-stuffing.svg" alt="Two bit waveforms. Data: seven zeros, then six ones. On the wire: after the first five zeros a stuff bit 1 is inserted, then the remaining two zeros and five ones, then a stuff bit 0, then the last one. The two stuff bits are highlighted, and brackets mark each run of five equal bits that triggers one."/>

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

- It guarantees **edges**, so every node keeps resynchronizing (section 04).
- **Six equal bits** inside a frame cannot be data: they are an error, which is why an error flag
  is six dominant bits.
- It adds up to **24 bits** to an 8-byte frame, and how many depends on the data.

</div>
<div>

<img style="max-height: 22rem" src="/figures/05-frame-time.svg" alt="Worst-case frame time in microseconds against 0 to 8 data bytes, one line per bit rate. Each rises linearly; at 8 bytes the worst case is 1080 microseconds at 125 kbit/s, 540 at 250 kbit/s, 270 at 500 kbit/s and 135 at 1 Mbit/s."/>

</div>
</div>

<div class="caption text-left">Worst-case length of a base frame with n data bytes:
8n + 47 + ⌊(34 + 8n − 1)/4⌋ bits — 135 bits for 8 bytes, 270 µs at 500 kbit/s</div>

<!--
Bit stuffing. CAN sends bits as plain levels, without a clock wire. A long run of zeros or ones has
no edges, and without edges the receivers cannot resynchronize. So the rule is: after five equal bits
in a row, the sender inserts one bit of the opposite value. The receivers know the rule and remove
it.

Follow the waveform. Seven zeros, then six ones. After the fifth zero, the sender inserts a one. Then
the remaining two zeros and the ones; after the fifth one, it inserts a zero. The stuff bits are
the highlighted ones. The rule runs from the
start of frame to the end of the CRC. The fixed bits after that, the delimiters, the acknowledgement
and the end of frame, are never stuffed.

Three consequences. Edges are guaranteed, at least one falling edge every ten bits,
which is what resynchronization needs. Six equal bits inside the stuffed part can never be data, so
they signal an error; that is exactly what an error flag is, six dominant bits in a row. And frames
get longer by a number of bits that depends on the data.

The formula at the bottom gives the worst case, which we need in section 08 for timing, and the
plot turns it into time. For eight data bytes, a frame can take up to 135 bits on the
wire, 24 of them stuff bits. At 500 kilobits per second, that is 270 microseconds; at 125 kilobits,
more than a millisecond.
-->

---
routeAlias: arbitration-on-the-wire
---

## Arbitration on the wire

<img class="w-full" style="max-height: 24rem" src="/diagrams/05-arbitration.svg" alt="Bit waveforms of three ECUs starting together, start of frame, identifier bits 10 to 0 and RTR, and the bus below them. ECU 3 sends 711h: at bit 10 it sends a recessive 1, reads a dominant 0 and stops; its remaining bits are grayed. ECU 1 sends 2A0h: at bit 7 it sends 1, reads 0 and stops. ECU 2 sends 265h, 0 1 0 0 1 1 0 0 1 0 1, through to the end. The bus row is identical to ECU 2's bits."/>

<div class="caption">Redrawn from the source deck, slide 29: the clapping example from section 01</div>

<div class="grid grid-cols-2 gap-8">
<div>

- Each controller **reads back** every bit it sends.
- Sent recessive, read dominant: **lost**. It becomes a receiver for the rest of the frame.

</div>
<div>

- The winner never notices the clash: the bus carried **exactly its bits**.
- The losers try again when the bus is idle, after the end of frame and the intermission.

</div>
</div>

> Arbitration costs the winner **no time**, but a loser can wait for every higher-priority frame
> queued ahead of it. Section 08 calculates how long.

<!--
Here is the clapping example from section 01, as the source deck draws it on the wire. Three ECUs
start at the same moment, with identifiers 2A0, 265 and 711.

Each CAN controller reads back, through its transceiver, every bit it sends. The bottom row is the
bus: it is zero whenever any node sends a zero. At the first identifier bit, bit 10, ECU 3, with 711,
sends a recessive one and reads back a dominant zero. It has lost. It stops
sending and simply listens to the rest of the frame; if the frame carries data it needs, it uses
it. At the fourth bit, bit 7, ECU 1, with 2A0, sends a one, reads a zero, and stops too. ECU 2, with 265,
never sees a difference. The bus carried exactly its bits, so it sends its whole frame as if it had
been alone. Compare the bus row with ECU 2's row: they are the same, bit for bit.

The losers do not wait a fixed time. They try again as soon as the bus is idle, after the end of
frame and the three bits of intermission. Then they arbitrate again, perhaps against new frames.

The box is the bridge to section 08. Arbitration costs the winner nothing. But a low-priority frame
can lose again and again while higher-priority frames queue ahead of it. How long it can wait, in
the worst case, can be calculated, and you do that in build 04.
-->

---
routeAlias: acknowledgement
---

## Acknowledgement

<div class="grid grid-cols-2 gap-8">
<div>

### How it works

- The sender transmits the ACK slot **recessive**.
- **Every** node that received the frame correctly drives it **dominant**, whether or not it uses the
  data.
- Sender reads recessive: nobody received it correctly. **ACK error**, send again.

</div>
<div>

### What it means

- The sender learns that **at least one** node got the frame, never **which**.
- A frame is valid only if it is valid **everywhere**: one node that saw it corrupted destroys it for
  all with an error frame.
- Whether the right receiver is alive is the **application's** job: it watches for a message that
  stops arriving (a timeout).

</div>
</div>

<!--
The acknowledgement. The sender transmits the ACK slot as a recessive bit. Every node that received
the frame correctly overwrites it with a dominant bit, whether or not it uses the data. Many nodes
may drive it together; that is fine, dominant is dominant. If the sender reads back recessive,
nobody received the frame correctly. That is an ACK error, and the sender sends the frame again.

What does it mean? The sender learns that at least one node got the frame, but never which one.
That is the post office contrast from section 02 again: no signed receipt from an addressee.
And a frame is valid only if it is valid everywhere: a single node that saw it corrupted destroys
it for everybody with an error frame, so all nodes keep the same data.

So how does the brake ECU know that the motor controller is still alive? Not from CAN. The
application watches the messages it expects, and if one stops arriving for longer than a set time,
it raises a fault. That is a timeout, and every safety-relevant message in a car has one.
-->
