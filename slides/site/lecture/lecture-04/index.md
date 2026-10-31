---
title: Lecture 4 — build a battery-electric car
---

[← Vehicle Systems & Components](../../index.html)

# Lecture 4: build a battery-electric car

From a DC-equivalent machine on a test bench to a Leaf-class car on the WLTC and its energy bill in kWh/100 km

**What you build.** The energy chain of an electric car, one link per step, in your `MyCar` on the branch `handson-04`: the machine, the converter that feeds it, the battery behind them, then the car, regenerative braking and the energy bill. Each step follows the theory section that introduces it. The motor, gear and battery numbers are the Nissan Leaf ZE1's; the body, the road load and the cycle are the course car's, so the result can be set beside Lecture 2's engine.

**How each step works.** Each step lists the parts to place with their library path, instance name and values, every wire and line of code, and the numbers the run must show before you go on. Use the names given here: later steps read signal paths such as `battery.SoC`. A parameter the tables give a type such as `Voltage`, `Current` or `Torque` is a `Real` in the **Add parameter** form, which offers only `Real`, `Integer`, `Boolean` and `String`: pick `Real` and put the unit (`V`, `A`, `W`, `m`, `N.m`) in **Unit**.

**Fell behind?** Every step ends with a **Fell behind?** block: the finished code of that step, to paste. Paste it whole: the `{^…}` tags and the `metadata` block at its end place every part and wire, so the diagram opens laid out. The benches you paste in **Do this** carry them for the same reason. The course repository has the same components as the reference answers in `dyad/HandsOn04/`, under the same names; under **+** they show as `VehicleSystemsComponents › HandsOn04`. Build your own; open them only to compare.

**Plotting.** Every plot is drawn in the Julia REPL: click **Dyad: Open Julia REPL** in the **Actions** panel's title bar. Snippets do not load `MyCar`: the REPL reloads it when you run an analysis from Studio. So each time you add an analysis, click ▷ **Run Analysis** and pick it once before you paste a snippet that calls it.

Every number in an expected result is a test expectation or a measured run of the reference model.

- [00 · Set up: the course library](#step-00)
- [01 · The machine: T = KΦI, E = KΦω](#step-01)
- [02 · The converter: V_out = d·V_in, and field weakening](#step-02)
- [03 · The battery: V = E − I·R](#step-03)
- [04 · The car: machine → 8.193 → differential → front wheels](#step-04)
- [05 · Regen blended onto the Lecture 3 brakes](#step-05)
- [06 · The WLTC energy bill](#step-06)

## 00 Set up

### 00 · Set up: the course library {#step-00}

Today's parts, `Vehicle › Electric` with `AuxLoad` and `TorqueSplit`, the planar WLTC car with its road load, and the reference answers in `HandsOn04`, are in the course library from Lecture 4 on. Your `MyCar` needs that version, and two packages your own code names: `ElectricalComponents` for the circuits and `MultibodyComponents` for the differential.

::: details No MyCar of your own, or yours does not compile? Start from the course's.

Today uses nothing you built before: every step adds new components, and the car, the cycle and Lecture 3's brakes come from the course library. The course's `MyCar` repository has a start for it at the tag `lecture-04-start`: hands-on 1's car on Dyad 3.5, with nothing of Lecture 3 or today. Fork it and work on your fork; do this before class if you can.

1. On github.com, open [`dr14-make/MyCar`](https://github.com/dr14-make/MyCar) and click **Fork**. Untick **Copy the `main` branch only**, so the fork gets the tags too, then click **Create fork**. The fork is `https://github.com/<you>/MyCar`.
2. In Studio, press <kbd>F1</kbd> → **Git: Clone**, paste your fork's URL, pick an empty folder, and click **Open** when asked.
3. Press <kbd>F1</kbd> → **Git: Create Branch From…**, type `handson-04`, and pick the tag `lecture-04-start` from the list.
4. In the **Actions** panel's title bar, click **Dyad: Open Julia REPL** and run the lines below. The first download takes a few minutes; wait until it stops printing.

   ```julia
   using Pkg
   Pkg.instantiate()
   ```

5. Go on with step 2 of **Do this** below: your `handson-04` branch already exists, so skip step 1.

Your commits go to your fork, one per step, and the pull request at the end goes from `handson-04` to your fork's `main`.

:::

#### Do this

1. In the status bar, click the branch name → **Create new branch…** → `handson-04`, from `main`. If your Lecture 3 work is on another branch, `main` is still enough: today needs only a `MyCar` that compiles.
2. Open the Julia REPL and move the course library to the Lecture 4 version for Dyad 3.5. If you did Lecture 3, you added the library then, and your `Manifest.toml` still holds the version from that day, without today's parts. Started from `main` or `lecture-04-start`? `MyCar` has no course library yet, and the same line adds it. The second line adds the two packages your code names directly; one you already have is left as it is.

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "lecture-04-dyad-3.5")
   Pkg.add(["ElectricalComponents", "MultibodyComponents"])
   ```

3. <kbd>F1</kbd> → **Dyad: Restart Language Server**. The language server read your `Project.toml` when Studio started; until it restarts, the next compile flags every library part with `missing-direct-dependency … not a direct dependency`.
4. <kbd>F1</kbd> → **Dyad: Compile**.
5. Open any diagram, click **+** and open `VehicleSystemsComponents` → `Vehicle` → `Electric`.

[![The + library panel open at VehicleSystemsComponents › Vehicle › Electric, listing AuxLoad, Battery, BuckChopper, Converter, DCMachine, ElectricDrive, FieldEMF, HBridge, PWM, RegenBlend and Switch above the test benches; HandsOn04 and the other folders one level up.](/lecture/lecture-04/img/step00-electric-library.png)](/lecture/lecture-04/img/step00-electric-library.png)

::: tip Expected result

`using VehicleSystemsComponents`, `using ElectricalComponents` and `using MultibodyComponents` run in the REPL without an error. Under **+**, `Vehicle › Electric` lists `AuxLoad` and `TorqueSplit`; `Vehicle › Planar` lists `PlanarCar`, `PlanarRoadLoad`, `BusMotion` and `ABSUnit`; and `VehicleSystemsComponents` lists `HandsOn04`.

:::

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

`p`, `n`, `spline`, `support`, `i`, `E`, `tau_em`, `tau`, `w`, `k`, `R`, `P_cu` and the other `P_` losses are the names the course library's `Vehicle.Electric.DCMachine` uses. Keep them: step 02 gives this machine a field input and drives it from the converter, and in step 04 the car takes either machine.

:::

#### Do this

[![The finished DCMachineDyno in Studio: voltage into supply on the left with ground below it; machine at the top right, p and n on its left edge, its shaft wired to dyno; speed into dyno below; the machine's and the dyno's supports to mounts.](/lecture/lecture-04/img/step01-dyno.png)](/lecture/lecture-04/img/step01-dyno.png)

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `DCMachine`. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save.

   ::: code-group

   ```txt [DCMachine]
   component DCMachine
     "Positive electrical pin."
     p = Pin() {^p}
     "Negative electrical pin."
     n = Pin() {^n}
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
     "Voltage across the component (between pin p and pin n)."
     variable v::Voltage
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
     v = p.v - n.v
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
     "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/DCMachine.svg"}, "labels": [{"label": "$(instance)", "x": 500, "y": 1150, "rot": 0}]},
     "_links": {
       "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 120, "y": 450}], "E": -1}, {"S": 2, "M": [], "E": -1}, {"S": -1, "M": [{"x": 120, "y": 880}], "E": -2}, {"S": 3, "M": [{"x": 360, "y": 800}], "E": -2}, {"S": -2, "M": [], "E": -3}, {"S": -3, "M": [], "E": 6}, {"S": -3, "M": [], "E": -4}, {"S": 4, "M": [{"x": 545, "y": 800}], "E": -4}, {"S": 5, "M": [{"x": 720, "y": 800}, {"x": 720, "y": 880}], "E": -4}], "junctions": [{"x": 120, "y": 800}, {"x": 360, "y": 880}, {"x": 500, "y": 880}, {"x": 545, "y": 880}]}},
       "id6": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "id5": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [], "E": 2}, {"S": -1, "M": [], "E": -2}, {"S": -2, "M": [], "E": -3}, {"S": -2, "M": [], "E": -4}, {"S": -3, "M": [{"x": 490, "y": 750}], "E": 4}, {"S": -3, "M": [{"x": 290, "y": 630}, {"x": 290, "y": 750}], "E": 3}, {"S": -4, "M": [{"x": 690, "y": 750}], "E": 5}, {"S": -4, "M": [{"x": 890, "y": 630}, {"x": 890, "y": 750}], "E": 6}], "junctions": [{"x": 620, "y": 450}, {"x": 620, "y": 630}, {"x": 490, "y": 630}, {"x": 690, "y": 630}]}},
       "id4": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 470, "y": 500}, {"x": 470, "y": 560}, {"x": 60, "y": 560}, {"x": 60, "y": 800}], "E": 2}]}},
       "id3": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 500, "y": 200}], "E": 2}]}},
       "id2": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "id1": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "spline": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}, "diagram": {"x1": 950, "y1": 400, "x2": 1050, "y2": 500}}}},
       "support": {"Dyad": {"placement": {"icon": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}, "diagram": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}}}},
       "p": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}, "diagram": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}}}},
       "n": {"Dyad": {"placement": {"icon": {"iconName": "neg", "x1": -50, "y1": 750, "x2": 50, "y2": 850}, "diagram": {"iconName": "neg", "x1": -50, "y1": 750, "x2": 50, "y2": 850}}}},
       "resistor": {"Dyad": {"placement": {"diagram": {"x1": 100, "y1": 150, "x2": 200, "y2": 250}}}},
       "inductor": {"Dyad": {"placement": {"diagram": {"x1": 250, "y1": 150, "x2": 350, "y2": 250}}}},
       "emf": {"Dyad": {"placement": {"diagram": {"x1": 450, "y1": 400, "x2": 550, "y2": 500}}}},
       "rotor": {"Dyad": {"placement": {"diagram": {"x1": 700, "y1": 400, "x2": 800, "y2": 500}}}},
       "friction": {"Dyad": {"placement": {"diagram": {"x1": 150, "y1": 700, "x2": 250, "y2": 800}}}},
       "iron": {"Dyad": {"placement": {"diagram": {"x1": 350, "y1": 700, "x2": 450, "y2": 800}}}},
       "windage": {"Dyad": {"placement": {"diagram": {"x1": 550, "y1": 700, "x2": 650, "y2": 800}}}},
       "constant_loss": {"Dyad": {"placement": {"diagram": {"x1": 750, "y1": 700, "x2": 850, "y2": 800}}}}
     }
   }
   end
   ```

   :::

   `p` and `n` are the electrical pins, both on the machine's left edge, and `v = p.v - n.v` is its terminal voltage. The armature is the chain `p → resistor → inductor → emf → n`. The `emf` turns current into torque on its `rotor` and speed into voltage, both through `k`. The rotor inertia and the four loss parts all sit on the `emf`'s rotor and push back against the `support`, the housing. `k` is written as the formula it comes from, so if you change `R` or a loss, the machine still meets 320 N·m at 3283 rpm on 350 V.

2. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `DCMachineDyno`. With nothing selected, click **Edit Parameters** → **Add parameter** three times for `V`, `rpm_start` and `rpm_end`. Place the seven blocks from the table, rename each to its **Name** and set the values in its **Set** column. Searching **+** for `DCMachine` lists the course library's `HandsOn04` and `Vehicle › Electric` machines first: drag the one under `MyCar`. Each block lands with a default name (`constant1`, `voltagesource`, `dcmachine`, …), so rename all seven.
3. Wire:
   - `voltage.y → supply.V`
   - `supply.p → machine.p`
   - `machine.n → supply.n`, and `supply.n → ground.g`
   - `speed.y → dyno.w_ref`
   - `machine.spline → dyno.spline`
   - `machine.support → mounts.spline`, and `dyno.support → mounts.spline`

   Click an empty spot of the canvas between two wires: right after a wire is drawn, the next drag can be taken as a click and draw nothing. Count the `connect` lines in code view: eight.
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
  voltage = BlockComponents.Sources.Constant(k = V) {^voltage}
  supply = ElectricalComponents.Analog.Sources.VoltageSource() {^supply}
  machine = DCMachine() {^machine}
  ground = ElectricalComponents.Analog.Basic.Ground() {^ground}
  speed = BlockComponents.Sources.Ramp(height = (rpm_end - rpm_start) * pi / 30.0, offset = rpm_start * pi / 30.0, start_time = 1.0, duration = 10.0) {^speed}
  dyno = RotationalComponents.Sources.VelocitySource() {^dyno}
  mounts = RotationalComponents.Components.Fixed() {^mounts}
relations
  initial dyno.phi = 0
  initial machine.inductor.i = 0
  connect(voltage.y, supply.V) {^id1}
  connect(supply.p, machine.p) {^id2}
  connect(machine.n, supply.n) {^id3}
  connect(supply.n, ground.g) {^id4}
  connect(speed.y, dyno.w_ref) {^id5}
  connect(machine.spline, dyno.spline) {^id6}
  connect(machine.support, mounts.spline) {^id7}
  connect(dyno.support, mounts.spline) {^id8}
metadata {
  "_links": {
    "id8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 800, "y": 720}, {"x": 800, "y": 800}], "E": 2}]}},
    "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 650, "y": 500}], "E": 2}]}},
    "id6": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 970, "y": 400}, {"x": 970, "y": 670}], "E": 2}]}},
    "id5": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "id4": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "id3": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 600, "y": 460}, {"x": 600, "y": 550}], "E": 2}]}},
    "id2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 20, "y": 550}, {"x": 20, "y": 340}], "E": 2}]}},
    "id1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 250, "y": 430}], "E": 2}]}},
    "voltage": {"Dyad": {"placement": {"diagram": {"x1": 60, "y1": 380, "x2": 160, "y2": 480}}}},
    "supply": {"Dyad": {"placement": {"diagram": {"x1": 200, "y1": 500, "x2": 300, "y2": 600}}}},
    "machine": {"Dyad": {"placement": {"diagram": {"x1": 640, "y1": 300, "x2": 840, "y2": 500}}}},
    "ground": {"Dyad": {"placement": {"diagram": {"x1": 260, "y1": 640, "x2": 340, "y2": 720}}}},
    "speed": {"Dyad": {"placement": {"diagram": {"x1": 660, "y1": 620, "x2": 760, "y2": 720}}}},
    "dyno": {"Dyad": {"placement": {"diagram": {"x1": 840, "y1": 620, "x2": 940, "y2": 720}}}},
    "mounts": {"Dyad": {"placement": {"diagram": {"x1": 600, "y1": 800, "x2": 700, "y2": 900}}}}
  }
}
end

analysis DCMachineDynoTransient
  extends TransientAnalysis(stop = 12.0, alg = ODEAlg.Rodas5P(), saveat = 0.01, tstops = [1.0, 11.0])
  "Supply voltage at the terminals"
  parameter V::Voltage = 350.0
  "Dyno speed before the ramp [rpm]"
  parameter rpm_start::Real = 3283.0
  "Dyno speed after the ramp [rpm]"
  parameter rpm_end::Real = 3600.0
  model = DCMachineDyno(V = V, rpm_start = rpm_start, rpm_end = rpm_end)
end
```

:::

::::

---

## 04 The envelope

### 02 · The converter: V_out = d·V_in, and field weakening {#step-02}

