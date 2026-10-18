---
title: Lecture 1 hands-on — build the car
---

[← Vehicle Systems & Components](../../index.html) · [Projector deck →](../../handson-01/index.html){target="_self"}

# Lecture 1 hands-on: build the car

From a first look at Dyad Studio to a car spinning its wheel on a slippery road

**Why we build it.** A cruise control has to know how the car reacts before it can drive it: how late the engine answers, how hard the air pushes back, when the wheels spin. So before the next lecture designs a controller, you build the car. **What you build:** a pedal command into an engine, through a gear and wheel, pushing a car body, read by a speedometer — then a tire that can slip. By the end your car reaches 246 km/h flat out on a dry road, and barely 10 km/h after 5 s on snow with its wheel spinning.

![The car as a chain of four parts: the pedal command goes into the engine, the engine's shaft into the gear and wheel, the wheel pushes the body along the road, and a speedometer reads the body's speed in km/h. Each part is labeled with the hands-on step that builds it.](/handson/lecture-01/img/car-chain.svg){style="background:#fff;padding:8px;border-radius:4px"}

**How each step works.** It starts with the idea it needs, in a short **Why** box; the *Details* boxes hold the derivations, for when you want them. Each build opens with a picture of the finished model, so you know where you are going. Then you build, and the checkpoint is a number you could have predicted first: where your run agrees, your model is right. **After this session:** [Lecture 1](../../lecture-01/index.html){target="_self"} puts this car under P, PI and PID control.

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

Why we build the car, what the tool is, where its controls are · 48 min

### What you are looking at <Badge type="info" text="15 min" /> {#ui}

Dyad Studio is a VS Code extension: you draw or write models in the Dyad language, and it compiles them to Julia and simulates them.

#### Three ideas

- **A library is a folder.** Your models live as `.dyad` files under `dyad/`. The extension compiles them into Julia under `generated/` — never edit that folder by hand; it is rewritten on every compile. The folder is also a Julia package, so `using MyCar` loads your models in a Julia REPL.
- **A component is a model; an analysis is an experiment on one.** A component says what the system is — parts, wires, equations. An analysis says what to do with it — for example simulate for 300 s. You can only simulate a component whose inputs are all driven, so every experiment gets a small test bench component around the thing you built.
- **Diagram and code are the same file.** Every block you place is a line of code, every wire a `connect`. Step 01 shows it.

::: info Why parts, not arrows: acausal modeling

In a block diagram (Simulink, most control tools) every wire is an arrow: *speed in, force out*, and you decide what is computed from what. Physics does not work that way: a damper relates force and speed, whichever side drives it. In Dyad (and Modelica) each part states its physics as **equations**, and joining two parts adds more: at every mechanical joint the **speeds are equal** and the **forces add up to zero**. Dyad works out the direction for each model you build. Signals such as the torque command and the km/h readout still have arrows; a model mixes both kinds.

:::

::: details What Dyad does when you press ▷

1. **Collect equations:** every part's own, plus two for every joint.
2. **Check equations = unknowns.** A model that is not balanced does not compile. An input nobody drives is one unknown too many, which is why every experiment needs a test bench; a part not tied to ground is the other usual cause.
3. **Simplify.** Symbolic algebra removes trivial equations and solves for the derivatives, leaving differential equations in the states only: *ẋ = f(x, u, t)*, how fast the state changes depends on the state, the input and the time.
4. **Solve in time.** A solver steps forward from the start state, *x(t + Δt) ≈ x(t) + Δt·f(x, u, t)*, and picks Δt itself: small where things change fast.

The car body of step 04: unknowns *v*, *F*<sub>drag</sub>, *F*<sub>roll</sub>; equations *F*<sub>drag</sub> = 0.378·*v*², *F*<sub>roll</sub> = 165 N and 1400·*v̇* = *F* − *F*<sub>drag</sub> − *F*<sub>roll</sub>. Three and three; simplified, one state: *v̇* = (*F* − 0.378·*v*² − 165) / 1400.

:::

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

#### Parts

| Name | Library path | Set |
| --- | --- | --- |
| `delay` | BlockComponents › Nonlinear › PadeDelay | `n = 6`, `m = 5`, `delayTime = 0.3` |
| `lag` | BlockComponents › Continuous › FirstOrder | `T = 0.3` |

#### What you are building

[![Tour in Dyad Studio: delay and lag wired in the diagram with the delay parameter panel open, and the same component in the code view.](/handson/lecture-01/img/step01-engine-two-views.png){width="1419" height="828"}](/handson/lecture-01/img/step01-engine-two-views.png)

Same model, two views: each block in the diagram is one line under `component`, the wire is the one `connect` under `relations`, and the values in the parameter panel are the arguments in parentheses.

`delay` holds a signal back: what goes in comes out 0.3 s later. `lag` follows its input smoothly instead of jumping. Together they are the front half of the engine; step 02 explains them. Here only the clicking matters.

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

The `{^delay}` tags and the `metadata` block at the end of the code are where the diagram keeps positions and wire routes: leave them alone.

