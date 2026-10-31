---
title: Lecture 3 — build an ABS of your own
---

[← Vehicle Systems & Components](../../index.html) · [Lecture deck →](../../lecture-03/index.html){target="_self"}

# Lecture 3: build an ABS of your own

From a car whose wheel locks under a panic stop to an ABS that sees only the wheel speed, tested on dry, wet and snowy roads

**What you build.** Your `MyCar` from the [hands-on](../../handson/lecture-01/) has a `Body`. In this lecture you put it on the course library's brakes and brake it from 90 km/h, along with the lecturer: first through a brake system you wire from the pedal to the wheel, with no ABS, then with a slip controller of your own, then with an ABS that knows only the wheel speed. Every number the lecture's ABS slides show comes out of a model on your own screen. Step 01 is on paper; step 02 wires the brake system; steps 03–04 each add a controller and its bench; step 05 is a table from the REPL. Traction control is a bonus task to take home. ESP is a demo: nothing to build.

**How each step works.** The slide that introduces a step shows the finished diagram or code, names the library parts it uses, and links here. Each step below lists the blocks to place with their library path, instance name and values, every wire and line of code, and what the plot and the braking distance must show before you go on. Use the names given here: the steps after it read signal paths like `abs.p_cmd` and `est.v_ref`, and the REPL loop of step 05 calls your analyses by name.

**Given parts.** You build the benches and the controllers; the brake system, the wheel, the valves and the pressure integrator come finished from the course library. The step where a part first appears has a **Given parts** box: what the part models, its ports, the parameters that matter and where their values come from.

**Fell behind?** Every step ends with a **Fell behind?** block: the finished code of that step, to paste. The course repository has the same components as the reference answers in `dyad/HandsOn03/`, under the same names; under **+** they show as `VehicleSystemsComponents › HandsOn03`. Build your own; open them only to compare.

**Plotting.** Every plot is drawn in the Julia REPL: click **Dyad: Open Julia REPL** in the **Actions** panel's title bar. Each snippet starts with `using Plots; plotly()`, which switches Plots to its interactive backend. Snippets do not load `MyCar`: the REPL reloads it when you run an analysis from Studio. So each time you add an analysis, click ▷ **Run Analysis** and pick it once before you paste a snippet that calls it; until then the snippet fails with ``UndefVarError: `PedalStopTransient` not defined in `Main.MyCar` ``. The plots show pressures in Pa: 1 bar is 10⁵ Pa, so 89 bar reads 8.9×10⁶.

**Solver.** Every analysis today runs **Tsit5** with a maximum step of 1 ms (`dtmax = 1e-3`). The ABS switches the brake every few milliseconds behind a 30 ms lag; a stiff solver such as FBDF steps over the switching and reports a wrong success.

Every number in an expected result is a test expectation or a measured run of the reference model, with Tsit5 at `dtmax = 1e-3`.

**00 — Before the first section**

