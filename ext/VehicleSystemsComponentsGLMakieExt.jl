module VehicleSystemsComponentsGLMakieExt

using VehicleSystemsComponents
using GLMakie
using OrdinaryDiffEqDefault: step!, init, Rodas5P
using ModelingToolkit: remake, getp, getu

const DRIVE_MODES = (("N (coast)", 0.0), ("D", 0.025), ("e-Pedal", 0.2))
const PEAK_KAPPA, PEAK_ALPHA = 0.12, 0.12
const FRAME = 1 / 60
const FULL_LOCK = 9.6
const LOCK_RANGE = (0.3FULL_LOCK, FULL_LOCK)

# All model-dependent data belongs to this invocation, not to the extension module.
function context(integ, assembly)
    sys = assembly.vehicle
    a, b, tw, i_s, mass, radius, torque, ratio = Float64.(getp(assembly, [
        sys.car.a, sys.car.b, sys.car.tw, sys.car.i_s, sys.car.m,
        sys.car.radius, sys.car.tau_max, sys.blend.ratio])(integ))
    signals = (
        :x => sys.motion.x, :y => sys.motion.y, :psi => sys.motion.psi,
        :vx => sys.motion.vx, :r => sys.motion.r, :ay => sys.motion.ay, :sw => sys.steering_response.y,
        :kfl => sys.slips.kappa_fl, :kfr => sys.slips.kappa_fr,
        :krl => sys.slips.kappa_rl, :krr => sys.slips.kappa_rr,
        :afl => sys.car.bus.alpha_fl, :afr => sys.car.bus.alpha_fr,
        :arl => sys.car.bus.alpha_rl, :arr => sys.car.bus.alpha_rr,
        :tfl => sys.car.tau_fl, :tfr => sys.car.tau_fr,
        :trl => sys.car.tau_rl, :trr => sys.car.tau_rr,
        :demand => sys.blend.tau_brake,
        :esp => sys.ecu.esp.dT_fl + sys.ecu.esp.dT_fr + sys.ecu.esp.dT_rl + sys.ecu.esp.dT_rr,
        :motor => sys.drive.machine.tau,
        :power => sys.drive.battery.v * sys.drive.battery.i, :soc => sys.drive.SoC)
    read_signals = getu(assembly, collect(last.(signals)))
    snapshot = i -> NamedTuple{Tuple(first.(signals))}(Tuple(read_signals(i)))
    return (; i_s, mass, radius, torque, ratio, snapshot,
            by_hand = hasproperty(assembly.driver, :reader),
            wheel_at = (fl = (a, tw / 2), fr = (a, -tw / 2),
                        rl = (-b, tw / 2), rr = (-b, -tw / 2)))
end

"Pedals, steering, fixed run settings, and display state for one drive."
mutable struct Controls
    throttle::Float64
    brake::Float64
    steer::Float64
    esp::Bool
    abs::Bool
    mu::Float64
    paused::Bool
    lock::Float64
    mode::Int
end
Controls(; esp_on = 1.0, abs_on = 1.0, mu = 1.0) =
    Controls(0, 0, 0, esp_on > 0.5, abs_on > 0.5, mu, false, FULL_LOCK, 2)
adjust_lock!(c, dir) = (c.lock = clamp(c.lock * 1.15^dir, LOCK_RANGE...))
max_steer(c, speed) = c.lock / (1 + max(speed, 0.0) / 45)

function apply!(integ, sys, ctx, c, speed)
    ctx.by_hand || return nothing
    liftoff = c.throttle < 0.02 ? ctx.mass * 9.81 * DRIVE_MODES[c.mode][2] *
        ctx.radius / (4 * ctx.torque) : 0.0
    VehicleSystemsComponents.set_human_commands!(;
        throttle = c.throttle, brake = max(c.brake, liftoff), steer = c.steer * max_steer(c, speed))
end

grips(s) = map((k, a) -> clamp(max(abs(k) / PEAK_KAPPA, abs(a) / PEAK_ALPHA), 0.0, 1.5),
    (s.kfl, s.kfr, s.krl, s.krr), (s.afl, s.afr, s.arl, s.arr))
