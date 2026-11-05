# Lecture 5 best-BSFC operating line (scripts/bsfc_line.jl), the line the CVT holds the engine on.

include("../scripts/bsfc_line.jl")
using .BsfcLine

const BSFC_LINE = read_line()

@testset "Lecture 5 best-BSFC line" begin
    m = load_maps()
    (; rpm, torque, bsfc) = BSFC_LINE
    power = BSFC_LINE.power_kw

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
    @test ps[d.V_nom] == 270.0
    # The machine is designed at the pack's terminal voltage at rated input, not its open circuit.
    Vd = 220.0
    @test ps[d.machine.V_nom] == Vd
    @test Vd ≈ (270 + sqrt(270^2 - 4 * 0.33 * 30e3 / 0.9)) / 2 rtol = 1e-3
    @test ps[d.battery.E] * ps[d.battery.Q_nom] / 3.6e6 ≈ 1.4 rtol = 0.05
    @test run.sol[d.SoC][1] ≈ 0.6
    @test ps[d.battery.R0] ≈ 0.33
    @test ps[d.reduction.ratio] == 1.0
    # Independent Leaf-based scaling and the unchanged machine's quadratic design equation.
    scale = 30 / 110
    R = 0.05 * (Vd / 350)^2 / scale
    w = 30e3 / 205
    losses = (0.5 + 1.0) * scale + 300 / (10100pi / 30)^3 * scale * w^2 + 200scale / w
    k = (Vd + sqrt(Vd^2 - 4w * R * (205 + losses))) / (2w)
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
    # Half the power sags the pack less: design at its own loaded voltage, 15 kW at about 90 %.
    Vd_small = 248.0
    @test Vd_small ≈ (270 + sqrt(270^2 - 4 * 0.33 * 15e3 / 0.9)) / 2 rtol = 1e-3
    small = VehicleSystemsComponents.Lecture5.HybridDriveDynoTransient(P_rated=15e3, T_max=102.5, V_design=Vd_small)
    @test string(small.sol.retcode) == "Success"
    s = symbolic_container(small).drive
    @test small.sol.ps[s.machine.w_base] ≈ ps[d.machine.w_base]
    @test small.sol.ps[s.machine.T_max] == 102.5
    @test small.sol.ps[s.machine.C] ≈ ps[d.machine.C] / 2
    R_small = 0.05 * (Vd_small / 350)^2 / (scale / 2)
    losses_small = losses / 2
    k_small = (Vd_small + sqrt(Vd_small^2 - 4w * R_small * (102.5 + losses_small))) / (2w)
    @test small.sol.ps[s.machine.R] ≈ R_small rtol = 1e-12
    @test small.sol.ps[s.machine.k] ≈ k_small rtol = 1e-12
    @test small.sol.ps[s.converter.I_max] ≈ (102.5 + losses_small) / k_small rtol = 1e-12
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
            w, R, V, T = (s.ps[p] for p in (d.w_base, d.R, d.V_design, d.T_max))
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
    power, rpm = BSFC_LINE.power_kw, BSFC_LINE.rpm

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

