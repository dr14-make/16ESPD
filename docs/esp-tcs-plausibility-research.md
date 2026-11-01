# ESP and TCS plausibility: what do measured cars and the regulations say?

Research note for Lecture 3. It collects measured and regulatory numbers for four questions:

1. the FMVSS 126 sine-with-dwell test, and what real cars score in it;
2. how fast an ESP hydraulic unit builds wheel pressure without the pedal;
3. split-µ straight braking;
4. traction control.

It then checks the current Lecture 3 model numbers against those bands.

Read with [`lecture-03-esp-research.md`](lecture-03-esp-research.md) (model fidelity, controller,
build sequence) and [`abs-efficiency-research.md`](abs-efficiency-research.md) (ABS gain on snow,
snow µ–slip curves, R13-H adhesion utilization). This note does not repeat them.

Evidence comes in two kinds:

- **Literature.** Each claim cites its source. A number that only a manufacturer press release
  gives is marked **manufacturer claim**. A number derived from a source by arithmetic is marked
  **derived**. Where no primary source was found, the note says so.
- **Model numbers** are quoted from `test/esp_plausibility.jl`, `notebooks/lecture03/03-esp.pluto.jl`,
  `docs/lecture-03-run-sheet.md` and the `.dyad` sources. Nothing was rerun for this note.

## Summary

1. **Sine-with-dwell.**
   - **Procedure.** 80 km/h, coasting. A is the steering-wheel angle for 0.3 g in the slowly
     increasing steer test (13.5°/s). The steer is a 0.7 Hz sine with a 500 ms dwell at the second
     peak. Amplitudes go from 1.5A in 0.5A steps to the larger of 6.5A and 270°, capped at 300°.
     Pass limits: yaw rate ≤ 35 % of the peak 1.0 s after COS and ≤ 20 % at 1.75 s, and lateral
     displacement ≥ 1.83 m at 1.07 s after BOS for GVWR ≤ 3500 kg [1].
   - **ESC off.** Five 2004 cars spun at 110–190° of steering wheel angle [3]. In the NPRM's
     example car, the yaw rate was still about 35°/s at COS in the 169° run, and it was rising
     again at COS + 2 s [2].
   - **ESC on.** All 62 production vehicles of 2005 met the limits left-right, and one failed
     right-left [2]. The NPRM's example car sat at about 30 % 1.0 s after COS at 279°, just under
     the 35 % limit [2]. A 2022 compliance test (Toyota Highlander) scored |ratio| ≤ 3.6 % on every
     run up to 270°, and 3.1–3.4 m of lateral displacement [5].
   - **Where the limits come from.** The ratio limits are set where the logistic spin model gives
     a 95 % or higher chance of a heading change under 90° [2, 4]. The 1.83 m limit is the least
     responsive production group (SUVs with roll stability control) that NHTSA did not want to
     ban [2].
2. **Active pressure build.**
   - No published bar/s figure or time to 50 or 100 bar for a pump-based ESP was found in a
     primary source.
   - Two suppliers state their by-wire units against a conventional system [7, 8]. Continental's
     MK C1 reaches "time-to-lock" in 150 ms, "twice as fast as conventional systems". Bosch's
     iBooster reaches full pressure in about 120 ms, "three times faster". Those claims put a
     conventional ESP at about 300–360 ms to lock (**derived**).
   - **Cold fluid.** FMVSS 116 allows up to 1800 mm²/s at −40 °C for DOT 4 [10]. Bosch patents
     name high viscosity as the limit on build dynamics, which is why precharge pumps and
     accumulator pre-filling exist [11, 12].
   - **One-wheel ESP pressure.** A Bosch patent states "up to 140 bar" during ESP regulation
     [11]. No measured one-wheel intervention pressure during a sine-with-dwell was found.
3. **Split-µ.**
   - **R13-H** [13]. 50 km/h, kH ≥ 0.5, kH/kL ≥ 2. No direct-controlled wheel may lock. The
     steering correction must stay ≤ 120° in the first 2 s and ≤ 240° in all; yaw ≤ 15° and a
     3.5 m lane are the stability limits in §5.3.6. The laden deceleration must be
     z ≥ 0.75·(4kL + kH)/5 and z ≥ kL [13, 15].
   - **NHTSA, nine 1990s cars at 48 km/h** [14]. With ABS disabled, every car yawed out of its
     lane. With ABS, the driver kept control easily and ABS stopped 11 % shorter.
   - **NHTSA, five 2000s cars at 50 km/h, PFC 0.35/0.85** [15]. They decelerated at
     0.48–0.67 g, with 10–71° of steering correction and "minimal yaw angle".
   - No measured comparison of select-low, yaw-moment build-up (GMA) and ESP on the same car was
     found.
