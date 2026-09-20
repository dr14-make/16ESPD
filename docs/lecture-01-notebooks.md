# Notebook specifications — Lecture 1

Cell-by-cell detail for all ten notebooks. Written so that someone who has not seen the
planning conversation can build any one of them without asking questions.

Shared conventions: every notebook opens with a one-cell setup that activates the project and
loads the shared helper from `notebooks/lecture01/support.jl`; speed axes are km/h because the
model emits km/h through `Vehicle.ToKmPerHour`, not because the notebook converts anything;
the control loop runs in km/h throughout, so every gain `k` is in N.m per km/h; every notebook ends with a short
"what this bought us" markdown cell that names the next notebook. Model construction and
solving happen in `src/`, so a code cell in a notebook is a call and a plot, not twenty lines
of assembly.

Numbers quoted below are analytic and indicative — confirm each against the simulation and
correct this file where they differ.

---

## 01 — The car

**Thesis.** Before you can control something you have to know what it does on its own.

**Source.** Slides 6 (response types), 7 (step test), 16-17 (vehicle energy);
`6.PIDBuildingamodel.md` for the white-box framing only.

**Model.** `Lecture1.CarPlant`, open loop. No controller anywhere in this notebook.

**Cells.**

1. *Markdown — what a system is.* Inputs, outputs, state, disturbances. The car: torque command
   in, speed out, road gradient as the disturbance.
2. *Markdown — the force balance.* Typeset

       m dv/dt = T*i/r  -  1/2 rho CdA v^2  -  f_r m g cos(alpha)  -  m g sin(alpha)

   and name each term against slide 16's O_V, O_f, O_z, O_s.
3. *Code — terminal speed, analytically.* Solve the balance at dv/dt = 0 for full torque.
   Expect ~68.4 m/s = 246 km/h.
4. *Markdown — an aside worth making.* That number is too high for a 150 N.m car, because an
   ideal engine delivers peak torque at every speed and a real one does not. Say so explicitly;
   it is the hook into lecture 2's torque map, and a student who notices it unaided will
   distrust everything that follows.
5. *Code — open-loop run to terminal speed.* Full torque from rest. Plot speed against time.
   Note the time scale: the vehicle's own time constant is around 60 s, so this is slow.
6. *Code — the step test.* Torque step partway through the run. Plot commanded torque and
   delivered torque on one axes, and speed below.
7. *Markdown — the three responses.* Mark the transient region and the steady-state region on
   the speed plot. Dynamic response is their sum — slide 6, in the students' own notation.
8. *Code — read K, tau and theta off the curve.* The dead band at the start is `theta_e`, the
   rise is dominated by the vehicle's `tau`, and the gain is the steady-state change in speed
   divided by the change in torque. State all three; notebook 08 uses exactly these.

**Plots.** Speed to terminal; commanded vs delivered torque showing lag and dead time; the
annotated step response with K, tau and theta marked.

**Check.** If the car does not reach a steady speed, the drag force sign is wrong.

---

## 02 — Open loop versus closed loop  *(Tier 2)*

**Thesis.** Feedforward is correct exactly as long as the world matches your model.

**Source.** `1.EverythingYouNeedtoKnowAboutControlTheory.md`; slides 2-5.

**Model.** `Lecture1.CarPlant` driven by a constant torque, then by `Lecture1.CruiseLoop` with
integral and derivative off.

**Cells.**

1. *Markdown — the two architectures.* Reference against reality, or reference alone. Redraw
   slide 3's diagram in the notebook's own terms.
2. *Code — invert the model.* Compute by hand the torque that holds 90 km/h on flat dry road:
   about 31 N.m. Run it open loop. It works.
3. *Code — break it three ways.* Same constant torque, but (a) a 4% grade, (b) 200 kg of
   payload, (c) a headwind modelled as a drag-area increase. Plot all four runs on one axes
   against the 90 km/h target.
4. *Markdown — what went wrong.* Nothing in the controller. The controller was right; the
   world moved. There is no error signal anywhere in this architecture, so nothing can notice.
5. *Code — close the loop.* The same three disturbances under proportional control. All three
   come back towards target.
6. *Markdown — the cost.* Feedback changes the system's dynamics rather than merely its
   operation, which is why the rest of the lecture exists — and why a badly tuned loop can do
   more harm than no loop at all.

**Plots.** Four open-loop runs against target; the same three disturbances closed-loop.

---

## 03 — Proportional  *(Tier 1)*

**Thesis.** Proportional control gets you close, and close is where it stops.

