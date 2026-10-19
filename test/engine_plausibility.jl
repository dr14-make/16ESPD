using DyadInterface: symbolic_container

const AirPathTransient = VehicleSystemsComponents.Vehicle.Engine.AirPathTransient
const P_AMBIENT = 101325.0
const PI_CRITICAL = 0.528

rad_per_s(rpm) = rpm * pi / 30

function air_path_run(; kwargs...)
    result = AirPathTransient(; kwargs...)
    model = symbolic_container(result)
    sol = result.sol
    return (t = sol.t, p_m = sol[model.air.p_m], mdot_thr = sol[model.air.mdot_thr],
            mdot_cyl = sol[model.air.mdot_cyl], retcode = sol.retcode)
end

const MappedEngineTransient = VehicleSystemsComponents.Vehicle.Engine.MappedEngineTransient
const MappedEngineDynoTransient = VehicleSystemsComponents.Vehicle.Engine.MappedEngineDynoTransient

function mapped_engine_run(analysis; kwargs...)
    result = analysis(; kwargs...)
    model = symbolic_container(result)
    sol = result.sol
    return (result = result, model = model, sol = sol)
end

choked_flow_nonnegative(run) =
    all(run.mdot_thr[k] >= 0 for k in eachindex(run.t) if run.p_m[k] < PI_CRITICAL * P_AMBIENT)

# Engine maps on the rpm x kPa grid written by scripts/alpha_engine_maps.jl.
function read_engine_map(name)
    lines = readlines(joinpath(@__DIR__, "..", "data", "engine", name))
    p_kpa = parse.(Float64, split(lines[1], ",")[2:end])
    rows = [parse.(Float64, split(l, ",")) for l in lines[2:end] if !isempty(l)]
    rpm = first.(rows)
    data = reduce(vcat, permutedims(r[2:end]) for r in rows)
    return (rpm = rpm, p_kpa = p_kpa, data = data)
end

function bilinear(map, rpm, p_kpa)
    i = clamp(searchsortedlast(map.rpm, rpm), 1, length(map.rpm) - 1)
    j = clamp(searchsortedlast(map.p_kpa, p_kpa), 1, length(map.p_kpa) - 1)
    u = (rpm - map.rpm[i]) / (map.rpm[i+1] - map.rpm[i])
    v = (p_kpa - map.p_kpa[j]) / (map.p_kpa[j+1] - map.p_kpa[j])
    d = map.data
    return (1 - u) * (1 - v) * d[i, j] + u * (1 - v) * d[i+1, j] +
           (1 - u) * v * d[i, j+1] + u * v * d[i+1, j+1]
end