@testset "engine-generator" begin
    H_u = 43.4e6
    maps = load_maps()
    trapz(t, y) = sum((y[1:end-1] .+ y[2:end]) ./ 2 .* diff(t))
    # Best-BSFC line speed for an engine power, as OperatingLine interpolates it.
    line_power, line_speed = BSFC_LINE.power_kw, BSFC_LINE.rpm
    function line_rpm(P_kW)
        P_kW <= first(line_power) && return first(line_speed)
        P_kW >= last(line_power) && return last(line_speed)
        k = searchsortedlast(line_power, P_kW)
        w = (P_kW - line_power[k]) / (line_power[k+1] - line_power[k])
        return line_speed[k] + w * (line_speed[k+1] - line_speed[k])
    end
    # Hold k ends at k t_hold + (k - 1) t_ramp; the analyses write their stop time out for the
    # bench defaults, so check those are the defaults in force.
    hold_ends(m, s, n) = (@test s.ps[m.t_hold] == 10.0 && s.ps[m.t_ramp] == 2.0;
        @test s.t[end] ≈ n * s.ps[m.t_hold] + (n - 1) * s.ps[m.t_ramp];
        [k * s.ps[m.t_hold] + (k - 1) * s.ps[m.t_ramp] for k in 1:n])
    # Last 3 s of a hold, on the saved 0.05 s grid.
    window(s, t_end) = filter(t -> t_end - 3.0 - 1e-9 <= t <= t_end + 1e-9, s.t)
    function check_hold(u, s, t_end, P)
        ts = window(s, t_end)
        at(x) = s(ts, idxs = x).u
        P_el, N, N_ref, P_shaft = at(u.P_elec), at(u.N), at(u.N_ref), at(u.P_shaft)
        @test all(isapprox.(P_el, P; rtol = 1e-3))
        @test all(isapprox.(N, N_ref; atol = 1.0))
        # The line is fed the engine power the unit needs, so the engine sits on the line.
        P_eng = at(u.engine.tau_e) .* at(u.machine.w)
        @test all(isapprox.(N, line_rpm.(P_eng ./ 1e3); atol = 5.0))
        @test all(isapprox.(P_shaft, P_eng; rtol = 5e-3))
        return (; ts, P_el, N, P_eng, mdot = at(u.mdot_fuel), v = at(u.converter.v_in),
            field = at(u.converter.field))
    end

    @testset "resistive load" begin
        run = VehicleSystemsComponents.Lecture5.EngineGeneratorBenchTransient()
        @test string(run.sol.retcode) == "Success"
        m, s = symbolic_container(run), run.sol
        u = m.unit
        ends = hold_ends(m, s, 4)
        commands = (s.ps[m.P_1], s.ps[m.P_2], s.ps[m.P_3], s.ps[m.P_4])
        @test all(s[u.converter.field] .> 1 - 1e-6)
        for (t_end, P) in zip(ends, commands)
            h = check_hold(u, s, t_end, P)
            @info "Engine-generator, resistive load" P_cmd_kW = P / 1e3 P_elec_kW = h.P_el[end] / 1e3 N_rpm = h.N[end] P_engine_kW = h.P_eng[end] / 1e3 mdot_fuel_g_s = 1e3h.mdot[end] bsfc_g_kWh = h.mdot[end] * 3.6e9 / h.P_eng[end] bus_V = h.v[end] eta_system = h.P_el[end] / (h.mdot[end] * H_u)
        end

        # The 30 kW hold puts the engine on the line's best-BSFC row, 32 kW at 3000 rpm.
        h = check_hold(u, s, ends[3], commands[3])
        @test all(isapprox.(h.N, 3000.0; atol = 1.0))
        @test all(31.0 .< h.P_eng ./ 1e3 .< 33.0)
        @test h.v[end] ≈ s.ps[m.V_bus] rtol = 1e-3

        # System efficiency as electrical energy out over fuel energy in, and its two shares,
        # each checked against what produces it: the engine's against the Lecture 2 map's BSFC
        # at the held speed and torque, the generator's against its own loss signals.
        ts = h.ts
        at(x) = s(ts, idxs = x).u
        E_el, E_fuel = trapz(ts, h.P_el), H_u * trapz(ts, h.mdot)
        E_shaft = trapz(ts, h.P_eng)
        E_loss = trapz(ts, at(u.machine.P_loss) .+ at(u.converter.P_loss))
        eta_sys, eta_eng, eta_gen = E_el / E_fuel, E_shaft / E_fuel, E_el / E_shaft
        point = bsfc_at(maps, h.N[end], s(ts[end], idxs = u.engine.tau_e))
        @test point !== nothing
        eta_map = 3.6e6 / (point.bsfc * 1e-3 * H_u)
        @test eta_eng ≈ eta_map rtol = 0.01
        @test point.bsfc ≈ BSFC_LINE.bsfc[findfirst(==(32.0), BSFC_LINE.power_kw)] rtol = 0.005
        @test eta_gen ≈ E_el / (E_el + E_loss) rtol = 1e-3
        @test 0.92 < eta_gen < 0.96
        @test 0.32 < eta_sys < 0.345
        @info "Engine-generator best point" P_engine_kW = h.P_eng[end] / 1e3 N_rpm = h.N[end] bsfc_sim = h.mdot[end] * 3.6e9 / h.P_eng[end] bsfc_map = point.bsfc eta_system = eta_sys eta_engine = eta_eng eta_generator_converter = eta_gen machine_loss_W = s(ts[end], idxs = u.machine.P_loss) converter_loss_W = s(ts[end], idxs = u.converter.P_loss)
    end

    @testset "battery bus" begin
        run = VehicleSystemsComponents.Lecture5.EngineGeneratorBatteryBenchTransient()
        @test string(run.sol.retcode) == "Success"
        m, s = symbolic_container(run), run.sol
        u, b = m.unit, m.battery
        p(x) = s.ps[x]
        ends = hold_ends(m, s, 6)
        commands = (p(m.P_1), p(m.P_2), p(m.P_3), p(m.P_4), p(m.P_5), p(m.P_6))
        for k in (1, 2, 3, 4, 6)
            h = check_hold(u, s, ends[k], commands[k])
            # The battery takes the delivered power less its own resistive loss.
            ts = h.ts
            stored = p(b.E) * p(b.Q_nom) * (s(ts[end], idxs = b.SoC) - s(ts[1], idxs = b.SoC))
            i = s(ts, idxs = b.i).u
            @test stored ≈ trapz(ts, h.P_el .- p(b.R0) .* i .^ 2) rtol = 1e-3
            @test stored > 0
            @info "Engine-generator, battery bus" P_cmd_kW = commands[k] / 1e3 P_elec_kW = h.P_el[end] / 1e3 N_rpm = h.N[end] P_engine_kW = h.P_eng[end] / 1e3 mdot_fuel_g_s = 1e3h.mdot[end] bus_V = h.v[end] field = h.field[end] eta_system = h.P_el[end] / (h.mdot[end] * H_u)
        end
        # 50 kW on the line runs above the generator's full-field speed for this bus.
        h4 = check_hold(u, s, ends[4], commands[4])
        @test all(0.9 .< h4.field .< 0.99)
        @test all(s(window(s, ends[3]), idxs = u.converter.field).u .> 1 - 1e-6)

        # 70 kW is past the engine's full load at the line's top speed: the generator unloads,
        # the unit delivers the engine's full load just under the commanded speed, and the
        # power trim stays bounded instead of winding up.
        ts = window(s, ends[5])
        at(x) = s(ts, idxs = x).u
        N_lag = at(u.N_ref) .- at(u.N)
        @test all(at(u.pedal) .> 0.99)
        @test all(at(u.P_elec) .< commands[5] - 1e3)
        @test all(at(u.P_elec) .> 55e3)
        @test all(0.0 .< N_lag .< p(u.dw_unload) * 30 / pi)
        @test all(abs.(at(u.P_trim)) .< 5e3)
        @test maximum(at(u.N)) - minimum(at(u.N)) < 1.0
        @info "Engine-generator past full load" P_cmd_kW = commands[5] / 1e3 P_elec_kW = at(u.P_elec)[end] / 1e3 N_ref_rpm = at(u.N_ref)[end] N_rpm = at(u.N)[end] P_trim_W = at(u.P_trim)[end] current_A = at(u.converter.i_out)[end] I_max_A = p(u.converter.I_max)
        # Recovery: back on 30 kW the hold is settled from 3 s after the ramp ends.
        late = filter(t -> ends[5] + p(m.t_ramp) + 3.0 <= t <= ends[6] + 1e-9, s.t)
        @test all(isapprox.(s(late, idxs = u.P_elec).u, commands[6]; rtol = 1e-3))
        @test all(isapprox.(s(late, idxs = u.N).u, 3000.0; atol = 1.0))
    end
