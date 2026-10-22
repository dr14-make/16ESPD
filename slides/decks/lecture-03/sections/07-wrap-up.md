---
routeAlias: wrap-up
layout: section
---

###### Section 07

# Wrap-up

What each system measures, what it controls, and what it acts on.

<!--
Budget: 4 minutes for the section: the table 1, the summary 1, the hand-over 2. The sources slide is
for the handout; skip it in the room.

One table for the whole lecture, the summary, the hand-over to the hands-on, and the sources.
-->

---
routeAlias: systems-table
---

## One idea, four systems

| System | Measures | Keeps near the peak | Acts on |
|---|---|---|---|
| **ABS** | wheel speeds | braking slip of each wheel | brake pressure: build, hold, dump |
| **TCS** | wheel speeds | driving slip of each driven wheel | brake on one wheel, engine torque |
| **ESP** | + steering angle, yaw rate, lateral acceleration | the car's yaw rate and sideslip | brake on single wheels, engine torque |
| **Torque vectoring** | the same as ESP | the car's yaw response, all the time | drive torque per wheel |

Each one builds on the hardware of the one before: ESP is impossible without four-channel ABS.

<!--
Read the table top to bottom. Each system adds either a sensor or an actuator to the one before.
ABS needs wheel speeds and valves that can take pressure away. TCS adds the engine as an actuator
and valves that can build pressure. ESP adds three sensors that tell it what the driver wants and
what the car does. Torque vectoring adds an actuator that can push as well as brake.

And each is a controller around the same nonlinear plant: the tire, whose force peaks and then
falls. The same family of cascade loops Lecture 1 ended on.
-->

---

## Summary of the lecture

- **01** friction peaks at a few percent of slip and falls when the tire slides; braking distance
  is $v^2 / 2 g \mu$.
- **02** lever, booster and master cylinder turn a 169 N foot into the 62 bar that stops the
  car at 1 g, in two independent circuits.
- **03** ABS holds each wheel near its peak with only wheel speeds to go on; the car stays
  steerable and stops shorter. In the model: 11 % shorter on a dry road.
- **04** TCS does the same for a driven wheel, with the brakes and the engine.
- **05** ESP compares the driver's intention with the car's yaw rate and brakes single wheels;
  without it, our planar car spins in the sine-with-dwell.
- **06** torque vectoring makes the same yaw moment with drive torque instead of brakes.

### Next: the hands-on, ABS on your own car. <Link to="handover">→</Link>

<!--
If you take one picture away from today, take the friction curve with the ABS dots crowded at its
peak. Everything else today is about getting the tire there and keeping it there.

The notebooks are in the repository: `notebooks/lecture03/01-abs.pluto.jl` and
`02-brake-hydraulics.pluto.jl`. Open them in Pluto, move the sliders: road friction and a_ref in
the first, booster vacuum in the second.

The source deck's title also named SRS, the supplemental restraint system. It is covered in
Lecture 4 with the rest of active and passive safety.
-->

---
routeAlias: handover
---

## Next: the hands-on, ABS on your own car

<div class="grid grid-cols-[1.25fr_1fr] gap-8">
<div>

| Step | | min | theory |
|---|---|---:|---|
| 00 | Set up | 8 | |
| 01 | The tire's limit, by hand | 7 | <Link to="braking-distance">01</Link> |
| 02 | Lock the wheel | 15 | <Link to="one-stop">03, one stop</Link> |
| 03 | An ABS of your own | 25 | <Link to="abs-model">03, the model</Link> |
| 04 | Only the wheel speed | 18 | <Link to="reference-speed">03, reference speed</Link> |
| 05 | Across road surfaces | 14 | <Link to="abs-surfaces">03, surfaces</Link> |
| | Hand in: a pull request | 3 | |

Bonus, after the session: **traction control** on your `SlipCar` (step 06).

</div>
<div>

**Have open**

