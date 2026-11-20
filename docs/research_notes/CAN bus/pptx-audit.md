# Lecture 6 — CAN bus: audit of the source deck

Source: `docs/materials/CANBus/6. Multiplexing in car electronic systems – CAN bus.pptx`
(34 slides, 14 with speaker notes). Extraction in this scratchpad:

- `slides.txt` — every slide's text, media list and speaker notes
- `render/deck.pdf`, `render/h-NN.png` — LibreOffice renders, one PNG per slide
- `render/m1..m4.png` — contact sheets of the picture-heavy slides

Implementation read from PRs 262, 263, 265 (all open, stacked: 262 ← 263 ← 265) at
`origin/feat/can-fabia-cluster`.

## 1. Slide-by-slide inventory

Sections as the deck's agenda (slide 2) names them: multiplexing principles, OSI model, the CAN
protocol (introduction, error management, topology). In practice the order is
multiplexing (3–6) → OSI (7–15) → CAN overview and other buses (16–21) → physical layer (22–25)
→ data link (26–30) → errors (31–33) → diagnosis (34).

| # | Title | Key content | Diagrams / pictures | Speaker notes |
|---|---|---|---|---|
| 1 | Multiplexing in car electronic systems – CAN bus | cover | — | — |
| 2 | Agenda | multiplexing, OSI, CAN intro, error mgmt, topology | — | — |
| 3 | Multiplexing | definition; advantages (less wiring, shared sensors, flexibility); FDM, TDM, time+frequency, CDM (DSSS, "party languages") | TDM mux/demux; FDM modulators summing carriers; DSSS data XOR pseudorandom code | — |
| 4 | Analogy train | network = rails, ECU = station, message = train, bytes = wagons, bit rate = speed; train identified by number; everyone receives | clip-art train "n° 128" with passengers "engine water temperature", "engine speed" | — |
| 5 | Analogy: television | broadcast; several receivers; transmitter must repeat on error | satellite dish broadcasting to two PCs showing "Speed = 130 km/h" | — |
| 6 | Multiplexing in vehicles | traditional vs multiplexed | point-to-point wiring of speed/engine-speed sensors to ABS, AT, injection, cluster vs the same on one bus | — |
| 7 | OSI model | layered model, independence of layers | 7-layer stack picture | generic OSI prose |
| 8 | Physical layer | bits; voltages, timing, cables; examples Ethernet, FDDI, RJ45 | — | FDDI definition |
| 9 | Data link layer | frames; addressing, error detection, error frame; examples PPP, FDDI, ATM, IEEE 802.x | — | switches/MAC prose, PPP definition |
| 10 | Network layer | packets; segmentation into 8-byte frames ("30-byte packets") ; IP, IPX | — | routers/IP prose |
| 11 | Transport layer | segments; TCP, UDP | — | generic |
| 12 | Session layer | dialogue; example SQL | — | RPC, NetBIOS, SQL definitions |
| 13 | Session layer example | phone-call analogy | — | — |
| 14 | Presentation layer | encoding/encryption; TIFF, GIF, JPEG, MPEG, HTML | — | generic |
| 15 | Application layer | browsers, FTP, mail | — | generic |
| 16 | Brief summary of the CAN network | CAN HS vs CAN LSFT; history 1986, 1987, 1991 (Mercedes S-Class), ISO 11898 1993 | — | — |
| 17 | Brief summary of the CAN network | serial, "asynchronous", "Bosch proprietary"; multi-master, non-destructive arbitration, twisted pair, max 1 Mbit/s (125/250/500 at Renault), 0–8 bytes, max 16 ECUs HS / 18 LSFT; error detection, retransmission, fault confinement, bus-off | — (title overlaps body in render) | — |
| 18 | Other communication interfaces | LIN: cheap, master/slave, no collision detection | — | — |
| 19 | MOST | optical multimedia bus, API, Network Services | — | — |
| 20 | Electronic layout of 407 | Peugeot 407 network | diagram: CAN HS 500 kb/s powertrain (ECM, BVA, ESP, …), CAN LSFT 125 kb/s body and comfort, BSI as gateway, DiagOnCAN, a LIN branch to front wipers | — |
| 21 | BMW 1 Series architecture | BMW E87 network | diagram: CAN powertrain HS 500 kb/s, CAN body LS 100 kb/s, MOST 22.5 Mb/s infotainment ring, LIN sub-bus, gateway | — |
| 22 | CAN physical layer | HS (≤1 Mb/s, terminated at both ends, fails on short/open) vs LSFT (≤125 kb/s, termination distributed in nodes, survives OW/SC) | node stack (µC → CAN controller → transceiver); HS levels: recessive 2.5/2.5 V, dominant 3.5/1.5 V, differential 0/2 V; LSFT levels with ±5 V differential; scope captures | — |
| 23 | PMA – Physical Medium Attachment | — | two 120 Ω end terminations (motor control, AT) with ABS on a stub; split termination 2×60 Ω + 4.7 nF | 120 Ω matches cable impedance, prevents reflections (CSS Electronics prose) |
| 24 | Topology: possible choices | linear, star, mixed | three topology sketches with R at ends; "what does that change for my ECU" — connector with internal loop-through | — |
| 25 | CAN physical layer signaling | PLS: bit timing, bit rate 125/250/500, coding, bit synchronization because clocks are asynchronous | colored bit-level base frame (Wikipedia picture) with CAN_H/CAN_L traces | — |
| 26 | (Frame format — title hidden behind overflowing tables) | two Wikipedia tables: extended (29-bit) and base (11-bit) frame fields with lengths | bit-field strips for both formats | Wikipedia CRC definition |
| 27 | Data link layer frames | data, remote ("mileage totalizer"), error, overload frames; NRZ, bit stuffing after 5 equal bits; resync at least every 10 bits | stuffing examples, "worst re-synchronization case" | — |
| 28 | The CAN frame: the identifier | transmit when idle unless bus-off; bitwise arbitration over the identifier; loser becomes receiver, retransmits | — | — |
| 29 | Arbitration priority and collisions | wired-AND comparison | three ECUs (IDs 2A0h, 265h, 711h) with controller/transceiver; 711h drops first, 2A0h next, 265h wins | dominant/recessive explanation; "retransmits six bit clocks after the end" |
| 30 | Acknowledgement | every controller ACKs a correct frame; one node can destroy a frame with an error frame; transmitter does not know receivers | — | — |
| 31 | Error management | bit, ACK (transmitter); stuff, form, CRC (receiver) | — | — |
| 32 | Error management | error-active / error-passive / bus-off behavior; reconnection needs controller reinit | — | — |
| 33 | Error management | TEC, REC; +1 or +8; −1 on success; link to CSS Electronics tutorial | TEC/REC vs time with thresholds 96, 128, 256, active→passive→bus-off | — |
| 34 | CAN diagnostic | network diagnosis by correlation | car network with a cut stub to EPS/dashboard; matrix of who-receives-whom (OK/NOK) locating the break | — |