4. **TCS.**
   - **Target slip.** A Ford patent sets 3–8 % drive slip and cites prior art at about 10 % [17].
     Measured snow µ–slip peaks sit at 20–40 % slip (see
     [`abs-efficiency-research.md`](abs-efficiency-research.md) §2), so a snow target has to be
     higher.
   - **Brake-based TCS** (the "electronic differential lock") works only up to about 40 km/h in a
     Bosch patent [18].
   - **Response order.** Brake (designable as the fastest), then spark, then fuel, then throttle
     [17]. An engine cycle lasts 200–20 ms at 600–6000 rpm, and throttle-valve position has a
     10–100 ms time constant before manifold filling [19].
   - **Traction gain.** No measured with/without-TCS acceleration on snow or ice was found in a
     primary source.
5. **Our models.**
   - **In band:** the passive and ESP sine-with-dwell metrics, the PI ESP split-µ heading, and
     the planar locked-wheel and ABS distances.
   - **Out of band:**
     - ESP braking the wheel directly, which locks it (production ESP is slip-limited);
     - ABS alone on split-µ without GMA or select-low (101°; real ABS cars stay in lane);
     - the TCS snow traction gain (+43 % force, about 0–18 % plausible);
     - the brake actuation speed (about 3× faster than a pump-based ESP, ≥ 3× for the TCS bonus).

## 1. FMVSS 126 sine-with-dwell

### Procedure and criteria (49 CFR 571.126 [1])

| item | value | clause |
|---|---|---|
| surface | peak friction coefficient 1.02 (current text; standard reference test tire) | S6.2.2 |
| ambient | 7–40 °C | S6.1.1 |
| A | steering-wheel angle at 0.3 g, by linear regression over six slowly-increasing-steer runs at 80 ± 2 km/h and 13.5°/s, averaged in absolute value | S7.6 |
| steer | 0.7 Hz sine, 500 ms dwell beginning at the second peak | S7.9 |
| speed | coasting in high gear at 80 ± 2 km/h | S7.9 |
| amplitudes | from 1.5A in steps of 0.5A, up to the greater of 6.5A and 270°, at most 300° | S7.9 |
| BOS / COS | first ±5° of filtered steering angle / steering back to zero after the dwell | S7.11.6, S7.11.7 |
| stability | ψ̇(COS + 1.00 s) ≤ 35 % and ψ̇(COS + 1.75 s) ≤ 20 % of the first yaw-rate peak after the steering reverses | S5.2.1, S5.2.2 |
| responsiveness | lateral CG displacement ≥ 1.83 m (GVWR ≤ 3500 kg; 1.52 m above) at BOS + 1.07 s, for runs at ≥ 5A | S5.2.3 |

The definition also requires individual brake torque at all four wheels and a means to modify
engine torque (S4, S5.1) [1]. The PRIA reads this as requiring ABS-equivalent braking [4].

### Where the limits come from

From the NPRM [2] and the PRIA [4]:

- **Spin-out** is defined empirically as a final heading more than 90° from the initial heading
  after a symmetric steer.
- A logistic regression on all 40 NHTSA and Alliance vehicles predicts the ≥ 90° outcome from the
  remaining yaw rate. If that rate is ≤ 35 % at 1.0 s after zero steer, there is a "95 percent
  (or greater) probability" of no spinout; ≤ 20 % at 1.75 s gives the same prediction [2]. The
  PRIA calls this "a 5 percent spinout threshold" [4].
- In the 2004 phase, the 1.0 s window predicted best. Its one uncertain region sat at **60 %** of
  peak; below 60 % the spin probability was under 50 % [3].
- **1.83 m** is half of a 12 ft lane. It was taken from 61 vehicles in 107 configurations (ESC on
  or off) at ≥ 180° of steering. The least responsive vehicles were SUVs with roll stability
  control, and all but one of the 61 reached 1.83 m [2, 4].
- **1.07 s** is the start of the dwell. It is short enough for the double integration of a_y to
  stay accurate [2, 4].

