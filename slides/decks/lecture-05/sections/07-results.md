---
routeAlias: results
layout: section
---

###### Section 07

# Results

The WLTC for three powertrains on one car, and the five positions against the published studies,
each with its baseline.

`notebooks/lecture05/01-operating-points.pluto.jl` · `notebooks/lecture05/02-p-positions.pluto.jl`

<!--
Section 07: the results. There are two comparisons. First, the WLTC for three powertrains on one
car: the conventional car, your hybrid, and Lecture 4's electric car. Then the five machine
positions, against the three studies that the ICCT reviewed, and for each study its baseline, the
car it measured its savings against. That baseline is where most of the disagreement between
numbers comes from. You finish with build 04, the charge-sustaining WLTC.
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

MJ of gasoline into the engine against MJ out of the battery's terminals: the energy each car draws
from its own store, without the refinery, power station or grid.

</div>
<div>

<img src="/figures/07-three-powertrains.svg" class="w-full" style="max-height: 30rem" alt="WLTC fuel in L/100 km by phase for the conventional car, the same car with its CVT on the best-BSFC line, and the P2 hybrid SoC-corrected. Low: 7.13, 6.63 and 3.52. Medium: 5.77, 5.32 and 3.41. High: 5.12, 4.82 and 3.73. Extra High: 5.68, 5.59 and 5.00. Whole cycle: 5.72, 5.44 and 4.09. The hybrid saves most in the Low phase, about half, and least in Extra High."/>

<div class="caption">Fuel per WLTC phase, slowest to fastest. The hybrid saves most in Low, where
the conventional car idles and creeps.</div>

</div>
</div>

<!--
The first comparison: the three powertrains on the same cycle.

The conventional car is H0: the same planar car, with K0 closed while it moves and the hybrid
machine removed, so that the rows differ only in the powertrain. It uses 5.72 liters per 100
kilometers, 184.9 megajoules. The second row is build 02: the same engine-only car with its CVT on
the operating-line schedule. It uses 5.44 liters, 175.8 megajoules, 4.9 percent less, with no
electric machine. For scale, Lecture 2's car, on its own one-dimensional car model, burned 5.22.
Then the hybrid you finish today, with its fuel corrected for the change in the battery's charge:
4.09 liters, 132.1 megajoules, 28.5 percent less than H0. Its raw fuel is 4.11 liters. It ends with
a little more charge than it started with, so the correction takes a few hundredths off. And
Lecture 4's battery-electric car: no liters, and 47.2 megajoules per 100 kilometers at the battery's
terminals, the number from the end of Lecture 4.

Be careful what the megajoule column compares. For the three fuel rows it is the gasoline's heating
value going into the engine, with the hybrid's corrected for its change of charge. For the electric
car it is the electricity coming out of the battery's terminals. So it is the energy each car draws
from its own store. It does not count the whole chain from the oil well or the power station: it
leaves out the refinery, the power station, the grid and the charger. That is the same caveat as in
Lecture 4.

The figure splits the three fuel cars by WLTC phase. Across are the four phases, Low, Medium, High
and Extra High, from slowest to fastest, and the whole cycle on the right. Up is the fuel in liters
per 100 kilometers. Red is the conventional car, purple is the same car with its CVT on the
operating line, and green is the hybrid with its fuel corrected for the battery. Each phase is
charged its own fuel, and for the hybrid also the fuel equivalent of the battery energy it drew in
that phase, so its phases add up to the 4.09. The hybrid halves the Low phase, from 7.13 down to
3.52, because there it drives electrically while the conventional car idles and creeps. In Extra
High, where the engine is loaded anyway, it saves about 12 percent. The line car gains 6 to 8
percent in the first three phases, and under 2 in Extra High.
-->

---
routeAlias: baselines
---

## Whose baseline?

<div class="tight">

| Study | Baseline | Car | Gearbox |
|---|---|---|---|
| Schaeffler 2018 | **12 V stop/start** | compact (C-segment), 1.0 L 3-cylinder; 1.4 kWh battery | 7-speed dual-clutch |
| Chalmers (SAE 2019-01-0366) | **no stop/start** | compact (C-segment), 1300 kg + 50 kg, 1.5 L gasoline | 7-speed dual-clutch |
| TU Braunschweig 2018 | **stop/start** | compact (C-segment), 1520 kg | manual |
| **Ours** | **idles at stops** | Lecture 2's engine | CVT |