@testset "Engine air-path plausibility (brake plan 2a)" begin
    idle = air_path_run(stop = 3.0, omega = rad_per_s(800), p_m0 = P_AMBIENT)
    p_idle = idle.p_m[end]
    @testset "idle, closed throttle, 800 rpm" begin
        @test string(idle.retcode) == "Success"
        @test 30e3 <= p_idle <= 36e3
        @test p_idle ≈ 33e3 rtol = 0.01
        @test choked_flow_nonnegative(idle)
    end

    @testset "overrun, closed throttle, 3000 rpm" begin
        overrun = air_path_run(stop = 2.0, omega = rad_per_s(3000), p_m0 = p_idle)
        @test overrun.p_m[end] < p_idle
        # The 17-34 kPa overrun band assumes an ECU that opens extra air on overrun; with only
        # the idle leak the manifold pulls down to about 13.5 kPa.
        @test_broken overrun.p_m[end] >= 17e3
        @test choked_flow_nonnegative(overrun)
    end

    @testset "tip-in to wide open at 3000 rpm" begin
        tip_in = air_path_run(stop = 2.0, du = 1.0, t_step = 0.5, omega = rad_per_s(3000),
                              p_m0 = 13.5e3)
        @test tip_in.p_m[end] > 90e3
        @test tip_in.p_m[end] < P_AMBIENT
        @test choked_flow_nonnegative(tip_in)
        @test all(>=(0), tip_in.mdot_thr)
    end

    @testset "wide-open throttle across speed" begin
        for rpm in (1000, 2000, 4000, 6000)
            wot = air_path_run(stop = 0.5, u0 = 1.0, omega = rad_per_s(rpm), p_m0 = 95e3)
            @test 90e3 < wot.p_m[end] < P_AMBIENT
            # The maps take full load at 95 kPa; a 50 mm throttle with no intake-duct loss
            # drops only 1-3 kPa, so wide open lands just above their 90-98 kPa band.
            @test_broken wot.p_m[end] <= 98e3
        end
    end

    @testset "manifold time constant" begin
        step_idle = air_path_run(stop = 3.0, du = 0.002, t_step = 1.0,
                                 omega = rad_per_s(800), p_m0 = p_idle)
        tau_idle = rise_time(step_idle.t, step_idle.p_m, 0.632; t0 = 1.0)
        @test 0.08 <= tau_idle <= 0.2

        # Part load at 3000 rpm, about 53 kPa: the throttle is still choked.
        settle = air_path_run(stop = 1.0, u0 = 0.117, omega = rad_per_s(3000), p_m0 = 50e3)
        step_3000 = air_path_run(stop = 1.5, u0 = 0.117, du = 0.005, t_step = 1.0,
                                 omega = rad_per_s(3000), p_m0 = settle.p_m[end])
        tau_3000 = rise_time(step_3000.t, step_3000.p_m, 0.632; t0 = 1.0)
        @test 0.02 <= tau_3000 <= 0.05
    end

    @testset "booster inflow at idle" begin
        release = air_path_run(stop = 4.0, omega = rad_per_s(800), mdot_bst = 2e-3,
                               t_bst = 1.0, d_bst = 0.5, p_m0 = p_idle)
        @test maximum(release.p_m) > p_idle + 10e3
        # Brake plan 2c: back to idle within 2 kPa inside 2 s of the release ending.
        after = findall(t -> t >= 1.5 + 2.0, release.t)
        @test all(abs.(release.p_m[after] .- p_idle) .<= 2e3)
        @test release.p_m[end] ≈ p_idle rtol = 1e-3
    end

    @testset "cylinder air matches the maps' fuel and lambda" begin
        fuel = read_engine_map("fuel_gps.csv")
        lambda = read_engine_map("lambda.csv")
        afr_s = 14.6
        # Cruise speeds of the mapped-engine plan, plus wide open at 3000 rpm where lambda < 1.
        for (rpm, u) in ((1710, 0.04), (3080, 0.1), (4450, 0.18), (3000, 1.0))
            run = air_path_run(stop = 1.0, u0 = u, omega = rad_per_s(rpm), p_m0 = 50e3)
            p_kpa = run.p_m[end] / 1e3
            mdot_from_maps = afr_s * bilinear(lambda, rpm, p_kpa) * bilinear(fuel, rpm, p_kpa) / 1e3
            @test run.mdot_cyl[end] ≈ mdot_from_maps rtol = 0.01
        end
    end
end


# Second column of a curve CSV keyed on rpm, linearly interpolated.
function engine_curve(name, rpm)
    rows = [parse.(Float64, split(l, ",")[1:2])
            for l in readlines(joinpath(@__DIR__, "..", "data", "engine", name))[2:end] if !isempty(l)]
    x, y = first.(rows), last.(rows)
    i = clamp(searchsortedlast(x, rpm), 1, length(x) - 1)
    return y[i] + (rpm - x[i]) / (x[i+1] - x[i]) * (y[i+1] - y[i])
end

