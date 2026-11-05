# Lecture 5 best-BSFC operating line (scripts/bsfc_line.jl), the line the CVT holds the engine on.

include("../scripts/bsfc_line.jl")
using .BsfcLine

const LINE_ROWS = [parse.(Float64, split(l, ',')) for l in readlines(LINE_FILE)[2:end]]

@testset "Lecture 5 best-BSFC line" begin
    m = load_maps()
    rows = LINE_ROWS
    power, rpm, torque, bsfc = (getindex.(rows, k) for k in 1:4)

    @testset "the committed file is what the script writes" begin
        @test read(LINE_FILE, String) == render_line(operating_line(m))
    end

    @testset "speed rises with power, idle to peak" begin
        @test all(diff(power) .> 0)
        @test issorted(rpm)
        @test rpm[end] > rpm[1]
        @test first(power) == 1.0
        peak = maximum(n -> power_kw(n, reachable_torque(m, n)), BsfcLine.SPEEDS)
        @test last(power) ≈ peak atol = 1e-3
        @test RPM_IDLE <= first(rpm) && last(rpm) <= RPM_MAX
    end

    @testset "every point is a reachable operating point" begin
        @test all(isapprox.(power_kw.(rpm, torque), power; rtol = 1e-4))
        @test all(torque .<= reachable_torque.(Ref(m), rpm) .+ 1e-3)
    end

    # Once on the full-load curve the line stays on it up to peak power: each row is the lowest
    # grid speed that reaches its power, so a speed command tracking it has no step there.
    @testset "the top of the line follows full load without a step" begin
        step = BsfcLine.RPM_STEP
        on_fl = [n > RPM_IDLE && torque_for(P, n - step) > reachable_torque(m, n - step)
                 for (P, n) in zip(power, rpm)]
        k = findfirst(on_fl)
        @test k !== nothing && k < length(power) && all(on_fl[k:end])
        @test maximum(diff(rpm[k:end])) <= 200
    end

    # A sample of the map independent of `bsfc_at`: torque and fuel interpolated bilinearly
    # straight from the tables, at the search's own 5 rpm speeds and every 0.1 kPa of p_m, under
    # full load. Every sample is a point the search scores exactly, so none may be below its
    # minimum; the sample comes within its p_m resolution of it.
    @testset "the line reaches the map's minimum BSFC [g/kWh]" begin
        fl(n) = BsfcLine.lin(m.fl_rpm, m.fl_T, n)
        bilinear(Z, n, p) = begin
            i = clamp(searchsortedlast(m.rpm, n), 1, length(m.rpm) - 1)
            j = clamp(searchsortedlast(m.kpa, p), 1, length(m.kpa) - 1)
            s = (n - m.rpm[i]) / (m.rpm[i+1] - m.rpm[i])
            t = (p - m.kpa[j]) / (m.kpa[j+1] - m.kpa[j])
            (1 - s) * ((1 - t) * Z[i, j] + t * Z[i, j+1]) +
                s * ((1 - t) * Z[i+1, j] + t * Z[i+1, j+1])
        end
        sample_min = minimum(BsfcLine.SPEEDS) do n
            minimum(first(m.kpa):0.1:last(m.kpa); init = Inf) do p
                T = bilinear(m.torque, n, p)
                0 < T <= fl(n) ? bilinear(m.fuel, n, p) * 3600 / power_kw(n, T) : Inf
            end
        end
        best = global_min_bsfc(m)
        line_min = minimum(bsfc)
        @info "Best-BSFC line" sample_min best line_min
        @test best.bsfc <= sample_min + 1e-6
        @test sample_min - best.bsfc < 0.1
        # 1 kW power steps and 5 rpm speed steps leave the line just above the true minimum.
        @test line_min - best.bsfc < 0.5
        @test line_min >= best.bsfc - 0.01
        @test 225 <= line_min <= 260
    end
end

using DyadInterface: symbolic_container

const _K0 = VehicleSystemsComponents.Vehicle

function _k0_run(; command = 1.0, demand = 100.0, slip_start = 100.0)
    bench = _K0.TestDisconnectClutch(; name = :bench, command, demand, slip_start)
    return _K0.DisconnectClutchTransient(model = bench)
