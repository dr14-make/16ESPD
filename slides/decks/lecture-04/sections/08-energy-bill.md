---
routeAlias: energy-bill
layout: section
---

###### Section 08

# The energy bill

A meter on every link of the chain, the WLTC bill in kWh/100 km, what braking gave back, and the
same cycle in MJ/100 km against Lecture 2's engine.

`notebooks/lecture04/03-energy-bill.pluto.jl`

<!--
Budget: about 17 minutes, of which build 06 takes about 8: the meters 2, the bill 3, braking 2,
against the engine 2, build 06 8. The headline result of the lecture.
-->

---
routeAlias: meters
---

## A meter on every link

<div class="grid grid-cols-[1.15fr_1fr] gap-8">
<div class="tight">

| Meter | Integrates | Link |
|---|---|---|
| `E_cells` | *E* · *i* | out of the cells |
| `E_dc` | *v* · *i* at the terminals | the battery's output |
| `E_R0` | *R*₀ *i*² | the battery's resistance |
| `E_aux` | *v* · *i* of `aux` | the 12 V network |
| `E_conv` | `converter.P_loss` | the converter |
| `E_motor` | `machine.P_loss` | the machine |
| `E_road` | road-load force × speed | drag and rolling |
| `E_brake`, `E_tire` | torque × speed, force × slip speed | brakes, tire slip |

</div>
<div>

A meter is a state: `der(E_road) = roadload.F * car.bus.vx`.

Energy is conserved, so the links must add up:

$$
E_{cells} = E_{road} + E_{brake} + E_{tire} + E_{motor} + E_{conv} + E_{R_0} + E_{aux} + \Delta E_{kin}
$$

Each meter is measured on its own: their sum closing on the battery **checks the model**. A sign
error or a loss counted twice shows up as a residual.

</div>
</div>

<!--
Step 06's idea: the battery alone gives the consumption; a meter on every link gives the bill,
where each kilowatt-hour went.

Each meter is a state that integrates a power, started at zero: the road-load meter integrates the
road-load force times the car's speed. The solver integrates it with the same accuracy as the
car's speed, so the bill does not depend on how the result is saved.

The balance: what left the cells equals the road load, the friction brakes, tire slip, the
machine's losses, the converter's, the battery's resistance, the auxiliaries, and the change of
kinetic energy, zero when the car ends at rest. Because every term is measured separately from
its own part's power, a sign error in a connector or a loss counted twice would show up as a
residual. On the reference run it is 3 times 10 to the minus 9.
-->

---
routeAlias: the-bill
class: big-figure
---

## The WLTC bill

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Losses over the WLTC per kilometer, out of the cells 134.3 Wh/km: road load 103.1, machine 17.6, auxiliaries 6.4, battery R0 3.1, converter 2.1, tire slip 1.8, friction brakes 0.1.](/figures/08-energy-bill.svg)

</div>
<div class="text-[0.95rem]">

| at the battery terminals | |
|---|---:|
| **Wh/km** | **131.2** |
| **kWh/100 km** | **13.12** |
| plan's band | 120–155 |

The road takes three quarters. Of the chain, **the machine** is the largest loss: light load,
where the fixed losses count.

</div>
</div>

<!--
The figure is notebook 03 section 2, "Where the energy went": the course library's `PlanarBEVWLTC`,
the twin of your `BEVEnergyBill`, each bar one link's loss over the cycle per kilometer.

Read it left to right. The road load, drag and rolling resistance, 103.1 Wh per km: the price of
moving the car at all. The machine, 17.6: the largest loss of the chain, because the WLTC drives
at light load, where section 04's map is lowest. The auxiliaries, 6.4: 300 watts for half an
hour. The battery's resistance 3.1, the converter 2.1, tire slip 1.8, the friction brakes 0.1:
only what the fade leaves near standstill. Together 134.3 out of the cells.

At the battery terminals: 131.2 Wh per km, 13.12 kWh per 100 km. The plan's band, 120 to 155, is
derived from the Leaf's WLTP figure of 171 Wh per km at the wall, less 10 to 15 percent for
charging, and a course road load about 15 percent below the Leaf's coastdown.
-->

---
routeAlias: braking-back
---

## What braking gave back

<div class="grid grid-cols-2 gap-8">
<div class="tight">

| over the WLTC | kWh | |
|---|---:|---:|
| traction at the shaft | 3.341 | |
| braking taken back at the shaft | 0.897 | 27 % of traction |
| reaching the battery | 0.795 | 89 % of that |
| | | **24 %** of traction |

At the terminals: **165.4 Wh/km** out, **34.2 Wh/km** back.

</div>
<div>

A quarter of the energy the machine put into the wheels came back to the pack.

Without regen every stop would burn it in the brakes, as in Lecture 2's car.

The plan's anchor: **18–25 %**. The measured Leaf's regen path recovers 70–87 % of its braking;
our lossless reduction lets 89 % through.

</div>
</div>

<!--
Step 06's braking numbers, from the guide's worked checkpoint. Over the cycle the shaft delivered
3.341 kWh of traction and took back 0.897 kWh under braking: 27 percent. Of that, 0.795 reached
the battery, 89 percent: the machine, the converter and the pack each take a few percent on the
way back. So the battery got back 24 percent of the traction energy.

At the terminals: the battery gave out 165.4 Wh per km and took 34.2 back; the net, 131.2, is the
bill.

The thesis of the lecture in one table: the chain closes in both directions, and each link costs a
few percent each way.
-->

---
routeAlias: against-the-engine
class: big-figure
---

