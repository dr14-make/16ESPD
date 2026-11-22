using DyadInterface: symbolic_container, simplify_model
using ModelingToolkit
using OrdinaryDiffEqDefault: solve, Tsit5, Rodas5P, ContinuousCallback, NoInit, terminate!, remake

const _BAL = VehicleSystemsComponents.Vehicle.Electric

# [BALANCING-BENCH] (assumed): C/10 cycling, 0.10 A top-up for two hours,
# 3.0 V discharge cutoff. 4.20 V is the [CHEN-2020] NMC stand-in (verified),
# not a claimed Leaf charge specification; the low-current phase is not a CV regulator.

@testset "Bleed physics and balancing time" begin
    run = _BAL.BleedTransient()
    s, m = run.sol, symbolic_container(run)
    @test string(s.retcode) == "Success"
    @test s(5, idxs = m.battery.I_bleed) == 0
    @test s(11, idxs = m.battery.I_bleed) ≈ 0.240 atol = 0.001
    @test s(5100, idxs = m.battery.cell.SoC) ≈ 0.43 atol = 0.0003
    ts = collect(10.0:1.0:5100.0)
    soc = s(ts, idxs = m.battery.cell.SoC).u
    t_percent = ts[findfirst(x -> x <= 0.43, soc)] - 10
    @test t_percent / 3600 ≈ 1.4 atol = 0.04
    for t in (11.0, 100.0, 5000.0)
        @test s(t, idxs = m.battery.cell.i) ≈ s(t, idxs = m.battery.I_bleed) atol = 1e-10
        @test s(t, idxs = m.battery.P_bleed) ≈ s(t, idxs = m.battery.ambient.port.Q_flow) atol = 1e-10
    end
    @test 0.240 <= 3.7 / (3.7 / 0.260) <= 0.300
    @test 0.240 <= 4.20 / (3.7 / 0.260) <= 0.300
    println("Bleeding 1% of 33.1 Ah: $(t_percent / 3600) h; initial current $(s(11, idxs=m.battery.I_bleed)) A")
end

@testset "Balancer thresholds, gate, and hysteresis memory" begin
    run = _BAL.BalancerTransient()
    s, m = run.sol, symbolic_container(run)
    @test s(50, idxs = m.channel.bleed) ≈ 1 atol = 1e-6
    @test s(110, idxs = m.channel.bleed) == 0
    for (voltage, minimum) in ((4.107, 4.10), (4.104, 4.10), (3.99, 3.95))
        raw = _BAL.TestPassiveBalancer(name = :threshold, voltage = voltage, minimum_voltage = minimum)
        sys = simplify_model(raw)
        off = solve(ODEProblem(sys, [], (0.0, 50.0)), Tsit5(); reltol = 1e-8, abstol = 1e-10)
        @test maximum(abs, off[sys.channel.bleed]) < 1e-8
    end
    sys = simplify_model(_BAL.TestPassiveBalancer(name = :memory))
    on = solve(ODEProblem(sys, [], (0.0, 50.0)), Tsit5(); reltol = 1e-8, abstol = 1e-10)
    held = solve(ODEProblem(sys, merge(Dict(unknowns(sys) .=> on.u[end]),
        Dict(sys.voltage => 4.107)), (50.0, 90.0); algebraic_only = true),
        Tsit5(); reltol = 1e-8, abstol = 1e-10)
    @test minimum(held[sys.channel.bleed]) > 0.999
    reset = solve(ODEProblem(sys, merge(Dict(unknowns(sys) .=> held.u[end]),
        Dict(sys.voltage => 4.104)), (90.0, 99.0); algebraic_only = true),
        Tsit5(); reltol = 1e-8, abstol = 1e-10)
    @test reset[sys.channel.bleed][end] < 0.2
end

function _bal_cycles(enabled; cycles = 3)
    sys = simplify_model(_BAL.BalancingString(name = :string))
    cells = [getproperty(sys, Symbol("c$i")) for i in 1:4]
    prob = ODEProblem(sys, [], (0.0, 40000.0))
    rows = []
    function stage(prob, current, gate, duration; limit = nothing, upper = true)
        # Carry only differential states; algebraic voltages must follow the new current.
        op = Dict{Any, Any}(unknowns(sys)[i] => prob.u0[i]
            for i in eachindex(prob.u0) if prob.f.mass_matrix[i, i] != 0)
        op[sys.I_string] = current
        op[sys.balancing] = gate
        p = ODEProblem(sys, op, (0.0, duration); algebraic_only = true)
        if limit === nothing
            return solve(p, Rodas5P(); reltol = 1e-8, abstol = 1e-10, dtmax = 30.0)
        end
        voltage = upper ? sys.v_max : sys.v_min
        condition(u, t, integrator) = p.f.observed(voltage, u, p.p, t) - limit
        stop!(integrator) = terminate!(integrator)
        # A stop changes no states; default event initialization would reset the cells.
        cb = upper ? ContinuousCallback(condition, stop!, nothing; initializealg = NoInit()) :
                     ContinuousCallback(condition, nothing, stop!; initializealg = NoInit())
        solve(p, Rodas5P(); callback = cb, reltol = 1e-8, abstol = 1e-10, dtmax = 30.0)
    end
    for cycle in 1:cycles
        cc = stage(prob, -3.31, 0.0, 40000.0; limit = 4.20)
        @test string(cc.retcode) == "Terminated"
        @test cc[sys.v_max][end] ≈ 4.20 atol = 1e-7
        cc_spread = maximum(cc[c.cell.SoC][end] for c in cells) - minimum(cc[c.cell.SoC][end] for c in cells)
        top = cc
        if enabled
            # 0.10 A is below the shunt current; the leading cells can lose net charge.
            top = stage(remake(cc.prob; u0 = cc.u[end]), -0.10, 1.0, 7200.0; limit = 4.20)
            @test string(top.retcode) in ("Success", "Terminated")
            @test maximum(top[sys.v_max]) <= 4.20001
        end
        spread = maximum(top[c.cell.SoC][end] for c in cells) - minimum(top[c.cell.SoC][end] for c in cells)
        volts = maximum(top[c.v][end] for c in cells) - minimum(top[c.v][end] for c in cells)
        discharge = stage(remake(top.prob; u0 = top.u[end]), 3.31, 0.0, 40000.0;
            limit = 3.0, upper = false)
        @test string(discharge.retcode) == "Terminated"
        @test discharge[sys.v_min][end] ≈ 3.0 atol = 1e-7
        ah = discharge[sys.Ah_out][end] - discharge[sys.Ah_out][1]
        @test 25 < ah < 34
        push!(rows, (; cycle, cc_spread, spread, volts, ah))
        println("balancing=$enabled cycle=$cycle CC spread=$cc_spread top spread=$spread voltage spread=$volts V usable=$ah Ah")
        prob = remake(discharge.prob; u0 = discharge.u[end])
    end
    rows
end

@testset "Four-cell cycling: fullest-cell charge limit and usable string capacity" begin
    without = _bal_cycles(false)
    with = _bal_cycles(true)
    @test all(r.spread > 0.09 for r in without)
    @test all(diff([r.spread for r in with]) .< -0.005)
    @test all(with[i].spread < without[i].spread for i in 1:3)
    @test all(with[i].ah > without[i].ah for i in 1:3)
    @test with[end].spread < 0.5 * without[end].spread
    @test with[end].ah > with[1].ah
end
