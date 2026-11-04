# Lecture 5 best-BSFC operating line (scripts/bsfc_line.jl), the line the CVT holds the engine on.

include("../scripts/bsfc_line.jl")
using .BsfcLine

@testset "Lecture 5 best-BSFC line" begin
    m = load_maps()
    rows = [parse.(Float64, split(l, ',')) for l in readlines(LINE_FILE)[2:end]]
    power, rpm, torque, bsfc = (getindex.(rows, k) for k in 1:4)

    @testset "the committed file is what the script writes" begin
        @test read(LINE_FILE, String) == render_line(operating_line(m))
    end

    @testset "speed rises with power, idle to peak" begin
        @test all(diff(power) .> 0)
        @test issorted(rpm)
        @test rpm[end] > rpm[1]
        @test first(power) == 1.0
        peak = maximum(n -> reachable_torque(m, n) * n * pi / 30e3, BsfcLine.SPEEDS)
        @test last(power) ≈ peak atol = 1e-3
        @test RPM_IDLE <= first(rpm) && last(rpm) <= RPM_MAX
    end

    @testset "every point is a reachable operating point" begin
        @test all(isapprox.(torque .* rpm .* pi ./ 30e3, power; rtol = 1e-4))
        @test all(torque .<= reachable_torque.(Ref(m), rpm) .+ 1e-3)
    end

    # Independent of the script's search: BSFC at the table nodes themselves, under full load and
    # inside the speed range. Between nodes BSFC is a ratio of linear functions along each axis,
    # so no point of the bilinear map is lower than its lowest node or full-load cap point.
    @testset "the line reaches the map's minimum BSFC [g/kWh]" begin
        fl(n) = BsfcLine.lin(m.fl_rpm, m.fl_T, n)
        node_min = minimum(m.fuel[i, j] * 3600 / (m.torque[i, j] * n * pi / 30e3)
                           for (i, n) in enumerate(m.rpm), j in eachindex(m.kpa)
                           if RPM_IDLE <= n <= RPM_MAX && 0 < m.torque[i, j] <= fl(n))
        best = global_min_bsfc(m)
        line_min = minimum(bsfc)
        @info "Best-BSFC line" node_min best line_min
        @test best.bsfc <= node_min + 1e-6
        @test node_min - best.bsfc < 1.0
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

    # No net battery energy: the correction vanishes exactly, not to a tolerance.
    neutral = soc_fuel_end(P = 0.0)
    @test neutral.E_MJ == 0.0
    @test neutral.corr == neutral.raw
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