</div>

<div class="handson">A baseline without stop/start lets every hybrid also claim the stop/start
saving: 5.0 % on the WLTC in Chalmers' 12 V case. Our baseline idles, so our savings read high
against the stop/start studies.</div>

<!--
Before any table of savings, here is the question that decides it: saving against what? The
baseline is the car a study measures its saving against.

The three studies that the ICCT's 2022 review reproduces compare positions like for like, but each
against its own baseline. Schaeffler, 2018, compares against a 12 volt stop/start car: a C-segment
car with a 1.0 liter three-cylinder engine and a seven-speed dual-clutch gearbox, an automated
gearbox with two clutches, with a 1.4 kilowatt-hour battery in the hybrids. Chalmers, in the SAE
paper 2019-01-0366, compares against the same car without stop/start: a C-segment car of 1300
kilograms plus 50, with a 1.5 liter gasoline engine, again with a seven-speed dual-clutch gearbox.
TU Braunschweig, 2018, compares against stop/start: a 1520 kilogram C-segment car with a manual
gearbox.

And ours: Lecture 2's engine and CVT, idling at every stop. So ours is closest to Chalmers.

The green box says why this matters. A baseline without stop/start lets every hybrid also take the
credit for stopping the engine. In Chalmers' own numbers, a 12 volt stop/start alone saves 5.0
percent on the WLTC. Against a baseline that idles, our savings will read high next to Schaeffler
and Braunschweig. On top of that, our CVT can move the engine toward the line without a battery,
4.9 percent in build 02, which a stepped gearbox cannot do, so part of the operating-point saving
already belongs to the CVT. So we compare our table for ranking and order of magnitude, not to the
percent.
-->

---
routeAlias: p-position-table
---

## The five positions against the studies

<div class="tight">

| Position | ICCT 2022, WLTC CO₂, 15 kW | Ours, 30 kW, vs H0 |
|---|---|---:|
| P0 | 4–9 % (15–16 kW) | 15.74 % |
| P1 | 8.5–10.4 % | 21.10 % |
| P2 | 12–25 % | 28.53 % |
| P3 | 15–25 % | 28.65 % |
| P4 | ≈ 15.5 % (with a P0) | 28.53 % (ideal starter) |

</div>

**Ranking, all three studies:** P0 < P1 ≪ P2 ≈ P3 ≈ P4 <span class="text-xs opacity-70">(< below,
≪ far below, ≈ about equal)</span>

<img src="/figures/07-p-position-table.svg" class="w-full" alt="WLTC results per position, each with a 30 kW machine and a 270 V battery. Corrected fuel in L/100 km: P0 4.82, P1 4.51, P2 4.09, P3 4.08, P4 4.09. Saving against H0: 15.74, 21.10, 28.53, 28.65 and 28.53 percent; against the line car: 11.40, 17.03, 24.85, 24.97 and 24.84. Braking energy stored: 1.60, 2.14, 2.64, 2.72 and 2.72 MJ. Engine-off electric driving: 19.7 and 18.8 s for P0 and P1, about 531 to 534 s for P2, P3 and P4."/>

<div class="caption">Fuel before and after the battery correction · saving against three
baselines · braking energy stored and asked for · seconds with the engine off · engine starts</div>

<!--
The second comparison: the same parts, moved to the other four places in the driveline.

The left column is the band each position reaches in the three studies, at the 15 kilowatts they
compare at. It is the reference we check our results against. P0, with 15 to 16 kilowatts: 4 to 9
percent, with Schaeffler's 6.6 at 16 kilowatts and Chalmers' 8.9 at 15 among them. P1: 8.5 to 10.4.
P2: 12 to 25, and that spread comes mostly from the baseline, with or without stop/start. P3: 15 to
25. P4 with a P0 for starting: about 15.5, which is Schaeffler's number. The ranking is the same in
all three studies: P0 below P1, far below P2, P3 and P4, which are close to each other.

