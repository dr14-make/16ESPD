# Lecture 1 — Control Systems: Introduction and PID

One car, three fidelity levels, ten notebooks. Every control idea is introduced as a change to
the *controller*, never as a change of subject: the plant stays the same vehicle throughout, so
students carry one mental model from open-loop coasting to cruise control on black ice.

## Source material

| Source | Used in |
|---|---|
| `1.EverythingYouNeedtoKnowAboutControlTheory.md` | 02 |
| `2.PIDUnderstanding.md` | 03, 04, 05 |
| `3.PIDIntegral.md` | 06 |
| `4.PIDDerivative.md` | 07 |
| `5.PIDTunning.md` | 08 |
| `6.PIDBuildingamodel.md` | 01 (first-principles / white-box modeling only) |
| `7.PIDTUnningMethods.md` | 08 (the saturation trap only; loop shaping and pole placement deferred) |
| `8.DiscreetControll.md` | 09 (discrete half only; cascade deferred) |
| `tuning_methods.pdf` | 08 (Cohen-Coon, Ziegler-Nichols, Tyreus-Luyben tables) |
| `2. Engine CS.pptx` slides 2-7, 12-17 | 01, 02, 08 |
| `2. Engine CS.pptx` slides 19-59 | lecture 2 |

## Scope

In: the control panorama, open vs closed loop, P, PI, PID, integral windup, derivative and
noise, the step test, heuristic tuning, actuator saturation, discretization, and wheel slip.

Deferred to lecture 2: cascade control, loop shaping, pole placement, system identification,
linearization, and the engine-control half of the deck.

## Delivery

Driven live from the projector. Every notebook is committed with its outputs already executed,
which serves three purposes: students get a readable artifact rather than empty cells, anyone
with Dyad can re-run it, and a stalled solve in front of the room falls back to a plot that is
already on screen.

Prose in English. SI internally, km/h on the axes.

## The model ladder

### L0 — longitudinal car (notebooks 01-09)

    T_cmd -> transport delay 0.04 s -> first-order lag 0.3 s -> limit [0, 150 N.m]
          -> gear ratio 4.0 / wheel radius 0.31 m -> tractive force

    body:  m = 1400 kg
           aerodynamic drag   0.5 * rho * CdA * v^2,  CdA = 0.63 m^2, rho = 1.2 kg/m^3
           rolling resistance f_r = 0.012, regularized near v = 0
           grade              m * g * sin(alpha),  alpha a time-varying input

### Why the engine lags are not optional

An ideal engine — torque available instantly, merely capped — makes the plant first order, and
that breaks the lecture in three places:

- **Ziegler-Nichols becomes impossible.** It requires sustained oscillation under pure
  proportional gain. A first-order plant reaches 90 degrees of phase lag and a second-order one
  never crosses 180, so no value of Kp will ever make it oscillate. Slide 15's practical task
  could not be performed.
- **Cohen-Coon degenerates.** It fits a FOPTD model — first order *plus time delay*. With no
  dead time, theta goes to zero and the tuning formulas fall apart.
- **The derivative has nothing to do.** Without phase lag there is little overshoot to tame, and
  the punchline of the PID story lands flat.

Both lags are physically real: manifold filling is a first-order lag of a few tenths of a
second, and injection-to-torque is a transport delay of roughly one engine cycle. Including
them makes the car FOPTD by construction, and every demo then works on a single model.

### L1 — with wheel (notebook 10)

Adds wheel inertia and an ideal rolling wheel between driveline and body.

### L2 — with slip (notebook 10)

Replaces ideal rolling with a slipping contact:

    slip ratio   kappa = (omega * r - v) / max(|v|, eps)
    contact      F_x = mu(kappa) * F_z

`mu(kappa)` uses the adhesion/sliding shape already established by Dyad's multibody
`SlipWheelJoint` (`sAdhesion`, `sSlide`, `mu_A`, `mu_S`) so it is a recognized model rather
than an invented one, with a road-friction scale exposed as an input.

### Scenarios

Two scenarios carry the whole lecture:

- **Setpoint step 90 -> 110 km/h** — P, PI, PID, and the step test.
- **10% climb at 130 km/h** — windup. At these parameters the car genuinely runs out of torque
  and falls back, so saturation has a cause a student can compute rather than a number that was
  chosen to make a point.

Exact parameter values will be trimmed during the build so each scenario fires cleanly rather
than nearly fires.

## The notebooks

| # | Title | Punchline | Tier |
|---|---|---|---|
| 01 | The car | transient vs steady state; read K, tau, theta off a step | 1 |
| 02 | Open vs closed loop | feedforward is right until the hill | 2 |
| 03 | P | error shrinks with Kp but never reaches zero | 1 |
| 04 | PI | the integrator finds notebook 02's answer by itself | 1 |
| 05 | PID | the three paths, plotted separately | 1 |
| 06 | Windup | the hill the engine cannot climb | 1 |
| 07 | Derivative and noise | small noise, steep slope, ruined command | 3 |
| 08 | Tuning | step test -> Cohen-Coon / ZN / Tyreus-Luyben -> the saturation trap | 1 |
| 09 | Discretization | the strobe light slows down | 2 |
| 10 | Wheel and slip | cruise control meets black ice | 3 |