### Measured: ESC off

Forkenbrock, Elsasser and O'Harra, ESV 05-0221 [3], Table 4 gives the handwheel angle that
produced "excessive yaw" with ESC disabled, on a VDA surface with peak 0.91–0.97 and slide
0.83–0.87:

| vehicle (MY) | SWD 0.5 Hz [°] | SWD 0.7 Hz [°] | 0.7 Hz sine steer [°] |
|---|---:|---:|---:|
| Chevrolet Corvette (2002) | 120 | **110** | 140 |
| Volvo XC90 4x4 (2004) | 130 | **130** | 170 |
| Toyota Camry (2003) | 160 | **160** | 230 |
| Toyota 4Runner 4x4 (2003) | 180 | **170** | 200 |
| GMC Savana 3500 van (2004) | 170 | **190** | none up to 300 |

The paper's text gives 180° for the Camry's sine-with-dwell, where the table gives 160°. The table
is quoted here.

The NPRM's worked example (its Figs. 4–5; the vehicle is not named) [2]:

- **ESC off:** stable at 80° and 120°. At **169°** it spins. The yaw rate is still about 35°/s at
  COS, the same at COS + 1 s, and higher at COS + 2 s, and the car turns "nearly front to rear in
  four seconds".
- **ESC on:** at 80°, 120° and 180° the yaw rate decays "in a fraction of a second". At 279°
  (= 6.5A, so A ≈ 43°, **derived**) it is about **30 %** of peak at COS + 1 s and 0 % at
  COS + 1.75 s.
- So the ESC-on margin at the top amplitude was only about 5 points under the 35 % limit.

The NPRM's Figs. 6–7 plot all 62 vehicles as two clusters, ESC disabled at the top and ESC
enabled at the bottom. The figures are images in the text copy read. So no per-vehicle ESC-off
ratios are quoted here; the full DOT HS 809 974 report was not reachable.

### Measured: ESC on (compliance test)

NHTSA compliance report 126-TRC-21-004, MY 2022 Toyota Highlander, GVWR 2690 kg [5]:

| quantity | value |
|---|---|
| A (0.3 g) | 28.1° |
| amplitudes run | 42° to 270° (1.5A to 9.6A), both directions |
| peak yaw rate | 11.5–58.6 °/s |
| yaw-rate ratio, 1.0 s after COS | −2.5 % to +2.4 % |
| yaw-rate ratio, 1.75 s after COS | −2.3 % to +3.6 % |
| lateral displacement at BOS + 1.07 s (≥ 5A) | 3.12–3.42 m |

A modern ESC therefore stops the yaw essentially at COS, with ratios near zero rather than near
the 35 % limit. Its responsiveness is about 1.8× the minimum.

**Reading.**

- **ESC-off spinouts** in the regulation's research cars start at about 110–190°, roughly 4A
  (169° = 3.9A for the NPRM car, **derived**). A spinning car's ratio stays near or above 100 %.
- **ESC-on cars** range from about 30 % (a 2005-era calibration at 6.5A) down to about 0 % (2022).
- **Responsiveness** of 3.1–3.4 m is typical for a passenger vehicle that passes.

## 2. Active pressure build without the pedal

### What was found

| source | claim | trust |
|---|---|---|
| Continental press release, 1 Aug 2017 [7] | MK C1 "can build up braking pressure in 150 ms (time-to-lock), which is twice as fast as conventional systems" | manufacturer claim |
| Ward's Auto, 19 Jun 2013, on Bosch iBooster [8] | "full braking pressure automatically in a mere 120 milliseconds … three times faster than previous systems" | trade press quoting Bosch |
| Bosch, Automotive Engineering Exposition 2019 sheet [9] | iBooster gen 2: "3 times higher pressure dynamics than normal ESP®" | manufacturer claim, no time given |
| Bosch patent US 8,579,385 [11] | in an ESP regulation "a brake pressure of up to 140 bar can be adjusted"; parallel pump suction improves "pressure buildup dynamics" "especially at low temperatures and with high-viscosity fluid" | primary (patent text), read |
| Bosch patent US 7,896,448 [12] | a "rapid reaction" of ESP is possible if the low-pressure accumulator already holds fluid the pump can suction; the patent pre-fills it through the pedal | primary (patent text), read; no numbers |
| FMVSS 116 S5.1.3 [10] | kinematic viscosity at −40 °C at most 1500 (DOT 3), 1800 (DOT 4), 900 (DOT 5) mm²/s; at least 1.5 mm²/s at 100 °C | regulation, read |