- [00 · Set up: the course library](#step-00)

**01 — Friction and stopping**

- [01 · The tire's limit, by hand](#step-01)

**02 — How the brakes work**

- [02 · Pedal to wheel](#step-02)

**03 — Anti-lock braking**

- [03 · An ABS of your own](#step-03)
- [04 · Only the wheel speed](#step-04)
- [05 · Across road surfaces](#step-05)

**04 — Traction control**

- [06 · Take-home bonus: traction control](#step-06)

## 00 Set up

Lecture deck: [front matter](../../lecture-03/index.html#/build-setup){target="_self"}

### 00 · Set up: the course library {#step-00}

Today's parts, the brake system, the braked wheels and the pressure integrator, are in the course library. Your `MyCar` needs a version that has them, and the fluid library `HydraulicComponents`.

::: details No MyCar of your own, or yours does not compile? Start from the course's.

Today needs only hands-on 1's car. The course's `MyCar` repository has it at the tag `lecture-03-start`: the finished hands-on 1 car, with nothing of today's work. Fork it and work on your fork; do this before class if you can.

1. On github.com, open [`dr14-make/MyCar`](https://github.com/dr14-make/MyCar) and click **Fork**. Untick **Copy the `main` branch only**, so the fork gets the tag too, then click **Create fork**. The fork is `https://github.com/<you>/MyCar`.
2. In Studio, press <kbd>F1</kbd> → **Git: Clone**, paste your fork's URL, pick an empty folder, and click **Open** when asked.
3. Press <kbd>F1</kbd> → **Git: Create Branch From…**, type `lecture-03`, and pick the tag `lecture-03-start` from the list.
4. In the **Actions** panel's title bar, click **Dyad: Open Julia REPL** and run the lines below. The first download takes a few minutes; wait until it stops printing.

   ```julia
   using Pkg
   Pkg.instantiate()
   ```

5. Go on with step 2 of **Do this** below: your `lecture-03` branch already exists, so skip step 1.

Your commits go to your fork, one per step, and the pull request at the end goes from `lecture-03` to your fork's `main`.

:::

#### Do this

1. In the status bar, click the branch name → **Create new branch…** → `lecture-03`, from `main`. If you finished hands-on 2, branch from where it left you. If not, `main` is enough: today needs only hands-on 1's `Body`.
2. Open the Julia REPL and move the course library to the Lecture 3 version for Dyad 3.5. If you did hands-on 2, you added the library then, and your `Manifest.toml` still holds the version from that day, without today's parts. Started from `main`? `MyCar` has no course library yet, and the same line adds it. The second line adds `HydraulicComponents`: in step 02 your own bench declares the brake fluid, so `MyCar` needs the package itself.

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "lecture-03-dyad-3.5")
   Pkg.add("HydraulicComponents")
   ```

3. <kbd>F1</kbd> → **Dyad: Restart Language Server**. The language server read your `Project.toml` when Studio started; until it restarts, the next compile flags every library part with `missing-direct-dependency … not a direct dependency`.
4. <kbd>F1</kbd> → **Dyad: Compile**.
5. Open any diagram, click **+** and open `VehicleSystemsComponents` → `Vehicle` → `Wheel`.

[![The + library panel open at VehicleSystemsComponents › Vehicle › Wheel, listing BrakeActuator, BrakedWheel, HydraulicBrakedWheel and TireFrictionCurve among the test benches; HandsOn03 and the other folders one level up.](/lecture/lecture-03/img/step00-wheel-library.png)](/lecture/lecture-03/img/step00-wheel-library.png)

::: tip Expected result

`using VehicleSystemsComponents` and `using HydraulicComponents` run in the REPL without an error. Under **+**, `Vehicle › Wheel` lists `BrakedWheel`, `HydraulicBrakedWheel`, `BrakeActuator` and `TireFrictionCurve`; `Vehicle › Brake` lists `BrakePedal`, `StaticBooster`, `TandemMasterCylinder`, `BrakeLine`, `BrakeCaliper` and `ABSValve`; and `Vehicle` lists `ABSPressureIntegrator`.

:::

## 01 Friction and stopping

Lecture deck: [friction and stopping](../../lecture-03/index.html#/friction-and-stopping){target="_self"}

### 01 · The tire's limit, by hand {#step-01}

Before anything runs, the three numbers every later run is judged by: the brake torque at which the tire is at its peak, and the braking distances at the peak and sliding.

#### Given

The car you brake today: **1400 kg** on one lumped wheel that carries the whole weight, rolling radius *r* = **0.31 m**, braking from **90 km/h** = 25 m/s. Its tire is the `TireFrictionCurve` you built in hands-on 1, with the same defaults as the library's: peak *μ*<sub>A</sub> = **1.0** at 4 % slip, sliding *μ*<sub>S</sub> = **0.7** from 12 %. The road factor scales both: 1 dry, 0.5 wet, 0.3 snow.

$$
F_z = m g \qquad T_{peak} = \mu_A F_z\, r \qquad d = \frac{v^2}{2\,\mu\, g}
$$

#### Do this

On paper or in the REPL, with *g* = 9.80665 m/s²:

1. The normal force *F*<sub>z</sub> and the peak torque *T*<sub>peak</sub>. Compare with the driver's 6000 N·m.
2. The braking distance at the peak (*μ* = 1.0) and sliding (*μ* = 0.7).
3. The same two on snow: multiply both friction values by 0.3.

```julia
F_z = 1400 * 9.80665
T_peak = 1.0 * F_z * 0.31
d(μ) = 25^2 / (2 * μ * 9.80665)
d(1.0), d(0.7), d(0.3), d(0.21)
```

::: tip Expected result

- *F*<sub>z</sub> = **13 729 N**, *T*<sub>peak</sub> = **4256 N·m**. The driver's 6000 N·m is 1.4 times that, so without ABS the wheel must lock.
- Dry road: **31.9 m** at the peak, **45.5 m** sliding.
- Snow: **106.2 m** at the peak, **151.7 m** sliding.

The peak distance is the floor no ABS beats. The sliding distance is roughly what a locked wheel gives.

:::

## 02 How the brakes work

Lecture deck: [how the brakes work](../../lecture-03/index.html#/brakes){target="_self"}

### 02 · Pedal to wheel {#step-02}

The brake system of section 02, wired by you: pedal, booster, tandem master cylinder, two brake lines and a wheel with a front and a rear caliper, stopping your own `Body` from 90 km/h. Pressed firmly, it stops the car hard without locking the wheel; pressed harder, it locks it. The hard stop is the no-ABS baseline of steps 03–05.

#### Parts

New component `PedalStop` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `pedal` | parameter `Real` | `0.6` — pedal command, the foot force as a fraction of 500 N |
| `road_mu` | parameter `Real` | `1.0` — road-friction multiplier |
| `command` | BlockComponents › Sources › Step | `height = pedal`, `start_time = 0.5` |
| `pedal_unit` | VehicleSystemsComponents › Vehicle › Brake › BrakePedal | defaults |
| `booster` | VehicleSystemsComponents › Vehicle › Brake › StaticBooster | defaults |
| `master` | VehicleSystemsComponents › Vehicle › Brake › TandemMasterCylinder | defaults |
| `line_f` | VehicleSystemsComponents › Vehicle › Brake › BrakeLine | defaults (1.5 m) |
| `line_r` | VehicleSystemsComponents › Vehicle › Brake › BrakeLine | `L = 4.0` |
| `wheel` | VehicleSystemsComponents › Vehicle › Wheel › HydraulicBrakedWheel | defaults |
| `body` | your `Body` (hands-on 1) | — |
| `fixed_hydraulic` | TranslationalComponents › Components › Fixed | — |
| `fixed` | RotationalComponents › Components › Fixed | — |
| `speed` | TranslationalComponents › Sensors › VelocitySensor | — |
| `road` | BlockComponents › Sources › Constant | `k = road_mu` |

In one line: `BrakePedal` multiplies the foot by 3.5, `StaticBooster` by 5 more up to run-out, `TandemMasterCylinder` turns the force into one pressure `p_mc` in two circuits, each `BrakeLine` carries it to the wheel, and `HydraulicBrakedWheel`'s two calipers turn it into torque on a wheel that carries the whole car. The box below says what each part is.

:::: info Given parts: the brake system, the wheel and the blocks around them

Library parts are under **+** → `VehicleSystemsComponents › Vehicle › Brake` and `› Wheel`. Values marked *PATH* are from the California PATH brake test car (Gerdes et al., report UCB-ITS-PRR-97-21); *assumed* values have no primary source and are the course's choice. The derivations are in the course repository's `docs/reports/Passenger car brake system modeling.md`.

**`BrakePedal`** (`pedal_unit`): an ideal, massless pedal lever. The input `u` is the pedal command, the driver's foot force as a fraction of `F_max`, clamped to 0–1, the way a throttle command is a fraction of full throttle. The flange `rod` pushes the booster's input; `support` is the pivot, which takes the reaction. The lever multiplies the force by `i_p` and costs travel by the same factor: the pedal moves `i_p` times as far as the rod.

- `i_p = 3.5`, the lever ratio: assumed, inside the 3.2–5 range cited for boosted cars.
- `F_max = 500` N, the foot force at `u = 1`: the ceiling a brake test may use (FMVSS 135). Pedal 0.3 is 150 N, pedal 0.6 is 300 N.

**`StaticBooster`** (`booster`): the vacuum booster as its force characteristic. Engine vacuum on one side of a diaphragm, atmosphere let in behind it when the driver pushes, adds force to the rod. *Static* means no chamber dynamics: the assist appears at once, with no pneumatic lag and no hysteresis. Flanges `input` (from the pedal's `rod`), `rod_out` (to the master cylinder's `pushrod`) and `support` (the housing, which takes the assist's reaction); the rod is rigid, so `input` and `rod_out` move together. Below the cut-in force the output is zero; at cut-in it jumps to the jump-in force; then every newton in gives `SR` newtons out; at run-out the rear chamber is at full atmosphere, the assist cannot grow, and past it only the foot adds.

- `SR = 5`, the servo ratio; `F_cut = 40` N cut-in and `F_jump = 500` N jump-in, at the rod: assumed, since no primary source gave production values.
- `A_d = 0.0533` m² diaphragm area, `p_vac = 33` kPa absolute vacuum (an idle manifold, as in hands-on 2), `F_rs0 = 97` N return-spring preload: PATH. `p_atm = 101325` Pa.
- What they give, in foot force: cut-in at 11.4 N (5.7 bar), 0.357 bar per newton boosted, run-out at **232 N** and 84.3 bar, 0.071 bar per newton past it. Without vacuum, 500 N makes 29.2 bar. These are the deck's *Pedal force to line pressure* figure.

**`TandemMasterCylinder`** (`master`): two pistons in one bore, quasi-static: the pressure follows the rod force at once, `p_mc = max(0, F_rod − F_cs0 − F_cf) / A_mc`, the same in both circuits. Flanges `pushrod` and `support`; hydraulic ports `front` and `rear`, one per circuit; outputs `p_mc`, the pressure in Pa, and `x_rod`, the rod travel. It counts the fluid it pushes out, and the rod travel is a dead stroke plus that volume over the bore area. It does not model a failed circuit.

- `A_mc` = 4.91 cm², a 25 mm bore; `F_cs0 = 138` N spring preload; `F_cf = 80` N seal friction: PATH.
- `s_dead` = 2.5 mm, the dead stroke before the compensating ports close: assumed, inside the 1.5–3.5 mm textbook range.

**`BrakeLine`** (`line_f`, `line_r`): a laminar (Hagen–Poiseuille) line, a pure resistance: pressure drop proportional to flow, Δ*p* = 128 *ν L ṁ* / (π *D*⁴). No compliance, no fluid inertia. Ports `port_a`, toward the master cylinder, and `port_b`, toward the wheel.

- `D = 3` mm bore, `L = 1.5` m; the rear line is set to `L = 4.0` m because it runs the length of the car: assumed.
- `nu` = 10 mm²/s, DOT 4 at 20 °C. At −40 °C DOT 4 may reach 1800 mm²/s, and the line's lag grows 180-fold. At 20 °C it is milliseconds.

**`HydraulicBrakedWheel`** (`wheel`): an equivalent road wheel. All four wheels are lumped into one that carries the whole car, with one caliper per axle. Inside: `inertia`, `caliper_f`, `caliper_r` and `tire`, in that order along the shaft. Ports: `spline`, the inboard shaft, free here (step 04's wheel-speed sensor goes on it); `support`, the brake housing, to ground; `flange`, to the body; `front` and `rear`, the two circuits; input `mu_scale`, the road factor; output `kappa`, the wheel's **true** slip, negative while braking. Steps 02–03 use `kappa` as an ideal slip sensor; a real ABS has none, which is step 04.

- `J_w = 4` kg·m², the four wheels' inertia; `radius = 0.31` m; `F_z = 13729.31` N, 1400 kg × 9.80665 m/s², step 01's *F*<sub>z</sub>.
- The tire: `sAdhesion = 0.04`, `sSlide = 0.12`, `mu_A = 1.0`, `mu_S = 0.7`, the curve of step 01.
- The calipers' values below. Your initial lines and plots read inside it: `wheel.inertia.w`, `wheel.caliper_f.p`.

**`BrakeCaliper`** (inside the wheel, `caliper_f` and `caliper_r`): one axle's disc brakes. The fluid that enters first takes up the pad clearance, the pressure rising to the pad-contact pressure `p0`; beyond it the caliper stiffens as it fills, *p* = *p*₀ + *K*₁*u* + *K*₃*u*³ in the volume *u* past the clearance. The torque is `K · max(0, p − p0)`, against the wheel's rotation; below `w0` = 0.2 rad/s its sign ramps smoothly through zero, so the solver can cross standstill. It is not stiction.

- `K` = 49.0 N·m/bar front, 19.9 N·m/bar rear, 68.9 in all: from 57 mm and 38 mm pistons, pad friction 0.40, effective radii 0.12 and 0.11 m. Textbook values, unverified. So a 1 g stop, 4256 N·m, needs 61.8 bar.
- `p0` = 0.5 bar; clearance volume 0.5 cm³ front, 0.3 cm³ rear; `K1` = 1e12 and 2.5e12 Pa/m³, `K3` = 4.8e23 and 7.5e24 Pa/m⁹, front and rear: shaped to textbook magnitudes and assumed. No verified production caliper curve was found.

**`TireFrictionCurve`** (inside the wheel's `tire`): the friction coefficient against slip, the curve you built in hands-on 1, with the same defaults. It rises from zero to `mu_A` at a slip of `sAdhesion`, falls to `mu_S` at `sSlide` and stays there up to a locked wheel; it is point-symmetric, so braking is the same curve with the sign turned. The tire around it computes the slip *κ* = (*ωr* − *v*) / max(|*v*|, 0.5 m/s) and the force `mu_scale · μ · F_z`. Its tests: *κ* −0.04 gives *μ* −1, −0.08 gives −0.85, −0.3 and −1 give −0.7. The road factor scales the whole curve, so on snow the peak is 0.3, still at 4 % slip.

**The brake fluid** (two code lines): `HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)`, an isothermal, slightly compressible liquid. DOT 4 has a density of about 1.045 kg/L and a bulk modulus of about 1.4 GPa at room temperature; `let_gas = false` leaves out gas in the fluid. Dyad cannot declare a fluid inside a library part that connects to outside ports, so the bench declares it once; `continuity(medium, master.front.medium)` hands it to the master cylinder, which passes it to `rear`, and every connection carries it on to the lines, the calipers and, in step 03, the valves. The lines' viscosity is `BrakeLine`'s `nu`, not the medium's.

**The standard blocks.** `BlockComponents › Sources › Step` (`command`): its output `y` is `offset` until `start_time`, then `offset + height`: here 0, then `pedal` at 0.5 s, the foot pressed at once. `BlockComponents › Sources › Constant` (`road`): `y = k`, the road factor. `TranslationalComponents › Components › Fixed` (`fixed_hydraulic`): a flange held still, ground for the pedal pivot and the booster and master-cylinder housings. `RotationalComponents › Components › Fixed` (`fixed`): a shaft held still, what the calipers push against. `TranslationalComponents › Sensors › VelocitySensor` (`speed`): its output `v` is the speed of the flange it sits on, here the car's, measured exactly.

**Your `Body`** (`body`): not given, yours from hands-on 1: 1400 kg, drag area 0.63 m², rolling resistance 0.012, on a flat road. It is the same physics as the library's `Vehicle.VehicleBody`, so the lecture's distances hold for your car. Its `flange` takes the tire's force; the initial lines set `body.mass.s` and `body.mass.v`.

**`Vehicle.braking_distance(r)`**, in the REPL: the distance from the pedal at 0.5 s until the car is below 0.5 m/s. One definition for the guide, the tests and the lecture's notebook.

::::

#### Do this

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `PedalStop`. With nothing selected, click **Edit Parameters** in the diagram toolbar → **Add parameter**: `pedal`, type `Real`, value `0.6`, and `road_mu`, type `Real`, value `1.0`. Place the twelve blocks from the table.

   [![PedalStop's parameter panel with nothing selected, over the finished bench: pedal 0.6 and road_mu 1.0, and the Add parameter button.](/lecture/lecture-03/img/step02-params.png)](/lecture/lecture-03/img/step02-params.png)

   [![The finished PedalStop with command selected: its parameter panel shows height = pedal, start_time 0.5 and offset 0.0.](/lecture/lecture-03/img/step02-command-params.png)](/lecture/lecture-03/img/step02-command-params.png)

   [![The finished PedalStop with line_r selected: its parameter panel shows D 3e-3 m, L 4.0 m and nu 10e-6 m2/s.](/lecture/lecture-03/img/step02-line-r-params.png)](/lecture/lecture-03/img/step02-line-r-params.png)

2. Rename every block to the name in the table: select it → **Edit Parameters** → the pencil next to its name. Studio names a placed block after its part (`step`, `brakepedal`, `tandemmastercylinder`, `fixed` and `fixed1`, `constant1`, …), and the code you paste below and every snippet use the table's names. The two `Fixed` blocks: rename the translational one, whose port is a green square, to `fixed_hydraulic` first, and only then the rotational one, whose port is a gray circle, to `fixed`; a name that is still taken cannot be given.
3. Wire:
   - `command.y → pedal_unit.u`
   - `pedal_unit.rod → booster.input`, `booster.rod_out → master.pushrod`

   [![PedalStop with all twelve blocks placed and the force chain wired: command into pedal_unit, pedal_unit.rod into booster, booster.rod_out into master.pushrod; nothing else wired yet.](/lecture/lecture-03/img/step02-force-chain.png)](/lecture/lecture-03/img/step02-force-chain.png)

   - `pedal_unit.support`, `booster.support` and `master.support → fixed_hydraulic.flange`
   - `master.front → line_f.port_a`, `line_f.port_b → wheel.front`
   - `master.rear → line_r.port_a`, `line_r.port_b → wheel.rear`
   - `wheel.support → fixed.spline`

   [![PedalStop with the hydraulic half wired too: the three housings onto fixed_hydraulic, master.front and master.rear through line_f and line_r into wheel.front and wheel.rear, wheel.support onto fixed; road, body and speed not yet wired.](/lecture/lecture-03/img/step02-hydraulics.png)](/lecture/lecture-03/img/step02-hydraulics.png)

   - `road.y → wheel.mu_scale`
   - `wheel.flange → body.flange`, and `speed.flange → body.flange`

   [![The finished PedalStop diagram: the chain command, pedal_unit, booster and master from the left, fixed_hydraulic under the three housings, line_f and line_r into wheel, road and fixed under the wheel, speed and body on the right.](/lecture/lecture-03/img/step02-pedal-bench.png)](/lecture/lecture-03/img/step02-pedal-bench.png)

4. Toggle to code (⇄) and paste the brake fluid: the `path medium` line among the declarations, above `relations`, and the `continuity` line inside `relations`. Dyad cannot declare a fluid inside a library part, so the bench that assembles the circuit declares it; the connections carry it from `master.front` to every port of both circuits. Without these two lines the bench does not compile: Studio reports `Invalid common set: In component PedalStop, no local specification or external connectors on which to determine value for the following common variables: master.front.medium, master.rear.medium, line_f.port_a.medium, …`, and the command-line compiler `Expected to find line_f.port_a.medium in at least one continuity graph for PedalStop`.

   ::: code-group

   ```txt [Brake fluid]
     path medium::HydraulicComponents.Interfaces.AbstractMedium = HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)
   relations
     continuity(medium, master.front.medium)
   ```

   :::

   Then add the starting state at the end of `relations`: the wheel rolling at the car's speed, the car at 25 m/s.

   ::: code-group

   ```txt [Initial state]
     initial wheel.inertia.phi = 0
     initial wheel.inertia.w = 25 / 0.31
     initial body.mass.s = 0
     initial body.mass.v = 25
   ```

   :::

   Forget them and the wheel starts at rest: the run then shows a wheel spinning up, not a stop.

   [![PedalStop in the code view: the twelve instances, the path medium line above relations, the fourteen connects, the continuity line and the four initial lines.](/lecture/lecture-03/img/step02-fluid-code.png)](/lecture/lecture-03/img/step02-fluid-code.png)

5. <Badge type="tip" text="New analysis" /> Add the analysis in code, below the component, so it sets the solver and passes `pedal` and `road_mu` through:

   ```txt
   analysis PedalStopTransient
     extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
     parameter pedal::Real = 0.6
     parameter road_mu::Real = 1.0
     model = PedalStop(pedal = pedal, road_mu = road_mu)
   end
   ```

6. Click ▷ **Run Analysis → PedalStopTransient** once, so the REPL loads it, then run it twice from the REPL. First a firm stop, `pedal = 0.3`: plot the master-cylinder pressure, the speed and the slip, and read the braking distance. `braking_distance` measures from the pedal at 0.5 s until the car is below 0.5 m/s.

   ```julia
   using Plots; plotly()
   using VehicleSystemsComponents: Vehicle
   r = MyCar.PedalStopTransient(pedal = 0.3);
   plot(r; idxs = [r."master.p_mc", r."speed.v", r."wheel.kappa"], layout = (3, 1))
   Vehicle.braking_distance(r)
   ```

   [![The snippet's plot at pedal 0.3 in three panels: master.p_mc steps to about 5.5 times 10 to the 6 Pa at 0.5 s; speed.v falls in a straight line from 25 m/s to zero at about 3.4 s; wheel.kappa drops to about -0.027 and stays there until the car stops.](/lecture/lecture-03/img/step02-pedal03-plot.png)](/lecture/lecture-03/img/step02-pedal03-plot.png)

   Then the panic stop, the default `pedal = 0.6`:

   ```julia
   r = MyCar.PedalStopTransient();
   plot(r; idxs = [r."master.p_mc", r."speed.v", r."wheel.kappa"], layout = (3, 1))
   Vehicle.braking_distance(r)
   ```

   [![The same plot at pedal 0.6: master.p_mc steps to about 8.9 times 10 to the 6 Pa; speed.v reaches zero just before 4 s; wheel.kappa goes to -1 within 0.2 s of the pedal and stays there: the wheel is locked.](/lecture/lecture-03/img/step02-pedal06-plot.png)](/lecture/lecture-03/img/step02-pedal06-plot.png)

[![Two panels against time at pedal 0.6. Top: car speed falls in a straight line from 90 km/h at 0.5 s to zero just before 4 s, while the wheel's surface speed drops to zero within 0.2 s. Bottom: wheel slip goes from 0 to -1 within 0.2 s of the pedal and stays there. Title: hydraulic pedal stop, 43.7 m from 90 km/h.](/lecture/lecture-03/img/step02-locked-stop.svg)](/lecture/lecture-03/img/step02-locked-stop.svg)

::: tip Expected result

**Pedal 0.3, 150 N of foot:** `master.p_mc` peaks at **55.1 bar**, 5.51×10⁶ on the plot's Pa axis, and the calipers hold **3765 N·m**, under the 4256 N·m of step 01. The wheel never locks: `wheel.kappa` stays above −0.03. The car decelerates at about 0.87 g, and `braking_distance` gives **36.0 m**. The front caliper's pressure rises from 10 to 90 % in 4.4 ms, and the master cylinder pushes 3.5 cm³ of fluid into the two circuits.

**Pedal 0.6, 300 N**, past the booster's run-out: **89.2 bar** and **6109 N·m**, 1.4 times what the tire can carry. `wheel.kappa` reaches **−1** within 0.2 s of the pedal and stays there; the car is at rest just before **4 s**. `braking_distance` gives **43.7 m**: just short of the 45.5 m sliding bound of step 01, because the wheel is not locked at once, and drag and rolling resistance help. At `road_mu` 0.5 and 0.3: 85.1 and 136.7 m, once `stop` is long enough for the car to come to rest; step 05's loop sets it.

The harder foot stops 7.7 m longer. Steps 03–05 measure every ABS against the 43.7 m of pedal 0.6.

Reference: `HandsOn03.PedalStop`, `HandsOn03.PedalStopTransient`.

:::

:::: warning Fell behind?

Right-click `MyCar` → **Add Component**, name it `PedalStop`, toggle to code (⇄) and paste this over its contents. It needs your `Body` from hands-on 1, and `HydraulicComponents` in `MyCar` from step 00.

::: code-group

```txt [PedalStop]
component PedalStop
  "Pedal command: foot force as a fraction of 500 N"
  parameter pedal::Real = 0.6
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  command = BlockComponents.Sources.Step(height = pedal, offset = 0.0, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  pedal_unit = VehicleSystemsComponents.Vehicle.Brake.BrakePedal()
  booster = VehicleSystemsComponents.Vehicle.Brake.StaticBooster()
  master = VehicleSystemsComponents.Vehicle.Brake.TandemMasterCylinder()
  line_f = VehicleSystemsComponents.Vehicle.Brake.BrakeLine()
  line_r = VehicleSystemsComponents.Vehicle.Brake.BrakeLine(L = 4.0)
  wheel = VehicleSystemsComponents.Vehicle.Wheel.HydraulicBrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  fixed_hydraulic = TranslationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
  path medium::HydraulicComponents.Interfaces.AbstractMedium = HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)
relations
  connect(command.y, pedal_unit.u)
  connect(pedal_unit.rod, booster.input)
  connect(booster.rod_out, master.pushrod)
  connect(pedal_unit.support, booster.support, master.support, fixed_hydraulic.flange)
  connect(master.front, line_f.port_a)
  connect(line_f.port_b, wheel.front)
  connect(master.rear, line_r.port_a)
  connect(line_r.port_b, wheel.rear)
  continuity(medium, master.front.medium)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.inertia.phi = 0
  initial wheel.inertia.w = 25 / 0.31
  initial body.mass.s = 0
  initial body.mass.v = 25
end

analysis PedalStopTransient
  extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
  parameter pedal::Real = 0.6
  parameter road_mu::Real = 1.0
  model = PedalStop(pedal = pedal, road_mu = road_mu)
end
```

:::

::::

## 03 Anti-lock braking

Lecture deck: [anti-lock braking](../../lecture-03/index.html#/abs){target="_self"}

### 03 · An ABS of your own {#step-03}

A slip controller that keeps the wheel off the sliding plateau, acting on the brake you wired in step 02. First on the present slip (A), then on the slip predicted 30 ms ahead (C), which leads the valve's lag.

#### Parts

New component `SlipABS`, written in code:

| Name | What | Set |
| --- | --- | --- |
| `kappa`, `v`, `demand` | inputs: wheel slip, car speed, the driver's master-cylinder pressure [Pa] | — |
| `p_cmd` | output: the wheel pressure the ABS allows [Pa] | — |
| `pressure` | VehicleSystemsComponents › Vehicle › ABSPressureIntegrator | `T_track = 0.01` |
| `lambda_target` | parameter | `0.04` — the slip held, the tire's peak |
| `k_inc`, `k_dec` | parameters | `2.9e7`, `5.8e7` Pa/s (290 and 580 bar/s) — build and dump rates |
| `v_min` | parameter | `1.5` m/s — ABS off below this speed |
| `T_p`, `T_f` | parameters (part C) | `0.03` s look-ahead, `0.003` s slip-rate filter |

:::: info Given parts: the pressure integrator and the valve

**`ABSPressureIntegrator`** (`pressure`, inside your `SlipABS`; under **+** at `VehicleSystemsComponents › Vehicle`): the modulator's build, hold and dump as one block. Inputs `demand`, the driver's pressure; `requested_rate`, the rate your law asks for; `active`, on above 0.5. Output `cmd`. While `active` is off, its state follows `demand` with the time constant `T_track`. While it is on, the state integrates `requested_rate`: a positive rate builds, zero holds, a negative one dumps. It stops at zero when dumping and at `demand` when building, and if the driver's pressure falls below it, it comes down with the demand. `cmd` is the state clipped to [0, `demand`], so the ABS can only take pressure away. It is unit-neutral: pascals here, newton meters in the library's own ABS, which uses the same block.

- `T_track = 0.01` s, set on the `pressure` line: the course's choice; the file gives no source.

**`ABSValve`** (`valve_f`, `valve_r`, placed in part B; under `Vehicle › Brake`): an **ideal** modulator for one circuit, between the master cylinder and the line. Ports `port_a`, the master-cylinder side, and `port_b`, the line and caliper side; input `p_cmd`, the wheel pressure the ECU allows, in Pa. While `p_cmd` is at or above the master-cylinder pressure the inlet is open: the caliper side carries the master cylinder's pressure, with no lag. Below it the caliper-side pressure follows `p_cmd`, clipped to [0, `p_mc`], after a first-order lag `T_v`. It never rises above the master cylinder.

- `T_v = 0.03` s, the electronics and solenoid reaction time: the same 30 ms brake lag the lecture's ABS model is built around, and the 30 ms your look-ahead in part C leads.

What it is **not**: the real modulator of the lecture's *build, hold, dump* slide. A real channel has a normally open inlet valve, a normally closed outlet valve, a low-pressure accumulator and a return pump; the build and dump rates come from the valves' orifices, and the pump's return is the pulse the driver feels in the pedal. `ABSValve` is the result of that hardware, not the hardware: your controller sets the rates, the fluid it dumps leaves the model, and there is no accumulator, no pump and no pedal pulse. A valve-level model is planned for the library (`docs/brake-system-implementation-plan.md`, step 3).

::::

#### Do this

1. <Badge type="tip" text="New component" /> **A · the controller.** Right-click `MyCar` → **Add Component**, name it `SlipABS`, toggle to code (⇄) and paste the ports, `pressure` and their placements over its contents. A port written in code has no place on the block's outline until the `{^…}` marker and the `metadata` block give it one; without them all four ports sit on top of each other at the block's center, and the bench cannot wire them.

   ```txt
   component SlipABS
     "Wheel slip, negative while braking"
     kappa = RealInput() {^kappa}
     "Vehicle speed"
     v = RealInput() {^v}
     "Master-cylinder pressure demand [Pa]"
     demand = RealInput() {^demand}
     "Allowed wheel-circuit pressure [Pa]"
     p_cmd = RealOutput() {^p_cmd}
     pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01) {^pressure}
   relations
   metadata {
     "_links": {
       "kappa": {"Dyad": {"placement": {"icon": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}, "diagram": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}}}},
       "v": {"Dyad": {"placement": {"icon": {"x1": -50, "x2": 50, "y1": 450, "y2": 550}, "diagram": {"x1": -50, "x2": 50, "y1": 450, "y2": 550}}}},
       "demand": {"Dyad": {"placement": {"icon": {"x1": -50, "x2": 50, "y1": 700, "y2": 800}, "diagram": {"x1": -50, "x2": 50, "y1": 700, "y2": 800}}}},
       "p_cmd": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}, "diagram": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}}}},
       "pressure": {"Dyad": {"placement": {"diagram": {"x1": 400, "x2": 600, "y1": 400, "y2": 600}}}}
     }
   }
   end
   ```

   Then write the parameters from the table and a variable `cycled::Real` above `relations`, and the relations for part A below it, above `metadata`. If the ports still sit at the block's center on the bench, open `SlipABS`'s diagram and drag each port to the edge of the outline: the inputs left, `p_cmd` right.

   ```txt
     initial cycled = 0
     der(cycled) = ifelse(v > v_min and kappa < -lambda_target, 1000 * (1 - cycled), 0)
     connect(demand, pressure.demand)
     pressure.requested_rate = ifelse(kappa < -lambda_target, -k_dec, k_inc)
     pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
     p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)
   ```

   Slip is negative while braking: past −0.04 the wheel is beyond the peak, so dump; otherwise build. `cycled` is a latch that flips to 1 the first time the wheel goes past the peak. Until then `p_cmd` is the driver's own pressure: a command at or above the master-cylinder pressure leaves the valve's inlet open with no lag, so a stop that never locks the wheel is exactly step 02's stop.

   [![SlipABS's own diagram: the inputs kappa, v and demand on the left edge of the outline, p_cmd on the right, the pressure block in the middle, and demand wired to pressure.demand.](/lecture/lecture-03/img/step03-slipabs-diagram.png)](/lecture/lecture-03/img/step03-slipabs-diagram.png)

2. <Badge type="tip" text="New component" /> **B · the bench, a copy of step 02's.** Right-click `PedalStop` → **Duplicate**, name it `ABSStop`. With nothing selected, **Edit Parameters** → **Add parameter**: `T_p`, type `Real` with unit `s`, value `0.03`, and `lambda_target`, type `Real`, value `0.04`. The form offers no `Time` type; `Real` in seconds is the same. If the copy is missing from the Components tree, or its diagram opens empty, open `absstop.dyad` once (<kbd>Ctrl</kbd>+<kbd>P</kbd>), then the diagram again.

   [![ABSStop's parameter panel with nothing selected: pedal 0.6, road_mu 1.0, T_p 0.03 s and lambda_target 0.04, over the finished bench.](/lecture/lecture-03/img/step03-params.png)](/lecture/lecture-03/img/step03-params.png)

   Delete the two wires `master.front → line_f.port_a` and `master.rear → line_r.port_a`, and place:

   | Name | Library path | Set |
   | --- | --- | --- |
   | `valve_f` | VehicleSystemsComponents › Vehicle › Brake › ABSValve | defaults |
   | `valve_r` | VehicleSystemsComponents › Vehicle › Brake › ABSValve | defaults |
   | `abs` | your `SlipABS` | `lambda_target = lambda_target`; `T_p = T_p` follows in part C |

   `ABSValve` is the ideal modulator of the **Given parts** box above: the caliper follows `p_cmd` 30 ms late, never above the master-cylinder pressure, and the pedal does not pulse.

   Wire:
   - `master.front → valve_f.port_a`, `valve_f.port_b → line_f.port_a`
   - `master.rear → valve_r.port_a`, `valve_r.port_b → line_r.port_a`

   [![ABSStop mid-build: step 02's chain with valve_f and valve_r between master and the lines, both ports wired, the valves' p_cmd inputs still open; abs not yet placed.](/lecture/lecture-03/img/step03-valves.png)](/lecture/lecture-03/img/step03-valves.png)

   - `master.p_mc → abs.demand`
   - `abs.p_cmd → valve_f.p_cmd`, and `abs.p_cmd → valve_r.p_cmd`
   - `wheel.kappa → abs.kappa`, `speed.v → abs.v`

   [![The ABSStop diagram: step 02's chain with valve_f and valve_r between master and the lines, abs below them, master.p_mc, wheel.kappa and speed.v wired into it and abs.p_cmd out to both valves.](/lecture/lecture-03/img/step03-abs-bench.png)](/lecture/lecture-03/img/step03-abs-bench.png)

   The brake fluid, the four initial lines and every other wire came with the copy; the analysis did not, since **Duplicate** copies the component only. In the code view, add this analysis below the component:

   ```txt
   analysis ABSStopTransient
     extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
     parameter road_mu::Real = 1.0
     parameter T_p::Time = 0.03
     parameter lambda_target::Real = 0.04
     parameter pedal::Real = 0.6
     model = ABSStop(road_mu = road_mu, T_p = T_p, lambda_target = lambda_target, pedal = pedal)
   end
   ```

   Click ▷ **Run Analysis → ABSStopTransient** once, then plot the front wheel pressure beside the master cylinder's, and the slip:

   ```julia
   using Plots; plotly()
   using VehicleSystemsComponents: Vehicle
   r = MyCar.ABSStopTransient();
   plot(r; idxs = [r."master.p_mc", r."wheel.caliper_f.p", r."wheel.kappa"], layout = (3, 1))
   Vehicle.braking_distance(r)
   ```

   [![Run A, no look-ahead, in three panels: master.p_mc at about 8.9 times 10 to the 6 Pa; wheel.caliper_f.p saws between about 1 and 7 times 10 to the 6 Pa; wheel.kappa dives deeper on every cycle, to -1 near the end.](/lecture/lecture-03/img/step03-runA-plot.png)](/lecture/lecture-03/img/step03-runA-plot.png)

3. **C · the look-ahead.** In `SlipABS` add the parameters `T_p = 0.03` and `T_f = 0.003` and the three variables above `relations`, and the four new lines below it; the rate line and the latch now read `kappa_pred`:

   ```txt
     variable kappa_f::Real
     variable kappa_dot::Real
     variable kappa_pred::Real
   relations
     initial kappa_f = 0
     der(kappa_f) = (kappa - kappa_f) / T_f
     kappa_dot = (kappa - kappa_f) / T_f
     kappa_pred = kappa + T_p * kappa_dot
     der(cycled) = ifelse(v > v_min and kappa < -lambda_target and kappa_pred < -lambda_target, 1000 * (1 - cycled), 0)
     pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
   ```

   `kappa_f` follows the slip 3 ms late, so `kappa_dot` is the slip's rate of change, filtered. In `ABSStop`, set `abs` to `T_p = T_p` as well, so the bench's `T_p` reaches it. Click ▷ **Run Analysis → ABSStopTransient** again, which also brings the REPL's `MyCar` up to date, and rerun the snippet. With the full code below, `MyCar.ABSStopTransient(T_p = 0)` is run A again.

   [![SlipABS in the code view: the four ports and the pressure line with their placement markers, the parameters, the look-ahead variables, the latch, the rate ifelse and the p_cmd line, and the metadata block with the ports' placements.](/lecture/lecture-03/img/step03-slipabs-code.png)](/lecture/lecture-03/img/step03-slipabs-code.png)

   [![The finished ABSStop with abs selected: MyCar.SlipABS's parameter panel shows lambda_target = lambda_target, k_inc 2.9e7, k_dec 5.8e7, v_min 1.5 m/s, T_p = T_p and T_f 0.003 s.](/lecture/lecture-03/img/step03-abs-params.png)](/lecture/lecture-03/img/step03-abs-params.png)

   [![Run C, 30 ms look-ahead: after one dip, wheel.caliper_f.p holds near 6.4 times 10 to the 6 Pa with a fine ripple until about 3 s; wheel.kappa sits just below zero near -0.04, then locks briefly as the ABS switches off just before standstill.](/lecture/lecture-03/img/step03-runC-plot.png)](/lecture/lecture-03/img/step03-runC-plot.png)

[![Two panels against time for the two ABS runs. Top, front wheel pressure beside the master cylinder's: without look-ahead it saws deep below it; with the 30 ms look-ahead it holds near 63.6 bar with a ripple of about 1 bar. Bottom, slip: without look-ahead each cycle dives past the -0.12 sliding line; with it the slip sits on the -0.04 peak line.](/lecture/lecture-03/img/step03-abs-torque-slip.svg)](/lecture/lecture-03/img/step03-abs-torque-slip.svg)

::: tip Expected result

**A, no look-ahead:** **53.4 m**, *longer* than the locked 43.7 m; on wet and snow, with a `stop` long enough to come to rest, 98.8 and 151.6 m, longer there too. The slip dives past the 12 % sliding point every cycle. Not a mistake: the law reacts to the slip now, but the valve follows 30 ms later, so every dump comes too late.

**C, look-ahead 30 ms:** **34.2 m**, 22 % shorter than locked. The front caliper's pressure `wheel.caliper_f.p` holds at **63.6 bar** on average with a ripple of about 1 bar at **26 Hz**: a smooth slip regulator. `wheel.kappa` stays near −0.04. Below 1.5 m/s the ABS switches off and the wheel locks just before standstill. At `road_mu` 0.5 and 0.3, with a `stop` long enough to come to rest: 64.6 and 106.1 m.

The wheel pressure never exceeds `master.p_mc`. At `pedal = 0.3`, where the wheel never locks, the ABS never acts: `MyCar.ABSStopTransient(pedal = 0.3)` stops in **35.95 m**, step 02's 36.0 m.

C is the law of the library's `ABSIdealController`, on pressure through the hydraulics instead of on a torque command: 34.2 m against the library's 34.4 m. Reference: `HandsOn03.SlipABS`, `HandsOn03.ABSStop`.

:::

:::: warning Fell behind?

Add components `SlipABS` and `ABSStop` in `MyCar`, toggle each to code (⇄) and paste over its contents; `ABSStop` does not need a working `PedalStop`. It needs your `Body`, and `HydraulicComponents` in `MyCar` from step 00; its analysis passes `T_p` through, so `MyCar.ABSStopTransient(T_p = 0)` is run A.

::: code-group

```txt [SlipABS]
component SlipABS
  "Wheel slip, negative while braking"
  kappa = RealInput() {^kappa}
  "Vehicle speed"
  v = RealInput() {^v}
  "Master-cylinder pressure demand [Pa]"
  demand = RealInput() {^demand}
  "Allowed wheel-circuit pressure [Pa]"
  p_cmd = RealOutput() {^p_cmd}
  pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01) {^pressure}
  "Slip held, just past the tire's peak"
  parameter lambda_target::Real = 0.04
  "Pressure build rate [Pa/s]"
  parameter k_inc::Real = 2.9e7
  "Pressure dump rate [Pa/s]"
  parameter k_dec::Real = 5.8e7
  "ABS off below this speed"
  parameter v_min::Velocity = 1.5
  "Look-ahead, the brake's lag"
  parameter T_p::Time = 0.03
  "Slip-rate filter"
  parameter T_f::Time = 0.003
  variable kappa_f::Real
  variable kappa_dot::Real
  variable kappa_pred::Real
  variable cycled::Real
