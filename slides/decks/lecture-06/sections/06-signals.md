---
routeAlias: signals
layout: section
---

###### Section 06

# Signals

From a physical value to bits in a frame: the DBC file, factor and offset, byte order, counters and
checksums.

<!--
Section 06, signals. At the sender, a speed in kilometers per hour must become a few bits in a
frame. At every receiver, those bits must become a speed again. A file called the DBC file says how.
The examples are real: they come from the Volkswagen-group platform of the Škoda Fabia, whose
instrument cluster we drive in the wrap-up.
-->

---
routeAlias: value-to-bits
---

## From a value to bits

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

$$\text{value} = \text{raw} \times \text{factor} + \text{offset}$$

$$\text{raw} = \operatorname{round}\!\left(\frac{\text{value} - \text{offset}}{\text{factor}}\right)$$

- **raw**: the whole number in the frame, usually unsigned (a DBC `-` marks a signed one)
- **factor**: the resolution, one raw step
- **offset**: shifts the range, e.g. to allow negative temperatures
- **n** bits set the range: offset … offset + factor × (2<sup>n</sup> − 1)

> Every signal is **rounded** to its factor and **clamped** to its range. The bus cannot carry what
> the database did not plan for.

</div>
<div>

### Three real signals (VW PQ24 drivetrain CAN)

| Signal | Frame | Bits | Factor | Offset | Bit range |
|---|---|---:|---:|---:|---|
| engine speed | 280h | 16 | 0.25 rpm | 0 | 0–16 383 rpm |
| vehicle speed | 1A0h | 15 | 0.01 km/h | 0 | 0–327 km/h |
| coolant temperature | 288h | 8 | 0.75 °C | −48 °C | −48 to 143.25 °C |

90 °C coolant: (90 − (−48)) / 0.75 = **184** = B8h; back: 184 × 0.75 − 48 = 90 ✓

</div>
</div>

<div class="caption text-left">PQ24: the Volkswagen-group small-car platform of the Škoda Fabia II
· values from the PQ24 drivetrain CAN matrix used on the bench in this course</div>

<!--
A frame carries only whole numbers. The first formula at the top left turns such a number into a
physical value: value equals raw times factor plus offset. Every receiver does this. The second
formula is the same rule backward, and the sender uses it: subtract the offset, divide by the
factor, and round to the nearest whole number. That whole number goes into the frame.

The bullets explain the parts. Raw is the whole number that is in the frame. Usually it has no sign.
A signal can also be signed, which lets the raw number itself go below zero; the DBC file marks such
a signal with a minus sign. The factor is the step size: what one step of the raw number is worth.
The offset shifts the range, for example so that a temperature can go below zero. And the number of
bits, n, sets how far the range reaches. The smallest value is the offset, when the raw number is
zero. The largest is the offset plus the factor times the largest raw number, which is 2 to the n,
minus one.

The box is what you need for the build. Every signal is rounded to its factor and clamped, that is
limited, to its range. The bus cannot carry anything finer or larger than the database planned.

On the right are three real signals from the Fabia's platform. The last column is the bit range:
everything the bits can hold. Engine speed uses 16 bits with a factor of 0.25 revolutions per
minute. Its bits reach 16,383. Vehicle speed uses 15 bits with a factor of 0.01 kilometers per hour.
Its bits reach 327. Coolant temperature uses only 8 bits, with a factor of
0.75 degrees and an offset of minus 48 degrees. The largest raw number in 8 bits is 255. 255 times
0.75 is 191.25, and adding the offset of minus 48 gives 143.25. So it covers minus 48 to 143.25
degrees.

The last line works one example in both directions. The sender has 90 degrees. Subtract the offset:
90 minus minus 48 is 138. Divide by 0.75: the raw number is 184. In hexadecimal that is B8. The
receiver goes back: 184 times 0.75 is 138, minus 48 is 90 degrees again. Here the division comes
out exactly, so nothing is lost to rounding.

The car maker picks these numbers for each signal: fine enough, wide enough, and as few bits as
possible. The next slide shows what happens when a value does not fit.
-->

---
routeAlias: rounded-and-clamped
layout: default
class: big-figure
---

## Rounded and clamped

<img src="/figures/06-quantization.svg" alt="A ramp signal as the sender sees it and as a receiver decodes it, sent in 8 bits. Sent with factor 1, the received value is a coarse staircase around the ramp that keeps up with it. Sent with factor 0.1, a fine staircase that nearly covers the ramp until it reaches the largest value its 8 bits can hold; from there the received value stays flat while the ramp keeps rising."/>

<div class="caption">A ramp sent in 8 bits with factor 1 and with factor 0.1: true value against received
value · the finer factor is clamped at its raw range</div>

