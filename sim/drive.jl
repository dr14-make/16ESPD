# Drive the battery-electric planar car in real time, from a DualSense or the keyboard.
#   julia +dyad-3.5.0 --project=. sim/drive.jl
# Warm session: in a REPL started the same way, `include("sim/drive.jl"); main()`. Closing the
# window returns to the REPL; `main()` again opens it in seconds, the model and solver already
# compiled.
#
# The library environment comes first; sim/ is stacked behind it so GLMakie never becomes a
# library dependency.
push!(LOAD_PATH, @__DIR__)

include(joinpath(@__DIR__, "plant.jl"))
include(joinpath(@__DIR__, "DualSense.jl"))
using .DualSense
using GLMakie
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using SymbolicIndexingInterface: setp, getp, getu

const SURFACES = [
    ("dry", (1.0, 1.0, 1.0, 1.0)),
    ("wet", (0.7, 0.7, 0.7, 0.7)),
    ("snow", (0.3, 0.3, 0.3, 0.3)),
    ("split-μ: ice on the right", (1.0, 0.2, 1.0, 0.2)),
]
const SURFACE_LEDS = (0b00100, 0b01010, 0b10101, 0b11011)

const PEAK_KAPPA, PEAK_ALPHA = 0.12, 0.12
const FRAME = 1 / 60

println("compiling the car…")
@named model = drive_model()
const SYS = simplify_model(model)
const PROB = ODEProblem(SYS, [], (0.0, 1e7))
new_integrator() = init(PROB, Rodas5P(); dtmax = 0.005, save_everystep = false)

const A, B, TW, I_S, M_CAR, R_WHEEL, T_FULL, RATIO = Float64.(getp(SYS, [
    SYS.car.a, SYS.car.b, SYS.car.tw, SYS.car.i_s,
    SYS.car.m, SYS.car.radius, SYS.car.tau_max, SYS.blend.ratio])(PROB))

const set_throttle! = setp(SYS, SYS.throttle_pedal.k)
const set_brake! = setp(SYS, SYS.brake_pedal.k)
const set_steer! = setp(SYS, SYS.steering_wheel.k)
const set_esp! = setp(SYS, SYS.ecu.esp_on)
const set_abs! = setp(SYS, SYS.ecu.abs_on)
const set_mu! = setp(SYS, [SYS.car.mu_scale_fl, SYS.car.mu_scale_fr, SYS.car.mu_scale_rl, SYS.car.mu_scale_rr])

const SIGNALS = (
    :x => SYS.motion.x, :y => SYS.motion.y, :psi => SYS.motion.psi,
    :vx => SYS.motion.vx, :r => SYS.motion.r, :ay => SYS.motion.ay, :sw => SYS.hands.y,
    :kfl => SYS.slips.kappa_fl, :kfr => SYS.slips.kappa_fr,
    :krl => SYS.slips.kappa_rl, :krr => SYS.slips.kappa_rr,
    :afl => SYS.car.bus.alpha_fl, :afr => SYS.car.bus.alpha_fr,
    :arl => SYS.car.bus.alpha_rl, :arr => SYS.car.bus.alpha_rr,
    :tfl => SYS.car.tau_fl, :tfr => SYS.car.tau_fr, :trl => SYS.car.tau_rl, :trr => SYS.car.tau_rr,
    :demand => SYS.blend.tau_brake,
    :esp => SYS.ecu.esp.dT_fl + SYS.ecu.esp.dT_fr + SYS.ecu.esp.dT_rl + SYS.ecu.esp.dT_rr,
    :motor => SYS.drive.machine.tau,
    :power => SYS.drive.battery.v * SYS.drive.battery.i,
    :soc => SYS.drive.SoC,
)
const read_signals = getu(SYS, collect(last.(SIGNALS)))
snapshot(integ) = NamedTuple{Tuple(first.(SIGNALS))}(Tuple(read_signals(integ)))

mutable struct Controls
    throttle::Float64
    brake::Float64
    steer::Float64      # -1 full right .. 1 full left
    esp::Bool
    abs::Bool
    surface::Int
    paused::Bool
    lock::Float64       # steering-wheel angle at full stick and standstill [rad]
    mode::Int           # index into DRIVE_MODES
end

Controls() = Controls(0, 0, 0, true, true, 1, false, FULL_LOCK, 2)

