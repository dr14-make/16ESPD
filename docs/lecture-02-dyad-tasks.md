# Dyad agent brief — Lecture 2 engine models

Companion to `docs/lecture-02-plan.md`, which holds the teaching intent, the settled decisions
(S1–S10), the reality anchors and the "Agent quick start" table. Read the plan first. Several
component shapes only make sense once you know which notebook consumes them
(`docs/lecture-02-notebooks.md`).

## Read before the first compile

1. `docs/lecture-02-plan.md`: settled decisions, reality anchors, commands.
2. `agent_resources/skills/dyad-language/SKILL.md`, then from `agent_resources/docs/`:
   `syntax.md`, `components.md`, `initialization.md`, `metadata.md` (test blocks),
   `analyses.md` and `analysis_points.md` (needed for `LinearAnalysis` in task 2).
3. `docs/HANDOVER.md` § "Gotchas found during the build". Every item there has already cost a
   cycle once. The two that bite hardest: a `.dyad` edit does nothing until
   `~/.dyad-maxwell/dyad-lang/apps/cli/dyad compile .` regenerates `generated/`, and the suite must
   run from `test/`.
4. `docs/lecture-01-dyad-tasks.md` § "Parameter forwarding" and § "Harnesses and analyses". The
   same rules apply here.
5. The source note for whatever you are building, listed under each component as **Refs**.

## Submodule layout

    dyad/Vehicle/Engine/   physical engine: air path, torque, fuel film, exhaust, sensors, actuators
    dyad/Vehicle/ECU/      control functions an ECU runs: fuel metering, λ, idle, knock, torque structure
    dyad/Lecture2/         harnesses, scenarios and analyses that exist only to teach this lecture

The dividing line from Lecture 1 still holds: if a later lecture would use it unchanged, it
belongs under `Vehicle/`. Referenced fully qualified, e.g.
`VehicleSystemsComponents.Vehicle.Engine.AirPath`. A definition may not share its name with a
sibling submodule directory, so no component may be called `Engine` or `ECU`.

## Ground rules

- **Compose the standard library; write equations only where nothing exists.** Stdlib source
  lives at `agent_resources/stdlib_reference/<Library>/<Path>.dyad`. Read the component before
  using it; parameter names are not guessable.
- **Namespace everything** except base connectors (`RealInput`, `RealOutput`, `Flange`, `Spline`,
  `Pin`, `HeatPort`).
- **Never edit `generated/`.** **Never change an existing component** (`IdealEngine`,
  `CarPlant`, `VehicleBody`, `Driveline`, anything under `Vehicle/Brake` or `Vehicle/Wheel`).
  Lecture 1 and Lecture 3 tests pin their numbers (plan S6).
- **Units.** SI inside components: engine speed is `omega` in rad/s, pressure in Pa, mass flow in
  kg/s. **One documented exception: spark advance is in degrees BTDC** (signals `sigma`,
  tables `sigma_mbt`), because every map, slide and source uses degrees. Convert to rpm only for
  display, through the existing `Vehicle.ToRPM`.
- **Provenance tags on every default** (plan S10): `(MathWorks)`, `(Bosch)`, `(EPA ALPHA)`,
  `(Brandt)`, `(Di Cairano)`, `(Crossley-Cook)`, `(deck)`, `(textbook)`, `(derived)`,
  `(assumed)`, in the parameter's docstring.
- **No events** (plan S7). Latches and switches use `ifelse`/`min`/`max`, following
  `dyad/Vehicle/ABSController.dyad`. A sign function that the solver must step across is
  smoothed with `tanh(e/eps)`, and a test shows that halving `eps` changes the result by under 2 %.
- **Every component ships a `test component`** with a `"tests"` metadata block carrying
  `expect.initial` and `expect.final` (copy the shape from
  `dyad/Vehicle/Wheel/SlipWheel1D.dyad`). Reality-anchor checks that need derived metrics go in
  `test/engine_plausibility.jl` (create it, include it from `test/runtests.jl`). Generic helpers
  (`rise_time`, `max_rate`, `cycle_frequency`) go in `test/plausibility_helpers.jl`, shared with
  the brake suite.
- **Harnesses drive every `RealInput` and set initial conditions at the steady operating point**
  (`p_m`, `omega`, film mass, controller integrators), so runs do not spend seconds settling
  before the interesting part. A model with an unconnected `RealInput` cannot be a
  `TransientAnalysis` model.
- **Every `Lecture2` harness `X` gets an analysis `XTransient`** (or `XSteadyState`) extending
  `TransientAnalysis`, the repo's naming convention (`ABSBrakeTransient`, `ForceChainTransient`).
  Every knob a notebook varies is forwarded to the harness and exposed on the analysis by a short
  name (Lecture 1 parameter-forwarding rule). Notebooks call these analyses and nothing deeper. A
  notebook that needs a nested `a__b__c` override is a missing forward: fix the analysis.
- **Verify as you go.** Compile and simulate each component before building the next.
- **If a reality anchor fails, report it with the number.** Do not move the band and do not tune
  a parameter outside its sourced range without saying so. The bands are design choices.
