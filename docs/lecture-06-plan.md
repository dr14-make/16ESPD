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

**S7 — The CAN car carries the real architecture, with as much on the bus as a car carries.**
The ABS ECU reads the four wheel-speed sensors on its own wires and estimates reference speed and
slip itself (`HandsOn03/RefSpeedEstimator`), instead of reading the true slip from the car's
measurement bus. It then publishes vehicle speed and the wheel speeds on the bus, as a real brake
unit does (the Fabia cluster's speedometer reads the `Bremse` frames). Steering angle, yaw rate
and the pedal request go on the bus as smart-sensor messages. Only the caliper torques stay wired:
they are hydraulic lines. The `ideal` switch is the "without CAN" comparison on the same canvas;
the point-to-point `PlanarBEVDrive` is the wiring picture. The change is made to the CAN car in
the #262–#265 stack, not as a second car, and it is work for the Dyad agent (§ Car change).

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
| ABS stop from 80 km/h, ideal bus | 26.839 m (= point-to-point); remeasure after S7 | #262 |
| same, 10 / 20 / 40 ms chassis messages | 27.496 / 28.415 / 28.210 m; remeasure after S7 | #262 |
| car's bus load at 500 kbit/s | 7.45 %; remeasure after S7 | `can_schedule`, #263 |
| worst-case response times | 0.28 ms (ABS active) – 1.03 ms (dashboard); remeasure after S7 | `can_schedule`, #263 |
| top-level connections, point-to-point → bus | 29 → 23; recount after S7 | #262 |
| harness mass and wire length, current car | to verify | Bosch Automotive Handbook; Navet & Simonot-Lion |

The #262 numbers are on true slip. After S7 the ABS runs on estimated slip, so every number in
this table except the harness row moves.

The 40 ms stop is shorter than the 20 ms one; the distances agree from 1e-5 to 1e-10 tolerance,
so it is the message period beating against the ABS's 5 ms cycle, not solver noise. The deck
shows it as a warning against reading period sweeps as monotone.

## Live build (students, about 90 minutes, starters in `dyad/HandsOn06/`)

| Step | Students do | Checkpoint |
|---|---|---|
| 1a | open the point-to-point car, delete the ECU-to-ECU wires, connect every ECU node to one bus; count the wires before and after | ideal bus reproduces the point-to-point stop; the wire count |
| 1b | inside one node, add the pedal-request message by hand: `CanTxReal` at the sender, `CanRxReal` at the receiver, choosing slot, ID, period and scale | the car drives as before on the ideal bus |
| 2 | run `check_can` on a starter where two ECUs transmit on the same slot; read the sentence, fix it | model compiles; `check_can` silent |
| 3 | switch to the realistic bus and sweep the chassis period 10 / 20 / 40 ms | stopping distance per period, remeasured after S7 |
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

The S7 change, on top of #265. A full brief with checks goes in `lecture-06-dyad-tasks.md` when
the agent picks it up.

1. `CanBrakeNode` takes the four wheel speeds (`omega_*` from the car's measurement bus) instead
   of the four slips, and estimates reference speed and slip with `RefSpeedEstimator`; `BusSlip`
   leaves the CAN car.
2. The brake node transmits vehicle speed and the four wheel speeds; `CanSensorNode` stops sending
   vehicle speed and keeps steering angle, yaw rate and the dashboard message.
3. The pedal torque request goes on the bus to the blend node.
4. The `ideal` bus still reproduces a point-to-point car running the same estimator.
5. Remeasure the reality-anchor table and the 10 / 20 / 40 ms sweep; regenerate the DBC and the
   `can_schedule` report; keep the Fabia cluster's speed source pointed at the new message.
6. The hands-on in `dyad/HandsOn06/`: ECU nodes with both wired ports and a bus port; a step 1a
   starter (point-to-point wiring), a step 1b starter (bus, pedal request missing), a step 2
   starter (two transmitters on one slot); reference solutions; tests pinning every checkpoint.

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
