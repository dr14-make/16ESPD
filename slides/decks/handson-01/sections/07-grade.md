---
routeAlias: grade
layout: section
---

###### Step 07 · 13 min

# A road with a gradient

Your first equation: the pull of gravity along the slope.

[page: step 07](../handson/lecture-01/#grade) · reference `dyad/HandsOn/GradeForce.dyad`, `GradeBody.dyad`

<!--
**Say:** The standard library's Mass block takes a fixed angle. A hill
that starts in the middle of a run needs a force driven by a signal, and no part does
that, so you write one.

**Timing:** 13 minutes: 3 for the slope slide, 10 building. Students short on time paste the full component
from the page's solution panel and read the equation.
-->

---
routeAlias: slope
---

## The slope: part of the weight pulls back

<div class="grid grid-cols-2 gap-8">
<div>

![A car on a road tilted by angle alpha. Its weight m g points straight down and splits into m g sine alpha along the road, pointing downhill, and m g cosine alpha into the road. A right triangle under the road shows rise over run, which is tangent alpha.](/diagrams/07-slope.svg)

*Angle exaggerated (30°); a 10 % hill is
only 5.7°.*

</div>
<div>

- **along the road:** m·g·sin α
  — pulls the car back;
- **into the road:** m·g·cos α
  — presses the tires down.

**What "10 %" means.** A road sign gives
*rise ÷ run*: 10 m up for every 100 m across. Rise ÷ run is
**tan α**, so tan α = 0.10 → α = 5.7°, sin α = 0.0995.

$$ F_{\text{slope}} = m\,g\,\sin(\arctan 0.10) = 1366\ \text{N} $$

> **Compare with the engine**
>
> Flat out: 1935 N. At 130 km/h up 10 %: 1366 + 493 drag + 164 rolling =
> **2023 N > 1935 N**. The car cannot hold 130 km/h here — the next
> lecture's "windup" section is this hill.

No library part turns a slope into a force: step 07 is your first
equation.

</div>
</div>

<!--
**Say:** On a flat road the weight presses straight into the road and does
not slow the car. Tilt the road, and part of the weight now points backward along it. The
steeper the hill, the bigger that part.

**Derivation, step by step** (draw the triangle on the board):

1. The road is tilted by angle α. Weight m·g points straight down.
2. The part along the road is m·g·sin α; the part into the road is m·g·cos α
   (the right angle is between the road and the "into the road" direction).
3. Road signs give a gradient: rise ÷ horizontal run. That is tan α. So
   α = arctan(gradient), and the force is m·g·sin(arctan(gradient)).
4. 10 %: arctan 0.10 = 5.71°; sin 5.71° = 0.0995. 1400 × 9.81 × 0.0995 = 1366 N.

**Why the distinction:** for small slopes sin α ≈ tan α (0.0995 vs 0.100),
so it barely matters at 10 %. At 50 % it does. Writing it properly once means the question
never comes back.

**The comparison numbers:** rolling on the slope uses the "into the road"
part, f<sub>r</sub>·m·g·cos α = 165 × 0.995 = 164 N. Total at 130 km/h: 1366 + 493 + 164 =
2023 N, more than the engine's 1935 N — so the speed must drop.

**Step 07's other check:** a free 1400 kg mass on this slope slows down at
1366 / 1400 = 0.976 m/s².
-->

---

## One equation

```julia
component GradeForce
  extends TranslationalComponents.Interfaces.PartialForce
  grade = RealInput()
  parameter m::Dyad.Mass = 1400
  parameter g::Acceleration = 9.80665
relations
  f = m * g * sin(atan(grade))
end
```

- **Add Component**, then ⇄ — an equation has no diagram form.
- `extends PartialForce` brings the ports and `f`; you write only
  what `f` is.
- `grade` is tan α — the same convention `RollingResistance` uses,
  so one signal drives both.

<!--
**Say:** The keyword extends means inheritance. The interface already has
a flange, a support and a force variable called f. The component's whole job is the one
line in its relations section.

**They get wrong:** the sign. The source acts on the body with −f, so a
climb needs positive f to hold the car back. That is why there is no minus in the
equation.

**Point at:** `sin(atan(grade))`. A 10 % grade is
tan α = 0.10, not α = 0.10.
-->

---

## extends: reuse, then flatten to see it all

<div class="grid grid-cols-2 gap-8">
<div>

`extends X` copies everything `X` declares —
ports, variables, equations — into your component. Each level adds a little:

1. `PartialElementaryOneFlangeAndSupport2`: ports `flange`,
   `support`; *s = flange.s − support.s*;
   *support.f = −flange.f* (the push-back).
2. `PartialForce`: a variable `f`, with
   *f = flange.f*. Its one gap: what `f` is.
3. `GradeForce`, yours: fills the gap with one equation.

Same idea in every analysis: `extends TransientAnalysis(stop = 300)`
inherits the solver set-up; you only set what differs.

</div>
<div>

```julia [GradeForce, flattened]
component GradeForce
  flange = Flange()       # from …Support2
  support = Flange()      # from …Support2
  grade = RealInput()
  variable s::Length      # from …Support2
  variable f::Dyad.Force  # from PartialForce
  parameter m::Dyad.Mass = 1400
  parameter g::Acceleration = 9.80665
relations
  s = flange.s - support.s      # …Support2
  support.f = -flange.f         # …Support2
  f = flange.f                  # PartialForce
  f = m * g * sin(atan(grade))  # yours
end
```

In the code view, click **Flatten Component** above the
`component` line to see this for any model.

</div>
</div>

<!--
**Say:** The word extends means: start from that model and add to it.
You do not copy the ports and the push-back equation by hand. You inherit them. Every
force source in the library is built the same way, and each one only says what its force
is.

**Say:** If you ever wonder what a component really contains, flatten it.
The flat view lists every port, variable and equation, including the inherited ones. That
is the list Dyad counts when it checks that equations match unknowns.

**Point at:** the comments on the right. Three of the four equations are
inherited; the student writes one.

**Tutor:** the listing on the slide is written by hand from the library
sources to show the content; Dyad Studio's flat view can format it differently, for
example with the inherited names fully qualified. Flatten `GradeForce` once
live so the room sees the real thing.
-->

---

## Give the body a grade input

![GradeBody: the grade input feeds both the rolling resistance inclination and the grade force.](/img/step07-grade-body.png)

*Duplicate `Body` → `GradeBody` · delete `incl_const` ·
one `grade` input into `rolling.inclination` and `gradeforce.grade` ·
`GradeForce(m = m, g = g)`*

<!--
**Say:** On a 10 percent hill, the backward pull is 1400 times 9.81 times
the sine of the angle whose tangent is 0.1. That is 1366 newtons. Compare that with the
1935 newtons of full traction from step 3: a 10 percent hill eats most of the engine. At
130 kilometers per hour it eats all of it. That is the windup scenario of the PID
lecture.
-->
