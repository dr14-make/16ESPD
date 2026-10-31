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
Section 08, the energy bill, the headline result of the lecture. We put a meter on every link of the
chain, read the WLTC bill in kilowatt-hours per 100 kilometers, see what braking gave back, and
compare the same cycle, in megajoules per 100 kilometers, with Lecture 2's engine car. The figures
come from notebook 03, and the section ends with build 06.
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
The battery alone would give us the consumption. A meter on every link gives us the bill: where each
kilowatt-hour went.

The table lists the meters, and each one integrates a power. `E_cells` integrates E times i, the
energy out of the cells. `E_dc` integrates v times i at the terminals, the battery's output. `E_R0`
integrates R0 i squared, the battery's resistance. `E_aux` integrates the auxiliary load's v times
i, the 12 volt network. `E_conv` integrates the converter's loss power, and `E_motor` the machine's.
`E_road` integrates the road-load force times the car's speed: drag and rolling resistance. And
`E_brake` and `E_tire` integrate torque times wheel speed at the four friction brakes, and tire
force times slip speed at the four tires.

On the right: a meter is a state. For example, the derivative of `E_road` equals the road-load force
times the car's speed, starting from zero. The solver integrates it with the same accuracy as the
car's speed, so the bill does not depend on how the result is saved.

Energy is conserved, so the links must add up, and that is the formula. What left the cells, E
cells, equals the road load, plus the friction brakes, plus tire slip, plus the losses of the
machine, the converter and the battery's resistance, plus the auxiliaries, plus the change of
kinetic energy, Delta E kin, which is zero when the car ends at rest. The reduction and the
differential are ideal and cost nothing.

Each meter is measured on its own, from its own part's power, so their sum closing on the battery
checks the model. A sign error in a connector, or a loss counted twice, would show up as a residual.
On the reference run the residual is 3 times 10 to the minus 9.
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
The WLTC bill. The figure is notebook 03, section 2, where the energy went: the course library's
`PlanarBEVWLTC`, the twin of the `BEVEnergyBill` you build. Each bar is one link's loss over the
whole cycle, divided by the distance, in watt-hours per kilometer, and the title gives the total:
out of the cells, 134.3 watt-hours per kilometer.

Read the bars from left to right. The road load, drag and rolling resistance: 103.1, the price of
moving the car at all. The machine: 17.6, the largest loss of the chain, because the WLTC drives at
light load, where section 04's map is lowest. The auxiliaries: 6.4, that is 300 watts for half an
hour. The battery's resistance: 3.1. The converter: 2.1. Tire slip: 1.8. And the friction brakes:
0.1, only what the fade leaves near standstill. Together, 134.3.

The table on the right is the consumption at the battery terminals, what the pack delivers: 131.2
watt-hours per kilometer, which is 13.12 kilowatt-hours per 100 kilometers. It is less than what
left the cells by exactly the 3.1 lost in the battery's own resistance. The plan's band is 120 to
155 watt-hours per kilometer. It is derived from the Leaf's official WLTP figure of 171 watt-hours
per kilometer, which is measured at the wall: less 10 to 15 percent for charging, and allowing for
the course road load being about 15 percent below the Leaf's measured coastdown. We land inside it.

So, the text under the table: the road takes three quarters, and of the chain the machine is the
largest loss, at light load, where the fixed losses count.
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
What did braking give back? The table is build 06's worked checkpoint, over the whole WLTC. The
machine's shaft delivered 3.341 kilowatt-hours of traction. Under braking it took back 0.897
kilowatt-hours, 27 percent of the traction. Of that, 0.795 kilowatt-hours reached the battery, 89
percent: the machine, the converter and the pack each take a few percent on the way back. So the
battery got back 24 percent of the traction energy.

At the battery terminals, per kilometer: the battery gave out 165.4 watt-hours and took 34.2 back
from braking. The difference, 131.2, is the bill on the last slide.

On the right: a quarter of the energy the machine put into the wheels came back to the pack. Without
regen every stop would have burned it in the brakes, as in Lecture 2's car.

