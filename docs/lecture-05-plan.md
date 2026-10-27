# Lecture 5 — Hybrids: design

The design document for Lecture 5. Read `lecture-04-plan.md` first: this lecture reuses its
machine, converter, battery, platform and regen blending, and its settled decisions S2, S4, S7, S9
and S10 hold here unchanged.

| Document | Holds |
|---|---|
| `lecture-05-plan.md` (this file) | scope, thesis, model ladder, settled decisions, reality anchors, build, deck |
| `lecture-04-plan.md` | the battery-electric car this lecture builds on |
| `research_notes/Electric and hybrid vehicles/teaching_materials.md` §5 | P0–P4 studies (ICCT 2022: Schaeffler, Chalmers, TU Braunschweig) and ORNL machine data |

## Source and scope

`materials/Hybrids/7. Electric vehicles and Electric Machines.pptx`, slides 9–19: series and
parallel hybrids, degree of hybridization and BSFC, cost drivers, the P0–P4 positions and their
characteristics, the controller architecture, other hybridization types. Fuel-cell vehicles
(deck 8: 17–34) are the extra pack, where they return as a series hybrid with a different source.

## Thesis

**A hybrid saves fuel by moving the engine's operating point, and the clutch decides how far it
can move it.**

Lecture 2's engine spends most of WLTC far from its best BSFC. A hybrid adds a machine and a small
battery so that the engine runs where it is efficient or not at all, and braking energy comes back.
Students build a P2 hybrid on a CVT, steer the engine onto its best-BSFC line, and write the energy
manager that decides when the engine runs. The lecturer then moves the machine to every other
position and shows the result the deck describes in words: the decoupling clutch matters more
than the machine's power.

## The model ladder

| Level | Model | What it adds | Built in |
|---|---|---|---|
| H0 | Lecture 2's `MapEngine` car | conventional baseline, L/100 km on WLTC | reference |
| H1 | P2 powertrain | `MapEngine` → K0 clutch → L4 machine (≈ 30 kW) → `CVTDriveline` → planar differential; L4 battery at ≈ 1.4 kWh | step 1 |
| H2 | H1 + operating line | CVT ratio commanded to hold the engine on its best-BSFC line for the requested power | step 2 |
| H3 | H2 + energy manager | rule-based modes inside an SoC window, with hysteresis; regen through L4's blending | step 3 |
| H4 | P0, P1, P3, P4 variants | the same parts on different flanges | lecturer demo |

## Settled decisions

**S1 — Students build P2; the P-position comparison is a demo.** P2 is the position where every
hybrid mode (electric drive, boost, regen, charging, engine-off sailing) is possible, so one energy
manager exercises them all. Moving the machine to P0, P1, P3 and P4 is the same experiment five
times; it is one table the lecturer shows.

**S2 — The transmission is the existing `CVTDriveline`.** The course has no stepped gearbox, and
the CVT gives the energy manager the one degree of freedom that explains the fuel saving: it chooses
the engine speed. The layout is engine → K0 → P2 machine → CVT → differential, with P3 at the CVT
output and P4 on the rear flanges. A stepped gearbox goes to the extra pack.

**S3 — The energy manager is rule-based.** Modes: electric only at low demand, engine on the
operating line, boost when demand exceeds the engine's line, regen when braking, charge when SoC
is low. Mode changes use Lecture 2's `HysteresisLatch` so they do not chatter, and follow the house
rule of continuous latches without events (Lecture 2 S7). No optimizer (ECMS, dynamic programming)
in the build; ECMS is a theory slide.

**S4 — Results are charge-sustaining.** A hybrid that ends WLTC with less charge than it started
borrowed fuel from the battery. The fuel figure is SoC-corrected, and the check is that SoC returns
to its start within a stated band.

**S5 — The series hybrid is homework, on prepared ground.** The course library ships an
engine-generator part with its mount and a WLTC bench; the student wires the series layout and
writes the SoC thermostat. It is the same shape as the fuel-cell car in the extra pack.