end

include("../notebooks/lecture05/operating_points.jl")
using .OperatingPoints

# The extraction behind the operating-points notebook, on Hands-on 02's steady 90 km/h cruise:
# one operating point held for a minute, so every figure has a value to check it against.
@testset "Lecture 5 operating points on a steady cruise" begin
    r = VehicleSystemsComponents.HandsOn02.MappedCarCruiseTransient()
    m = symbolic_container(r)
    sol = r.sol
    op = operating_points(sol; speed = m.car.engine.speed.w, torque = m.car.engine.torque.tau,
        fuel = m.car.engine.mdot_fuel, vehicle_speed = m.car.v_kmh, dt = 0.5)
    f = fuel_metrics(op)
    T = last(sol.t)

    @test length(op.t) == 120
    @test op.km ≈ 1.5 rtol = 0.01

    # The car's own L/h output, integrated apart from the extraction and its units.
    ts = 0.0:0.01:T
    lph = sol(ts; idxs = m.car.fuel_lph).u
    liters = sum((lph[1:end-1] .+ lph[2:end]) ./ 2) * step(ts) / 3600
    @test f.fuel_g / 1e3 / RHO_PETROL ≈ liters rtol = 1e-3
    @test f.L_per_100km ≈ 100 * lph[end] / sol(T; idxs = m.car.v_kmh) rtol = 0.01

    # The map tables give the same BSFC at the simulated speed and torque.
    maps = load_maps()
    k = length(op.t)
    @test op.bsfc[k] ≈ bsfc_at(maps, op.rpm[k], op.torque[k]).bsfc rtol = 0.01
    @test f.bsfc_mean ≈ op.bsfc[k] rtol = 0.01
    @test f.bsfc_cycle ≈ f.bsfc_mean rtol = 0.01
    @test f.idle == 0

    gap = op.bsfc[k] - line_bsfc(op.power_kw[k])
    @test gap > 0
    @test f.near_line == (gap <= 10 ? 1.0 : 0.0)
    @test fuel_metrics(op; band = gap + 1).near_line ≈ 1

    # An engine that never fires, as in electric driving, has no cells and no BSFC to report.
    off = merge(op, (; fuel_g = zero(op.fuel_g)))
    @test isempty(fuel_cells(off).fuel_g)
    f_off = fuel_metrics(off)
    @test f_off.L_per_100km == 0
    @test all(ismissing, (f_off.bsfc_mean, f_off.bsfc_cycle, f_off.near_line, f_off.idle))
    @info "Lecture 5 cruise operating point" rpm = op.rpm[k] torque = op.torque[k] f gap