Observations on the deck as a whole:

- Nine of 34 slides (7–15) are generic OSI with internet examples (Ethernet, TCP, SQL, browsers);
  none maps OSI to CAN (ISO 11898-1 = data link + PCS, ISO 11898-2 = PMA; ISO-TP and UDS above).
- The architecture diagrams (Peugeot 407, BMW E87) are about 2004 vehicles; no domain or zonal
  architecture.
- Slide 26 is pasted from Wikipedia (footnote markers "[a]", hyperlinked "Cyclic redundancy
  check") and overflows the slide; slide 17's title overlaps its body. Speaker notes are mostly
  pasted definitions (Wikipedia, CSS Electronics), not lecturer notes.
- Several figures carry Renault/PSA material (Renault bit rates on slide 17).

## 2. Coverage and correctness

| Topic | Status | Slides | Remarks |
|---|---|---|---|
| Why multiplexing (wire count, weight) | partial | 3–6 | Qualitative only. No numbers (harness mass, wire count, connector count, cost). Slide 3 spends most space on FDM/CDM, which CAN does not use; CAN is TDMA-by-arbitration (CSMA/CR). |
| Bus topology & termination 120 Ω | present | 23, 24 | 120 Ω in the diagram and notes; split termination shown. Missing: total 60 Ω measured H–L as the bench check, stub-length limits, bus length vs bit rate. Star topology shown as equal choice; ISO 11898-2 HS is a linear bus with short stubs. |
| Physical layer: CAN_H/CAN_L, dominant/recessive, levels | present | 22, 29 notes | HS levels correct (2.5/2.5 V recessive, 3.5/1.5 V dominant). Dominant = 0 explained only in speaker notes of 29, not on a slide. Wired-AND, common-mode rejection and twisted pair EMC reasoning not stated. |
| Bit timing & bit rates | partial | 17, 22, 25 | Rates 125/250/500 kb/s and 1 Mb/s listed. No bit segments (sync, prop, phase 1/2), sample point, SJW, hard vs resync; no propagation-delay limit (≈40 m at 1 Mb/s). |
| HS 500 kb/s vs LS fault-tolerant 125 kb/s | present | 16, 22, 20–21 | ISO 11898-3 not named. LSFT is largely legacy in new cars. |
| Frame format | present (with defects) | 26, 25, 27 | Base and extended tables are complete (SOF, ID, SRR, IDE, RTR, r0/r1, DLC, data, CRC 15, delimiters, ACK, EOF 7). Missing intermission (3-bit IFS). Says DLC "0–8 bytes" without noting values 9–15 mean 8 in classic CAN. Copied from Wikipedia, overflows the slide. |
| Bitwise arbitration / priority | present | 28, 29 | Good worked example (2A0h/265h/711h is consistent). Speaker note "re-transmits six bit clocks after the end of the dominant message" is wrong: the loser retries when the bus goes idle after EOF and the 3-bit intermission (plus 8-bit suspend if error-passive). No "lower ID = higher priority" rule stated on a slide in words; no identifier-assignment design consequence. |
| Bit stuffing | present | 27, 31 | Correct (5 equal → opposite bit, SOF to CRC sequence; stuff error at 6). Overhead (up to ~20 %) not quantified. |
| Error detection | present | 30, 31 | Five error types correct. Missing: error frame structure (6-bit flag + 8-bit delimiter), active vs passive error flag, no bit check during arbitration and ACK slot, residual error probability. |
| Fault confinement (TEC/REC, states) | partial | 32, 33 | States and counters present. Thresholds only in the picture (128 passive, 256 bus-off). "+1 or 8 depending on the error rating" is vague: transmitter errors are +8 TEC, most receiver errors +1 REC (+8 in specific cases). Bus-off recovery stated as needing controller reinit; ISO allows recovery after 128 × 11 recessive bits, auto or host-triggered. Error-passive 8-bit suspend transmission missing. |
| Remote / overload frames | present | 27 | Overload frame described as "in case of an anomaly" — imprecise; it delays the next frame and modern controllers never generate one on their own. Remote frames discouraged by CiA/AUTOSAR; note is fine. |
| Bus load & response-time analysis | missing | — | No frame-length formula, no load calculation, no worst-case response time (Tindell/Davis). |
| Gateways, multiple buses | partial | 20, 21 | Shown in diagrams (BSI, gateway) but never explained: why split buses, routing latency, security boundary. |
| DBC files, signal scaling, byte order | missing | — | No signal vs message distinction, no factor/offset, no Intel/Motorola, no DBC. |
| Counters / checksums (E2E) | missing | — | No alive counters, CRC/XOR checksums, AUTOSAR E2E, timeouts. |
| CAN FD | missing | — | Slide 17's "max 1 Mbit/s, 0–8 bytes" is outdated for any car after ~2018: CAN FD (ISO 11898-1:2015) has up to 64 bytes and 2–8 Mbit/s data phase; CAN XL (CiA 610, ISO 11898-1:2024) up to 2048 bytes. |
| LIN / FlexRay / Automotive Ethernet | partial | 18, 19, 20–21 | LIN brief (no 19.2 kbit/s, schedule table, ISO 17987). MOST covered — now obsolete, replaced by Ethernet. FlexRay and Automotive Ethernet (100BASE-T1, 1000BASE-T1, 10BASE-T1S) missing entirely. |
| Diagnostics (OBD-II, UDS on CAN) | missing | 34 (other sense) | Slide 34 is network-health diagnosis (who hears whom), not OBD-II/UDS. No ISO 15765-4 (OBD on CAN), ISO 14229 UDS, ISO-TP segmentation (slide 10 hints at it without naming it), DTCs, 0x7DF/0x7E8. |
| Security | missing | — | Not in the checklist but worth a slide: CAN has no authentication; SecOC, gateway firewalls, Miller–Valasek Jeep. |

### Factual errors and outdated claims

- **Slide 17 "Bosch proprietary protocol"** — outdated: CAN is an ISO standard since 1993
  (ISO 11898); Bosch's licensing concerns the controller IP, the protocol is open.
- **Slide 17 "asynchronous"** — misleading: there is no separate clock line, but receivers
  synchronize to the transmitter's edges bit by bit; CAN is a bit-synchronous protocol.
- **Slide 17 "maximum of 16 ECUs on CAN HS, 18 on CAN LSFT"** — wrong as a protocol limit. ISO
  11898-2 transceivers must drive at least 30 nodes (typical datasheets 110); ISO 11898-3 LSFT
  allows up to 32. The numbers are an OEM (Renault/PSA) design rule.
- **Slide 17 "max bit rate 1 Mbit/s", "0 to 8 bytes"** — classic CAN only; CAN FD/XL omitted.
- **Slide 29 speaker notes "six bit clocks after"** — see arbitration row above.
- **Slide 32 bus-off recovery** — the standard defines automatic recovery after 128 occurrences
  of 11 recessive bits; requiring a host reset is an implementation choice.
- **Slide 33 "+1 or 8 depending on the error rating"** — imprecise (see fault-confinement row).
- **Slide 27 overload frame "generated in case of an anomaly"** — imprecise.
- **Slide 12 session layer example "SQL"** — wrong (SQL is an application-level query
  language); generic OSI slides contain several such internet-folklore examples.
- **Slide 19 MOST** — outdated technology for a current lecture.
- **Slide 24** — star topology presented as an equal choice for CAN HS without its reflection
  penalty.
- Slide 16 history is correct (Bosch at SAE 1986, Intel 82526 / Philips 82C200 in 1987,
  Mercedes W140 1991, ISO 11898 1993).

## 3. What the Dyad implementation can show live

Implementation pieces (branch `feat/can-fabia-cluster`):

- `dyad/Vehicle/Planar/CanTx.dyad` — `CanNet` connector (array of value/presence slots),
  `CanTxReal/Integer/Boolean` (slot, 11-bit `id`, `period`, `scale`, `offset`, `raw_min/raw_max`),
  `CanRx*`, `CanTermination`, `CanAdapter`; `CanLink` = periodic sampler → `CanPack`
  quantization (round, clamp to raw range) → `UnitDelay` (one frame of latency) → hold; a
  structural `ideal` switch removes the chain.
- `dyad/Vehicle/Planar/CanNodes.dyad` — the car's ECUs: sensor node (speed 0x080, steering 0x090,
  yaw 0x0A0 at 10 ms; dashboard speed 0x300 at 100 ms), blend node (friction demand 0x100,
  torque request 0x110 at 20 ms), brake node (ABS active 0x070 at 10 ms), drive node, cluster
  node.