::: info Why two kinds of wire

The wire you drew is a **signal**: one number, one way, like an arrow — `delay` works it out, `lag` reads it. Today's signals are the torque you ask for, the km/h on the speedometer and how slippery the road is.

A **mechanical joint** has no arrow: two parts bolted together. Dyad then knows two facts: they **move together** (same position, same speed), and they **push each other equally** (the forces add up to zero). A sliding port (`Flange`) carries position *s* and force *f*; a turning port (`Spline`) angle *φ* and torque *τ*. The one that is equal at both ends is the *potential*, the one that sums to zero the *flow*, like voltage and current in a circuit. So you never decide which part drives which: you draw the car the way it is put together.

In Studio the port's shape tells the kind: triangles are signals, gray circles turning shafts, green squares sliding parts. You can only wire like to like.

:::

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

#### Where you are, where you are going

Step 01 left you a component called `Engine` holding two blocks, `delay → lag`. This step turns it into the engine below by adding four things to that same component: three **parameters**, two more **parts** (a limiter and a torque source), and three **ports** so other components can plug into it. Then a small test bench drives it.

[![The finished Engine diagram: tau_cmd input on the left, then delay, lag, limiter and torque blocks in a row, the spline port on the right and the support port at the bottom; the Engine panel at top right lists the parameters theta_e, tau_e and T_max above an Add parameter button.](/handson/lecture-01/img/step02-engine-finished.png){style="max-width:560px" width="903" height="897"}](/handson/lecture-01/img/step02-engine-finished.png)

The finished `Engine`: `tau_cmd` → `delay` → `lag` → `limiter` → `torque` → `spline`, with `torque`'s support down to `support`. The two blocks you already have are the second and third. Top right is `Engine`'s own panel — click an empty spot of the canvas to open it — with the three parameters of stage B and the **Add parameter** button.

::: info Why the engine is late, slow and limited