### 01 — The car

Build L0 from first principles: force balance, terminal speed. Open-loop constant throttle to
terminal speed; then a torque step, with the transport delay and lag visible on the torque
trace. Name the regions — transient, steady state, dynamic response as their sum. Close by
reading K, tau and theta off the step, which notebook 08 comes back to.

### 02 — Open vs closed loop

Invert the steady-state model by hand to get the torque that holds 90 km/h, and run it
open-loop: correct on flat dry road. Then break it three ways — a 4% grade, a headwind, 200 kg
of payload — and watch it settle at the wrong speed each time. Close the loop with P and watch
all three come right. This is the argument for why feedback exists at all.

### 03 — P

`LimPID` with integral and derivative switched off. Step 90 -> 110 km/h at four gains on one
axes, plus steady-state error against Kp. The error shrinks hyperbolically and never reaches
zero. Drag plays the role gravity plays in the drone example of the source video.

### 04 — PI

Integral switched on. PI against P on one axes, and the integrator state plotted as it settles.
Its final value equals the feedforward torque computed by hand in notebook 02 — the same number
found two ways, which is the best available explanation of what an integrator is actually
doing. Then shrink Ti until overshoot appears, motivating 05.

### 05 — PID

All three paths. P, PI and PID overlaid, then the three path contributions plotted separately
over time so the division of labor is visible: proportional carries the transient, integral
holds the steady state, derivative arrives only while the error is moving.

### 06 — Windup

Cruise at 130 km/h, then a sustained 10% climb the engine cannot hold. Without limit awareness
the integrator winds up through the climb and overshoots hard when the road flattens. With
output limits and anti-windup it does not. Integrator states overlaid for both.

### 07 — Derivative and noise

A noisy speedometer. With a near-pure derivative the torque command chatters; the noise
amplitude has not changed, but its slope has. Sweep the derivative filter coefficient until the
command is usable again. Explains why `LimPID` has an `Nd` parameter at all.

### 08 — Tuning

The payoff for the FOPTD plant. Open-loop step test following the procedure on slide 7, read K,
tau and theta, then compute gains three ways from the tables in `tuning_methods.pdf`:
Cohen-Coon from the open-loop response, Ziegler-Nichols by raising Kp to sustained oscillation
for Ku and Pu, Tyreus-Luyben from the same pair. Overlay all three responses. Close with the
trap from the source video: push the gains until the response looks perfect, then plot the
commanded torque and find it far beyond what the engine can deliver.

### 09 — Discretization

Take the gains from 08 and run the controller at a sequence of sample times. Overshoot grows,
then the loop rings, then it diverges — the same controller, degraded only by how often it
looks. Fixes: sample faster, or re-tune for the rate you actually have.

### 10 — Wheel and slip

L1 first: add wheel inertia and check whether the gains survive. Then L2, in three beats.

1. Standing start on low friction. The wheel spins, the car does not accelerate, the error
   stays large and the integrator winds up against a limit that is not in the engine at all.
2. The `mu(kappa)` curve on screen, with the peak marked. Past the peak more slip gives *less*
   force, so wheelspin runs away — the plant is open-loop unstable in that region. This is the
   gate the tuning video opens with: is your system well behaved?
3. **Cruise control on an ice patch.** Cruising at 90 km/h, road friction collapses for two
   seconds. The controller reads falling speed, commands more torque, spins the driven wheel,
   and destroys the traction it was trying to use. Overlaid against what a friction-aware torque
   limit would have done.

Beat 3 is the safety lesson, and it is also the sharpest possible argument for why lecture 2
needs cascade control.

## Tiers and build order

Built strictly in order, so that time pressure cuts from the end rather than from the middle.

**Tier 1 — the live spine.** 01, 03, 04, 05, 06, 08. Bulletproof, executed, committed. On its
own this is a complete lecture: intro, P, PI, PID, windup, heuristic tuning.

**Tier 2 — requested by name.** 09, 02.

**Tier 3 — upside.** 07, 10.

    1. Vehicle + Lecture1 components -> notebooks 01, 03, 04, 05, 06   -> execute, commit
    2. Notebook 08 (no new components)                                 -> execute, commit
       --- the lecture is safe from here ---
    3. Sampler -> 09;  notebook 02
    4. Noise source -> 07;  wheel and slip components -> 10
    5. Stretch: Pluto versions of 05 and 09

## Conventions

- Jupyter `.ipynb`, executed and committed. Pluto is a later upgrade, not a dependency.
- Model construction and solving live in a shared helper under `src/`, so notebook cells stay
  thin and the Pluto port is a rebind rather than a rewrite.
- Dyad models are organized into submodules — see `lecture-01-dyad-tasks.md`.
