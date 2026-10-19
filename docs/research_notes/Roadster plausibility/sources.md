# Tesla Roadster "SpaceX package": is it physically possible?

Sources and back-of-envelope numbers for the Roadster hands-on (#64). Compiled 2026-10-16.

## The event

The unveil was livestreamed on 2026-10-15 (US time) from SpaceX McGregor, Texas, after a weather
delay from Oct 1. Tesla also published two official videos.

- The Ramp | Roadster: https://www.youtube.com/watch?v=7p5LxFdc-Qg
- The Kickflip | Roadster: https://www.youtube.com/watch?v=r5vsHHPVhJg
- Electrek, technical look: https://electrek.co/2026/10/15/an-updated-technical-look-at-teslas-kick-flipping-0-60-in-1s-next-gen-roadster/
- Electrek, unveil: https://electrek.co/2026/10/15/tesla-unveils-cyberfied-new-roadster-kickflip/
- TechCrunch: https://techcrunch.com/2026/10/15/tesla-reveals-spacex-powered-roadster-that-flies-and-falls-with-style/
- Paul Tan, reads the on-screen telemetry: https://paultan.org/2026/10/16/tesla-roadster-revealed-flies-on-spacex-air-thrusters-0-96-km-h-in-0-81s-production-2028/
- CNBC: https://www.cnbc.com/amp/2026/10/15/tesla-roadster-reveal-what-to-know-about-the-delayed-ev.html
- Motor1: https://www.motor1.com/news/812195/tesla-roadster-stunt-2028-production/
- InsideEVs: https://insideevs.com/news/812151/2027-tesla-roadster-price-specs-release-date/
- Teslarati, fans: https://www.teslarati.com/tesla-roadster-downforce-fan-system/
- Tesla on X (URLs from Electrek, not opened):
  - Thrusters and COPVs: https://x.com/Tesla/status/2110904290743402880
  - "4–5x tire force": https://x.com/Tesla/status/2110904620948267152
  - Downforce: https://x.com/Tesla/status/2110905133785829671
  - Trims: https://x.com/Tesla/status/2110905588402295283

## What was shown

- **0–60 mph runs.** One recorded run took 1.0 s. A live run took 0.81 s, with problems
  reported on the timer.
- **Ramp run.** Suction fans held the car on a ramp curling past vertical (about 170° pitch). An
  on-screen readout showed 4,700 kg of downforce. The car then released, pitched over to level,
  and landed on its thrusters. The landing peaked at about 3.3 g.
- **Kickflip.** The car jumped a row of Tesla vehicles while doing a 360° roll.
- **Supersonic exhaust** with shock diamonds.
- **No sustained flight.** Only hops, flips and short hovers. Different cars were used for
  different stunts.
- **Remote staging.** The rig was tethered and staged remotely, with nobody in the car (Motor1,
  Electrek).

## Specs

Each spec is marked by how solid it is: **T** = Tesla said it, **P** = press report not confirmed
by Tesla, **M** = measured or estimated by a third party.

| Item | Value | Status |
| --- | --- | --- |
| Trims (claimed 0–60 mph) | Performance: under 1.6 s, road legal. Thrust: under 0.9 s, rear thrusters. Rocket: under 0.59 s, 10 thrusters, 1 seat, invite only | T |
| Thrusters | 10 cold-gas thrusters on compressed air, 600 L in COPVs, rechargeable | T (Moravy) |
| Rear thrust | Over 80 kN from 4 rear ports. Tesla's "supports more than 8,000 kg against gravity" line is relayed by the press | P |
| Air mass | About 250 kg (attributed to The Verge). Electrek splits the tanks as 200 L on Thrust plus 400 L on Rocket | P |
| Tank pressure | Not published. Conflicting figures: a 5,500 psi (380 bar) cabin readout, and 10,000 psi (690 bar) from Electrek, matching Musk in 2018. 250 kg in 600 L fits roughly 380–450 bar | conflicting |
| Downforce | 4,700 kg readout. Holds the car inverted while stationary. Over 2 g cornering, against 1.26 g from tires alone | T, but Electrek doubts it |
| Fans | About 4 × 20 kW (Electrek estimate) | M |
| Mass | Not disclosed. Estimates: under 1,700 kg (Electrek), about 1,900 kg (Brownlee), about 2,350 kg (CellCog) | M |
| Drivetrain | RWD with 2 rear motors and torque vectoring, over 1 MW, about 1,400 N·m (Hagerty), 4680 cells, 800–1,000 V. Battery kWh not disclosed. Tire grip limit 1.26 g (Moravy) | P (Top Gear, Electrek, EVXL https://evxl.co/2026/10/16/tesla-roadster-1-mw-rear-wheel-drive-unit/) |
| Thruster layout | Thrust trim: 4 rear nozzles in the diffuser. Rocket trim: 10 in total (4 rear, 4 down at the corners, about 2 front/side for yaw and roll). Valves actuated electrically | Moravy, via Electrek and EVXL https://evxl.co/2026/10/16/tesla-roadster-thrusters-compressed-air-tank/ |
| Top speed and range | Over 230 mph, over 300 mi. Top speed figures conflict: 210, 214, 230+ and 330 mph | T, conflicting |
| 0.55 s figure | Measured with a 1 ft rollout, which is worth about 0.1 s | T |
| Tires | Pirelli P Zero Trofeo RS "Elect" | P |
| Price | Not announced. Reservations: $50k for Performance, $250k for Thrust | T |
| Refill | About 6–7 h now, 30 min targeted | P |
| Production | 2028 | T |

## Measured from the videos

These are frame-by-frame estimates from Tesla's two videos, using the car's 4.3 m length as the
scale. Expect 15–20% scale error.

- **Kickflip.**
  - 12.3 m/s horizontal speed and an 8.0 m apex (Paul Tan reads about 7 m).
  - Vertical acceleration of −0.92 g, so the video plays close to real time.
  - Roll of 177°/s, 2.0 s per turn.
- **Ramp.**
  - About 27 m high (Paul Tan reads about 21 m).
  - **The early fall in the main shot measures 2.3 g, so the shot plays about 1.5× faster than real
    time.** This makes a good detective exercise.
  - At real time: about 3 m/s climb, a pitch-over of about 150°/s, and about 27 kN of braking
    thrust.

## Back-of-envelope physics

Inputs: 60 mph = 26.82 m/s and a car of about 2,000 kg unless stated.

| Claim | Calculation | Verdict |
| --- | --- | --- |
| 0–60 mph on tires only | a = μg. μ = 1.26 gives 2.17 s, μ = 1.5 gives 1.82 s. With RWD and load transfer, about 0.8 g, so about 3.4 s | Under 1.6 s needs downforce |
| Fan suction | Normal load is (m + D)g. 4,700 kg over about 4 m² means Δp ≈ 11.5 kPa. Downforce is independent of speed, unlike a wing | Plausible, but the fan power depends strongly on the skirt gap (62–208 kW at 3–10 mm) |
| 0–60 mph in 0.81 s | Average 3.4 g over 11 m. 80 kN gives about 4 g at 2,000 kg, plus the tires | Possible with thrust, if full thrust is reached at t = 0 (pre-spooled) |
| Cold gas | Air Isp is 55–70 s, so v_e is 540–690 m/s. At 80 kN, ṁ is 115–150 kg/s | About 2 s of full thrust from 250 kg. Thrust falls as the tank blows down |
| 7–8 m hop | v_z = √(2gh) ≈ 12 m/s, so the impulse is about 24 kN·s, roughly 0.4 s at 80 kN | 40–55 kg of air. Plausible |
| Power vs traction | The energy floor is t ≥ mv²/(2P) ≈ 0.72 s at 1 MW. Traction and power limits cross at v = P/(μmg) ≈ 40 m/s | 0–60 is limited by traction all the way, not by power |
| 360° roll at the measured 177°/s | I_roll ≈ 870 kg·m², so L ≈ 2.7 kN·m·s. With a 0.9 m arm the impulse is about 3 kN·s, roughly 5 kg of air (double it to stop). A 1 s roll with spin-up and stop needs about 25 kN, roughly 45 kg | Cheap at the video's rate. Rotation is cheap and lift is expensive |
| Hover / "it can fly" | ṁ = mg/v_e ≈ 33 kg/s | About 4–5 s at most. Hops, not flight |
| Stored energy | 600 L at 380 bar: isothermal p·V·ln(p/p0) ≈ 135 MJ (37 kWh). Burst ≈ 46 MJ, about 11 kg of TNT | Crash-safety discussion point |
| Propulsive efficiency at 60 mph | F·v divided by ½ṁv_e² ≈ 7–9% | Rockets are bad at car speeds |

Third-party analyses:
- CellCog, the most quantitative: https://cellcog.ai/blog/tesla-roadster-physics/
- Electrek technical look, linked above.
- Pre-reveal tire-limit analyses by Engineering Explained:
  - https://jalopnik.com/how-the-tesla-roadster-might-pull-off-zero-to-60-mph-in-1820682224
  - https://jalopnik.com/1847047575

## Not verified

- **Not read directly:** tesla.com/roadster and the X posts. Tesla's wording comes through
  Electrek, Teslarati and Paul Tan.
- **Not confirmed by Tesla:** 80 kN and 250 kg.
- **Not disclosed:** mass, battery capacity, pressure and thrust per nozzle.
- **Timing:** the 0.81 s run was timed by Tesla, with problems reported on the timer.
- **Heights and the 3.3 g landing:** read from Tesla's on-screen overlay, not measured.

## Use in the session

The steps, decisions and acceptance bands built on these numbers are in
`docs/roadster-dyad-tasks.md`.
