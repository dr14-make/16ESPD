---
title: Lecture 1 — build the cruise controller
---

[← Vehicle Systems & Components](../../index.html) · [Lecture deck →](../../lecture-01/index.html){target="_self"}

# Lecture 1: build the cruise controller

From the car you built in the hands-on to a PID cruise control that survives a hill, a noisy speedometer and a patch of ice

**What you build.** The [hands-on](../../handson/lecture-01/) left you a car: torque command in, speed out. In this lecture you put a controller in front of it and close the loop, one block at a time, along with the lecturer. Every plot in the lecture comes from a diagram you have on your own screen. The loop itself — setpoint, controller, car, road — is drawn once in step 2 and never changes again; every later step happens inside the controller.

**How each step works.** The slide that introduces a step shows the finished diagram and links here. Each step below lists the blocks to place with their library path, instance name and values, every wire, and what the plot must show before you go on. Use the instance names given here: the lecture's notebooks read signal paths like `controller.integrator.y`, and with the same names your diagram reads the same way.

**Fell behind?** There are two catch-up checkpoints: the **P checkpoint** at the end of step 3 and the **PID checkpoint** at the end of step 5. Each has your `CruiseController` and `CruiseLoopStep` as they stand at that point, as code to paste. The course repository has the same checkpoints in `dyad/Lecture1/CruiseLoop.dyad`: the reference `CruiseLoop`, whose switches `with_I` and `with_D` turn the integral and derivative branches on and off.

Every component here exists in the course repository, and every number in an expected result is a test expectation or a docstring of the reference model.

**01 — The car you built**

