using DyadInterface: simplify_model, symbolic_container
using ModelingToolkit
using OrdinaryDiffEqDefault: solve, Rodas5P

const _PT = VehicleSystemsComponents.Vehicle.Electric

function _pt_solve(model, stop; dtmax = 10.0)
    m = simplify_model(model)
    s = solve(ODEProblem(m, [], (0.0, stop)), Rodas5P();
        reltol = 1e-9, abstol = 1e-10, dtmax)
    @test string(s.retcode) == "Success"
    return s, m
end

function _pt_cross(s, x, value)
    @test s(s.t[end], idxs = x) >= value
    lo, hi = 0.0, s.t[end]
    for _ in 1:55
        mid = (lo + hi) / 2
        if s(mid, idxs = x) >= value
            hi = mid
        else
            lo = mid
        end
    end
    return hi
end

function _pt_energy(s, pack; T0 = 298.15)
    for t in range(1.0, s.t[end]; length = 40)
        stored = 303000 * (s(t, idxs = pack.T) - T0)
        # At rest the reference is zero; allow sub-millijoule cancellation of MJ terms.
        @test stored + s(t, idxs = pack.E_out) ≈ s(t, idxs = pack.E_in) rtol = 1e-6 atol = 1e-3
    end
end

@testset "Resistor heat, including zero R1 and zero current" begin
    for (current, r1) in ((143.0, 0.08375), (143.0, 0.0), (0.0, 0.08375))
        s, m = _pt_solve(_PT.TestThermalTheveninCell(name = :cell, I = current, R1 = r1), 200.0)
        expected = current^2 * (0.1 + r1 * (1 - exp(-200 / 25.7))^2)
        @test s[m.battery.dissipated][end] ≈ expected atol = 1e-6
        @test s[m.ambient.port.Q_flow][end] ≈ expected atol = 1e-6
        @test s[m.battery.heat_port.Q_flow][end] ≈ -expected atol = 1e-6
    end
end

@testset "Pack cooling, equilibrium, and optional coolant" begin
    for t0 in (298.15, 308.15)
        s, m = _pt_solve(_PT.TestPackThermal(name = :rest, T0 = t0), 151500.0; dtmax = 500.0)
        for t in (0.0, 15150.0, 151500.0)
            @test s(t, idxs = m.pack.T) ≈ 298.15 + (t0 - 298.15) * exp(-t / 15150) atol = 1e-7
        end
        @test s[m.pack.heat_port.Q_flow][end] == 0.0
        @test abs(s[m.pack.T][end] - 298.15) < 0.0005
        if t0 == 298.15
            @test maximum(abs, s[m.pack.air.Q_flow]) == 0.0
        end
        _pt_energy(s, m.pack; T0 = t0)
    end
    s, m = _pt_solve(_PT.TestPackThermal(name = :coolant,
        __overrides = Dict("pack.G_coolant" => 20.0)), 7575.0)
    @test s[m.pack.T][end] ≈ 298.15 + 10 / exp(1) atol = 1e-7
    _pt_energy(s, m.pack; T0 = 308.15)
end

@testset "Temperature derating law" begin
    d = _PT.ThermalDerating(name = :derating)
    ports = ModelingToolkit.toggle_namespacing(d, false)
    reduced = simplify_model(d; inputs = [ports.T], outputs = [ports.P_max])
    substitutions = Dict(eq.lhs => eq.rhs for eq in observed(reduced))
    merge!(substitutions, Dict(k => v for (k, v) in ModelingToolkit.get_bindings(reduced)
        if string(v) != "missing"))
    rhs = ModelingToolkit.Symbolics.unwrap(ModelingToolkit.toggle_namespacing(reduced, false).P_max)
    for _ in 1:length(substitutions)
        rhs = ModelingToolkit.Symbolics.substitute(rhs, substitutions)
    end
    defaults = ModelingToolkit.get_initial_conditions(reduced)
    internal = Dict(k => v for (k, v) in defaults if occursin('₊', string(k)))
    rhs = ModelingToolkit.Symbolics.substitute(rhs, internal)
    vars = collect(ModelingToolkit.Symbolics.get_variables(rhs))
    evaluate = ModelingToolkit.Symbolics.build_function(rhs, vars; expression = Val(false))
    for (temp, expected) in ((290.0, 50000.0), (305.15, 50000.0),
            (310.9, 37500.0), (316.65, 25000.0), (328.15, 0.0), (340.0, 0.0))
        values = Dict("T(t)" => temp, "P_full" => 50000.0,
            "T_start" => 305.15, "T_stop" => 328.15)
        @test evaluate([values[string(x)] for x in vars]) ≈ expected atol = 1e-7
    end