The right column is ours, from the P-positions notebook: the course car with today's 30 kilowatt
machine at each position, SoC-corrected, against H0. P0 saves 15.74 percent, P1 21.10, P2 28.53, P3
28.65, and P4 28.53. The ranking matches the studies: P0 below P1, far below P2, P3 and P4, which
are within 0.12 points of each other. Our P4 is not the studies' P4 plus P0. It is an electric rear
axle, and an ideal crank starter stands in for the P0, only to start the engine, with no second
machine to boost or recuperate. Our absolute numbers are higher than the bands, for two reasons: our
baseline idles, as the last slide explained, and our machine is twice the studies' size. We did not
run the positions at 15 kilowatts. Only P2 has a 15 kilowatt figure, 25.3 percent, from the
machine-size sweep.

The figure below is a table, one row per position, all at 30 kilowatts. It adds what a percentage
hides. Read the columns from left to right. Raw fuel and corrected fuel, in liters per 100
kilometers: before and after the correction for the battery's change of charge. Then three savings,
in percent. First against H0, the conventional car. Then against the line car, the engine-only car
with its CVT on the operating line from build 02. And then against the line car minus its idle
fuel: a rough stand-in for a car with stop/start, made by removing the fuel it burns while idling,
not by simulating one. Then two energies, in megajoules. Stored is the braking energy that really
reached the battery. Requested is the regen the manager asked for, before the losses in the
machine, the converter and, for P0, the belt. Then the electric seconds: how long the car drove
with the engine off. And starts: how many times the engine started.

The take-away is the electric column. P0 and P1 drive electrically for under 20 seconds; P2, P3 and
P4 for about 530.
-->

---
routeAlias: reading-the-table
---

## Reading the table

<div class="grid grid-cols-2 gap-8">
<div>

### What should agree

- The **ranking**: the coupled positions well below the decoupled ones.
- The **gap** P0 to P2 or P3: **15–16 percentage points** in Chalmers at 15 kW; ours
  **12.8–12.9** at 30 kW, not like for like.
- More power: 20–30 kW adds **5–10 %** on P2, P3, P4 (ICCT). Our P2, 15 → 30 kW: **25.3 → 28.5 %**;
  past 22 kW the machine already covers the regen and the low-power driving.

</div>
<div>

### What will differ, and why

- **Baseline**: ours idles; two of the three studies' cars stop.
- **Transmission**: our CVT alone saves 4.9 % by moving toward the line; theirs are stepped.
- **Strategy**: our five rules, not their carefully tuned controllers.
- **Car and engine**: Lecture 2's engine, not a 1.0 or 1.5 L DCT car.

</div>
</div>

<div class="handson">If our ranking disagrees, the model is wrong. If our percentages differ, read
the baseline first.</div>

<!--
Here is how to read the comparison.

First, what should agree. The ranking: the coupled positions, P0 and P1, well below the decoupled
ones. The size of the gap: in the Chalmers study, at 15 kilowatts on the WLTC, P2 is 15.6
percentage points above P0, and P3 is 16.1 above. Across the three studies, the gap between coupled
and decoupled positions ranges from about 7 to 16 points. Ours, at 30 kilowatts: P2 is 12.8 points above P0,
and P3 is 12.9 above. That is not like for like, since the studies' gap is at 15 kilowatts and we
ran the positions only at 30. And the effect of power: the ICCT finds that going from 15 to 20 or
30 kilowatts adds 5 to 10 percent on P2, P3 and P4, while P0 and P1 gain little, because their limit
is the coupled engine, not the machine. Ours gains less. The machine-size sweep of section 03 takes
our P2 from 25.3 percent at 15 kilowatts to 28.5 at 30, about 3 points, and most of that by 22
kilowatts. Once the machine covers the regen and the low-power driving, more power buys nothing.

Second, what will differ. The baseline: ours idles, while two of the three studies' cars stop. The
transmission: our CVT alone already moves the engine toward the line, 4.9 percent in build 02,
while the studies' dual-clutch and manual gearboxes leave more for the hybrid to gain. The
strategy: our five rules, against controllers that the studies tuned carefully. And the car and
the engine themselves.

The green box is the rule for me and for you. If our ranking disagrees with all three studies, our
model is wrong, and we look for the bug. If our percentages differ, read the baseline first.
-->