**Source.** `2.PIDUnderstanding.md`, first third; slide 9.

**Model.** `Lecture1.CruiseLoop(with_I = false, with_D = false)`.

**Scenario.** Step 90 -> 110 km/h on flat road. Required torque goes 31 -> 40 N.m, well inside
the limit, so nothing saturates here. Saturation arrives in notebook 06 and not before.

**Cells.**

1. *Markdown — the control law.* `u = k * e`. Nothing else.
2. *Code — one run.* Step response at a middling gain, with the steady-state error annotated
   on the plot.
3. *Code — the gain family.* Four gains spanning about two decades on one axes. Indicative
   values, to be confirmed: k = 14, 56, 220, 890 N.m per km/h give steady-state errors of
   roughly 2.8, 0.7, 0.18 and 0.05 km/h.
4. *Code — error against gain.* Plot steady-state error against k on a log axis. It decays
   hyperbolically and never reaches zero.
5. *Markdown — why.* At equilibrium the car needs a non-zero torque just to hold speed against
   drag. A proportional controller can only produce non-zero torque from non-zero error.
   Therefore the error cannot be zero. This is the drone hovering below its setpoint, with drag
   playing the part gravity played.
6. *Markdown — the fix, named but not yet built.* Something that remembers.

**Plots.** Step response at one gain with error annotated; four-gain family; error against gain.

**Check.** If the error vanishes at high gain, the integral path was left switched on.

---

## 04 — Proportional-integral  *(Tier 1)*

**Thesis.** The integrator works out the answer you computed by hand in notebook 02.

**Source.** `2.PIDUnderstanding.md`, middle third.

**Model.** `Lecture1.CruiseLoop(with_I = true, with_D = false)`.

**Cells.**

1. *Markdown — adding memory.* The integral accumulates error, so it keeps changing for as
   long as any error remains, and stops changing only when the error is zero.
2. *Code — PI against P.* Same step, both controllers on one axes. P settles short; PI reaches
   the setpoint.
3. *Code — the punchline.* Plot the integrator's internal state over time. It settles at the
   torque required to hold 110 km/h — about 40 N.m — which is the number computed by hand in
   notebook 02. Annotate the analytic value as a horizontal line so the two visibly coincide.
4. *Markdown — what that means.* The integrator performed the model inversion from notebook 02,
   without being given a model. That is what "removes steady-state error" actually means, and
   it is the single most useful sentence in this notebook.
5. *Code — the cost.* Sweep `Ti` downwards. Overshoot appears and grows. Plot the family.
6. *Markdown — where overshoot comes from.* By the time the error reaches zero the integrator
   is already holding more torque than is needed, and the only way to unwind it is to spend
   time on the far side of the setpoint.

**Plots.** P vs PI; integrator state with the analytic torque marked; `Ti` family.

**Check.** If the integrator settles at anything other than the hand-computed cruise torque,
either the gear ratio or the unit convention is inconsistent between notebook and model.

---

## 05 — Proportional-integral-derivative  *(Tier 1)*

**Thesis.** Three terms, three jobs: present, past, future.

**Source.** `2.PIDUnderstanding.md`, final third; slides 8-9.

**Model.** `Lecture1.CruiseLoop(with_I = true, with_D = true)`.

**Cells.**

1. *Markdown — the third path.* The derivative responds to how fast the error is changing, so
   it brakes on approach rather than on arrival.
2. *Code — P vs PI vs PID.* One axes, same step, same `k`. This plot is the spine of the whole
   lecture; make it the best-looking one in the set.
3. *Code — the three contributions.* Plot each path's output separately over time, plus their
   sum. Proportional carries the transient, integral holds the steady state, derivative exists
   only while the error is moving and is exactly zero at both ends.
4. *Code — `Td` family.* Too little and overshoot survives; too much and the response becomes
   sluggish and jittery.
5. *Markdown — naming the variants.* Zeroing a gain removes a path, which is why PI, PD and P
   controllers all have names — and why a Dyad model with two boolean parameters covers all of
   them, which is literally what notebooks 03, 04 and 05 have been doing.

**Plots.** P/PI/PID overlay; the three contributions; `Td` family.

**This is the notebook to port to Pluto first** if the stretch goal is reached: three sliders,
one response curve.

---

## 06 — Integral windup  *(Tier 1)*

**Thesis.** The integrator does not know the engine has run out.

**Source.** `3.PIDIntegral.md`.

**Model.** `Lecture1.CruiseLoop` plus `GradeProfile`; and the clamping variant from task 4.