abs_cycling(s, c) = c.abs && s.demand > 100 && any(<(0.85 * s.demand), (s.tfl, s.tfr, s.trl, s.trr))
esp_braking(s, c) = c.esp && s.esp > 50
ramp(x, target, rate, dt) = x + clamp(target - x, -rate * dt, rate * dt)
function rotate(points, x, y, psi)
    cs, sn = cos(psi), sin(psi)
    [Point2f(x + cs * px - sn * py, y + sn * px + cs * py) for (px, py) in points]
end
box(cx, cy, len, wid, ang) = rotate([(-len/2, -wid/2), (len/2, -wid/2),
    (len/2, wid/2), (-len/2, wid/2)], cx, cy, ang)
function car_shapes(ctx, s)
    body = rotate(box(-0.1, 0.0, 4.3, 1.8, 0.0), s.x, s.y, s.psi)
    wheels = [rotate(box(px, py, 0.64, 0.24, w in (:fl, :fr) ? s.sw / ctx.i_s : 0.0),
        s.x, s.y, s.psi) for (w, (px, py)) in pairs(ctx.wheel_at)]
    return body, wheels
end
grip_color(g) = g < 0.7 ? RGBf(0.2, 0.75, 0.3) : g < 1.0 ? RGBf(0.95, 0.75, 0.1) : RGBf(0.9, 0.15, 0.1)
bar(x) = (n = round(Int, 12clamp(x, 0, 1)); "█"^n * "░"^(12 - n))
function course!(ax)
    span = -400:10:400
    linesegments!(ax, [p for v in span for p in (Point2f(v, -400), Point2f(v, 400))]; color = (:gray55, 0.35), linewidth = 1)
    linesegments!(ax, [p for v in span for p in (Point2f(-400, v), Point2f(400, v))]; color = (:gray55, 0.35), linewidth = 1)
    scatter!(ax, [Point2f(x, 0) for x in 60:20:220]; color = :orange, marker = :utriangle, markersize = 14)
    scatter!(ax, [Point2f(x, y) for x in 260:12:340 for y in (-1.8, 1.8)]; color = :orange, marker = :utriangle, markersize = 12)
    text!(ax, Point2f(60, -6); text = "slalom", color = :gray40)
    text!(ax, Point2f(260, -6); text = "lane change", color = :gray40)
    lines!(ax, [Point2f(40cos(a), 80 + 40sin(a)) for a in range(0, 2π, 120)]; color = (:white, 0.6), linewidth = 3)
    text!(ax, Point2f(-10, 125); text = "40 m circle", color = :gray40)
end

# No method is overwritten when SDL loads. Choose its extension only when driving is requested.
function VehicleSystemsComponents.drive_window(integ, sys, spec)
    padext = Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsPadExt)
    mode = padext === nothing || !hasproperty(sys.driver, :reader) ? nothing : padext.PadMode()
    return VehicleSystemsComponents.drive_window(integ, sys, spec, mode)
end
# Runtime routing avoids dependencies between the two optional extensions.
pad_extension() = Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsPadExt)
poll_controls!(pad, c, kb) = pad_extension().poll_controls!(pad, c, kb)
feedback!(pad, s, c, clock) = pad_extension().feedback!(pad, s, c, clock)
haptics!(pad, s, c, clock) = pad_extension().haptics!(pad, s, c, clock)
quiet!(pad) = pad_extension().quiet_session!(pad)

poll_controls!(::Nothing, c, kb) = (kb.throttle, kb.brake, kb.steer, false)
feedback!(::Nothing, s, c, clock) = nothing
haptics!(::Nothing, s, c, clock) = nothing
quiet!(::Nothing) = nothing

