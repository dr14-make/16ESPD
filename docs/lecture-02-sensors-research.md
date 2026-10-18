# Lecture 2, section 04 (sensors): what to add and where to get it

Research only; the deck is unchanged. Reads with `lecture-02-engine-research.md` (models F1–F3),
`lecture-02-deck-figure-plan.md` (figure classes R/G/D/N/K, `CardExport` cards) and
`lecture-02-notebooks.md` (notebook 09). Every number carries its source. Tags follow the engine
research note: **(verified)** read in the primary document, **(search summary)** seen only in a
search result or a secondary page, **(derived)** computed here from verified numbers, **(assumed)**
an illustrative value that needs no source but must be labeled so on the slide.

## 1. Gap analysis

### What section 04 covers now (10 content slides)

| Slide | Content | Depth |
|---|---|---|
| 04.2 `automotive-sensors` | sensor in the loop (Bosch figure, redrawn) | good |
| 04.3 `sensor-classification` | curve types, output-signal types, live card | good |
| 04.4 | requirements, reliability classes | good |
| 04.5 `basic-control-system` | 21-part layout; names crank (14), phase (10), knock (11) sensors | names only |
| 04.6 | position sensors, potentiometer, "trend to wear-free" | thin |
| 04.7 `tps` | dual-track potentiometer, V1 + V2 = 5 V plausibility, worn-track plot | good |
| 04.8 `etc` | drive-by-wire loop, limp home, step response | good |
| 04.9 | wear-free sensors: inductive, eddy current, Hall, as a bullet list | **thin**: no principle, no signal, no use |
| 04.10 `temperature-sensors` | NTC, Bosch M12 curve | good |
| 04.11 `maf` | hot-film principle; MAP/speed-density only in the speaker notes | MAF good, **MAP missing on the slide** |

### Missing or thin

