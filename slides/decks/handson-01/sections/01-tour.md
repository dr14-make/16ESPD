---
routeAlias: tour
layout: section
---

###### Step 01 · 13 min

# One model, two views

Place two blocks, wire them, set a parameter — then see the same three facts as code.

[page: step 01](../handson/lecture-01/#tour) · reference `dyad/HandsOn/Tour.dyad`

<!--
**Say:** The first thing you build is the front half of the engine. It is
small on purpose, because the point is the editor, not the physics.

**Do it live, first, slowly:** Components → right-click
`MyCar` → Add Component → `Engine`. Then + → `PadeDelay`,
rename to `delay`. Then let them do the same with `FirstOrder`.

**Timing:** 13 minutes: 10 building, then 3 on "two kinds of wire" at the end. Wait until most hands are done before the ⇄ slide.
-->

---

## What you are building

![Tour in Dyad Studio: delay and lag wired in the diagram with the delay parameter panel open, and the same component in the code view.](/img/step01-engine-two-views.png)

*`delay` (PadeDelay: n = 6, m = 5, delayTime = 0.3) → `lag` (FirstOrder: T = 0.3), one wire `delay.y → lag.u`*

<!--
**Point at:** the parameter panel on the left, then line 5 on the right.
`n`, `m`, `delayTime` appear in both — the panel is
editing that line.

**They get wrong:** wiring `u` to `y` backwards, or
dropping the wire on the block body instead of the port square. A wire only exists if it
shows as a `connect` in the code.

**Their name is `Engine`, the screenshot says `Tour`:**
the reference library already has a finished `Engine`, so the two-block copy
needed another name. Theirs stays `Engine` — step 02 finishes it.
-->

---

## ⇄ — the same three facts

```julia
component Engine
  delay = BlockComponents.Nonlinear.PadeDelay(n = 6, m = 5, delayTime = 0.3)
  lag = BlockComponents.Continuous.FirstOrder(T = 0.3)
relations
  connect(delay.y, lag.u)
end
```

- Every block is a line `name = Library.Path(parameters)`.
- Every wire is a `connect` under `relations`.
- Change `T = 0.3` to `0.5` here, toggle back: the panel shows 0.5.

<!--
**Say:** Nothing in the diagram is hidden from the code. The reverse is
also true, for everything except equations, which have no picture. From step 7 on, you
will write those equations in this view.

**Do it live:** the round trip on the last bullet. It is the moment it
clicks for most of the room.

**They notice:** `{^delay}` tags and a `metadata`
block in their file. That is where the diagram keeps positions and wire routes. Leave it
alone — it is the diagram's, not theirs.
-->

---
routeAlias: two-kinds-of-wire
---

## Two kinds of wire

<div class="grid grid-cols-2 gap-8">
<div>

### A signal: a number

It goes one way, like an arrow. One block works out a number; the next
block reads it.

![Two blocks joined by an arrow: the first block's number is read by the second.](/diagrams/01-signal-wire.svg)

*Examples today: the torque you ask for, the km/h on the
speedometer, how slippery the road is.*

</div>
<div>

### A mechanical joint: physics

No arrow. Two parts bolted together. Dyad then knows two facts:

- they **move together** — same position, same speed;
- they **push each other equally** — the forces add up to zero.

![Two blocks joined by a plain line with no arrowhead: they move together and push on each other equally.](/diagrams/01-mechanical-joint.svg)

</div>
</div>

<!--
**Say:** A signal wire is like a message: "the driver wants 40
newton-meters". It goes one way. A mechanical joint is like a bolt. The wheel does not
"send" a force to the car body. They are fastened together and they move together, and
whatever the wheel pushes, the body is pushed by.

**Why it matters:** because a joint has no direction, you never have to decide
"who drives whom". You draw the car the way it is put together, and Dyad works out the
equations. That is why Dyad can join a body onto a driveline with one wire.

**The technical words, if a student asks:**

- Every mechanical port carries two numbers. A sliding port (`Flange`) carries
  position *s* and force *f*. A turning port (`Spline`) carries
  angle *φ* and torque *τ*.
- The one that is *equal* at both ends (position, angle) is called the
  *potential*. The one that *sums to zero* (force, torque) is the
  *flow*. Same idea as voltage and current in a circuit.
- This way of modeling is called *acausal*: equations, not assignments.

**In Dyad Studio:** the port shape tells you the kind. Gray circles are
turning (rotational), green squares are sliding (translational). You can only wire like to
like.
-->
