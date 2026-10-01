# Engine control systems: teaching materials for quantitative (Dyad) models

Scope: Lecture 2, second half (`materials/ControlTheory/2. Engine CS.pptx`, slides 16–59). That covers
vehicle energy demand, ICE cycles, the ECU, sensors, injection, ignition, lambda control and the TWC.
This note lists sources that let us go deeper and that give equations, parameter values or datasets we
can build models from.

How to read the source labels:
- **verified**: I opened the primary page or PDF and read the claim there.
- **search summary**: the claim comes from a search-engine summary of that URL. The page itself was
  blocked (403/503) or not opened.
- **not verified**: I could not reach a primary source. Treat as a lead only.

Related note already in the repo: the MVEM intake manifold (throttle orifice, filling/emptying,
speed-density) is covered in
`research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md`. This note does not
repeat those equations.

---

## 0. Top 8 picks for building Dyad models

| # | Source | Why it is top | Feeds |
|---|---|---|---|
| 1 | **Crossley & Cook (1991) engine model, as published in MathWorks "Using Simulink and Stateflow in Automotive Applications"**: every polynomial coefficient is printed | A complete, closed set of equations with numbers: throttle f(θ)·g(Pm), manifold ODE, pumping polynomial, torque polynomial in (m_a, A/F, spark, N), J·dN/dt. It ports straight to an acausal model. | Throttle → manifold → torque → crank speed model; speed/idle PI loop; spark and AFR effect on torque |
| 2 | **Guzzella & Onder, *Intro. to Modeling and Control of ICE Systems*, 2nd ed. 2010**, especially App. B (idle-speed case study with numerical parameter values) and §2.4.2, §2.8.3, §4.2, §4.3 | The single best map onto slides 16–59: wall-wetting, transport delays, TWC model, knock control, AFR feedforward and feedback. It is the textbook of ETH's engine course. | Wall-wetting (x–τ), lambda loop with delay, TWC O₂ storage, knock controller, idle-speed control |
| 3 | **Brandt, Wang & Grizzle TWC oxygen-storage model** (limited integrator, free PDF) | A one-state ODE for catalyst oxygen fraction θ, with stoichiometric 14.6. It is the simplest physics model of slide-topic "TWC oxygen storage". | TWC block downstream of the lambda loop; post-cat trim demo |
| 4 | **Bosch Motorsport datasheets: LSU 4.9 (Ip vs λ table) and NTC M12 (R vs T table)** | Real, OEM-published sensor characteristics to use as lookup tables | Wideband sensor model; coolant/intake NTC + pull-up divider → ECU ADC |
| 5 | **MathWorks fault-tolerant fuel control (`sldemo_fuelsys`)** | Two-step EGO (tanh) sensor, PI correction with ±0.5 error, 14.6 target, sensor-fault modes, rich fallback (A/F ≈ 11.7) | Lambda jump/ramp loop with switching sensor; ECU mode logic (warm-up, fault) |
| 6 | **EPA ALPHA complete engine maps** (free spreadsheets + MATLAB files of real, benchmarked engines) | Measured BSFC/fuel-flow maps over the full speed–torque range | Mapped engine for energy demand over a drive cycle; BSFC / efficiency ≈ 37% discussion |
| 7 | **Drive cycles: DieselNet WLTC class 1–3 text files, EPA UDDS/HWFET/US06/NEDC elements** | Second-by-second speed traces, free | Vehicle energy demand notebook (aero, rolling, grade, acceleration) |
| 8 | **LiU TCSI simulation testbed (GPL-3, MATLAB/Simulink)**, plus Eriksson & Nielsen (Wiley 2014) | An open, validated mean-value model of a 1.8 L turbo SI engine with throttle, manifold, wastegate, PI boost control and drive cycles | Reference values for a larger SI air-path model; validation target for our Dyad MVEM |

Runner-up for control exercises: the **Di Cairano et al. (CDC 2008) idle-speed plant**, a two-input
(air, spark) model with dead times T_air ≈ 0.12 s and T_spk ≈ 0.03 s at 650 rpm and Ts = 30 ms. It is a
good delay-control (Smith predictor / PI) exercise. See §5.

---

## 1. Textbooks: chapter-to-slide map

