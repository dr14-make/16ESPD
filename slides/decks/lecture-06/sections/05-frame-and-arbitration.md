---
routeAlias: frame-and-arbitration
layout: section
---

###### Section 05

# Frame and arbitration

The fields of a frame, bit stuffing, the arbitration example on the wire, and the acknowledgement.

<!--
Section 05, the frame and arbitration. We take one frame apart, field by field. Then we look at bit
stuffing, replay the clapping example on the wire, and finish with the acknowledgement.
-->

---
routeAlias: data-frame
---

## The data frame

<img src="/diagrams/05-data-frame.svg" class="w-full" style="max-height: 17rem" alt="Classic CAN base data frame as a row of fields, left to right, with each field's bits and level: bus idle; start of frame, 1 bit, dominant; identifier, 11 bits, and RTR, 1 bit, dominant, together the arbitration field; IDE and r0, 1 bit each, dominant, and DLC, 4 bits, the control field; data, 0 to 64 bits, 0 to 8 bytes; CRC, 15 bits, and its delimiter, 1 recessive bit; ACK slot, sent recessive and driven dominant by the receivers, and ACK delimiter, recessive; end of frame, 7 recessive bits; intermission, 3 recessive bits; bus idle. A bracket marks start of frame to the end of the CRC, 34 plus 8n bits, as stuffed; the rest is fixed form, never stuffed. In all, 47 plus 8n bits for n data bytes before stuffing."/>

<div class="caption">Classic CAN base frame, after ISO 11898-1 · four kinds of frame: data (this one),
remote, error (section 07) and overload</div>

<div class="tight">

| Field | Bits | Job |
|---|---:|---|
| Start of frame | 1 | one dominant bit; every node hard-synchronizes on its edge |
| Identifier + RTR | 11 + 1 | the topic, and the priority in arbitration; RTR dominant = data frame |
| IDE, r0, DLC | 1 + 1 + 4 | base format, reserved, and the number of data bytes (0–8; codes 9–15 also mean 8) |
| Data | 0–64 | the signals |
| CRC + delimiter | 15 + 1 | checksum over everything before it |
| ACK slot + delimiter | 1 + 1 | the sender leaves it recessive; **any** correct receiver drives it dominant |
| End of frame, intermission | 7 + 3 | recessive; the 3-bit gap before the next frame may start |

</div>

**11-bit** identifiers here; trucks use **29-bit** extended ones (SAE J1939); on a tie the short
frame wins.

<!--
This is a data frame of classic CAN, drawn from left to right in the order the bits are sent. The
table below gives the job of each field, and the two lines at the bottom of the picture spell out
every short name once.

The level row in the picture uses two letters. A capital D is dominant, logic 0; a small r is
recessive, logic 1. Section 04 showed what the two levels look like on the wires.

It starts with the start of frame: one dominant bit. On its edge every node synchronizes.

Next is the identifier, 11 bits. It is the topic number, and it is the priority during arbitration.
Behind it is one bit called RTR, remote transmission request. It is dominant in a data frame.

Then six control bits. The first is IDE, identifier extension: dominant means the short, 11-bit
identifier. The second, r0, is reserved for later use. Both are dominant here. The other four are the
DLC, the data length code. It says how many data bytes follow: 0 to 8. Four bits could count to 15.
In classic CAN the codes 9 to 15 are allowed, but they still mean 8 bytes.

Then the data: up to 8 bytes, which is 64 bits. These carry the signals.

Then the CRC, 15 bits. CRC stands for cyclic redundancy check. The sender calculates this check
number from all the bits before it. Each receiver calculates it again and compares. If the two
differ, a bit was damaged on the way. One recessive bit, a delimiter, closes the field.

Then the ACK slot and its delimiter. The sender leaves the slot recessive, and any receiver that got
the frame correctly makes it dominant. That is the nod.

The frame ends with 7 recessive bits, the end of frame. Then 3 more recessive bits, the
intermission, must pass before the next frame may start.

In total that is 47 bits plus the data. With 8 data bytes it is 111 bits, and only 64 of them are
your data.

The line under the table adds the long format. Our car uses 11-bit identifiers. Trucks use a
standard called SAE J1939, and it needs more identifiers, so their frames carry 29 bits: the first
11, then two recessive bits, then 18 more. The second of those two is IDE, now recessive, which tells
every node that the long form follows. If a short frame and a long frame start with the same 11
bits, the short one wins. Right after the 11 bits, the short frame sends dominant bits where the
long frame sends recessive ones, and dominant wins.

The caption under the picture names all four kinds of frame. This one is the data frame, and almost all traffic is
data frames. A remote frame asks another node to send its data; cars rarely use it. An error frame
is the "STOP!" shout; section 07 covers it. An overload frame lets any node ask for a short delay
before the next frame; modern controllers almost never send one.
-->

---
routeAlias: bit-stuffing
---

## Bit stuffing

After **five equal bits** in a row, the sender inserts **one opposite bit**; the receivers remove it.
From the start of frame to the end of the CRC, so the identifier and the CRC are stuffed too.

