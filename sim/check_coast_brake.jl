# Coast-down from ~105 km/h, then a full brake application, printing road load, motor torque and
# per-wheel friction torque and slip. Run from the repository root:
#   julia +dyad-3.5.0 --project=. sim/check_coast_brake.jl
include(joinpath(pwd(), "sim", "plant.jl"))
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using SymbolicIndexingInterface: setp, getu
@named model = drive_model()
sys = simplify_model(model)
integ = init(ODEProblem(sys, [], (0.0, 1e6)), Rodas5P(); dtmax = 0.005, save_everystep = false)
th = setp(integ, sys.throttle_pedal.k); br = setp(integ, sys.brake_pedal.k)
rd = getu(integ, [sys.motion.vx, sys.roadload.F, sys.drive.machine.tau, sys.blend.tau_motor, sys.blend.tau_brake,
                  sys.car.tau_fl, sys.car.tau_rl, sys.slips.kappa_fl, sys.slips.kappa_rl])
show(t) = (s = rd(integ); println(rpad("t=$(round(integ.t, digits=2))", 8), " v=", round(3.6s[1], digits=1), " km/h  F_road=", round(s[2]),
  " N  motor=", round(s[3]), "  regen_cmd=", round(s[4]), "  fric_demand/wheel=", round(s[5]),
  "  tau_fl=", round(s[6]), " tau_rl=", round(s[7]), "  kappa_fl=", round(s[8], digits=3), " kappa_rl=", round(s[9], digits=3)))
th(integ, 1.0); step!(integ, 9.0, true); show(0)
th(integ, 0.0); println("-- coast"); for k in 1:5; step!(integ, 2.0, true); show(0); end
br(integ, 1.0); println("-- full brake"); for k in 1:12; step!(integ, 0.25, true); show(0); end
