---
theme: default
title: Lecture 1 — Cruise control, live
routerMode: hash
transition: none
layout: default
addons:
  - ./addon-pluto
pluto:
  notebook: ../../pluteSpike/backend/notebook.jl
---

## The car

<Grid>
  <Card :x="0" :y="0" :w="3" :h="12"><PlutoCard name="car" /></Card>
  <Card :x="3" :y="0" :w="9" :h="12"><PlutoCard name="open-loop" /></Card>
</Grid>

<!--
**Beat:** the plant, before anyone mentions control. ~4 minutes.

Open on the table, not the plot. These eight numbers are the whole car for the next two
hours — 1400 kg, a drag area of 0.63 m², a torque ceiling of 150 N·m at the crank through a
gear ratio of 4. Say out loud that there is *no controller anywhere on this slide*.

Then the plot. Constant throttle holding 90 km/h, and at t = 10 s the command steps up by
20 N·m. Walk the curve:

- it does not move for about a tenth of a second — that is `theta_e`, the dead time
- it then rises on a lag — `tau_e = 0.3 s`, the engine filling in
- it settles at a *new constant speed*, not a rising one, because drag grows with v²

The third point is the one to land. A car under constant throttle is already a closed system
that finds its own equilibrium; what we add today is not stability, it is *choosing* which
speed that equilibrium sits at.

**If they ask** why the step is 20 N·m: no reason, it is a readable size. The shape is what
matters and the shape is the same for any step that does not hit the ceiling.

**If the plot is blank** the kernel is still warming. Keep talking through the table — it
takes about thirty seconds from a cold start and the cards fill in without a reload.
-->

---

## Proportional

<Grid>
  <Card :x="0" :y="0" :w="3" :h="3"><PlutoCard name="gain-p" /></Card>
  <Card :x="0" :y="3" :w="3" :h="3"><PlutoCard name="target-speed" /></Card>
  <Card :x="3" :y="0" :w="6" :h="12"><PlutoCard name="speed-plot" /></Card>
  <Card :x="9" :y="0" :w="3" :h="5"><PlutoCard name="settings" /></Card>
  <Card :x="9" :y="5" :w="3" :h="7"><PlutoCard name="metrics" /></Card>
</Grid>

<!--
**Beat:** the first controller, and its one flaw. ~8 minutes. This is the longest stop on the
deck; everything after it is a correction to what they see here.

Start with **Kp at 2** and the target at **110 km/h**, which is where the sliders load. The car
starts at 90, so there is a 20 km/h error on the table from t = 0.

Drive it in this order:

1. **Kp = 0.** Nothing happens — the command is zero, the car coasts down. Torque is
   proportional to error and the proportion is nothing.
2. **Kp = 2.** It climbs and settles. Now point at `steady-state error` in the metrics card
   and read the number aloud. It is not zero.
3. **Kp = 8.** Faster, and the error shrinks. Read the number again.
4. **Kp = 18.** Overshoot appears, then ringing.

The question to ask the room, before you answer it: *why can the steady-state error never be
zero?* Give it a moment. The answer is that holding 110 km/h needs real torque against drag and
rolling resistance — and a proportional controller can only produce torque by being wrong. Zero
error commands zero torque, which is not enough to hold the speed. **The error is the price of
the torque.**

That sentence is the slide. Everything on the next one exists to avoid paying it.

**Watch for:** at Kp above about 15 the ringing gets interesting and the temptation is to keep
going. Resist it — instability is the Windup slide's job, and the dead time is what makes it
happen, not the gain alone.

**If a student says "just add a constant offset"** — that is feedforward, it is a real answer,
and it is exactly what the integrator will work out for itself in about ninety seconds.
-->

---

## Proportional-integral

<Grid>
  <Card :x="0" :y="0" :w="3" :h="3"><PlutoCard name="gain-p" /></Card>
  <Card :x="0" :y="3" :w="3" :h="3"><PlutoCard name="gain-i" /></Card>
  <Card :x="0" :y="6" :w="3" :h="3"><PlutoCard name="target-speed" /></Card>
  <Card :x="3" :y="0" :w="6" :h="12"><PlutoCard name="speed-plot" /></Card>
  <Card :x="9" :y="0" :w="3" :h="5"><PlutoCard name="settings" /></Card>
  <Card :x="9" :y="5" :w="3" :h="7"><PlutoCard name="metrics" /></Card>
</Grid>

<!--
**Beat:** the fix, and its cost. ~6 minutes.

Leave Kp where the last slide ended. Take **Ki from 0 to 0.1** and let it run.

The error goes to zero. Say why in the terms the last slide set up: the integrator accumulates
the error over time, so *any* persistent error keeps growing the command until it stops being
persistent. It is the machine working out the offset a student proposed by hand.

Then show what it cost. Put **Ki at 1.5** and watch the overshoot:

- the integrator is still full of history when the error crosses zero
- so it keeps commanding torque *past* the setpoint
- the car has to overshoot to unwind it

Two numbers in the metrics card carry this: `overshoot` climbs and `settling time` gets worse
even though the steady-state error stays at zero. Good tracking and fast tracking are separate
things and you have just traded one for the other.

**Leave Ki near 0.3 before paging on.** The Windup slide is much clearer from a system that is
already behaving.
-->

---

## Proportional-integral-derivative

<Grid>
  <Card :x="0" :y="0" :w="3" :h="3"><PlutoCard name="gain-d" /></Card>
  <Card :x="0" :y="3" :w="3" :h="3"><PlutoCard name="gain-p" /></Card>
  <Card :x="0" :y="6" :w="3" :h="3"><PlutoCard name="gain-i" /></Card>
  <Card :x="0" :y="9" :w="3" :h="3"><PlutoCard name="target-speed" /></Card>
  <Card :x="3" :y="0" :w="6" :h="12"><PlutoCard name="speed-plot" /></Card>
  <Card :x="9" :y="0" :w="3" :h="5"><PlutoCard name="settings" /></Card>
  <Card :x="9" :y="5" :w="3" :h="7"><PlutoCard name="metrics" /></Card>
