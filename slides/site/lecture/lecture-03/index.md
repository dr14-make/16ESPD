---
title: Lecture 3 — build an ABS of your own
---

[← Vehicle Systems & Components](../../index.html) · [Lecture deck →](../../lecture-03/index.html){target="_self"}

# Lecture 3: build an ABS of your own

From a car whose wheel locks under a panic stop to an ABS that sees only the wheel speed, tested on dry, wet and snowy roads

**What you build.** Your `MyCar` from the [hands-on](../../handson/lecture-01/) has a `Body`. In this lecture you put it on the course library's braked wheel and brake it from 90 km/h, along with the lecturer: first with no ABS, then with a slip controller of your own, then with an ABS that knows only the wheel speed. Every number the lecture's ABS slides show comes out of a model on your own screen. Step 01 is on paper; steps 02–04 each add one bench or controller; step 05 is a table from the REPL. Traction control is a bonus task to take home. ESP is a demo: nothing to build.

**How each step works.** The slide that introduces a step shows the finished diagram or code and links here. Each step below lists the blocks to place with their library path, instance name and values, every wire and line of code, and what the plot and the braking distance must show before you go on. Use the names given here: the steps after it read signal paths like `abs.tau_cmd` and `est.v_ref`, and the REPL loop of step 05 calls your analyses by name.

**Fell behind?** Every step ends with a **Fell behind?** block: the finished code of that step, to paste. The course repository has the same components as the reference answers in `dyad/HandsOn03/`, under the same names; under **+** they show as `VehicleSystemsComponents › HandsOn03`. Build your own; open them only to compare.

**Plotting.** Every plot is drawn in the Julia REPL: click **Dyad: Open Julia REPL** in the **Actions** panel's title bar. Each snippet starts with `using Plots; plotly()`, which switches Plots to its interactive backend. Snippets do not load `MyCar`: the REPL that runs your analyses has already included it.

**Solver.** Every analysis today runs **Tsit5** with a maximum step of 1 ms (`dtmax = 1e-3`). The ABS switches the brake every few milliseconds behind a 30 ms lag; a stiff solver such as FBDF steps over the switching and reports a wrong success.

Every number in an expected result is a test expectation or a measured run of the reference model, with Tsit5 at `dtmax = 1e-3`.

**00 — Before the first section**