Press the pedal, and the torque comes in three stages, one block each: {#pedal}

1. **Late** (`delay`, θ<sub>e</sub> = 0.3 s): for 0.3 s nothing happens. The engine computer reacts, fuel is measured out, a cylinder fires, the shafts twist up; 0.3 s lumps that whole chain into one number.
2. **Slow** (`lag`, τ<sub>e</sub> = 0.3 s): then the torque grows, quickly at first and then more gently, as the intake manifold fills with air.
3. **Limited** (`limiter`): never above 150 N·m, this engine's peak, and never below 0: it cannot brake.

A fourth block, the torque source, turns the number into a real twist on the shaft. You can tell delay and lag apart on a plot: the delay is flat, nothing happens; the lag starts at once, but gradually.

![Torque against time. The request jumps from 0 to 200 newton-meters at 0.5 seconds. The delivered torque stays at zero until 0.8 seconds, then rises along a curve, and is cut flat at 150 newton-meters from about 1.22 seconds.](/handson/lecture-01/img/step02-pedal-response.svg){style="background:#fff;padding:8px;border-radius:4px"}

The **lag** in words: the torque moves toward the request, and the bigger the gap, the faster it moves, τ<sub>e</sub>·d*T*/d*t* = *T*<sub>req</sub> − *T*. A gap that shrinks in proportion to itself shrinks exponentially, *T*(*t*) = *T*<sub>req</sub>(1 − e<sup>−*t*/τ<sub>e</sub></sup>): after one time constant it has covered **63 %** of the way, after two 86 %, after three 95 %. The time constant is not how long it takes to get there; it never strictly arrives. The car itself will turn out to be a lag too, with a time constant of about a minute.

:::

::: details Details: the plot of stage E, worked out before you make it

Request 200 N·m at 0.5 s; delay 0.3 s, lag 0.3 s, ceiling 150 N·m.

- **When it starts:** 0.5 + 0.3 = **0.8 s**; nothing before.
- **At 1.0 s:** the lag has run 0.2 s. 200 × (1 − e<sup>−0.2/0.3</sup>) = 200 × (1 − 0.513) = **97 N·m**. The lag aims at the full 200; the limiter only cuts the result afterwards.
- **When it hits 150:** 200 × (1 − e<sup>−*t*′/0.3</sup>) = 150, so e<sup>−*t*′/0.3</sup> = 0.25 and *t*′ = 0.3 × ln 4 = 0.42 s after the start: **1.22 s**.
- **The lag's solution:** call the gap *g* = *T*<sub>req</sub> − *T*. Then τ<sub>e</sub>·d*g*/d*t* = −*g*, whose solution is *g*(*t*) = *g*(0)·e<sup>−*t*/τ<sub>e</sub></sup>. 1 − e<sup>−1</sup> = 0.632, 1 − e<sup>−2</sup> = 0.865, 1 − e<sup>−3</sup> = 0.950.

Your plot shows 97.5 N·m at 1.0 s and a little wiggle before 0.8 s: the delay is an approximation (stage E). Within about 1 N·m is a match.

:::

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

::: info Why a support port: every force needs a reaction

An engine twists its shaft — and twists its mounts the other way, like a drill trying to spin in your hand. A wheel pushes the car forward and the road backward: Newton's third law. In Dyad that other side is a `support` port, and it must end at a `Fixed` block, the ground or the car's frame. Leave it open, and Dyad calls the system *unbalanced*: a force with nowhere to go. The engine needs fixed mounts here; step 03 brings the gear's and wheel's supports out, step 05 grounds them.

The **sign rule**: a force counts as positive when it flows *into* a part. So a tire pushing the car forward shows up as a *negative* force at its port; step 09 writes it.

:::

#### D · A test bench

An engine with an unconnected input cannot be simulated — nobody has said what the torque command is. So it gets a bench: a source for the command, a load on the shaft, and something for the mounts to push against.

::: info Why an inertia, and why initial values

The engine's torque must act on something: on a bare shaft it has nowhere to go and the model cannot be solved. An **inertia** is a spinning mass that resists changes in rotation, *T* = *J*·d*ω*/d*t*; with *J* = 1 kg·m² its angular acceleration in rad/s² equals the delivered torque in N·m.

The solver steps forward from a known start, so every state needs a value at *t* = 0: here the lag's output and the shaft's angle and speed. All zero means no torque, not turning. Change them and the same model starts elsewhere — a car already at 90 km/h, say. The starting state has no diagram form, so it is written in code.

:::

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
    using Plots
    r = MyCar.EngineStepTransient()
    plot(r; idxs = r."engine.limiter.y")
    ```

    The same pattern plots several signals, `idxs = [r."a", r."b"]`, or one against another, `idxs = (r."x", r."y")`.

[![Plot of engine.limiter.y: zero until 0.5 s, a 0.3 s dead time with small ripples, then a rise that is clipped flat at 150 N·m from about 1.2 s.](/handson/lecture-01/img/step02-engine-step-plot.png){width="990" height="528"}](/handson/lecture-01/img/step02-engine-step-plot.png)

The run: 200 N·m is asked for at 0.5 s. Nothing arrives for the 0.3 s dead time (the small wiggles are the Padé approximation), the lag shapes the rise, and the limiter clips it at 150 N·m.

::: info Why the wiggles: the delay is a stand-in

A true delay must remember the whole last 0.3 s of its input, to replay it later. A simulator only tracks a handful of numbers that change smoothly. So Dyad uses a stand-in, `PadeDelay`: six such numbers, tuned to behave almost exactly like a 0.3 s delay. The tiny wiggles before 0.8 s come from the stand-in, not from the engine. Those six helper numbers are also what a plain `plot` draws: they swing into the thousands and hide the torque.

`theta_e` is **structural** because the block computes its coefficients from the delay when the model is compiled: a new delay is a new model, not just a new number. With `m = n − 1` a sudden step cannot leak through before the delay has elapsed.

:::

::: tip Checkpoint

Measured on `HandsOn.EngineStepTransient`:

- `engine.limiter.y` stays at 0 through the step at 0.5 s, reads only 6.2 N·m at 0.8 s, 97.5 N·m at 1.0 s, clips at **150 N·m at 1.22 s** and stays there.
- `engine.delay.y` reads 208.1 at 0.9 s before settling at 200: the Padé approximation of the delay overshoots. The limiter hides it.
- `load.w` ends at 306.0 rad/s at 3 s.

:::

Commit: **Source Control** → message `Step 02: engine` → **Commit** → **Sync Changes**.

::: info Why keep the delay and the lag at all

For "how fast is it flat out?" the delay barely matters. For "how should a cruise control react?" it matters a lot: a model is good enough when it keeps the effects that matter for your question. Without the delay and the lag the torque appears the instant you ask for it, and the car becomes too easy to control — any controller works, real cars are not like that, and the two tuning recipes of the next lecture, Ziegler–Nichols and Cohen–Coon, cannot be used: one needs the car to swing back and forth under control, the other divides by the delay.

:::

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

::: info Why F = T · i / r: from a twist to a push

Two steps, and you have felt both. **The gear multiplies the twist:** the engine turns *i* = 4 times for every turn of the wheel, like a low bicycle gear, so the wheel gets 4 × the torque and turns 4 × slower. **The wheel turns the twist into a push:** torque is force times lever arm, and at the road the lever arm is the radius *r*, so *F* = *T*<sub>wheel</sub> / *r*. Together:

*F* = *T* · *i* / *r*: 100 N·m × 4 / 0.31 m = **1290 N**, which on 1400 kg and nothing else gives **0.92 m/s²**; flat out, 150 N·m gives **1935 N** — almost 2 kN, the weight of 200 kg, from a "weak" 150 N·m engine.

**Speeds go the other way:** wheel speed = *v* / *r*, engine speed = *i* × that. At 90 km/h, 25 m/s / 0.31 × 4 = 323 rad/s = **3080 rpm**.

The wheel here *rolls without sliding*. Steps 08–10 break that.

:::

::: details Details: why the gear multiplies the torque

An ideal gear loses no energy, so power in = power out: *T*·ω<sub>engine</sub> = *T*<sub>wheel</sub>·ω<sub>wheel</sub>. With ω<sub>engine</sub> = *i*·ω<sub>wheel</sub> that gives *T*<sub>wheel</sub> = *i*·*T*. To rpm: rad/s × 60 / 2π; one turn is 2π ≈ 6.28 rad.

:::

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

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Driveline`. It opens as an empty diagram.

2. Add the two parameters. Click an empty spot of the canvas and use **Add parameter** in the component panel for each row of the parameters table, or toggle to code (⇄) and paste them above `relations`:

   ::: code-group

   ```txt [Parameters]
     "Gear ratio"
     parameter i::Real = 4.0
     "Wheel rolling radius"
     parameter r::Length = 0.31
   ```

   :::

   Then give the parts the *names*, not the numbers — the parts table shows which.

3. Place `gear` and `wheel` and wire `gear.spline_b → wheel.spline`.

4. Add the four ports. Wire `spline → gear.spline_a` and `wheel.flange → flange`.

5. Both reaction paths go out of the component: wire `gear.support` and `wheel.support_r` to `support_r`, and `wheel.support_t` to `support_t`. The car will ground them.

6. Set `ratio = i` and `radius = r`. The force at the flange is then `T · i / r`, the formula of the Why box at the start of this step.

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

::: info Why these forces: four on the car

![A car on an inclined road with the forces acting on it drawn as labeled arrows: tractive force up the slope at the driven wheel, aerodynamic drag and rolling resistance down the slope, and the weight resolved into a component along the slope and one into the road surface.](/handson/lecture-01/img/step04-four-forces.svg){style="background:#fff;padding:8px;border-radius:4px"}

- **The push from the wheels**, step 03's *T*·*i*/*r*: the only force we control.
- **Air drag**: the car pushing air out of the way; small at low speed, large at high speed.
- **Rolling resistance**: the tires squash and spring back on every turn and lose a little energy each time; about the same at any speed.
- **The slope**: part of the car's own weight pulls it back down a hill. Zero on a flat road; step 07 adds it.

The push minus the three resistances is what speeds the car up. The course lectures call them *O*<sub>V</sub> (air), *O*<sub>f</sub> (rolling), *O*<sub>s</sub> (slope) and *O*<sub>z</sub> (speeding up); they also list *O*<sub>aux</sub>, power for electrical equipment, which this model leaves out. The slope in the picture is drawn steeper than a real road, so the arrows are readable.

:::

::: info Why drag grows with speed squared

Speed enters twice. **How much air:** each second the car's front, area *A*, moves *v* meters and pushes away the air in front of it: twice as fast, twice the air. **How hard:** each kilogram of that air is pushed to roughly the car's speed: twice as fast, twice as hard. So drag goes as ρ·*A*·*v* × *v* = ρ·*A*·*v*², and doubling the speed gives **4 ×** the drag. The measured shape factor *C*<sub>d</sub> and the ½ account for air that flows around the car instead of being carried along:

*F*<sub>drag</sub> = ½ ρ *C*<sub>d</sub>*A* *v*² = ½ × 1.2 × 0.63 × *v*² = **0.378 · *v*²**

| speed | m/s | drag |
| --- | --: | --: |
| 30 km/h | 8.3 | 26 N |
| 90 km/h | 25.0 | 236 N |
| 130 km/h | 36.1 | 493 N |

Because of the square, the car behaves differently at different speeds: a controller tuned at 90 km/h is tuned for 90 km/h only.

:::

::: info Why rolling resistance is a constant, and a signal

**Rolling resistance** is a fixed share of the weight pressing on the tires: *F*<sub>roll</sub> = *f*<sub>r</sub>·*m*·*g* = 0.012 × 1400 × 9.81 = **164.8 N**, at any speed. At 90 km/h drag is the bigger one, 236 against 165; at 30 km/h it flips, 26 against 165.

`RollingResistance` takes the weight *m*·*g* as a **parameter**, a number fixed before the run starts, and the coefficient and the road slope as **signals**, values that arrive through a wire and may change during the run — so a hill can appear halfway through a drive (step 07).

:::

::: details Details: the 500 N check, and why v_nominal does not matter

**Push the body with a constant 500 N.** At the start nothing holds it back yet: 500 / 1400 = **0.357 m/s²**. It speeds up until drag + rolling = 500 N: 0.378·*v*² + 164.8 = 500, so *v*² = 335.2 / 0.378 = 886.8 and *v* = **29.78 m/s**, about 107 km/h. The reference test `TestBody` checks both. (The model uses *g* = 9.80665, which gives 164.75 N; it does not show in any result.)

**The drag block** is a general block for any force that grows with speed squared, and knows it as one point on its curve: force `f_nominal` at speed `v_nominal`. It computes *f* = −*f*<sub>nominal</sub>·*v*·|*v*| / *v*<sub>nominal</sub>². With *f*<sub>nominal</sub> = −½ρ*C*<sub>d</sub>*A*·*v*<sub>nominal</sub>², *v*<sub>nominal</sub> cancels and leaves ½ρ*C*<sub>d</sub>*A*·*v*·|*v*|: any value gives the same drag, 30 m/s (340.2 N) is just a reference. It must not be zero: the block divides by it.

:::

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

5. Set the drag parameters. `f_nominal` is negative, which makes the source a load; `ForceDirection = false` makes drag oppose motion both ways. `-0.5 * rho * CdA * v_nominal ^ 2` is ½ρ·C<sub>d</sub>A·v² at the nominal speed, written in the parameters' names. A positive `f_nominal` makes drag push the car forward: if your car in step 05 runs away to absurd speeds, check this sign first.

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

::: info Why one equation describes the whole car: the force balance

Newton's second law, mass × acceleration = the sum of all forces:

*m*·d*v*/d*t* = *T*·*i*/*r* − ½ρ*C*<sub>d</sub>*A*·*v*² − *f*<sub>r</sub>·*m*·*g*·cos α − *m*·*g*·sin α

Read it as a budget: the push comes in, air, tires and slope take their share, and **what is left speeds the car up**; if nothing is left, the speed is steady. *T* is the torque the engine actually delivers, after its delay, lag and ceiling, not what the driver asks for. On a flat road cos α = 1 and sin α = 0. Because of the *v*², the car is *nonlinear*: doubling the push does not double the speed. You do not type this equation: you join the parts on one mechanical joint, and the rule of step 01 — forces add up to zero — writes it for you.

The whole car is **nine numbers**: in `Engine` *T*<sub>max</sub> = 150 N·m, τ<sub>e</sub> = 0.3 s, θ<sub>e</sub> = 0.3 s; in `Driveline` *i* = 4.0, *r* = 0.31 m; in `Body` *m* = 1400 kg, *C*<sub>d</sub>*A* = 0.63 m², ρ = 1.2 kg/m³, *f*<sub>r</sub> = 0.012. Every number in this hands-on and in the next lecture comes from these nine, by arithmetic you can check. (`g` and `v_nominal` are in `Body` too, but they do not describe this car.)

:::

::: info Why 246 km/h: when the push runs out

At top speed the car no longer speeds up, d*v*/d*t* = 0, and on a flat road the balance becomes **push = air + tires**: {#top-speed}

1. The most push: 150 × 4 / 0.31 = **1935 N**.
2. The tires take 165 N; 1935 − 165 = 1770 N is left for the air.
3. 0.378·*v*² = 1770, so *v*² = 4683 and *v* = 68.4 m/s × 3.6 = **246 km/h**.

The same idea holds a speed: push = air + tires, then back to engine torque, *T* = *F*·*r*/*i*.

| hold | air | + tires | = push | torque |
| --- | --: | --: | --: | --: |
| 90 km/h | 236 | 165 | 401 N | **31.1 N·m** |
| 110 km/h | 353 | 165 | 518 N | **40.1 N·m** |

The next lecture opens with these two: its controller has to find them on its own. Setting d*v*/d*t* = 0 gives the *steady state*, where the car ends up; it says nothing about how long it takes.

:::

::: info Why it takes so long: the car is a lag, with a time constant of a minute

Near any speed the car behaves like step 02's lag: a little too fast, and drag grows a little and pulls it back. How hard it pulls back sets its time constant: {#time-constant}

τ<sub>car</sub> = *m* / (extra drag per extra m/s) = *m* / (2 × 0.378 × *v*)

At 100 km/h (27.8 m/s) drag is 0.378 × 27.8² = 292 N; 1 m/s faster it is 313 N, about **21 N** more. So τ = 1400 / 21 = **67 s**: some 200 times slower than the engine's 0.3 s. The car, not the engine, sets how slowly the speed changes. Drag is stronger at high speed, so the car settles quicker there: 74 s at 90 km/h, 61 s at 110.

From the reference run: **23.6 s** to 100 km/h, **143 s** to 99 % of the top speed, **246.39 km/h** at 300 s. There is no neat hand formula for these, because the time constant changes with speed. **So run for 300 s:** stop sooner and the car is still on its way up, and 246 looks wrong.

:::

::: details Details: the time constant derived

Suppose the car is near speed *v* and goes Δ*v* faster. Drag grows from 0.378·*v*² to about 0.378·*v*² + 2·0.378·*v*·Δ*v* (the slope of *v*² is 2*v*). That extra drag slows the car: *m*·dΔ*v*/d*t* = −2·0.378·*v*·Δ*v*. This is step 02's lag equation, τ·dΔ*v*/d*t* = −Δ*v*, with τ = *m* / (2·0.378·*v*). At 27.8 m/s: 2 × 0.378 × 27.8 = 21.0, and 1400 / 21.0 = 66.7 s.

:::

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
   using Plots
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

A different number? Check in this order: speed climbing far past 246 → the sign of `f_nominal` in `Body`; a different final speed → `i = 4` and `r = 0.31` in `Driveline`; still different → `T_max = 150` in `Engine`; still rising at the right edge → `stop` is not 300.

Commit: **Source Control** → message `Step 05: car` → **Commit** → **Sync Changes**.

::: info Why 246 km/h is still wrong

Your car reached the 246 km/h worked out on paper, and that number is wrong for a real car. Our engine gives 150 N·m at every engine speed; a real one gives its best only in the middle of its rev range. At 246 km/h the engine would turn at **8430 rpm** (step 03: *v* / *r* × *i* × 60 / 2π), where a real one gives much less, so the real top speed is lower. Between 90 km/h (3080 rpm) and 130 km/h (4450 rpm), where the next lecture drives, the two agree, and there the model is good. A model contains only what you put into it. Fixing the top end means a torque curve: the Lecture 2 hands-on.

![Engine torque against crankshaft speed. A flat line at 150 newton-meters across the whole range is our model; a curve that rises, plateaus and falls away is the shape of a real engine. The band where the PID lecture operates is shaded, and the crankshaft speed implied by 246 km/h is marked well past the real curve's peak.](/handson/lecture-01/img/step05-torque-curve.svg){style="background:#fff;padding:8px;border-radius:4px"}

Blue: exactly what our engine block computes. Red: the usual *shape* of a petrol engine, drawn for comparison, not measured.

:::

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

::: info Why so little: the wheel's hidden mass

To speed up the car, the engine must also spin up the wheels, which costs energy as if the car were a little heavier. A wheel of inertia *J* spinning at ω = *v* / *r* holds ½*J*ω² = ½(*J*/*r*²)*v*²: exactly the energy of a mass **J / r²** moving at *v*. {#hidden-mass}

For *J* = 1 kg·m² (a road wheel with its tire, about 20 kg mostly 0.2–0.3 m from the center): 1 / 0.31² ≈ **10 kg** on a 1400 kg car, 0.7 % heavier. The time to 100 km/h grows with the mass, 23.6 s × 1.0074 ≈ **23.8 s**. At a steady speed nothing speeds up, so the top speed does not change: like a bicycle with heavy wheels, slow to start, fine once rolling.

Not every added detail matters, and part of modeling is knowing which. But the wheel now has a spin of its own, and in step 09 that is what lets it slip.

:::

::: details Details: the hidden mass derived

The car's moving energy is ½·*m*·*v*², a wheel's spinning energy ½*J*ω². The wheel rolls, so ω = *v* / *r*, and the total is ½(*m* + *J*/*r*²)*v*². The engine supplies it, so the car behaves as if its mass were *m* + *J*/*r*² = 1400 + 10.4 kg. Parts on the engine side, such as a flywheel, turn *i* = 4 times faster and count *i*² = 16 times more, *J*<sub>e</sub>·*i*²/*r*²; this model leaves them out.

:::

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
   using Plots
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

::: info Why an equation: part of the weight pulls back

On a flat road the weight presses straight into the road. Tilt the road by α, and the weight *m*·*g* splits in two: **along the road**, *m*·*g*·sin α, pulling the car back; **into the road**, *m*·*g*·cos α, pressing the tires down. {#slope}

![A car on a road tilted by angle alpha. Its weight m g points straight down and splits into m g sine alpha along the road, pointing downhill, and m g cosine alpha into the road. A right triangle under the road shows rise over run, which is tangent alpha.](/handson/lecture-01/img/step07-slope.svg){style="background:#fff;padding:8px;border-radius:4px;max-width:420px"}

A road sign's **10 %** means rise ÷ run: 10 m up for every 100 m across. Rise ÷ run is **tan α**, so α = arctan 0.10 = 5.7° (the picture exaggerates it to 30°), and

*F*<sub>slope</sub> = *m*·*g*·sin(arctan 0.10) = 1400 × 9.81 × 0.0995 = **1366 N**

For small slopes sin α ≈ tan α (0.0995 against 0.100); the exact formula keeps the model right on any slope. Compare with the engine: flat out it pushes 1935 N. At 130 km/h up 10 % the car needs 1366 + 493 drag + 164 rolling = **2023 N**, more than 1935: it cannot hold 130 km/h there. The next lecture's windup section uses this hill. No library part turns a slope into a force, so this is your first equation.

:::

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
2. Write the one equation below. `grade` is tan α, the same convention `RollingResistance` uses for its `inclination`, so one signal can drive both: a 10 % grade is `grade = 0.10`, not α = 0.10. There is no minus sign: a force source acts on the body with −`f`, so a climb needs a positive `f` to hold the car back.
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

::: details Details: what `extends` brings, and how to see it all

`extends X` copies everything `X` declares — ports, variables, equations — into your component, and each level adds a little:

1. `PartialElementaryOneFlangeAndSupport2`: the ports `flange` and `support`, *s* = `flange.s` − `support.s`, and the push-back `support.f = -flange.f`.
2. `PartialForce`: a variable `f`, with `f = flange.f`. Its one gap: what `f` is.
3. Your `GradeForce` fills the gap with one equation.

Flattened, that is:

```
component GradeForce
  flange = Flange()       # from …Support2
  support = Flange()      # from …Support2
  grade = RealInput()
  variable s::Length      # from …Support2
  variable f::Dyad.Force  # from PartialForce
  parameter m::Dyad.Mass = 1400
  parameter g::Acceleration = 9.80665
relations
  s = flange.s - support.s      # …Support2
  support.f = -flange.f         # …Support2
  f = flange.f                  # PartialForce
  f = m * g * sin(atan(grade))  # yours
end
```

In the code view, click **Flatten Component** above the `component` line to see this for any model; Studio may format it differently. Dyad needs exactly one equation per unknown, and this is the list it counts. Every analysis works the same way: `extends TransientAnalysis(stop = 300)` inherits the solver set-up, and you set only what differs.

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

::: info Why slip: until now the wheel could not

Steps 03–07 use an `IdealRollingWheel`: one turn of the wheel always moves the car exactly one circumference, so wheel and car can never disagree. On a dry road that is nearly true — a driven tire slips by about one percent, and the top speed does not care. On snow or ice it is not true at all: the wheel can spin much faster than the car moves. Steps 08–10 are about that difference.

**Slip** κ is how much faster the tire surface moves than the car, as a share of the car's speed: {#slip-and-grip}

κ = (ω·*r* − *v*) / *v*

A car at 10 m/s with its tire surface at 10.4 m/s has κ = 0.4 / 10 = 0.04: 4 % slip. **Grip** μ is the share of the load on the tire, *F*<sub>z</sub>, that it can turn into a push: *F*<sub>x</sub> = μ(κ)·*F*<sub>z</sub>.

A tire grips by slipping a little as the tread stretches: more slip, more grip, up to a **peak** of μ = 1.0 at 4 % slip. Past it the rubber slides instead of stretching, and sliding grips worse than sticking — like a heavy box, hard to get moving, easier once it slides — so grip falls to 0.7. Braking makes κ negative, and the curve is mirrored: that side is where anti-lock brakes work.

![Friction coefficient against slip ratio from 0 to 0.3. The dry-road curve rises steeply to a peak of 1.0 at slip 0.04, then falls to a plateau of 0.7 beyond 0.12. A snow curve is the same shape at one fifth the height, peaking at 0.2. A dashed line at 0.28 marks the most the engine can ask for: below the whole dry curve, above the whole snow curve.](/handson/lecture-01/img/step08-slip-grip.svg){style="background:#fff;padding:8px;border-radius:4px"}

**Normal driving is the rising part.** The model drives one axle carrying half the car, *F*<sub>z</sub> = 1400 × 9.81 / 2 = 6865 N. Cruising at 100 km/h needs 292 + 165 = 457 N, μ = 0.07, a slip of about 0.2 %. Even flat out, 1935 N is μ = 0.28 at under 1 % slip. The peak is reached only when a wheel starts to spin or lock. On snow every height is × 0.2: the dashed line, the most the engine can ask for, lies under the whole dry curve and over the whole snow curve. Step 10 comes back to it.

:::

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

::: details Details: how the curve is built, and other tire models

One building block, an S-shaped cubic, *h*(*x*) = 1.5·*x* − 0.5·*x*³. It goes from −1 to 1 as *x* goes from −1 to 1, and its slope, 1.5 − 1.5·*x*², is zero at both ends, so pieces built from it join without corners. A corner would make the slope jump, and the solver, which picks its step from how fast things change, would need tiny steps or fail one.

![The dry tire curve split into three pieces: a rising S-curve from slip 0 to 0.04 reaching 1.0, a falling S-curve from 0.04 to 0.12 down to 0.7, and a flat line at 0.7 beyond 0.12.](/handson/lecture-01/img/step08-three-pieces.svg){style="background:#fff;padding:8px;border-radius:4px"}

1. **Rise**, κ from 0 to 0.04: μ = μ<sub>A</sub>·*h*(κ / 0.04), flat on top exactly at the peak. At κ = 0.02, *h*(0.5) = 0.6875, so μ ≈ 0.69.
2. **Fall**, 0.04 to 0.12: *x* = (κ − 0.08)·2 / 0.08 runs from −1 to 1, and μ = (μ<sub>A</sub> + μ<sub>S</sub>)/2 + (μ<sub>S</sub> − μ<sub>A</sub>)/2·*h*(*x*) = 0.85 − 0.15·*h*(*x*): 1.0, then 0.85 halfway, then 0.7. The reference test checks the midpoint.
3. **Slide**, beyond 0.12: μ = 0.7.

Ours is the simplest model that still has a peak and a slide. Others: **linear**, μ = *C*·κ, fine for small slip but with no peak, so it can never show wheelspin running away; **Pacejka's Magic Formula**, *F* = *D*·sin(*C*·arctan(*B*κ − *E*(*B*κ − arctan *B*κ))), fitted to test-rig data and the industry standard; **brush** models, the tread as elastic bristles that stick, then slide; **dynamic** models such as LuGre, friction with its own state, for effects like the rolling distance a tire needs before its force builds up.

:::

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
   using Plots
   r = MyCar.TireFrictionCurveSweep()
   plot(r; idxs = (r."curve.kappa", r."curve.mu"))
   ```

::: tip Checkpoint

The curve is point-symmetric: −0.7 for a wheel locked under braking (κ = −1), −0.85 at κ = −0.08, the peak of 1.0 at κ = 0.04, and 0.7 at κ = 1. These are the values `TestTireFrictionCurve` asserts. The axis runs from −1 to +1, so the peaks sit in a narrow spike near zero: that is correct. A plot against time means the round-bracket pair is missing in `idxs`.

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

The idea is step 08's: [slip, and how grip depends on it](#slip-and-grip).

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

::: info Why the slippery road gives less push

The test drives the wheel with a steady 600 N·m, the engine's 150 × 4, into a 1 kg·m² wheel and a bare 1400 kg mass, with no drag and no rolling resistance. **Dry:** 600 / 0.31 = 1935 N is μ = 0.28 of the 6865 N load, which the curve reaches at a slip of about 0.0076. **Slippery:** the push needed is past the peak, so the tire gives only sliding grip, 0.7 × 0.2 = 0.14 of the load, and the rest of the engine's push spins the wheel. A slip of 135 means the tire surface moves 136 times as fast as the car.

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

::: info Why the wheel spins: two limits, the engine's and the tire's

The push to the road passes through two things in a row, the engine and the tire, and the lower limit decides. The driven wheels carry half the car, *F*<sub>z</sub> = 6865 N, and the most the tire can push is μ<sub>peak</sub> × *F*<sub>z</sub>:

| limit | N at the road |
| --- | --: |
| engine, flat out (step 03) | 1935 |
| tire, dry: 1.0 × 6865 | 6865 |
| tire, snow: 0.2 × 6865 | 1373 |
| tire, ice: 0.05 × 6865 | 343 |

**Dry:** the engine runs out first, and the tire stays left of its peak; the car behaves like step 05's, 21 km/h after 5 s. **Snow:** the tire runs out first, 1373 < 1935, and the engine keeps pushing the wheel **past the peak**. Then it runs away: more slip → less grip → less holding the wheel back → it spins faster → more slip. That comes from the tire curve, not from anything you built. The table only says the wheel *must* spin; how far the car gets, about 10 km/h after 5 s, comes from the run. (The 50/50 split of the weight is a modeling choice.)

:::

#### Where you are, where you are going

This is a new car, not an edit of `Car`. The slipping wheel replaces the rolling wheel that sat inside `Driveline`, so the gear and the wheel inertia are placed directly, and the body is the `GradeBody` of step 07. Two speeds come out: the car's, and the tire surface's. On ice they come apart.

[![SlipCar diagram: engine, gear, wheel inertia and slip wheel drive the grade body, with separate sensors for vehicle speed and wheel surface speed.](/handson/lecture-01/img/step10-standing-start.png){width="1502" height="940"}](/handson/lecture-01/img/step10-standing-start.png)

`SlipCar`: two speed outputs, `v_kmh` from the body and `wheel_kmh` from the wheel shaft. On snow they come apart.

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

[![The SlipCarStandingStart bench: the constants road (k = 0), friction (k = 0.2) and cmd (k = 150) on the left, wired into the car block's three inputs on its left edge, from top to bottom grade, mu_scale and tau_cmd.](/handson/lecture-01/img/step10-standing-start-bench.png){style="max-width:300px" width="460" height="598"}](/handson/lecture-01/img/step10-standing-start-bench.png)

The finished bench, drawn by the Dyad command line from the reference `HandsOn.SlipCarStandingStart`; it draws no port names. `car`'s inputs are, from the top, `grade`, `mu_scale` and `tau_cmd`.

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
   using Plots
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

The run: the wheel surface (orange) is past 1500 km/h after 5 s while the car (blue) has reached 10 km/h. Past the peak of the curve, more slip gives less grip, so the wheel runs away. {#wheelspin}

::: tip Checkpoint

Measured on `HandsOn.SlipCarStandingStartTransient`, friction 0.2: after 1 s the car makes 1.94 km/h while the wheel surface is already at 159.8 km/h; after 5 s the car makes **10.12 km/h** and the wheel surface **1501 km/h**. The model has no rev limit, so the engine keeps delivering 150 N·m into a wheel that has nothing to push against. On the dry road (friction 1.0) the two speeds stay together: 21.08 km/h for the car, 21.24 km/h at the wheel surface after 5 s.

:::

::: info Why 1500 km/h is not a bug

A real engine has a rev limiter that cuts power at a maximum engine speed. This model has none, so nothing stops the wheel: 1500 km/h at the tire is the engine at about 51 000 rpm. The number follows from what was left out. This is also where the next lecture ends: a cruise control on ice sees the speed drop and asks for more torque, with exactly this result. That is why a real cruise control switches off when traction control steps in.

:::

Something else? The car goes backward: the sign of `flange.f` in `SlipWheel1D`. Both lines together on the slippery run: the bench's `friction` is still 1.0. A violent slip at the start: `initial car.wheel_inertia.w = 0` is missing.

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