**Scenario.** Cruise at 130 km/h. From t = 30 s, a sustained 10% climb. The climb needs 2024 N
and the engine can deliver 1935 N, so it saturates and the car falls back to about 118 km/h.
The climb ends later in the run, and that is where the damage shows.

**Cells.**

1. *Markdown — actuators are not linear.* Real actuators saturate. A linear model will happily
   command torque the engine cannot produce, and nothing in the model complains.
2. *Code — the climb, no anti-windup.* Plot speed, commanded torque, delivered torque, and the
   integrator state. Through the climb the integrator keeps growing even though delivered
   torque is pinned at the limit.
3. *Markdown — why the overshoot is coming.* When the road flattens the car accelerates, but
   the integrator must unwind from far above the limit before delivered torque falls at all.
   During all of that the car is still being commanded to accelerate.
4. *Code — the overshoot.* Run past the end of the climb. Annotate the peak.
5. *Markdown — clamping.* Two conditions: the output is saturating, and the error has the same
   sign as the output. When both hold, stop integrating. This is the method from the source
   video.
6. *Code — three-way comparison.* No anti-windup, clamping, and `LimPID`'s back-calculation.
   Speed and integrator state for each. Report peak overshoot for all three.
7. *Markdown — set the limit below the physical one.* An engine loses torque when hot, with
   age, at altitude. Clamping at exactly the nameplate limit will still wind up.

**Plots.** Climb with integrator state; the overshoot after the climb; three-way comparison.

---

## 07 — Derivative and noise  *(Tier 3)*

**Thesis.** The derivative does not care how big the noise is, only how fast.

**Source.** `4.PIDDerivative.md`.

**Model.** `Lecture1.CruiseLoop` with `Lecture1.MeasurementNoise` on the velocity measurement.

**Cells.**

1. *Markdown — every sensor is noisy.* A speedometer included.
2. *Code — the measurement.* True speed and measured speed on one axes. The noise is small
   enough to look harmless.
3. *Markdown — why small noise is not safe.* Differentiating a sine of amplitude A and
   frequency omega gives amplitude `A*omega`. Amplitude unchanged, frequency up tenfold, slope
   up tenfold. Show the two sines and their slopes side by side.
4. *Code — near-pure derivative.* Large `Nd`. The commanded torque chatters violently while the
   speed trace still looks almost clean. Report the torque command range.
5. *Code — `Nd` family.* Sweep the filter coefficient. The chatter subsides.
6. *Markdown — choosing the cutoff.* Low enough to remove the noise, high enough to leave the
   signal. The trade-off, not a recipe.
7. *Markdown — the equivalence, optional.* A filtered derivative `s*N/(s+N)` is identical to a
   feedback loop with `N` forward and an integrator in the feedback path. Cheaper to compute,
   harder to read. Worth a slide only if time allows.

**Plots.** True vs measured speed; two sines with their slopes; commanded torque at large `Nd`;
`Nd` family.

**Note.** The noise source must be deterministic — see the decision log in `HANDOVER.md`.

---

## 08 — Tuning  *(Tier 1)*

**Thesis.** You can compute a starting gain set from a single step test, without a model.

**Source.** `5.PIDTunning.md`; `tuning_methods.pdf`; `7.PIDTUnningMethods.md` for the
saturation trap only; slides 12-15. Slide 15's practical task is this notebook.

**Model.** `Lecture1.CarPlant` open loop for the step test; `Lecture1.CruiseLoop` for the rest.

**Cells.**

1. *Markdown — the flowchart.* Is the system well behaved? Do you have a model or hardware?
   Place this car on it: stable, near enough linear, minimum phase, manageable delay.
2. *Code — the open-loop step test.* Following slide 7's procedure exactly: settle, step,
   record, scale by the step size. Read `K`, `tau` and `theta`.
3. *Code — Cohen-Coon.* Apply the table from `tuning_methods.pdf` to those three numbers.
   Simulate the result.
4. *Code — Ziegler-Nichols.* Raise `k` under pure proportional control until oscillation is
   sustained. Report `Ku` and `Pu`, apply the ZN table, simulate.
5. *Code — Tyreus-Luyben.* Same `Ku` and `Pu`, different table, more conservative. Simulate.
6. *Code — all three overlaid.* Plus a comment on which the students would actually ship.
7. *Markdown — the danger in ZN on real hardware.* It requires deliberately driving the plant
   to the edge of instability. Safe in simulation; often unacceptable on a real vehicle.