Between the pack and the machine sits the inverter. Averaged over a switching period it is one number, the duty *d*: it gives the machine *d* times the pack voltage and draws *d* times the machine current from the pack. Give it a current limit and a voltage limit, drive step 01's machine through it, and sweep the dyno from standstill to 10 000 rpm: the shaft gives the Leaf's **320 N·m up to 3283 rpm**, and above that, where the voltage runs out, a torque that falls as 1/ω at **110 kW**.

#### Given

The average converter, with its two limits:

$$
v_{out} = d\, v_{in} \qquad i_{in} = d\, i_{out} + \frac{P_{loss}}{v_{in}} \qquad |i_{out}| \le I_{max} \qquad |d| \le d_{max}
$$

$$
P_{loss} = \underbrace{V_{on}\,|i_{out}|}_{\text{conduction}} + \underbrace{f_s\, t_{sw}\, v_{in}\,|i_{out}|}_{\text{switching}}
$$

Without its losses the converter is a DC transformer: *v*<sub>in</sub>·*i*<sub>in</sub> = *v*<sub>out</sub>·*i*<sub>out</sub>. With them, *P*<sub>in</sub> = *P*<sub>out</sub> + *P*<sub>loss</sub>, in either direction. The machine gets one new input, its **field**: the flux Φ as a fraction of full, so that

$$
E = \text{field}\cdot K\Phi\,\omega \qquad T_{em} = \text{field}\cdot K\Phi\, i
$$

| Parameter | Value | Where it comes from |
| --- | --- | --- |
| *I*<sub>max</sub> | 332.2 A | the current at which step 01's machine gives 320 N·m at base speed |
| *d*<sub>max</sub> | 1 | the inverter cannot give the machine more than the pack's voltage |
| *T*<sub>i</sub> | 1 ms | how fast the inverter's current loop follows its command |
| *V*<sub>on</sub> | 1.2 V | two devices carry the current at any instant, 0.6 V each (deck: power electronics) |
| *f*<sub>s</sub>, *t*<sub>sw</sub> | 5 kHz, 1 µs | ORNL ran the Leaf inverter at 5 kHz; 1 µs edges land the efficiency in ORNL's 96–99 % |

::: info Why the torque falls as 1/ω

Step 01 showed the trouble: on a fixed 350 V the machine's torque falls on a steep line and reaches zero at *V*/*K*Φ = 3447 rpm, where the back-EMF has caught up with the supply. The Leaf's motor runs to about 10 000 rpm.

The converter's current limit caps the torque: 332.2 A is 322.1 N·m in the air gap, 320 N·m at the shaft. To drive that current the machine needs *v* = *K*Φ·ω + *R*·*I*<sub>max</sub>, and the converter lowers its duty to give exactly that. As the speed rises the duty rises with the back-EMF, until at **3283 rpm** it reaches 1: the converter is giving all of the pack's 350 V. That is the **base speed**, the corner of the envelope, and the voltage has run out.

Faster than that, the only way to keep the current flowing is to lower *E* = *K*Φ·ω, and the only part of it left to lower is Φ: **field weakening**, the deck's second way to control a DC motor. Hold the voltage at 350 V and the current at 332.2 A, and *K*Φ·ω must stay at 350 − 16.6 = 333.4 V. So Φ falls as 1/ω, the torque *K*Φ·*I* falls as 1/ω with it, and the power *E*·*I* = 333.4 V × 332.2 A = **110.75 kW** stays constant: the hyperbola on every EV's spec sheet. A permanent-magnet motor's flux comes from its magnets and cannot be turned down. Its inverter weakens it instead, with a current that opposes the magnets (the d-axis current of field-oriented control), and does exactly this.

:::

::: info How the converter decides

`T_i * der(i_out) = i_cmd - i_out` is the current loop: the output current follows the command, clipped to ±*I*<sub>max</sub>, within a few milliseconds. The duty is then whatever the machine needs to carry that current. The last relation is an either-or: **either the field is full, or the duty is at its limit**, which is `min(1 - field, d_max - abs(d)) = 0`. Below base speed the voltage has room, so the field stays at 1. Above it the duty sits at 1, and the field goes wherever it must for the current to keep flowing. It is written with the corner of `min` rounded by `eps` = 10⁻⁴, so the solver meets no kink at base speed; the rounding costs 0.02 N·m at the corner and nothing measurable elsewhere.

:::

::: details Details: the checkpoint numbers worked through

- **Below base speed:** *K*Φ = 0.9697 N·m/A, so 332.2 A is *T*<sub>em</sub> = 322.1 N·m. At standstill *v*<sub>out</sub> = 0.05 × 332.2 = 16.6 V, so *d* = 16.6/350 = **0.047**. At 3283 rpm the shaft losses take 2.1 N·m: **320.0 N·m**, **110.0 kW**.
- **Base speed:** *K*Φ·ω + *R*·*I*<sub>max</sub> = 350 V gives ω = 333.4/0.9697 = 343.8 rad/s = **3283 rpm**.
- **At 10 000 rpm:** ω = 1047.2 rad/s, field = 333.4/(0.9697 × 1047.2) = **0.328**, *T*<sub>em</sub> = 110 752/1047.2 = 105.8 N·m. The shaft losses take 2.0 N·m: **103.8 N·m**, **108.7 kW**. Friction, iron and windage grow with speed, so the shaft power slips from 110.0 to 108.7 kW while *E*·*I* stays at 110.75 kW.
- **The converter:** *P*<sub>out</sub> = 350 × 332.2 = 116.27 kW; *P*<sub>loss</sub> = 332.2 × (1.2 + 5000 × 10⁻⁶ × 350) = 332.2 × 2.95 = 0.98 kW; *P*<sub>in</sub> = **117.25 kW**, and the converter is 350/352.95 = **99.2 %** efficient. Machine and converter together: 110.0/117.2 = **93.8 %** at the corner.

:::

#### Parts

New component `FieldEMF` in `MyCar`, and a new version of your `DCMachine`: paste the code below.

New component `Converter` in `MyCar`: paste the code below.

New component `ConverterDyno` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `V` | parameter `Voltage` | `350.0`: the supply voltage |
| `I_ref` | parameter `Current` | `500.0`: the current asked of the converter, more than it gives |
| `rpm_start` | parameter `Real` | `0.0`: dyno speed before the ramp |
| `rpm_end` | parameter `Real` | `10000.0`: dyno speed after the ramp |
| `voltage` | BlockComponents › Sources › Constant | `k = V` |
| `supply` | ElectricalComponents › Analog › Sources › VoltageSource | — |
| `current` | BlockComponents › Sources › Constant | `k = I_ref` |
| `converter` | your `Converter` | defaults |
| `machine` | your `DCMachine` | `field_weakening = true` |
| `ground` | ElectricalComponents › Analog › Basic › Ground | — |
| `speed` | BlockComponents › Sources › Ramp | `height = (rpm_end - rpm_start) * pi / 30.0`, `offset = rpm_start * pi / 30.0`, `start_time = 1.0`, `duration = 100.0` |
| `dyno` | RotationalComponents › Sources › VelocitySource | — |
| `mounts` | RotationalComponents › Components › Fixed | — |

:::: info Given parts: the field and the current command

**`FieldEMF`** (inside your machine, as `emf`): the standard library's `RotationalEMF` with one more input, `field`. Its equations are `RotationalEMF`'s with *k* replaced by `field * k`, and it has the same pins, splines and names, so it swaps in without touching a wire. With `field = 1` it is the element you had.

**`Constant`** (`current`): the current command into the converter's `i_ref`, in amperes; positive drives, negative brakes. Asking for 500 A asks for more than the converter will give, so every point of the sweep is a point of the envelope.

The supply, the dyno and the mounts are step 01's.

::::

::: warning Use these names

`p_in`, `p_out`, `n`, `i_ref`, `field`, `d`, `v_in`, `i_in`, `v_out`, `i_out`, `P_in`, `P_out` and `P_loss` are the names the course library's `Vehicle.Electric.Converter` uses, and `field_weakening` and `field` the names its `DCMachine` uses. Keep them, and in step 04 the car takes either converter and either machine.

:::

#### Do this

[![The finished ConverterDyno in Studio: current into the top of converter; supply's p into converter.p_in, converter.p_out into machine.p; converter.n, machine.n, supply.n and ground on one node; converter's field output into machine.field; speed into dyno and both supports to mounts, as in step 01.](/lecture/lecture-04/img/step02-converter-dyno.png)](/lecture/lecture-04/img/step02-converter-dyno.png)

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `FieldEMF`. Toggle to code (⇄), select everything, paste the block below and save.

   ::: code-group

   ```txt [FieldEMF]
   component FieldEMF
     "Positive electrical pin"
     p = Pin() {^p}
     "Negative electrical pin"
     n = Pin() {^n}
     "Rotor spline"
     rotor = Spline() {^rotor}
     "Housing (support) of the emf shaft"
     housing = Spline() {^housing}
     "Flux as a fraction of full flux, 1 for full"
     field = RealInput() {^field}
     "Torque and back-EMF constant KΦ at full flux"
     parameter k::ElectricalTorqueConstant
     "Voltage drop between the two pins"
     variable v::Voltage
     "Current flowing from positive to negative pin"
     variable i::Current
     "Angle of the rotor with respect to the housing"
     variable phi::Angle
     "Angular velocity of the rotor relative to the housing"
     variable w::AngularVelocity
     "Torque on the rotor"
     variable tau::Torque
   relations
     v = p.v - n.v
     0 = p.i + n.i
     i = p.i
     phi = rotor.phi - housing.phi
     w = der(phi)
     v = field * k * w
     tau = -field * k * i
     tau = rotor.tau
     0 = housing.tau + rotor.tau
   metadata {
     "Dyad": {
       "labels": [{"label": "$(instance)", "x": 500, "y": 1200, "rot": 0}],
       "icons": {"default": "dyad://ElectricalComponents/RotationalEMF.svg"}
     },
     "_links": {
       "p": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": 450, "y1": -50, "x2": 550, "y2": 50}}}},
       "n": {"Dyad": {"placement": {"icon": {"iconName": "neg", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}}}},
       "rotor": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}}}},
       "housing": {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}}}},
       "field": {"Dyad": {"placement": {"icon": {"x1": 150, "y1": -50, "x2": 250, "y2": 50, "rot": 90}}}}
     }
   }
   end
   ```

   :::

2. <Badge type="warning" text="Change" /> Open your `DCMachine`, toggle to code, select everything and paste the block below over it.

   ::: code-group

   ```txt [DCMachine]
   component DCMachine
     "Positive electrical pin."
     p = Pin() {^p}
     "Negative electrical pin."
     n = Pin() {^n}
     "Rotor shaft"
     spline = Spline() {^spline}
     "Housing"
     support = Spline() {^support}
     "Flux as a fraction of full flux; present only with field_weakening = true"
     field = RealInput() if field_weakening {^field}
     resistor = ElectricalComponents.Analog.Basic.Resistor(R = R) {^resistor}
     inductor = ElectricalComponents.Analog.Basic.Inductor(L = L) {^inductor}
     emf = FieldEMF(k = k) {^emf}
     rotor = RotationalComponents.Components.Inertia(J = J) {^rotor}
     friction = RotationalComponents.Sources.SignTorque(tau_nominal = -T_f, reg = RotationalComponents.Sources.Regularization.Linear(), w0 = w_reg) {^friction}
     iron = RotationalComponents.Sources.SignTorque(tau_nominal = -K_i, reg = RotationalComponents.Sources.Regularization.Linear(), w0 = w_reg) {^iron}
     windage = RotationalComponents.Sources.QuadraticSpeedDependentTorque(tau_nominal = -k_w * w_base ^ 2, w_nominal = w_base, TorqueDirection = false) {^windage}
     constant_loss = RotationalComponents.Sources.InverseSpeedDependentTorque(tau_nominal = -C / w_reg, w_nominal = w_reg, w0 = w_reg, TorqueDirection = false) {^constant_loss}
     "Expose the field input; off runs at full flux"
     structural parameter field_weakening::Boolean = false
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
     "Voltage across the component (between pin p and pin n)."
     variable v::Voltage
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
     v = p.v - n.v
     connect(p, resistor.p) {^id1}
     connect(resistor.n, inductor.p) {^id2}
     connect(inductor.n, emf.p) {^id3}
     connect(emf.n, n) {^id4}
     connect(emf.rotor, rotor.spline_a, friction.spline, iron.spline, windage.spline, constant_loss.spline) {^id5}
     connect(rotor.spline_b, spline) {^id6}
     connect(emf.housing, friction.support, iron.support, windage.support, constant_loss.support, support) {^id7}
     if field_weakening
       connect(field, emf.field) {^id8}
     else
       emf.field = 1.0
     end
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
     "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/DCMachine.svg"}, "labels": [{"label": "$(instance)", "x": 500, "y": 1150, "rot": 0}]},
     "_links": {
       "id8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 80, "y": 500}, {"x": 80, "y": 320}, {"x": 470, "y": 320}], "E": 2}]}},
       "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 120, "y": 450}], "E": -1}, {"S": 2, "M": [], "E": -1}, {"S": -1, "M": [{"x": 120, "y": 880}], "E": -2}, {"S": 3, "M": [{"x": 360, "y": 800}], "E": -2}, {"S": -2, "M": [], "E": -3}, {"S": -3, "M": [], "E": 6}, {"S": -3, "M": [], "E": -4}, {"S": 4, "M": [{"x": 545, "y": 800}], "E": -4}, {"S": 5, "M": [{"x": 720, "y": 800}, {"x": 720, "y": 880}], "E": -4}], "junctions": [{"x": 120, "y": 800}, {"x": 360, "y": 880}, {"x": 500, "y": 880}, {"x": 545, "y": 880}]}},
       "id6": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "id5": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [], "E": 2}, {"S": -1, "M": [], "E": -2}, {"S": -2, "M": [], "E": -3}, {"S": -2, "M": [], "E": -4}, {"S": -3, "M": [{"x": 490, "y": 750}], "E": 4}, {"S": -3, "M": [{"x": 290, "y": 630}, {"x": 290, "y": 750}], "E": 3}, {"S": -4, "M": [{"x": 690, "y": 750}], "E": 5}, {"S": -4, "M": [{"x": 890, "y": 630}, {"x": 890, "y": 750}], "E": 6}], "junctions": [{"x": 620, "y": 450}, {"x": 620, "y": 630}, {"x": 490, "y": 630}, {"x": 690, "y": 630}]}},
       "id4": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 470, "y": 500}, {"x": 470, "y": 560}, {"x": 60, "y": 560}, {"x": 60, "y": 800}], "E": 2}]}},
       "id3": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 500, "y": 200}], "E": 2}]}},
       "id2": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "id1": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "spline": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}, "diagram": {"x1": 950, "y1": 400, "x2": 1050, "y2": 500}}}},
       "support": {"Dyad": {"placement": {"icon": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}, "diagram": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}}}},
       "p": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}, "diagram": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}}}},
       "n": {"Dyad": {"placement": {"icon": {"iconName": "neg", "x1": -50, "y1": 750, "x2": 50, "y2": 850}, "diagram": {"iconName": "neg", "x1": -50, "y1": 750, "x2": 50, "y2": 850}}}},
       "field": {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}, "diagram": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}}}},
       "resistor": {"Dyad": {"placement": {"diagram": {"x1": 100, "y1": 150, "x2": 200, "y2": 250}}}},
       "inductor": {"Dyad": {"placement": {"diagram": {"x1": 250, "y1": 150, "x2": 350, "y2": 250}}}},
       "emf": {"Dyad": {"placement": {"diagram": {"x1": 450, "y1": 400, "x2": 550, "y2": 500}}}},
       "rotor": {"Dyad": {"placement": {"diagram": {"x1": 700, "y1": 400, "x2": 800, "y2": 500}}}},
       "friction": {"Dyad": {"placement": {"diagram": {"x1": 150, "y1": 700, "x2": 250, "y2": 800}}}},
       "iron": {"Dyad": {"placement": {"diagram": {"x1": 350, "y1": 700, "x2": 450, "y2": 800}}}},
       "windage": {"Dyad": {"placement": {"diagram": {"x1": 550, "y1": 700, "x2": 650, "y2": 800}}}},
       "constant_loss": {"Dyad": {"placement": {"diagram": {"x1": 750, "y1": 700, "x2": 850, "y2": 800}}}}
     }
   }
   end
   ```

   :::

   Four things changed. `emf` is now your `FieldEMF`. The structural parameter `field_weakening` decides whether the machine has a `field` input: the line `field = RealInput() if field_weakening` creates it only when `field_weakening` is true. The `if` block in `relations` wires that input to the EMF, or else holds the field at 1. And the metadata places `field` on the machine's left edge, between `p` and `n`, and routes its wire to `emf`. Left at its default, `false`, this is step 01's machine: run **DCMachineDynoTransient** again and it gives the same 320 N·m and −304 N·m.

3. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `Converter`. Toggle to code, select everything, paste the block below and save.

   ::: code-group

   ```txt [Converter]
   component Converter
     "DC link, positive rail: the battery side"
     p_in = Pin() {^p_in}
     "Output, positive rail: the machine side"
     p_out = Pin() {^p_out}
     "Negative rail, common to input and output"
     n = Pin() {^n}
     "Output current command, positive motoring"
     i_ref = RealInput() {^i_ref}
     "Field command to the machine: flux as a fraction of full"
     field = RealOutput() {^field}
     "Output current limit, the 332.2 A at which the machine gives 320 N.m"
     parameter I_max::Current = 332.2
     "Largest duty: the voltage limit as a fraction of the input"
     parameter d_max::Real = 1.0
     "Current-loop time constant"
     parameter T_i::Time = 1.0e-3
     "Conduction drop of the two devices that carry the current, 0.6 V each"
     parameter V_on::Voltage = 1.2
     "Switching frequency"
     parameter f_s::Frequency = 5.0e3
     "Duration of each switching edge"
     parameter t_sw::Time = 1.0e-6
     "Rounding of the corner of min(1 - field, d_max - |d|)"
     parameter eps::Real = 1.0e-4
     "Input voltage, the DC link"
     variable v_in::Voltage
     "Input current, drawn from the DC link"
     variable i_in::Current
     "Output voltage, across the machine"
     variable v_out::Voltage
     "Output current, into the machine"
     variable i_out::Current
     "Duty ratio, v_out / v_in"
     variable d::Real
     "Current command after the limit"
     variable i_cmd::Current
     "Power drawn from the DC link"
     variable P_in::Power
     "Power delivered to the machine"
     variable P_out::Power
     "Conduction loss"
     variable P_cond::Power
     "Switching loss"
     variable P_sw::Power
     "Sum of the losses"
     variable P_loss::Power
   relations
     v_in = p_in.v - n.v
     v_out = p_out.v - n.v
     i_in = p_in.i
     i_out = -p_out.i
     p_in.i + p_out.i + n.i = 0
     v_out = d * v_in
     i_in = d * i_out + P_loss / v_in
     i_cmd = max(-I_max, min(I_max, i_ref))
     T_i * der(i_out) = i_cmd - i_out
     (1 - field) + (d_max - abs(d)) - sqrt(((1 - field) - (d_max - abs(d))) ^ 2 + eps ^ 2) = 0
     P_in = v_in * i_in
     P_out = v_out * i_out
     P_cond = V_on * abs(i_out)
     P_sw = f_s * t_sw * v_in * abs(i_out)
     P_loss = P_cond + P_sw
   metadata {
     "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/Converter.svg"}, "labels": [{"label": "$(instance)", "x": 500, "y": 1100, "rot": 0}]},
     "_links": {
       "p_in": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}, "diagram": {"iconName": "pos", "x1": -50, "y1": 150, "x2": 50, "y2": 250}}}},
       "p_out": {"Dyad": {"placement": {"icon": {"iconName": "pos", "x1": 950, "y1": 150, "x2": 1050, "y2": 250}, "diagram": {"iconName": "pos", "x1": 950, "y1": 150, "x2": 1050, "y2": 250}}}},
       "n": {"Dyad": {"placement": {"icon": {"iconName": "neg", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}, "diagram": {"iconName": "neg", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}}}},
       "i_ref": {"Dyad": {"placement": {"icon": {"x1": 450, "y1": -50, "x2": 550, "y2": 50, "rot": 90}, "diagram": {"x1": 450, "y1": -50, "x2": 550, "y2": 50, "rot": 90}}}},
       "field": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 650, "x2": 1050, "y2": 750}, "diagram": {"x1": 950, "y1": 650, "x2": 1050, "y2": 750}}}}
     }
   }
   end
   ```

   :::

   The three pins share one negative rail, `n`, as in the deck's chopper: the pack sits between `p_in` and `n`, the machine between `p_out` and `n`. A pin's current counts positive *into* the component, so `i_in = p_in.i` is drawn from the pack and `i_out = -p_out.i` is pushed into the machine, and the three currents sum to zero. The next two lines are the converter's equations; `P_loss / v_in` is the extra input current that pays for the losses. Then the current limit and the current loop, the either-or between field and duty, and the two losses.

4. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `ConverterDyno`. With nothing selected, click **Edit Parameters** → **Add parameter** four times for `V`, `I_ref`, `rpm_start` and `rpm_end`. Place the nine blocks from the table, rename each to its **Name** and set the values in its **Set** column. Studio draws `machine`'s `field` input on its left edge, between `p` and `n`, whatever `field_weakening` says; it only exists once `field_weakening` is ticked `true`.
5. Wire:
   - `voltage.y → supply.V`
   - `supply.p → converter.p_in`
   - `converter.p_out → machine.p`
   - `machine.n → converter.n`, `supply.n → converter.n`, and `converter.n → ground.g`
   - `current.y → converter.i_ref`
   - `converter.field → machine.field`
   - `speed.y → dyno.w_ref`
   - `machine.spline → dyno.spline`
   - `machine.support → mounts.spline`, and `dyno.support → mounts.spline`
6. <Badge type="tip" text="New analysis" /> Toggle to code. Add these two lines in the `relations` section, so that the dyno's angle and the current start at zero:

   ```txt
   initial dyno.phi = 0
   initial converter.i_out = 0
   ```

   The converter sets the current now, so the machine's inductor carries `converter.i_out`: step 01's `initial machine.inductor.i = 0` would set the same current twice. Then add the analysis below the component:

   ```txt
   analysis ConverterDynoTransient
     extends TransientAnalysis(stop = 102.0, alg = ODEAlg.Rodas5P(), saveat = 0.05, tstops = [1.0, 101.0])
     parameter V::Voltage = 350.0
     parameter I_ref::Current = 500.0
     parameter rpm_start::Real = 0.0
     parameter rpm_end::Real = 10000.0
     model = ConverterDyno(V = V, I_ref = I_ref, rpm_start = rpm_start, rpm_end = rpm_end)
   end
   ```

   The dyno holds standstill for a second while the current rises, sweeps to 10 000 rpm in 100 s, and holds again.
7. Click ▷ **Run Analysis → ConverterDynoTransient** once, then plot the envelope, the shaft power, and the duty against the field:

   ```julia
   using Plots; plotly()
   r = MyCar.ConverterDynoTransient();
   rpm = r.sol[r."machine.w"] .* 30 ./ pi;
   plot(rpm[21:end], r.sol[r."machine.tau"][21:end]; xlabel = "rpm", ylabel = "N·m", label = "shaft torque")
   plot(rpm[21:end], r.sol[r."machine.P_mech"][21:end] ./ 1e3; xlabel = "rpm", ylabel = "kW", label = "shaft power")
   plot(rpm[21:end], [r.sol[r."converter.d"][21:end] r.sol[r."converter.field"][21:end]]; xlabel = "rpm", label = ["duty d" "field"])
   ```

   Points 1 to 20 are the first second at standstill, so the curves start at point 21, *t* = 1 s.
8. Check that the power balances, and that the torque is 1/ω above base speed:

   ```julia
   r.sol[r."converter.P_in"][end], r.sol[r."converter.P_out"][end], r.sol[r."converter.P_loss"][end]
   r.sol[r."machine.tau_em"][end] * r.sol[r."machine.w"][end]
   ```

9. Run it on a lower pack voltage, at part load, and braking:

   ```julia
   r = MyCar.ConverterDynoTransient(V = 300.0);
   plot(r.sol[r."machine.w"][21:end] .* 30 ./ pi, r.sol[r."machine.P_mech"][21:end] ./ 1e3)
   r = MyCar.ConverterDynoTransient(I_ref = 150.0);
   plot(r.sol[r."machine.w"][21:end] .* 30 ./ pi, r.sol[r."machine.tau"][21:end])
   r = MyCar.ConverterDynoTransient(I_ref = -500.0);
   plot(r.sol[r."machine.w"][21:end] .* 30 ./ pi, r.sol[r."converter.P_in"][21:end] ./ 1e3)
   ```

::: tip Expected result

**The envelope:** `converter.i_out` is **332.2 A** from the first few milliseconds to the end: the converter was asked for 500 A and gives its limit. At standstill `converter.d` is **0.047**: 16.6 V is all it takes to push 332.2 A through 0.05 Ω. Up to base speed `converter.field` stays at **1**, the duty rises in a straight line with the back-EMF (**0.60** at 1900 rpm), `machine.tau_em` holds **322.1 N·m**, and the shaft gives **319.1 N·m** at 1900 rpm: the air-gap torque less the losses and the 0.52 N·m the dyno spends accelerating the rotor. Near 95 rpm the shaft torque dips to **300 N·m**: step 01's constant 200 W loss is a torque *C*/ω, 20 N·m there.

**The corner:** the duty reaches **1** at **3283 rpm**, and there the field starts to fall. Held at 3283 rpm (`rpm_start = rpm_end = 3283.0`) the shaft gives **320.0 N·m**, **110.0 kW**.

**Above base speed:** the duty stays at 1, the field falls as 1/ω (**0.66** at 5000 rpm, **0.328** at 10 000 rpm), and so does the torque: **209 N·m** at 5000 rpm, **103.8 N·m** held at 10 000 rpm. `machine.tau_em` × `machine.w` is **110.75 kW** all the way; the shaft power slips from 110.0 to **108.7 kW** as friction, iron loss and windage grow with speed.

**The power:** at the end `converter.P_in` is **117.25 kW**, `converter.P_out` **116.27 kW**, and `converter.P_loss` **0.98 kW**, their difference to the watt, at every instant. The converter is **99.2 %** efficient at 350 V out. Its losses track the current, not the power, so at 1000 rpm and 220 N·m, 113 V out, it is 97.5 %: ORNL measured 96–98 % over most of the Leaf inverter's map, and 99 % at high speed.

**300 V:** the voltage runs out sooner. The corner moves to **2791 rpm** and the power above it drops to 94.1 kW in the air gap, 92 kW at the shaft. A sagging pack does this in step 03.

**150 A:** 145.5 N·m in the air gap up to **3373 rpm**: less current needs less *R*·*i*, so the voltage lasts slightly longer. Above it the power holds at 51.4 kW in the air gap.

**−500 A, braking:** −332.2 A and a negative torque at every speed. Above **3610 rpm** the back-EMF would push more than 350 V into the pack, and the converter weakens the field here too. At 10 000 rpm `converter.P_in` is **−115.3 kW**: power flowing back into the supply. At standstill there is no back-EMF to brake with, so the supply pays the copper loss: **+6.5 kW** in.

Reference: `HandsOn04.FieldEMF`, `HandsOn04.DCMachine`, `HandsOn04.Converter`, `HandsOn04.ConverterDyno`, `HandsOn04.ConverterDynoTransient`; the course library's copies are `Vehicle.Electric.FieldEMF`, `Vehicle.Electric.DCMachine` and `Vehicle.Electric.Converter`.

:::

Commit: **Source Control** → message `Step 02: converter` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `FieldEMF`, `DCMachine` and `Converter` from steps 1 to 3 of **Do this** above. Then right-click `MyCar` → **Add Component**, name it `ConverterDyno`, toggle to code (⇄) and paste this over its contents.

::: code-group

