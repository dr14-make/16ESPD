# Lecture 6 — CAN bus: design

The design document for Lecture 6. The car is Lecture 4's planar BEV with its ABS and ESP from
Lecture 3; the bus blocks come from #262, #263 and #265.

| Document | Holds |
|---|---|
| `lecture-06-plan.md` (this file) | scope, thesis, settled decisions, analogy, reality anchors, build, deck |
| `research_notes/CAN bus/pptx-audit.md` | slide-by-slide inventory of the source deck, coverage, errors, gap sources |
| `research_notes/CAN bus/analogy.md` | candidate analogies scored against CAN, with sources |

## Source and scope

`materials/CANBus/6. Multiplexing in car electronic systems – CAN bus.pptx`, 34 slides:
multiplexing (3–6), OSI (7–15), history, LIN, MOST and two 2004 car networks (16–21), physical
layer and topology (22–25), frame, stuffing, arbitration, ACK (26–30), errors and fault
confinement (31–33), network-health diagnosis (34).

The source deck has no bus load or response time, no DBC or signal scaling, no counters or
checksums, no CAN FD or CAN XL, no FlexRay or Ethernet, no OBD-II, UDS or ISO-TP. Those are the
topics the model shows best, so the deck adds them from the sources in the audit.

## Thesis

**A bus trades wires for time: every signal on it arrives late, quantized and on a schedule, and
the car has to be designed so that does not matter.**

Students see the bus replace point-to-point wires in the car they already know, then pay for it:
the ABS stopping distance grows with the message period, and the bus load says how much room is
left.

## Settled decisions

**S1 — One analogy: a meeting room with strict speaking rules.** It replaces the railway (4) and
TV (5) slides and runs through the OSI and CAN sections. "CAN is not a post office" is the one
contrast, on the OSI slide: no address on the envelope, no receipt from an addressee. The deck
says where the analogy stops: on the arbitration slide (people do not clap in sync, nodes sample
the same bit at the same instant) and on the physical-layer slide. It states that an ID names the
topic, never the sender.

**S2 — OSI stays, mapped to CAN.** The nine generic slides become one table per layer: what
classic CAN puts there and what the meeting room puts there. CAN fills 1, 2 and 7; 3–6 are empty
because everyone is in one room speaking one language, with ISO-TP (4) and UDS sessions (5) as
the diagnostic exceptions. A second slide says which layers the Dyad blocks model: `CanTx`/`CanRx`
model 6–7 and the message period, `can_schedule` summarizes 2, nothing models 1.

**S3 — Hands-on: put the car on the bus, then read off its cost.** Students rewire the
point-to-point car onto one bus and add one message by hand, fix a `check_can` error, sweep the
message period against the ABS stop and read the bus load (§ Live build).

**S4 — Streaming is a lecturer demo.** The CAN blocks are plain discrete-time models and run in
Dyad Studio on any OS with no adapter. SocketCAN streaming (`candump`, the Fabia cluster) needs
Linux and CANBus.jl from `sim/`, so it runs on the lecturer's laptop only.

**S5 — The deck says what `check_can` is not.** It catches wiring mistakes in the model, not CAN
protocol errors; error frames and TEC/REC stay theory.