# Lift-off deceleration with the throttle released [g]. RegenBlend regenerates only on a brake
# request, so lift-off regen is a light brake-pedal value the machine takes first. D is derived from
# Argonne's 2013 Leaf coast-down; e-Pedal's 0.2 g is Nissan's figure (research note in #155).
const DRIVE_MODES = (("N (coast)", 0.0), ("D", 0.025), ("e-Pedal", 0.2))
# A full brake pedal asks T_FULL (`car.tau_max`) of every wheel.
liftoff_brake(g_decel) = M_CAR * 9.81 * g_decel * R_WHEEL / (4 * T_FULL)

# 1.5 turns lock to lock each way, about 34° at the road wheel through the 16:1 column.
const FULL_LOCK = 9.6
const LOCK_RANGE = (0.3FULL_LOCK, 1.0FULL_LOCK)

const DPAD_RIGHT, DPAD_LEFT = 0x02, 0x06

adjust_lock!(c::Controls, dir) = (c.lock = clamp(c.lock * 1.15^dir, LOCK_RANGE...))

# Less lock as speed builds, so the stick stays drivable on a motorway.
max_steer(c::Controls, speed) = c.lock / (1 + max(speed, 0.0) / 45)

# ESP, ABS and surface as last set on the integrator; `surface == 0` means none set yet.
mutable struct Applied
    esp::Bool
    abs::Bool
    surface::Int
end

Applied() = Applied(false, false, 0)

function apply!(integ, c::Controls, speed, applied::Applied)
    max_sw = max_steer(c, speed)
    set_throttle!(integ, c.throttle)
    liftoff = c.throttle < 0.02 ? liftoff_brake(DRIVE_MODES[c.mode][2]) : 0.0
    set_brake!(integ, max(c.brake, liftoff))
    set_steer!(integ, c.steer * max_sw)
    fresh = applied.surface == 0
    if fresh || applied.esp != c.esp
        set_esp!(integ, c.esp ? 1.0 : 0.0)
        applied.esp = c.esp
    end
    if fresh || applied.abs != c.abs
        set_abs!(integ, c.abs ? 1.0 : 0.0)
        applied.abs = c.abs
    end
    if applied.surface != c.surface
        set_mu!(integ, SURFACES[c.surface][2])
        applied.surface = c.surface
    end
end

# Grip used per wheel (FL, FR, RL, RR), 0 rolling freely .. 1 at the tire's peak and beyond.
grips(s) = map((k, a) -> clamp(max(abs(k) / PEAK_KAPPA, abs(a) / PEAK_ALPHA), 0.0, 1.5),
               (s.kfl, s.kfr, s.krl, s.krr), (s.afl, s.afr, s.arl, s.arr))

abs_cycling(s, c) = c.abs && s.demand > 100 &&
    any(<(0.85 * s.demand), (s.tfl, s.tfr, s.trl, s.trr))
esp_braking(s, c) = c.esp && s.esp > 50

# Sets the pad's feedback for this frame without sending it. Paused, the motors and triggers rest
# and only the lights show state.
function feedback!(pad, s, c, clock)
    if c.paused
        rumble!(pad)
        trigger!(pad, :left, TriggerOff())
        trigger!(pad, :right, TriggerOff())
    else
        spin = max(abs(s.kfl), abs(s.kfr)) / PEAK_KAPPA
        slide = maximum(grips(s))
        road = abs(s.vx) > 0.5 ? 0.03 + 0.05 * min(abs(s.vx) / 30, 1.0) : 0.0
        abs_on = abs_cycling(s, c)
        rumble!(pad; low = clamp(0.8 * (slide - 0.85), 0.0, 0.7) + (abs_on ? 0.25 : 0.0),
                high = road + (abs_on ? 0.35 : 0.0))
        trigger!(pad, :left, abs_on ? Vibration(2, 1.0, 25) : Feedback(2, 0.35))
        trigger!(pad, :right,
                 spin > 1.0 && c.throttle > 0.1 ? Vibration(3, 0.7, 40) : Feedback(1, 0.12))
    end
    if esp_braking(s, c)
        isodd(floor(Int, 8clock)) ? lightbar!(pad, 1.0, 0.45, 0.0) : lightbar!(pad, 0.0, 0.0, 0.0)
    elseif !c.esp
        lightbar!(pad, 0.5, 0.0, 0.0)
    else
        lightbar!(pad, 0.0, 0.3, 0.05)
    end
    player_leds!(pad, SURFACE_LEDS[c.surface])
    return pad
end

