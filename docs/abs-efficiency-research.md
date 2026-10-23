# ABS stopping efficiency on snow: is a 5 % gain over the locked wheel realistic?

Research note on one question. On snow (`road_mu = 0.3`), the wheel-speed-only ABS stops in
130.55 m and the locked wheel in 136.75 m, only 4.5 % shorter. The true-slip ABS stops in 106.05 m,
22 % shorter. Which of these matches measured cars?

Read with [`abs-frequency-research.md`](abs-frequency-research.md) (cycle rates, tire realism)
and [`abs-braking-distance-findings.md`](abs-braking-distance-findings.md) (controller history).
This note does not repeat them.

Evidence comes in three kinds:

- **Literature.** Each claim cites its source. Where only a secondary source exists, the claim is
  marked **unverified**.
- **Simulation (Dyad).** Parameter overrides on the hands-on models `PedalStop`,
  `ABSStopWheelOnly` and `ABSStop` at `road_mu = 0.3`. No model file was changed. The baselines
  reproduce the quoted numbers (136.75 / 130.53 / 106.0 m).
- **Arithmetic** on the quoted distances.

## Summary

1. **Measured ABS-vs-locked results on snow vary in sign, and they cluster near zero.**
   - A 1969 four-wheel ABS stopped 11 % shorter than locked wheels on snow and ice at 45 mph [1].
   - With fresh snow on pavement near freezing, the locked or non-ABS car decelerated *better*
     [2, 3]: 3.0 vs 2.6 m/s² in one test, about 15 % more [3].
   - Locked wheels dig into loose snow, down to a grippier layer [3, 4]. Many single locked
     runs on loose snow out-decelerated ABS, but averaged over 24 tyre-surface combinations, ABS
     still won [4].
   - Our wheel-speed ABS's 4.5 % sits inside that measured band. Our true-slip ABS's 22 % is
     above every snow number found.
2. **Real snow has a flat μ–slip curve with a late peak.**
   - On compacted snow the peak sits at 20–40 % slip, and at 100 % slip "the differences between
     these maximum values and skid resistance coefficients … are small" [5].
   - A road friction tester puts the winter-surface peak at about 30 % slip, against 18 % dry
     [6].
   - Our tire peaks at 4 % slip and drops to 0.7 of the peak by 12 % on every surface, because
     `road_mu` only scales the curve.
   - On snow this overstates the ABS headroom: the model allows about 22 %, where real packed
     snow allows roughly 0–15 %.
3. **The 4.5 % is right for the wrong reason.** Two defects partly cancel:
   - the plant overstates what ABS can gain on snow;
   - the controller wastes most of that gain.
   - **Controller side.** The dump and build rates are fixed in bar/s, and so is the 30 ms valve
     lag. On snow the lock pressure is only about 19 bar (0.3 × 62 bar). One valve lag at the dump
     rate is 580 bar/s × 0.03 s ≈ 17 bar, nearly the whole lock pressure. Each cycle therefore
     dumps almost to zero, then rebuilds at 116 bar/s.
   - Scaling `k_inc`, `k_dec`, `a_minus` and `a_plus` by 0.3 gives 113.2 m (−17 % vs locked).
     Cutting the valve lag to 10 ms gives 111.4 m. `a_ref` has no effect (130.7 m at 2.4).
   - **Plant side.** A packed-snow-like tire (sliding/peak 0.9–0.95, peak at 15 % slip) shortens
     the locked stop to 103–109 m. The unchanged wheel-speed ABS then stops 5–8 % *longer* than
     locked.
4. **R13-H adhesion utilization.**
   - Annex 6 requires ε ≥ 0.75, measured at about 0.8 and at ≤ 0.3 adhesion [7].
   - ε compares ABS deceleration with the *peak* adhesion k (the best non-locking deceleration),
     not with the locked wheel [7].
   - Our wheel-speed ABS scores ε ≈ 0.81–0.83 on every surface (proxy below). It would pass, even
     on snow, despite its small gain over locked.
5. **Dry and wet.**
   - Measured ABS gains are 10–13 % on dry concrete and 11–17 % on wet asphalt, against the
     driver's best non-ABS stop [8].
   - Our dry 12 % (wheel-speed ABS) is plausible.
   - Our true-slip ABS's 22 % dry gain is too optimistic, because real dry slide/peak is
     0.83–0.89 [8], not 0.7.