- [1a · Step test on your car](#step-1a)
- [1b · `GradeCar`: the car on a hill](#step-1b)

**02–05 — Closing the loop, P, PI, PID**

- [2 · The loop and the controller shell](#step-2)
- [3 · Proportional: one gain](#step-3) — checkpoint **P**
- [4 · Integral: an integrator and a placeholder](#step-4)
- [5 · Derivative: the filtered derivative branch](#step-5) — checkpoint **PID**

**06 — Integral windup**

- [6a · `T_max` on `GradeCar`](#step-6a)
- [6b · The limiter](#step-6b)
- [6c · The climb: watch the integrator wind up](#step-6c)
- [6d · Clamping: freeze the integrator](#step-6d)

**07–10 — Noise, tuning, sampling, slip**

- [7 · A noisy speedometer](#step-7)
- [8 · Mass and delay as parameters](#step-8)
- [9 · Discretization (demo)](#step-9)
- [10 · Cruise control on ice](#step-10)

## 01 The car you built

Lecture deck: [the car](../../lecture-01/index.html#/the-car){target="_self"}

### 1a · Step test on your car {#step-1a}

Hold your `Car` at a steady 90 km/h, step the torque to the value that holds 110 km/h, and read the response.

#### Parts

New component `CarStepTest` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `cmd` | BlockComponents › Sources › Step | `offset = 31.078`, `height = 9.041`, `start_time = 50` |
| `plant` | your `Car` | — |

`31.078` N·m holds 90 km/h and `40.119` N·m holds 110 km/h — the cruise torques from the force balance on paper. The step height is their difference.

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `CarStepTest`. Place `cmd` and `plant` from the table and wire `cmd.y → plant.tau_cmd`.
2. Toggle to code (⇄) and add the starting state at the end of `relations`. The car starts in equilibrium at 25 m/s (90 km/h) with the engine lag already at the holding torque; without that the run would spend hundreds of seconds settling before the step.

   ::: code-group

   ```txt [Initial state]
     initial plant.body.mass.s = 0
     initial plant.body.mass.v = 25
     initial plant.engine.lag.x = 31.078
   ```

   :::

3. <Badge type="tip" text="New analysis" /> With `CarStepTest` open, press ▷ (**Run Analysis**), choose **TransientAnalysis**, name it `CarStepTestTransient` and set `stop` to `500` s. Run it and plot `plant.v_kmh`.

[![CarStepTest diagram: a torque step source driving the plant, your Car.](/lecture/lecture-01/img/step01-step-test.png)](/lecture/lecture-01/img/step01-step-test.png)

[![Plot of plant.v_kmh: flat at 90 km/h until the step at 50 s, then rising to 110 km/h.](/lecture/lecture-01/img/step01-step-test-plot.png)](/lecture/lecture-01/img/step01-step-test-plot.png)

::: tip Expected result

`plant.v_kmh` sits at **90 km/h** until 50 s, then rises to **110 km/h** by 500 s; `plant.engine.limiter.y` moves from 31.078 to 40.119 N·m. The vehicle's own time constant is about 60 s. Read K, τ and θ off this curve as the lecture deck does.

Reference: `HandsOn.Car`, `Lecture1.CarStepTest`.

:::

### 1b · `GradeCar`: the car on a hill {#step-1b}

A copy of your `Car` whose body is the `GradeBody` of hands-on [step 07](../../handson/lecture-01/#grade), with a `grade` input. The loop runs on this car from section 02 to section 09.

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `grade` | Dyad › RealInput | port, left edge under `tau_cmd` — tan α |
| `body` | your `GradeBody` | replaces `Body` |

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `Car` → **Duplicate** and name the copy `GradeCar`.
2. Delete `body`. Place your `GradeBody` and rename it `body`. Rewire the two connections the old body had: `driveline.flange → body.flange` and `vsensor.flange → body.flange`.
3. Place a `RealInput`, rename it `grade`, put it on the left edge under `tau_cmd`, and wire `grade → body.grade`.
4. Bench: right-click `CarFullThrottle` → **Duplicate**, name it `GradeCarFullThrottle`. Replace `car` with a `GradeCar` named `car`, add `road` = BlockComponents › Sources › Constant with `k = 0`, and wire `road.y → car.grade`. Give it a TransientAnalysis `GradeCarFullThrottleTransient` with `stop = 300` s.

[![The finished GradeCar diagram: the grade input wired to body.grade, under tau_cmd.](/lecture/lecture-01/img/step01-gradecar.png)](/lecture/lecture-01/img/step01-gradecar.png)

::: tip Expected result

On a flat road (`road.k = 0`) full throttle from rest reads **246.388 km/h** at 300 s — the same as your `Car`. A flat `GradeBody` is a `Body`. Set `road.k = 0.1` for a 10 % climb and the terminal speed drops; the engine stays at its 150 N·m ceiling throughout.

Reference: `HandsOn.GradeCar`, bench `GradeCarFullThrottle`.

:::

## 02 Closing the loop

Lecture deck: [open vs closed loop](../../lecture-01/index.html#/open-vs-closed-loop){target="_self"}

### 2 · The loop and the controller shell {#step-2}

Draw the loop once — setpoint, controller, car, road — and start the controller with the one block every feedback controller has: the error.

#### Parts

New component `CruiseController`, the controller shell:

| Name | Library path | Set |
| --- | --- | --- |
| `u_s` | Dyad › RealInput | port, left edge — setpoint in km/h |
| `u_m` | Dyad › RealInput | port, bottom edge — measured speed in km/h |
| `y` | Dyad › RealOutput | port, right edge — torque command in N·m |
| `error` | BlockComponents › Math › Add | `k1 = 1`, `k2 = -1` |

New component `CruiseLoopStep`, the loop:

| Name | Library path | Set |
| --- | --- | --- |
| `demand` | BlockComponents › Sources › Step | `offset = 90`, `height = 20`, `start_time = 0` |
| `controller` | your `CruiseController` | — |
| `plant` | your `GradeCar` | — |
| `road` | BlockComponents › Sources › Constant | `k = 0` |

#### Do this

1. <Badge type="tip" text="New component" /> Add a component `CruiseController`. Place the three ports and `error`, and wire `u_s → error.u1`, `u_m → error.u2`. With `k1 = 1`, `k2 = -1` the block computes `u_s − u_m`: positive when the car is too slow.
2. <Badge type="tip" text="New component" /> Add a component `CruiseLoopStep`. Place the four parts and wire:
   - `demand.y → controller.u_s`
   - `plant.v_kmh → controller.u_m`
   - `controller.y → plant.tau_cmd`
   - `road.y → plant.grade`
3. Toggle to code (⇄) and add the starting state — a settled 90 km/h cruise with the engine lag at the holding torque:

   ::: code-group

   ```txt [Initial state]
     initial plant.body.mass.s = 0
     initial plant.body.mass.v = 25
     initial plant.engine.lag.x = 31.078
   ```

   :::

4. <Badge type="tip" text="New analysis" /> Create a TransientAnalysis of `CruiseLoopStep`, name it `CruiseLoopTransient` and set `stop` to `100` s. Do not run it yet: `controller.y` has nothing driving it until step 3.

The setpoint steps from 90 to 110 km/h at the very start of the run. Delaying the step would give a P-only controller an interval at zero error, in which it commands zero torque.

[![The whole loop: demand step, controller, plant (GradeCar) and road. This diagram does not change again.](/lecture/lecture-01/img/step02-loop.png)](/lecture/lecture-01/img/step02-loop.png)

[![The CruiseController shell: ports u_s, u_m and y, and the error block with k1 = 1 and k2 = -1 in its parameter panel.](/lecture/lecture-01/img/step02-controller-shell.png)](/lecture/lecture-01/img/step02-controller-shell.png)

::: tip Expected result

Both components show no problems except the unconnected `y` in `CruiseController`. Nothing to plot yet.

:::

## 03 Proportional

Lecture deck: [proportional](../../lecture-01/index.html#/proportional){target="_self"}

### 3 · Proportional: one gain {#step-3}

Command torque in proportion to the error.

#### Parts

In `CruiseController`:

| Name | Library path | Set |
| --- | --- | --- |
| `k` | parameter `Real` | `56` — controller gain in N·m per km/h |
| `gain` | BlockComponents › Math › Gain | `k = k` |

#### Do this

1. Click an empty spot of the `CruiseController` canvas and **Add parameter** `k`, type `Real`, value `56`.
2. Place `gain` with `k = k`. Wire `error.y → gain.u` and `gain.y → y`.
3. Run `CruiseLoopTransient` and plot `plant.v_kmh` with `demand.y`.

[![CruiseController with error, gain and the output y in a row.](/lecture/lecture-01/img/step03-gain.png)](/lecture/lecture-01/img/step03-gain.png)

[![Plot of the speed settling at about 109.3 km/h against the setpoint at 110: the steady-state error.](/lecture/lecture-01/img/step03-p-plot.png)](/lecture/lecture-01/img/step03-p-plot.png)

::: tip Expected result — checkpoint P

`plant.v_kmh` rises from 90 and settles at about **109.3 km/h** against the 110 km/h setpoint. The 0.7 km/h that remain are the steady-state error: a P controller only pushes while there is an error, so some error has to stay to hold the extra torque that 110 km/h needs.

:::

:::: warning Fell behind?

Catch-up: paste into a new component. Add a component `CruiseController` in `MyCar`, toggle to code (⇄) and paste the first block over its contents; then the same for `CruiseLoopStep` with the second. If you already have components with these names, paste over their contents instead. `CruiseLoopStep` uses your `GradeCar` from step 1b. Then create the TransientAnalysis `CruiseLoopTransient` of step 2 if you do not have it.

::: code-group

```txt [CruiseController]
component CruiseController
  "Setpoint in km/h"
  u_s = RealInput()
  "Measured speed in km/h"
  u_m = RealInput()
  "Torque command in N·m"
  y = RealOutput()
  error = BlockComponents.Math.Add(k1 = 1, k2 = -1)
  gain = BlockComponents.Math.Gain(k = k)
  "Controller gain in N·m per km/h"
  parameter k::Real = 56
relations
  connect(u_s, error.u1)
  connect(u_m, error.u2)
  connect(error.y, gain.u)
  connect(gain.y, y)
end
```

```txt [CruiseLoopStep]
component CruiseLoopStep
  demand = BlockComponents.Sources.Step(offset = 90, height = 20, start_time = 0)
  controller = CruiseController()
  plant = GradeCar()
  road = BlockComponents.Sources.Constant(k = 0)
relations
  connect(demand.y, controller.u_s)
  connect(plant.v_kmh, controller.u_m)
  connect(controller.y, plant.tau_cmd)
  connect(road.y, plant.grade)
  initial plant.body.mass.s = 0
  initial plant.body.mass.v = 25
  initial plant.engine.lag.x = 31.078
end
```

:::

Or open the reference `CruiseLoop` with `with_I = false, with_D = false` — the default of `CruiseLoopTransient` — which settles at the same 109.3.

::::

## 04 Proportional-integral

Lecture deck: [proportional-integral](../../lecture-01/index.html#/proportional-integral){target="_self"}

### 4 · Integral: an integrator and a placeholder {#step-4}

Add the error's history to the command, through a three-input sum that keeps a slot free for the derivative.

#### Parts

In `CruiseController`:

| Name | Library path | Set |
| --- | --- | --- |
| `Ti` | parameter `Time` | `10` — integral time |
| `xi0` | parameter `Real` | `0` — initial integrator state |
| `add_pid` | BlockComponents › Math › Add3 | `k1 = 1`, `k2 = 1`, `k3 = 1` |
| `integrator` | BlockComponents › Continuous › Integrator | `k = 1/Ti`, `x0 = xi0` |
| `zero_d` | BlockComponents › Sources › Constant | `k = 0` — holds the derivative slot |

#### Do this

1. Add the parameters `Ti` and `xi0`.
2. Delete the wire `error.y → gain.u`. Place `add_pid` between `error` and `gain`, and wire `error.y → add_pid.u1`, `add_pid.y → gain.u`.
3. Place `integrator` and wire `error.y → integrator.u`, `integrator.y → add_pid.u3`.
4. Place `zero_d` next to `add_pid.u2` and wire `zero_d.y → add_pid.u2`. It is a placeholder: step 5 replaces it with the derivative branch.
5. Run `CruiseLoopTransient` and plot `plant.v_kmh`, with `controller.integrator.y` on a second axis.

[![CruiseController with add_pid between error and gain, the integrator on u3 and the zero_d constant on u2.](/lecture/lecture-01/img/step04-integrator.png)](/lecture/lecture-01/img/step04-integrator.png)

[![Plot of the speed reaching 110 km/h, with the integrator output on a second axis.](/lecture/lecture-01/img/step04-pi-plot.png)](/lecture/lecture-01/img/step04-pi-plot.png)

::: tip Expected result

`plant.v_kmh` now reaches **110 km/h**, passes it briefly — the PI overshoot that step 5 removes — and settles on it: the steady-state error of step 3 is gone. `controller.integrator.y` climbs while there is an error and levels off once the speed arrives — it has found the extra torque by itself.

:::

## 05 PID

Lecture deck: [PID](../../lecture-01/index.html#/pid){target="_self"}

### 5 · Derivative: the filtered derivative branch {#step-5}

Replace the placeholder with a filtered derivative of the (weighted) error.

#### Parts

In `CruiseController`:

| Name | Library path | Set |
| --- | --- | --- |
| `Td` | parameter `Time` | `0.5` — derivative time |
| `Nd` | parameter `Real` | `10` — derivative filter: the filter time constant is `Td/Nd` |
| `wd` | parameter `Real` | `0` — setpoint weight in the derivative |
| `xd0` | parameter `Real` | `-90` — initial derivative-filter state |
| `add_d` | BlockComponents › Math › Add | `k1 = wd`, `k2 = -1` |
| `derivative` | BlockComponents › Continuous › Derivative | `k = Td`, `T = Td/Nd`, `x0 = xd0` |

#### Do this

1. Add the four parameters. `k = 56`, `Ti = 10` stay as they are.
2. Delete `zero_d`.
3. Place `add_d` below the integrator and wire `u_s → add_d.u1`, `u_m → add_d.u2`.
4. Place `derivative` and wire `add_d.y → derivative.u`, `derivative.y → add_pid.u2`.
5. Run `CruiseLoopTransient` and plot `plant.v_kmh` and `controller.y`.

`add_d` is a second error block with its own setpoint weight `wd`. At `wd = 1` it would be the error itself; at `wd = 0` the derivative sees only the measured speed, so a setpoint step does not kick it. Step 7 shows what `wd = 1` would do.

`xd0 = -90` seeds the derivative filter at `(wd − 1) · 90`, the value it would hold at a steady 90 km/h cruise. Left at 0, the filter sees a 90 km/h step at t = 0 and commands a spike of −50400 N·m.

[![CruiseController with add_d feeding derivative into add_pid.u2; the derivative's parameter panel shows k = Td and T = Td/Nd.](/lecture/lecture-01/img/step05-derivative.png)](/lecture/lecture-01/img/step05-derivative.png)

[![Plot of the speed and the controller output for the full PID loop.](/lecture/lecture-01/img/step05-pid-plot.png)](/lecture/lecture-01/img/step05-pid-plot.png)

::: tip Expected result — checkpoint PID

`plant.v_kmh` reaches **110 km/h**, as in step 4, without step 4's overshoot. The jump in `controller.y` at the setpoint step is the proportional term, as before; no derivative spike rides on it. The plot matches the PID curve in the lecture deck.

:::

:::: warning Fell behind?

Catch-up: paste into a new component. Add a component `CruiseController` in `MyCar`, toggle to code (⇄) and paste the first block over its contents; then the same for `CruiseLoopStep` with the second. If you already have components with these names, paste over their contents instead. `CruiseLoopStep` uses your `GradeCar` from step 1b. Then create the TransientAnalysis `CruiseLoopTransient` of step 2 if you do not have it.

::: code-group

```txt [CruiseController]
component CruiseController
  "Setpoint in km/h"
  u_s = RealInput()
  "Measured speed in km/h"
  u_m = RealInput()
  "Torque command in N·m"
  y = RealOutput()
  error = BlockComponents.Math.Add(k1 = 1, k2 = -1)
  add_d = BlockComponents.Math.Add(k1 = wd, k2 = -1)
  derivative = BlockComponents.Continuous.Derivative(k = Td, T = Td / Nd, x0 = xd0)
  integrator = BlockComponents.Continuous.Integrator(k = 1 / Ti, x0 = xi0)
  add_pid = BlockComponents.Math.Add3(k1 = 1, k2 = 1, k3 = 1)
  gain = BlockComponents.Math.Gain(k = k)
  "Controller gain in N·m per km/h"
  parameter k::Real = 56
  "Integral time"
  parameter Ti::Time = 10
  "Initial integrator state"
  parameter xi0::Real = 0
  "Derivative time"
  parameter Td::Time = 0.5
  "Derivative filter: the filter time constant is Td / Nd"
  parameter Nd::Real = 10
  "Setpoint weight in the derivative"
  parameter wd::Real = 0
  "Initial derivative-filter state, (wd - 1) * 90"
  parameter xd0::Real = -90
relations
  connect(u_s, error.u1)
  connect(u_m, error.u2)
  connect(error.y, add_pid.u1)
  connect(error.y, integrator.u)
  connect(integrator.y, add_pid.u3)
  connect(u_s, add_d.u1)
  connect(u_m, add_d.u2)
  connect(add_d.y, derivative.u)
  connect(derivative.y, add_pid.u2)
  connect(add_pid.y, gain.u)
  connect(gain.y, y)
end
```

```txt [CruiseLoopStep]
component CruiseLoopStep
  demand = BlockComponents.Sources.Step(offset = 90, height = 20, start_time = 0)
  controller = CruiseController()
  plant = GradeCar()
  road = BlockComponents.Sources.Constant(k = 0)
relations
  connect(demand.y, controller.u_s)
  connect(plant.v_kmh, controller.u_m)
  connect(controller.y, plant.tau_cmd)
  connect(road.y, plant.grade)
  initial plant.body.mass.s = 0
  initial plant.body.mass.v = 25
  initial plant.engine.lag.x = 31.078
end
```

:::

Or open the reference `CruiseLoop` with `with_I = true, with_D = true`, `Td = 0.5` and `wd = 0`; its `xd0` follows `wd` by itself.

::::

## 06 Integral windup

Lecture deck: [integral windup](../../lecture-01/index.html#/windup){target="_self"}

### 6a · `T_max` on `GradeCar` {#step-6a}

Make the engine's torque ceiling a parameter of the car, so a bench can change it.

#### Do this

1. Open `GradeCar`, click an empty spot of the canvas and **Add parameter** `T_max`, type `Torque`, value `150`.
2. Click `engine` and set its `T_max` to `T_max`.

[![GradeCar's parameter panel with T_max, and engine selected so its T_max = T_max binding shows.](/lecture/lecture-01/img/step06-tmax.png)](/lecture/lecture-01/img/step06-tmax.png)

::: tip Expected result

Nothing changes in any run: the default is the 150 N·m the engine already had. `GradeCar(T_max = 120)` would now lower the ceiling from the bench.

:::

### 6b · The limiter {#step-6b}

Limit the controller's own output to what the engine can deliver.

#### Parts

In `CruiseController`:

| Name | Library path | Set |
| --- | --- | --- |
| `y_max` | parameter `Real` | `1e300` — output ceiling; no limit unless one is set |
| `y_min` | parameter `Real` | `-y_max` — output floor |
| `limiter` | BlockComponents › Nonlinear › Limiter | `y_max = y_max`, `y_min = y_min` |

In `CruiseLoopStep`:

| Name | Set |
| --- | --- |
| `controller` | `y_max = 150` — the engine's `T_max`; `y_min = 0` — the engine cannot brake |

The defaults are the reference's: a `CruiseController` with no limits set behaves as before. The limits belong to the loop, which knows which engine it drives.

#### Do this

1. Add the parameters `y_max` and `y_min`.
2. Delete the wire `gain.y → y`. Place `limiter` and wire `gain.y → limiter.u`, `limiter.y → y`.
3. Open `CruiseLoopStep`, click `controller` and set `y_max = 150`, `y_min = 0`.
4. Run `CruiseLoopTransient` again and plot `controller.y` with `controller.gain.y`.

[![CruiseController ending in gain, limiter and the output y.](/lecture/lecture-01/img/step06-limiter.png)](/lecture/lecture-01/img/step06-limiter.png)

::: tip Expected result

The 90 → 110 km/h step asks for more than 150 N·m at the start, so `controller.y` sits flat on 150 for the first moments instead of rising above it; it stays between 0 and 150 N·m throughout, and the speed still reaches 110 km/h. The command the controller *wants* is `controller.gain.y`, the one it sends is `controller.y`: the gap between them is the saturation.

:::

### 6c · The climb: watch the integrator wind up {#step-6c}

Cruise at 130 km/h into a 10 % climb the engine cannot hold, and watch what the integrator does while the engine is saturated.

#### Parts

New component `CruiseClimb`, a duplicate of `CruiseLoopStep` with:

| Name | Library path | Set |
| --- | --- | --- |
| `demand` | BlockComponents › Sources › Constant | `k = 130` — replaces the step |
| `road` | BlockComponents › Sources › Pulse | `amplitude = 0.10`, `offset = 0`, `start_time = 30`, `duty_cycle = 1.0`, `period = 120` — replaces the constant |
| `controller` | your `CruiseController` | `xd0 = -130` — the derivative-filter seed for a 130 km/h cruise; `y_max = 150`, `y_min = 0` come along from step 6b |

Your library cannot see the course library's `GradeProfile`; the pulse is what the reference uses inside it. `xd0` is `(wd − 1) · 130` for this cruise: left at the step-5 value −90, the run opens with a derivative spike.

#### Do this

1. Right-click `CruiseLoopStep` → **Duplicate** and name it `CruiseClimb`.
2. Replace `demand` with a `Constant(k = 130)` named `demand`, and `road` with the pulse above named `road`. Rewire `demand.y → controller.u_s` and `road.y → plant.grade`. Click `controller` and set `xd0 = -130`.
3. In code (⇄), change the starting state to a settled 130 km/h cruise:

   ::: code-group

   ```txt [Initial state]
     initial plant.body.mass.s = 0
     initial plant.body.mass.v = 36.111111111111114
     initial plant.engine.lag.x = 50.9693
   ```

   :::

4. Create a TransientAnalysis `CruiseClimbTransient` with `stop = 400` s. Run it and plot `plant.v_kmh`, `controller.y` and `controller.integrator.y`.

[![The climb harness: the road pulse driving the plant's grade input.](/lecture/lecture-01/img/step06-climb.png)](/lecture/lecture-01/img/step06-climb.png)

[![Speed, controller output and integrator through the climb and after it: the overshoot after the crest.](/lecture/lecture-01/img/step06-windup-plot.png)](/lecture/lecture-01/img/step06-windup-plot.png)

::: tip Expected result

The climb starts at 30 s and needs more tractive force than the engine can supply: `controller.y` sits at 150 N·m and the car heads for about **118 km/h**; the climb ends before it gets there, at **119.10 km/h** and still falling. All that time the error is positive, so `controller.integrator.y` keeps climbing. At 150 s the road flattens, and the wound-up integrator still commands acceleration: the speed overshoots 130 km/h, by more the longer the hill lasted.

Compare with the course model `CruiseClimb`, which closes the loop with the library's `LimPID` and its back-calculation anti-windup; it is back at **130 km/h** at 400 s.

:::

### 6d · Clamping: freeze the integrator {#step-6d}

Stop the integrator while it would only push the command deeper into a limit.

#### Do this

1. Open `CruiseController` and toggle to code (⇄).
2. Delete the line `connect(error.y, integrator.u)`.
3. Add a variable for the error above `relations`, and the clamping equation inside it:

   ::: code-group

   ```txt [Clamping]
     variable control_error::Real
   relations
     control_error = error.y
     integrator.u = ifelse(limiter.y >= y_max,
                      ifelse(control_error >= 0, 0.0, control_error),
                      ifelse(limiter.y <= y_min,
                        ifelse(control_error <= 0, 0.0, control_error),
                        control_error))
   ```

   :::

4. Save, run `CruiseClimbTransient` again and plot the same three signals on the same axes as in step 6c.

The integrator freezes only when both hold: the output is at a limit, **and** the error has the sign that would drive it further into that limit. Freezing on saturation alone would trap the integrator when the hill ends and the loop needs it to come back down; with the sign condition it unwinds the moment the error reverses. The nested `ifelse` avoids boolean operators.

[![The integrator.u = ifelse(...) equation in CruiseController's code view.](/lecture/lecture-01/img/step06-clamping-code.png)](/lecture/lecture-01/img/step06-clamping-code.png)

[![Speed, controller output and integrator on the same axes as the windup plot, with clamping.](/lecture/lecture-01/img/step06-clamping-plot.png)](/lecture/lecture-01/img/step06-clamping-plot.png)

::: tip Expected result

On the climb `controller.integrator.y` stops rising as soon as the engine saturates, and after the crest the overshoot is far smaller than in step 6c. The speed is back at **130 km/h** at 400 s.

Reference: `ClampingCruiseClimb` (analysis `ClampingCruiseClimbTransient`).

:::

## 07 Derivative and noise

Lecture deck: [derivative and noise](../../lecture-01/index.html#/derivative-and-noise){target="_self"}

### 7 · A noisy speedometer {#step-7}

Put a little noise on the measured speed and see what the derivative does with it; then take the setpoint out of the derivative, and change its filter.

#### Parts

New component `MeasurementNoise`: paste the code below. It adds a fixed sum of six sines, 0.2 km/h each, from 0.5 to 16 Hz — deterministic, so every run gives the same plot.

::: code-group

```txt [MeasurementNoise]
component MeasurementNoise
  extends BlockComponents.Interfaces.SISO
  "Amplitude of each sinusoid"
  parameter amplitude::Real = 0.2
  "Component frequencies in Hz"
  parameter f1::Frequency = 0.5
  parameter f2::Frequency = 1.0
  parameter f3::Frequency = 2.0
  parameter f4::Frequency = 4.0
  parameter f5::Frequency = 8.0
  parameter f6::Frequency = 16.0
  # Fixed, non-zero phase offsets so the components do not all peak at t = 0.
  parameter p1::Real = 0.0
  parameter p2::Real = 0.7
  parameter p3::Real = 1.5
  parameter p4::Real = 2.2
  parameter p5::Real = 3.0
  parameter p6::Real = 3.9
relations
  y = u + amplitude * (
    sin(2 * pi * f1 * time + p1) +
    sin(2 * pi * f2 * time + p2) +
    sin(2 * pi * f3 * time + p3) +
    sin(2 * pi * f4 * time + p4) +
    sin(2 * pi * f5 * time + p5) +
    sin(2 * pi * f6 * time + p6))
end
```

:::

New component `NoisyCruiseStep`, a duplicate of `CruiseLoopStep` with:

| Name | Library path | Set |
| --- | --- | --- |
| `noise` | your `MeasurementNoise` | `amplitude = 0.2` |
| `controller` | your `CruiseController` | `y_max = 1e6`, `y_min = -1e6` — limits lifted |
| `plant` | your `GradeCar` | `T_max = 1e6` — limit lifted |

Every limit is lifted, as in the lecture notebook, so the limiter does not clip the chatter and hide it. The limits are lifted on this duplicate only: `CruiseLoopStep` keeps its step 6b limits, 150 and 0.

#### Do this

1. <Badge type="tip" text="New component" /> Add a component `MeasurementNoise`, toggle to code (⇄) and paste the block above over its contents.
2. Right-click `CruiseLoopStep` → **Duplicate** and name it `NoisyCruiseStep`.
3. Delete the wire `plant.v_kmh → controller.u_m`. Place `noise` and wire `plant.v_kmh → noise.u`, `noise.y → controller.u_m`.
4. Click `controller` and set `y_max = 1e6`, `y_min = -1e6`; click `plant` and set `T_max = 1e6`.
5. Click `controller` and set `wd = 1` and `xd0 = 0` — the seed `(wd − 1) · 90` that goes with `wd = 1`. Create a TransientAnalysis `NoisyCruiseTransient` with `stop = 40` s. Run it and plot `controller.y`, then `plant.v_kmh` with `noise.y`.
6. Set `wd = 0` and `xd0 = -90` back — the step-5 values. Run again, same axes.
7. Keep `wd = 0` and change `Nd`: run at `Nd = 100` — the filter almost gone — then at 20, 5 and 2, with `controller.y` on the same axes. `Nd` is an ordinary parameter, so each run is a re-solve, not a recompile.

[![NoisyCruiseStep: the noise block inserted between plant.v_kmh and controller.u_m.](/lecture/lecture-01/img/step07-noise-loop.png)](/lecture/lecture-01/img/step07-noise-loop.png)

[![controller.y chattering with wd = 1.](/lecture/lecture-01/img/step07-noisy-plot.png)](/lecture/lecture-01/img/step07-noisy-plot.png)

[![The same plot on the same axes with wd = 0: the setpoint kick is gone.](/lecture/lecture-01/img/step07-wd0-plot.png)](/lecture/lecture-01/img/step07-wd0-plot.png)

::: tip Expected result

At `wd = 1` the car still makes the step — `plant.v_kmh` climbs from 90 towards 110 km/h, and the noisy `noise.y` wiggles a few tenths of a km/h around it — but `controller.y` chatters: noise of a few tenths of a km/h, differentiated, is a steep slope. At `wd = 0` the kick at the setpoint step disappears; the chatter stays, because it comes from the measurement. A larger `Nd` filters less and the chatter grows: in the 20–30 s window the swing of `controller.y` falls from about **1751 N·m** at `Nd = 100` to **316 N·m** at `Nd = 2` — still twice what the engine can deliver.

Reference: `NoisyCruiseLoop`, bench `NoisyCruiseStep`. To reproduce this step, run `NoisyCruiseTransient` with `Td = 0.5`, `wd` per run (1, then 0; its `xd0` follows `wd` by itself), `T_max = 1e6`, `y_max = 1e6`, `y_min = -1e6` and `stop = 40`.

:::

## 08 Tuning

Lecture deck: [tuning](../../lecture-01/index.html#/tuning){target="_self"}

### 8 · Mass and delay as parameters {#step-8}

Expose the two plant values the robustness sweep changes, then try the Ziegler-Nichols gains on a heavier car and a slower engine — on a duplicate of the loop, so `CruiseLoopStep` stays as it is for step 10.

#### Parts

In `GradeCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `m` | parameter `Dyad.Mass` | `1400` — vehicle mass; `body`: `m = m` |
| `theta_e` | structural parameter `Time` | `0.3` — injection-to-torque delay; `engine`: `theta_e = theta_e` |

New component `TuningCruiseStep`, a duplicate of `CruiseLoopStep` with:

| Name | Library path | Set |
| --- | --- | --- |
| `controller` | your `CruiseController` | `k = 67.41`, `Ti = 1.092`, `Td = 0.273` — the Ziegler-Nichols gains; `y_max = 1e6`, `y_min = -1e6` — limits lifted; `Nd = 10`, `wd = 0`, `xd0 = -90` stay |
| `plant` | your `GradeCar` | `T_max = 1e6` — limit lifted |

#### Do this

1. Open `GradeCar` and **Add parameter**:
   - `m`, type `Dyad.Mass`, value `1400`. Click `body` and set `m = m`. Your `GradeBody` passes `m` on to its grade force, so one binding reaches rolling resistance, the slope force and the inertia.
   - `theta_e`, type `Time`, value `0.3`, **structural**. Click `engine` and set `theta_e = theta_e`. It is structural because the engine's Padé delay builds its coefficients from it when the model is compiled; if **Add parameter** offers no structural option, toggle to code and write `structural parameter theta_e::Time = 0.3`.
2. Right-click `CruiseLoopStep` → **Duplicate** and name it `TuningCruiseStep`. Click `controller` and set the gains and limits from the table; click `plant` and set `T_max = 1e6`.
3. <Badge type="tip" text="New analysis" /> Create a TransientAnalysis of `TuningCruiseStep`, name it `TuningCruiseTransient` and set `stop` to `60` s. Run it and plot `plant.v_kmh`: the baseline.
4. Click `plant`, set `m = 1600` — a 200 kg payload — and run again.
5. Set `m = 1400` back and `theta_e = 0.6`, twice the delay. Run again; this one recompiles, because `theta_e` is structural.
6. Put `theta_e = 0.3` back.

[![GradeCar's parameter panel with m and theta_e exposed.](/lecture/lecture-01/img/step08-params.png)](/lecture/lecture-01/img/step08-params.png)

::: tip Expected result

With the `GradeCar` defaults nothing changes in any earlier run. On `TuningCruiseStep`, the 200 kg payload barely moves the response: feedback absorbs it. The doubled delay rings much harder: the Ziegler-Nichols gains came from a measurement at 0.3 s, and the margin they left is gone.

The reference `HandsOn.GradeCar` carries `theta_e`, `T_max`, `m` and also the drag area `CdA`.

:::

## 09 Discretization

Lecture deck: [discretization](../../lecture-01/index.html#/discretization){target="_self"}

### 9 · Discretization (demo) {#step-9}

Demo only: watch, nothing to build. The lecturer runs `SampledCruiseLoop`, the same loop around `GradeCar` with the controller replaced by the library's `DiscreteComponents.DiscretePIDStandard`: a periodic clock, a sampler on the setpoint and one on the measured speed, the discrete PID, and a zero-order hold in front of the car.

The controller runs the Ziegler-Nichols PID gains of step 8 — `k = 67.41`, `Ti = 1.092`, `Td = 0.273`, `wd = 0` — with every limit lifted, on the 90 → 110 km/h step. Only the sample time `Ts` changes: 0.01, 0.1, 0.4 and 1 s. As `Ts` grows, the response overshoots more, then rings, then does not come back. Two fixes follow: sample faster (`Ts = 0.05` s, gains untouched), or re-tune for the slow rate (`k = 20`, `Ti = 3`, `Td = 0.5` at `Ts = 1` s), which is stable but slower. `Ts` is structural, so each sample time is a recompile.

[![SampledCruiseLoop: clock, the two samplers, DiscretePIDStandard, the zero-order hold and the plant.](/lecture/lecture-01/img/step09-sampler.png)](/lecture/lecture-01/img/step09-sampler.png)

## 10 Wheel and slip

Lecture deck: [wheel and slip](../../lecture-01/index.html#/wheel-and-slip){target="_self"}

### 10 · Cruise control on ice {#step-10}

Put your controller on the `SlipCar` of hands-on [step 10](../../handson/lecture-01/#standing-start) and drive it across eight seconds of ice.

#### Parts

New component `SlipCruiseIcePatch`, a duplicate of `CruiseLoopStep` as it stands after step 6 — steps 7 and 8 worked on duplicates, so it still has `k = 56`, `Ti = 10`, `Td = 0.5`, `Nd = 10`, `wd = 0`, `xd0 = -90` and the limits 150 and 0 — with:

| Name | Library path | Set |
| --- | --- | --- |
| `demand` | BlockComponents › Sources › Constant | `k = 90` — replaces the step |
| `controller` | your `CruiseController` | `xi0 = 31.078 / 56` — the integrator starts at the holding torque; everything else stays |
| `plant` | your `SlipCar` | replaces `GradeCar` |
| `friction` | BlockComponents › Sources › Pulse | `amplitude = 0.05`, `offset = 1.0`, `start_time = 4`, `duty_cycle = 1.0`, `period = 8` |

The pulse outputs `amplitude` on the patch and `offset` outside it, so the grip drops from 1.0 to 0.05 for 8 s, from 4 s to 12 s. Your library cannot see the course library's `FrictionProfile`; the pulse is what the reference uses inside it, with `low = 0.05`.

#### Do this

1. Right-click `CruiseLoopStep` → **Duplicate** and name it `SlipCruiseIcePatch`.
2. Delete `plant` and `demand`. Place your `SlipCar` named `plant` and the `Constant(k = 90)` named `demand`. Rewire `demand.y → controller.u_s`, `plant.v_kmh → controller.u_m`, `controller.y → plant.tau_cmd`, `road.y → plant.grade`.
3. Place `friction` and wire `friction.y → plant.mu_scale`. Set `xi0` on `controller`.
4. In code (⇄), replace the starting state. `SlipCar` has a wheel with its own inertia, so the wheel's angle and speed start too, rolling without slip at 90 km/h:

   ::: code-group

   ```txt [Initial state]
     initial plant.body.mass.s = 0
     initial plant.body.mass.v = 25
     initial plant.engine.lag.x = 31.078
     initial plant.wheel_inertia.phi = 0
     initial plant.wheel_inertia.w = 25 / plant.r
   ```

   :::

5. Create a TransientAnalysis `SlipCruiseTransient` with `stop = 45` s. Run it and plot `plant.v_kmh` against `plant.wheel_kmh`.

[![The loop with plant as SlipCar and the friction profile on mu_scale.](/lecture/lecture-01/img/step10-slip-loop.png)](/lecture/lecture-01/img/step10-slip-loop.png)

[![plant.v_kmh against plant.wheel_kmh across the ice patch: wheelspin is the gap between them.](/lecture/lecture-01/img/step10-ice-patch-plot.png)](/lecture/lecture-01/img/step10-ice-patch-plot.png)

::: tip Expected result

Before 4 s `plant.v_kmh` and `plant.wheel_kmh` lie on top of each other at **90 km/h**. Across the patch the two speeds come apart: `plant.wheel_kmh` tears away far above the car's speed — the gap is the wheel spinning — while `plant.v_kmh` sags by only about **3 km/h** and the slip ratio `plant.wheel.kappa` runs far past the 0.04 adhesion peak, to about **38**. The tread reaches about **3400 km/h**. The controller only sees the car's speed, so it answers the lost grip with more torque. When the grip returns at 12 s the car surges to about **112 km/h** before settling back.

Reference: `SlipCruiseLoop`, bench `SlipCruiseIcePatch`. To reproduce this step, run `SlipCruiseTransient` with `Td = 0.5`, `wd = 0`, `patch_start = 4`, `patch_duration = 8` and `stop = 45`.

:::

---

Reference models: `dyad/HandsOn/` and `dyad/Lecture1/` in the course repository. Build plan: `docs/lecture-01-live-build-plan.md`.