end

@testset "Lecture 5: K0 actuator and torque capacity" begin
    run = _k0_run()
    m, s = symbolic_container(run), run.sol
    T = s.ps[m.clutch.actuator_time]
    peak_rows = split.(readlines(joinpath(@__DIR__, "../data/engine/full_load.csv"))[2:end], ',')
    peak = maximum(parse(Float64, row[2]) for row in peak_rows)
    capacity = s[m.clutch.tau_capacity][end]
    nominal = s.ps[m.clutch.tau_max]
    @test nominal == 230.0
    @test capacity >= 1.5 * peak
    @test s[m.clutch.position][1] == 0.0
    @test s(0.1 + T * log(10), idxs = m.clutch.position) ≈ 0.9 atol = 1e-4
    rise = rise_time(s.t, s[m.clutch.position], 0.9; t0 = 0.1)
    @test rise <= 0.35
    @test all(0 .<= s[m.clutch.capacity_fraction] .<= 1)
    @test all(s[m.clutch.tau] .* s[m.clutch.w_slip] .>= 0)
    # Both free inertias accelerate together; transmitted torque is demand * J_load / J_total.
    expected_tau = 100.0 * 1.5 / (1.5 + 0.15)
    @test s[m.clutch.tau][end] ≈ expected_tau atol = 1e-5
    @test abs(s[m.clutch.w_slip][end]) < 1.0
    @test s[m.clutch.w_slip][end] ≈
        s.ps[m.clutch.w_regularization] * atanh(expected_tau / capacity) atol = 1e-6
    println("K0: peak=$(peak) N.m, nominal=$(nominal) N.m, capacity=$(capacity) N.m, " *
        "t90=$(rise) s, slip=$(s[m.clutch.w_slip][end]) rad/s")
end

@testset "Lecture 5: K0 open over signed slip through 300 rad/s" begin
    max_open = 0.0
    for slip in (-300.0, -100.0, 0.0, 100.0, 300.0)
        run = _k0_run(command = 0.0, demand = 0.0, slip_start = slip)
        m, s = symbolic_container(run), run.sol
        torque = maximum(abs, s[m.clutch.tau])
        max_open = max(max_open, torque)
        @test torque < 1.0
        @test s[m.clutch.w_slip][1] ≈ slip atol = 1e-10
        @test maximum(abs, s[m.clutch.w_slip]) <= 300.0 + 1e-8
        @test all(s[m.clutch.position] .== 0)
    end
    println("K0: maximum open torque=$(max_open) N.m")
end

@testset "Lecture 5: K0 near-lock under mapped-engine peak demand" begin
    run = _k0_run(demand = 150.234)
    m, s = symbolic_container(run), run.sol
    @test abs(s[m.clutch.w_slip][end]) < 1.0
    @test abs(s[m.clutch.tau][end]) < s[m.clutch.tau_capacity][end]
    @test s[m.clutch.tau][end] ≈ 150.234 / 1.1 atol = 1e-5
    println("K0: peak-demand settled slip=$(s[m.clutch.w_slip][end]) rad/s")
end