- [00 · Set up: the course library](#step-00)

**01 — Friction and stopping**

- [01 · The tire's limit, by hand](#step-01)

**03 — Anti-lock braking**

- [02 · Lock the wheel](#step-02)
- [03 · An ABS of your own](#step-03)
- [04 · Only the wheel speed](#step-04)
- [05 · Across road surfaces](#step-05)

**04 — Traction control**

- [06 · Take-home bonus: traction control](#step-06)

## 00 Set up

Lecture deck: [front matter](../../lecture-03/index.html#/build-setup){target="_self"}

### 00 · Set up: the course library {#step-00}

Today's parts, the braked wheel and the pressure integrator, are in the course library. Your `MyCar` needs a version that has them.

#### Do this

1. In the status bar, click the branch name → **Create new branch…** → `lecture-03`, from `main`. If you finished hands-on 2, branch from where it left you. If not, `main` is enough: today needs only hands-on 1's `Body`.
2. Open the Julia REPL and add the course library at the tag this lecture was rehearsed on. If you added it in hands-on 2, this replaces that branch pin.

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "TODO-TAG")
   ```

   <!-- TODO: replace TODO-TAG with the rehearsed tag, here and on the deck's build 00 slide. -->

3. <kbd>F1</kbd> → **Dyad: Compile**.
4. Open any diagram, click **+** and open `VehicleSystemsComponents` → `Vehicle` → `Wheel`.

::: info Screenshot to come

`step00-wheel-library.png`: the **+** popup open at `VehicleSystemsComponents › Vehicle › Wheel`, listing `BrakedWheel`, `BrakeActuator` and `TireFrictionCurve`.

:::

::: tip Expected result

`using VehicleSystemsComponents` runs in the REPL without an error. Under **+**, `Vehicle › Wheel` lists `BrakedWheel`, `BrakeActuator` and `TireFrictionCurve`, and `Vehicle` lists `ABSPressureIntegrator`.

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

## 03 Anti-lock braking

Lecture deck: [anti-lock braking](../../lecture-03/index.html#/abs){target="_self"}

### 02 · Lock the wheel {#step-02}

A braking bench with your own `Body` on the library's braked wheel. A 6000 N·m step at 0.5 s locks the wheel, and the car stops on the sliding friction.

#### Parts

New component `LockedStop` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `road_mu` | parameter `Real` | `1.0` — road-friction multiplier |
| `wheel` | VehicleSystemsComponents › Vehicle › Wheel › BrakedWheel | defaults |
| `body` | your `Body` (hands-on 1) | — |
| `fixed` | RotationalComponents › Components › Fixed | — |
| `speed` | TranslationalComponents › Sensors › VelocitySensor | — |
| `demand` | BlockComponents › Sources › Step | `height = 6000`, `start_time = 0.5` |
| `road` | BlockComponents › Sources › Constant | `k = road_mu` |

`BrakedWheel` is the wheel's inertia (4 kg·m²), a brake that follows its torque command with a 30 ms lag, and the tire curve, with the whole car's weight on it. Its `tau_cmd` input is the brake torque asked for; its output `kappa` is the wheel's true slip.

#### Do this

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `LockedStop`. Click an empty spot of the canvas → **Add parameter** `road_mu`, type `Real`, value `1.0`. Place the six blocks from the table.
2. Wire:
   - `demand.y → wheel.tau_cmd`
   - `road.y → wheel.mu_scale`
   - `wheel.support → fixed.spline`
   - `wheel.flange → body.flange`, and `speed.flange → body.flange`
3. Toggle to code (⇄) and add the starting state at the end of `relations`: the brake at zero torque, the wheel rolling at the car's speed, the car at 25 m/s.

   ::: code-group

   ```txt [Initial state]
     initial wheel.brake.tau_actual = 0
     initial wheel.inertia.phi = 0
     initial wheel.inertia.w = 25 / 0.31
     initial body.mass.s = 0
     initial body.mass.v = 25
   ```

   :::

   Forget them and the wheel starts at rest: the run then shows a wheel spinning up, not a stop.

4. <Badge type="tip" text="New analysis" /> Add the analysis in code, below the component, so it sets the solver and passes `road_mu` through for step 05:

   ```txt
   analysis LockedStopTransient
     extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
     parameter road_mu::Real = 1.0
     model = LockedStop(road_mu = road_mu)
   end
   ```

5. Run it, plot the speed and the slip, and read the braking distance. `braking_distance` measures from the brake application at 0.5 s until the car is below 0.5 m/s.

   ```julia
   using Plots; plotly()
   r = MyCar.LockedStopTransient()
   plot(r; idxs = [r."speed.v", r."wheel.kappa"], layout = (2, 1))
   VehicleSystemsComponents.Vehicle.braking_distance(r)
   ```

::: info Screenshot to come

`step02-locked-bench.png`: the finished `LockedStop` diagram, `demand` and `road` on the left, `wheel` in the middle with `fixed` under it, `body` and `speed` on the right.

:::

[![Two panels against time. Top: car speed falls in a straight line from 90 km/h at 0.5 s to zero at about 4 s, while the wheel's surface speed drops to zero within 0.17 s. Bottom: wheel slip goes from 0 to -1 at about 0.67 s and stays there. Title: locked stop, 43.7 m from 90 km/h.](/lecture/lecture-03/img/step02-locked-stop.svg)](/lecture/lecture-03/img/step02-locked-stop.svg)

::: tip Expected result

`wheel.kappa` reaches **−1** at **0.67 s**, 0.17 s after the step, and stays there. The car is at rest at **4.0 s**. `braking_distance` gives **43.7 m**: just short of the 45.5 m sliding bound of step 01, because the wheel is not locked for the first 0.17 s, and drag and rolling resistance help. At `road_mu` 0.5 and 0.3: 85.1 and 136.8 m.

Reference: `HandsOn03.LockedStop`, `HandsOn03.LockedStopTransient`. It equals the library's `Vehicle.LockedBrakeTransient` to machine precision.

:::

:::: warning Fell behind?

Right-click `MyCar` → **Add Component**, name it `LockedStop`, toggle to code (⇄) and paste this over its contents. It needs your `Body` from hands-on 1.

::: code-group

```txt [LockedStop]
component LockedStop
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  "Driver's brake demand, 6000 N·m from 0.5 s"
  demand = BlockComponents.Sources.Step(height = 6000, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  wheel = VehicleSystemsComponents.Vehicle.Wheel.BrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
relations
  connect(demand.y, wheel.tau_cmd)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.brake.tau_actual = 0
  initial wheel.inertia.phi = 0
  initial wheel.inertia.w = 25 / 0.31
  initial body.mass.s = 0
  initial body.mass.v = 25
end

analysis LockedStopTransient
  extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
  parameter road_mu::Real = 1.0
  model = LockedStop(road_mu = road_mu)
end
```

:::

::::

### 03 · An ABS of your own {#step-03}

A slip controller that keeps the wheel off the sliding plateau. First on the present slip (A), then on the slip predicted 30 ms ahead (C), which leads the brake's lag.

#### Parts

New component `SlipABS`, written in code:

| Name | What | Set |
| --- | --- | --- |
| `kappa`, `v`, `demand` | inputs: wheel slip, car speed, driver's demand | — |
| `tau_cmd` | output: brake torque command | — |
| `pressure` | VehicleSystemsComponents › Vehicle › ABSPressureIntegrator | `T_track = 0.01` |
| `lambda_target` | parameter | `0.04` — the slip held, the tire's peak |
| `k_inc`, `k_dec` | parameters | `20000`, `40000` N·m/s — build and dump rates |
| `v_min` | parameter | `1.5` m/s — ABS off below this speed |
| `T_p`, `T_f` | parameters (part C) | `0.03` s look-ahead, `0.003` s slip-rate filter |

`ABSPressureIntegrator` is given: it integrates `requested_rate` into a torque command and keeps it between zero and `demand`; while `active` is 0 it tracks the demand within `T_track`. A positive rate is the modulator's build, a negative one its dump, zero its hold.

#### Do this

1. <Badge type="tip" text="New component" /> **A · the controller.** Right-click `MyCar` → **Add Component**, name it `SlipABS`, toggle to code (⇄) and write the ports, parameters and `pressure` from the table. The relations, for part A:

   ```txt
     connect(demand, pressure.demand)
     pressure.requested_rate = ifelse(kappa < -lambda_target, -k_dec, k_inc)
     pressure.active = ifelse(v > v_min, 1.0, 0.0)
     connect(pressure.tau_cmd, tau_cmd)
   ```

   Slip is negative while braking: past −0.04 the wheel is beyond the peak, so dump; otherwise build.

2. <Badge type="tip" text="New component" /> **B · the bench.** Right-click `LockedStop` → **Duplicate**, name it `ABSStop`. Place your `SlipABS` as `abs`. Delete the wire `demand.y → wheel.tau_cmd` and wire instead:
   - `demand.y → abs.demand`, `abs.tau_cmd → wheel.tau_cmd`
   - `wheel.kappa → abs.kappa`, `speed.v → abs.v`

   Add the analysis `ABSStopTransient` below it, as in step 02 but with `model = ABSStop(road_mu = road_mu)`. Run it and plot the torque at the wheel and the slip:

   ```julia
   using Plots; plotly()
   r = MyCar.ABSStopTransient()
   plot(r; idxs = [r."wheel.brake.tau_actual", r."wheel.kappa"], layout = (2, 1))
   VehicleSystemsComponents.Vehicle.braking_distance(r)
   ```

3. **C · the look-ahead.** In `SlipABS` add the parameters `T_p = 0.03` and `T_f = 0.003`, three variables, and three lines; the rate line now reads `kappa_pred`:

   ```txt
     variable kappa_f::Real
     variable kappa_dot::Real
     variable kappa_pred::Real
   relations
     initial kappa_f = 0
     der(kappa_f) = (kappa - kappa_f) / T_f
     kappa_dot = (kappa - kappa_f) / T_f
     kappa_pred = kappa + T_p * kappa_dot
     pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
   ```

   `kappa_f` follows the slip 3 ms late, so `kappa_dot` is the slip's rate of change, filtered. Run `ABSStopTransient` again. With the full code below, `MyCar.ABSStopTransient(T_p = 0)` is run A again.

::: info Screenshots to come

`step03-slipabs-code.png`: `SlipABS` in the code view, the `pressure` line and the three look-ahead lines visible. `step03-abs-bench.png`: the `ABSStop` diagram, `abs` between `demand` and `wheel`, with the `wheel.kappa` and `speed.v` wires back into it.

:::

[![Two panels against time for the two ABS runs. Top, brake torque: without look-ahead it saws between about 600 and 4700 N·m; with the 30 ms look-ahead it holds near 4300 to 4400 N·m, just above the dotted 4256 N·m tire peak, until 3 s. Bottom, slip: without look-ahead each cycle dives past the -0.12 sliding line; with it the slip sits on the -0.04 peak line.](/lecture/lecture-03/img/step03-abs-torque-slip.svg)](/lecture/lecture-03/img/step03-abs-torque-slip.svg)

::: tip Expected result

**A, no look-ahead:** **53.8 m**, *longer* than the locked 43.7 m. The torque saws between about 600 and 4700 N·m at **2.6 Hz**, and the slip dives past the 12 % sliding point every cycle: 26 % of the stop is spent sliding. Not a mistake: the law reacts to the slip now, but the brake follows 30 ms later, so every dump comes too late.

**C, look-ahead 30 ms:** **34.4 m**, 21 % shorter than locked. `wheel.brake.tau_actual` holds at 4300–4400 N·m with a small **31 Hz** ripple, a little *above* the 4256 N·m of step 01 (the brake also decelerates the wheel's inertia). `wheel.kappa` stays near −0.04 and never passes −0.12. Below 1.5 m/s, at 3.0 s, the ABS switches off and the wheel locks just before standstill. `abs.tau_cmd` never exceeds the demand. At `road_mu` 0.5 and 0.3: 63.4 and 102.2 m.

C is the library's `ABSIdealController` equation for equation: `ABSStopTransient` equals `Vehicle.IdealBrakeTransient` to machine precision. Reference: `HandsOn03.SlipABS`, `HandsOn03.ABSStop`.

:::

:::: warning Fell behind?

Add components `SlipABS` and `ABSStop` in `MyCar`, toggle each to code (⇄) and paste over its contents. `ABSStop` needs your `Body`; its analysis passes `T_p` through, so `MyCar.ABSStopTransient(T_p = 0)` is run A.

::: code-group

```txt [SlipABS]
component SlipABS
  "Wheel slip, negative while braking"
  kappa = RealInput()
  "Vehicle speed"
  v = RealInput()
  "Driver's brake demand"
  demand = RealInput()
  "Brake torque command to the wheel"
  tau_cmd = RealOutput()
  pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01)
  "Slip held, just past the tire's peak"
  parameter lambda_target::Real = 0.04
  "Pressure build rate [N·m/s]"
  parameter k_inc::Real = 20000
  "Pressure dump rate [N·m/s]"
  parameter k_dec::Real = 40000
  "ABS off below this speed"
  parameter v_min::Velocity = 1.5
  "Look-ahead, the brake's lag"
  parameter T_p::Time = 0.03
  "Slip-rate filter"
  parameter T_f::Time = 0.003
  variable kappa_f::Real
  variable kappa_dot::Real
  variable kappa_pred::Real
relations
  initial kappa_f = 0
  der(kappa_f) = (kappa - kappa_f) / T_f
  kappa_dot = (kappa - kappa_f) / T_f
  kappa_pred = kappa + T_p * kappa_dot
  connect(demand, pressure.demand)
  pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
  pressure.active = ifelse(v > v_min, 1.0, 0.0)
  connect(pressure.tau_cmd, tau_cmd)
end
```

```txt [ABSStop]
component ABSStop
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  "Look-ahead; 0 is part A"
  parameter T_p::Time = 0.03
  "Driver's brake demand, 6000 N·m from 0.5 s"
  demand = BlockComponents.Sources.Step(height = 6000, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  abs = SlipABS(T_p = T_p)
  wheel = VehicleSystemsComponents.Vehicle.Wheel.BrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
relations
  connect(demand.y, abs.demand)
  connect(abs.tau_cmd, wheel.tau_cmd)
  connect(wheel.kappa, abs.kappa)
  connect(speed.v, abs.v)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.brake.tau_actual = 0
  initial wheel.inertia.phi = 0
  initial wheel.inertia.w = 25 / 0.31
  initial body.mass.s = 0
  initial body.mass.v = 25
end

analysis ABSStopTransient
  extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Tsit5(), dtmax = 1e-3)
  parameter road_mu::Real = 1.0
  parameter T_p::Time = 0.03
  model = ABSStop(road_mu = road_mu, T_p = T_p)
end
```

:::

::::

### 04 · Only the wheel speed {#step-04}

A real ABS measures only the wheel speed. This step feeds your ABS from a wheel-speed sensor alone, through an estimate of the car's speed you write, with the cycle a production ECU runs: dump, hold, and build slowly from the held level.

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
| `tau_cmd` | output | — |
| `pressure` | ABSPressureIntegrator, as before | `T_track = 0.01` |
| `a_minus` | parameter | `12` m/s² — wheel deceleration that starts a dump |
| `a_plus` | parameter | `3` m/s² — wheel acceleration that holds |
| `lambda_1` | parameter | `0.2` — estimated slip that starts a dump |
| `k_dec`, `k_inc` | parameters | `40000`, `8000` N·m/s — dump, and the slow rebuild |
| `v_min` | parameter | `1.5` m/s |
| `T_latch` | parameter | `0.001` s |

#### Do this

1. <Badge type="tip" text="New component" /> **A · the estimator.** Add `RefSpeedEstimator`, toggle to code (⇄), write the ports and parameters, two variables `v_w::Velocity` and `v_f::Velocity`, and the relations:

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

2. <Badge type="tip" text="New component" /> **B · the controller.** Right-click `SlipABS` → **Duplicate**, name it `PhaseABS`. Delete the look-ahead (its two parameters, three variables and four lines). Add the input `a_w`, the parameters from the table, and two variables `phase::Real` and `cycled::Real`. The relations:

   ```txt
     phase = ifelse(a_w > a_plus, 0, ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
     initial cycled = 0
     der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
     connect(demand, pressure.demand)
     pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
     pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
     connect(pressure.tau_cmd, tau_cmd)
   ```

   `phase` is −1 dump, 0 hold, 1 build. A rolling wheel cannot decelerate faster than the car, at most about 9.8 m/s² on a dry road, so a wheel decelerating past 12 m/s² has gone over the tire's peak. The estimated slip only catches a wheel that is already locked. `cycled` is a latch: until the first dump the integrator is inactive and passes the demand through, the fast first build; afterwards every build is slow and starts from where the hold left the pressure.

3. <Badge type="tip" text="New component" /> **C · the bench.** Right-click `ABSStop` → **Duplicate**, name it `ABSStopWheelOnly`. Replace `abs` with a `PhaseABS` named `abs`. Delete the `wheel.kappa` and `speed.v` wires into `abs`. Place:

   | Name | Library path | Set |
   | --- | --- | --- |
   | `wspeed` | RotationalComponents › Sensors › VelocitySensor | — |
   | `est` | your `RefSpeedEstimator` | `a_ref = a_ref` |
   | `a_ref` | parameter `Acceleration` on the bench | `8` |

   Wire `wspeed.spline → wheel.spline`, `wspeed.w → est.omega`, `est.kappa_hat → abs.kappa`, `est.a_w → abs.a_w`, `est.v_ref → abs.v`. Add the analysis `ABSStopWheelOnlyTransient` passing `road_mu` and `a_ref` (see the code below). Run it, then the wet road:

   ```julia
   using Plots; plotly()
   r = MyCar.ABSStopWheelOnlyTransient()
   VehicleSystemsComponents.Vehicle.braking_distance(r)
   r = MyCar.ABSStopWheelOnlyTransient(road_mu = 0.5, stop = 10)
   plot(r; idxs = [r."abs.phase", r."abs.tau_cmd", r."wheel.brake.tau_actual"],
        layout = (3, 1), xlims = (0.9, 1.45))
   ```

::: info Screenshots to come

`step04-estimator-code.png` and `step04-phaseabs-code.png`: the two components in the code view. `step04-wheel-only-bench.png`: the `ABSStopWheelOnly` diagram with `wspeed` on the wheel shaft and `est` feeding `abs`. `step04-phase-plot.png`: the student's own phase plot at `road_mu = 0.5`.

:::

[![Two panels from 0.9 to 1.45 s of the wheel-speed-only stop at road mu 0.5. Top, brake torque: the command climbs slowly in green build phases, drops in short red dump phases and stays flat in amber hold phases; the torque at the wheel follows it between 2000 and 2300 N·m. Bottom, speed: the car falls steadily, the wheel runs about 3 km/h below it, and the estimate rides the wheel. Title: 69.8 m.](/lecture/lecture-03/img/step04-phase-cycle.svg)](/lecture/lecture-03/img/step04-phase-cycle.svg)

::: tip Expected result

**Dry road: 35.5 m**, shorter than your locked wheel (43.7 m) and than the library's clocked wheel-speed-only ECU (38.7 m), 1.1 m from your true-slip ABS. **Wet, μ 0.5: 69.8 m** against 85.1 m locked; **snow, μ 0.3: 119.6 m** against 136.8 m.

At μ 0.5 the cycle runs build → dump → hold → build, about 5 dumps a second; `abs.pressure.p` is flat in every hold, and the torque at the wheel stays between about 2000 and 2300 N·m early in the stop. On a dry road the dump ends before the wheel turns round, so the hold never comes: dump and slow build, about 10 a second. `abs.tau_cmd` never exceeds the demand.

Keep `T_f` at 5 ms: filter `a_w` more heavily, at 10 ms, and the snow stop grows to 137.8 m, longer than locked; the filter lag plays the part the brake lag played in step 03 A.

Reference: `HandsOn03.RefSpeedEstimator`, `HandsOn03.PhaseABS`, `HandsOn03.ABSStopWheelOnly`.

:::

:::: warning Fell behind?

Add the three components in `MyCar`, toggle each to code (⇄) and paste. Short of time? Paste `PhaseABS` and the bench, and write only the estimator.

::: code-group

```txt [RefSpeedEstimator]
component RefSpeedEstimator
  "Wheel speed from a sensor on the wheel shaft"
  omega = RealInput()
  "Estimated wheel slip"
  kappa_hat = RealOutput()
  "Estimated vehicle speed"
  v_ref = RealOutput()
  "Wheel surface acceleration"
  a_w = RealOutput()
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
end
```

```txt [PhaseABS]
component PhaseABS
  "Estimated wheel slip, negative while braking"
  kappa = RealInput()
  "Wheel surface acceleration"
  a_w = RealInput()
  "Estimated vehicle speed"
  v = RealInput()
  "Driver's brake demand"
  demand = RealInput()
  "Brake torque command to the wheel"
  tau_cmd = RealOutput()
  pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01)
  "Wheel deceleration that starts a dump (-a)"
  parameter a_minus::Acceleration = 12
  "Wheel acceleration that holds the pressure (+a)"
  parameter a_plus::Acceleration = 3
  "Estimated slip that starts a dump"
  parameter lambda_1::Real = 0.2
  "Dump rate [N·m/s]"
  parameter k_dec::Real = 40000
  "Rebuild rate after the first dump [N·m/s]"
  parameter k_inc::Real = 8000
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
  connect(demand, pressure.demand)
  pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
  pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
  connect(pressure.tau_cmd, tau_cmd)
end
```

```txt [ABSStopWheelOnly]
component ABSStopWheelOnly
  "Road-friction multiplier (1 dry, 0.5 wet, 0.3 snow)"
  parameter road_mu::Real = 1.0
  "Deceleration the estimator assumes while the wheel slips"
  parameter a_ref::Acceleration = 8
  "Driver's brake demand, 6000 N·m from 0.5 s"
  demand = BlockComponents.Sources.Step(height = 6000, start_time = 0.5)
  road = BlockComponents.Sources.Constant(k = road_mu)
  abs = PhaseABS()
  est = RefSpeedEstimator(a_ref = a_ref)
  wspeed = RotationalComponents.Sensors.VelocitySensor()
  wheel = VehicleSystemsComponents.Vehicle.Wheel.BrakedWheel()
  body = Body()
  fixed = RotationalComponents.Components.Fixed()
  speed = TranslationalComponents.Sensors.VelocitySensor()
relations
  connect(demand.y, abs.demand)
  connect(abs.tau_cmd, wheel.tau_cmd)
  connect(wspeed.spline, wheel.spline)
  connect(wspeed.w, est.omega)
  connect(est.kappa_hat, abs.kappa)
  connect(est.v_ref, abs.v)
  connect(est.a_w, abs.a_w)
  connect(road.y, wheel.mu_scale)
  connect(wheel.support, fixed.spline)
  connect(wheel.flange, body.flange, speed.flange)
  initial wheel.brake.tau_actual = 0
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

One table from the REPL: your locked wheel, your ABS on the true slip and your ABS on the wheel speed only, on dry, wet and snowy roads. Then the `a_ref` knob.

#### Do this

1. Paste the loop into the REPL. The stop time grows on slippery roads so every car comes to rest; on snow it is about 20 s.

   ```julia
   using VehicleSystemsComponents: Vehicle
   stop(μ; a = Inf) = 0.5 + 1.5 * 25 / min(0.7μ * 9.81, a) + 1
   d(run) = round(Vehicle.braking_distance(run); digits = 1)
   for μ in (1.0, 0.5, 0.3)
       println(μ, "  ",
           d(MyCar.LockedStopTransient(road_mu = μ, stop = stop(μ))), "  ",
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

::: info Screenshot to come

`step05-surface-table.png`: the REPL after the loop, the three rows of distances.

:::

[![Grouped bars of braking distance from 90 km/h at road mu 1.0, 0.5 and 0.3. Locked: 43.7, 85.1, 136.8 m. ABS on true slip: 34.4, 63.4, 102.2 m. ABS on wheel speed only, yours: 35.5, 69.8, 119.6 m. The library's clocked ECU: 38.7, 83.2, 141.3 m, the last longer than locked.](/lecture/lecture-03/img/step05-surfaces.svg)](/lecture/lecture-03/img/step05-surfaces.svg)

::: tip Expected result

| road μ | locked | ABS, true slip | ABS, wheel only (yours) | ABS, wheel only (library, 5 ms) |
|---:|---:|---:|---:|---:|
| 1.0 | **43.7 m** | **34.4 m** | **35.5 m** | 38.7 m |
| 0.5 | **85.1 m** | **63.4 m** | **69.8 m** | 83.2 m |
| 0.3 | **136.8 m** | **102.2 m** | **119.6 m** | 141.3 m, longer than locked |

Your first two columns must match the lecture's surface table to the decimal. Your wheel-speed-only ABS keeps most of the gain on a dry road and about half of it on snow. The library ECU falls into the `a_ref` trap on snow: `a_ref = 8` is almost three times what the road allows, so its estimate falls too fast, it under-reads the slip and lets the wheel slide. With `a_ref = 2.4` it stops in 128.4 m. Yours does not fall into it: it dumps on the wheel's own deceleration.

Your `a_ref = 2.4` reruns: **124.1 m** on snow, *longer* than at 8, and **105.4 m** on a dry road. The other side of the same knob: an `a_ref` below the car's real deceleration lets the estimate run above the car, the estimated slip passes `lambda_1` while the tire sits at its peak, and the controller dumps on slip that is not there. An ABS can only be as good as its guess of the car's speed.

:::

::: warning Fell behind?

The loop needs the three analyses of steps 02–04 under exactly these names, each passing `road_mu` through. The reference analyses are `VehicleSystemsComponents.HandsOn03.LockedStopTransient`, `ABSStopTransient` and `ABSStopWheelOnlyTransient`: put `VehicleSystemsComponents.HandsOn03.` in place of `MyCar.` to run the loop on them.

:::

## 04 Traction control

Lecture deck: [traction control](../../lecture-03/index.html#/tcs){target="_self"}

### 06 · Take-home bonus: traction control {#step-06}

A bonus task for home, for extra points. Hands-on 1's `SlipCar` on snow, full torque from rest: without traction control the wheel spins up, as on Lecture 1's ice patch; with a brake-based TCS it holds near the peak and the car is faster after 10 s.

#### Parts

- Given: `VehicleSystemsComponents › Vehicle › Wheel › BrakeActuator` (a brake with a 30 ms lag) and `ABSPressureIntegrator`.
- Yours: `SlipCar` from hands-on 1, and `SlipABS` from step 03.

#### The task

1. `TCSSlipCar`: duplicate `SlipCar`, put a `BrakeActuator` between `wheel_inertia` and `wheel` with its `support` on `rot_ground`, and add an input `tau_tcs` for its command.
2. `TCS`: step 03's law turned round. The slip is positive while driving: the pressure builds while `kappa_pred > lambda_target` and falls otherwise, clipped to [0, `tau_tcs_max`].
3. A bench: a full-torque step on `tau_cmd` from rest, `mu_scale = 0.2`, 10 s. Run it with and without the TCS.

#### Hand in

A pull request from your `lecture-03` branch into the branch you started from, not merged, with:

- wheel slip and car speed over 10 s, with and without TCS. By hand, the traction limit is 0.2 × 6865 N = **1373 N** at the peak against **961 N** spinning: roughly **8.5 against 5.7 m/s** after 10 s;
- one paragraph: why a production TCS cuts engine torque when both driven wheels spin, what `SlipCar`'s 0.3 s engine delay would do to that loop, and why braking one wheel works only through an open differential, which a one-wheel model cannot show.

## 05 Electronic stability program

Lecture deck: [ESP](../../lecture-03/index.html#/esp){target="_self"}

A demo on the course library's planar car: nothing to build. The lecturer runs the sine-with-dwell test without ESP, with ESP braking the wheels directly and with ESP through four ABS channels, then a split-µ stop with one side on ice. Every number is recomputed in `notebooks/lecture03/03-esp.pluto.jl`.

---

Reference models: `dyad/HandsOn03/` in the course repository; checkpoint tests in `test/abs_handson_plausibility.jl`. Build plan: `docs/lecture-03-handson-plan.md`.
