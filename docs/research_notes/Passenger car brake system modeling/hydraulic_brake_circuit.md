# Hydraulic brake circuit of a passenger car (master cylinder to wheel brake torque): lumped-model data

Scope note for the report writer: web access to the key primary references (Limpert, Breuer & Bill, the Bosch handbook, Day's *Braking of Road Vehicles*, SAE papers, and the ScienceDirect / Brake & Front End / Anton Paar pages) was mostly blocked (HTTP 403 or paywalled). This session verified only a small set of numbers. Anything marked **[background, unverified]** comes from standard textbook knowledge (mainly Limpert and Breuer & Bill). Treat those items as plausible defaults to check against the book before quoting them as fact. The equations under Inferences are first-principles derivations that I built from the cited values.

One source I pulled, Lundin's KTH thesis "Modeling of a Hydraulic Braking System", covers an **industrial mine-hoist disc-spring brake**, not a car. It is cited below only for general hydraulic equations (Hagen-Poiseuille, effective bulk modulus with entrained air, the capacitance pole). Its numbers (such as 145 bar and mineral oil at 876 kg/m³) do not apply to cars.

## Tandem master cylinder: construction, bores, dead travel, force sharing, equations

### Takeaway
A tandem master cylinder (TMC) has two pistons in series in one bore. The pushrod drives the primary piston. The primary chamber's pressure, together with the intermediate spring, drives the floating secondary piston. So at steady state both circuits carry almost the same pressure, p ≈ F_pushrod / A_bore. Before any pressure builds, each piston first has to travel a "dead" or port-closing stroke, about 1–2 mm per piston, to cover its compensating port (or close its central valve).

### Cited Findings
- A TMC can use central valves. At the start of pressure build-up the central valve closes and shuts the secondary outlet-pressure space off from the follow-up (reservoir) space. This is the alternative to compensating-port (snifter hole) designs — [US20080282697A1, Tandem master cylinder with central valves](https://patents.google.com/patent/US20080282697A1/en); [US4885910A](https://patents.google.com/patent/US4885910A/en)
- If one circuit fails, the pedal and system must have enough stroke to take up that circuit's dead travel and still pressurize the remaining circuit. The failed-side piston bottoms mechanically before the good circuit builds pressure — [Ford Muscle Forums discussion (low-quality source)](https://www.fordmuscleforums.com/threads/assigned-ports-on-tandem-master-cylinder-what-works-best-and-why.609034/); design intent consistent with [US4621498A](https://patents.google.com/patent/US4621498A/en)
- Aftermarket TMC datasheets list bore options and outlet porting — [Wilwood compact tandem MC datasheet ds1287](https://www.wilwood.com/PDF/DataSheets/ds1287.pdf); [Wilwood aluminum tandem MC ds487](https://www.wilwood.com/PDF/DataSheets/ds487.pdf) (bores not extracted this session)
- MathWorks ships a "Vacuum Boosted Tandem Primary Cylinder" example (Simscape Fluids). Its input is pushrod force and its output is the pressure in both brake lines, and it plots applied force against generated pressure. The parameter values sit inside the model file, not on the web page — [MathWorks: Vacuum Boosted Tandem Primary Cylinder](https://www.mathworks.com/help/hydro/ug/vacuum-boosted-tandem-primary-cylinder.html); [MathWorks automotive examples index](https://www.mathworks.com/help/hydro/automotive-examples.html)

### Inferences
- **Bore sizes [background, unverified]:** passenger-car TMC bores follow inch sizes: 19.05 (3/4"), 20.64 (13/16"), 22.22 (7/8"), 23.81 (15/16") and 25.4 mm (1"). Area A_mc = π d²/4. For example, 22.22 mm gives 3.88 cm², so 100 bar needs 3.88 kN on the pushrod.
- **Dead travel [background, unverified]:** about 1.5–3.5 mm total pushrod travel before pressure rises: primary port-closing stroke, plus secondary port-closing stroke (taken up while the intermediate spring compresses), plus booster and pushrod free play.
- **Force balance and lumped equations (derived):**
  - Primary piston: m₁ẍ₁ = F_rod − p₁A − F_s1(x₁ − x₂) − F_fric,1
  - Secondary piston: m₂ẍ₂ = p₁A + F_s1(x₁ − x₂) − p₂A − F_s2(x₂) − F_fric,2
  - Piston masses are small (tens of grams), so the dynamics can be treated as quasi-static. At steady state p₂ ≈ p₁ − (F_s2 − F_s1 + ΔF_fric)/A. The spring preloads are tens of N, which amounts to about 0.1–0.5 bar and is negligible above a few bar.
  - Volume delivered by each chamber: Q_i = A·max(0, ẋ_i) once x_i > s_close,i. Below s_close,i the chamber vents to the reservoir, so p_i = p_atm.
  - Chamber pressure: dp_i/dt = (Q_i − Σ Q_lines,i) / C_i(p_i), with C = dV/dp taken from the P–V curves below.
  - Pedal travel: s_pedal = i_pedal·(x₁ + free play). Because the two chambers are in series, x₁ = x₂ + (primary-circuit volume)/A and x₂ = (secondary-circuit volume)/A. Pedal travel therefore adds the fluid demand of both circuits.
- **Single-circuit failure (derived):** if the primary circuit is lost, x₁ runs until the primary piston touches the secondary, and the pushrod force then acts on the secondary directly. If the secondary circuit is lost, the secondary piston bottoms out and the primary circuit works normally. Either way, pedal travel rises by roughly one circuit's volume divided by A.

### Gaps
- No verified OEM datasheet for bore, stroke, port-closing stroke or spring preloads. Continental ATE and TRW catalogs were not reached. The Simscape example's parameter values would need the model opened in MATLAB (`openExample`).

## Dual-circuit split: front/rear (II) versus diagonal (X), and failure behavior

### Takeaway
The II (front/rear) split loses either the front axle, the dominant one, or the rear axle, so failed-circuit performance is very asymmetric. The X (diagonal) split always keeps one front wheel and its opposite rear wheel, about half the braking capability. The cost is a yaw moment and pull toward the working front brake. Front-drive cars with a front-biased distribution mostly use X; II is common on rear-drive and larger cars.

### Cited Findings
- In a diagonal split, losing one circuit leaves one front brake and the diagonally opposite rear brake, which keeps about half the braking capability — [EduMech: Divided (split) hydraulic braking systems](https://www.edumech.co.uk/learn/braking/split-divided-braking)
- In a front/rear split, one axle must do all the braking after a failure. Losing the front circuit leaves only the rear brakes. Front brake gain is usually much larger than rear gain, so performance varies strongly between the two failure cases — [US10988170, Driver steer recommendation upon loss of one brake circuit of a diagonal split layout](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10988170)
- A failed diagonal circuit makes the vehicle pivot about the working front brake, producing a pull. Suspension parameters can amplify it, and "all vehicles equipped with diagonally split hydraulic circuits will try to change lanes under failed-circuit braking conditions" — [US10988170](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10988170)

### Inferences
- **[background, unverified]** X-split cars limit the pull with a negative (or zero) scrub radius front suspension. ECE R13-H requires minimum residual deceleration with one circuit failed.
- For modeling: the TMC primary feeds circuit 1 and the secondary feeds circuit 2. For II, circuit 1 goes to the front and circuit 2 to the rear (the assignment varies by OEM). For X, circuit 1 goes to FL+RR and circuit 2 to FR+RL. With an X split, a rear pressure limiter (proportioning valve or EBD) is needed separately in each circuit.

### Gaps
- No verified residual-deceleration numbers for II versus X failure, and no verified regulatory minimums (ECE R13-H / FMVSS 135 secondary-system requirements) were retrieved.

## Brake fluid, lines and hoses: properties, and whether line resistance and inertia matter

### Takeaway
The DOT specs bound viscosity: DOT 4 is ≤ 1800 mm²/s at −40 °C and ≥ 1.5 mm²/s at 100 °C. Density is about 1.05 kg/L. The fluid's own bulk modulus is on the order of 1.5–2 GPa (compressibility about 7×10⁻⁴ MPa⁻¹ at room temperature, rising several-fold when hot), so fluid compression is small next to caliper and hose compliance. Line resistance is negligible at room temperature. It becomes dominant for fast pressure changes (ABS/ESC) in cold fluid, which is exactly why DOT 4 LV (≤ 750 mm²/s) exists.

### Cited Findings
- DOT 3: dry/wet boiling point 205/140 °C, ν ≤ 1500 mm²/s at −40 °C, ≥ 1.5 mm²/s at 100 °C, glycol ether. DOT 4: 230/155 °C, ≤ 1800 mm²/s at −40 °C, glycol ether/borate ester. DOT 5.1: 260/180 °C, ≤ 900 mm²/s. DOT 5 (silicone): 260/180 °C, ≤ 900 mm²/s. DOT 4+ / "Super DOT 4" / LV: ≤ 750 mm²/s at −40 °C — [Wikipedia: Brake fluid](https://en.wikipedia.org/wiki/Brake_fluid)
- DOT 4 LV specifies 750 mm²/s instead of 1800 mm²/s at −40 °C — [Brake & Front End: What is DOT 4 LV](https://www.brakeandfrontend.com/what-is-a-dot-4-lv-brake-fluid-video/)
- DOT 4 density is 1.045 kg/L at 20 °C (one manufacturer's product) — [Liqui Moly Brake Fluid DOT 4](https://www.liqui-moly.com/en/us/brake-fluid-dot-4-p000420.html); one manufacturer quotes 1500 cSt at −40 °C for its DOT 4 — [Chevron Brake Fluid DOT 4 PDS](https://cglapps.chevron.com/msdspds/PDSDetailPage.aspx?docDataId=282834&docFormat=PDF) (per search snippet)
- Brake fluid compressibility runs from about 0.0007 MPa⁻¹ at room temperature (bulk modulus about 1.4 GPa) to about 0.003 MPa⁻¹ at 200 °C (about 0.33 GPa). Design practice specifies fluid consumption as working fluid volume × compressibility coefficient — [ScienceDirect Topics: Brake fluid (excerpt from Day, *Braking of Road Vehicles*, per search snippet; page itself 403)](https://www.sciencedirect.com/topics/engineering/brake-fluid)
- SAE J1401 brake hose, 1/8 in size: maximum volumetric expansion 0.33 cc/ft at 1000 psi (69 bar) and 0.42 cc/ft at 1500 psi (103 bar). Good hoses reach about 0.15 cc/ft at 1000 psi and 0.20 cc/ft at 1500 psi — [US7748412, Hose having a single reinforcing layer](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7748412) (per search summary); standard: [SAE J1401](https://www.sae.org/standards/j1401-road-vehicle-hydraulic-brake-hose-assemblies-use-nonpetroleum-base-hydraulic-fluids)
- Hagen-Poiseuille laminar pipe resistance: ΔP = 128 μ L Q / (π D⁴). Transmission-line dynamics act as a low-pass at low frequency, with resonances and anti-resonances at higher frequency — [Lundin, KTH thesis, eq. 2.2](https://www.diva-portal.org/smash/get/diva2:818797/FULLTEXT01.pdf)
- Effective bulk modulus with entrained air (Cho et al. form, R = V_g0/V_l0 at P₀, β_l ≫ P): β_e = β_l·[R + (1+P/P₀)^(1/γ)] / [R·β_l/(γ(P+P₀)) + (1+P/P₀)^(1/γ)] (re-derived from a garbled PDF-to-text extraction; the limits check out: R = 0 gives β_l, and large R gives γ(P+P₀)). Its simple series form is 1/β_e = 1/β_l + (V_g/V_t)/β_g + 1/β_container, where β_g = γP for adiabatic air. Air at atmospheric pressure has β_g ≈ 1.4×10⁵ Pa, so a small amount of entrained air dominates at low pressure — [Lundin, eqs. 3.39, 3.47–3.49](https://www.diva-portal.org/smash/get/diva2:818797/FULLTEXT01.pdf)
- For a volume filled through a flow input, the pressure pole sits at s = −β_e·K/V: bandwidth scales with the effective bulk modulus, which is why entrained air has to be kept to a minimum — [Lundin, eq. 3.113](https://www.diva-portal.org/smash/get/diva2:818797/FULLTEXT01.pdf)

### Inferences
- **Line geometry [background, unverified]:** rigid steel or Cunifer lines are 4.75 mm (3/16") OD with about 3.0–3.2 mm ID, or 6 mm OD. Front/rear run lengths are about 1–2 m to the front and 3–5 m to the rear. Flexible hoses at each wheel are about 0.3–0.5 m of 1/8" (3.2 mm ID) hose.
- **Hose compliance (derived from J1401):** 0.33 cc/ft is about 1.08 cm³/m at 69 bar. A 0.4 m hose therefore takes at most about 0.43 cm³ at 69 bar, and good hoses about 0.2 cm³, i.e. about 0.3–0.6 mm³/bar per hose. That is a second-order but not negligible share of a 1–3 cm³ caliper demand.
- **Fluid compression (derived):** a total system volume of about 50–100 cm³ (mostly the master cylinder and lines) with β ≈ 1.4–2 GPa gives about 0.25–0.7 cm³ at 100 bar, which is small next to the caliper demand.
- **Line resistance (derived, 3 m of 3 mm ID line):**
  - At −40 °C with DOT 4 (ν = 1800 mm²/s, μ ≈ 1.88 Pa·s): R = 128·1.88·3/(π·(3 mm)⁴) ≈ 2.8×10¹² Pa·s/m³. Pushing 2 cm³ in 0.2 s (Q = 10 cm³/s) would need about 280 bar, so the flow is strongly resistance-limited: time constant τ = R·C ≈ 2.8×10¹²·(2 cm³/100 bar = 2×10⁻¹³ m³/Pa) ≈ 0.6 s.
  - With DOT 4 LV (750 mm²/s) R drops by 2.4×.
  - At 20 °C (ν assumed about 10 mm²/s; not verified) R ≈ 1.6×10¹⁰ Pa·s/m³, so τ ≈ 3 ms. That is negligible next to pedal-apply times of about 0.1–0.3 s but relevant for ABS valve cycling.
  - Model the resistance as a nonlinear orifice/pipe element and make viscosity a function of temperature.
- **Fluid inertia (derived):** I = ρL/A = 1045·3/(7.07×10⁻⁶ m²) ≈ 4.4×10⁸ kg/m⁴. Combined with C ≈ 2×10⁻¹³ m³/Pa, the line resonance is f = 1/(2π√(IC)) ≈ 17 Hz. That is relevant for ABS pressure-oscillation and pedal-feedback studies. It can be dropped (first-order RC) for vehicle-deceleration studies.
- **Transport delay (derived):** acoustic wave speed a = √(β/ρ) ≈ √(1.5×10⁹/1045) ≈ 1200 m/s in rigid pipe (lower in hoses), so a 3–5 m line gives about 3–4 ms. That is usually negligible and can be modeled as a pure delay if needed.
- **Pressure rise times [background, unverified]:** driver panic apply with a vacuum booster reaches about 100 bar in about 150–300 ms. Hydraulic brake assist and ESC pumps are pump-limited at a few hundred bar/s. Treat these as plausible, not verified.

### Gaps
- No verified viscosity-versus-temperature table for DOT 4 between −40 and 100 °C (the Anton Paar wiki returned 403). A Walther/ASTM D341 fit through the two spec points (1800 mm²/s at −40 °C, 1.5 mm²/s at 100 °C) is a reasonable model assumption but was not verified.
- No verified bulk modulus figure for glycol fluid specifically at 20 °C apart from the Day-derived compressibility above.

## Pressure–volume (P–V) characteristic of calipers and the whole system

### Takeaway
Wheel-brake fluid demand is strongly nonlinear. There is an initial nearly flat take-up of piston/pad clearance (fractions of a cm³ at under about 2–5 bar), then a progressive (stiffening) curve: at low pressure the wheel brake is soft, and it stiffens as pressure rises. Suppliers and ABS/brake-by-wire controllers store it as a lookup of about 6+ points, or as a fitted polynomial or exponential. Seal deformation alone contributes very little, under 2 mm³ over 0–50 bar for a 57 mm piston, so pad compressibility, caliper deflection and hoses dominate.

### Cited Findings
- As volume V (cm³) rises, wheel-brake pressure p (bar) rises continuously and slightly progressively, because the wheel brake stiffens (elasticity falls) as volume grows — [ScienceDirect Topics: Brake fluid (snippet, patent-derived text)](https://www.sciencedirect.com/topics/engineering/brake-fluid); consistent with patents [US9656653](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9656653), [US9020691](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9020691)
- For a 57 mm diameter disc brake caliper piston, FEA predicts that fluid consumption from seal deflection and deformation rises linearly by **less than 2 mm³ over 0–50 bar** — [ScienceDirect Topics: Brake fluid (Day, *Braking of Road Vehicles*, per snippet)](https://www.sciencedirect.com/topics/engineering/brake-fluid)
- Example slave-cylinder compliance: 8 mm³ of consumption at 5 MPa, giving c ≈ 2 mm³/MPa (clutch/slave context) — [ScienceDirect Topics: Brake fluid (snippet)](https://www.sciencedirect.com/topics/engineering/brake-fluid)
- Production brake systems store a reference P–V curve with a nominal dead-stroke travel and at least six characteristic pressure–volume points, and compare it with the curve measured on each braking for fault detection — [US9656653, Hydraulic brake system … fault condition detection](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9656653)
- Individual wheel-brake P–V curves V_i(p) can be identified from a pressure-supply piston's travel by activating different groups of wheel brakes and solving a (least-squares) linear system. The curves are then represented by interpolation or least-squares fit — [US10173653B2, Method for determining a P/V characteristic curve of a wheel brake](https://patents.google.com/patent/US10173653B2/en); [US9988025](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9988025)
- The P–V curve depends on brake-fluid temperature: as temperature rises the "lost" volume grows — [US11338782, Brake system and method for controlling the same (snippet)](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11338782)
- A published AMESim model of the full hydraulic servo brake (pedal, vacuum booster with rubber reaction disc, TMC, pipes, wheel cylinders, calipers) includes pipe deformation and friction-lining deformation because they drive pedal feel — [Brake System Simulation to Predict Brake Pedal Feel in a Passenger Car (ResearchGate)](https://www.researchgate.net/publication/37794850_Brake_System_Simulation_to_Predict_Brake_Pedal_Feel_in_a_Passenger_Car)

### Inferences
- **Typical magnitudes [background, unverified, check against Breuer & Bill]:**
  - Front floating caliper (about 54–60 mm piston): about 0.2–0.4 cm³ clearance take-up, then about 1.0–2.0 cm³ total at 100 bar.
  - Rear disc (about 34–38 mm piston): about 0.4–0.8 cm³ at 100 bar.
  - Rear drum wheel cylinder: larger low-pressure demand from shoe travel.
  - Whole car at 100 bar: about 4–8 cm³ including hoses and fluid compression. With a 22.22 mm TMC this corresponds to about 10–20 mm of TMC stroke.
- **Recommended fitted forms for a lumped model:**
  1. Piecewise: V(p) = V_0·min(p/p_0, 1) + a·p^b for p ≥ 0, with b ≈ 0.5–0.8 (sub-linear volume means stiffening pressure). V_0 is the clearance volume and p_0 about 1–3 bar.
  2. Exponential stiffening: p(V) = k_1·(exp(k_2·(V − V_0)) − 1) for V > V_0.
  3. Polynomial: p(V) = c_1 V + c_2 V² + c_3 V³, or V(p) as a 2nd–3rd order polynomial in p, fitted to measured points.

  The model state should be volume V_i, with p_i = f(V_i). Hydraulic capacitance is then C(p) = dV/dp, large at low p and small at high p.
- **Caliper hysteresis and knockback:** add a small hysteresis (seal rollback, about 0.1–0.2 mm piston retraction) if release behavior matters.

### Gaps
- **No verified numeric P–V curve for a specific production passenger-car caliper was found.** The best source is Breuer & Bill (Brake Technology Handbook), which plots caliper fluid demand, or supplier (ATE/TRW) data. Neither was accessible this session.

## Disc caliper and drum brake: torque equations, μ, fade, brake factor

### Takeaway
Disc torque per wheel: T = C*·(p − p_0)·A_pist·r_eff, with brake factor C* = 2μ for a disc (both pads). Pad μ ≈ 0.35–0.45 for passenger cars. p_0 is the push-out/threshold pressure, about 0.3–1 bar. Drum brakes have much higher brake factors (leading-trailing C* about 2 at μ ≈ 0.38; duo-servo about 5–6) and correspondingly higher sensitivity to μ. That is why cars use discs at the front and, increasingly, at the rear.

### Cited Findings
- A leading-trailing drum brake has good stability and makes parking-brake integration easy, but gives a smaller braking effect. A duo-servo drum gives a much higher braking effect (so a smaller drum will do) but is **sensitive to variation in lining μ and in shoe/drum contact** — [US6186294 Drum brake](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6186294); [Akebono drum brakes overview](https://www.akebono-brake.com/english/product_technology/product/automotive/drum/)
- A simple disc-brake torque form: T_B = F_clamp·μ·D_B/2 per friction face, based on disc diameter and effective radius — [Lundin thesis §2](https://www.diva-portal.org/smash/get/diva2:818797/FULLTEXT01.pdf) (hoist brake, form transferable)
- A MathWorks Simscape Driveline example "Fixed Caliper Disk Brake" (`sdl_braking_caliper_disk_brake`) exists, and a Simscape Fluids example parameterizes a caliper disk brake from TMC datasheet data — [MathWorks Automotive examples](https://www.mathworks.com/help/hydro/automotive-examples.html); [MATLAB Answers: Modeling of a brake system in Simscape](https://www.mathworks.com/matlabcentral/answers/300873-modeling-of-a-brake-system-in-simscape)

### Inferences
- **Torque equation (derived):** T_disc = 2·μ·max(0, p − p_0)·n_pist·A_pist·r_eff. For a floating single-piston caliper n_pist = 1 (the reaction force clamps the outer pad). For an opposed fixed caliper, A counts the pistons on one side only.
- **Effective radius [background, unverified]:** r_eff ≈ (r_o + r_i)/2 (uniform-wear assumption: mean radius), about 0.10–0.14 m front and 0.10–0.12 m rear for a compact to midsize car.
- **Piston sizes [background, unverified]:**
  - Front floating calipers: 54 / 57 / 60 mm, i.e. 22.9 / 25.5 / 28.3 cm².
  - Rear floating calipers: 34 / 36 / 38 mm, i.e. 9.1 / 10.2 / 11.3 cm².
  - Rear drum wheel cylinders: 17.5–22.2 mm.
  - The 57 mm piston cited from Day above is consistent with this.
- **μ and fade [background, unverified]:** OE passenger-car pad μ is about 0.35–0.45 nominal. μ falls when fade sets in, at disc temperatures around 500–600 °C or more for organic/NAO pads. A simple model is μ(T) = μ₀·(1 − k·max(0, T − T_fade)) together with a lumped disc thermal node. A thermal model is outside this note's scope.
- **Drum brake factor [background, Limpert, unverified]:**
  - Leading shoe C*_L ≈ μ·a/(b − μ·c).
  - Trailing shoe C*_T ≈ μ·a/(b + μ·c).
  - Leading-trailing total C* ≈ 2 at μ = 0.38; two-leading ≈ 3; duo-servo ≈ 5–6 at μ = 0.38.
  - Sensitivity dC*/dμ·(μ/C*): about 1 for a disc, about 1.2–1.5 for leading-trailing, about 3–4 for duo-servo.
  - Drum torque: T = C*·p·A_wc·r_drum.

### Gaps
- Limpert/Breuer & Bill tables of C* versus μ and the exact shoe-geometry formulas were not accessible to verify.

## Brake-force distribution: ideal versus installed, load transfer, proportioning/load-sensing valves, EBD

### Takeaway
The ideal distribution keeps front and rear μ-utilization equal: as deceleration rises, load shifts forward, so the ideal rear share falls. A fixed installed ratio crosses the ideal curve at one "critical" deceleration. Above it the rear would lock first, which is unstable. A proportioning valve bends the rear pressure curve at a knee pressure (about 40–48 bar) and passes only a fraction (about 0.3–0.45) of further input above it. Load-sensing valves move the knee with rear axle load. Modern ABS units do this electronically (EBD) with the rear inlet/outlet valves.

### Cited Findings
- The "knee point" is the bend in the plot of rear line pressure against master-cylinder pressure. Below it (typically 600–700 psi, i.e. 41–48 bar) the valve passes full pressure. Above it the rear gets about 43% of the extra input. Example: 1000 psi input with a 675 psi knee gives 675 + 0.43·325 ≈ 815 psi at the rear — [Brakes-shop.com Brakepedia: Brake proportioning valves (via search summary; page 403)](https://www.brakes-shop.com/brakepedia/general/brake-proportioning-valves); see also [Wilwood: How does a proportioning valve work](https://shop.wilwood.com/blogs/news/how-does-a-proportioning-valve-work)
- Ideal braking requires the front/rear pressure distribution to change with longitudinal deceleration. A proportioning valve gives a bilinear front/rear pressure relation to approximate it. Weight transfer lowers rear traction, so equal pressure risks rear lock-up first and instability — [Wilwood](https://shop.wilwood.com/blogs/news/how-does-a-proportioning-valve-work); [US6213566 Brake proportioning in-line ball valve](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6213566); [US4053186](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/4053186)
- Proportioning valves can also be modulated by other signals (for example steering hydraulic pressure) — [US5147113](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5147113)
- Front/rear electronic distribution control exists in patents — [US6595600 Front-rear braking force distribution control system](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6595600)

### Inferences
- **Ideal distribution (derived, rigid-body load transfer):** with mass m, wheelbase l, static front/rear axle distances l_f and l_r (from the CG), CG height h and deceleration z = a/g:
  - F_z,f = m g (l_r + z h)/l
  - F_z,r = m g (l_f − z h)/l
  - Ideal (equal utilization): F_x,f/F_x,r = (l_r + z h)/(l_f − z h), so the ideal front share φ_f(z) = (l_r + z h)/l.
  - Example: l = 2.6 m, l_f = 1.04 m (60% static front), h = 0.55 m. Then φ_f = 0.60 at z = 0 and 0.81 at z = 1. The ideal share at 1 g is about 80/20; at 0.5 g it is about 70/30.
- **Installed distribution (derived):** φ_f,inst = K_f/(K_f + K_r), with K = Σ(torque per bar)/r_tire. The critical deceleration is z_crit = (φ_f,inst·l − l_r)/h. The installed bias is chosen so that z_crit is about 0.8–1.0 g laden.
- **Proportioning valve model (derived from the cited knee/slope):** p_r = p_in for p_in ≤ p_knee; p_r = p_knee + s·(p_in − p_knee) otherwise, with s ≈ 0.25–0.45. A load-sensing valve makes p_knee a function of rear suspension deflection, i.e. rear axle load. Valve dynamics can be ignored (quasi-static), but include some hysteresis if needed.
- **EBD [background, unverified]:** implemented in ABS software. When rear slip exceeds front slip by a threshold, it closes the rear inlet valve (holds pressure) and then modulates. It usually replaces the mechanical valve entirely, so the rear hydraulic ratio can be sized larger for better rear use at low deceleration. In a lumped model, implement it as a rule: hold p_r when λ_r − λ_f > Δλ_threshold.

### Gaps
- No primary (Limpert/Bosch) source verified for knee pressures and slopes in OE passenger cars; the 43% / 600–700 psi figures come from aftermarket/secondary sources.

## Overall numbers for a ~1400 kg car

### Takeaway
A 1 g stop in a ~1400 kg car needs about 13.7 kN of total brake force and roughly 55–80 bar of line pressure with typical OE caliper sizes. Pedal force is then about 150–250 N with a vacuum booster. Systems are designed for 120–180 bar maximum (lock or booster run-out and above).

### Cited Findings
- Line pressure = force / master-cylinder area (basic brake math) — [Brake & Front End: Brake math, calculating the force needed to stop a car](https://www.brakeandfrontend.com/brake-math-calculating-the-force-needed-to-stop-a-car/) (page 403; statement per search snippet)
- The vehicle deceleration and brake force can be converted into an "equivalent master-cylinder pressure" through the brake specifications, which is standard practice in ESC/brake-control patents — [US7681962 Method for estimating master cylinder pressure during brake apply](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7681962)

### Inferences (worked example, all derived, inputs [background, unverified])
- **Inputs:** m = 1400 kg; r_tire = 0.30 m; μ_pad = 0.40.
  - Front: 57 mm floating caliper (25.5 cm²), r_eff = 0.12 m.
  - Rear: 38 mm floating caliper (11.3 cm²), r_eff = 0.11 m.
- **Torque per bar:**
  - Front: 2·0.40·25.5×10⁻⁴·10⁵·0.12 ≈ **24.5 N·m/bar per wheel**, 49 N·m/bar per axle.
  - Rear: 2·0.40·11.3×10⁻⁴·10⁵·0.11 ≈ **9.9 N·m/bar per wheel**, 19.9 N·m/bar per axle.
  - Installed split at equal pressure: 49/(49 + 19.9) ≈ **71/29** front/rear.
- **1 g stop:** F_x = 1400·9.81 = 13.7 kN, so wheel torque total = 13.7 kN·0.30 m = 4.12 kN·m. With a 71/29 split, front 2.93 kN·m and rear 1.19 kN·m, both needing **p ≈ 60 bar**. With μ_pad = 0.35 or a smaller piston this becomes about 70–80 bar.
- **Pedal force for 60 bar:** with a 22.22 mm TMC (3.88 cm²) the pushrod needs 2.33 kN. With a booster gain of about 5–7 **[background]** the booster input is about 330–470 N. With a pedal ratio of about 3–4 **[background]** the driver's foot force is about **100–160 N**. Reserve: vacuum-booster run-out typically reached at about 80–100 bar **[background]**; above that, extra pressure takes about 1:1 pushrod force.
- **Fluid displaced for 60 bar:** about 2×(0.8–1.2) + 2×(0.3–0.5) + hoses about 0.5 + compression about 0.3 cm³, i.e. about 3–4.5 cm³, which is about 8–12 mm of TMC stroke plus dead travel. That corresponds to about 30–50 mm of pedal travel at a pedal ratio of about 3.5, consistent with normal pedal feel **[inference]**.
- **Max line pressure:** 100–180 bar (the task brief's range, consistent with the torque-per-bar arithmetic, since 1 g needs only about 60–80 bar and the design margin covers fade, a laden vehicle and a failed circuit) **[not independently verified]**.

### Gaps
- No single verified OEM data sheet (for example a VW Golf / Škoda Octavia brake spec) was retrieved to anchor these numbers. Recommend checking against Breuer & Bill, chapter on brake system design, or a Bosch Automotive Handbook table.

## Published lumped models and their equations

### Takeaway
Standard lumped structure: pedal lever → booster (static gain with run-out) → TMC (two pistons, port-closing stroke, springs) → per-circuit volume nodes with nonlinear capacitance → pipe/hose elements (laminar R, optional inertance) → wheel-brake nodes with P–V curve → torque = C*·(p − p_0)·A·r_eff. The ready-made tools are MathWorks Simscape Fluids/Driveline (TMC, vacuum booster, caliper disk brake and ABS examples), AMESim (pedal-feel model) and the Modelica Fluid/Hydraulic libraries. Lundin gives the equations for effective bulk modulus, Hagen-Poiseuille lines, transmission lines and the capacitance pole.

### Cited Findings
- MathWorks Simscape Fluids automotive examples: *ABS Open Loop Test Bench* (manual braking, caliper disc brake pressures), *Anti-Lock Braking System*, *Vacuum Booster* (applied against generated force), *Vacuum Boosted Tandem Primary Cylinder* (pushrod force → brake-line pressures) — [MathWorks Automotive examples](https://www.mathworks.com/help/hydro/automotive-examples.html)
- Simscape Driveline "Fixed Caliper Disk Brake" example `sdl_braking_caliper_disk_brake` and the Brakes and Detents library — [MathWorks Brakes and Detents](https://www.mathworks.com/help/sdl/brakes-and-detents.html); [MATLAB Answers thread](https://www.mathworks.com/matlabcentral/answers/300873-modeling-of-a-brake-system-in-simscape)
- AMESim full servo brake model (pedal, vacuum booster with rubber reaction disc, TMC, pipe deformation, wheel cylinders, calipers, lining deformation) for pedal-feel prediction — [ResearchGate: Brake System Simulation to Predict Brake Pedal Feel in a Passenger Car](https://www.researchgate.net/publication/37794850_Brake_System_Simulation_to_Predict_Brake_Pedal_Feel_in_a_Passenger_Car)
- Modeling and simulation of an automotive hydraulic brake system (Vietnamese university journal) — [JST-UD article](https://jst-ud.vn/jst-ud/article/download/10773/6949) (content not extracted)
- Hydraulic modeling equations: Hagen-Poiseuille (eq. 2.2), modal transmission-line approximation (Yang & Tobler), effective bulk modulus with air (eqs. 3.47–3.49, after Cho et al.), and the pressure pole s = −β_e K/V — [Lundin, KTH](https://www.diva-portal.org/smash/get/diva2:818797/FULLTEXT01.pdf)

### Inferences
- **Minimal lumped equation set (derived), per circuit k ∈ {1, 2} and wheel j:**
  1. F_rod = i_booster(F_pedal·i_pedal) (with run-out saturation). The TMC pistons follow the force balance in the master-cylinder section.
  2. Chamber: C_mc·dp_k/dt = A·ẋ_k·H(x_k − s_close,k) − Σ_j Q_kj
  3. Line/hose: Q_kj = (p_k − p_wj)/R_kj(T) (add I_kj·dQ_kj/dt for ABS/pedal-feel fidelity; optional pure delay L/a)
  4. Proportioning (rear only): p_k→rear limited by the knee/slope map, or by the EBD hold logic.
  5. Wheel brake: dV_wj/dt = Q_kj, p_wj = f_PV,j(V_wj) (piecewise, exponential or polynomial fit)
  6. Torque: T_j = C*_j·max(0, p_wj − p_0,j)·A_j·r_eff,j (disc C* = 2μ; drum C* from the shoe formulas), with sign set by wheel speed (friction model with regularization near ω = 0).
- **Stiffness and time scales:** the smallest time constant is the line RC at room temperature (about ms) and the line resonance (about 10–20 Hz). Use an implicit solver, or drop the inertance for vehicle-dynamics studies.

### Gaps
- Modelica: no specific Modelica brake-hydraulics library was verified this session. Candidates are Modelica.Fluid, the commercial HyLib/Hydraulics libraries, and Claytex/VeSyMA brakes, all unconfirmed.
- The specific SAE papers on caliper P–V modeling were not retrieved.