@testset "Mapped engine" begin
    idle = mapped_engine_run(MappedEngineTransient; rpm = 800.0, pedal_cmd = 0.0,
                             p_m0 = 32955.7)
    idle_rpm = idle.sol(5.0, idxs = idle.model.engine.crankshaft.w) * 30 / pi
    idle_pm = idle.sol(5.0, idxs = idle.model.engine.p_m) / 1e3
    @test 700 <= idle_rpm <= 900
    @test 30 <= idle_pm <= 36

    # Pedals found by bisection on the 5 s dyno torque against the plan's cruise torques.
    fuel = read_engine_map("fuel_gps.csv")
    for (rpm, pedal, tau_target) in ((1710, 0.124172, 18.4), (3080, 0.220321, 31.1),
                                     (4450, 0.330916, 51.0))
        run = mapped_engine_run(MappedEngineDynoTransient; scenario = 1, rpm = rpm,
                                pedal_cmd = pedal, p_m0 = 40e3)
        p_kpa = run.sol(5.0, idxs = run.model.engine.p_m) / 1e3
        @test run.sol(5.0, idxs = run.model.engine.tau_e) ≈ tau_target rtol = 0.01
        @test run.sol(5.0, idxs = run.model.engine.mdot_fuel) ≈
              bilinear(fuel, rpm, p_kpa) / 1e3 rtol = 0.01
    end

    wot_torques = Float64[]
    for rpm in (1000, 2000, 3000, 4000, 6000)
        run = mapped_engine_run(MappedEngineDynoTransient; scenario = 1, rpm = rpm,
                                pedal_cmd = 1.0, p_m0 = 95e3)
        tau = run.sol(5.0, idxs = run.model.engine.tau_e)
        capped = run.sol(5.0, idxs = run.model.engine.torque_map.map.y) >=
                 run.sol(5.0, idxs = run.model.engine.torque_map.full_load.y)
        on_curve = isapprox(tau, engine_curve("full_load.csv", rpm); rtol = 0.01)
        push!(wot_torques, tau)
        if rpm == 6000
            # ALPHA full load at 6000 rpm sits at 106.5 kPa; the air path reaches 98.8 kPa, so
            # the map gives 126.7 N.m, 8 % under the curve, and the cap never engages.
            @test_broken on_curve && capped
        else
            @test on_curve
            @test capped
        end
    end
    @test 145 <= maximum(wot_torques) <= 155

    tip_in = mapped_engine_run(MappedEngineDynoTransient; scenario = 2, rpm = 2000,
                               pedal_initial = 0.2, pedal_final = 1.0, t_step = 0.5,
                               p_m0 = 40e3)
    tip_tau = tip_in.sol[tip_in.model.engine.tau_e]
    tip_rise = rise_time(tip_in.sol.t, tip_tau, 0.9; t0 = 0.5) -
               rise_time(tip_in.sol.t, tip_tau, 0.1; t0 = 0.5)
    @test 0.01 <= tip_rise <= 0.15

    overrun = mapped_engine_run(MappedEngineDynoTransient; scenario = 1, rpm = 3000,
                                pedal_cmd = 0.0, p_m0 = 13482.4)
    @test overrun.sol(5.0, idxs = overrun.model.engine.tau_e) ≈
          engine_curve("closed_throttle.csv", 3000) rtol = 0.01
    @test overrun.sol(5.0, idxs = overrun.model.engine.mdot_fuel) < 1e-10
    @test overrun.sol(5.0, idxs = overrun.model.engine.mdot_hc) < 1e-10
    @test overrun.sol(5.0, idxs = overrun.model.engine.mdot_co) < 1e-10
    @test overrun.sol(5.0, idxs = overrun.model.engine.mdot_nox) < 1e-10

    # Speed ramp 3000 -> 800 rpm over 1-4 s. The run starts closed above 1300 rpm, where the latch
    # initializes cut, so the fuel is zero from the first sample.
    ramp = mapped_engine_run(MappedEngineDynoTransient; scenario = 3, rpm = 3000,
                             pedal_cmd = 0.0, p_m0 = 13482.4)
    t, rpm_ramp = ramp.sol.t, ramp.sol[ramp.model.engine.N]
    fuel_ramp, tau_ramp = ramp.sol[ramp.model.engine.mdot_fuel], ramp.sol[ramp.model.engine.tau_e]
    @test all(fuel_ramp[rpm_ramp .> 1300] .< 1e-10)
    resume = findfirst(>(1e-7), fuel_ramp)
    @test resume !== nothing && rpm_ramp[resume] < 1000
    @test fuel_ramp[end] > 1e-5
    @test maximum(tau_ramp[resume:end]) <= tau_ramp[end] + 0.5

    booster = mapped_engine_run(MappedEngineTransient; rpm = 800.0, pedal_cmd = 0.0,
                                p_m0 = 32955.7, booster_flow = 0.002,
                                t_booster = 1.0, booster_duration = 0.5)
    booster_rpm = booster.sol[booster.model.engine.crankshaft.w] .* 30 ./ pi
    booster_pm = booster.sol[booster.model.engine.p_m] ./ 1e3
    @test maximum(booster_pm) > 45
    @test minimum(booster_rpm) > 450

    booster_bump = maximum(booster_pm) - booster.sol(1.0, idxs = booster.model.engine.p_m) / 1e3
    @info "Mapped engine acceptance" idle_rpm idle_pm wot_torques tip_rise rpm_ramp[resume] booster_bump extrema(booster_rpm)
end


const MapEngineDynoTransient = VehicleSystemsComponents.HandsOn02.MapEngineDynoTransient

# Hands-on 02's MapEngine held at one pedal for the analysis's 2 s, read at the end.
function map_engine_steady(rpm, pedal, p_m0)
    run = mapped_engine_run(MapEngineDynoTransient; rpm = rpm, pedal_initial = pedal,
                            pedal_final = pedal, t_step = 10.0, p_m0 = p_m0)
    engine, t = run.model.engine, run.sol.t[end]
    return (p_kpa = run.sol(t, idxs = engine.p_m) / 1e3,
            tau = run.sol(t, idxs = engine.torque_map.y),
            fuel_gps = run.sol(t, idxs = engine.mdot_fuel) * 1e3,
            co2_gps = run.sol(t, idxs = engine.mdot_co2) * 1e3)
