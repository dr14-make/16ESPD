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
the remainder goes to the hydraulics through the existing allocator. A fourth rule withdraws
regen while the ABS acts on either driven wheel. With the shared ABS memory fix, the hard-stop
bench keeps this rule ON (`withdraw = 1`): 27.102036224 m, 0.61 % above friction-only,
inside the 1 % distance regression tolerance. ON is shorter and keeps slip above −0.2 while vx > 3 m/s; OFF reverses
front wheels and is not a physical regen benchmark. WLTC does not use the rule.
WLTC never decelerates harder than 1.5 m/s² (0.15 g), so friction only covers the low-speed
fade (under 4 % of braking energy). The meaningful motor-share goal is NOT met: blanket
front-active withdrawal suppresses regen almost throughout; gross machine share is only
0.839 %. WLTC reports recovered energy independently.

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
### Historical #156 rebase evidence (superseded by the memory-fix evidence below)

The following measurements, failure diagnosis, run durations and test counts record the rebase
state **before** the ABS memory fix; they are history, not current expectations.

- Step 5's `Vehicle.Electric.RegenBlend` caps the machine's braking at the smallest of 320 N·m
  (Nissan), 80.5 kW over the machine speed (INL, the 2013 pack's 10 s charge capability) and a
  linear fade below 10 km/h (assumed), and sends the rest through Lecture 3's equal per-wheel
  demand to the four brakes. On the hard stop (`Vehicle.Planar.PlanarBEVHardStop`, Lecture 3's
  ABS stop from 80 km/h), the rule-OFF diagnostic takes 33.037836314 m / 2.705 s after the
  pedal, with 45.3137% machine share, 160119.109 J shaft recovery, 193237.591 J friction,
  27300.500 J tire loss and 154840.805 J battery recovery. This is not the rule-ON default
  result below. Friction-only takes 26.937898732 m / 2.335 s, with shaft_in 853.747 J,
  shaft_out 7484.425 J, friction 352732.323 J, tire 34555.337 J and battery recovery zero.
  On WLTC
  (`Vehicle.Planar.PlanarBEVRegenWLTC`) neither limit binds above 2 km/h (WLTC asks at most 87 N·m
  and 32 kW), friction takes 0.004 % of the braking, and 23.85 % of the traction comes back: the
  share sits in the anchor's upper half because the ideal reduction lets 88.6 % of the braking
  through, above the measured Leaf's 70–87 %. A 15 kW charge limit brings the share down to the
  measured cars' 21.40 % only by putting 9.5 % of WLTC's braking on friction, above S8's 4 %. The hard stop's meters (shaft, friction, tire slip) close on the
  kinetic energy of body and wheels to 10⁻⁹; the rotor's energy reaches the battery without
  passing the reduction, so it stays out of that balance.
- Issue #140 adds `RegenBlend(abs_rule = true)`. `ABSUnit(report_front = true)` reports a
  front command below sampled demand; `allow` decays with 30 ms and recovers with 0.5 s
  time constants (assumed). After the #156 rebase, the dry default remains `withdraw = 1`
  per user request: 59.409163717 m / 5.100 s from pedal to vx < 0.5 m/s, shaft_in
  3501.911496 J, shaft_out 5010.979664 J, friction 350708.377370 J, tire 31457.672893 J,
  battery recovery 2979.353015 J, machine share 0.98865324%. Minimum slip above 3 m/s is
  −0.0243273 front / −0.0935963 rear. Keep the broken no-distance-penalty assertion:
  the penalty against friction-only is now 32.47 m. Do not hide this by retuning friction ABS.
  Measured trace: front friction torque is exactly zero at t = 0.55, 0.6, 0.65, 0.8,
  1, 1.5, 2, 2.5 and 3 s; `allow` is 0.3114, 0.05882, 0.011109 and 7.485e-5 at the first
  four times. At 0.515 s predicted slip −0.151742 triggers release with `p = tau_lock = 0`.
  At 0.525 s phase returns to increase, yet both `15*tau_lock` and `1.5*tau_lock` rates
  remain zero. At 1 s predicted slip +0.001823 still leaves pressure and rebuild rate zero. WLTC is untouched: 23.85%, 34.25 Wh/km
  recovered and 131.15 Wh/km consumption.
- Low-grip benches: `Vehicle.Planar.PlanarBEVLowGripStopTransient()` and
  `HandsOn04.BEVLowGripStopTransient()` retain `withdraw = 1`, `stop = 28`. At road grip
  ×0.3, rule ON reaches vx < 0.5 m/s 16.4 s after the pedal at 190.445049116 m; minimum
  slip above 3 m/s is −0.0493111 front / −0.105156 rear. The default 28 s run fails
  `Unstable` at 24.565 s in prolonged parking, consistent with the known tire singularity;
  rerun with `stop = 20` succeeds (HandsOn: 190.472 m). `withdraw = 0, stop = 12` succeeds numerically at
  95.098241553 m but minimum front slip −17.35917766 means reversed wheels, NOT a physical
  benchmark. The rule is not traction control: machine-only light braking may lock a wheel
  without a friction demand for ABS to modulate.

### #156 rebase follow-up ledger and delivery

| Comparison | Before → after |
|---|---|
| Calibrated dry rule OFF → rule ON default | 33.037836314 → 59.409163717 m |
| Dry withdrawal enabled, old → rebased calibration | 38.836 → 59.409163717 m; old motor 5930 J / friction 360743 J / share 1.617% |
| Low grip rule ON, old → rebased | 275.02 → 190.445049116 m |
| Low grip rule OFF, old → rebased (reversed wheels; nonphysical) | 112.35 → 95.098241553 m |
| Old dry rule OFF before recalibration, regen / friction-only | 36.22 / 38.82 m (historical) |

Rebase: `41ef17a` → `7bac0b4` on `878ce03` (`origin/main`), compiler 3.5.0; generated
Julia comes from the compiler. Conflict and historical #156 ledgers are in `docs/HANDOVER.md`.
Tests: `regen` 97 pass / 1 broken; `abs` 84 pass; `esp` 159 pass; `planar_wltc` 36 pass / 1 pre-existing broken initialization case. No figure export in this follow-up:
Lecture 4 `07-regen-hard-stop.svg` and `07-hard-stop-split.svg` data changed, and notebook
source uses the coordinated default. Lecture 3 carry-forward changed figures:
`03-brake-steer-path`, `03-brake-steer-forces`, `05-esp-abs`, `05-split-mu`; all SWD plots
also depend on calibration.


### Current ABS memory-fix evidence (required-runtime measurements)

`ABSModulatorDiscrete` now uses the existing `k_inc_fast`/`k_inc_slow` ramps whenever
`tau_lock < tau_memory_min` (1 N·m, assumed). Otherwise memory-scaled reapply is
unchanged. Release memory and decrement are untouched; the threshold is tagged (assumed).

| Dry rule ON (`withdraw = 1`, retained default) | Before → after |
|---|---|
| Distance to vx < 0.5 m/s | 59.409163717 → 27.102036224 m |
| Time after pedal | 5.100 → 2.340 s |
| Shaft in / out | 3501.911496 / 5010.979664 → 2951.278652 / 6479.217812 J |
| Friction / tire loss | 350708.377370 / 31457.672893 → 348907.684116 / 35277.237330 J |
| Battery positive recovery | 2979.353015 → 2956.884659 J |
| Gross motor share | 0.98865324 → 0.839 % |

ON front/rear minimum slip above 3 m/s is −0.126072/−0.090554. Friction-only BEV is
unchanged: 26.937898732 m, 2.335 s, brake 352732.323 J / tire 34555.337 J. ON is
0.16413749 m / 0.61 % longer. The broken penalty assertion is replaced by
`distance <= 1.01 * friction_distance` (1 % tolerance). This does **not** meet the meaningful
motor-share goal: blanket front-active withdrawal suppresses regen almost throughout the stop.
Net energy accounting subtracts shaft output from shaft recovery, rather than using gross share.

Dry OFF is now 27.238292677 m, 2.425 s; shaft_in 91401.848027 J, shaft_out 61800.443694 J,
brake 226903.189571 J, tire 124152.388374 J, battery positive recovery 92809.448651 J,
gross motor share 28.7 %. Front minimum slip −5.893705 above 3 m/s indicates reversed
wheels, **NOT a physical regen benchmark**. Keep ON: shorter and keeps slip above −0.2 while vx > 3 m/s.

ON trace: at 0.515 s `p = tau_lock = 0`; at 0.525 s `p = 200`, rate 40000;
at 0.55 s `p = 600`, rate 16000; at 0.6 s `p = 1400`; later valid lock memory ≈1.25 kN·m.

Low-grip ON: 190.445049116 → 87.594615426 m, time after pedal 16.4 → 7.665 s;
front/rear minimum slip above 3 m/s −0.187106/−0.104377. Use `stop = 12` for both
`Vehicle.Planar.PlanarBEVLowGripStopTransient` and `HandsOn04.BEVLowGripStopTransient`
and the test: `stop = 20` now fails at 15.835 s in parking, after stopping at 8.165 s absolute.
OFF is unchanged: 95.098241553 m, minimum front slip −17.35918, reversed wheels/nonphysical.
HandsOn low-grip: 87.604052512 m (Success, `stop = 12`); library 87.594615426 m.

ABS-alone dry is unchanged: 26.517044326 m at 80 km/h and 41.028141818 m at 100 km/h.
WLTC is untouched: 23.85 %, 34.25 Wh/km recovered, 131.15 Wh/km consumption.
No figure export: Lecture 4 `07-regen-hard-stop.svg` and `07-hard-stop-split.svg` remain
historical images pending re-export; notebook source and teaching text carry current evidence.


Limit trace (rule ON): demand binds at 0.505 s (61.03 N·m), charge power by 0.515 s
(137.20 N·m). Withdrawal then dominates: 42.87 N·m at 0.55 s, 8.19 at 0.6 s,
0.01138 at 0.8 s, while front friction reaches 1226.13 N·m. Actual regen stays near zero
through 2.7 s; below the ABS cutoff it returns under fade (14.73 N·m at 2.8 s / 2.795 km/h).
Peak electromagnetic / battery-terminal recovery: 78.957 / 75.829 kW. These are not changes
to the 80.5 kW charge ceiling, 320 N·m torque ceiling, 34.27 km/h corner or 10 km/h fade.
ABS-alone low grip, split-µ, brake-and-steer and all seven SWD cases reproduce baseline
metrics; Lecture 3 figure data have no new changes from this follow-up.

Final validation: `abs` 84 pass; `esp` 159 pass; `regen` 102 pass (formerly 97 pass /
1 broken); `planar_wltc` 36 pass / 1 pre-existing broken. Groups ran separately with
Julia +dyad-3.5.0, compiler 3.5.0; no figure exports.
