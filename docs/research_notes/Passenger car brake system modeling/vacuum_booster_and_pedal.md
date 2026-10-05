# Vacuum Brake Booster (Brake Servo) and Driver Pedal — Lumped Modeling Notes

Source-quality note up front: the most useful primary source found and actually read was the California PATH report by Hedrick, Gerdes, Maciuca and Swaroop (UCB-ITS-PRR-97-21, 1997). Its parameter table (Table 2.1) and its measured chamber-pressure traces (Figs. 2.13–2.16) come from an instrumented PATH test car. The full vacuum-booster equations of that group appear in Gerdes & Hedrick, "Brake System Modeling for Simulation and Control", ASME J. Dyn. Sys. Meas. Control 121(3):496, 1999. That paper is paywalled and was not read. The report's text is also mostly un-extractable (Type-3 fonts), so its pages were read as images. The second source is the Delphi patent US6033038A, which gives a full two-chamber booster ODE model. Many SAE papers, ResearchGate papers and trade-press pages returned 403 or were paywalled; these are listed as gaps.

---

## 1. Construction and operating phases (released / apply / hold / release)

### Takeaway
A single-diaphragm booster has two chambers. The front chamber (vacuum chamber, on the master-cylinder side) is always connected through a check valve to the manifold or a pump. The rear chamber (working, or apply, chamber) sits on the pedal side. A control valve (poppet valve) in the hub of the power piston is driven by the relative displacement between the input pushrod/plunger (valve plunger, "air valve") and the power-piston body. It has three states:
- **Released:** the vacuum valve is open and the atmospheric valve closed, so both chambers sit at vacuum.
- **Apply:** the vacuum valve closes and the atmospheric valve opens, so air flows into the rear chamber.
- **Hold / lap:** both valves are closed, and the pressure difference is trapped.

A reaction disc (rubber "reaction washer") splits the output-rod reaction between the plunger and the piston. This sets the servo ratio and the jump-in. Which phase is active is decided purely by the force balance on the plunger versus the power piston: plunger displacement relative to the piston, with a dead band or valve spring.

