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
- **05** The CVT holds the engine on its best-BSFC line; the machine shifts the load.
- **06** Five rules, two latches, charge-sustaining within ± 2 %.
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

05: the CVT holds the engine on its best-BSFC line, and the machine shifts the load.

06: five rules, two latches, and a result that is charge-sustaining within 2 percent.

07: the ranking P0 below P1, far below P2, P3 and P4, and every saving stated against its baseline.
-->

---
routeAlias: what-you-measured
---

## What you measured on your own car

<div class="tight">

| Step | You built | You measured |
|---|---|---|
| 01 | the P2 powertrain | engine only and electric only follow the WLTC: <span class="todo">TODO</span> |
| 02 | the operating line | engine points on the best-BSFC line: <span class="todo">TODO</span> |
| 03 | the energy manager | modes without chatter, SoC in its window: <span class="todo">TODO</span> |
| 04 | the charge-sustaining WLTC | SoC-corrected L/100 km and MJ/100 km: <span class="todo">TODO</span> |

</div>

<!--
What you measured, one row per step, with the checkpoint numbers once the reference model has
produced them. Step 01, the P2 powertrain, following the WLTC engine only and electric only. Step
02, the engine's points on its best-BSFC line. Step 03, the modes switching without chatter and the
state of charge in its window. Step 04, the charge-sustaining WLTC, in corrected liters and in
megajoules per 100 kilometers.
-->

---
routeAlias: known-limits
---

## What the model leaves out

- **No stepped gearbox**, no shift logic: the CVT's ratio is free. A stepped gearbox is in the
  extra pack.
- **No engine start dynamics** and no start fuel: every restart is free.
- **No emissions beyond fuel**: the catalyst cooling down during electric driving is not modeled.
- **P4 is not torque vectoring**: it drives the rear flanges through its own reduction.

<div class="handson">Homework: the series hybrid, on prepared ground. Extra pack: the fuel-cell car,
the same shape with another source.</div>

<!--
What the model leaves out, from the plan's known limits.

There is no stepped gearbox and no shift logic: the CVT's ratio is free. The Sonata's P2 sits in a
six-speed automatic, and the studies of section 07 use dual-clutch and manual gearboxes; the stepped
gearbox is in the extra pack.

There are no engine start dynamics and no fuel to start the engine: every restart is free. A real
energy manager penalizes starts, which is one more reason for hysteresis.

There are no emissions beyond fuel. In particular the catalyst cools down while the car drives
electrically, and a cold catalyst at restart costs emissions; we do not model it.

And our P4 drives the rear flanges through its own reduction; it is not torque vectoring. That comes
in a later lecture on the same platform.

The green box: your homework is the series hybrid on prepared ground, and the extra pack's fuel-cell
car is the same shape with another source.
-->