> The factor sets the **smallest step** a receiver can see; the length in bits sets the **largest
> value**. Beyond it, the receiver reads a flat line and cannot tell.

<!--
This picture shows the two limits from the last slide at work. A value rises steadily, a ramp. It is
sent twice, both times in 8 bits but with two different factors, and we compare what a receiver
decodes with the true value.

With a factor of 1, the received value moves in whole steps. It is a staircase. Each step is one raw
count. With a factor of 0.1, the steps are ten times smaller, and the staircase hugs the ramp. That
is rounding, also called quantization: the bus carries only whole raw numbers.

Now look at the end of the ramp. The fine line stops rising and goes flat. With the same 8 bits, its
ten times smaller steps reach only a tenth as far. Its raw number has reached the largest value the
bits can hold, and the sender clamps it there. The true value keeps climbing, but the receiver sees a
flat line. Nothing tells it that the value is cut off. The coarse line, with factor 1, still has room
and keeps up.

So the box is the rule for choosing a signal's layout. The factor sets the smallest step you can
see. The number of bits sets the largest value. A finer factor needs more bits for the same range,
and the frame has only 64 bits.

The next slide shows where these choices are written down.
-->

---
routeAlias: dbc
---

## The DBC file

<div class="text-[0.8rem]">

```text
BO_ 640 Motor_1: 8 Motor
 SG_ Motordrehzahl : 16|16@1+ (0.25,0) [0|16256] "U/min" Kombi

BO_ 416 Bremse_1: 8 Bremse
 SG_ Geschwindigkeit : 17|15@1+ (0.01,0) [0|326] "km/h" Kombi,Motor
 SG_ Zaehler : 56|4@1+ (1,0) [0|15] "" Kombi
```

</div>

| Part | Meaning |
|---|---|
| `BO_ 640 Motor_1: 8 Motor` | a frame: identifier 640 = 280h, name, 8 data bytes, sent by the engine ECU |
| `SG_ Motordrehzahl` | a signal in it: engine speed |
| `16\|16@1+` | starts at bit 16, 16 bits long, `@1` Intel byte order, `+` unsigned |
| `(0.25,0)` | factor and offset |
| `[0\|16256]` | the declared valid range, inside what the 16 bits hold (0–16 383 rpm) |
| `"U/min" Kombi` | the unit, and the ECUs that receive it: the cluster |

**Multiplexed** signals: one field, the multiplexer, says which set of signals the rest of the frame
carries this time, so one identifier can take turns.

<div class="caption text-left">DBC: Vector's database format, the de facto standard for CAN signal
definitions · lines written for this slide from the PQ24 layout, names shortened, in German as in
the matrix: Motor = engine, Bremse = brakes, Kombi
= instrument cluster, Zähler = counter</div>

<!--
All these definitions go into one file per bus, the DBC file. DBC is a file format from the tool
maker Vector, and nearly everyone uses it. The code at the top shows two frames in that format. The
names are German, as the car maker wrote them. The table below explains the first frame part by
part.

A line that starts with BO declares a frame. Its identifier is 640 in decimal, which is 280 in
hexadecimal. Its name is Motor_1, it has 8 data bytes, and the engine ECU sends it.

A line that starts with SG declares a signal in that frame. Motordrehzahl is the engine speed.

Then the layout. 16, bar, 16 means the signal starts at bit 16 and is 16 bits long. The "at 1" is
the byte order, called Intel; the next slide explains it. The plus means the number has no sign.

In parentheses are the factor and the offset: 0.25 and 0. In square brackets is the range the car
maker declares as valid: 0 to 16,256. That is a little less than the 16 bits could hold, 16,383 from
two slides back. Both are true. The bits set what can be sent; the DBC says which values a
receiver should accept. Raw numbers above the valid range are left unused, or a maker uses them to
mark a signal as invalid. The same holds for the vehicle speed: its bits reach 327, and the DBC
declares 0 to 326. Last come the unit and the receivers. Here the only receiver is Kombi, the
instrument cluster.

The second frame, Bremse_1, comes from the brake ECU. It carries the vehicle speed, received by the
cluster and by the engine ECU. One sender, several receivers: that is the meeting room. It also
carries a 4-bit counter, Zaehler. We come back to it in two slides.

The bold line under the table names one more trick, multiplexed signals. One field in the frame, the
multiplexer, is a number that says which set of signals the other bytes carry this time. Value 0
might mean one group of signals, value 1 another. So one identifier can carry more than 8 bytes of
signals, taking turns. The DBC marks the multiplexer with a capital M and each switched signal with a
small m and its number.

Software tools read this file to translate the raw frames on a bus into values with units.
-->

---
routeAlias: byte-order
---

## Byte order: Intel and Motorola

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