end

@testset "Adiabatic first, then passive air: INL checks are not a fit" begin
    # INL reports +6.5/+2.9 K for a 2012 24 kWh pack with unspecified windows.
    # This ZE1 10–80 % resistor-only model overpredicts DC and underpredicts AC.
    for (g, expected) in ((0.0, (18.63143, 1.61591)), (20.0, (17.05406, 0.64620)))
        s, m = _pt_solve(_PT.ThermalACvsDC(name = :comparison, G_air = g), 34000.0)
        for (sub, rise, label) in zip((m.dc, m.ac), expected, ("DC", "AC"))
            t80 = _pt_cross(s, sub.battery.SoC, 0.8)
            measured = s(t80, idxs = sub.thermal.T) - 298.15
            @test measured ≈ rise atol = 0.002
            @test s(t80, idxs = sub.battery.SoC) ≈ 0.8 atol = 1e-8
            @test minimum(s[sub.battery.dissipated]) >= 0.0
            @test maximum(s[sub.charger.current]) <= 143.0 + 1e-6
            _pt_energy(s, sub.thermal)
            println("$label G=$g W/K: t80=$t80 s, rise=$measured K, heat=$(s(t80, idxs=sub.thermal.E_in)) J")
        end
    end
end

@testset "Rapidgate continuous charge-drive-charge" begin
    run = _PT.RapidgateTwoChargesTransient()
    s, m = run.sol, symbolic_container(run)
    @test string(s.retcode) == "Success"
    t1, td, t2 = [_pt_cross(s, m.throughput, x) for x in (0.7, 1.4, 2.1)]
    peak1 = maximum(s(collect(range(0, t1; length = 1000)), idxs = m.thermal.T).u) - 273.15
    peak2 = maximum(s(collect(range(td, t2; length = 1000)), idxs = m.thermal.T).u) - 273.15
    @test t1 ≈ 2767.188 atol = 0.2
    @test t2 - td ≈ 5749.903 atol = 0.3
    @test peak1 ≈ 42.05406 atol = 0.002
    @test peak2 ≈ 46.73531 atol = 0.002
    @test t2 - td > t1
    @test peak2 > peak1 > 32.0
    for (t, soc) in ((t1, 0.8), (td, 0.1), (t2, 0.8))
        @test s(t, idxs = m.battery.SoC) ≈ soc atol = 3e-6
    end
    @test s((t1 + td) / 2, idxs = m.load.v) * s((t1 + td) / 2, idxs = m.load.i) ≈ 20000 atol = 1e-5
    @test s(1000.0, idxs = m.derating.P_max) < 50000.0
    _pt_energy(s, m.thermal)
    println("Rapidgate: first=$t1 s, peak=$peak1 C; second=$(t2-td) s, peak=$peak2 C; first derates")
end

@testset "Unset power input preserves original CC-CV bench" begin
    s, m = _pt_solve(_PT.CCCVLeafCharge(name = :unlimited), 8000.0; dtmax = 5.0)
    @test s(1.0, idxs = m.charger.current) ≈ 143.0 atol = 1e-5
    @test maximum(abs.(1e-5 .* s[m.charger.current] .-
        min.(143e-5, max.(0.0, 403.2 .- s[m.battery.v])))) < 1e-8
    @test s[m.charger.phase][end] == 3.0
    @test 0.99 < s[m.battery.SoC][end] < 1.0
end