6. **Cycling.**
   - Measured Bosch ABS cycles at 2–4 Hz (front, asphalt) with wheel-pressure swings of roughly
     20–30 bar around 90–125 bar. On ice it cycles at 4–6 Hz, swinging between about 5 and 35 bar
     [9].
   - Our true-slip ABS's 26 Hz / 1 bar ripple is a continuous slip regulator, not a production
     cycle.

## 1. Measured ABS vs locked wheel on snow (and ice)

| source | surface | comparison | result (negative = ABS longer) | trust |
|---|---|---|---|---|
| Clemett & Moules (Ford), HRR 477, 1973, Table 1, data from Chrysler "Sure Brake" SAE 690213 [1] | snow and ice, 45 mph | 4-wheel ABS vs all wheels locked | 255 ft → 227 ft, **+11.0 %** ("an average for various environmental conditions") | primary (review quoting test data), read |
| Eddie, SAE 940724, 1994 [2] | smooth ice, hard-packed snow; fresh snow on asphalt | ABS on vs off, same car | ABS "generally gave a slight deceleration advantage"; **on fresh snow on pavement just below freezing, non-ABS runs got somewhat better traction**; 0.10–0.30 g overall | abstract only |
| Sokolovskij & Pečeliūnas, *Strojniški vestnik* 53(4), 2007, Table 2 [3] | snow "fit for traffic" | Ford Escort ABS vs Ford Sierra non-ABS (different cars) | ABS 2.6 vs non-ABS **3.0** m/s², ABS **−13 %** deceleration; ice 2.0 vs 1.8 m/s² (ABS +11 %) | primary, read; cars differ |
| Strandberg, VETA *Dialog* No. 2, 1995 (Volvo 850, 9 tyres, 66 ordinary drivers) [4] | loose snow, polished ice, harsh ice | ABS vs ABS disconnected, driver's own braking | mean deceleration higher with ABS in **all 24** tyre-surface combinations; "many individual tests" on loose snow decelerated more with wheels locked, "digging themselves down … to a level with greater adhesion" | author's summary page, read; full report not seen |
| Burton et al., RACV report 04/01, 2004 [10] | review | — | "stopping distances on snow and gravel are greater in an ABS vehicle"; locked wheels gain from "a build up of material in front of a sliding wheel" | secondary review |
| Tekniikan Maailma, VW Golf V on non-studded tyres | snow | locked vs ABS | 53 m locked, 64 m ABS | **unverified** (seen only as second-hand wiki tables) |

Not found: a controlled modern study that separates packed snow from loose snow with a purely
locked-wheel baseline. The NHTSA light-vehicle program [8] tested no snow.

**Reading.** On packed snow and ice the measured ABS gain is small and positive (about 0–11 %). On
fresh or loose snow over pavement it turns negative (to about −15 % in deceleration), because the
locked tire plows a wedge or scrapes through to the pavement [2, 3, 4, 10]. Clemett & Moules state
the mechanism generally: "In the absence of a distinct peak at low slip in the µ-slip
characteristic curve, no improvement over locked-wheel stopping distance can be expected" [1].

**Against our runs** (gain vs locked: wheel-speed 4.5 %, true-slip 22.4 %):

- **The wheel-speed ABS** sits inside the measured band.
- **The true-slip ABS** beats every snow measurement found, by about a factor of 2.
- **The model cannot reach the band's lower end.** The tire curve never rises past `mu_S` after
  the peak, so loose snow, where locking wins, is out of reach.

## 2. The real snow μ–slip curve

| source | surface | peak µ | slip at peak | lock / peak | trust |
|---|---|---|---|---|---|
| Ichihara & Mizoguchi, TRB Special Report 115, 1970 [5] | compacted snow, rib/snow/studded tyres, 20 km/h | braking coefficients: new snow 0.2–0.25, old snow 0.25–0.30, ice 0.1–0.2 (30–40 km/h) | 20–40 % on normal compacted snow; "relatively low slip on a hard snow surface and … higher slip on a soft snow surface" | "the differences between these maximum values and skid resistance coefficients at 100 percent slip are small", so **≈ 0.85–1.0** | primary, read |
| Fleege, Wambold & Rado, TRB Conf. Proc. 16, 1996 (ROAR variable-slip tester, ASTM E1551 tyre) [6] | packed snow, loose snow, slush, ice; dry/wet baseline | packed snow ≈ 0.3; dry 0.84–0.87 | "around 18 percent on dry, 20 percent on wet, and nearly 30 percent on the winter contaminated surfaces" | not tabulated; a shape factor "separates the loose snow and slush from the packed snow and ice" | primary, read |
| Clemett & Moules 1973, Fig. 5 [1] | ice at 30 °F | — | — | peak/lock > 1 at 30 mph, but maximum *at lock* at 20 mph | primary, read |
| Burckhardt "snow" parameters (c₁ 0.1946, c₂ 94.129, c₃ 0.0646), as transcribed in [11] | snow | 0.19 | 0.06 | 0.68 | fitted model, secondary transcription |
| Karyotakis et al. (Volvo/Chalmers), AVEC'22, Table 1 [12] | packed snow, winter tyres, ABS stops | 0.33–0.44 (ABS-braking µ) | — | — | primary, read |
| **Model** (`TireFrictionCurve`, scaled by `road_mu`) | every surface | 0.3 at `road_mu = 0.3` | **0.04** | **0.70** | — |

