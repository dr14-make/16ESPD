# Can the plant keep up with the wall clock? Steps the solver in display-frame slices under a
# scripted drive (launch, slalom, hard stop) and reports the time spent per simulated second,
# then the frames that missed their budget, separately.
#   julia +dyad-3.5.0 --project=. sim/bench_realtime.jl
using VehicleSystemsComponents, ModelingToolkit
using DyadInterface: simplify_model
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using ModelingToolkit: getu, remake

const V = VehicleSystemsComponents

@named model = V.PlanarBEVByHand()
t_build = @elapsed sys = simplify_model(model)
println("compiled in $(round(t_build, digits = 1)) s; ",
        length(unknowns(sys)), " unknowns")

prob = ODEProblem(sys, [], (0.0, 1e6))
start(prob) = (V.reset_human_commands!(); init(prob, Rodas5P(); dtmax = 0.005, save_everystep = false))

function driver(time)
    time < 6 ? (1.0, 0.0, 0.0) :
    time < 12 ? (0.4, 0.0, 1.5 * sin(2π * (time - 6) / 3)) :
    time < 16 ? (0.0, 1.0, 0.0) : (0.0, 0.0, 0.0)
end

const FRAME = 1 / 60
function frame!(integ, commands)
    th, br, st = commands(integ.t)
    V.set_human_commands!(throttle = th, brake = br, steer = st)
    step!(integ, FRAME, true)
end
drive!(integ, stop, commands) = while integ.t < stop
    frame!(integ, commands)
end

speed = getu(prob, sys.vehicle.motion.vx)
yaw = getu(prob, sys.vehicle.motion.r)
torques = getu(prob, [sys.vehicle.car.tau_fl, sys.vehicle.car.tau_fr, sys.vehicle.car.tau_rl, sys.vehicle.car.tau_rr])
status(integ) = "t=$(round(integ.t, digits = 1))  v=$(round(3.6speed(integ), digits = 1)) km/h  " *
                "r=$(round(yaw(integ), digits = 2))  tau=$(round.(Int, torques(integ)))"

# Launch, steer, a brake at speed and the status line each compile on first use, and what a
# compilation leaves on the heap slows the next young collections. A separate integrator
# reaches them all, so the measured drive starts from the same state as an unwarmed one.
warm = start(remake(prob; p = deepcopy(prob.p)))
drive!(warm, 3.0, driver)
drive!(warm, 3.2, t -> (0.4, 0.0, 1.0))
drive!(warm, 3.4, t -> (0.0, 1.0, 0.0))
drive!(warm, 3.5, t -> (0.0, 0.0, 0.0))
status(warm)

integ = start(prob)
drive!(integ, 0.5, driver)

function measure!(integ, stop, frame_gc)
    frames, at = Float64[], Float64[]
    next_print = 2 * (floor(integ.t / 2) + 1)
    V.collect_after_warm_up!(frame_gc)
    wall = @elapsed while integ.t < stop
        push!(at, integ.t)
        push!(frames, @elapsed (frame!(integ, driver); V.collect_after_frame!(frame_gc)))
        if integ.t >= next_print - FRAME / 2
            next_print += 2
            println(status(integ))
        end
    end
    return wall, frames, at
end

t0 = integ.t
wall, frames, at = measure!(integ, 18.0, V.FrameGC())
ms(x) = round(1000x, digits = 1)
sorted = sort(frames)
slowest = argmax(frames)
over = count(>(FRAME), frames)
println("\n$(round(integ.t - t0, digits = 1)) s simulated in $(round(wall, digits = 2)) s wall: ",
        "$(round((integ.t - t0) / wall, digits = 1))x real time, mean frame $(round(1000wall / length(frames), digits = 2)) ms")
println("frames over the $(ms(FRAME)) ms budget: $over of $(length(frames)); ",
        "p99 $(ms(sorted[ceil(Int, 0.99length(sorted))])) ms, ",
        "slowest $(ms(frames[slowest])) ms at t=$(round(at[slowest], digits = 2)) s")