@testset "SoC-corrected fuel" begin
    _V = VehicleSystemsComponents.Vehicle
    function soc_fuel_end(; P)
        bench = _V.TestSoCCorrectedFuel(; name = :bench, P)
        run = _V.SoCCorrectedFuelTransient(model = bench)
        m, s = symbolic_container(run), run.sol
        y(x) = s[x][end]
        return (; raw = y(m.meter.fuel_raw), E_MJ = y(m.meter.E_batt_MJ),
            corr = y(m.meter.fuel_corr), energy = y(m.meter.energy_corr),
            first = (s[m.meter.fuel_raw][1], s[m.meter.fuel_corr][1], s[m.meter.energy_corr][1]))
    end

    # Hand calculation, 1 g/s of fuel, 1 kW out of the battery's store and 20 m/s for 500 s:
    # 10 km, 0.5 kg of fuel = 0.5 / 0.745 L, 0.5 MJ from the battery at eta_eb = 0.30.
    km = 20.0 * 500.0 / 1000.0
    fuel_L = 0.5 / 0.745
    eq_L = 0.5 / (0.30 * 43.4) / 0.745
    raw = fuel_L / km * 100.0
    corr = (fuel_L + eq_L) / km * 100.0
    @test raw ≈ 6.7114 atol = 1e-4
    @test corr ≈ 7.2269 atol = 1e-4

    drawn = soc_fuel_end(P = 1000.0)
    # The standstill guard sqrt(s^2 + d_reg^2) moves 10 km by 5e-9 of itself.
    @test drawn.raw ≈ raw rtol = 1e-7
    @test drawn.E_MJ ≈ 0.5 rtol = 1e-7
    @test drawn.corr ≈ corr rtol = 1e-7
    @test drawn.energy ≈ corr * 0.745 * 43.4 rtol = 1e-7
    @test all(iszero, drawn.first)

    # No net battery energy: raw and corrected consumption agree within 1e-10 L/100 km.
    neutral = soc_fuel_end(P = 0.0)
    @test neutral.E_MJ == 0.0
    @test neutral.corr ≈ neutral.raw atol=1e-10
    @test neutral.raw ≈ raw rtol = 1e-7

    # Ending with less charge charges more fuel to the run; ending with more, less.
    charged = soc_fuel_end(P = -1000.0)
    @test charged.E_MJ ≈ -0.5 rtol = 1e-7
    @test drawn.corr > neutral.corr > charged.corr
    @test drawn.corr - neutral.corr ≈ neutral.corr - charged.corr rtol = 1e-7

    # A real battery cycled back to its start SoC: the stored energy nets to zero while
    # R0 i^2 burns 0.1 * 100^2 / 2 * 500 = 0.25 MJ, which terminal energy would have credited.
    run = _V.SoCCorrectedFuelBatteryTransient()
    m, s = symbolic_container(run), run.sol
    E_R0 = s[m.E_R0][end] / 1e6
    @test E_R0 ≈ 0.25 rtol = 1e-6
    @test s[m.battery.SoC][end] ≈ s[m.battery.SoC][1] atol = 1e-9
    @test abs(s[m.meter.E_batt_MJ][end]) < 1e-6 * E_R0
    @test s[m.E_dc][end] / 1e6 ≈ -E_R0 rtol = 1e-6
    @test s[m.meter.fuel_corr][end] ≈ s[m.meter.fuel_raw][end] rtol = 1e-8
    println("SoC-corrected fuel, cycled battery: E_batt = $(s[m.meter.E_batt_MJ][end]) MJ, ",
        "R0 loss = $E_R0 MJ, terminal = $(s[m.E_dc][end] / 1e6) MJ, ",
        "raw = $(s[m.meter.fuel_raw][end]), corrected = $(s[m.meter.fuel_corr][end]) L/100 km")
end