<img class="w-full" style="max-height: 14rem" src="/diagrams/05-bit-stuffing.svg" alt="Two bit waveforms on the wire, 17 data bits each, stuff bits shaded. All zeros: after every five zeros a stuff bit 1 is inserted, one every 5 bits, 3 stuff bits in all, 20 bits on the wire. Worst case, data 11111 0000 1111 0000: after the first five ones a stuff bit 0; that stuff bit and the next four zeros make five equal bits, so another stuff bit 1 follows, and so on: one stuff bit every 4 data bits after the first, 4 stuff bits in all, 21 bits on the wire. Brackets mark the data bits of each run that triggers a stuff bit: 5, 5, 5 in the first row; 5, 4, 4, 4 in the second."/>

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

- It guarantees **edges**, so every node keeps resynchronizing (section 04).
- **Six equal bits** inside a frame cannot be data: they are an error, which is why an error flag
  (section 07) is six dominant bits.
- Worst case, one stuff bit per **4** bits after the first: up to **24 bits** more on an 8-byte
  frame, 135 bits in all.

</div>
<div>

<img style="max-height: 22rem" src="/figures/05-frame-time.svg" alt="Worst-case frame time, with maximum stuffing, in microseconds against 0 to 8 data bytes, one line per bit rate. Each rises linearly; at 8 bytes the worst case is 1080 microseconds at 125 kbit/s, 540 at 250 kbit/s, 270 at 500 kbit/s and 135 at 1 Mbit/s."/>

</div>
</div>

<!--
Now the rule we promised: bit stuffing. CAN has no separate clock wire. The receivers keep time from
the edges in the signal, and a long run of equal bits has no edges. So the rule at the top of the
slide is: after five equal bits in a row, the sender inserts one opposite bit. That extra bit is the
stuff bit. The receivers know the rule and remove it again.

Stuffing applies from the start of frame to the end of the CRC. That includes the identifier and the
CRC itself, not only the data. The fixed bits after the CRC are never stuffed.

The picture shows two rows of bits on the wire. Low is dominant, logic 0; high is recessive, logic
1. The shaded bits are stuff bits.

The top row sends only zeros. After every five zeros the sender inserts a one. So there is one stuff
bit every 5 data bits: 17 data bits become 20 on the wire.

The bottom row is the worst case. The data is five ones, then four zeros, four ones, four zeros, and
so on. After the first five ones the sender inserts a zero. That stuff bit is itself the first bit
of the next run. Four more zeros from the data make five equal bits, so another stuff bit follows,
a one. Then four ones, and again a stuff bit. So after the first five bits, every four data bits
force a stuff bit: 17 data bits become 21 on the wire. This pattern gives the most stuff bits a
frame can get.

The bullets on the left give three consequences. First, edges are guaranteed, so every node can keep
resynchronizing. Second, six equal bits in a row can never be data inside a frame. Six equal bits
mean an error. That is why the "STOP!" shout on CAN, the error flag, is six dominant bits; section
07 explains it. Third, the frame gets longer. In an 8-byte frame, 98 bits are stuffed: 34 bits of
header and CRC plus 64 bits of data. With one stuff bit after the first five and then one per four,
that is up to 24 stuff bits, and the frame grows from 111 to 135 bits.

The plot on the right shows the longest possible frame time, with maximum stuffing, against the
number of data bytes, one line per bit rate. Read the right end. With 8 bytes, a frame takes at most
135 bits. At 500 kilobits per second that is 270 microseconds. At 125 kilobits per second it is 1080
microseconds, just over a millisecond. Remember the 270 microseconds; we use them in section 08.
-->

---
routeAlias: frame-on-the-wire
layout: default
class: big-figure
---

## One whole frame on the wire

<img src="/figures/05-frame-bits.svg" alt="One complete classic CAN base frame drawn as a logic level over time, bit by bit, fields colored: start of frame, identifier 1A0h, RTR, IDE, r0, DLC 8, eight data bytes carrying vehicle speed 87 km/h as raw 8700, the computed CRC-15 and its delimiter, ACK slot and delimiter, end of frame and intermission. Stuff bits are marked where five equal bits in a row occur, between the start of frame and the end of the CRC."/>

<div class="caption">Frame 1A0h carrying vehicle speed 87 km/h: 87 / 0.01 = raw 8700 (section 06), 8 data
bytes · CRC-15 computed over the frame · stuff bits marked</div>

> Every field from the last slides, in order. Where the stuff bits fall depends on the data, so the
> same frame gets longer or shorter as the speed changes.

<!--
Here are the last two slides put together: one whole frame, every bit as it goes onto the wire.
Low is dominant, logic 0; high is recessive, logic 1, as before. The colors mark the fields from
the frame slide.

The frame is a real one from our car. Its identifier is 1A0 in hexadecimal: the brake ECU's frame
that carries the vehicle speed. The car drives at 87 kilometers per hour. The signal counts in steps
of 0.01 kilometers per hour, so the number in the frame is 8700. Section 06 shows how that works.
The frame has 8 data bytes, so the data length code is 8.

