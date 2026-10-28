---
title: Lecture 4 — build a battery-electric car
---

[← Vehicle Systems & Components](../../index.html)

# Lecture 4: build a battery-electric car

From a DC-equivalent machine on a test bench to a Leaf-class car on the WLTC and its energy bill in kWh/100 km

**What you build.** The energy chain of an electric car, one link per step, in your `MyCar` on the branch `handson-04`: the machine, the converter that feeds it, the battery behind them, then the car, regenerative braking and the energy bill. Each step follows the theory section that introduces it. The motor, gear and battery numbers are the Nissan Leaf ZE1's; the body, the road load and the cycle are the course car's, so the result can be set beside Lecture 2's engine.

**How each step works.** Each step lists the parts to place with their library path, instance name and values, every wire and line of code, and the numbers the run must show before you go on. Use the names given here: later steps read signal paths such as `battery.SoC`.

**Fell behind?** Every step ends with a **Fell behind?** block: the finished code of that step, to paste. The course repository has the same components as the reference answers in `dyad/HandsOn04/`, under the same names; under **+** they show as `VehicleSystemsComponents › HandsOn04`. Build your own; open them only to compare.

**Plotting.** Every plot is drawn in the Julia REPL: click **Dyad: Open Julia REPL** in the **Actions** panel's title bar. Snippets do not load `MyCar`: the REPL reloads it when you run an analysis from Studio. So each time you add an analysis, click ▷ **Run Analysis** and pick it once before you paste a snippet that calls it.

Every number in an expected result is a test expectation or a measured run of the reference model.

<!-- Steps 01, 02 and 04–06 land with their own issues under dr14-make/16ESPD#99. -->