relations
  initial kappa_f = 0
  der(kappa_f) = (kappa - kappa_f) / T_f
  kappa_dot = (kappa - kappa_f) / T_f
  kappa_pred = kappa + T_p * kappa_dot
  initial cycled = 0
  der(cycled) = ifelse(v > v_min and kappa < -lambda_target and kappa_pred < -lambda_target, 1000 * (1 - cycled), 0)
  connect(demand, pressure.demand) {^id1}
  pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
  pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
  p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)
metadata {
  "_links": {
    "kappa": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 200, "y2": 300},
          "diagram": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}
        }
      }
    },
    "v": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 450, "y2": 550},
          "diagram": {"x1": -50, "x2": 50, "y1": 450, "y2": 550}
        }
      }
    },
    "demand": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 700, "y2": 800},
          "diagram": {"x1": -50, "x2": 50, "y1": 700, "y2": 800}
        }
      }
    },
    "p_cmd": {
      "Dyad": {
        "placement": {
          "icon": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550},
          "diagram": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}
        }
      }
    },
    "pressure": {"Dyad": {"placement": {"diagram": {"x1": 400, "x2": 600, "y1": 400, "y2": 600}}}},
    "id1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 200, "y": 750}, {"x": 200, "y": 450}], "E": 2}]}},
    "id2": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}}
  }
}
end
```

```txt [ABSStop]
component ABSStop
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  "Look-ahead; 0 is part A"
  parameter T_p::Time = 0.03
  "Slip the ABS holds"
  parameter lambda_target::Real = 0.04
  "Pedal command: foot force as a fraction of 500 N"
  parameter pedal::Real = 0.6
  command = BlockComponents.Sources.Step(height = pedal, offset = 0.0, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  pedal_unit = VehicleSystemsComponents.Vehicle.Brake.BrakePedal()
  booster = VehicleSystemsComponents.Vehicle.Brake.StaticBooster()
  master = VehicleSystemsComponents.Vehicle.Brake.TandemMasterCylinder()
  valve_f = VehicleSystemsComponents.Vehicle.Brake.ABSValve()
  valve_r = VehicleSystemsComponents.Vehicle.Brake.ABSValve()
  line_f = VehicleSystemsComponents.Vehicle.Brake.BrakeLine()
  line_r = VehicleSystemsComponents.Vehicle.Brake.BrakeLine(L = 4.0)
  abs = SlipABS(T_p = T_p, lambda_target = lambda_target)
  wheel = VehicleSystemsComponents.Vehicle.Wheel.HydraulicBrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  fixed_hydraulic = TranslationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
  path medium::HydraulicComponents.Interfaces.AbstractMedium = HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)
