---
routeAlias: front-matter
layout: cover
---

# Brakes and Stability Control

<h1 class="!text-5xl !-mt-4 opacity-70">ABS, TCS and ESP</h1>

Vehicle Systems &amp; Components — Lecture 3

Every system today does one thing: keeps the tire near the peak of its friction curve.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Budget for the front matter: 10 minutes, cover to the set-up build slide, of which 6 are step 00.
The lecture is one 3-hour block: the theory and a live build on the students' own car, section by
section, as in Lecture 1. Timing and setup are in `docs/lecture-03-run-sheet.md`.

Today is about the four systems between the driver and the road: the brakes themselves, the
anti-lock braking system, traction control and the electronic stability program.

The sentence on the slide is the whole lecture. ABS keeps a braking tire near its friction peak.
Traction control does the same for a driven tire. ESP does it for the car as a whole, by braking
single wheels to steer the car's rotation.

You do not only listen. In sections 01 to 03 you build on your own car in Dyad Studio, along
with me: first a brake system from pedal to wheel, pressed hard enough to lock the wheel, then a
slip controller of your own, then one that sees only the wheel speed. Every build step has one slide: a screenshot, a one-line recipe and a "page:
step" link to the build guide on the course site, which has every block, line of code and number
to expect. If you fall behind, the guide has each step's finished code to paste.

The source deck was titled "ABS, ESP, SRS". The restraint systems, airbags and belt pretensioners,
move to Lecture 4 with the rest of passive safety.

The handout, `handout.pdf`, is published next to the deck, one slide per page.
-->

---
routeAlias: from-lecture-1
---

## Where Lecture 1 left the tire

<div class="grid grid-cols-2 gap-8">
<div>

At the end of Lecture 1 a cruise controller drove a car onto ice. The tire crossed its
**adhesion peak**, the wheel spun up to 3400 km/h of tread speed, and the controller could not see
it happen.

$$
\kappa \;=\; \frac{\omega r - v}{\max(|v|,\ \varepsilon)}
\qquad F_x \;=\; \mu(\kappa)\,F_z
$$

Past the peak, more slip means less force, and the wheel runs away. Lecture 1 named the cure:
**an inner loop that regulates slip.**

</div>
<div>

![The dry-road friction curve: grip rises with slip to a peak, then falls toward a sliding plateau. The region past the peak, where more slip gives less force, is shaded.](/figures/10-past-the-peak.svg)

<div class="caption">Lecture 1, section 10: the friction curve and its unstable side</div>

</div>
</div>

<!--
Recall the picture. Slip kappa is how much faster the tread moves than the car, as a fraction of
the car's speed. Zero is pure rolling. Positive is wheelspin. Today we mostly brake, so slip is
negative: the tread moves slower than the car, and a locked wheel sits at minus one.

The curve is symmetric. Braking or driving, the tire gives its most force at a few percent of
slip and less once it slides. That is why everything today is a slip controller: ABS on the
braking side, traction control on the driving side.

The figure is Lecture 1's, the same `TireFrictionCurve` component the ABS model in this lecture
uses: peak 1.0 at 4 percent slip, sliding 0.7 from 12 percent.
-->

---

## The sections

| # | Section | What it covers | You build |
|---|---|---|---|
| | Set up | | 00 the course library in your `MyCar` |
| <Link to="friction-and-stopping">01</Link> | Friction and stopping | the friction coefficient, the tire's slip curve, braking distance and the cornering limit | 01 the tire's limit, by hand |
| <Link to="brakes">02</Link> | How the brakes work | lever, hydraulics, the booster, the tandem master cylinder and the two circuits | 02 your brake system, pedal to wheel |
| <Link to="abs">03</Link> | Anti-lock braking | history, wheel-speed sensors, the modulator, channel layouts, the control cycle, the model | 03 your own ABS · 04 on the wheel speed only · 05 across road surfaces |
| <Link to="tcs">04</Link> | Traction control | ABS turned around: brake and engine intervention on a spinning wheel | 06 take-home bonus: TCS |
| <Link to="esp">05</Link> | Electronic stability program | sensors, the reference model, understeer and oversteer, selective braking, ESP through ABS, split-µ | demo only |
| <Link to="wrap-up">06</Link> | Wrap-up | what each system controls, and what you measured | |

<!--
Seven sections in three hours, with a 10-minute break in the middle of section 03 and a 5-minute
one after it. Budgets per section are on each section's cover and in
`docs/lecture-03-run-sheet.md`.

The first two sections are physics: what the tire can give, and how the brake system turns a foot
into pressure and torque. Section 02 ends with your car stopped by a brake system you wire
yourself. Section 03 is the center of the lecture, and most of the building happens there: three
steps on your own car. Sections 04 and 05 build on the same hardware: TCS adds
engine control, ESP adds three sensors. Traction control is a bonus task for home; ESP is a demo on a planar car.
-->

---
layout: center
---

## The models behind this lecture

<div class="grid grid-cols-3 gap-8 text-left text-[0.9rem]">
<div>

### Notebook 01, ABS

`notebooks/lecture03/01-abs.pluto.jl`

One wheel braking a 1400 kg car from 90 km/h, with and without ABS.