@testset "hybrid drive" begin
    run = VehicleSystemsComponents.Lecture5.HybridDriveDynoTransient()
    @test string(run.sol.retcode) == "Success"
    d = symbolic_container(run).drive
    ps = run.sol.ps
    @test ps[d.machine.T_max] == 205.0
    @test ps[d.machine.w_base] * 30 / pi ≈ 1397.458 atol = 0.001
    @test ps[d.machine.V_nom] == 270.0
    @test ps[d.battery.E] * ps[d.battery.Q_nom] / 3.6e6 ≈ 1.4 rtol = 0.05
    @test run.sol[d.SoC][1] ≈ 0.6
    @test ps[d.battery.R0] ≈ 0.1 * 270 / 350
    @test ps[d.reduction.ratio] == 1.0
    # Independent Leaf-based scaling and the unchanged machine's quadratic design equation.
    scale = 30 / 110
    R = 0.05 * (270 / 350)^2 / scale
    w = 30e3 / 205
    losses = (0.5 + 1.0) * scale + 300 / (10100pi / 30)^3 * scale * w^2 + 200scale / w
    k = (270 + sqrt(270^2 - 4w * R * (205 + losses))) / (2w)
    for (p, expected) in ((d.machine.R, R), (d.machine.L, 0.01R),
            (d.machine.J, 0.05scale), (d.machine.T_f, 0.5scale),
            (d.machine.K_i, scale), (d.machine.k_w, 300 / (10100pi / 30)^3 * scale),
            (d.machine.C, 200scale), (d.machine.tau_loss_base, losses), (d.machine.k, k),
            (d.converter.I_max, (205 + losses) / k))
        @test ps[p] ≈ expected rtol = 1e-12
    end
    ts = collect(0.5:0.01:22.0)
    at(x) = run.sol(ts, idxs = x).u
    torque, power = at(d.machine.tau), at(d.machine.P_mech)
    rpm, field = at(d.machine.w) .* (30 / pi), at(d.converter.field)
    @test maximum(torque) ≈ 205.0 rtol = 0.05
    @test maximum(power) ≈ 30e3 rtol = 0.05
    # Report a reproducible loaded corner: first sample with >0.1% field weakening.
    corner = something(findfirst(<(0.999), field), lastindex(rpm)) |> i -> rpm[i]
    @test 1300 < corner < 1450
    @info "30 kW hybrid envelope" peak_torque=maximum(torque) peak_power=maximum(power) nominal_corner_rpm=ps[d.w_base]*30/pi loaded_corner_rpm=corner energy_kWh=ps[d.battery.E]*ps[d.battery.Q_nom]/3.6e6
    for rpm0 in (200, 700, 1400, 2000, 3000, 4000)
        t = rpm0 == 4000 ? 22.0 : rpm0 == 200 ? 0.5 : 1 + (rpm0 - 200) / 190
        @info "30 kW dyno" rpm=rpm0 torque=run.sol(t, idxs=d.machine.tau) power=run.sol(t, idxs=d.machine.P_mech)
    end
    # Algebraic residual follows the default relative solver tolerance (about 1e-6).
    @test all(isapprox.(at(d.converter.P_in), at(d.converter.P_out) .+ at(d.converter.P_loss); rtol=1e-5))
    @test all(isapprox.(at(d.battery.v), ps[d.battery.E] .- ps[d.battery.R0] .* at(d.battery.i); atol=1e-8))
    @test run.sol[d.SoC][end] < run.sol[d.SoC][1]
    # Held final speed removes rotor acceleration and electrical storage terms.
    t = 22.0
    value(x) = run.sol(t, idxs=x)
    @test value(d.machine.P_elec) ≈ value(d.machine.P_mech) + value(d.machine.P_loss) rtol=1e-8

    # ICCT-2022 Fig. 6 compares 15 kW positions. Halve torque, not speed, to keep the
    # transmission-input speed range fixed; this is a sizing comparison, not a measured map.
    small = VehicleSystemsComponents.Lecture5.HybridDriveDynoTransient(P_rated=15e3, T_max=102.5)
    @test string(small.sol.retcode) == "Success"
    s = symbolic_container(small).drive
    @test small.sol.ps[s.machine.w_base] ≈ ps[d.machine.w_base]
    @test small.sol.ps[s.machine.T_max] == 102.5
    @test small.sol.ps[s.machine.C] ≈ ps[d.machine.C] / 2
    @test small.sol.ps[s.machine.R] ≈ 2 * ps[d.machine.R]
    @test small.sol.ps[s.converter.I_max] ≈ ps[d.converter.I_max] / 2
    @test small.sol.ps[s.battery.E] * small.sol.ps[s.battery.Q_nom] / 3.6e6 ≈ 1.4
    small_torque = small.sol(ts, idxs=s.machine.tau).u
    small_power = small.sol(ts, idxs=s.machine.P_mech).u
    small_rpm = small.sol(ts, idxs=s.machine.w).u .* (30 / pi)
    small_field = small.sol(ts, idxs=s.converter.field).u
    @test maximum(small_torque) ≈ 102.5 rtol=0.05
    @test maximum(small_power) ≈ 15e3 rtol=0.05
    small_corner = something(findfirst(<(0.999), small_field), lastindex(small_rpm)) |> i -> small_rpm[i]
    @test 1300 < small_corner < 1450
    @info "15 kW hybrid envelope" peak_torque=maximum(small_torque) peak_power=maximum(small_power) loaded_corner_rpm=small_corner
    for rpm0 in (200, 700, 1400, 2000, 3000, 4000)
        t = rpm0 == 4000 ? 22.0 : rpm0 == 200 ? 0.5 : 1 + (rpm0 - 200) / 190
        @info "15 kW dyno" rpm=rpm0 torque=small.sol(t, idxs=s.machine.tau) power=small.sol(t, idxs=s.machine.P_mech)
    end
