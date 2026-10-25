---
routeAlias: wrap-up
layout: section
---

###### Section 06

# Wrap-up

What each system measures, what it controls, and what it acts on.

<!--
Budget: 3 minutes for the section: the table 1, the summary 1, what you measured 1. The sources
slide is for the handout; skip it in the room.

One table for the whole lecture, the summary, the numbers the students measured, and the sources.
-->

---
routeAlias: systems-table
---

## One idea, three systems

| System | Measures | Keeps near the peak | Acts on |
|---|---|---|---|
| **ABS** | wheel speeds | braking slip of each wheel | brake pressure: build, hold, dump |
| **TCS** | wheel speeds | driving slip of each driven wheel | brake on one wheel, engine torque |
| **ESP** | + steering angle, yaw rate, lateral acceleration | the car's yaw rate and sideslip | brake on single wheels, engine torque |

Each one builds on the hardware of the one before: ESP is impossible without four-channel ABS.

<!--
Read the table top to bottom. Each system adds either a sensor or an actuator to the one before.
ABS needs wheel speeds and valves that can take pressure away. TCS adds the engine as an actuator
and valves that can build pressure. ESP adds three sensors that tell it what the driver wants and
what the car does.

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
  without it, our planar car spins in the sine-with-dwell; through ABS, no braked wheel locks.

### Next: what you measured on your own car. <Link to="what-you-measured">→</Link>

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
routeAlias: what-you-measured
---

## What you measured

| Build | What | Number | Why |
| --- | --- | --- | --- |
| 01 | the tire's limit | 4256 N·m · 31.9 to 45.5 m | by hand |
| 02 | your brake system, pedal to wheel | 36.0 m at pedal 0.3 · 43.7 m at 0.6, locked | past the tire's 4256 N·m the wheel locks |
| 03 A | ABS on the present slip | 53.4 m, longer than locked | 30 ms too late each cycle |
| 03 C | ABS with a 30 ms look-ahead | 34.2 m, 22 % shorter | the lag led |
| 04 | ABS on the wheel speed only | 38.5 m yours · 38.7 m library | dump, hold, build slowly |
| 05 | on snow, μ 0.3 | 136.7 · 106.1 · 130.6 · 141.3 m | locked · true slip · yours · library |

The controller that knows the slip wins on every road. Without the car's speed, an ABS trusts
the wheel's own deceleration and remembers the pressure; on snow that gains only 5 %, as on real
cars. Where it trusts a poor guess of the speed instead, it can stop longer than a locked wheel.

<div class="text-sm opacity-70 mt-4">

Take home: traction control on your `SlipCar`, <Link to="bonus-tcs">the bonus task</Link>, for
extra points. Next lecture: active and passive safety, including the restraint systems (airbags,
belt pretensioners).

</div>

<!--
Budget: 1 minute. The section 03 claims, each tested on your own parts and your own brake: a
locked wheel stops on the sliding friction, build 02; ABS holds the tire near its peak and stops
shorter, build 03 C; the controller must lead the 30 millisecond lag, build 03 A against C;
without the car's speed it must estimate it, and an estimate it trusts too much can cost the
whole gain, builds 04 and 05. Yours on the wheel speed matches the library's ECU on a dry road,
and on snow gains little over a locked wheel, as measured cars do.

Commit your work on the `lecture-03` branch: one commit per build is a good habit. The bonus goes
in as a pull request from that branch; the guide page says what it must contain.

The notebooks are in the repository, and the reference answers to every build are in
`dyad/HandsOn03/`.
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
- `docs/lecture-03-tire-models-research.md`: slip, the tire-model family, the locked wheel

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
- Allegro MicroSystems, A19302 datasheet (wheel-speed IC: current levels, PW and AK protocols);
  Infineon, TLE5041plusC product brief (2013); SKF, patent US 11041875 B2 (encoder ring)

**Papers and books**

- A. van Zanten, R. Erhardt, G. Pfaff, *VDC, the Vehicle Dynamics Control System of Bosch*,
  SAE 950759 (1995)
- J. Day, S. Roberts, *A Simulation Model for Vehicle Braking Systems Fitted with ABS*,
  SAE 2002-01-0559
- R. Rajamani, *Vehicle Dynamics and Control*, 2nd ed., Springer 2012, ch. 2 and 8
- T. D. Gillespie, *Fundamentals of Vehicle Dynamics*, SAE 1992, ch. 6 (Ackermann steering)
- W. F. Milliken, D. L. Milliken, *Race Car Vehicle Dynamics*, SAE 1995 (steering systems)
- J. C. Gerdes et al., California PATH report UCB-ITS-PRR-97-21 (brake system model)
- H. B. Pacejka, *Tire and Vehicle Dynamics*, 3rd ed., Elsevier 2012 (slip, brush model,
  Magic Formula); E. Bakker, L. Nyborg, H. B. Pacejka, SAE 870421 (1987)
- E. Fiala, VDI-Z 96 (1954); H. Dugoff, P. Fancher, L. Segel, SAE 700377 (1970); M. Burckhardt,
  *Radschlupf-Regelsysteme*, Vogel 1993
- W. Hirschberg, G. Rill, H. Weinfurter, *Tire model TMeasy*, VSD 45 (2007); C. Canudas de Wit
  et al., IEEE TAC 40(3) (1995), LuGre; M. Gipser, *The FTire Tire Model Family* (cosin)
- MathWorks, Simscape Driveline *Tire-Road Interaction (Magic Formula)*: typical coefficients

</div>
</div>

<!--
Where each fact came from. The speaker notes on each slide name the source for the facts on it,
and say when something could not be verified.

Not verified from a primary source: Voisin's date, around 1920, from secondary sources only; the
classification of three- and one-channel ABS; the margin factor on the reference yaw rate in
Rajamani; the engine interventions of a particular TCS product. The 7 and 14 milliamp levels of
active wheel-speed sensors come from an Allegro datasheet, not a Bosch one; the VDA AK-protocol
specification itself was not opened. The 2 to 6 per second ABS slip cycle is cited from Day and
Roberts by the repository's frequency research; the paper itself is paywalled.
-->
