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
    reached = s(s.t[end], idxs = x) >= value
    @test reached
    reached || error("Crossing target $value was not reached")
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

function _pt_energy(s, pack; T0 = 298.15, C = 250000.0)
    for t in range(1.0, s.t[end]; length = 40)
        stored = C * (s(t, idxs = pack.T) - T0)
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

@testset "Arrhenius fit range and fixed polarization time" begin
    for temp in (283.15, 313.15)
        s, m = _pt_solve(_PT.TestThermalTheveninCell(name = :temperature,
            __overrides = Dict("ambient.T" => temp)), 200.0)
        factor = exp(12500.0 / 8.314 * (1 / temp - 1 / 298.15))
        ratio = s[m.battery.ohmic.R_actual][end] / 0.1
        @test ratio ≈ factor rtol = 1e-12
        @test s[m.battery.polarization.R_actual][end] / 0.08375 ≈ factor rtol = 1e-12
        @test s(25.7, idxs = m.battery.v1) ≈ -143 * 0.08375 * factor * (1 - exp(-1)) atol = 1e-6
        if temp == 283.15
            # ORNL's cold R0 ratio is 1.65; the single-Ea fit does not capture the colder slope.
            @test 1.30 < ratio < 1.40
            println("Arrhenius R(10 C)/R(25 C): $ratio; ORNL cold R0 measurement approximately 1.65")
        end
    end
end

@testset "Pack cooling, equilibrium, and optional coolant" begin
    for t0 in (298.15, 308.15)
        s, m = _pt_solve(_PT.TestPackThermal(name = :rest, T0 = t0), 250000.0; dtmax = 500.0)
        for t in (0.0, 25000.0, 250000.0)
            @test s(t, idxs = m.pack.T) ≈ 298.15 + (t0 - 298.15) * exp(-t / 25000) atol = 1e-7
        end
        @test s[m.pack.heat_port.Q_flow][end] == 0.0
        @test abs(s[m.pack.T][end] - 298.15) < 0.0005
        if t0 == 298.15
            @test maximum(abs, s[m.pack.air.Q_flow]) == 0.0
        end
        if t0 > 298.15
            tau = -25000.0 / log((s(25000.0, idxs = m.pack.T) - 298.15) / (t0 - 298.15))
            @test 4.5 < tau / 3600 < 8.0
            println("Rest time constant: $(tau / 3600) h")
        end
        _pt_energy(s, m.pack; T0 = t0)
    end
    s, m = _pt_solve(_PT.TestPackThermal(name = :coolant,
        __overrides = Dict("pack.G_coolant" => 20.0)), 250000.0 / 30.0)
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

@testset "ZE1 field window, not the smaller INL pack" begin
    s, m = _pt_solve(_PT.ThermalACvsDC(name = :comparison,
        __overrides = Dict("ac.battery.Q_nom" => 66.2 * 3600,
            "ac.battery.R0" => 0.077, "ac.battery.R1" => 0.065,
            "ac.thermal.cp" => 230000.0 / 303.0)), 34000.0)
    for (sub, bounds, label, capacity) in ((m.dc, (15.0, 22.0), "ZE1 DC", 250000.0),
            (m.ac, (0.0, 1.0), "INL-like AC 3.3 kW", 230000.0))
        t80 = _pt_cross(s, sub.battery.SoC, 0.8)
        rise = s(t80, idxs = sub.thermal.T) - 298.15
        # ZE1 field reports are secondary; INL's +2.9 K AC mean includes Phoenix ambient swing.
        @test bounds[1] < rise < bounds[2]
        @test s(t80, idxs = sub.battery.SoC) ≈ 0.8 atol = 1e-8
        @test minimum(s[sub.battery.dissipated]) >= 0.0
        @test s(t80, idxs = sub.battery.ohmic.R_actual) < 0.1
        @test s(t80, idxs = sub.battery.polarization.R_actual) < 0.08375
        @test maximum(s[sub.charger.current]) <= 143.0 + 1e-6
        @test s(t80, idxs = sub.battery.polarization.R_actual) /
            s(t80, idxs = sub.battery.ohmic.R_actual) ≈ (capacity == 250000.0 ? 0.08375 / 0.1 : 0.065 / 0.077) rtol = 1e-12
        _pt_energy(s, sub.thermal; C = capacity)
        println("$label: t80=$t80 s, rise=$rise K")
    end
