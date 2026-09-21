**Beat:** the failure that is not a tuning problem. ~8 minutes. Two plots on this slide — the
torque plot is the one that explains it.

Set up first, then talk: **gradient to 10%**, anti-windup **off**, target 110. Let it run.

The car cannot hold 110 up a 10% grade. The command pins at the 150 N·m ceiling and stays
there — show it on the torque plot, the commanded trace flat against the dashed ceiling while
the delivered trace sits underneath it.

Now the part they cannot see: the integrator does not know about the ceiling. The error stays
positive, so it keeps accumulating, and the commanded torque the controller *believes* it is
asking for climbs far past anything the engine can deliver.

Take the **gradient back to 0** and watch what happens. The car should accelerate straight to
110 and hold. Instead it sails past — sometimes far past — because the controller has to
unwind an integrator holding minutes of impossible history before it will take its foot off.

Then flip **anti-windup on** and do the whole thing again. The overshoot goes.

The mechanism is four lines in the notebook and worth reading out: when the command is
clamped, the integration step for that instant is *undone*. `if antiwindup && u != u_sat` —
the integrator only accumulates while the controller still has authority.

**This is the slide that matters.** Windup is not a badly tuned loop; a perfectly tuned loop
does it. It is what happens when the model the controller has of itself stops matching the
actuator it is driving, and no amount of moving Kp and Ki fixes it.

**If the demo does not overshoot** — the gradient needs to be held long enough for the
integrator to fill. Give it the full run before dropping the grade back.