The CRC is not made up for the picture. It was calculated from the bits before it, exactly as a CAN
controller does it.

Now look for the marked bits. Each one is a stuff bit, inserted after five equal bits in a row. You
find them only between the start of frame and the end of the CRC. The fixed bits at the end have
none.

The box gives the lesson. The stuff bits depend on the data. If the speed changes, the bits change,
and the frame may need more or fewer stuff bits. That is why the timing calculations in section 08
always use the worst case.
-->

---
routeAlias: arbitration-on-the-wire
---

## Arbitration on the wire

<img class="w-full" style="max-height: 24rem" src="/diagrams/05-arbitration.svg" alt="Bit waveforms of three ECUs starting together, start of frame, identifier bits 10 to 0 and RTR, and the bus below them. ECU 3 sends 711h: at bit 10 it sends a recessive 1, reads a dominant 0 and stops; its remaining bits are grayed. ECU 1 sends 2A0h: at bit 7 it sends 1, reads 0 and stops. ECU 2 sends 265h, 0 1 0 0 1 1 0 0 1 0 1, through to the end. The bus row is identical to ECU 2's bits."/>

<div class="caption">The clapping example from section 01, as bits on the wire</div>

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
This is the clapping example from section 01, now as bits on the wire. Three ECUs start at the same
moment. ECU 1 sends identifier 2A0, ECU 2 sends 265, and ECU 3 sends 711. The bottom row is the bus.
The bus is dominant, a zero, whenever at least one ECU sends a zero.

The first bullet is the key: each controller reads back every bit it sends. All three send the
dominant start of frame. Then comes the identifier, highest bit first. At bit 10, ECU 3 sends a
recessive one, but it reads a dominant zero from the bus. It has lost. It stops sending and becomes
a receiver for the rest of the frame. Its remaining bits are drawn in gray. At bit 7, the same
happens to ECU 1: it sends a one, reads a zero, and stops.

ECU 2 never sees a difference. Compare its row with the bus row: they are identical. So the winner
does not notice the contest, and its frame is not delayed.

The losers try again as soon as the bus is idle, after the end of frame and the intermission.

The box at the bottom leads to section 08. Arbitration costs the winner no time. But a frame with
low priority can lose several times in a row, while frames with higher priority go first. Section 08
calculates how long it can wait.
-->

---
routeAlias: acknowledgement
---

## Acknowledgement

<div class="diagram-wide">

<img src="/diagrams/05-ack-slot.svg" style="max-height: 13rem" alt="Three waveforms over the CRC delimiter, the ACK slot, the ACK delimiter and the start of the end of frame. The sender sends recessive throughout. Every receiver that got the frame correctly drives the ACK slot dominant and is recessive otherwise. The bus is therefore dominant in the ACK slot and recessive around it. A dashed line in the slot shows the bus staying recessive when nobody acknowledges: an ACK error."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

- The sender transmits the ACK slot **recessive**.
- **Every** node that received the frame correctly drives it **dominant**, whether or not it uses the
  data.
- Sender reads recessive: nobody received it correctly. **ACK error**, send again.

</div>
<div>

- The sender learns that **at least one** node got the frame, never **which**.
- A frame is valid only if it is valid **everywhere**: one node that saw it corrupted destroys it for
  all with an error frame (section 07).

> ACK: **one yes** is enough. Error frame: **one no** cancels it for everyone.
- Whether the right receiver is alive is the **application's** job: it watches for a message that
  stops arriving (a timeout).

</div>
</div>

<!--
The last field to explain is the acknowledgement, the nod.

The picture shows the end of a frame as three waveforms: the sender, the receivers and the bus. Low
is dominant, logic 0; high is recessive, logic 1.

The left column says how it works. The sender transmits the ACK slot as a recessive bit: the top
line stays high. Every node that
received the frame correctly drives the slot dominant: the middle line dips. It does so whether it
needs the data or not. Several nodes may do this at once; the bus is simply dominant, the bottom
line. The sender reads that dip back and knows the frame arrived. If nobody acknowledges, the bus
stays high, the dashed line. The sender reads the slot back as recessive. That is an ACK error, and
the sender sends the frame again.

The right column says what it means. The sender learns that at least one node got the frame. It never learns
which one. That is the difference from the post office: there is no signed receipt.

The second bullet repeats the rule from the room: a frame counts only if it is correct everywhere.
One node that received it damaged destroys it for all with an error frame. Section 07 shows how.
The box under the second bullet puts the two rules side by side. For the acknowledgement, one yes
is enough: a single receiver that drives the slot dominant is all the sender needs. For the error
frame, one no is enough: a single receiver that saw a damaged frame cancels it for everyone.

So how does the brake ECU know that the motor controller is still alive? CAN does not tell it. The
last bullet gives the answer. The software in each ECU, the application, watches the messages it
expects. If one stops arriving for longer than a set time, the ECU reports a fault. That is called a
timeout.

We can now send a frame. Next: how a physical value, such as a speed, gets into its data bytes.
-->
