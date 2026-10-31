# Can the plant keep up with the wall clock? Steps the solver in display-frame slices under a
# scripted drive (launch, slalom, hard stop) and reports the time spent per simulated second.
#   julia +dyad-3.5.0 --project=. sim/bench_realtime.jl
include(joinpath(@__DIR__, "plant.jl"))
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using SymbolicIndexingInterface: setp, getu

@named model = drive_model()
t_build = @elapsed sys = simplify_model(model)
println("compiled in $(round(t_build, digits = 1)) s; ",
        length(unknowns(sys)), " unknowns")

prob = ODEProblem(sys, [], (0.0, 1e6))
integ = init(prob, Rodas5P(); dtmax = 0.005, save_everystep = false)
set_throttle! = setp(integ, sys.throttle_pedal.k)
set_brake! = setp(integ, sys.brake_pedal.k)
set_steer! = setp(integ, sys.steering_wheel.k)
speed = getu(integ, sys.motion.vx)
yaw = getu(integ, sys.motion.r)
torques = getu(integ, [sys.car.tau_fl, sys.car.tau_fr, sys.car.tau_rl, sys.car.tau_rr])

function driver(time)
    time < 6 ? (1.0, 0.0, 0.0) :
    time < 12 ? (0.4, 0.0, 1.5 * sin(2π * (time - 6) / 3)) :
    time < 16 ? (0.0, 1.0, 0.0) : (0.0, 0.0, 0.0)
end

frame = 1 / 60
function run(stop)
    worst = 0.0
    wall = @elapsed while integ.t < stop
        th, br, st = driver(integ.t)
        set_throttle!(integ, th)
        set_brake!(integ, br)
        set_steer!(integ, st)
        f = @elapsed step!(integ, frame, true)
        worst = max(worst, f)
        if isapprox(integ.t % 2, 0; atol = frame / 2)
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