**S6 — Machine and battery are sized like a full hybrid.** ≈ 30 kW and ≈ 1.4 kWh, as in the
ORNL-benchmarked 2011 Sonata Hybrid (30 kW P2 with an engine clutch, 1.4 kWh, 270 V). The demo also
runs a 15 kW case, the size the ICCT-reviewed studies compare positions at.

## Reality anchors

| Quantity | Band | Source |
|---|---|---|
| WLTC CO₂ reduction, P0, 15–16 kW | 4–9 % | ICCT 2022 (Schaeffler, Chalmers) |
| WLTC CO₂ reduction, P1, 15 kW | 8.5–10.4 % | ICCT 2022 |
| WLTC CO₂ reduction, P2, 15 kW | 12–25 % | ICCT 2022; spread depends on the baseline (with or without stop/start) |
| WLTC CO₂ reduction, P3, 15 kW | 15–25 % | ICCT 2022 |
| WLTC CO₂ reduction, P4+P0 | ≈ 15.5 % (15 kW) | ICCT 2022 (Schaeffler) |
| Ranking | P0 < P1 ≪ P2 ≈ P3 ≈ P4 | consistent across all three studies |
| P0 belt-drive system efficiency | 86–88 % peak; belt loss 1–6 % | ORNL, Hyundai HSG |
| SoC drift over WLTC | within ± 2 % of capacity | assumed charge-sustaining tolerance |

The studies compare against stop/start or a no-stop/start baseline on DCT cars; our baseline is
Lecture 2's car with a CVT and idling at stops. The table is compared for ranking and order of
magnitude, and the deck says which baseline each number uses.

## Live build (students, in `MyCar` on `handson-05`)

| Step | Students build | Checkpoint |
|---|---|---|
| 1 | P2 powertrain on the planar car | engine-only and electric-only runs both follow WLTC |
| 2 | engine operating line: CVT ratio from requested power | engine points sit on the best-BSFC line of the L2 map |
| 3 | rule-based energy manager | modes switch without chatter; SoC stays in its window |
| 4 | charge-sustaining WLTC | SoC-corrected L/100 km: conventional vs hybrid vs L4 BEV (MJ/100 km) |

Prepared in the course library: the K0 clutch with its actuator, the P-position benches, the
SoC-corrected fuel calculation, the degree-of-hybridization notebook, and the series-hybrid
homework ground. Reference solutions live in `dyad/HandsOn05/`.

## Theory deck

A Slidev deck in `slides/decks/lecture-05/`, build slides interleaved.

1. Why hybridize: where Lecture 2's engine spends WLTC on its BSFC map (deck 7: 11).
2. Series and parallel (7: 9–10); the series homework. Other types (7: 19), briefly.
3. Degree of hybridization and cost (7: 11–12): micro, mild 48 V, full, plug-in.
4. P0–P4 (7: 13–17) with the decoupling argument. → step 1
5. Operating-point shifting with a CVT; e-CVT and power split, Prius as a picture. → step 2
6. Energy management (7: 18): rules, SoC window, charge sustaining; ECMS in one slide. → step 3
7. Results: the WLTC comparison and the P-position table against the ICCT studies. → step 4

## Notebooks

| Notebook | Shows |
|---|---|
| operating points | L2 engine points on its BSFC map: conventional vs P2 hybrid on WLTC |
| P-position table | the demo sweep: fuel, recovered energy, modes available per position |
| degree of hybridization | machine size 8–40 kW against fuel saving at P2 |

## Known limits

- No stepped gearbox, no shift logic: the CVT's ratio is free (extra pack).
- No engine start dynamics or start fuel penalty; engine-off phases are assumed free to restart.
- No emissions beyond fuel; catalyst cool-down during electric phases is not modeled.
- The P4 variant drives the rear flanges through its own reduction; it is not torque vectoring.