- **Dyad Studio** with your `MyCar`, on a new branch `handson-03` from `main`
- the **guide**: [handson/lecture-03](../handson/lecture-03/index.html)
- **this deck, section 03**: its result slides are the checkpoints
- paper or the Julia REPL for step 01

**Bring from earlier**: hands-on 1's `Body` and `TireFrictionCurve`. Hands-on 2 is not needed.

<div class="text-sm opacity-70 mt-4">

Next lecture: active and passive safety, including the restraint systems (airbags, belt
pretensioners).

</div>
</div>
</div>

<!--
Budget: 2 minutes. Leave it on the projector while the room switches over, so laptops are open on
the right things when the hands-on starts.

The hands-on has its own deck, `handson-03`, one slide per step, and its guide on the course site.
Step 00 adds the course library at the tag the session was rehearsed on; the guide gives the exact
`Pkg.add` line, so do not dictate it from here.

Every number a step checks against is on a slide of section 03: the locked stop's 43.7 meters,
the true-slip ABS's 34.4, the wheel-speed-only ABS's 38.7, the surface table. The green cues on
those slides say which step uses which.

A student who did not finish hands-on 2 can still do all of it: the session needs only hands-on
1's `Body` and the course library.
-->

---
routeAlias: sources
---

## Sources

<div class="grid grid-cols-2 gap-8 text-sm">
<div>

**Course and repository**

- Source deck: *3. ABS, ESP, SRS* (course materials); figures from HowStuffWorks and Renault as
  credited there
- `docs/reports/Passenger car brake system modeling.md` and its research notes
- `docs/abs-frequency-research.md`, `docs/abs-braking-distance-findings.md`,
  `docs/abs-controller-spec.md`, `docs/lecture-03-preparation.md`
- `docs/lecture-03-esp-research.md`, `docs/lecture-03-esp-dyad-tasks.md`: the planar car and
  the sine-with-dwell runs

**Standards and agencies**

- 49 CFR 571.126 (FMVSS 126), electronic stability control; NHTSA final rule, 72 FR 17236 (2007)
- NHTSA, Kahane, DOT HS 812 020 (2014), ESC effectiveness
- 49 CFR 571.135 (FMVSS 135), light vehicle brake systems
- Regulation (EC) 661/2009 and (EU) 407/2011; UN Regulation 140

</div>
<div>

**Industry**

- Bosch Mobility: antilock braking system; electronic stability program; wheel-speed sensor
- Bosch press archive: "Staying on track", 25 years of ESP
- Mercedes-Benz: 40 years of ABS (1978)
- Volkswagen newsroom: XDS; Honda: SH-AWD (2004)

**Papers and books**

- A. van Zanten, R. Erhardt, G. Pfaff, *VDC, the Vehicle Dynamics Control System of Bosch*,
  SAE 950759 (1995)
- J. Day, S. Roberts, *A Simulation Model for Vehicle Braking Systems Fitted with ABS*,
  SAE 2002-01-0559
- R. Rajamani, *Vehicle Dynamics and Control*, 2nd ed., Springer 2012, ch. 2 and 8
- T. D. Gillespie, *Fundamentals of Vehicle Dynamics*, SAE 1992, ch. 6 (Ackermann steering)
- W. F. Milliken, D. L. Milliken, *Race Car Vehicle Dynamics*, SAE 1995 (steering systems)
- J. C. Gerdes et al., California PATH report UCB-ITS-PRR-97-21 (brake system model)

</div>
</div>

<!--
Where each fact came from. The speaker notes on each slide name the source for the facts on it,
and say when something could not be verified.

Not verified from a primary source: Voisin's date, around 1920, from secondary sources only; the
classification of three- and one-channel ABS; the 7 and 14 milliamp levels of active wheel-speed
sensors; the margin factor on the reference yaw rate in Rajamani; the engine interventions of a
particular TCS product. The 2 to 6 per second ABS slip cycle is cited from Day and Roberts by the
repository's frequency research; the paper itself is paywalled.
-->