haptics!(pad, s, c, clock) = send!(feedback!(pad, s, c, clock))

# Keyboard: analog pedals and wheel are ramped so a key press is not a step.
ramp(x, target, rate, dt) = x + clamp(target - x, -rate * dt, rate * dt)

function rotate(points, x, y, psi)
    cs, sn = cos(psi), sin(psi)
    [Point2f(x + cs * px - sn * py, y + sn * px + cs * py) for (px, py) in points]
end
box(cx, cy, len, wid, ang) = rotate([(-len / 2, -wid / 2), (len / 2, -wid / 2),
                                     (len / 2, wid / 2), (-len / 2, wid / 2)], cx, cy, ang)
const WHEEL_AT = (fl = (A, TW / 2), fr = (A, -TW / 2), rl = (-B, TW / 2), rr = (-B, -TW / 2))

function car_shapes(s)
    body = rotate(box(-0.1, 0.0, 4.3, 1.8, 0.0), s.x, s.y, s.psi)
    delta = s.sw / I_S
    wheels = [rotate(box(px, py, 0.64, 0.24, w in (:fl, :fr) ? delta : 0.0), s.x, s.y, s.psi)
              for (w, (px, py)) in pairs(WHEEL_AT)]
    return body, wheels
end

grip_color(g) = g < 0.7 ? RGBf(0.2, 0.75, 0.3) : g < 1.0 ? RGBf(0.95, 0.75, 0.1) : RGBf(0.9, 0.15, 0.1)

function course!(ax)
    span = -400:10:400
    linesegments!(ax, [p for v in span for p in (Point2f(v, -400), Point2f(v, 400))];
                  color = (:gray55, 0.35), linewidth = 1)
    linesegments!(ax, [p for v in span for p in (Point2f(-400, v), Point2f(400, v))];
                  color = (:gray55, 0.35), linewidth = 1)
    cones = [Point2f(x, 0) for x in 60:20:220]
    scatter!(ax, cones; color = :orange, marker = :utriangle, markersize = 14)
    lane = [Point2f(x, y) for x in 260:12:340 for y in (-1.8, 1.8)]
    scatter!(ax, lane; color = :orange, marker = :utriangle, markersize = 12)
    text!(ax, Point2f(60, -6); text = "slalom", color = :gray40)
    text!(ax, Point2f(260, -6); text = "lane change", color = :gray40)
    θ = range(0, 2π, 120)
    lines!(ax, [Point2f(40cos(a), 80 + 40sin(a)) for a in θ]; color = (:white, 0.6), linewidth = 3)
    text!(ax, Point2f(-10, 125); text = "40 m circle", color = :gray40)
end

bar(x) = (n = round(Int, 12clamp(x, 0, 1)); "█"^n * "░"^(12 - n))

# A scripted drive through launch, slalom and a full stop compiles the solver's paths (ABS and ESP
# included) before the window opens; once per Julia session. The pad's feedback is computed but
# not sent, then one quiet report goes out, so the controller stays still while the window opens.
const WARMED = Ref(false)
function warm_up!(pad)
    println("warming up the solver…")
    controls = Controls()
    integ = new_integrator()
    applied = Applied()
    for k in 1:600
        tm = k * FRAME
        controls.throttle, controls.brake, controls.steer =
            tm < 4 ? (1.0, 0.0, 0.0) : tm < 7 ? (0.3, 0.0, sin(3tm)) : (0.0, 1.0, 0.0)
        apply!(integ, controls, 10.0, applied)
        step!(integ, FRAME, true)
        s = snapshot(integ)
        car_shapes(s)
        map(grip_color, grips(s))
        pad === nothing || feedback!(pad, s, controls, tm)
    end
    pad === nothing || quiet!(pad)
    WARMED[] = true
end