- **Crankshaft and camshaft sensing**: named on 04.5 and in section 06 (coil-on-plug, "once the
  ECU knows the crank angle"), never explained. Everything crank-synchronous in sections 05 and 06
  (injection timing, spark advance in degrees, dwell) rests on it. The largest gap.
- **Hall and magnetoresistive principles**: 04.9 lists "Hall effect" with no physics, no
  switching/linear distinction, no differential sensing.
- **Misfire detection** from crank speed: absent. It is the textbook example of a sensor reused for
  diagnosis, and OBD law sets its thresholds.
- **Pressure sensors** (MAP, barometric, fuel rail): the hands-on engine runs speed-density on
  manifold pressure, yet MAP lives only in the 04.11 notes.
- **Knock sensor**: named on 04.5 and 06 (`ignition-advance` "the knock sensor pulls the spark back")
  with no sensor physics.
- **What the sensor puts on its wire, and the ECU's fault checks**: 04.3 shows amplitude/frequency/
  pulse width abstractly; ratiometric 5 V, open-collector pulse trains, SENT and out-of-range /
  rationality checks are not named. The TPS slide already demonstrates one plausibility check.
- **Contactless pedal/throttle sensors**: 04.7 says "today electronic throttles"; the sensor in a
  modern pedal is a dual-die Hall angle sensor, not a potentiometer.

### Already elsewhere: don't duplicate

- **λ probes**: section 07 `oxygen-sensor` covers ZrO₂ switching vs broadband (LSU 4.9 card), the
  300 °C light-off and the heater. Nothing to add in 04. NOx sensors and exhaust-gas temperature
  are optional, one bullet at most, and belong in 07 next to the catalyst, not in 04.
- **Hot-film MAF dynamics**: planned as `HotFilmMAF` in notebook 09 (closed loop inside the
  sensor). Section 04's slide is enough until that model lands.
- **Knock control** (retard step, advance ramp): section 06 and model G4. Section 04 gets only the
  sensor; 06 keeps the loop.

### Belongs to another lecture

| Topic | Where | Why |
|---|---|---|
| **CAN and in-vehicle networking** (frames, arbitration, gateways, LIN/FlexRay/Ethernet) | **CAN lecture** | separate lecture; in 04 mention at most "covered in the CAN lecture" |
| Smart sensors that report over the bus (steering-angle sensor, yaw-rate/acceleration cluster, battery sensor, radar/camera objects) | CAN lecture (bus side); 10–12 (function side) | their interface *is* the bus |
| Wheel-speed sensors in depth (active 7/14 mA current interface, AK protocol, magnetic encoder rings) | 10–11, ABS/ESP/TCS | one bridge line in 04 only: "the same Hall/GMR sensor reads a wheel in the ABS lecture" |
| Inertial sensors (MEMS yaw rate, acceleration) | 10–12 | chassis, not engine |
| Ultrasonic, radar, lidar, camera | 12 and 14 (CARLA) | assistance and autonomy |
| Motor position sensors (resolver, rotor angle) | 6–8, electric drives | same Hall/MR physics; mention as a forward link if 04 covers MR |

## 2. Proposed additions, ranked

Total if all are taken: **+9 to +13 slides** (section 04 has 10 content slides today). Section
anchors use the current order. Figures follow the figure-plan classes: **N** new figure from code,
**D** redrawn diagram.

### A1. Crankshaft and camshaft position: the 60−2 wheel (3 slides)

**Goes:** directly after 04.9 *Wear-free sensors* (which already ends "the crankshaft and camshaft
position sensors are usually Hall or inductive sensors reading a toothed wheel"), after A2 if A2 is
taken.

**Outline.**
1. *The trigger wheel*: 60 tooth positions, two removed: 6° per pitch, the gap is the once-per-rev
   reference; the first tooth after the gap is tooth 1. Tooth frequency in Hz equals the engine speed
   in rpm. Front pulley or flywheel mounting.
2. *Two sensors, two waveforms*: VR (passive, two wires, amplitude grows with speed, zero crossing
   marks the tooth center, nothing at standstill) against Hall (active, three wires, a square wave
   from 0 rpm, edge at a fixed field threshold). Live card: the same 60−2 wheel through both, gap
   marked, at cranking and at 3000 rpm.
3. *Where is TDC, and which cylinder*: the gap fixes crank angle modulo 360°; a four-stroke cycle is
   720°, so a cam sensor (half speed) supplies the phase. Without it, wasted spark still works but
   sequential injection does not. Sync is lost → injection and spark stop; the cam signal alone
   gives a degraded limp mode (common practice; confirm against Reif, *Gasoline Engine Management*,
   before it goes on a slide).

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| 60−2 pitch, gap | 6° per position; gap between edges spans 3 pitches = 18° | (derived) from 60 positions / 360° |
| Tooth frequency | f [Hz] = n [rpm]; 800 rpm → 800 Hz, 6000 rpm → 6 kHz | (derived) |
| Gap signature | tooth period after the gap ≈ 3× the one before at constant speed | (derived) |
| Bosch IS-C inductive sensor | 60−2 wheel, Ø160.43 mm, tooth 4.1 mm / gap 4.3 mm; air gap 0.8 ± 0.3 mm; coil 340 Ω, ≤ 64 mH; ≤ 15 kHz; −40…230 °C head; "speed reflected on the interval between the voltage's zero transition points" | Bosch Motorsport IS-C datasheet (verified) |
| VR needs a minimum speed | "an inductive sensor needs a base speed to produce a measurable voltage; speeds cannot be measured from standstill"; Hall sensors detect rotation from standstill | Bosch Motorsport "Drehzahlsensoren" general information (verified, German) |
| VR amplitude range | about 0.5 V at low speed to about 22 V at high speed (one Ford design) | US 6885186 B2 (search summary) |
| VR zero crossing | "practically invariant to speed of rotation"; adaptive arming threshold rises with amplitude | Woodward MotoHawk VR documentation (verified) |
| Infineon TLE4929C (Hall crank IC) | supply 4.0–16 V; 0–8 kHz at full accuracy; jitter ≤ 0.015° crank (3σ); differential Hall, back-bias magnet; calibrated after 3–4 magnetic edges; direction by pulse width, 45 µs forward / 180 µs backward; open drain, 1.2 kΩ pull-up | TLE4929C-X2A datasheet (verified) |
| Bosch HA-P2 (Hall) | ≤ 10 kHz; air gap 0.5–2.5 mm; open collector, 1 kΩ load | Bosch Motorsport HA-P2 datasheet (search summary) |
| 720° and cam phase | cycle spans two crank revolutions, so 2 × (60−2) pulses per cycle; the cam wheel identifies the cylinder | US 11603806, US 5469823 (search summary) |

**Figure.** **N**, `illustrations` notebook (idealized, like `sensor-classification`): crank angle
0–720° on x; rows: 60−2 tooth pattern, VR voltage at 300 and 3000 rpm (v ∝ dΦ/dt, so amplitude
scales with speed; zero crossings fixed), Hall output (square wave, same edges), cam signal (one
pulse per 720°), TDC of cylinder 1 marked. Plus **D**: a redrawn sensor-over-wheel sketch (magnet,
coil or Hall IC, air gap).

### A2. Magnetic sensing principles: Hall and magnetoresistive (1–2 slides, rewrite of 04.9)

**Goes:** replaces or extends 04.9 *Wear-free sensors*, before A1.

**Outline.**
1. *Hall effect*: current through a semiconductor plate, field perpendicular, Lorentz force pushes
   carriers sideways, U_H ∝ I·B. Switching Hall (latch/switch with hysteresis: cam phase, gear
   tooth) against linear Hall (output ∝ B: angle, position, current). Differential (two or three
   plates, e.g. TLE4929) rejects stray fields and air-gap drift. Back-biased: a magnet behind the IC
   and a ferrous wheel; or a bare IC reading a magnetized multipole ring.
2. *Magnetoresistive (AMR/GMR/TMR)*: resistance varies with field direction in the chip plane; about
   50× more sensitive than Hall, > 50 % larger maximum air gap, best edge repeatability, but limited
   linear range. Used for crank (Allegro ATS16951) and wheel speed (Infineon TLE5045iC). One line:
   "the same chip reads a wheel in the ABS lecture" and the rotor angle in the e-motor lecture.

Keep the eddy-current and short-circuit-ring bullets of 04.9 as one line ("inductive position
sensors: an AC coil and a conducting target") or drop them: no engine sensor in the deck uses them,
and inductive (eddy-current) pedal/throttle sensors exist but are a minority next to Hall.

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| GMR vs Hall | sensitivity ~50× Hall; max air gap > 50 % larger "in most cases"; best edge repeatability; limited linear range | Allegro AN296248 (verified) |
| GMR crank IC | extended air gap, lower jitter than Hall | Allegro ATS16951 product page (search summary) |
| GMR wheel-speed IC | two-wire 7/14 mA current interface, jitter 0.02 %, −40…190 °C | Infineon TLE5045iC product page (search summary) — for the ABS lecture |

**Figure.** **D**: Hall plate (reuse OpenStax CC BY 4.0 figure, or redraw it), next to a back-biased
differential sensor over a tooth/gap. No model needed.

### A3. Misfire detection from crank speed (1–2 slides)

**Goes:** right after A1 (it is the crank sensor reused for diagnosis).

**Outline.**
1. Each firing accelerates the crank; a misfire removes one torque pulse, so the tooth periods over
   that cylinder's segment grow. The ECU computes segment times per cylinder from the 60−2 signal
   and flags outliers. OBD demands per-cylinder identification from the second crank revolution
   after start, with two thresholds: misfire that would overheat the catalyst (per 200 revolutions,
   MIL blinks) and misfire that would raise emissions above 1.5 × the limit (per 1000 revolutions).
2. Why it is hard: the speed dip shrinks with 1/ω, so at high speed and low load it drowns in
   torsional vibration and wheel tolerances. Live card: crank speed through four cylinders with one
   misfire, at 2000 and 6000 rpm.

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| Catalyst-damage misfire | % misfire per **200-revolution** increments for each speed/load; criterion may be set at 5 % where the damage level is below that | 13 CCR 1968.2 (e)(3.2.1), CARB OBD II (verified, 2006 clean text) |
| Emissions misfire | % misfire per **1000-revolution** increments that would exceed 1.5 × FTP standards; floor 1 % | 13 CCR 1968.2 (e)(3.2.2) (verified) |
| Monitoring | "no later than the end of the second crankshaft revolution after engine start"; cylinder-specific fault code | 13 CCR 1968.2 (e)(3.1), (3.3.1) (verified) |
| One OEM calibration | catalyst-damage threshold ≈ 4.7 % over 200 revolutions | GM 2012 OBD "Engine Diagnostics" mode 6 tables (search summary) |
| Size of the dip | four-cylinder, mean torque 50 Nm, J = 0.15 kg·m² (assumed): missing work T·π = 157 J; Δω ≈ W/(Jω) ≈ 5 rad/s (2.4 %) at 2000 rpm, 1.7 rad/s (0.27 %) at 6000 rpm | (derived) from ½Jω²; J and torque (assumed) |
| Tooth timing noise | TLE4929 jitter 0.015° against a 6° pitch: 0.25 % of one tooth period | (derived) |

**Figure.** **N**: from a Dyad model (see hands-on H2) or, before that, the `illustrations` notebook:
crank speed against crank angle over two cycles, one cylinder misfiring, two speeds; below, the
per-cylinder segment time with the threshold line.

### A4. Pressure sensors: MAP, barometric, fuel rail (1–2 slides)

**Goes:** after 04.11 `maf` (MAP is the alternative load signal the `maf` notes already introduce).

**Outline.**
1. *Piezoresistive MEMS*: a silicon diaphragm with diffused resistors in a Wheatstone bridge, a
   vacuum reference for absolute pressure, an ASIC for gain and temperature compensation;
   ratiometric output. MAP feeds speed-density (the hands-on engine's maps are read at speed and
   manifold pressure; idle sits at 33 kPa). The barometric sensor (often inside the ECU) corrects
   for altitude; many ECUs read baro from the MAP before cranking (common practice, unverified).
2. *Rail pressure (GDI)*: a steel diaphragm with strain gauges, 0–280 bar or more; it closes the
   high-pressure pump loop (section 05). Optional: in-cylinder pressure sensors exist in research
   and some production diesels, one line.

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| Bosch PS-AA (MAP) | absolute, 0.1–1.15 bar or 0.2–2.5 bar; supply 4.75–5.25 V; full-scale output 0.4–4.65 V at 5 V, ratiometric; 4,048 mV/bar, offset −4.8 mV (1.15 bar variant); T10/90 = 1 ms; ±0.016 bar; −40…130 °C; recommended ECU RC low-pass τ = 2 ms; "piezo-resistive sensor element" | Bosch Motorsport PS-AA datasheet (verified) |
| MAP output at the hands-on idle point | 33 kPa → 4.048·0.33 − 0.005 = 1.33 V; 100 kPa → 4.04 V | (derived) from PS-AA |
| Bosch PST-F 2 (GDI rail) | 0–280 bar absolute, max 340 bar; 0.5–4.5 V ratiometric; 14.3 mV/bar, offset 500 mV; T10/90 = 0.2–0.8 ms; strain gauges on a steel diaphragm; built-in NTC (10 kΩ at 25 °C) | Bosch Motorsport PST-F 2 280 bar datasheet (verified) |
| Diagnostic bands | outputs below ~0.2 V or above ~4.8 V treated as faults on PST-F 2 | retailer copy (search summary): verify before quoting |

**Figure.** **N**, `09-sensors`: PS-AA transfer line (V against kPa) with the 0.4/4.65 V limits and
the out-of-range bands shaded; the idle (33 kPa) and full-load (95 kPa) points of the hands-on
engine marked. Optionally the 1 ms sensor plus 2 ms RC filter on the `maf-tip-in` manifold-pressure
trace from notebook 12.

### A5. Knock sensor (1–2 slides)

**Goes:** after A4, the last sensor before the interface slide. Section 06 `ignition-advance` keeps
the loop and links back here.

**Outline.**
1. *The sensor*: a piezoceramic ring under a seismic mass, bolted to the block; block vibration →
   force → charge/voltage. Broadband accelerometer, not a resonant one. Mounting torque and a clean
   flat seat set its coupling.
2. *Finding knock in the noise*: knock is an acoustic resonance of the gas in the cylinder at
   several kHz; the ECU band-passes around it, rectifies and integrates inside a crank-angle window
   after TDC per cylinder (from the crank signal, A1), compares with a learned background level, and
   retards that cylinder's spark (section 06). Signal chain per Guzzella & Onder §4.2 (TOC verified;
   details to check in the book).

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| Bosch KS4-P | 3–25 kHz; 26 ± 8 mV/g at 5 kHz; main resonance 30 kHz; > 1 MΩ; 1,150 ± 200 pF; −40…150 °C; M8, 20 ± 5 Nm; seismic mass + piezoceramic | Bosch Motorsport KS4-P datasheet (verified) |
| Knock frequency | f = ρ_mn·c/(πB), first mode ρ₁₀ = 1.841 (Draper) | US 9835514 (search summary); VEMS manual (search summary) |
| Example | B = 86 mm, c ≈ 900 m/s in the hot end gas (assumed) → f ≈ 6.1 kHz | (derived) |
| Observed bands | "around 6.3 kHz", "about 8 kHz", "4–14 kHz" for a single knock event | patents US 10480479, US 7299680, US 5215059 (search summary) |
| Chain | pressure oscillation → block vibration (accelerometer) → audible noise | MIT OCW 2.61 lecture 10, slide "Steps to audible knock" (verified) |
| Knock control | feedback of spark timing on a knock sensor lets the engine run near its knock limit; most critical at WOT, low speed | MIT OCW 2.61 lecture 10 (verified) |

**Figure.** **N**, `illustrations` or `09-sensors`: synthetic accelerometer trace for one cycle
(engine noise plus a damped 6 kHz burst after TDC), the band-pass output, the crank-angle window and
the integrated value against the threshold, for a normal and a knocking cycle. Idealized; label so.

### A6. What a sensor puts on its wire, and how the ECU checks it (1 slide)

**Goes:** before the summary; it collects the signal types the section has met.

**Outline.** One table, one example per row from this section:

| Signal | Example in 04 | ECU check |
|---|---|---|
| Ratiometric analog 0.5–4.5 V of a 5 V reference | TPS, MAP, rail pressure | out of range (short to ground/supply, open wire) |
| Resistance in a divider | NTC | out of range; rationality (coolant ≈ intake air after a long soak) |
| Pulse train, VR or Hall | crank, cam | tooth count per revolution, gap where expected, cam edge in its window |
| PWM / SENT (SAE J2716) | Hall angle sensor in pedal or throttle | frame CRC, status nibble, timeout |
| Redundant pair | dual-track TPS, pedal | tracks agree (sum = 5 V, or 2:1 ratio) |
| Bus message | smart sensors | **covered in the CAN lecture** |

Ratiometric means the sensor and the ADC share the 5 V reference, so supply drift cancels. SENT is a
one-wire, one-way digital frame: each nibble is a time between falling edges, so it rides on the
same wire and connector as an analog sensor.

**Key numbers.**

| Item | Value | Source |
|---|---|---|
| SENT tick | 3–90 µs, sender's choice; 3 µs typical | Wikipedia "SENT (protocol)" (verified); PicoScope SENT guide (search summary) |
| SENT frame | 56-tick sync/calibration pulse; nibble = 12–27 ticks (value + 12); status + 6 data nibbles + CRC; two 12-bit fast channels; slow channel over many frames | Wikipedia (verified); Typhoon HIL SENT reference (search summary) |
| SENT tolerance | ±20 % clock tolerance, receiver rescales from the sync pulse | PicoScope (search summary) |
| Melexis MLX90377 dual-die angle sensor | SENT (SAE J2716 APR2016), PWM, SPC or ratiometric analog; 12-bit; SENT 3 µs tick, 320-tick frame → 0.96 ms refresh, ≈ 1.9 ms latency; PWM 100–2000 Hz; dual die "full redundant"; ASIL-C capable (SENT/PWM), ASIL-B (analog); applications: pedal, throttle | MLX90377 datasheet rev. 003 (verified) |
| Pedal tracks 2:1 | one track counts 0–100 %, the other 0–50 % (VW) | Ross-Tech wiki (search summary; OEM-specific, cite as an example only) |

**Figure.** **N**, `illustrations`: one SENT frame drawn from a 12-bit value (sync, status, six
nibbles, CRC) on a time axis in ticks. Small and exact, since the encoding is fully specified.

### A7. Contactless pedal and throttle position (1 slide, optional)

**Goes:** after 04.8 `etc`, or fold into A6's "redundant pair" row if slides are short.

**Outline.** A magnet on the shaft, a Hall angle IC (Triaxis-type, sensing the field direction) in
the housing: no wiper, no wear. Two independent dies in one package give two outputs; the pedal
module adds a second track at a different slope so a short between the two lines is visible. The
ECU's drive-by-wire monitor compares pedal tracks, throttle tracks and the air mass expected for
that opening (a second-level rationality check) and drops to limp home on disagreement. The
pedal-throttle-air cross-check is described in Reif, *Gasoline Engine Management* (not read here:
verify before the slide).

**Key numbers.** MLX90377 row in A6; linearity error ±1° (XY mode), hysteresis ≤ 0.2° (MLX90377
datasheet, verified).

**Figure.** Reuse the existing `tps-tracks` card; add a 2:1 pedal pair beside it (**N**, `09-sensors`,
a three-line addition to the TPS cell).

### Dropped or demoted

- **Eddy-current and capacitive proximity sensors**: no engine function in this deck depends on
  them; one line in A2 at most.
- **In-cylinder pressure sensors**: research and niche production; one line in A4.
- **NOx sensor, EGT**: section 07 if anywhere.
- **Fuel level, oil level/quality**: low teaching value here.

## 3. Optional hands-on and notebook ideas

All are Pluto cells or small Dyad components in the house style; none needs a new library. Effort
assumes the author knows the repo.

| # | Idea | Where | Effort | What students see |
|---|---|---|---|---|
| H1 | **60−2 signal and speed estimation**: generate tooth edges from θ(t) for a cranking-to-idle run-up; detect the gap (period ratio > 2); estimate speed per tooth with a 1 MHz timer; plot quantization error (≈ 0.6 % per tooth at 6000 rpm, 167 µs per tooth, derived) and jitter against averaging over 1, 6, 60 teeth | Pluto, `09-sensors`; pure Julia, no solver | 0.5 day | why the ECU averages over a cylinder segment; why speed is noisy at high rpm |
| H2 | **Misfire in crank speed**: crank `Inertia` driven by four phased torque pulses (`RotationalComponents`), a load torque, one pulse dropped; segment times per cylinder | Dyad component + Pluto cell | 1 day | the dip, its 1/ω shrink; set the threshold, count misfires per 200 revs |
| H3 | **VR vs Hall waveform**: v = N·dΦ/dθ·ω with Φ(θ) from the tooth profile; zero crossing vs fixed threshold; amplitude at 100 rpm vs 6000 rpm | Pluto, extends H1 | 2–3 h | why VR fails at cranking; why its edge is a zero crossing |
| H4 | **Knock window**: synthetic block vibration plus a damped burst; band-pass, rectify, integrate in a crank window; vary noise and window | Pluto, DSP only | 0.5 day | the detection trade-off; links to section 06's retard/advance loop (G4) |
| H5 | **MAP chain**: PS-AA transfer line, 2 ms RC, 10-bit ADC, out-of-range bands; inject a short and an open wire | Pluto, `09-sensors` | 2 h | a diagnostic code from first principles |
| H6 | **SENT decoder**: encode and decode one frame, flip a bit, watch the CRC catch it | Pluto | 2–3 h | digital sensor interfaces without a bus |

H1 + H2 together are the strongest pair: they reuse the crank signal the deck already depends on
and end in a regulation number.

## 4. Sources

Access: **free** (open web), **paywalled**, **library** (CTU access likely). Reuse: **cite**
(numbers are facts; redraw any figure in our own style), **reuse with attribution** (license
allows), **no reuse** (cite only, do not redraw closely).

### Textbooks and handbooks

| Source | Good for | Access | Figure reuse |
|---|---|---|---|
| K. Reif (ed.), *Sensoren im Kraftfahrzeug*, Bosch Fachinformation Automobil, Vieweg+Teubner, 1st ed. 2010, 221 figs; DOI listed as 10.1007/978-3-8348-2208-6 (catalog, search summary). English counterpart: Bosch *Sensors in the Motor Vehicle* (yellow series) | the reference for every principle here: Hall, MR, VR, piezo, MEMS pressure, knock | paywalled / library | cite only; redraw |
| K. Reif (ed.), *Automotive Mechatronics*, Bosch Professional Automotive Information, Springer Vieweg 2015, ISBN 978-3-658-03974-5 (search summary, catalogs) | English chapters on travel/angle, engine-speed, pressure, temperature, flow, gas sensors | paywalled / library | cite only |
| K. Reif (ed.), *Gasoline Engine Management*, Springer Vieweg 2014, ISBN 978-3-658-03963-9 (already in the engine survey) | crank/cam sync, knock control, OBD misfire in system context | paywalled | cite only |
| Bosch, *Automotive Handbook*, 11th ed., Wiley 2022, ISBN 978-1-119-91190-6 | sensor overview chapter | paywalled | cite only |
| L. Guzzella, C. Onder, *Introduction to Modeling and Control of IC Engine Systems*, 2nd ed., Springer 2010, DOI 10.1007/978-3-642-10775-7 | §4.2 knock detection and control; Ch. 3 crank-synchronous discrete-event models | paywalled | cite; models re-derivable |
| U. Kiencke, L. Nielsen, *Automotive Control Systems*, 2nd ed., Springer 2005, DOI 10.1007/b137654 | engine management chapter (misfire, knock) | paywalled | cite only |
| W. Cheng, MIT OCW 2.61 *Internal Combustion Engines*, Spring 2017, Lecture 10 "SI engine combustion (cont.); knock", [PDF](https://ocw.mit.edu/courses/2-61-internal-combustion-engines-spring-2017/35c1c5bbf304c0f41e1de0cec0b0ee85_MIT2_61S17_lec10.pdf) (verified) | knock chain, control strategy | free | **CC BY-NC-SA 4.0** for MIT's own slides; the knock pressure-trace (Heywood Fig. 9-59, McGraw-Hill) and spectrogram (SAE 980893) are **explicitly excluded** from the license: cite only |

### Datasheets and application notes (all free; cite numbers, redraw figures)

| Source | URL | Good for |
|---|---|---|
| Bosch Motorsport, *Inductive Speed Sensor IS-C*, V1, 2016 | [PDF](https://www.bosch-motorsport.com/media/downloads/inductive_speed_sensor_is-c.pdf) (verified) | VR sensor and its 60−2 wheel geometry (A1) |
| Bosch Motorsport, *Drehzahlsensoren* (general information, German), 2011 | [PDF](https://www.bosch-motorsport.de/content/downloads/Raceparts/Resources/pdf/Generelle%20Informationen_207941131_Speed_Sensor_Hall-Effect_HA-M.pdf) (verified) | VR vs Hall in one page (A1, A2) |
| Bosch Motorsport, *Hall Effect Speed Sensor HA-P2* | [PDF](https://www.bosch-motorsport-shop.com.au/assets/files/0232103111_Hall_Effect_Speed_sensor_DE.pdf) (search summary) | Hall gear-tooth sensor numbers (A1) |
| Infineon, *TLE4929C-X2A* datasheet | [PDF](https://www.infineon.com/assets/row/public/documents/24/49/infineon-tle4929c-x2a-m38n-datasheet-en.pdf) (verified) | differential Hall crank IC: jitter, calibration, direction pulses (A1) |
| Allegro, AN296248 *GMR versus Hall effect for speed sensors* | [PDF](https://www.allegromicro.com/-/media/files/application-notes/an296248_gmr-vs-hall-speed-sensors.pdf) (verified) | Hall vs GMR table (A2) |
| Allegro, crankshaft and camshaft sensor IC pages (ATS16951 GMR, ATS601, ATS673/674 TPOS) | [crank](https://www.allegromicro.com/en/products/sense/magnetic-speed/crankshaft-sensor-ics) (search summary) | TPOS cam sensing, GMR crank (A1, A2) |
| Infineon, *TLE5045iC* product page | [page](https://infineon.com/cms/en/product/sensor/magnetic-sensors/magnetic-speed-sensors/tle5045ic-r050) (search summary) | GMR wheel-speed bridge to the ABS lecture |
| Woodward, MotoHawk *Variable Reluctance Signal Behavior* | [page](https://mcs.woodward.com/content/motohawk/Documentation/MotoHawk2025aSP0/HTML/MotoHawk_topics/VRInterfacing.html) (verified) | VR zero crossing, adaptive threshold, polarity (A1, H3) |
| Analog Devices, *MAX9924–MAX9927 VR sensor interface* | [PDF](https://wcm-cce.cldnet.analog.com/media/en/technical-documentation/data-sheets/MAX9924-MAX9927.pdf) (search summary; fetch failed) | adaptive peak threshold and zero-crossing conditioning (A1, H3) |
| Bosch Motorsport, *Pressure Sensor Air PS-AA*, 2026 | [PDF](https://www.bosch-motorsport.com/media/catalog_content/downloads_catalog/pdf_catalog/data_sheet_69416587_pressure_sensor_air_ps-aa.pdf) (verified) | MAP transfer line, response, filter (A4, H5) |
| Bosch Motorsport, *Pressure Sensor Combined PST-F 2 280 bar*, 2026 | [PDF](https://www.bosch-motorsport.com/media/catalog_content/downloads_catalog/pdf_catalog/data_sheet_70473483_pressure_sensor_combined_pst-f_2_280_bar.pdf) (verified) | GDI rail pressure, combined NTC (A4) |
| Bosch Motorsport, *Knock Sensor KS4-P*, 2026 | [PDF](https://www.bosch-motorsport.com/content/downloads/Raceparts/Resources/pdf/Data%20Sheet_69010059_Knock_Sensor_KS4-P.pdf) (verified) | knock sensor numbers and mounting (A5) |
| Melexis, *MLX90377 Triaxis position sensor IC*, rev. 003 | [PDF](https://media.melexis.com/-/media/files/documents/datasheets/mlx90377-datasheet-melexis.pdf) (verified) | dual-die Hall angle sensor, SENT/PWM/analog, ASIL (A6, A7) |

Bosch Motorsport datasheets are Bosch copyright with no reuse license: numbers are citable, figures
must be redrawn, product photos not reused. Same for Infineon, Allegro, Melexis, Analog Devices.

### Regulations, standards, open references

| Source | Good for | Access | Reuse |
|---|---|---|---|
| CARB, 13 CCR §1968.2, *Malfunction and Diagnostic System Requirements … (OBD II)*, 2006 clean text, [PDF](https://ww2.arb.ca.gov/sites/default/files/barcu/regact/obdii06/19682clean.pdf) (verified). Current amendments: [2022 final order](https://ww2.arb.ca.gov/sites/default/files/barcu/regact/2022/accii/2acciifro1968.2.pdf) (not read) | misfire thresholds, monitoring conditions (A3) | free | quote freely with citation (regulation text) |
| SAE J2716, *SENT* (APR2016) | the SENT standard itself | paywalled (SAE) | cite only |
| Wikipedia, "SENT (protocol)", [page](https://en.wikipedia.org/wiki/SENT_(protocol)) (verified) | SENT frame summary (A6) | free | text CC BY-SA 4.0; we only cite |
| PicoScope, *Decoding SENT protocol (SAE J2716)*, [page](https://www.picoauto.com/library/product-news/sent-protocol-decoding-and-diagnosis-guide) (search summary) | worked tick/nibble example | free | cite only |
| OpenStax *College Physics*, Fig. 22.27 Hall effect, via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Openstax_college-physics_22.27_Hall-effect.jpg) (verified) | Hall plate figure (A2) | free | **CC BY 4.0: reuse with attribution** |
| Wikimedia Commons, *Hall-Effect-diagram.svg* (Gregors, 2011), [file](https://commons.wikimedia.org/wiki/File:Hall-Effect-diagram.svg) (verified) | alternative Hall diagram, SVG | free | **CC BY-SA 3.0 / GFDL: reuse with attribution, share-alike on the adapted image** |
| US patents 6885186 (VR amplitude), 11603806 and 5469823 (cam/crank sync), 9835514 (Draper knock frequency), 10480479 / 7299680 / 5215059 (knock bands), 5862507 (misfire from crank sampling) | numbers and mechanisms where no datasheet states them | free (USPTO, Google Patents) | cite; redraw rather than copy |

No openly licensed university lecture notes on engine sensors turned up (one standard search);
MIT OCW 2.61 is the only open course, and its sensor-relevant figures are third-party. Wikimedia
Commons has no crank-sensor or 60−2 diagram with a clear license (category search came back empty),
so the crank figures should come from our own code (A1) anyway.

## Open decisions for the lecturer

- **Slide budget**: all of A1–A7 adds 9–13 slides to a 10-slide section. A minimal cut is A1 + A2
  (merged into 04.9) + A4: +5 slides. A3 and A5 are the next two; A6 and A7 can fold into one.
- **Knock**: sensor in 04 and control in 06 (proposed), or everything in 06 next to the advance map.
- **Misfire**: here (as a crank-sensor reuse) or with OBD in section 07; there is no OBD slide yet.
- **Wheel speed**: one bridge line in 04 (proposed) with the full sensor in the ABS lecture, or none.
- **Which hands-on, if any**: H1 + H2 recommended; H4–H6 only if notebook 09 grows beyond Tier 3.
