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
        capped = run.sol(5.0, idxs = run.model.engine.torque_map.y) >=
                 run.sol(5.0, idxs = run.model.engine.full_load.y)
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

    # Speed ramp 3000 -> 800 rpm over 1-4 s. The cut latch starts fueled, so skip its first 0.5 s.
    ramp = mapped_engine_run(MappedEngineDynoTransient; scenario = 3, rpm = 3000,
                             pedal_cmd = 0.0, p_m0 = 13482.4)
    t, rpm_ramp = ramp.sol.t, ramp.sol[ramp.model.engine.N]
    fuel_ramp, tau_ramp = ramp.sol[ramp.model.engine.mdot_fuel], ramp.sol[ramp.model.engine.tau_e]
    latched = t .>= 0.5
    @test all(fuel_ramp[latched .& (rpm_ramp .> 1300)] .< 1e-10)
    resume = findfirst(k -> latched[k] && fuel_ramp[k] > 1e-7, eachindex(t))
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
