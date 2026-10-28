# Lecture 4 step 03 checkpoints: the simple battery, V = E − I·R with coulomb-counted SoC, on a
# constant-current discharge. The library battery and the hands-on 04 reference must both give
# the numbers the guide states, which are hand calculations from the Leaf ZE1 defaults.

using DyadInterface: symbolic_container

const _E4 = VehicleSystemsComponents.Vehicle.Electric
const _H4 = VehicleSystemsComponents.HandsOn04

# Leaf ZE1 pack: 350 V nominal and 40 kWh, so 114.3 A·h.
const _E_oc = 350.0
const _Q_nom = 40e3 * 3600 / 350
const _t_on, _t_end = 60.0, 1860.0
# The solver lands on the load step, but the last stages of the step that ends there already see
# the load; the counted charge carries that, measured at 3.5e-6 of SoC.
const _soc_atol = 1e-5

_soc_end(I) = 0.9 - I * (_t_end - _t_on) / _Q_nom
_trapz(t, y) = sum((y[1:end-1] .+ y[2:end]) ./ 2 .* diff(t))

function _discharge_traces(run)
    m = symbolic_container(run)
    s = run.sol
    return (; t = s.t, v = s[m.battery.v], i = s[m.battery.i], soc = s[m.battery.SoC],
        p_load = s[m.load.v] .* s[m.load.i])
end

@testset "Lecture 4 step 03: battery defaults are the Leaf ZE1 pack" begin
    run = _E4.BatteryTransient()
    m = symbolic_container(run)
    ps = run.sol.ps
    @test ps[m.battery.E] == 350.0
    @test ps[m.battery.Q_nom] / 3600 ≈ 114.29 atol = 0.01
    # The charge capacity and the open-circuit voltage give back the 40 kWh on the sticker.
    @test ps[m.battery.E] * ps[m.battery.Q_nom] / 3.6e6 ≈ 40.0 rtol = 1e-12
    # INL's mid-SoC band for the pack resistance, 0.10–0.14 Ω.
    @test 0.10 <= ps[m.battery.R0] <= 0.14
    @test run.sol[m.battery.SoC][1] == 0.9
end

@testset "Lecture 4 step 03: constant-current discharge at 100 A" begin
    lib = _E4.BatteryTransient()
    mine = _H4.BatteryDischargeTransient()
    for run in (lib, mine)
        (; t, v, i, soc, p_load) = _discharge_traces(run)
        before, during = t .< _t_on, t .>= _t_on
        # Open circuit: the terminals show E, and no current means no charge counted.
        @test all(v[before] .== _E_oc)
        @test all(soc[before] .== 0.9)
        # Under load the terminal voltage sags by I·R0 = 10 V, at once and for as long as it flows.
        @test all(isapprox.(i[during], 100.0; atol = 1e-9))
        @test all(isapprox.(v[during], 340.0; atol = 1e-9))
        # SoC falls on a straight line of slope −I/Q_nom: 0.4375 in 30 minutes.
        k = findfirst(during)
        @test (soc[end] - soc[k]) / (t[end] - t[k]) ≈ -100.0 / _Q_nom rtol = 1e-9
        @test soc[end] ≈ 0.4625 atol = _soc_atol
        # The energy chain closes: 17.0 kWh reach the load, 0.5 kWh burn in R0, and their sum is
        # the 17.5 kWh = 0.4375 × 40 kWh that the counted charge took out at E.
        W_load = _trapz(t, p_load) / 3.6e6
        W_loss = _trapz(t, 0.1 .* i .^ 2) / 3.6e6
        W_E = _E_oc * _Q_nom * (soc[1] - soc[end]) / 3.6e6
        @test W_load ≈ 17.0 atol = 1e-3
        @test W_loss ≈ 0.5 atol = 1e-4
        @test W_load + W_loss ≈ W_E rtol = 1e-4
    end
    # The reference solution is the library battery under another name.
    ts = range(0, _t_end, length = 1001)
    ml, mm = symbolic_container(lib), symbolic_container(mine)
    @test lib.sol(ts, idxs = ml.battery.v).u ≈ mine.sol(ts, idxs = mm.battery.v).u atol = 1e-9
    @test lib.sol(ts, idxs = ml.battery.SoC).u ≈ mine.sol(ts, idxs = mm.battery.SoC).u atol = 1e-12
end

@testset "Lecture 4 step 03: charging, other currents and a tired pack" begin
    # The sag is I·R0 at every current, and charging lifts the terminals above E.
    for (I, v_load) in ((-20.0, 352.0), (100.0, 340.0), (330.0, 317.0))
        for run in (_E4.BatteryTransient(I_load = I), _H4.BatteryDischargeTransient(I_load = I))
            (; t, v, i, soc) = _discharge_traces(run)
            during = t .>= _t_on
            @test all(isapprox.(v[during], v_load; atol = 1e-9))
            @test all(isapprox.(i[during], I; atol = 1e-9))
            @test soc[end] ≈ _soc_end(I) atol = _soc_atol
        end
    end
    # Charging: −20 A puts 0.0875 of SoC back, and the power flows into the battery.
    (; soc, p_load) = _discharge_traces(_H4.BatteryDischargeTransient(I_load = -20.0))
    @test soc[end] ≈ 0.9875 atol = _soc_atol
    @test p_load[end] ≈ -7040.0 atol = 1e-6
    # 330 A is about the ZE1's 110 kW: 104.6 kW at the terminals. Thirty minutes of it is 55 kWh
    # from a 40 kWh pack, and nothing in V = E − I·R stops it, so SoC runs through zero.
    (; v, i, soc) = _discharge_traces(_H4.BatteryDischargeTransient(I_load = 330.0))
    @test v[end] * i[end] / 1e3 ≈ 104.61 atol = 1e-6
    @test soc[end] ≈ -0.54375 atol = _soc_atol
    # Near empty the resistance is about 50 % higher (INL): the sag grows to 15 V, and the counted
    # charge does not change, because coulomb counting sees only the current.
    (; t, v, soc) = _discharge_traces(_E4.BatteryTransient(R0 = 0.15))
    @test all(isapprox.(v[t .>= _t_on], 335.0; atol = 1e-9))
    @test soc[end] ≈ 0.4625 atol = _soc_atol
end
