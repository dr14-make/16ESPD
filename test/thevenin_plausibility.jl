using DyadInterface: symbolic_container, simplify_model
using ModelingToolkit
using OrdinaryDiffEqDefault: solve, Tsit5

const _TH = VehicleSystemsComponents.Vehicle.Electric
const _TH_OCV = [2.500, 3.296, 3.485, 3.581, 3.667, 3.751, 3.841, 3.948, 4.042, 4.097, 4.200]

function _th_pulse(; kwargs...)
    model = _TH.TestTheveninCell(; name = :pulse, kwargs...)
    sys = simplify_model(model)
    sol = solve(ODEProblem(sys, [], (0.0, 180.0)), Tsit5();
        tstops = [10.0, 40.0], reltol = 1e-9, abstol = 1e-11, dtmax = 0.5)
    return sol, sys
end

@testset "Thevenin pulse: ohmic step, polarization, recovery" begin
    run = _TH.TheveninPulseTransient()
    s, m = run.sol, symbolic_container(run)
    b = m.battery
    at(t, x) = s(t, idxs = x)
    @test string(s.retcode) == "Success"
    # 0.1 mV allows edge sampling/integration error, still ten times below 1 mV.
    drop = at(10 - 1e-5, b.v) - at(10 + 1e-5, b.v)
    sag = at(40 - 1e-5, b.v1)
    recovery = at(40 + 25.7, b.v1)
    @test drop ≈ 0.048 atol = 1e-4
    @test sag ≈ 30 * 0.00134 * (1 - exp(-30 / 25.7)) atol = 1e-4
    @test sag ≈ 0.0277 atol = 1e-4
    @test recovery ≈ sag / exp(1) atol = 1e-4
    @test at(40 + 1e-5, b.v) - at(40 - 1e-5, b.v) ≈ 0.048 atol = 1e-4
    @test at(180, b.v) ≈ at(180, b.E) atol = 2e-4
    @test at(180, b.SoC) ≈ 0.6 - 30 * 30 / (33.1 * 3600) atol = 1e-7
    ts = collect(40.001:0.1:180)
    relaxation = -s(ts, idxs = b.v1).u
    @test rise_time(ts, relaxation, 1 - exp(-1)) ≈ 25.7 atol = 0.2
    println("Thevenin pulse: R0 drop=$(1000drop) mV, RC sag=$(1000sag) mV, RC after tau=$(1000recovery) mV")
end

@testset "Thevenin OCV: table, monotonicity, clamped ends" begin
    volts = Float64[]
    for (soc, expected) in zip(-0.1:0.1:1.1, vcat(first(_TH_OCV), _TH_OCV, last(_TH_OCV)))
        s, m = _th_pulse(I_load = 0.0, SoC0 = soc, Ns = 96.0)
        @test string(s.retcode) == "Success"
        push!(volts, s[m.battery.v][end])
        @test volts[end] ≈ 96expected atol = 1e-9
        @test s[m.battery.E][end] ≈ volts[end] atol = 1e-9
    end
    @test all(diff(volts) .>= -1e-10)
    s, m = _th_pulse(I_load = 0.0, SoC0 = 0.55)
    @test s[m.battery.v][end] ≈ (3.751 + 3.841) / 2 atol = 1e-9
end

@testset "Thevenin reduces to Battery with flat OCV and R1 zero" begin
    flat = fill(350.0, 11, 2)
    s, m = _th_pulse(R1 = 0.0, Ns = 1.0, SoC0 = 0.9, ocv_data = flat)
    base = _TH.TestBattery(name = :base, I_load = 30.0, R0 = 0.0016,
        __overrides = Dict("battery.Q_nom" => 33.1 * 3600,
            "load_profile.start_time" => 10.0))
    bm = simplify_model(base)
    bs = solve(ODEProblem(bm, [], (0.0, 39.0)), Tsit5();
        tstops = [10.0], reltol = 1e-9, abstol = 1e-11, dtmax = 0.5)
    for t in (0.0, 5.0, 11.0, 25.0, 39.0)
        @test s(t, idxs = m.battery.v) ≈ bs(t, idxs = bm.battery.v) atol = 1e-9
        @test s(t, idxs = m.battery.SoC) ≈ bs(t, idxs = bm.battery.SoC) atol = 1e-7
    end
    @test maximum(abs, s[m.battery.v1]) < 1e-12
end


@testset "Lecture 4 WLTC with a drop-in Thevenin battery" begin
    planar = VehicleSystemsComponents.Vehicle.Planar
    metrics = []
    for analysis in (planar.PlanarBEVWLTCTransient, planar.PlanarBEVTheveninWLTCTransient)
        run = analysis()
        m, s = symbolic_container(run), run.sol
        @test string(s.retcode) == "Success"
        @test s.t[end] == 1800.0
        @test maximum(abs, 3.6 .* s[m.car.bus.vx] .- s[m.trace.y]) < 2.0
        cells, dc, soc = s[m.E_cells][end] / 3.6e6, s[m.E_dc][end] / 3.6e6, s[m.drive.SoC][end]
        push!(metrics, (; cells, dc, soc))
        if analysis === planar.PlanarBEVTheveninWLTCTransient
            @test s[m.E_cells][end] ≈ s[m.E_dc][end] + s[m.E_R0][end] + s[m.E_RC][end] rtol = 1e-8
        end
        println("WLTC $(nameof(analysis)): cells=$cells kWh, terminals=$dc kWh, final SoC=$soc")
        GC.gc()
    end
    baseline, thevenin = metrics
    # A 3% energy band and 1 percentage point SoC band test the requested comparability,
    # without treating the higher, SoC-dependent OCV as a constant 350 V source.
    @test thevenin.cells ≈ baseline.cells rtol = 0.03
    @test thevenin.dc ≈ baseline.dc rtol = 0.03
    @test thevenin.soc ≈ baseline.soc atol = 0.01
end