Engine speed **2000 rpm** → raw 2000 / 0.25 = 8000 = **1F40h**, in bytes 2 and 3 of frame 280h:

<img src="/diagrams/06-byte-order.svg" alt="Two 8 by 8 grids, one row per data byte 0 to 7, bit 7 on the left. Left, Intel, DBC 16|16@1+: byte 2 holds 40h, the low byte, 0100 0000; byte 3 holds 1Fh, the high byte, 0001 1111; the start bit 16, byte 2 bit 0, is framed as the lowest bit. Right, Motorola, DBC 23|16@0+: byte 2 holds 1Fh, the high byte; byte 3 holds 40h, the low byte; the start bit 23, byte 2 bit 7, is framed as the highest bit."/>

</div>
<div>

- **Intel**: the **low** byte first (little-endian). VW's PQ24 matrix, and our model, use it.
- **Motorola**: the **high** byte first (big-endian). Other car makers' matrices use it, often in the
  same car on another bus.
- The DBC marks each signal: `@1` Intel, `@0` Motorola. Its start bit is the lowest bit for Intel,
  the highest for Motorola.

> Decode Intel bytes as Motorola and 2000 rpm reads as 401Fh × 0.25 ≈ **4104 rpm**.

</div>
</div>

<!--
A signal of 16 bits needs two bytes. There are two ways to order them in the frame, and this slide
shows both.

Take an engine speed of 2000 revolutions per minute. Divide by the factor 0.25: the raw number is
8000. In hexadecimal that is 1F40. So the two bytes are 1F, the high byte, and 40, the low byte. The
signal sits in bytes 2 and 3 of frame 280.

The picture shows the frame's 8 data bytes as a grid: one row per byte, eight bits per row, bit 7 on
the left. The blue cells are the low byte, the orange cells the high byte.

On the left, Intel. The low byte comes first: byte 2 holds 40 and byte 3 holds 1F. This order is
also called little-endian. The Fabia's platform uses it, and so does our model.

On the right, Motorola. The high byte comes first: byte 2 holds 1F, byte 3 holds 40. This order is
called big-endian. Other car makers use it, sometimes on another bus of the same car.

The DBC file marks each signal: at 1 for Intel, at 0 for Motorola. The framed cell is the signal's
start bit, the number before the bar in the DBC. For Intel it is the lowest bit of the value, bit 16.
For Motorola it is the highest bit, bit 23. So the same two bytes get two different start bits.

The box shows what happens if you mix them up. Read the Intel bytes as if they were Motorola, and
you get 401F in hexadecimal. Times 0.25, that is about 4104 revolutions per minute instead of 2000.
Nothing on the bus warns you. The number is simply wrong.
-->

---
routeAlias: counters-and-checksums
---

## Counters and checksums

<div class="diagram-wide">

<img src="/diagrams/06-byte-map.svg" style="max-height: 11rem" alt="A protected 8-byte frame as a row of fields: ID and DLC; data bytes 0 to 5 carrying signals; byte 6 with a signal in its upper half and a 4-bit counter in its lower half; byte 7, the checksum; then the CRC, 15 bits; then ACK and end of frame. A bracket over bytes 0 to 6 points into byte 7: checksum = byte 0 XOR byte 1 XOR ... XOR byte 6, computed by the sender's software. A bracket over the CRC: added by the CAN controller, outside the data. Under the 8 data bytes: what the application writes; the receiver XORs bytes 0 to 7 and must get 00h."/>

</div>

<div class="grid grid-cols-2 gap-8">
<div>

### In the data bytes

| Frame | Sender | Protection |
|---|---|---|
| 1A0h Bremse_1 | brake ECU | 4-bit **counter**, +1 every frame |
| 050h Airbag_1 | airbag ECU | counter + **XOR checksum** of the other bytes |
| 480h Motor_5 | engine ECU | **XOR checksum** in byte 7 |

**XOR checksum**, one running chain, e.g. over three bytes: 12h ⊕ 34h = 26h, 26h ⊕ 56h = **70h**.
The receiver XORs all bytes with the checksum: 12h ⊕ 34h ⊕ 56h ⊕ 70h = **00h**, else it drops the
value.

</div>
<div>

### Why, when CAN has a CRC?

- The CRC protects the frame **on the wire**. It cannot see a **stale** value from a hung sender, or
  a value corrupted **inside** an ECU or a gateway.
- A counter that stops counting: the sender's software has hung. A wrong checksum: the data is not
  what the sending software meant.
- XOR is weak: two flipped bits in the **same column** cancel, and **swapped bytes** go unseen. So
  **AUTOSAR E2E** uses a CRC (+ counter + data ID); **SecOC** adds a cryptographic code against
  forged frames.

</div>
</div>

