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
| conventional, Lecture 2 | 5.22 | 168.8 |
| P2 hybrid, SoC-corrected | <span class="todo">TODO</span> | <span class="todo">TODO</span> |
| battery-electric, Lecture 4 | — | 47.2 |

</div>

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

The conventional car, Lecture 2's: 5.22 liters per 100 kilometers, 168.8 megajoules per 100
kilometers of petrol. The hybrid you finish today, with its fuel corrected for the change in the
battery's charge: TODO until the reference run of issue 113. The battery-electric car of Lecture 4:
no liters, 47.2 megajoules per 100 kilometers at the battery's terminals, from Lecture 4's wrap-up.

Be careful what the megajoule column compares. For the two fuel cars it is the petrol's heating
value going into the engine; for the electric car it is the electricity coming out of the battery's
terminals. It is the energy each car draws from its own store. It is not well-to-wheel: it leaves
out the refinery, the power station, the grid and the charger. That is the same caveat as in
Lecture 4.

The figure will show the three by WLTC phase. Watch the Low phase: that is where the conventional car
is worst, and where the hybrid's electric driving and regen should gain the most.
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

The green box is why it matters. A baseline without stop/start lets every hybrid also take the credit
for stopping the engine: in Chalmers' own numbers, a 12 volt stop/start alone saves 5.0 percent on
the WLTC. Against a baseline that idles, our savings will read high next to Schaeffler and
Braunschweig. And our CVT already holds the engine better than a stepped gearbox would, which takes
some of the operating-point saving away from the hybrid. The plan therefore compares our table for
ranking and order of magnitude, not to the percent.
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
- The **gap** at 15 kW: about **7–15 points** between coupled and decoupled.
- More power helps the decoupled positions most: 20–30 kW adds **5–10 %** on P2, P3, P4.

</div>
<div>

### What will differ, and why

- **Baseline**: ours idles; two of the three studies' cars stop.
- **Transmission**: our CVT already sits near the line; theirs are stepped.
- **Strategy**: our five rules, not their calibrated controllers.
- **Car and engine**: Lecture 2's engine, not a 1.0 or 1.5 L DCT car.

</div>
</div>

<div class="handson">If our ranking disagrees, the model is wrong. If our percentages differ, read
the baseline first.</div>

<!--
How to read the comparison when it arrives.

What should agree. The ranking: the coupled positions, P0 and P1, well below the decoupled ones. The
size of the gap: the research note's takeaway puts it at about 7 to 15 points on the WLTC at 15
kilowatts. And the effect of power: the ICCT finds that going from 15 to 20 or 30 kilowatts adds 5
to 10 percent on P2, P3 and P4, while P0 and P1 gain little, because their limit is the coupled
engine, not the machine. Our 15 and 30 kilowatt columns test exactly that.

What will differ. The baseline: ours idles. The transmission: our CVT already holds the engine
close to the line, while the studies' dual-clutch and manual gearboxes leave more for the hybrid to
gain. The strategy: our five rules against controllers the studies calibrated. And the car and
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

<span class="todo">TODO: guide link · reference `dyad/HandsOn05/…`</span>

</div>
<div class="stack">

*The full hybrid on the WLTC bench · the fuel block on the fuel flow, the battery's terminal
power and the distance · then the three cars side by side*

```julia
# TODO: snippet from the build guide (#113)
```

<div class="handson">✓ SoC at the end within <b>± 2 %</b> of capacity of its start:
<span class="todo">TODO ΔSoC</span> · L/100 km: conventional on this bench
<span class="todo">TODO</span> (Lecture 2: 5.22), hybrid SoC-corrected <span class="todo">TODO</span>
· MJ/100 km: conventional <span class="todo">TODO</span>, hybrid <span class="todo">TODO</span>,
battery-electric <b>47.2</b></div>

</div>
</div>

<!--
Build 04: the charge-sustaining WLTC. The screenshot comes with the build guide of issue 113.

You put your full hybrid, with its operating line and its energy manager, on the WLTC bench, and add
the library's fuel block from issue 199. It reads the engine's fuel flow, the battery's terminal
power and the distance, and reports the raw fuel, the net battery energy and the SoC-corrected fuel,
in liters and in megajoules per 100 kilometers. Then you put the three cars side by side.

The checkpoint, from the plan. First the honesty check: the state of charge at the end must be
within 2 percent of capacity of its start. Then the numbers: the SoC-corrected liters per 100
kilometers for the conventional car and the hybrid, and megajoules per 100 kilometers for all three.
The electric car's 47.2 is Lecture 4's. The conventional car's number on this bench comes from the
reference run and is still TODO; Lecture 2's 5.22 is there to compare with. The hybrid's are TODO until the reference run.

If your state of charge ends outside the band, the charge thresholds are too far apart or the charge
power too small for the cycle; the fuel figure is then not one to quote.
-->

---

## Summary of section 07

- Three powertrains on one car and one cycle: **168.8**, <span class="todo">TODO</span> and
  **47.2 MJ/100 km**.
- Every saving is against a baseline: **say which**. Ours idles at stops.
- The studies agree on the ranking, **P0 < P1 ≪ P2 ≈ P3 ≈ P4**, and so must we.

### Next: <Link to="wrap-up">→ 08, wrap-up</Link>

<!--
Section 07 in three lines. Three powertrains on one car and one cycle: 168.8 megajoules per 100
kilometers for the conventional car, the hybrid's number from your build 04, and 47.2 for the
electric car. Every saving is against a baseline, so say which; ours idles at stops. And the three
studies agree on the ranking, P0 below P1, far below P2, P3 and P4, and so must our table.
-->