end

@testset "Hands-on 02 map engine" begin
    closed = map_engine_steady(3000, 0.0, 13482.4)
    @test closed.p_kpa ≈ 13.5 rtol = 0.01
    @test closed.tau ≈ -18.2 rtol = 0.01
    # No fuel cut: the closed-pedal map point still burns what the measured engine burned there.
    @test closed.fuel_gps ≈ 0.097 rtol = 0.01

    wot = map_engine_steady(3000, 1.0, 99.9e3)
    @test wot.p_kpa ≈ 99.9 rtol = 0.01
    @test wot.tau ≈ 148.4 rtol = 0.01
    @test wot.tau ≈ engine_curve("full_load.csv", 3000) rtol = 0.01
    @test wot.fuel_gps ≈ 3.75 rtol = 0.01
    @test wot.co2_gps ≈ 3.09 * wot.fuel_gps rtol = 1e-9

    # Pedals found by bisection on the 2 s dyno torque against the plan's cruise torques. The
    # pedal drives the throttle directly, so they sit below MappedEngine's progressive-pedal ones.
    fuel = read_engine_map("fuel_gps.csv")
    cruise_torques = Float64[]
    for (rpm, pedal, tau_target, p_m0) in ((1710, 0.043754, 18.4, 41.9e3),
                                           (3080, 0.103415, 31.1, 47.8e3),
                                           (4450, 0.190361, 51.0, 60.8e3))
        point = map_engine_steady(rpm, pedal, p_m0)
        push!(cruise_torques, point.tau)
        @test point.tau ≈ tau_target rtol = 0.01
        @test point.fuel_gps ≈ bilinear(fuel, rpm, point.p_kpa) rtol = 0.01
    end

    # The analysis defaults: the 90 km/h cruise point, pedal opened a little at 1 s. The pedal
    # moves the throttle instantly, so the torque rise is the manifold filling alone.
    step = mapped_engine_run(MapEngineDynoTransient)
    step_tau = step.sol[step.model.engine.torque_map.y]
    step_rise = rise_time(step.sol.t, step_tau, 0.9; t0 = 1.0) -
                rise_time(step.sol.t, step_tau, 0.1; t0 = 1.0)
    @test 0.01 <= step_rise <= 0.1

    idle = map_engine_steady(800, 0.0, 33e3)
    @test idle.p_kpa ≈ 33.0 rtol = 0.01

    @info "Hands-on 02 map engine" closed wot cruise_torques step_rise idle
end

const AirPathStep = VehicleSystemsComponents.HandsOn02.AirPathStep
const AirPathStepTransient = VehicleSystemsComponents.HandsOn02.AirPathStepTransient

# The step 02 bench's pressure in kPa just before its throttle step at 1 s and at the end.
function air_path_step_kpa(; kwargs...)
    run = mapped_engine_run(AirPathStepTransient;
                            model = AirPathStep(; name = :AirPathStep, kwargs...))
    p_m = run.model.manifold.p_m
    return (before = run.sol(0.999, idxs = p_m) / 1e3, after = run.sol[p_m][end] / 1e3)
end

@testset "Hands-on 02 manifold" begin
    idle = air_path_step_kpa()
    @test idle.before ≈ 33.0 atol = 0.05
    @test idle.after ≈ 37.3 atol = 0.05

    open_3000 = air_path_step_kpa(speed__k = 314.159, throttle_cmd__height = 1.0)
    @test open_3000.before ≈ 13.5 atol = 0.05
    @test open_3000.after ≈ 99.9 atol = 0.05
end

@testset "Hands-on 02 cruise table" begin
    # Steps 01 and 05: the cruise points read off the maps at the hands-on car's speed and
    # holding torque, to the digits the page shows. Petrol 745 g/L; CO2 3.09 x fuel.
    torque, fuel = read_engine_map("torque_Nm.csv"), read_engine_map("fuel_gps.csv")
    for (kmh, rpm, tau, p_kpa, gps, lph, l100, co2) in
        ((50, 1710, 18.4, 41.9, 0.346, 1.67, 3.3, 77),
         (90, 3080, 31.1, 47.8, 0.850, 4.11, 4.6, 105),
         (130, 4450, 51.0, 60.8, 1.892, 9.14, 7.0, 162))
        lo, hi = 0.0, 105.0
        for _ in 1:60
            mid = (lo + hi) / 2
            bilinear(torque, rpm, mid) < tau ? (lo = mid) : (hi = mid)
        end
        fuel_gps = bilinear(fuel, rpm, lo)
        fuel_lph = fuel_gps * 3600 / 745
        @test round(lo; digits = 1) == p_kpa
        @test round(fuel_gps; digits = 3) == gps
        @test round(fuel_lph; digits = 2) == lph
        @test round(fuel_lph / kmh * 100; digits = 1) == l100
        @test round(3.09 * fuel_gps / (kmh / 3.6) * 1000) == co2
    end