</Grid>

<!--
**Beat:** the third term, and why it is mostly off. ~5 minutes.

**Kd from 0 to 6.** The overshoot flattens. The derivative term reads the *rate* the error is
closing at and takes torque off before the car arrives — braking into the corner.

Then be honest about it:

- there is no measurement noise in this simulation at all
- a real speed signal is differentiated noise, amplified by Kd
- which is why production cruise control is usually PI, and D, when it exists, sits on the
  measurement rather than on the error and is filtered hard

Point back at notebook 07 if they have done it — the chattering-command figure there is this
exact failure with a noisy sensor.

**Kd = 20** if there is time. Nothing dramatic happens here, because the signal is clean; say
that plainly rather than pretending the demo shows a danger it cannot show. *The reason to
leave D alone is not in this room, it is in the sensor.*
-->

---

## Windup

<Grid>
  <Card :x="0" :y="0" :w="3" :h="2"><PlutoCard name="grade" /></Card>
  <Card :x="0" :y="2" :w="3" :h="2"><PlutoCard name="antiwindup" /></Card>
  <Card :x="0" :y="4" :w="3" :h="2"><PlutoCard name="gain-p" /></Card>
  <Card :x="0" :y="6" :w="3" :h="2"><PlutoCard name="gain-i" /></Card>
  <Card :x="0" :y="8" :w="3" :h="2"><PlutoCard name="gain-d" /></Card>
  <Card :x="0" :y="10" :w="3" :h="2"><PlutoCard name="target-speed" /></Card>
  <Card :x="3" :y="0" :w="6" :h="6"><PlutoCard name="speed-plot" /></Card>
  <Card :x="3" :y="6" :w="6" :h="6"><PlutoCard name="torque-plot" /></Card>
  <Card :x="9" :y="0" :w="3" :h="5"><PlutoCard name="settings" /></Card>
  <Card :x="9" :y="5" :w="3" :h="7"><PlutoCard name="metrics" /></Card>
</Grid>

<!--
**Beat:** the failure that is not a tuning problem. ~8 minutes. Two plots on this slide — the
torque plot is the one that explains it.

Set up first, then talk: **gradient to 10%**, anti-windup **off**, target 110. Let it run.

The car cannot hold 110 up a 10% grade. The command pins at the 150 N·m ceiling and stays
there — show it on the torque plot, the commanded trace flat against the dashed ceiling while
the delivered trace sits underneath it.

Now the part they cannot see: the integrator does not know about the ceiling. The error stays
positive, so it keeps accumulating, and the commanded torque the controller *believes* it is
asking for climbs far past anything the engine can deliver.

Take the **gradient back to 0** and watch what happens. The car should accelerate straight to
110 and hold. Instead it sails past — sometimes far past — because the controller has to
unwind an integrator holding minutes of impossible history before it will take its foot off.

Then flip **anti-windup on** and do the whole thing again. The overshoot goes.

The mechanism is four lines in the notebook and worth reading out: when the command is
clamped, the integration step for that instant is *undone*. `if antiwindup && u != u_sat` —
the integrator only accumulates while the controller still has authority.

**This is the slide that matters.** Windup is not a badly tuned loop; a perfectly tuned loop
does it. It is what happens when the model the controller has of itself stops matching the
actuator it is driving, and no amount of moving Kp and Ki fixes it.

**If the demo does not overshoot** — the gradient needs to be held long enough for the
integrator to fill. Give it the full run before dropping the grade back.
-->

---

## Tuning

<Grid>
  <Card :x="0" :y="0" :w="3" :h="2"><PlutoCard name="gain-p" /></Card>
  <Card :x="0" :y="2" :w="3" :h="2"><PlutoCard name="gain-i" /></Card>
  <Card :x="0" :y="4" :w="3" :h="2"><PlutoCard name="gain-d" /></Card>
  <Card :x="0" :y="6" :w="3" :h="2"><PlutoCard name="target-speed" /></Card>
  <Card :x="0" :y="8" :w="3" :h="2"><PlutoCard name="grade" /></Card>
  <Card :x="0" :y="10" :w="3" :h="2"><PlutoCard name="antiwindup" /></Card>
  <Card :x="3" :y="0" :w="6" :h="12"><PlutoCard name="speed-plot" /></Card>
  <Card :x="9" :y="0" :w="3" :h="5"><PlutoCard name="settings" /></Card>
  <Card :x="9" :y="5" :w="3" :h="7"><PlutoCard name="metrics" /></Card>
</Grid>

<!--
**Beat:** hand the controls over. ~10 minutes, or whatever is left.

No new content on this slide. Every input is here and the brief is a single sentence:

> Get from 90 to 110 km/h with **no overshoot**, settling inside **15 seconds**, on a **5%
> grade**, and hold it.

Let the room call the numbers and drive the sliders yourself. Read the metrics card out after
each attempt so the comparison is a number rather than an impression.

What usually happens, in order:

- someone pushes Kp hard and gets ringing
- someone pushes Ki hard and gets overshoot
- the combination that works is a *moderate* Kp with enough Ki to close the error, and it
  takes several tries to find

Let it take several tries. The point of the exercise is that there is no formula on this
slide — and then, in the last minute, say that there is one: **Ziegler–Nichols**, which is
notebook 08, and which reads its two numbers off the open-loop step response from the very
first slide of this deck.

That is the closing line. Page back to slide 1 if the timing allows.
-->