```txt [ConverterDyno]
component ConverterDyno
  "Supply voltage at the converter's input"
  parameter V::Voltage = 350.0
  "Current asked of the converter"
  parameter I_ref::Current = 500.0
  "Dyno speed before the ramp [rpm]"
  parameter rpm_start::Real = 0.0
  "Dyno speed after the ramp [rpm]"
  parameter rpm_end::Real = 10000.0
  voltage = BlockComponents.Sources.Constant(k = V) {^voltage}
  supply = ElectricalComponents.Analog.Sources.VoltageSource() {^supply}
  current = BlockComponents.Sources.Constant(k = I_ref) {^current}
  converter = Converter() {^converter}
  machine = DCMachine(field_weakening = true) {^machine}
  ground = ElectricalComponents.Analog.Basic.Ground() {^ground}
  speed = BlockComponents.Sources.Ramp(height = (rpm_end - rpm_start) * pi / 30.0, offset = rpm_start * pi / 30.0, start_time = 1.0, duration = 100.0) {^speed}
  dyno = RotationalComponents.Sources.VelocitySource() {^dyno}
  mounts = RotationalComponents.Components.Fixed() {^mounts}
relations
  initial dyno.phi = 0
  initial converter.i_out = 0
  connect(voltage.y, supply.V) {^id1}
  connect(supply.p, converter.p_in) {^id2}
  connect(converter.p_out, machine.p) {^id3}
  connect(converter.n, machine.n, supply.n, ground.g) {^id4}
  connect(current.y, converter.i_ref) {^id7}
  connect(converter.field, machine.field) {^id8}
  connect(speed.y, dyno.w_ref) {^id9}
  connect(machine.spline, dyno.spline) {^id10}
  connect(machine.support, mounts.spline) {^id11}
  connect(dyno.support, mounts.spline) {^id12}
metadata {
  "_links": {
    "id12": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 800, "y": 720}, {"x": 800, "y": 800}], "E": 2}]}},
    "id11": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 650, "y": 500}], "E": 2}]}},
    "id10": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 970, "y": 400}, {"x": 970, "y": 670}], "E": 2}]}},
    "id9": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "id8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 580, "y": 440}, {"x": 580, "y": 400}], "E": 2}]}},
    "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 440, "y": 170}], "E": 2}]}},
    "id4": {"Dyad": {"edges": [{"S": 2, "M": [{"x": 600, "y": 460}, {"x": 600, "y": 500}], "E": 1}, {"S": 1, "M": [{"x": 320, "y": 500}], "E": -1}, {"S": -1, "M": [], "E": 3}, {"S": -1, "M": [], "E": 4}], "junctions": [{"x": 320, "y": 550}]}},
    "id3": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "id2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 20, "y": 550}, {"x": 20, "y": 340}], "E": 2}]}},
    "id1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 250, "y": 430}], "E": 2}]}},
    "voltage": {"Dyad": {"placement": {"diagram": {"x1": 60, "y1": 380, "x2": 160, "y2": 480}}}},
    "supply": {"Dyad": {"placement": {"diagram": {"x1": 200, "y1": 500, "x2": 300, "y2": 600}}}},
    "current": {"Dyad": {"placement": {"diagram": {"x1": 220, "y1": 120, "x2": 320, "y2": 220}}}},
    "converter": {"Dyad": {"placement": {"diagram": {"x1": 340, "y1": 300, "x2": 540, "y2": 500}}}},
    "machine": {"Dyad": {"placement": {"diagram": {"x1": 640, "y1": 300, "x2": 840, "y2": 500}}}},
    "ground": {"Dyad": {"placement": {"diagram": {"x1": 280, "y1": 640, "x2": 360, "y2": 720}}}},
    "speed": {"Dyad": {"placement": {"diagram": {"x1": 660, "y1": 620, "x2": 760, "y2": 720}}}},
    "dyno": {"Dyad": {"placement": {"diagram": {"x1": 840, "y1": 620, "x2": 940, "y2": 720}}}},
    "mounts": {"Dyad": {"placement": {"diagram": {"x1": 600, "y1": 800, "x2": 700, "y2": 900}}}}
  }
}
end

analysis ConverterDynoTransient
  extends TransientAnalysis(stop = 102.0, alg = ODEAlg.Rodas5P(), saveat = 0.05, tstops = [1.0, 101.0])
  "Supply voltage at the converter's input"
  parameter V::Voltage = 350.0
  "Current asked of the converter"
  parameter I_ref::Current = 500.0
  "Dyno speed before the ramp [rpm]"
  parameter rpm_start::Real = 0.0
  "Dyno speed after the ramp [rpm]"
  parameter rpm_end::Real = 10000.0
  model = ConverterDyno(V = V, I_ref = I_ref, rpm_start = rpm_start, rpm_end = rpm_end)
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

[![The finished BatteryDischarge in Studio: load_profile into the top of load; load's p wired to battery's p on the left, load's n to battery's n on the right, and battery.n to ground.](/lecture/lecture-04/img/step03-battery-discharge.png)](/lecture/lecture-04/img/step03-battery-discharge.png)

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `Battery`. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save.

   ::: code-group

   ```txt [Battery]
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
   metadata {
     "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/Battery.svg"}}
   }
   end
   ```

   :::

   `extends … TwoPin` gives the battery its two pins, `p` on the left and `n` on the right, and the terminal voltage `v = p.v - n.v`. A pin's current counts positive *into* the component, so the current that comes back into `n` is the one that left `p` through the load: `i = n.i`, and `p.i + n.i = 0` says the battery stores no charge on its terminals. The last two lines are the two equations above; `Q_nom` is in coulombs, so 114.3 A·h is written as 40 kWh × 3600 s/h over 350 V.

   If the compile flags `ElectricalComponents` as `missing-direct-dependency`, run the `Pkg.add` lines of [step 00](#step-00), then <kbd>F1</kbd> → **Dyad: Restart Language Server** and compile again.

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
  load_profile = BlockComponents.Sources.Step(height = I_load, offset = 0.0, start_time = 60.0) {^load_profile}
  load = ElectricalComponents.Analog.Sources.CurrentSource() {^load}
  battery = Battery() {^battery}
  ground = ElectricalComponents.Analog.Basic.Ground() {^ground}
relations
  connect(load_profile.y, load.I) {^id1}
  connect(battery.p, load.p) {^id2}
  connect(battery.n, load.n, ground.g) {^id3}
metadata {
  "_links": {
    "load_profile": {"Dyad": {"placement": {"diagram": {"x1": 260, "y1": 150, "x2": 360, "y2": 250}}}},
    "load": {"Dyad": {"placement": {"diagram": {"x1": 450, "y1": 300, "x2": 550, "y2": 400}}}},
    "battery": {"Dyad": {"placement": {"diagram": {"x1": 450, "y1": 600, "x2": 550, "y2": 700}}}},
    "ground": {"Dyad": {"placement": {"diagram": {"x1": 620, "y1": 760, "x2": 700, "y2": 840}}}},
    "id1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 500, "y": 200}], "E": 2}]}},
    "id2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 380, "y": 650}, {"x": 380, "y": 350}], "E": 2}]}},
    "id3": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [{"x": 660, "y": 350}], "E": 2}, {"S": -1, "M": [], "E": 3}], "junctions": [{"x": 660, "y": 650}]}}
  }
}
end

analysis BatteryDischargeTransient
  extends TransientAnalysis(stop = 1860.0, tstops = [60.0])
  "Current drawn from the battery once the load is on; negative charges it"
  parameter I_load::Current = 100.0
  model = BatteryDischarge(I_load = I_load)
end
```

:::

::::

---

## 07 The car and regen

### 04 · The car: machine → 8.193 → differential → front wheels {#step-04}

Put steps 01–03 into a car. The battery feeds the converter, the converter the machine, the machine turns the Leaf's single 8.193 reduction, and the reduction turns the planar car's differential, which shares its torque between the two front wheels. The 12 V auxiliaries hang on the battery. A PI driver follows WLTC: the car drives the cycle's **23.27 km** to within a few metres and never more than **1.6 km/h** off the trace, and the battery goes from 0.9 to **0.822**.

#### Given

The Leaf ZE1 reduction, **8.193** from the motor to the differential. The differential is a planetary gear that splits its input torque equally between two wheels and lets them turn at different speeds:

$$
\omega_{machine} = 8.193\;\frac{\omega_{fl} + \omega_{fr}}{2} \qquad \tau_{fl} = \tau_{fr} = \frac{8.193\;\tau_{machine}}{2}
$$

The car is Lecture 3's planar car with the course road load (`PlanarRoadLoad`: 1500 kg, *C*<sub>d</sub>*A* = 0.63 m², *f*<sub>r</sub> = 0.012), and the cycle the WLTC class 3b trace of Lecture 2. Both are prepared in the course library, as are `AuxLoad`, the 12 V network as a constant **300 W** draw on the battery, and `TorqueSplit`, which shares the driver's torque between the machine and the friction brakes.

::: info Torque in, current out

The driver thinks in torque, the converter in current. The drive turns one into the other: the machine gives *field*·*K*Φ newton-metres per ampere, so it asks the converter for `i_ref = tau_ref / (converter.field * machine.k)`. Below base speed (about 48 km/h in this car) the field is 1; above it the converter weakens the field, at 131 km/h to about a third, and the same torque takes three times the current. A field-oriented drive does the same with its q-axis current.

Divided by full field only, the drive would give a third of the torque asked for at 131 km/h, and the driver's loop gain would fall with it on the motorway. Divided by the present field, a torque command means the same torque at any speed.

:::

::: info Braking: the machine first, the friction brakes at walking pace

When the driver's output goes negative, the car has to slow down. The machine can do it: asked for a negative torque, it turns generator, the converter's and the battery's currents reverse, and the pack charges. WLTC never brakes harder than 1.5 m/s², about 85 N·m at the machine for the body alone (the run peaks at 87 N·m), well inside its 320 N·m, so above walking pace the machine does all the braking.

Near standstill it must not: a machine asked for a negative torque at a stop drives the car backwards. So the machine's share fades linearly from all of it at **10 km/h** (`v_fade`) to none at standstill, and the planar car's own front friction brakes take the rest, at the same wheel torque. A friction brake only ever opposes motion, so the car stops and is held at every stop without rolling back. The course library's `TorqueSplit` block does this split. Step 05 extends it to real blending onto Lecture 3's hydraulic brakes, with the machine's and the battery's limits.

:::

#### Parts

New component `ElectricDrive` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `ratio` | parameter `Real` | `8.193`: the reduction |
| `P_aux` | parameter `Power` | `300.0`: the 12 V network |
| `tau_ref` | Dyad › RealInput | the machine torque asked for |
| `spline` | Dyad › Spline | the reduction's output, to the differential |
| `support` | Dyad › Spline | the machine housing and gear case |
| `SoC` | Dyad › RealOutput | the battery's state of charge |
| `battery` | your `Battery` | defaults |
| `aux` | VehicleSystemsComponents › Vehicle › Electric › AuxLoad | `P_aux = P_aux` |
| `converter` | your `Converter` | defaults |
| `machine` | your `DCMachine` | `field_weakening = true` |
| `ground` | ElectricalComponents › Analog › Basic › Ground | — |
| `reduction` | RotationalComponents › Components › IdealGear | `ratio = ratio` |

New component `BEVWLTC` in `MyCar`: paste the code below. It is the course library's planar WLTC bench with your drive on the front axle.

:::: info Given parts: the reduction, the differential and the auxiliaries

**`IdealGear`** (`reduction`): a lossless gear. `spline_a` turns `ratio` times faster than `spline_b`, and `spline_b` carries `ratio` times the torque; the housing reaction goes to `support`. Put the machine on `spline_a`.

**`DifferentialGear`** (`differential`, in the bench): MultibodyComponents › PlanarMechanics. The torque on `flange_b` is split equally between `flange_left` and `flange_right`, and `flange_b` turns at their average speed. It needs no housing.

**`AuxLoad`** (`aux`): draws the current that makes *v*·*i* = `P_aux` from the pins it sits across, following the voltage within 10 ms. It stands for the DC-DC converter and everything on the 12 V network: control units, pumps, fans, lights.

**`TorqueSplit`** (`split`, in the bench): VehicleSystemsComponents › Vehicle › Electric. Takes the driver's torque `tau_ref` and the speed `v` in km/h. Gives `tau_motor`, all of a positive `tau_ref` and the share `fade = clamp(v / v_fade, 0, 1)` of a negative one, and `tau_brake`, the rest of a negative one as a torque for each front brake: `-(1 - fade) min(tau_ref, 0) ratio / 2`.

::::

::: warning Use these names

The bench and step 06 read `drive.battery`, `drive.converter`, `drive.machine`, `drive.aux` and `drive.SoC`. Keep the names, and either your drive or the course library's `Vehicle.Electric.ElectricDrive` fits.

:::

#### Do this

[![The finished ElectricDrive in Studio: battery and aux side by side across one positive and one negative rail; converter fed from the positive rail, its p_out into machine.p and its field into machine.field; machine.n and ground on the negative rail; machine into reduction and reduction into the spline port; battery.SoC up to the SoC port, tau_ref at the top left, support at the bottom.](/lecture/lecture-04/img/step04-electric-drive.png)](/lecture/lecture-04/img/step04-electric-drive.png)

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `ElectricDrive`. With nothing selected, click **Edit Parameters** → **Add parameter**: `ratio`, type `Real`, value `8.193`, and `P_aux`, type `Power`, value `300.0`. Place the parts from the table and rename each to its **Name**. Set `machine`'s `field_weakening` to `true`, `aux`'s `P_aux` to `P_aux` and `reduction`'s `ratio` to `ratio`.
2. Wire:
   - `battery.p → converter.p_in`, and `battery.p → aux.p`
   - `battery.n → converter.n`, `battery.n → aux.n`, `battery.n → machine.n` and `battery.n → ground.g`
   - `converter.p_out → machine.p`, and `converter.field → machine.field`
   - `machine.spline → reduction.spline_a`, and `reduction.spline_b → spline`
   - `machine.support → reduction.support`, and `reduction.support → support`
   - `battery.SoC → SoC`