# Feedback is computed without sending during solver warm-up.
const WARMED = Set{DataType}()
function warm_up!(integ, sys, ctx, pad)
    typeof(integ) in WARMED && return quiet!(pad)
    println("warming up the solver…")
    quiet!(pad)
    warmprob = remake(integ.sol.prob; p = deepcopy(integ.p), tspan = (0.0, 11.0))
    warm = init(warmprob, Rodas5P(); dtmax = 0.005, save_everystep = false)
    controls = Controls()
    for k in 1:600
        tm = k * FRAME
        controls.throttle, controls.brake, controls.steer =
            tm < 4 ? (1.0, 0.0, 0.0) : tm < 7 ? (0.3, 0.0, sin(3tm)) : (0.0, 1.0, 0.0)
        apply!(warm, sys, ctx, controls, 10.0)
        step!(warm, FRAME, true)
        s = ctx.snapshot(warm)
        car_shapes(ctx, s)
        map(grip_color, grips(s))
        feedback!(pad, s, controls, tm)
    end
    VehicleSystemsComponents.reset_human_commands!()
    quiet!(pad)
    push!(WARMED, typeof(integ))
end

VehicleSystemsComponents.drive_window(integ, sys, spec, ::Nothing) = window!(integ, sys, spec, nothing)

"Reset with fresh continuous and discrete solution histories."
function fresh_integrator(initial_prob, spec)
    VehicleSystemsComponents.reset_human_commands!()
    prob = remake(initial_prob; p = deepcopy(initial_prob.p))
    return init(prob, Rodas5P(); dtmax = spec.dtmax, saveat = spec.frame,
        save_everystep = false)
end