end

const MapEngineFuelCutDynoTransient = VehicleSystemsComponents.HandsOn02.MapEngineFuelCutDynoTransient

@testset "Hands-on 02 fuel cut" begin
    # Step 03 E: released from wide open at 1 s and 3000 rpm; from 2 s the dyno ramps the speed
    # down to 800 rpm over 3 s.
    release = mapped_engine_run(MapEngineFuelCutDynoTransient; rpm = 3000, pedal_initial = 1.0,
                                pedal_final = 0.0, p_m0 = 99889.9, stop = 6.0)
    engine, sol = release.model.engine, release.sol
    t, fuel = sol.t, sol[engine.mdot_fuel]
    rpm = sol[engine.speed.w] .* 30 ./ pi

    fired_fuel = sol(0.99, idxs = engine.mdot_fuel)
    @test sol(0.99, idxs = engine.torque_map.y) ≈ 148.4 rtol = 0.01
    @test fired_fuel * 1e3 ≈ 3.75 rtol = 0.01

    t_cut = t[findfirst(k -> t[k] > 1.0 && fuel[k] < 0.01 * fired_fuel, eachindex(t))] - 1.0
    @test t_cut ≈ 0.03 atol = 0.005
    tau_cut = sol(2.0, idxs = engine.torque_map.y)
    @test sol(2.0, idxs = engine.mdot_fuel) < 1e-10
    @test tau_cut ≈ -18.7 rtol = 0.01
    @test tau_cut ≈ engine_curve("closed_throttle.csv", 3000) rtol = 0.01
    @test sol(2.0, idxs = engine.p_m) / 1e3 ≈ 13.5 rtol = 0.01

    # During the cut the torque is the closed-throttle curve at any pressure, so MappedEngine,
    # whose throttle actuator closes 50 ms later, ends on the same torque.
    course = mapped_engine_run(MappedEngineDynoTransient; scenario = 2, rpm = 3000,
                               pedal_initial = 1.0, pedal_final = 0.0, t_step = 1.0,
                               p_m0 = 99889.9)
    @test course.sol(2.0, idxs = course.model.engine.tau_e) ≈ tau_cut rtol = 1e-6

    after = t .> 1.2
    @test all(fuel[after .& (rpm .> 1000)] .< 1e-7)
    resume = findfirst(k -> after[k] && fuel[k] > 1e-7, eachindex(t))
    @test resume !== nothing
    @test 990 < rpm[resume] < 1000
    @test t[resume] ≈ 4.73 atol = 0.01
    @test sol(t[resume], idxs = engine.p_m) / 1e3 ≈ 27.0 rtol = 0.01

    idle = (p_kpa = sol(6.0, idxs = engine.p_m) / 1e3,
            fuel_gps = sol(6.0, idxs = engine.mdot_fuel) * 1e3,
            tau = sol(6.0, idxs = engine.torque_map.y))
    @test idle.p_kpa ≈ 33.0 rtol = 0.01
    @test idle.fuel_gps ≈ 0.096 rtol = 0.01
    @test abs(idle.tau) < 1.0

    # Runs 1 and 2 on the bench after the paste. Run 1 never closes the pedal and ends before
    # the ramp, so it is unchanged; run 2 starts closed above 1300 rpm, so it starts cut.
    run1 = mapped_engine_run(MapEngineFuelCutDynoTransient)
    @test run1.sol(2.0, idxs = run1.model.engine.p_m) ≈ 52944.0 atol = 10.0
    @test run1.sol(2.0, idxs = run1.model.engine.torque_map.y) ≈ 41.3722 atol = 0.01
    run2 = mapped_engine_run(MapEngineFuelCutDynoTransient; rpm = 3000, pedal_initial = 0.0,
                             pedal_final = 1.0, p_m0 = 13482.4)
    @test run2.sol(0.99, idxs = run2.model.engine.mdot_fuel) < 1e-10
    @test run2.sol(0.99, idxs = run2.model.engine.torque_map.y) ≈ tau_cut rtol = 1e-6
    @test run2.sol(2.0, idxs = run2.model.engine.torque_map.y) ≈ 148.4 rtol = 0.01

    @info "Hands-on 02 fuel cut" t_cut tau_cut rpm[resume] t[resume] idle
end

const HandsOn02Car = VehicleSystemsComponents.HandsOn02