| Book | Edition / publisher | Chapters that map to the slides | What can be modeled | Access |
|---|---|---|---|---|
| **Guzzella & Onder**, *Introduction to Modeling and Control of Internal Combustion Engine Systems* | 2nd ed., Springer 2010, ISBN 978-3-642-10774-0, DOI 10.1007/978-3-642-10775-7 (verified, publisher reading sample: [e-bookshelf PDF](https://content.e-bookshelf.de/media/reading/L-14493-6ab8f78ca4.pdf)) | §1.2 ECU hardware/software; §1.3.2 main SI control loops → ECU slides. §2.3 air system (receivers, valve mass flows, engine mass flows) → throttle/MAF/MAP. **§2.4.2 wall-wetting dynamics, §2.4.3 gas mixing and transport delays** → injection, lambda delay. §2.5.1 torque generation → spark advance/MBT. §2.7.2–2.7.4 stoichiometric combustion, pollutant formation → AFR 14.7, NOx/HC. **§2.8.2–2.8.3 TWC principles and modeling** → TWC/O₂ storage. Ch. 3 discrete-event models (injection/ignition DEM) → crank-synchronous ECU. **§4.2 knock (autoignition, criteria, detection, controller)**. **§4.3 AFR control (feedforward, conventional feedback, H∞, IMC)**. **App. B idle-speed case study incl. B.2.3 "Numerical Values of the Model Parameters"**. App. C.2 thermodynamic cycles / heat-release approximations → Otto cycle. (TOC verified from the reading sample above.) | Nearly everything on slides 30–59, with control-oriented ODEs | Paywalled (Springer) |
| **Eriksson & Nielsen**, *Modeling and Control of Engines and Drivelines* | Wiley, April 2014, 588 pp., ISBN 978-1-118-47999-5 ([Wiley-VCH](https://www.wiley-vch.de/en/areas-interest/engineering/modeling-and-control-of-engines-and-drivelines-978-1-118-47999-5), verified TOC; [LiU page](https://www.vehicular.isy.liu.se/Publications/Books/14_LELN.html)) | Ch. 2 Vehicle (driving resistance) → energy-demand slides. Ch. 5 thermodynamics and working cycles → Otto/Diesel. Ch. 6 combustion and emissions. **Ch. 7 mean value engine modeling**. **Ch. 9 engine management systems intro; Ch. 10 basic control of SI engines** → ECU, injection, ignition, lambda. Ch. 16 diagnosis. | MVEM components; SI control loops | Paywalled; it is the textbook of LiU course TSFS09 ([LiU study info](https://studieinfo.liu.se/en/kurs/TSFS09)) |
| **Heywood**, *Internal Combustion Engine Fundamentals* | 2nd ed., McGraw-Hill 2018, ISBN 978-1-260-11610-6 ([McGraw-Hill](https://www.mheducation.com/highered/mhp/product/internal-combustion-engine-fundamentals-2e.html), verified TOC) | Ch. 2 design and operating parameters (bmep, bsfc, η_v). Ch. 3 thermochemistry (stoichiometric AFR, λ). Ch. 5 ideal cycles → Otto/Diesel efficiency. **Ch. 7 mixture preparation in SI engines** → injection, wall film. **Ch. 9 combustion in SI engines** → spark advance, MBT, knock, burn-rate (Wiebe-type) curves. Ch. 11 pollutant formation and control → NOx/HC vs timing, catalysts. Ch. 13 friction. Ch. 15 operating characteristics → maps. | Cycle and efficiency numbers; burn-rate functions; emissions trends | Paywalled |
| **Guzzella & Sciarretta**, *Vehicle Propulsion Systems* | 3rd ed., Springer 2013, ISBN 978-3-642-35912-5 ([Springer](https://www.springer.com/us/book/9783642359125), search summary) | Ch. 2 "Vehicle Energy and Fuel Consumption – Basic Concepts" → slides on aero drag, rolling resistance, grade, acceleration, cycle energy. Ch. 3 IC-engine propulsion (Willans-type engine models, search summary). Exercises at the end of each chapter, with solutions "on the web" (search summary; the solution location was not found). | Backward (quasi-static) energy demand over a cycle | Paywalled. The companion QSS Toolbox is free (§2). |
| **Kiencke & Nielsen**, *Automotive Control Systems: For Engine, Driveline, and Vehicle* | 2nd ed., Springer 2005, DOI 10.1007/b137654 ([Springer](https://link.springer.com/10.1007/b137654), search summary) | Chapters: Thermodynamic Engine Cycles; **Engine Management Systems; Engine Control Systems** (lambda, ignition, knock, idle). | Control-loop structures; older but complete | Paywalled |
| **Bosch / Reif (ed.)**, *Gasoline Engine Management: Systems and Components* | Springer Vieweg 2014 (Bosch Professional Automotive Information), ISBN 978-3-658-03963-9, 354 pp. ([Springer](https://www.springer.com/us/book/9783658039639), search summary) | Cylinder-charge control, fuel injection (MPI/GDI, injectors), ignition (coil, dwell, spark plugs), catalytic emission control, lambda sensors, diagnosis → the descriptive half of slides 30–59 | OEM component descriptions and typical values. Few control models. | Paywalled |
| **Bosch Automotive Handbook** | 11th ed., Wiley 2022, ISBN 978-1-119-91190-6, 2,048 pp. (search summary of retailer pages, e.g. [ebook.de](https://www.ebook.de/de/product/42321455/robert_bosch_gmbh_automotive_handbook.html)) | Driving resistance formulas and coefficients, engine management, sensors, lambda control, catalysts | Coefficient tables (c_d, f_r, etc.) | Paywalled |

---

## 2. Open courses, lecture notes, free software

| Item | URL | What it gives | License / access | Slide topic → notebook |
|---|---|---|---|---|
| **ETH Zurich IDSC "Engine Systems"** (Onder) | [idsc.ethz.ch/…/engine-systems.html](https://idsc.ethz.ch/education/lectures/engine-systems.html) | Course built on Guzzella & Onder 2nd ed. It has two MATLAB/Simulink exercises: intake-manifold parameter identification from real engine data, and a full engine model + model-based **idle-speed controller** run on a real test bench (competition) (search summary; the page returned 503) | Materials sit behind ETH Moodle; not public | Course template for our ISC notebook |
| **ETH IDSC QSS Toolbox** (quasi-static backward vehicle simulation) | Original: `http://www.idsc.ethz.ch/Downloads/DownloadFiles/qss` (cited by the fork, not opened); forks: [SourceForge qsstoolbox](https://sourceforge.net/p/qsstoolbox/), [MATLAB File Exchange 73483](https://www.mathworks.com/matlabcentral/fileexchange/73483-qss-toolbox) (search summary) | Drive-cycle-driven energy/fuel model for conventional/hybrid/EV powertrains | Free | Energy-demand notebook (cross-check our numbers) |
| **MIT OCW 2.61 Internal Combustion Engines** (W. Cheng, Spring 2017) | [ocw.mit.edu 2.61 lecture notes](https://ocw.mit.edu/courses/2-61-internal-combustion-engines-spring-2017/resources/lecture-notes/) (verified) | 19 lecture PDFs: ideal cycle analysis, thermochemistry, **mixture preparation in SI engines**, intake/exhaust, **SI combustion; knock**, **SI emissions and emissions control**, friction, turbocharging | **CC BY-NC-SA 4.0**, free. We may reuse figures with attribution in non-commercial teaching. | Otto cycle, AFR/λ, knock, TWC background slides |
| **LiU Vehicular Systems software** | [vehsys.gitlab-pages.liu.se/www/software](https://vehsys.gitlab-pages.liu.se/www/software/) (verified; the old `fs.isy.liu.se/Software` redirects here) | LiU Diesel / LiU Diesel 2 (heavy-duty diesel, EGR+VGT), LiU-D-El (diesel-electric), TruckBenchmarkModel, Modelica-MVEMLib, psPack (cycle thermodynamics), LiU CPgui (compressor maps), **TCSI Engine Simulation Testbed** | Free/open (per page) | Diesel models are less relevant. TCSI and psPack are the useful ones. |
| **LiU TCSI Simulation Testbed** | [github.com/nkymark/TCSISimTestbed](https://github.com/nkymark/TCSISimTestbed) (verified) | 1.8 L 4-cyl turbo SI MVEM: air filter, compressor, intercooler, **throttle, intake manifold**, engine, exhaust manifold, turbine, wastegate; 13 states; PI boost controller with anti-windup; WLTP/NEDC/EUDC/FTP-75 cycles; 11 fault scenarios. Paper: Ng, Frisk, Krysander, Eriksson, *IEEE Control Systems Magazine* 40(2):56–83, 2020. | **GPL-3.0** | Parameter source and validation target for a Dyad SI air-path model; diagnosis extension |
| **Modelica-MVEMLib** (LiU / OpenProd) | Mirror: [github.com/stjordanis/modelica-mvem](https://github.com/stjordanis/modelica-mvem) (verified). The original LiU URL now returns 404. | Modelica MVEM framework: GasPort, FixedVolume, IdealRestriction, FuelAirMixer, AdiabaticBurner (search summary) | **GPL-2.0** | Closest existing *acausal* analogue to what we build in Dyad. Good for connector design. |
| **Modelica VehicleInterfaces** | [github.com/modelica/VehicleInterfaces](https://github.com/modelica/VehicleInterfaces) (search summary) | Standard engine/driveline/chassis interface definitions (Modelica Association; Dassault, DLR, Modelon, Claytex) | Free, open source | Interface conventions for engine ↔ driveline in Dyad |
| **Eriksson 2007, "Modeling and Control of Turbocharged SI and DI Engines"**, *Oil & Gas Sci. Tech.* 62(4):523–538 | [OGST PDF](https://ogst.ifpenergiesnouvelles.fr/fr/articles/ogst/pdf/2007/04/ogst06101.pdf) (search summary; direct fetch 403) | Component-based MVEM (compressor/turbine models) plus **AFR control of SI engines** and observers | Open access (per search summary) | Compact free substitute for Eriksson & Nielsen Ch. 7–10 |
| **Moskwa, PhD thesis, MIT 1988, "Automotive engine modeling for real time control"** (advisor J.K. Hedrick) | [DSpace@MIT 1721.1/14617](https://dspace.mit.edu/handle/1721.1/14617) (search summary) | Full engine model derivation (throttle, manifold, fuel, rotational dynamics, delays) | Free PDF (~15 MB) | Background derivations for the MVEM notebook |
| **ADVISOR** (NREL Advanced Vehicle Simulator) | [adv-vehicle-sim.sourceforge.net](https://adv-vehicle-sim.sourceforge.net/) (search summary) | MATLAB/Simulink vehicle sim with component data files, incl. SI engine fuel-converter maps (`FC_SI*`) | Free, open source (last release 2003) | Extra engine maps for energy demand |

---

## 3. Benchmark models with published equations and parameters

### 3.1 Crossley & Cook (1991) four-cylinder SI engine: MathWorks `sldemo_engine` / `sldemo_enginewc`

- Original: P.R. Crossley and J.A. Cook, IEE Int. Conf. "Control 91", Conf. Publ. 332, vol. 2,
  pp. 921–925, Edinburgh, 1991 (paywalled, not opened). Reference and equations taken from the
  MathWorks booklet [Using Simulink and Stateflow in Automotive Applications (mirror PDF)](https://www.ee.hacettepe.edu.tr/~solen/Matlab/MatLab/Matlab%2C%20Simulink%20-%20Using%20Simulink%20and%20Stateflow%20in%20Automotive%20Applications.pdf), Ch. I "Engine Model" (verified). Current docs:
  [Engine Timing Model with Closed Loop Control](https://www.mathworks.com/help/simulink/slref/engine-timing-model-with-closed-loop-control.html) (verified: discrete PI on speed, crank-synchronous execution).
- Equations as printed (verified). Exponents were lost in the PDF text extraction and are restored
  from the polynomial structure. Check them against the PDF figure before coding.
  - Throttle: ṁ_ai = f(θ)·g(Pm) [g/s], f(θ) = 2.821 − 0.05231θ + 0.10299θ² − 0.00063θ³ (θ in deg).
    g(Pm) = 1 for Pm ≤ Pamb/2 (choked); (2/Pamb)·√(Pm·Pamb − Pm²) for Pamb/2 ≤ Pm ≤ Pamb;
    −(2/Pm)·√(Pm·Pamb − Pamb²) for Pamb ≤ Pm ≤ 2Pamb; −1 for Pm ≥ 2Pamb.
  - Manifold: dPm/dt = (R·T/Vm)·(ṁ_ai − ṁ_ao).
  - Pumping: ṁ_ao = −0.366 + 0.08979·N·Pm − 0.0337·N·Pm² + 0.0001·N²·Pm (N in rad/s, Pm in bar).
  - Compression delay: combustion is delayed 180° crank after the end of intake.
  - Torque: T = −181.3 + 379.36·m_a + 21.91·(A/F) − 0.85·(A/F)² + 0.26σ − 0.0028σ² + 0.027N
    − 0.000107N² + 0.00048Nσ + 2.55σ·m_a − 0.05σ²·m_a (m_a in g, σ spark advance in deg BTDC).
  - J·dN/dt = T_eng − T_load.
  - The booklet does not print a value for J or Vm here. Look in the shipped model or pick values.
- The booklet says its version omits EGR, unlike Crossley & Cook, and points to Moskwa & Hedrick (ACC
  1987), Powell & Cook (ACC 1987) and Weeks & Moskwa (SAE 950417) (verified).
- **Teaching value:** the torque polynomial contains A/F and spark advance explicitly. One model shows
  MBT (∂T/∂σ = 0), the cost of running rich/lean, and idle/speed control.

### 3.2 Hendricks mean value engine model (MVEM)

- Hendricks & Sorenson, "Mean Value Modelling of Spark Ignition Engines", SAE 900616 (1990): a
  three-state nonlinear model (crank speed, manifold pressure, fuel-film/AFR), ±2% steady-state
  accuracy over the full map ([SAE Mobilus](https://saemobilus.sae.org/content/900616), verified abstract).
- Follow-ups: SAE 910258 "SI Engine Controls and Mean Value Engine Modelling", SAE 920682 "The
  Analysis of Mean Value SI Engine Models" (Hendricks & Vesterholm), SAE 980784 (turbo SI), "Modelling
  of the manifold filling dynamics" ([DTU Orbit](https://orbit.dtu.dk/en/publications/modelling-of-the-manifold-filling-dynamics/)) (search summary).
- Access: SAE papers are paywalled. Guzzella & Onder Ch. 2 and Eriksson & Nielsen Ch. 7 give the same
  structure.

### 3.3 Cho & Hedrick (1989), Moskwa & Hedrick (1987)

- Cho & Hedrick, "Automotive powertrain modeling for control", *ASME J. Dyn. Sys. Meas. Control*
  111(4):568–576, 1989: eight states plus two time delays, covering the SI engine, automatic
  transmission and tires ([TRID](https://trid.trb.org/View/493404), search summary). Paywalled.
- Moskwa thesis (free, §2) is the long form of the Moskwa & Hedrick ACC 1987 paper.

### 3.4 Wall-wetting (x–τ, Aquino)

- Aquino, "Transient A/F Control Characteristics of the 5 Liter Central Fuel Injection Engine", SAE
  810494 (1981). A first-order wall-film model with two parameters: an impaction fraction (x) and an
  evaporation ("boiling") time constant (τ). Air flow was predicted within ±4%, and x varied linearly
  with throttle angle ([SAE Mobilus](https://saemobilus.sae.org/content/810494), search summary).
  Paywalled.
- Control-oriented treatment with compensator design: Guzzella & Onder §2.4.2 (wall-wetting) and §3.2.3
  (DEM of fuel-flow dynamics) (TOC verified).

### 3.5 Throttle (compressible orifice) and manifold filling

- Already researched with sources in `engine_manifold_vacuum.md` (isentropic orifice with choking at
  0.528, isothermal filling, speed-density). Guzzella & Onder §2.3.1–2.3.3 is the textbook reference.

### 3.6 Combustion / burn rate (Wiebe)

- Wiebe mass-fraction-burned function x_b = 1 − exp(−a·((θ−θ₀)/Δθ)^(m+1)), with parameters a
  (efficiency), m (form factor) and burn duration Δθ. It is the standard for 0-D/1-D cycle simulation
  (search summary of e.g. [bibliotekanauki.pl PDF](https://bibliotekanauki.pl/articles/949481.pdf)). The
  formula is standard (Heywood Ch. 9). I did not verify an open primary source with typical a/m
  values. Guzzella & Onder App. C.2.2–C.2.3 covers heat-release approximations (Csallner functions).
- LiU psPack (§2) is a free cycle-simulation tool.

### 3.7 Lambda sensor and transport delay

- Guzzella & Onder §2.4.3 "Gas Mixing and Transport Delays": mixing as a first-order lag plus a
  transport delay that scales with engine speed (TOC verified; equations not read).
- MathWorks `sldemo_fuelsys`: the EGO sensor is a hyperbolic-tangent switching characteristic around
  0.5 V. The PI correction uses e₀ = +0.5 when EGO ≤ 0.5 and −0.5 when EGO > 0.5. The target A/F is
  14.6. When one sensor fails the mixture goes rich, with fuel at 125% (A/F ≈ 0.8·14.6 = 11.7). When
  two or more sensors fail, the engine shuts down ([MathWorks Stateflow example](https://www.mathworks.com/help/stateflow/ug/model-a-fault-tolerant-fuel-control-system.html), verified).
- Grizzle, Dobbins & Cook, "Individual Cylinder Air-Fuel Ratio Control with a Single EGO Sensor",
  *IEEE Trans. Veh. Tech.* 40(1), 1991 ([free PDF](https://grizzle.robotics.umich.edu/files/GrizzleDobbinsCook_ICAFC.pdf), verified title). Switching-sensor-based control with dynamometer results.
- Jump/ramp limit-cycle analysis: the limit-cycle period depends on transport delay, sensor filter time
  constant, jump-back and ramp ([US4397278A](https://patents.google.com/patent/US4397278), search
  summary). This is a lead only; derive the period analytically in the notebook.

### 3.8 Three-way catalyst oxygen storage

- **Brandt, Wang & Grizzle**, "A Simplified Three-Way Catalyst Model for Use in On-Board SI Engine
  Control and Diagnostics" ([free PDF](https://grizzle.robotics.umich.edu/files/twc_conf.pdf),
  verified). The journal version is "Dynamic modeling of a three-way catalyst for SI engine exhaust
  emission control", *IEEE TCST* 8(5):767–776, 2000 (search summary).
  - θ ∈ [0,1] is the fraction of occupied oxygen sites, a **limited integrator**:
    dθ/dt = (1/C)·ṁ_F·S·(A/F_feedgas … −1)·0.21·r(·) inside 0 ≤ θ ≤ 1, and 0 otherwise. Here
    C is capacity (mass of O₂ storable) and S ≈ 14.6 is the stoichiometric ratio. r = α_L·f_L(θ) when
    lean, α_R·f_R(θ) when rich. f_L decreases monotonically from 1 to 0 and f_R increases from 0 to 1.
    The release rate is normally higher than the storage rate (verified; the equation text was garbled
    in extraction, so copy the exact form from the PDF). The data come from a 1996 Pd-Pt-Rh catalyst.
    The paper also has a static-efficiency table and a first-order temperature/light-off model.
- **Muske & Peyton Jones**, "Estimating the Oxygen Storage Level of a Three-Way Automotive Catalyst",
  ACC 2004 ([free PDF](https://skoge.folk.ntnu.no/prost/proceedings/acc04/Papers/0727_FrA05.3.pdf),
  verified). It uses a nonlinear integrating storage model with a θ-dependent capacity N(φ) instead of
  hard limits, plus a post-cat sensor distortion model. Moving-horizon estimator.
- Peyton Jones et al., "A Simplified Model for the Dynamics of a Three-way Catalytic Converter", SAE
  2000-01-0652 (search summary; paywalled).
- Guzzella & Onder §2.8.3 (2nd ed. has an "improved physical and chemical model" of the TWC, per its
  preface, verified).

### 3.9 Idle speed control benchmarks

- **Guzzella & Onder App. B**: idle-speed system modeling, parameter identification, **numerical
  parameter values (B.2.3)**, linearized model, controller design (TOC verified). This is the ETH lab
  problem.
- **Di Cairano, Yanakiev, Bemporad, Kolmanovsky, Hrovat**, "An MPC design flow for automotive control
  and applications to idle speed regulation", 47th IEEE CDC 2008 ([free PDF](https://skoge.folk.ntnu.no/prost/proceedings/cdc-2008/data/papers/0604.pdf), verified).
  - Inputs: airflow u_air (normalized 0–10, nominal 2.13) and spark u_spk ∈ [−15, 15] deg about a
    nominal with about 15° reserve below MBT. Output: speed, reference 650 rpm, must stay within
    [450, 2000] rpm.
  - Plant: G_air(s) = k₁·ω₁²/(s² + 2δ₁ω₁s + ω₁²)·e^(−sT_air) and
    G_spk(s) = k₂·ω₂²(s/a + 1)/(s² + 2δ₂ω₂s + ω₂²)·e^(−sT_spk), with T_air ≈ 0.12 s, T_spk ≈ 0.03 s at
    650 rpm, Ts = 30 ms.
  - The numeric k, δ, ω values were not printed in the part I read. Check the PDF.
  - **Teaching value:** a fast, short-delay actuator (spark) next to a slow, long-delay one (air).
- **HYCON idle speed control benchmark**: Balluchi, Benvenuti, Di Benedetto, Villa,
  Sangiovanni-Vincentelli. A hybrid model of the four-stroke engine for idle and cut-off control
  ([Univ. Rome record](https://iris.uniroma1.it/handle/11573/524844); related [Proc. IEEE 2000 PDF](https://ptolemy.berkeley.edu/projects/embedded/asves/hybrid/papers/procIEEE2000.pdf)) (search summary; not opened).

### 3.10 Mapped engine (MathWorks Powertrain Blockset)

- **Mapped SI Engine**: lookup tables for torque, air, fuel, exhaust temperature, efficiency and
  emissions versus commanded torque and speed ([MathWorks](https://www.mathworks.com/help/autoblks/ref/mappedsiengine.html), search summary).
- **SI Core Engine**: speed-density or dual-cam air models. Torque is inner torque (gross IMEP) minus
  friction, with a spark-retard efficiency multiplier M_sa = f(ΔSA), ΔSA = SA_opt − SA. Fuel mass flow
  comes from injector slope × pulse width × cylinders ([MathWorks](https://www.mathworks.com/help/autoblks/ref/sicoreengine.html), verified).
- This is the structure we want for "pulse width = base × factors" and the "spark efficiency vs
  retard" slide.

### 3.11 Knock control

- Guzzella & Onder §4.2 (autoignition, knock criteria, detection, controller) (TOC verified).
- Conventional strategy: retard spark quickly on each knock event and advance it slowly otherwise.
  Statistical and knock-margin controllers instead track a target knock rate. Sources: Politecnico di
  Milano papers [knock_margin_control.pdf](https://re.public.polimi.it/bitstream/11311/1063829/1/knock_margin_control.pdf)
  and [OutputBasedKnockControl_TCST.pdf](https://re.public.polimi.it/retrieve/e0c31c0d-6804-4599-e053-1705fe0aef77/OutputBasedKnockControl_TCST.pdf)
  (search summary; direct fetch 403).

### 3.12 Drive cycles

| Cycle | Source | Format | Status |
|---|---|---|---|
| WLTC class 1, 2, 3a, 3b | [DieselNet WLTC page](https://dieselnet.com/standards/cycles/wltp.php) (cites UNECE GTR 15) | .txt time–speed | verified |
| WLTP official text (GTR No. 15, Amendment 6, 2020) | [unece.org PDF](https://unece.org/sites/default/files/2022-06/ECE-TRANS-180a15am6e.pdf) | PDF (cycle tables + road-load procedure) | search summary; PDF blocked (403). Annex numbers not verified. |
| UDDS, FTP-75, HWFET, US06, SC03, NYCC, LA-92; ECE elementary urban + EUDC (NEDC parts); Japanese 10-15 | [EPA Dynamometer Drive Schedules](https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules) | tab-delimited .txt / .xls, 1 Hz (some 10 Hz) | verified |

---

## 4. Datasets and parameter sets

| Dataset | Source | Content | License | Use |
|---|---|---|---|---|
| **EPA ALPHA complete engine maps** | [EPA "Combining Data into Complete Engine ALPHA Maps"](https://epa.gov/vehicle-and-fuel-emissions-testing/combining-data-complete-engine-alpha-maps) (verified) | Benchmarked engines, e.g. 2018 Mazda 2.5L Skyactiv-G, 2018 Toyota 2.5L A25A-FKS, 2016 Honda 1.5L L15B7, 2013 Ford 1.6L EcoBoost, 2014 Mazda 2.0L Skyactiv, 2015 Ford 2.7L EcoBoost, 2013 GM 2.5L LCV, 2015 BMW 3.0L diesel, plus modeled concept engines. Zips hold map images, spreadsheet tables, a method document and MATLAB input files; maps cover idle/motoring to WOT and redline. | Public, citation required ("for use in other models, technical analyses, and publications") | BSFC map → fuel use over a WLTC; peak efficiency vs the slide's ~37% |
| **ADVISOR fuel-converter data** | [ADVISOR](https://adv-vehicle-sim.sourceforge.net/) (search summary) | SI/CI engine maps as MATLAB data files | Open source | Older, alternative maps |
| **Bosch LSU 4.9 wideband** | [Bosch Motorsport datasheet](https://www.bosch-motorsport.com/content/downloads/Raceparts/Resources/pdf/Data%20Sheet_69034379_Lambda_Sensor_LSU_4.9.pdf) (verified) | Planar ZrO₂ dual-cell limiting-current sensor, range λ 0.65–∞. Ip→λ table: −2.000 mA→0.650; −1.243→0.750; −0.927→0.800; −0.652→0.850; −0.405→0.900; −0.183→0.950; −0.040→0.990; **0→1.003**; 0.097→1.050; 0.193→1.100; 0.329→1.179; 0.671→1.429; 0.938→1.701; 1.150→1.990; 1.385→2.434; 1.700→3.413; 2.000→5.391; 2.250→10.119. Nernst cell nominal 300 Ω; heater 7.5 W steady, 7.5 V nominal; accuracy λ=1: 1.016 ± 0.007. | Public datasheet | Wideband sensor lookup + first-order lag; why only Ip correlates with O₂ |
| **Bosch NTC M12 temperature sensor** | [Bosch Motorsport datasheet](https://www.bosch-motorsport.com/content/downloads/Raceparts/Resources/pdf/Data%20Sheet_70101387_Temperature_Sensor_NTC_M12.pdf) (verified) | R(T): −40 °C 45,313 Ω; −20 15,462; 0 5,896; 20 **2,500**; 40 1,175; 60 596; 80 323; 100 187; 120 113; 130 89. Accuracy ±1.4 °C at 25 °C. Typical pull-up 1 or 3 kΩ. | Public datasheet | NTC + divider → ADC → ECU lookup; fit β-parameter / Steinhart-Hart |
| **Bosch EV14 injector** | [EV14 datasheet (Lingenfelter mirror)](https://www.lingenfelter.com/images/Injection_Valve_EV_14_Datasheet_51_en_2775993867.pdf) (verified) | Flow at 3 bar (n-heptane) 146–1,023 cm³/min; variants 116–697 g/min; 12 Ω coil; max 8 bar | Public datasheet | Static injector flow; coil R for the solenoid RL model |
| Injector **dead time vs battery voltage** | Retailer copy only: 8 V 2.000 ms, 12 V 0.903 ms, 14 V 0.800 ms, 16 V 0.558 ms at 2 bar ([xtramotorsport](https://xtramotorsport.com/product/bosch-motorsport-ev14-fuel-injector-670-g-min-980-cc-min-flow-matched/), search summary) | | **Not verified** at Bosch. Not in the official datasheet above. | Battery-voltage correction factor of pulse width |
| **Two-step (switching) HEGO characteristic** | No open OEM datasheet found | | **Gap.** Use the tanh model from `sldemo_fuelsys`, or Bosch *Gasoline Engine Management* (paywalled). | |

---

## 5. Control teaching benchmarks: summary

| Problem | Best source | Plant / data available | Exercise idea |
|---|---|---|---|
| Idle speed control (air + spark, delays) | Di Cairano et al. CDC 2008 (free); Guzzella & Onder App. B (paramet. values, paywalled) | 2nd-order TFs plus dead times 0.12 s / 0.03 s; constraints | PI on air + P on spark; then a Smith predictor on the air path; load-step (A/C on) rejection |
| Engine speed control via throttle | MathWorks `sldemo_enginewc` / Crossley & Cook | Full nonlinear equations (§3.1) | Crank-synchronous discrete PI; compare with time-sampled PI (links to lecture 1 discretization notebook) |
| AFR control with switching sensor and transport delay | `sldemo_fuelsys`; Guzzella & Onder §4.3; Grizzle et al. 1991 | tanh EGO, ±0.5 error, 14.6 target; delay ∝ 1/N | Jump/ramp controller → limit cycle; period and amplitude vs delay; wideband sensor + PI/Smith predictor vs two-step |
| Wall-wetting compensation | Aquino 1981; Guzzella & Onder §2.4.2 | x–τ model | Tip-in λ excursion with and without inverse x–τ compensation |
| Post-cat trim / O₂ storage | Brandt et al.; Muske & Peyton Jones | limited-integrator θ model | Outer loop keeps θ ≈ 0.5; show breakthrough when θ saturates |
| Knock control | Guzzella & Onder §4.2; PoliMi papers | stochastic knock event vs spark | Retard-step / advance-ramp controller; mean spark vs knock rate |
| Boost control (bonus) | LiU TCSI testbed (GPL) | Full MVEM + PI with anti-windup | Anti-windup demo (links to lecture 1 windup notebook) |

---

## 6. Suggested notebook/model mapping (lecture 2)

- **02-energy-demand**: c_d·A, f_r, grade, m·a over WLTC/UDDS (DieselNet/EPA) → wheel energy; with an
  ALPHA BSFC map → fuel. Cross-check against Guzzella & Sciarretta Ch. 2 or QSS.
- **03-mean-value-engine**: Crossley & Cook equations (§3.1) as a Dyad component chain: throttle →
  manifold volume → pumping → torque → inertia. The manifold part reuses `engine_manifold_vacuum.md`.
- **04-sensors**: NTC + divider + ADC (Bosch table); LSU 4.9 lookup; tanh HEGO; MAF as a first-order
  lag (no open OEM data found).
- **05-injection**: injector RL solenoid with pickup/dropout (12 Ω coil, EV14) → dead time; pulse width
  = base × factors (SI Core Engine structure); x–τ wall film.
- **06-ignition**: torque vs spark from the Crossley-Cook polynomial → MBT; dwell/coil energy
  (½·L·I², no open coil datasheet found, **gap**); knock-control loop.
- **07-lambda-loop**: jump/ramp with transport delay → limit cycle; then the TWC θ model and post-cat
  trim.
- **08-idle-speed**: Di Cairano plant; PI vs Smith predictor; spark as fast actuator.

## 7. Gaps and unverified items

- The Crossley & Cook original paper, the Hendricks SAE papers, Aquino SAE 810494, Cho & Hedrick and
  Peyton Jones SAE 2000-01-0652 are paywalled and were not read. Their content here comes from
  abstracts or secondary reproductions.
- The ETH Engine Systems and VPS course materials are behind Moodle. The ETH QSS original download URL
  was not opened.
- No open OEM data was found for: a two-step HEGO voltage curve, an ignition coil (L, dwell), MAF
  hot-film transfer characteristic, or crank/cam sensor signals.
- The GTR 15 PDF could not be fetched (403), so annex numbers for the cycle tables and road-load
  procedure are not verified. Use the DieselNet text files for the data.
- Wiebe a/m typical values were not verified from an open primary source.
