# SI engine intake manifold as the vacuum source for the brake booster (mean-value modeling)

Notation used throughout: p_a ambient pressure, p_m manifold absolute pressure (MAP), T_m manifold
temperature, V_m manifold volume, V_d displacement, N engine speed [rpm], ω engine speed [rad/s],
η_v volumetric efficiency, R = 287 J/(kg·K), γ = 1.4. "Vacuum" = p_a − p_m (gauge, positive).
Unit conversion used: 1 inHg = 3.386 kPa.

## Mean-value engine model (MVEM) of the intake manifold: filling/emptying, throttle flow, cylinder flow

### Takeaway
The standard MVEM uses one state, p_m, driven by an isothermal filling/emptying balance
dp_m/dt = (R·T_m/V_m)(ṁ_thr − ṁ_cyl), with ṁ_thr from a compressible (isentropic) orifice equation
with choking at p_m/p_a ≈ 0.528 and ṁ_cyl from the speed-density relation
ṁ_cyl = η_v·(p_m/(R·T_m))·V_d·N/120 (four-stroke). A booster port is simply a third mass flow
term into the same balance.

### Cited Findings
- The manifold filling (manifold pressure) state equation is "one of the most important differential
  equations" of an SI MVEM; Hendricks et al. derived a simplified, more physical form to make MVEM
  calibration easier (Hendricks, Chevalier, Jensen, Sorenson et al., SAE 960037, 1996, "Modelling of the
  Intake Manifold Filling Dynamics") — [SAE 960037](https://saemobilus.sae.org/papers/modelling-intake-manifold-filling-dynamics-960037)
- MathWorks Simscape Driveline "Air Intake" block implements exactly the lecture-level model:
  - dp_im/dt = (R_air·T_amb/V_im)·(ṁ_thr − ṁ_cyl)
  - ṁ_cyl = ω·V_d·p_im / (2·R_air·T_amb)  [note: this is per-radian form; ω in rad/s would need a 1/(2π)
    factor to match the rev-based formula — see Inferences; no η_v parameter, i.e. η_v is absorbed/assumed 1]
  - Throttle flow in three regimes: laminar ṁ_thr = S_thr·c1·(p_amb − p_im)/√T_amb (form as rendered:
    "S_thr T_amb c1 (P_amb − P_im)"), subsonic ṁ_thr ∝ S_thr·p_amb·c2·[(p_amb/p_im)^cb − (p_amb/p_im)^ca],
    choked ṁ_thr ∝ S_thr·c3·p_amb (constants c1..c3, ca, cb not reproduced in the fetched summary)
  - Throttle open area as cubic polynomial S_thr(θ) = k0 + k1·θ + k2·θ² + k3·θ³, plus a leakage area
  - Defaults: R_air 287.058 J/(kg·K), κ 1.4, p_amb 101.325 kPa, T_amb 298.15 K, throttle rest angle 3°,
    throttle plate diameter 5 cm, leakage area 1 cm², manifold volume 1000 cm³, displacement 1500 cm³,
    throttle actuator time constant 0.1 s
  — [MathWorks Air Intake](https://www.mathworks.com/help/sdl/ref/airintake.html)
- MathWorks Powertrain Blockset "Flow Restriction" (isentropic ideal-gas orifice), a clean statement of
  the compressible throttle equation:
  - ṁ = Γ·Ψ(Π), Γ = A_eff·p_up/(R·T_up), Π = p_down/p_up, A_eff = C_d·A_orifice
  - critical ratio Π_cr = (2/(γ+1))^(γ/(γ−1))
  - choked (Π < Π_cr): Ψ = √[γ·(2/(γ+1))^((γ+1)/(γ−1))·Π] as rendered in the fetched page. (Textbook
    form is Ψ = √γ·(2/(γ+1))^((γ+1)/(2(γ−1))), independent of Π; treat the "·Π" as a
    rendering artifact to verify against the page.)
  - subsonic (Π_cr ≤ Π ≤ Π_lim): Ψ = √[2γ/(γ−1)·(Π^(2/γ) − Π^((γ+1)/γ))]
  - near-zero Δp (Π > Π_lim): linearized Ψ = (Π−1)/(Π_lim−1)·Ψ(Π_lim) to avoid infinite slope at Π→1
  - defaults γ = 1.3998, R = 287.05 J/(kg·K), Π_lim = 0.95, C_d = 1.0
  — [MathWorks Flow Restriction](https://www.mathworks.com/help/autoblks/ref/flowrestriction.html)
- Throttle mass flow is determined by throttle plate angle, ambient pressure and manifold pressure; the
  discharge coefficient C_d accounts for flow friction losses through the throttle — [SAE 960037 summary via search](https://saemobilus.sae.org/papers/modelling-intake-manifold-filling-dynamics-960037)
- Speed-density cylinder flow for a four-stroke: ṁ_e = η_v·(n_e/2)·V_d·p/(R·T), n_e in rev/s, V_d total
  displacement — [ScienceDirect Topics: Engine Volumetric Efficiency](https://www.sciencedirect.com/topics/engineering/engine-volumetric-efficiency)
- Manifold/air-path time constant and delay depend on operating point (speed, air mass flow); the
  induction-to-power-stroke delay is approximated as 2(CYL−1)/(ω·CYL) — search snippet from
  [arXiv 2107.14321](https://arxiv.org/pdf/2107.14321) (text citing Guzzella & Onder 2009; the full PDF
  did not extract, so the exact form is unverified). Guzzella & Onder, *Introduction to Modeling and
  Control of Internal Combustion Engine Systems*, Springer 2009/2010 is the reference text cited there.

### Inferences
- Recommended lecture equations (consistent with both MathWorks blocks and speed-density):
  1. dp_m/dt = (R·T_m/V_m)·(ṁ_thr + ṁ_bst − ṁ_cyl)   [ṁ_bst = flow from booster through check valve]
  2. ṁ_thr = C_d·A_thr(θ)·p_a/√(R·T_a)·Ψ(p_m/p_a), with Ψ as above; γ = 1.4 gives Π_cr = 0.528
     (computed). At idle (p_m ≈ 27–40 kPa, Π ≈ 0.27–0.40) the throttle is **choked**, so
     ṁ_thr ≈ 0.0404·C_d·A_thr·p_a/√T_a [kg/s, SI] is independent of p_m (0.0404 = √(γ/R)·(2/(γ+1))^((γ+1)/(2(γ−1))), computed).
     This is why idle MAP is set purely by throttle/idle-bypass area against engine pumping.
  3. A_thr(θ) = (π·D²/4)·(1 − cos θ/cos θ_0) (common geometric form; not sourced above — MathWorks uses a
     cubic fit) plus a leakage/idle-air area A_leak.
  4. ṁ_cyl = η_v·V_d·N/120 · p_m/(R·T_m) (N in rpm).
- Linearizing (1) around a closed throttle (choked, ṁ_thr constant) gives a first-order lag with
  τ_m = 120·V_m/(η_v·V_d·N) (derived). With MathWorks defaults V_m = 1 L, V_d = 1.5 L and η_v ≈ 0.8:
  τ_m ≈ 0.125 s at 800 rpm, 0.033 s at 3000 rpm. So manifold dynamics are fast relative to braking
  (seconds) but not negligible at idle; with a booster volume added (see next section) the effective
  time constant of the combined system is much larger.
- The Simscape ṁ_cyl = ω·V_d·p/(2RT): with ω in rad/s this overstates flow by 2π relative to the
  rev-based formula unless ω is meant in rev/s. Check the block's units before copying.

### Gaps
- Guzzella & Onder and Heywood texts were not directly accessible; their exact notation (e.g. G&O's
  Ψ(p_m/p_a) and the "receiver" model) is reconstructed from MathWorks docs, not quoted from the books.
- Hendricks' specific modified state equation (SAE 960037) is behind a paywall; not reproduced.

## Typical numbers (volumes, efficiencies, MAP by operating point, time constants)

### Takeaway
Idle MAP ~27–47 kPa (16–20 inHg vacuum), closed-throttle overrun ~17–34 kPa (20–25 inHg), WOT ≈ ambient
(vacuum → 0). Manifold volume ~1 L and displacement ~1.5 L are reasonable defaults; η_v ≈ 0.8–0.9 at
peak torque for production NA engines.

### Cited Findings
- Hot idle, 3.0 L engine, sea level: barometric 101 kPa, MAP 27 kPa, vacuum 74 kPa (19.9 inHg); MAF at hot
  idle ≈ 3–3.2 g/s — [MOTOR magazine, Fuel Injection Diagnosis (2008)](https://www.motor.com/magazine-summary/fuel-injection-diagnosis-july-2008/)
- At 5,500 ft: barometric 84 kPa, idle MAP still 27 kPa, vacuum only 57 kPa (14.9 inHg) — "absolute
  engine working pressure at idle and light load is unchanged by elevation" — [MOTOR](https://www.motor.com/magazine-summary/fuel-injection-diagnosis-july-2008/)
- Idle vacuum "typically ranges from 16 to 20 inches Hg in most vehicles"; highest vacuum occurs during
  closed-throttle deceleration, "typically four to five inches Hg higher than at idle"; under hard
  acceleration "vacuum plummets to zero"; overall range 0 to 22+ inHg — [AA1Car, MAP sensors](https://www.aa1car.com/library/map_sensors.htm)
- Barometric pressure varies 28–31 inHg with location/weather — [AA1Car](https://www.aa1car.com/library/map_sensors.htm)
- Maximum vacuum occurs in overrun (closed throttle, low gear); WOT under heavy load gives minimal
  vacuum — [Wikipedia, Manifold vacuum](https://en.wikipedia.org/wiki/Manifold_vacuum)
- Default MVEM parameters: V_m 1000 cm³, V_d 1500 cm³, throttle plate diameter 50 mm, leakage area 1 cm²,
  throttle actuator time constant 0.1 s — [MathWorks Air Intake](https://www.mathworks.com/help/sdl/ref/airintake.html)
- Naturally aspirated street engines run η_v ≈ 80–90 % at peak torque; stock engines peak ~85 % —
  [Wikipedia, Volumetric efficiency](https://en.wikipedia.org/wiki/Volumetric_efficiency) (via search
  summary; secondary source, Heywood cited there)
- 20 inHg ≈ 68 kPa of manifold vacuum at sea level; such ≥20 inHg vacuum "can be achieved during engine
  deceleration" — [Tire Review, Brake Booster and the Barometer](https://www.tirereview.com/brake-booster-and-the-barometer/)
  (search snippet; page returned 403)
- Downsizing to 2.0 L and 1.4 L engines means "less displacement to generate the vacuum" —
  [Tire Review](https://www.tirereview.com/brake-booster-and-the-barometer/) (search snippet)

### Inferences
- Converted to absolute pressure at p_a = 101.3 kPa: idle 16–20 inHg → p_m ≈ 34–47 kPa; overrun
  20–25 inHg → p_m ≈ 17–34 kPa; MOTOR's 27 kPa idle is at the deep end. A good lecture set:
  idle 30–35 kPa, overrun (fuel cut) 20–25 kPa, part-load cruise 50–70 kPa, WOT 95–100 kPa (NA).
  The cruise and WOT numbers come from a Quora answer seen only in search and are not otherwise sourced
  — treat as plausible, not cited.
- Idle airflow check: 3 g/s for 3.0 L at 27 kPa, ~750 rpm, 300 K gives η_v ≈ ṁ·120·R·T/(V_d·N·p_m) ≈
  0.003·120·287·300/(0.003·750·27000) ≈ 0.51 (computed, assumed N and T). η_v at idle is thus well
  below the 0.8–0.9 peak value; a constant η_v ≈ 0.8 overpredicts idle airflow — use η_v(N, p_m) map or
  accept the error.
- Manifold stored air at idle: m = p_m·V_m/(R·T) ≈ 27e3·1e-3/(287·300) ≈ 0.31 g (computed) — small
  compared with the booster's air content (next section).

### Gaps
- No primary source found for measured passenger-car intake manifold volumes (only MathWorks default).
- Heywood's η_v curves and Bosch Automotive Handbook numbers were not accessible.

## Brake booster connection: hose, check valve, and booster air consumption

### Takeaway
The booster's vacuum (front) chamber connects to the manifold (downstream of the throttle) through a
hose and a one-way check valve that holds the last reached vacuum when p_m rises. A brake release dumps
the working chamber's atmospheric-pressure air (~1–2 g for a ~2 L chamber) into the manifold, which is
equivalent to ~0.5 s of idle airflow and shows up as a transient MAP rise / idle disturbance.

### Cited Findings
- Booster anatomy: a movable wall divides the housing into a front chamber connected to the vacuum
  source and a rear chamber selectively connected to the front chamber or to atmosphere via a valve
  mechanism — [US6446537B1](https://patents.google.com/patent/US6446537B1/en) (search summary)
- On application the input rod closes the vacuum port to the rear of the diaphragm and opens an
  atmospheric port; the pressure difference pushes the diaphragm/pushrod — [Brake & Front End, Booster
  service fundamentals](https://www.brakeandfrontend.com/brake-booster-service-fundamentals/) (search snippet)
- Booster chambers are evacuated and held at the achieved vacuum "by a properly operating check valve";
  at 20 inHg (68 kPa) the booster exerts 9.8 ± 0.5 psi on the diaphragm — [Tire Review](https://www.tirereview.com/brake-booster-and-the-barometer/) (search snippet)
- An 8-inch booster with 20 inHg engine vacuum gives ~240 lb of assist — [Brake & Front End](https://www.brakeandfrontend.com/vacuum-brake-booster-diagnostics/) (search snippet)
- Hella electric-pump data sheets quote "booster size"/test volume 3.2 L (UP28), 4 L (UP30), 5 L
  (UP32/UP5.0), and a vacuum-curve chart annotated "Booster volume = 4 L" — [Hella UP28/UP30/UP32 tech info](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf);
  [Hella brief: Vacuum pumps and pressure sensor](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
- Single boosters are scaled 9"–11", tandem 8+8" to 10+10" — [Bosch vacuum brake booster](https://www.bosch-mobility.com/en/solutions/driving-safety/vacuum-brake-booster/) (search summary)
- Hella's system diagram: booster → check valve → engine vacuum line, with the electric pump in parallel
  behind its own non-return valve and a pressure switch/sensor to the ECU — [Hella tech info](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf)
- Hella booster vacuum sensor: 0.4–4.8 V over 0 to −1000 hPa differential, ±16.5 hPa accuracy —
  [Hella brief](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
- Ford patents describe reducing booster vacuum consumption by limiting air entering the working chamber
  and limiting diaphragm stroke, so the engine can run longer at higher (more efficient) manifold
  pressures — [US 9260091 "Method and system for reducing vacuum consumption in a vehicle"](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9260091) (search summary; PDF was image-only)

### Inferences
- Booster model: treat the vacuum chamber as a second isothermal receiver
  dp_b/dt = (R·T/V_b)·(ṁ_rel − ṁ_bst), with ṁ_bst = orifice flow (same Ψ as the throttle) with effective
  area A_hose when p_b > p_m and **0 otherwise** (ideal check valve = pneumatic diode). ṁ_rel is the air
  admitted from the working chamber on release (and a small draw from diaphragm motion on apply).
- Air consumed per full apply–release: m ≈ V_w·(p_a − p_b)/(R·T). With V_w ≈ 2 L (half of a 4 L booster,
  assumed) and p_b = 30 kPa: m ≈ 2e-3·71e3/(287·293) ≈ 1.7 g (computed). Against ~3 g/s idle airflow
  (MOTOR) and ~0.3 g manifold content, releasing the brake at idle is a large disturbance: ~0.5 s worth of
  idle air. The idle-speed controller sees it as a vacuum leak (more air → more torque with fixed
  spark, or a MAP rise). Several successive pumps without re-evacuation step p_b toward p_a (each dump
  mixes working-chamber air into V_b).
- Vacuum available to the booster is p_a − max(p_b): altitude reduces it roughly in proportion
  (74 → 57 kPa at 5,500 ft per MOTOR), and assist force F ≈ A_diaphragm·(p_a − p_b).
- Check-valve cracking pressure and hose restriction numbers were not found; a lecture model can use
  A_hose ~ 20–40 mm² (hose ID ~ 6–8 mm, assumed) and zero cracking pressure.

### Gaps
- No source found giving measured grams of air per stop or measured idle-speed dip per brake release.
- No source for check-valve cracking pressure or hose ID; the SAE literature on booster vacuum
  consumption was not accessible.

## When manifold vacuum is insufficient: WOT, turbo, diesel, EV/hybrid, cold start, altitude

### Takeaway
Any unthrottled or boosted operation removes the vacuum source: at WOT and under boost the check valve
simply closes and the booster lives off stored vacuum; diesels and electrified drivetrains need a
dedicated pump (mechanical or electric). Cold-start catalyst heating (retarded spark → larger throttle
opening) and high altitude reduce vacuum, and ECUs actively trade efficiency to restore it.

### Cited Findings
- Diesels have no butterfly throttle; power is controlled by fuel quantity, so they create minimal
  manifold vacuum and use a separate vacuum pump ("exhauster") — [Wikipedia, Manifold vacuum](https://en.wikipedia.org/wiki/Manifold_vacuum)
- Running the engine "as unthrottled as possible" for fuel economy can leave insufficient vacuum for
  the brake booster; hybrids may be "not even capable of generating a vacuum"; the UP28 supports
  booster vacuum during cold start/warm-up, the UP30 is a stand-alone source — [Hella tech info](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf)
- Electric pump data (rotary vane, dry-running, all at 12–13.5 V):
  - UP28 (support application): max vacuum ≥ 86 % below ambient; 3.2 L test volume evacuated to
    p_abs = 500 mbar in ≤ 6 s and 300 mbar in ≤ 12 s (tech-info sheet); brief gives ≤ 5.5 s to −50 % and
    ≤ 11 s to −70 %; < 10 A average; 600 h life; > 450,000 switching cycles; < 1 kg
  - UP30: 4 L, 500 mbar ≤ 4 s, 300 mbar ≤ 8 s; UP32: 5 L, 500 mbar ≤ 3.4 s, 300 mbar ≤ 6.6 s;
    ≥ 1200 h; > 1.2 M cycles
  - UP5.0 (stand-alone): ≥ 90 % vacuum, 5 L, −50 % in ≤ 3.0 s, −70 % in ≤ 6.0 s, 16 A, 1,500 h, < 73 dB(A)
  — [Hella tech info](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf);
  [Hella brief](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
  (the tech-info sheet labels the condition "at 100 hPa ambient pressure", evidently a typo for 1000 hPa)
- Aftermarket rotary-vane pumps switch on below ~18 inHg and off above ~25 inHg; engines with less than
  ~15 inHg at idle give hard pedals; turbo/supercharged/big-cam engines are typical candidates —
  [Summit Racing vacuum pumps](https://www.summitracing.com/search/part-type/vacuum-pumps-street) (search summary; aftermarket, low-authority)
- Patents describe electric vacuum pumps plumbed between the booster and intake points upstream and
  downstream of the turbo compressor, and ejector/aspirator devices generating vacuum from intake flow —
  [US 8839755 "Electrically driven vacuum pump for a vehicle"](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8839755) (search summary);
  [US8925520B2 "Intake system including vacuum aspirator"](https://patents.google.com/patent/US8925520)
- Cold-start catalyst heating: the ECU retards spark to raise exhaust temperature and opens the throttle
  to hold torque, which lowers manifold vacuum available to the booster; GM's remedy momentarily
  interrupts heating (close throttle, advance spark) when MAP exceeds a threshold or after a set time,
  "a duration of one second is sufficient", holding torque variation < 5 Nm and idle speed variation
  < 50 rpm — [US8103431B2 "Engine vacuum enhancement in an internal combustion engine"](https://patents.google.com/patent/US8103431B2/en)
- Altitude: idle MAP stays ~27 kPa but vacuum falls from 74 kPa (sea level) to 57 kPa (5,500 ft) —
  [MOTOR](https://www.motor.com/magazine-summary/fuel-injection-diagnosis-july-2008/)

### Inferences
- Fitting p_b(t) = p_a·exp(−Q·t/V) to the Hella −50 % points gives effective pumping speeds
  Q ≈ V·ln2/t: UP28 ≈ 3.2·0.693/5.5 ≈ 0.40 L/s (24 L/min); UP5.0 ≈ 5·0.693/3.0 ≈ 1.16 L/s (69 L/min)
  (computed). The same Q predicts −70 % at 9.5 s (UP28) and 5.2 s (UP5.0) vs spec 11 s and 6 s, so a
  constant-Q pump with a floor p_min = 0.10–0.14·p_a is a fair lecture model:
  ṁ_pump = (Q/(R·T))·max(p_b − p_min, 0)·u_pump, with on/off hysteresis on p_b.
- Scenario matrix for the lecture:
  - NA SI, idle/overrun: p_m 20–35 kPa, check valve opens whenever p_b > p_m → booster recharged in
    well under a second after release (τ_m small, flow choked-limited by hose).
  - NA SI, WOT: p_m → ~p_a, ṁ_bst = 0; booster relies on stored vacuum; recharge on lift-off.
  - Turbo SI under boost: p_m > p_a; check valve closed; needs a pump/ejector for sustained demand.
  - Diesel: no throttle → p_m ≈ p_a (or boosted); mechanical or electric pump is the only source.
  - EV/HEV (engine off, start-stop): no engine flow; electric pump (UP30/UP5.0 class) or a
    non-vacuum brake (electro-hydraulic/eBooster).
  - Cold start with catalyst heating, high altitude: vacuum reduced, not absent.
- Mechanical camshaft/vacuum pumps on diesels are implied by Hella's note that its electric pumps need
  "no lubrication circuit connection" (mechanical vane pumps are oil-lubricated), but no primary data
  (flow, drive power) was found.

### Gaps
- No primary data found for mechanical (cam-driven) vacuum pump flow/power in passenger-car diesels.
- No quantified MAP values during catalyst-heating mode found (US8103431 uses an unspecified
  "predetermined MAP").

## Simplest credible lecture model and existing open models

### Takeaway
Two pneumatic states — p_m and booster pressure p_b — plus engine speed from the existing engine model
are sufficient. The throttle is a choked/subsonic orifice, the cylinders a speed-density sink, the check
valve a one-way orifice, and the brake pedal an air-admission event into the booster.

### Cited Findings
- MathWorks Air Intake block is a ready reference implementation (one pressure state, cubic throttle
  area, leakage area, speed-density sink, constant ambient temperature) — [MathWorks Air Intake](https://www.mathworks.com/help/sdl/ref/airintake.html)
- MathWorks Flow Restriction block provides the compressible orifice with a linearized region near
  Δp = 0 (Π_lim = 0.95), useful for the check valve/hose, which operates near Δp → 0 when the booster is
  nearly recharged — [MathWorks Flow Restriction](https://www.mathworks.com/help/autoblks/ref/flowrestriction.html)
- Hendricks' MVEM line (SAE 960037) and Guzzella & Onder (Springer 2009) are the standard references
  for this structure — [SAE 960037](https://saemobilus.sae.org/papers/modelling-intake-manifold-filling-dynamics-960037); [arXiv 2107.14321 references](https://arxiv.org/pdf/2107.14321)

### Inferences
- Essential states and parameters:
  - p_m: V_m (≈1 L), T_m (≈ ambient, isothermal), throttle D (≈50 mm), C_d (≈0.7–1, assumed), A_leak
    (≈1 cm², sets idle), V_d, η_v (constant 0.6–0.8 or a map).
  - p_b: V_b (3–5 L vacuum side, Hella test volumes), A_hose, ideal check valve.
  - Brake event: admits m ≈ V_w·(p_a − p_b)/(R·T) on release (or model the working chamber as a third
    receiver with pedal-controlled valves if pedal-force dynamics matter).
  - Optional: electric pump ṁ_pump with hysteresis (on ~18 inHg, off ~25 inHg per aftermarket data).
- Safe to omit: temperature dynamics (isothermal), throttle actuator lag (0.1 s default), EGR, intake
  runner wave dynamics, fuel film/wall-wetting, induction-to-power delay (matters for torque, not vacuum),
  hose volume, η_v dependence on p_m (unless idle accuracy matters — see η_v ≈ 0.5 check above).
- Engine torque coupling (optional): mean torque ∝ ṁ_cyl for stoichiometric operation, so the idle speed
  dip after a brake release follows from the extra ṁ_bst only if the engine model has an idle-speed
  controller; otherwise show the MAP bump only.

### Gaps
- No open Modelica library with an SI intake-manifold + brake-booster vacuum model was found in this
  search (Modelica Standard Library/VehicleInterfaces were not checked in depth).
- MathWorks throttle-flow constants c1..c3, ca, cb were not visible in the fetched summary.
