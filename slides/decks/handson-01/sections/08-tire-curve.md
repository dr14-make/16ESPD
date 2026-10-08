---
routeAlias: tire-curve
layout: section
---

###### Step 08 · 20 min

# Tire friction against slip

Grip peaks at 4 % slip and falls once the tire slides.

[page: step 08](../handson/lecture-01/#tire-curve) · reference `dyad/HandsOn/TireFrictionCurve.dyad`

<!--
**Say:** A tire does not grip by rolling perfectly. It grips by slipping a
little, as the tread deforms, and up to a point, more slip means more force. Past that
point it slides, and grip drops.

**Timing:** 20 minutes: 5 for the two slip slides, 15 building. The relations are long; students paste
the component from the page (New component → ⇄ → Ctrl+A → paste) and spend the time reading it and on the plot.
-->

---
routeAlias: no-slip
---

## Until now, the wheel could not slip

Steps 03 to 07 use an *ideal rolling wheel*: one turn of the wheel
always moves the car exactly one wheel-circumference. Wheel and car can never disagree.

<div class="grid grid-cols-2 gap-8">
<div>

> **On a dry road**
>
> Nearly true. A driven tire slips by about one per cent. The top speed does not care.

</div>
<div>

> **On snow or ice**
>
> Not true at all. The wheel can spin much faster than the car moves — and that difference
> is the whole story of this topic.

</div>
</div>

<!--
**Say:** An assumption does not announce itself. This one is even in the
part's name, "ideal rolling". On a dry road it costs nothing, so nobody notices it until
it fails.

**Ask the room:** what else have we quietly assumed? *(Straight road.
Constant mass. An engine that gives 150 N·m at any revs — that one we flagged in step 05.
Good answers are worth thirty seconds.)*
-->

---
routeAlias: slip-and-grip
---

## Slip, and how grip depends on it

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

**Slip** κ: how much faster the tire surface moves than the
car, as a share of the car's speed.

$$ \kappa \;=\; \frac{\omega r - v}{v} $$

Car at 10 m/s, tire surface at 10.4 m/s: κ = 0.4 / 10 = 0.04, i.e.
4 % slip.

**Grip** μ: the share of the load on the tire, F<sub>z</sub>,
that it can turn into a push:

$$ F_x \;=\; \mu(\kappa)\cdot F_z $$

</div>
<div>

![Friction coefficient against slip ratio from 0 to 0.3. The dry-road curve rises steeply to a peak of 1.0 at slip 0.04, then falls to a plateau of 0.7 beyond 0.12. A snow curve is the same shape at one fifth the height, peaking at 0.2. A dashed line at 0.28 marks the most the engine can ask for: below the whole dry curve, above the whole snow curve.](/diagrams/08-slip-grip.svg)

**Normal driving is the rising part.** Cruising at
100 km/h needs 457 N of the tire's 6865 N load: μ = 0.07, slip about 0.2 %. Even flat
out, μ = 0.28 and slip under 1 %. The peak at 4 % is reached only when the wheel
starts to spin or lock.

</div>
</div>

<!--
**Say:** A tire does not grip by rolling perfectly. To push the car, the
rubber has to stretch, so the tread moves slightly faster than the road under it. A little
slip gives a little grip. More slip gives more grip, up to about 4 percent.

**Say:** Past that, the rubber stops stretching and starts sliding. And
sliding grips worse than sticking. Think of pushing a heavy box: it is hard to get it
moving, and easier once it slides. So past the peak, more slip gives *less*
grip.

**Why the rising part is normal driving:** the tire only has to supply
what the car needs. F<sub>z</sub> = m·g/2 = 6865 N on the driven axle. Cruising at
100 km/h: drag 292 N + rolling 165 N = 457 N, so μ = 457 / 6865 = 0.067, which the dry
curve reaches at κ ≈ 0.002. Flat out, the engine's 1935 N is μ = 0.28 at κ ≈ 0.008. Both
sit low on the steep rising part, far left of the 4 % peak.

**Walk the curve:** rising part — normal driving, everything is designed for
it. Peak at κ = 0.04, μ = 1.0 — the most this tire can ever push. Past it, falling to
μ = 0.7 when fully sliding. The orange curve is the same tire on packed snow: everything
× 0.2.

**The slip formula, details:**

- ω·r is the speed of the tread (step 03: one turn = one circumference). v is the car's
  speed. The difference, divided by v, is slip as a fraction.
- At a standstill v = 0 and the division breaks, so the model divides by
  max(|v|, ε) with a small ε — step 09 calls it `v_eps`.
- Braking makes κ negative (the wheel turns slower than the car) and the curve is
  mirrored — that is the ABS lecture.

**The curve's parameters** (step 08): peak at sAdhesion = 0.04 with
mu_A = 1.0; full sliding from sSlide = 0.12 with mu_S = 0.7. Each piece is a smooth cubic so
the solver sees no corners. The shape is the same as Dyad's multibody slip wheel.

**The red dashed line** is next slide's punchline: the most the engine can
ask of the tire.
-->

---

## How the curve is built: three pieces

<div class="grid grid-cols-2 gap-8">
<div>

One building block, an S-shaped cubic:

$$ h(x) = 1.5\,x - 0.5\,x^3 $$

It goes from −1 to 1 as *x* goes from −1 to 1, and its slope,
1.5 − 1.5*x*², is **zero at both ends**. So pieces built from it
join without corners.

1. **Rise**, 0 → 0.04: μ = μ<sub>A</sub>·h(κ / 0.04). Flat top exactly
   at the peak, μ<sub>A</sub> = 1.0.
2. **Fall**, 0.04 → 0.12: the same h, stretched to that range, taking μ
   from 1.0 down to μ<sub>S</sub> = 0.7. Halfway, κ = 0.08: μ = 0.85.
3. **Slide**, beyond 0.12: μ = 0.7, constant.

Braking: μ = sign(κ) · μ(|κ|), so the curve is mirrored.

</div>
<div>

![The dry tire curve split into three pieces: a rising S-curve from slip 0 to 0.04 reaching 1.0, a falling S-curve from 0.04 to 0.12 down to 0.7, and a flat line at 0.7 beyond 0.12.](/diagrams/08-three-pieces.svg)

> **Ours is one of several tire models**
>
> **Linear**, μ = C·κ: small slip only, no peak.<br>
> **Ours**: smooth pieces through four points.<br>
> **Pacejka's Magic Formula**: the industry standard, fitted to test-rig data.<br>
> **Brush / dynamic**: elastic tread bristles, or friction with its own state.

</div>
</div>

<!--
**Say:** Real tire curves come from measurements. Here we draw the shape
with four numbers: where the peak is and how high, and where full sliding starts and how
high. Between those points we need smooth curves.

**Say:** The trick is one small cubic that rises from minus one to one and
is perfectly flat at both ends. We use it once for the rise and once, stretched and turned
upside down, for the fall. Because every piece arrives flat, the pieces meet without a
corner.

**Why no corners:** at a corner the slope jumps. The solver chooses its
step size from how fast things change, so a jump forces tiny steps or a failed step. A
straight-line curve would look almost the same and simulate worse.

**The fall, in detail** (if asked): map κ in [0.04, 0.12] to
x = (κ − 0.08) · 2 / 0.08, which runs from −1 to 1. Then
μ = (μ<sub>A</sub> + μ<sub>S</sub>)/2 + (μ<sub>S</sub> − μ<sub>A</sub>)/2 · h(x)
= 0.85 − 0.15·h(x): 1.0 at x = −1, 0.85 at x = 0, 0.7 at x = 1. The reference test
checks the midpoint, 0.85.

**A number to check on the rise:** κ = 0.02 is x = 0.5,
h = 0.75 − 0.0625 = 0.6875, so μ ≈ 0.69 at half the peak slip.

**Say:** This is not the only way to model a tire. It is the simplest
one that still has a peak and a slide, which is all today's question needs. Industry uses
fitted models with many more parameters, but the shape is the same: rise, peak, fall to
sliding.

**Other tire models, for a student who asks:**

- *Linear*: μ = C·κ with a stiffness C. Fine for small slip, but it has no peak,
  so it can never show wheelspin running away.
- *Piecewise smooth* (ours): a few points joined by smooth curves. Easy to
  read and tune; not fitted to a real tire.
- *Pacejka's Magic Formula*:
  F = D·sin(C·arctan(Bκ − E·(Bκ − arctan Bκ))). B, C, D and E (and, in full versions,
  dozens more, for load, camber and combined slip) are fitted to test-rig measurements.
  The standard in vehicle-dynamics software.
- *Physical "brush" models*: the tread as rows of elastic bristles that stick,
  then slide. Derives the curve from rubber stiffness and contact length.
- *Dynamic friction models* (e.g. LuGre): friction with its own internal state,
  for transient effects such as relaxation length — the tire needs some rolling distance
  before the force builds up.
-->

---

## κ in, μ out

<div class="grid grid-cols-2 gap-8">
<div>

- Rises to **μ<sub>A</sub> = 1.0** at κ = 0.04 (adhesion).
- Falls to **μ<sub>S</sub> = 0.7** beyond κ = 0.12 (sliding).
- Each segment is a cubic with zero slope at its ends — no corners for the solver.
- Point-symmetric: braking slip gives negative friction.

```julia [Julia REPL]
using MyCar, Plots
r = MyCar.TireFrictionCurveSweep()
plot(r; idxs = (r."curve.kappa", r."curve.mu"))
```

</div>
<div>

![mu against kappa: peaks at plus and minus 1.0 near 0.04 and falls to plus and minus 0.7 beyond 0.12.](/img/step08-tire-curve-plot.png)

</div>
</div>

<!--
**Say:** The sweep bench ramps the slip, kappa, from minus 1 to plus 1
over 2 seconds. Plotting against time would show the same curve with a shifted axis.
Giving the idxs argument a pair of signals, x and y, plots one signal against the
other.

**Point at:** the peak, then the right of it. Past the peak more slip
gives *less* force. Hold that thought: it is why wheelspin runs away in step 10.

**Tie back:** the slip slide at the start of this step drew this exact curve, with the
engine's ceiling across it. The shape is Dyad's multibody slip wheel's, and the PID
lecture's last section puts a cruise controller on it.
-->
