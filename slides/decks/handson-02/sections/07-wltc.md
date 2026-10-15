---
routeAlias: wltc
layout: section
---

###### Step 07 · if time allows

# WLTC: the test cycle

The same engine with a gearbox and a driver, following the 30-minute trace a car's label is
measured on.

[page: step 07](../handson/lecture-02/#wltc)

<!--
**Say:** Steady cruise is not how anyone drives, and it is not how the label is measured. The WLTC
is a speed trace, 30 minutes long, through town, suburb, road and motorway. To follow it the car
needs gears and a driver who presses the pedal to track the trace.

**Only if time allows.** If the session has no room, point students at the prepared notebook and
stop at the hand-in.

**TODO (whole step):** depends on task 6 (scope B: gearbox, shift schedule, PI driver, WLTC class
3 trace from DieselNet). Fill in the model names, the checkpoint (L/100 km and g CO₂/km over the
cycle) and a real 1.5 L car's label figure with its source once task 6 exists.
-->

---

## What changes, and what to compare

<div class="grid grid-cols-2 gap-8">
<div>

- **A gearbox** with 5 or 6 ratios and a shift schedule: the engine stays near its efficient
  middle.
- **A driver:** a PI controller from speed error to pedal — Lecture 1's cruise control, steering a
  speed trace instead of a setpoint.
- **The trace:** WLTC class 3, 1800 s, up to 131 km/h.

</div>
<div>

> **Compare**
>
> Your L/100 km and g CO₂/km over the whole cycle against a real 1.5 L petrol car's label.
>
> Expect yours to be a little lower: no cold start, no auxiliaries, no driver who overshoots.

</div>
</div>

<!--
**Say:** Three additions, all things you have seen. The driver is the cruise controller of
Lecture 1. The gearbox is the driveline of hands-on 1 with a choice of ratios. The trace is a
table of speed against time.
-->
