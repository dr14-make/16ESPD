---
routeAlias: wheel-inertia
layout: section
---

###### Step 06 · 12 min

# A wheel with inertia

A 1 kg·m² wheel between gear and road — and how little it changes.

[page: step 06](../handson/lecture-01/#wheel-inertia) · reference `dyad/HandsOn/WheeledDriveline.dyad`, `WheeledCar.dyad`

<!--
**Say:** The wheel now has its own state: its own speed. Today that speed
is still tied to the car's speed. In step 9 we cut that tie, and that is where ice
happens.

**Timing:** 12 minutes: 2 for the hidden mass, 10 for Duplicate and one wire.
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
**Say:** A bicycle with heavy wheels feels sluggish when you start, but
rolls along fine once it is moving. It is the same here.

**Derivation, step by step**

1. Moving energy of the car: ½·m·v².
2. Spinning energy of a wheel: ½·J·ω², where J (kg·m²) is how hard it is to spin up.
3. The wheel rolls, so ω = v / r. Substitute: ½·J·v²/r² = ½·(J/r²)·v².
4. Total energy = ½·(m + J/r²)·v². The engine has to supply it, so the car behaves as if
   its mass were m + J/r².

**The numbers:** J/r² = 1 / 0.0961 = 10.4 kg. 10.4 / 1400 = 0.74 %. Time to
100 km/h scales with mass, so 23.6 s × 1.0074 = 23.8 s — step 06's checkpoint.

**If someone asks about the engine's own flywheel:** parts on the engine
side spin i times faster, so they count i² = 16 times more: J<sub>e</sub>·i²/r². Our model
leaves them out.

**Ask the room first,** before showing the numbers: how much slower will the
car be? Most guess a lot. *(0.2 s out of 23.6. Not every added detail matters — knowing
which ones do is the skill. But the wheel now has its own speed, and in step 08 that is what
lets it spin.)*
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
using MyCar, Plots
a = MyCar.CarFullThrottleTransient()
b = MyCar.WheeledCarFullThrottleTransient()
p = plot(a; idxs = a."car.v_kmh", label = "Car")
plot!(p, b; idxs = b."car.v_kmh", label = "WheeledCar")
```

</div>
</div>

<!--
**Steps:** Duplicate `Driveline` → `WheeledDriveline`,
insert the inertia. Duplicate `Car` → `WheeledCar`, swap the
driveline. Duplicate the bench, swap the car, add
`initial car.driveline.inertia.phi = 0`, paste the analysis. The page has all of
it as copyable code.

**They get wrong:** forgetting the new initial line. The wheel's angle is a
new state and needs a start.
-->

---

## J / r² ≈ 10 kg

![Car and WheeledCar speed overlaid: the dashed WheeledCar curve lies almost exactly on the Car curve.](/img/step06-wheeled-car-plot.png)

- **23.6 → 23.8 s** to 100 km/h
- **246.39** km/h — unchanged

<!--
**Ask the room first:** before showing the plot, how much slower will the
car be? Most guess a lot.

**Say:** Seen through the rolling radius, a wheel inertia of 1
kilogram-meter squared behaves like about 10 kilograms of extra mass on a 1400-kilogram
car. That is the inertia divided by the radius squared: 1 divided by 0.31 squared. Inertia
slows the launch, not the top speed. At constant speed nothing accelerates, so inertia
does nothing.
-->
