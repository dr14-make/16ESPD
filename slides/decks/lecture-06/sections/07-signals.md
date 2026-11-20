---
routeAlias: signals
layout: section
---

###### Section 07

# Signals

From a physical value to bits in a frame: the DBC file, factor and offset, byte order, counters and
checksums.

<!--
Section 07: signals. A speed in kilometers per hour has to become a few bits in a frame at the
sender, and a speed again at every receiver. The signal database says how. Our examples are real:
the frames a 2000s Volkswagen-group car sends to its instrument cluster, which we use in the
wrap-up to drive a real Škoda Fabia cluster.
-->

---
routeAlias: value-to-bits
---

## From a value to bits

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

$$\text{value} = \text{raw} \times \text{factor} + \text{offset}$$

- **raw**: the unsigned or signed integer in the frame
- **factor**: the resolution, one raw step
- **offset**: shifts the range, e.g. to allow negative temperatures
- **length** in bits sets the range: factor × 2<sup>length</sup>

> Every signal is **rounded** to its factor and **clamped** to its range. The bus cannot carry what
> the database did not plan for.

</div>
<div>

### Three real signals (VW PQ24 drivetrain CAN)

| Signal | Frame | Bits | Factor | Offset | Range |
|---|---|---:|---:|---:|---|
| engine speed | 280h | 16 | 0.25 rpm | 0 | 0–16 383 rpm |
| vehicle speed | 1A0h | 15 | 0.01 km/h | 0 | 0–327 km/h |
| coolant temperature | 288h | 8 | 0.75 °C | −48 °C | −48 to 143 °C |

90 °C coolant: raw = (90 + 48) / 0.75 = **184** = B8h

</div>
</div>

<div class="caption text-left">PQ24: the Volkswagen-group small-car platform of the Škoda Fabia II
· values from the PQ24 drivetrain CAN matrix used on the bench in this course</div>

<!--
A frame carries integers. A signal becomes an integer by one linear rule: the value equals the raw
integer times a factor, plus an offset. The factor is the resolution: one step of the raw integer.
The offset shifts the range, so that a temperature can go below zero without a sign bit. And the
number of bits sets how far the range reaches: the factor times two to the power of the length.

The box is the point to remember for the build. Every signal on the bus is rounded to its factor
and clamped to its range. If the database gives vehicle speed a resolution of one kilometer per
hour, no receiver will ever see 87.4.

On the right, three real signals from the frames a Volkswagen-group car of the Škoda Fabia's
generation sends to its dashboard. Engine speed: 16 bits at a quarter of an rpm, up to about 16
thousand rpm. Vehicle speed: 15 bits at one hundredth of a kilometer per hour, up to 327. Coolant
temperature: only 8 bits, at three quarters of a degree, with an offset of minus 48, so it covers
minus 48 to 143 degrees. At 90 degrees the raw value is 90 plus 48, divided by 0.75: 184,
hexadecimal B8. Each car maker chooses these numbers for each signal: enough resolution, enough
range, as few bits as possible.
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
| `[0\|16256]` | the allowed physical range |
| `"U/min" Kombi` | the unit, and the ECUs that receive it: the cluster |

<div class="caption text-left">DBC: Vector's database format, the de facto standard for CAN signal
definitions · lines written for this slide from the PQ24 layout, names shortened, in German as in
the matrix: Motor = engine, Bremse = brakes, Kombi
= instrument cluster, Zähler = counter</div>

<!--
The car maker writes all of these definitions into one file per bus, the communication matrix. The
format nearly everyone uses is the DBC file, from the tool maker Vector. Here are three lines of it,
written for two of our frames.

A line starting with BO_ declares a frame: identifier 640 decimal, which is 280 hexadecimal, named
Motor_1, eight data bytes, sent by the engine ECU. Under it, each line starting with SG_ declares a
signal. Motordrehzahl is German for engine speed; the names are the car maker's own.

Then the layout. 16 bar 16 means the signal starts at bit 16 of the frame and is 16 bits long. At-1
means Intel byte order, the next slide. Plus means unsigned. In parentheses the factor and offset,
0.25 and zero. In brackets the allowed physical range. Then the unit, and the list of ECUs that
receive the signal: here only the cluster, Kombi.

The second frame, Bremse_1 from the brake ECU, carries the vehicle speed and a four-bit counter,
which we meet two slides on. Notice that vehicle speed is received by the cluster and the engine
ECU: one sender, several receivers, the broadcast from section 02.

Tools read this file to decode traffic. Our model writes one too: the function can_dbc produces the
DBC of the model's bus, and you can decode the simulated car's frames with it.
-->

---
routeAlias: byte-order
---

## Byte order: Intel and Motorola

<div class="grid grid-cols-2 gap-8">
<div>

