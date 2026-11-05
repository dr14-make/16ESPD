---
routeAlias: energy-management
layout: section
---

###### Section 06

# Energy management

What the controller decides, the rules that decide it, the SoC window and its hysteresis, charge
sustaining, and the optimizer in one slide.

<!--
Section 06, energy management. The hardware of sections 04 and 05 gives the car choices; the energy
manager makes them, many times a second. We look at what a hybrid controller decides, write it as
rules inside a window of state of charge, keep the rules from chattering with Lecture 2's
hysteresis latch, insist that the battery ends where it started, and look at the optimizer the
industry uses, ECMS, in one slide. You build the energy manager at the end, build 03.
-->

---
routeAlias: controller
---

## What the controller decides

<div class="diagram-wide">

![Block diagram of a hybrid controller. Inputs on the left, measured and asked for: vehicle speed, engine speed, machine speed, accelerator demand, brake demand, battery SoC and K0 state, all on one bus. Four blocks read the bus: start/stop decides engine on or off; clutch control, K0 open or closed; generation, the charge power from SoC; regen braking, the machine's share and the friction rest. A demand-split block takes their decisions and the K0 state. Outputs on the right, commands: engine on and starter, K0 engagement, engine torque, machine torque, friction brakes.](/diagrams/06-controller.svg)

</div>

<div class="handson">Every decision on the right is a mode or a torque. In our car the CVT's ratio
is one more command, from build 02's line.</div>

<!--
This is the usual controller architecture, redrawn from the original deck's slide 18, which shows a
Modelica controller of this shape.

On the left, what the controller measures and is asked for: the vehicle speed, the engine speed,
the machine speed, the driver's accelerator and brake demands, the battery's state of charge, and
whether the clutch is engaged.

In the middle, its four decisions. Start and stop: should the engine run at all. Clutch control:
should K0 be open or closed. Generation: how much charging power the battery needs, from its state
of charge. Regen braking: how much of the braking the machine takes, and how much is left for the
friction brakes; that is Lecture 4's blending. Then a demand split turns those decisions into two
torques: one for the engine, one for the machine.

On the right, the commands: engine on and the starter, the clutch engagement, the engine torque,
the machine torque, and the friction brakes.

The green box: every output is either a mode, on or off, or a torque. Our car has one more command,
the CVT's ratio, which build 02's operating line already sets.
-->

---
routeAlias: rules
---

## Rules: five modes

<div class="diagram-wide">

![The modes over the plane of the power the driver asks for at the wheels, horizontally, and the state of charge, vertically. Negative power, braking: regen, the machine brakes first with Lecture 4's blending. From zero to P_ev: electric only, K0 open, engine off. From P_ev to P_line,max: engine on its line, machine idle. Above P_line,max: boost, engine and machine. Below the SoC thresholds, from zero to P_line,max: charge, the engine on its line above the demand and the machine generating the rest; above P_line,max: the engine alone above its line, as boost fades out with low charge. Two dashed lines mark the SoC hysteresis: charge on at the lower, charge off at the upper.](/diagrams/06-modes.svg)

</div>
<div class="grid grid-cols-2 gap-x-8 text-[0.85rem] mt-2">
<div>

1. **Regen** when braking: through Lecture 4's blending.
2. **Electric only** at low demand: K0 open, engine off.
3. **Engine on the line** in the middle.

</div>
<div>

4. **Boost** when the demand exceeds the line.
5. **Charge** when SoC is low: the engine above the demand.

Thresholds <span class="todo">TODO: P<sub>ev</sub>, P<sub>line,max</sub>, SoC on/off (#113)</span>

</div>
</div>

<!--
The energy manager we build is rule-based, settled decision S3 of the plan. Five modes, laid out on
a plane: horizontally, the power the driver asks for at the wheels, negative when braking;
vertically, the battery's state of charge.

One, regen: whenever the driver brakes, the machine brakes first, through Lecture 4's series
blending, and the friction brakes take the rest.

Two, electric only: at low demand, up to a threshold P ev, K0 opens and the engine stops; the
machine drives. This is where section 01 showed the engine is worst.

Three, engine on its line: in the middle, the engine drives alone on its best-BSFC line and the
machine idles.

Four, boost: above the line's upper end, the machine adds its torque, so the engine does not leave
the line for full load.

Five, charge: when the state of charge is low, the engine runs on its line above the demand and the
machine generates the rest. That is load-point raising from section 05, used to refill the battery.

The thresholds, P ev, the line's upper end, and the two state-of-charge levels, come from the
reference model of issue 113 and are TODO.
-->

---
routeAlias: soc-window
---

## The SoC window, with hysteresis

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

A single threshold chatters: the engine starts, SoC rises a hair, the engine stops, SoC falls a
hair, the engine starts.

Two thresholds and a latch:

$$
\text{charge} =
\begin{cases}
\text{on} & \text{SoC} < \text{SoC}_{\text{on}} \\
\text{off} & \text{SoC} > \text{SoC}_{\text{off}} \\
\text{unchanged} & \text{otherwise}
\end{cases}
$$

The same for the engine's start against P<sub>ev</sub>.

</div>
<div>

- Lecture 2's **`HysteresisLatch`**, the same part.
- **Continuous latches, no events**: the house rule of Lecture 2 (S7).
- The window keeps the battery away from both ends: room to take regen above, reserve to boost
  below.

<span class="todo">TODO: SoC<sub>on</sub>, SoC<sub>off</sub>, the window (#113)</span>

</div>
</div>

<!--
Why hysteresis. With a single threshold, the controller chatters. The state of charge falls below
the threshold, the engine starts charging, the state of charge rises a hair above it, the engine
stops, the charge falls a hair, the engine starts. A real engine would start and stop many times a
second; in a model the solver takes tiny steps at every switch.

The cure is two thresholds and a memory. Charging switches on below SoC on and off above SoC off,
and between the two it stays as it was. That is the latch on the slide. The same goes for starting
the engine against the electric-only threshold: start above one power, stop below a lower one.

You have the part already: Lecture 2's `HysteresisLatch`. It follows the house rule of Lecture 2's
settled decision S7, continuous latches without events, so the solver does not have to stop and
restart at every switch.

The window itself keeps the battery away from both ends: room above the top to take a regen event,
and reserve below the bottom for electric driving and boost. The two levels come from the reference
model, issue 113.
-->

---
routeAlias: charge-sustaining
---

## Charge sustaining: no borrowed fuel

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

A hybrid that ends the WLTC with less charge than it started **borrowed fuel from the battery**.

- Check: SoC at the end within **± 2 % of capacity** of its start.
- Correct: turn the net battery energy into fuel.

$$
V_{f,\text{corr}} = V_f + \frac{E_{b,\text{start}} - E_{b,\text{end}}}{\eta_{eb}\,H_u\,\rho_f}
$$

Less charge at the end, more fuel charged to the run.

</div>
<div>

**Size of the window**

± 2 % of 1.4 kWh = ± 0.028 kWh ≈ ± 0.1 MJ of battery energy

The conventional car's WLTC: **42.9 MJ** of fuel.

η<sub>eb</sub>, engine to battery: **0.30** = 0.347 · 0.90 · 0.97 (assumed)

</div>
</div>

<!--
Settled decision S4 of the plan: results are charge-sustaining. A hybrid that ends the WLTC with
less charge than it started has borrowed fuel from the battery: energy the engine put in some
earlier day. Report its raw fuel and it looks better than it is.

Two defenses. First a check: the state of charge at the end must be within plus or minus 2 percent
of the battery's capacity of its start. That band is the plan's, an assumed charge-sustaining
tolerance. Second a correction: turn the net battery energy into the fuel it would have taken to put
it back. The formula: the corrected fuel volume is the raw fuel plus the battery energy at the start
minus at the end, divided by the engine-to-battery efficiency, the fuel's heating value and its
density. With 43.4 megajoules per kilogram and 0.745 kilograms per liter, Lecture 4's petrol. The
sign: less charge at the end, more fuel charged to the run.

The library gives you this as a block, SoC-corrected fuel. It follows the linear correction of SAE
J1711 and UN ECE R101, but where those take the slope from a regression over several tests, the
block fixes it with an engine-to-battery efficiency of 0.30, assumed: the Lecture 2 engine on its
best-BSFC line at a 15 kilowatt charging point, 34.7 percent, times 0.90 for the machine and inverter
generating, times 0.97 for the battery's charging loss.

The right column sizes the window. 2 percent of 1.4 kilowatt-hours is 0.028 kilowatt-hours, about
0.1 megajoules. The conventional car burns 42.9 megajoules of fuel on the WLTC, on this bench. So
the band is small against the cycle's fuel, even after dividing by
the efficiency: the correction is a check on honesty, not a large term.
-->

---
routeAlias: ecms
---

## The optimizer in one slide: ECMS

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

**Equivalent consumption minimization strategy.** At every instant, choose the split *u* that
minimizes an equivalent fuel flow:

$$
\dot m_{eq}(u) = \dot m_f(u) + s\,\frac{P_b(u)}{H_u}
$$

- *P*<sub>b</sub> > 0, discharging: the battery's energy costs future fuel.
- *P*<sub>b</sub> < 0, charging: it earns fuel back.
- *s*, the equivalence factor: too high and the battery is never used; too low and it drains.
  Tuned, or adapted with SoC, so the cycle ends charge-sustaining.

</div>
<div>

**Beside it**

- **Dynamic programming**: the true optimum over a known cycle, computed offline backward in
  time; the benchmark the others are measured against.
- **Rules**: what we build; transparent, and tuned by reading them.

<div class="handson">Not in today's build: settled decision S3.</div>

</div>
</div>

<!--
What the industry uses when rules are not enough: ECMS, the equivalent consumption minimization
strategy. One slide, not built today; settled decision S3 keeps the build rule-based.

The idea: at every instant, consider every possible split u of the demand between the engine and the
machine, and choose the one that minimizes an equivalent fuel flow. That is the real fuel flow plus a
penalty for using the battery: s times the battery power divided by the fuel's heating value. When
the battery discharges, its energy is charged as fuel, because the engine will have to put it back
later. When it charges, the term is negative: the stored energy earns fuel back.

Everything hangs on s, the equivalence factor. Too high and the battery looks expensive, so it is
never used; too low and it looks free, so it drains. In practice s is tuned for the cycle, or adapted
on line from the state of charge, so that the cycle ends charge-sustaining. That is the same
constraint as our window, written as a price.

Beside it, dynamic programming: the true optimum over a cycle known in advance, computed offline,
backward in time over a grid of state of charge. No car can run it, because no car knows its future,
but it is the benchmark every strategy is measured against. And rules, what we build: transparent,
and tuned by reading them, which is why we start there.
-->

---
routeAlias: build-energy-manager
---

## Build 03: the energy manager

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

<div class="placeholder">

**Screenshot: `step03-energy-manager.png`**

The energy manager in Studio: demand, SoC and speeds in; the two latches; engine on, K0, engine
torque and machine torque out.

Captured with the build guide, #113

</div>

**Given:** Lecture 2's `HysteresisLatch`, Lecture 4's regen blending

<span class="todo">TODO: guide link · reference `dyad/HandsOn05/…`</span>

</div>
<div class="stack">

*Two latches, SoC and demand · five modes as rules · the demand split into an engine torque and
a machine torque · K0 and engine-on from the modes · regen through the blending*

```julia
# TODO: snippet from the build guide (#113)
```

<div class="handson">✓ over the WLTC the modes switch without chatter: <span class="todo">TODO
mode changes</span> · SoC stays in its window: <span class="todo">TODO min–max</span></div>

</div>
</div>

<!--
Build 03: the energy manager. The screenshot will show it in Studio, captured with the build guide
of issue 113.

What you build, in the italic line. Two latches from Lecture 2: one on the state of charge for
charging, one on the demand for starting the engine. The five modes as rules. The demand split, which
turns the mode and the demand into an engine torque and a machine torque. The clutch and the
engine-on command from the modes. And regen through Lecture 4's blending, which you already have.

The checkpoint, from the plan: over the WLTC the modes switch without chatter, and the state of
charge stays in its window. The number of mode changes and the state of charge's minimum and maximum
come from the reference model and are TODO.

If you see the engine start and stop several times within a second, a latch is missing or its two
thresholds are the same.
-->

---

## Summary of section 06

- The controller decides **modes and torques**: engine on, K0, the split, regen.
- **Five rules**: regen, electric only, on the line, boost, charge.
- **Hysteresis** keeps them from chattering: two thresholds and a latch, without events.
- **Charge-sustaining**: SoC back within ± 2 %, fuel corrected for the rest.
- **ECMS** prices the battery's energy as fuel; not built today.

### Next: what it all saves. <Link to="results">→ 07, results</Link>

<!--
Section 06 in five lines. The controller decides modes and torques: whether the engine runs,
whether K0 is closed, how the demand is split, and how much the machine brakes. We write it as five
rules: regen, electric only, on the line, boost, charge. Hysteresis keeps them from chattering, with
two thresholds and a latch and no events. The result must be charge-sustaining: state of charge back
within 2 percent, the fuel corrected for the rest. And ECMS, which we do not build, prices the
battery's energy as fuel and minimizes at every instant.

Next: what all this saves on the WLTC.
-->