The two measured winter studies [5, 6] agree with each other. The Burckhardt fit does not, and
puts the snow peak at a low slip with a 0.68 drop. That fit is a curve family tuned for controller
studies, and its source data were not available to check. Weight the two field measurements over
it.

What this does to our model on snow:

- **Peak µ** of 0.3 matches packed snow [5, 6, 12]. The level is right.
- **Peak slip** of 4 % is 5–10× too early for snow [5, 6]. It is also too early for asphalt
  ([`abs-frequency-research.md`](abs-frequency-research.md) §2).
- **Sliding/peak** of 0.70 is too harsh for packed snow. That ratio sets the locked-wheel penalty:
  the locked stop is about 1/0.7 = 1.43× the ideal before drag, which is the 22 % headroom the
  true-slip ABS captures. Real packed snow, at 0.85–1.0 [5], leaves 0–15 % headroom, matching the
  measured gains in §1.
- **Loose snow** cannot be represented. It would need `mu_S > mu_A` (friction rising toward lock)
  plus a plowing force [1, 3, 4].

### Simulation: what a snow-like tire does (Dyad, `road_mu = 0.3`)

| case | locked [m] | wheel-speed ABS [m] | gain vs locked |
|---|---:|---:|---:|
| current tire (`mu_S = 0.7`, `sAdhesion = 0.04`, `sSlide = 0.12`) | 136.75 | 130.53 | +4.5 % |
| `mu_S = 0.9` | 108.53 | 114.32 | **−5.3 %** |
| `mu_S = 0.95`, `sAdhesion = 0.15`, `sSlide = 0.5` (packed-snow-like) | 103.25 | 111.70 | **−8.2 %** |

`mu_S` is relative to `mu_A = 1`, before the `road_mu` scale. With a realistic snow tire, the
locked wheel gets much better (−21 to −25 %). The wheel-speed ABS then stops longer than locked.
That matches the fresh-snow results [2, 3], but not the small positive packed-snow gains [1, 4].

## 3. Why our wheel-speed ABS gains so little on this plant

Simulation (Dyad), `ABSStopWheelOnly`, `road_mu = 0.3`, current tire, one change per row:

| change | distance [m] | gain vs locked 136.75 m |
|---|---:|---:|
| none | 130.53 | +4.5 % |
| `est.a_ref` 8 → 2.4 | 130.74 | +4.4 % |
| `abs.lambda_1` 0.2 → 0.08 | 131.19 | +4.1 % |
| `abs.a_minus`, `abs.a_plus` × 0.3 | 139.81 | −2.2 % |
| `abs.k_inc`, `abs.k_dec` × 0.3 | 124.27 | +9.1 % |
| rates **and** `a_minus`, `a_plus` × 0.3 | **113.16** | **+17.2 %** |
| valve lag `T_v` 30 → 10 ms (both valves) | **111.35** | **+18.6 %** |
| true-slip `ABSStop` for reference | 106.0 | +22.5 % |

- **The reference speed is not the problem.** `a_ref` barely matters, because `PhaseABS` dumps on
  wheel deceleration, which needs no speed estimate. That agrees with the comment in
  `test/abs_handson_plausibility.jl`.