**Derived.** If a conventional pump-based ESP is "half as fast" as 150 ms to lock, or a third as
fast as 120 ms to full pressure, then it needs about **300–360 ms** to reach lock pressure on a dry
road. Both claims compare against an unnamed baseline, so the band is soft.

**Cold fluid.** These numbers bound the effect:

- The FMVSS 116 limit lets DOT 4 be roughly 1000× more viscous at −40 °C than at 100 °C (1800
  vs ≥ 1.5 mm²/s). Pump suction through the master cylinder, the switchover valve and the
  high-pressure valve is the restriction.
- A search excerpt of another brake-control patent (US 6,807,848, not opened) says that below
  about −10 °C viscosity "impairs the controllability" of the brake pressure. It adds that precharge
  pumps and auxiliary pressure sources were proposed but are "increasingly avoided" for cost.
  That is consistent with [11, 12], but it is **unverified** from the full text.
- The "low viscosity" DOT 4 grades (ISO 4925 class 6, about 750 mm²/s at −40 °C) were seen only
  in a trade article quoting Bosch ("the lower the viscosity, the shorter the reaction times of
  ESP"). That is **secondary**; the ISO text was not read.

**Not found:** a measured or specified active build rate in bar/s, the time to 50 or 100 bar at
the caliper, any temperature curve of it, the precharge-pump delivery figures, or the brake
pressure a production ESP applies to the one braked wheel in a sine-with-dwell. The likely owners
are Bosch's *Brake systems and brake control* / Automotive Handbook and van Zanten's SAE 950759
and 2000-01-1633, none of which were accessible.

## 3. Split-µ straight braking

### UN R13-H requirement (Annex 6 [13])

| clause | requirement |
|---|---|
| 5.3.4 | right and left wheels on kH and kL with kH ≥ 0.5 and kH/kL ≥ 2: directly controlled wheels must not lock under a sudden full application at 50 km/h |
| 5.3.5, App. 3 | laden category-1 vehicles must reach z_MALS ≥ 0.75·(4kL + kH)/5 and z_MALS ≥ kL (the formula is an image in the copy read; it is taken from NHTSA's quotation of it [15]) |
| 5.3.6 | brief lock allowed; indirectly controlled wheels may lock, but the vehicle must not exceed a yaw angle of 15° or leave a 3.5 m lane |
| 5.3.7 | steering correction allowed if within 120° in the first 2 s and ≤ 240° in all; the vehicle's median plane starts on the boundary, and no outer tyre may cross it |

At kL = 0.3, kH = 1.0 the minimum z is 0.33 g (**derived**), barely above select-low on all four
wheels (0.30 g). NHTSA called the requirement "extremely low" [15].

### Measured

| source | conditions | result |
|---|---|---|
| Forkenbrock, Flick, Garrott, SAE 1999-01-1287 [14] | nine 1990s cars, 48 km/h, wet asphalt (skid no. 85/65) / wet epoxy (nominal 20/3, actual 52/14 for cars A–G) | ABS disabled, panic brake: "each test vehicle deviated from its stopping lane by yawing out of control". With ABS: "no problem maintaining control". ABS 11.3 % (light) / 11.4 % (laden) shorter than the best non-ABS stop. Two cars stopped shorter without ABS but deviated nearly 3 m from a 3.7 m lane |
| Snyder, Jones, Grygier, Garrott, DOT HS 809 747, 2005 [15] | five 2000s ABS vehicles (LeSabre, Sonoma, Sienna, Corolla, CR-V), 50 km/h, Jennite PFC 0.35 / wet asphalt PFC 0.85, test driver steering | deceleration 0.48–0.67 g (ECE minimum 0.338 g; mean of the two surfaces 0.60 g). Maximum handwheel correction 10–71° (Sienna 10–16°, LeSabre 33–71°, Sonoma 47–58°), reached 1.1–3.9 s after brake application. The driver starts correcting 0.25–0.5 s after the brake goes on. "All of the test vehicles were observed to have minimal yaw angle response" |

DOT HS 809 747 also describes the build strategy, which is the yaw-moment build-up delay. The
pressure rises on all wheels until the low-side front wheel slips. The ABS then "searches for a
higher threshold on the 'high' side". "The short delay before reaching maximum pressure on the
high side gives the driver some reaction time" [15].

### Select-low, GMA and ESP

- **Patents** describe the GMA logic only qualitatively:
  - The Bosch patent DE 3925828 holds the high-µ wheel's pressure, then raises it synchronously
    with the low wheel [16].
  - The Wabco EP 0807562 limits the left/right pressure difference and claims the stopping
    distance is "not significantly lengthened".
  - Neither gives a delay time, a pressure gradient or a measured yaw.
- **Select-low penalty (derived)**, static loads, our planar car geometry (55.6 % front), µ
  1.0 / 0.3, no load transfer:
  - individual control: 0.65 g;
  - rear select-low only: 0.49 g, a stop about 32 % longer;
  - select-low on both axles: 0.30 g, about 2.2× longer.
  - The measured 0.48–0.67 g at 0.35/0.85 [15] lies between all-select-low (0.35 g) and the mean
    (0.60 g), which is consistent with rear select-low plus GMA at the front.
- **Not found:** a measured yaw rate, heading change or steering-correction comparison on one car
  across select-low, GMA and ESP; and any measured select-low stopping-distance penalty.
  Production ABS calibrations are not published. The Karyotakis et al. IAVSD 2023 paper on the
  split-friction stopping limit is simulation only and is not cited for numbers.

## 4. Traction control

### Target slip and limits

| source | value | trust |
|---|---|---|
| Ford patent US 5,519,617 (1996) [17] | desired drive slip "about 3% to 8% of the driving wheel speed"; cites US 4,788,644 at "approximately 10%" | primary (patent), read |
| Zexel Torsen patent US 5,524,080 (1996) | slip-curve peaks "generally fall between 15 and 30 percent wheel slip" | primary (patent), read; general statement |
| Mazda patent US 5,329,453 (1994) | engine target slip below the brake target slip (two thresholds, no values) | primary (patent), read |
| Bosch patent US 4,971,400 (1990) [18] | brake-based ASR used only "up to 40 km/h maximum"; the valve is switched off above about 40 km/h | primary (patent), read |
| Ichihara & Mizoguchi 1970; Fleege et al. 1996 (see [`abs-efficiency-research.md`](abs-efficiency-research.md) §2) | snow and ice µ peak at 20–40 % (compacted snow) or about 30 % (winter surfaces) slip, with lock/peak ≈ 0.85–1.0 | primary, braking direction |

**Not found:** a production TCS calibration table (slip target against speed or surface), or a
primary source for "5–15 %, higher on snow". The 3–8 % and 10 % patent values sit at the dry
µ–slip peak. The winter peaks at 20–40 % imply a higher snow target, but the number a production
system uses was not found.

### Actuator response

| path | what was found |
|---|---|
| order | Ford [17]: brake application "could be designed to be the fastest type of response". Next is spark retard, then fuel control; "the series throttle response is slower still" |
| spark / fuel cut | GM patent US 5,213,178: "spark timing control responds faster than disabling a cylinder"; it runs the traction loop every 12.5 ms. Spark and fuel act per combustion event; an engine cycle is 200–20 ms at 600–6000 rpm [19], so on a four-cylinder the next firing comes 5–50 ms later (**derived**) |
| throttle | valve position time constant "approximately 10–100 ms for common automotive butterfly valves" [19], plus intake-manifold filling (not quantified there) |
| brake | pump-based active build (§2): about 300 ms to lock pressure on dry (**derived**, soft). On snow the needed pressure is about µ times smaller, but pump start and priming do not scale with it |

**Not found:** measured end-to-end TCS response times for throttle, spark and fuel cut on one car.

### Traction gain

**Not found:** a primary, measured acceleration or traction comparison with and without TCS on
snow, ice or split-µ. The SAE originals (Maisch, Jonner, Sigl, SAE 870337; SAE 900204) were not
accessible, and the online material is consumer-level.

Two bounds follow from physics and the measured µ–slip curves (**derived**):

- **Uniform low µ.** The gain is at most peak/spinning − 1. With winter lock/peak ≈ 0.85–1.0, that
  is about 0–18 %. Loose snow can favor spinning, as it favors locking in braking.
- **Split-µ, open differential.** The drive force is limited to about twice the low-µ wheel's
  force. Brake-based TCS lets the high-µ wheel carry more, so the gain is up to
  (µL + µH)/(2µL). That is 2× at 0.2/0.6, before the brake's own losses. No measured number
  was found.

## Check against our models

| model number | measured / regulatory band | verdict | why it might differ |
|---|---|---|---|
| **Passive planar car, sine-with-dwell:** spins (ratio 0.85–1.32) from 97° to 220° with A = 21.6°, so from 4.5A; plows (ratio 0) at 270°; passive y(1.07 s) 1.15–3.73 m | ESC-off spins at 110–190° [3], about 3.9A for the NPRM car [2]; some non-ESC vehicles do not spin [2] | **In band** | A = 21.6° is small next to 28–43° on real cars (16:1 ratio, no steering compliance), so absolute angles look low and multiples of A look high |
| **ESP braking one wheel directly:** passes at every amplitude, ratio 0.00, y(1.07) ≥ 1.83 m from 108°, but the braked wheel locks (κ < −0.9) and the car leaves at 12–16 m/s (≈ 48 km/h from 80) | modern ESC ratio ≈ 0 ± 4 % [5]; 2005-era up to about 30 % [2]; y(1.07) 3.1–3.4 m [5]; production ESC braking is slip-limited (ABS-equivalent required [4]) | **Ratios and displacement in band; the wheel lock is out of band** | Without a slip limit the allocator asks for up to 2500 N·m, about 2× the front lock torque (≈ 1270 N·m at µ 1, **derived**). The 40 % speed loss is a symptom of the lock. No measured end speed after a sine-with-dwell was found, so the speed itself cannot be banded |
| **ESP through ABS:** braked-wheel slip stays above −0.13; car leaves at about 19 m/s | production ESC limits slip like ABS; Bosch states up to 140 bar in ESP regulation [11] | **In band** (qualitatively) | No measured one-wheel slip or pressure trace during a sine-with-dwell was found. The end-speed loss (−14 to −17 % from 76° up) is plausible but unbanded |
| **Split-µ (1.0/0.3, 80 km/h, wheel held straight):** ABS alone 101°; P ESP barely helps; PI ESP 3° | R13-H: yaw ≤ 15°, a 3.5 m lane, 10–240° of steering allowed [13]. Real ABS cars: minimal yaw with 10–71° of driver steering [15]. Non-ABS cars yaw out of the lane [14] | **ABS alone: out of band** against a production ABS; **PI ESP: in band** | "ABS alone" here has individual control on both axles, with no GMA, no select-low and no driver. Production ABS adds GMA, rear select-low and a driver counter-steer starting at 0.25–0.5 s [15]. The 101° behaves like the ABS-disabled cars [14]. It also runs at 80 km/h against R13-H's 50 km/h, with kH/kL = 3.3. The P controller's weakness is real control theory: the heading error is the integral of the yaw-rate error. Production systems rely on feedforward GMA, not on yaw feedback alone |
| **Planar straight stop, µ 1.0, 80 km/h:** locked 31.6 m; ABS 26.5 m (41.0 m from 100 km/h) | ideal v²/2µg = 25.2 m (**derived**). Real dry slide/peak 0.83–0.89 (ABS note) against model µ_S/µ_A = 0.8. R13-H ε ≥ 0.75. Real ABS stops 10–13 % shorter than the best non-ABS stop on dry [14] | **Locked: in band. ABS: in band** (ε ≈ 25.2/26.5 = 0.95, **derived**; the proxy includes the pressure build-up after the pedal). 16 % shorter than locked, against 10–13 % measured, but the measured reference is the best non-ABS stop, not a locked one | The channels release at predicted slip 0.14 front / 0.11 rear, around this tire's peaks (`sAdhesion` 0.12 front, 0.09 rear), and hold mean slip near −0.10 front / −0.08 rear from 0.8 to 2 s. The thresholds, 80 ms prediction and 90 % pressure retention are calibrated assumptions, not a production calibration |
| **TCS bonus, SlipCar on snow (µ scale 0.2):** peak traction 1373 N vs 961 N spinning (+43 %); 8.5 vs 5.7 m/s after 10 s (+49 %) | peak/spinning on packed snow ≈ 1.0–1.18 (lock/peak 0.85–1.0, braking-direction measurements) → about 0–18 % | **Out of band (too optimistic)** | Same cause as the ABS note: one tire curve (sliding/peak 0.70, early peak) scaled by `road_mu`. A snow-shaped curve would shrink the gain. No measured TCS-vs-no-TCS acceleration was found to band it directly |
| **Brake actuation:** planar brakes are torque-level with a 30 ms first-order lag, plus a 100 ms first-order ESP build (`T_build`). The TCS bonus brake has a 30 ms lag | conventional pump ESP ≈ 300–360 ms to lock (**derived** from [7, 8]); by-wire units 120–150 ms [7, 8]; pump start and precharge limits matter, worse in cold fluid [10–12] | **Out of band: too fast.** The ESP path reaches the front lock torque in about 0.1 s (0.07 s of `T_build` plus the 30 ms lag, **derived**), 3× faster than a conventional ESP and close to the by-wire claims. The TCS bonus brake is faster still, by about 10× on paper | A torque-level first-order lag has no pump flow limit, no fluid volume and no viscosity. For TCS on snow the needed pressure is small, which narrows the gap, but pump start-up does not shrink with it. A rate limit in N·m/s, or a dead time of about 0.1–0.2 s before build, would be closer. Neither has a primary number behind it |

## Sources

1. 49 CFR § 571.126, FMVSS No. 126 "Electronic stability control systems for light vehicles",
   S4, S5.1–S5.2, S6, S7.6, S7.9, S7.11. https://www.law.cornell.edu/cfr/text/49/571.126 (read)
2. NHTSA, FMVSS No. 126 NPRM, 71 FR 54712, 18 Sep 2006, §§ "Sine With Dwell", "Spinout Criteria",
   "Responsiveness Criteria".
   https://www.govinfo.gov/content/pkg/FR-2006-09-18/html/06-7598.htm (read). The final rule,
   72 FR 17236, 6 Apr 2007,
   https://www.govinfo.gov/content/pkg/FR-2007-04-06/html/07-1649.htm, was read in part; it
   states the same criteria and that the maneuver is "severe enough to produce spinout for most
   vehicles without ESC".
3. Forkenbrock, G. J., Elsasser, D., O'Harra, B., "NHTSA's Light Vehicle Handling and ESC
   Effectiveness Research Program", 19th ESV, paper 05-0221, 2005, Table 4 and "Definition of
   Spinout".
   https://web.archive.org/web/2020id_/https://www-nrd.nhtsa.dot.gov/pdf/esv/esv19/Other/Print%2005.pdf
   (read)
4. NHTSA, "Preliminary Regulatory Impact Analysis, FMVSS No. 126 Electronic Stability Control
   Systems", 2006, Ch. II.C.
   https://web.archive.org/web/2020id_/https://www.nhtsa.gov/sites/nhtsa.gov/files/fmvss/ESC_PRIA.pdf
   (read)
5. Karls, D. (TRC Inc.), "Final Report of FMVSS 126 Compliance Testing of 2022 Toyota Highlander,
   NHTSA No. C20215104", report 126-TRC-21-004, 17 Dec 2021, SIS and sine-with-dwell tables.
   https://static.nhtsa.gov/odi/ctr/9999/TRTR-647601-2021-001.pdf (read)
6. Forkenbrock, G. et al., "Development of Criteria for Electronic Stability Control Performance
   Evaluation", DOT HS 809 974, Dec 2005, docket NHTSA-2006-25801-0005. (Cited by [2, 4];
   regulations.gov returned 403, so not read.)
7. Continental AG, "Continental's cutting-edge brake technology MK C1 enables the next step to
   highly automated driving", press release, 1 Aug 2017, as republished by Automotive World.
   https://www.automotiveworld.com/news-releases/continentals-cutting-edge-brake-technology-mk-c1-enables-next-step-highly-automated-driving
   (read; manufacturer claim)
8. Ward's Auto, "Bosch rolling out vacuum-free iBooster", 19 Jun 2013.
   https://www.wardsauto.com/news/archive-wards-bosch-rolling-out-vacuum-free-ibooster/783149/
   (read; trade press quoting Bosch)
9. Robert Bosch GmbH, Automotive Engineering Exposition 2019 product sheet, "iBooster and ESP®hev".
   https://www.bosch.co.jp/aee2019/pdf/bosch-automotive-engineering-exposition-2019-electrified--iBooster-and-ESP(r)hev-01.pdf
   (read; manufacturer claim)
10. 49 CFR § 571.116, FMVSS No. 116 "Motor vehicle brake fluids", S5.1.3.
    https://www.law.cornell.edu/cfr/text/49/571.116 (read)
11. Schepp, R., Alaze, N. (Robert Bosch GmbH), "Brake system for a vehicle", US 8,579,385 B2,
    2013. https://patents.google.com/patent/US8579385B2/en (read)
12. Bareiss, A. (Robert Bosch GmbH), "Method for precharging a low-pressure accumulator of a motor
    vehicle braking system", US 7,896,448 B2, 2011.
    https://patents.google.com/patent/US7896448B2/en (read)
13. UN Regulation No. 13-H, Annex 6 §§ 5.3.4–5.3.7 and Appendix 3 (English/Japanese copy hosted
    by MLIT). https://www.mlit.go.jp/jidosha/un/UN_R013H.pdf (read; the Appendix 3 formula is an
    image)
