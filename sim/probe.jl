# Walk a connected DualSense through every input and feedback channel, a few seconds each.
#   julia sim/probe.jl [step...]     steps: input lightbar rumble triggers
include(joinpath(@__DIR__, "DualSense.jl"))
using .DualSense

function hold(pad, seconds; show_input = false)
    t_end = time() + seconds
    next_print = time()
    while time() < t_end
        s = poll!(pad)
        send!(pad)
        if show_input && time() >= next_print
            pressed = [k for k in keys(DualSense.BUTTONS) if s[k]]
            println("L ($(round(s.lx, digits = 2)), $(round(s.ly, digits = 2)))  ",
                    "R ($(round(s.rx, digits = 2)), $(round(s.ry, digits = 2)))  ",
                    "L2 $(round(s.l2, digits = 2))  R2 $(round(s.r2, digits = 2))  ",
                    "dpad $(s.dpad)  $(pressed)")
            next_print += 0.5
        end
        sleep(0.01)
    end
end

function step(name, f)
    println("\n== ", name)
    flush(stdout)
    f()
end

steps = isempty(ARGS) ? ["input", "lightbar", "rumble", "triggers"] : ARGS
pad = open_pad()
println("opened ", pad.path, pad.bluetooth ? " (Bluetooth)" : " (USB)")
try
    "input" in steps && step("input: move both sticks, squeeze L2/R2, press buttons (6 s)",
                             () -> hold(pad, 6; show_input = true))
    "lightbar" in steps && step("lightbar: red, green, blue", () -> begin
        for (name, rgb) in (("red", (1, 0, 0)), ("green", (0, 1, 0)), ("blue", (0, 0, 1)))
            println("  ", name)
            lightbar!(pad, rgb...)
            player_leds!(pad, name == "red" ? 0b00100 : name == "green" ? 0b01010 : 0b11111)
            hold(pad, 1.5)
        end
    end)
    "rumble" in steps && step("rumble: heavy motor, then light motor", () -> begin
        println("  heavy (left grip)")
        rumble!(pad; low = 0.8)
        hold(pad, 1.2)
        println("  light (right grip)")
        rumble!(pad; high = 0.8)
        hold(pad, 1.2)
        rumble!(pad)
        hold(pad, 0.2)
    end)
    "triggers" in steps && step("triggers: keep squeezing L2 and R2 through each", () -> begin
        for (label, l, r) in (
            ("R2 stiff all the way (Rigid), L2 free", TriggerOff(), Rigid(0.0, 1.0)),
            ("R2 detent mid-travel (Section), L2 stiff from zone 3 (Feedback)",
             Feedback(3, 0.75), Section(0.3, 0.6, 1.0)),
            ("L2 buzzes at 30 Hz (Vibration), R2 free", Vibration(0, 1.0, 30), TriggerOff()),
            ("L2 buzzes at 10 Hz from mid-travel", Vibration(4, 1.0, 10), TriggerOff()),
        )
            println("  ", label)
            trigger!(pad, :left, l)
            trigger!(pad, :right, r)
            hold(pad, 4)
        end
    end)
finally
    close(pad)
    println("\nclosed; feedback reset")
end