# A run's signals on a uniform 1 ms grid, so event times below resolve to the millisecond.
function car_signals(run)
    car, sol = run.model.car, run.sol
    t = collect(range(0.0, sol.t[end]; step = 0.001))
    read(sym) = sol(t, idxs = sym).u
    return (t = t, v = read(car.v_kmh), rpm = read(car.flywheel.w) .* 30 ./ pi,
            p_kpa = read(car.p_m) ./ 1e3, fuel = read(car.fuel_lph),
            cut = read(car.engine.cut_logic.cut), slip = read(car.driveline.clutch.w_slip),
            capacity = read(car.driveline.clutch.tau_capacity),
            ratio = read(car.driveline.variator.ratio), a = read(car.body.mass.a))
end

@testset "Hands-on 02 CVT" begin
    # Step 04: pedal floored from rest, engine idling at 900 rpm behind the open clutch.
    run = mapped_engine_run(HandsOn02Car.MappedCarWOTTransient; stop = 300.0)
    s = car_signals(run)
    @test string(run.sol.retcode) == "Success"
    @test s.t[end] == 300.0

    # The clutch slips while it engages, holding the engine near its 1300 rpm ramp center.
    at(x, time) = x[round(Int, time / 0.001) + 1]
    @test at(s.rpm, 0.5) ≈ 1300 atol = 5
    @test at(s.rpm, 1.0) ≈ 1300 atol = 5
    lock = findfirst(i -> s.t[i] > 0.1 && abs(s.slip[i]) < 1.0 && s.capacity[i] > 200.0,
                     eachindex(s.t))
    @test s.t[lock] ≈ 1.33 atol = 0.05
    @test s.v[lock] ≈ 13.7 atol = 0.05
    @test s.rpm[lock] ≈ 1414 atol = 5
    @test all(abs.(s.slip[lock:end]) .< 1.0)

    t100 = s.t[findfirst(>=(100.0), s.v)]
    @test t100 ≈ 10.43 atol = 0.05
    @test at(s.v, 60.0) ≈ 196.6 atol = 0.2
    @test at(s.v, 120.0) ≈ 204.9 atol = 0.2
    @test s.v[end] ≈ 205.33 atol = 0.1
    @test abs(s.a[end]) < 1e-4
    @test s.rpm[end] ≈ 6000 atol = 10
    @test at(s.ratio, 300.0) ≈ 3.41 atol = 0.01
    # At top speed the wide-open engine's power is what drag and rolling take, lossless CVT.
    car, sol = run.model.car, run.sol
    tau_top = sol(300.0, idxs = car.engine.torque_map.y)
    road_n = 0.5 * 1.2 * 0.63 * (s.v[end] / 3.6)^2 + 0.012 * 1400 * 9.80665
    @test tau_top ≈ 126.5 atol = 0.2
    @test tau_top * s.rpm[end] * pi / 30 ≈ road_n * s.v[end] / 3.6 rtol = 1e-3

    # Until about 58 km/h the ratio sits at its 12.0 launch stop, so the engine runs past the
    # 6000 rpm target; it peaks short of the 6500 rpm limiter, and the fuel is never cut.
    @test maximum(s.rpm) ≈ 6393 atol = 15
    @test s.t[argmax(s.rpm)] ≈ 6.37 atol = 0.05
    @test maximum(s.rpm) < 6500.0
    @test maximum(s.cut) < 1e-3
    @test minimum(s.rpm) >= 899.0

    metrics = (; lock_t = s.t[lock], lock_kmh = s.v[lock], lock_rpm = s.rpm[lock], t100,
               v60 = at(s.v, 60.0), v120 = at(s.v, 120.0), top = s.v[end], rpm_top = s.rpm[end],
               rpm_max = maximum(s.rpm), t_rpm_max = s.t[argmax(s.rpm)], ratio_top = s.ratio[end],
               fuel_top = s.fuel[end], p_top = s.p_kpa[end], tau_top)
    @info "Hands-on 02 CVT" metrics
end

@testset "Vehicle road brake" begin
    run = mapped_engine_run(VehicleSystemsComponents.Vehicle.RoadBrakeTransient)
    sol, m = run.sol, run.model
    for body in (m.body, m.swapped_body)
        @test sol(1.0, idxs = body.v) ≈ 10 - 4000 / 1400 rtol = 1e-3
        @test abs(sol(6.0, idxs = body.v)) < 1e-3
        @test minimum(sol[body.v]) > -1e-3
    end
end

