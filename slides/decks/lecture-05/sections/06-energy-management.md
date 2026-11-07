---
routeAlias: energy-management
layout: section
---

###### Section 06

# Energy management

What the controller decides, the rules that decide it, the battery's charge window, ending with the
charge we started with, and the optimizer in one slide.

<!--
Section 06, energy management. The hardware of sections 04 and 05 gives the car choices; the energy
manager makes them, many times a second. We look at what a hybrid controller decides, and write it
as rules that keep the battery's state of charge, how full it is, inside a window. We keep the
rules from switching on and off too fast with Lecture 2's hysteresis latch, a switch with two
thresholds and a memory. We insist that the battery ends where it started. And we look at the
optimizer the industry uses, ECMS, in one slide. You build the energy manager at the end, build 03.
-->

---
routeAlias: controller
---

## What the controller decides

<div class="diagram-wide">

![Block diagram of a hybrid controller. Inputs on the left, measured and asked for: vehicle speed, engine speed, machine speed, accelerator demand, brake demand, battery SoC and K0 state, all on one bus. Four blocks read the bus: start/stop decides engine on or off; clutch control, K0 open or closed; generation, the charge power from SoC; regen braking, the machine's share and the friction rest. A demand-split block takes their decisions and the K0 state. Outputs on the right, commands: engine on and starter, K0 engagement, engine torque, machine torque, friction brakes.](/diagrams/06-controller.svg)

</div>

<div class="caption">Left: what the controller measures and is asked for · middle: its four
decisions · right: the commands it sends</div>

<div class="handson">Every decision on the right is a mode or a torque. In our car the CVT's ratio
is one more command, from build 02's line.</div>

<!--
This is the usual controller architecture, redrawn from the original deck's slide 18, which shows a
Modelica controller of this shape.

On the left, what the controller measures and is asked for: the vehicle speed, the engine speed,
the machine speed, the driver's accelerator and brake demands, the battery's state of charge, and
whether the clutch is engaged.

Read the drawing left to right; the blue arrows carry signals. In the middle, its four decisions.
Start and stop: should the engine run at all. Clutch control: should K0 be open or closed.
Generation: how much charging power the battery needs, from its state of charge. Regen braking:
how much of the braking the machine takes, and how much is left for the friction brakes; that is
Lecture 4's brake sharing. Then a demand split divides what the driver asks for into two torques:
one for the engine, one for the machine.

On the right, the commands: engine on and the starter, the clutch engagement, the engine torque,
the machine torque, and the friction brakes.

The green box is the take-away: every output is either a mode, on or off, or a torque. Our car has
one more command, the CVT's ratio, which build 02's operating line already sets.
-->

---
routeAlias: rules
---

## Rules: five modes

<div class="diagram-wide">

![The modes over the plane of the power the driver asks for at the wheels, horizontally, and the state of charge, vertically. Negative power, braking: regen, the machine brakes first with Lecture 4's blending. From zero to the electric-drive threshold, P ev: electric only, K0 open, engine off. From P ev to the line's power cap, P line max: engine on its line, machine idle. Above P line max: boost, engine and machine. Below the SoC thresholds, from zero to P line max: charge, the engine on its line above the demand and the machine generating the rest; above P line max: the engine alone above its line, as boost fades out with low charge. Two dashed lines mark the SoC hysteresis: charge on at the lower, charge off at the upper.](/diagrams/06-modes.svg)

</div>
<div class="caption">Across: power the driver asks for at the wheels, below 0 when braking · up:
state of charge (SoC) · each colored box is one mode</div>
<div class="grid grid-cols-2 gap-x-8 text-[0.85rem] mt-2">
<div>

1. **Regen** when braking: the machine brakes first, friction brakes add the rest.
2. **Electric only** at low demand: K0 open, engine off.
3. **Engine on the line** in the middle.

</div>
<div>

4. **Boost** when the demand exceeds the line.
5. **Charge** when SoC is low: the engine above the demand.

Thresholds: P<sub>ev</sub>, the electric-only limit: engine on above **12 kW**, off below **8 kW**
· P<sub>line,max</sub>, the top of the engine's line: **60 kW**, on the WLTC test **30 kW** ·
charging on/off at SoC **0.55 / 0.60**, on the WLTC test **0.52 / 0.55**

</div>
</div>

<!--
The energy manager we build is rule-based: fixed rules on demand and charge, no optimizer. Five
modes, laid out on a chart. Across, the power the driver asks for at the wheels, in kilowatts,
below zero when braking. Up, the battery's state of charge, from empty to full. Each colored box is
one mode: the car is in the mode whose box holds the current demand and charge. The take-away: the
mode depends only on two numbers, how much power the driver wants and how full the battery is.

One, regen, the green box on the left: whenever the driver brakes, the machine brakes first, and
the friction brakes take the rest, as in Lecture 4. The drawing calls that blending.

Two, electric only, the blue box: at low demand, up to a threshold P ev, the electric-drive limit,
K0 opens and the engine stops; the machine drives. This is where section 01 showed the engine is
worst.

Three, engine on its line, the orange box: in the middle, the engine drives alone on its best-BSFC
line and the machine idles.

Four, boost, the red box: above the line's upper end, P line max, the machine adds its torque, so
the engine does not leave the line for full load.

Five, charge, the purple band along the bottom: when the state of charge is low, the engine runs on
its line above the demand and the machine generates the rest. That is raising the engine's load
from section 05, used to refill the battery. At the bottom right, with low charge and high demand,
there is no boost: the engine works alone, above its line. The two dashed lines are where charging
switches on and off; the next slide explains why there are two.

The thresholds, from the library's energy manager. P ev is itself a pair: the engine starts above 12
kilowatts of demand and stops below 8; between them it stays as it was. The line's upper end is 60
kilowatts by default; the WLTC test model sets it to 30, our choice for that test. Charging
switches on below 0.55 state of charge and off above 0.60 by default; the WLTC test moves the
window down to 0.52 and 0.55, to leave room for regen late in the cycle.
-->

---
routeAlias: soc-window
---

## The SoC window, with hysteresis

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

A single threshold chatters, switching on and off very fast: the engine starts, SoC rises a hair,
the engine stops, SoC falls a hair, the engine starts.

Two thresholds and a latch, a switch that remembers its last state:

$$
\text{charge} =
\begin{cases}
\text{on} & \text{SoC} < \text{SoC}_{\text{on}} \\
\text{off} & \text{SoC} > \text{SoC}_{\text{off}} \\
\text{unchanged} & \text{otherwise}
\end{cases}
$$

SoC<sub>on</sub>: charging starts below it · SoC<sub>off</sub>: charging stops above it, a little
higher. The same for the engine's start against P<sub>ev</sub>.

</div>
<div>

- Lecture 2's **`HysteresisLatch`**, the same part.
- The latch switches smoothly, so the solver never has to stop and restart: Lecture 2's rule
  (S7).
- The window keeps the battery away from both ends: room to take regen above, reserve to boost
  below.

Default SoC<sub>on</sub> **0.55**, SoC<sub>off</sub> **0.60**, the start. On the WLTC test
**0.52 / 0.55**: room above for late regen.

</div>
</div>

<!--
Why hysteresis. Hysteresis means a gap between the switch-on and the switch-off point. With a single
threshold, the controller chatters: it switches on and off very fast. The state of charge falls
below the threshold, the engine starts charging, the state of charge rises a hair above it, the
engine stops, the charge falls a hair, the engine starts. A real engine would start and stop many
times a second; in a model the solver takes tiny steps at every switch.

The cure is two thresholds and a memory. Read the formula on the slide line by line. Charging is on
when the state of charge is below SoC on. It is off when the state of charge is above SoC off, which
is a little higher. In between, it stays as it was. That memory is the latch. The same goes for
starting the engine against the electric-only threshold: start above one power, stop below a lower
one.

You have the part already: Lecture 2's `HysteresisLatch`. It follows Lecture 2's rule: the latch
switches smoothly, so the solver, the program that steps the model through time, does not have to
stop and restart at every switch.

The window itself keeps the battery away from both ends: room above the top to take a regen event,
and reserve below the bottom for electric driving and boost. The library's defaults charge below
0.55 and stop at 0.60, which is where the battery starts. The WLTC test moves the window down, to
0.52 and 0.55, so the battery has room above it for the regen late in the cycle.
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

<div class="caption text-left"><i>V</i><sub>f</sub>: fuel used, L · <i>E</i><sub>b</sub>: energy in
the battery, MJ · η<sub>eb</sub>: share of the fuel's energy that ends up in the battery ·
<i>H</i><sub>u</sub>: energy per kg of fuel, MJ/kg · ρ<sub>f</sub>: fuel density, kg/L</div>

Less charge at the end, more fuel charged to the run.

</div>
<div>

**Size of the window**

± 2 % of 1.4 kWh = ± 0.028 kWh ≈ ± 0.1 MJ of battery energy

The conventional car's WLTC: **43.0 MJ** of fuel.

η<sub>eb</sub>, engine to battery: **0.30** = 0.347 · 0.90 · 0.97 (assumed): engine × machine
and inverter × battery charging

</div>
</div>

<!--
Every result is charge-sustaining: the battery ends the test about as full as it started. A hybrid
that ends the WLTC with less charge than it started has borrowed fuel from the battery: energy the
engine put in some earlier day. Report its raw fuel and it looks better than it is.

Two defenses. First a check: the state of charge at the end must be within plus or minus 2 percent
of the battery's capacity of its start. That band is our choice, an assumed charge-sustaining
tolerance. Second a correction: turn the net battery energy into the fuel it would have taken to put
it back. The formula, in words: the corrected fuel, in liters, is the fuel the engine really used,
plus a correction. The correction is the battery energy at the start minus the energy at the end,
in megajoules. We divide it by three things: eta e b, the engine-to-battery efficiency, the share
of the fuel's energy that ends up stored in the battery; H u, the energy in one kilogram of fuel;
and rho f, the fuel's density, kilograms per liter. That turns megajoules of battery energy into
liters of fuel. We use 43.4 megajoules per kilogram and 0.745 kilograms per liter, Lecture 4's
gasoline. The sign: less charge at the end, more fuel charged to the run.

The library gives you this as a block, SoC-corrected fuel. It follows the straight-line correction
of the American and European test rules for hybrids, SAE J1711 and UN ECE R101. Those rules find
the slope of that line by fitting several test runs. The block instead fixes it with an
engine-to-battery efficiency of 0.30, assumed: the Lecture 2 engine on its best-BSFC line at a 15
kilowatt charging point, 34.7 percent, times 0.90 for the machine and inverter generating, times
0.97 for the battery's charging loss.

The right column sizes the window. 2 percent of 1.4 kilowatt-hours is 0.028 kilowatt-hours, about
0.1 megajoules. The conventional car burns 43.0 megajoules of fuel on the WLTC, on this test model.
So the band is small against the cycle's fuel, even after dividing by the efficiency: the correction
is a check on honesty, not a large term.
-->

---
routeAlias: ecms
---

## The optimizer in one slide: ECMS

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

**Equivalent consumption minimization strategy**: count battery energy as fuel, and at every
instant choose the split *u* that uses the least:

$$
\dot m_{eq}(u) = \dot m_f(u) + s\,\frac{P_b(u)}{H_u}
$$

<div class="caption text-left"><i>u</i>: how the power is split between engine and machine ·
ṁ: fuel flow, g/s · <i>P</i><sub>b</sub>: battery power, kW · <i>H</i><sub>u</sub>: energy per kg
of fuel, MJ/kg · <i>s</i>: equivalence factor, the price of battery energy in fuel</div>

- *P*<sub>b</sub> > 0, discharging: the battery's energy costs future fuel.
- *P*<sub>b</sub> < 0, charging: it earns fuel back.
- *s*, the equivalence factor: too high and the battery is never used; too low and it drains.
  Tuned, or adapted with SoC, so the cycle ends charge-sustaining.

</div>
<div>

**Beside it**

- **Dynamic programming**: the true optimum over a known cycle, computed after the fact,
  from the end of the cycle back to the start; the yardstick for the others.
- **Rules**: what we build; transparent, and tuned by reading them.

<div class="handson">Not in today's build: our manager stays rule-based.</div>

</div>
</div>

<!--
What the industry uses when rules are not enough: ECMS, the equivalent consumption minimization
strategy. One slide, not built today; the build stays rule-based.

The idea: at every instant, consider every possible split u of the demand between the engine and the
machine, and choose the one that minimizes an equivalent fuel flow, m dot e q, in grams per second.
That is the real fuel flow, m dot f, plus a penalty for using the battery: s times the battery
power P b divided by H u, the energy in one kilogram of fuel. Dividing kilowatts by megajoules per
kilogram gives grams per second, so the battery power becomes a fuel flow. When
the battery discharges, its energy is charged as fuel, because the engine will have to put it back
later. When it charges, the term is negative: the stored energy earns fuel back.

Everything hangs on s, the equivalence factor, a plain number with no unit: the price of battery
energy in fuel. Too high and the battery looks expensive, so it is never used; too low and it looks
free, so it drains. In practice s is tuned for the cycle, or adjusted while driving from the state
of charge, so that the cycle ends with the battery as full as it started. That is the same
constraint as our window, written as a price.

Beside it, dynamic programming: the true optimum over a cycle known in advance, computed on a
computer after the fact, from the end of the cycle back to the start, over a grid of state of
charge values. No car can run it, because no car knows its future,
but it is the benchmark every strategy is measured against. And rules, what we build: transparent,
and tuned by reading them, which is why we start there.
-->

---
routeAlias: build-energy-manager
---

## Build 03: the energy manager

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

![The manager in P2HybridWLTC: driver demand, speed, SoC and engine speed in on the left, available torque from below; engine power, engine torque, engine-on, K0 and machine torque out to the map and the powertrain.](/img/lecture-05/step03-energy-manager.png)

**Given:** `EnergyManager`, built on Lecture 2's `HysteresisLatch` and Lecture 4's regen
brake sharing · `TorqueToPedal`, the engine map read backwards: torque in, pedal out

[page: step 3](../lecture/lecture-05/#step-3) · reference `dyad/HandsOn05/P2HybridWLTC.dyad`

</div>
<div class="stack">

*The full hybrid drive back on the shaft · the manager splits the driver's demand into an engine
torque and a machine torque · the inverse map turns the engine's into a pedal · engine-on, K0 and
the CVT's speed target from its modes · its friction share through the CVT ratio*

`manager`, set in Studio: `mapped_limits` true · `SoC_on` 0.52 · `SoC_off` 0.55 ·
`P_line_max` 30 kW

```txt
N_target = max(manager.engine_on * line.N
               + (1.0 - manager.engine_on) * demand_line.N, N_locked)
```

<div class="handson">✓ over the WLTC the modes switch without chatter: <b>44</b> engine starts, the
shortest on for <b>1.9 s</b> · SoC from 0.600 down to <b>0.513</b>, back up to <b>0.613</b> ·
speed error <b>1.32</b> km/h</div>

</div>
</div>

<!--
Build 03: the energy manager. On the left, the manager in Studio. Its inputs come in on the left:
the driver's demand, the speed, the state of charge and the engine speed, and the torque the engine
can give from below. Its outputs leave on the right: engine power, engine torque, engine on, K0 and
machine torque.

The library gives you the rules as one block, the energy manager: three of Lecture 2's latches, on
the demand for starting the engine, on the line's cap for boost, and on the state of charge for
charging, and Lecture 4's regen brake sharing. What you build, in the italic line, is the car around
it.
You put the full hybrid drive back, with its losses, its 30 kilowatts and its 1.4 kilowatt-hours.
The manager takes the driver's demand and splits it into an engine torque and a machine torque; an
inverse engine map turns the engine's torque into a pedal. Its modes switch the engine on, close K0
and pick the CVT's speed target, and its friction-brake share goes to the wheels through the CVT's
ratio. Above the snippet, the manager's four parameters you set in Studio: use the engine's torque
limits from its map, and the WLTC test's thresholds. The snippet is the engine speed target. In
words: when the engine is on, aim at the line's speed; when it is off, aim at a second line taken
from the demand; and never go below the locked minimum speed from build 02.

The checkpoint: over the WLTC the modes switch without chatter, and the state of charge stays in its
window. The reference run starts the engine 44 times, and the shortest run of the engine is 1.9
seconds, so no start is chatter. The state of charge starts at 0.600, above the window, so the
manager does not charge at first; electric driving and boost draw it down to 0.513, just under the
window's bottom. From there engine charging and regen bring it back up, 3.92 megajoules into the
battery over the run, to at most 0.613, and it ends at 0.612. And the car still follows the cycle
within 1.32 kilometers per hour.

If you see the engine start and stop several times within a second, a latch is missing or its two
thresholds are the same.
-->

---

## Summary of section 06

- The controller decides **modes and torques**: engine on, K0, the split, regen.
- **Five rules**: regen, electric only, on the line, boost, charge.
- **Hysteresis** keeps them from switching on and off too fast: two thresholds and a latch.
- **Charge-sustaining**: SoC back within ± 2 %, fuel corrected for the rest.
- **ECMS** prices the battery's energy as fuel; not built today.

### Next: what it all saves. <Link to="results">→ 07, results</Link>

<!--
Section 06 in five lines. The controller decides modes and torques: whether the engine runs, whether
K0 is closed, how the demand is split, and how much the machine brakes. We write it as five rules:
regen, electric only, on the line, boost, charge. Hysteresis keeps them from switching on and off
too fast, with two thresholds and a latch. The result must be charge-sustaining: state of charge
back within 2 percent, the fuel corrected for the rest. And ECMS, which we do not build, prices the
battery's energy as fuel and minimizes at every instant.

Next: what all this saves on the WLTC.
-->