**S7 — The CAN car carries the real EV architecture (#269).** The brake ECU reads the four
wheel-speed sensors on its own wires and estimates reference speed and slip itself (the library's
wheel-only estimator). The brake pedal is wired to it (hydraulics plus travel sensor), and it does
the regen/friction blending and drives the calipers, as iBooster + ESP hev or VW MEB do. On the bus
it publishes vehicle speed, the four wheel speeds, the held ABS status (the cluster lamp reads it)
and the regen torque request to the VCU; the accelerator is wired to the VCU. Steering angle and
yaw rate come from the sensor node over the bus. The ABS loop never crosses the bus. The `ideal`
switch reproduces the point-to-point twin `PlanarBEVDriveEstimated` run for run.
`PlanarBEVCanBusBrake` keeps the earlier layout, with the brake request crossing the bus twice, as
the counterexample for step 3. The ABS-active flag is held from the first genuine release to
brake release or standstill, as real units report it.

**S6 — The source deck's errors are corrected, not repeated.**

| Slide | Claim | Correction |
|---|---|---|
| 17 | Bosch proprietary | ISO 11898 since 1993 |
| 17 | asynchronous | receivers resynchronize on edges every bit |
| 17 | max 16 ECUs HS, 18 LS | carmaker design rule; ISO 11898-2 ≥ 30 nodes, 11898-3 up to 32 |
| 17 | 1 Mbit/s, 0–8 bytes | classic CAN only; CAN FD 64 bytes, CAN XL 2048 |
| 19 | MOST | obsolete; replaced by automotive Ethernet |
| 24 | star equal to bus for HS | HS-CAN is a linear bus with short stubs |
| 26 | frame table | missing the 3-bit intermission |
| 29 notes | retransmit six bit clocks after the end | retries once the bus is idle after EOF and intermission |
| 32 | bus-off needs a reset | recovery after 128 × 11 recessive bits |
| 33 | +1 or 8 | +8 on transmit errors, mostly +1 on receive errors |

## The analogy, layer by layer

| # | OSI layer | Classic CAN | Meeting room |
|---|---|---|---|
| 7 | Application | ID and signal meaning: DBC, J1939, CANopen, OBD-II/UDS | the agenda: topic 0x1A0 is vehicle speed |
| 6 | Presentation | not defined; the DBC's factor, offset and byte order | agreed units: "87.00" means km/h, to the hundredth (the real signal's factor is 0.01 km/h) |
| 5 | Session | empty; UDS session control in diagnostics | empty; a private consultation with the chair |
| 4 | Transport | empty; ISO-TP for long diagnostic messages | empty; a long report in numbered installments |
| 3 | Network | empty: no addresses, no routing; a gateway works at layer 7 | one room; an interpreter in the doorway |
| 2 | Data link | SOF, arbitration, stuffing, CRC, ACK, error frames, fault confinement, filtering | one clap to start, clap the topic number, after five same beats, one opposite beat (so never six), check number, any listener nods, "STOP!", strikes → whisper → leave the room, ignore topics you do not need |
| 1 | Physical | CAN_H/CAN_L, dominant/recessive, bit rate, 120 Ω | clap and silence, speaking pace; the analogy stops here |

## Reality anchors

| Quantity | Value | Source |
|---|---|---|
| ABS stop from 80 km/h, ideal bus = point-to-point | 28.11 m mean (28.02–28.25) | sweep, #269 |
| real layout, 10 / 20 / 40 ms, mean (range) | 28.90 (28.62–29.06) / 29.50 (28.98–30.02) / 30.22 (30.02–30.44) m | sweep, #269 |
| brake request on the bus, 10 / 20 / 40 ms | 30.10 (28.79–30.74) / 29.62 (29.32–29.95) / 33.64 (31.79–35.78) m | sweep, #269 |
| car's bus load at 500 / 250 kbit/s | 13.45 % / 26.9 % | `can_schedule`, #269 |
| worst-case response times at 500 kbit/s | 0.28 ms (ABS status) – 1.48 ms (regen request, dashboard) | `can_schedule`, #269 |
| top-level signal nets, point-to-point → bus | 31 → 19 (library car); 22 → 19 (hands-on starter) | #269 |
| harness, premium car | > 4 km, > 3000 wires, ≈ 700 connectors, ≈ 60 kg (average car 25–45 kg); Peugeot 306 → 307: 635 → 370 wires | `research_notes/CAN bus/harness-figures.md` |