relations
  connect(command.y, pedal_unit.u)
  connect(pedal_unit.rod, booster.input)
  connect(booster.rod_out, master.pushrod)
  connect(pedal_unit.support, booster.support, master.support, fixed_hydraulic.flange)
  connect(master.front, valve_f.port_a)
  connect(valve_f.port_b, line_f.port_a)
  connect(line_f.port_b, wheel.front)
  connect(master.rear, valve_r.port_a)
  connect(valve_r.port_b, line_r.port_a)
  connect(line_r.port_b, wheel.rear)
  continuity(medium, master.front.medium)
  connect(master.p_mc, abs.demand)
  connect(wheel.kappa, abs.kappa)
  connect(speed.v, abs.v)
  connect(abs.p_cmd, valve_f.p_cmd, valve_r.p_cmd)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.inertia.phi = 0
  initial wheel.inertia.w = 25 / 0.31
  initial body.mass.s = 0
  initial body.mass.v = 25
end

analysis ABSStopTransient
  extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
  parameter road_mu::Real = 1.0
  parameter T_p::Time = 0.03
  parameter lambda_target::Real = 0.04
  parameter pedal::Real = 0.6
  model = ABSStop(road_mu = road_mu, T_p = T_p, lambda_target = lambda_target, pedal = pedal)