@testset "Hands-on 02 CVT cruise" begin
    # Step 05: the CVT car started steady; each speed's pedal holds it within 0.25 km/h for 60 s.
    # Petrol 745 g/L, CO2 3.09 x fuel, so 2302 g CO2 per liter.
    fuel_map = read_engine_map("fuel_gps.csv")
    measured = NamedTuple[]
    for (kmh, pedal, rpm0, p_m0, rpm, ratio, p_kpa, lph, l100, co2, fixed_l100) in
        ((50, 0.04878, 1992, 40100, 1992, 4.64, 40.1, 1.84, 3.7, 85, 3.3),
         (90, 0.0916, 2182, 54420, 2182, 2.83, 54.4, 3.55, 3.9, 91, 4.6),
         (130, 0.17373, 3118, 67220, 3118, 2.80, 67.2, 7.78, 6.0, 138, 7.0))
        run = mapped_engine_run(HandsOn02Car.MappedCarCruiseTransient; speed_kmh = kmh,
                                pedal_cmd = pedal, rpm0 = rpm0, p_m0 = p_m0)
        s = car_signals(run)
        @test string(run.sol.retcode) == "Success"
        @test maximum(abs.(s.v .- kmh)) < 0.25
        v, fuel = s.v[end], s.fuel[end]
        @test round(s.rpm[end]) ≈ rpm atol = 2
        @test round(s.ratio[end]; digits = 2) == ratio
        @test round(s.p_kpa[end]; digits = 1) == p_kpa
        @test round(fuel; digits = 2) == lph
        # The fuel map read at the CVT's operating point predicts the car's fuel flow.
        @test fuel * 745 / 3600 ≈ bilinear(fuel_map, s.rpm[end], s.p_kpa[end]) rtol = 0.01
        @test round(fuel / v * 100; digits = 1) == l100
        @test round(fuel * 2302 / v) == co2
        # Above 50 km/h the CVT runs the engine slower and less throttled than the fixed gear;
        # at 50 km/h its 1800 rpm floor runs it faster.
        @test (fuel / v * 100 > fixed_l100) == (kmh == 50)
        push!(measured, (; kmh, v, rpm = s.rpm[end], ratio = s.ratio[end], p_kpa = s.p_kpa[end],
                         lph = fuel, l100 = fuel / v * 100, co2 = fuel * 2302 / v))
    end
    @info "Hands-on 02 CVT cruise" measured
end

