---
routeAlias: results
layout: section
---

###### Section 07

# Results

The WLTC for three powertrains on one car, and the five positions against the published studies,
each with its baseline.

<span class="todo">TODO: notebook files (#113, #114)</span>

<!--
Section 07, the results. Two comparisons. First the WLTC for three powertrains on one car: the
conventional car, your hybrid, and Lecture 4's electric car. Then the five machine positions,
against the three studies the ICCT reviewed, and for each study the baseline it measured against,
because that is where most of the disagreement between numbers comes from. You finish with build
04, the charge-sustaining WLTC.
-->

---
routeAlias: three-powertrains
---

## The WLTC, three ways

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

<div class="tight">

| Powertrain | L/100 km | MJ/100 km |
|---|---:|---:|
| conventional, same planar car (H0) | 5.72 | 184.9 |
| conventional, CVT on the operating line | 5.44 | 175.8 |
| P2 hybrid, SoC-corrected | 4.09 | 132.1 |
| battery-electric, Lecture 4 | — | 47.2 |

</div>

The hybrid saves **28.5 %** against H0; the line alone, **4.9 %**.

MJ of petrol into the tank against MJ out of the battery's terminals: the energy each car draws
from its store, not from the well or the grid.

</div>
<div>

<div class="placeholder">

**Figure: `07-three-powertrains.svg`**

WLTC energy per 100 km for the three cars, by phase, the hybrid SoC-corrected.

Produced by the charge-sustaining WLTC run, #113

</div>

</div>
</div>

<!--
The first comparison: the three powertrains on the same cycle.

The conventional car is H0: the same planar car, K0 locked once it moves and the hybrid machine removed, so the
rows differ only in the powertrain: 5.72 liters per 100 kilometers, 184.9 megajoules. The second
row is build 02: the same engine-only car with its CVT on the operating-line schedule, 5.44 liters,
175.8 megajoules, 4.9 percent less with no electric machine. For
scale, Lecture 2's car on its own, one-dimensional bench burned 5.22. The hybrid you finish today,
with its fuel corrected for the change in the battery's charge: 4.09 liters, 132.1 megajoules, 28.5
percent less than H0. Its raw fuel is 4.11 liters; it ends with a little more charge than it
started, so the correction takes a few hundredths off. The battery-electric car of Lecture 4:
no liters, 47.2 megajoules per 100 kilometers at the battery's terminals, from Lecture 4's wrap-up.

Be careful what the megajoule column compares. For the three fuel rows it is the petrol's heating
value going into the engine, the hybrid's corrected for its change of charge; for the electric car
it is the electricity coming out of the battery's terminals. It is the energy each car draws from
its own store. It is not well-to-wheel: it leaves out the refinery, the power station, the grid and
the charger. That is the same caveat as in Lecture 4.

The table has the reference run's totals. The figure, the same three cars split by WLTC phase, is
still to be drawn from that run.
-->

---
routeAlias: baselines
---

## Whose baseline?

<div class="tight">

| Study | Baseline | Car | Gearbox |
|---|---|---|---|
| Schaeffler 2018 | **12 V stop/start** | C-segment, 1.0 L 3-cylinder; 1.4 kWh battery | 7-speed DCT |
| Chalmers (SAE 2019-01-0366) | **no stop/start** | C-segment, 1300 kg + 50 kg, 1.5 L petrol | 7-speed DCT |
| TU Braunschweig 2018 | **stop/start** | C-segment, 1520 kg | manual |
| **Ours** | **idles at stops** | Lecture 2's engine | CVT |

</div>

<div class="handson">A baseline without stop/start lets every hybrid also claim the stop/start
saving: 5.0 % on the WLTC in Chalmers' 12 V case. Our baseline idles, so our savings read high
against the stop/start studies.</div>

<!--
Before any table of savings, the question that decides it: saving against what?

The three studies the ICCT's 2022 review reproduces compare positions like for like, but each
against its own baseline. Schaeffler, 2018: against a 12 volt stop/start car, a C-segment car with a
1.0 liter three-cylinder and a seven-speed dual-clutch gearbox, with a 1.4 kilowatt-hour battery in
the hybrids. Chalmers, the SAE paper 2019-01-0366: against the same car without stop/start, a
C-segment car of 1300 kilograms plus 50, with a 1.5 liter petrol engine, again a seven-speed
dual-clutch. TU Braunschweig, 2018: against stop/start, a 1520 kilogram C-segment car with a manual
gearbox.

Ours: Lecture 2's engine and CVT, idling at every stop. So ours is closest to Chalmers.

The green box is why it matters. A baseline without stop/start lets every hybrid also take the
credit for stopping the engine: in Chalmers' own numbers, a 12 volt stop/start alone saves 5.0
percent on the WLTC. Against a baseline that idles, our savings will read high next to Schaeffler
and Braunschweig. And our CVT can move the engine toward the line without a battery, 4.9 percent in
build 02, which a stepped gearbox cannot, so part of the operating-point saving is already the
CVT's. The plan therefore compares our table for ranking and order of magnitude, not to the percent.
-->

---
routeAlias: p-position-table
---

## The five positions against the studies

<div class="grid grid-cols-[1.2fr_1fr] gap-6 items-start">
<div class="tight">

| Position | ICCT 2022, WLTC CO₂, 15 kW | Ours, 15 kW | Ours, 30 kW |
|---|---|---:|---:|
| P0 | 4–9 % (15–16 kW) | <span class="todo">TODO</span> | <span class="todo">TODO</span> |
| P1 | 8.5–10.4 % | <span class="todo">TODO</span> | <span class="todo">TODO</span> |
| P2 | 12–25 % | <span class="todo">TODO</span> | <span class="todo">TODO</span> |
| P3 | 15–25 % | <span class="todo">TODO</span> | <span class="todo">TODO</span> |
| P4 (+P0) | ≈ 15.5 % | <span class="todo">TODO</span> | <span class="todo">TODO</span> |

**Ranking, all three studies:** P0 < P1 ≪ P2 ≈ P3 ≈ P4

</div>
<div>

<div class="placeholder">

**Figure: `07-p-position-table.svg`**

WLTC fuel saving, recovered energy and available modes per position, at 15 and 30 kW, with the
ICCT bands shaded.

Produced by the P-position notebook, #114

</div>

</div>
</div>

<!--
The second comparison, and the demo: the same parts on the other four flanges.

The left column is the band each position reaches in the three studies, at the 15 kilowatts they
compare at; it is the reality-anchor table of the plan. P0, with 15 to 16 kilowatts: 4 to 9 percent,
Schaeffler's 6.6 at 16 kilowatts and Chalmers' 8.9 at 15 among them. P1: 8.5 to 10.4. P2: 12 to 25;
that spread is mostly the baseline, with or without stop/start. P3: 15 to 25. P4 with a P0 for
starting: about 15.5, Schaeffler's number. The ranking is the same in all three studies: P0 below
P1, far below P2, P3 and P4, which are close to each other.

The two right columns are ours, from the P-position notebook of issue 114: the course car with the
machine at each position, at 15 kilowatts, the studies' size, and at 30 kilowatts, today's. They are
TODO until the benches run. What I expect, and what the notebook's test asserts, is the ranking. The
absolute numbers should land in the same order of magnitude, high against the stop/start studies for
the reason on the last slide.

The figure will add what a percentage hides: how much braking energy each position recovered, and
which modes it could use at all.
-->

---
routeAlias: reading-the-table
---

## Reading the table

<div class="grid grid-cols-2 gap-8">
<div>

### What should agree

- The **ranking**: the coupled positions well below the decoupled ones.
- The **gap** at 15 kW: about **15–16 points** between P0 and P2 or P3 in Chalmers.
- More power helps the decoupled positions most: 20–30 kW adds **5–10 %** on P2, P3, P4.

</div>
<div>

### What will differ, and why

- **Baseline**: ours idles; two of the three studies' cars stop.
- **Transmission**: our CVT alone saves 4.9 % by moving toward the line; theirs are stepped.
- **Strategy**: our five rules, not their calibrated controllers.
- **Car and engine**: Lecture 2's engine, not a 1.0 or 1.5 L DCT car.

</div>
</div>

<div class="handson">If our ranking disagrees, the model is wrong. If our percentages differ, read
the baseline first.</div>

<!--
How to read the comparison when it arrives.

What should agree. The ranking: the coupled positions, P0 and P1, well below the decoupled ones. The
size of the gap: in the Chalmers study, at 15 kilowatts on the WLTC, P2 is 15.6 points above P0 and
P3 16.1; the research note puts the coupled-to-decoupled gap at about 7 to 15 points across the
three studies. And the effect of power: the ICCT finds that going from 15 to 20 or 30 kilowatts adds 5
to 10 percent on P2, P3 and P4, while P0 and P1 gain little, because their limit is the coupled
engine, not the machine. Our 15 and 30 kilowatt columns test exactly that.

What will differ. The baseline: ours idles. The transmission: our CVT alone already moves the engine
toward the line, 4.9 percent in build 02, while the studies' dual-clutch and manual gearboxes leave
more for the hybrid to gain. The strategy: our five rules against controllers the studies calibrated. And the car and
engine themselves.

The green box is the rule for the lecturer and for you. If our ranking disagrees with all three
studies, our model is wrong, and we look for the bug. If our percentages differ, read the baseline
first.
-->

---
routeAlias: build-charge-sustaining
---

## Build 04: the charge-sustaining WLTC

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

<div class="placeholder">

**Screenshot: `step04-charge-sustaining.png`**

The hybrid WLTC bench with the SoC-corrected fuel block reading the fuel flow, the battery power
and the distance.

Captured with the build guide, #113

</div>

**Given:** the SoC-corrected fuel calculation (#199)

[page: step 4](../lecture/lecture-05/#step-4) · reference `dyad/HandsOn05/P2HybridWLTC.dyad`

</div>
<div class="stack">

*Nothing new to wire: the fuel block is on the bench already · run the full 1800 s, read the
meter at the end · then the three cars side by side*

```txt
# keep, already on the bench: stored power, not terminal
meter.P_stored = powertrain.E * powertrain.i
# read at t = 1800 s
meter.fuel_raw   meter.fuel_corr   meter.energy_corr
```

<div class="handson">✓ SoC at the end within <b>± 2 %</b> of capacity of its start:
0.600 → <b>0.612</b> · L/100 km: conventional on this bench
<b>5.72</b> (Lecture 2: 5.22), hybrid SoC-corrected <b>4.09</b> (raw 4.11), <b>−28.5 %</b>
· MJ/100 km: conventional <b>184.9</b>, hybrid <b>132.1</b>,
battery-electric <b>47.2</b></div>

</div>
</div>

<!--
Build 04: the charge-sustaining WLTC. The screenshot comes with the build guide of issue 113.

Your hybrid bench already carries the library's fuel block from issue 199, wired since the first
build; step 4 adds nothing to it. You run the full 1800 seconds and read the meter only at the end.
The block reads the engine's fuel flow, the power into and out of
the battery's store, open-circuit voltage times current, and the distance. Stored, not terminal:
the terminal power would count the battery's resistance loss as charge it never holds. The block
reports the raw fuel, the net battery energy and the SoC-corrected fuel, in liters and in
megajoules per 100 kilometers. Then you put the three cars side by side.

The checkpoint, from the plan. First the honesty check: the state of charge at the end must be
within 2 percent of capacity of its start. Then the numbers: the SoC-corrected liters per 100
kilometers for the conventional car and the hybrid, and megajoules per 100 kilometers for all three.
The electric car's 47.2 is Lecture 4's. The conventional car's 5.72 is this bench's reference run;
Lecture 2's 5.22 is there to compare with. The hybrid starts at 0.600 and ends at 0.612, 1.2 points
up, well inside the band. Its corrected fuel is 4.09 liters per 100 kilometers, raw 4.11, and 132.1
megajoules: 28.5 percent less than H0.

If your state of charge ends outside the band, the charge thresholds are too far apart or the charge
power too small for the cycle; the fuel figure is then not one to quote.
-->

---

## Summary of section 07

- Three powertrains on one car and one cycle: **184.9**, **132.1** and **47.2 MJ/100 km**.
- Every saving is against a baseline: **say which**. Ours idles at stops.
- The studies agree on the ranking, **P0 < P1 ≪ P2 ≈ P3 ≈ P4**, and so must we.

### Next: <Link to="wrap-up">→ 08, wrap-up</Link>

<!--
Section 07 in three lines. Three powertrains on one car and one cycle: 184.9 megajoules per 100
kilometers for the conventional car, 132.1 for the hybrid of your build 04, and 47.2 for the
electric car. Every saving is against a baseline, so say which; ours idles at stops. And the three
studies agree on the ranking, P0 below P1, far below P2, P3 and P4, and so must our table.
-->