end
```

:::

::::


### 04 · Only the wheel speed {#step-04}

A real ABS measures only the wheel speed. This step feeds your ABS from a wheel-speed sensor alone, through an estimate of the car's speed you write, with the cycle a production ECU runs: dump, hold, and build slowly from the held level. It acts on the same brake and valves as step 03.

#### Parts

New component `RefSpeedEstimator`, in code:

| Name | What | Set |
| --- | --- | --- |
| `omega` | input: wheel speed from a sensor on the wheel shaft [rad/s] | — |
| `kappa_hat`, `v_ref`, `a_w` | outputs: estimated slip, estimated car speed, wheel surface acceleration | — |
| `radius` | parameter | `0.31` m |
| `a_ref` | parameter | `8` m/s² — the deceleration assumed while the wheel slips |
| `v0` | parameter | `25` m/s — speed at the start |
| `T_up` | parameter | `0.01` s — how fast the estimate follows the wheel up |
| `v_eps` | parameter | `0.5` m/s — floor on the speed the slip is divided by |
| `T_f` | parameter | `0.005` s — wheel-acceleration filter |

New component `PhaseABS`, a duplicate of `SlipABS`:

| Name | What | Set |
| --- | --- | --- |
| `kappa`, `a_w`, `v`, `demand` | inputs | — |
| `p_cmd` | output: allowed wheel pressure [Pa] | — |
| `pressure` | ABSPressureIntegrator, as before | `T_track = 0.01` |
| `a_minus` | parameter | `12` m/s² — wheel deceleration that starts a dump |
| `a_plus` | parameter | `3` m/s² — wheel acceleration that holds |
| `lambda_1` | parameter | `0.2` — estimated slip that starts a dump |
| `k_dec`, `k_inc` | parameters | `5.8e7`, `1.16e7` Pa/s (580 and 116 bar/s) — dump, and the slow rebuild |
| `v_min` | parameter | `1.5` m/s |
| `T_latch` | parameter | `0.001` s |

:::: info Given parts: the wheel-speed sensor

**`RotationalComponents › Sensors › VelocitySensor`** (`wspeed`, placed in part C): its output `w` is the angular speed of the shaft it sits on, in rad/s, measured exactly; its port `spline` goes on `wheel.spline`. It is the ABS's wheel-speed sensor, and from this step on the only thing your ABS measures: `wheel.kappa` and `speed.v` are no longer wired to it. A real sensor counts the teeth of a ring turning with the wheel, and the ECU computes the speed from the pulse timing; this one reads the speed directly.

`ABSPressureIntegrator` and `ABSValve` are step 03's; in `PhaseABS` a `requested_rate` of zero is the hold.

::::

#### Do this

1. <Badge type="tip" text="New component" /> **A · the estimator.** Add `RefSpeedEstimator`, toggle to code (⇄) and paste the ports and their placements over its contents, as for `SlipABS` in step 03:

   ```txt
   component RefSpeedEstimator
     "Wheel speed from a sensor on the wheel shaft"
     omega = RealInput() {^omega}
     "Estimated wheel slip"
     kappa_hat = RealOutput() {^kappa_hat}
     "Estimated vehicle speed"
     v_ref = RealOutput() {^v_ref}
     "Wheel surface acceleration"
     a_w = RealOutput() {^a_w}
   relations
   metadata {
     "_links": {
       "omega": {"Dyad": {"placement": {"icon": {"x1": -50, "x2": 50, "y1": 450, "y2": 550}}}},
       "kappa_hat": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 200, "y2": 300}}}},
       "v_ref": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}}}},
       "a_w": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 700, "y2": 800}}}}
     }
   }
   end
   ```

   [![RefSpeedEstimator's own diagram: the input omega on the left edge of the outline, and the outputs kappa_hat, v_ref and a_w on the right.](/lecture/lecture-03/img/step04-estimator-diagram.png)](/lecture/lecture-03/img/step04-estimator-diagram.png)

   Then write the parameters from the table and two variables `v_w::Velocity` and `v_f::Velocity` above `relations`, and the relations below it:

   ```txt
     v_w = omega * radius
     initial v_ref = v0
     der(v_ref) = ifelse(v_w > v_ref, (v_w - v_ref) / T_up, -a_ref)
     kappa_hat = (v_w - v_ref) / max(v_ref, v_eps)
     initial v_f = v0
     der(v_f) = (v_w - v_f) / T_f
     a_w = (v_w - v_f) / T_f
   ```

   While the wheel turns faster than the estimate, the estimate follows it; otherwise it falls at `a_ref`. `a_w` is the wheel's own acceleration, filtered as step 03's slip rate was: it needs no estimate of the car's speed.

   [![RefSpeedEstimator in the code view: the input omega and the three outputs with their placement markers, the six parameters, the two variables and the seven relations.](/lecture/lecture-03/img/step04-estimator-code.png)](/lecture/lecture-03/img/step04-estimator-code.png)

2. <Badge type="tip" text="New component" /> **B · the controller.** Add `PhaseABS`, toggle to code (⇄) and paste the `PhaseABS` block of **Fell behind?** below over its contents: five ports with their placements, the parameters from the table, the variables `phase` and `cycled`. Do not duplicate `SlipABS` and edit it: the copy writes its types as `Dyad.RealInput` and `Dyad.Time`, keeps the description `"short SlipABS component description"`, and any port declaration you retype loses its `{^…}` marker, so the port stacks at the block's center again. The relations to read:

   ```txt
     phase = ifelse(a_w > a_plus, 0, ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
     initial cycled = 0
     der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
     connect(demand, pressure.demand)
     pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
     pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
     p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)
   ```

   `phase` is −1 dump, 0 hold, 1 build. A rolling wheel cannot decelerate faster than the car, at most about 9.8 m/s² on a dry road, so a wheel decelerating past 12 m/s² has gone over the tire's peak. The estimated slip only catches a wheel that is already locked. `cycled` is step 03's latch, now set by the first dump: until then `p_cmd` is the driver's own pressure and the valve stays open, the fast first build; afterwards every build is slow and starts from where the hold left the pressure.

   [![PhaseABS's own diagram: the inputs kappa, a_w, v and demand on the left edge, p_cmd on the right, the pressure block in the middle with demand wired to it.](/lecture/lecture-03/img/step04-phaseabs-diagram.png)](/lecture/lecture-03/img/step04-phaseabs-diagram.png)

   [![PhaseABS in the code view: five ports and pressure with their placement markers, the parameters, the phase line, the cycled latch and the nested rate ifelse.](/lecture/lecture-03/img/step04-phaseabs-code.png)](/lecture/lecture-03/img/step04-phaseabs-code.png)

3. <Badge type="tip" text="New component" /> **C · the bench.** Right-click `ABSStop` → **Duplicate**, name it `ABSStopWheelOnly`. Replace `abs` with a `PhaseABS` named `abs`, and wire `master.p_mc → abs.demand` and `abs.p_cmd → valve_f.p_cmd`, `valve_r.p_cmd` again if the swap dropped them. Delete the `wheel.kappa` and `speed.v` wires into `abs`. Replace the bench parameters `T_p` and `lambda_target` with `a_ref`: **Edit Parameters** → **Add parameter**, type `Real` with unit `m/s2`, value `8`, since the form has no `Acceleration` type. Place:

   | Name | Library path | Set |
   | --- | --- | --- |
   | `wspeed` | RotationalComponents › Sensors › VelocitySensor | — |
   | `est` | your `RefSpeedEstimator` | `a_ref = a_ref` |
   | `a_ref` | parameter `Real`, unit `m/s2`, on the bench | `8` |

   Wire `wspeed.spline → wheel.spline` and `wspeed.w → est.omega`.

   [![ABSStopWheelOnly mid-build, shown with the old abs deleted and PhaseABS not yet placed in its stead: wspeed on wheel.spline, wspeed.w into est.omega, est's three outputs still open; no wire from wheel.kappa or speed.v.](/lecture/lecture-03/img/step04-wheel-only-midbuild.png)](/lecture/lecture-03/img/step04-wheel-only-midbuild.png)

   Then wire est's outputs into abs: `est.kappa_hat → abs.kappa`, `est.a_w → abs.a_w`, `est.v_ref → abs.v`.

   [![The ABSStopWheelOnly diagram: wspeed on the wheel shaft, its output into est, and est's three outputs into abs; nothing from wheel.kappa or speed.v into abs.](/lecture/lecture-03/img/step04-wheel-only-bench.png)](/lecture/lecture-03/img/step04-wheel-only-bench.png)

   The copy has no analysis: add this one below the component, then click ▷ **Run Analysis → ABSStopWheelOnlyTransient** once before the snippet.

   ```txt
   analysis ABSStopWheelOnlyTransient
     extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
     parameter road_mu::Real = 1.0
     parameter a_ref::Acceleration = 8
     model = ABSStopWheelOnly(road_mu = road_mu, a_ref = a_ref)
   end
   ```

   Run it, then the snowy road:

   ```julia
   using Plots; plotly()
   using VehicleSystemsComponents: Vehicle
   r = MyCar.ABSStopWheelOnlyTransient();
   Vehicle.braking_distance(r)
   r = MyCar.ABSStopWheelOnlyTransient(road_mu = 0.3, stop = 20);
   plot(r; idxs = [r."abs.phase", r."abs.p_cmd", r."wheel.caliper_f.p"],
        layout = (3, 1), xlims = (1.0, 2.5))
   ```

   [![The snippet's plot on snow from 1.0 to 2.5 s, in three panels: abs.phase switching between 1, 0 and -1; abs.p_cmd sawing between about 1.3 and 2.6 times 10 to the 6 Pa; wheel.caliper_f.p following it, smoother, between about 1.5 and 2.2 times 10 to the 6 Pa.](/lecture/lecture-03/img/step04-phase-plot.png)](/lecture/lecture-03/img/step04-phase-plot.png)

   The pressure panels are in Pa: 2×10⁶ is 20 bar. The legend lists all three series in one box at the top. The same plot of the dry run, from 1.0 to 3.3 s:

   ```julia
   r = MyCar.ABSStopWheelOnlyTransient();
   plot(r; idxs = [r."abs.phase", r."abs.p_cmd", r."wheel.caliper_f.p"],
        layout = (3, 1), xlims = (1.0, 3.3))
   ```

   [![The same plot on a dry road, the first run with road_mu left at 1.0, from 1.0 to 3.3 s: abs.phase switching between 1 and -1 about 14 times a second at speed; abs.p_cmd and wheel.caliper_f.p rippling near 6.3 times 10 to the 6 Pa until about 2.2 s, then deep dumps, the caliper down to between about 3.6 and 2.5 times 10 to the 6 Pa, as the car slows.](/lecture/lecture-03/img/step04-dry-plot.png)](/lecture/lecture-03/img/step04-dry-plot.png)

[![Two panels from 1.0 to 2.5 s of the wheel-speed-only stop on snow, road mu 0.3. Top, pressure: the allowed pressure climbs slowly in blue build phases, drops in vermilion dump phases and stays flat in yellow hold phases; the front caliper follows it between 14.5 and 22.1 bar, about six dumps a second. Bottom, speed: the car falls steadily, the wheel dips below it in every dump, and the estimate rides the wheel. Title: 130.6 m.](/lecture/lecture-03/img/step04-phase-cycle.svg)](/lecture/lecture-03/img/step04-phase-cycle.svg)

::: tip Expected result

**Dry road: 38.5 m**, shorter than your locked wheel (43.7 m) and level with the library's clocked wheel-speed-only ECU (38.7 m). **Wet, μ 0.5: 78.0 m** against 85.1 m locked; **snow, μ 0.3: 130.6 m** against 136.7 m, only about 5 % shorter.

On snow, in the plot's window from 1.0 to 2.5 s, the front caliper cycles **about 6 times a second between 14.5 and 22.1 bar** (`wheel.caliper_f.p`, 1.45–2.21×10⁶ Pa on the plot): build → dump → hold → build, with `abs.pressure.p` flat in every hold. Over the whole stop the dumps deepen and slow down as the car slows: from 1 s until the car is below 3 m/s, 40 dumps in 9.5 s, about **4 a second, between 1.6 and 22.3 bar**, and only about 3 a second near the end. On a dry road, over the same span (1.0–3.3 s), **24.3 to 64.9 bar**: at speed a ripple of 2–3 bar around 63 bar, about 14 dumps a second, then four deep dumps, to 24–36 bar, as the car slows. A measured Bosch ABS cycles 2–4 times a second on asphalt with 15–30 bar swings, and 4–6 times on ice with near-full dumps (Day & Roberts, SAE 2002-01-0559). On snow yours is in that range; on a dry road it ripples faster and shallower at speed and dumps deeper near the end: its rates are fixed in bar per second for one road, and one 30 ms valve lag at 580 bar/s is 17 bar. `docs/abs-efficiency-research.md` §3 has the runs. The wheel pressure never exceeds `master.p_mc`.

Keep `T_f` at 5 ms: a heavier filter delays `a_w`, and that lag plays the part the valve lag played in step 03 A.

Reference: `HandsOn03.RefSpeedEstimator`, `HandsOn03.PhaseABS`, `HandsOn03.ABSStopWheelOnly`.

:::

:::: warning Fell behind?

Add the three components in `MyCar`, toggle each to code (⇄) and paste. Short of time? Paste `PhaseABS` and the bench, and write only the estimator.

::: code-group

```txt [RefSpeedEstimator]
component RefSpeedEstimator
  "Wheel speed from a sensor on the wheel shaft"
  omega = RealInput() {^omega}
  "Estimated wheel slip"
  kappa_hat = RealOutput() {^kappa_hat}
  "Estimated vehicle speed"
  v_ref = RealOutput() {^v_ref}
  "Wheel surface acceleration"
  a_w = RealOutput() {^a_w}
  "Wheel rolling radius"
  parameter radius::Length = 0.31
  "Assumed deceleration while the wheel slips"
  parameter a_ref::Acceleration = 8
  "Speed at the start"
  parameter v0::Velocity = 25
  "Time constant of following the wheel up"
  parameter T_up::Time = 0.01
  "Floor on the speed the slip is divided by"
  parameter v_eps::Velocity = 0.5
  "Wheel-acceleration filter"
  parameter T_f::Time = 0.005
  variable v_w::Velocity
  variable v_f::Velocity
