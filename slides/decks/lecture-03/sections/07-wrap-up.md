---
routeAlias: wrap-up
layout: section
---

###### Section 07

# Wrap-up

What each system measures, what it controls, and what it acts on.

<!--
One table for the whole lecture, the summary, and the sources.
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
- **05** ESP compares the driver's intention with the car's yaw rate and brakes single wheels.
- **06** torque vectoring makes the same yaw moment with drive torque instead of brakes.

### Next lecture: active and passive safety, including the restraint systems (airbags, belt pretensioners).

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
- R. Rajamani, *Vehicle Dynamics and Control*, 2nd ed., Springer 2012, ch. 8
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