8. *Code — the saturation trap.* Push the gains until the step response looks superb, then plot
   the commanded torque and find it far outside what the engine can deliver. Re-run with the
   limiter active and watch the beautiful response disappear.
9. *Markdown — the lesson.* A linear model will let you design a controller your hardware
   cannot execute, and it will not warn you. Always plot the actuator command.

**Plots.** The annotated step test; three tuned responses overlaid; commanded torque for the
over-aggressive design, with the torque limit drawn on.

**This notebook depends entirely on acceptance criterion 4** — see Risk 1 in `HANDOVER.md`.
Without a measurable `Ku`, cells 4 and 5 cannot be written.

---

## 09 — Discretization  *(Tier 2)*

**Thesis.** The same controller gets worse purely because it looks less often.

**Source.** `8.DiscreetControll.md`, second half.

**Model.** `Lecture1.CruiseLoop` with the sampler from task 5, using the gains from 08.

**Cells.**

1. *Markdown — controllers run on computers.* A digital controller reads, computes, commands,
   and then does nothing at all until the next tick.
2. *Markdown — the strobe light.* Walking a winding corridor under continuous light, then under
   a strobe that slows down. The corridor did not change.
3. *Code — the sample-time sweep.* The same gains at several sample times on one axes.
   Overshoot grows, then the loop rings, then it diverges.
4. *Code — the actuator command.* If the real clocked partition was built, this is the
   staircase, and it is the headline plot. If only the surrogate exists, say plainly here that
   the notebook is demonstrating the mechanism rather than a real sampler.
5. *Markdown — why it destabilizes.* A zero-order hold costs the loop about half a sample of
   phase. Phase margin is finite; spend it and the loop rings, spend more and it does not
   recover.
6. *Code — the fixes.* Sample faster, or re-tune for the rate you actually have. Show both.
7. *Markdown — why we design in continuous time first.* Easier, better tooled, and the plant is
   continuous anyway. Convert afterwards and verify the rate held up.

**Plots.** Sample-time family; actuator command (staircase if available); re-tuned slow-rate
response against the original.

---

## 10 — Wheel and slip  *(Tier 3)*

**Thesis.** The tire is an actuator too, and it saturates — which makes cruise control
dangerous on ice.

**Source.** The lecturer's own addition; `5.PIDTunning.md` for the "is it well behaved" gate.

**Model.** `Lecture1.WheeledCarPlant` (L1), then `Lecture1.SlipCarPlant` and
`Lecture1.SlipCruiseLoop` (L2), with `Lecture1.FrictionProfile`.

**Cells.**

1. *Code — L1, the wheel appears.* Add wheel inertia and ideal rolling. Re-run the notebook 05
   step with the same gains. They should still work; if the response shifts, say by how much.
2. *Markdown — what ideal rolling assumes.* That the contact patch never slides. Everything so
   far has quietly assumed it.
3. *Code — L2, beat one: wheelspin.* Standing start at full torque on low friction. Plot wheel
   speed and vehicle speed together: the wheel runs away, the car barely moves. Under closed
   loop the error stays large and the integrator winds up against a limit that is not in the
   engine at all.
4. *Code — beat two: the curve.* Plot `mu` against slip ratio with the peak marked. Overlay
   where the operating point sat during the wheelspin run — past the peak.
5. *Markdown — why it runs away.* Past the peak, more slip gives less force, which gives more
   slip. That is a positive feedback loop inside the plant. The plant is open-loop unstable
   there, which is precisely the gate the tuning video opens with: *is your system well
   behaved?* Here, in that region, it is not — and no amount of PID tuning fixes a plant that
   is running away from you.
6. *Code — beat three: cruise control on an ice patch.* Cruising at 90 km/h, friction collapses
   for two seconds. The controller sees speed falling and commands more torque. The driven
   wheel spins up. The traction it was trying to use is destroyed by the attempt to use it.
   Plot speed, wheel speed, slip ratio and commanded torque on shared time axes, with the ice
   patch shaded.
7. *Code — what should have happened.* The same run with a friction-aware torque limit.
8. *Markdown — the two lessons.* Real cruise control disengages when traction control
   intervenes, and this is why. And the fix — an inner loop that regulates slip inside an outer
   loop that regulates speed — is cascade control, which is where lecture 2 begins.

**Plots.** L1 versus L0 step; wheelspin; the `mu`-slip curve with the operating point; the ice
patch with four traces; the same with a traction limit.

**Solver note.** The friction curve has a discontinuous second derivative at its transitions.
Explicit Runge-Kutta methods handle it better than BDF.
