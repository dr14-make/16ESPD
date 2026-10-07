---
routeAlias: proportional
layout: section
---

###### Notebook 03

# Proportional

Proportional control gets you close, and close is where it stops.

`notebooks/lecture01/03-proportional.ipynb`

<!--
**Say:** from here to the end of section 06 the car never changes. Not one parameter.
Everything that happens is a change to the controller.

**Timing:** 10 minutes. Three cells, all of them fast, because the closed loop settles in
seconds where the open loop took minutes.

**Cut order:** this is spine — do not cut it. The lecture is not complete without it.
-->

---

## The whole control law

$$
u \;=\; k\,e \;=\; k\,\bigl(v_{\text{set}} - v\bigr)
$$

<div class="grid grid-cols-2 gap-8">
<div>

Torque command proportional to how far off we are. That is all of it. No memory, no
prediction.

Units, once and for all: *e* is km/h, *u* is N·m, so **k is N·m per km/h**.

</div>
<div>

> **One idealization, stated out loud**
>
> Cruise at **90**, step the setpoint to **110 km/h**, flat road. *Holding* those speeds takes
> 31 and 40 N·m. But at the step the error is 20 km/h, and *k* times 20 is large — the gentlest
> gain here asks for 280 N·m, the fiercest for 17,800. **So this section's engine delivers
> whatever we ask** (`T_max` and `y_max` lifted). The limit returns in section 06.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
</div>

<!--
**Say:** think of walking to a line on a football pitch. Far away, walk fast; close, slow
down; on the line, stop. A proportional controller and a person crossing a room are the same
algorithm, and for that problem it works perfectly — you stop exactly on the line.

**Then say:** now think about a drone hovering at 50 m. At the target the error is zero, so
the controller commands zero, so the propellers stop, so it falls. That system needs a
non-zero output to *stay* where you put it — and proportional control can only make a
non-zero output out of a non-zero error.

**Ask the room:** which of those two is our car? *(The drone. Holding 110 km/h needs 40 N·m
forever, because drag never stops. Let them get there; the next three slides are just
evidence for the answer they gave.)*

**In the model:** One **`LimPID`**, and the wire from `plant.v_kmh` back to
`controller.u_m`. That wire is the whole difference between this section and section 02.

**Readout — every symbol on this slide**

- **u = k·e** — the entire proportional control law. Output is gain times error, and nothing
  else.
- **k** — the proportional gain, N·m per km/h. Sometimes written K<sub>p</sub>.
- **e = v_set − v** — the error, km/h. Positive means we are going too slowly.
- **u** — commanded engine torque, N·m.
- **T_max = 150 N·m** — the engine's physical ceiling. **y_max** — the controller's own
  output clamp, a separate number. Both lifted for this section.
- **280 / 17,800 N·m** — the peak torque the gentlest and fiercest gains here ask for at the
  instant of the step. Against 150 available.
-->

---

## One gain, one step

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 2. One assumption, stated before it is used]
Scenarios = VehicleSystemsComponents.Lecture1
SPEED = "loop.plant.v_kmh"
UNLIMITED = 1.0e6            # N.m, the ceiling lifted away

single = Scenarios.CruiseLoopTransient(
    k = 14.0, T_max = UNLIMITED, y_max = UNLIMITED, stop = 30.0)

plt = plot_speed(single; sig = SPEED, setpoint = 110, label = "k = 14")
bracket_error!(plt, single; setpoint = 110, sig = SPEED)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

- **2.8** km/h short
- **≈ 40** N·m to hold 110
- **280** N·m peak command

</div>
<div>

![Step response from 90 to 110 km/h under proportional control, settling just below the setpoint with the gap marked by a bracket.](/figures/03-single-gain.svg)

*The response settles, and it settles **below** the dashed setpoint. The bracket is the steady-state error.*

</div>
</div>

<!--
**Point at:** the dashed line, then the solid one, then the gap between them. Do not say
"error" yet — ask what they see.

**Ask the room:** is this controller broken? *(No. It is doing exactly what it was told. It
is stable, it is quick, it stopped somewhere sensible — and it is wrong, permanently, and it
will never notice.)*