---
routeAlias: build-charge-sustaining
---

## Build 04: the charge-sustaining WLTC

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

![The meter in P2HybridWLTC: the powertrain's fuel flow and the vehicle speed wired in; the stored battery power enters as an equation.](/img/lecture-05/step04-charge-sustaining.png)

**Given:** the SoC-corrected fuel calculation (`SoCCorrectedFuel`)

[page: step 4](../lecture/lecture-05/#step-4) · reference `dyad/HandsOn05/P2HybridWLTC.dyad`

</div>
<div class="stack">

*Nothing new to wire: the fuel block is on the test model already · run the full 1800 s, read the
meter at the end · then the three cars side by side*

```txt
# keep, already on the bench: stored power, not terminal
meter.P_stored = powertrain.E * powertrain.i
# read at t = 1800 s
meter.fuel_raw   meter.fuel_corr   meter.energy_corr
```

<div class="handson">✓ SoC at the end within <b>± 2 %</b> of capacity of its start:
0.600 → <b>0.612</b> · L/100 km: conventional on this test model
<b>5.72</b> (Lecture 2: 5.22), hybrid SoC-corrected <b>4.09</b> (raw 4.11), <b>−28.5 %</b>
· MJ/100 km: conventional <b>184.9</b>, hybrid <b>132.1</b>,
battery-electric <b>47.2</b></div>

<img src="/img/lecture-05/step03-hybrid-wltc.png" style="max-height: 13rem" alt="The hybrid's WLTC run: the speed follows the trace; the SoC starts at 0.600, falls to 0.513, rises to at most 0.613 and ends at 0.612; the engine speed against its target, with long stretches at zero; the raw and the SoC-corrected fuel in L/100 km, apart early in the run and meeting near 4 at the end." />

<div class="caption">Top right: SoC ends near where it started · bottom right: raw and corrected fuel
meet once the battery is back</div>

</div>
</div>

<!--
Build 04: the charge-sustaining WLTC, the run that must end with the battery as full as it started.
On the left you see the fuel block on the hybrid test model in Studio. The powertrain's fuel flow
and the car's speed are wired into it, and the battery power enters as one line of code.

Your hybrid test model already carries the library's fuel block, SoCCorrectedFuel; it has been
wired in since the first build, and step 4 adds nothing to it. You run the full 1800 seconds and
read the meter only at the end. The block reads the engine's fuel flow, the power going into and
out of the battery's store, and the distance. The code line says how the stored power is computed:
E, the battery's open-circuit voltage, which is the voltage with no current flowing, times i, the
current. We use the stored power, not the terminal power, because the power at the terminals would
count the heat lost in the battery's resistance as charge the battery never holds. The block
reports the raw fuel, the net battery energy, and the SoC-corrected fuel, in liters and in
megajoules per 100 kilometers. Then you put the three cars side by side.

Now the checkpoint. First the honesty check: the state of charge at the end must be within 2
percent of capacity of where it started. Then the numbers: the SoC-corrected liters per 100
kilometers for the conventional car and the hybrid, and megajoules per 100 kilometers for all
three. The electric car's 47.2 comes from Lecture 4. The conventional car's 5.72 is this test
model's reference run, and Lecture 2's 5.22 is there to compare with. The hybrid starts at 0.600
and ends at 0.612, 1.2 points up, well inside the band. Its corrected fuel is 4.09 liters per 100
kilometers, raw 4.11, and 132.1 megajoules: 28.5 percent less than H0.

If your state of charge ends outside the band, then either the charge thresholds are too far apart,
or the charging power is too small for the cycle. In that case, your fuel figure is not one to
quote.

The plot under the checkpoint is the hybrid's WLTC run. Look at the top right: the state of charge
wanders down and up during the cycle, and ends near where it started. Now look at the bottom right:
the raw fuel and the corrected fuel are far apart early in the run, while the battery is drawn down,
and they meet at the end, once the battery is back.
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
electric car. Every saving is measured against a baseline, so always say which one; ours idles at
stops. And the three studies agree on the ranking, P0 below P1, far below P2, P3 and P4, and so must
our table.
-->