And here is the anchor that section 07 pointed to: 18 to 25 percent. It is derived. About a quarter
of the traction energy comes back as braking, 25 to 26 percent, and Boretti's analysis of measured
2012 and 2013 Leafs found the regen path, from braking power at the vehicle to the battery,
recovering 70 to 87 percent of it. Our lossless reduction lets 89 percent through, so we land in the
upper half of the band. The gap to the measured car is the efficiency of the regen path, not a
ceiling.

That is the thesis of the lecture in one table: the chain closes in both directions, and each link
costs a few percent each way.
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
Against the engine car. The figure is notebook 03, section 4: the energy over the WLTC in megajoules
per 100 kilometers, three bars. Green, Lecture 2's engine car, in fuel: 168.8. Light gray, the
battery-electric car at the wall, including the 13 percent charging loss: 54.3. Blue, the
battery-electric car at the battery: 47.2.

The arithmetic on the right. One kilowatt-hour is 3.6 megajoules, so 13.12 kilowatt-hours per 100
kilometers is 47.2 megajoules per 100 kilometers. Lecture 2's engine car burns 5.22 liters per 100
kilometers on the same cycle; times 0.745 kilograms per liter, times the lower heating value of 43.4
megajoules per kilogram, that is 168.8. The electric car needs 3.6 times less energy, on the same
cycle and road load, with a car 100 kilograms heavier. And at the wall, 47.2 divided by 0.87 is
54.3.

Be fair about the comparison. The engine car weighs 1400 kilograms, this one 1500. Neither carries a
heater or air conditioning: a 3 kilowatt heater would add 64 watt-hours per kilometer, half again.
And the megajoules of electricity were made somewhere, in a power station, at its own efficiency.
The bill compares the cars, not the energy systems behind them.

Most of the gap is the engine's efficiency, about 30 percent at its best, against a chain that loses
a few percent per link and gets braking energy back. The notebook also shows the gap phase by phase:
it is widest in town, where the engine runs far below its best efficiency and every stop turns
kinetic energy into heat, and it narrows on the motorway, where drag dominates both bills.
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
Build 06: the WLTC energy bill. This is the shortest build: one paste and one run.

The italic line: a new component `BEVEnergyBill`, pasted from the guide. It extends your build 04
bench, so it is the same car, with the meters of two slides back added as states. Its analysis,
`BEVEnergyBillTransient`, passes P aux through. Run it once, then read the bill.

The snippet on the right. km is the distance driven, in kilometers. kWh converts a meter's final
value from joules to kilowatt-hours. links lists the seven meters with their names, and the next
line prints each one in watt-hours per kilometer. Wh per km is the meter at the battery terminals
per kilometer: the consumption. And the last line puts this car and the engine car side by side, in
megajoules per 100 kilometers. The guide's version of the snippet also computes the residual and the
braking share.

The first green box, the bill in watt-hours per kilometer: road load 103.1, machine 17.6,
auxiliaries 6.4, battery R0 3.1, converter 2.1, tire slip 1.8, friction brakes 0.1. Unrounded, they
add up to 134.3 out of the cells, and the residual is a few times 10 to the minus 9. The car ends at
rest, so the change of kinetic energy is zero.

The second green box: Wh per km at the terminals is 131.2, 13.12 kilowatt-hours per 100 kilometers,
inside the plan's 120 to 155. The terminals took 34.2 watt-hours per kilometer back from braking.
47.2 megajoules per 100 kilometers, against 168.8 for the engine car. And change one thing: with P
aux at 500 watts the consumption becomes 135.5. 200 watts more, for half an hour, over 23
kilometers, is 4.3 watt-hours per kilometer.
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
Section 08 in five lines. Every link has its own meter, and their sum closes on the cells to 3 times
10 to the minus 9. On the WLTC the car takes 131.2 watt-hours per kilometer at the battery, 13.12
kilowatt-hours per 100 kilometers, inside the plan's band of 120 to 155. The road takes 103.1, the
machine 17.6, the auxiliaries 6.4, and the rest of the chain a few watt-hours per kilometer each.
Braking gave back 24 percent of the traction energy. And 47.2 megajoules per 100 kilometers, against
168.8 for Lecture 2's engine car: 3.6 times less.

That is the headline: the same car on the same cycle needs a bit over a quarter of the energy with
an electric chain, because each link is efficient and the chain runs backwards when the car brakes.
-->