relations
  v_w = omega * radius
  initial v_ref = v0
  der(v_ref) = ifelse(v_w > v_ref, (v_w - v_ref) / T_up, -a_ref)
  kappa_hat = (v_w - v_ref) / max(v_ref, v_eps)
  initial v_f = v0
  der(v_f) = (v_w - v_f) / T_f
  a_w = (v_w - v_f) / T_f
metadata {
  "_links": {
    "omega": {"Dyad": {"placement": {"icon": {"x1": -50, "x2": 50, "y1": 450, "y2": 550}}}},
    "kappa_hat": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 200, "y2": 300}}}},
    "v_ref": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}}}},
    "a_w": {"Dyad": {"placement": {"icon": {"x1": 950, "x2": 1050, "y1": 700, "y2": 800}}}}
  }
}
end
```

```txt [PhaseABS]
component PhaseABS
  "Estimated wheel slip, negative while braking"
  kappa = RealInput() {^kappa}
  "Wheel surface acceleration"
  a_w = RealInput() {^a_w}
  "Estimated vehicle speed"
  v = RealInput() {^v}
  "Master-cylinder pressure demand [Pa]"
  demand = RealInput() {^demand}
  "Allowed wheel-circuit pressure [Pa]"
  p_cmd = RealOutput() {^p_cmd}
  pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01) {^pressure}
  "Wheel deceleration that starts a dump (-a)"
  parameter a_minus::Acceleration = 12
  "Wheel acceleration that holds the pressure (+a)"
  parameter a_plus::Acceleration = 3
  "Estimated slip that starts a dump"
  parameter lambda_1::Real = 0.2
  "Dump rate [Pa/s]"
  parameter k_dec::Real = 5.8e7
  "Rebuild rate after the first dump [Pa/s]"
  parameter k_inc::Real = 1.16e7
  "ABS off below this speed"
  parameter v_min::Velocity = 1.5
  "Time constant of the cycled latch"
  parameter T_latch::Time = 0.001
  "-1 decrease, 0 hold, 1 increase"
  variable phase::Real
  "1 once the first dump has happened"
  variable cycled::Real
