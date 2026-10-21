---
routeAlias: front-matter
layout: cover
---

# Brakes and Stability Control

<h1 class="!text-5xl !-mt-4 opacity-70">ABS, TCS, ESP and torque vectoring</h1>

Vehicle Systems &amp; Components — Lecture 3

Every system today does one thing: keeps the tire near the peak of its friction curve.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Today is about the four systems between the driver and the road: the brakes themselves, the
anti-lock braking system, traction control and the electronic stability program. At the end, the
newest addition: systems that add torque to a wheel instead of only taking it away.

The sentence on the slide is the whole lecture. ABS keeps a braking tire near its friction peak.
Traction control does the same for a driven tire. ESP does it for the car as a whole, by braking
single wheels to steer the car's rotation. Torque vectoring does it with drive torque.

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

| # | Section | What it covers |
|---|---|---|
| <Link to="friction-and-stopping">01</Link> | Friction and stopping | the friction coefficient, the tire's slip curve, braking distance and the cornering limit |
| <Link to="brakes">02</Link> | How the brakes work | lever, hydraulics, the booster, the tandem master cylinder and the two circuits |
| <Link to="abs">03</Link> | Anti-lock braking | history, wheel-speed sensors, the modulator, channel layouts, the control cycle, the model |
| <Link to="tcs">04</Link> | Traction control | ABS turned around: brake and engine intervention on a spinning wheel |
| <Link to="esp">05</Link> | Electronic stability program | sensors, the reference model, understeer and oversteer, selective braking |
| <Link to="torque-vectoring">06</Link> | Torque vectoring | adding torque instead of only braking: differentials and electric motors |
| <Link to="wrap-up">07</Link> | Wrap-up | what each system controls, and the sources |

<!--
Seven sections. The first two are physics: what the tire can give, and how the brake system turns
a foot into pressure and torque. Section 03 is the center of the lecture and ties to the ABS model
and notebook in the repository. Sections 04 to 06 build on the same hardware: TCS adds engine
control, ESP adds three sensors, torque vectoring adds an actuator that can push as well as brake.
-->

---
layout: center
---

## The models behind this lecture

<div class="grid grid-cols-2 gap-10 text-left">
<div>

### `notebooks/lecture03/01-abs.pluto.jl`

One wheel braking a 1400 kg car from 90 km/h, with and without ABS.

- `Vehicle.Wheel.BrakedWheel`: inertia, brake, `TireFrictionCurve`
- `Vehicle.ABSController`: wheel-speed-only ABS, clocked at 5 ms
- `Vehicle.ABSBrakeTest`: `ABSBrakeTransient`, `LockedBrakeTransient`, `IdealBrakeTransient`

</div>
<div>

### `notebooks/lecture03/02-brake-hydraulics.pluto.jl`

The driver's foot to master-cylinder pressure.

- `Vehicle.Brake.BrakePedal`: the lever
- `Vehicle.Brake.StaticBooster`: the vacuum booster's characteristic
- `Vehicle.Brake.TandemMasterCylinder`: two circuits from one bore
- `Vehicle.Brake.ForceChainTransient`: a 0–500 N pedal ramp

</div>
</div>

<!--
Like Lecture 2, the theory here is tied to models you can run. Two Pluto notebooks, both in the
repository. Every plot in sections 02 and 03 marked as a figure comes from running one of them; the
speaker notes say which cell.

Neither model is a car yet. The ABS model is a single lumped wheel carrying the whole car: no load
transfer, no steering, no yaw. That is enough for ABS, not for ESP; the ESP section says what the
model would need. The brake model stops at master-cylinder pressure: lines and calipers are the
next increment of the brake plan.
-->
