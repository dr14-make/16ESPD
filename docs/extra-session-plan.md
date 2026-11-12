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
| `research_notes/Electric and hybrid vehicles/hydrogen.md` (new) | stations, fueling protocol, FCEVs, efficiency chain, PEM data |

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
| 01 | Cells and chemistries | deck 8 tour cut to what is on the road now: LFP vs NMC, sodium-ion; specific energy and cost today | table, prices |
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
| 01 | Cells and chemistries | 15 | 5 | the comparison table only (LFP, NMC, sodium-ion, cost) |
| 02 | The Thevenin cell | 15 | 5 | the circuit and the pulse-response plot |
| 03 | The BMS | 15 | 7 | SoC drift and its OCV reset; balancing as one picture |
| 04 | Charging | 40 | 25 | CC-CV, the three measured curves, losses, 400 V vs 800 V, CZ network; drops connector history, ISO 15118 detail, degradation |
| — | Break | 15 | — | |
| 05 | Fuel cells | 20 | 10 | polarization curve and the stack; drops chemistry types and thermal detail |
| 06 | Hydrogen | 35 | 20 | fueling at 700 bar, station chain, counts and closures, price; drops storage alternatives (hydrides, chemical) |
| 07 | The fuel-cell car | 15 | 10 | Mirai as a series hybrid, the efficiency chain BEV vs FCEV |
| 08 | Wrap-up | 5 | 5 | |
| | **Total** | **180** | **90** | |

The cut is not a second deck. Each slide the 90-minute version skips is marked in its frontmatter,
so the same source builds both; skipped slides stay in the handout. The cut protects charging and
hydrogen, the topics this session exists for, and takes its time from the battery sections, which
recall Lecture 4.

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
| CV voltage, NCA / LFP cell | 4.20 V / 3.6 V; cutoff ≈ C/50 (not the usual C/20) | verified, datasheets |
| End of CC on the course Leaf at 50 kW | ≈ 4.05 V per cell (14 V pack I·R) | computed |
| Leaf 40 kWh DC | 46 kW peak, 10–80 % in 43 min; throttles above 32 °C | secondary |
| Leaf pack warming per charge | 6.5 °C DC vs 2.9 °C AC | verified, INL |
| 10–80 %, 800 V vs 400 V | Ioniq 5 18 min, Taycan 2024 18 min / Model Y 27, ID.3 28 | OEM verified / secondary |
| Charging loss | AC 11 kW 5.1–7.0 %, socket 12.7–24.2 %, DC 5–15 % (+2–8 % cold) | verified, ADAC 2026 |
| Fast-charge degradation | 2.3 %/yr mean; ≤ 3.0 % heavy DC vs ≈ 1.5 % AC | verified, Geotab 2026 |
| CZ public points, end 2025 | 7,574, 12.8 % ≥ 150 kW | secondary |
| 700 bar fueling | precool −40 °C, tank gas ≤ 85 °C, dispenser ≤ 875 bar | verified, DOE |
| Compression and precooling energy | ≈ 3 kWh/kg (1.7–6.4) + 0.15–0.2 kWh/kg | verified, DOE |
| Mirai | 5.6 kg H₂, 0.79 kg/100 km, 128 kW, 330 cells | verified, Toyota |
| H₂ price | DE ≈ €13–19/kg; CA $34.55/kg (Oct 2024); Praha 278 CZK/kg (2023) | mixed, see note |
| Stations | world 1,160 (end 2024); DE ≈ 50 (Jan 2026, was 80+); CA 50 retail, 74 % availability | secondary / CARB verified |
| FCEV sales 2025 | world 16,011; Europe 566; Germany 49 registrations | secondary / KBA verified |
| Power to wheel | BEV 69 %, FCEV 26 %; Mirai ≈ 46 kWh electricity/100 km ≈ 2.5× BEV | Agora / computed |
| Grey H₂ | 10–14 kg CO₂e/kg H₂ | verified, IEA |
| PEM stack parameters | Pukrushpan P2000 set: 381 cells, 280 cm², i_max 2.2 A/cm² | verified; check b₁₁ misprint |

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