<!--
Some signals are so important that the frame protects them a second time.

The picture at the top shows where this protection sits. It is an example layout of an 8-byte frame.
Bytes 0 to 5 carry signals. Byte 6 carries one more signal and a 4-bit counter; 4 bits are half a
byte, also called a nibble. Byte 7 is the checksum. The sender's software computes it from bytes 0 to
6 and writes it into the data like any other signal. To the CAN controller it is just data. The CRC
is something else. It is not in the data bytes at all. The CAN controller adds it after the data, in
hardware, and checks it on the way in.

The table on the left shows three frames from the Fabia's network. Bremse_1, from the brake ECU,
carries a 4-bit counter. The sender adds one with every frame, and after 15 it starts again at 0.
Airbag_1 carries a counter and a checksum. Motor_5, from the engine ECU, carries a checksum in byte
7.

A checksum is not a copy of the data. It is one summary byte, like the check digit at the end of an
ISBN, the number on a book. Here it is made with XOR, exclusive or. XOR compares two bits: equal bits
give 0, different bits give 1. On whole bytes it does this for each of the eight bit positions. The
checksum is one running chain: byte 0 XOR byte 1, then that result XOR byte 2, and so on up to byte
6. The line under the table shows it with three bytes. 12 hexadecimal XOR 34 is 26. 26 XOR 56 is 70.
So the checksum is 70. The receiver does the same chain over all the bytes, the checksum included.
Any byte XOR itself is zero, so if nothing changed, the answer must be 00. If it is not, the receiver
uses the last good value or a safe default.

The right column answers the obvious question: CAN already has a CRC, so why add more? The CRC
protects the frame only on the wire. Two faults pass it. One: the software in the sender has
stopped, and the ECU keeps repeating an old value. The frames are valid. But the counter no longer
counts, and the receiver notices. Two: the value was damaged inside an ECU or a gateway, before the
CRC was calculated. A checksum calculated by the application itself reveals that.

The last bullet names the weakness of XOR. If two bits flip in the same position, in two different
bytes, the two changes cancel and the checksum still fits. And XOR does not care about order, so two
swapped bytes give the same checksum. That is why today's standard, AUTOSAR E2E, end-to-end
protection, puts a real CRC, a counter and a data identifier into the data of safety-related frames.
And SecOC, Secure Onboard Communication, also from AUTOSAR and named in section 02, adds a code that
only ECUs with the secret key can produce. It protects against forged frames.
-->

---
routeAlias: fields-on-a-block
---

## The same fields on a Dyad block

| DBC | `CanTxReal` parameter | In the model |
|---|---|---|
| identifier | `id` | 0–2047; the priority in `can_schedule` |
| — | `slot` | which place on the model's bus carries the signal; one transmitter per slot |
| cycle time | `period` | sampled every period, delivered one period later |
| factor, offset | `scale`, `offset` | rounded to `scale` |
| raw range | `raw_min`, `raw_max` | clamped |
| byte order | — | Intel, always |

Signals with the same `id` share a frame, packed in slot order, at most 8 bytes; `can_dbc` writes the
DBC of the model's bus.

`CanTxReal` carries **only the scaled value**: sample → scale and round to the raw integer →
one-period delay → hold. **No counter, no checksum**; the Fabia demo's stream adds the ones the
cluster expects (section 10).

<div class="handson">Build 01 starts here: you put the car's signals onto the bus and choose these
fields for each.</div>

<!--
Now the same fields on the block you use in the build. The block is called CanTxReal, and it sends
one signal. The table pairs each DBC field with a parameter of the block.

The identifier is the parameter id, from 0 to 2047. The function can_schedule uses it as the
priority.

The second row has no DBC partner. The slot is the place on the model's bus that carries this
signal. Each slot may have only one transmitter.

The cycle time is the parameter period. The block reads its input once per period and delivers the
value one period later.

Factor and offset are called scale and offset. The value is rounded to the scale. The raw range is
raw_min and raw_max, and the value is clamped to it. The byte order is always Intel.

The line under the table adds two things. Signals with the same id share one frame, with at most 8
bytes, as on a real bus. And the function can_dbc writes the DBC file of the model's bus.

The next line says what the block leaves out. CanTxReal carries only the scaled value. Inside, it
does four things in a row. It samples its input once per period. It scales the sample and rounds it
to the raw whole number, and clamps it. It delays that number by one period. And it holds it until
the next one arrives. It does not model the counters or the checksums from the last slide. When we
drive the real Fabia cluster in section 10, a separate program, the demo's stream, builds the real
frames and adds the counters and checksums the cluster expects. The cluster checks them, like the
receivers on the last slide.

The green box: build 01 starts here. You put the car's signals on the bus, and you choose these
fields for each one.
-->