## Against the engine car

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Energy over the WLTC in MJ/100 km: Lecture 2's engine car 168.8 in fuel, the battery-electric car 54.3 at the wall with 13 % charging loss, and 47.2 at the battery.](/figures/08-mj-comparison.svg)

</div>
<div class="text-[0.95rem]">

1 kWh = 3.6 MJ: **13.12 kWh/100 km = 47.2 MJ/100 km**.

Lecture 2's engine car: 5.22 L/100 km × 0.745 kg/L × 43.4 MJ/kg = **168.8 MJ/100 km**.

**3.6 times less**, on the same cycle and road load, with a car 100 kg heavier. At the wall:
54.3.

</div>
</div>

<!--
The figure is notebook 03 section 4, "Against the engine car".

The units: a kilowatt-hour is 3.6 megajoules, so the electric car's 13.12 kWh per 100 km is 47.2
megajoules. Lecture 2's engine car burns 5.22 liters per 100 km on the same cycle: times the
density 0.745 and the lower heating value 43.4 megajoules per kilogram, 168.8. The ratio is 3.6.
At the wall, with 13 percent lost in charging: 54.3.

Be fair about the comparison. The engine car weighs 1400 kg, this one 1500. Neither has a heater
or air conditioning: a 3 kW heater would add 64 Wh per km, half again. And the megajoules of
electricity were made somewhere: in a power station, at its own efficiency. The bill compares the
cars, not the energy systems behind them.

Most of the gap is the engine's efficiency, about 30 percent at its best and far less at part load
in town, against a chain that loses a few percent per link and gets braking energy back. The
notebook shows the gap phase by phase: widest in town, narrowest on the motorway.
-->

---
routeAlias: build-bill
---

## Build 06: the WLTC energy bill

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

*New `BEVEnergyBill`: paste from the guide. It `extends` your step 04 bench and adds the meters ·
`BEVEnergyBillTransient` · ▷ once, then read the bill*

**Given:** your step 04 `ElectricDrive` and `BEVWLTC`

[page: step 06](../lecture/lecture-04/#step-06) · reference `dyad/HandsOn04/BEVEnergyBill.dyad`

<div class="handson">✓ in Wh/km: road <b>103.1</b>, machine <b>17.6</b>, aux <b>6.4</b>, R₀ <b>3.1</b>,
converter <b>2.1</b>, tire <b>1.8</b>, brakes <b>0.1</b> · <b>134.3</b> out of the cells ·
<code>residual</code> a few <b>10⁻⁹</b></div>

<div class="handson">✓ <code>Wh_per_km</code> <b>131.2</b>, 13.12 kWh/100 km · <b>34.2 Wh/km</b>
back from braking · <b>47.2</b> against <b>168.8 MJ/100 km</b> · <code>P_aux = 500.0</code>:
135.5 Wh/km</div>

</div>
<div>

```julia
r = MyCar.BEVEnergyBillTransient();
km = r.sol[r."car.bus.x"][end] / 1000
kWh(x) = r.sol[x][end] / 3.6e6
links = ["road load" => r."E_road",
    "machine" => r."E_motor", "auxiliaries" => r."E_aux",
    "battery R0" => r."E_R0", "converter" => r."E_conv",
    "tire slip" => r."E_tire", "friction brakes" => r."E_brake"]
[name => round(kWh(x) / km * 1000; digits = 1)
    for (name, x) in links]
Wh_per_km = kWh(r."E_dc") / km * 1000
MJ_per_100km = Wh_per_km * 3.6 / 10, 5.22 * 0.745 * 43.4
```

</div>
</div>

<!--
Eight minutes: one paste, one run, read the numbers.

1. `BEVEnergyBill`: paste from the guide. It extends your step 04 bench, so it is the same car,
   with the meters of the last slide added as states, and the per-kilometer results as variables.
2. The analysis `BEVEnergyBillTransient`, with `P_aux` passed through.
3. Run, then the snippet. The guide's version also computes the residual and the braking share.

Expected, from `HandsOn04.BEVEnergyBillTransient`: road load 103.1 Wh per km, machine 17.6,
auxiliaries 6.4, battery R0 3.1, converter 2.1, tire slip 1.8, friction brakes 0.1. Together 134.3
out of the cells; the residual about 3 times 10 to the minus 9; the car ends at rest so delta E
kin is zero. At the battery terminals 131.2 Wh per km, 13.12 kWh per 100 km, inside the plan's
120 to 155. The terminals gave out 165.4 and took 34.2 back from braking. 47.2 against 168.8
megajoules per 100 km.

Change one thing: 500 watts of auxiliaries puts the consumption at 135.5 Wh per km: 200 watts more
for half an hour over 23 km is 4.3 Wh per km. A 3 kW heater would add 64.

Reference: the course library's `PlanarBEVWLTC` carries the same meters; notebook 03 draws the
bill.
-->

---

## Summary of section 08

- Every link has its own meter; their sum closes on the cells to **3 × 10⁻⁹**.
- WLTC at the battery: **131.2 Wh/km**, **13.12 kWh/100 km**, inside the plan's 120–155.
- The road takes **103.1**, the machine **17.6**, the auxiliaries 6.4; the rest of the chain a few
  Wh/km each.
- Braking gave back **24 %** of the traction energy.
- **47.2 MJ/100 km**, against **168.8** for Lecture 2's engine car: 3.6 times less.

### Next: the whole lecture on one page. <Link to="wrap-up">→ 09, wrap-up</Link>

<!--
One minute. That is the headline: the same car on the same cycle needs a bit over a quarter of the
energy with an electric chain, because each link is efficient and the chain runs backwards when the
car brakes.
-->