Each sweep cell is six stops with the pedal press shifted over 0–40 ms
(`assets/data/lecture06/can_stop.csv`). With the brake request on the bus a single stop is phase
luck: where the press falls between frames decides whether the first ABS cycle overshoots, so one
car spreads up to 4 m and 20 ms can beat 10 ms. The real layout spreads at most 0.5 m and costs
about 2 m at 40 ms, the late regen request; we accept that as the price of the bus. The
counterexample briefly locks a rear wheel at one 10 ms timing; the real layout never does.

## Live build (students, about 90 minutes, starters in `dyad/HandsOn06/`)

| Step | Students do | Checkpoint |
|---|---|---|
| 1a | open the point-to-point car, delete the ECU-to-ECU wires and switch the nodes to the bus (the backbone is pre-connected); count the wires before and after | ideal bus reproduces the point-to-point stop, 28.185 m; 22 → 19 nets |
| 1b | inside the brake ECU, add the regen-request message by hand (`CanTxReal`; the VCU's `CanRxReal` is in place), choosing slot, ID, period and scale | the car stops as before on the ideal bus, 28.185 m |
| 2 | run `check_can` on a starter where two ECUs transmit on the same slot; read the sentence, fix it | model compiles; `check_can` silent |
| 3 | switch to the realistic bus and sweep the chassis period 10 / 20 / 40 ms, real layout against the brake-request-on-the-bus car | stopping distance per period; the sweep's means and ranges |
| 4 | in the Julia REPL, run `can_schedule` on the car; then halve the bit rate or add a fast message and run it again | bus load at 500 kbit/s; how the load and response times move |

Lecturer demo at the end: the scripted drive streamed to `candump`, then the real Škoda Fabia
cluster over PCAN-USB, with its counters and checksums.

Settled for the build:
- **Step 1** works at two levels: the whole architecture first (ECU nodes with both wired ports
  and a bus port, so the rewiring is visible on the car's canvas), then one message by hand, so
  the scaling from section 06 is practiced. Wiring every message by hand would take most of the
  session.
- **Step 2** plants one mistake, two ECUs on one slot: a real design error (two ECUs claiming one
  identifier), unlike a missing `CanTermination`, which students would confuse with the 120 Ω
  resistor.
- **Step 4** runs in the REPL, as Lecture 5's build plots there; no notebook, no custom Studio
  analysis for a report-only function.

## Car change (Dyad agent)

Done in #269 over three agent runs: the wheel-only estimator, the held ABS flag, then the real EV
layout with the counterexample kept, the phase sweep and the HandsOn06 starters, references and
`handson06` tests.

## Theory deck

A Slidev deck in `slides/decks/lecture-06/`, in the source deck's order, corrected and enriched,
build slides interleaved.

1. Multiplexing: frequency, time and code sharing with a bench each; the meeting room (replaces
   4–5); wired against bused, the planar car (3–6).
2. The OSI model, one slide per layer as in the source (7–15), each mapped onto CAN and the
   meeting room; all seven at a glance; CAN is not a post office; which layers the Dyad blocks
   model.
3. Networks in a car: HS and LS CAN, LIN, the 407 and E87 networks, gateways; CAN FD, CAN XL,
   FlexRay, automotive Ethernet, zonal architectures (16–21, MOST marked obsolete).
4. Physical layer: levels, termination, topology, bit timing and sample point (22–25).
5. Frame and arbitration: fields, frame types, stuffing, arbitration, ACK (26–30).
6. Signals: DBC, factor and offset, byte order, counters and checksums (added). → step 1
7. Errors and fault confinement (31–33); what `check_can` catches instead. → step 2
8. Timing: periods, latency, bus load, response-time analysis (added). → steps 3, 4
9. Diagnostics: finding a broken wire (34); OBD-II, UDS, ISO-TP (added).
10. Demo and wrap-up: the Fabia cluster.

## Known limits

- One slot per signal: no arbitration is simulated; `can_schedule` reports, it does not run.
- No physical layer, no frame fields, no error frames or TEC/REC.
- Latency is one fixed period; no jitter, ECU clocks synchronous.
- Classic CAN only, Intel byte order only.