14. Forkenbrock, G., Flick, M., Garrott, W. R., "A Comprehensive Light Vehicle Antilock Brake
    System Test Track Performance Evaluation", SAE 1999-01-1287, "Split-Mu Surface Braking",
    Table 2, Table A1.
    https://web.archive.org/web/20250822053247id_/https://www.nhtsa.gov/sites/nhtsa.gov/files/sae1999-01-1287.pdf
    (read)
15. Snyder, A., Jones, B. (TRC), Grygier, P., Garrott, W. R. (NHTSA), "NHTSA Light Vehicle ABS
    Performance Test Development", DOT HS 809 747, Jun 2005, §4 (Eq. 4.4, Tables 4.19–4.22).
    https://web.archive.org/web/2024id_/https://www.nhtsa.gov/sites/nhtsa.gov/files/absperformancefinalreport.pdf
    (read; Table 4.21's header says "mph", the text says 50 km/h)
16. Robert Bosch GmbH, "Antiblockierregelsystem", DE 3925828 A1; Wabco GmbH, "Verfahren zur
    Giermoment-Abschwächung bei einem Antiblockiersystem", EP 0807562 A2.
    https://patents.google.com/patent/DE3925828A1/de,
    https://patents.google.com/patent/EP0807562A2/de (read; qualitative only)
17. Ford Motor Co., "Torque managed traction control for the drive wheels of an automotive
    vehicle", US 5,519,617, 1996. https://patents.google.com/patent/US5519617A/en (read). Also
    General Motors Corp., "Traction control system with fuel and spark control", US 5,213,178,
    1993, https://patents.google.com/patent/US5213178A/en (read); Zexel Torsen, US 5,524,080,
    1996, https://patents.google.com/patent/US5524080A/en (read); Mazda Motor Corp., US 5,329,453,
    1994, https://patents.google.com/patent/US5329453A/en (read in part).
18. Robert Bosch GmbH, "Method and apparatus for traction control (ASR)", US 4,971,400, 1990.
    https://patents.google.com/patent/US4971400 (read)
19. Zhu, Q., Onori, S., Prucka, R., "An Economic Nonlinear Model Predictive Control Strategy for SI
    Engines: Model-Based Design and Real-Time Experimental Validation", *IEEE Trans. Control
    Systems Technology*, doi 10.1109/TCST.2017.2769660, §§ on actuator dynamics.
    https://pangea.stanford.edu/ERE/pdf/OnoriPDF/Journals/36.pdf (read)

**Not accessible:**

- DOT HS 809 974 (regulations.gov 403) and Forkenbrock & Boyd, ESV 2007 paper 07-0456 (NHTSA
  server 403). They hold the per-vehicle ESC-on and ESC-off yaw-rate ratios.
- Bosch Automotive Handbook and *Brake systems and brake control*; van Zanten et al., SAE 950759
  and SAE 2000-01-1633 (likely owners of the active-build, precharge-pump and intervention-pressure
  numbers).
- Maisch, Jonner, Sigl, SAE 870337, and SAE 900204 (ASR traction gains).
- VW self-study programme 374 on EDL/ASR (host unreachable).
- The full text of US 6,807,848 (Google Patents 404).
- Secondary material seen in search snippets only, and not used for numbers: Brake & Front End on
  low-viscosity fluid, and the Queensland in-service ESC test report (empty download).