**Read out:** the bracket annotation — 2.8 km/h short at this gain. And then the third number
on the slide, which is the one nobody expects: to make that modest-looking response the
controller asked for **280 N·m** at the instant of the step, from an engine that can give
150. We lifted the limit to get this plot. Say so.

**Contrast, loudly:** the open-loop car took several minutes to change speed. This took
seconds. Same engine, same mass, same drag. Feedback changed the dynamics of the system, not
just how it is operated.

**Readout — every symbol on this slide**

- **k = 14** N·m per km/h — a deliberately gentle gain.
- **2.8 km/h** — the steady-state error: setpoint minus where it settled.
- **≈ 40 N·m** — the torque needed to hold 110 km/h, which is what the loop ends up
  delivering.
- **280 N·m** — the peak command, at the step, when the error is still the full 20 km/h.
- **The bracket** — drawn between the settled speed and the dashed setpoint. Its label is the
  error.
- **stop = 30.0** — the run length in seconds.
-->

---

## Turn the gain up

<!-- The four gains and their outcomes are read from the executed notebook at the shipped
     theta_e = 0.3 s, where the ultimate gain is about 115 N.m per km/h. That is why the top
     two members of the family oscillate rather than settle, and why the slide says so. -->

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 3. Raising the gain]
GAINS = [14.0, 56.0, 220.0, 890.0]

family = sweep(
    Scenarios.CruiseLoopTransient(
        k = 14.0, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0),
    "k", GAINS)

plot_sweep(family; sig = SPEED, setpoint = 110, name = "k")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

| k [N·m per km/h] | what it does |
|---:|---|
| 14 | settles, 2.8 km/h short |
| 56 | settles, 0.7 km/h short |
| 220 | **never settles** — past K<sub>u</sub> |
| 890 | **never settles** — past K<sub>u</sub> |

*The ultimate gain is about **115** N·m per km/h. Two of these four are on the far side of it.*
</div>
<div>

![Four step responses at increasing proportional gain on one axes: each rises faster and settles closer to the setpoint, and none reaches it.](/figures/03-gain-family.svg)

*Left: four gains across two decades. Right: the last half minute, magnified — the two lowest gains have settled short, the two highest are still oscillating.*

</div>
</div>

<!--
**Point at:** the curves in order. Each one rises faster and each one stops closer. Then
point at the dashed setpoint and say: none of them arrives.

**Point at the right-hand panel**, the magnified last half minute. Two of these curves are
flat lines below the setpoint. The other two are still oscillating, and they will still be
oscillating tomorrow.

**Say:** so the pattern only holds while the loop is stable. Between 56 and 220 we crossed
something — the *ultimate gain*, about 115 N·m per km/h. Past it, "steady-state error" is not
a small number, it is a question with no answer.

**Ask the room:** so what gain do we need for zero error? *(Infinite. Somebody will say it —
and now you can answer that we cannot even reach 220. There is a ceiling on this approach and
we just hit it.)*

**Promise section 08:** that ultimate gain is not a nuisance. It is a measurement, and two of
the three tuning methods in this lecture are built on it.

**They get wrong:** "just turn it up more". Ask what else grows when the gain grows — the
commanded torque at the instant of the step, and the loop's appetite for sensor noise. We
spend section 08 on exactly that bill.

**Readout — every symbol on this slide**

- **k = 14, 56, 220, 890** — four gains spanning about two decades, N·m per km/h.
- **K<sub>u</sub> ≈ 115** N·m per km/h — the *ultimate gain*: the gain at which the loop
  oscillates forever, neither growing nor decaying. Above it there is no steady state.
- **Settled error** — 2.8 km/h at k = 14, 0.7 at k = 56. The other two never settle, so the
  question does not apply to them.
- **The right-hand panel** — the last 30 seconds, magnified onto a 5 km/h window so the
  difference between "settled" and "still oscillating" is visible.
-->

---

## Error against gain

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 4. Error against gain]
# solved from the force balance, not simulated: e = T(v_set - e)/k
function settled_error(k; v_set = 110.0)
    e = 0.0
    for _ in 1:20
        e = cruise_torque(v_set - e) / k
    end
    return e
end

K_ULTIMATE = 115.0     # N.m per km/h
plot(ks, settled_error.(ks); xscale = :log10, lw = 2.5)
vline!([K_ULTIMATE]; ls = :dash, color = :firebrick, label = "Ku = 115")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