- `dyad/Vehicle/Planar/PlanarBEVCanDrive.dyad`, `CanCruise.dyad`, `CanHardStop.dyad`.
- `dyad/Vehicle/Planar/module.jl` — `check_can`, `can_layout`, `can_encode`/`can_decode`
  (Intel, two's complement), `can_dbc` (writes a DBC with `GenMsgCycleTime`), `can_schedule`
  (worst-case frame length with stuffing `47 + 8s + ⌊(34+8s−1)/4⌋`, blocking, fixed-point
  response time, bus load).
- `dyad/can_stream.jl` + `ext/VehicleSystemsComponentsCANBusExt.jl` — paced SocketCAN streaming
  of every frame at its period to `vcan0`/`can0`; `mise run can`.
- `dyad/fabia_protocol.jl`, `FabiaCluster.dyad`, `FabiaClusterNode.dyad`, `sim/fabia/*.jl` — PQ24
  frames to a real Škoda Fabia cluster over PCAN-USB at 500 kbit/s; `mise run fabia`,
  `mise run fabia:hand`.

| Lecture topic | Feature that shows it | How it looks in the room |
|---|---|---|
| Why multiplexing | `PlanarBEVCanDrive` next to `PlanarBEVDrive`; 29 → 23 top-level connections; one multi-way `connect` | canvas comparison, the deck's slide 6 made real; honest point that wheel-speed sensing and caliper torques stay hardwired |
| Bus + termination | `CanTermination` (exactly one per bus), `check_can` refusing a bus without one or with two | conceptual only: the model's termination closes the connector, it is not 120 Ω (say so) |
| Message identifier & priority | 11-bit `id` on every `CanTx*`, asserted 0..2047; `can_schedule` orders by id | identifiers chosen by criticality (ABS 0x070 highest, dashboard 0x300 lowest) |
| Signal scaling / quantization | `CanPack` (`scale`, `offset`, raw range, saturation); `CanTxStep` bench | step through a 0.1 scale; resolution and saturation visible in a figure |
| DBC files, factor/offset, Intel | `can_dbc` writes the DBC; `can_encode/decode`; Fabia `setbits!` | open the generated DBC; decode `candump` lines by hand or with cantools/SavvyCAN |
| Byte order | Intel only (teaching layout and PQ24) | Motorola cannot be shown from the model; needs a diagram |
| Multiplexed signals in a frame | `motor_2` (0x288) mux byte cycling 0x0C/0x40/0x8F/0xC0 | candump shows the first byte rotating |
| Sampling period & latency effect | `period`, `UnitDelay`, `ideal` switch; ABS stop from 80 km/h: 26.84 m ideal, 27.50 m at 10 ms, 28.42 m at 20 ms, 28.21 m at 40 ms | the strongest figure: period dominates over transmission time; the non-monotonic 40 ms result shows aliasing against the ABS 5 ms cycle |
| Bus load & response time | `can_schedule`: 7.45 % load at 500 kbit/s, response 0.28 ms (ABS active) to 1.03 ms (dashboard) | Tindell/Davis analysis done on the car's own bus; varying bitrate/period live |
| Bit stuffing (overhead) | worst-case stuffing term in `can_schedule` frame length | numeric only; stuffing itself not simulated |
| Configuration errors | `check_can`: missing/duplicate termination, slot clash, id with two periods, Rx with no Tx | these are model wiring errors, not CAN protocol errors (say so) |
| Real traffic, tooling | `CanAdapter` + `mise run can` → `candump vcan0` (≈15 300 frames / 30 s for the car) | live candump, DBC decode, frame periods visible in `candump -td` |
| Real ECU, counters, checksums | Fabia PQ24: 4-bit counters in Bremse_1 0x1A0 and Airbag_1 0x050; XOR checksum in Motor_5 0x480 and Airbag_1; Bremse_2 distance pulses | the needle moves; candump shows the counter nibble stepping and the XOR byte. Freezing the counter or corrupting the checksum to show the cluster rejecting the frame would be a live E2E demo, but nothing in the branches does it and the cluster's reaction has not been tested on the bench |
| Network configuration / installed list | Verbauliste_1 0x5D8, Systeminfo_1 0x5D0 required before lamps react | maps onto slide 34's network-diagnosis idea and onto coding a replacement ECU |
| Two-way traffic, receiving | cluster echo Kombi_1 0x320 decoded by `decode_echo!` (speed ≈ 4 % high on the needle) | candump shows the cluster's own frames; speedometer over-reading regulation (UNECE R39) as a side note |
| Gateways / multiple buses | `check_can` handles several nets; termination inside the cluster node | no gateway block; mention, not demo |

Topics the model cannot show (need diagrams, scope captures or the bench adapter):

- bit-level arbitration and the wired-AND (no arbitration simulated: every slot is its own
  channel; `can_schedule` is a report, not a scheduler);
- physical layer: voltages, differential signaling, 120 Ω, reflections, stubs, bus length;
- bit timing, sample point, synchronization, bit stuffing on the wire;
- frame fields (SOF, CRC, ACK, EOF) — the model sends values, not frames; `candump` shows only
  id + payload;
- error detection, error frames, TEC/REC, error-passive, bus-off (no protocol errors in model
  or stream);
- jitter and asynchronous ECU clocks (all ECUs on one 5 ms grid; PR 262 scope note), queueing
  delay feeding back into control (latency is a fixed one period, not the response time);
- CAN FD, LIN, FlexRay, Ethernet; OBD-II/UDS (the Fabia cluster would answer UDS/KWP2000-on-CAN
  on its diagnostic IDs, but nothing in the branches does this);
- Motorola byte order, remote frames, overload frames.

Possible bench extensions (not implemented): `cangen`/`canbusload` from can-utils for bus
load; a PCAN adapter's error counters (`ip -details -statistics link show can0`) and unplugging
the termination to provoke error-passive/bus-off live; a cheap logic analyzer or scope on
CAN_H/CAN_L for the physical layer and stuffing.

## 4. Gaps to fill from outside sources

| Gap | Suggested sources |
|---|---|
| Frame format corrections, IFS, DLC 9–15, error frame structure, fault-confinement rules exact (+8/+1, 128/256, bus-off recovery 128×11) | Bosch, *CAN Specification 2.0* (1991), Parts A/B; ISO 11898-1:2015 (data link) |
| Physical layer: levels, termination, split termination, stubs, bus length vs bit rate | ISO 11898-2:2016 (HS PMA); CiA 301/CiA application notes on cabling; TI SLLA270 "Introduction to the CAN"; NXP TJA1044 datasheet |
| Bit timing, sample point, SJW, synchronization | ISO 11898-1; Bosch "The Configuration of the CAN Bit Timing" (Hartwich & Bassemir, 1999 iCC); CiA 601-3 (bit-time recommendations for CAN FD) |
| LSFT and single-wire CAN (legacy) | ISO 11898-3; SAE J2411 |
| Bus load and response-time analysis | Tindell, Burns, Wellings, "Calculating CAN message response times", *Control Eng. Practice* 1995; Davis, Burns, Bril, Lukkien, "CAN schedulability analysis: refuted, revisited and revised", *Real-Time Systems* 35 (2007) — the frame-length formula `can_schedule` uses |
| DBC, signals, factor/offset, Intel/Motorola | Vector "DBC File Format Documentation"; cantools documentation; CSS Electronics DBC intro (secondary) |
| Counters, checksums, E2E, timeouts | AUTOSAR Classic "Specification of SW-C End-to-End Communication Protection Library" (E2E profiles 1, 2, 5); ISO 26262-6 (freedom from interference rationale) |
| CAN FD and CAN XL | Bosch *CAN with Flexible Data-Rate* v1.0 (2012); ISO 11898-1:2015 and :2024; CiA 610-1 (CAN XL); Hartwich, "CAN with flexible data-rate", iCC 2012 |
| LIN, FlexRay, Automotive Ethernet; domain/zonal architecture | ISO 17987 (LIN); ISO 17458 (FlexRay); IEEE 802.3bw (100BASE-T1), 802.3bp (1000BASE-T1), 802.3cg (10BASE-T1S); OPEN Alliance; Zimmermann & Schmidgall, *Bussysteme in der Fahrzeugtechnik* (Springer) |
| Gateways and multiple buses | Zimmermann & Schmidgall; Navet & Simonot-Lion (eds.), *Automotive Embedded Systems Handbook* (CRC 2008) |
| OBD-II and UDS on CAN, ISO-TP | ISO 15765-2 (ISO-TP), ISO 15765-4 (OBD on CAN), ISO 14229-1/-3 (UDS), SAE J1979 (OBD PIDs) |
| Security | AUTOSAR SecOC specification; Miller & Valasek, "Remote Exploitation of an Unaltered Passenger Vehicle" (2015); UNECE R155 |
| History (to keep, verified) | Bosch CAN history page; CiA "History of CAN technology" |
| Wire-harness numbers for the multiplexing motivation | Bosch *Automotive Handbook* (networking chapter); a current OEM harness figure (e.g. harness mass ≈ 50 kg / ≈ 5 km wire in a premium car, as cited in Navet & Simonot-Lion) — verify before use |