- US English in identifiers and docstrings. Comments explain *why* (a constraint, an invariant, a
  gotcha), never what the code says and never the history of the change.

## Engine constants

One place for shared numbers. Each component repeats the ones it uses as defaults, with the tag.

| Name | Value | Tag |
|---|---|---|
| `V_d` displacement | 1.5e-3 m³ | (MathWorks) shared with brake plan 2a |
| `V_m` manifold volume | 1.0e-3 m³ | (MathWorks) |
| `n_cyl` | 4 | (assumed) |
| `R` air | 287.05 J/(kg·K) | (textbook) |
| `gamma` air | 1.4 | (textbook) |
| `p_a` ambient | 101 325 Pa | (textbook) |
| `T_a`, `T_m` intake air | 298.15 K | (MathWorks) |
| `D_thr` throttle plate | 0.05 m | (MathWorks) |
| `A_idle` throttle leakage / bypass at closed throttle | 13e-6 m², calibrate for 33 kPa idle | (derived) brake plan 2a |
| `AFR_s` stoichiometric | 14.7 | (deck) slide 44 map; slide 23 says 14.6, a fuel-composition difference: note it in the docstring |
| `H_l` lower heating value, gasoline | 43.4e6 J/kg | (textbook) |
| `rho_f` gasoline density | 740 kg/m³ | (textbook) |
| `omega_idle` | 800 rpm = 83.8 rad/s | (assumed) matches brake plan |
| `omega_max` rev limit | 6500 rpm = 680.7 rad/s | (assumed) |
| `J_e` crankshaft + flywheel | 0.15 kg·m² | (assumed) check against Guzzella & Onder App. B if a copy is available |

## Vehicle/Engine — air path (task 1)