end


@testset "P2 powertrain" begin
    @testset "HandsOn05 sources stay in sync" begin
        for (name, original) in (("P2Powertrain", "Vehicle"), ("P2WLTC", "Lecture5"))
            source(folder) = read(joinpath(@__DIR__, "..", "dyad", folder, name * ".dyad"), String)
            normalize(text) = replace(text,
                "VehicleSystemsComponents.HandsOn05.P2Powertrain" => "VehicleSystemsComponents.Vehicle.P2Powertrain",
                "VehicleSystemsComponents.HandsOn05.P2WLTC" => "VehicleSystemsComponents.Lecture5.P2WLTC")
            @test normalize(source("HandsOn05")) == normalize(source(original))
        end
    end
    for (electric, analysis, stop) in (
        (false, VehicleSystemsComponents.Lecture5.P2EngineWLTCTransient, 1800.0),
        (true, VehicleSystemsComponents.Lecture5.P2ElectricWLTCTransient, 589.0))
        run = analysis()
        m, s = symbolic_container(run), run.sol
        @test string(s.retcode) == "Success"
        @test s.t[end] == stop
        speed_error = maximum(abs, 3.6 .* s[m.car.bus.vx] .- s[m.trace.y])
        trace_distance = sum(diff(s.t) .* (s[m.trace.y][1:end-1] .+ s[m.trace.y][2:end])) / 7.2
        @test speed_error < 2.0
        @test s[m.meter.s][end] ≈ trace_distance rtol=5e-4
        if electric
            @test maximum(abs, s[m.powertrain.position]) < 1e-9
            @test abs(s[m.meter.m_fuel][end]) < 1e-9
            @test maximum(abs, s[m.powertrain.engine_speed]) < 1e-9
            @test s[m.powertrain.SoC][end] < s[m.powertrain.SoC][1]
            @test s[m.meter.E_batt][end] ≈ s.ps[m.powertrain.drive.battery.E] *
                s.ps[m.powertrain.drive.battery.Q_nom] *
                (s[m.powertrain.SoC][1] - s[m.powertrain.SoC][end]) rtol=1e-6
        else
            @test maximum(abs, s[m.powertrain.tau_ref]) == 0.0
            @test s[m.powertrain.engine_speed][1] * 30 / pi ≈ 800.0
            @test s[m.powertrain.position][1] == 0.0
            rpm = s[m.powertrain.engine_speed] .* (30 / pi)
            above_ramp = rpm .> s.ps[m.engage_rpm] + 5 * s.ps[m.engage_width_rpm]
            @test any(above_ramp)
            # Allow actuator lag while checking near-closure above the engagement ramp.
            @test minimum(s[m.powertrain.position][above_ramp]) > 0.99
            @test s[m.meter.fuel_raw][end] ≈ 5.715009 rtol=1e-3
            @test s[m.meter.fuel_corr][end] ≈ s[m.meter.fuel_raw][end] atol=1e-10
            @test s[m.meter.energy_corr][end] ≈ 184.7834 rtol=1e-3
            @test maximum(abs, s[m.powertrain.i]) < 1e-9
            capacity = maximum(s[m.powertrain.k0.tau_capacity])
            @test maximum(s[m.powertrain.engine_torque]) < capacity
            d = m.powertrain.drive
            for p in (d.T_f, d.K_i, d.k_w, d.C, d.J, d.tau_loss_base)
                @test s.ps[p] == 0.0
            end
            w, R, V, T = (s.ps[p] for p in (d.w_base, d.R, d.V_nom, d.T_max))
            @test s.ps[d.k] ≈ (V + sqrt(V^2 - 4w * R * T)) / (2w) rtol=1e-12
            @test s[d.machine.i][1] == 0.0
            loss = s[m.powertrain.k0.tau] .* s[m.powertrain.k0.w_slip]
            @test minimum(loss) >= 0.0
            slip_MJ = sum(diff(s.t) .* (loss[1:end-1] .+ loss[2:end])) / 2e6
            @info "H0 K0" slip_MJ peak_engine_torque=maximum(s[m.powertrain.engine_torque]) capacity
        end
        @info "P2 fixed-mode WLTC" electric speed_error distance=s[m.meter.s][end] raw_L100=s[m.meter.fuel_raw][end] corrected_L100=s[m.meter.fuel_corr][end] MJ100=s[m.meter.energy_corr][end] fuel_kg=s[m.meter.m_fuel][end] SoC_drop=s[m.powertrain.SoC][1]-s[m.powertrain.SoC][end]
    end