relations
  phase = ifelse(a_w > a_plus, 0, ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
  initial cycled = 0
  der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
  connect(demand, pressure.demand) {^id1}
  pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
  pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
  p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)
metadata {
  "_links": {
    "kappa": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 100, "y2": 200},
          "diagram": {"x1": -50, "x2": 50, "y1": 100, "y2": 200}
        }
      }
    },
    "a_w": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 330, "y2": 430},
          "diagram": {"x1": -50, "x2": 50, "y1": 330, "y2": 430}
        }
      }
    },
    "v": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 570, "y2": 670},
          "diagram": {"x1": -50, "x2": 50, "y1": 570, "y2": 670}
        }
      }
    },
    "demand": {
      "Dyad": {
        "placement": {
          "icon": {"x1": -50, "x2": 50, "y1": 800, "y2": 900},
          "diagram": {"x1": -50, "x2": 50, "y1": 800, "y2": 900}
        }
      }
    },
    "p_cmd": {
      "Dyad": {
        "placement": {
          "icon": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550},
          "diagram": {"x1": 950, "x2": 1050, "y1": 450, "y2": 550}
        }
      }
    },
    "pressure": {"Dyad": {"placement": {"diagram": {"x1": 400, "x2": 600, "y1": 400, "y2": 600}}}},
    "id1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 200, "y": 850}, {"x": 200, "y": 450}], "E": 2}]}},
    "id2": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}}
  }
}
end
```

```txt [ABSStopWheelOnly]
component ABSStopWheelOnly
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  "Deceleration the estimator assumes while the wheel slips"
  parameter a_ref::Acceleration = 8
  "Pedal command: foot force as a fraction of 500 N"
  parameter pedal::Real = 0.6
  command = BlockComponents.Sources.Step(height = pedal, offset = 0.0, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  pedal_unit = VehicleSystemsComponents.Vehicle.Brake.BrakePedal()
  booster = VehicleSystemsComponents.Vehicle.Brake.StaticBooster()
  master = VehicleSystemsComponents.Vehicle.Brake.TandemMasterCylinder()
  valve_f = VehicleSystemsComponents.Vehicle.Brake.ABSValve()
  valve_r = VehicleSystemsComponents.Vehicle.Brake.ABSValve()
  line_f = VehicleSystemsComponents.Vehicle.Brake.BrakeLine()
  line_r = VehicleSystemsComponents.Vehicle.Brake.BrakeLine(L = 4.0)
  abs = PhaseABS()
  est = RefSpeedEstimator(a_ref = a_ref)
  wspeed = RotationalComponents.Sensors.VelocitySensor()
  wheel = VehicleSystemsComponents.Vehicle.Wheel.HydraulicBrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  fixed_hydraulic = TranslationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
  path medium::HydraulicComponents.Interfaces.AbstractMedium = HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)
relations
  connect(command.y, pedal_unit.u)
  connect(pedal_unit.rod, booster.input)
  connect(booster.rod_out, master.pushrod)
  connect(pedal_unit.support, booster.support, master.support, fixed_hydraulic.flange)
  connect(master.front, valve_f.port_a)
  connect(valve_f.port_b, line_f.port_a)
  connect(line_f.port_b, wheel.front)
  connect(master.rear, valve_r.port_a)
  connect(valve_r.port_b, line_r.port_a)
  connect(line_r.port_b, wheel.rear)
  continuity(medium, master.front.medium)
  connect(master.p_mc, abs.demand)
  connect(abs.p_cmd, valve_f.p_cmd, valve_r.p_cmd)
  connect(wspeed.spline, wheel.spline)
  connect(wspeed.w, est.omega)
  connect(est.kappa_hat, abs.kappa)
  connect(est.v_ref, abs.v)
  connect(est.a_w, abs.a_w)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.inertia.phi = 0
  initial wheel.inertia.w = 25 / 0.31
  initial body.mass.s = 0
  initial body.mass.v = 25
end

analysis ABSStopWheelOnlyTransient
  extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
  parameter road_mu::Real = 1.0
  parameter a_ref::Acceleration = 8
  model = ABSStopWheelOnly(road_mu = road_mu, a_ref = a_ref)
