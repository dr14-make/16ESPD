module VehicleSystemsComponentsPadExt
using VehicleSystemsComponents
using GLMakie
using SimpleDirectMediaLayer
include("DualSense.jl")
using .DualSense

"Dispatch marker for an optional controller session."
struct PadMode end
"Controller and input-edge history for one drive."
mutable struct PadSession
    pad::Pad
    previous_buttons::UInt32
    previous_dpad::UInt8
end
window_extension() = Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsGLMakieExt)
function VehicleSystemsComponents.drive_window(integ, sys, spec, ::PadMode)
    pad = try
        p = open_pad()
        quiet!(p)
        println("DualSense on ", p.path)
        p
    catch e
        e isa InterruptException && rethrow()
        println("no DualSense (", sprint(showerror, e), "); keyboard only")
        nothing
    end
    session = pad === nothing ? nothing : PadSession(pad, UInt32(0), 0x08)
    try
        return window_extension().window!(integ, sys, spec, session)
    finally
        pad === nothing || close(pad)
    end
end

function poll_controls!(session::PadSession, c, kb)
    win = window_extension()
    ps = poll!(session.pad)
    edge = ps.buttons & ~session.previous_buttons
    session.previous_buttons = ps.buttons
    hit(b) = (edge & DualSense.BUTTONS[b]) != 0
    hit(:triangle) && (c.esp = !c.esp)
    hit(:square) && (c.abs = !c.abs)
    hit(:circle) && (c.surface = mod1(c.surface + 1, length(win.SURFACES)))
    hit(:cross) && (c.mode = mod1(c.mode + 1, length(win.DRIVE_MODES)))
    hit(:ps) && (c.paused = !c.paused)
    if ps.dpad != session.previous_dpad
        ps.dpad == 0x06 && win.adjust_lock!(c, -1)
        ps.dpad == 0x02 && win.adjust_lock!(c, 1)
        session.previous_dpad = ps.dpad
    end
    stick = abs(ps.lx) < 0.06 ? 0.0 : ps.lx
    return (max(kb.throttle, ps.r2), max(kb.brake, ps.l2),
            kb.steer == 0 ? -stick : kb.steer, hit(:options))
end

const SURFACE_LEDS = (0b00100, 0b01010, 0b10101, 0b11011)
function feedback!(session::PadSession, s, c, clock)
    pad = session.pad
    win = window_extension()
    if c.paused
        rumble!(pad)
        trigger!(pad, :left, TriggerOff())
        trigger!(pad, :right, TriggerOff())
    else
        spin = max(abs(s.kfl), abs(s.kfr)) / win.PEAK_KAPPA
        slide = maximum(win.grips(s))
        road = abs(s.vx) > 0.5 ? 0.03 + 0.05 * min(abs(s.vx) / 30, 1.0) : 0.0
        abs_on = win.abs_cycling(s, c)
        rumble!(pad; low = clamp(0.8 * (slide - 0.85), 0.0, 0.7) + (abs_on ? 0.25 : 0.0),
                high = road + (abs_on ? 0.35 : 0.0))
        trigger!(pad, :left, abs_on ? Vibration(2, 1.0, 25) : Feedback(2, 0.35))
        trigger!(pad, :right,
                 spin > 1.0 && c.throttle > 0.1 ? Vibration(3, 0.7, 40) : Feedback(1, 0.12))
    end
    if win.esp_braking(s, c)
        isodd(floor(Int, 8clock)) ? lightbar!(pad, 1.0, 0.45, 0.0) : lightbar!(pad, 0.0, 0.0, 0.0)
    elseif !c.esp
        lightbar!(pad, 0.5, 0.0, 0.0)
    else
        lightbar!(pad, 0.0, 0.3, 0.05)
    end
    player_leds!(pad, SURFACE_LEDS[c.surface])
    return pad
end
haptics!(session::PadSession, s, c, clock) = send!(feedback!(session, s, c, clock))
# Qualify the transport method: these are different types, not new transport API methods.
quiet_session!(session::PadSession) = DualSense.quiet!(session.pad)
end