end

@testset "INL-like 24 kWh, near empty to full, 120 A then 395 V CV" begin
    # The older 66.2 Ah pack is a parameter configuration, not a ZE1 calibration.
    # INL Fig. 6 evening charge starts at 32 C; use constant 32 C ambient, not a daily swing.
    s, m = _pt_solve(_PT.ThermalCharge(name = :inl, I_cc = 120.0, T0 = 305.15,
        __overrides = Dict("thermal.T_ambient" => 305.15,
            "battery.Q_nom" => 66.2 * 3600, "battery.SoC0" => 0.05,
            "battery.R0" => 0.077, "battery.R1" => 0.065,
            "thermal.cp" => 230000.0 / 303.0, "charger.V_max" => 395.0,
            "charger.I_cut" => 66.2 / 50)), 8000.0)
    # Full means the 395 V CV endpoint at C/50, not 100 % on the ZE1 proxy OCV table.
    full = _pt_cross(s, -m.charger.current, -66.2 / 50)
    rise = s(full, idxs = m.thermal.T) - 305.15
    @test 6.0 < rise < 10.0
    @test s(1.0, idxs = m.charger.current) ≈ 120.0 atol = 1e-5
    @test s(0.9 * full, idxs = m.charger.phase) == 2.0
    @test s[m.charger.phase][end] == 3.0
    @test 0.90 < s(full, idxs = m.battery.SoC) < 1.0
    @test s(full, idxs = m.charger.v) ≈ 395.0 atol = 0.002
    _pt_energy(s, m.thermal; C = 230000.0, T0 = 305.15)
    println("INL-like: CV endpoint=$full s, SoC=$(s(full, idxs=m.battery.SoC)), rise=$rise K")
end

@testset "Zero activation energy retains the fixed-resistance bench" begin
    s, m = _pt_solve(_PT.ThermalCharge(name = :fixed, Ea = 0.0, G_air = 20.0,
        __overrides = Dict("thermal.cp" => 1000.0)), 4000.0)
    @test all(==(0.1), s[m.battery.ohmic.R_actual])
    @test all(==(0.1 * 1.34 / 1.60), s[m.battery.polarization.R_actual])
    t80 = _pt_cross(s, m.battery.SoC, 0.8)
    for t in (1.0, 25.7, 200.0)
        current = s(t, idxs = m.battery.stored_current)
        @test s(t, idxs = m.battery.dissipated) ≈
            0.1 * current^2 + s(t, idxs = m.battery.v1)^2 / (0.1 * 1.34 / 1.60) atol = 1e-8
    end
    @test t80 ≈ 2767.188157534367 atol = 0.002
    @test s(t80, idxs = m.thermal.T) - 298.15 ≈ 17.054060753112708 atol = 2e-5
    _pt_energy(s, m.thermal; C = 303000.0)
end

@testset "Rapidgate continuous charge-drive-charge" begin
    run = _PT.RapidgateTwoChargesTransient()
    s, m = run.sol, symbolic_container(run)
    @test string(s.retcode) == "Success"
    t1, td, t2 = [_pt_cross(s, m.throughput, x) for x in (0.7, 1.4, 2.1)]
    peak1 = maximum(s(collect(range(0, t1; length = 1000)), idxs = m.thermal.T).u) - 273.15
    peak2 = maximum(s(collect(range(td, t2; length = 1000)), idxs = m.thermal.T).u) - 273.15
    @test 35 * 60 < t1 < 60 * 60
    @test 60 * 60 < t2 - td < 130 * 60
    @test 40.0 < peak1 < 47.0
    @test 43.0 < peak2 < 52.0
    @test t2 - td > 1.25 * t1
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