- **The problem is everything scaled for dry road.**
  - The thresholds and rates are tuned to a 62 bar lock pressure.
  - On snow the lock pressure is about 19 bar peak and about 13 bar sliding (0.3 and 0.21 ×
    4256 N·m ÷ 68.9 N·m/bar).
  - During one 30 ms valve lag, the dump command falls 17 bar. Every dump therefore empties the
    caliper, and the rebuild at 116 bar/s takes about 0.15 s per cycle.
  - This is the same "rates should scale with the lock torque" finding as in
    [`abs-frequency-research.md`](abs-frequency-research.md) §5, now on the hydraulic plant.
- **Production ECUs adapt.** They learn the lock pressure and step the reapply from it. The Bosch
  cycle's slow reapply runs at about 1/10 of the fast rate after a learned level [9].

## 4. Regulatory benchmark: UN R13-H adhesion utilization

From UN Regulation No. 13-H, Annex 6 [7]:

- §5.2.1: "The anti-lock system shall be deemed to be satisfactory when the condition ε ≥ 0.75
  is satisfied, where ε represents the adhesion utilized."
- §5.2.2: ε is measured "on road surfaces with a coefficient of adhesion of 0.3 or less, and of
  about 0.8 (dry road), with an initial speed of 50 km/h". A footnote allows worn tyres and values
  up to 0.4 until such surfaces are available. Some copies render this as "0.36", which is 0.3
  followed by footnote 6. §5.2.5 requires the test both laden and unladen.
- Appendix 2:
  - **k** (coefficient of adhesion) is "the quotient of the maximum braking forces without locking
    the wheels and the corresponding dynamic load". It comes from single-axle stops timed from 40
    to 20 km/h, z = 0.566/t (Δv = 20 km/h ÷ g, derived).
  - **z_AL** is measured "from an initial vehicle speed of 55 km/h … with full cycling" over 45 to
    15 km/h, z_AL = 0.849/t_m (derived the same way).
  - ε = z_AL / k_M, with k_M weighted by dynamic axle loads.
  - Rolling resistance of unbraked axles (0.010/0.015) is credited, and ε > 1.00 forces a
    re-measurement.

So ε is **ABS deceleration over peak-friction deceleration**, not ABS over locked. On our tire a
locked wheel reaches 0.70 of the peak, just under the 0.75 floor. An ABS can therefore satisfy
R13-H on snow while barely beating a locked wheel.

**Our runs.** As a proxy, ε ≈ d_ideal / d (with d_ideal = v₀²/2gµ):

| road µ | locked | true-slip ABS | wheel-speed ABS |
|---|---:|---:|---:|
| 1.0 | 0.73 | 0.93 | 0.83 |
| 0.5 | 0.75 | 0.99 | 0.82 |
| 0.3 | 0.78 | 1.00 | 0.81 |

The wheel-speed ABS passes the 0.75 floor on every surface.

The proxy is biased in two ways. The second bias explains why the locked wheel "passes" on
snow:

- **Too low:** it includes the pedal and valve build-up at the start of the stop, which R13-H's
  45→15 km/h window excludes.
- **Too high:** it credits aerodynamic drag and rolling resistance to the brakes. That matters
  more at low µ.

A closer equivalent:

1. Take the mean deceleration while `body.mass.v` falls from 12.5 to 4.17 m/s (45→15 km/h).
2. Subtract the drag and rolling contribution at those speeds.
3. Divide by `road_mu·mu_A·g`.

Not computed here.

## 5. Dry and wet, for comparison

NHTSA, nine 1990s production cars (Forkenbrock, Flick, Garrott, SAE 1999-01-1287) [8]:

- **ABS was compared with the best non-ABS stop.** On the dry/wet paved surfaces, that was the
  driver's "best effort" modulated stop, with no more than one wheel per axle locked. Full-pedal
  locked stops were omitted there "due to the excessive tire wear".
- These percentages therefore *understate* the gain over a fully locked car.

| surface (ASTM skid no. peak/slide) | slide/peak | ABS gain, light / laden |
|---|---:|---|
| dry concrete (90/75) | 0.83 | 9.8 % / 12.7 % |
| wet asphalt (85/65) | 0.76 | 11.4 % / 17.2 % |
| wet polished concrete (?/60) | — | 16.7 % / 23.1 % |
| wet Jennite (30/10) | 0.33 | 17.6 % / 26.6 % |
| grass | — | −7.1 % / +6.9 % |
| loose gravel | — | **−30.0 % / −24.6 %** (vs full-pedal locked) |

The 1969 Chrysler system against fully locked wheels gave [1]:

- dry concrete −3.8 %;
- wet concrete +11.5 %;
- wet Jennite +41 %;
- gravel −25 %.