**Refs:** `research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md`
(equations, numbers, the 2π trap in the Simscape cylinder-flow form);
`docs/brake-system-implementation-plan.md` § 2a (the interface and done-when this task adopts);
MathWorks Air Intake defaults (https://www.mathworks.com/help/sdl/ref/airintake.html);
Guzzella & Onder §2.3.1–2.3.3 (textbook form).

### `Throttle` (new equations)

    RealInput u_thr        # 0 = closed stop, 1 = wide open
    RealInput p_m          # downstream pressure
    RealOutput mdot_thr
    alpha   = alpha_0 + u_thr * (pi/2 - alpha_0)                  # plate angle; alpha_0 = closed angle
    A_thr   = A_idle + (pi * D_thr^2 / 4) * (1 - cos(alpha) / cos(alpha_0))
    Pi      = max(p_m / p_a, Pi_cr)                               # Pi_cr = (2/(gamma+1))^(gamma/(gamma-1)) = 0.528
    Psi     = sqrt(2*gamma/(gamma-1) * (Pi^(2/gamma) - Pi^((gamma+1)/gamma)))   for Pi <= Pi_lin
            = linear through 0 at Pi = 1, matched at Pi_lin = 0.95            otherwise
    mdot_thr = C_d * A_thr * p_a / sqrt(R * T_a) * Psi

The linearization above `Pi_lin` removes the infinite slope at `Pi = 1` and allows reverse flow
if `p_m > p_a` (brake plan 2a). `alpha_0 = 7°` (assumed), `C_d = 0.8` (assumed). Throttle flow
must never go negative while choked.

### `IntakeManifold` (new equations)

    RealInput mdot_in, mdot_out, mdot_aux     # aux = booster check-valve inflow (brake plan 2a); 0 here
    RealOutput p_m
    der(p_m) = R * T_m / V_m * (mdot_in + mdot_aux - mdot_out)

### `CylinderAirflow` (new equations)

    RealInput p_m, omega
    RealOutput mdot_cyl
    mdot_cyl = eta_v(omega, p_m) * V_d * omega / (4*pi) * p_m / (R * T_m)

`omega/(4*pi)` is the four-stroke `N/120` in rad/s; the Simscape `omega*V_d*p/(2RT)` form is off
by 2π (see the manifold note). `eta_v` is a `BlockComponents.Tables.InterpolatedTable`
(`agent_resources/stdlib_reference/BlockComponents/Tables/InterpolatedTable.dyad`) over `omega`
and `p_m`, with a structural `use_table` switch that falls back to a constant `eta_v0 = 0.8` for
the brake plan. Default table: `eta_v` ≈ 0.55 at idle pressure rising to 0.90 at mid-speed wide
open, falling to 0.80 at 6500 rpm (assumed shape; the note computes ≈ 0.51 at a real idle point).

### `AirPath` (assembly)

`Throttle` + `IntakeManifold` + `CylinderAirflow`. Inputs `u_thr`, `omega`, `mdot_aux`; outputs
`p_m`, `mdot_thr` (what a MAF sensor would see), `mdot_cyl`. This is exactly brake plan 2a's
interface; once it lands, 2a is done.

## Vehicle/Engine — torque and the mean-value engine (task 2)

**Refs:** plan S3; MathWorks SI Core Engine (https://www.mathworks.com/help/autoblks/ref/sicoreengine.html)
for the efficiency-chain structure; teaching materials §3.1 (Crossley & Cook, for comparison only)
and §4 (EPA ALPHA maps, for calibration sanity).

### `SpeedScheduledDelay` (new equations; plan S8)

    RealInput u, omega
    RealOutput y
    structural parameter n::Integer        # decision D1
    parameter phi::Real                    # delay as crank angle [rad]
    parameter theta_0::Time = 0            # speed-independent part (gas travel)
    theta = phi / max(omega, omega_min) + theta_0
    chain of n first-order lags, each with time constant theta / n

Used for induction-to-power (`phi` = 180° crank, Crossley-Cook) and exhaust transport (task 5).
Its test compares it against `BlockComponents.Nonlinear.PadeDelay` at constant speed.

### `TorqueProduction` (new equations; plan S3)

    RealInput mdot_cyl, mdot_f_cyl, sigma, omega, p_m
    RealOutput tau_e, lambda_cyl, eta_b
    lambda_cyl = mdot_cyl / (AFR_s * max(mdot_f_cyl, eps_f))
    burned     = min(mdot_f_cyl, mdot_cyl / AFR_s)
    M_sigma    = max(0, 1 - c_sigma * (sigma_mbt(omega, p_m) - sigma)^2)
    tau_i      = eta_i * M_sigma * M_lambda(lambda_cyl) * H_l * burned / max(omega, omega_min)
    FMEP       = k_f * (0.97e5 + 0.15e5 * (N/1000) + 0.05e5 * (N/1000)^2)      # Pa, N in rpm
    tau_e      = tau_i - V_d / (4*pi) * (FMEP + p_exh - p_m)
    eta_b      = tau_e * omega / (H_l * max(mdot_f_cyl, eps_f))

- `burned` makes torque air-limited when rich and fuel-limited when lean, and zero on fuel cut.
- `M_lambda`: a 1-D `Interpolation` table, 1.00 at λ = 1, about 1.03 at λ = 0.88 (rich power), about
  1.04 at λ = 1.1 (lean efficiency; torque still falls because `burned` falls), dropping to 0 near the
  lean misfire limit λ ≈ 1.6 (assumed shape).
- `c_sigma = 4e-4 /deg²` gives 4 % loss at 10° from MBT (assumed; anchor 2–5 %).
- `sigma_mbt`: an `InterpolatedTable` over `omega` and `p_m`, about 10° at idle to 35° at
  high speed and light load (assumed; task 6 produces a physics-based version notebook 02 compares).
- FMEP is the Barnes-Moss SI correlation (textbook, Heywood eq. 13.20, unverified). `k_f`
  scales it for a modern engine; see decision D3. `p_exh = 1.05 * p_a` (assumed).
- `eta_i = 0.40` (assumed), tuned with `k_f` to land the efficiency and torque anchors.

**Calibration tension, flagged up front.** A hand check at 3000 rpm WOT with `eta_v = 0.9`,
`eta_i = 0.40`, `k_f = 1` gives `tau_e ≈ 118 N·m`, below the 130–150 N·m band. Barnes-Moss
friction (≈ 1.9 bar at 3000 rpm) is high for a modern engine. Expect `k_f ≈ 0.6` and
`eta_v` peak ≈ 0.95. Report what you chose.

### `WallWetting` (new equations; built in task 3, used here)

See task 3. `MeanValueEngine` includes it behind a structural `with_film::Boolean = true`.

### `MeanValueEngine` (assembly)

    ports: Spline spline, support
    inputs: u_thr, mdot_f_inj (injected fuel mass flow), sigma (deg BTDC), T_cool (for the film)
    outputs: omega, p_m, mdot_thr, mdot_cyl, lambda_cyl, tau_e, eta_b
    AirPath -> WallWetting -> SpeedScheduledDelay (induction to power, on air and fuel)
      -> TorqueProduction -> RotationalComponents.Sources.TorqueSource
    RotationalComponents.Components.Inertia(J = J_e) on the spline side
    speed sensor -> omega

### Lecture2 harnesses for task 2

- `EngineDyno`: `RotationalComponents.Sources.SpeedSource`
  (`agent_resources/stdlib_reference/RotationalComponents/Sources/SpeedSource.dyad`) holds speed;
  fuel is metered open loop at `lambda = 1` from `mdot_cyl` (a simple `Gain`, no ECU yet). Forward
  `omega_set`, `u_thr`, `sigma`.
- `EngineMapSweep`: an analysis (or a Julia helper in `notebooks/lecture02/support.jl`, decided in
  the notebook brief) running `EngineDyno` across `omega × u_thr` to steady state and tabulating
  torque, BSFC, `p_m` and `eta_b`. `SteadyStateAnalysis` is documented in `agent_resources/docs/analyses.md`.
- `ThrottleStep`: free-running engine on a load inertia with a throttle step. Used by
  `LinearAnalysis` at idle, 2000 rpm and 4000 rpm to read gain, lag and delay (needs analysis
  points; see `agent_resources/docs/analysis_points.md`).

## Vehicle/Engine + Vehicle/ECU — fuel path (task 3)

**Refs:** teaching materials §3.4 (x–τ, Aquino), §3.10 (SI Core Engine fuel structure);
deck slide 44 (`ppt/media/image53.png`, the AFR map to transcribe); Guzzella & Onder §2.4.2 if a
copy is available.

### `WallWetting` (new equations)

    RealInput mdot_inj, T_cool
    RealOutput mdot_f_cyl
    X     = interpolate between X_cold = 0.5 and X_warm = 0.3 over T_cool in [20, 90] °C     (assumed)
    tau_f = interpolate between tau_cold = 0.6 s and tau_warm = 0.2 s                       (assumed)
    der(m_film) = X * mdot_inj - m_film / tau_f
    mdot_f_cyl  = (1 - X) * mdot_inj + m_film / tau_f

### `Vehicle/ECU/FuelMetering` (new equations; the slide 44 formula as a component)

    RealInput mdot_air_meas, omega, p_m, T_cool, lambda_trim, U_batt
    RealOutput mdot_f_cmd, t_inj
    load        = p_m / p_a
    lambda_tgt  = AFR_map(omega, load) / AFR_s     # InterpolatedTable from the transcribed slide 44 map
    mdot_f_base = mdot_air_meas / (AFR_s * lambda_tgt)
    mdot_f_des  = mdot_f_base * F_cool(T_cool) * lambda_trim
    film compensation (structural with_comp): an internal x–tau model with estimates Xh, tauh;
        mdot_f_cmd = (mdot_f_des - m_film_hat / tauh) / (1 - Xh), clipped at >= 0
    t_inj       = (mdot_f_cmd * 4*pi / (max(omega, omega_min) * n_cyl)) / q_inj + t_dead(U_batt)

- Transcribe the slide 44 table (speeds 600–6000 rpm × load 10–100 %, AFR values) into
  `data/engine/afr_map_slide44.csv` with a header comment naming the source slide. Load axis is the
  percentage in the slide, interpreted as `p_m / p_a`.
- `F_cool`: warm-up enrichment, 1.3 at 20 °C to 1.0 at 80 °C and above (assumed).
- `q_inj` is the injector static flow in kg/s per injector: 146 cm³/min × `rho_f` (Bosch EV14).
- `t_dead(U_batt)`: the EV14 table (8 V 2.00 ms, 12 V 0.90, 14 V 0.80, 16 V 0.558) as an
  `Interpolation`, tagged "retailer data, not verified at Bosch". Task 4 regenerates it from physics.
- Overrun fuel cut (structural `with_cutoff`): cut when `u_thr` is near 0 and `omega > 1500 rpm`,
  resume below 1200 rpm, as a continuous latch.

### Lecture2 harness: `TipInTest`

`EngineDyno` at 2000 rpm, `FuelMetering` with `lambda_trim = 1`, warm and cold, throttle tip-in
from 10 % to 40 % at t = 1 s and tip-out at t = 3 s. Forward `with_comp`, `T_cool`, `Xh`, `tauh`.

## Vehicle/Engine — fuel injector (task 4)

**Refs:** deck slides 43 and 45 (`ppt/media/image54.png`); Bosch EV14 datasheet (12 Ω, flow
variants, max 8 bar) and the dead-time table, both in teaching materials §4; stdlib
`ElectricalComponents/Analog/Basic/{Resistor,VariableResistor,Ground}.dyad`,
`ElectricalComponents/Analog/Sources/VoltageSource.dyad`,
`TranslationalComponents/Components/{Mass,Spring,ElastoGap,Fixed}.dyad`. Stdlib
`TranslationalEMF` is a constant-gain transducer, not a gap-dependent solenoid, so it is
not the right block.

### `Solenoid` (new equations: a two-domain component)

    Pin p, n; Flange flange (armature), support
    L(g)   = L_inf + L_0 * g_0 / (g + g_0)        # inductance rises as the gap closes; g = g_max - x
    psi    = L(g) * i                             # flux linkage, the electrical state
    v      = R * i + der(psi)
    f      = 0.5 * i^2 * dL/dx                    # energy-consistent magnetic force, toward closing the gap

`R = 12 Ω` (Bosch EV14). Choose `L_inf`, `L_0`, `g_0` (assumed) so that the electrical time
constant is 0.3–0.6 ms and the opening dead time lands in the anchor band.

### `FuelInjector` (assembly)

    Pin p, n; RealInput p_rail_diff; RealOutput mdot_f, lift
    Solenoid -> needle Mass (m = 3e-3 kg, assumed) + return Spring with preload (assumed)
             -> two ElastoGap stops: seat at lift 0, armature stop at lift 0.06 mm (deck: 0.05 mm)
    mdot_f = C_d * min(pi * d_seat * lift, A_orifice) * sqrt(2 * rho_f * p_rail_diff)

Size `A_orifice` so that full lift at 3 bar gives 146 cm³/min (Bosch EV14).

### Lecture2 harness: `InjectorPulse`

Battery `VoltageSource` from a constant `U_batt`, low-side switch as a `VariableResistor` driven
by a pulse (`R_on = 0.1 Ω`, `R_off` per decision D4), `p_rail_diff = 3e5`. Outputs current,
lift, cumulative fuel (an integrator). Forward `U_batt`, `t_pulse`.

## Vehicle/Engine + Vehicle/ECU — exhaust, λ sensors, catalyst, λ control (task 5)

**Refs:** teaching materials §3.7 (MathWorks `sldemo_fuelsys`: tanh EGO, ±0.5 error, 14.6 target,
https://www.mathworks.com/help/stateflow/ug/model-a-fault-tolerant-fuel-control-system.html),
§3.8 (Brandt, Wang & Grizzle catalyst, https://grizzle.robotics.umich.edu/files/twc_conf.pdf;
copy the exact equations from the PDF, since the extraction was garbled), §4 (Bosch LSU 4.9
table); deck slides 57–59 (`image75.png`, `image76.png`, `image77–79.jpeg`).

### `ExhaustTransport`

A `SpeedScheduledDelay` on λ from cylinder to the upstream sensor location.
`phi` ≈ 540° crank (exhaust stroke after the power stroke, assumed), `theta_0` chosen so that the
total injection-to-sensor delay is 0.15–0.35 s at idle and 0.04–0.10 s at 3000 rpm (assumed).

### `LambdaSensorSwitching` (new equations)

    RealInput lambda; RealOutput V
    V_static = V_lean + (V_rich - V_lean) / 2 * (1 + tanh((1 - lambda) / w))
    first-order lag tau_s on V
    V_rich = 0.9 V, V_lean = 0.1 V (deck slide 58), w = 0.005 so the switch spans λ 0.98–1.02 as
    on slide 58 (derived), tau_s = 0.07 s (assumed)

### `LambdaSensorWideband`

The LSU 4.9 table (pump current vs λ, teaching materials §4) as an `Interpolation` producing the
pump current, then the inverse table giving the ECU's λ estimate, plus a first-order lag
(tau = 0.1 s, assumed). The two-stage form shows that the sensor measures current, not λ.

### `Catalyst` (new equations; Brandt et al.)

    RealInput lambda_in, mdot_exh; RealOutput lambda_out, theta
    theta in [0, 1], fraction of oxygen storage sites occupied: a limited integrator
    lean: der(theta) = (oxygen excess flow) * alpha_L * f_L(theta) / C, stops at 1
    rich: der(theta) = (oxygen deficit flow) * alpha_R * f_R(theta) / C, stops at 0
    lambda_out = 1 + (lambda_in - 1) * (1 - stored fraction)

Copy the exact form of the excess-flow term and of `f_L`, `f_R` from the PDF. `C`, the oxygen
storage capacity, is (assumed) 0.5 g O₂; release is faster than storage (Brandt). The limited
integrator uses `ifelse` clamps, not events.

### `Vehicle/ECU/TwoStepLambdaController` (new equations)

    RealInput V_sensor; RealOutput lambda_trim
    s           = tanh((V_sensor - V_ref) / eps_V)       # +1 rich, -1 lean; V_ref = 0.45 V
    der(F_I)    = -k_ramp * s
    lambda_trim = 1 + F_I - k_jump * s + (shift term, decision D2)

Defaults `k_jump = 0.03`, `k_ramp = 0.05 /s` (assumed, tuned for ±2–3 % λ at idle, deck slide 57).
Expose `k_jump`, `k_ramp` and the rich/lean shift.

### `Vehicle/ECU/WidebandLambdaPI` and `Vehicle/ECU/PostCatTrim`

- `WidebandLambdaPI`: `BlockComponents.Continuous.LimPID` on λ_meas with setpoint 1, output
  `lambda_trim` clipped to 0.8–1.2. A Smith-predictor variant is a stretch goal.
- `PostCatTrim`: a slow integrator on the downstream switching sensor that shifts the two-step
  controller (or the wideband setpoint) to keep the catalyst `theta` near 0.5. Slide 57 fig. b
  and slide 59.

### Lecture2 harness: `LambdaLoop`

`EngineDyno` at a forwarded `omega_set` and `u_thr`, `FuelMetering` → `MeanValueEngine` →
`ExhaustTransport` → `LambdaSensorSwitching` → `TwoStepLambdaController` → back to
`FuelMetering.lambda_trim`; catalyst and downstream sensor in series. Structural switches select
two-step vs wideband PI and post-cat trim on/off. A purge disturbance (EVAP, slide 56) adds a fuel
mass-flow step of 8 % of the operating fuel flow (assumed) into the cylinder at a forwarded time.

## Vehicle/Engine — single cylinder, crank angle (task 6)

**Refs:** teaching materials §3.6 (Wiebe; a, m not verified from an open source); MIT OCW 2.61
(https://ocw.mit.edu/courses/2-61-internal-combustion-engines-spring-2017/, cycle analysis);
deck slides 20–22 (p–V) and 50 (`image62.png`).

### `SingleCylinder` (new equations; plan S1, a separate time scale)

    parameters: bore 74.5 mm, stroke 85.8 mm, conrod 140 mm, r_c = 10.5 (assumed, 1.5 L class);
                gamma = 1.3 (textbook); Wiebe a = 5, m = 2, burn duration 50° (textbook, unverified);
                t_ign = 1 ms ignition delay (assumed); f_wall = 0.2 heat-loss fraction (assumed)
    inputs as parameters: omega, sigma (deg BTDC), p_ivc, lambda
    theta(t) = -pi + omega * t                       # crank angle from BDC; simulate BDC -> BDC
    V(theta) = slider-crank volume
    combustion start = -sigma + omega * t_ign (in crank angle)
    x_b(theta) = Wiebe, Q_tot = (1 - f_wall) * m_f * H_l
    dp/dt = (gamma - 1)/V * dQ/dt - gamma * p / V * dV/dt
    outputs: p, V, x_b, W_i = integral of p dV, IMEP, theta at p_max, max dp/dtheta (knock proxy)

The fixed ignition delay in *time* is what makes MBT advance with speed. A burn duration fixed
in crank degrees alone would not. Valve events are simplified away (the closed part runs BDC to
BDC); say so in the docstring.

### Lecture2 analysis: `SparkSweep`

Runs `SingleCylinder` across `sigma` at a forwarded speed and load; also motored (`lambda` → no
fuel) for the compression check.

## Vehicle/ECU — idle speed control (task 7)

**Refs:** teaching materials §3.9 (Di Cairano et al. 2008,
https://skoge.folk.ntnu.no/prost/proceedings/cdc-2008/data/papers/0604.pdf: 650 rpm reference,
[450, 2000] rpm constraint, ≈ 15° spark reserve, delays 0.12 s air and 0.03 s spark); Lecture 1
PID components (`dyad/Lecture1/CruiseLoop.dyad`, `ClampingPID.dyad`).

### `IdleSpeedController`

Two paths from the speed error: air (`LimPID` → `u_thr` in a bypass range 0–0.1) and spark
(proportional, possibly with a derivative term, around `sigma_idle = sigma_mbt - reserve`,
`reserve = 12°`, clipped to ±12°). Expose all gains, the reserve and `with_spark`.

### Lecture2 harness: `IdleLoop`

Free-running `MeanValueEngine` (no vehicle) with `FuelMetering` at λ = 1, an accessory load as a
`TorqueSource` on the spline: an A/C compressor step of 8 N·m (assumed) at t = 2 s, removed at
t = 6 s. Forward the load and controller gains.

## Lecture 2 road load (task 8)

**Refs:** deck slides 16–18; existing `dyad/Vehicle/VehicleBody.dyad`; drive cycles from
EPA (public domain, https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules)
and WLTC class 3b from DieselNet (https://dieselnet.com/standards/cycles/wltp.php); stdlib
`BlockComponents/Tables/Interpolation.dyad` with a file source (see
`BlockComponents/Tables/Tests/InterpolationFile.dyad`).

- `Vehicle/RoadLoadMeter`: from the body velocity and the body's parameters, compute and
  integrate the power of each resistance (drag, rolling, grade, inertia `m·a·v`) and an
  auxiliary power `P_aux = 500 W` (assumed). Do not edit `VehicleBody`.
- `Lecture2/DriveCycle`: `CarPlant` (unchanged) tracking a speed trace from
  `data/drive_cycles/<cycle>.csv` through a `LimPID` driver. Store cycle files with a header
  comment naming the source URL.

## Ignition coil and knock (task 9)

**Refs:** deck slides 47–55 (`image62–67`); stdlib
`ElectricalComponents/Analog/Basic/{Transformer,MTransformer,Inductor,Capacitor,VariableResistor}.dyad`;
teaching materials §3.11 (knock control: retard fast, advance slowly).

- `Vehicle/Engine/IgnitionCoil`: battery → primary `Transformer` winding (R_p = 0.5 Ω,
  L_p = 3 mH, turns ratio 1:80, all assumed) → low-side switch (`VariableResistor`) driven by a
  dwell pulse. Secondary: winding capacitance 50 pF (assumed) and a spark-gap element
  (decision D4) that breaks down at 10–15 kV (assumed). Outputs primary current, secondary
  voltage, stored energy `0.5 * L_p * i^2`.
- `Vehicle/ECU/KnockControl`: knock is present while `sigma > sigma_kl(omega, p_m)` (an assumed
  knock-limit table below MBT at high load and low speed). While knocking, retard at
  `k_ret = 30 °/s`; otherwise re-advance at `k_adv = 0.5 °/s` up to zero retard. The result is a
  sawtooth around the knock limit, the same jump/ramp shape as the λ controller.

## Sensors (task 10)

**Refs:** teaching materials §4 (Bosch NTC M12 table, Bosch LSU 4.9 table); deck slides 36–37;
stdlib `ThermalComponents/Components/{HeatCapacitor,ThermalConductor,Convection}.dyad`.

- `Vehicle/Engine/NTCSensor`: Bosch NTC M12 R(T) table (2 500 Ω at 20 °C) → divider with a pull-up
  `R_pu = 2.5 kΩ` from 5 V (assumed; the datasheet says 1 or 3 kΩ is typical) → output voltage;
  sensor thermal lag through a small `HeatCapacitor` (tau ≈ 10 s, assumed).
- `Vehicle/Engine/HotFilmMAF`: a film `HeatCapacitor` (free time constant ~ 10 ms, assumed)
  cooled by King's-law convection `h = a + b * sqrt(mdot)` (assumed) and held at a constant
  over-temperature (150 K, assumed) by a PI controller; output is the heating power, mapped back
  to mass flow by the inverse King's law. A constant-power (open-loop) variant shows why the
  sensor runs closed loop.

## Cooling and warm-up (task 11)

**Refs:** deck slides 27–28; stdlib ThermalComponents as above.

- `Vehicle/Engine/CoolingCircuit`: block `HeatCapacitor` (100 kg × 500 J/(kg·K)), coolant
  `HeatCapacitor` (5 kg × 3600 J/(kg·K)), heat input = 30 % of fuel power (all assumed), wax
  thermostat as a conductance ramping from 0 at 88 °C to full at 95 °C, radiator to ambient, fan
  with hysteresis (on at 100 °C, off at 95 °C), as a continuous latch.
- `Vehicle/Engine/CatalystThermal`: catalyst `HeatCapacitor` heated by exhaust; exhaust heat
  rises as spark is retarded (fraction of fuel power to exhaust rises with
  `sigma_mbt - sigma`, assumed linear). Light-off at 250–300 °C (textbook).

## Capstone (task 12)

**Refs:** deck slides 24–25 and 28; `dyad/Vehicle/CarPlant.dyad` (the shape to mirror);
`docs/lecture-01-plan.md` and `notebooks/lecture01/01-the-car.ipynb` cell 4 (the "246 km/h is too
high" hook this resolves).

- `Vehicle/ECU/TorqueStructure`: pedal (0–1) → torque demand `pedal * tau_wot(omega)` (from the
  task 2 map) → throttle setpoint through an inverse map plus a small PI on torque estimate;
  spark at MBT; overrun fuel cut; rev limiter cutting fuel at 6500 rpm and resuming at 6300 rpm
  (continuous latch).
- `Vehicle/EngineCarPlant`: `MeanValueEngine` + `FuelMetering` + `TorqueStructure` +
  `Driveline` (`i = 4`, unchanged) + `VehicleBody` + speed sensor + `ToKmPerHour`. Same port
  names as `CarPlant` where meaning matches (`grade`, `v_kmh`, `v`), with `pedal` replacing
  `tau_cmd`.
- `Lecture2/EngineCruise`: the Lecture 1 `CruiseLoop` controller around `EngineCarPlant`
  (controller output → `pedal`).

## Decisions delegated to you

**D1: lag-chain order `n` in `SpeedScheduledDelay`.** High enough that the phase error at the λ
limit-cycle frequency is under 10° against a `PadeDelay` of the same delay; low enough not to
stiffen the model. Report the phase error at 1 Hz and 4 Hz for your choice. Lean towards 6–10.

**D2: two-step controller smoothing and shift.** Choose `eps_V` small enough that halving it
changes limit-cycle period and amplitude by under 2 %. Implement the rich/lean shift either as
asymmetric jumps or as the slide 57 dwell time `t_v`. Lean towards asymmetric jumps, and describe
the dwell equivalent in the docstring, because a dwell needs a timer latch.

**D3: which knob closes the torque gap.** Land the WOT torque and peak-efficiency anchors with
`k_f`, `eta_i` and the `eta_v` peak, each inside a defensible range. Report the three values and
the resulting peak torque, peak efficiency and min BSFC.

**D4: switch-off and spark-gap elements.** No ideal switch, diode or Zener exists in
`ElectricalComponents`. For the injector driver, choose `R_off` so that the flyback clamps near
60–80 V (a real driver's Zener clamp), and report the clamp voltage and the dropout time. For the
spark gap, a `VariableResistor` whose resistance drops from open to an arc value when
`|v| > V_breakdown` and latches until the current decays. Keep both stiff-solver-friendly and
say which solver you used.

## Acceptance criteria

Verify each numerically and report the number. Bands are in the plan's reality-anchor table.

**Task 1 (air path).** Idle 800 rpm closed throttle: `p_m` 30–36 kPa. WOT: `p_m` > 90 kPa.
Overrun at 3000 rpm: `p_m` below idle, 17–34 kPa. Step-response time constant 0.08–0.2 s at
800 rpm and 0.02–0.05 s at 3000 rpm. `mdot_thr` never negative while choked.

**Task 2 (mean-value engine), the gate for Tier 1.** *Verify this first*: `LinearAnalysis` (or a
step fit) at idle, 2000 and 4000 rpm shows the throttle-to-torque time constant falling with
speed, and the induction-to-power delay equals 180° of crank at each speed within 5 %. Then the
map: peak torque 130–150 N·m; peak brake efficiency 33–38 %; min BSFC 225–260 g/kWh; torque
loss 2–5 % at 10° retard; zero torque on fuel cut; idle fuel 0.4–0.9 L/h. Notebook 03's whole
argument rests on the first check.

**Task 3 (fuel path).** Tip-in at 2000 rpm, warm, no compensation: a lean excursion in
`lambda_cyl` of at least 5 %. With compensation and exact estimates (`Xh = X`, `tauh = tau_f`):
under 1 %. Cold engine without compensation: a larger excursion than warm. The slide 44 map
reproduces its own cells within 0.05 AFR at the grid points.

**Task 4 (injector).** Opening dead time 0.6–1.0 ms at 14 V and 1.5–2.5 ms at 8 V; needle lift
saturates at the stop; static flow 146 cm³/min ±5 % at 3 bar; the fuel-vs-pulse-width
characteristic is linear above about 2 ms with an offset equal to the dead time; the current trace
shows the pickup kink of slide 45. Report the flyback clamp voltage.

**Task 5 (λ loop), the gate for notebook 06.** *Verify first*: the two-step loop limit-cycles,
with λ excursion ±2–3 % at idle, frequency 0.5–5 Hz, and frequency higher at 3000 rpm than at
idle. Then: halving `eps_V` changes period and amplitude by under 2 %; with the catalyst,
`theta` stays inside (0.2, 0.8) and the downstream sensor does not switch under the limit cycle; a
sustained 5 % lean bias saturates `theta` and the downstream sensor switches; post-cat trim
restores `theta` toward 0.5; the purge step is rejected and λ returns within ±1 % in under 3 s.
The wideband PI holds λ within ±1 % in steady state.

**Task 6 (single cylinder).** Motored: peak pressure equals `p_ivc * r_c^gamma` within 1 % and net
loop work is zero within 1 % of gross compression work. Fired at MBT: peak pressure 12–20° ATDC;
indicated efficiency below the ideal Otto `1 - r_c^(1-gamma)`. MBT advance at 4000 rpm exceeds
MBT at 1500 rpm. Over-advanced by 15°: higher and earlier peak; retarded by 15°: lower peak after
TDC (deck slide 50 shapes).

**Task 7 (idle).** With an 8 N·m step, speed never falls below 450 rpm in either configuration;
air plus spark at least halves the speed dip compared with air alone; speed recovers to within
25 rpm of setpoint in under 3 s.

**Task 8 (road load).** Over the cycle, the sum of the term energies equals the tractive
energy within 1 %; driver tracking error under 2 km/h RMS; at steady 130 km/h drag exceeds
rolling resistance by more than 3×, at 50 km/h by less than 1.5×.

**Task 9 (coil, knock).** Dwell 2–4 ms at 14 V gives primary current and stored energy within
the plan's band; open-circuit secondary peak 20–40 kV; peak secondary voltage rises with dwell.
Knock controller settles into a sawtooth whose mean is within 2° of the knock limit.

**Task 10 (sensors).** NTC output matches the Bosch table at −20, 20 and 100 °C within 1 %
(resistance) and is monotonic. Closed-loop MAF responds to a flow step at least 5× faster than
the constant-power variant.

**Task 11 (cooling).** Coolant 20 → 90 °C in 4–10 min at light load; thermostat holds 85–95 °C;
spark retard reaches catalyst light-off sooner (report by how much).

**Task 12 (capstone).** WOT on flat road: terminal speed is rev-limited or torque-curve-limited
and below 200 km/h (expected ≈ 190 km/h at 6500 rpm with `i = 4`, `r = 0.31 m`), with the
rev-limiter cycle visible. The Lecture 1 cruise step 90 → 110 km/h with Lecture 1 gains runs
and is reported against the Lecture 1 result.

## Build order

    1. AirPath                                   (also completes brake plan 2a)
    2. SpeedScheduledDelay, TorqueProduction, MeanValueEngine, EngineDyno, maps   -> GATE
    3. WallWetting, FuelMetering, TipInTest
    4. Solenoid, FuelInjector, InjectorPulse     (independent; may run in parallel with 1-3)
    5. ExhaustTransport, λ sensors, Catalyst, λ controllers, LambdaLoop           -> GATE
       --- Tier 1 is safe from here ---
    6. SingleCylinder, SparkSweep                (independent; may run in parallel)
    7. IdleSpeedController, IdleLoop
    8. RoadLoadMeter, DriveCycle
    9. IgnitionCoil, KnockControl
    10. NTCSensor, HotFilmMAF
    11. CoolingCircuit, CatalystThermal
    12. TorqueStructure, EngineCarPlant, EngineCruise
