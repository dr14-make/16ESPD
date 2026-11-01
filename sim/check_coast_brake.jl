# Coast-down from ~105 km/h, then a full brake application, printing road load, motor torque and
# per-wheel friction torque and slip.
#   julia +dyad-3.5.0 --project=. sim/check_coast_brake.jl
using VehicleSystemsComponents, ModelingToolkit
using DyadInterface: simplify_model
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using SymbolicIndexingInterface: setp, getu
@named model = VehicleSystemsComponents.PlanarBEVScripted(
    table = "dyad://VehicleSystemsComponents/drivers/hard_stop.csv")
sys = simplify_model(model)
integ = init(ODEProblem(sys, [], (0.0, 1e6)), Rodas5P(); dtmax = 0.005, save_everystep = false)
vehicle = sys.vehicle
rd = getu(integ, [vehicle.motion.vx, vehicle.roadload.F, vehicle.drive.machine.tau, vehicle.blend.tau_motor, vehicle.blend.tau_brake,
                  vehicle.car.tau_fl, vehicle.car.tau_rl, vehicle.slips.kappa_fl, vehicle.slips.kappa_rl])
report() = (s = rd(integ); println(rpad("t=$(round(integ.t, digits=2))", 8), " v=", round(3.6s[1], digits=1), " km/h  F_road=", round(s[2]),
  " N  motor=", round(s[3]), "  regen_cmd=", round(s[4]), "  fric_demand/wheel=", round(s[5]),
  "  tau_fl=", round(s[6]), " tau_rl=", round(s[7]), "  kappa_fl=", round(s[8], digits=3), " kappa_rl=", round(s[9], digits=3)))
step!(integ, 9.0, true); report()
println("-- coast"); for k in 1:5; step!(integ, 2.0, true); report(); end
println("-- full brake"); for k in 1:12; step!(integ, 0.25, true); report(); end