Our model at `road_mu` 1.0 / 0.5 (same 0.7 ratio):

- **Wheel-speed ABS:** +11.9 % / +8.3 %. The dry gain is plausible. The 0.5 gain is low next to
  wet asphalt's 11–17 %, which has a similar ratio (0.76).
- **True-slip ABS:** +21.7 % / +24.1 %. The dry gain is too high, because real dry slide/peak is
  0.83–0.89. The wet gain is at the top of the measured range.

## 6. Cycle frequency and pressure swing

Day & Roberts, SAE 2002-01-0559, compared their model with Bosch test data, "probably" Bosch
ABS 5.2 [9]. The figures were read off the plots:

| surface | cycle rate (text) | wheel pressure (Figs. 5, 7, read off the plots) |
|---|---|---|
| asphalt, 100 km/h | "approximately 2 to 4 cycles per second for the front wheels and 4 to 6 … rear" | front sawtooth ≈ 90–125 bar, swings ≈ 15–30 bar (≈ 15–25 % of level); master cylinder ≈ 200 bar |
| ice, 50 km/h | "approximately 4 to 6 cycles per second for the front wheels and slightly higher … rear" | wheel pressures between ≈ 5 and 35 bar, so nearly full dumps; master cylinder ≈ 140–160 bar |

They add that "The cycle frequency is a natural consequence of the wheel spin dynamics" [9]. This
confirms the 2–6 Hz in [`abs-frequency-research.md`](abs-frequency-research.md) from the primary
paper (re-read for this note).

**Against our runs.**

- **True-slip ABS** (26 Hz, ±0.5 bar around 63.6 bar, about 1.6 % of level): a continuous slip
  regulator. That suits an ideal benchmark, but it is not what a production ABS looks like. A
  production ABS runs about 10× slower with about 10× larger relative swings.
- **Wheel-speed ABS** (9.2 Hz dry, 4.1 Hz at µ 0.5, per the plausibility test): closer to the
  measured range.
- **Snow.** Real ice cycles dump almost fully, as ours do. But the real ones keep 4–6 Hz with a
  learned reapply level [9], so they lose less time rebuilding.

## Verdict

| surface | wheel-speed ABS (a_ref 8) | true-slip ABS | what would move us toward the data |
|---|---|---|---|
| **snow, µ 0.3** | **Plausible in number (4.5 %; measured −15 to +11 %), wrong in cause.** The plant offers 22 % and the controller wastes most of it. | **Too optimistic** (22 % vs ≤ 11 % measured). | **Plant:** make the tire shape surface-dependent instead of scaling one curve. For packed snow use `mu_S/mu_A` ≈ 0.85–0.95 and peak slip ≈ 0.15–0.3; for loose snow use `mu_S ≥ mu_A`. This cuts the true-slip gain to near zero and makes the locked wheel competitive, as measured. **Controller:** scale `k_inc`/`k_dec` and `a_minus`/`a_plus` with the learned lock pressure (× 0.3 here gives 113 m, +17 %). `a_ref` does not matter. |
| **wet, µ 0.5** | Slightly **too pessimistic** (8 % vs 11–17 % on a similar 0.76 ratio). | Plausible, at the top of the range (24 %). | Same rate scaling. The 30 ms valve lag is unverified, and 10 ms adds about 15 points on snow. A sourced solenoid lag would settle it. |
| **dry, µ 1.0** | **Plausible** (12 % vs 10–13 %). | **Too optimistic** (22 %). | Raise dry `mu_S/mu_A` to about 0.83–0.89 [8] and move the peak later ([`abs-frequency-research.md`](abs-frequency-research.md) §2). |

For the lecture:

- **Snow.** "ABS barely beats a locked wheel on snow" is a true statement about real cars. On
  loose snow a locked wheel can even win. It is the right teaching point. The model currently
  gets there by under-performing the controller on a tire that exaggerates the possible gain.
  The honest fix is a snow-shaped tire, after which the numbers would show the effect for the
  physical reason: a flat μ–slip curve.
- **Snow, true-slip ABS.** Its 106 m is not a real-world reference on snow.
- **Regulation.** Under R13-H, the yardstick is ε ≥ 0.75 against *peak* friction. Every ABS run
  here passes it.

## Reproduce