### Cited Findings
- At rest, vacuum from the intake manifold or a dedicated pump is present on both sides of the diaphragm. On apply, the control valve "closes the vacuum path between the two chambers and opens one side to atmospheric pressure". On release, the control valve restores vacuum to both chambers. A "reaction disc … transmits force and provides proportional pedal feedback". — [EduMech: Vacuum Brake Booster](https://www.edumech.co.uk/learn/braking/vacuum-brake-booster)
- Bosch: in a two-chamber design with a movable diaphragm, "when the driver actuates the brake pedal, ambient air flows into the rear chamber", which pushes the diaphragm toward the master cylinder. — [Bosch Mobility: Vacuum brake booster](https://www.bosch-mobility.com/en/solutions/driving-safety/vacuum-brake-booster/)
- The valves are designed so that the assist force of the piston is always proportional to the pedal force. Both sides are under vacuum at rest. A check valve holds the vacuum at full load and with the engine stopped. Housing diameter reaches up to 11 in (about 28 cm). Tandem units are used where space is tight (e.g. Smart). — [de.wikipedia: Bremskraftverstärker](https://de.wikipedia.org/wiki/Bremskraftverst%C3%A4rker)
- Delphi patent model: flows are atmosphere → apply chamber (m1) through the air valve, apply chamber → vacuum chamber (m2) through internal passages of the power piston, and vacuum chamber → intake manifold (m3) through the check valve. Flow-mode switches are ψ1 = 1 if the piston moves forward (apply), ψ2 = 1 if it moves rearward (release), and ψ3 = 1 when P_v > P_map (check valve open). — [US6033038A, Brake control method having booster runout and pedal force estimation](https://patents.google.com/patent/US6033038A/en)
- Delphi: "the pushrod force (that is, the pedal force F_pedal acting through the amplification ratio R_bp of the brake pedal) is opposed by the sum of the pushrod reaction force F_rpr, the air valve spring force F_av, and the contact force F_contact". — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Gerdes/Hedrick: "the vacuum booster model combines a static control valve with dynamic air flows, resulting in the ability to easily reproduce both static hysteresis effects and rapid transients". — [Gerdes & Hedrick 1999, ASME JDSMC 121(3):496 (abstract)](https://asmedigitalcollection.asme.org/dynamicsystems/article-abstract/121/3/496/395112/Brake-System-Modeling-for-Simulation-and-Control)
- The PATH report notes that earlier literature models were too heavy or too crude. Fisher (1970) needed 18 states for pedal + booster + master cylinder + lines. Khan et al. (1994) used 10 states, validated only for very slow applies, with "highly questionable thermodynamics", and ignored reaction-washer hysteresis and master-cylinder seal friction. Brake dynamics were often treated as first-order plus pure delay (McMahon 1990; Raza 1994). The PATH three-state model (two chamber pressures + one hydraulic volume) was proposed instead. — [Hedrick, Gerdes, Maciuca, Swaroop, PATH UCB-ITS-PRR-97-21, 1997, p. 5](https://escholarship.org/uc/item/02b8f7q2)
- A 2013 structural booster model for pedal-feel analysis uses three springs, two valves, one reaction washer and dynamic air flows, with explicit "state identification criteria". — [Scientific.Net AMR 622-623:1248, "A Vacuum Booster Model for Brake Pedal Feeling Analysis" (abstract)](https://www.scientific.net/AMR.622-623.1248)
- Reaction disc (patents): the reaction disc "provide[s] a predetermined servo ratio by distributing a reaction force from the master cylinder … to the power piston and the plunger". It also gives the jump-in, because it is initially separated from the plunger. In some two-stage designs the servo ratio in the initial interval is greater than later. — [USPTO patent 5907990, "Brake booster having a reaction force mechanism"](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5907990); [USPTO 5943937](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5943937)

### Inferences
Phase logic for a lumped model follows the Gerdes approach of a static valve plus dynamic flows. Let `F_in` be the pushrod force, `F_r` the reaction-disc force on the plunger, and `F_app`, `F_rel` the valve thresholds:
- **Apply** (atmospheric valve open, vacuum valve closed) if `F_in − F_r(...) > F_app`.
- **Release** (vacuum valve open, atmospheric valve closed) if `F_in − F_r(...) < −F_rel`.
- **Hold / lap** (both closed) otherwise.

The PATH Table 2.1 lists `F_app = 50 N` and `F_rel = 50 N`. The symbol names suggest they are exactly these apply/release thresholds, but the defining equation was not read because it is in the paywalled 1999 paper. The dead band `F_app + F_rel` creates the static hysteresis of the booster characteristic.

An alternative is a geometric valve. Valve-opening areas are functions of the plunger-to-piston relative displacement `δ = x_plunger − x_piston`: `A_atm(δ) = w·max(0, δ − δ0)` and `A_vac(δ) = w·max(0, −δ − δ0)`, where `δ0` is the lap (poppet-seat) overlap. This form is standard and needs the poppet geometry (not found).

### Gaps
- The exact 1999 Gerdes & Hedrick booster equations (valve force balance, reaction-washer hysteresis model) were not accessible (ASME paywall).
- No source was found that gives poppet-valve seat diameters or stroke-dependent opening areas.

---

## 2. Static characteristic: output vs input force, jump-in, servo ratio, knee/run-out, hysteresis

### Takeaway
F_out vs F_in has these parts:
1. A dead zone up to the cut-in force (return spring + valve spring preload).
2. A vertical jump-in step, while the clearance between reaction disc and plunger closes.
3. A linear boosted section with slope = servo ratio. The servo ratio is set by the reaction-disc area ratio (piston/plunger contact areas), not by diaphragm size.
4. A knee (run-out) where the rear chamber reaches atmospheric pressure, so assist saturates at `A_d·(p_atm − p_front)`.
5. Above run-out, a slope of 1 (pure mechanical), or pedal ratio × 1 at the pedal.

The release branch lies below the apply branch (hysteresis) because of valve dead band, seal friction and rubber-disc hysteresis.

### Cited Findings
- Force balance on the power piston (Delphi quasi-static form): `P_a = P_v(last) + (F_rpp + F_ret − F_av − F_contact)/A_boost`. Here F_rpp is the reaction (master-cylinder) force on the piston, F_ret the return spring, F_av the air-valve spring force and F_contact the contact force. "Runout occurs when the apply chamber pressure P_a reaches atmospheric pressure P_atm." — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- The pushrod force `F_pedal·R_bp` is balanced by `F_rpr + F_av + F_contact` (reaction on pushrod + air-valve spring + contact force). During run-out the extra pedal force goes through the contact force. — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Simple booster force relation used in a vehicle design paper: `F_t = F_c − (P_vac1 − P_vac2)·A_vac`, where F_c is the master-cylinder pushrod force, F_t the input force and A_vac the diaphragm area. Pedal: `F_p = F_t·l_p1/l_p2`. Their city-car example (MEV-02, about 1.0–1.3 t) needed 426 N pedal force with the booster vs 625 N without for 3.2 MPa line pressure, i.e. only 1.48× (a small city-car booster). — [Nugraha et al., Int. J. Technology 12(4):802–812, 2021](https://ijtech.eng.ui.ac.id/download/article/4636)
- Jump-in: "At the initial stage of power assistance, a clearance between the front reaction disk and the rear reaction disk is taken up to thereby provide a 'jump-in' output force. Subsequent to a specific point, the output rises in accordance with a given servo ratio which is determined by the ratio of the area of the end face of the sleeve contacted by the reaction disc and the area of the end face of the plunger plate contacted by the reaction disc." — [USPTO 5943937, Pressure differential operated brake booster](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5943937)
- Boost ratio is also described as the ratio of the plunger abutting cross-section to the output-rod abutting cross-section. A typical range of 3:1 to 8:1 is quoted. This came via search snippet from a secondary blog (PatSnap Eureka), so treat it as low-reliability. — [PatSnap Eureka blog: What is a brake booster](https://eureka.patsnap.com/blog/machinery-tech-resources/what-is-brake-booster/)
- Driving-style tuning (EHB benchmarked on the vacuum-booster curve): a "comfort" feel means a larger jump-in and a larger boost ratio in the linear section. A "sporty" feel means a lower jump-in and a lower ratio. Cut-in force is kept the same. After run-out all curves have the same slope. The vacuum-booster apply/return curve with hysteresis is used as the baseline characteristic. — [Scientific Reports 14 (2024), s41598-024-80788-2](https://www.nature.com/articles/s41598-024-80788-2)
- Measured behavior (PATH test car): with a slow ramp to about 375 N input force, the apply-chamber pressure rose from about 33 kPa abs to about 72–74 kPa abs, i.e. below atmospheric, so this was not run-out. The vacuum chamber rose transiently from 33 to about 38 kPa and then decayed back to about 34 kPa as the manifold re-evacuated it. On release the vacuum chamber spiked again to about 38 kPa as apply-chamber air was dumped into it. — [PATH UCB-ITS-PRR-97-21, Fig. 2.13/2.14, pp. 24–25](https://escholarship.org/uc/item/02b8f7q2)
- The PATH authors state that neglecting booster inertia shows up at the start of air flow: "Since pedal inertia contributes to F_in, no single value for the booster characteristic can predict the exact force required to initiate braking for step and slow responses." — [PATH report p. 24](https://escholarship.org/uc/item/02b8f7q2)

### Inferences
Recommended static equations. `F_rs0 + K_rs·x_p` is the return spring, `F_mc` the force demanded by the master cylinder, `A_d` the effective diaphragm area, and `Δp = p_front − p_rear` with p_front the vacuum chamber and p_rear the working chamber.

- **Power-piston force balance (massless):**
  `F_out = F_in,disc_share + A_d·(p_rear − p_front) − (F_rs0 + K_rs·x_p)`.
  In steady boosted operation, the reaction-disc law gives the split. The output reaction `F_out` spreads over the disc (area `A_disc`, output side). The plunger sees `F_in = F_out·(A_pl/A_disc)`, so `F_out = (A_disc/A_pl)·F_in = SR·F_in` (servo ratio `SR = A_disc/A_pl`). The piston supplies the rest, `F_out·(1 − A_pl/A_disc)`. This holds while the plunger is in contact with the disc. Before contact (jump-in), `F_in` is carried only by the valve spring, and F_out jumps to the value at which the disc bulges enough to touch the plunger.
- **Characteristic curve (piecewise):**
  - `F_out = 0` for `F_in < F_cut-in`.
  - `F_out = F_jump + SR·(F_in − F_cut-in)` in the boosted regime.
  - Run-out assist `F_assist,max = A_d·(p_atm − p_front) − F_rs`, which gives the knee input force `F_in,knee ≈ F_assist,max/(SR − 1)`.
  - Beyond the knee, `F_out = F_out,knee + (F_in − F_in,knee)`.
- **Worked number with the PATH parameters** (A_d = 5.33×10⁻² m², vacuum ≈ 33 kPa abs, p_atm ≈ 101.3 kPa): `Δp_max ≈ 68 kPa`, so `F_assist,max ≈ 3.6 kN` before subtracting the return spring (97 N preload). This is consistent with the Bosch iBooster "supporting force up to 6.2 kN" being a larger, tandem-class replacement.
- **Vacuum-level dependence:** the run-out point scales linearly with `(p_atm − p_manifold)`. At altitude or with poor vacuum (turbo GDI under load), the knee moves to lower pedal forces.

### Gaps
- No primary, numeric source was obtained for typical servo ratio (a range of about 4–8 is commonly quoted, but only a blog snippet was found), jump-in force (N), cut-in force (N) or hysteresis width (N) for a named production booster. The 2019 SAE characterization paper (Walker, Rucoba, Barnes & Kent, SAE 2019-01-0412) and SAE J1808 (booster test procedure) would contain these but are paywalled.
- Reaction-disc rubber properties (Shore hardness, stiffness) were not found.

---

## 3. Dynamics: chamber mass balances, valve flows, chamber volumes, response time

### Takeaway
The standard lumped model has two pressure states, `p_a` (apply/rear) and `p_v` (vacuum/front). Each gets an ideal-gas mass balance with a variable volume driven by power-piston travel `x_p`. Three flows connect them: atmosphere → rear (atmospheric valve), rear → front (vacuum valve), and front → manifold (check valve). Piston travel is usually taken as quasi-static from the master-cylinder pressure–volume curve rather than as a mass-spring state. Response is dominated by filling the rear chamber through the small atmospheric-valve orifice (hundreds of ms for full assist). The PATH authors describe booster dynamics as having large pure time delay and lag.

### Cited Findings
- **Delphi (US6033038A) chamber ODEs, verbatim form:**
  - `dP_a/dt = 1/V_a · [R·γ·T_atm·(m1·ψ1 − m2·ψ2) − γ·P_a·A_b·Ẋ_p]`
  - `dP_v/dt = 1/V_v · [R·γ·T_atm·(m2·ψ2 − m3·ψ3) − γ·P_v·A_b·Ẋ_p]`

  Here γ = 1.4 (the patent calls it "Boyle's coefficient"; it is the adiabatic ratio of specific heats), T_atm is the under-hood air temperature, and A_b the total diaphragm area. `V_v = A_boost·[(X_pmax/2) − X_p(0) − X_p]`, and V_a is diaphragm area × piston displacement. — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Orifice flow in the same patent: m1 and m2 use a discharge coefficient C_d, the passage area A, upstream and downstream pressures p_u and p_d, pressure ratio ν = p_d/p_u, and a factor B, "the value of singularity when the ratio ν is equal to one". m3 (to the manifold through the check valve) "is determined empirically as a function of pressure differential between vacuum chamber and engine intake manifold". — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Power-piston travel in the Delphi model: "X_p is computed as a function of master cylinder pressure P_mc using an empirically determined calibration table". X_p also sets the return-spring force F_ret. — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Other patents describe the same structure: the model contains the movable partition, working and vacuum chambers, and three valves between the ventilation side, working chamber, vacuum chamber and venting side. Fluidic processes are modeled with mass conservation in the chambers and momentum along flow lines (Bernoulli), with the ideal-gas law and the first/second law of thermodynamics. — [US8155821, Vacuum brake booster and method for the operation thereof](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8155821)
- The PATH/Gerdes model uses linearized flow coefficients. Table 2.1 (units m·s, so mass flow [kg/s] = C·Δp [Pa]):
  - `C_aa = 5.8×10⁻⁵ m·s` (atmosphere → apply)
  - `C_av = 2.2×10⁻⁴ m·s` (apply → vacuum)
  - `C_vm = 1.26×10⁻⁴ m·s` (vacuum → manifold, check valve)
  - `C_leak = 1.4×10⁻⁷ m·s`

  Chamber volumes: `V_vo = 2.4×10⁻³ m³` (vacuum chamber, 2.4 L) and `V_ao = 4.3×10⁻⁴ m³` (apply chamber at rest, 0.43 L). Diaphragm area `A_d = 5.33×10⁻² m²`. Return spring `F_rso = 97 N`, `K_rs = 2411 N/m`. Valve thresholds `F_app = 50 N`, `F_rel = 50 N`. Master cylinder: `A_mc = 4.91×10⁻⁴ m²` (25 mm bore), spring `F_cso = 138 N`, `K_cs = 175 N/m`, seal friction `F_cf = 80 N`. Push-out pressure `P_o = 10.67 kPa`, line flow coefficient `C_q = 1.4 cm³/(s·√kPa)`. — [PATH UCB-ITS-PRR-97-21, Table 2.1, p. 23](https://escholarship.org/uc/item/02b8f7q2)
- The PATH report states that the parameters were determined "directly by experiment" where possible and otherwise by matching simulation to experiment. The test car had pressure sensors in the apply and vacuum chambers, intake manifold, master-cylinder secondary line and front brake, plus potentiometers on the pedal linkage and master cylinder, and a hydraulic cylinder applying the pedal input. Remaining chamber-pressure mismatch was attributed to "linearization and the simplified treatment of orifice size and check valve flow". — [PATH report pp. 22–24](https://escholarship.org/uc/item/02b8f7q2)
- Master-cylinder coupling used with the booster (PATH single-state form): `P_mc = (F_out − F_cs − F_cf)/A_mc`, `x_mc = V/A_mc`, `V̇ = σ·C_q·√|P_mc − P_w|`, `P_w = P_w(V)` (cubic P–V capacity). — [PATH report eqs. 2.32–2.35, p. 19](https://escholarship.org/uc/item/02b8f7q2)
- Timing (PATH test car, step input of about 200 N): master-cylinder pressure starts rising about 0.08 s after the input and overshoots to about 1.85 MPa at about 0.12 s. The wheel pressure follows with a lag and settles at about 2.85 MPa by about 0.4–0.5 s (Fig. 2.12, hydraulic model validation). — [PATH report Fig. 2.12, p. 23](https://escholarship.org/uc/item/02b8f7q2)
- The later PATH work cites Gerdes (1996) on booster dynamics having "large 'pure' time delay and lag". — [UC Berkeley PATH report (eScholarship qt7n15m1wk)](https://escholarship.org/content/qt7n15m1wk/qt7n15m1wk.pdf) (seen via search snippet only)
- Response-time limits in panic braking: "In an emergency stop where the brake pedal is rapidly depressed, the vacuum booster may not be able to react fast enough". Brake Assist Systems (mechanical or electromechanical) detect fast pedal application and give 100 % assist. — [US6705200B2, Vacuum brake booster with mechanical emergency braking assistance](https://patents.google.com/patent/US6705200B2/en); related [US5249651, Pneumatic brake booster with improved response time](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5249651)

### Inferences
Recommended lumped model (isothermal is adequate for the slow re-evacuation; adiabatic γ = 1.4 as in Delphi for fast apply; a polytropic n between 1 and 1.4 is a common compromise).

- **Chamber volumes:**
  `V_f(x_p) = V_f0 − A_d·x_p` and `V_r(x_p) = V_r0 + A_d·x_p` (PATH: V_f0 = 2.4 L, V_r0 = 0.43 L).
- **Pressure ODEs (polytropic n):**
  - `dp_r/dt = n/V_r · (R·T·(ṁ_atm→r − ṁ_r→f) − p_r·A_d·ẋ_p)`
  - `dp_f/dt = n/V_f · (R·T·(ṁ_r→f − ṁ_f→man − ṁ_leak) + p_f·A_d·ẋ_p)`

  The sign on the ẋ_p term follows from V_f shrinking as the piston advances. Note that Delphi writes the vacuum-chamber term with the same sign as the apply chamber; check the sign convention for your own x_p direction.
- **Valve flows:**
  - Linear option (Gerdes): `ṁ = C·(p_up − p_down)` in the open state, with C_aa, C_av, C_vm as above.
  - Compressible-orifice option (ISO 6358 form; standard formulation, not re-fetched in this session):
    - choked flow, `p_d/p_u ≤ b`: `ṁ = C·p_u·ρ0·√(T0/T_u)`
    - subsonic flow: `ṁ = C·p_u·ρ0·√(T0/T_u)·√(1 − ((p_d/p_u − b)/(1 − b))²)`

    Here C is the sonic conductance and b the critical pressure ratio (about 0.528 for an ideal nozzle; lower for real valves). Opening areas are scaled with the valve state or displacement.
  - Check valve: one-way, `ṁ_f→man = C_vm·max(0, p_f − p_man − Δp_crack)`. The cracking pressure was not found; a few kPa is typical, but that value is unsourced.
- **Piston travel:** quasi-static from the master-cylinder volume. PATH (single state): `x_p = x_mc = V/A_mc`, with V from the hydraulic flow ODE. Alternatively use a mass-spring state (booster moving mass is small; PATH neglected booster inertia).
- **Time scale from PATH coefficients:** rear-chamber time constant `τ ≈ V_r/(R·T·C_aa)`. With `V_r ≈ 0.5–1 L`, `R·T ≈ 8.4×10⁴ J/kg` and `C_aa = 5.8×10⁻⁵`, τ ≈ 0.1–0.2 s. This is consistent with the observed ~0.1–0.4 s rise times.

### Gaps
- The exact compressible-flow expression in US6033038A (##EQU1##) did not render. Numeric C_d and passage areas were not given.
- There is no measured booster response time (ms to 90 % output) for a production unit from a primary source. Such data sits in SAE J1808 test results and paywalled SAE papers.
- The paper "Modelling and Simulation of Brake Booster Vacuum Pumps" (SAE 2013-01-9016) uses mass and energy conservation per control volume. Only its abstract was seen. — [SAE 2013-01-9016](https://www.sae.org/publications/technical-papers/content/2013-01-9016/)

---

## 4. Typical numbers: sizes, volumes, springs, vacuum, consumption, reserve

### Takeaway
Passenger-car single boosters are 9–11 in diameter and tandems 8+8 to 10+10 in (Bosch). The PATH test car had A_d = 0.0533 m², equivalent to a 260 mm (10.3 in) diaphragm, with a 2.4 L front chamber and a 0.43 L rear chamber. Test "booster volumes" used by pump suppliers are 3.2–5 L. Idle manifold vacuum at the booster is 17–21 inHg (about 30–43 kPa abs at sea level); the PATH car measured 33 kPa abs. A full application consumes roughly 0.5–1 L of free air, and with the check valve closed the booster gives about 2–3 useful assisted applications.

### Cited Findings
- **Sizes:** Bosch single boosters are "scalable from 9" to 11"". Tandem boosters range from 8+8" to 10+10", and tandems (four chambers) are used for larger vehicles. The Tie-Rod variant is up to 20 % lighter, with aluminum another 20–25 % lighter. — [Bosch Mobility: Vacuum brake booster](https://www.bosch-mobility.com/en/solutions/driving-safety/vacuum-brake-booster/)
- **PATH test-car parameters** (full list in Section 3): A_d = 5.33×10⁻² m², V_vo = 2.4 L, V_ao = 0.43 L, return spring 97 N + 2411 N/m, valve thresholds 50 N / 50 N. — [PATH UCB-ITS-PRR-97-21, Table 2.1](https://escholarship.org/uc/item/02b8f7q2)
- **Measured chamber pressures** (PATH test car, engine idling): both chambers at about 33 kPa abs at rest. The apply chamber reached about 72–74 kPa abs with about 375 N input force, and about 60–65 kPa with about 200 N step input. — [PATH report Figs. 2.13–2.16, pp. 24–27](https://escholarship.org/uc/item/02b8f7q2)
- **Vacuum supply:** 17–21 inHg at idle at the booster is the service-trade specification. — [Brake & Front End, Brake Booster: How to test vacuum power assist](https://www.brakeandfrontend.com/ase-a5-how-to-test-vacuum-power-assist-and-hydroboost-braking-systems/) (via search snippet; page fetch was blocked with 403)
- **Reserve:** the check valve "traps reserve vacuum inside to ensure 2 to 3 power-assisted brake applications remain available if the engine unexpectedly dies". In the engine-off test, "at least two brake applications should have a power-assisted feel before the pedal hardens". — [Brake & Front End (via search snippet)](https://www.brakeandfrontend.com/ase-a5-how-to-test-vacuum-power-assist-and-hydroboost-braking-systems/); [OpenExamPrep ASE A5 guide](https://open-exam-prep.com/study-guides/ase-a5/hydraulic-power-assist-core/vacuum-booster-operation) (secondary)
- **Electric vacuum-pump test volumes and evacuation times** (Hella/Pierburg UP28):
  - Test volume about 3.2 L: 500 mbar abs in ≤ 6 s, 300 mbar abs in ≤ 12 s (12 V, 1000 hPa ambient). Maximum vacuum ≥ 86 % below ambient.
  - Other variants: test volume 4 L gives 500 mbar in ≤ 4 s and 300 mbar in ≤ 8 s; 5 L gives 500 mbar in ≤ 3.4 s and 300 mbar in ≤ 6.6 s.
  - Hella's brief lists "booster size 3.2 l / 5 l".

  — [EV West: Hella UP28 technical information PDF](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf); [Hella Brief Information, vacuum pumps and pressure sensor](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
- **Hella booster-vacuum pressure sensor range:** 0 to −1000 hPa differential, with 0.5–4.5 V output. — [Hella Brief Information](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
- **Electric vacuum pump on a converted EV** (MEV-02 city car): extra 250×170×170 mm package, 2.6 kg, 3.9 Wh battery consumption (their test cycle). — [Nugraha et al., Int. J. Technology 2021](https://ijtech.eng.ui.ac.id/download/article/4636)

### Inferences
- **Air consumed per application** (computed from PATH parameters, isothermal, 20 °C). Filling the rear chamber from 33 kPa to atmospheric at an assumed piston travel of 10 mm (`V_r = 0.43 + 0.53 = 0.96 L`) takes `Δm = Δp·V_r/(R·T) ≈ 0.78 g` of air, about 0.65 L at ambient conditions. On release this mass is dumped into the front chamber and must be pumped out by the manifold. This is the load the booster places on the engine-manifold model.
- **Reserve after the engine stops** (computed; check valve closed, no leakage). Pressure after each full-to-atmosphere application and release is `p_{k+1} = [p_k·(V_f0 − A_d·x) + p_atm·(V_r0 + A_d·x)]/(V_f0 + V_r0)`. The table gives the start pressure before each stop and the maximum assist `A_d·(p_atm − p_k)`:

  | Stop | x = 5 mm: start pressure | x = 5 mm: max assist | x = 10 mm: start pressure | x = 10 mm: max assist | x = 15 mm: start pressure | x = 15 mm: max assist |
  |---|---|---|---|---|---|---|
  | 1 | 33 kPa | 3.64 kN | 33 kPa | 3.64 kN | 33 kPa | 3.64 kN |
  | 2 | 50 kPa | 2.74 kN | 56 kPa | 2.40 kN | 63 kPa | 2.06 kN |
  | 3 | 63 kPa | 2.07 kN | 72 kPa | 1.58 kN | 80 kPa | 1.16 kN |
  | 4 | 72 kPa | 1.56 kN | 82 kPa | 1.04 kN | 89 kPa | 0.66 kN |
  | 5 | 79 kPa | 1.18 kN | 88 kPa | 0.69 kN | 94 kPa | 0.37 kN |

  This reproduces the "2–3 assisted applications" rule of thumb. It is a modeler's calculation from PATH parameters, not a measured result.
- **Useful identities:**
  - 1 inHg = 3.386 kPa, so 17–21 inHg vacuum at sea level is about 30–44 kPa abs.
  - Equivalent diameter `D = 2·√(A/π)`, so 9 in gives 0.041 m² and 11 in gives 0.061 m² gross area; effective area is smaller because of the hub and diaphragm roll.

### Gaps
- There is no primary number for diaphragm effective area vs nominal size, rear-chamber dead volume, or piston travel to run-out for a named production booster.
- There is no primary measurement of air consumption per stop, or of the number of assisted stops, for a specific booster. The figures above are computed.

---

## 5. Pedal: ratio, travel, forces, feel

### Takeaway
The pedal is a lever. `F_pushrod = i_p·F_pedal` with pedal ratio `i_p = l_pedal/l_pushrod`, and pushrod travel `x_pr = x_pedal/i_p`. Boosted pedals typically sit around 3–5:1; manual (unboosted) pedals are around 5–7:1. Regulatory tests bound driver force at 500 N maximum (FMVSS 135 / ECE R13-H), including the booster-failed (depleted) test.

### Cited Findings
- Pedal ratios: "Typical non-boosted ratios range from 6:1 to 7:1, with booster pedals using 4.5:1 to 5:1". "The average person can press on the brake pedal with about 70 lbs of force." These are aftermarket/hot-rod figures, so OEM passenger cars may be lower (3–4:1 commonly quoted, not confirmed here). — [Summit Racing Help Center: What is brake pedal ratio](https://help.summitracing.com/knowledgebase/article/SR-05037/en-us); [Master Power Brakes: calculating pedal ratio](https://mpbrakes.com/how-to-series-correctly-calculating-brake-pedal-ratio/)
- One boosted system is described as using 3.2:1 to 4:1. This came from a search-result summary whose provenance was not verified (Tomorrow's Technician page). — [Tomorrow's Technician: Understanding Brake Boosters](https://www.tomorrowstechnician.com/boosters-and-master-cylinders-how-pressure-builds/)
- FMVSS 135 (light vehicles):
  - The service-brake effectiveness tests (S7.5 cold, S7.6 high speed, S7.7 engine off) use a pedal-force window of 65 N to 500 N. The retrieved text renders it "≤65 N, ≤500 N"; the lower bound is the minimum-force parameter.
  - S7.11 "Brake power unit or brake power assist unit inoperative (system depleted)": exhaust any residual reserve, then make 6 stops, each by a continuous application, with pedal force ≤ 500 N. Stopping distance must be ≤ 168 m from 100 km/h (or S ≤ 0.10·V + 0.0158·V²).

  — [49 CFR 571.135 (Cornell LII)](https://www.law.cornell.edu/cfr/text/49/571.135)
- The booster-failure requirement: FMVSS 135 required MY2000+ cars and MY2002+ light trucks to meet tougher stopping distances with the booster failed. — [Counterman: Power brake boosters](https://www.counterman.com/power-brake-boosters/) (via search snippet)
- PATH measured "human-like" input forces at the pushrod/pedal-linkage of about 375 N (slow apply, about 1 s ramp) and about 200 N (step). The input was applied by a hydraulic cylinder on the pedal linkage. — [PATH report Fig. 2.13](https://escholarship.org/uc/item/02b8f7q2)
- Delphi model: pedal force is estimated as `F_pedal = (F_rpr + F_av + F_contact)/R_bp`, with R_bp the pedal amplification ratio. — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- Variable-ratio pedals exist to shape feel. — [EP1349755B1, Brake pedal assembly with variable ratio](https://patents.google.com/patent/EP1349755B1/en)

### Inferences
Pedal model:
- Rigid lever: `F_pr = i_p·F_ped − F_pedal_return_spring`, `x_pr = x_ped/i_p`, with pedal inertia `J_p` if pedal dynamics matter. PATH notes that pedal inertia visibly affects the start of flow.
- Pedal feel = F_ped vs x_ped, which is the sum of:
  - lost travel (pushrod gap + booster valve lap + master-cylinder compensation-port closure)
  - jump-in (pedal barely moves while output steps)
  - boosted slope = hydraulic P–V stiffness divided by `(SR·i_p)²` in stiffness terms
  - run-out (sudden pedal hardening)

Rough envelope (not sourced to a primary document): normal braking is about 50–150 N at the pedal, emergency 300–500+ N. The 500 N regulatory ceiling defines the upper test value.

### Gaps
- There is no primary (OEM/Bosch Handbook) figure for pedal ratio, total pedal travel (mm), or pushrod travel for modern passenger cars. The Bosch Automotive Handbook and Limpert "Brake Design and Safety" were not accessible.
- There are no ECE R13-H numeric details beyond what the FMVSS mirror provides. The ECE R13-H text was only seen on Scribd and not fetched.

---

## 6. Check valve and alternatives to manifold vacuum (pumps, electromechanical boosters)

### Takeaway
A one-way check valve between manifold and booster holds the lowest pressure reached. It isolates the booster at wide-open throttle, when a turbocharger produces positive manifold pressure, and after engine stop. Diesels, unthrottled engines (Valvetronic/MultiAir), turbo-GDI, stop/start, hybrids and EVs lack reliable manifold vacuum. They use mechanical (camshaft/alternator-driven) or electric vane vacuum pumps, or drop the vacuum booster in favor of electromechanical boosters (Bosch iBooster, ZF/TRW EBB). Electromechanical boosters also add brake-by-wire functions: regen blending, automated braking, redundancy.

### Cited Findings
- A check valve keeps residual vacuum without engine support, which allows limited use after parking. — [Wikipedia: Vacuum servo](https://en.wikipedia.org/wiki/Vacuum_servo)
- Diesel engines and throttle-less gasoline engines (Valvetronic, MultiAir) need a separate vacuum pump. The check valve maintains vacuum at full load and with the engine stopped. — [de.wikipedia: Bremskraftverstärker](https://de.wikipedia.org/wiki/Bremskraftverst%C3%A4rker)
- The Hella UP28 electric vane pump is triggered on demand when the engine cannot supply enough vacuum (cold start/warm-up, high altitude, A/C load, or unthrottled operation for efficiency). The UP5.0/UP30 is a standalone vacuum supply for all drive concepts including EV/hybrid. The pump sucks air from the booster through the brake system's pneumatic lines, and a pressure sensor lets the ECU switch it. — [EV West / Hella UP28 technical information](https://www.evwest.com/support/SC-VP-Hella-UP28-Vacuum-Pump-Technical-Information.pdf); [Hella Brief Information](https://www.hella.com/resources-soe/assets/documents_global/10069076a_AM0.pdf)
- Turbo engines make vacuum at idle and light load, but manifold pressure is positive under boost. GDI and stop/start reduce available vacuum, and BEVs have none. — [Apex TechNation: Vacuum vs electric brake boosters](https://apextechnation.com/articles/vacuum-vs-electric-brake-booster) (secondary trade article)
- Bosch iBooster: vacuum-independent electromechanical booster in which a motor and gear drive assist the master-cylinder piston. Data:
  - supporting force up to 6.2 kN
  - motor mechanical power up to 450 W
  - mass about 4.5 kg
  - supply voltage > 9.8 V
  - builds pressure "three times more quickly" than ESP
  - near-full recuperation up to 0.3 g with ESP hev
  - software-adjustable pedal feel
  - redundancy for automated driving
  - removes the vacuum pump and lines

  — [Bosch Mobility: iBooster](https://www.bosch-mobility.com/en/solutions/driving-safety/ibooster/)
- ZF/TRW Electronic Brake Booster (EBB) is marketed for EVs and in the aftermarket. — [ZF press release](https://press.zf.com/press/en/releases/release_54849.html)
- Mechanical/electric pump modeling: the paper "Modelling and Simulation of Brake Booster Vacuum Pumps" applies mass and energy conservation to each control volume to get instantaneous pressure. — [SAE 2013-01-9016 (abstract)](https://www.sae.org/publications/technical-papers/content/2013-01-9016/)
- Engine controllers restart an auto-stopped engine to restore booster vacuum when it degrades. — [USPTO 9404437, Engine control apparatus performing automatic engine restart for ensuring brake booster assistance](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9404437)

### Inferences
Coupling to an engine-manifold model:
- `ṁ_booster→manifold = f_cv(p_f − p_man)`. This is zero if `p_man ≥ p_f` (boosted or WOT), and the flow enters the manifold as an extra air source (a small unmetered air leak for the idle-speed controller).
- An electric pump is modeled as a volumetric source `ṁ = ρ(p_f)·V̇_pump(p_f)`, with a curve fitted to the evacuation-time data above (e.g. 3.2 L to 500 mbar in 6 s).
- Stop/start logic compares p_f with a threshold (via the Hella-type sensor) and restarts the engine or runs the pump.

### Gaps
- No check-valve cracking pressure or flow curve was found.
- No mechanical (camshaft) vacuum-pump displacement data was found.

---

## 7. Published lumped booster models and their equations

### Takeaway
The canonical references are:
- Gerdes & Hedrick (PATH 1993/1997; ASME JDSMC 1999): a static control valve (force thresholds), dynamic chamber airflows with linear coefficients, and a reduced one-state hydraulics model. This gives three states in total and was validated against a car.
- Delphi US6033038A: an adiabatic two-chamber model with compressible orifices, used for run-out and pedal-force estimation.
- Structural pedal-feel models (springs + valves + reaction washer, often in AMESim).
- Modelica/Simscape: no dedicated vacuum-booster block was found. Build it from pneumatic chambers, orifices and a check valve.

### Cited Findings
- Gerdes & Hedrick 1999: "reduced-order models … The vacuum booster model combines a static control valve with dynamic air flows … a four-state model of the brake hydraulics … can be reduced to one or two states". It shows better agreement for the pedal-force → brake-pressure response than earlier literature. — [ASME JDSMC 121(3):496](https://asmedigitalcollection.asme.org/dynamicsystems/article-abstract/121/3/496/395112/Brake-System-Modeling-for-Simulation-and-Control)
- PATH 1997 three-state model validated on slow and step applies. It gives the parameter set (Table 2.1) and hydraulics equations 2.1–2.36. Hydraulic states are displaced volumes, with Bernoulli flow `V̇ = σ·C_q·√|ΔP|` and a nonlinear capacity `P_w(V)`. — [PATH UCB-ITS-PRR-97-21](https://escholarship.org/uc/item/02b8f7q2)
- Earlier PATH paper: Gerdes, Maciuca, Devlin, Hedrick, "Brake System Modeling for IVHS Longitudinal Control", ASME WAM DSC-Vol. 53, 1993 (five states). — cited in [PATH report p. 5](https://escholarship.org/uc/item/02b8f7q2)
- Delphi model equations: see Section 3. — [US6033038A](https://patents.google.com/patent/US6033038A/en)
- AMESim full brake model (pedal, vacuum booster, master cylinder, pipes, calipers). It includes reaction-plate stiffness, rubber valve opening, and master-cylinder, caliper and pipe compliance, and is verified with static and dynamic road tests. — [SAE 2017-01-1371, Modeling, Simulation and Experimental Analysis of Brake Pedal Feel for Passenger Car](https://saemobilus.sae.org/papers/modeling-simulation-experimental-analysis-brake-pedal-feel-passenger-car-2017-01-1371); related [ResearchGate: Vacuum booster–brake master cylinder system dynamic model for brake pedal feel](https://researchgate.net/publication/290011141_Vacuum_booster_-_Brake_master_cylinder_system_dynamic_model_for_brake_pedal_feel) (abstracts only)
- Other SAE references: "Brake Vacuum Booster Characterization" (Walker, Rucoba, Barnes, Kent), SAE 2019-01-0412 (accident-reconstruction context; not read). SAE J1808 "Vacuum Power Assist Brake Booster Test Procedure" (1989, revised 2015) is the standard test procedure. — [SAE J1808](https://www.sae.org/standards/content/j1808_198910/)
- MathWorks: no vacuum-booster example was found. Community answers point to the Simscape gas library, and the Simscape Fluids "Tandem Primary Cylinder" example for hydraulics. — [MATLAB Answers: Modeling of a brake system in Simscape](https://www.mathworks.com/matlabcentral/answers/300873-modeling-of-a-brake-system-in-simscape)

### Inferences
- A minimal, validated-in-literature structure for coupling to an engine model has four states:
  - `p_r`, `p_f` (booster chambers)
  - `V` (displaced brake fluid)
  - optionally `p_man` from the engine model
- Its algebraic parts are the static valve logic (apply/hold/release thresholds, 50 N in PATH), the piston force balance and the reaction-disc split. Parameters can start from PATH Table 2.1.
- In Modelica, build it from `Modelica.Fluid` / `Modelica.Thermal`-style volumes with variable volume, or with a custom `der(p)` equation. Use orifice components (e.g. from Modelica.Fluid.Valves, or a custom ISO 6358 orifice) and a check valve, and add a 1-D translational mechanics piston, spring and reaction-disc gain.

### Gaps
- No open Modelica library component or Simscape example specific to a vacuum booster was located.
- Full text of the SAE and Chinese-journal pedal-feel models was not accessible, so their parameter values are unknown.
