---
routeAlias: manifold
layout: section
---

###### Step 02 · 15 min

# Manifold: a pressure that fills

Air in through the throttle, out into the cylinders; the pressure is what is left.

[page: step 02](../handson/lecture-02/#manifold) · reference `dyad/Vehicle/Engine/TestAirPath.dyad`

<!--
**Say:** The one equation this session is about. Hands-on 1 had a 0.3 second lag "because the
manifold has to fill". Today the manifold is a real volume, and the lag comes out of it, different
at every speed.

**Built or given:** students write the manifold, one equation. The throttle and the cylinders'
air flow are given from `Vehicle.Engine`: the throttle is a choked-flow orifice and the cylinders
use a volumetric efficiency that must match the maps exactly. Neither is today's lesson.

**Timing:** 15 minutes: 4 of theory, 3 to paste, 5 to draw the bench, 3 to run twice.

**TODO (reference):** the student versions `HandsOn02.Manifold`, `HandsOn02.AirPathStep` and
`HandsOn02.AirPathStepTransient` do not exist yet. The checkpoint numbers are already fixed by
`Vehicle.Engine.TestAirPath`, merged in #47, which uses the same equation.
-->

---
routeAlias: filling
---

## Mass in, mass out

<div class="grid grid-cols-2 gap-8">
<div>

The manifold is a box of air. Its pressure rises when more air comes in than goes out:

$$
\frac{V_m}{R\,T_m}\,\frac{dp_m}{dt} \;=\; \dot m_{\text{thr}} + \dot m_{\text{bst}} - \dot m_{\text{cyl}}
$$

- ***ṁ*<sub>thr</sub>** — through the throttle: the pedal opens it.
- ***ṁ*<sub>bst</sub>** — from the brake booster: zero today.
- ***ṁ*<sub>cyl</sub>** — into the cylinders: grows with *p<sub>m</sub>* and with speed.

</div>
<div>

#### Two numbers to find in your plot

| | closed throttle | settles in τ ≈ |
| --- | --: | --: |
| 800 rpm, idle | **33 kPa** | **0.15 s** |
| 3000 rpm, overrun | **13.5 kPa** | **0.03 s** |

Wide open, at any speed: **≈ 100 kPa**, the air outside.

> Lecture 1's engine lag was a fixed **0.3 s**. The real one is shorter, and depends on speed.

</div>
</div>

<!--
**Say:** Bath tub again, from hands-on 1. The throttle is the tap, the cylinders are the drain,
and the drain gets stronger the fuller the tub is. So the level settles where in equals out, and
it gets there with a time constant.

**Derivation of τ, if asked:**

1. Near a balance point, a small rise δp in pressure makes the cylinders draw more:
   δṁ_cyl = (∂ṁ_cyl/∂p_m)·δp. The throttle's flow does not change: below 53.5 kPa (0.528 × 101.3)
   it is choked, so its flow does not depend on p_m.
2. So (V_m/RT)·dδp/dt = −(∂ṁ_cyl/∂p_m)·δp, the lag equation, with τ = (V_m/RT) / (∂ṁ_cyl/∂p_m).
3. V_m/(R T_m) = 0.001 / (287 × 298) = 1.17·10⁻⁸ kg/Pa. At 800 rpm and 33 kPa, ∂ṁ_cyl/∂p_m ≈
   7.5·10⁻⁸ kg/(s·Pa). τ = 0.156 s.
4. At 3000 rpm the cylinders pump 3.75 × as often and breathe better: τ ≈ 0.034 s (theory deck,
   section 08).

**Why 33 kPa:** the idle air leak through the closed throttle was sized to give it
(`A_idle`, derived). Zero brake torque at 800 rpm falls at the same pressure on the map: the
air path and the maps agree.

**They get wrong:** expecting 0 kPa with the throttle closed. A closed throttle still leaks, and
the cylinders stop pulling once the pressure is low.
-->

---

## Paste the manifold, draw the bench

<div class="grid grid-cols-2 gap-6">
<div>

```julia [Manifold]
component Manifold
  mdot_thr = RealInput()
  mdot_bst = RealInput()
  mdot_cyl = RealInput()
  p_m = RealOutput()
  parameter V_m::Volume = 1.0e-3
  parameter T_m::Temperature = 298.15
  parameter R::Real = 287.05
  variable p::Pressure
relations
  V_m / (R * T_m) * der(p) = mdot_thr + mdot_bst - mdot_cyl
  p_m = p
end
```

</div>
<div>

**Bench `AirPathStep`** — from **+** → `VehicleSystemsComponents › Vehicle › Engine`:

<img src="/img/step02-airpath-bench.png" class="max-h-72 mx-auto" alt="AirPathStep: throttle_cmd into throttle, no_booster into the manifold, speed into cylinders; both flows into the manifold, and manifold.p_m back to throttle and cylinders.">

*`speed` = `Constant(k = 83.776)`, 800 rpm · `initial manifold.p = 101325`*

</div>
</div>

<!--
**Say:** The manifold has nothing to draw: three flows in, one pressure out, one equation. Paste
it, like the tire curve in hands-on 1. Then draw the bench around it with the two given parts.

**Point at:** the feedback wire. `p_m` goes back into the throttle and the cylinders, because both
flows depend on it. That loop is what makes the pressure settle.

**The slide omits the port annotations.** The page's `Manifold` carries a `{"Dyad": …}`
placement on each port: three inputs on the left edge, `p_m` on the right. Without them the four
ports stack in the middle of the `manifold` block and the bench cannot be wired. If a student's
ports stack, they pasted without them: paste the page's block again.

**They get wrong:** search "Manifold" also offers `IntakeManifold`, and "Throttle" offers four
throttles: take their own `MyCar › Manifold` and the plain `Vehicle › Engine › Throttle`. The
parts arrive as `step`, `constant1`, `constant2`, `throttle`, `cylinderairflow`, `manifold`;
rename them to the page's names. The icons do not name their inputs: hover a port. `Throttle`
has `u_thr` on top, `p_m` below; `CylinderAirflow` has `p_m` on top, `omega` below.

**They get wrong:** forgetting the initial line, or putting it after `metadata`. It goes after the
last `connect`. Without it the solver does not know the manifold starts full of outside air.

-->

---

## Run it twice

<div class="grid grid-cols-2 gap-8">
<div>

1. ▷ → **Create New Analysis** → `TransientAnalysis`, `AirPathStepTransient`, `stop = 3`. Run it with ▷.
2. **Idle:** `throttle_cmd` with `height = 0.005`, `start_time = 1`.
3. **3000 rpm:** `speed` `k = 314.159`, `throttle_cmd` `height = 1`. Run again.

```julia [Julia REPL]
r = MyCar.AirPathStepTransient()
plot(r; idxs = r."manifold.p_m")
```

</div>
<div>

> **Checkpoint**
>
> - idle: 101.3 → **33.0 kPa** within 1 s, then **37.3 kPa** after the small step
> - 3000 rpm: down to **13.5 kPa**, then **99.9 kPa** wide open
> - τ ≈ **0.15 s** on the small step at idle; the 3000 rpm curve settles about **5 ×** faster

Page: [Manifold](../handson/lecture-02/#manifold)

</div>
</div>

<!--
**Say:** One bench, two runs. At idle the pressure pulls down from the outside air to 33 kPa,
and a tiny throttle opening lifts it to 37. At 3000 rpm with the throttle closed it pulls down
much further, to 13.5: that is overrun, the vacuum the brake booster loves. Then wide open, and it
is back near the outside pressure.

**Where the numbers come from:** the test cases of `Vehicle.Engine.TestAirPath`: idle 32955.7 Pa,
idle step 37270 Pa, overrun 13482.4 Pa, tip-in 99889.9 Pa. A student manifold with the given
parts is the same equation, so it must give the same numbers.

**They get wrong:** plotting in pascals and reading 33000 as wrong. Divide by 1000.

**They get wrong:** calling `MyCar.AirPathStepTransient()` in a REPL opened before the component
existed: `UndefVarError`. Run once with ▷ on the analysis tab, which loads it, or restart the REPL.

**They get wrong:** reading τ on the first fall from 101 kPa. That fall is not a straight lag; its
1/e time is about 0.10 s. The 0.15 s is the small step at 1 s.

**Parameter fields:** click, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd>, type, <kbd>Enter</kbd>. <kbd>Ctrl</kbd>+<kbd>A</kbd>
selects the whole Studio page, and a triple-click does not select the old value.

**TODO (screenshot):** `step02-idle-plot.png`.
-->
