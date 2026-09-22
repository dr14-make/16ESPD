**Beat:** the fix, and its cost. ~6 minutes.

Leave Kp where the last slide ended. Take **Ki from 0 to 0.1** and let it run.

The error goes to zero. Say why in the terms the last slide set up: the integrator accumulates
the error over time, so *any* persistent error keeps growing the command until it stops being
persistent. It is the machine working out the offset a student proposed by hand.

Then show what it cost. Put **Ki at 1.5** and watch the overshoot:

- the integrator is still full of history when the error crosses zero
- so it keeps commanding torque *past* the setpoint
- the car has to overshoot to unwind it

Two numbers in the metrics card carry this: `overshoot` climbs and `settling time` gets worse
even though the steady-state error stays at zero. Good tracking and fast tracking are separate
things and you have just traded one for the other.

**Leave Ki near 0.3 before paging on.** The Windup slide is much clearer from a system that is
already behaving.
