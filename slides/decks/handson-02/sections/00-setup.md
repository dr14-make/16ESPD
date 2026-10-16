---
routeAlias: setup
layout: cover
---

# Drive a mapped engine

<h1 class="!text-5xl !-mt-4 opacity-70">Lecture 2 hands-on</h1>

Vehicle Systems &amp; Components

From a pedal to a manifold pressure to liters per hundred kilometers.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
**Before the room fills.** Deck on the projector, Dyad Studio on your laptop with your own
`MyCar` from hands-on 1 open on `main`. Open **presenter mode** from the nav bar now.

**Where this sits:** after the engine lecture. Its last section, "The mapped engine", promised
what we do today: a pedal, a throttle, a manifold pressure, and measured maps that return torque,
fuel and CO2. Today the students build it into the car they built in hands-on 1.

**Students follow the course page.** Put the link on the board: `handson/lecture-02/` on the
course site. The deck is for you.

**Timing:** about 90 minutes: setup 8, maps 12, manifold 15, map engine 20, car 12, cruise 12,
coast and brake 8, hand-in 3. Step 07 (WLTC) only if time is left. Deep links are by name:
`#/cruise` is step 05.

**If time runs short:** cut step 06's brake stop first, then step 02's 3000 rpm runs. Do not cut
step 05: the cruise numbers are the session's result.
-->

---

## Why we are here

<div class="grid grid-cols-2 gap-8">
<div>

Lecture 1's engine gave 150 N·m at every speed, 0.3 s late. It took the car to **246 km/h**,
and it could not say how much fuel that took.

A real engine answers two questions ours could not:

- **How much torque**, at this speed and this throttle?
- **How much fuel**, and so how much CO₂ per kilometer?

</div>
<div>

> **The ECU's answer: maps**
>
> A table measured on a test bench, read at **engine speed** and **manifold pressure**. The
> engine control unit does this hundreds of times a second.
>
> Today you read those maps, by hand and then in a model, and drive the car with them.

</div>
</div>

<!--
**Say:** Hands-on 1 ended with a promise. Our car reached 246 kilometers per hour, and we said
the number was wrong: a real engine gives its torque only in the middle of its speed range.
The engine lecture showed what a real engine control unit does instead. It measures the engine
speed and the pressure in the intake manifold, and looks both up in tables. Today we use real
tables, measured by the US EPA on a Mazda engine.

**Ask the room:** what does a car's sticker say about fuel? *(Liters per 100 km and grams of CO2
per km. By the end of today you will have both numbers for your own car at three speeds.)*
-->

---
routeAlias: what-we-build
---

## What we are building today

![The mapped engine: pedal to throttle, throttle air flow into the intake manifold whose state is the pressure p_m, the brake booster feeding air in as well, the cylinders drawing air out; maps read at engine speed and p_m return torque to the crankshaft and car, and fuel flow to the fuel and CO₂ outputs; engine speed feeds back to the maps and the cylinders.](/diagrams/00-mapped-engine.svg)

<!--
**Say:** This is the picture from the end of the lecture. Follow the air: the pedal opens the
throttle, air fills the manifold, the cylinders draw it out. The manifold pressure is what is
left: it is a state, and it takes time to change. The maps are read at speed and that pressure,
and give torque to the car and fuel to the tank gauge.

**Point at:** which boxes the students build. The manifold (step 02) and a small map engine
(step 03) are their own. The throttle and the cylinders are given, finished, from the course
library: they are physics the lecture stated, not what today teaches.

**Point at:** the dashed booster input. It is held at zero today. The brake lecture connects it.
-->

---

## Today

| # | Step | Min | You end with |
| --- | --- | --- | --- |
| <Link to="setup-library">00</Link> | Set up | 8 | the course library in `MyCar`, a `handson-02` branch |
| <Link to="maps">01</Link> | Read the maps | 12 | 4.6 L/100 km at 90 km/h — from the table, by hand |
| <Link to="manifold">02</Link> | Manifold | 15 | a pressure that fills: 33 kPa at idle |
| <Link to="map-engine">03</Link> | Map engine on a dynamometer | 20 | your own engine: 148 N·m at full load, 3000 rpm |
| <Link to="mapped-car">04</Link> | The car with a mapped engine | 12 | about 190 km/h flat out, not 246 |
| <Link to="cruise">05</Link> | Cruise: fuel and CO₂ | 12 | L/100 km and g CO₂/km at 50, 90, 130 km/h |
| <Link to="coast-brake">06</Link> | Coast-down and brake stop | 8 | fuel cut, and the vacuum for the brakes |
| <Link to="wltc">07</Link> | WLTC, if time allows | — | the car on a real test cycle |

<!--
**Say:** The same rhythm as hands-on 1: predict a number, build, check the model gives it. Step
01 predicts the most important number of the day, the fuel at 90 km/h, from the tables alone;
step 05 measures it.

**Point at:** step 04. That is the milestone, the same car as hands-on 1 with a real engine, and
it no longer reaches 246.

**Say:** Keep the names the page gives you: `engine`, `car`, `p_m`, `fuel_lph`. The plot commands
use them.
-->

---
routeAlias: setup-library
layout: section
---

###### Step 00 · 8 min

# Set up

A new branch on your `MyCar`, and the course library beside your own.

[page: step 00](../handson/lecture-02/#setup)

<!--
**Say:** Today's engine uses parts you will not build: the throttle, the cylinders' air flow and
the finished mapped engine. They live in the course library, `VehicleSystemsComponents`. You add
it to your library once, like the standard libraries in hands-on 1.

**Timing:** 8 minutes. The add downloads and precompiles; talk through step 01's maps while it
runs.

**TODO (rehearsal):** confirm that `Pkg.add(url = …)` is enough for Dyad Studio to list
`VehicleSystemsComponents` under **+**, or whether **Actions → Import Library** is needed. Pin the
add to a tag once the mapped engine (task 3) and the car (task 4) are merged, so students get the
engine the checkpoints were read from.
-->

---

## Branch, then add the course library

1. Status bar → switch to the branch that holds your car (`handson-01`, or where Lecture 1
   left it) → **Create new branch…** → `handson-02`.
2. **Dyad: Open Julia REPL**, then:

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD")
   ```

3. Julia Commands → **Dyad Compile**.
4. **+** in any diagram → `VehicleSystemsComponents` → `Vehicle` → `Engine`.

> **Checkpoint**
>
> `Engine` lists `AirPath`, `CylinderAirflow`, `MappedEngine` and `Throttle`.

Page: [Set up](../handson/lecture-02/#setup)

<!--
**Say:** One line in the REPL adds the course repository as a library. Its engine parts then
appear under the plus button like the standard ones.

**They get wrong:** branching from `main`, which holds only the empty library: step 04 then has
no `Car` to duplicate. Check a few status bars.

**If stuck:** a network error during the add: pair the student with a neighbor; step 01 needs
only the REPL and the CSV files, which come with the same add.

**TODO (screenshot):** `step00-engine-library.png`, the **+** tree opened at `Vehicle › Engine`.
-->
