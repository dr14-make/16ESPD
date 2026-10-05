# Lecture 1 hands-on — build the car and the wheel in Dyad Studio

## Goal

A 90-minute hands-on Dyad session in which every student builds, from an empty Dyad library,
the longitudinal car that the Lecture 1 notebooks run, then gives its driveline a wheel with
inertia. Students who finish early, or work at home, continue to a slipping wheel and a
standing start on ice.

Success: every student leaves with a car that simulates and reaches the same terminal speed as
`Vehicle.CarPlant` in notebook 01, and has seen once that a Dyad diagram and Dyad code are the
same model.

## Revision — all in class, screenshots only

Supersedes the session length, the take-home split and the pictures below:

- The whole guide runs in class: about 155 minutes in two parts.
- **Part 1, Dyad Studio and the extension** (30 min): what the extension is and where its
  controls are, creating the library, and step 01, the two-block tour.
- **Part 2, Build the car** (125 min): steps 02–10, one component per step, slip wheel included.
- Each step's picture is a Dyad Studio screenshot of its `HandsOn` model; the hand-drawn SVG
  diagrams are gone. Checkpoint plots are rendered from the reference analyses.

## Revision — the hands-on comes before the PID lecture

Supersedes "Out of scope: changes to the deck" below. The hands-on now precedes the PID lecture,
opens with why and what, and teaches each step's physics at that step. See
`2026-10-04-lecture-01-handson-first-design.md`.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Starting point | Empty Dyad library | Most of the car is standard-library parts wired together; building it from nothing is the workflow worth learning |
| Wheel scope | L1 (inertia) in class, L2 (slip) take-home | Everyone finishes a working car; the fast students still reach the ice demo |
| Format | Web page under `docs/`, published with the course Pages site | Sits next to the deck students already use |
| Interaction | Diagram editor first, code only where needed | Code where a component has equations, and for analyses |
| Pictures | Hand-drawn inline SVG per step, plus a marked screenshot slot | Correct without screenshots; the lecturer adds real ones where the GUI is confusing |
| Session length | 90 minutes | — |

## The classroom car

The car students build is a reduced `Vehicle.CarPlant`, chosen so the in-class part needs no
hand-written equations:

- **Flat road.** No `grade` input and no `GradeForce`. `RollingResistance` still needs an
  `inclination` input; it is driven from a `Constant(k = 0)`.
- **km/h by a gain.** `BlockComponents.Math.Gain(k = 3.6)` instead of `Vehicle.ToKmPerHour`.
- **Everything else identical** to `Vehicle.CarPlant`: same parts, same parameters, including
  `PadeDelay(n = 6, m = 5)`. The terminal speed is therefore the one notebook 01 shows.

Parameters are taken from the models, not from `lecture-01-plan.md`: `IdealEngine` has
`theta_e = 0.3 s` where the plan and task docs say 0.04 s. The guide follows the model; the
docs are left as they are.

## Session plan

| # | Step | Min | Code |
|---|---|---|---|
| 0 | Before class: Dyad Studio installed, a new library created and `Pkg.instantiate` done | — | — |
| 1 | Tour: library browser, place a part, wire ports, set a parameter, diagram/code toggle | 10 | read only |
| 2 | `Engine`: `RealInput` → `PadeDelay` → `FirstOrder` → `Limiter` → `TorqueSource` | 20 | the analysis |
| 3 | `Driveline`: `IdealGear` → `IdealRollingWheel` | 10 | — |
| 4 | `Body`: `Mass`, `QuadraticSpeedDependentForce`, `RollingResistance` with `Constant` inputs, `Fixed` | 15 | — |
| 5 | `Car`: engine + driveline + body + `VelocitySensor` + km/h `Gain`; full throttle from rest to terminal speed | 20 | the analysis |
| 6 | `WheeledDriveline`: add an `Inertia` between gear and wheel; compare against step 5 | 10 | — |

Fifteen minutes of slack. Take-home:

| # | Step | Code |
|---|---|---|
| 7 | `GradeForce` and a `Body` with a grade input | equations |
| 8 | `TireFrictionCurve`: adhesion/sliding `mu(kappa)` | equations |
| 9 | `SlipWheel1D`: slip ratio and contact force | equations |
| 10 | Standing start on low friction: the wheel spins, the car barely moves | the analysis |

## The page

One self-contained file, `docs/handson/lecture-01/index.html`, styled like `docs/index.html`
(same tokens, same type, light theme, no external requests, so it opens from a memory stick
like the rest of the site). `docs/index.html` links to it from the Lecture 1 card area.

Every step is a section with:

1. the goal in one sentence and the time budget;
2. a parts table — instance name, library path (`RotationalComponents › Components ›
   IdealGear`), parameters to set;
3. an inline SVG of the target diagram: blocks, port names and wires, laid out as the
   reference model's diagram metadata places them;
4. a screenshot slot — a marked placeholder naming the model to open and screenshot, replaced
   by an `<img>` once the lecturer has one;
5. numbered actions;
6. a checkpoint — what the plot should look like and the value to read off it, quoted from a
   real run of the reference model;
7. a collapsed `<details>` "Stuck? The full model" with the reference Dyad code.

Steps that need code show it in a copyable block with what is new emphasized.

## Reference models

A new submodule, `dyad/HandsOn/`, one component per step, so the lecturer can open each in
Dyad Studio and screenshot it, and so the page's solution panels quote code that compiles:

- `Engine`, `Driveline`, `Body`, `Car`, `WheeledDriveline`, `WheeledCar` (in class)
- `GradeForce`, `GradeBody`, `TireFrictionCurve`, `SlipWheel1D`, `SlipCar` (take-home)
- one harness and one `TransientAnalysis` per checkpoint

Each component carries diagram placement metadata so it opens laid out, and a `test` with
`expect.initial` and `expect.final`. The models are written the way a student would arrive at
them: no forwarded parameters beyond what a step uses, short docstrings, no history comments.
`HandsOn` does not depend on `Vehicle`; it is the student's own library in miniature.

## Verification

- `~/.dyad-maxwell/dyad-lang/apps/cli/dyad compile .` succeeds and the `HandsOn` files appear
  in `generated/`.
- `cd test && julia +dyad-3.4.0 --project=.. runtests.jl` passes, with the new tests counted.
- The `Car` terminal speed under full torque matches `Vehicle.CarPlant`'s within the solver
  tolerance; the number on the page is the measured one.
- The `SlipCar` low-friction start shows wheel speed well above vehicle speed.
- The page opens from `file://` with the network off, has no horizontal scroll at phone width,
  and every `<details>` panel's code matches the `.dyad` source it quotes.

## Out of scope

- Real Dyad Studio screenshots (the lecturer's to capture; slots are provided).
- Controllers. The session ends at the plant; the cruise loop stays in the lecture.
- Changes to `Vehicle/`, `Lecture1/`, the notebooks or the deck.
