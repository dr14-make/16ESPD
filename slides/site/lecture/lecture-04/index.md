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

<!-- Steps 02 and 04–06 land with their own issues under dr14-make/16ESPD#99. -->

- [01 · The machine: T = KΦI, E = KΦω](#step-01)
- [03 · The battery: V = E − I·R](#step-03)

## 02 The DC machine

### 01 · The machine: T = KΦI, E = KΦω {#step-01}

The motor as the lecture's DC machine section writes it: a back-EMF behind the armature's resistance and inductance, and the deck's losses as parts on the shaft. On a dyno that holds base speed on a 350 V supply, the shaft gives the Leaf's **320 N·m at 3283 rpm**, 110 kW; as the dyno speeds it up, the torque falls along a straight line, through zero just below 3447 rpm, and the machine starts generating.

#### Given

The Nissan Leaf ZE1 motor: **320 N·m** from standstill to its base speed of **3283 rpm**, where it meets its **110 kW**. The machine is fed from the 350 V pack of step 03.

$$
v = R\,i + L\frac{di}{dt} + E \qquad E = K\Phi\,\omega \qquad T_{em} = K\Phi\, i
$$

$$
P_{loss} = \underbrace{R\,i^2}_{\text{copper}} + \underbrace{T_f\,\omega}_{\text{friction}} + \underbrace{K_i\,\omega}_{\text{iron}} + \underbrace{k_w\,\omega^3}_{\text{windage}} + \underbrace{C}_{\text{constant}}
$$

| Parameter | Value | Where it comes from |
| --- | --- | --- |
| *R* | 0.05 Ω | chosen so the efficiency lands on ORNL's measured Leaf motor map |
| *L* | 0.5 mH | *L*/*R* = 10 ms |
| *T*<sub>f</sub>, *K*<sub>i</sub> | 0.5 N·m, 1.0 N·m | friction and iron loss, as torques: 0.5 kW and 1 kW at 9550 rpm |
| *k*<sub>w</sub> | 300 / (10 100 rpm)³ | windage: 300 W at the motor's top speed |
| *C* | 200 W | lost at any speed |
| *K*Φ | 0.9697 N·m/A | derived: at 350 V and 3283 rpm the shaft delivers 320 N·m |

*i* flows into the positive terminal, through the armature and out of the negative one; it is negative while the machine generates. The copper loss lives in the resistor, so the efficiency of this machine is computed from its parts, never looked up from a map.

::: info Why one constant does both jobs

A conductor of length *l* carrying current *I* across a field *B* feels the force *F* = *BIl*. Wound onto a rotor of radius *r*, every conductor adds *BIl*·*r* to the torque, and all of that is fixed by the build except *I*: so *T* = *K*Φ·*I*. The same conductors moving at speed *ωr* through the same field have a voltage *Blωr* induced in them, so *E* = *K*Φ·*ω*, with the same *K*Φ. That is why the power balance closes: *E*·*i* = *K*Φ·*ω*·*i* = *T*·*ω*, electrical power in becomes mechanical power out.

On a fixed supply the current is whatever the gap *V* − *E* drives through *R*: *i* = (*V* − *K*Φ*ω*)/*R*. Torque is therefore a straight line in speed, falling by (*K*Φ)²/*R* = 1.97 N·m per rpm, and it reaches zero where the back-EMF has caught up with the supply, at *V*/*K*Φ. Push the shaft faster than that and *E* exceeds *V*: the current reverses, and the motor is a generator.

:::

::: details Details: the checkpoint numbers worked through

- **Losses at base speed:** ω = 3283 × π/30 = 343.8 rad/s. The shaft losses take 0.5 + 1.0 + *k*<sub>w</sub>·343.8² + 200/343.8 = 0.5 + 1.0 + 0.03 + 0.58 = **2.11 N·m**, 0.73 kW.
- ***K*Φ:** the shaft gives 320 N·m when the electromagnetic torque is 322.1 N·m, so *i* = 322.1/*K*Φ, and 350 V = *K*Φ × 343.8 + 0.05 × 322.1/*K*Φ. Solved for *K*Φ: **0.9697 N·m/A**.
- **At base speed:** *E* = 0.9697 × 343.8 = **333.4 V**, so *i* = (350 − 333.4)/0.05 = **332.2 A**. Copper loss 332.2² × 0.05 = **5.52 kW**. Shaft power 320 × 343.8 = **110.0 kW**; electrical power 350 × 332.2 = 116.3 kW, so the motor is **94.6 %** efficient here.
- **The line:** the torque falls by 0.9697²/0.05 = 18.8 N·m per rad/s, **1.97 N·m per rpm**, and reaches zero near 350/0.9697 = 360.9 rad/s = **3447 rpm**. At 3600 rpm the back-EMF is 365.6 V, the current is (350 − 365.6)/0.05 = **−312 A**, and the shaft takes **−304 N·m**.

:::

#### Parts

New component `DCMachine` in `MyCar`: paste the code below.

New component `DCMachineDyno` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `V` | parameter `Voltage` | `350.0`: the supply voltage |
| `rpm_start` | parameter `Real` | `3283.0`: dyno speed before the ramp |
| `rpm_end` | parameter `Real` | `3600.0`: dyno speed after the ramp |
| `voltage` | BlockComponents › Sources › Constant | `k = V` |
| `supply` | ElectricalComponents › Analog › Sources › VoltageSource | — |
| `machine` | your `DCMachine` | defaults |
| `ground` | ElectricalComponents › Analog › Basic › Ground | — |
| `speed` | BlockComponents › Sources › Ramp | `height = (rpm_end - rpm_start) * pi / 30.0`, `offset = rpm_start * pi / 30.0`, `start_time = 1.0`, `duration = 10.0` |
| `dyno` | RotationalComponents › Sources › VelocitySource | — |
| `mounts` | RotationalComponents › Components › Fixed | — |

:::: info Given parts: the supply, the dyno and the loss torques

**`VoltageSource`** (`supply`): an ideal voltage source. It holds its pins `V` volts apart, whatever current flows, in either direction. Fed from a constant 350 V it stands in for the pack: a stiff supply with no converter between it and the machine, which is what step 02 adds.

**`VelocitySource`** (`dyno`): the dynamometer. It forces its `spline` to the speed its input `w_ref` asks for, in rad/s, and absorbs or supplies whatever torque that takes. The `speed` ramp holds 3283 rpm for a second, ramps to 3600 rpm over ten and holds again.

**`SignTorque`**, **`QuadraticSpeedDependentTorque`**, **`InverseSpeedDependentTorque`** (inside the machine): torques that depend only on the shaft speed, with a negative `tau_nominal` so they brake. Friction and iron loss are a constant torque, so their power grows as ω; windage is a torque in ω², a power in ω³; the constant loss is a torque *C*/ω, so its power is *C* at every speed. Below `w_reg`, 95 rpm, the constant-torque terms fade to zero, so a machine at standstill has no infinite drag.

::::

::: warning Use these names

`p`, `n`, `spline`, `support`, `i`, `E`, `tau_em`, `tau`, `w`, `k`, `R`, `P_cu` and the other `P_` losses are the names the course library's `Vehicle.Electric.DCMachine` uses. Keep them, and in step 02 the converter, and in step 04 the car, take either machine.

:::

#### Do this

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `DCMachine`. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save.

   ::: code-group

   ```txt [DCMachine]
   component DCMachine
     extends ElectricalComponents.Analog.Interfaces.TwoPin
     "Rotor shaft"
     spline = Spline() {^spline}
     "Housing"
     support = Spline() {^support}
     resistor = ElectricalComponents.Analog.Basic.Resistor(R = R) {^resistor}
     inductor = ElectricalComponents.Analog.Basic.Inductor(L = L) {^inductor}
     emf = ElectricalComponents.Analog.Basic.RotationalEMF(k = k) {^emf}
     rotor = RotationalComponents.Components.Inertia(J = J) {^rotor}
     friction = RotationalComponents.Sources.SignTorque(tau_nominal = -T_f, reg = RotationalComponents.Sources.Regularization.Linear(), w0 = w_reg) {^friction}
     iron = RotationalComponents.Sources.SignTorque(tau_nominal = -K_i, reg = RotationalComponents.Sources.Regularization.Linear(), w0 = w_reg) {^iron}
     windage = RotationalComponents.Sources.QuadraticSpeedDependentTorque(tau_nominal = -k_w * w_base ^ 2, w_nominal = w_base, TorqueDirection = false) {^windage}
     constant_loss = RotationalComponents.Sources.InverseSpeedDependentTorque(tau_nominal = -C / w_reg, w_nominal = w_reg, w0 = w_reg, TorqueDirection = false) {^constant_loss}
     "Peak shaft torque, Leaf ZE1"
     parameter T_max::Torque = 320.0
     "Base speed, 3283 rpm"
     parameter w_base::AngularVelocity = 3283.0 * pi / 30.0
     "Supply voltage at which the machine reaches base speed at full torque"
     parameter V_nom::Voltage = 350.0
     "Armature resistance"
     parameter R::Resistance = 0.05
     "Armature inductance, L/R = 10 ms"
     parameter L::Inductance = 0.5e-3
     "Rotor inertia"
     parameter J::Inertia = 0.05
     "Friction torque T_f; loss T_f w"
     parameter T_f::Torque = 0.5
     "Iron loss coefficient K_i; loss K_i w"
     parameter K_i::Torque = 1.0
     "Windage coefficient k_w; loss k_w w^3, 300 W at 10100 rpm [N.m.s2]"
     parameter k_w::Real = 300.0 / (10100.0 * pi / 30.0) ^ 3
     "Constant loss C"
     parameter C::Power = 200.0
     "Speed below which the speed-independent loss torques fade to zero"
     parameter w_reg::AngularVelocity = 10.0
     "Torque the losses take at base speed"
     parameter tau_loss_base::Torque = T_f + K_i + k_w * w_base ^ 2 + C / w_base
     "Torque and back-EMF constant KΦ, from k w_base + R (T_max + tau_loss_base) / k = V_nom"
     parameter k::ElectricalTorqueConstant = (V_nom + sqrt(V_nom ^ 2 - 4.0 * w_base * R * (T_max + tau_loss_base))) / (2.0 * w_base)
     "Armature current, into p"
     variable i::Current
     "Back-EMF, E = k w"
     variable E::Voltage
     "Electromagnetic torque, tau_em = k i"
     variable tau_em::Torque
     "Shaft speed relative to the housing"
     variable w::AngularVelocity
     "Torque delivered at the shaft"
     variable tau::Torque
     "Electrical power into the terminals"
     variable P_elec::Power
     "Mechanical power out of the shaft"
     variable P_mech::Power
     "Copper loss, R i^2"
     variable P_cu::Power
     "Friction loss"
     variable P_fric::Power
     "Iron loss"
     variable P_iron::Power
     "Windage loss"
     variable P_wind::Power
     "Constant loss"
     variable P_const::Power
     "Sum of the losses"
     variable P_loss::Power
   relations
     connect(p, resistor.p) {^id1}
     connect(resistor.n, inductor.p) {^id2}
     connect(inductor.n, emf.p) {^id3}
     connect(emf.n, n) {^id4}
     connect(emf.rotor, rotor.spline_a, friction.spline, iron.spline, windage.spline, constant_loss.spline) {^id5}
     connect(rotor.spline_b, spline) {^id6}
     connect(emf.housing, friction.support, iron.support, windage.support, constant_loss.support, support) {^id7}
     i = p.i
     E = emf.v
     tau_em = -emf.tau
     w = emf.w
     tau = -spline.tau
     P_elec = v * i
     P_mech = tau * w
     P_cu = resistor.v * resistor.i
     P_fric = -friction.tau * w
     P_iron = -iron.tau * w
     P_wind = -windage.tau * w
     P_const = -constant_loss.tau * w
     P_loss = P_cu + P_fric + P_iron + P_wind + P_const
   metadata {
     "_links": {
       "spline": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}}}},
       "support": {"Dyad": {"placement": {"icon": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}}}},
       "p": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": 150, "y1": -50, "x2": 250, "y2": 50}}}},
       "n": {"Dyad": {"placement": {"icon": {"iconName": "neg", "x1": 750, "y1": -50, "x2": 850, "y2": 50}}}}
     }
   }
   end
   ```

   :::

   `extends … TwoPin` gives the machine its electrical pins and its terminal voltage `v`. The armature is the chain `p → resistor → inductor → emf → n`. The `emf` turns current into torque on its `rotor` and speed into voltage, both through `k`. The rotor inertia and the four loss parts all sit on the `emf`'s rotor and push back against the `support`, the housing. `k` is written as the formula it comes from, so if you change `R` or a loss, the machine still meets 320 N·m at 3283 rpm on 350 V.

2. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `DCMachineDyno`. With nothing selected, click **Edit Parameters** → **Add parameter** three times for `V`, `rpm_start` and `rpm_end`. Place the seven blocks from the table, rename each to its **Name** and set the values in its **Set** column.
3. Wire:
   - `voltage.y → supply.V`
   - `supply.p → machine.p`
   - `machine.n → supply.n`, and `supply.n → ground.g`
   - `speed.y → dyno.w_ref`
   - `machine.spline → dyno.spline`
   - `machine.support → mounts.spline`, and `dyno.support → mounts.spline`
4. <Badge type="tip" text="New analysis" /> Toggle to code. Add these two lines in the `relations` section, so that the dyno's angle and the armature current start at zero:

   ```txt
   initial dyno.phi = 0
   initial machine.inductor.i = 0
   ```

   Then add the analysis below the component, so it passes the voltage and the speeds through:

   ```txt
   analysis DCMachineDynoTransient
     extends TransientAnalysis(stop = 12.0, alg = ODEAlg.Rodas5P(), saveat = 0.01, tstops = [1.0, 11.0])
     parameter V::Voltage = 350.0
     parameter rpm_start::Real = 3283.0
     parameter rpm_end::Real = 3600.0
     model = DCMachineDyno(V = V, rpm_start = rpm_start, rpm_end = rpm_end)
   end
   ```

   `tstops` lands the solver on both corners of the ramp. The current starts at zero and reaches its 332 A within 50 ms: the armature's time constant is *L*/*R* = 10 ms.
5. Click ▷ **Run Analysis → DCMachineDynoTransient** once, then plot the torque-speed curve, and check that the copper loss is *I*²*R*:

   ```julia
   using Plots; plotly()
   r = MyCar.DCMachineDynoTransient();
   rpm = r.sol[r."machine.w"] .* 30 ./ pi;
   plot(rpm[101:end], r.sol[r."machine.tau"][101:end]; xlabel = "rpm", ylabel = "N·m", label = "shaft torque")
   r.sol[r."machine.tau"][101], r.sol[r."machine.P_cu"][101], 0.05 * r.sol[r."machine.i"][101]^2
   plot(r; idxs = [r."machine.P_cu", r."machine.P_fric", r."machine.P_iron", r."machine.P_wind", r."machine.P_const"])
   ```

   Points 1 to 100 are the first second, where the current is still rising from zero, so the curve starts at point 101, at *t* = 1 s.
6. Lower the supply to 200 V, and look at the current the machine draws at 1500 rpm:

   ```julia
   r = MyCar.DCMachineDynoTransient(V = 200.0, rpm_start = 1500.0, rpm_end = 2200.0);
   plot(r.sol[r."machine.w"][101:end] .* 30 ./ pi, r.sol[r."machine.tau"][101:end])
   r.sol[r."machine.i"][101]
   ```

::: tip Expected result

**350 V, the default:** for the first second the shaft holds **3283 rpm** and gives **320.0 N·m**, which is **110.0 kW**. `machine.i` is **332.2 A** and `machine.E` **333.4 V**; `machine.P_cu` is **5.52 kW**, exactly 0.05 × 332.2², and the shaft losses add **0.73 kW**: 94.6 % efficient. As the dyno ramps, the torque falls on a straight line of **−1.97 N·m per rpm**, crosses zero at about **3446 rpm**, just below *V*/*K*Φ = 3447 rpm, and ends at **−304 N·m** at 3600 rpm, with **−312 A**: the machine is generating, and the current flows back into the supply. Along the ramp the torque sits **0.46 N·m** above the steady line: the inductance holds the current 0.64 A behind the falling back-EMF.

**The losses:** `P_fric` and `P_iron` grow in proportion to the speed, 172 W and 344 W at base speed; `P_wind` is **10 W** there and grows as ω³; `P_const` stays at **200 W**.

**200 V:** the line keeps its slope and moves down in speed: it crosses zero at **1968 rpm**, just below 200/0.9697 = 1969 rpm. At 1500 rpm the shaft gives **922 N·m** for **953 A**, nearly three times the current at the Leaf's 320 N·m. A fixed supply cannot give the full torque at low speed without that current: step 02's converter lowers the voltage *and* caps the current.

Reference: `HandsOn04.DCMachine`, `HandsOn04.DCMachineDyno`, `HandsOn04.DCMachineDynoTransient`; the course library's copy is `Vehicle.Electric.DCMachine`.

:::

Commit: **Source Control** → message `Step 01: machine` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `DCMachine` from step 1 of **Do this** above. Then right-click `MyCar` → **Add Component**, name it `DCMachineDyno`, toggle to code (⇄) and paste this over its contents.

::: code-group

```txt [DCMachineDyno]
component DCMachineDyno
  "Supply voltage at the terminals"
  parameter V::Voltage = 350.0
  "Dyno speed before the ramp [rpm]"
  parameter rpm_start::Real = 3283.0
  "Dyno speed after the ramp [rpm]"
  parameter rpm_end::Real = 3600.0
  voltage = BlockComponents.Sources.Constant(k = V)
  supply = ElectricalComponents.Analog.Sources.VoltageSource()
  machine = DCMachine()
  ground = ElectricalComponents.Analog.Basic.Ground()
  speed = BlockComponents.Sources.Ramp(height = (rpm_end - rpm_start) * pi / 30.0, offset = rpm_start * pi / 30.0, start_time = 1.0, duration = 10.0)
  dyno = RotationalComponents.Sources.VelocitySource()
  mounts = RotationalComponents.Components.Fixed()
relations
  initial dyno.phi = 0
  initial machine.inductor.i = 0
  connect(voltage.y, supply.V)
  connect(supply.p, machine.p)
  connect(machine.n, supply.n)
  connect(supply.n, ground.g)
  connect(speed.y, dyno.w_ref)
  connect(machine.spline, dyno.spline)
  connect(machine.support, mounts.spline)
  connect(dyno.support, mounts.spline)
end

analysis DCMachineDynoTransient
  extends TransientAnalysis(stop = 12.0, alg = ODEAlg.Rodas5P(), saveat = 0.01, tstops = [1.0, 11.0])
  parameter V::Voltage = 350.0
  parameter rpm_start::Real = 3283.0
  parameter rpm_end::Real = 3600.0
  model = DCMachineDyno(V = V, rpm_start = rpm_start, rpm_end = rpm_end)
end
```

:::

::::

---

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

Reference models: `dyad/HandsOn04/` in the course repository; checkpoint tests in `test/machine_plausibility.jl` and `test/battery_plausibility.jl`. Design: `docs/lecture-04-plan.md`.
