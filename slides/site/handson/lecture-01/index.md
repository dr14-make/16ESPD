---
title: Lecture 1 hands-on — build the car
---

[← Vehicle Systems & Components](../../index.html) · [Tutor deck →](../../handson-01/index.html){target="_self"}

# Lecture 1 hands-on: build the car

From a first look at Dyad Studio to a car spinning its wheel on a slippery road

**Why we build it.** A cruise control has to know how the car reacts before it can drive it: how late the engine answers, how hard the air pushes back, when the wheels spin. So before the next lecture designs a controller, you build the car. **What you build:** a pedal command into an engine, through a gear and wheel, pushing a car body, read by a speedometer — then a tire that can slip. By the end your car reaches 246 km/h flat out on a dry road, and barely 10 km/h on snow with its wheel spinning.

**How each step works.** It starts with the physics it needs — your tutor explains it from the [tutor deck](../../handson-01/index.html){target="_self"}, and the *Theory* link under each step's goal opens those slides. Then you build, and the checkpoint is a number you predicted first. **After this session:** [Lecture 1](../../lecture-01/index.html){target="_self"} puts this car under P, PI and PID control.

**Part 1** introduces Dyad Studio: what the extension adds to VS Code, where its controls are, and how a diagram and its code are one model. **Part 2** builds the car out of standard-library parts, one component per step, mostly in the diagram editor. At the end of step 5 your car reaches the same terminal speed as the course model `Vehicle.CarPlant`; step 6 gives its wheel inertia; steps 7–10 add equations of your own and end with the car spinning its wheel on a slippery road.

Every component here exists in the course repository under `dyad/HandsOn/`, and every number in a checkpoint was read off a run of it. The budgets, theory included, add up to about 225 minutes: 48 for Part 1, 171 for Part 2 and 5 to hand in — plan a break after step 05.

**Part 1 — Dyad Studio and the extension**