@testset "Hands-on 02 CVT coast and brake" begin
    # Step 06 A: pedal released at 5 s from the 90 km/h cruise.
    coast = car_signals(mapped_engine_run(HandsOn02Car.MappedCarCoastTransient))
    after = coast.t .> 5.0
    cut_on = findfirst(i -> after[i] && coast.cut[i] > 0.5, eachindex(coast.t))
    resume = findfirst(i -> i > cut_on && coast.cut[i] < 0.5, eachindex(coast.t))
    opens = findfirst(i -> coast.t[i] > 6.0 && abs(coast.slip[i]) > 1.0, eachindex(coast.t))
    rest = findfirst(i -> after[i] && coast.v[i] < 0.1, eachindex(coast.t))
    @test coast.fuel[4990] ≈ 3.55 atol = 0.005
    @test coast.t[cut_on] - 5.0 < 0.01
    # The cut fades the fuel out over the latch's 10 ms, so it is gone within 0.2 s.
    @test maximum(coast.fuel[5200:resume-50]) < 1e-6
    @test minimum(coast.p_kpa[after]) ≈ 17.1 atol = 0.1
    @test coast.a[5500] ≈ -0.39 atol = 0.01
    # Below 75 km/h the ratio climbs and holds the engine just under the 1800 rpm floor.
    band = findall(i -> after[i] && 30 < coast.v[i] < 70, eachindex(coast.t))
    @test all(1725 .< coast.rpm[band] .< 1780)
    @test coast.t[opens] ≈ 66.0 atol = 0.1
    @test coast.v[opens] ≈ 11.2 atol = 0.2
    @test coast.rpm[opens] ≈ 1140 atol = 10
    @test opens < resume
    @test coast.t[resume] ≈ 66.3 atol = 0.1
    @test coast.v[resume] ≈ 10.8 atol = 0.2
    @test 990 < coast.rpm[resume] < 1000
    @test coast.p_kpa[resume] ≈ 27.4 atol = 0.2
    @test coast.t[rest] ≈ 91.5 atol = 0.2
    @test coast.rpm[end] ≈ 775 atol = 2
    @test coast.p_kpa[end] ≈ 33.6 atol = 0.1
    @test coast.fuel[end] ≈ 0.47 atol = 0.005
    @test minimum(coast.rpm[after]) > 770

    # Step 06 B: the same release with 4000 N of brake from 5 s, to rest and held there.
    stop = car_signals(mapped_engine_run(HandsOn02Car.MappedCarBrakeStopTransient))
    after = stop.t .> 5.0
    braking = findall(i -> 5.2 < stop.t[i] < 10.0, eachindex(stop.t))
    @test all(-3.25 .< stop.a[braking] .< -3.1)
    t25 = stop.t[findfirst(i -> after[i] && stop.v[i] < 25.0, eachindex(stop.t))]
    stopped = findfirst(i -> after[i] && stop.v[i] < 0.1, eachindex(stop.t))
    @test t25 ≈ 10.69 atol = 0.02
    @test stop.t[stopped] ≈ 12.94 atol = 0.02
    @test maximum(stop.p_kpa[stop.t .> 5.2]) < 34.0
    @test minimum(stop.p_kpa[after]) ≈ 17.6 atol = 0.1
    refuel = findfirst(i -> stop.t[i] > 5.1 && stop.cut[i] < 0.5, eachindex(stop.t))
    release = findfirst(i -> stop.t[i] > 6.0 && abs(stop.slip[i]) > 1.0, eachindex(stop.t))
    @test stop.t[refuel] ≈ 11.97 atol = 0.02
    @test stop.v[refuel] ≈ 10.4 atol = 0.2
    @test stop.t[release] ≈ 12.0 atol = 0.02
    @test minimum(stop.rpm[after]) > 770
    @test stop.rpm[end] ≈ 775 atol = 2
    @test all(abs.(stop.v[stopped:end]) .< 0.1)
    @test abs(stop.v[end]) < 1e-3

    coast_events = (; cut = coast.t[cut_on], p_min = minimum(coast.p_kpa[coast.t .> 5]),
                    a_release = coast.a[5500], rpm_band = extrema(coast.rpm[band]),
                    clutch_opens = (coast.t[opens], coast.v[opens], coast.rpm[opens]),
                    fuel_back = (coast.t[resume], coast.v[resume], coast.rpm[resume],
                                 coast.p_kpa[resume]),
                    at_rest = coast.t[rest])
    stop_events = (; a = extrema(stop.a[braking]), t25, at_rest = stop.t[stopped],
                   p_range = (minimum(stop.p_kpa[after]), maximum(stop.p_kpa[stop.t .> 5.2])),
                   fuel_back = (stop.t[refuel], stop.v[refuel], stop.rpm[refuel],
                                stop.p_kpa[refuel]),
                   clutch_opens = (stop.t[release], stop.v[release], stop.rpm[release]))
    @info "Hands-on 02 CVT coast and brake" coast_events stop_events
end


# Share of samples inside the WLTC tolerance: ±2 km/h around the trace's extremes within ±1 s.
function wltc_band_share(sol, m, T)
    t = 0.0:0.1:T
    speed = vec(Array(sol(t, idxs = m.car.v_kmh)))
    target = vec(Array(sol(t, idxs = m.trace.y)))
    window(i) = max(1, i - 10):min(length(t), i + 10)
    inside = [minimum(target[window(i)]) - 2 <= speed[i] <= maximum(target[window(i)]) + 2
              for i in eachindex(t)]
    return count(inside) / length(t), maximum(abs.(speed .- target))
end

wltc_label(sol, m, T) = (km = sol(T, idxs = m.dist_km.y),
                    l_per_100km = 100 * sol(T, idxs = m.fuel_L.y) / sol(T, idxs = m.dist_km.y))

@testset "Hands-on 02 WLTC bonus" begin
    low_medium = mapped_engine_run(HandsOn02Car.MappedCarWLTCLowMediumTransient)
    sol, m = low_medium.sol, low_medium.model
    @test string(sol.retcode) == "Success"
    @test wltc_label(sol, m, 1022.0).km ≈ 7.853 atol = 5e-3
    @test wltc_label(sol, m, 1022.0).l_per_100km ≈ 5.593 atol = 5e-3
    @test wltc_band_share(sol, m, 1022.0)[1] ≈ 0.9858 atol = 2e-3

    full = mapped_engine_run(HandsOn02Car.MappedCarWLTCTransient)
    sol, m = full.sol, full.model
    figures = wltc_label(sol, m, 1800.0)
    band, max_error = wltc_band_share(sol, m, 1800.0)
    @test string(sol.retcode) == "Success"
    @test figures.km ≈ 23.270 atol = 5e-3
    @test figures.l_per_100km ≈ 5.218 atol = 5e-3
    @test 2302 * figures.l_per_100km / 100 ≈ 120.1 atol = 0.05
    @test band ≈ 0.9846 atol = 2e-3
    @info "Hands-on 02 WLTC bonus" figures band max_error
end
