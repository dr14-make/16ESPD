# Dyad agent brief — Roadster hands-on: is it physically possible?

Spec for issue #64. In one short hands-on session, students take the claims from Tesla's
2026-10-15 Roadster demo, build a small Dyad model for each, and reach a yes or no. Sources and
the back-of-envelope numbers are in `docs/research_notes/Roadster plausibility/sources.md`.

## Read before the first compile

1. `agent_resources/skills/dyad-language/SKILL.md`, then from `agent_resources/docs/` read
   `syntax.md`, `components.md`, `initialization.md`, `metadata.md` (test blocks) and
   `analyses.md`.
2. `docs/HANDOVER.md` § "Gotchas found during the build". The three that bite hardest:
   - A `.dyad` edit does nothing until `npx -y @juliacomputing/dyad-cli@3.5.0 compile .`
     regenerates `generated/`.
   - The suite must run from `test/`.
   - A model with an unconnected `RealInput` cannot be a `TransientAnalysis` model.
3. `docs/lecture-01-dyad-tasks.md` § "Parameter forwarding" and § "Harnesses and analyses".
4. The draft from commit f5c0990: `dyad/Roadster/` and `dyad/Vehicle/Wheel/LoadedSlipWheel1D.dyad`.

## The session

The core is one launch story in three layers on the same 1D car: tires, then suction, then thrust.
Each layer adds one component, so students see which layer makes which claim possible. Tesla's
trims follow the same order: Performance (fans, under 1.6 s), Thrust (adds rear thrusters, under
0.9 s) and Rocket (10 thrusters, under 0.59 s). The session ends with "can it fly?".

| Step | Claim | Verdict the models should reach |
| --- | --- | --- |
| 1 | 0–60 mph in under 1 s on tires | No. About 2.2 s with all-wheel drive and about 3.3 s with rear-wheel drive. The tire limits, not the 1 MW drive |
| 2 | Suction gives under 1.6 s and holds the car upside down | Yes. The limit moves from the tire to the drive's torque. The fan power depends strongly on the skirt gap |
| 3 | Rear thrust gives 0.81 s | Yes, at a cost in air |
| 4 | "It can fly" | No: hops and seconds of hover, then the tank is empty |

## Layout

    dyad/Vehicle/Wheel/   LoadedSlipWheel1D, which a later lecture could reuse unchanged
    dyad/Roadster/        everything that exists for this session: drive, axle load, fan, tank,
                          nozzle, harnesses and analyses
    test/roadster_plausibility.jl   closed-form checks, included from test/runtests.jl

Reference components fully qualified, e.g. `VehicleSystemsComponents.Roadster.AxleLoad`.

## Ground rules

- **Compose the standard library; write equations only where nothing exists.** Stdlib source is
  at `agent_resources/stdlib_reference/<Library>/<Path>.dyad`.
- **Never edit `generated/` by hand, and never change a component outside `dyad/Roadster/` and
  `LoadedSlipWheel1D`.** Lecture snapshots depend on the existing ones.