- [03 · The battery: V = E − I·R](#step-03)

## 06 Batteries, simply

### 03 · The battery: V = E − I·R {#step-03}

The pack the machine draws on, as the lecture's battery section writes it: a constant open-circuit voltage *E* behind a resistance *R*<sub>0</sub>, and a state of charge counted from the current. On a bench that draws 100 A for half an hour, the terminal voltage sags 10 V the moment the load comes on, and the state of charge falls from 0.9 to 0.4625.

#### Given

The Nissan Leaf ZE1 pack: **40 kWh** at **350 V** nominal, 96 cell pairs in series. Its resistance is about **0.1 Ω**: 2 mΩ per 56 Ah cell, 96 in series over 2 in parallel. INL measured 0.11–0.145 Ω on a 2013 Leaf pack at mid charge, and about 50 % more near empty.

$$
v = E - R_0\, i \qquad \frac{d\,SoC}{dt} = -\frac{i}{Q_{nom}} \qquad Q_{nom} = \frac{40\ \text{kWh}}{350\ \text{V}} = 114.3\ \text{A·h}
$$

*i* is the discharge current: out of the positive terminal, through the load and back into the negative one. It is negative while the battery charges, which is what regenerative braking does in step 05.

::: info Why the voltage sags, and why SoC is counted

The cells' chemistry sets a voltage *E* when no current flows. Current has to cross the electrolyte, the electrodes and every busbar between 192 cells, and that costs a voltage *R*<sub>0</sub>·*i*, burned as heat. So the harder you pull, the lower the voltage the inverter sees, and the more of the energy stays in the pack as heat.

Nothing in a battery measures its state of charge. The battery management system counts it: it integrates the current it measures, the charge taken out over the charge the pack holds. That is *coulomb counting*, and it is the second equation. Capacity in A·h is charge; energy in kWh is that charge times the voltage it was delivered at, which is why 40 kWh at 350 V is 114.3 A·h.

Here *E* is constant: an empty pack shows the same 350 V as a full one. The extra pack's Thevenin cell reads *E* from the state of charge instead, and adds the slow relaxation a real cell shows after a load step.

:::

::: details Details: the checkpoint numbers worked through

- **Capacity:** 40 000 Wh / 350 V = 114.29 A·h = 411 429 C, since 1 A·h is 3600 C.
- **Sag at 100 A:** 100 × 0.1 = 10 V, so 340 V.
- **Charge out in 30 minutes:** 100 A × 0.5 h = 50 A·h, and 50 / 114.29 = 0.4375 of the pack: SoC 0.9 → 0.4625.
- **Energy:** *E* gives 350 V × 50 A·h = 17.5 kWh, which is 0.4375 × 40 kWh. *R*<sub>0</sub> burns 100² × 0.1 = 1 kW for half an hour, 0.5 kWh. The load gets 340 V × 100 A × 0.5 h = 17.0 kWh: 97 % of what left the cells.
- **At full power:** 330 A is about the ZE1 motor's 110 kW. The sag is 33 V, so 317 V and 104.6 kW at the terminals, and *R*<sub>0</sub> burns 330² × 0.1 = 10.9 kW. Half an hour of that is 330 × 0.5 = 165 A·h from a 114.3 A·h pack.

:::

#### Parts

New component `Battery` in `MyCar`: paste the code below.

New component `BatteryDischarge` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `I_load` | parameter `Current` | `100.0`: the current the load draws; negative charges the battery |
| `load_profile` | BlockComponents › Sources › Step | `height = I_load`, `offset = 0.0`, `start_time = 60.0` |
| `load` | ElectricalComponents › Analog › Sources › CurrentSource | — |
| `battery` | your `Battery` | defaults |
| `ground` | ElectricalComponents › Analog › Basic › Ground | — |

:::: info Given parts: the load and the ground

**`CurrentSource`** (`load`): an ideal current source. It forces the current its input `I` asks for, in amperes, into its pin `p`, through itself and out of `n`, whatever the voltage across it. Wired with its `p` on the battery's `p`, it pulls `I` out of the battery's positive terminal: a load that draws exactly 100 A, as a motor drive does when it is asked for a fixed torque.

**`Ground`** (`ground`): the 0 V reference. Every electrical circuit needs one, or its voltages float; it carries no current here.

::::

::: warning Use these names

`p`, `n`, `SoC`, `v`, `i`, `E`, `R0`, `Q_nom` and `SoC0` are the names the course library's `Vehicle.Electric.Battery` uses, and the names the extra pack's Thevenin cell keeps. Keep them, and in step 04 either battery, or the Thevenin cell later, drops into the car without rewiring.

:::

#### Do this

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `Battery`. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save.

   ::: code-group

   ```txt [Battery]
   """
   The battery as an open-circuit voltage behind a resistance, its state of
   charge counted from the current.
   """
   component Battery
     extends ElectricalComponents.Analog.Interfaces.TwoPin
     "State of charge: 1 full, 0 empty"
     SoC = RealOutput() {"Dyad": {"placement": {"icon": {"x1": 450, "y1": -50, "x2": 550, "y2": 50, "rot": 270}, "diagram": {"x1": 450, "y1": -50, "x2": 550, "y2": 50, "rot": 270}}}}
     "Open-circuit voltage, Leaf ZE1 nominal"
     parameter E::Voltage = 350.0
     "Series resistance"
     parameter R0::Resistance = 0.1
     "Charge capacity, 40 kWh / 350 V = 114.3 A.h [C]"
     parameter Q_nom::ElectricCharge = 40.0e3 * 3600.0 / 350.0
     "State of charge at t = 0"
     parameter SoC0::Real = 0.9
     "Discharge current, out of p through the load and back into n"
     variable i::Current
   relations
     initial SoC = SoC0
     p.i + n.i = 0
     i = n.i
     v = E - R0 * i
     der(SoC) = -i / Q_nom
   end
   ```

   :::

   `extends … TwoPin` gives the battery its two pins, `p` on the left and `n` on the right, and the terminal voltage `v = p.v - n.v`. A pin's current counts positive *into* the component, so the current that comes back into `n` is the one that left `p` through the load: `i = n.i`, and `p.i + n.i = 0` says the battery stores no charge on its terminals. The last two lines are the two equations above; `Q_nom` is in coulombs, so 114.3 A·h is written as 40 kWh × 3600 s/h over 350 V.

   If the compile flags `ElectricalComponents` as `missing-direct-dependency`, add it in the REPL with `using Pkg; Pkg.add("ElectricalComponents")`, then <kbd>F1</kbd> → **Dyad: Restart Language Server** and compile again.

2. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `BatteryDischarge`. With nothing selected, click **Edit Parameters** → **Add parameter**: `I_load`, type `Current`, value `100.0`. Place the four blocks from the table and rename each to its **Name**: select it → **Edit Parameters** → the pencil next to its name. Set `load_profile`'s `height` to `I_load` and its `start_time` to `60.0`.
3. Wire:
   - `load_profile.y → load.I`
   - `battery.p → load.p`
   - `load.n → battery.n`, and `battery.n → ground.g`

   Hover a pin to read its name before you wire it: on both `battery` and `load`, `p` is the left pin and `n` the right one.
4. <Badge type="tip" text="New analysis" /> Toggle to code and add the analysis below the component, so it passes `I_load` through:

   ```txt
   analysis BatteryDischargeTransient
     extends TransientAnalysis(stop = 1860.0, tstops = [60.0])
     parameter I_load::Current = 100.0
     model = BatteryDischarge(I_load = I_load)
   end
   ```

   `tstops = [60.0]` makes the solver land exactly on the load step. Without it the solver strides across the switch-on, misses about half a second of the current, and SoC ends at 0.46237 instead of 0.4625.
5. Click ▷ **Run Analysis → BatteryDischargeTransient** once, then plot the terminal voltage, the current and the state of charge, and read the final SoC:

   ```julia
   using Plots; plotly()
   r = MyCar.BatteryDischargeTransient();
   plot(r; idxs = [r."battery.v", r."battery.i", r."battery.SoC"], layout = (3, 1))
   r.sol[r."battery.SoC"][end]
   ```

6. Charge the battery instead, then pull the motor's full power from it:

   ```julia
   r = MyCar.BatteryDischargeTransient(I_load = -20.0);
   plot(r; idxs = [r."battery.v", r."battery.SoC"], layout = (2, 1))
   r = MyCar.BatteryDischargeTransient(I_load = 330.0);
   plot(r; idxs = [r."battery.v", r."battery.SoC"], layout = (2, 1))
   ```

::: tip Expected result

**100 A, the default:** `battery.v` holds **350 V** for the first minute and drops to **340 V** at 60 s, the moment `battery.i` steps to 100 A: the sag is *R*<sub>0</sub>·*i* = **10 V**, and it stays exactly 10 V for as long as the current flows. `battery.SoC` stays at **0.9** while no current flows, then falls on a straight line to **0.4625** at 1860 s: 0.4375 of the pack, 50 A·h out of 114.3. Of the 17.5 kWh that left the cells, **17.0 kWh** reached the load and **0.5 kWh** heated *R*<sub>0</sub>.

**−20 A, charging:** the terminals rise *above* *E*, to **352 V**: a charger has to push against *E* and *R*<sub>0</sub> both. SoC climbs from 0.9 to **0.9875**.

**330 A, about the motor's 110 kW:** **317 V** under load, **104.6 kW** at the terminals and 10.9 kW lost in *R*<sub>0</sub>. SoC passes zero after 19 minutes of load and ends at **−0.544**: nothing in V = E − I·R knows the pack is empty. A real pack's voltage collapses near empty, to 296 V at 3 % in INL's test of a 2013 Leaf pack, and its management system cuts the current long before.

Reference: `HandsOn04.Battery`, `HandsOn04.BatteryDischarge`, `HandsOn04.BatteryDischargeTransient`; the course library's copy is `Vehicle.Electric.Battery`.

:::

Commit: **Source Control** → message `Step 03: battery` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `Battery` from step 1 of **Do this** above. Then right-click `MyCar` → **Add Component**, name it `BatteryDischarge`, toggle to code (⇄) and paste this over its contents.

::: code-group

```txt [BatteryDischarge]
component BatteryDischarge
  "Current drawn from the battery once the load is on; negative charges it"
  parameter I_load::Current = 100.0
  load_profile = BlockComponents.Sources.Step(height = I_load, offset = 0.0, start_time = 60.0)
  load = ElectricalComponents.Analog.Sources.CurrentSource()
  battery = Battery()
  ground = ElectricalComponents.Analog.Basic.Ground()
relations
  connect(load_profile.y, load.I)
  connect(battery.p, load.p)
  connect(load.n, battery.n)
  connect(battery.n, ground.g)
end

analysis BatteryDischargeTransient
  extends TransientAnalysis(stop = 1860.0, tstops = [60.0])
  parameter I_load::Current = 100.0
  model = BatteryDischarge(I_load = I_load)
end
```

:::

::::

---

Reference models: `dyad/HandsOn04/` in the course repository; checkpoint tests in `test/battery_plausibility.jl`. Design: `docs/lecture-04-plan.md`.