- Script: `scripts/abs_snow_overrides.jl`.
- Run it with `julia +dyad-3.4.0 --project=.` from the repo root.
- It compiles `PedalStop`, `ABSStopWheelOnly` and `ABSStop` with `road_mu = 0.3`, overrides
  parameters in the `ODEProblem`, and solves with Tsit5 at `dtmax = 1e-3`. Distances come from
  `Vehicle.braking_distance` (from 0.5 s to v < 0.5 m/s).

## Sources

1. Clemett, H. R., Moules, J. W. (Ford), "Brakes and Skid Resistance", *Highway Research Record*
   477, 1973, pp. 27–33, Table 1 (data from Schafer & Douglas, SAE 690213) and Figs. 5, 9.
   https://onlinepubs.trb.org/Onlinepubs/hrr/1973/477/477-006.pdf (read)
2. Eddie, R., "Ice, ABS, and Temperature", SAE 940724, 1994.
   https://saemobilus.sae.org/papers/ice-abs-temperature-940724 (abstract only)
3. Sokolovskij, E., Pečeliūnas, R., "The Influence of Road Surface on an Automobile's Braking
   Characteristics", *Strojniški vestnik – J. Mech. Eng.* 53(4), 2007, 216–223, Table 2.
   https://www.sv-jme.eu/article/the-influence-of-road-surface-on-an-automobiles-braking-characteristics/
   (read)
4. Strandberg, L., "Automobile Brakeability on Ice and Snow with Ordinary Drivers", VETA *Dialog*
   No. 2, 1995; author's summary at http://www.veta.se/abs66ice.htm (summary read, report not
   seen)
5. Ichihara, K., Mizoguchi, M., "Skid Resistance of Snow- or Ice-Covered Roads", HRB Special
   Report 115, 1970, Table 1 and Figs. 2–3.
   https://onlinepubs.trb.org/Onlinepubs/sr/sr115/115-010.pdf (read)
6. Fleege, E. J., Wambold, J. C., Rado, Z., "Variable Slip Friction Measurement Techniques for
   Snow and Ice Operations", TRB Conference Proceedings 16, 1996, Fig. 2 and text.
   https://onlinepubs.trb.org/Onlinepubs/conf/1996/cp16/cp16-013.pdf (read)
7. UN Regulation No. 13-H, Annex 6 §5.2 and Appendices 1–2 (English/Japanese copy hosted by
   MLIT). https://www.mlit.go.jp/jidosha/un/UN_R013H.pdf (read). The EU OJ text is at
   https://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2010:230:0001:0080:EN:PDF (not
   opened).
8. Forkenbrock, G., Flick, M., Garrott, W. R., "A Comprehensive Light Vehicle Antilock Brake
   System Test Track Performance Evaluation", SAE 1999-01-1287, Table 2 and Table A1.
   https://web.archive.org/web/20250822053247id_/https://www.nhtsa.gov/sites/nhtsa.gov/files/sae1999-01-1287.pdf
   (read)
9. Day, T. D., Roberts, S. G., "A Simulation Model for Vehicle Braking Systems Fitted with ABS",
   SAE 2002-01-0559, "Comparison with experiment", Figs. 5 and 7.
   https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf (read; pressure swings read off the plots)
10. Burton, D., Delaney, A., Newstead, S., Logan, D., Fildes, B., "Evaluation of Anti-lock
    Braking Systems Effectiveness", RACV Research Report 04/01, 2004, §2.4.
    https://web.archive.org/web/2010id_/http://www.monash.edu.au/miri/research/reports/other/racv-abs-braking-system-effectiveness.pdf
    (read; secondary review)
11. Crocetti et al., arXiv:2211.02558, Burckhardt parameters for dry, wet and snow.
    https://arxiv.org/abs/2211.02558 (read; peak values computed from the parameters)
12. Karyotakis, E., Yang, D., Jonasson, M., Sjöberg, J., "Experimental Study on Road Friction
    Variation and Stopping Distance Uncertainty using ABS Braking Data", AVEC'22, Table 1.
    https://research.chalmers.se/publication/534217/file/534217_Fulltext.pdf (read)

**Not accessible:** SAE 940724 full text, Strandberg's full report, SAE 690213 and 690214
(Harned et al. μ–slip curves), the Bosch Automotive Handbook, and Heißing & Ersoy, *Chassis
Handbook* (cited by Wikipedia for ABS on gravel and deep snow). NHTSA DOT HS 808 206 (Kahane)
was seen only in search snippets saying ABS lengthens gravel stops by about 28 % and that the
effect on snow is unknown, so it is not cited above.
