**Beat:** the first controller, and its one flaw. ~8 minutes. This is the longest stop on the
deck; everything after it is a correction to what they see here.

Start with **Kp at 2** and the target at **110 km/h**, which is where the sliders load. The car
starts at 90, so there is a 20 km/h error on the table from t = 0.

Drive it in this order:

1. **Kp = 0.** Nothing happens — the command is zero, the car coasts down. Torque is
   proportional to error and the proportion is nothing.
2. **Kp = 2.** It climbs and settles. Now point at `steady-state error` in the metrics card
   and read the number aloud. It is not zero.
3. **Kp = 8.** Faster, and the error shrinks. Read the number again.
4. **Kp = 18.** Overshoot appears, then ringing.

The question to ask the room, before you answer it: *why can the steady-state error never be
zero?* Give it a moment. The answer is that holding 110 km/h needs real torque against drag and
rolling resistance — and a proportional controller can only produce torque by being wrong. Zero
error commands zero torque, which is not enough to hold the speed. **The error is the price of
the torque.**

That sentence is the slide. Everything on the next one exists to avoid paying it.

**Watch for:** at Kp above about 15 the ringing gets interesting and the temptation is to keep
going. Resist it — instability is the Windup slide's job, and the dead time is what makes it
happen, not the gain alone.

**If a student says "just add a constant offset"** — that is feedforward, it is a real answer,
and it is exactly what the integrator will work out for itself in about ninety seconds.