</div>
<div>

![Steady-state error against proportional gain on a logarithmic gain axis: a hyperbolic decay that approaches zero without reaching it.](/figures/03-error-vs-gain.svg)

*Hyperbolic decay, solved from the force balance so it is defined everywhere. It approaches zero and never arrives — and past K<sub>u</sub>, shaded, there is no steady state left to measure.*

</div>
</div>

<!--
**Point at:** the curve hugging the axis on the right and never touching it. This is the
shape of "asymptotically, never".

**Then point at the shaded region** and be precise about what changed. This curve is
*solved*, not simulated — it is the fixed point of e = T(v−e)/k, which has an answer at every
gain. The shading marks where that answer stops meaning anything, because the loop no longer
settles. The crosses are the two gains from the last slide that the curve predicts and the
simulation refuses to deliver.

**Say:** and now the argument, which is three sentences and you should be able to reproduce
it in the exam. One: at 110 km/h the car needs about 40 N·m just to stand still against drag.
Two: a proportional controller's only source of output is *k* times the error. Three:
therefore the error cannot be zero, because if it were, the torque would be zero, and the car
would slow down.

**Ask the room:** what would have to be true of a plant for proportional control to reach the
setpoint exactly? *(That holding the setpoint needs zero control effort. Walking across a room
qualifies. Almost nothing you will ever be paid to control does.)*

**Readout — every symbol on this slide**

- **The blue curve** — the error *solved* from the force balance, not simulated: the fixed
  point of e = T_cruise(v_set − e)/k. It has an answer at every gain.
- **The shaded region** — gains above K<sub>u</sub> = 115, where the loop does not settle, so
  the curve's answer is not a thing you could measure.
- **Black dots** — simulated runs that settled. **Red crosses** — gains the curve predicts but
  the simulation refuses to deliver.
- **Log axis** — the gain spans two and a half decades, so equal spacing means equal ratios,
  not equal differences.
-->

---

## Why it cannot be zero

<div class="grid grid-cols-2 gap-8">
<div>

$$
u_{\text{needed}}(110) \;\approx\; 40\ \mathrm{N{\cdot}m} \qquad u = k\,e
$$

$$
\Rightarrow\quad e_{\infty} \;=\; \frac{u_{\text{needed}}}{k} \;\neq\; 0
$$

*Double the gain, halve the error. Never remove it.*

</div>
<div>

> **Same story, different plant**
>
> The drone hovers *below* 50 m because it needs 100 rpm to stay up, and only an error can
> produce 100 rpm. Our car cruises *below* 110 km/h because it needs 40 N·m to stay there.
>
> **Drag is playing the part gravity played.**

</div>
</div>

### The fix has to be something that *remembers*.

<!--
**Say:** write that division down. It is the most reusable thing in this section:
steady-state error under proportional control is the effort you need divided by the gain you
chose.

**Say:** and notice what it tells you about the plant — the harder the job, the bigger the
error. On a hill, this same controller is worse. We will watch that happen in section 06.

**Ask the room, to set up 04:** what could a controller add to its output that does not
depend on the error right now? *(Something accumulated. Steer them to "it should remember
that it has been short for a while." Do not say "integral" for them — let the room produce
the word.)*

**Readout — every symbol on this slide**

- **u_needed(110) ≈ 40 N·m** — the effort required to hold the setpoint, which never goes
  away because drag never goes away.
- **e<sub>∞</sub> = u_needed / k** — the steady-state error. The most reusable formula in this
  section.
- **e<sub>∞</sub>** — the subscript means "as time goes to infinity", i.e. once settled.
-->

---

## What this bought us

- A loop that is fast, stable, and permanently wrong.
- A formula for how wrong: *e*<sub>∞</sub> = effort needed ÷ gain chosen.
- The knowledge that no gain fixes it — the fix has to be a different *kind* of term.

### Next: give the controller a memory. <Link to="proportional-integral">→ 04, proportional-integral</Link>

<!--
**Check before moving on:** if the error vanished at high gain in your executed notebook, the
integral path was left switched on — `with_I = false` is the whole difference between this
section and the next.
-->
