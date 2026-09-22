**Beat:** the third term, and why it is mostly off. ~5 minutes.

**Kd from 0 to 6.** The overshoot flattens. The derivative term reads the *rate* the error is
closing at and takes torque off before the car arrives — braking into the corner.

Then be honest about it:

- there is no measurement noise in this simulation at all
- a real speed signal is differentiated noise, amplified by Kd
- which is why production cruise control is usually PI, and D, when it exists, sits on the
  measurement rather than on the error and is filtered hard

Point back at notebook 07 if they have done it — the chattering-command figure there is this
exact failure with a noisy sensor.

**Kd = 20** if there is time. Nothing dramatic happens here, because the signal is clean; say
that plainly rather than pretending the demo shows a danger it cannot show. *The reason to
leave D alone is not in this room, it is in the sensor.*