function main()
    pad = try
        p = open_pad()
        println("DualSense on ", p.path)
        p
    catch e
        println("no DualSense (", sprint(showerror, e), "); keyboard only")
        nothing
    end

    controls = Controls()
    if !WARMED[]
        warm_up!(pad)
    elseif pad !== nothing
        quiet!(pad)
    end
    integ = new_integrator()
    applied = Applied()

    GLMakie.activate!(; title = "VehicleSystemsComponents — planar BEV", vsync = false)
    fig = Figure(size = (1500, 900), backgroundcolor = RGBf(0.93, 0.93, 0.9))
    ax = Axis(fig[1, 1]; aspect = DataAspect(), backgroundcolor = RGBf(0.82, 0.83, 0.8),
              xlabel = "x [m]", ylabel = "y [m]")
    course!(ax)

    s = snapshot(integ)
    body0, wheels0 = car_shapes(s)
    trail = Observable(Point2f[])
    skids = Observable(Point2f[])
    body = Observable(body0)
    wheels = Observable(wheels0)
    wheel_colors = Observable(fill(grip_color(0.0), 4))
    scatter!(ax, skids; color = (:black, 0.35), markersize = 3)
    lines!(ax, trail; color = (:steelblue, 0.7), linewidth = 2)
    poly!(ax, body; color = RGBf(0.15, 0.3, 0.6), strokecolor = :black, strokewidth = 1)
    poly!(ax, wheels; color = wheel_colors, strokecolor = :black, strokewidth = 1)

    hud = fig[1, 2] = GridLayout(; tellheight = false, valign = :top)
    colsize!(fig.layout, 2, GLMakie.Fixed(380))
    speed_text = Observable("0 km/h")
    status_text = Observable("")
    Label(hud[1, 1], speed_text; fontsize = 56, font = :bold, halign = :left)
    Label(hud[2, 1], status_text; fontsize = 17, halign = :left, justification = :left,
          font = "DejaVu Sans Mono")
    Label(hud[3, 1], """
        DualSense                Keyboard
        R2 throttle              W / ↑
        L2 brake                 S / ↓
        left stick steer         A D / ← →
        △ ESP   □ ABS            E   Q
        ○ road surface           R
        × drive mode N/D/e-Pedal  M
        options reset            Backspace
        PS pause                 P
        D-pad ← → steering lock  [ ]
        """; fontsize = 14, halign = :left, justification = :left, font = "DejaVu Sans Mono",
          color = :gray30, padding = (0, 0, 20, 0))

    held = Set{Keyboard.Button}()
    pressed = Keyboard.Button[]
    on(events(fig).keyboardbutton) do ev
        if ev.action == Keyboard.press
            push!(held, ev.key)
            push!(pressed, ev.key)
        elseif ev.action == Keyboard.release
            delete!(held, ev.key)
        end
        return Consume(false)
    end

    screen = display(fig)
    kb = (throttle = 0.0, brake = 0.0, steer = 0.0)
    previous_buttons = UInt32(0)
    previous_dpad = 0x08
    last_wall = time()
    sim_time_acc = 0.0
    wall_acc = 0.0
    work_ms = 0.0
    step_count = 0
    try
        while isopen(screen)
            frame_start = time()
            dt = clamp(frame_start - last_wall, 1e-3, 0.05)
            last_wall = frame_start

            reset = false
            for key in pressed
                key == Keyboard.e && (controls.esp = !controls.esp)
                key == Keyboard.q && (controls.abs = !controls.abs)
                key == Keyboard.r && (controls.surface = mod1(controls.surface + 1, length(SURFACES)))
                key == Keyboard.m && (controls.mode = mod1(controls.mode + 1, length(DRIVE_MODES)))
                key == Keyboard.p && (controls.paused = !controls.paused)
                key == Keyboard.backspace && (reset = true)
                key == Keyboard.left_bracket && adjust_lock!(controls, -1)
                key == Keyboard.right_bracket && adjust_lock!(controls, 1)
            end
            empty!(pressed)
            # A key released while another window has focus never reports its release.
            if !events(fig).hasfocus[]
                empty!(held)
                kb = (throttle = 0.0, brake = 0.0, steer = 0.0)
            end
            up = Keyboard.w in held || Keyboard.up in held
            down = Keyboard.s in held || Keyboard.down in held
            left = Keyboard.a in held || Keyboard.left in held
            right = Keyboard.d in held || Keyboard.right in held
            kb = (throttle = ramp(kb.throttle, up ? 1.0 : 0.0, 3.0, dt),
                  brake = ramp(kb.brake, down ? 1.0 : 0.0, 4.0, dt),
                  steer = ramp(kb.steer, left - right, left == right ? 4.0 : 2.0, dt))

            throttle, brake, steer = kb.throttle, kb.brake, kb.steer
            if pad !== nothing
                ps = poll!(pad)
                edge = ps.buttons & ~previous_buttons
                previous_buttons = ps.buttons
                hit(b) = (edge & DualSense.BUTTONS[b]) != 0
                hit(:triangle) && (controls.esp = !controls.esp)
                hit(:square) && (controls.abs = !controls.abs)
                hit(:circle) && (controls.surface = mod1(controls.surface + 1, length(SURFACES)))
                hit(:cross) && (controls.mode = mod1(controls.mode + 1, length(DRIVE_MODES)))
                hit(:ps) && (controls.paused = !controls.paused)
                hit(:options) && (reset = true)
                if ps.dpad != previous_dpad
                    ps.dpad == DPAD_LEFT && adjust_lock!(controls, -1)
                    ps.dpad == DPAD_RIGHT && adjust_lock!(controls, 1)
                    previous_dpad = ps.dpad
                end
                throttle = max(throttle, ps.r2)
                brake = max(brake, ps.l2)
                stick = abs(ps.lx) < 0.06 ? 0.0 : ps.lx
                kb.steer == 0 && (steer = -stick)
            end
            controls.throttle, controls.brake, controls.steer = throttle, brake, steer

            if reset
                integ = new_integrator()
                applied = Applied()
                s = snapshot(integ)
                trail[] = Point2f[]
                skids[] = Point2f[]
            end

            work = @elapsed if !controls.paused
                apply!(integ, controls, s.vx, applied)
                step!(integ, dt, true)
                if !(string(integ.sol.retcode) in ("Default", "Success"))
                    @warn "solver stopped ($(integ.sol.retcode)); resetting the car"
                    integ = new_integrator()
                    applied = Applied()
                end
                sim_time_acc += dt
            end
            wall_acc += dt
            work_ms = 0.9work_ms + 0.1 * 1000work
            s = snapshot(integ)
            g = grips(s)

            b, ws = car_shapes(s)
            body[] = b
            wheels[] = ws
            wheel_colors[] = collect(map(grip_color, g))
            step_count += 1
            if !controls.paused && step_count % 3 == 0
                push!(trail[], Point2f(s.x, s.y))
                length(trail[]) > 1500 && popfirst!(trail[])
                notify(trail)
                for (gw, poly) in zip(g, ws)
                    gw >= 1.0 && push!(skids[], sum(poly) / 4)
                end
                length(skids[]) > 6000 && deleteat!(skids[], 1:length(skids[])-6000)
                notify(skids)
            end
            limits!(ax, s.x - 40, s.x + 40, s.y - 25, s.y + 25)

            speed_text[] = "$(round(Int, 3.6 * s.vx)) km/h"
            status_text[] = join([
                "throttle $(bar(controls.throttle))",
                "brake    $(bar(controls.brake))",
                "steer    $(lpad(round(Int, rad2deg(s.sw)), 4))°  wheel $(lpad(round(Int, rad2deg(s.sw / I_S)), 3))°",
                "lock now $(lpad(round(Int, rad2deg(max_steer(controls, s.vx) / I_S)), 4))° at the wheel ($(round(Int, 100controls.lock / FULL_LOCK)) %)",
                "",
                "motor   $(lpad(round(Int, s.motor), 5)) N·m",
                "brakes  FL $(lpad(round(Int, s.tfl), 4)) + regen $(lpad(round(Int, max(-s.motor, 0) * RATIO / 2), 4)) N·m",
                "        RL $(lpad(round(Int, s.trl), 4)) N·m",
                "battery $(lpad(round(s.power / 1000, digits = 1), 6)) kW   SoC $(round(100s.soc, digits = 1)) %",
                "yaw     $(lpad(round(s.r, digits = 2), 6)) rad/s",
                "lat acc $(lpad(round(s.ay / 9.81, digits = 2), 6)) g",
                "",
                "ESP $(controls.esp ? "on " : "OFF")  $(esp_braking(s, controls) ? "▶ BRAKING A WHEEL" : "")",
                "ABS $(controls.abs ? "on " : "OFF")  $(abs_cycling(s, controls) ? "▶ CYCLING" : "")",
                "road  $(SURFACES[controls.surface][1])",
                "drive $(DRIVE_MODES[controls.mode][1])",
                "",
                "$(pad === nothing ? "keyboard" : "DualSense + keyboard")$(controls.paused ? "   PAUSED" : "")",
                "solver $(round(work_ms, digits = 1)) ms / frame",
            ], "\n")

            pad === nothing || haptics!(pad, s, controls, wall_acc)
            sleep(max(0.0, FRAME - (time() - frame_start)))
        end
    finally
        pad === nothing || close(pad)
    end
end

abspath(PROGRAM_FILE) == (@__FILE__) && main()