- **The defaults are the baseline car:** 2,000 kg, μ = 1.26 (Tesla's own tire figure), 1 MW,
  12,000 N·m at the wheels (1,400 N·m × an assumed 8.5:1 reduction), r = 0.35 m and C_dA = 0.6 m².
  Tesla published neither the mass nor the reduction ratio. Any parameter you add carries its
  source or "assumed" in its docstring.
- **Every model has a Dyad test component, and every verdict has a closed-form check** in
  `test/roadster_plausibility.jl`.
- **Do not move an acceptance band.** If a result misses, report it and say why.
- **Keep the analyses fast.** A student runs each one live, so each should finish in a few
  seconds once compiled.

## Task 1 — Validate the tire-only launch (draft exists)

The draft in f5c0990 is unreviewed. Treat it as a proposal: verify it, and change whatever is
wrong. Any change goes in its own commit, with the reason in the commit body.

**What exists.**
- `PowerLimitedMotor`: `min(tau_cmd, T_max, P_max / max(w, w_eps))`, referred to the wheels.
- `AxleLoad`: driven-axle load `share·(m·g + downforce) + m·a_pitch·h/L`. The term `a_pitch`
  lags the acceleration by `T_pitch = 0.1 s`. Without the lag, the solver solved the load equation
  for `a` and divided by zero when `h_over_L = 0`.
- `LoadedSlipWheel1D`: `SlipWheel1D` with `F_z` taken as an input.
- `RoadsterLaunch`: ideal traction control requests `grip·mu_A·F_z·r` with `grip = 0.98`.
- `RoadsterLaunchTransient`.

**Review these and state a verdict on each.**
- Sign conventions of the motor, wheel and axle load against the stdlib.
- **Traction control reads `F_z` directly.** That is an idealization ("perfect traction
  control"). Is it acceptable for teaching, or should it be a slip controller?
- Whether 0.1 s is a defensible pitch lag.
- The wheel inertia of 2.4 kg·m², μ_S = 1.0, and C_dA = 0.6.
- **Rolling resistance ignores downforce.** It will matter in task 2.
- Whether lumping the motor and reduction into one wheel-torque source hides anything students
  need.

**Add.**
- A test component with Dyad test cases.
- Julia checks in `test/roadster_plausibility.jl`, included from `runtests.jl`.

**Acceptance.** Measure the 0–60 mph time t60 by interpolating where `v` crosses 26.8224 m/s.

| Check | Closed form | Band |
| --- | --- | --- |
| All-wheel drive (`share = 1`, `h_over_L = 0`) | 26.8224 / (0.98·1.26·g) = 2.215 s, without drag or wheel inertia | 2.20–2.35 s |
| Rear-wheel drive (defaults) | a/g = 0.98·1.26·0.55 / (1 − 0.98·1.26·0.17) = 0.860, so 3.18 s | 3.15–3.45 s |
| Mass sweep, 1,700 to 2,350 kg | A tire-limited launch is nearly independent of mass | t60 spread under 3 % |
| Drive power at 26.82 m/s, all-wheel drive | 24.2 kN × 26.82 m/s = 650 kW | Under 1 MW: the tire is the limit at 60 mph, not power |
| Slip | Held at peak adhesion | `kappa` stays within 0.02–0.05 after the first 0.1 s |

**Report.** Every number above, each review verdict, and every change you made with its reason.

## Task 2 — Suction fan and the suction launch

**Build `Roadster.SuctionFan`.** It holds an underbody pressure drop and reports the cost.

- **Input:** `cmd`, 0 to 1.
- **Pressure drop:** the target is `cmd·dp_max`, reached through a first-order lag `T_fan`,
  0.3 s (assumed).
- **Output:** `downforce = dp·A_floor`.
- **Leakage under the skirt:** `Q = C_d·perimeter·gap·√(2·dp/ρ)`.
- **Fan power:** `P = Q·dp/η`.
- **Defaults:** `A_floor = 4.0 m²`, `perimeter = 10 m`, `gap = 3 mm`, `C_d = 0.6` and
  `η = 0.6`, all assumed. `dp_max` is sized to the 4,700 kgf readout.

**Wire the fan into the launch.** Its downforce feeds `AxleLoad.downforce`. Keep `RoadsterLaunch`
the single launch car: with `cmd = 0` it must reproduce task 1 exactly. Start the fan at its
target before the launch, because the car sits on suction before it moves. Decide whether
downforce loads the rolling resistance, and say so.

**Add an inverted-hold test component** for the fan alone: the downforce against the car's weight
with gravity reversed.

**Acceptance.**

| Check | Closed form | Band |
| --- | --- | --- |
| `dp` at 4,700 kgf | 4,700·g / 4.0 = 11,523 Pa | Within 0.5 % |
| Fan power at full suction, 3 mm gap | Q = 2.49 m³/s, so P = 47.9 kW | Within 2 % |
| Fan power at full suction, 10 mm gap | 159.7 kW | Within 2 % |
| Least `dp` to hang the 2,000 kg car upside down | m·g / A = 4,903 Pa, costing 13.3 kW at 3 mm | Within 2 % |
| Launch at full suction, both drive layouts | The tire limit rises to about 4.1 g (all-wheel drive). The binding limit becomes the drive torque: 34.3 kN, 1.75 g, so 1.56 s | 1.5–1.7 s for both layouts. Report which limit binds over the run |
| Sweep `T_max` from 12 to 20 kN·m | Raising it moves the limit back to power and the tire | Report t60 against `T_max` |

**Report.** The numbers, and in one paragraph the teaching point: suction moves the limit from
the tire to the drive.

## Task 3 — Cold-gas tank and nozzle (independent of tasks 1 and 2)

**Build `Roadster.AirTank`.** A fixed volume holding air mass `m_g`.

- **Pressure:** polytropic blowdown, `p/p0 = (m_g/m0)^n` and `T/T0 = (m_g/m0)^(n−1)`, from an
  ideal-gas start.
- **Index:** `n = 1.4` (adiabatic) by default. Setting `n = 1` gives isothermal, so students can
  compare the two bounds.
- **Defaults:** `V = 0.6 m³` (Tesla), `p0 = 380 bar` (the 5,500 psi in-car readout) and
  `T0 = 293.15 K`.
- **Port:** expose the tank state to the nozzle. If the stdlib has no fitting compressible-gas
  connector, a pair of signals is fine; state which you used.

**Build `Roadster.ColdGasNozzle`.** It is a choked orifice with ideal expansion.

- **Valve:** input `cmd`, 0 to 1, which scales the throat area.
- **Mass flow:** `ṁ = cmd·A_t·p·√(γ/(R·T))·(2/(γ+1))^((γ+1)/(2(γ−1)))`.
- **Exhaust speed:** `v_e = η_n·√(2·c_p·T·(1 − (p_a/p)^((γ−1)/γ)))`.
- **Thrust:** `F = ṁ·v_e`, applied at a translational flange.
- **Low pressure:** below p/p_a = 1.893 the flow is no longer choked. Either model the subsonic
  branch or close the valve below 2 bar. Choose one and document it.
- **Sizing:** size `A_t` so thrust is 80 kN at full tank (`η_n = 1`):
  A_t = 1.286e-3 m², about 20 mm diameter for each of 4 rear nozzles.

**Add `AirTank` + `ColdGasNozzle` test components** with a fixed thrust stand.

**Acceptance.**

| Check | Closed form | Band |
| --- | --- | --- |
| Initial air mass | p0·V / (R·T0) = 270.9 kg, ideal gas. Real gas holds about 250 kg; note it, don't model it | Within 0.5 % |
| Initial thrust | 80 kN | Within 1 % |
| Initial ṁ and v_e | 115.4 kg/s and 693 m/s (Isp 70.7 s) | Within 1 % |
| Pressure at half mass, `n = 1.4` | 0.379·p0 | Within 1 % |
| Total impulse, open until choking ends | 146.6 kN·s by quadrature, using 264.8 kg | Within 2 % |
| `n = 1` against `n = 1.4` | Isothermal gives more impulse | Report both |

## Task 4 — Thrust launch and "can it fly?" (needs tasks 2 and 3)

**Thrust launch.** Add the tank and the rear nozzles to `RoadsterLaunch`, pushing the body
forward. The valves open at t = 0 (pre-spooled). With the valves closed, the car must reproduce
the task 2 result exactly. Run three configurations at 2,000 kg:
- tires + thrust
- tires + suction + thrust
- all three with a 200 L tank, Electrek's split for the Thrust trim

Report t60 and the air used to 60 mph for each.

**Rear thrust passes both limits.** It acts on the body directly, so it adds acceleration
whether the tire or the drive torque is binding. The second configuration should show this:
suction leaves the launch limited by torque at 1.75 g, and rear thrust then adds about 4 g on top.

**Down or back: the split question.** A plume over the roof suggests air pushing the car down for
grip. Add a parameter `down_fraction`, from 0 to 1:
- **Down:** that fraction of the thrust pushes the car down, entering `AxleLoad.downforce`.
- **Back:** the rest pushes the car forward.

Sweep it from 0 to 1 in four cases: rear-wheel and all-wheel drive, each with suction off and
with full suction. In each case, report t60 against `down_fraction`, the best split, and why.

Closed-form expectations at t = 0:
- **Pushing down helps only while the tire is the limit, and only if each newton gains more than
  one newton of drive.**
  - Rear-wheel drive gains 0.98·1.26·0.55 / (1 − 0.98·1.26·0.17) = 0.86 N per newton pushing
    down. Pointing all the air backward is therefore always best: `down_fraction = 0`.
  - All-wheel drive gains 1.23 N per newton, but only until the drive-torque cap. That takes
    (34.3 − 24.2) kN / 1.23 ≈ 8 kN of downward thrust. Beyond it, the downward air is wasted, so
    the best split is near 0.1 and the gain is a few percent at most.
  - With full suction, the drive torque binds from the start, so `down_fraction = 0` is best for
    both layouts.
- **The model assumes the thrust line passes at center-of-mass height,** so thrust moves load
  only through the acceleration term. State this; do not model the pitch moment.

**Build `Roadster.VerticalHop`.** A vertical 1D model for "can it fly":
- **Body:** the car's mass with gravity.
- **Ground:** a ground contact (a unilateral spring-damper; follow the `ElastoGap` stdlib
  component).
- **Thrust:** the tank and four downward nozzles pushing up. Size them so full thrust matches
  the rear set.

**Add two analyses to `VerticalHop`.**
- **Hop:** open-loop full thrust for a burn time `t_b`, then the valves close. Find the `t_b` that
  gives an 8 m apex (the kickflip), and report the air used.
- **Hover:** a PI altitude controller drives the valve to hold 2 m from a standing start. Run it
  until the valve saturates and altitude is lost, and report the hover time.

**Acceptance.**

| Check | Closed form or estimate | Band |
| --- | --- | --- |
| Tires + thrust, initial acceleration | (F_tire + 80 kN) / m | Within 2 % at t = 0+ |
| t60, tires + thrust | Average 3.4 g gives 0.81 s (Tesla, live) | Report it and compare with 0.81 s |
| t60, all three | Rocket trim claims under 0.59 s | Report it and compare |
| t60, tires + suction + thrust | (34.3 kN + 80 kN) / m = 5.8 g at the start, fading as the tank empties | About 0.5–0.6 s. Report the binding limits |
| Best `down_fraction` | 0 for rear-wheel drive in both suction cases. Near 0.1 for all-wheel drive without suction. 0 with full suction | Matches in every case. Report the t60 curves |
| Hop to 8 m | v_z = √(2·g·8) = 12.5 m/s | 40–70 kg of air |
| Hover time, 2,000 kg, 600 L at 380 bar | ṁ ≈ m·g / v_e ≈ 30–35 kg/s at the start, rising as v_e falls | 3–8 s. Report it, plus the sweep over mass (1,700–2,350 kg) and p0 (300–690 bar) |

**Report.** The verdicts for steps 3 and 4, in one sentence each, with the numbers behind them.

## Not for the Dyad agent

- **Warm-up free-fall fit.** It needs frame-by-frame positions from Tesla's ramp video, which
  this repo does not have yet.
- **Hands-on guide and deck.** These come after the models settle, following
  `slides/CONTEXT.md`.
- **Kickflip roll budget.** Speaker notes only: about 5–10 kg of air at the measured 177°/s.
