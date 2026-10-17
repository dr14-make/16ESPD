---
routeAlias: tour
layout: section
---

###### Step 01 · 13 min

# One model, two views

Place two blocks, wire them, set a parameter — then see the same model as code.

[page: step 01](../handson/lecture-01/#tour) · reference `dyad/HandsOn/Tour.dyad`

<!--
**Say:** The first thing you build is the front half of the engine. It is
small, because this step is about the editor, not the physics.

**The two blocks, in plain terms:**

- **`PadeDelay`** holds a signal back: what goes in comes out 0.3 s later. It stands for
  the engine's short pause before it reacts.
- **`FirstOrder`** is a *lag*: its output follows its input smoothly instead of jumping.
  `T = 0.3` means it covers about two thirds (63 %) of a change in 0.3 s. It stands for
  the engine building up its push.
- Step 02 explains both properly. Today only the clicking matters.

**Do it live, first, slowly:**

1. Components → right-click `MyCar` → **Add Component** → type `Engine`, Enter. A white
   canvas opens.
2. **+** (fifth icon in the small toolbar, top left of the canvas) → type `PadeDelay` →
   click `BlockComponents › Nonlinear › PadeDelay`. A block with a wave icon appears.
3. Click the block. A panel opens on the right. Click the pencil ✎ next to the name, type
   `delay`, Enter.
4. Under **Parameters**: `n` = 6, `m` = 5, `delayTime` = 0.3. Leave the rest.

Then let them do the same with `FirstOrder`: name `lag`, `T` = 0.3. Then wire and save.

**Timing:** 13 minutes: 10 building, then 3 on "two kinds of wire" at the end. Wait until
most hands are done before the ⇄ slide.

**Checkpoint, from the page:** the code view shows the two block lines and one
`connect(delay.y, lag.u)`. There is nothing to run or plot in this step. Students commit
with the message `Step 01: tour`, then click **Publish Branch** (the first upload of the
branch).
-->

---

## What you are building

![Tour in Dyad Studio: delay and lag wired in the diagram with the delay parameter panel open, and the same component in the code view.](/img/step01-engine-two-views.png)

*`delay` (PadeDelay: n = 6, m = 5, delayTime = 0.3) → `lag` (FirstOrder: T = 0.3), one wire `delay.y → lag.u`*

<!--
**Point at:** the parameter panel on the left, then line 5 on the right.
`n`, `m`, `delayTime` appear in both — the panel is
editing that line.

**What the parameters mean, if asked:** `delayTime = 0.3` is the delay in seconds. `n = 6`
and `m = 5` set how closely the block imitates a pure delay; higher is closer. Students
just type them in. `T = 0.3` is the lag's time in seconds.

**The ports:** each block has a small triangle on its left edge, the input `u`, and one on
its right edge, the output `y`. The wire goes from `delay`'s right triangle to `lag`'s left
triangle: press, hold, drag, release.

**They get wrong:** wiring `u` to `y` backwards, or dropping the wire on the block body
instead of the port. A wire only exists if it shows as a `connect` in the code. Check by
pressing ⇄: the line must read `connect(delay.y, lag.u)`.

**Their name is `Engine`, the screenshot says `Tour`:**
the reference library already has a finished `Engine`, so the two-block copy
needed another name. Theirs stays `Engine` — step 02 finishes it.
-->

---

## ⇄ — the same model as code

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

**Reading the code aloud:** `component Engine` starts the model. Each of the next two lines
is one block: its name, then where it comes from in the library, then its settings in
brackets. `relations` starts the list of wires. `end` closes the model.

**Do it live:** the round trip on the last bullet. In the code change `T = 0.3` to
`T = 0.5`, save with <kbd>Ctrl</kbd>+<kbd>S</kbd>, press ⇄, click `lag`: the panel shows
0.5. Then set it back to 0.3. This is where most of the room sees that the two views are
one file.

**They notice:** `{^delay}` tags and a `metadata`
block in their file. That is where the diagram keeps positions and wire routes. They should
not edit it.
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
newton-meters" (a newton-meter is the unit of twisting force, torque). It goes one way. A mechanical joint is like a bolt. The wheel does not
"send" a force to the car body. They are fastened together and they move together, and
whatever the wheel pushes, the body is pushed by.

**Why it matters:** a joint has no direction, so you never have to decide
which part drives which. You draw the car the way it is put together, and Dyad works out the
equations. That is why Dyad can join a body onto a driveline with one wire.

**The technical words, if a student asks:**

- Every mechanical port carries two numbers. A sliding port (`Flange`) carries
  position *s* and force *f*. A turning port (`Spline`) carries
  angle *φ* ("phi") and torque *τ* ("tau").
- The one that is *equal* at both ends (position, angle) is called the
  *potential*. The one that *sums to zero* (force, torque) is the
  *flow*. Same idea as voltage and current in a circuit.
- This way of modeling is called *acausal*: equations, not assignments.

**In Dyad Studio:** the port shape tells you the kind. Small triangles are signals, the
kind they wired today. Gray circles are turning shafts (rotational), green squares are
sliding parts (translational). You can only wire like to like.

**Ask the room:** which kind is the wire you just drew from `delay` to `lag`? *(A signal.
It carries one number, one way, from `delay`'s output to `lag`'s input.)*
-->
