# Lecture 4 — The battery-electric car: design

The design document for Lecture 4. Read this first. Lecture 5 (`lecture-05-plan.md`) builds on
every part made here.

| Document | Holds |
|---|---|
| `lecture-04-plan.md` (this file) | scope, thesis, model ladder, settled decisions, reality anchors, build, deck |
| `lecture-05-plan.md` | the hybrid lecture, which reuses this lecture's motor, converter and battery |
| `research_notes/Electric and hybrid vehicles/teaching_materials.md` | Leaf numbers, ORNL efficiency maps, cell data, regen and P0–P4 studies, with verification status |

## Source and scope

`materials/Hybrids/7. Electric vehicles and Electric Machines.pptx` (deck 7) and the battery
parameter slides of `materials/Hybrids/8. Batteries and Fuel Cells.pptx` (deck 8). Both decks
follow Larminie & Lowry, *Electric Vehicle Technology Explained*, closely.

| Deck 7 / 8 slides | Content | Here |
|---|---|---|
| 7: 3–7 | why EVs, history, energy model, regen, benefits | condensed into the opening; the energy model is Lecture 2 notebook 01's road load |
| 7: 8–12, 19 | BEV, series and parallel layouts, degree of hybridization, cost | BEV only; the rest is Lecture 5 |
| 7: 13–18 | P0–P4 | Lecture 5 |
| 7: 20–26 | DC motor: F = BIL, T = KΦI, back-EMF, losses, efficiency, cooling, control | **build steps 1–2**, extended (S3) |
| 7: 27–33 | DC regulation, choppers, H-bridge, PWM, three-phase, motor as brake | average models in the car; switching models as a demo (S4) |
| 7: 34–39 | BLDC, SRM, induction, machines for hybrids | extended with PMSM/FOC (S3) |
| 8: 3–6, 14–16 | battery parameters, summary table | **build step 3**, simple model (S5) |
| 8: 7–13 | chemistry tour | extra pack |
| 8: 17–34 | fuel cells and hydrogen | extra pack |

## Thesis

**An electric car is an energy chain you can close in both directions.**

Lecture 2 ended with fuel going one way, into heat and motion. Here every link — battery,
converter, motor, gear, wheel — is reversible, and each one costs a few percent each way. Students
build the chain from the motor outwards, put it into the planar car, and drive WLTC. The headline
result is the energy bill: kWh/100 km at the battery, how much braking energy came back, and the
same cycle in MJ/100 km for Lecture 2's engine.

## The model ladder

| Level | Model | What it adds | Built in |
|---|---|---|---|
| M0 | `Roadster.PowerLimitedMotor` (exists) | torque and power ceilings, no electrics, no regen | reference only |
| M1 | DC-equivalent machine | `RotationalEMF` + armature R, L; T = KΦI, E = KΦω, copper loss I²R | step 1 |
| M2 | M1 + shaft losses | the deck's loss formula as parts: T_f, K_i·ω, k_w·ω³, constant C | step 1 |
| M3 | M2 + average converter | V_out = d·V_in, I_in = d·I_out, current and voltage limits → field weakening | step 2 |
| M4 | M3 + battery | V = E − I·R, SoC by coulomb counting | step 3 |
| C1 | planar BEV | M4 → single reduction → planar `DifferentialGear` → front wheels; `RoadLoad` | step 4 |
| C2 | C1 + regen blending | motor first, L3 hydraulics for the remainder | step 5 |

## Settled decisions

**S1 — Two lectures plus an extra pack.** L4 is the battery-electric car, L5 is hybrids. The
in-depth battery (Thevenin cell, CC-CV charging, SoC estimation, balancing, BMS), fuel cells, a dq
PMSM model and a stepped gearbox go into an extra session or a take-home pack. Torque vectoring
with in-wheel motors comes later, on the same platform.

**S2 — The platform is Lecture 3's planar car.** Four wheels, four `spin_*` flanges: every
architecture in L4 and L5 is a choice of which flanges a machine drives, and torque vectoring needs
no new car. Measured: a full 1800 s WLTC on the planar car with a PI driver takes 3.3 s warm,
~27 s cold, against 6.2 s / 57 s for Lecture 2's longitudinal WLTC.

**S3 — The motor is a physical DC-equivalent machine; the efficiency map is computed, never
added.** It is built from the stdlib `RotationalEMF` with armature R and L, and the remaining
terms of deck slide 24's loss formula are parts on the shaft. Copper loss lives in the resistor,
so a measured map cannot be layered on top without counting it twice. The map is a notebook
output: sweep torque and speed, plot the contours, set them next to ORNL's measured Leaf map. The
theory justifies the model: a PMSM under field-oriented control behaves as this machine (concepts
and animation, no Clarke/Park algebra). Field weakening appears where the converter voltage
saturates. PMSM versus induction (magnets, cost, drag losses when coasting) is a theory section.

