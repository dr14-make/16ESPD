---
routeAlias: wheel-inertia
layout: section
---

###### Step 06 · 12 min

# A wheel with inertia

A 1 kg·m² wheel between gear and road — and how little it changes.

[page: step 06](../handson/lecture-01/#wheel-inertia) · reference `dyad/HandsOn/WheeledDriveline.dyad`, `WheeledCar.dyad`

<!--
**Tutor — one word:** *inertia* is how hard something is to spin up. It is measured in
kilogram-meters squared (kg·m²). The model's 1 kg·m² stands for a road wheel with its tire:
about 20 kg, most of it 0.2–0.3 m from the center.

**Say:** Until now the wheel had no weight of its own. Now it does, and the model tracks its
own spin. Today that spin is still tied to the car's speed. In step 9 we remove that link,
which lets the wheel spin on ice.

**Timing:** 12 minutes: 2 for the hidden-mass slide, 10 for copying three models and
adding one part.

**What students should see at the end:** two speed curves almost on top of each other.
100 km/h at 23.8 s instead of 23.6 s; the same 246.39 km/h at 300 s.
-->

---
routeAlias: hidden-mass
---

## The wheel's hidden mass

<div class="grid grid-cols-2 gap-8">
<div>

To speed up the car, the engine must also spin up the wheels. That costs
energy, as if the car were a little heavier.

Energy of a spinning wheel, with ω = v / r:

$$
\tfrac12 J\omega^2 \;=\; \tfrac12 J\frac{v^2}{r^2}
      \;=\; \tfrac12\,\underbrace{\Big(\frac{J}{r^2}\Big)}_{\text{extra mass}}\,v^2
$$

That is exactly the energy of a mass **J/r²** moving at
speed v.

</div>
<div>

#### Step 06: a wheel with J = 1 kg·m²

1 / 0.31² = 1 / 0.096 ≈ **10 kg** extra on a 1400 kg car:
0.7 % heavier.

- **23.6 → 23.8** s to 100 km/h

> **Starting, not top speed**
>
> At a steady speed nothing speeds up, so the extra mass does nothing. The top speed does
> not change.

</div>
</div>

<!--
**Ask the room first,** before you talk through the right half of the slide: how much
later will the car reach 100 km/h with a heavy wheel? Most guess a lot. *(0.2 s out of
23.6. Not every added detail matters; part of modeling is knowing which ones do. But the
wheel now has its own spin, and in step 09 that is what lets it slip.)*

**Say:** A bicycle with heavy wheels is slow to start, but rolls along
fine once it is moving. The car behaves the same way.

**Symbols:** J is the wheel's inertia, 1 kg·m². ω ("omega") is how fast the wheel turns, in
radians per second. r = 0.31 m is the wheel radius. v is the car's speed in m/s. The wheel
rolls without slipping, so ω = v / r.

**Derivation, step by step** (for a student who asks):

1. Moving energy of the car: ½·m·v².
2. Spinning energy of a wheel: ½·J·ω².
3. The wheel rolls, so ω = v / r. Substitute: ½·J·v²/r² = ½·(J/r²)·v².
4. Total energy = ½·(m + J/r²)·v². The engine has to supply it, so the car behaves as if
   its mass were m + J/r².

**The numbers:** J/r² = 1 / 0.0961 = 10.4 kg. 10.4 / 1400 = 0.74 %. Time to
100 km/h grows with mass, so 23.6 s × 1.0074 ≈ 23.8 s — step 06's checkpoint.

**If someone asks about the engine's own flywheel:** parts on the engine side spin i = 4
times faster, so they count i² = 16 times more: J<sub>e</sub>·i²/r². Our model
leaves them out.
-->

---

## Duplicate, insert, compare

<div class="grid grid-cols-2 gap-8">
<div>

![WheeledDriveline: an inertia block between the gear and the rolling wheel.](/img/step06-wheeled-driveline.png)

*Components → right-click → **Duplicate** · `inertia` Inertia(J = J_w), new parameter `J_w` = 1.0*

</div>
<div>

```julia [Julia REPL]
using Plots
a = MyCar.CarFullThrottleTransient()
b = MyCar.WheeledCarFullThrottleTransient()
p = plot(a; idxs = a."car.v_kmh", label = "Car")
plot!(p, b; idxs = b."car.v_kmh", label = "WheeledCar")
```

</div>
</div>

<!--
**Say:** We do not change the old car. We copy it and change the copy, so we can compare the
two.

**Steps** (all on the student page, with copyable code):

1. **Components** panel → right-click `Driveline` → **Duplicate** → name the copy
   `WheeledDriveline`.
2. In the copy, delete the wire `gear.spline_b` → `wheel.spline`. Press **+** and place
   `RotationalComponents › Components › Inertia` as `inertia`, between gear and wheel. Wire
   `gear.spline_b` → `inertia.spline_a` and `inertia.spline_b` → `wheel.spline`.
3. Add the parameter `J_w`, type `MomentOfInertia`, value `1.0`. Set the inertia's
   `J = J_w`.
4. Right-click `Car` → **Duplicate** → `WheeledCar`. Replace its `driveline` with a
   `WheeledDriveline`. The connection points are the same, so the wires stay.
5. Right-click `CarFullThrottle` → **Duplicate** → `WheeledCarFullThrottle`. Swap `car` for a
   `WheeledCar`. In code (⇄), add `initial car.driveline.inertia.phi = 0` at the end of
   `relations`. Save.
6. With `WheeledCarFullThrottle` open, ▷ **Run Analysis** → **TransientAnalysis**, name it
   `WheeledCarFullThrottleTransient`, `stop` = `300`. Run it with ▷ in the **Analyses**
   panel.
7. In the Julia REPL, type the five lines on the slide. `plot` draws the old car; `plot!`
   (with the "!") adds the new car to the same picture.

**They get wrong:** forgetting the new `initial` line. The wheel's angle (`phi`) is a new
quantity the simulation tracks over time, so it needs a starting value.
-->

---

## J / r² ≈ 10 kg

![Car and WheeledCar speed overlaid: the dashed WheeledCar curve lies almost exactly on the Car curve.](/img/step06-wheeled-car-plot.png)

- **23.6 → 23.8 s** to 100 km/h
- **246.39** km/h — unchanged

<!--
**What students should see:** two curves that are almost one. At 10 s the new car reads
43.27 km/h against 43.59 km/h for the old one. 100 km/h comes at 23.8 s instead of 23.6 s.
Both end at 246.39 km/h. Their line colors and styles may differ from the picture.

**Say:** Seen through the wheel's radius, a wheel inertia of 1 kilogram-meter squared
behaves like about 10 kilograms of extra mass on a 1400-kilogram car. That is the inertia
divided by the radius squared: 1 divided by 0.31 squared. Inertia slows the launch, not the
top speed. At constant speed nothing speeds up, so inertia does nothing.

**If a student's curves differ more than this:** check that `J_w` is 1.0, and that the
inertia sits between `gear` and `wheel` with the old direct wire removed. If the final speed
is not 246.39, the problem is in the parts copied from steps 02–05, not in the new wheel.
-->