function window!(integ, sys, spec, pad)
    initial_prob = remake(integ.sol.prob; p = deepcopy(integ.p), u0 = copy(integ.u))
    function reset!()
        integ = fresh_integrator(initial_prob, spec)
        return nothing
    end
    ctx = context(integ, sys)
    warm_up!(integ, sys, ctx, pad)
    controls = Controls(; esp_on = spec.esp_on, abs_on = spec.abs_on, mu = spec.mu)
    GLMakie.activate!(; title = "VehicleSystemsComponents — planar BEV", vsync = false)
    fig = Figure(size = (1500, 900), backgroundcolor = RGBf(0.93, 0.93, 0.9))
    ax = Axis(fig[1, 1]; aspect = DataAspect(), backgroundcolor = RGBf(0.82, 0.83, 0.8), xlabel = "x [m]", ylabel = "y [m]")
    course!(ax)
    s = ctx.snapshot(integ)
    body0, wheels0 = car_shapes(ctx, s)
    trail, skids = Observable(Point2f[]), Observable(Point2f[])
    body, wheels = Observable(body0), Observable(wheels0)
    wheel_colors = Observable(fill(grip_color(0.0), 4))
    scatter!(ax, skids; color = (:black, 0.35), markersize = 3)
    lines!(ax, trail; color = (:steelblue, 0.7), linewidth = 2)
    poly!(ax, body; color = RGBf(0.15, 0.3, 0.6), strokecolor = :black, strokewidth = 1)
    poly!(ax, wheels; color = wheel_colors, strokecolor = :black, strokewidth = 1)
    hud = fig[1, 2] = GridLayout(; tellheight = false, valign = :top)
    colsize!(fig.layout, 2, GLMakie.Fixed(380))
    speed_text, status_text = Observable("0 km/h"), Observable("")
    Label(hud[1, 1], speed_text; fontsize = 56, font = :bold, halign = :left)
    Label(hud[2, 1], status_text; fontsize = 17, halign = :left, justification = :left, font = "DejaVu Sans Mono")
    Label(hud[3, 1], """
        DualSense                Keyboard
        R2 throttle              W / ↑
        L2 brake                 S / ↓
        left stick steer         A D / ← →
        × drive mode N/D/e-Pedal  M
        options reset            Backspace
        PS pause                 P
        D-pad ← → steering lock  [ ]
        """; fontsize = 14, halign = :left, justification = :left, font = "DejaVu Sans Mono", color = :gray30, padding = (0, 0, 20, 0))
    held, pressed = Set{Keyboard.Button}(), Keyboard.Button[]
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
    last_wall = time()
    wall_start = last_wall
    wall_acc, work_ms, frames = 0.0, 0.0, 0
    try
        while isopen(screen)
            frame_start = time()
            spec.duration > 0 && frame_start - wall_start >= spec.duration && break
            dt = clamp(frame_start - last_wall, 1e-3, 0.05)
            last_wall = frame_start
            reset = false
            for key in pressed
                key == Keyboard.m && (controls.mode = mod1(controls.mode + 1, length(DRIVE_MODES)))
                key == Keyboard.p && (controls.paused = !controls.paused)
                key == Keyboard.backspace && (reset = true)
                key == Keyboard.left_bracket && adjust_lock!(controls, -1)
                key == Keyboard.right_bracket && adjust_lock!(controls, 1)
            end
            empty!(pressed)
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
            throttle, brake, steer, pad_reset = poll_controls!(pad, controls, kb)
            reset |= pad_reset
            controls.throttle, controls.brake, controls.steer = throttle, brake, steer
            if reset
                reset!()
                s = ctx.snapshot(integ)
                trail[], skids[] = Point2f[], Point2f[]
            end
            work = @elapsed if !controls.paused
                apply!(integ, sys, ctx, controls, s.vx)
                step!(integ, dt, true)
                if !(string(integ.sol.retcode) in ("Default", "Success"))
                    @warn "solver stopped ($(integ.sol.retcode)); resetting the car"
                    reset!()
                end
            end
            wall_acc += dt
            work_ms = 0.9work_ms + 0.1 * 1000work
            s = ctx.snapshot(integ)
            g = grips(s)
            b, ws = car_shapes(ctx, s)
            body[], wheels[], wheel_colors[] = b, ws, collect(map(grip_color, g))
            frames += 1
            if !controls.paused && frames % 3 == 0
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
                "throttle $(bar(controls.throttle))", "brake    $(bar(controls.brake))",
                "steer    $(lpad(round(Int, rad2deg(s.sw)), 4))°  wheel $(lpad(round(Int, rad2deg(s.sw / ctx.i_s)), 3))°",
                "lock now $(lpad(round(Int, rad2deg(max_steer(controls, s.vx) / ctx.i_s)), 4))° at the wheel ($(round(Int, 100controls.lock / FULL_LOCK)) %)", "",
                "motor   $(lpad(round(Int, s.motor), 5)) N·m",
                "brakes  FL $(lpad(round(Int, s.tfl), 4)) + regen $(lpad(round(Int, max(-s.motor, 0) * ctx.ratio / 2), 4)) N·m",
                "        RL $(lpad(round(Int, s.trl), 4)) N·m",
                "battery $(lpad(round(s.power / 1000, digits = 1), 6)) kW   SoC $(round(100s.soc, digits = 1)) %",
                "yaw     $(lpad(round(s.r, digits = 2), 6)) rad/s",
                "lat acc $(lpad(round(s.ay / 9.81, digits = 2), 6)) g", "",
                "ESP $(controls.esp ? "on " : "OFF")  $(esp_braking(s, controls) ? "▶ BRAKING A WHEEL" : "")",
                "ABS $(controls.abs ? "on " : "OFF")  $(abs_cycling(s, controls) ? "▶ CYCLING" : "")",
                "road  μ = $(controls.mu)", "drive $(DRIVE_MODES[controls.mode][1])", "",
                "$(pad === nothing ? "keyboard" : "DualSense + keyboard")$(controls.paused ? "   PAUSED" : "")",
                "solver $(round(work_ms, digits = 1)) ms / frame"], "\n")
            haptics!(pad, s, controls, wall_acc)
            sleep(max(0.0, spec.frame - (time() - frame_start)))
        end
    catch e
        e isa InterruptException || rethrow()
        @info "drive interrupted; returning current drive" simulation_time = integ.t
    finally
        # The pad extension owns pad lifetime, including errors before display(fig).
        VehicleSystemsComponents.reset_human_commands!()
        isopen(screen) && close(screen)
    end
    return (; frames, wall = time() - wall_start, integrator = integ)
end

end