- `Vehicle.Wheel.BrakedWheel`: inertia, brake, `TireFrictionCurve`
- `Vehicle.ABSController`: wheel-speed-only ABS, clocked at 5 ms
- `Vehicle.ABSBrakeTest`: `ABSBrakeTransient`, `LockedBrakeTransient`, `IdealBrakeTransient`

</div>
<div>

### Notebook 02, brakes

`notebooks/lecture03/02-brake-hydraulics.pluto.jl`

The driver's foot to master-cylinder pressure.

- `Vehicle.Brake.BrakePedal`: the lever, on a 0–1 pedal command
- `Vehicle.Brake.StaticBooster`: the vacuum booster's characteristic
- `Vehicle.Brake.TandemMasterCylinder`: two circuits from one bore
- `Vehicle.Brake.ForceChainTransient`: a 0–500 N pedal ramp

</div>
<div>

### Yours, built along

Your `MyCar` library, on the given brake parts and wheels and your hands-on 1 `Body`.

- `PedalStop`: pedal to wheel, through lines and calipers
- `SlipABS`: your slip controller
- `RefSpeedEstimator`, `PhaseABS`: an ABS on the wheel speed alone

Reference answers: `dyad/HandsOn03/`.

ESP demo: `Vehicle.Planar.PlanarCar`, notebook `03-esp.pluto.jl`.

</div>
</div>

<!--
Like Lecture 2, the theory here is tied to models you can run. Two Pluto notebooks, both in the
repository. Every plot in sections 02 and 03 marked as a figure comes from running one of them; the
speaker notes say which cell.

The third column is what you build today, along with me: four small models in your own
library, each checked against a number on its build slide. The course repository has the reference
answers in `dyad/HandsOn03/`, under the same names. The ESP demo runs on a fourth
model, a planar four-wheel car, which section 05 introduces.

Neither notebook model is a car yet. The ABS model is a single lumped wheel carrying the whole car: no load
transfer, no steering, no yaw. That is enough for ABS, not for ESP; the ESP section brings in the
planar car. Notebook 02 stops at master-cylinder pressure. The brake lines and the calipers that
carry it to the wheel are library parts too: `BrakeLine`, `BrakeCaliper` and
`HydraulicBrakedWheel`, which you wire in build 02.
-->

---
routeAlias: build-setup
---

## Build 00: set up

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

```julia
# in MyCar, on a new branch lecture-03 from main
using Pkg
Pkg.add(url = "https://github.com/dr14-make/16ESPD",
        rev = "TODO-TAG")   # tag not cut yet
Pkg.add("HydraulicComponents")
```

Then <kbd>F1</kbd> → **Dyad: Compile**.

*Branch `lecture-03` · move the course library to the Lecture 3 tag · add `HydraulicComponents`
· compile · **+** → `VehicleSystemsComponents › Vehicle › Wheel` lists `BrakedWheel` and
`HydraulicBrakedWheel`*

[page: step 00](../lecture/lecture-03/#step-00)

</div>
<div>

<div class="placeholder">Screenshot to come: <code>step00-wheel-library.png</code>, the <b>+</b>
popup open at <code>VehicleSystemsComponents › Vehicle › Wheel</code></div>

> **No hands-on 2 branch?** Start from `main`: today needs only hands-on 1's `Body`.

</div>
</div>

<!--
Before the first build, the course library. Today's parts, the brake system, the braked wheels
and the pressure integrator, live in the course library, and your `MyCar` needs a version that
has them.

In the status bar at the bottom, click the branch name and create a new branch, `lecture-03`, from
`main`. If you finished hands-on 2, branch from where it left you; if not, `main` is enough,
because today needs only the `Body` from hands-on 1.

Open the Julia REPL: click Dyad: Open Julia REPL in the Actions panel's title bar. Paste the
lines on the slide. You added the course library in hands-on 2, but your manifest still holds the
version from that day, which has none of today's parts. The first `Pkg.add` moves it to a fixed
tag, the version this lecture was rehearsed on. If you skipped hands-on 2, the same line adds it.
The second adds `HydraulicComponents`, the fluid library: in build 02 your own bench declares the
brake fluid, and that needs the package in `MyCar` itself. Then F1, Dyad: Compile.

Check: open any diagram, click plus, and open VehicleSystemsComponents, Vehicle, Wheel. You should
see `BrakedWheel`, `HydraulicBrakedWheel`, `BrakeActuator` and `TireFrictionCurve`. Next to it,
`Brake` lists `BrakePedal`, `StaticBooster`, `TandemMasterCylinder`, `BrakeLine` and
`BrakeCaliper`. One level up, `Vehicle` lists `ABSPressureIntegrator`. In the REPL, `using VehicleSystemsComponents` runs without an error.

Under plus there is also a `HandsOn03` folder: those are the reference answers to today's steps.
Build your own; open them only to compare.

TODO before the lecture: replace TODO-TAG with the tag cut from main, here and on the guide page, and
capture step00-wheel-library.png. If the tag carries the planar car's MultibodyComponents, ask the
students to run this step before the lecture: the first compile then takes about a minute longer.
-->
