using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container

const _EL3 = VehicleSystemsComponents.Lecture3

"First time after `t0` at which `signal` reaches `level`, linearly interpolated, minus `t0`."
function esp_time_to(sol, signal, level, t0)
    t, y = sol.t, sol[signal]
    i = findfirst(k -> t[k] >= t0 && y[k] >= level, eachindex(t))
    isnothing(i) && return Inf
    return t[i-1] + (level - y[i-1]) / (y[i] - y[i-1]) * (t[i] - t[i-1]) - t0
end

# Bands are soft: no primary active-build figure exists. The warm time to lock is fitted (the
# pump displacement is chosen for it), so its band only guards the fit; the 300–360 ms target
# comes from docs/lecture-03-esp-active-build.md. The remaining bands bracket model behavior that
# follows from the parts, widened for parameter drift.
@testset "ESP active pressure build" begin
    t_build = 0.05

    warm = _EL3.ESPActiveBuildTransient()
    mw = symbolic_container(warm)
    sw = warm.sol
    p_lock = sw.ps[mw.p_lock] / 1e5
    @test p_lock ≈ 52.2 atol = 0.1

    t50 = esp_time_to(sw, mw.p_wheel_bar, 50.0, t_build)
    t100 = esp_time_to(sw, mw.p_wheel_bar, 100.0, t_build)
    t_lock = esp_time_to(sw, mw.p_wheel_bar, p_lock, t_build)
    @test 0.25 <= t_lock <= 0.45
    @test 0.25 <= t50 <= t_lock
    @test t_lock < t100 <= 0.6
    @test 150 <= 100 / t100 <= 400
    @test 135 <= maximum(sw[mw.p_wheel_bar]) <= 145

    # Hold: the closed inlet valve traps the wheel pressure.
    @test abs(sw(0.95, idxs = mw.p_wheel_bar) - sw(0.77, idxs = mw.p_wheel_bar)) < 1.0
    # Release: the wheel empties, and the accumulator never gives fluid it does not hold.
    @test sw[mw.p_wheel_bar][end] < 1.0
    @test minimum(sw[mw.circuit.V_lpa]) > -1e-9

    cold = _EL3.ESPActiveBuildColdTransient()
    mc = symbolic_container(cold)
    sc = cold.sol
    t_lock_cold = esp_time_to(sc, mc.p_wheel_bar, p_lock, t_build)
    @test sc.ps[mc.nu] == 1800e-6
    @test isfinite(t_lock_cold)
    @test t_lock_cold >= 3 * t_lock
    @test esp_time_to(sc, mc.p_wheel_bar, 50.0, t_build) >= 3 * t50
    @test maximum(sc[mc.p_wheel_bar]) <= 145
    @test minimum(sc[mc.circuit.V_lpa]) > -1e-9

    # De-energized valves with the pump running: the switchover valve vents the pump to the master
    # cylinder and the closed high-pressure valve starves it, so no pressure builds.
    passive = _EL3.ESPActiveBuildTransient(energize_valves = 0.0)
    mp = symbolic_container(passive)
    @test maximum(passive.sol[mp.p_wheel_bar]) < 0.1
end
