---
routeAlias: open-vs-closed-loop
layout: section
---

###### Notebook 02

# Open loop versus closed loop

Feedforward is correct exactly as long as the world matches your model.

`notebooks/lecture01/02-open-vs-closed-loop.ipynb`

<!--
**Say:** we have a model of the car that predicted its terminal speed correctly. So here is a
fair question before we spend an hour on feedback: why measure anything at all? Just compute
the right throttle and apply it.

**Timing:** 8 minutes. This section is the *motivation* for everything after it, so if you cut
it, make sure section 03 opens with the argument instead.

**Cut order:** second to go. Drop this before touching the P → PI → PID → windup run.
-->

---

## Two architectures

<div class="grid grid-cols-2 gap-8">
<div>

#### Open loop — feedforward

![Open-loop block diagram: reference into controller into plant, producing an output, with a disturbance entering the plant and no path back.](/diagrams/02-open-loop.svg)

*The reference is fed forward and never comes back. There is no error signal anywhere in this picture.*

</div>
<div>

#### Closed loop — feedback

![Closed-loop block diagram: reference into a summing junction that subtracts the measured output, then controller, then plant, with a disturbance entering the plant and the output fed back to the summing junction.](/diagrams/02-closed-loop.svg)

*The output is compared with the reference, and the difference — the error — is what the controller acts on.*

</div>
</div>

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

<!--
**Point at** the missing wire in the left diagram. That absence is the entire difference, and
everything else follows from it.

**Say:** feedforward needs a model, because the controller has to invert the plant — given the
speed you want, produce the torque that achieves it. Any error in that inversion becomes an
error in the output, permanently, with nothing to correct it.

**Say:** and feedback is not obviously better. It is a hack we are forced into because we
cannot know the plant and the world well enough. Given perfect knowledge we would not want the
extra wire at all — it brings problems of its own, which is what the remaining sections are
about.

**In the model:** `LimPID` has a **feedforward input**, `u_ff`, and we have wired a constant
**zero** to it. Both architectures are in this one block; today we use only the right-hand
half of it.

**Terms, if anyone asks**

- **Open loop / feedforward** — u computed from r alone. No sensor, no error, no loop.
- **Closed loop / feedback** — u computed from the error. The output is fed back and compared.
- **Comparator** — the circle with + and −. It forms e = r − y, and it is the only place the
  two signals meet.
- **Model inversion** — solving the plant backwards: given the output you want, what input
  produces it? That is all a feedforward controller does.
- **u_ff** — `LimPID`'s feedforward input. Real controllers often use both paths; we tie this
  one to zero.
-->

---

## Invert the model, and drive

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Invert the model]
Scenarios = VehicleSystemsComponents.Lecture1

v = 90 / 3.6                                  # m/s
F = 0.5 * CAR.rho * CAR.CdA * v^2 +           # drag
    CAR.f_r * CAR.m * CAR.g                   # rolling
tau_ff = F * CAR.r / CAR.i                    # N.m at the engine

nominal = Scenarios.FeedforwardCruiseTransient(
    tau_ff = tau_ff, stop = 1200.0)
plot_speed(nominal; setpoint = 90)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

</div>
<div>

- **31.1** N·m computed
- **90.0** km/h achieved

> **It works**
>
> No sensor. No error signal. No controller worth the name — and the car sits on 90 km/h. On a
> flat, dry road, with the car we modelled, feedforward is exactly right.

</div>
</div>

<!--
**Say:** and it is not a trick. This is a legitimate control strategy, it is cheap, and it is
fast — there is no loop to be unstable, so it cannot oscillate. Feedforward is genuinely the
right answer for a lot of problems.

**Point at** the inversion in the code. That line *is* the controller. Everything the
controller knows about the car is in it: mass, drag area, rolling coefficient, wheel radius,
gear ratio.

**Ask the room:** what has to be true for this to keep working? *(Collect answers — they will
list the assumptions themselves, which is much better than you listing them. Then break
exactly those assumptions on the next slide.)*

**Readout — every symbol on this slide**

- **v = 90/3.6 = 25 m/s** — the target speed in SI, because the force balance is in SI.
- **F** — the total resisting force at that speed, N: drag plus rolling.
- **tau_ff = F·r/i = 31.1 N·m** — the torque at the engine that produces it. Divide by the
  gear ratio, multiply by the wheel radius: the driveline equation run backwards.
- **Feedforward** — this single number *is* the controller. There is nothing else in it.
-->

---

## Break it three ways

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Break it three ways]
WORLDS = [("flat road, nominal car", (grade = 0.0,  m = CAR.m,       CdA = CAR.CdA)),
          ("1% grade",               (grade = 0.01, m = CAR.m,       CdA = CAR.CdA)),
          ("200 kg payload",         (grade = 0.0,  m = CAR.m + 200, CdA = CAR.CdA)),
          ("20% more drag area",     (grade = 0.0,  m = CAR.m,       CdA = 1.2 * CAR.CdA))]

open_loop = [name => Scenarios.FeedforwardCruiseTransient(
                 tau_ff = tau_ff, grade = w.grade, m = w.m, CdA = w.CdA,
                 stop = 1200.0)
             for (name, w) in WORLDS]

