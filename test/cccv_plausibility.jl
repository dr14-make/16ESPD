using DyadInterface: simplify_model
using ModelingToolkit
using OrdinaryDiffEqDefault: solve, Rodas5P

const _CC = VehicleSystemsComponents.Vehicle.Electric

@testset "Plain Dyad components" begin
    root = joinpath(@__DIR__, "..", "dyad")
    @test all(!occursin(r"\bexternal\s+component\b", read(joinpath(dir, file), String))
        for (dir, _, files) in walkdir(root) for file in files)
end

function _cc_check(model, ns, r0, r1, icc, vmax; label)
    m = simplify_model(model)
    s = solve(ODEProblem(m, [], (0.0, 8000.0)), Rodas5P();
        reltol = 1e-8, abstol = 1e-10, dtmax = 5.0)
    b, c = m.battery, m.charger
    at(t, x) = s(t, idxs = x)
    @test string(s.retcode) == "Success"
    phases = s[c.phase]
    transitions = findall(j -> phases[j] != phases[j - 1], 2:length(phases)) .+ 1
    @test phases[1] == 1
    @test phases[end] == 3
    @test length(transitions) == 2
    function first_crossing(predicate)
        j = findfirst(predicate, s.t)
        @test j !== nothing && j > 1
        lo, hi = s.t[j - 1], s.t[j]
        for _ in 1:50
            mid = (lo + hi) / 2
            if predicate(mid)
                hi = mid
            else
                lo = mid
            end
        end
        return hi
    end
    rreg, icut = 1e-5, (40000 / 350) / 50
    tc = first_crossing(t -> at(t, b.v) > vmax - icc * rreg)
    td = first_crossing(t -> at(t, c.current) < icut)
    @test phases[transitions] == [2, 3]
    @test at(1.0, c.current) ≈ icc atol = 1e-5
    @test at(tc / 2, c.current) ≈ icc atol = 1e-5
    switch_ocv = at(tc, b.E) / ns
    @test switch_ocv ≈ (vmax - icc * (r0 + r1)) / ns atol = 3e-5
    @test at(tc, b.v) ≈ vmax atol = 0.003
    ts = sort(unique(vcat(collect(0.0:0.5:8000.0), s.t)))
    volts = s(ts, idxs = b.v).u
    currents = s(ts, idxs = c.current).u
    soc = s(ts, idxs = b.SoC).u
    @test maximum(volts) <= vmax + 0.003
    @test minimum(currents) >= -1e-7
    # Dense interpolation of the algebraic voltage need not satisfy the current constraint.
    @test maximum(s[c.current]) <= icc + 1e-5
    cv = collect(range(tc + 0.01, td - 0.01; length = 1000))
    @test all(diff(s(cv, idxs = c.current).u) .<= 1e-5)
    @test maximum(abs.(s(cv, idxs = b.v).u .- vmax)) < 0.003
    @test at(td, c.current) ≈ icut atol = 1e-7
    @test at(td - 0.001, c.current) > icut
    @test 0.0 < at(td + 0.001, c.current) < icut
    @test at(td - 0.001, c.phase) == 2
    @test at(td + 0.001, c.phase) == 3
    @test all(0.0 .< s(collect(td + 1:1:8000), idxs = c.current).u .< icut)
    @test maximum(abs.(rreg .* s[c.current] .-
        min.(icc * rreg, max.(0.0, vmax .- s[b.v])))) < 1e-8
    @test s(ts, idxs = c.phase).u ==
        ifelse.(currents .< icut, 3.0, ifelse.((vmax .- volts) ./ rreg .>= icc, 1.0, 2.0))
    @test 0.99 < soc[end] < 1.0
    @test all(diff(soc) .>= -1e-9)
    @test 0.99 < at(td, b.SoC) < soc[end]
    @test at(td + 10, b.SoC) < soc[end]
    @test at(tc, b.SoC) ≈ 0.1 + icc * tc / (40000 * 3600 / 350) atol = 1e-7
    @test maximum(abs.(s(ts, idxs = b.i).u .+ currents)) < 1e-8
    @test maximum(abs.(s(ts, idxs = c.p.i).u .+ s(ts, idxs = b.p.i).u)) < 1e-8
    println("$label: switch OCV=$switch_ocv V/cell, IR/cell=$(icc*r0/ns) V, " *
        "CC=$tc s, CV=$(td-tc) s, done=$td s, final SoC=$(soc[end]), " *
        "max terminal=$(maximum(volts)) V, cutoff=$(at(td-0.001,c.current)) A")
    return switch_ocv
end

@testset "CC-CV Leaf resistance-only slide" begin
    ocv = _cc_check(_CC.CCCVLeafCharge(name = :leaf_r0, R1 = 0.0),
        96, 0.1, 0.0, 143.0, 403.2; label = "Leaf R1=0")
    @test ocv ≈ 4.05 atol = 0.005
end

@testset "CC-CV Leaf with polarization" begin
    ocv = _cc_check(_CC.CCCVLeafCharge(name = :leaf_rc),
        96, 0.1, 0.1 * 1.34 / 1.60, 143.0, 403.2; label = "Leaf default RC")
    @test ocv ≈ 3.9263 atol = 0.0001
end

@testset "CC-CV 800 V exercise" begin
    ocv = _cc_check(_CC.CCCV800V(name = :pack800),
        192, 0.2, 0.0, 250.0, 806.4; label = "800 V")
    @test ocv ≈ 3.94 atol = 0.005
    @test 250 * 0.2 / 192 ≈ 0.26 atol = 0.001
end


@testset "CC-CV Studio transient analyses" begin
    for analysis in (_CC.CCCVLeafChargeTransient, _CC.CCCV800VTransient)
        run = analysis()
        @test string(run.sol.retcode) == "Success"
        @test run.sol.t[end] == 8000.0
    end
end