end

@testset "operating line" begin
    power, rpm = getindex.(LINE_ROWS, 1), getindex.(LINE_ROWS, 2)

    # The sweep request is (t - 10) kW, from -10 kW to 100 kW.
    lookup = VehicleSystemsComponents.Vehicle.OperatingLineTransient()
    @test string(lookup.sol.retcode) == "Success"
    target(P_kW) = lookup.sol(P_kW + 10.0, idxs = symbolic_container(lookup).line.N)
    @test target(32.0) ≈ 3000.0 atol = 1e-9
    @test all(isapprox.(target.(power), rpm; atol = 1e-6))
    @test all(target(P) ≈ first(rpm) for P in (-10.0, -1.0, 0.0, 0.5, first(power)))
    @test all(target(P) ≈ last(rpm) for P in (last(power), 86.0, 100.0))

    run = VehicleSystemsComponents.Lecture5.OperatingLineBenchTransient()
    @test string(run.sol.retcode) == "Success"
    m, s = symbolic_container(run), run.sol
    v = m.variator
    p(x) = s.ps[x]
    N_wheel, i_od, i_l = p(m.wheel_rpm), p(v.i_overdrive), p(v.i_launch)
    floor_bias = N_wheel / hypot(N_wheel, p(v.output_rpm_floor))
    ts = collect(0.0:0.05:102.0)
    at(x) = s(ts, idxs = x).u
    N_a, N_t, ratio, cmd = at(v.N_a), at(m.line.N), at(v.ratio), at(v.i_command)

    @test all(i_od - 1e-6 .<= ratio .<= i_l + 1e-6)

    # Settled on the 32 kW hold: the line speed, low only by the output-speed floor's bias.
    hold = 38.0 .<= ts .<= 43.0
    @test all(isapprox.(N_a[hold], 3000.0 * floor_bias; atol = 0.1))

    # Steady state on the hold: the dyno absorbs the requested power, so the variator passes
    # torque times ratio and power through unchanged.
    P_dyno = -at(v.spline_b.tau)[hold] .* at(v.w_b)[hold]
    @test all(isapprox.(P_dyno, p(m.P_hold); rtol = 1e-6))

    # In range the input shaft trails the line by the actuator lag, ratio_time times the
    # line's steepest slope times the ramp rate, plus the floor bias, which grows with speed.
    slope = maximum(diff(rpm) ./ diff(power))
    rate = max((p(m.P_hold) - p(m.P_start)) / p(m.rise.duration),
        (p(m.P_end) - p(m.P_hold)) / p(m.top.duration)) / 1e3
    in_range = i_od + 1e-3 .< cmd .< i_l - 1e-3
    bound = p(v.ratio_time) * slope * rate + maximum(N_t[in_range]) * (1 - floor_bias) + 10.0
    lag = maximum(abs.(N_a[in_range] .- N_t[in_range]))
    @test lag < bound

    # Out of range the ratio sits at its limit: overdrive under the line's low end, launch
    # past its reach, with the shaft on the side of the target the limit forces.
    low = ts .<= 2.0
    @test all(isapprox.(ratio[low], i_od; atol = 1e-6))
    @test all(isapprox.(N_a[low], i_od * N_wheel; atol = 1e-3))
    @test all(N_a[low] .> N_t[low])
    top = ts .>= 100.0
    @test all(isapprox.(ratio[top], i_l; atol = 1e-6))
    @test all(isapprox.(N_a[top], i_l * N_wheel; atol = 1e-3))
    @test all(N_a[top] .< N_t[top])
    @info "Operating-line bench" settled_rpm = N_a[findlast(hold)] max_in_range_lag_rpm = lag lag_bound_rpm = bound dyno_power_W = P_dyno[end] low_rpm = N_a[1] top_rpm = N_a[end]