plt = plot(; xlabel = "time [s]", ylabel = "speed [km/h]")
for (name, sol) in open_loop
    plot!(plt, signal(sol, "plant.v_kmh")...; lw = 2, label = name)
end
hline!(plt, [90]; ls = :dash, color = :black, label = "target")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

</div>
<div>

![Four open-loop runs against a 90 km/h target over twenty minutes: the nominal case sits on target, while the 1% grade, the 200 kg payload and the 20% larger drag area each settle at a visibly different wrong speed, the grade lowest.](/figures/02-open-loop-broken.svg)

*Same torque, four worlds. Three of them settle somewhere the driver did not ask for.*

</div>
</div>

<!--
**Read out** the three wrong speeds.

**Say:** and now the important part — *nothing in the controller went wrong*. It computed
31.1 newton-metres, it commanded 31.1, it delivered 31.1. It is still correct. The world
moved.

**Say:** and there is no error signal anywhere in this architecture, so nothing in the system
is even capable of noticing. The car is not failing to correct; it has no concept of
correction.

**Ask the room:** which of the three would a driver notice first? *(The hill. And which would
they never notice? The payload — the car is just quietly slower than they asked, forever.)*

**Readout — every symbol on this slide**

- **1 % grade** — tan α = 0.01, about 0.57°. A gentle motorway rise, and it costs 137 N
  against the 401 N the engine is holding — the car falls to 58.25 km/h.
- **200 kg payload** — m goes from 1400 to 1600 kg, changing both rolling resistance and the
  slope term. Settles at 85.40 km/h.
- **20 % more drag area** — a roof box or a headwind, since relative airspeed is what drag
  depends on. Settles at 82.16 km/h.
- **The dashed line** — the 90 km/h target nobody is holding any more.
-->

---

## Close the loop

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Close the loop]
# the same four worlds, now with the loop closed
K = 25.0                   # N.m per km/h
UNLIMITED = 1.0e6          # N.m — both torque ceilings lifted

closed = [name => Scenarios.CruiseLoopTransient(
              k = K, v_lo = 90.0, v_hi = 90.0,
              grade = w.grade, m = w.m, CdA = w.CdA,
              T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)
          for (name, w) in WORLDS]

for (name, sol) in closed
    plot!(plt, signal(sol, "loop.plant.v_kmh")...; lw = 2, label = name)
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

All three come back towards the target — without the controller being told which disturbance it
is facing, or that there is one.

</div>
<div>

![Two panels. Left: the same four worlds under proportional control, every run climbing back to within about two km/h of the 90 km/h target, with dotted lines marking where the open loop had settled. Right: the first twenty seconds magnified onto the last two km/h, showing the runs arriving within five seconds and the small error each one keeps.](/figures/02-closed-loop-recovered.svg)

*One controller, three different worlds, one outcome. That is the argument for feedback.*

</div>
</div>

<!--
**Say:** the controller has no model. It does not know about the hill, or the luggage, or the
wind. It knows one number — how far off it is — and that is enough to handle three
disturbances it was never designed for.

**Point at** the remaining gap between the curves and the target. It is still there, and it
is different for each disturbance. Do not explain it — say "hold that thought" and let
section 03 land it.

**Ask the room:** what did we give up to get this? *(Next slide. Take guesses first — "cost",
"complexity", "a sensor" are all partly right, and the real answer is more interesting than
any of them.)*
-->

---

## What feedback costs

### Feedforward changes how a system is *operated*.

### Feedback changes what the system *is*.

*The controller sets the rate of change as a function of the current state, and that
relationship is new dynamics — dynamics the car did not have before you wired it up.*

> **Which cuts both ways**
>
> You can take an unstable system and make it stable. You can also take a perfectly stable car
> and make it oscillate, or worse. A badly tuned loop is more dangerous than no loop at all —
> and it is why the rest of this lecture exists.

<!--
**Say:** this is the sentence to take away from the section. Feedforward cannot destabilize
anything — there is no loop. Feedback can, because there is.

**Say:** which is why control engineering spends so much of its effort on *analysis* rather
than on design. Designing a controller that works on a good day is not hard. Proving that it
cannot do harm on a bad one is the job.

**Flag forward:** we will see the loop destabilize twice today — once on purpose in section
08, to measure it, and once by accident in section 09, from nothing more than a slow
processor.

**Terms, if anyone asks**

- **Dynamics** — how a system evolves: its poles, its time constants, its stability.
  Feedforward leaves them alone; feedback rewrites them.
- **Stability** — whether a disturbance dies out or grows. Feedback can create it, and can
  destroy it.
-->

---

## What this bought us

- A working feedforward controller — and three ordinary situations that defeat it.
- The reason feedback exists: the world moves, and only an error signal notices.
- The warning: feedback changes the dynamics, so it can make things worse.

### Next: the simplest thing that uses an error signal. <Link to="proportional">→ 03, proportional</Link>

<!--
**Bridge:** so we need feedback. Let us start with the least clever thing we could possibly
do with an error signal — multiply it by a number.
-->