Engine speed **2000 rpm** → raw 2000 / 0.25 = 8000 = **1F40h**, starting at byte 2:

| Byte | 0 | 1 | 2 | 3 | 4 | … |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| **Intel** (little-endian) | 00 | 00 | **40** | **1F** | 00 | … |
| **Motorola** (big-endian) | 00 | 00 | **1F** | **40** | 00 | … |

</div>
<div>

- **Intel**: the **low** byte first. VW's PQ24 matrix, and our model, use it.
- **Motorola**: the **high** byte first. Other car makers' matrices use it, often in the same car on
  another bus.
- The DBC marks each signal: `@1` Intel, `@0` Motorola.

> Decode Intel bytes as Motorola and 2000 rpm reads as 401Fh × 0.25 = **4104 rpm**.

</div>
</div>

<!--
A 16-bit signal takes two bytes, and there are two ways to put them in the frame.

Take engine speed at 2000 rpm. The raw value is 2000 divided by 0.25: 8000, hexadecimal 1F40. In
Intel byte order, named after the Intel processors that store numbers this way, the low byte comes
first: byte 2 holds 40, byte 3 holds 1F. That is how the Fabia's engine ECU sends it, and how our
model packs every signal. In Motorola byte order, the high byte comes first: 1F, then 40.

Both are in use, chosen by the car maker, sometimes differently on two buses of the same car. The
DBC marks each signal: at-1 for Intel, at-0 for Motorola.

The box shows why it matters. Read the Intel bytes 40 1F as if they were Motorola, and you get
401F hexadecimal, 16 415 decimal, times 0.25: 4104 rpm instead of 2000. Nothing on the bus warns
you; the number is simply wrong.
-->

---
routeAlias: counters-and-checksums
---

## Counters and checksums

<div class="grid grid-cols-2 gap-8">
<div>

### In the frame

| Frame | Sender | Protection |
|---|---|---|
| 1A0h Bremse_1 | brake ECU | 4-bit **counter**, +1 every frame |
| 050h Airbag_1 | airbag ECU | counter + **XOR checksum** of the other bytes |
| 480h Motor_5 | engine ECU | **XOR checksum** in byte 7 |

The receiver checks both, and on a failure uses the last good value or a safe default.

</div>
<div>

### Why, when CAN has a CRC?

- The CRC protects the frame **on the wire**. It cannot see a sender that keeps repeating a **stale**
  value, or a value corrupted **inside** an ECU or a gateway.
- A counter that stops counting: the sender's software has hung.
- A checksum computed by the **application**: the data is what the sending software meant.
- Today: **AUTOSAR E2E** (CRC + counter + data ID) for safety; **SecOC** adds a cryptographic code
  against forged frames.

</div>
</div>

<!--
Some signals matter so much that the frame protects them a second time.

On the left, three frames of the Fabia's network. Bremse_1, from the brake ECU, carries a four-bit
counter that goes up by one with every frame and wraps from 15 to 0. Airbag_1 carries a counter and
a checksum: the XOR of the other bytes. Motor_5, from the engine ECU, carries an XOR checksum in its
last byte. The receiver checks them; if the check fails, it keeps the last good value or falls back
to a safe default, and after a while sets a fault.

On the right, the obvious question: CAN already has a 15-bit CRC, why more? Because the CRC protects
the frame on the wire, from the sender's controller to the receiver's controller. It cannot see a
sender whose software has hung and keeps sending the same old bytes: the frames are perfectly
valid. A counter that stops counting reveals that. And it cannot see data corrupted inside an ECU
or a gateway before it reached the controller. A checksum computed by the application itself shows
that the data is what the sending software meant.

Modern cars standardize this as AUTOSAR end-to-end protection: a CRC, a counter and a data
identifier in every safety-relevant frame. And because a bus where anyone may talk is also a bus
where an attacker may talk, many new frames also carry SecOC, a short cryptographic code that only
ECUs with the key can produce.
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

<div class="handson">Build 01 starts here: you put the car's signals onto the bus and choose these
fields for each.</div>

<!--
Here is the same list of fields on the block you use in the build, CanTxReal.

The identifier is the parameter id, from zero to 2047; the model uses it as the priority when it
calculates the bus timing. The slot has no DBC counterpart: it is the place on the model's bus that
carries this signal, and each slot may have only one transmitter. The cycle time is the period: the
block samples its input once per period and delivers it one period later. Factor and offset are
scale and offset: the value is rounded to the scale. The raw range is raw_min and raw_max: the value
is clamped. The byte order is always Intel.

Signals with the same identifier share one frame, packed in slot order, up to eight bytes, as on a
real bus. And can_dbc writes the DBC file of the model's bus, so a real CAN tool can decode the
simulated traffic.

That is where build 01 starts: you put the car's signals onto the bus and choose these fields for
each one.
-->