end

@testset "energy manager" begin
    run = VehicleSystemsComponents.Lecture5.EnergyManagerBenchTransient()
    @test string(run.sol.retcode) == "Success"
    m, s = symbolic_container(run), run.sol
    M = m.manager
    p(x) = s.ps[x]
    ts = collect(0.0:0.05:900.0)
    at(x) = s(ts, idxs = x).u
    within(a, b) = a .<= ts .<= b
    eng, bst, chg = at(M.engine.y), at(M.boost.y), at(M.charge.y)
    tau_dem, tau_m, tau_e = at(M.tau_dem), at(M.tau_machine), at(M.tau_engine)
    fric, P_e, w = at(M.tau_friction), at(M.P_engine), at(M.w_shaft)
    soc = at(m.SoC)
    T_max, P_max, P_regen = p(M.T_max), p(M.P_max), p(M.P_regen)
    P_chg, P_line_max = p(M.P_chg), p(M.P_line_max)
    SoC_on, SoC_off = p(M.SoC_on), p(M.SoC_off)
    # Times a latch output passes 0.5, the instants its mode changes.
    switches(y) = ts[findall(i -> (y[i] - 0.5) * (y[i+1] - 0.5) < 0, 1:length(y)-1)]
    settled(y, a, b, v) = all(isapprox.(y[within(a, b)], v; atol = 1e-3))

    @testset "each mode in its segment" begin
        # Electric only: the machine carries the demand, the engine is released.
        ev = within(0.0, 15.0)
        @test settled(eng, 0.0, 15.0, 0.0)
        @test all(isapprox.(tau_m[ev], tau_dem[ev]; atol = 1e-6))
        @test all(abs.(P_e[ev]) .< 1e-6)
        # On the line: the engine supplies the demand power, the machine idles, and the line's
        # target is the table's 30 kW speed.
        @test settled(at(M.on_line), 36.0, 42.0, 1.0)
        line = within(36.0, 42.0)
        @test all(isapprox.(P_e[line], 30.0e3; rtol = 1e-6))
        @test all(abs.(tau_m[line]) .< 1e-6)
        k30 = findfirst(==(30.0), BSFC_LINE.power_kw)
        @test all(isapprox.(at(m.line.N)[line], BSFC_LINE.rpm[k30]; atol = 1e-6))
        # Boost: the engine is held at the line cap and the machine adds the remaining 15 kW.
        @test settled(at(M.boosting), 64.5, 66.0, 1.0)
        boost = within(64.5, 66.0)
        @test all(isapprox.(P_e[boost], P_line_max; rtol = 1e-6))
        @test all(isapprox.(tau_m[boost] .* w[boost], 15.0e3; rtol = 1e-6))
        # At 110 kW the machine saturates at P_max and the engine rises past the line cap to
        # cover the rest: the demand is delivered up to P_peak plus the machine limit.
        sat = within(68.5, 71.0)
        P_dem = tau_dem .* w
        @test all(isapprox.(tau_m[sat] .* w[sat], P_max; rtol = 1e-6))
        @test all(isapprox.(P_e[sat], 110.0e3 - P_max; rtol = 1e-6))
        @test all(isapprox.(P_e[sat] .+ tau_m[sat] .* w[sat],
            min.(P_dem[sat], p(M.P_peak) + P_max); rtol = 1e-6))
        # Back to electric after the demand falls below P_off.
        @test settled(eng, 77.0, 88.0, 0.0)
        # Regen: the machine takes 20 kW whole; of 50 kW it takes its 30 kW ceiling and the
        # friction brakes the rest.
        light, heavy = within(92.0, 96.0), within(100.0, 104.0)
        @test all(isapprox.(tau_m[light] .* w[light], -20.0e3; rtol = 1e-6))
        @test all(abs.(fric[light]) .< 1e-6)
        @test all(isapprox.(tau_m[heavy] .* w[heavy], -P_regen; rtol = 1e-6))
        @test all(isapprox.(fric[heavy] .* w[heavy], 50.0e3 - P_regen; rtol = 1e-6))
        # At standstill the regen fade hands the whole braking demand to the friction brakes.
        stop = within(127.5, 130.0)
        @test all(abs.(tau_m[stop]) .< 1e-9)
        @test all(isapprox.(fric[stop], 60.0; atol = 1e-9))
        # Launch: 250 N.m at standstill starts the engine for the 45 N.m the machine cannot
        # give, at idle speed; K0 closes and the plant's K0 slip carries it to the shaft.
        launch = within(134.5, 137.0)
        @test settled(eng, 134.5, 137.0, 1.0)
        @test all(isapprox.(tau_m[launch], T_max; atol = 1e-9))
        @test all(isapprox.(tau_e[launch], 250.0 - T_max; rtol = 1e-3))
        @test all(isapprox.(at(M.engage)[launch], 1.0; atol = 1e-3))
        # Charge: a low battery starts the engine at 6 kW demand, the engine runs P_chg above it
        # and the machine generates P_chg.
        charging = at(M.charging) .> 0.999
        @test count(charging) > 0
        @test all(isapprox.(P_e[charging], 6.0e3 + P_chg; rtol = 1e-3))
        @test all(isapprox.(tau_m[charging] .* w[charging], -P_chg; rtol = 1e-3))
        # Wherever the modes are settled, machine, engine and friction brakes deliver the demand.
        steady = (eng .< 1e-4 .|| eng .> 1 - 1e-4) .&& (bst .< 1e-4 .|| bst .> 1 - 1e-4) .&&
                 (chg .< 1e-4 .|| chg .> 1 - 1e-4)
        delivered = tau_m .+ at(M.engage) .* tau_e .- fric
        @test all(isapprox.(delivered[steady], tau_dem[steady]; atol = 0.05))
    end

    @testset "no chatter under dithering" begin
        # One switch per threshold the scripted demand crosses, each inside the dithered or
        # ramped window that crosses it.
        on_off = switches(eng)
        boost_switches = switches(bst)
        @test count(t -> t < 150.0, on_off) == 4
        @test 15.0 < on_off[1] < 29.0 && 74.0 < on_off[2] < 88.0
        @test 132.0 < on_off[3] < 133.5 && 136.0 < on_off[4] < 138.0
        @test length(boost_switches) == 2
        @test 47.0 < boost_switches[1] < 61.0 && 69.0 < boost_switches[2] < 74.0
        @test isempty(filter(t -> t < 150.0, switches(chg)))
        # Inside the dither windows every latch holds its value.
        # Settled after about seven latch times past the switch.
        @test settled(eng, 18.0, 29.0, 1.0)
        @test settled(bst, 50.0, 61.0, 1.0)
        # In the SoC loop each charge switch moves the engine once, and no mode switches faster
        # than the battery can move SoC across its band: discharge at 6 kW, charge at P_chg.
        loop_charge = filter(>(150.0), switches(chg))
        loop_engine = filter(>(150.0), on_off)
        @test length(loop_engine) == length(loop_charge)
        E_band = (SoC_off - SoC_on) * p(m.E_cap)
        t_min = min(E_band / (6.0e3 / p(m.eta)), E_band / (P_chg * p(m.eta)))
        @test minimum(diff(loop_charge)) > 0.9 * t_min
        @test length(loop_charge) <= ceil(Int, 750.0 / t_min)
    end

    @testset "outputs within their limits" begin
        @test all(abs.(tau_m) .<= T_max + 1e-9)
        @test all(abs.(tau_m .* w) .<= P_max * (1 + 1e-9))
        @test all(-1e-9 .<= P_e .<= p(M.P_peak) + 1e-6)
        N = at(m.line.N)
        @test all(first(BSFC_LINE.rpm) - 1e-9 .<= N .<= last(BSFC_LINE.rpm) + 1e-9)
        for y in (at(M.engage), at(M.engine_on))
            @test all(0.0 .<= y .<= 1.0)
        end
        # The latch states themselves leave [0, 1] only by the integration error.
        for y in (eng, bst, chg)
            @test all(-1e-4 .<= y .<= 1 + 1e-4)
        end
        @test all(fric .>= -1e-9)
        @test all(fric .<= max.(-tau_dem, 0.0) .+ 1e-9)
        @test all(tau_e .>= -1e-9)
        modes = at(M.ev) .+ at(M.on_line) .+ at(M.charging) .+ at(M.boosting)
        @test all(isapprox.(modes, 1.0; atol = 1e-12))
    end

    @testset "SoC stays in its window once the loop closes" begin
        t_first = first(filter(>(150.0), switches(chg)))
        @test soc[findfirst(>=(t_first), ts)] ≈ SoC_on atol = 1e-3
        loop = ts .>= t_first
        @test minimum(soc[loop]) >= SoC_on - 2e-3
        @test maximum(soc[loop]) <= SoC_off + 2e-3
        @test length(filter(>(150.0), switches(chg))) >= 6
    end

    @info "Energy manager bench" engine_switches = switches(eng) boost_switches = switches(bst) charge_switches = switches(chg) SoC_loop = extrema(soc[ts .>= 300.0]) SoC_max = maximum(soc) tau_machine = extrema(tau_m) P_engine_max = maximum(P_e)

    @testset "depleted battery" begin
        low = VehicleSystemsComponents.Lecture5.EnergyManagerLowSoCTransient()
        @test string(low.sol.retcode) == "Success"
        lm, ls = symbolic_container(low), low.sol
        LM = lm.manager
        lts = collect(0.0:0.05:70.0)
        lp(x) = ls.ps[x]
        lat(x) = ls(lts, idxs = x).u
        lwithin(a, b) = a .<= lts .<= b
        on, w, P_e = lat(LM.engine_on), lat(LM.w_shaft), lat(LM.P_engine)
        tau_m, fric, soc = lat(LM.tau_machine), lat(LM.tau_friction), lat(lm.SoC)
        P_m = tau_m .* w
        @test all(lat(LM.charge.y) .> 1 - 1e-6)
        # At standstill a low battery leaves the engine off and K0 open.
        still = lwithin(0.0, 10.0)
        @test all(on[still] .< 1e-9) && all(lat(LM.engage)[still] .< 1e-9) && all(P_e[still] .< 1e-9)
        # On the launch the engine stays off below w_off and starts once, above w_on.
        @test all(on[lwithin(0.0, 26.0) .&& w .< lp(LM.w_off)] .< 1e-6)
        lswitches(y) = lts[findall(i -> (y[i] - 0.5) * (y[i+1] - 0.5) < 0, 1:length(y)-1)]
        starts = lswitches(lat(LM.engine.y))
        @test length(starts) == 1
        @test ls(starts[1], idxs = LM.w_shaft) >= lp(LM.w_on)
        # Boost latched at 80 kW, but SoC below SoC_on fades the machine's share by a_boost.
        boost = lwithin(31.0, 36.0)
        x = clamp.((soc[boost] .- lp(LM.SoC_on) .+ lp(LM.dSoC_boost)) ./ lp(LM.dSoC_boost), 0.0, 1.0)
        a = x .^ 2 .* (3 .- 2 .* x)
        @test all(lat(LM.boost.y)[boost] .> 1 - 1e-6)
        @test all(soc[boost] .< lp(LM.SoC_on))
        @test all(isapprox.(P_m[boost], a .* lp(LM.P_max); rtol = 1e-6))
        @test all(isapprox.(P_e[boost] .+ P_m[boost], 80.0e3; rtol = 1e-6))
        @test maximum(P_m[boost]) < 0.25 * lp(LM.P_max)
        # Charging at 6 kW: the engine runs P_chg above the demand.
        charge = lwithin(40.0, 46.0)
        @test all(isapprox.(P_e[charge], 6.0e3 + lp(LM.P_chg); rtol = 1e-6))
        @test all(isapprox.(P_m[charge], -lp(LM.P_chg); rtol = 1e-6))
        # At 55 kW the charge shift stops at the line cap.
        cap = lwithin(50.0, 56.0)
        @test all(isapprox.(P_e[cap], lp(LM.P_line_max); rtol = 1e-6))
        @test all(isapprox.(P_m[cap], 55.0e3 - lp(LM.P_line_max); rtol = 1e-6))
        # Braking with the engine on: no charge adder, regen takes the whole 20 kW.
        brake = lwithin(60.0, 66.0)
        @test all(on[brake] .> 1 - 1e-6)
        @test all(abs.(P_e[brake]) .< 1e-6)
        @test all(isapprox.(P_m[brake], -20.0e3; rtol = 1e-6))
        @test all(abs.(fric[brake]) .< 1e-9)
        @test all(-1e-9 .<= P_e .<= lp(LM.P_peak) + 1e-6)
        @info "Energy manager, depleted battery" engine_start = starts boost_share = extrema(a) SoC = extrema(soc)
    end
end