end
```

:::

::::


### 05 · Across road surfaces {#step-05}

One table from the REPL: your step 02 stop at pedal 0.6, which locks the wheel, your ABS on the true slip and your ABS on the wheel speed only, on dry, wet and snowy roads. Then the `a_ref` knob.

**Given:** `Vehicle.braking_distance`, step 02's, and `Vehicle.ABSBrakeTransient`, the lecture's own ABS model: the wheel-speed-only `Vehicle.ABSController`, clocked every 5 ms, on the library's `BrakedWheel`, a torque-level brake with a 30 ms lag. It is the deck's ABS column, run from the REPL for your table's fourth column; nothing to place.

#### Do this

1. Paste the loop into the REPL. The stop time grows on slippery roads so every car comes to rest; on snow it is about 20 s.

   ```julia
   using VehicleSystemsComponents: Vehicle
   stop(μ; a = Inf) = 0.5 + 1.5 * 25 / min(0.7μ * 9.81, a) + 1
   d(run) = round(Vehicle.braking_distance(run); digits = 1)
   for μ in (1.0, 0.5, 0.3)
       println(μ, "  ",
           d(MyCar.PedalStopTransient(road_mu = μ, stop = stop(μ))), "  ",
           d(MyCar.ABSStopTransient(road_mu = μ, stop = stop(μ))), "  ",
           d(MyCar.ABSStopWheelOnlyTransient(road_mu = μ, stop = stop(μ; a = 8))))
   end
   ```

2. The library's clocked wheel-speed-only ECU, the lecture's own model, for the fourth column:

   ```julia
   for μ in (1.0, 0.5, 0.3)
       println(μ, "  ", d(Vehicle.ABSBrakeTransient(road_mu = μ, stop = stop(μ; a = 8))))
   end
   ```

3. The `a_ref` knob. On snow *μ g* is about 2.9 m/s², and 0.8 *μ g* ≈ 2.4 m/s² is about where an estimate that learns the road would settle. Rerun your wheel-speed-only bench with `a_ref = 2.4`, on snow and on a dry road:

   ```julia
   d(MyCar.ABSStopWheelOnlyTransient(road_mu = 0.3, a_ref = 2.4, stop = 25))
   d(MyCar.ABSStopWheelOnlyTransient(road_mu = 1.0, a_ref = 2.4, stop = 15))
   ```

   And the library ECU with the same `a_ref` on snow:

   ```julia
   d(Vehicle.ABSBrakeTransient(road_mu = 0.3, a_ref = 2.4, stop = stop(0.3; a = 2.4)))
   ```

[![The Julia REPL after the loop: three rows, 1.0 43.7 34.2 38.5, 0.5 85.1 64.6 78.0 and 0.3 136.7 106.1 130.6.](/lecture/lecture-03/img/step05-surface-table.png)](/lecture/lecture-03/img/step05-surface-table.png)

[![Grouped bars of braking distance from 90 km/h at road mu 1.0, 0.5 and 0.3. Locked, pedal 0.6: 43.7, 85.1, 136.7 m. ABS on true slip: 34.2, 64.6, 106.1 m. ABS on wheel speed only, yours: 38.5, 78.0, 130.6 m. The library's clocked ECU: 38.7, 83.2, 141.3 m, the last longer than locked.](/lecture/lecture-03/img/step05-surfaces.svg)](/lecture/lecture-03/img/step05-surfaces.svg)

::: tip Expected result

| road μ | locked, pedal 0.6 | ABS, true slip | ABS, wheel only (yours) | ABS, wheel only (library, 5 ms) |
|---:|---:|---:|---:|---:|
| 1.0 | **43.7 m** | **34.2 m** | **38.5 m** | 38.7 m |
| 0.5 | **85.1 m** | **64.6 m** | **78.0 m** | 83.2 m |
| 0.3 | **136.7 m** | **106.1 m** | **130.6 m** | 141.3 m, longer than locked |

Your locked column matches the lecture's surface table within 0.1 m. Your true-slip column is close to its ideal-ABS column but not equal: yours brakes through the valves, lines and calipers of step 02. Both your ABS columns beat locked on every road. Your wheel-speed-only ABS keeps most of the gain on a dry road, level with the library ECU, but on snow it gains only about 5 %: its dumps empty the caliper (step 04). Measured cars gain little on packed snow too; the lecture's "Against measured cars" slide has the data. The library ECU falls into the `a_ref` trap on snow: `a_ref = 8` is almost three times what the road allows, so its estimate falls too fast, it under-reads the slip and lets the wheel slide. With `a_ref = 2.4` it stops in 128.4 m. Yours does not fall into it: it dumps on the wheel's own deceleration.

Your `a_ref = 2.4` reruns: **130.9 m** on snow, no better than at 8, and **106.3 m** on a dry road, the stop ruined. The other side of the same knob: an `a_ref` below the car's real deceleration lets the estimate run above the car, the estimated slip passes `lambda_1` while the tire sits at its peak, and the controller dumps on slip that is not there. An ABS can only be as good as its guess of the car's speed, and yours leans on the guess only to catch a locked wheel.

:::

::: warning Fell behind?

The loop needs the three analyses of steps 02–04 under exactly these names, each passing `road_mu` through. The reference analyses are `VehicleSystemsComponents.HandsOn03.PedalStopTransient`, `ABSStopTransient` and `ABSStopWheelOnlyTransient`: put `VehicleSystemsComponents.HandsOn03.` in place of `MyCar.` to run the loop on them.

:::

## 04 Traction control

Lecture deck: [traction control](../../lecture-03/index.html#/tcs){target="_self"}

### 06 · Take-home bonus: traction control {#step-06}

A bonus task for home, for extra points. Your whole car from hands-on 2 on snow, full throttle from rest: without traction control the wheel spins up, as on Lecture 1's ice patch. You stop it two ways, with the brakes and with the engine, and compare. The lecture's "brake or engine" slide has the answer to aim for.

#### Parts

- From hands-on 2: your mapped engine with fuel cut, flywheel, centrifugal clutch, CVT and car body (your `MappedCar`).
- From hands-on 3: your two `ABSValve`s and brake lines, the `HydraulicBrakedWheel`, and `SlipABS` from step 03.
- Given: `HydraulicComponents › Sources › BoundaryPressure`, `ABSPressureIntegrator`, and the standard `Min` and `Gain` blocks.

#### The task

1. The car: connect the mapped engine through the flywheel, centrifugal clutch and CVT to the `HydraulicBrakedWheel`, and the wheel to the body. Put an `ABSValve` and a brake line in each brake circuit.
2. The pressure: nobody presses the pedal while accelerating, so leave out the pedal, booster and master cylinder. Feed both valves from a `BoundaryPressure` at 8.9 MPa. It stands in for the pump and accumulator a real TCS unit has.
3. The brake TCS: `SlipABS` turned round. Driving slip is positive, so the pressure builds while `kappa_pred > lambda_target` and falls otherwise, between zero and the supply pressure.
4. The engine TCS: the same law on a throttle limit between 0 and 1. It falls while the predicted slip is above the target and recovers below it. Feed the engine with `Min(driver throttle, limit)`, and keep the driver's throttle wired straight to the CVT schedule. The throttle acts through the manifold, so look further ahead than the brake: 0.3 s instead of 30 ms.
5. The bench: start the engine at idle, step the throttle to full at 0 s, `mu_scale = 0.2`, 10 s. Give it two parameters, `brake_enabled` and `engine_enabled`, each through its own `Gain`, so the diagram shows both loops.
6. Run four cases: off, brake only, engine only, both.

::: tip Expected result

With Tsit5 and `dtmax = 1e-3`, at 10 s:

| TCS | speed | slip | engine | burned in the brakes |
|---|---:|---:|---:|---:|
| off | 5.64 m/s | 9.7 | 6410 rpm | 0 |
| brake only | 5.99 m/s | 0.11 | 2450 rpm | 115 kJ |
| engine only | 6.62 m/s | 0.03 | 2520 rpm | 0 |
| both | 6.45 m/s | 0.03 | 2450 rpm | 28 kJ |

The CVT stays at its 12:1 launch ratio in the three controlled runs. If the uncontrolled run stops early on the 6500 rpm rev limiter, set `abstol = 1e-5` and `reltol = 1e-5` in the analysis.

:::

#### Hand in

A pull request from your `lecture-03` branch into the branch you started from, not merged, with:

- wheel slip and car speed over 10 s for the four cases;
- one paragraph: why braking barely helps here and cutting the engine does, what an open differential with two driven wheels would change, and why the engine path needs a much longer look-ahead than the brake.

## 05 Electronic stability program

Lecture deck: [ESP](../../lecture-03/index.html#/esp){target="_self"}

A demo on the course library's planar car: nothing to build. The lecturer runs the sine-with-dwell test without ESP, with ESP braking the wheels directly and with ESP through four ABS channels, then a split-µ stop with one side on ice. Every number is recomputed in `notebooks/lecture03/03-esp.pluto.jl`.

---

Reference models: `dyad/HandsOn03/` in the course repository; checkpoint tests in `test/abs_handson_plausibility.jl`. Build plan: `docs/lecture-03-handson-plan.md`.

## Planar ABS demo calibration (issue #156)

The four-wheel demo is separate from the 90 km/h one-wheel builds above. Its dry stop
from 80 km/h is **26.52 m** (previously 36.05 m), with established deceleration **9.74 m/s²**;
from 100 km/h it is **41.03 m**. Predicted release 0.14 front / 0.11 rear surrounds the
tires' 0.12 / 0.09 peaks (derived); 80 ms prediction, 90% pressure retention and 10 ms hold
are calibrated assumptions, not a claimed Bosch production calibration. A 40 kN·m/s initial
build preserves low-grip recovery. Uniform μ=0.3 stops in **85.73 m**, without wheel lock.
Brake-and-steer: **28.3 m** along the path, **2.64 m** sideways at the obstacle, versus
31.6 m and effectively zero sideways locked.

Dry-asphalt anchors: auto motor und sport's Leaf ZE1, 39 m from 100 km/h; Argonne's
2013 Leaf, 36.9 m from 60 mph. Sources are linked in
`docs/research_notes/Electric and hybrid vehicles/bev-road-load-and-braking-validation.md`, item 8.
