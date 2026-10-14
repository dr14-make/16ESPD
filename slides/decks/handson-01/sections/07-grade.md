---
routeAlias: grade
layout: section
---

###### Step 07 · 13 min

# A road with a gradient

Your first equation: the pull of gravity along the slope.

[page: step 07](../handson/lecture-01/#grade) · reference `dyad/HandsOn/GradeForce.dyad`, `GradeBody.dyad`

<!--
**Say:** Until now the road was flat. In step 04 the body got its slope
from a constant block, `incl_const`, set to 0. A hill that starts in the middle of a drive
needs a force that follows a changing number. No ready-made part gives the pull of gravity
along a slope, so you write one.

**Plain words:** *grade* (or gradient) is how steep the road is, written
the way a road sign writes it: 10 % means 10 m up for every 100 m along the ground. A
*component* is one model block in Dyad, saved as one file in the student's library.

**What students end with:** two components, `GradeForce` (new, written as
code) and `GradeBody` (a copy of `Body` with a slope input). Nothing is simulated in this
step. The check is that both save with nothing listed in the **Problems** tab under the
editor. Commit message: `Step 07: grade`.

**Timing:** 13 minutes: 3 for the slope slide, 10 building. Students short on time open
**Stuck? The full model** at the end of step 07 on their page, paste the component, and read
the equation.
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
> lecture's "windup" section uses this hill.

No library part turns a slope into a force: step 07 is your first
equation.

</div>
</div>

<!--
**Say:** On a flat road the weight presses straight into the road and does
not slow the car. Tilt the road, and part of the weight points backward along it. The
steeper the hill, the bigger that part.

**Symbols on the slide:** m = car mass, 1400 kg. g = gravity, 9.81 m/s².
m·g is the car's weight in newtons (N), the unit of force. α (alpha) is the road's angle.
sin, cos and tan are the school triangle ratios; arctan goes back from tan to the angle.

**Derivation, step by step** (draw the triangle on the board):

1. The road is tilted by angle α. Weight m·g points straight down.
2. The part along the road is m·g·sin α; the part into the road is m·g·cos α
   (the right angle is between the road and the "into the road" direction).
3. Road signs give a gradient: rise ÷ horizontal run. That is tan α. So
   α = arctan(gradient), and the force is m·g·sin(arctan(gradient)).
4. 10 %: arctan 0.10 = 5.71°; sin 5.71° = 0.0995. 1400 × 9.81 × 0.0995 = 1366 N.

**If asked "why not just sin of 0.10?":** for small slopes sin α ≈ tan α
(0.0995 vs 0.100), so it barely matters at 10 %. At 50 % it does. With the exact formula the
model stays correct on any slope.

**The comparison box, number by number:**

- 1935 N: the engine flat out, 150 N·m × gear 4 ÷ wheel radius 0.31 m (step 03).
- 493 N: air drag at 130 km/h (36.1 m/s): 0.5 × air density 1.2 × drag area 0.63 × 36.1².
- 164 N: rolling resistance, the tires' own loss. Coefficient 0.012 × 1400 × 9.81 = 165 N on
  the flat; on the slope only the "into the road" part counts: 165 × cos α = 165 × 0.995.
- Total 2023 N, more than 1935 N, so the car slows down.

"Windup" is a controller problem the next lecture explains; you do not need it here.

**The reference test for step 07:** a free 1400 kg mass on this slope,
no engine, slows down at 1366 / 1400 = 0.976 m/s².
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
**Say:** The word `extends` means: start from an existing model and add to
it. `PartialForce` already has two connection points and a force called `f`. You add
only the one line under `relations`, the section that holds the equations.

**The words in the code, plainly:**

- `flange`: the connection point where the force pushes on the car body.
- `support`: the connection point it pushes against, the ground.
- `RealInput()`: an input port that carries a plain number signal, here the slope.
- `parameter`: a fixed number the user can change, here mass and gravity.
- `atan` is arctan; `grade` is the 0.10 of a 10 % road.

**Where to click:** in the **Components** tree, right-click `MyCar` →
**Add Component** → name it `GradeForce`. It opens as an empty diagram. Click ⇄
(**Toggle Between Code and Diagram View**, top right of the editor, in the row with the file's
tab) to get the code, type or paste, then save with Ctrl+S. Expected: nothing in the
**Problems** tab.

**They get wrong:** the sign. The force source pushes on the body with −f,
so a climb needs a positive f to hold the car back. That is why there is no minus in the
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
You do not copy the ports and the push-back equation by hand; you inherit them. Every
force source in the library is built the same way, and each one only states what its force
is.

**Say:** If you ever wonder what a component really contains, flatten it.
The flat view lists every port, variable and equation, including the inherited ones. Dyad
needs exactly one equation per unknown quantity; this is the list it counts.

**Plain words:** *inherit* = get for free from the model you extend.
*Port* = connection point. *Variable* = a quantity that changes during the run. The
"push-back" equation says the ground feels the same force as the car, in the opposite
direction.

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
**Say:** The body gets one new input, the slope. That one number feeds
two places: the rolling resistance, and the new gravity force. So the two can never
disagree about how steep the road is.

**Where to click, in order** (the caption under the picture is this list):

1. **Components** tree → right-click `Body` → **Duplicate** → name it `GradeBody`.
2. In its diagram, delete the block `incl_const` (the old flat-road constant).
3. With **+**, add an input port, `Dyad` › `RealInput`, and rename it `grade`.
4. With **+**, place your `GradeForce` (under `MyCar` at the bottom of the list). In its
   panel set `m = m` and `g = g`. That reuses the body's own mass and gravity, so the
   car's mass is set in one place.
5. Draw four wires: `grade` → `rolling.inclination`, `grade` → `gradeforce.grade`,
   `gradeforce.flange` → `mass.flange_a`, `gradeforce.support` → `ground.flange`.
6. Save. Nothing in **Problems**. Commit `Step 07: grade`, then **Sync Changes** (uploads
   the commit to GitHub).

**Expected result:** nothing runs here. If a student asks what it would do:
the reference test pushes the body with 500 N up a 2 % climb from 10 m/s. It barely speeds
up: 0.0164 m/s² at the start, 10.16 m/s after 10 s.

**Close:** 1366 N on a 10 % hill, against 1935 N from the engine flat
out. A 10 % hill takes most of the engine's force; at 130 km/h it takes all of it.
-->
