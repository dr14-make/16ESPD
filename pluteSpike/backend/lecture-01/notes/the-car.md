**Beat:** the plant, before anyone mentions control. ~4 minutes.

Open on the table, not the plot. These eight numbers are the whole car for the next two
hours — 1400 kg, a drag area of 0.63 m², a torque ceiling of 150 N·m at the crank through a
gear ratio of 4. Say out loud that there is *no controller anywhere on this slide*.

Then the plot. Constant throttle holding 90 km/h, and at t = 10 s the command steps up by
20 N·m. Walk the curve:

- it does not move for about a tenth of a second — that is `theta_e`, the dead time
- it then rises on a lag — `tau_e = 0.3 s`, the engine filling in
- it settles at a *new constant speed*, not a rising one, because drag grows with v²

The third point is the one to land. A car under constant throttle is already a closed system
that finds its own equilibrium; what we add today is not stability, it is *choosing* which
speed that equilibrium sits at.

**If they ask** why the step is 20 N·m: no reason, it is a readable size. The shape is what
matters and the shape is the same for any step that does not hit the ceiling.

**If the plot is blank** the kernel is still warming. Keep talking through the table — it
takes about thirty seconds from a cold start and the cards fill in without a reload.
