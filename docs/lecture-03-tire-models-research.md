# Lecture 3: tire slip, tire models, and why a locked wheel does not steer

Research notes behind two slides in `slides/decks/lecture-03/sections/01-friction-and-stopping.md`:
`tire-models` ("Slip, and how simulators model it") and `locked-wheel-steer` ("Why a locked wheel
does not steer"), and their figures from `scripts/export_lecture03_tire_figures.jl`.

Each claim names its source. "Verified" means the source itself was read for this note;
"literature" means a standard reference cited from the textbook literature, not reopened here;
"not verified" says so explicitly. No text or figure is copied from any source.

## 1. Slip

### Longitudinal slip κ

- **Definition used in the models and the deck.** With $V_x$ the wheel center's speed along the
  wheel heading, $\Omega$ the wheel's spin and $r_e$ its effective rolling radius, the slip speed
  of the contact patch is $V_{sx} = V_x - \Omega r_e$ and the practical slip is
  $\kappa = -V_{sx}/|V_x| = (\Omega r_e - V_x)/|V_x|$: zero in free rolling, negative under
  braking, $-1$ for a locked wheel, positive while driving. Source: Pacejka, *Tire and Vehicle
  Dynamics*, 3rd ed. (2012), §1.2 (literature); MathWorks Simscape Driveline, *Tire-Road
  Interaction (Magic Formula)* reference page, which writes exactly $\kappa = -V_{sx}/|V_x|$ and
  states that a locked, sliding wheel has $\kappa = -1$ (verified,
  https://www.mathworks.com/help/sdl/ref/tireroadinteractionmagicformula.html).
- **Our 1D wheel** (`dyad/Vehicle/Wheel/SlipWheel1D.dyad`) uses
  `kappa = (omega * radius - v) / max(abs(v), v_eps)` with `v_eps = 0.5 m/s`: the same definition
  with a floor on the denominator near standstill (verified, repository).
- **Theoretical slip σ.** Brush-model theory uses $\sigma_x = -V_{sx}/V_r$, the slip speed over
  the wheel's circumferential speed $V_r = \Omega r_e$; under braking $\sigma_x = \kappa/(1+\kappa)$,
  unbounded as the wheel locks. Pacejka (2012), §3.2 (literature). This matters here because the
  planar car's tire normalizes by $\Omega r_e$, not by $V_x$ (section 3).
- **SAE J670 / ISO 8855.** Both define longitudinal slip with the same longitudinal velocity
  component, so κ is interchangeable between them; the two axis systems differ by the sign of
  the y and z axes (Altair MotionView documentation, *Utilities to Calculate Tire Kinematics*,
  verified for the axis statement). The exact wording and percent-versus-ratio form in SAE J670
  (2008) and ISO 8855 (2011) was **not verified** (standards are paywalled). MF-Tyre / MF-Swift
  use ISO-style axes and $\kappa = -1$ at lock (Pacejka 2012, ch. 4, literature).

### Slip angle α

- **Definition.** The angle between the wheel's heading (its plane, in top view) and the
  velocity of the wheel center: $\tan\alpha = -V_{sy}/|V_x|$, $V_{sy}$ the lateral slip speed.
  Pacejka (2012), §1.2 (literature). The sign of α and of $F_y$ differs between SAE and ISO axes
  (y and z flipped, as above); the deck uses magnitudes and draws directions, so the sign does not
  matter on the slides.
- **Where lateral force comes from.** A rolling tire's tread elements enter the contact patch
  aligned with the wheel plane and are carried along it, while the patch as a whole moves along
  the travel direction; the tread deflects sideways in proportion to the slip angle, and the
  deflection, held by friction, is the lateral force. At small α the force is linear,
  $F_y = C_\alpha \alpha$, $C_\alpha$ the cornering stiffness. Pacejka (2012), ch. 3, brush model
  (literature); Rajamani, *Vehicle Dynamics and Control*, 2nd ed. (2012), §2.4 (literature).
  **The force needs a slip angle: no angle between heading and travel, no lateral force.**

### Combined slip and the friction circle

- **Friction circle (Kamm circle).** The horizontal force a tire transmits is bounded by about
  $\mu F_z$ in any direction: $F_x^2 + F_y^2 \le (\mu F_z)^2$. Measured tires give an ellipse
  rather than a circle, because longitudinal and lateral peak friction differ. Milliken and
  Milliken, *Race Car Vehicle Dynamics* (SAE, 1995), ch. 2 (literature); Pacejka (2012), §1.3 and
  ch. 4 (literature). The name is after Wunibald Kamm; the original Kamm reference was **not
  verified**.
- **Combined slip in the Magic Formula.** MF 5.x / 6.x multiply the pure-slip forces by weighting
  functions $G_{x\alpha}(\alpha,\kappa)$ and $G_{y\kappa}(\kappa,\alpha)$, each a cosine-arctangent
  "hill" equal to 1 at zero of the other slip, which reduce $F_x$ as α grows and $F_y$ as κ
  grows. Pacejka (2012), §4.3.2; Besselink, Schmeitz and Pacejka, *An improved Magic
  Formula/Swift tyre model that can handle inflation pressure changes*, Vehicle System Dynamics
  48 (suppl. 1), 2010 (literature; MF 6.1).
- **Sliding tire.** A fully sliding contact patch's friction force points against its sliding
  velocity (Coulomb friction is opposite to the relative velocity of the surfaces). For a locked
  wheel, $\Omega = 0$, the patch's sliding velocity is the wheel center's velocity over the
  ground, i.e. along the direction of travel, whatever way the wheel is pointed. So the force is
  straight back along the path, with **no component across it**: it decelerates the car but
  cannot turn it. In the brush model this is the limit of full sliding, where the force direction
  is that of the total slip vector (Pacejka 2012, §3.3, literature); in an isotropic
  combined-slip model like the planar car's it is exact (section 3).

## 2. The model family, one line each

| Model | Captures | Parameters | Cost | Typical use | Source |
|---|---|---|---|---|---|
| Linear, cornering stiffness | $F_y = C_\alpha \alpha$ (and $F_x = C_\kappa \kappa$); no saturation | 1 per axle/direction | trivial | linear bicycle model, ESP reference yaw rate, handling analysis | Rajamani 2012 §2.4; Gillespie 1992 ch. 6 (literature) |
| Brush / Fiala | elastic bristles on a rigid ring; adhesion and sliding zones in the patch; saturates at μF_z; combined slip from the slip vector | stiffness, μ (one or static/kinetic), pressure shape | closed form, cheap | teaching, physical insight, quick handling sims | Fiala, *Seitenkräfte am rollenden Luftreifen*, VDI-Z 96 (1954); Pacejka 2012 ch. 3 (literature) |
| Dugoff | brush-type combined slip in closed form, with a saturation factor; linear stiffness up to friction limit | $C_\alpha$, $C_\kappa$, μ (optionally speed-dependent) | cheap | combined-slip control design, estimation | Dugoff, Fancher, Segel, SAE 700377 (1970); Rajamani 2012 ch. 13 (literature) |
| Burckhardt | μ against slip only: $\mu = c_1(1-e^{-c_2 s}) - c_3 s$ per road surface | 3 per surface (dry/wet asphalt, cobbles, snow, ice …) | trivial | ABS/TCS design, road-friction estimation | Burckhardt, *Fahrwerktechnik: Radschlupf-Regelsysteme*, Vogel 1993; table in Kiencke and Nielsen, *Automotive Control Systems*, Springer (literature) |
| Magic Formula (Pacejka) | empirical fit of measured $F_x$, $F_y$, $M_z$ against slip, load, camber, pressure; combined slip by weighting functions | 4 shape factors (B, C, D, E) for a quick fit; about 100+ coefficients in a full MF 5.2 / 6.x `.tir` file | cheap per evaluation, expensive to measure | industry standard for steady-state and handling simulation | Bakker, Nyborg, Pacejka, SAE 870421 (1987); Bakker, Pacejka, Lidner, SAE 890087 (1989); Pacejka and Bakker, VSD 21 suppl. (1993); Besselink et al. VSD 48 suppl. (2010) (literature) |
| TMeasy | semi-physical: each force curve from a few physically meaningful points (initial slope, peak, sliding), combined slip by normalizing the slip vector | ~ a dozen per load level | cheap | handling, real-time, when measurement data are scarce | Hirschberg, Rill, Weinfurter, *Tire model TMeasy*, Vehicle System Dynamics 45 (suppl. 1, TMPT issue), 2007 (verified as listed in TU Graz repository; page numbers not checked); Rill, *Road Vehicle Dynamics*, CRC 2011 |
| LuGre (dynamic friction) | a bristle state with its own dynamics: stick-slip, hysteresis, friction lag at low speed and standstill | σ0, σ1, σ2, Stribeck curve | an extra ODE per contact | traction/ABS control design, standstill | Canudas de Wit, Olsson, Åström, Lischinsky, IEEE Trans. Autom. Control 40(3), 1995; Canudas de Wit et al., *Dynamic friction models for road/tire longitudinal interaction*, VSD 39(3), 2003 (literature) |
| Physical: FTire, CDTire | flexible belt of lumped masses (FTire: 80 to 200 belt nodes, 5 DOF each) on the rim, a distributed tread contact on a 3D road | structural stiffness, damping, modal data, tread friction: many | FTire's design target: 5 to 20 times real time | ride, durability load histories, uneven roads and cleats, up to ~150 Hz | Gipser, *The FTire Tire Model Family* (cosin, verified: 80 to 200 nodes, 5 DOF per belt segment, valid to 150 Hz, target 5 to 20 × real time); Gallrein and Bäcker, *CDTire: a tire model for comfort and durability applications*, VSD 45 suppl. (2007) (literature) |
| SWIFT (MF-Swift) | rigid ring with contact patch dynamics on top of the MF, for short wavelengths | MF set plus ring stiffness, mass, effective road | moderate | ABS on uneven road, shimmy, frequencies to ~60 to 100 Hz | Pacejka 2012 ch. 9; Schmeitz, Besselink, Jansen, *TNO MF-SWIFT*, VSD 45 suppl. (2007) (literature) |

Values not verified from a primary source: the "100+" coefficient count of a full MF file and
the SWIFT frequency range are from Pacejka's book and vendor descriptions, quoted as order of
magnitude.

### Parameter sets used for `01-tire-models.svg`

- **Magic Formula, longitudinal, dry tarmac:** B = 10, C = 1.9, D = 1, E = 0.97. MathWorks
  Simscape Driveline *Tire-Road Interaction (Magic Formula)*, table of typical coefficients
  (verified; also wet 12/2.3/0.82/1, snow 5/2/0.3/1, ice 4/2/0.1/1). Peak at −κ = 0.18, 0.92 at
  a locked wheel (computed by the script).
- **Magic Formula, lateral:** shape factor C = 1.3 for side force, the value reported by Bakker,
  Nyborg and Pacejka (1987) (literature); D = 1 and E = 0 are this script's choice, and B is fitted
  so that BCD equals the planar tire's cornering stiffness. Peak at α = 15.3°. This is a fitted
  illustration, not a measured tire.
- **Burckhardt, dry asphalt:** c1 = 1.2801, c2 = 23.99, c3 = 0.52 (Burckhardt 1993 via Kiencke
  and Nielsen; the same values appear in many papers, e.g. Mechanics & Industry 2024 table T2,
  verified as a secondary listing). Peak μ = 1.17 at s = 0.17, 0.76 locked; the figure scales it
  to a peak of 1.
- **Brush, longitudinal:** parabolic pressure, one μ = 1, slip stiffness 19 per unit slip (= the
  Magic Formula's BCD), full sliding from σ = 0.158, −κ = 0.136. Pacejka 2012 ch. 3 formula
  $F = \mu F_z(3\theta\sigma - 3\theta^2\sigma^2 + \theta^3\sigma^3)$, $\theta = C/(3\mu F_z)$.
- **Fiala, lateral:** the same brush formula in $\tan\alpha$, cornering stiffness 12.5 per rad
  and unit load (the planar tire's), full sliding from 13.5°.

## 3. What our models use, exactly

### 1D wheel: `Vehicle.Wheel.SlipWheel1D` with `Vehicle.Wheel.TireFrictionCurve`

- Slip $\kappa = (\omega r - v)/\max(|v|, 0.5\,\text{m/s})$.
- $\mu(\kappa)$ is a point-symmetric "triple-S" piecewise cubic: from 0 it rises as
  $\mu_A(-\tfrac12 x^3 + \tfrac32 x)$, $x = |\kappa|/s_A$, to the peak $\mu_A = 1.0$ at
  $|\kappa| = s_A = 0.04$; a second cubic falls to $\mu_S = 0.7$ at $s_S = 0.12$; constant
  beyond, up to the locked wheel. $C^1$, second derivative jumps at $s_A$ and $s_S$.
- $F_x = \mu_\text{scale}\,\mu(\kappa)\,F_z$, $\mu_\text{scale}$ the road factor.
- Longitudinal only: there is no lateral force in this model.
- The curve is the same function as `MultibodyComponents.limit_S_triple(sA, sS, mu_A, mu_S, |κ|)`,
  written out in Dyad.

### Planar car: `Vehicle.Planar.PlanarBrakedWheel` → `MultibodyComponents.PlanarMechanics.SlipBasedWheelJoint`

Read from `MultibodyComponents` 0.2.6, `dyad/PlanarMechanics/slip_based_wheel_joint.dyad`, the
version in the repository's Manifest. It follows the Modelica PlanarMechanics library's slip-based
wheel (Zimmer and Otter, *Real-time models for wheels and tyres in an object-oriented modelling
framework*, Vehicle System Dynamics 48(2), 2010, literature).

- Wheel-frame slip velocities: $v_{s,\text{long}} = v_\text{long} - r\omega$ and
  $v_{s,\text{lat}} = v_\text{lat}$; total $v_s = \sqrt{v_{s,\text{long}}^2 + v_{s,\text{lat}}^2}$
  (+ 10⁻⁴ m/s).
- Thresholds scale with the wheel's circumferential speed:
  $v_A = \max(0.05, s_A |r\omega|)$, $v_S = \max(0.15, s_S |r\omega|)$. So the curve's argument is
  the slip speed over $r\omega$, Pacejka's theoretical slip $|\sigma|$, combined over both
  directions.
- Force magnitude $|F| = F_z\,\text{limit\_S\_triple}(v_A, v_S, \mu_A, \mu_S, v_s)$: the same
  triple-S cubic as the 1D curve, in $|\sigma|$.
- Force direction: **against the total slip velocity**, $F_\text{long} = |F|\,v_{s,\text{long}}/v_s$,
  $F_\text{lat} = |F|\,v_{s,\text{lat}}/v_s$. An isotropic friction-circle model: the circle's
  radius is $\mu(|\sigma|) F_z$, and longitudinal and lateral slip compete for it.
- Parameters in `PlanarCar`: $\mu_A = 1.0$, $\mu_S = 0.8$, front $s_A = 0.12$, rear 0.09,
  $s_S = 3 s_A$, each scaled by a per-wheel road factor. In terms of κ: front peak at
  $\kappa = -0.12/1.12 = -0.107$, sliding from $-0.265$; laterally, peak at
  $\alpha = \arctan 0.12 = 6.8°$, sliding from 19.8°. Cornering stiffness at zero slip:
  $1.5/s_A = 12.5$ per rad and unit load, 50 kN/rad at the rig's 4 kN.
- **Locked wheel, in this model.** $\omega = 0$: $v_{s,\text{long}} = v_\text{long}$,
  $v_{s,\text{lat}} = v_\text{lat}$, so the slip velocity is the wheel center's velocity over the
  ground and the force, $\mu_S F_z$, points straight back along the travel. In the wheel frame
  that leaves $F_y = \mu_S F_z \sin\alpha$, small but not zero; across the path it is exactly
  zero. The repository's own rig test `TestPlanarWheelRig/locked` (v = 20 m/s, v_y = 2.4 m/s,
  i.e. α = 6.8°, F_z = 4 kN) expects $F_x = -3177.2$ N, $F_y = -381.3$ N:
  $3200 \cos 6.8°$ and $3200 \sin 6.8°$, a force exactly along the velocity.
- What it leaves out: no relaxation length (forces respond instantly to slip), no aligning
  moment, no load sensitivity of μ or stiffness, no camber; longitudinal and lateral peaks at the
  same normalized slip (a circle, not an ellipse).

### Why that is enough here

The lecture's questions are about the shape of μ against slip, a peak and a lower sliding value,
and about the friction budget shared between braking and cornering. The triple-S curve has the
peak and the drop; the planar tire's slip-vector direction gives the friction circle and the
locked-wheel behavior exactly. What a Magic Formula adds (measured shape, load sensitivity,
aligning moment, camber) changes numbers, not the mechanism ABS and ESP act on. Our curves are
harsher than measured tires (sliding-to-peak 0.7 and 0.8 against 0.76 to 0.89 measured, see
`docs/abs-frequency-research.md`), and the 1D curve peaks at a smaller slip (4 %) than the usual
10 to 20 % (MF dry tarmac 18 %, Burckhardt dry asphalt 17 %, figure numbers above).

## 4. Numbers in `01-locked-wheel-forces.svg` and `01-combined-slip.svg`

The front wheel at α = 4°, per unit normal load (script output).

Case (a), the brush model in pure side slip (Pacejka 2012, ch. 3; literature): parabolic
pressure $q_z = \tfrac{3F_z}{4a}(1-x^2/a^2)$ over the patch $-a \le x \le a$, leading edge at
$x = a$; a tread element sticks to the road from the leading edge, so its sideways deflection
grows linearly toward the rear, $v(x) = (a - x)\tan\alpha$, until the bristle force reaches
$\mu q_z$; behind that point it slides, its force following the pressure down to zero at the
trailing edge. With $\theta = C_\alpha/(3\mu F_z)$, sliding starts at $x/a = 2\theta\tan\alpha - 1$
and $F_y = \mu F_z(3\theta\tan\alpha - 3\theta^2\tan^2\alpha + \theta^3\tan^3\alpha)$ up to full
sliding at $\theta\tan\alpha = 1$. At small α the force distribution is a triangle and its
resultant acts $a/3$ behind the center: the pneumatic trail $t$, which with $F_y$ gives the aligning
moment $M_z = -t F_y$; the trail shrinks as the sliding zone grows and vanishes at full sliding
(Pacejka 2012, ch. 3). With $\mu = 1$ and the planar tire's $C_\alpha/F_z = 12.5$/rad: sliding
behind $x/a = -0.42$, $F_y = 0.644\,\mu F_z$ (the script integrates the distribution and matches
the closed form), resultant at $x/a = -0.161$, so $t = 0.16\,a$ against $0.33\,a$ in the
small-angle limit. A locked wheel slides over the whole patch: no stuck elements, no deflection
triangle, the force against the sliding velocity.

Cases (b) and (c), the planar car's front tire at 20 m/s:

| case | κ | \|F\|/F_z | F_x | F_y (wheel frame) | across the path |
|---|---:|---:|---:|---:|---:|
| (a) rolling, planar tire for comparison | 0 | 0.775 | 0 | 0.775 | 0.773 |
| (b) ABS, near the peak | −0.08 | 0.998 | 0.751 | 0.657 | 0.603 |
| (c) locked | −1 | 0.800 | 0.798 | 0.056 | 0.000 |

At α = 4° the planar tire's lateral force against braking slip: 0.76 at −κ = 0.04, 0.66 at 0.08,
0.54 at 0.107 (the front peak), 0.29 at 0.2, 0.11 at 0.5, 0.06 at 1.0; across the path 0.73,
0.60, 0.49, 0.23, 0.06, 0.00.

## Sources

- H. B. Pacejka (with I. Besselink), *Tire and Vehicle Dynamics*, 3rd ed., Butterworth-Heinemann
  (Elsevier), 2012: §1.2 slip; ch. 3 brush model, tread deflection in the contact patch and
  pneumatic trail; ch. 4 Magic Formula and combined slip; ch. 9 SWIFT.
- E. Bakker, L. Nyborg, H. B. Pacejka, *Tyre modelling for use in vehicle dynamics studies*, SAE
  870421, 1987.
- E. Bakker, H. B. Pacejka, L. Lidner, *A new tire model with an application in vehicle dynamics
  studies*, SAE 890087, 1989.
- H. B. Pacejka, E. Bakker, *The Magic Formula tyre model*, Vehicle System Dynamics 21 (suppl.),
  1993.
- I. J. M. Besselink, A. J. C. Schmeitz, H. B. Pacejka, *An improved Magic Formula/Swift tyre
  model that can handle inflation pressure changes*, Vehicle System Dynamics 48 (suppl. 1), 2010.
- E. Fiala, *Seitenkräfte am rollenden Luftreifen*, VDI-Zeitschrift 96, 1954.
- H. Dugoff, P. S. Fancher, L. Segel, *An analysis of tire traction properties and their
  influence on vehicle dynamic performance*, SAE 700377, 1970.
- M. Burckhardt, *Fahrwerktechnik: Radschlupf-Regelsysteme*, Vogel, 1993; U. Kiencke, L. Nielsen,
  *Automotive Control Systems*, Springer.
- W. Hirschberg, G. Rill, H. Weinfurter, *Tire model TMeasy*, Vehicle System Dynamics 45
  (suppl. 1), 2007; G. Rill, *Road Vehicle Dynamics: Fundamentals and Modeling*, CRC, 2011.
- C. Canudas de Wit, H. Olsson, K. J. Åström, P. Lischinsky, *A new model for control of systems
  with friction*, IEEE Trans. Automatic Control 40(3), 1995; C. Canudas de Wit, P. Tsiotras,
  E. Velenis, M. Basset, G. Gissinger, *Dynamic friction models for road/tire longitudinal
  interaction*, Vehicle System Dynamics 39(3), 2003.
- M. Gipser, *The FTire Tire Model Family*, cosin scientific software,
  https://www.cosin.eu/wp-content/uploads/ftire_eng_3.pdf (verified).
- J. Gallrein, M. Bäcker, *CDTire: a tire model for comfort and durability applications*,
  Vehicle System Dynamics 45 (suppl. 1), 2007.
- A. J. C. Schmeitz, I. J. M. Besselink, S. T. H. Jansen, *TNO MF-SWIFT*, Vehicle System
  Dynamics 45 (suppl. 1), 2007.
- D. Zimmer, M. Otter, *Real-time models for wheels and tyres in an object-oriented modelling
  framework*, Vehicle System Dynamics 48(2), 2010.
- R. Rajamani, *Vehicle Dynamics and Control*, 2nd ed., Springer, 2012, ch. 2 and 13.
- W. F. Milliken, D. L. Milliken, *Race Car Vehicle Dynamics*, SAE, 1995, ch. 2.
- MathWorks, Simscape Driveline, *Tire-Road Interaction (Magic Formula)*,
  https://www.mathworks.com/help/sdl/ref/tireroadinteractionmagicformula.html (verified).
- Altair, MotionView, *Utilities to Calculate Tire Kinematics, Forces, and Moments* (axis
  systems; verified for the SAE/ISO axis statement only).
- SAE J670 (2008), *Vehicle Dynamics Terminology*; ISO 8855:2011, *Road vehicles — Vehicle
  dynamics and road-holding ability — Vocabulary* (not opened).