end


@testset "operating line on the P2 car" begin
    for (name, folder) in (("P2OperatingLinePowertrain", "Vehicle"), ("P2OperatingLineWLTC", "Lecture5"))
        source(dir) = read(joinpath(@__DIR__, "..", "dyad", dir, name * ".dyad"), String)
        normalize(t) = replace(t, "VehicleSystemsComponents.HandsOn05.P2OperatingLinePowertrain" =>
            "VehicleSystemsComponents.Vehicle.P2OperatingLinePowertrain")
        @test normalize(source("HandsOn05")) == normalize(source(folder))
    end
    run = VehicleSystemsComponents.Lecture5.P2OperatingLineWLTCTransient()
    m, s = symbolic_container(run), run.sol
    @test string(s.retcode) == "Success"
    @test s.t[end] == 1800.0
    speed_error = maximum(abs, 3.6 .* s[m.car.bus.vx] .- s[m.trace.y])
    @test speed_error < 2.0
    trace_distance = sum(diff(s.t) .* (s[m.trace.y][1:end-1] .+ s[m.trace.y][2:end])) / 7.2
    @test s[m.meter.s][end] ≈ trace_distance rtol=5e-4
    @test maximum(abs, s[m.powertrain.tau_ref]) == 0.0
    @test maximum(abs, s[m.powertrain.i]) < 1e-9
    @test s[m.meter.fuel_corr][end] ≈ s[m.meter.fuel_raw][end] atol=1e-10

    # Uniform samples avoid weighting points by adaptive solver effort. Fuel uses trapezoids.
    ts = collect(0.0:0.1:1800.0)
    at(x) = s(ts, idxs=x).u
    rpm = at(m.powertrain.engine_speed) .* (30 / pi)
    torque = at(m.powertrain.engine_torque)
    power = rpm .* torque .* (pi / 30 / 1000)
    target = [BsfcLine.lin(getindex.(LINE_ROWS, 1), getindex.(LINE_ROWS, 2), p) for p in power]
    deviation = abs.(rpm .- target)
    cmd = at(m.powertrain.variator.i_command)
    ratio = at(m.powertrain.variator.ratio)
    # Dense interpolation undershoots the 2.8 bound by 5.4e-6 at default solver tolerance.
    @test all(2.8 - 1e-5 .<= ratio .<= 12.0 + 1e-5)
    idle = (power .< 1.0) .| (at(m.driver.y) .<= 0.0)
    launch = .!idle .& (cmd .>= 11.999)
    overdrive = .!idle .& (cmd .<= 2.801)
    eligible = .!idle .& .!launch .& .!overdrive
    # Horizontal band in the speed–torque plane, evaluated at ACTUAL brake power.
    # 0.5 s ratio lag, crank acceleration, floor bias and K0 slip cause transient departures.
    on = eligible .& (deviation .<= 500.0)
    @test sum(eligible) / length(ts) > 0.20
    @test sum(on) / sum(eligible) > 0.95
    fuel = at(m.powertrain.mdot_fuel)
    fuel[1] /= 2
    fuel[end] /= 2
    @test sum(fuel[on]) / sum(fuel) > 0.44
    for (label, mask) in (("on", on), ("off", .!on), ("idle/braking", idle),
            ("launch", launch), ("overdrive", overdrive), ("in-range transient", eligible .& .!on))
        @info "P2 operating points: $label" point_percent=100sum(mask)/length(ts) fuel_percent=100sum(fuel[mask])/sum(fuel)
    end
    baseline = VehicleSystemsComponents.Lecture5.P2EngineWLTCTransient()
    bm = symbolic_container(baseline)
    raw, h0 = s[m.meter.fuel_raw][end], baseline.sol[bm.meter.fuel_raw][end]
    @test raw ≈ 5.44968 rtol=1e-3
    @test h0 ≈ 5.715009 rtol=1e-3
    @info "P2 operating-line WLTC" speed_error distance=s[m.meter.s][end] raw_L100=raw H0_L100=h0 difference=raw-h0 percent=100*(raw/h0-1)
end
