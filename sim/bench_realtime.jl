# Can the plant keep up with the wall clock? Steps the solver in display-frame slices under a
# scripted drive (launch, slalom, hard stop) and reports the time spent per simulated second.
#   julia +dyad-3.5.0 --project=. sim/bench_realtime.jl
using VehicleSystemsComponents, ModelingToolkit
using DyadInterface: simplify_model
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using ModelingToolkit: getu

@named model = VehicleSystemsComponents.PlanarBEVByHand()
t_build = @elapsed sys = simplify_model(model)
println("compiled in $(round(t_build, digits = 1)) s; ",
        length(unknowns(sys)), " unknowns")

VehicleSystemsComponents.reset_human_commands!()
prob = ODEProblem(sys, [], (0.0, 1e6))
integ = init(prob, Rodas5P(); dtmax = 0.005, save_everystep = false)
speed = getu(integ, sys.vehicle.motion.vx)
yaw = getu(integ, sys.vehicle.motion.r)
torques = getu(integ, [sys.vehicle.car.tau_fl, sys.vehicle.car.tau_fr, sys.vehicle.car.tau_rl, sys.vehicle.car.tau_rr])

function driver(time)
    time < 6 ? (1.0, 0.0, 0.0) :
    time < 12 ? (0.4, 0.0, 1.5 * sin(2π * (time - 6) / 3)) :
    time < 16 ? (0.0, 1.0, 0.0) : (0.0, 0.0, 0.0)
end

frame = 1 / 60
function run(stop)
    worst = 0.0
    next_print = 2 * (floor(integ.t / 2) + 1)
    wall = @elapsed while integ.t < stop
        th, br, st = driver(integ.t)
        VehicleSystemsComponents.set_human_commands!(throttle = th, brake = br, steer = st)
        f = @elapsed step!(integ, frame, true)
        worst = max(worst, f)
        if integ.t >= next_print - frame / 2
            next_print += 2
            println("t=$(round(integ.t, digits = 1))  v=$(round(3.6speed(integ), digits = 1)) km/h  ",
                    "r=$(round(yaw(integ), digits = 2))  tau=$(round.(Int, torques(integ)))")
        end
    end
    return wall, worst
end

run(0.5)  # first steps pay for compilation
wall, worst = run(18.0)
println("\n$(round(integ.t - 0.5, digits = 1)) s simulated in $(round(wall, digits = 2)) s wall: ",
        "$(round((integ.t - 0.5) / wall, digits = 1))x real time; slowest frame $(round(1000worst, digits = 1)) ms ",
        "(budget $(round(1000frame, digits = 1)) ms)")
