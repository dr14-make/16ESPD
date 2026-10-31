# `PlanarBEVDrive` assembled in Julia from the library's compiled components, wiring for wiring as
# dyad/Vehicle/Planar/PlanarBEVDrive.dyad declares it. Once that file compiles, `drive_model`
# becomes `VehicleSystemsComponents.Vehicle.Planar.PlanarBEVDrive`.
using VehicleSystemsComponents, ModelingToolkit
using ModelingToolkit: t_nounits as t
using BlockComponents, RotationalComponents, MultibodyComponents
using DyadInterface: simplify_model

const VSC = VehicleSystemsComponents

function drive_model(; name, m = 1500.0, radius = 0.31, T_full = 2500.0, tau_max = 320.0,
                     P_charge = 80.5e3, v_fade = 10.0, P_aux = 300.0, ratio = 8.193,
                     T_driver = 0.05, dv_wheel = 0.01)
    @named throttle_pedal = BlockComponents.Sources.Constant(k = 0.0)
    @named brake_pedal = BlockComponents.Sources.Constant(k = 0.0)
    @named steering_wheel = BlockComponents.Sources.Constant(k = 0.0)
    @named pedals = BlockComponents.Math.Add(k1 = tau_max, k2 = -4.0 * T_full / ratio)
    @named foot = BlockComponents.Continuous.FirstOrder(T = T_driver)
    @named hands = BlockComponents.Continuous.FirstOrder(T = T_driver)
    @named robot = VSC.Vehicle.Planar.SteeringRobot()
    @named kmh = VSC.Vehicle.ToKmPerHour()
    @named blend = VSC.Vehicle.Electric.RegenBlend(; ratio, radius, tau_max, P_charge, v_fade)
    @named drive = VSC.Vehicle.Electric.ElectricDrive(; ratio, P_aux)
    @named differential = MultibodyComponents.PlanarMechanics.DifferentialGear()
    @named mount = RotationalComponents.Components.Fixed()
    @named ecu = VSC.Vehicle.Planar.BrakeControlUnit(; radius, T_max = T_full)
    @named car = VSC.Vehicle.Planar.PlanarCar(; m, radius, tau_max = T_full)
    @named roadload = VSC.Vehicle.Planar.PlanarRoadLoad(; m)
    @named flat = BlockComponents.Sources.Constant(k = 0.0)
    @named motion = VSC.Vehicle.Planar.BusMotion()
    @named slips = VSC.Vehicle.Planar.BusSlip()
    systems = [throttle_pedal, brake_pedal, steering_wheel, pedals, foot, hands, robot, kmh, blend,
               drive, differential, mount, ecu, car, roadload, flat, motion, slips]
    eqs = [
        connect(car.bus, motion.bus, slips.bus),
        connect(throttle_pedal.y, pedals.u1),
        connect(brake_pedal.y, pedals.u2),
        connect(pedals.y, foot.u),
        connect(foot.y, blend.tau_ref),
        connect(steering_wheel.y, hands.u),
        connect(hands.y, robot.delta_sw_ref),
        connect(robot.steering, car.steering),
        connect(motion.vx, kmh.u, ecu.vx),
        connect(kmh.y, blend.v),
        connect(blend.tau_motor, drive.tau_ref),
        connect(blend.tau_brake, ecu.demand),
        connect(drive.spline, differential.flange_b),
        connect(differential.flange_left, car.spin_fl),
        connect(differential.flange_right, car.spin_fr),
        connect(drive.support, mount.spline),
        connect(motion.delta_sw, ecu.delta_sw),
        connect(motion.r, ecu.r),
        connect(slips.kappa_fl, ecu.kappa_fl),
        connect(slips.kappa_fr, ecu.kappa_fr),
        connect(slips.kappa_rl, ecu.kappa_rl),
        connect(slips.kappa_rr, ecu.kappa_rr),
        connect(ecu.tau_fl, car.tau_fl),
        connect(ecu.tau_fr, car.tau_fr),
        connect(ecu.tau_rl, car.tau_rl),
        connect(ecu.tau_rr, car.tau_rr),
        connect(flat.y, roadload.grade),
        connect(car.chassis, roadload.chassis),
    ]
    w0 = dv_wheel / radius
    init = [
        car.body.r ~ [0, 0], car.body.v ~ [0, 0], car.body.phi ~ 0.0, car.body.w ~ 0.0,
        car.fl.inertia.w ~ w0, car.fr.inertia.w ~ w0, car.rl.inertia.w ~ w0, car.rr.inertia.w ~ w0,
        car.fl.inertia.phi ~ 0.0, car.fr.inertia.phi ~ 0.0,
        car.rl.inertia.phi ~ 0.0, car.rr.inertia.phi ~ 0.0,
        car.fl.brake.tau_actual ~ 0.0, car.fr.brake.tau_actual ~ 0.0,
        car.rl.brake.tau_actual ~ 0.0, car.rr.brake.tau_actual ~ 0.0,
        drive.converter.i_out ~ 0.0, foot.x ~ 0.0, hands.x ~ 0.0,
    ]
    return System(eqs, t; systems, name, initialization_eqs = init)
end
