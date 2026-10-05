# ABS hydraulic modulator (HCU) and its rule-based control, for lumped per-wheel modeling

Scope note: this search found few openly accessible primary sources with OEM valve numbers. Bosch
books (Automotive Handbook, "Driving-safety systems", Reif "Brakes, Brake Control and Driver
Assistance Systems") and SAE hydraulic-modeling papers are paywalled and were not read directly.
Where a number came only from a secondary source or a simulation default, that is stated. Every
claim below carries its source. Anything not found is in the Gaps sections.

## 1. Architecture of a return-flow (closed) ABS/ESC unit

### Takeaway
Each wheel channel is one normally-open inlet valve (fed from the master cylinder) and one
normally-closed outlet valve that dumps to a low-pressure accumulator (LPA). A return pump, one per
circuit and driven by one shared DC motor through an eccentric, sends the fluid back to the
master-cylinder side. An ESP unit adds two valves per circuit: a switchover (isolation) valve and a
high-pressure switching (suction) valve, for 12 valves in total.

### Cited Findings
- Per-wheel circuit topology used in a published HCU model: vacuum booster, master cylinder, motor,
  accumulator, inlet valve, outlet valves, pump. Master-cylinder outputs are X-split, and each
  circuit feeds two diagonal wheels through an increase (inlet) valve and a decrease (outlet)
  valve. Normal braking: inlet open, outlet closed. On incipient lock the inlet closes (hold); if
  the wheel still tends to lock, the outlet opens (decrease). — [Cai et al., "Modeling and
  Simulation of ABS Hydraulic Control Unit", EMEIT-2012](https://www.atlantis-press.com/article/3621.pdf)
- The inlet valve is a high-speed switching solenoid valve made of magnetic tube, armature
  ("action iron"), valve, push rod, valve seat, filter and filter holder. — [Cai et al.
  2012](https://www.atlantis-press.com/article/3621.pdf)
- Inlet/isolation valve: isolates the wheel from the master cylinder and the pump/accumulator.
  Outlet/dump valve: releases wheel pressure. — [Underhood Service, "ABS/ESC: Hydraulic Control
  Unit/Modulator Diagnostics"](https://www.underhoodservice.com/abs-esc-hydraulic-control-unit-modulator-diagnostics/)
- Flow through the release (outlet) valve first fills a spring-loaded piston accumulator at the
  pump inlet, which allows immediate pressure reduction. Once the pump motor is at speed, the pump
  draws fluid from that accumulator and returns it. — [US5590936A, Hydraulic ABS
  modulator](https://patents.google.com/patent/US5590936A/en)
- A Bosch ESP modulator (ABS 5.7 generation) has 12 solenoid valves. Each of its 2 circuits has
  2 inlet valves, 2 outlet valves, one high-pressure switching valve and one switchover valve.
  Each circuit also has a pump element and a low-pressure reservoir on a shared electric motor. —
  search-result summary of [ResearchGate figure, "Diagram of the ESP electrohydraulic modulator
  (ABS Bosch 5.7)"](https://www.researchgate.net/figure/Diagram-of-the-ESP-electrohydraulic-modulator-ABS-Bosch-57-RREV-RRAV-LFEV-LFAV_fig1_326685570)
  (figure labels RREV/RRAV/LFEV/LFAV: EV = Einlassventil (inlet), AV = Auslassventil (outlet)).
- The return pump is a reciprocating-piston pump driven by an eccentric. Pump pressures up to
  about 200 bar can occur. — [US5199860A, Hydraulic reciprocating piston pump for brake
  installations with ABS](https://patents.google.com/patent/US5199860A/en)
- An ESC HCU places a hydraulic pump between the wheel and the master cylinder, so that fluid can
  return from the wheel to the master cylinder while ABS/ESC is active. — [Springer IJAT, "Performance
  Prediction and Flow Characteristics of a Hydraulic Pump for ABS and ESC Systems Using FSI
  Simulation"](https://link.springer.com/article/10.1007/s12239-020-0134-4) (abstract via search)

### Inferences
- A minimal per-wheel channel for the model: MC node, then inlet valve (NO, with a check valve in
  parallel from wheel to MC), then caliper node. From the caliper node: outlet valve (NC), then LPA
  node, then pump (per circuit), then damper node, then back to the MC side upstream of the inlet
  valves. The check-valve bypass lets wheel pressure follow a released pedal even while the inlet
  valve is energized. The check-valve topology is standard Bosch/Continental practice, but no
  source read here confirms it.
- 4-channel vs 3-channel: 3-channel systems control the rear axle jointly ("select-low"). This is
  general knowledge; no source was read for it here (see Gaps).
- ESC additions per circuit, from the Bosch 12-valve description: a normally-open switchover
  valve (USV) between MC and the inlet-valve rail, which closes for active build and can
  pressure-limit. Also a normally-closed high-pressure switching valve (HSV), which opens so the
  pump suction can draw from the MC/reservoir during active build.

### Gaps
- There are no open-access datasheets for Bosch ABS 8/9/ESP 9 or Continental MK60/MK100 valve
  counts per variant, or for check-valve cracking pressures.
- The damper (damping chamber plus restrictor after the pump outlet) is known to exist, but no
  volume or orifice numbers were found.
- The Bosch books that document 3- vs 4-channel configurations could not be read.

## 2. Valve physics: equations, orifice sizes, switching times, analog/PWM operation

### Takeaway
Model each valve as a variable orifice with a turbulent law and a laminar regularization near
Δp = 0, with an opening x(t) driven by a first-order or second-order solenoid-armature model. The
Cai et al. model gives the full electro-mechanical ODE set. Analog ("linearized") inlet valves are
driven with a current that depends on Δp, taken from stored opening-current curves.

### Cited Findings
- **Solenoid electromagnetic and armature model** (Cai et al. 2012, eqs. 1–3):
  - di/dt = [U − R·i − (∂L/∂x)·i·v] / [L(x,i) + i·∂L/∂i]
  - dv/dt = (1/m)·[F_m(x,i) − k·(x + G0) − F_p(x) − b·v − F_f]
  - dx/dt = v

  U is the drive voltage, R the coil resistance, L the inductance, m the armature ("spool") mass,
  k the return-spring stiffness, G0 the spring preload, F_p the flow force, b the damping and F_f
  friction. — [Cai et al. 2012](https://www.atlantis-press.com/article/3621.pdf)
- Orifice sizes from the same paper: an outlet-valve diameter of **1.16 mm** gave good pressure
  tracking and **0.74 mm** gave poor tracking. The inlet-valve maximum tappet stroke of **0.23 mm**
  performed better than **0.33 mm**. The paper's labels are inconsistent: its figures label D for
  pressure increase and L for decrease, yet the text calls D the outlet valve. — [Cai et al.
  2012](https://www.atlantis-press.com/article/3621.pdf)
- A 2025 HCU model for wheel-cylinder pressure estimation models the normally-open valve (NOV) as
  a **relief-valve model expressed by algebraic equations**, together with a DC-motor-pump model.
  — [Liu et al., "Comprehensive wheel cylinder pressure estimation based on systematic hydraulic
  control unit model", Proc. IMechE D, 2025](https://journals.sagepub.com/doi/10.1177/09544070231215684)
  (abstract only)
- Analog inlet-valve control (Continental patent):
  - I_valve = I_open(Δp)_table · i_grad, where the "opening current characteristic curves are
    stored in an associated control unit, in which the dependency of the opening current on the
    difference in pressure is represented in table form".
  - Correction: i_grad = 1 − Range(grad_CMD / grad_max).
  - Maximum achievable gradient: grad_max is a function of Δp_valve, the hydraulic capacity
    C_wheel = dV/dp and the flow resistance R_H. The fetched text rendered it as
    Δp·C_wheel/R_H, which is dimensionally inconsistent. The physically consistent form is
    Δp/(R_H·C_wheel), so check the original.

  — [US8215722B2, Method for calculating the control current of an electrically controllable
  hydraulic valve](https://patents.google.com/patent/US8215722B2/en)
- Proportional operation of the NO inlet valve: while MC pressure rises and the outlet valve is
  closed, a current that keeps the inlet valve not fully closed limits flow into the wheel
  cylinder in proportion to the current, so wheel pressure rises gradually. — search summary of
  [US10118600, Vehicle brake hydraulic pressure control
  apparatus](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10118600)
- General solenoid valves: direct-acting valves switch in about 5–10 ms, pilot-operated valves in
  15–150 ms. This is not ABS-specific. — [Wikipedia, Solenoid
  valve](https://en.wikipedia.org/wiki/Solenoid_valve)

### Inferences
- Orifice law for the model (standard hydraulics, same as the Simscape Fluids orifice blocks):

  q = Cd·A(x)·sqrt(2/ρ)·Δp / (Δp² + Δp_cr²)^(1/4)

  This smooth form reduces to the turbulent law q = Cd·A·sqrt(2|Δp|/ρ)·sign(Δp) for
  |Δp| ≫ Δp_cr and is linear (laminar) near zero. Use Cd ≈ 0.6–0.7. For a poppet/seat valve,
  A(x) = π·d_seat·x·sin(α) up to the seat bore area π·d²/4. Seat bore 0.7–1.2 mm, per the Cai
  et al. diameters.
- A lumped simulation does not need eqs. 1–3. A first-order lag on the opening (time constant
  about 2–5 ms) plus a dead time of a few ms reproduces digital-valve behavior. This value is
  inferred from the general 5–10 ms figure above, not measured ABS data.
- Stepped build with a digital inlet valve means PWM-like pulse trains: open for a few ms, then
  hold. The pressure step per pulse is about q·t_on/C_wheel.

### Gaps
- No open source was found for ABS inlet/outlet valve seat diameters of Bosch or Continental
  production valves, opening/closing times in ms, coil resistance, or PWM carrier frequency for
  analog valves.
- The SAE hydraulic-modeling papers were not accessible.

## 3. Pressure gradients, cycle frequency, step size

### Takeaway
The only explicit numbers found come from a simulation default set (EDC HVE, SAE 2002-01-0559),
not from a hardware measurement:
- primary apply rate about 345 bar/s;
- secondary (stepped) apply rate about 34.5 bar/s, one tenth of primary;
- release rate stated as 10 000 psi/s (about 690 bar/s), but the paper also prints 7 000 kPa/s,
  so the number is internally inconsistent;
- 50 ms apply delay.

The measured front-wheel ABS pressure traces in that paper oscillate at tens of bar within
fractions of a second.

### Cited Findings
- HVE Bosch V1 defaults (P195/75R14 passenger-car tire), from Appendix I:

  | Parameter | Value |
  |---|---|
  | Apply Delay | 0.05 s |
  | Primary Application Rate | "35000 kPa (5000 psi/sec)" |
  | Secondary Application Rate | "3500 kPa (500 psi/sec)" |
  | Release Rate | "7000 kPa/sec (10000 psi/sec)" |
  | Threshold ABS pressure | 70 kPa |
  | Wheel Minimum Spin Accel (−a) | −175 rad/s² |
  | Wheel Maximum Spin Accel (+a) | 50 rad/s² |
  | Wheel Maximum Slip | 0.15 |
  | Low Friction Threshold | 0.35 |
  | Threshold Wheel Velocity | 70.4 rad/s |

  — [Day & Roberts (EDC), "A Simulation Model for Vehicle Braking Systems Fitted with ABS", SAE
  2002-01-0559](https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf)
- The EDC Figure 5 caption reads "Experimental braking test results for an ABS-equipped vehicle
  on a high-friction (asphalt) surface". It plots system and front/rear wheel pressure (bar) over
  0–4 s, with axis scales up to 80 bar and 250 bar. Its Figure 4 shows one simulated cycle between
  about 25 and 40 bar over 1.5–1.8 s. — [SAE 2002-01-0559](https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf)
- One secondary web article states that ABS modules "release and reapply pressure at 10–20 Hz
  cycles". Treat this as low-reliability: it is a non-primary source and it likely conflates valve
  pulsing with control cycles. — [Embien, "Deep Dive Into ABS Control
  Module"](https://www.embien.com/automotive-insights/a-deep-dive-into-anti-lock-brake-system-abs-control-module)
- A student implementation argues that ABS logic should run at about 500 Hz, compared with the
  50 Hz used in its simulation. — [Howlett, "Construction of Automotive Control Software (ABS)",
  BSc thesis, 2019](https://charliehowlett.co.uk/ABSConstruction.pdf)
- The Cai et al. HCU increase and decrease pressure tests track a target pressure, but the
  gradients are shown only graphically. — [Cai et al. 2012](https://www.atlantis-press.com/article/3621.pdf)

### Inferences
- The EDC 5000 psi/s ≈ 345 bar/s and 500 psi/s ≈ 34.5 bar/s conversions are internally
  consistent: 35 000 kPa/s and 3 500 kPa/s. The release line is not: 10 000 psi/s = 68 950 kPa/s,
  not 7 000 kPa/s. One of those two numbers is a typo. Use 690 bar/s as the dump rate only as a
  placeholder, since it matches the "release faster than primary apply" logic.
- The ratio of about 10:1 between primary and secondary apply rates is what the stepped
  (pulse-series) build should emulate on average.
- Full ABS control cycles (dump, hold, build) implied by the EDC traces are of order 0.1–0.3 s,
  that is, about 3–10 Hz. This is read from the trace time scale and is not a stated number.

### Gaps
- No hardware-measured build/dump gradients for Bosch or Continental units, and no documented
  stepped-reapply step size in bar per pulse, were found openly. Bosch "Driving-safety systems"
  (SAE ISBN 0-7680-0511-6), the source the EDC implementation follows, should contain them.

## 4. Low-pressure accumulator, return pump, motor, pedal feedback

### Takeaway
The LPA is a spring-loaded piston accumulator: preload about 4–6 bar, about 10 bar when full,
about 5 cm³ per circuit in one published model. Its capacity is sized relative to the wheel-brake
fluid volume. The return pump is an eccentric-driven piston pump, with q = A·e·ω·cos(ωt) per
piston. Returned fluid and valve switching cause pedal kickback.

### Cited Findings
- LPA prestress "equivalent to a high accumulator pressure of, for example 4 to 6 bars". "When
  the holding capacity of the low-pressure accumulator 48 is fully utilized, it is equivalent to a
  pressure of approximately 10 bars." — [US5015043A (Daimler-Benz ASR/ABS)](https://patents.google.com/patent/US5015043A/en)
- A related patent search summary reported two further sizing rules. The LPA "receiving capacity
  corresponds approximately to half the brake fluid volume forced under highest brake pressure
  into wheel brakes". Pump "delivery volume per piston stroke is about 1/20 to 1/10 of the
  receiving capacity of the low-pressure accumulator". This was not confirmed in the US5015043
  full text, which was fetched but did not show these sentences. The exact patent is unconfirmed:
  it is one of [US5015043](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5015043)
  or [US7931345](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7931345).
- Cai et al. model parameters:

  | Parameter | Value |
  |---|---|
  | Motor resistance | 0.125 Ω |
  | Motor inductance | 9.34e-5 H |
  | Motor inertia | 9.5e-5 kg·m² |
  | Motor friction torque | 0.3 N·m |
  | Accumulator volume | 5.3 ml |
  | Accumulator spring stiffness | 6200 N/m |
  | Accumulator piston diameter | 24 mm |
  | Pump eccentricity | 1 mm |
  | Pump piston diameter | "1mm" (as printed) |

  — [Cai et al. 2012](https://www.atlantis-press.com/article/3621.pdf)
- Cai et al. pump/motor/LPA equations:
  - Pump: V = A·e·sin(φ0 + ωt), q = A·e·ω·cos(φ0 + ωt).
  - Equivalent piston pressure p = p_out − f·p_in, where f is the area ratio.
  - Load torque M = q·p.
  - DC motor: di/dt = (U − iR − kφ·ω)/L, and J·dω/dt = kφ·i − (M + m0). The paper writes the
    second as "ω = [kφ·i − (M+m0)]/J", which is evidently dω/dt.
  - LPA: V = l_e·π·d²/4, q = v·(π/4)·d²·ρ(P)/ρ(0), and piston force F = l_e·k − (π/4)·d²·P,
    with F = m·ẍ.

  — [Cai et al. 2012](https://www.atlantis-press.com/article/3621.pdf)
- The pump motor recirculates brake fluid during ABS. Solenoid and pump operation causes the
  pedal "kick back"/pulsation. — [Underhood Service](https://www.underhoodservice.com/abs-esc-hydraulic-control-unit-modulator-diagnostics/);
  [Brake & Front End, "Understanding ABS Modulator Problems"](https://www.brakeandfrontend.com/understanding-abs-modulator-problems/)
- Short-term pressure peaks are buffered in an equalizing tank. A hydraulic pump regularly returns
  excess fluid toward the reservoir so that the tank does not overflow. — search summary of the
  ESP modulator sources above (low reliability, secondary).

### Inferences
- Consistency check on Cai et al. The spring stiffness of 6200 N/m on a 24 mm piston (area
  4.52e-4 m²) gives 1.37e7 Pa per m of stroke. The 5.3 ml volume corresponds to 11.7 mm of
  stroke, which is about 1.6 bar of spring-pressure rise over the full stroke. That is
  plausible only with a preload of a few bar, consistent with the 4–6 bar to 10 bar range in
  US5015043.
- A 1 mm pump-piston diameter with 1 mm eccentricity gives about 1.6 mm³ per revolution, far too
  small to empty a 5 ml LPA. The printed "1mm" diameter is probably a typo, for example for
  about 6–10 mm. Flag it rather than use it.
- Modeling the LPA: V_lpa = clamp((p_lpa − p_pre)/k_eff, 0, V_max). Its spring stiffness is
  k_eff = k_spring/A_piston². When V_lpa reaches V_max, the LPA pressure rises sharply toward the
  wheel pressure, so the outlet-valve Δp and the dump rate collapse. Pump-out rate then limits
  dump capability. This is why sustained low-μ ABS needs the pump running.
- Pedal pulsation: the pump discharges into the MC-side line through the damper, pushing fluid
  back into the MC. This shows up as pressure ripple at pump frequency (motor speed × number of
  pistons) and as pedal push-back.

### Gaps
- Typical motor speeds (rpm), pump displacement per revolution, and damper volumes for current
  units were not found in open sources.

## 5. Rule-based ABS logic mapped to valve commands (Bosch cycle)

### Takeaway
The Bosch cycle, as implemented in the published EDC model after Bosch "Driving-safety systems"
(1999), has eight phases. Each phase maps directly to inlet/outlet commands:

| Phase | Wheel condition / trigger | Pressure action | Inlet (NO) | Outlet (NC) |
|---|---|---|---|---|
| 1 | Normal braking, until wheel decel < −a | Follow MC | open | closed |
| 2 | Wait until slip > slip threshold (λ1) | Hold | closed | closed |
| 3 | Until wheel accel back above −a (EDC: until it becomes positive) | Dump at release rate | closed | open |
| 4 | Apply-delay time or until accel > +A | Hold | closed | closed |
| 5 | Until accel drops below +A (EDC: until it goes negative) | Build at primary rate | open | closed |
| 6 | Apply delay, or until decel < −a again | Hold | closed | closed |
| 7 | Until decel < −a | Slow build at secondary rate (about 1/10 of primary) | pulsed | closed |
| 8 | New cycle | Dump, go to phase 3 | closed | open |

### Cited Findings
- EDC's description of the phases, which "is based on the information provided in reference 10"
  (Bosch Driving-safety systems, 2nd ed., SAE, 1999, ISBN 0-7680-0511-6). — [SAE
  2002-01-0559](https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf)
  - Phase 1: "Output pressure is set equal to input pressure … until the wheel angular
    acceleration (negative) drops below the Wheel Minimum Spin Acceleration, −a."
  - Phase 2: maintain pressure "until the tire longitudinal slip exceeds the slip associated with
    the Slip Threshold. At this time, the current tire slip is stored and used as the slip
    threshold criterion in later phases."
  - Phase 3: reduce at Release Rate "until the wheel spin acceleration becomes positive (… in
    which the pressure is decreased until the spin acceleration exceeds −a)".
  - Phase 4: hold "for the specified Apply Delay, or until the wheel spin acceleration (positive)
    exceeds +A, a multiple (normally 10x) of the Wheel Maximum Spin Acceleration, +a".
  - Phase 5: "increases according to the Primary Apply Rate" until acceleration becomes negative
    (Bosch: drops below +A).
  - Phase 6: hold for Apply Delay or until acceleration again passes −a.
  - Phase 7: "increases according to the Secondary Apply Rate, normally a fraction (1/10) of the
    Primary Apply Rate … until wheel angular acceleration drops below" −a.
  - Phase 8: reduce; "the process returns to Phase 3 and a new control cycle begins".
  - Adaptive learning: if the current slip exceeds the slip stored in phase 2, the logic jumps to
    phase 3.
- Bosch cycle notes (patent search summary): in phases 1 and 5 the wheel runs in the stable
  region of the μ-slip curve, and during phases 2 and 6 a closed (not pulsed) pressure reduction
  takes place. This phase numbering differs from EDC. — [US5618088, Anti-lock control
  system](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5618088)
- Threshold-based patents use deceleration thresholds B12 (switch from phase 1, increase, to
  phase 2, hold) and B23 (switch from phase 2 to phase 3, decrease). These are set per vehicle-speed
  range and road μ. — search summary of [US5190361](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5190361)
  and related patents
- Build-phase parameters in a Bosch-style algorithm:
  - AMax1 is the wheel-deceleration threshold that triggers holding during pressure build-up.
  - AMax2 is the threshold that triggers reduction.
  - DeltaPSearch0 is the per-cycle pressure increment ("search ramp").
  - DeltaPRed0 is the pressure release on exceeding AMax2.

  — [US5332301A](https://patents.google.com/patent/US5332301A/en)
- Typical threshold magnitudes are quoted in a secondary summary: hold at −1.2 to −1.8 g wheel
  deceleration, reduce at 25–35 % slip, re-apply at +0.5 to +1.0 g. This is low reliability
  (an aggregator). — [PatSnap Eureka, ABS technical analysis](https://eureka.patsnap.com/materials/abs-braking-system-technical)
- EDC default thresholds: −a = −175 rad/s² and +a = 50 rad/s². +A = 10·(+a) = 500 rad/s² per the
  "normally 10x" rule. — [SAE 2002-01-0559](https://edccorp.com/library/TechRefPdfs/EDC-0033.pdf)

### Inferences
- For a wheel radius of about 0.3 m, −175 rad/s² corresponds to about 52 m/s² (5.3 g) of
  circumferential wheel deceleration. That is much larger than the 1.2–1.8 g in the aggregator.
  The two sets are not directly comparable: EDC thresholds are tuned for its simulation, and
  real Bosch −a values are proprietary. Treat both as tuning starting points.
- Pulse series for phase 7: command the inlet valve open for t_on (a few ms), then closed for
  t_off (tens of ms), so that the mean gradient is about 1/10 of the free-flow build rate. For
  example, with a free-flow rate of about 345 bar/s, a 5 ms pulse gives about 1.7 bar per step.
  Every 50 ms, that averages about 35 bar/s, matching the EDC secondary rate. The numbers are
  illustrative and derived from the table above.
- Implementation as a finite-state machine: state = phase, and transitions use wheel
  acceleration (from the wheel-speed derivative) and slip relative to a reference speed. The
  output is a pair (inlet_cmd, outlet_cmd) ∈ {0,1}² plus an optional inlet duty cycle.

### Gaps
- The original Bosch cycle figure and its high-μ, low-μ and μ-split variants (for example
  low-μ phases with λ1 slip threshold and pulsed dump) were not read first-hand.
- No vendor-disclosed pulse widths (ms) or step sizes (bar) were found.

## 6. Published lumped HCU models and validation data

### Takeaway
Usable open models are:
- Cai et al. 2012, with full equations and partial parameters;
- EDC SAE 2002-01-0559, a rate-based pressure model with parameters and a measured vehicle trace;
- the MathWorks Simscape Fluids "ABS Open Loop Test Bench", with its parameters only inside the
  model file;
- US8215722, for the analog-valve current law.

### Cited Findings
- Cai et al.:
  - Simulink HCU model built from solenoid valve, motor, pump and accumulator submodels.
  - Validated against HCU bench pressure increase/decrease tests that follow a target pressure,
    shown in figures only.
  - Their references [3] Xie 2008 and [4] Gao 2009, both Jilin University theses on ESP
    hydraulic modulator modeling, are sources for fuller models.

  — [Cai et al. 2012](https://www.atlantis-press.com/article/3621.pdf)
- MathWorks "ABS Open Loop Test Bench" (Simscape Fluids):
  - Tandem primary cylinder, an HCU with apply valve, release valve, pump and accumulator, and a
    fixed caliper disc brake.
  - Simulates open-loop ABS and plots caliper pressures.
  - "can be utilized in sizing of the release valve, apply valve and accumulator".
  - Numerical parameters are only in the model file, not on the page.

  — [MathWorks](https://www.mathworks.com/help/hydro/ug/ABS-open-loop-il.html)
- Pressure-transfer model of an ESC HCU for wheel-pressure estimation. — [Research on ESC Hydraulic
  Control Unit Property and Pressure Estimation, Springer
  2012](https://link.springer.com/chapter/10.1007/978-3-642-31656-2_86) (abstract only)
- Systematic HCU model with a DC motor-pump and algebraic relief-valve NOV. — [Liu et al.
  2025](https://journals.sagepub.com/doi/10.1177/09544070231215684) (abstract only)
- Pressure estimation and control of an HCU in an electric-wheel vehicle. — [Xiangyang et al.,
  Math. Probl. Eng. 2020](https://onlinelibrary.wiley.com/doi/10.1155/2020/6576297) (403 on
  fetch; not read)

### Inferences
- Recommended lumped state set per wheel:
  - caliper pressure p_w, with C_w(p) = dV/dp from the caliper p–V curve;
  - valve openings x_in and x_out, each as a first-order lag;
  - per circuit: LPA volume, damper pressure and pump speed ω (motor ODE).
- Mass balance: C_w·dp_w/dt = q_in(p_mc − p_w, x_in) + q_chk(p_w − p_mc) − q_out(p_w − p_lpa, x_out).
- The MathWorks example is the most direct template for building the model in Modelica or
  Simscape. Open it in MATLAB to harvest parameters.

### Gaps
- No open Modelica ABS-HCU library was found.
- No open measured caliper-pressure traces with synchronized valve commands were found; only EDC's
  vehicle trace was found.