**S4 — Power electronics: average models in the car, switching models beside it.** Same rule as
Lecture 2's S1: never stack time scales. The inverter in the car is the average converter of step
2. The DC-DC converter is a constant 12 V auxiliary power draw (the deck's O_aux). The charger is a
theory slide and one efficiency. The buck chopper and the H-bridge with PWM are separate
millisecond-scale models for the lecturer's demo and a notebook, regenerating deck slides 28–32.
The stdlib has no switch, so a switch is a `VariableResistor` toggled between on and off
values. ElectricalComponents 3.0 does ship an exponential `Diode`, which the freewheeling diodes
use. Slides 29 (boost) and 32 (three-phase bridge) are diagrams with no switched model; the
notebook regenerates 28, 30 and 31.

**S5 — The battery is simple and has one interface.** V = E − I·R with constant E, SoC by coulomb
counting. The extra pack's Thevenin cell (OCV(SoC), R0, one RC pair) replaces it without
rewiring, so the connector and parameter names are chosen with that successor in mind.

**S6 — The car is the course car with Leaf-class numbers.** Same body, cycle and road load as
Lectures 1–3, so the engine-versus-motor comparison is fair; motor, gear and battery numbers come
from the Leaf ZE1. Mass is 1500 kg, the planar car's default and the Leaf's curb mass.

**S7 — Road load is one law used by both cars.** A mass-free `RoadLoad` (drag, rolling,
grade on a translational flange) is extracted from `Vehicle.VehicleBody`, which becomes
`Mass + RoadLoad` with numerically identical results. The planar car gets it through an adapter: a
speed source driven by the sensed body-frame vx, a force sensor, and `WorldForceTorque` with
`resolve_in_frame = frame_b`.

**S8 — Regen uses series blending on the Lecture 3 brakes.** The driver's brake demand goes to the
motor up to the smallest of its torque limit, the battery charge-power limit and a low-speed fade;
the remainder goes to the hydraulics through the existing allocator. A fourth, opt-in rule withdraws regen while the ABS acts on either driven wheel; the dry hard-stop bench defaults to `withdraw = 0` pending the gentle ABS calibration #156, and the low-grip bench demonstrates it enabled. WLTC does not use it. WLTC never decelerates harder
than 1.5 m/s² (0.15 g), so on WLTC friction only covers the low-speed fade (under 4 % of braking
energy). The blending is therefore shown on Lecture 3's hard stop, where the motor carries about half of
the braking, and WLTC reports the recovered energy.

**S9 — The standstill singularity is worked around on the bench.** `SlipBasedWheelJoint` puts its
regularization outside the square root, so the Jacobian turns NaN when a parked car's slip velocity
decays to exactly zero (JuliaComputing/MultibodyComponents.jl#185). The bench keeps the car off
exact zero until a fixed release ships. FBDF reports success on a frozen car; benches use Rodas5P
and check that the distance driven matches the cycle.

**S10 — Numbers carry their provenance**, as in Lecture 2's S10: `(Nissan)`, `(ORNL)`, `(INL)`,
`(EPA)`, `(EEA)`, `(EU)`, `(Audi)`, `(deck)`, `(textbook)`, `(derived)`, `(assumed)`, matching the
research note's labels.

## Reality anchors

Bands the build and the tests are checked against. Sources are in the research note.

| Quantity | Band | Source |
|---|---|---|
| Motor peak torque / power | 320 N·m / 110 kW | Nissan ZE1 (verified) |
| Base speed | 3283 rpm | Nissan ZE1 (verified) |
| Max motor speed | ≈ 10 100 rpm | derived from 144 km/h, 8.193, r = 0.31 m |
| Reduction ratio | 8.193 | Nissan ZE1 (verified) |
| Pack | 40 kWh, 350 V nominal, 96s2p | Nissan ZE1 (verified); cell config secondary |
| Pack resistance | 0.10–0.14 Ω mid-SoC, +50 % near empty | INL 2013 Leaf pulse tests (read from figure); GAO-2024 |
| Combined motor + inverter peak efficiency | 94–96 % mid speed, mid torque | ORNL 2012 Leaf (80 kW motor, see note) |
| Combined efficiency, low speed high torque | ≈ 80 % | ORNL, read from figure |
| Combined efficiency, near-zero torque | 70–80 % | ORNL, read from figure |
| Positive traction energy at wheel, WLTC | 139 Wh/km at 1500 kg | derived |
| Braking energy at wheel, WLTC | 25–26 % of traction | derived |
| Energy returned to battery, WLTC | 18–25 % of traction | derived: 25–26 % braking through a regen path of 70–87 % (Boretti, measured Leaf) up to ~95 % (ideal reduction) |
| Battery DC consumption, WLTC | 120–155 Wh/km | Leaf WLTP 171 Wh/km AC (secondary) less 10–15 % charging loss; course road load takes ~6 % less wheel energy on WLTC than EPA's Leaf coastdown (139.4 vs 148.8 Wh/km, see the road-load validation note) |
| Regen deceleration capability | 0.2–0.3 g | Nissan e-Pedal; Bosch ESP hev |

The ORNL map belongs to the 80 kW / 280 N·m first-generation motor, not the 110 kW ZE1 machine; the
comparison is of shape and level, not a fit. The low-speed regen fade speed has no primary source
and is `(assumed)` at 5–10 km/h.

## Live build (students, in `MyCar` on `handson-04`)

Theory and build are interleaved as in Lectures 1 and 3: each step follows its theory section.

| Step | Students build | Checkpoint |
|---|---|---|
| 1 | DC-equivalent machine with its losses, on a dyno bench | torque-speed curve; copper loss equals I²R |
| 2 | average converter with current and voltage limits | full envelope; torque falls as 1/ω above base speed |
| 3 | battery: V = E − I·R, SoC by coulomb counting | terminal voltage sags under load; SoC integrates |
| 4 | the car: machine → 8.193 reduction → `DifferentialGear` → front flanges | WLTC followed; distance matches the cycle |
| 5 | regen blending onto the L3 brakes | hard stop: motor share vs friction share; WLTC: recovered energy |
| 6 | WLTC energy bill | kWh/100 km at the battery; recovered vs burned; MJ/100 km vs Lecture 2 |

Prepared in the course library: `RoadLoad` and the planar adapter, the planar WLTC bench with the
driver PI and the standstill workaround, the constant 12 V auxiliary load, and the efficiency-map
notebook. Reference solutions live in `dyad/HandsOn04/`.

## Theory deck

A Slidev deck in `slides/decks/lecture-04/`, in the Lecture 3 layout, with the build slides
interleaved. Figures the models can produce are regenerated from them, not copied from the pptx.

1. Why electric, condensed (deck 7: 3–7) and the energy chain both ways.
2. The DC machine (7: 22–26): F = BIL to T = KΦI and E = KΦω; losses and efficiency. → step 1
3. Machines in real EVs (7: 34–39, extended): BLDC and PMSM, why FOC makes a PMSM look like step
   1's machine (animation), induction, SRM. PMSM versus induction; why AWD cars pair one of each.
4. The envelope (new): constant torque, field weakening, constant power; the efficiency map and
   where WLTC operating points land. → step 2
5. Power electronics (7: 27–33): DC regulation, buck and boost, H-bridge, PWM and harmonics,
   three-phase bridge; demo on the switching models. The DC-DC for 12 V. The charger.
6. Batteries, simply (8: 3–6, 14–16): V = E − IR, Ah and Wh, specific energy and power, the
   summary table. → step 3
7. The car and regen (7: 6, 33): regen limits, series versus parallel blending. → steps 4–5
8. The energy bill: WLTC results, the engine comparison. → step 6

## Notebooks

| Notebook | Shows |
|---|---|
| efficiency map | sweep of the step 1–2 machine; contours next to ORNL's Leaf map; WLTC operating points on top |
| switching | buck chopper ripple and losses; H-bridge PWM spectrum (deck slides 28–32) |
| energy bill | WLTC energy flows as a Sankey or stacked bar: road load, losses per link, regen, aux |

## Prerequisites

- Course `main` loads: the gitignored `Manifest.toml` is stale (BlockComponents 4.6 against the
  5.0 that `Project.toml` requires) and the `dyad` CLI binary reports 3.2.0. Use the pinned
  `npx @juliacomputing/dyad-cli@3.5.0` from the agent quick start in `lecture-02-plan.md`.
- `RoadLoad` extraction (S7), with Lectures 1–3 tests unchanged.
- Planar WLTC bench with road load and the standstill workaround (S9).

## Known limits

- Road load is the course law shared with Lectures 1–3 (S7), not the Leaf's coastdown. Against
  EPA's Test Car List coefficients for the Leaf ZE1 it is 1.3× at 20 km/h, equal near 50 km/h and
  0.84× at 130 km/h; its rolling coefficient 0.012 is an EU class E tire, where the Leaf's OE tire is
  class B (0.0066–0.0077). The car therefore coasts 100→20 km/h in 124 s against the Leaf's
  ~144 s, and WLTC wheel energy is ~6 % below the Leaf's. Kept so every lecture drives the same car;
  sources and the full comparison are in `docs/research_notes/Electric and hybrid vehicles/
  bev-road-load-and-braking-validation.md`.
- The machine is DC-equivalent; saliency, reluctance torque and dq dynamics are out (extra pack).
- Field weakening is a flux input on the machine (`FieldEMF`), set by the average converter where
  its duty reaches the limit. It costs nothing: a PMSM's d-axis copper loss is not modeled. The
  converter imposes its current, so it holds its voltage limit only through that field.
- The combined efficiency at low speed and high torque is 86.2 % (900 rpm at 180 N·m and
  1000 rpm at 220 N·m), against ORNL's ≈ 80 % on the 2012 Leaf. The machine alone gives 88 % there,
  inside ORNL's motor-only map; the gap is the average converter, whose loss scales only with the
  current, so it stays at 97.5 % with 113 V out where ORNL's measured inverter falls into the 80s.
  Accepted: the parameters stay fitted to the motor-only and inverter-only maps, and
  `test/efficiency_map_plausibility.jl` pins the 86.2 %.
- No thermal model of motor, inverter or battery; efficiencies are at warm operating temperature.
- Battery E is constant: SoC does not move the open-circuit voltage until the extra pack's cell.
- WLTC is gentle; the blending result on WLTC is mostly fade, so the hard stop carries that lesson.
- Reduction and differential are ideal gears. A real single-speed reducer's 2–3 % each way, on
  the 144 Wh/km of traction and 39 Wh/km of braking at the shaft, would add 4–5 Wh/km to the bill.
- Step 4's car (`Vehicle.Electric.TorqueSplit`) brakes on the motor down to 10 km/h and hands the
  rest to the front friction brakes; S8's charge-power limit, allocator and hard stop come with
  step 5. Measured on WLTC: 134.3 Wh/km at the cells, 34.2 Wh/km back into the battery
  terminals, 23.8 % of the shaft's traction energy, inside the 18–25 % anchor: the regen path
  (motor, converter, pack) returns 89 % of the shaft's braking energy, just above Boretti's
  measured 72–87 % on the MY2013 Leaf.
- Step 5's `Vehicle.Electric.RegenBlend` caps the machine's braking at the smallest of 320 N·m
  (Nissan), 80.5 kW over the machine speed (INL, the 2013 pack's 10 s charge capability) and a
  linear fade below 10 km/h (assumed), and sends the rest through Lecture 3's equal per-wheel
  demand to the four brakes. On the hard stop (`Vehicle.Planar.PlanarBEVHardStop`, Lecture 3's
  ABS stop from 80 km/h) the charge-power limit binds down to 34.3 km/h, the torque limit to
  10 km/h, the fade below; the machine takes 45 % of the braking and friction 55 %, just over half, and the stop is 33.0 m against 26.9 m on friction alone. On WLTC
  (`Vehicle.Planar.PlanarBEVRegenWLTC`) neither limit binds above 2 km/h (WLTC asks at most 87 N·m
  and 32 kW), friction takes 0.004 % of the braking, and 23.85 % of the traction comes back: the
  share sits in the anchor's upper half because the ideal reduction lets 88.6 % of the braking
  through, above the measured Leaf's 70–87 %. A 15 kW charge limit brings the share down to the
  measured cars' 21.40 % only by putting 9.5 % of WLTC's braking on friction, above S8's 4 %. The hard stop's meters (shaft, friction, tire slip) close on the
  kinetic energy of body and wheels to 10⁻⁹; the rotor's energy reaches the battery without
  passing the reduction, so it stays out of that balance.
- Issue #140 adds the opt-in `RegenBlend(abs_rule = true)` rule. `ABSUnit(report_front = true)`
  reports a front command below sampled demand; `allow` decays with 30 ms and recovers with
  0.5 s time constants (assumed). The dry hard stop defaults to `withdraw = 0`: 36.22 m,
  176.9 kJ motor / 181.8 kJ friction (49.32 % motor). With withdrawal enabled the gentle ABS
  remains active almost throughout and suppresses regen; keep it opt-in pending ABS calibration
  #156. WLTC equations and numbers are unchanged (23.85 %, 34.25 Wh/km recovered).
- Demonstrate on `Vehicle.Planar.PlanarBEVLowGripStopTransient()` or
  `HandsOn04.BEVLowGripStopTransient()` (default `withdraw = 1`, `stop = 28`). Verified runs
  at road grip ×0.3 give a 275.02 m stop with minimum front slip −0.04931 above 3 m/s.
  Compare `withdraw = 0, stop = 12`: the fronts lock and reverse under ideal machine torque,
  so the 112.35 m is not a physical locked-wheel benchmark. Longer parking disabled
  reaches the known tire singularity.
  The inherited slow reapply calibration is tracked in #156. The rule is not traction control:
  machine-only light braking may lock a wheel without a friction demand for the ABS to modulate.
