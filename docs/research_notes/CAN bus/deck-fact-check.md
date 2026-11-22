# Lecture 6 — CAN bus: fact check of sections 03–09

Scope: `slides/decks/lecture-06/sections/03-networks-in-a-car.md` through `09-diagnostics.md`,
slide text and speaker notes, plus the diagram and figure SVGs that carry numbers. The last two
slides of 08 (`where-the-brake-request-lives`, `what-the-bus-costs-the-abs`) were skipped: their
numbers come from simulation. No deck file was edited.

Every arithmetic example was recomputed. The figure `05-frame-bits.svg` was checked by rebuilding
the frame: ID 1A0h, DLC 8, data `00 00 F8 43 00 00 00 00` (8700 << 1 at start bit 17) gives
CRC-15 3F84h and 13 stuff bits, as drawn.

## Problems

Ordered by severity, most severe first.

| file:line | Deck claim | Verdict | Correction | Source |
|---|---|---|---|---|
| 08-timing.md:171, :190, :217–221 | simple response-time form "valid while R ≤ T"; "safe as long as R stays below T" | wrong | "valid while the frame's busy period (the time the bus stays busy with this and higher-priority frames) ends within its period T; near full load even R ≤ T is not enough (Davis et al. 2007)". Our frames (busy period 0.81 ms, T ≥ 10 ms) still meet the real condition, so the numbers stand | Bril, Lukkien, Davis, Burns, TU/e CS-Report 06-19 (2006): "even when deadlines are within periods" one job is not enough; its example is optimistic at ≈ 98 % load |
| 04-physical-layer.md:272–276, caption :287–290 | round trip must arrive "before the sample point", 2L·5 ns/m + 350 ns ≤ sample point × T_bit, giving 40–52 m at 1 Mbit/s | imprecise | the round trip must fit in Sync + Prop segment, because Phase 1 is kept free to absorb clock and phase errors. Suggest: "…must come back within the propagation segment, before the sample point; using the whole span up to the sample point gives an upper bound". It also contradicts the deck's own bit-timing slide (04:324), where Prop "covers the round trip" | Bosch CAN 2.0 Part A, bit timing: PROP_SEG compensates "physical delay times"; phase segments compensate edge phase errors |
| 03-networks-in-a-car.md:56, :77, :91 | "the high-speed standard requires at least 30" nodes; "≥ 30 possible" | unverifiable | ISO text not readable here; TI transceiver datasheets describe ISO 11898 as giving "a maximum of 30 nodes" (with 40 m bus, 0.3 m stubs). Suggest: "ISO 11898-2 is commonly quoted for 30 nodes; transceivers with high input resistance allow more" | TI SN65HVD1050 and SN65HVD251 datasheets, application section |
| 04-physical-layer.md:132, :140–141, :152–154; diagram 04-ls-levels.svg | ISO 11898-3 dominant: CAN_H 3.6–4 V, CAN_L 1–1.4 V, difference +2.2 to +3 V | imprecise | only lower/upper bounds are specified: CAN_H ≥ V_CC − 1.4 V (3.6 V), CAN_L ≤ 1.4 V, so the difference is "at least +2.2 V, typically about +3 V". Recessive is CAN_H ≤ 0.2 V and CAN_L ≥ V_CC − 0.2 V, so "≈ −5 V" is fine | NXP TJA1055 datasheet Rev. 04, Table 8 (V_O(dom), V_O(reces)) |
| 09-diagnostics.md:242, :277 (also 02-osi-layers.md:284, :311, outside scope) | ISO-TP first frame announces "up to 4095 bytes" | imprecise | "up to 4095 bytes (ISO 15765-2:2016 adds an escape form for up to 4 GB)" | Wikipedia ISO 15765-2; SAE J1979-2 FF escape proposal (12-bit FF_DL, 4-byte form above 4095) |
| 09-diagnostics.md:143 | "Diagnostics is the one place where CAN works with requests and answers" | imprecise | "Diagnostics is the main place where CAN works with requests and answers". The deck itself lists remote frames (05:96); J1939 request messages, CANopen SDO and XCP are also request/response | deck 05:96; Bosch CAN 2.0 (remote frame) |
| 08-timing.md:190, :217 | original analysis is "Tindell, Burns and Wellings (1995)"; "the original analysis from 1995" | imprecise | the analysis first appeared in 1994 (Tindell, Hansson, Wellings, RTSS 1994; Tindell & Burns 1994); the 1995 Control Engineering Practice paper is its journal form. Suggest "Tindell et al. (1994, 1995)" | Davis et al. 2007 abstract (White Rose eprint 2423): "the original 1994 analysis"; TU/e 06-19 ref. [10] |
| 06-signals.md:34 | the length sets the range: factor × 2^length | imprecise | "factor × (2^length − 1)" (the table's own numbers use this: 0.25 × 65535 = 16 383.75) | arithmetic |
| 06-signals.md:213, :240 | 401Fh × 0.25 = 4104 rpm | imprecise | 401Fh = 16 415; × 0.25 = 4103.75. Write "≈ 4104 rpm" | arithmetic |
| 04-physical-layer.md:347–348 | SJW "typically 1 to 4 tq, never more than Phase 2" | imprecise | "1 to 4 tq, never more than the shorter phase segment". Bosch 2.0 caps SJW at min(4, Phase 1); with the slide's Phase 1 = 5, Phase 2 = 3 (a layout CAN 2.0 does not allow, since Phase 2 = max(Phase 1, IPT); ISO 11898-1:2015 does), the binding cap is Phase 2 = 3 | Bosch CAN 2.0 Part A, bit timing |
| 05-frame-and-arbitration.md:98 | overload frame "Sent by: a receiver" | imprecise | "any node": the second overload condition, a dominant bit during intermission, is detected by the transmitter too | Bosch CAN 2.0 Part A, 3.1.4 |

## Briefly re-verified (previous review's corrections)

All hold: recessive near 2.5 V set by transceivers; stuff bit after five equal bits; error frame
plus intermission 17–23 bits; 1–2 periods late (model-specific); warning near 96 (Bosch: "greater
than about 96"); 1A0h for vehicle speed (consistent across 05, 06 and the figure); bus-off recovery
after 128 × 11 recessive bits; TEC +8 on transmit errors (Bosch rule 3, with two exceptions). The
R ≤ T wording is the one that does not hold; see the table.

## Checked and correct

About 120 claims were checked and found correct. Among them: history (Bosch 1983, SAE Detroit
February 1986, Intel 82526 / Philips 82C200 1987, W140 1991, ISO 11898 November 1993, CAN FD 2012
and ISO 11898-1:2015, CAN XL in ISO 11898-1:2024 and CiA 610-1, 2048 bytes, ≤ 20 Mbit/s); FD CRC
17/21 bits and the 16-byte boundary; FlexRay 10 Mbit/s, 254 bytes; Ethernet IEEE 802.3bw/bp/cg;
LS-FT up to 125 kbit/s and 32 nodes; LIN 20 kbit/s, 1 + 15 nodes; HS levels and the 0.5/0.9 V
thresholds; 120 Ω, the 60 Ω check, split termination; 0.3 m stubs; 8–25 tq; stuffing guaranteeing
a resync edge within 10 bits; frame 47 + 8n bits, stuffed region 34 + 8n, worst case
8n + 47 + ⌊(34 + 8n − 1)/4⌋ = 135 bits, 270/540/1080/135 µs; arbitration IDs 711h/2A0h/265h and the
losing bits; error rules (+8 receive case, error passive at 128, bus off at 256, suspend 8 bits);
residual error 4.7 × 10⁻¹¹; TEC reaching 256 after 32 failures; DBC syntax and the 280h/1A0h signal
ranges, B8h, 1F40h and both start bits; bus load 5.67 % and the R values 0.54/0.81/0.81 ms (and
4× at 125 kbit/s: 22.7 %, 2.16/3.24 ms); phase lag 18/36/72/144° and 108° for 30 ms; J1962 pins;
EOBD 2001/2004, US 1996 and CAN-only from 2008; 7DF/7E8, `02 01 0D` → `03 41 0D 57` = 87 km/h; UDS
service IDs and the 7F negative response; the ISO-TP VIN exchange (10 14, 30 00 00, 21/22); Jeep
2015 and the 1.4 million recall; UNECE R155 for all new vehicles from July 2024.

## Sources

- Bosch, CAN Specification 2.0, Part A (Sept. 1991), mirror at esd.cs.ucr.edu/webres/can20.pdf
- Bril, Lukkien, Davis, Burns, "Message response time analysis for ideal CAN refuted",
  TU/e CS-Report 06-19 (2006), www-users.york.ac.uk/~rd17/papers/CANrefuted.pdf
- Davis, Burns, Bril, Lukkien, Real-Time Systems 35(3), 2007, abstract at eprints.whiterose.ac.uk/2423
- NXP TJA1055 fault-tolerant CAN transceiver datasheet, Rev. 04 (2009)
- TI SN65HVD1050 / SN65HVD251 datasheets, application and implementation sections
- CiA, CAN XL and CAN history pages (can-cia.org); ISO 11898-1:2024 catalog entry (iso.org/standard/86384)
- Wikipedia: On-board diagnostics (J1962 pins, EOBD dates, 2008 CAN mandate); ISO 15765-2
- Microchip and NI LIN pages (16 nodes, 1–20 kbit/s)
- Press coverage of the FCA recall, 24 July 2015 (Fortune, CBS, Dark Reading)
- UK VCA and TÜV Rheinland pages on UN R155 dates
