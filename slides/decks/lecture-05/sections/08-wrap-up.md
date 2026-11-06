---
routeAlias: wrap-up
layout: section
---

###### Section 08

# Wrap-up

What you built, what you measured, and what the model leaves out.

<!--
Section 08, the wrap-up: the lecture in one slide, what you measured on your own car, and what the
model leaves out.
-->

---
routeAlias: lecture-summary
---

## Summary of the lecture

- **01** Lecture 2's engine: 232 g/kWh at best, 30.2 % over the WLTC. A hybrid moves the point,
  stops the engine, and brings the braking back.
- **02** Series: the motor alone drives. Parallel: both drive. Series-parallel: a clutch switches
  between them. Your homework is a series.
- **03** DOH = P<sub>EM</sub> / (P<sub>EM</sub> + P<sub>ICE</sub>); today's car is a full hybrid.
- **04** P0 and P1 turn with the engine; P2, P3, P4 sit behind a clutch. **The clutch matters
  more than the machine's power.**
- **05** The CVT moves the engine toward its best-BSFC line: 4.9 % less fuel alone; the machine
  shifts the load.
- **06** Five rules, three latches, charge-sustaining within ± 2 %.
- **07** The ranking P0 < P1 ≪ P2 ≈ P3 ≈ P4, each saving against a stated baseline.

<!--
The whole lecture, one line per section.

01: Lecture 2's engine is 232 grams per kilowatt-hour at its best and 30.2 percent efficient over
the WLTC. A hybrid saves fuel by moving the operating point, stopping the engine, and bringing the
braking back.

02: in a series hybrid the motor alone drives; in a parallel hybrid both do; a series-parallel
hybrid switches between the two with a clutch. Your homework is a series hybrid.

03: the degree of hybridization is the machine's share of the power; today's car is a full hybrid.

04: P0 and P1 turn with the engine; P2, P3 and P4 sit behind a clutch. The clutch matters more than
the machine's power.

05: the CVT moves the engine toward its best-BSFC line, 4.9 percent less fuel on its own, and the
machine shifts the load.

06: five rules, three latches, and a result that is charge-sustaining within 2 percent.

07: the ranking P0 below P1, far below P2, P3 and P4, and every saving stated against its baseline.
-->

---
routeAlias: what-you-measured
---

## What you measured on your own car

<div class="tight">

| Step | You built | You measured |
|---|---|---|
| 01 | the P2 powertrain | engine only 1.17 km/h, electric only on Low 1.50 km/h worst speed error |
| 02 | the operating line | 5.44 against H0's 5.72 L/100 km, 17 % of the fuel within ±150 rpm of the line |
| 03 | the energy manager | 44 engine starts, none shorter than 1.9 s; SoC 0.513–0.613 |
| 04 | the charge-sustaining WLTC | SoC 0.600 → 0.612; 4.09 L/100 km, 132.1 MJ/100 km, −28.5 % against H0 |

</div>

<!--
What you measured, one row per step, with the reference model's checkpoint numbers. Step 01, the P2
powertrain, following the WLTC engine only and electric only. Step 02, the operating line: 5.44
liters against H0's 5.72, with only 17 percent of the fuel near the line. Step 03, the modes
switching without chatter: 44 engine starts over the WLTC, none shorter than 1.9 seconds, and the
state of charge between 0.513 and 0.613. Step 04, the charge-sustaining WLTC: the state of charge
back at 0.612 from 0.600, and the hybrid at 4.09 corrected liters and 132.1 megajoules per 100
kilometers, 28.5 percent less than H0.
-->

---
routeAlias: known-limits
---

## What the model leaves out

- **No stepped gearbox**, no shift logic: the CVT's ratio is free. A stepped gearbox is in the
  extra pack.
- **Starts are warm**: K0 cranks the engine, fuel fades in from 400 to 700 rpm, the slip counts;
  no cold-start enrichment or warm-up, and the manager puts no price on a start.
- **No emissions beyond fuel**: the catalyst cooling down during electric driving is not modeled.
- **P4 is not torque vectoring**: it drives the rear flanges through its own reduction.

<div class="handson">Homework: the series hybrid, on prepared ground. Extra pack: the fuel-cell car,
the same shape with another source.</div>

<!--
What the model leaves out, from the plan's known limits.

There is no stepped gearbox and no shift logic: the CVT's ratio is free. The Sonata's P2 sits in a
six-speed automatic, and the studies of section 07 use dual-clutch and manual gearboxes; the stepped
gearbox is in the extra pack.

Engine starts are in the model, but only warm ones. K0 closes and cranks the engine while the
machine makes up the torque the clutch takes from the shaft; fuel fades in between 400 and 700
revolutions per minute; and the clutch's slip heat while it cranks is in the energy balance, not
left out. What is missing: the fuel always comes from the warm engine's steady-state map,
so there is no cold-start enrichment and no warm-up. And our energy manager puts no price on a
start; only its hysteresis keeps them apart. A real energy manager penalizes starts.

There are no emissions beyond fuel. In particular the catalyst cools down while the car drives
electrically, and a cold catalyst at restart costs emissions; we do not model it.

And our P4 drives the rear flanges through its own reduction; it is not torque vectoring. That comes
in a later lecture on the same platform.

The green box: your homework is the series hybrid on prepared ground, and the extra pack's fuel-cell
car is the same shape with another source.
-->
