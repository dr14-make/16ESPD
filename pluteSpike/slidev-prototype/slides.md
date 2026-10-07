---
theme: default
title: Cruise control — Slidev spike
canvasWidth: 1280
aspectRatio: 1280/760
routerMode: hash
transition: none
---

# Cruise control

PROTOTYPE — one PlutoDeck slide ported to Slidev.

Authored math is KaTeX: $u(t) = K_p\,e(t)$, with $e = v_\text{ref} - v$.

<!--
**Spike:** this cover has no cards. Move right to load the live slide.
-->

---

## Proportional

<div class="pluto-grid">
  <PlutoCard name="gain-p" :x="0" :y="0" :w="3" :h="3" />
  <PlutoCard name="target-speed" :x="0" :y="3" :w="3" :h="3" />
  <PlutoCard name="speed-plot" :x="3" :y="0" :w="6" :h="12" />
  <PlutoCard name="settings" :x="9" :y="0" :w="3" :h="5" />
  <PlutoCard name="metrics" :x="9" :y="5" :w="3" :h="7" />
</div>

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

<div class="pluto-grid">
  <PlutoCard name="gain-p" :x="0" :y="0" :w="3" :h="3" />
  <PlutoCard name="gain-i" :x="0" :y="3" :w="3" :h="3" />
  <PlutoCard name="target-speed" :x="0" :y="6" :w="3" :h="3" />
  <PlutoCard name="speed-plot" :x="3" :y="0" :w="6" :h="12" />
  <PlutoCard name="settings" :x="9" :y="0" :w="3" :h="5" />
  <PlutoCard name="metrics" :x="9" :y="5" :w="3" :h="7" />
</div>

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
