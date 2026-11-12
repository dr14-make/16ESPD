# Extra session — Energy on board: batteries in depth, charging and hydrogen: design

The design document for the extra session that closes the electric and hybrid block (#99, deck
#118). Read `lecture-04-plan.md` first: this session swaps its battery for a better cell, and
`lecture-05-plan.md` for the series-hybrid shape the fuel-cell car reuses.

| Document | Holds |
|---|---|
| `extra-session-plan.md` (this file) | scope, thesis, model ladder, settled decisions, reality anchors, deck |
| `lecture-04-plan.md` | the battery, BEV bench and WLTC energy bill this session extends |
| `lecture-05-plan.md` | the series-hybrid architecture and energy manager the fuel-cell car reuses |
| `research_notes/Electric and hybrid vehicles/teaching_materials.md` §3 | OCV(SoC), Leaf pack resistance |
| `research_notes/Electric and hybrid vehicles/charging.md` (new) | charging physics, curves, standards, network |
| `research_notes/Electric and hybrid vehicles/hydrogen.md` (new) | stations, fueling protocol, FCEVs, efficiency chain |
| `research_notes/Electric and hybrid vehicles/battery-terms.md` (new) | cell and pack layouts, C-rate, SoH, cycle and calendar ageing, Euro 7 durability |
| `research_notes/Electric and hybrid vehicles/pem-polarization.md` (new) | the polarization curve for the slide, Mirai comparison, Faraday |
| `research_notes/Electric and hybrid vehicles/bms.md` (new) | Thevenin parameters, SoC drift, balancing, safety limits |
| `research_notes/Electric and hybrid vehicles/energy-prices-cz.md` (new) | Czech prices and cost per 100 km |

## Source and scope

`materials/Hybrids/8. Batteries and Fuel Cells.pptx`:

| Deck 8 slides | Topic | Here |
|---|---|---|
| 3–6 | battery parameters | done in L4, recalled in one slide |
| 7–16 | chemistry tour, summary table | section 01, updated with LFP, NMC, sodium-ion |
| 17–29 | fuel-cell principles, losses, stack, thermal, balance of plant | section 05 |
| 30–34 | hydrogen as a fuel, storage | section 06, extended with stations |

Not in deck 8, added here: the Thevenin cell, CC-CV charging, SoC estimation, balancing and the
BMS (from #118 and #119), and charging infrastructure and hydrogen refueling (new, the
lecturer's request).

## Thesis

**Energy on board decides what the car is: how fast it goes back in, and what it costs to get it
there.**

Lecture 4 treated the battery as a fixed voltage behind a resistor. Here the cell gets an OCV
that moves with SoC and a relaxation, and then the two ways to refill an electric car are put
side by side: a plug, limited by the CV phase, heat and the grid, and a hydrogen nozzle, fast at
the car but long and lossy before it.

## Sections

| # | Section | Content | Model / figure |
|---|---|---|---|
| 00 | Front matter | where this sits after L4 and L5, what is a take-home | — |
| 01 | Cells and chemistries | the battery's terms on the Leaf pack (capacity, nominal voltage, gross vs usable, specific energy and power), C-rate, peak vs continuous power, cell to pack, SoC/DoD/SoH and ageing; then deck 8 tour cut to what is on the road now: LFP vs NMC, sodium-ion; specific energy and cost today | terms table, cell-to-pack diagram, ageing bars, prices |
| 02 | The Thevenin cell | OCV(SoC), R0, one RC pair; pulse response; what it fixes in L4's battery | formula plot |
| 03 | The BMS | SoC by coulomb counting and its drift; OCV correction; cell imbalance and passive balancing; limits (temperature, current, voltage) | diagrams |
| 04 | Charging | CC-CV at the cell; real DC curves (Leaf CHAdeMO with rapidgate, 400 V, 800 V); modes and connectors (Type 2, CCS2, NACS, MCS); AC vs DC losses; ISO 15118 and V2G; network in CZ/EU and AFIR | CC-CV formula plot, measured curves redrawn |
| 05 | Fuel cells | deck 8 principles and losses as a polarization curve; stack; balance of plant; Faraday hydrogen consumption | polarization-curve plot |
| 06 | Hydrogen on board and at the station | storage (Type IV 700 bar), J2601 fueling and precooling, station layout, station counts and closures, price per kg and per 100 km, AFIR Art. 6 | station chain diagram |
| 07 | The fuel-cell car | a series hybrid with a different source: stack + buffer battery on the L5 series shape; well-to-wheel against BEV and petrol | architecture diagram, efficiency chain |
| 08 | Wrap-up / take-home | the extra-pack exercises | — |

The dq PMSM model and the stepped gearbox are dropped from this deck; they move to #254.

## Timing: 3 hours, with a 90-minute cut

| # | Section | 3 h | 90 min | What the cut keeps |
|---|---|---|---|---|
| 00 | Front matter | 5 | 3 | one slide: where this sits after L4 and L5 |
| 01 | Cells and chemistries | 22 | 10 | the terms table, C-rate, and the comparison table (LFP, NMC, sodium-ion, cost) |
| 02 | The Thevenin cell | 12 | 4 | the circuit and the pulse-response plot |
| 03 | The BMS | 12 | 5 | SoC drift and its OCV reset; balancing as one picture |
| 04 | Charging | 40 | 25 | CC-CV, the three measured curves, losses, 400 V vs 800 V, CZ network; drops connector history, ISO 15118 detail, degradation |
| — | Break | 15 | — | |
| 05 | Fuel cells | 19 | 9 | polarization curve and the stack; drops chemistry types and thermal detail |
| 06 | Hydrogen | 35 | 20 | fueling at 700 bar, station chain, counts and closures, price; drops storage alternatives (hydrides, chemical) |
| 07 | The fuel-cell car | 15 | 9 | Mirai as a series hybrid, the efficiency chain BEV vs FCEV |
| 08 | Wrap-up | 5 | 5 | |
| | **Total** | **180** | **90** | |

The cut is not a second deck. Each slide the 90-minute version skips is marked in its frontmatter,
so the same source builds both; skipped slides stay in the handout. The cut protects charging and
hydrogen, the topics this session exists for, and takes its time from the battery sections, which
recall Lecture 4. Section 01 opens with the battery's terms; 02 and 03 give up time for them.

## Settled decisions

- **S1 — One session, Monday 16 Nov 2026, theory only.** A static Slidev deck in the Lecture 4
  layout with speaker notes; no live build, no new Dyad models. Matches #118.
- **S2 — No fuel-cell model.** The fuel-cell car is explained as a series hybrid with a different
  source (the Lecture 5 shape) on slides only; the polarization curve is a plotted formula, not a
  component.
- **S3 — Figures come from data, not models.** Measured charging curves, station and price data
  and the efficiency chain are redrawn from the research notes with their source tags; simple
  formula plots (CC-CV, polarization curve, Thevenin pulse response) are drawn by a notebook.
- **S4 — Leaf and Mirai are the reference cars.** The Leaf's CHAdeMO curve and rapidgate show the
  thermal limit; the Mirai anchors the FCEV numbers.
- **S5 — Secondary numbers get a primary before they reach a slide**, or are shown labeled as
  reported figures.

## Reality anchors

Labels as in the research notes; secondary numbers are flagged and need a primary before a slide.

| Quantity | Value | Source label |
|---|---|---|
| CV voltage, NCA / NMC / LFP cell | 4.20 V / 4.20 V / 3.6 V; cutoff C/50–C/96 in all three datasheets (C/20 unsupported) | verified, datasheets |
| End of CC on the course Leaf at 50 kW | ≈ 4.05 V per cell (14 V pack I·R) | computed |
| Leaf 40 kWh DC | 46 kW peak, 10–80 % in 43 min; throttles above 32 °C | secondary |
| Leaf pack warming per charge | 6.5 °C DC vs 2.9 °C AC | verified, INL |
| 10–80 %, 800 V vs 400 V | Ioniq 5 18 min, Taycan 2024 18 min / Model Y 27, ID.3 28 | OEM verified / secondary |
| Charging loss | AC 11 kW 5.1–7.0 %, socket 12.7–24.2 %, DC 5–15 % (+2–8 % cold) | verified, ADAC 2026 |
| Fast-charge degradation | 2.3 %/yr mean; ≤ 3.0 % heavy DC vs ≈ 1.5 % AC | verified, Geotab 2026 |
| CZ public points | end 2025: 7,574, 33.1 % DC, 12.8 % ≥ 150 kW; Sep 2026: 7,669, 36.1 % DC | verified, EAFO |
| EU27 public points | end 2025: 1,061,890, 18.3 % DC; Sep 2026: 1,176,554 | verified, EAFO |
| ISO 15118-20 | mandatory on new or renovated public points from 1 Jan 2027 (Reg. 2025/656) | verified |
| 700 bar fueling | precool −40 °C, tank gas ≤ 85 °C, dispenser ≤ 875 bar | verified, DOE |
| Compression and precooling energy | ≈ 3 kWh/kg (1.7–6.4) + 0.15–0.2 kWh/kg | verified, DOE |
| Mirai | 5.6 kg H₂, 0.79 kg/100 km, 128 kW, 330 cells | verified, Toyota |
| H₂ price | DE up to €19/kg (Jan 2026); CA $34.55/kg (Oct 2024); CZ 499 CZK/kg last reported (Jan 2024), 278 CZK/kg the 2023 introductory price | mixed, see note |
| Stations | world 1,160 (end 2024); DE ≈ 50 (Jan 2026, was 80+); CA 50 retail, 74 % availability | secondary / CARB verified |
| FCEV sales 2025 | world 16,011; Europe 566; Germany 49 registrations | secondary / KBA verified |
| Power to wheel | BEV 69 %, FCEV 26 %; Mirai ≈ 46 kWh electricity/100 km ≈ 2.7× the Leaf's 17.1; 69/26 also gives 2.7 | Agora / computed |
| Grey H₂ | 10–14 kg CO₂e/kg H₂ | verified, IEA |
| PEM slide curve | V = 0.950 − 0.178(1 − e^(−10i)) − 0.1575i − i(0.390i/2.2)²: 0.82/0.69/0.58/0.43 V at 0.1/0.5/1.0/1.5 A/cm²; b₁₁ = 0.005139 | verified, Pukrushpan thesis 2003 |
| Mirai gen 1 measured | ≈ 0.74 V/cell at 0.95 A/cm² | read from figure, ANL 2018 |
| Real 700 bar fills | 3.22 min, 0.9 kg/min mean over 1.85 M fills | verified, NLR |
| Thevenin cell, Leaf cell at ~60 % SoC | R0 ≈ 1.6 mΩ, R1 ≈ 1.1–1.9 mΩ, τ ≈ 19–29 s | derived, fit to ORNL HPPC |
| SoC drift | 50 mA offset on 33 Ah: 3.6 % per day | derived |
| Balancing current | TI BQ79616 240 mA, NXP MC33771C 300 mA | verified, datasheets |
| Runaway onset, 100 % SoC | NMC 85.5 / 198 °C, LFP 124 / 256 °C | verified |
| Cost per 100 km, CZ | Leaf home 120 CZK, Leaf DC 222–289, petrol 224, Mirai 394 (H₂ price weak) | derived |

## Issues

- #118 extra-pack deck: retitle and widen to charging and hydrogen; theory only per S1; dq PMSM
  and gearbox move to #254.
- #119 Thevenin cell, CC-CV bench, SoC estimator, PEM stack and FCEV bench: not for Monday. #119
  stays open as later work; the rest are not filed.
- New: commit the two research notes under `docs/research_notes/Electric and hybrid vehicles/`.

## Before Monday

1. Research notes into the repo; close the gaps that feed slides (Czech/EU totals, LBST end-2025
   counts, Pukrushpan b₁₁ check, current Czech prices for the cost per 100 km).
2. Deck skeleton with the eight sections and speaker notes.
3. Figures: redrawn charging curves, the station chain diagram, the efficiency chain, formula
   plots.
4. Landing page lists the deck as extra material; deck and handout build.