- [What you are looking at](#ui) — 15 min
- [Create your library](#library) — 15 min
- [Put your library on GitHub](#github) — 5 min

1. [Tour: one model, two views](#tour) — 13 min

**Part 2 — Build the car**

2. [Engine](#engine) — 27 min
3. [Driveline](#driveline) — 13 min
4. [Body](#body) — 21 min
5. [Car: full throttle to terminal speed](#car) — 27 min
6. [A wheel with inertia](#wheel-inertia) — 12 min
7. [A road with a gradient](#grade) — 13 min
8. [Tire friction against slip](#tire-curve) — 20 min
9. [A wheel that can slip](#slip-wheel) — 15 min
10. [Standing start on a slippery road](#standing-start) — 23 min

- [Hand in: open a pull request](#hand-in) — 5 min

## Part 1 — Dyad Studio and the extension

Why we build the car, what the tool is, where its controls are · 38 min

### What you are looking at <Badge type="info" text="15 min" /> {#ui}

Dyad Studio is a VS Code extension: you draw or write models in the Dyad language, and it compiles them to Julia and simulates them.

#### Three ideas

- **A library is a folder.** Your models live as `.dyad` files under `dyad/`. The extension compiles them into Julia under `generated/` — never edit that folder by hand; it is rewritten on every compile. The folder is also a Julia package, so `using MyCar` loads your models in a Julia REPL.
- **A component is a model; an analysis is an experiment on one.** A component says what the system is — parts, wires, equations. An analysis says what to do with it — for example simulate for 300 s. You can only simulate a component whose inputs are all driven, so every experiment gets a small test bench component around the thing you built.
- **Diagram and code are the same file.** Every block you place is a line of code, every wire a `connect`. Step 01 shows it.

#### Where things are

[![Dyad Studio with four numbered arrows: the Components panel and the Analyses panel in the Dyad sidebar, and the Run Analysis and Toggle Between Code and Diagram View buttons in the editor title bar.](/handson/lecture-01/img/dyad-studio-map.png){width="1720" height="1317"}](/handson/lecture-01/img/dyad-studio-map.png)

**1** **Components** panel in the Dyad sidebar: right-click your library → **Add Component**. **2** **Analyses** panel: right-click → **Add Analysis**; the ▷ beside an analysis runs it. **3** ▷ **Run Analysis**, in the editor title bar of an open analysis. **4** ⇄ **Toggle Between Code and Diagram View**. Bottom right, under **Julia Commands**: **Dyad Compile**, if saving does not compile. Ignore the plot in this picture: step 2 shows why it is unreadable and what to do instead.

[![The diagram toolbar's plus button opened: a search box above a tree of libraries — Dyad, RotationalComponents, BlockComponents, ElectricalComponents, ThermalComponents, TranslationalComponents, HydraulicComponents and the student's own library.](/handson/lecture-01/img/dyad-studio-add-component.png){style="max-width:520px" width="796" height="787"}](/handson/lecture-01/img/dyad-studio-add-component.png)

The **+** (**Add component**) button in the diagram toolbar: search for a part by name, or open a library and walk the path the parts table gives. `Dyad` holds the ports (`RealInput`, `Spline`, `Flange`); your own library is at the bottom. The sliders button next to it is **Edit Parameters**.

- The **Dyad** sidebar (the Dyad icon in the activity bar) holds four panels: **Actions**, **Components**, **Analyses** and **Notebooks**. The **Actions** title bar has **Dyad: Open Julia REPL**, which you need for plotting.
- Saving a `.dyad` file compiles it. If the **Analyses** panel does not pick up a change, click **Dyad Compile** under **Julia Commands**, beside the terminal.
- Results of a run appear in a **Julia Plots** pane.

### Create your library <Badge type="info" text="15 min" /> {#library}

An empty library of your own, with the three component libraries the car needs added and downloaded, so that step 01 can start placing parts.

#### Do this

1. In VS Code, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>. A text box opens at the top of the window: the command palette.

2. Type `Dyad: Create Component Library` and press <kbd>Enter</kbd> when it is highlighted.

3. When asked for a name, type `MyCar` and press <kbd>Enter</kbd>. When asked for a location, pick an *empty* folder. VS Code reopens in that folder.

4. Look at the terminal at the bottom of the window. The extension runs `Pkg.instantiate()` by itself; the first time it downloads and precompiles the standard libraries, which takes several minutes. Wait until it stops printing. If you can, do this step before the session.

5. In the **Activity Bar** — the column of icons on the far left — click the **Dyad** icon. The Dyad sidebar opens with four panels: **Actions**, **Components**, **Analyses**, **Notebooks** (arrows 1 and 2 in the map above).

6. In **Components**, click the arrow next to `MyCar` to expand it. It holds the example models the template ships with; leave them, they do no harm.

7. **Add the three standard libraries the car is built from.** A new library contains none of them. In the Dyad sidebar's **Actions** panel, click **Import Library**, pick `BlockComponents`, and when asked for the folder to install into, choose your `MyCar` folder. Repeat for `RotationalComponents` and `TranslationalComponents`. Each one is added to `Project.toml` and downloaded; wait for the terminal to finish.

8. **Add Plots**, which the plotting steps use. In the **Actions** panel's title bar, click **Dyad: Open Julia REPL**, then run:

   ```julia
   using Pkg; Pkg.add("Plots")
   ```

   The first download and precompile takes a few minutes; let it run while you go on.

::: tip Checkpoint

The terminal has finished without errors, `MyCar` appears in the **Components** panel, and `Project.toml` lists `BlockComponents`, `RotationalComponents`, `TranslationalComponents` and `Plots` under `[deps]`.

:::

Names in this guide are the ones the reference models use. Keep them: the checkpoints name signals such as `car.v_kmh`, and a different instance name means a different signal name.

### Put your library on GitHub <Badge type="info" text="5 min" /> {#github}

Your library in your own GitHub repository, and a branch `handson-01` that today's work goes on.

#### Do this

1. In the **Activity Bar**, click the **Source Control** icon (three dots joined by lines), or press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>.
2. Click **Publish to GitHub**. Sign in to GitHub if VS Code asks. Keep the name `MyCar`, choose a **public** or **private** repository, and keep the files VS Code offers ticked. VS Code makes the first commit, creates the repository and uploads it. This is your `main` branch: the empty library.
3. At the bottom left of the window, in the status bar, click the branch name `main` → **Create new branch…** → type `handson-01` → <kbd>Enter</kbd>. Everything you build today goes on this branch.

::: tip Checkpoint

Your repository opens on github.com with the library's files, and the status bar in VS Code shows `handson-01`.

:::

::: warning When to commit

After every checkpoint from step 01 on, save your progress: in **Source Control**, type the message given under the checkpoint (for example `Step 02: engine`), click **Commit**, then **Sync Changes** to upload it (the first time it says **Publish Branch**). If VS Code asks whether to stage all changes, answer **Yes**. One commit per step: if something breaks later, you can always go back to the last step that worked.

:::

### 01 Tour: one model, two views <Badge type="info" text="13 min" /> {#tour}

Place two blocks, wire them, set a parameter, and see that the diagram and the code are the same model.

Theory: [tutor slides — Two kinds of wire](../../handson-01/index.html#/two-kinds-of-wire){target="_self"}

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `delay` | BlockComponents › Nonlinear › PadeDelay | `n = 6`, `m = 5`, `delayTime = 0.3` |
| `lag` | BlockComponents › Continuous › FirstOrder | `T = 0.3` |

#### What you are building

[![Tour in Dyad Studio: delay and lag wired in the diagram with the delay parameter panel open, and the same component in the code view.](/handson/lecture-01/img/step01-engine-two-views.png){width="1419" height="828"}](/handson/lecture-01/img/step01-engine-two-views.png)

Same model, two views: each block in the diagram is one line under `component`, the wire is the one `connect` under `relations`, and the values in the parameter panel are the arguments in parentheses.

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Engine`. It opens as an empty diagram. Type the name and press <kbd>Enter</kbd>; a white canvas opens with a small toolbar in its top-left corner.
2. **Place the first part.** In that toolbar, click **+** (**Add component**, the fifth icon — see the second picture in *Where things are*). A search box opens above a list of libraries. Type `PadeDelay` and click the result, `BlockComponents › Nonlinear › PadeDelay`. A block with a sine-wave icon appears on the canvas.
3. **Name it.** Click the block once. A panel opens on the right of the canvas with the block's name at the top and a pencil ✎ beside it. Click the pencil, type `delay`, press <kbd>Enter</kbd>.
4. **Set its parameters.** In the same panel, under **Parameters**, click into the `n` field and type `6`; `m` → `5`; `delayTime` → `0.3`. Leave the rest. Close the panel with its ✕.
5. **Place the second part.** Click **+** again, search `FirstOrder`, click `BlockComponents › Continuous › FirstOrder`. Click the new block, rename it `lag` with the pencil, set `T` to `0.3`.
6. **Move the blocks** so `lag` sits to the right of `delay`: press on a block and drag it.
7. **Wire them.** Each block has a small port on its right edge (the output, `y`) and one on its left edge (the input, `u`). Press on `delay`'s right-hand port, hold, drag to `lag`'s left-hand port, release. A line joins them.
8. **Save** with <kbd>Ctrl</kbd>+<kbd>S</kbd>.
9. **Switch to code.** In the editor's title bar — the row with the file's tab, top right — click ⇄ (**Toggle Between Code and Diagram View**, arrow 4 in the map). Every block you placed is now a line `name = Library.Path(parameters)`, and the wire is a `connect(delay.y, lag.u)` line under `relations`.
10. **Round trip.** In the code, change `T = 0.3` to `T = 0.5`, save, click ⇄ again, click `lag`: its panel shows 0.5. Set it back to 0.3. One model, two views — whichever you edit, the other follows.

::: tip Checkpoint

The code view shows the two declarations and one `connect(delay.y, lag.u)`, matching the code half of the screenshot above. Keep this component open: step 2 finishes it.

:::

Commit: **Source Control** → message `Step 01: tour` → **Commit** → **Publish Branch** (from now on, **Sync Changes**).

::: details Stuck? The full model

From `dyad/HandsOn/Tour.dyad`, diagram annotations omitted. Yours is called `Engine`; the reference copy is `Tour` only so it can sit next to the finished `Engine` of step 2.

```
"""
Step 1 of the hands-on: two blocks and one wire, to show that the diagram and the code are the
same model. The delay's input is left open; step 2 finishes this into `Engine`.
"""
component Tour
  delay = BlockComponents.Nonlinear.PadeDelay(n = 6, m = 5, delayTime = 0.3)
  lag = BlockComponents.Continuous.FirstOrder(T = 0.3)
relations
  connect(delay.y, lag.u)
end
```

:::

## Part 2 — Build the car

Steps 2–10 · theory, then one component per step · 171 min

### 02 Engine <Badge type="info" text="27 min" /> {#engine}

Finish the engine — torque command in, shaft torque out through a delay, a lag and a 150 N·m ceiling — and watch it answer a step.

Theory: [tutor slides — what happens when you press the pedal, the lag, and the step-02 numbers](../../handson-01/index.html#/pedal){target="_self"}

#### Where you are, where you are going

Step 01 left you a component called `Engine` holding two blocks, `delay → lag`. This step turns it into the engine below by adding four things to that same component: three **parameters**, two more **parts** (a limiter and a torque source), and three **ports** so other components can plug into it. Then a small test bench drives it.

[![The finished Engine diagram: tau_cmd input on the left, then delay, lag, limiter and torque blocks in a row, the spline port on the right and the support port at the bottom; the Engine panel at top right lists the parameters theta_e, tau_e and T_max above an Add parameter button.](/handson/lecture-01/img/step02-engine-finished.png){style="max-width:560px" width="903" height="897"}](/handson/lecture-01/img/step02-engine-finished.png)

The finished `Engine`: `tau_cmd` → `delay` → `lag` → `limiter` → `torque` → `spline`, with `torque`'s support down to `support`. The two blocks you already have are the second and third. Top right is `Engine`'s own panel — click an empty spot of the canvas to open it — with the three parameters of stage B and the **Add parameter** button.

#### A · Open your Engine

1. In the **Components** panel, expand `MyCar` and click `Engine`. It opens with `delay` and `lag` wired together. If it opens as code, click ⇄ to get the diagram.

#### B · Name the values

A number a part needs becomes a parameter of `Engine`, and the part refers to it by name — so `Engine(T_max = 200)` later changes the ceiling in one place.

| Name | Type | Value | Meaning |
| --- | --- | --- | --- |
| `theta_e` | `Time` | `0.3` | Injection-to-torque transport delay |
| `tau_e` | `Time` | `0.3` | Manifold-filling first-order lag |
| `T_max` | `Torque` | `150` | Peak deliverable torque |

2. Click an empty spot of the canvas. The panel on the right now shows `Engine` itself, with an **Add parameter** button. Add one parameter per row of the table — or toggle to code (⇄) and paste these lines just above `relations`:

   ::: code-group

   ```txt [Parameters]
     "Injection-to-torque transport delay"
     structural parameter theta_e::Time = 0.3
     "Manifold-filling first-order lag"
     parameter tau_e::Time = 0.3
     "Peak deliverable torque"
     parameter T_max::Torque = 150
   ```

   :::

   `theta_e` is `structural` because `PadeDelay` builds its coefficients from the delay when the model is compiled; if **Add parameter** offers no structural option, use the pasted line.

3. Click `delay` and change `delayTime` from `0.3` to `theta_e`. Click `lag` and change `T` to `tau_e`. The fields accept names as well as numbers.

#### C · Complete the chain and add the ports

| Name | Library path | Set |
| --- | --- | --- |
| `tau_cmd` | Dyad › RealInput | port, left edge |
| `spline` | Dyad › Spline | port, right edge — the output shaft |
| `support` | Dyad › Spline | port, bottom edge — the engine mounts |
| `delay` | BlockComponents › Nonlinear › PadeDelay | `n = 6`, `m = 5`, `delayTime = theta_e` |
| `lag` | BlockComponents › Continuous › FirstOrder | `T = tau_e` |
| `limiter` | BlockComponents › Nonlinear › Limiter | `y_max = T_max`, `y_min = 0` |
| `torque` | RotationalComponents › Sources › TorqueSource | — |

4. Click **+**, search `Limiter`, click `BlockComponents › Nonlinear › Limiter`, rename it `limiter` and drag it to the right of `lag`. In its panel set `y_max` to `T_max` and `y_min` to `0` — the engine cannot brake through this path.
5. Click **+**, search `TorqueSource`, click `RotationalComponents › Sources › TorqueSource`, rename it `torque` and drag it to the right of `limiter`.
6. Wire `lag`'s output (right edge) to `limiter`'s input (left edge), and `limiter`'s output to `torque`'s `tau` input.
7. **Ports are parts too.** Click **+** and open `Dyad`, the first library in the list. Place a `RealInput` and rename it `tau_cmd`; place two `Spline`s and rename them `spline` and `support`. Drag `tau_cmd` onto the left edge of the thin blue rectangle, `spline` onto the right edge, `support` onto the bottom edge: that rectangle is the component's outline, and ports on it are what other components connect to.
8. Wire the ports: `tau_cmd` → `delay`'s input; `torque`'s right-hand gray circle (`spline`) → the `spline` port; `torque`'s bottom gray circle (`support`) → the `support` port. Save with <kbd>Ctrl</kbd>+<kbd>S</kbd>.

Your diagram should now match the picture at the top of this step, and the **Problems** tab under the editor should show nothing for `Engine`.

#### D · A test bench

An engine with an unconnected input cannot be simulated — nobody has said what the torque command is. So it gets a bench: a source for the command, a load on the shaft, and something for the mounts to push against.

| Name | Library path | Set |
| --- | --- | --- |
| `cmd` | BlockComponents › Sources › Step | `height = 200`, `offset = 0`, `start_time = 0.5` |
| `engine` | your `Engine` | — |
| `load` | RotationalComponents › Components › Inertia | `J = 1` |
| `mounts` | RotationalComponents › Components › Fixed | — |

[![EngineStep test harness: a step source drives the engine into a unit inertia held by fixed mounts.](/handson/lecture-01/img/step02-engine-step.png){width="1414" height="813"}](/handson/lecture-01/img/step02-engine-step.png)

The test harness: `cmd` steps the torque command above the ceiling, `load` is a 1 kg·m² inertia, and `EngineStepTransient` at the bottom of the code runs it for 3 s.

9. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `EngineStep`. It opens as an empty diagram. It is the test bench: a separate model that holds your engine.
10. Click **+**, open `MyCar` at the bottom of the list, click `Engine`, and rename the new block `engine`. With **+**, add `BlockComponents › Sources › Step` as `cmd` (`height = 200`, `offset = 0`, `start_time = 0.5`), `RotationalComponents › Components › Inertia` as `load` (`J = 1`) and `RotationalComponents › Components › Fixed` as `mounts`.
11. Wire `cmd`'s output → `engine`'s `tau_cmd`; `engine`'s `spline` → `load`'s left circle (`spline_a`); `engine`'s `support` → `mounts`.
12. Open `EngineStep`, toggle to code (⇄) and add the three `initial` lines from the block below at the end of `relations`: the starting state has no diagram form. Save.
13. <Badge type="tip" text="New analysis" /> With `EngineStep` open, press ▷ (**Run Analysis**) in the editor title bar. Dyad Studio offers the analysis types it can create: choose **TransientAnalysis**. It creates the analysis with `EngineStep` already assigned as its model and lists it in the **Analyses** panel. Name it `EngineStepTransient` — the plot command below calls it by that name; if it picked another name, change the word after `analysis` in its code — and set `stop` to `3` s.

The complete bench and its analysis as code. Take the `initial` lines from here; the `analysis` block is the fallback if creating it with ▷ does not work.

::: code-group

```txt [EngineStep and EngineStepTransient]
component EngineStep
  cmd = BlockComponents.Sources.Step(height = 200, offset = 0, start_time = 0.5)
  engine = Engine()
  "Unit inertia, so its angular acceleration reads as the delivered torque"
  load = RotationalComponents.Components.Inertia(J = 1)
  mounts = RotationalComponents.Components.Fixed()
relations
  connect(cmd.y, engine.tau_cmd)
  connect(engine.spline, load.spline_a)
  connect(engine.support, mounts.spline)
  initial engine.lag.x = 0
  initial load.phi = 0
  initial load.w = 0
end

analysis EngineStepTransient
  extends TransientAnalysis(stop = 3)
  model = EngineStep()
end
```

:::

#### E · Run and plot

13. Run it: press ▷ beside `EngineStepTransient` in the **Analyses** panel. Then plot `engine.limiter.y`. A plain `plot` of the result draws every state at once, including the six internal states of the delay, which swing into the thousands and hide everything else. Pick the one signal by name in the Julia REPL:

    ```julia
    using MyCar, Plots
    r = MyCar.EngineStepTransient()
    plot(r; idxs = r."engine.limiter.y")
    ```

    The same pattern plots several signals, `idxs = [r."a", r."b"]`, or one against another, `idxs = (r."x", r."y")`.

[![Plot of engine.limiter.y: zero until 0.5 s, a 0.3 s dead time with small ripples, then a rise that is clipped flat at 150 N·m from about 1.2 s.](/handson/lecture-01/img/step02-engine-step-plot.png){width="990" height="528"}](/handson/lecture-01/img/step02-engine-step-plot.png)

The run: 200 N·m is asked for at 0.5 s. Nothing arrives for the 0.3 s dead time (the small wiggles are the Padé approximation), the lag shapes the rise, and the limiter clips it at 150 N·m.

::: tip Checkpoint

Measured on `HandsOn.EngineStepTransient`:

- `engine.limiter.y` stays at 0 through the step at 0.5 s, reads only 6.2 N·m at 0.8 s, 97.5 N·m at 1.0 s, clips at **150 N·m at 1.22 s** and stays there.
- `engine.delay.y` reads 208.1 at 0.9 s before settling at 200: the Padé approximation of the delay overshoots. The limiter hides it.
- `load.w` ends at 306.0 rad/s at 3 s.

:::

Commit: **Source Control** → message `Step 02: engine` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/Engine.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
Torque command in, shaft torque out, through a transport delay, a first-order lag and a torque
ceiling.
"""
component Engine
  "Commanded torque"
  tau_cmd = RealInput()
  "Output shaft"
  spline = Spline()
  "Engine mounts"
  support = Spline()
  # m = n - 1 leaves the delay without direct feedthrough, so a command step cannot leak through
  # the limiter before the delay has elapsed.
  delay = BlockComponents.Nonlinear.PadeDelay(n = 6, m = 5, delayTime = theta_e)
  lag = BlockComponents.Continuous.FirstOrder(T = tau_e)
  limiter = BlockComponents.Nonlinear.Limiter(y_max = T_max, y_min = 0)
  torque = RotationalComponents.Sources.TorqueSource()
  # Structural because PadeDelay builds its coefficients from the delay when it is compiled.
  "Injection-to-torque transport delay"
  structural parameter theta_e::Time = 0.3
  "Manifold-filling first-order lag"
  parameter tau_e::Time = 0.3
  "Peak deliverable torque"
  parameter T_max::Torque = 150
relations
  connect(tau_cmd, delay.u)
  connect(delay.y, lag.u)
  connect(lag.y, limiter.u)
  connect(limiter.y, torque.tau)
  connect(torque.spline, spline)
  connect(torque.support, support)
end

"""A torque command above the ceiling, stepped in at 0.5 s, into a 1 kg·m² flywheel."""
component EngineStep
  cmd = BlockComponents.Sources.Step(height = 200, offset = 0, start_time = 0.5)
  engine = Engine()
  "Unit inertia, so its angular acceleration reads as the delivered torque"
  load = RotationalComponents.Components.Inertia(J = 1)
  mounts = RotationalComponents.Components.Fixed()
relations
  connect(cmd.y, engine.tau_cmd)
  connect(engine.spline, load.spline_a)
  connect(engine.support, mounts.spline)
  initial engine.lag.x = 0
  initial load.phi = 0
  initial load.w = 0
end

analysis EngineStepTransient
  extends TransientAnalysis(stop = 3)
  model = EngineStep()
end
```

:::

### 03 Driveline <Badge type="info" text="13 min" /> {#driveline}

Turn engine torque into a force on the car: a 4:1 gear and a 0.31 m rolling wheel.

Theory: [tutor slides — from a twist to a push, F = T · i / r](../../handson-01/index.html#/twist-to-push){target="_self"}

#### Parameters

| Name | Type | Value | Meaning |
| --- | --- | --- | --- |
| `i` | `Real` | `4.0` | Gear ratio |
| `r` | `Length` | `0.31` | Wheel rolling radius |

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `spline` | Dyad › Spline | port — from the engine |
| `support_r` | Dyad › Spline | port — gearbox housing |
| `flange` | Dyad › Flange | port — to the body |
| `support_t` | Dyad › Flange | port — the road |
| `gear` | RotationalComponents › Components › IdealGear | `ratio = i` |
| `wheel` | RotationalComponents › Components › IdealRollingWheel | `radius = r` |

#### What you are building

[![Driveline diagram: spline into an ideal gear, then an ideal rolling wheel out to the flange, with both supports brought out.](/handson/lecture-01/img/step03-driveline.png){width="1496" height="934"}](/handson/lecture-01/img/step03-driveline.png)

The finished `Driveline`, its panel listing the parameters `i` and `r` that the parts use. Rotational ports are gray circles and translational ports are green squares: the rolling wheel is where one becomes the other.

#### Do this

1. Add the two parameters. Click an empty spot of the canvas and use **Add parameter** in the component panel for each row of the parameters table, or toggle to code (⇄) and paste them above `relations`:

   ::: code-group

   ```txt [Parameters]
     "Gear ratio"
     parameter i::Real = 4.0
     "Wheel rolling radius"
     parameter r::Length = 0.31
   ```

   :::

   Then give the parts the *names*, not the numbers — the parts table shows which.

2. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Driveline`. It opens as an empty diagram. Then: Place `gear` and `wheel` and wire `gear.spline_b → wheel.spline`.

3. Add the four ports. Wire `spline → gear.spline_a` and `wheel.flange → flange`.

4. Both reaction paths go out of the component: wire `gear.support` and `wheel.support_r` to `support_r`, and `wheel.support_t` to `support_t`. The car will ground them.

5. Set `ratio = i` and `radius = r`. The force at the flange is then `T · i / r`, the formula from the theory slide at the start of this step.

::: tip Checkpoint

It saves without errors and has the four ports named in the table. Under 100 N·m into `spline` and 1400 kg on `flange`, the reference test `TestDriveline` accelerates the mass at 0.9217 m/s² (100 · 4 / 0.31 / 1400).

:::

Commit: **Source Control** → message `Step 03: driveline` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/Driveline.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out, and so is the test component. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""Gearbox and rolling wheel: engine shaft in, tractive force on the body out."""
component Driveline
  "From the engine"
  spline = Spline()
  "Gearbox housing"
  support_r = Spline()
  "To the body"
  flange = Flange()
  "Road"
  support_t = Flange()
  gear = RotationalComponents.Components.IdealGear(ratio = i)
  wheel = RotationalComponents.Components.IdealRollingWheel(radius = r)
  "Gear ratio"
  parameter i::Real = 4.0
  "Wheel rolling radius"
  parameter r::Length = 0.31
relations
  connect(spline, gear.spline_a)
  connect(gear.spline_b, wheel.spline)
  connect(wheel.flange, flange)
  connect(gear.support, support_r)
  connect(wheel.support_r, support_r)
  connect(wheel.support_t, support_t)
end
```

:::

### 04 Body <Badge type="info" text="21 min" /> {#body}

Give the car its 1400 kg and the two forces that hold it back on a flat road: drag and rolling resistance.

Theory: [tutor slides — the forces on the car, air drag, rolling resistance](../../handson-01/index.html#/four-forces){target="_self"}

#### Parameters

| Name | Type | Value | Meaning |
| --- | --- | --- | --- |
| `m` | `Dyad.Mass` | `1400` | Vehicle mass |
| `CdA` | `Area` | `0.63` | Aerodynamic drag area, Cd \* A |
| `rho` | `Density` | `1.2` | Air density |
| `f_r` | `Real` | `0.012` | Rolling resistance coefficient |
| `g` | `Acceleration` | `9.80665` | Gravitational acceleration |
| `v_nominal` | `Velocity` | `30` | Speed at which the drag force is specified |

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `flange` | Dyad › Flange | port — tractive force in |
| `mass` | TranslationalComponents › Components › Mass | `m = m` |
| `drag` | TranslationalComponents › Sources › QuadraticSpeedDependentForce | `ForceDirection = false`, `v_nominal = v_nominal`, `f_nominal = -0.5 * rho * CdA * v_nominal ^ 2` |
| `rolling` | TranslationalComponents › Components › RollingResistance | `fWeight = m * g` |
| `cr_const` | BlockComponents › Sources › Constant | `k = f_r` |
| `incl_const` | BlockComponents › Sources › Constant | `k = 0` — flat road |
| `ground` | TranslationalComponents › Components › Fixed | — |

#### What you are building

[![Body diagram: mass, quadratic drag and rolling resistance on one flange, with constants feeding the rolling coefficient and inclination.](/handson/lecture-01/img/step04-body.png){width="1499" height="945"}](/handson/lecture-01/img/step04-body.png)

The finished `Body`. Both `Constant` blocks feed `rolling`: one is the rolling coefficient, the other the flat-road inclination.

#### Do this

1. Add the six parameters. `m` feeds two parts and `rho`, `CdA`, `v_nominal` combine into one: naming them is what keeps those uses in step. Click an empty spot of the canvas and use **Add parameter** in the component panel for each row of the parameters table, or toggle to code (⇄) and paste them above `relations`:

   ::: code-group

   ```txt [Parameters]
     "Vehicle mass"
     parameter m::Dyad.Mass = 1400
     "Aerodynamic drag area, Cd * A"
     parameter CdA::Area = 0.63
     "Air density"
     parameter rho::Density = 1.2
     "Rolling resistance coefficient"
     parameter f_r::Real = 0.012
     "Gravitational acceleration"
     parameter g::Acceleration = 9.80665
     "Speed at which the drag force is specified"
     parameter v_nominal::Velocity = 30
   ```

   :::

   Then give the parts the *names*, not the numbers — the parts table shows which.

2. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Body`. It opens as an empty diagram. Then: Place the parts and wire the three forces — `flange`, `drag.flange`, `rolling.flange` — to `mass.flange_a`.

3. Wire `drag.support` and `rolling.support` to `ground.flange`: drag and rolling resistance push against the road and the air, not against the car.

4. Feed `rolling` its two signal inputs: `cr_const.y → rolling.cr` and `incl_const.y → rolling.inclination`. An unconnected input would leave the model incomplete.

5. Set the drag parameters. `f_nominal` is negative, which makes the source a load; `ForceDirection = false` makes drag oppose motion both ways. `-0.5 * rho * CdA * v_nominal ^ 2` is ½ρ·C<sub>d</sub>A·v² at the nominal speed, written in the parameters' names.

::: tip Checkpoint

It saves without errors. Under a constant 500 N the reference test `TestBody` starts at 0.357 m/s² and settles at 29.78 m/s, where drag and rolling resistance add up to 500 N.

:::

Commit: **Source Control** → message `Step 04: body` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/Body.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out, and so is the test component. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
Car body on a flat road: tractive force in at the flange, resisted by aerodynamic drag and rolling
resistance.
"""
component Body
  "Tractive force from the driveline"
  flange = Flange()
  mass = TranslationalComponents.Components.Mass(m = m)
  # A negative nominal force makes the source a load; ForceDirection = false gives the v*|v| form,
  # so drag opposes motion in both directions.
  drag = TranslationalComponents.Sources.QuadraticSpeedDependentForce(ForceDirection = false, v_nominal = v_nominal, f_nominal = -0.5 * rho * CdA * v_nominal ^ 2)
  rolling = TranslationalComponents.Components.RollingResistance(fWeight = m * g)
  cr_const = BlockComponents.Sources.Constant(k = f_r)
  "Flat road: tan(alpha) = 0"
  incl_const = BlockComponents.Sources.Constant(k = 0)
  ground = TranslationalComponents.Components.Fixed()
  "Vehicle mass"
  parameter m::Dyad.Mass = 1400
  "Aerodynamic drag area, Cd * A"
  parameter CdA::Area = 0.63
  "Air density"
  parameter rho::Density = 1.2
  "Rolling resistance coefficient"
  parameter f_r::Real = 0.012
  "Gravitational acceleration"
  parameter g::Acceleration = 9.80665
  "Speed at which the drag force is specified"
  parameter v_nominal::Velocity = 30
relations
  connect(flange, mass.flange_a)
  connect(drag.flange, mass.flange_a)
  connect(rolling.flange, mass.flange_a)
  connect(drag.support, ground.flange)
  connect(rolling.support, ground.flange)
  connect(cr_const.y, rolling.cr)
  connect(incl_const.y, rolling.inclination)
end
```

:::

### 05 Car: full throttle to terminal speed <Badge type="info" text="27 min" /> {#car}

Assemble engine, driveline and body into the car and drive it flat out from rest until it stops getting faster — at the 246 km/h worked out on paper at the start of this step.

Theory: [tutor slides — the force balance, top speed on paper, how long it takes](../../handson-01/index.html#/force-balance){target="_self"}

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `tau_cmd` | Dyad › RealInput | port |
| `v_kmh` | Dyad › RealOutput | port |
| `engine` | your `Engine` | — |
| `driveline` | your `Driveline` | — |
| `body` | your `Body` | — |
| `vsensor` | TranslationalComponents › Sensors › VelocitySensor | — |
| `to_kmh` | BlockComponents › Math › Gain | `k = 3.6` |
| `rot_ground` | RotationalComponents › Components › Fixed | — |
| `trans_ground` | TranslationalComponents › Components › Fixed | — |

Test bench `CarFullThrottle`:

| Name | Library path | Set |
| --- | --- | --- |
| `cmd` | BlockComponents › Sources › Constant | `k = 150` — the torque ceiling |
| `car` | your `Car` | — |

#### What you are building

[![Car diagram: torque command into engine, driveline and body, with a velocity sensor and a 3.6 gain producing speed in km/h.](/handson/lecture-01/img/step05-car.png){width="1433" height="820"}](/handson/lecture-01/img/step05-car.png)

The finished `Car`. The sensor reads the body's speed in m/s and the `k = 3.6` gain turns it into km/h.

[![Plot of car.v_kmh rising from zero and leveling off at about 246 km/h after roughly 150 s.](/handson/lecture-01/img/step05-car-plot.png){width="990" height="528"}](/handson/lecture-01/img/step05-car-plot.png)

The run: steep at first, then flattening as drag grows with the square of speed, settling at 246.39 km/h.

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Car`. It opens as an empty diagram. Then: Drop in your three components and wire `engine.spline → driveline.spline` and `driveline.flange → body.flange`.

2. Ground the reactions: `engine.support` and `driveline.support_r` to `rot_ground`, `driveline.support_t` to `trans_ground`.

3. Measure: `vsensor.flange` on `body.flange`, then `vsensor.v → to_kmh.u`. The sensor gives m/s; the gain of 3.6 makes it km/h.

4. Add the ports: `tau_cmd → engine.tau_cmd`, `to_kmh.y → v_kmh`.

5. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `CarFullThrottle`. It opens as an empty diagram. This is the bench. With **+**, place your `Car` (under `MyCar`) as `car` and a `BlockComponents › Sources › Constant` as `cmd` with `k = 150`. Wire `cmd.y → car.tau_cmd`.

6. Open `CarFullThrottle`, toggle to code (⇄) and add the three `initial` lines from the block below at the end of `relations`: the starting state has no diagram form. Save. The car needs its position fixed at the start as well as its speed; without `car.body.mass.s` the model has no unique initial state.

7. <Badge type="tip" text="New analysis" /> With `CarFullThrottle` open, press ▷ (**Run Analysis**) in the editor title bar. Dyad Studio offers the analysis types it can create: choose **TransientAnalysis**. It creates the analysis with `CarFullThrottle` already assigned as its model and lists it in the **Analyses** panel. Name it `CarFullThrottleTransient` — the plot command below calls it by that name; if it picked another name, change the word after `analysis` in its code — and set `stop` to `300` s.

8. Run it: press ▷ beside `CarFullThrottleTransient` in the **Analyses** panel. Then, in the Julia REPL (**Dyad: Open Julia REPL** in the **Actions** title bar), plot the speed:

   ```julia
   using MyCar, Plots
   r = MyCar.CarFullThrottleTransient()
   plot(r; idxs = r."car.v_kmh")
   ```

The complete bench and its analysis as code. Take the `initial` lines from here; the `analysis` block is the fallback if creating it with ▷ does not work.

::: code-group

```txt [CarFullThrottle and CarFullThrottleTransient]
component CarFullThrottle
  "Full throttle: the engine's 150 N·m ceiling"
  cmd = BlockComponents.Sources.Constant(k = 150)
  car = Car()
relations
  connect(cmd.y, car.tau_cmd)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
end

analysis CarFullThrottleTransient
  extends TransientAnalysis(stop = 300)
  model = CarFullThrottle()
end
```

:::

::: tip Checkpoint

Measured on `HandsOn.CarFullThrottleTransient`: 21.2 km/h at 5 s, 43.6 km/h at 10 s, 100 km/h at 23.6 s, 197.5 km/h at 60 s, 99 % of the final speed at 143 s and **246.39 km/h at 300 s**. The curve is a first-order rise: steep at first, then flattening as drag grows with the square of speed.

Same check against the course model: `Vehicle.CarPlant` at full torque reads 246.39 km/h at 300 s, and the two agree to 0.0001 km/h at 800 s (246.3957 km/h). Your car is the car Lecture 1 controls.

:::

Commit: **Source Control** → message `Step 05: car` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/Car.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
Longitudinal car on a flat road: torque command in, speed in km/h out.
"""
component Car
  "Commanded engine torque"
  tau_cmd = RealInput()
  "Vehicle speed in km/h"
  v_kmh = RealOutput()
  engine = Engine()
  driveline = Driveline()
  body = Body()
  vsensor = TranslationalComponents.Sensors.VelocitySensor()
  to_kmh = BlockComponents.Math.Gain(k = 3.6)
  "Engine mounts and gearbox housing"
  rot_ground = RotationalComponents.Components.Fixed()
  "Road under the wheel"
  trans_ground = TranslationalComponents.Components.Fixed()
relations
  connect(tau_cmd, engine.tau_cmd)
  connect(engine.spline, driveline.spline)
  connect(engine.support, rot_ground.spline)
  connect(driveline.support_r, rot_ground.spline)
  connect(driveline.flange, body.flange)
  connect(driveline.support_t, trans_ground.flange)
  connect(vsensor.flange, body.flange)
  connect(vsensor.v, to_kmh.u)
  connect(to_kmh.y, v_kmh)
end

"""Full throttle from rest on a flat road, run to terminal speed."""
component CarFullThrottle
  "Full throttle: the engine's 150 N·m ceiling"
  cmd = BlockComponents.Sources.Constant(k = 150)
  car = Car()
relations
  connect(cmd.y, car.tau_cmd)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
end

analysis CarFullThrottleTransient
  extends TransientAnalysis(stop = 300)
  model = CarFullThrottle()
end
```

:::

### 06 A wheel with inertia <Badge type="info" text="12 min" /> {#wheel-inertia}

Put a 1 kg·m² road wheel between the gear and the rolling contact, and see how little it changes.

Theory: [tutor slides — the wheel's hidden mass](../../handson-01/index.html#/hidden-mass){target="_self"}

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `inertia` | RotationalComponents › Components › Inertia | `J = J_w` |
| `(the rest)` | as in `Driveline` | — |

`WheeledCar` is `Car` with `driveline` swapped for `WheeledDriveline`; its test bench `WheeledCarFullThrottle` also needs `initial car.driveline.inertia.phi = 0`.

#### What you are building

[![WheeledDriveline diagram: an inertia block sits between the gear and the rolling wheel.](/handson/lecture-01/img/step06-wheeled-driveline.png){width="1504" height="944"}](/handson/lecture-01/img/step06-wheeled-driveline.png)

The only change from step 3: `inertia` sits between `gear` and `wheel`.

[![car.v_kmh for Car and WheeledCar overlaid: the dashed WheeledCar curve lies almost exactly on the Car curve, both settling at about 246 km/h.](/handson/lecture-01/img/step06-wheeled-car-plot.png){width="990" height="528"}](/handson/lecture-01/img/step06-wheeled-car-plot.png)

The run against step 5: the dashed curve lags by a fraction of a second at launch and is otherwise on top of it. Through the rolling radius, 1 kg·m² weighs like J / r² ≈ 10 kg on a 1400 kg car.

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `Driveline` → **Duplicate** and name the copy `WheeledDriveline`.

2. Delete the wire `gear.spline_b → wheel.spline`, place `inertia` between them and wire `gear.spline_b → inertia.spline_a`, `inertia.spline_b → wheel.spline`. Add the parameter `J_w` (`MomentOfInertia`, 1.0) next to the `i` and `r` the copy already has, and set `J = J_w`.

3. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `Car` → **Duplicate** and name the copy `WheeledCar`. In its diagram, replace its `driveline` with a `WheeledDriveline`. The ports are the same, so the wires stay.

4. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `CarFullThrottle` → **Duplicate** and name the copy `WheeledCarFullThrottle`. In its diagram, swap `car` for a `WheeledCar`. The wheel now has a state of its own: Open `WheeledCarFullThrottle`, toggle to code (⇄) and add the line `initial car.driveline.inertia.phi = 0` at the end of `relations`: the starting state has no diagram form. Save.

5. <Badge type="tip" text="New analysis" /> With `WheeledCarFullThrottle` open, press ▷ (**Run Analysis**) in the editor title bar. Dyad Studio offers the analysis types it can create: choose **TransientAnalysis**. It creates the analysis with `WheeledCarFullThrottle` already assigned as its model and lists it in the **Analyses** panel. Name it `WheeledCarFullThrottleTransient` — the plot command below calls it by that name; if it picked another name, change the word after `analysis` in its code — and set `stop` to `300` s. Fallback, as code:

   ::: code-group

   ```txt [WheeledCarFullThrottle and WheeledCarFullThrottleTransient]
   component WheeledCarFullThrottle
     "Full throttle: the engine's 150 N·m ceiling"
     cmd = BlockComponents.Sources.Constant(k = 150)
     car = WheeledCar()
   relations
     connect(cmd.y, car.tau_cmd)
     initial car.body.mass.s = 0
     initial car.body.mass.v = 0
     initial car.engine.lag.x = 0
     initial car.driveline.inertia.phi = 0
   end

   analysis WheeledCarFullThrottleTransient
     extends TransientAnalysis(stop = 300)
     model = WheeledCarFullThrottle()
   end
   ```

   :::

6. Run it: press ▷ beside `WheeledCarFullThrottleTransient` in the **Analyses** panel. Then plot it over step 5's curve in the Julia REPL:

   ```julia
   using MyCar, Plots
   a = MyCar.CarFullThrottleTransient()
   b = MyCar.WheeledCarFullThrottleTransient()
   p = plot(a; idxs = a."car.v_kmh", label = "Car")
   plot!(p, b; idxs = b."car.v_kmh", label = "WheeledCar")
   ```

::: tip Checkpoint

Measured on `HandsOn.WheeledCarFullThrottleTransient`: 43.27 km/h at 10 s against 43.59 km/h without the wheel inertia, 100 km/h at 23.8 s against 23.6 s, and the same 246.39 km/h at 300 s. The two curves are almost on top of each other: through the rolling radius, 1 kg·m² weighs like J / r² ≈ 10 kg on a 1400 kg car. Inertia slows the launch, not the terminal speed.

:::

Commit: **Source Control** → message `Step 06: wheel inertia` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/WheeledCar.dyad`, `dyad/HandsOn/WheeledDriveline.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out, and so is the test component. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
The driveline of step 3 with a road wheel that has inertia. The wheel still rolls without slip.
"""
component WheeledDriveline
  "From the engine"
  spline = Spline()
  "Gearbox housing"
  support_r = Spline()
  "To the body"
  flange = Flange()
  "Road"
  support_t = Flange()
  gear = RotationalComponents.Components.IdealGear(ratio = i)
  "Road wheel and tire, about 20 kg mostly between 0.2 and 0.3 m radius"
  inertia = RotationalComponents.Components.Inertia(J = J_w)
  wheel = RotationalComponents.Components.IdealRollingWheel(radius = r)
  "Gear ratio"
  parameter i::Real = 4.0
  "Road wheel and tire inertia"
  parameter J_w::MomentOfInertia = 1.0
  "Wheel rolling radius"
  parameter r::Length = 0.31
relations
  connect(spline, gear.spline_a)
  connect(gear.spline_b, inertia.spline_a)
  connect(inertia.spline_b, wheel.spline)
  connect(wheel.flange, flange)
  connect(gear.support, support_r)
  connect(wheel.support_r, support_r)
  connect(wheel.support_t, support_t)
end

"""
The car of step 5 with a wheel that has inertia.
"""
component WheeledCar
  "Commanded engine torque"
  tau_cmd = RealInput()
  "Vehicle speed in km/h"
  v_kmh = RealOutput()
  engine = Engine()
  driveline = WheeledDriveline()
  body = Body()
  vsensor = TranslationalComponents.Sensors.VelocitySensor()
  to_kmh = BlockComponents.Math.Gain(k = 3.6)
  "Engine mounts and gearbox housing"
  rot_ground = RotationalComponents.Components.Fixed()
  "Road under the wheel"
  trans_ground = TranslationalComponents.Components.Fixed()
relations
  connect(tau_cmd, engine.tau_cmd)
  connect(engine.spline, driveline.spline)
  connect(engine.support, rot_ground.spline)
  connect(driveline.support_r, rot_ground.spline)
  connect(driveline.flange, body.flange)
  connect(driveline.support_t, trans_ground.flange)
  connect(vsensor.flange, body.flange)
  connect(vsensor.v, to_kmh.u)
  connect(to_kmh.y, v_kmh)
end

"""Full throttle from rest on a flat road, with wheel inertia."""
component WheeledCarFullThrottle
  "Full throttle: the engine's 150 N·m ceiling"
  cmd = BlockComponents.Sources.Constant(k = 150)
  car = WheeledCar()
relations
  connect(cmd.y, car.tau_cmd)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
  initial car.driveline.inertia.phi = 0
end

analysis WheeledCarFullThrottleTransient
  extends TransientAnalysis(stop = 300)
  model = WheeledCarFullThrottle()
end
```

:::

### 07 A road with a gradient <Badge type="info" text="13 min" /> {#grade}

Write your first component with an equation — the along-slope pull of gravity — and give the body a `grade` input.

Theory: [tutor slides — the slope](../../handson-01/index.html#/slope){target="_self"}

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `(extends)` | TranslationalComponents › Interfaces › PartialForce | gives `flange`, `support` and the force `f` |
| `grade` | Dyad › RealInput | port — tan α |
| `m, g` | parameters | `m = 1400`, `g = 9.80665` |

`GradeBody` is `Body` with `incl_const` replaced by a `grade` input port that feeds both `rolling.inclination` and a `GradeForce(m = 1400)`.

#### What you are building

[![GradeBody diagram: the grade input feeds both the rolling resistance inclination and the grade force.](/handson/lecture-01/img/step07-grade-body.png){width="1500" height="943"}](/handson/lecture-01/img/step07-grade-body.png)

`GradeBody`: one `grade` input now drives both `rolling.inclination` and `gradeforce.grade`, replacing the flat-road constant.

#### Do this

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `GradeForce`. It opens as an empty diagram. Toggle to code (⇄): an equation has no diagram form. Start from the solution's first block — `extends` the force interface, declare the `grade` input and the two parameters. Short on time? Copy the whole component from **Stuck? The full model** below, paste it over the new file's contents, and read the relations against the next point.
2. Write the one equation below. `grade` is tan α, the same convention `RollingResistance` uses for its `inclination`, so one signal can drive both.
3. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `Body` → **Duplicate** and name the copy `GradeBody`. In the diagram, delete `incl_const`, add a `grade` input port, wire it to `rolling.inclination`, place a `GradeForce` with `m = m`, `g = g` — the body's own parameters, so the car's mass is set in one place — and wire `grade → gradeforce.grade`, `gradeforce.flange → mass.flange_a`, `gradeforce.support → ground.flange`.

::: code-group

```txt [GradeForce — complete]
component GradeForce
  extends TranslationalComponents.Interfaces.PartialForce
  "Road gradient, tan(alpha)"
  grade = RealInput()
  "Vehicle mass"
  parameter m::Dyad.Mass = 1400
  "Gravitational acceleration"
  parameter g::Acceleration = 9.80665
relations
  # A force source acts on the body with -f, so a climb (positive grade) needs positive f to
  # hold the car back.
  f = m * g * sin(atan(grade))
end
```

:::

::: tip Checkpoint

The reference tests: on a 10 % climb (`TestGradeForce`) `gf.f` reads 1366.1 N and the free mass decelerates at 0.976 m/s². With 500 N of traction on a 2 % climb starting at 10 m/s (`TestGradeBody`, case `climb`) the body barely accelerates: 0.0164 m/s² at the start, 10.16 m/s after 10 s.

:::

Commit: **Source Control** → message `Step 07: grade` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/GradeBody.dyad`, `dyad/HandsOn/GradeForce.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out, and so are the test components. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
The along-slope pull of gravity on the car, from a road-gradient signal.

`grade` is tan(alpha), the convention `RollingResistance` uses for its `inclination` input, so
one signal can drive both.
"""
component GradeForce
  extends TranslationalComponents.Interfaces.PartialForce
  "Road gradient, tan(alpha)"
  grade = RealInput()
  "Vehicle mass"
  parameter m::Dyad.Mass = 1400
  "Gravitational acceleration"
  parameter g::Acceleration = 9.80665
relations
  # A force source acts on the body with -f, so a climb (positive grade) needs positive f to
  # hold the car back.
  f = m * g * sin(atan(grade))
end

"""
The body of step 4 on a road with a gradient: one `grade` signal tilts the rolling resistance and
drives the grade force.
"""
component GradeBody
  "Tractive force from the driveline"
  flange = Flange()
  "Road gradient, tan(alpha)"
  grade = RealInput()
  mass = TranslationalComponents.Components.Mass(m = m)
  drag = TranslationalComponents.Sources.QuadraticSpeedDependentForce(ForceDirection = false, v_nominal = v_nominal, f_nominal = -0.5 * rho * CdA * v_nominal ^ 2)
  rolling = TranslationalComponents.Components.RollingResistance(fWeight = m * g)
  cr_const = BlockComponents.Sources.Constant(k = f_r)
  gradeforce = GradeForce(m = m, g = g)
  ground = TranslationalComponents.Components.Fixed()
  "Vehicle mass"
  parameter m::Dyad.Mass = 1400
  "Aerodynamic drag area, Cd * A"
  parameter CdA::Area = 0.63
  "Air density"
  parameter rho::Density = 1.2
  "Rolling resistance coefficient"
  parameter f_r::Real = 0.012
  "Gravitational acceleration"
  parameter g::Acceleration = 9.80665
  "Speed at which the drag force is specified"
  parameter v_nominal::Velocity = 30
relations
  connect(flange, mass.flange_a)
  connect(drag.flange, mass.flange_a)
  connect(rolling.flange, mass.flange_a)
  connect(gradeforce.flange, mass.flange_a)
  connect(drag.support, ground.flange)
  connect(rolling.support, ground.flange)
  connect(gradeforce.support, ground.flange)
  connect(cr_const.y, rolling.cr)
  connect(grade, rolling.inclination)
  connect(grade, gradeforce.grade)
end
```

:::

### 08 Tire friction against slip <Badge type="info" text="20 min" /> {#tire-curve}

A component made of equations instead of parts: slip ratio κ in, friction coefficient μ out — a peak of 1.0 at 4 % slip, falling to 0.7 once the tire slides.

Theory: [tutor slides — slip, and how grip depends on it](../../handson-01/index.html#/no-slip){target="_self"}

#### Where you are, where you are going

Everything so far was drawn. This component has nothing to draw: it is a formula. You paste it, read it line by line, then put it on a small bench that sweeps the slip from −1 to +1 so you can see the curve. Step 09 uses it inside the slipping wheel.

[![TireFrictionCurve: the diagram holds only the kappa input and mu output; the curve itself is equations in the code view.](/handson/lecture-01/img/step08-tire-curve.png){width="1426" height="823"}](/handson/lecture-01/img/step08-tire-curve.png)

`TireFrictionCurve` has no blocks inside: the diagram shows only its two ports, and the curve lives in the equations on the right.

[![Plot of mu against kappa: an odd-symmetric curve peaking at plus and minus 1.0 near a slip of 0.04 and falling to plus and minus 0.7 beyond 0.12.](/handson/lecture-01/img/step08-tire-curve-plot.png){width="990" height="528"}](/handson/lecture-01/img/step08-tire-curve-plot.png)

The sweep plotted as μ against κ rather than against time: peak adhesion 1.0 at κ = 0.04, sliding at 0.7 beyond κ = 0.12, mirrored for braking.

#### A · Create it and paste the code

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `TireFrictionCurve`.
2. Toggle to code (⇄). The new file holds an empty `component TireFrictionCurve` … `end`. Select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, then click **Copy** on the block below and paste with <kbd>Ctrl</kbd>+<kbd>V</kbd>. Save with <kbd>Ctrl</kbd>+<kbd>S</kbd>.

::: code-group

```txt [TireFrictionCurve]
"""
Tire friction coefficient against longitudinal slip: rises to the adhesion peak `mu_A` at
`sAdhesion`, falls to the sliding level `mu_S` at `sSlide`, and stays there. Point-symmetric, so
braking slip gives negative friction.
"""
component TireFrictionCurve
  "Longitudinal slip ratio, negative while braking"
  kappa = RealInput()
  "Friction coefficient, carrying the sign of the slip"
  mu = RealOutput()
  "Slip ratio at peak adhesion"
  parameter sAdhesion::Real = 0.04
  "Slip ratio at the sliding plateau"
  parameter sSlide::Real = 0.12
  "Peak adhesion coefficient"
  parameter mu_A::Real = 1.0
  "Sliding friction coefficient"
  parameter mu_S::Real = 0.7
  "Slip magnitude"
  variable slip::Real
  "Friction magnitude"
  variable mu_abs::Real
relations
  slip = abs(kappa)
  # -0.5·x³ + 1.5·x maps [-1, 1] onto [-1, 1] with zero slope at both ends, so the curve stays
  # continuously differentiable across the segment joins.
  mu_abs = ifelse(slip <= sAdhesion,
    mu_A * (-0.5 * (slip / sAdhesion) ^ 3 + 1.5 * (slip / sAdhesion)),
    ifelse(slip >= sSlide, mu_S,
      (mu_A + mu_S) / 2 + (mu_S - mu_A) / 2 * (-0.5 * ((slip - (sAdhesion + sSlide) / 2) * 2 / (sSlide - sAdhesion)) ^ 3 + 1.5 * ((slip - (sAdhesion + sSlide) / 2) * 2 / (sSlide - sAdhesion)))))
  mu = sign(kappa) * mu_abs
end
```

:::

3. Look at the **Problems** tab under the editor: nothing should be listed for this file. A red squiggle means the paste was incomplete — select all and paste again.

#### B · Read what you pasted

- `kappa = RealInput()`, `mu = RealOutput()` — the two ports: slip in, friction out.
- Four `parameter`s describe the curve: the peak `mu_A = 1.0` at `sAdhesion = 0.04`, the sliding level `mu_S = 0.7` from `sSlide = 0.12` on.
- Two `variable`s are helpers the equations use: `slip` and `mu_abs`.
- `slip = abs(kappa)` — the curve is built for positive slip, then mirrored.
- `mu_abs = ifelse(…)` — three pieces: rising to the peak, falling from peak to sliding, flat after. Each piece is a cubic with zero slope at its ends, so the curve has no corners for the solver to trip on.
- `mu = sign(kappa) * mu_abs` — negative slip (braking) gives negative friction.

#### C · Sweep it and plot the curve

4. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `TestTireFrictionCurve`. It is the bench: a ramp that moves κ from −1 to +1 in 2 s, into your curve.
5. Toggle to code (⇄). The new file holds an empty `component TestTireFrictionCurve` … `end`. Select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, then click **Copy** on the block below and paste with <kbd>Ctrl</kbd>+<kbd>V</kbd>. Save with <kbd>Ctrl</kbd>+<kbd>S</kbd>.

::: code-group

```txt [TestTireFrictionCurve]
component TestTireFrictionCurve
  "Slip swept from a locked wheel under braking to full wheelspin"
  slip = BlockComponents.Sources.Ramp(offset = -1, height = 2, duration = 2, start_time = 0)
  curve = TireFrictionCurve()
relations
  connect(slip.y, curve.kappa)
end
```

:::

6. <Badge type="tip" text="New analysis" /> With `TestTireFrictionCurve` open, press ▷ (**Run Analysis**) in the editor title bar and choose **TransientAnalysis**. It is created with `TestTireFrictionCurve` as its model and appears in the **Analyses** panel. Name it `TireFrictionCurveSweep` — the plot command calls it by that name; if it got another name, change the word after `analysis` in its code — and set `stop` to `2` s.

7. Run it: press ▷ beside `TireFrictionCurveSweep` in the **Analyses** panel. Then, in the Julia REPL, plot μ against κ rather than against time — the pair in parentheses means “first against second”:

   ```julia
   using MyCar, Plots
   r = MyCar.TireFrictionCurveSweep()
   plot(r; idxs = (r."curve.kappa", r."curve.mu"))
   ```

::: tip Checkpoint

The curve is point-symmetric: −0.7 for a wheel locked under braking (κ = −1), −0.85 at κ = −0.08, the peak of 1.0 at κ = 0.04, and 0.7 at κ = 1. These are the values `TestTireFrictionCurve` asserts.

:::

Commit: **Source Control** → message `Step 08: tire curve` → **Commit** → **Sync Changes**.

#### D · Try it

In `TireFrictionCurve`, change `mu_A = 1.0` to `1.2`, save, run `TireFrictionCurveSweep` again and re-plot: the peak rises and nothing else moves. Set it back to 1.0 before step 09.

::: details Stuck? The full model

From `dyad/HandsOn/TireFrictionCurve.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
Tire friction coefficient against longitudinal slip: rises to the adhesion peak `mu_A` at
`sAdhesion`, falls to the sliding level `mu_S` at `sSlide`, and stays there. Point-symmetric, so
braking slip gives negative friction.
"""
component TireFrictionCurve
  "Longitudinal slip ratio, negative while braking"
  kappa = RealInput()
  "Friction coefficient, carrying the sign of the slip"
  mu = RealOutput()
  "Slip ratio at peak adhesion"
  parameter sAdhesion::Real = 0.04
  "Slip ratio at the sliding plateau"
  parameter sSlide::Real = 0.12
  "Peak adhesion coefficient"
  parameter mu_A::Real = 1.0
  "Sliding friction coefficient"
  parameter mu_S::Real = 0.7
  "Slip magnitude"
  variable slip::Real
  "Friction magnitude"
  variable mu_abs::Real
relations
  slip = abs(kappa)
  # -0.5·x³ + 1.5·x maps [-1, 1] onto [-1, 1] with zero slope at both ends, so the curve stays
  # continuously differentiable across the segment joins.
  mu_abs = ifelse(slip <= sAdhesion,
    mu_A * (-0.5 * (slip / sAdhesion) ^ 3 + 1.5 * (slip / sAdhesion)),
    ifelse(slip >= sSlide, mu_S,
      (mu_A + mu_S) / 2 + (mu_S - mu_A) / 2 * (-0.5 * ((slip - (sAdhesion + sSlide) / 2) * 2 / (sSlide - sAdhesion)) ^ 3 + 1.5 * ((slip - (sAdhesion + sSlide) / 2) * 2 / (sSlide - sAdhesion)))))
  mu = sign(kappa) * mu_abs
end

component TestTireFrictionCurve
  "Slip swept from a locked wheel under braking to full wheelspin"
  slip = BlockComponents.Sources.Ramp(offset = -1, height = 2, duration = 2, start_time = 0)
  curve = TireFrictionCurve()
relations
  connect(slip.y, curve.kappa)
end

analysis TireFrictionCurveSweep
  extends TransientAnalysis(stop = 2)
  model = TestTireFrictionCurve()
end
```

:::

### 09 A wheel that can slip <Badge type="info" text="15 min" /> {#slip-wheel}

A tire instead of a rolling constraint: the wheel and the car may now move at different speeds, and your friction curve turns the difference into force.

Theory: [tutor slides — slip, and how grip depends on it (step 08)](../../handson-01/index.html#/slip-and-grip){target="_self"}

#### Where you are, where you are going

In the car so far, `IdealRollingWheel` locked wheel and road together: ω·r = v, always. `SlipWheel1D` takes its place. It has the same two connections — a shaft (`spline`) from the gear and a contact (`flange`) with the body — plus an input `mu_scale` for how slippery the road is. Inside it are equations and your `TireFrictionCurve` from step 08. Nothing runs in this step; step 10 puts it in a car.

[![SlipWheel1D diagram: the curve block sits between the spline and flange ports with no wires; it is connected through equations.](/handson/lecture-01/img/step09-slip-wheel.png){width="1431" height="828"}](/handson/lecture-01/img/step09-slip-wheel.png)

No wires to `curve`, on purpose: it is connected by the equations `curve.kappa = kappa` and `mu = mu_scale * curve.mu`, not by `connect`.

#### A · Create it and paste the code

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `SlipWheel1D`.
2. Toggle to code (⇄). The new file holds an empty `component SlipWheel1D` … `end`. Select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, then click **Copy** on the block below and paste with <kbd>Ctrl</kbd>+<kbd>V</kbd>. Save with <kbd>Ctrl</kbd>+<kbd>S</kbd>. It uses `TireFrictionCurve()`, so step 08 must be saved in the same library.

::: code-group

```txt [SlipWheel1D]
"""
A road wheel whose tire grips through slip: the shaft and the body move at different speeds, and
the friction curve turns the difference into traction.

`F_z` is the load on the one driven axle, about half the car's weight. `mu_scale` scales the
curve for the road: 1 on a dry road, 0.2 on a slippery one.
"""
component SlipWheel1D
  "Wheel shaft"
  spline = Spline()
  "Contact with the body"
  flange = Flange()
  "Road-friction multiplier"
  mu_scale = RealInput()
  curve = TireFrictionCurve()
  "Wheel rolling radius"
  parameter radius::Length = 0.31
  "Normal load on the driven axle"
  parameter F_z::Force = 6864.655
  "Speed below which slip is measured against v_eps instead of v"
  parameter v_eps::Velocity = 0.5
  "Wheel angular speed"
  variable omega::AngularVelocity
  "Vehicle speed"
  variable v::Velocity
  "Longitudinal slip ratio"
  variable kappa::Real
  "Friction coefficient after road scaling"
  variable mu::Real
  "Longitudinal tire force"
  variable F_x::Force
relations
  omega = der(spline.phi)
  v = der(flange.s)
  # At standstill v = 0 and the slip ratio is undefined; the floor keeps it finite.
  kappa = (omega * radius - v) / max(abs(v), v_eps)
  curve.kappa = kappa
  mu = mu_scale * curve.mu
  F_x = mu * F_z
  # Flow is positive into the component: the tire pushes the body forward with F_x, so the
  # flange reports -F_x, and the shaft feels the matching reaction torque.
  flange.f = -F_x
  0 = spline.tau + radius * flange.f
end
```

:::

3. Look at the **Problems** tab under the editor: nothing should be listed for this file. A red squiggle means the paste was incomplete — select all and paste again.
4. Toggle back to the diagram (⇄). You see three ports and the `curve` block — with no wires to it. That is correct: `curve` is connected by the equations `curve.kappa = kappa` and `mu = mu_scale * curve.mu`, not by `connect`. Both are legal.

#### B · Read the relations

- `omega = der(spline.phi)`, `v = der(flange.s)` — wheel angular speed and car speed, from the two ports.
- `kappa = (omega * radius - v) / max(abs(v), v_eps)` — slip: how much faster the tire surface moves than the car, relative to the car. `v_eps` keeps it finite at standstill, where v = 0.
- `curve.kappa = kappa`, `mu = mu_scale * curve.mu` — look up the friction, scale it for the road.
- `F_x = mu * F_z` — friction times the load on the driven axle, half the car's weight.
- `flange.f = -F_x` — flow is positive *into* a component, so a tire pushing the car forward reports −F<sub>x</sub>. Get this sign wrong and the car drives backward.
- `0 = spline.tau + radius * flange.f` — the same force acts back on the shaft as a torque.

::: tip Checkpoint

The file saves with nothing in **Problems**, and the diagram shows `spline`, `flange`, `mu_scale` and the unwired `curve`. In the reference library the test `TestSlipWheel1D` drives it with full torque for 5 s: on a slippery road (`mu_scale = 0.2`) the slip runs up to 135 and the car makes 3.43 m/s; on a dry road the slip stays at 0.0076 and the car makes 6.86 m/s. Step 10 shows you the same thing in your own car.

:::

Commit: **Source Control** → message `Step 09: slip wheel` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn/SlipWheel1D.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out, and so is the test component. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
A road wheel whose tire grips through slip: the shaft and the body move at different speeds, and
the friction curve turns the difference into traction.

`F_z` is the load on the one driven axle, about half the car's weight. `mu_scale` scales the
curve for the road: 1 on a dry road, 0.2 on a slippery one.
"""
component SlipWheel1D
  "Wheel shaft"
  spline = Spline()
  "Contact with the body"
  flange = Flange()
  "Road-friction multiplier"
  mu_scale = RealInput()
  curve = TireFrictionCurve()
  "Wheel rolling radius"
  parameter radius::Length = 0.31
  "Normal load on the driven axle"
  parameter F_z::Force = 6864.655
  "Speed below which slip is measured against v_eps instead of v"
  parameter v_eps::Velocity = 0.5
  "Wheel angular speed"
  variable omega::AngularVelocity
  "Vehicle speed"
  variable v::Velocity
  "Longitudinal slip ratio"
  variable kappa::Real
  "Friction coefficient after road scaling"
  variable mu::Real
  "Longitudinal tire force"
  variable F_x::Force
relations
  omega = der(spline.phi)
  v = der(flange.s)
  # At standstill v = 0 and the slip ratio is undefined; the floor keeps it finite.
  kappa = (omega * radius - v) / max(abs(v), v_eps)
  curve.kappa = kappa
  mu = mu_scale * curve.mu
  F_x = mu * F_z
  # Flow is positive into the component: the tire pushes the body forward with F_x, so the
  # flange reports -F_x, and the shaft feels the matching reaction torque.
  flange.f = -F_x
  0 = spline.tau + radius * flange.f
end
```

:::

### 10 Standing start on a slippery road <Badge type="info" text="23 min" /> {#standing-start}

Build a car around the slipping wheel and floor it on a slippery road: the wheel spins, the car barely moves.

Theory: [tutor slides — two limits: the engine's and the tire's](../../handson-01/index.html#/two-limits){target="_self"}

#### Where you are, where you are going

This is a new car, not an edit of `Car`. The slipping wheel replaces the rolling wheel that sat inside `Driveline`, so the gear and the wheel inertia are placed directly, and the body is the `GradeBody` of step 07. Two speeds come out: the car's, and the tire surface's. On ice they come apart.

[![SlipCar diagram: engine, gear, wheel inertia and slip wheel drive the grade body, with separate sensors for vehicle speed and wheel surface speed.](/handson/lecture-01/img/step10-standing-start.png){width="1502" height="940"}](/handson/lecture-01/img/step10-standing-start.png)

`SlipCar`: two speed outputs, `v_kmh` from the body and `wheel_kmh` from the wheel shaft. On ice they come apart.

#### A · Create the car and its parameters

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `SlipCar`.

2. Click an empty spot of the canvas and add the five parameters with **Add parameter** — or toggle to code (⇄), paste these lines above `relations`, and toggle back. `r` is used twice (tire and km/h gain) and `m` sets both the body and the axle load: one name each, so they cannot disagree.

   ::: code-group

   ```txt [Parameters]
     "Gear ratio"
     parameter i::Real = 4.0
     "Road wheel and tire inertia"
     parameter J_w::MomentOfInertia = 1.0
     "Wheel rolling radius, shared by the tire and the wheel-speed gain"
     parameter r::Length = 0.31
     "Vehicle mass; the driven axle carries half of it"
     parameter m::Dyad.Mass = 1400
     "Gravitational acceleration"
     parameter g::Acceleration = 9.80665
   ```

   :::

| Name | Type | Value | Meaning |
| --- | --- | --- | --- |
| `i` | `Real` | `4.0` | Gear ratio |
| `J_w` | `MomentOfInertia` | `1.0` | Road wheel and tire inertia |
| `r` | `Length` | `0.31` | Wheel rolling radius, shared by the tire and the wheel-speed gain |
| `m` | `Dyad.Mass` | `1400` | Vehicle mass; the driven axle carries half of it |
| `g` | `Acceleration` | `9.80665` | Gravitational acceleration |

#### B · Place the parts

With **+**, place every row of this table, rename it, and type the values in its panel. *Your* components (`Engine`, `SlipWheel1D`, `GradeBody`) are under `MyCar` at the bottom of the **+** list; the five ports are under `Dyad`. Put the inputs on the left edge of the outline and the two outputs on the right edge.

| Name | Library path | Set |
| --- | --- | --- |
| `tau_cmd, grade, mu_scale` | Dyad › RealInput | ports |
| `v_kmh, wheel_kmh` | Dyad › RealOutput | ports — car speed and wheel surface speed |
| `engine` | your `Engine` | — |
| `gear` | RotationalComponents › Components › IdealGear | `ratio = i` |
| `wheel_inertia` | RotationalComponents › Components › Inertia | `J = J_w` |
| `wheel` | your `SlipWheel1D` | `radius = r`, `F_z = m * g / 2` |
| `body` | your `GradeBody` | `m = m`, `g = g` |
| `vsensor` | TranslationalComponents › Sensors › VelocitySensor | — |
| `to_kmh` | BlockComponents › Math › Gain | `k = 3.6` |
| `wsensor` | RotationalComponents › Sensors › VelocitySensor | — |
| `wheel_to_kmh` | BlockComponents › Math › Gain | `k = r * 3.6` — ω·r in km/h |
| `rot_ground` | RotationalComponents › Components › Fixed | — |

#### C · Wire it

Fifteen wires. Tick them off as you go; the screenshot above shows where they run.

| # | From | To |
| --- | --- | --- |
| 1 | `tau_cmd` | `engine.tau_cmd` |
| 2 | `engine.spline` | `gear.spline_a` |
| 3 | `gear.spline_b` | `wheel_inertia.spline_a` |
| 4 | `wheel_inertia.spline_b` | `wheel.spline` |
| 5 | `engine.support` | `rot_ground` |
| 6 | `gear.support` | `rot_ground` |
| 7 | `wheel.flange` | `body.flange` |
| 8 | `grade` | `body.grade` |
| 9 | `mu_scale` | `wheel.mu_scale` |
| 10 | `vsensor.flange` | `wheel.flange` |
| 11 | `vsensor.v` | `to_kmh.u` |
| 12 | `to_kmh.y` | `v_kmh` |
| 13 | `wsensor.spline` | `wheel.spline` |
| 14 | `wsensor.w` | `wheel_to_kmh.u` |
| 15 | `wheel_to_kmh.y` | `wheel_kmh` |

3. Save. Look at the **Problems** tab under the editor: nothing should be listed for `SlipCar`. If something is, compare your wires with the table.

#### D · The bench

4. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `SlipCarStandingStart`. It is the bench.

5. With **+**, place your `SlipCar` as `car` and three `BlockComponents › Sources › Constant`: `cmd` with `k = 150` (full throttle), `road` with `k = 0` (flat), `friction` with `k = 0.2` (slippery). Wire them:

   | From | To |
   | --- | --- |
   | `cmd.y` | `car.tau_cmd` |
   | `road.y` | `car.grade` |
   | `friction.y` | `car.mu_scale` |

6. Toggle to code (⇄) and add the starting state at the end of `relations` — five lines, because wheel speed is now a state of its own. Save.

   ::: code-group

   ```txt [Starting state]
     initial car.body.mass.s = 0
     initial car.body.mass.v = 0
     initial car.engine.lag.x = 0
     initial car.wheel_inertia.phi = 0
     initial car.wheel_inertia.w = 0
   ```

   :::

#### E · Run and plot

7. <Badge type="tip" text="New analysis" /> With `SlipCarStandingStart` open, press ▷ (**Run Analysis**) in the editor title bar and choose **TransientAnalysis**. It is created with `SlipCarStandingStart` as its model and appears in the **Analyses** panel. Name it `SlipCarStandingStartTransient` — the plot command calls it by that name; if it got another name, change the word after `analysis` in its code — and set `stop` to `5` s.

8. Run it: press ▷ beside `SlipCarStandingStartTransient` in the **Analyses** panel. Then plot both speeds together in the Julia REPL:

   ```julia
   using MyCar, Plots
   r = MyCar.SlipCarStandingStartTransient()
   plot(r; idxs = [r."car.v_kmh", r."car.wheel_kmh"])
   ```

9. Same start on a dry road: in the bench, set `friction`'s `k` to `1.0`, save, run again and re-plot. Or, without touching the model:

   ```julia
   dry = MyCar.SlipCarStandingStartTransient(
       model = MyCar.SlipCarStandingStart(name = :SlipCarStandingStart, friction__k = 1.0))
   plot(dry; idxs = [dry."car.v_kmh", dry."car.wheel_kmh"])
   ```

[![Plot of car.v_kmh and car.wheel_kmh: the wheel surface speed climbs to 1500 km/h in 5 s while the body barely reaches 10 km/h.](/handson/lecture-01/img/step10-standing-start-plot.png){width="990" height="528"}](/handson/lecture-01/img/step10-standing-start-plot.png)

The run: the wheel surface (orange) is past 1500 km/h after 5 s while the car (blue) has reached 10 km/h. Past the peak of the curve, more slip gives less grip, so the wheel runs away.

::: tip Checkpoint

Measured on `HandsOn.SlipCarStandingStartTransient`, friction 0.2: after 1 s the car makes 1.94 km/h while the wheel surface is already at 159.8 km/h; after 5 s the car makes **10.12 km/h** and the wheel surface **1501 km/h**. The model has no rev limit, so the engine keeps delivering 150 N·m into a wheel that has nothing to push against. On the dry road (friction 1.0) the two speeds stay together: 21.08 km/h for the car, 21.24 km/h at the wheel surface after 5 s.

:::

Commit: **Source Control** → message `Step 10: standing start` → **Commit** → **Sync Changes**.

The complete bench and its analysis as code, if anything above went wrong:

::: code-group

```txt [SlipCarStandingStart and SlipCarStandingStartTransient]
component SlipCarStandingStart
  "Full throttle"
  cmd = BlockComponents.Sources.Constant(k = 150)
  "Flat road"
  road = BlockComponents.Sources.Constant(k = 0)
  "Slippery road; 1.0 is dry"
  friction = BlockComponents.Sources.Constant(k = 0.2)
  car = SlipCar()
relations
  connect(cmd.y, car.tau_cmd)
  connect(road.y, car.grade)
  connect(friction.y, car.mu_scale)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
  initial car.wheel_inertia.phi = 0
  initial car.wheel_inertia.w = 0
end

analysis SlipCarStandingStartTransient
  extends TransientAnalysis(stop = 5)
  model = SlipCarStandingStart()
end
```

:::

::: details Stuck? The full model

From `dyad/HandsOn/SlipCar.dyad`, copied from the source, except that each `metadata { … }` block — diagram layout and test cases — is left out. The `{^…}` tags that point into that layout are dropped too; the diagram editor writes its own when you draw. In the reference library these models sit in a sub-library called `HandsOn`; in yours they sit at the top level, and the code is the same.

```
"""
The car with a slipping wheel and a road gradient. Body speed and wheel surface speed are both
reported in km/h, so wheelspin shows as the gap between them.
"""
component SlipCar
  "Commanded engine torque"
  tau_cmd = RealInput()
  "Road gradient, tan(alpha)"
  grade = RealInput()
  "Road-friction multiplier"
  mu_scale = RealInput()
  "Vehicle speed in km/h"
  v_kmh = RealOutput()
  "Wheel surface speed, omega * radius, in km/h"
  wheel_kmh = RealOutput()
  engine = Engine()
  gear = RotationalComponents.Components.IdealGear(ratio = i)
  wheel_inertia = RotationalComponents.Components.Inertia(J = J_w)
  wheel = SlipWheel1D(radius = r, F_z = m * g / 2)
  body = GradeBody(m = m, g = g)
  vsensor = TranslationalComponents.Sensors.VelocitySensor()
  to_kmh = BlockComponents.Math.Gain(k = 3.6)
  wsensor = RotationalComponents.Sensors.VelocitySensor()
  wheel_to_kmh = BlockComponents.Math.Gain(k = r * 3.6)
  "Engine mounts and gearbox housing"
  rot_ground = RotationalComponents.Components.Fixed()
  "Gear ratio"
  parameter i::Real = 4.0
  "Road wheel and tire inertia"
  parameter J_w::MomentOfInertia = 1.0
  "Wheel rolling radius, shared by the tire and the wheel-speed gain"
  parameter r::Length = 0.31
  "Vehicle mass; the driven axle carries half of it"
  parameter m::Dyad.Mass = 1400
  "Gravitational acceleration"
  parameter g::Acceleration = 9.80665
relations
  connect(tau_cmd, engine.tau_cmd)
  connect(engine.spline, gear.spline_a)
  connect(gear.spline_b, wheel_inertia.spline_a)
  connect(wheel_inertia.spline_b, wheel.spline)
  connect(engine.support, rot_ground.spline)
  connect(gear.support, rot_ground.spline)
  connect(wheel.flange, body.flange)
  connect(grade, body.grade)
  connect(mu_scale, wheel.mu_scale)
  connect(vsensor.flange, wheel.flange)
  connect(vsensor.v, to_kmh.u)
  connect(to_kmh.y, v_kmh)
  connect(wsensor.spline, wheel.spline)
  connect(wsensor.w, wheel_to_kmh.u)
  connect(wheel_to_kmh.y, wheel_kmh)
end

"""Full throttle from rest on a slippery flat road: the wheel spins up, the car barely moves."""
component SlipCarStandingStart
  "Full throttle"
  cmd = BlockComponents.Sources.Constant(k = 150)
  "Flat road"
  road = BlockComponents.Sources.Constant(k = 0)
  "Slippery road; 1.0 is dry"
  friction = BlockComponents.Sources.Constant(k = 0.2)
  car = SlipCar()
relations
  connect(cmd.y, car.tau_cmd)
  connect(road.y, car.grade)
  connect(friction.y, car.mu_scale)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
  initial car.wheel_inertia.phi = 0
  initial car.wheel_inertia.w = 0
end

analysis SlipCarStandingStartTransient
  extends TransientAnalysis(stop = 5)
  model = SlipCarStandingStart()
end
```

:::

### Hand in: open a pull request <Badge type="info" text="5 min" /> {#hand-in}

A pull request that asks to merge `handson-01` into `main`: your work, ready to be reviewed.

#### Do this

1. In **Source Control**, check there is nothing left to commit and that **Sync Changes** shows no pending uploads.
2. Open your `MyCar` repository on github.com. A yellow bar says `handson-01` had recent pushes: click **Compare & pull request**. (No bar? **Pull requests** → **New pull request**, base `main`, compare `handson-01`.)
3. Title: `Lecture 1 hands-on`. In the description, write which steps you finished, the checkpoint numbers you got, and anything that did not match.
4. Click **Create pull request**. Do *not* merge it: it is reviewed first, and review comments appear on it.

::: tip Checkpoint

The pull request is open on github.com and its **Commits** tab lists your step commits, one per step.

:::

To answer a review comment, change the model, commit and sync again on the same branch: the new commit appears in the same pull request.

---

Reference models: `dyad/HandsOn/` in the course repository. Design notes: `docs/superpowers/specs/2026-10-02-lecture-01-handson-design.md`.