3. Toggle to code and add one line at the end of `relations`, the torque-to-current conversion at the present field:

   ```txt
   converter.i_ref = tau_ref / (converter.field * machine.k)
   ```

   If the compile flags `VehicleSystemsComponents` or `MultibodyComponents` as `missing-direct-dependency`, run the `Pkg.add` lines of [step 00](#step-00), then <kbd>F1</kbd> → **Dyad: Restart Language Server** and compile again.
4. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `BEVWLTC`. Toggle to code (⇄), select everything, paste the block below and save.

   ::: code-group

   ```txt [BEVWLTC]
   component BEVWLTC
     "Vehicle mass, shared by the car and its road load (probe)"
     parameter m::Mass = 1500.0
     "Wheel radius (repository default)"
     parameter radius::Length = 0.31
     "Driver gain, machine torque per km/h of speed error (assumed)"
     parameter k::Real = 50.0
     "Driver integral time (assumed)"
     parameter Ti::Time = 2.0
     "Driver torque limit, the machine's peak torque (Nissan)"
     parameter tau_max::Torque = 320.0
     "Speed below which the machine's braking share fades to zero, km/h (assumed)"
     parameter v_fade::Real = 10.0
     "Power drawn by the 12 V network (assumed)"
     parameter P_aux::Power = 300.0
     "Single-speed reduction (Nissan)"
     parameter ratio::Real = 8.193
     "Initial wheel surface speed above the body's, keeps the start off zero slip (assumed)"
     parameter dv_wheel::Velocity = 0.01
     trace = VehicleSystemsComponents.Vehicle.DriveCycle() {^trace}
     driver = BlockComponents.Continuous.LimPID(with_D = false, k = k, Ti = Ti, y_max = tau_max, y_min = -tau_max) {^driver}
     no_ff = BlockComponents.Sources.Constant(k = 0.0) {^no_ff}
     kmh = VehicleSystemsComponents.Vehicle.ToKmPerHour() {^kmh}
     drive = ElectricDrive(ratio = ratio, P_aux = P_aux) {^drive}
     differential = MultibodyComponents.PlanarMechanics.DifferentialGear() {^differential}
     mount = RotationalComponents.Components.Fixed() {^mount}
     straight = RotationalComponents.Components.Fixed() {^straight}
     flat = BlockComponents.Sources.Constant(k = 0.0) {^flat}
     car = VehicleSystemsComponents.Vehicle.Planar.PlanarCar(m = m, radius = radius) {^car}
     motion = VehicleSystemsComponents.Vehicle.Planar.BusMotion() {^motion}
     roadload = VehicleSystemsComponents.Vehicle.Planar.PlanarRoadLoad(m = m) {^roadload}
     split = VehicleSystemsComponents.Vehicle.Electric.TorqueSplit(ratio = ratio, v_fade = v_fade) {^split}
   relations
     connect(car.bus, motion.bus) {^wbus}
     connect(trace.y, driver.u_s) {^w1}
     connect(motion.vx, kmh.u) {^w2}
     connect(kmh.y, driver.u_m, split.v) {^w3}
     connect(no_ff.y, driver.u_ff) {^w4}
     connect(drive.spline, differential.flange_b) {^w5}
     connect(differential.flange_left, car.spin_fl) {^w6}
     connect(differential.flange_right, car.spin_fr) {^w7}
     connect(drive.support, mount.spline) {^w8}
     connect(car.steering, straight.spline) {^w9}
     connect(flat.y, roadload.grade) {^w10}
     connect(car.chassis, roadload.chassis) {^w11}
     connect(driver.y, split.tau_ref) {^w21}
     connect(split.tau_motor, drive.tau_ref) {^w23}
     connect(split.tau_brake, car.tau_fl, car.tau_fr) {^w24}
     car.tau_rl = 0.0
     car.tau_rr = 0.0
     initial car.body.r = [0, 0]
     initial car.body.v = [0, 0]
     initial car.body.phi = 0.0
     initial car.body.w = 0.0
     initial car.fl.inertia.w = dv_wheel / radius
     initial car.fr.inertia.w = dv_wheel / radius
     initial car.rl.inertia.w = dv_wheel / radius
     initial car.rr.inertia.w = dv_wheel / radius
     initial car.fl.inertia.phi = 0.0
     initial car.fr.inertia.phi = 0.0
     initial car.rl.inertia.phi = 0.0
     initial car.rr.inertia.phi = 0.0
     initial car.fl.brake.tau_actual = 0.0
     initial car.fr.brake.tau_actual = 0.0
     initial car.rl.brake.tau_actual = 0.0
     initial car.rr.brake.tau_actual = 0.0
     initial drive.converter.i_out = 0.0
   metadata {
     "_links": {
       "wbus": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "trace": {"Dyad": {"placement": {"diagram": {"x1": 20, "y1": 57, "x2": 100, "y2": 137}}}},
       "driver": {"Dyad": {"placement": {"diagram": {"x1": 140, "y1": 70, "x2": 240, "y2": 170}}}},
       "no_ff": {"Dyad": {"placement": {"diagram": {"x1": 100, "y1": 10, "x2": 140, "y2": 50}}}},
       "kmh": {"Dyad": {"placement": {"diagram": {"x1": 40, "y1": 190, "x2": 110, "y2": 260}}}},
       "drive": {"Dyad": {"placement": {"diagram": {"x1": 430, "y1": 50, "x2": 530, "y2": 150}}}},
       "differential": {"Dyad": {"placement": {"diagram": {"x1": 560, "y1": 260, "x2": 640, "y2": 340}}}},
       "mount": {"Dyad": {"placement": {"diagram": {"x1": 485, "y1": 190, "x2": 545, "y2": 240}}}},
       "straight": {"Dyad": {"placement": {"diagram": {"x1": 605, "y1": 500, "x2": 655, "y2": 550, "rot": 180}}}},
       "flat": {"Dyad": {"placement": {"diagram": {"x1": 440, "y1": 880, "x2": 480, "y2": 920}}}},
       "car": {"Dyad": {"placement": {"diagram": {"x1": 520, "y1": 600, "x2": 740, "y2": 820}}}},
       "motion": {"Dyad": {"placement": {"diagram": {"x1": 775, "y1": 610, "x2": 975, "y2": 810}}}},
       "roadload": {"Dyad": {"placement": {"diagram": {"x1": 500, "y1": 865, "x2": 570, "y2": 935}}}},
       "split": {"Dyad": {"placement": {"diagram": {"x1": 290, "y1": 70, "x2": 390, "y2": 170}}}},
       "w1": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 990, "y": 662.0}, {"x": 990, "y": 980}, {"x": 20, "y": 980}, {"x": 20, "y": 225}], "E": 2}]}},
       "w3": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [{"x": 125, "y": 143}], "E": 2}, {"S": -1, "M": [{"x": 270, "y": 225}, {"x": 270, "y": 140}], "E": 3}], "junctions": [{"x": 125, "y": 225}]}},
       "w4": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 190, "y": 30}], "E": 2}]}},
       "w5": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 550, "y": 100}, {"x": 550, "y": 344}], "E": 2}]}},
       "w6": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 480, "y": 300}, {"x": 480, "y": 655}], "E": 2}]}},
       "w7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 765, "y": 300}, {"x": 765, "y": 655}], "E": 2}]}},
       "w8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 515, "y": 150}], "E": 2}]}},
       "w9": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w10": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w11": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 680, "y": 820}, {"x": 680, "y": 900}], "E": 2}]}},
       "w21": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 265, "y": 120}, {"x": 265, "y": 100}], "E": 2}]}},
       "w23": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w24": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 410, "y": 140}, {"x": 410, "y": 633}], "E": -1}, {"S": -1, "M": [], "E": 2}, {"S": -1, "M": [{"x": 500, "y": 470}, {"x": 750, "y": 470}, {"x": 750, "y": 633}], "E": 3}], "junctions": [{"x": 500, "y": 633}]}}
     }
   }
   end

   analysis BEVWLTCTransient
     extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
     parameter k::Real = 50.0
     parameter Ti::Time = 2.0
     parameter v_fade::Real = 10.0
     parameter P_aux::Power = 300.0
     model = BEVWLTC(k = k, Ti = Ti, v_fade = v_fade, P_aux = P_aux)
   end
   ```

   :::

   The last three `connect` lines are the driver's output split: the driver's torque goes into `split`, which also gets the car's speed from `kmh.y`, `split.tau_motor` drives your `ElectricDrive`, and `split.tau_brake` goes to both front brakes. The `initial` lines are the library bench's: the car starts at rest with its wheels turning 0.01 m/s ahead of it, because the tire model cannot start from exact zero slip.
5. Click ▷ **Run Analysis → BEVWLTCTransient** once, then plot the speed against the trace, the battery and the machine:

   ```julia
   using Plots; plotly()
   r = MyCar.BEVWLTCTransient();
   plot(r; idxs = [r."trace.y", r."kmh.y"])
   plot(r; idxs = [r."drive.battery.i", r."drive.SoC", r."drive.converter.field"], layout = (3, 1))
   r.sol[r."car.bus.x"][end], r.sol[r."drive.SoC"][end]
   ```

::: tip Expected result

`kmh.y` lies on `trace.y` all the way: the worst gap is **1.63 km/h**, inside WLTP's ±2 km/h. `car.bus.x` ends at **23 267 m**, the trace's 23 266 m, and at every stop the car stands still to a thousandth of a km/h, never backwards.

`drive.battery.i` peaks at **138 A** (46 kW) in the Extra High phase and goes as low as **−86 A** (31 kW charging) under braking; between, the 300 W of auxiliaries draw 0.86 A. `drive.SoC` falls from **0.9** to **0.822**: 3.1 kWh of the 40. `drive.converter.field` is **1** below about 48 km/h and falls to **0.36** at the cycle's 131 km/h, where the machine turns 9260 rpm. The driver never asks for more than **117 N·m**, and the machine gives it at every speed to within 0.2 N·m.

The run takes about 7 s once compiled.

Reference: `HandsOn04.ElectricDrive`, `HandsOn04.BEVWLTC`, `HandsOn04.BEVWLTCTransient`; the course library's copies are `Vehicle.Electric.ElectricDrive` and `Vehicle.Planar.PlanarBEVWLTC`.

:::

Commit: **Source Control** → message `Step 04: the car` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `BEVWLTC` from step 4 of **Do this** above. Then right-click `MyCar` → **Add Component**, name it `ElectricDrive`, toggle to code (⇄) and paste this over its contents.

::: code-group

```txt [ElectricDrive]
component ElectricDrive
  "Machine torque asked for, positive motoring"
  tau_ref = RealInput() {^tau_ref}
  "Reduction output shaft, to the differential"
  spline = Spline() {^spline}
  "Machine housing and gear case"
  support = Spline() {^support}
  "Battery state of charge"
  SoC = RealOutput() {^SoC}
  battery = Battery() {^battery}
  aux = VehicleSystemsComponents.Vehicle.Electric.AuxLoad(P_aux = P_aux) {^aux}
  converter = Converter() {^converter}
  machine = DCMachine(field_weakening = true) {^machine}
  ground = ElectricalComponents.Analog.Basic.Ground() {^ground}
  reduction = RotationalComponents.Components.IdealGear(ratio = ratio) {^reduction}
  "Single-speed reduction, Leaf ZE1"
  parameter ratio::Real = 8.193
  "Power drawn by the 12 V network"
  parameter P_aux::Power = 300.0
relations
  connect(battery.p, converter.p_in, aux.p) {^w1}
  connect(battery.n, converter.n, aux.n, machine.n, ground.g) {^w2}
  connect(converter.p_out, machine.p) {^w3}
  connect(converter.field, machine.field) {^w4}
  connect(machine.spline, reduction.spline_a) {^w5}
  connect(reduction.spline_b, spline) {^w6}
  connect(machine.support, reduction.support, support) {^w7}
  connect(battery.SoC, SoC) {^w8}
  converter.i_ref = tau_ref / (converter.field * machine.k)
metadata {
  "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/ElectricDrive.svg"}},
  "_links": {
    "tau_ref": {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}, "diagram": {"x1": -50, "y1": 150, "x2": 50, "y2": 250}}}},
    "spline": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}, "diagram": {"x1": 950, "y1": 400, "x2": 1050, "y2": 500}}}},
    "support": {"Dyad": {"placement": {"icon": {"iconName": "support", "x1": 450, "y1": 950, "x2": 550, "y2": 1050}, "diagram": {"iconName": "support", "x1": 788, "y1": 950, "x2": 888, "y2": 1050}}}},
    "SoC": {"Dyad": {"placement": {"icon": {"x1": 450, "y1": -50, "x2": 550, "y2": 50, "rot": 270}, "diagram": {"x1": 135, "y1": -50, "x2": 235, "y2": 50, "rot": 270}}}},
    "battery": {"Dyad": {"placement": {"diagram": {"x1": 30, "y1": 390, "x2": 150, "y2": 510, "rot": 90}}}},
    "aux": {"Dyad": {"placement": {"diagram": {"x1": 230, "y1": 390, "x2": 350, "y2": 510, "rot": 90}}}},
    "converter": {"Dyad": {"placement": {"diagram": {"x1": 380, "y1": 360, "x2": 560, "y2": 540}}}},
    "machine": {"Dyad": {"placement": {"diagram": {"x1": 640, "y1": 360, "x2": 820, "y2": 540}}}},
    "ground": {"Dyad": {"placement": {"diagram": {"x1": 545, "y1": 720, "x2": 625, "y2": 800}}}},
    "reduction": {"Dyad": {"placement": {"diagram": {"x1": 855, "y1": 405, "x2": 945, "y2": 495}}}},
    "w1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 90, "y": 260}], "E": -1}, {"S": -1, "M": [{"x": 365, "y": 260}, {"x": 365, "y": 396}], "E": 2}, {"S": 3, "M": [], "E": -1}], "junctions": [{"x": 290, "y": 260}]}},
    "w2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 90, "y": 680}], "E": -1}, {"S": 3, "M": [], "E": -1}, {"S": -1, "M": [], "E": -2}, {"S": -2, "M": [], "E": 5}, {"S": -3, "M": [], "E": -2}, {"S": 2, "M": [], "E": -3}, {"S": 4, "M": [{"x": 585, "y": 504}], "E": -3}], "junctions": [{"x": 290, "y": 680}, {"x": 585, "y": 680}, {"x": 585, "y": 540}]}},
    "w3": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "w4": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 610, "y": 486}, {"x": 610, "y": 450}], "E": 2}]}},
    "w5": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "w6": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
    "w7": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": 2, "M": [{"x": 838, "y": 495}], "E": -1}, {"S": -1, "M": [], "E": 3}], "junctions": [{"x": 838, "y": 540}]}},
    "w8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 185, "y": 450}], "E": 2}]}}
  }
}
end
```

:::

::::

---

### 05 · Regen blended onto the Lecture 3 brakes {#step-05}

Give the brake demand to the machine first, up to the smallest of three limits, and the rest to Lecture 3's friction brakes. A fourth rule withdraws regen while the ABS acts on either driven (front) wheel. On the dry ABS stop from 80 km/h this changes the stop from **36.22 m** to **38.84 m**, and the machine/friction share from **49.32/50.68 %** to **1.62/98.38 %**. On WLTC no limit binds above walking pace: the battery gets back **23.85 %** of the traction energy, and the friction brakes burn almost nothing.

#### Given

**Series blending.** The driver's brake demand goes to the machine first, as much as it can take; only the rest goes to the friction brakes. The machine can take the smallest of three limits, each a torque at the machine:

| Limit | Torque ceiling | Value | Source |
| --- | --- | --- | --- |
| torque | `tau_max` | **320 N·m**, the machine's peak | Nissan ZE1 |
| charge power | `P_charge / w` | **80.5 kW**: a 2013 Leaf pack's 10 s charge capability at 20 % depth of discharge; the ZE1's larger pack takes more | INL |
| low-speed fade | `tau_max · clamp(v / v_fade, 0, 1)` | **`v_fade` = 10 km/h**; no primary source, the plan's band is 5–10 km/h | assumed |

$$
\tau_{regen} = \min\!\left(\tau_{demand},\ \tau_{max},\ \frac{P_{charge}}{\omega},\ \tau_{max}\,\mathrm{clamp}\!\left(\frac{v}{v_{fade}},0,1\right)\right)
\qquad
\tau_{brake} = \frac{(\tau_{demand} - \tau_{regen})\cdot 8.193}{4}
$$

`w` is the machine speed, estimated from the car's: `w = v / 3.6 · 8.193 / 0.31`. The rest of the demand, carried through the reduction, goes to the four wheel brakes in equal parts, as Lecture 3's brake demand does, so it can feed Lecture 3's `ABSUnit` unchanged.

The hard stop is Lecture 3's straight ABS stop (`Lecture3.ABSStraightStop`): from 80 km/h the driver asks each wheel for **2500 N·m**, 10 000 N·m in all, 1221 N·m at the machine. That is twice what the tires carry, so the ABS holds every wheel near its peak slip.

::: info Why the hard stop, and not WLTC

WLTC never decelerates harder than 1.5 m/s², 87 N·m at the machine, and never asks the battery for more than 32 kW: the torque and charge-power limits never bind, and friction only takes what the fade leaves near standstill. So on WLTC series blending looks like step 04's `TorqueSplit`. The hard stop asks for far more than the machine can take, so there the limits show, one after the other as the car slows.

:::

::: info The regenerative envelope

The three ceilings draw an envelope like the motoring one of step 02, mirrored: rising with speed to 320 N·m at 10 km/h, flat down to the corner speed where 320 N·m meets 80.5 kW, **34.3 km/h**, and falling as 1/*w* above it. The limit is on the machine's electromagnetic power, *τ*·*w*. The battery gets less: the machine's, the converter's and the battery's losses and the auxiliaries come off first, so it never takes more than 80.5 kW.

With `abs_rule = true`, connect `ABSUnit(report_front = true).front_active` to `blend.abs_active`. Every 5 ms the ABS reports whether either front command is below its sampled demand, including release, hold and slow reapply (and initial build-up). Regen's ceiling is multiplied by `allow`: it decays toward zero with a **30 ms** time constant while active and returns toward one with **0.5 s** otherwise (both assumed). Every N·m withdrawn goes into the four hydraulic demands; the ABS still decides what reaches each brake. Continuous torque avoids a converter step above base speed. `withdraw = 0.0` reproduces step 5 without the rule.

The default `abs_rule = false` keeps existing callers, including WLTC, unchanged; it adds neither a port nor a state. Keep the rule in the shared blending block, opt-in, rather than maintaining a second allocator. WLTC has no ABS and needs no extra wiring. This is not traction control: if the machine takes all of a light brake demand, the friction ABS has nothing to release and cannot detect machine-only locking.

:::

::: details Details: the checkpoint numbers worked through

- **At 80 km/h:** *w* = 22.22 / 0.31 × 8.193 = 587 rad/s (5610 rpm), and 80 500 W / 587 rad/s = **137 N·m**: the charge-power limit binds. At the wheels that is 137 × 8.193 = 1123 N·m, 3.6 kN on the road, **0.25 g** of regenerative deceleration, in the plan's 0.2–0.3 g band.
- **Corner speed:** 80 500 W / 320 N·m = 251.6 rad/s, so 251.6 × 0.31 / 8.193 × 3.6 = **34.3 km/h**. Below it the torque limit binds: 320 × 8.193 = 2622 N·m at the front wheels, about the 2534 N·m the front tires carry at µ = 1.
- **Without the ABS rule (step 5 baseline), energy split:** the car starts with 380.7 kJ in body and wheels. The machine takes **176.9 kJ** back through the reduction, the friction brakes burn **181.8 kJ**, tire slip 22.0 kJ. The machine's share of the braking is 176.9 / (176.9 + 181.8) = **49.3 %**; **170.2 kJ** reaches the battery terminals. The three add up to the 380.7 kJ the car started with, to under 10⁻⁹ of it, because `E_kin` leaves out the machine's rotor: the rotor's energy reaches the battery inside the machine, without passing the reduction where `E_shaft_in` is measured.
- **WLTC:** 34.25 Wh/km back into the terminals over 143.6 Wh/km of traction at the shaft is **23.85 %**. That is inside the plan's 18–25 %: a quarter of the traction comes back as braking, and the measured Leaf (Boretti, 2012 and 2013 models) recovers 70–87 % of it, while this model's ideal reduction and machine return 88.6 %. A lower charge limit does bring the share down to the measured car's, but only by braking on friction: at 15 kW the share is **21.40 %** and the friction brakes take **9.5 %** of WLTC's braking, above the plan's 4 %.

:::

#### Parts

New component `RegenBlend` in `MyCar`:

| Name | Library path | Set |
| --- | --- | --- |
| `ratio` | parameter `Real` | `8.193`: the reduction |
| `radius` | parameter `Length` | `0.31`: the wheel radius |
| `tau_max` | parameter `Torque` | `320.0`: the torque limit |
| `P_charge` | parameter `Power` | `80.5e3`: the charge-power limit |
| `v_fade` | parameter `Real` | `10.0`: the fade speed, km/h |
| `tau_ref` | Dyad › RealInput | the driver's torque at the machine, positive drives |
| `v` | Dyad › RealInput | the car's speed in km/h |
| `tau_motor` | Dyad › RealOutput | the torque the machine is asked for |
| `tau_brake` | Dyad › RealOutput | the torque asked of each of the four friction brakes |

New components `BEVHardStop` and `BEVRegenWLTC` in `MyCar`: paste the code below.

:::: info Given parts: the ABS and the slips

**`ABSUnit`** (`abs`, in the hard stop): VehicleSystemsComponents › Vehicle › Planar. Lecture 3's four-channel ABS: it applies the per-wheel brake demand `demand` to all four wheels and releases each wheel whose slip passes its threshold, reading `vx` and the four slips. Its `dT_*` inputs are for ESP and stay at zero here.

**`BusSlip`** (`slips`, in the hard stop): VehicleSystemsComponents › Vehicle › Planar. Reads the four wheel slips off the car's bus, as `BusMotion` reads its motion.

::::

::: warning Use these names

The benches read `blend.tau_ref`, `blend.v`, `blend.tau_motor`, `blend.tau_brake`, and the snippets plot `blend.tau_demand`, `blend.tau_regen_max` and `blend.tau_regen`. Keep the names, and either your block or the course library's `Vehicle.Electric.RegenBlend` fits.

:::

#### Do this

[![The finished BEVHardStop in Studio: pedal and kmh into blend; blend.tau_motor into drive, blend.tau_brake into the ABS; drive through the differential to the car's front wheels; slips and zero into the ABS, whose four outputs drive the car's brakes; motion reads the car's bus.](/lecture/lecture-04/img/step05-regen-blend.png)](/lecture/lecture-04/img/step05-regen-blend.png)

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `RegenBlend`. With nothing selected, click **Edit Parameters** → **Add parameter** for the five parameters in the table. Place the two inputs and two outputs and rename each to its **Name**: `tau_ref` and `v` on the left, `tau_motor` and `tau_brake` on the right.
2. Toggle to code and add the variables before `relations`, and the equations after it:

   ```txt
     "Machine speed estimated from the car's speed"
     structural parameter abs_rule::Boolean = false
     abs_active = RealInput() if abs_rule
     parameter withdraw::Real = 1.0 if abs_rule
     parameter T_withdraw::Time = 0.03 if abs_rule
     parameter T_return::Time = 0.5 if abs_rule
     variable allow::Real if abs_rule
     variable w::AngularVelocity
     "Fade factor: 1 above v_fade, 0 at standstill"
     variable fade::Real
     "Braking ceiling from the charge-power limit"
     variable tau_power::Torque
     "Braking ceiling from the low-speed fade"
     variable tau_fade::Torque
     "Braking ceiling: the smallest of the three limits"
     variable tau_regen_max::Torque
     "Braking demand at the machine shaft"
     variable tau_demand::Torque
     "Braking torque the machine is asked for"
     variable tau_regen::Torque
   relations
     w = max(v, 0.0) / 3.6 * ratio / radius
     fade = min(max(v / v_fade, 0.0), 1.0)
     tau_power = P_charge / max(w, 1.0)
     tau_fade = fade * tau_max
     if abs_rule
       initial allow = 1.0
       der(allow) = ifelse(withdraw * abs_active > 0.5, -allow / T_withdraw, (1.0 - allow) / T_return)
       tau_regen_max = allow * min(tau_max, min(tau_power, tau_fade))
     else
       tau_regen_max = min(tau_max, min(tau_power, tau_fade))
     end
     tau_demand = max(-tau_ref, 0.0)
     tau_regen = min(tau_demand, tau_regen_max)
     tau_motor = max(tau_ref, 0.0) - tau_regen
     tau_brake = (tau_demand - tau_regen) * ratio / 4.0
   ```

   The first five equations are the three ceilings; `max(w, 1.0)` keeps the quotient finite at standstill, where the fade has the ceiling at zero anyway. The last four are the blending: driving passes straight through, braking goes to the machine up to the ceiling, and the rest, carried through the reduction, is split over four wheels.
3. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `BEVHardStop`. Toggle to code (⇄), select everything, paste the block below and save.

   ::: code-group

   ```txt [BEVHardStop]
   component BEVHardStop
     "Vehicle mass"
     parameter m::Mass = 1500.0
     "Wheel radius"
     parameter radius::Length = 0.31
     "Initial speed, 80 km/h"
     parameter v0::Velocity = 22.22222222222222
     "Driver's brake demand at each wheel, as in Lecture 3"
     parameter T_cmd::Torque = 2500.0
     "Time the driver brakes"
     parameter brake_time::Time = 0.5
     "Time the driver takes to press the pedal fully"
     parameter t_apply::Time = 0.1
     "Machine torque limit, Leaf ZE1"
     parameter tau_max::Torque = 320.0
     "Battery charge-power limit"
     parameter P_charge::Power = 80.5e3
     "Speed below which the braking ceiling fades to zero, km/h"
     parameter v_fade::Real = 10.0
     "Power drawn by the 12 V network"
     parameter P_aux::Power = 300.0
     "Single-speed reduction, Leaf ZE1"
     parameter ratio::Real = 8.193
     parameter withdraw::Real = 1.0
     parameter road_mu::Real = 1.0
     pedal = BlockComponents.Sources.Ramp(offset = 0.0, height = -4.0 * T_cmd / ratio, duration = t_apply, start_time = brake_time) {^pedal}
     kmh = VehicleSystemsComponents.Vehicle.ToKmPerHour() {^kmh}
     blend = RegenBlend(ratio = ratio, radius = radius, tau_max = tau_max, P_charge = P_charge, v_fade = v_fade, abs_rule = true, withdraw = withdraw) {^blend}
     drive = ElectricDrive(ratio = ratio, P_aux = P_aux) {^drive}
     differential = MultibodyComponents.PlanarMechanics.DifferentialGear() {^differential}
     mount = RotationalComponents.Components.Fixed() {^mount}
     straight = RotationalComponents.Components.Fixed() {^straight}
     zero = BlockComponents.Sources.Constant(k = 0.0) {^zero}
     abs = VehicleSystemsComponents.Vehicle.Planar.ABSUnit(select_low = 0.0, report_front = true) {^abs}
     car = VehicleSystemsComponents.Vehicle.Planar.PlanarCar(m = m, radius = radius, mu_scale_fl = road_mu, mu_scale_fr = road_mu, mu_scale_rl = road_mu, mu_scale_rr = road_mu) {^car}
     motion = VehicleSystemsComponents.Vehicle.Planar.BusMotion() {^motion}
     slips = VehicleSystemsComponents.Vehicle.Planar.BusSlip() {^slips}
     "Power at the battery terminals, positive discharging"
     variable P_dc::Power
     "Power at the reduction output, positive driving the wheels"
     variable P_shaft::Power
     variable E_dc_in::Energy
     variable E_shaft_in::Energy
     variable E_brake::Energy
   relations
     connect(car.bus, motion.bus, slips.bus) {^wbus}
     connect(pedal.y, blend.tau_ref) {^w1}
     connect(motion.vx, kmh.u, abs.vx) {^w2}
     connect(kmh.y, blend.v) {^w3}
     connect(blend.tau_motor, drive.tau_ref) {^w4}
     connect(blend.tau_brake, abs.demand) {^w5}
     connect(drive.spline, differential.flange_b) {^w6}
     connect(differential.flange_left, car.spin_fl) {^w7}
     connect(differential.flange_right, car.spin_fr) {^w8}
     connect(drive.support, mount.spline) {^w9}
     connect(car.steering, straight.spline) {^w10}
     connect(zero.y, abs.dT_fl, abs.dT_fr, abs.dT_rl, abs.dT_rr) {^w11}
     connect(slips.kappa_fl, abs.kappa_fl) {^w12}
     connect(slips.kappa_fr, abs.kappa_fr) {^w13}
     connect(slips.kappa_rl, abs.kappa_rl) {^w14}
     connect(slips.kappa_rr, abs.kappa_rr) {^w15}
     connect(abs.tau_fl, car.tau_fl) {^w16}
     connect(abs.tau_fr, car.tau_fr) {^w17}
     connect(abs.tau_rl, car.tau_rl) {^w18}
     connect(abs.tau_rr, car.tau_rr) {^w19}
     connect(abs.front_active, blend.abs_active) {^w20}
     P_dc = drive.battery.v * drive.battery.i
     P_shaft = drive.machine.P_mech
     der(E_dc_in) = max(-P_dc, 0.0)
     der(E_shaft_in) = max(-P_shaft, 0.0)
     der(E_brake) = car.fl.brake.tau_friction * car.fl.brake.w + car.fr.brake.tau_friction * car.fr.brake.w + car.rl.brake.tau_friction * car.rl.brake.w + car.rr.brake.tau_friction * car.rr.brake.w
     initial car.body.r = [0, 0]
     initial car.body.v = [v0, 0]
     initial car.body.phi = 0.0
     initial car.body.w = 0.0
     initial car.fl.inertia.w = (v0 + 0.01) / radius
     initial car.fr.inertia.w = (v0 + 0.01) / radius
     initial car.rl.inertia.w = (v0 + 0.01) / radius
     initial car.rr.inertia.w = (v0 + 0.01) / radius
     initial car.fl.inertia.phi = 0.0
     initial car.fr.inertia.phi = 0.0
     initial car.rl.inertia.phi = 0.0
     initial car.rr.inertia.phi = 0.0
     initial car.fl.brake.tau_actual = 0.0
     initial car.fr.brake.tau_actual = 0.0
     initial car.rl.brake.tau_actual = 0.0
     initial car.rr.brake.tau_actual = 0.0
     initial drive.converter.i_out = 0.0
     initial E_dc_in = 0.0
     initial E_shaft_in = 0.0
     initial E_brake = 0.0
   metadata {
     "_links": {
       "pedal": {"Dyad": {"placement": {"diagram": {"x1": 140, "y1": 70, "x2": 240, "y2": 170}}}},
       "kmh": {"Dyad": {"placement": {"diagram": {"x1": 40, "y1": 190, "x2": 110, "y2": 260}}}},
       "blend": {"Dyad": {"placement": {"diagram": {"x1": 290, "y1": 70, "x2": 390, "y2": 170}}}},
       "drive": {"Dyad": {"placement": {"diagram": {"x1": 430, "y1": 50, "x2": 530, "y2": 150}}}},
       "mount": {"Dyad": {"placement": {"diagram": {"x1": 485, "y1": 190, "x2": 545, "y2": 250}}}},
       "differential": {"Dyad": {"placement": {"diagram": {"x1": 560, "y1": 260, "x2": 640, "y2": 340}}}},
       "straight": {"Dyad": {"placement": {"diagram": {"x1": 605, "y1": 500, "x2": 655, "y2": 550, "rot": 180}}}},
       "car": {"Dyad": {"placement": {"diagram": {"x1": 520, "y1": 600, "x2": 740, "y2": 820}}}},
       "motion": {"Dyad": {"placement": {"diagram": {"x1": 775, "y1": 610, "x2": 975, "y2": 810}}}},
       "zero": {"Dyad": {"placement": {"diagram": {"x1": 100, "y1": 633, "x2": 140, "y2": 673}}}},
       "abs": {"Dyad": {"placement": {"diagram": {"x1": 220, "y1": 593, "x2": 420, "y2": 793}}}},
       "slips": {"Dyad": {"placement": {"diagram": {"x1": 40, "y1": 740, "x2": 140, "y2": 840}}}},
       "wbus": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [], "E": 2}, {"S": -1, "M": [{"x": 760, "y": 950}, {"x": 30, "y": 950}, {"x": 30, "y": 790}], "E": 3}], "junctions": [{"x": 760, "y": 710}]}},
       "w1": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 265, "y": 120}, {"x": 265, "y": 100}], "E": 2}]}},
       "w2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 990, "y": 662}, {"x": 990, "y": 980}, {"x": 20, "y": 980}], "E": -1}, {"S": -1, "M": [{"x": 20, "y": 225}], "E": 2}, {"S": -1, "M": [], "E": 3}], "junctions": [{"x": 20, "y": 713}]}},
       "w3": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 270, "y": 225}, {"x": 270, "y": 140}], "E": 2}]}},
       "w4": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w5": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 410, "y": 140}, {"x": 410, "y": 560}, {"x": 200, "y": 560}, {"x": 200, "y": 613}], "E": 2}]}},
       "w6": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 550, "y": 100}, {"x": 550, "y": 344}], "E": 2}]}},
       "w7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 480, "y": 300}, {"x": 480, "y": 655}], "E": 2}]}},
       "w8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 765, "y": 300}, {"x": 765, "y": 655}], "E": 2}]}},
       "w9": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 515, "y": 150}], "E": 2}]}},
       "w10": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w11": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [{"x": 180, "y": 633}], "E": 2}, {"S": -1, "M": [], "E": 3}, {"S": -1, "M": [], "E": -2}, {"S": -2, "M": [], "E": 4}, {"S": -2, "M": [{"x": 180, "y": 693}], "E": 5}], "junctions": [{"x": 180, "y": 653}, {"x": 180, "y": 673}]}},
       "w12": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 180, "y": 760}, {"x": 180, "y": 733}], "E": 2}]}},
       "w13": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 190, "y": 780}, {"x": 190, "y": 753}], "E": 2}]}},
       "w14": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 170, "y": 800}, {"x": 170, "y": 860}, {"x": 260, "y": 860}], "E": 2}]}},
       "w15": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 160, "y": 820}, {"x": 160, "y": 880}, {"x": 300, "y": 880}], "E": 2}]}},
       "w16": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w17": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 440, "y": 673}, {"x": 440, "y": 470}, {"x": 750, "y": 470}, {"x": 750, "y": 633}], "E": 2}]}},
       "w18": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 460, "y": 713}, {"x": 460, "y": 743}], "E": 2}]}},
       "w20": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 320, "y": 520}], "E": 2}]}},
       "w19": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 450, "y": 753}, {"x": 450, "y": 900}, {"x": 750, "y": 900}, {"x": 750, "y": 743}], "E": 2}]}}
     }
   }
   end

   analysis BEVHardStopTransient
     extends TransientAnalysis(stop = 6.0, alg = ODEAlg.Rodas5P(), dtmax = 0.005, tstops = [0.5, 0.6], optimize = OptimizationLevel.None())
     parameter T_cmd::Torque = 2500.0
     parameter tau_max::Torque = 320.0
     parameter P_charge::Power = 80.5e3
     parameter v_fade::Real = 10.0
     parameter withdraw::Real = 1.0
     parameter road_mu::Real = 1.0
     model = BEVHardStop(T_cmd = T_cmd, tau_max = tau_max, P_charge = P_charge, v_fade = v_fade, withdraw = withdraw, road_mu = road_mu)
   end
   ```

   :::

   It is Lecture 3's ABS stop with your drive on the front axle: `pedal` asks for the 4 × 2500 N·m as a torque at the machine, `blend` gives the machine its share and `abs` the rest. The driver presses the pedal in 0.1 s instead of in a step: the converter imposes its current through the armature's inductance, so a torque step would make the converter's `field` jump at an instant the solver cannot take; `tstops` lands it on both corners of the ramp. The three meters integrate the battery's charging, the machine's braking at the reduction and the four friction brakes.
4. Click ▷ **Run Analysis → BEVHardStopTransient** once, then plot the speed, the regenerative envelope against speed, and the brakes, and read the energy split:

   ```julia
   using Plots; plotly()
   r = MyCar.BEVHardStopTransient();
   plot(r; idxs = [r."kmh.y", r."car.fl.brake.tau_friction", r."car.rl.brake.tau_friction"], layout = (3, 1))
   v = r.sol[r."kmh.y"]
   plot(v, [r.sol[r."blend.tau_regen_max"] r.sol[r."blend.tau_regen"]]; xlabel = "km/h", ylabel = "N·m",
       label = ["ceiling" "machine"], xflip = true)
   kJ(x) = r.sol[x][end] / 1e3
   kJ(r."E_shaft_in"), kJ(r."E_brake"), kJ(r."E_dc_in")
   kJ(r."E_shaft_in") / (kJ(r."E_shaft_in") + kJ(r."E_brake"))   # the machine's share
   ```

::: tip Expected result

With the rule enabled, the dry stop reaches 0.5 m/s **3.275 s** after the pedal, in **38.84 m**. The machine takes **5.93 kJ**, friction **360.74 kJ**, tire slip **19.69 kJ**; **5.89 kJ** reaches the battery. The energy balance still closes. The sampled ABS stays active almost throughout this stop, so regen remains withdrawn; this calibration does not improve dry stopping distance.

**Compare:** `MyCar.BEVHardStopTransient(withdraw = 0.0)` reproduces the earlier **36.22 m**, **176.89 kJ** motor / **181.79 kJ** friction (**49.32 %** motor), **170.24 kJ** into the battery. The three ceilings are visible on this counterfactual; with the rule they are upper bounds, not the actual torque. `P_charge = 0.0` gives the **38.82 m** friction-only reference.

**Low grip:** run `MyCar.BEVHardStopTransient(road_mu = 0.3, stop = 28.0)`. Front slip stays above **−0.050** while speed exceeds 3 m/s; stopping distance is **275.02 m**. With `withdraw = 0.0, stop = 12.0`, slip passes **−1** (lock) and reaches **−17.41**: the ideal negative torque then reverses the wheels. Its **112.35 m** distance is a model counterfactual, not a physically credible locked-wheel benchmark. The inherited ABS reapply calibration is slow on this road; this task does not retune it. Longer parking in that counterfactual eventually reaches the known tire Jacobian singularity.

Reference: `HandsOn04.RegenBlend`, `HandsOn04.BEVHardStop`, `HandsOn04.BEVHardStopTransient`; the course library's copies are `Vehicle.Electric.RegenBlend` and `Vehicle.Planar.PlanarBEVHardStop`.

:::

5. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `BEVRegenWLTC`. Toggle to code (⇄), select everything, paste the block below and save. It is step 04's bench with `blend` in place of `split`, the friction share on all four brakes, and four meters.

   ::: code-group

   ```txt [BEVRegenWLTC]
   component BEVRegenWLTC
     "Vehicle mass, shared by the car and its road load (probe)"
     parameter m::Mass = 1500.0
     "Wheel radius (repository default)"
     parameter radius::Length = 0.31
     "Driver gain, machine torque per km/h of speed error (assumed)"
     parameter k::Real = 50.0
     "Driver integral time (assumed)"
     parameter Ti::Time = 2.0
     "Driver and machine torque limit, the machine's peak torque (Nissan)"
     parameter tau_max::Torque = 320.0
     "Battery charge-power limit (INL)"
     parameter P_charge::Power = 80.5e3
     "Speed below which the braking ceiling fades to zero, km/h (assumed)"
     parameter v_fade::Real = 10.0
     "Power drawn by the 12 V network (assumed)"
     parameter P_aux::Power = 300.0
     "Single-speed reduction (Nissan)"
     parameter ratio::Real = 8.193
     "Initial wheel surface speed above the body's, keeps the start off zero slip (assumed)"
     parameter dv_wheel::Velocity = 0.01
     trace = VehicleSystemsComponents.Vehicle.DriveCycle() {^trace}
     driver = BlockComponents.Continuous.LimPID(with_D = false, k = k, Ti = Ti, y_max = tau_max, y_min = -tau_max) {^driver}
     no_ff = BlockComponents.Sources.Constant(k = 0.0) {^no_ff}
     kmh = VehicleSystemsComponents.Vehicle.ToKmPerHour() {^kmh}
     drive = ElectricDrive(ratio = ratio, P_aux = P_aux) {^drive}
     differential = MultibodyComponents.PlanarMechanics.DifferentialGear() {^differential}
     mount = RotationalComponents.Components.Fixed() {^mount}
     straight = RotationalComponents.Components.Fixed() {^straight}
     flat = BlockComponents.Sources.Constant(k = 0.0) {^flat}
     car = VehicleSystemsComponents.Vehicle.Planar.PlanarCar(m = m, radius = radius) {^car}
     motion = VehicleSystemsComponents.Vehicle.Planar.BusMotion() {^motion}
     roadload = VehicleSystemsComponents.Vehicle.Planar.PlanarRoadLoad(m = m) {^roadload}
     blend = RegenBlend(ratio = ratio, radius = radius, tau_max = tau_max, P_charge = P_charge, v_fade = v_fade) {^blend}
     "Power at the battery terminals, positive discharging"
     variable P_dc::Power
     "Power at the reduction output, positive driving the wheels"
     variable P_shaft::Power
     variable E_dc_in::Energy
     variable E_shaft_out::Energy
     variable E_shaft_in::Energy
     variable E_brake::Energy
   relations
     connect(car.bus, motion.bus) {^wbus}
     connect(trace.y, driver.u_s) {^w1}
     connect(motion.vx, kmh.u) {^w2}
     connect(kmh.y, driver.u_m, blend.v) {^w3}
     connect(no_ff.y, driver.u_ff) {^w4}
     connect(drive.spline, differential.flange_b) {^w5}
     connect(differential.flange_left, car.spin_fl) {^w6}
     connect(differential.flange_right, car.spin_fr) {^w7}
     connect(drive.support, mount.spline) {^w8}
     connect(car.steering, straight.spline) {^w9}
     connect(flat.y, roadload.grade) {^w10}
     connect(car.chassis, roadload.chassis) {^w11}
     connect(driver.y, blend.tau_ref) {^w21}
     connect(blend.tau_motor, drive.tau_ref) {^w23}
     connect(blend.tau_brake, car.tau_fl, car.tau_fr, car.tau_rl, car.tau_rr) {^w24}
     P_dc = drive.battery.v * drive.battery.i
     P_shaft = drive.machine.P_mech
     der(E_dc_in) = max(-P_dc, 0.0)
     der(E_shaft_out) = max(P_shaft, 0.0)
     der(E_shaft_in) = max(-P_shaft, 0.0)
     der(E_brake) = car.fl.brake.tau_friction * car.fl.brake.w + car.fr.brake.tau_friction * car.fr.brake.w + car.rl.brake.tau_friction * car.rl.brake.w + car.rr.brake.tau_friction * car.rr.brake.w
     initial car.body.r = [0, 0]
     initial car.body.v = [0, 0]
     initial car.body.phi = 0.0
     initial car.body.w = 0.0
     initial car.fl.inertia.w = dv_wheel / radius
     initial car.fr.inertia.w = dv_wheel / radius
     initial car.rl.inertia.w = dv_wheel / radius
     initial car.rr.inertia.w = dv_wheel / radius
     initial car.fl.inertia.phi = 0.0
     initial car.fr.inertia.phi = 0.0
     initial car.rl.inertia.phi = 0.0
     initial car.rr.inertia.phi = 0.0
     initial car.fl.brake.tau_actual = 0.0
     initial car.fr.brake.tau_actual = 0.0
     initial car.rl.brake.tau_actual = 0.0
     initial car.rr.brake.tau_actual = 0.0
     initial drive.converter.i_out = 0.0
     initial E_dc_in = 0.0
     initial E_shaft_out = 0.0
     initial E_shaft_in = 0.0
     initial E_brake = 0.0
   metadata {
     "_links": {
       "wbus": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "trace": {"Dyad": {"placement": {"diagram": {"x1": 20, "y1": 57, "x2": 100, "y2": 137}}}},
       "driver": {"Dyad": {"placement": {"diagram": {"x1": 140, "y1": 70, "x2": 240, "y2": 170}}}},
       "no_ff": {"Dyad": {"placement": {"diagram": {"x1": 100, "y1": 10, "x2": 140, "y2": 50}}}},
       "kmh": {"Dyad": {"placement": {"diagram": {"x1": 40, "y1": 190, "x2": 110, "y2": 260}}}},
       "drive": {"Dyad": {"placement": {"diagram": {"x1": 430, "y1": 50, "x2": 530, "y2": 150}}}},
       "differential": {"Dyad": {"placement": {"diagram": {"x1": 560, "y1": 260, "x2": 640, "y2": 340}}}},
       "mount": {"Dyad": {"placement": {"diagram": {"x1": 485, "y1": 190, "x2": 545, "y2": 240}}}},
       "straight": {"Dyad": {"placement": {"diagram": {"x1": 605, "y1": 500, "x2": 655, "y2": 550, "rot": 180}}}},
       "flat": {"Dyad": {"placement": {"diagram": {"x1": 440, "y1": 880, "x2": 480, "y2": 920}}}},
       "car": {"Dyad": {"placement": {"diagram": {"x1": 520, "y1": 600, "x2": 740, "y2": 820}}}},
       "motion": {"Dyad": {"placement": {"diagram": {"x1": 775, "y1": 610, "x2": 975, "y2": 810}}}},
       "roadload": {"Dyad": {"placement": {"diagram": {"x1": 500, "y1": 865, "x2": 570, "y2": 935}}}},
       "blend": {"Dyad": {"placement": {"diagram": {"x1": 290, "y1": 70, "x2": 390, "y2": 170}}}},
       "w1": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w2": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 990, "y": 662.0}, {"x": 990, "y": 980}, {"x": 20, "y": 980}, {"x": 20, "y": 225}], "E": 2}]}},
       "w3": {"Dyad": {"edges": [{"S": 1, "M": [], "E": -1}, {"S": -1, "M": [{"x": 125, "y": 143}], "E": 2}, {"S": -1, "M": [{"x": 270, "y": 225}, {"x": 270, "y": 140}], "E": 3}], "junctions": [{"x": 125, "y": 225}]}},
       "w4": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 190, "y": 30}], "E": 2}]}},
       "w5": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 550, "y": 100}, {"x": 550, "y": 344}], "E": 2}]}},
       "w6": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 480, "y": 300}, {"x": 480, "y": 655}], "E": 2}]}},
       "w7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 765, "y": 300}, {"x": 765, "y": 655}], "E": 2}]}},
       "w8": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 515, "y": 150}], "E": 2}]}},
       "w9": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w10": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w11": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 680, "y": 820}, {"x": 680, "y": 900}], "E": 2}]}},
       "w21": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 265, "y": 120}, {"x": 265, "y": 100}], "E": 2}]}},
       "w23": {"Dyad": {"edges": [{"S": 1, "M": [], "E": 2}]}},
       "w24": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 410, "y": 140}], "E": -1}, {"S": -1, "M": [], "E": -2}, {"S": -2, "M": [], "E": 2}, {"S": -2, "M": [{"x": 500, "y": 470}, {"x": 750, "y": 470}, {"x": 750, "y": 633}], "E": 3}, {"S": -1, "M": [], "E": -3}, {"S": -3, "M": [], "E": 4}, {"S": -3, "M": [{"x": 410, "y": 960}, {"x": 760, "y": 960}, {"x": 760, "y": 743}], "E": 5}], "junctions": [{"x": 410, "y": 633}, {"x": 500, "y": 633}, {"x": 410, "y": 743}]}}
     }
   }
   end

   analysis BEVRegenWLTCTransient
     extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
     parameter k::Real = 50.0
     parameter Ti::Time = 2.0
     parameter P_charge::Power = 80.5e3
     parameter v_fade::Real = 10.0
     parameter P_aux::Power = 300.0
     model = BEVRegenWLTC(k = k, Ti = Ti, P_charge = P_charge, v_fade = v_fade, P_aux = P_aux)
   end
   ```

   :::

   The ABS is not on this bench: on WLTC no wheel comes near its slip threshold, and its 200 Hz clock would make the solver stop every 5 ms for half an hour.
6. Click ▷ **Run Analysis → BEVRegenWLTCTransient** once, then read the recovered share and where the braking went:

   ```julia
   r = MyCar.BEVRegenWLTCTransient();
   km = r.sol[r."car.bus.x"][end] / 1000
   Wh_km(x) = r.sol[x][end] / 3600 / km
   Wh_km(r."E_dc_in"), Wh_km(r."E_shaft_out"), Wh_km(r."E_shaft_in"), Wh_km(r."E_brake")
   r.sol[r."E_dc_in"][end] / r.sol[r."E_shaft_out"][end]          # recovered share of traction
   plot(r; idxs = [r."blend.tau_demand", r."blend.tau_regen", r."blend.tau_brake"], layout = (3, 1))
   ```

::: tip Expected result

**The recovered share:** the battery terminals take back **34.25 Wh/km** of the **143.6 Wh/km** of traction at the shaft: **23.85 %**. The shaft took back 38.7 Wh/km, and 88.6 % of it reached the battery. The friction brakes burned **0.001 Wh/km**, 0.004 % of the braking: only what the fade left them in the last 2 km/h before each stop, and the hold at standstill.

`blend.tau_regen` lies on `blend.tau_demand` wherever the car moves faster than walking pace: WLTC never asks for more than 87 N·m at the machine, or 32 kW, so neither the torque nor the charge-power limit binds, and `blend.tau_brake` is zero except at the stops.

**Against step 04:** `TorqueSplit` recovered 23.80 % and burned 0.12 Wh/km in the front brakes below 10 km/h. Series blending changes WLTC by a twentieth of a point: on a gentle cycle the hard stop, not the cycle, shows what blending does. The plan's band is 18–25 %: Boretti measured 70–87 % regen efficiency on the 2012 and 2013 Leaf, and this model's lossless reduction lets 88.6 % through, so it sits in the upper half.

**Change one thing:** `MyCar.BEVRegenWLTCTransient(P_charge = 15.0e3)` lowers the charge limit to 15 kW. The share falls to **21.40 %**, inside the band, but the friction brakes now burn **3.69 Wh/km**, 9.5 % of the braking: the gap to the band is the regen path's efficiency, and a charge limit that closes it throws braking energy away.

Reference: `HandsOn04.BEVRegenWLTC`, `HandsOn04.BEVRegenWLTCTransient`; the course library's copy is `Vehicle.Planar.PlanarBEVRegenWLTC`, with the full energy bill of step 06.

:::

Commit: **Source Control** → message `Step 05: regen blending` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `BEVHardStop` and `BEVRegenWLTC` from steps 3 and 5 of **Do this** above; they need step 04's `ElectricDrive`, whose **Fell behind?** block is above. Then right-click `MyCar` → **Add Component**, name it `RegenBlend`, toggle to code (⇄) and paste this over its contents.

::: code-group

```txt [RegenBlend]
component RegenBlend
  "Torque asked for at the machine shaft: positive drives, negative brakes"
  tau_ref = RealInput() {^tau_ref}
  "Vehicle speed [km/h]"
  v = RealInput() {^v}
  "1 while the ABS acts on a wheel the machine drives, else 0; present only with abs_rule = true"
  abs_active = RealInput() if abs_rule {^abs_active}
  "Torque the machine is asked for"
  tau_motor = RealOutput() {^tau_motor}
  "Friction brake torque asked of each of the four wheel brakes"
  tau_brake = RealOutput() {^tau_brake}
  "Single-speed reduction, machine to differential (Nissan)"
  parameter ratio::Real = 8.193
  "Wheel radius, to estimate the machine speed from the car's (repository default)"
  parameter radius::Length = 0.31
  "Torque limit: the machine's peak torque (Nissan)"
  parameter tau_max::Torque = 320.0
  "Charge-power limit: the 2013 Leaf pack's 10 s charge capability at 20 % depth of discharge; the ZE1's larger pack takes more (INL)"
  parameter P_charge::Power = 80.5e3
  "Speed below which the machine's braking ceiling fades to zero, km/h; no primary source, the plan's band is 5-10 km/h (assumed)"
  parameter v_fade::Real = 10.0
  "Add the ABS rule and its abs_active input: regen backs off while the ABS acts on a driven wheel"
  structural parameter abs_rule::Boolean = false
  "ABS rule on (1) or off (0), so one bench runs both; present only with abs_rule = true"
  parameter withdraw::Real = 1.0 if abs_rule
  "Time constant regen backs off with: the friction brakes' 30 ms build-up, PlanarCar's T_brake (assumed)"
  parameter T_withdraw::Time = 0.03 if abs_rule
  "Time constant regen returns with once the ABS stops acting (assumed)"
  parameter T_return::Time = 0.5 if abs_rule
  "Machine speed estimated from the car's speed"
  variable w::AngularVelocity
  "Fade factor: 1 above v_fade, 0 at standstill"
  variable fade::Real
  "Braking ceiling from the charge-power limit"
  variable tau_power::Torque
  "Braking ceiling from the low-speed fade"
  variable tau_fade::Torque
  "Braking ceiling: the smallest of the three limits, times allow under the ABS rule"
  variable tau_regen_max::Torque
  "Braking demand at the machine shaft"
  variable tau_demand::Torque
  "Braking torque the machine is asked for"
  variable tau_regen::Torque
  "Share of the ceiling the ABS rule allows: 1, falling to 0 while the ABS acts; present only with abs_rule = true"
  variable allow::Real if abs_rule
relations
  w = max(v, 0.0) / 3.6 * ratio / radius
  fade = min(max(v / v_fade, 0.0), 1.0)
  # The 1 rad/s floor keeps the quotient finite at standstill, where the fade binds anyway.
  tau_power = P_charge / max(w, 1.0)
  tau_fade = fade * tau_max
  if abs_rule
    initial allow = 1.0
    # abs_active is held between ABS samples, so the switch between the two rates falls on a
    # sample instant and allow itself stays continuous.
    der(allow) = ifelse(withdraw * abs_active > 0.5, -allow / T_withdraw, (1.0 - allow) / T_return)
    tau_regen_max = allow * min(tau_max, min(tau_power, tau_fade))
  else
    tau_regen_max = min(tau_max, min(tau_power, tau_fade))
  end
  tau_demand = max(-tau_ref, 0.0)
  tau_regen = min(tau_demand, tau_regen_max)
  tau_motor = max(tau_ref, 0.0) - tau_regen
  tau_brake = (tau_demand - tau_regen) * ratio / 4.0
metadata {
  "Dyad": {"icons": {"default": "dyad://VehicleSystemsComponents/Vehicle/Electric/RegenBlend.svg"}, "labels": [{"label": "$(instance)", "x": 500, "y": 1100, "rot": 0}]},
  "_links": {
    "tau_ref": {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 250, "x2": 50, "y2": 350}}}},
    "v": {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 650, "x2": 50, "y2": 750}}}},
    "abs_active": {"Dyad": {"placement": {"icon": {"x1": 250, "y1": 950, "x2": 350, "y2": 1050, "rot": 270}}}},
    "tau_motor": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 250, "x2": 1050, "y2": 350}}}},
    "tau_brake": {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 650, "x2": 1050, "y2": 750}}}}
  }
}
end
```

:::

::::

---

## 08 The energy bill

### 06 · The WLTC energy bill {#step-06}

Put a meter on every link of the chain and read the bill: **131.2 Wh/km** at the battery terminals, 13.1 kWh/100 km, of which the road load takes 103 and the machine 18. Braking gives back a quarter of the traction energy, and the links add up to what left the cells to nine digits. In MJ/100 km the same cycle costs this car **47.2** and Lecture 2's engine car **168.8**.

#### Given

An energy meter is a state that integrates a power: `der(E_road) = roadload.F * car.bus.vx` starts at 0 and holds the joules the road load has taken so far. One meter per link:

| Meter | Power | Link |
| --- | --- | --- |
| `E_cells` | `battery.E * battery.i` | out of the cells: what SoC counts |
| `E_dc`, `E_dc_out`, `E_dc_in` | `battery.v * battery.i`, and its positive and negative parts | at the battery terminals: net, discharged, charged back |
| `E_R0` | `battery.R0 * battery.i^2` | the battery's resistance |
| `E_aux` | `aux.v * aux.i` | the 12 V network |
| `E_conv` | `converter.P_loss` | the converter |
| `E_motor` | `machine.P_loss` | the machine |
| `E_shaft_out`, `E_shaft_in` | positive and negative parts of `machine.P_mech` | traction into the reduction, and braking taken back through it |
| `E_road` | `roadload.F * car.bus.vx` | drag and rolling resistance |
| `E_brake` | brake torque × wheel speed, four wheels | the friction brakes |
| `E_tire` | tire force × slip speed, four wheels | tire slip |

and `E_kin`, the energy stored in motion (body, wheels, rotor) and in the armature's inductance. The reduction and the differential are lossless. Energy is conserved, so

$$
E_{cells} = E_{road} + E_{brake} + E_{tire} + E_{motor} + E_{conv} + E_{R_0} + E_{aux} + \Delta E_{kin}
$$

Lecture 2's engine car on the same cycle: **5.22 L/100 km** of petrol (its reference run, 1400 kg), at 0.745 kg/L and a lower heating value of 43.4 MJ/kg.

::: info Why meter the links, and not just the battery

The battery alone gives the consumption. The meters give the bill: where each kilowatt-hour went. And because each one is measured on its own, from the power in its own part, their sum closing on the battery is a check that the model is right: a sign error in a connector or a loss counted twice shows up as a residual.

Each meter is a state, not a sum over the plotted points afterwards: the solver integrates it with the same accuracy as the car's speed, so the bill closes to the solver's tolerance however the result is saved.

:::

::: details Details: the checkpoint numbers worked through

- **Per kilometre:** every meter divided by the 23.267 km driven. 3.0535 kWh at the terminals is **131.2 Wh/km**, 13.12 kWh/100 km; 3.1257 kWh out of the cells is 134.3 Wh/km.
- **MJ/100 km:** 1 kWh = 3.6 MJ, so 13.12 kWh/100 km is **47.2 MJ/100 km**. The engine car: 5.22 L × 0.745 kg/L × 43.4 MJ/kg = **168.8 MJ/100 km**, 3.6 times more. At the wall, with 13 % lost in charging, the electric car takes 54.3.
- **Braking:** the shaft delivered 3.341 kWh of traction and took back 0.897 kWh, **27 %**; the battery received 0.795 kWh of it, **89 %** of what the shaft took back and 24 % of the traction.
- **The plan's band:** the Leaf's WLTP figure is 171 Wh/km at the wall; less 10–15 % for charging that is 145–154 Wh/km at the battery, and the course road load is about 15 % below the Leaf's: **120–155 Wh/km**.

:::

#### Do this

1. <Badge type="tip" text="New component" /> Right-click `MyCar` → **Add Component**, name it `BEVEnergyBill`. Toggle to code (⇄), select everything, paste the block below and save. It `extends` your step 04 bench, so it is the same car with the meters added.

   ::: code-group

   ```txt [BEVEnergyBill]
   component BEVEnergyBill
     extends BEVWLTC
     "Power at the battery terminals, positive discharging"
     variable P_dc::Power
     "Power at the reduction output, positive driving the wheels"
     variable P_shaft::Power
     variable E_cells::Energy
     variable E_dc::Energy
     variable E_dc_out::Energy
     variable E_dc_in::Energy
     variable E_R0::Energy
     variable E_aux::Energy
     variable E_conv::Energy
     variable E_motor::Energy
     variable E_shaft_out::Energy
     variable E_shaft_in::Energy
     variable E_road::Energy
     variable E_brake::Energy
     variable E_tire::Energy
     "Kinetic energy of body, wheels and rotor, and the armature's magnetic energy"
     variable E_kin::Energy
   relations
     P_dc = drive.battery.v * drive.battery.i
     P_shaft = drive.machine.P_mech
     der(E_cells) = drive.battery.E * drive.battery.i
     der(E_dc) = P_dc
     der(E_dc_out) = max(P_dc, 0.0)
     der(E_dc_in) = max(-P_dc, 0.0)
     der(E_R0) = drive.battery.R0 * drive.battery.i ^ 2
     der(E_aux) = drive.aux.v * drive.aux.i
     der(E_conv) = drive.converter.P_loss
     der(E_motor) = drive.machine.P_loss
     der(E_shaft_out) = max(P_shaft, 0.0)
     der(E_shaft_in) = max(-P_shaft, 0.0)
     der(E_road) = roadload.F * car.bus.vx
     der(E_brake) = car.fl.brake.tau_friction * car.fl.brake.w + car.fr.brake.tau_friction * car.fr.brake.w + car.rl.brake.tau_friction * car.rl.brake.w + car.rr.brake.tau_friction * car.rr.brake.w
     der(E_tire) = car.fl.joint.f_long * car.fl.joint.v_slip_long + car.fl.joint.f_lat * car.fl.joint.v_slip_lat + car.fr.joint.f_long * car.fr.joint.v_slip_long + car.fr.joint.f_lat * car.fr.joint.v_slip_lat + car.rl.joint.f_long * car.rl.joint.v_slip_long + car.rl.joint.f_lat * car.rl.joint.v_slip_lat + car.rr.joint.f_long * car.rr.joint.v_slip_long + car.rr.joint.f_lat * car.rr.joint.v_slip_lat
     E_kin = 0.5 * m * (car.body.v[1] ^ 2 + car.body.v[2] ^ 2) + 0.5 * car.Iz * car.body.w ^ 2 + 0.5 * car.J * (car.fl.inertia.w ^ 2 + car.fr.inertia.w ^ 2 + car.rl.inertia.w ^ 2 + car.rr.inertia.w ^ 2) + 0.5 * drive.machine.J * drive.machine.rotor.w ^ 2 + 0.5 * drive.machine.L * drive.machine.inductor.i ^ 2
     initial E_cells = 0.0
     initial E_dc = 0.0
     initial E_dc_out = 0.0
     initial E_dc_in = 0.0
     initial E_R0 = 0.0
     initial E_aux = 0.0
     initial E_conv = 0.0
     initial E_motor = 0.0
     initial E_shaft_out = 0.0
     initial E_shaft_in = 0.0
     initial E_road = 0.0
     initial E_brake = 0.0
     initial E_tire = 0.0
   end

   analysis BEVEnergyBillTransient
     extends TransientAnalysis(stop = 1800.0, alg = ODEAlg.Rodas5P(), dtmax = 1.0, optimize = OptimizationLevel.None())
     parameter k::Real = 50.0
     parameter Ti::Time = 2.0
     parameter v_fade::Real = 10.0
     parameter P_aux::Power = 300.0
     model = BEVEnergyBill(k = k, Ti = Ti, v_fade = v_fade, P_aux = P_aux)
   end
   ```

   :::

2. Click ▷ **Run Analysis → BEVEnergyBillTransient** once, then read the bill:

   ```julia
   r = MyCar.BEVEnergyBillTransient();
   km = r.sol[r."car.bus.x"][end] / 1000
   kWh(x) = r.sol[x][end] / 3.6e6
   links = ["road load" => r."E_road", "machine" => r."E_motor", "auxiliaries" => r."E_aux",
       "battery R0" => r."E_R0", "converter" => r."E_conv", "tire slip" => r."E_tire",
       "friction brakes" => r."E_brake"]
   [name => round(kWh(x) / km * 1000; digits = 1) for (name, x) in links]  # Wh/km per link
   Wh_per_km = kWh(r."E_dc") / km * 1000                             # at the battery terminals
   ΔE_kin = (r.sol[r."E_kin"][end] - r.sol[r."E_kin"][1]) / 3.6e6
   residual = (sum(kWh(x) for (_, x) in links) + ΔE_kin - kWh(r."E_cells")) / kWh(r."E_cells")
   MJ_per_100km = Wh_per_km * 3.6 / 10, 5.22 * 0.745 * 43.4         # this car, the engine car
   kWh(r."E_dc_in") / kWh(r."E_shaft_out")                          # braking energy back, per traction
   ```

::: tip Expected result

**The bill, in Wh/km:** road load **103.1**, machine **17.6**, auxiliaries **6.4**, battery *R*<sub>0</sub> **3.1**, converter **2.1**, tire slip **1.8**, friction brakes **0.1**. Unrounded, they add up to **134.3 Wh/km** out of the cells, and `residual` is a few **10⁻⁹**. The car ends at rest, so `ΔE_kin` is zero.

**At the battery terminals:** `Wh_per_km` is **131.2**, 13.12 kWh/100 km, inside the plan's 120–155 Wh/km. The terminals gave out 165.4 Wh/km and took **34.2 Wh/km** back from braking: 24 % of the traction energy. The friction brakes burned only what the fade below 10 km/h left them.

**Against the engine car:** **47.2 MJ/100 km** against **168.8 MJ/100 km**, 3.6 times less, on the same cycle and road load with a car 100 kg heavier.

**Change one thing:** `MyCar.BEVEnergyBillTransient(P_aux = 500.0)` puts the consumption at 135.5 Wh/km: 200 W more for half an hour on 23 km is 4.3 Wh/km. A heater at 3 kW would add 64 Wh/km, half again.

Reference: `HandsOn04.BEVEnergyBill`, `HandsOn04.BEVEnergyBillTransient`; the course library's `Vehicle.Planar.PlanarBEVWLTC` carries the same meters, and `notebooks/lecture04/03-energy-bill.pluto.jl` draws the bill.

:::

Commit: **Source Control** → message `Step 06: energy bill` → **Commit** → **Sync Changes**.

:::: warning Fell behind?

Paste `BEVEnergyBill` from step 1 of **Do this** above; it needs step 04's `ElectricDrive` and `BEVWLTC`, whose **Fell behind?** block is above.

::::

---

Reference models: `dyad/HandsOn04/` in the course repository; checkpoint tests in `test/machine_plausibility.jl`, `test/converter_plausibility.jl`, `test/battery_plausibility.jl`, `test/bev_plausibility.jl` and `test/regen_plausibility.jl`. Design: `docs/lecture-04-plan.md`.
