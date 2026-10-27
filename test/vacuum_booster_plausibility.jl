# Brake plan increments 2b and 2c: the dynamic vacuum booster against PATH's traces and the
# plan's reality bands, its coupling to the air path and the electric pump, and the Lecture 3
# bench beside the hands-on benches it must leave unchanged.
#
# Bands the model misses with its PATH and assumed defaults are `@test_broken`, so they stay
# visible and turn into an "Unexpected Pass" once the defaults are retuned.
#
# Alone: julia +dyad-3.5.0 --project=. -e 'using Test, VehicleSystemsComponents;
#     include("test/plausibility_helpers.jl"); include("test/vacuum_booster_plausibility.jl")'

using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container

const _VB = VehicleSystemsComponents.Vehicle.Brake
const _VV = VehicleSystemsComponents.Vehicle
const _VL3 = VehicleSystemsComponents.Lecture3
const _P_ATM = 101325.0

# StaticBooster's characteristic at its defaults, for the comparison.
_static_F_out(F_in; p_vac = 33e3) =
    max(0.0, F_in < 40.0 ? 0.0 : min(500.0 + 5.0 * (F_in - 40.0), F_in + 0.0533 * (_P_ATM - p_vac) - 97.0))

# 10-90 % rise of `y` from its value at `t0` to its value at `t1`.
function _rise_10_90(t, y, t0, t1)
    i0, i1 = findfirst(>=(t0), t), findfirst(>=(t1), t)
    y0, y1 = y[i0], y[i1]
    cross(f) = t[findfirst(k -> k >= i0 && (y[k] - y0 - f * (y1 - y0)) * sign(y1 - y0) >= 0, eachindex(t))]
    return cross(0.9) - cross(0.1)
end

@testset "Vacuum booster 2b: constant vacuum" begin
    @testset "TestBoosterPATH: 375 N pushrod ramp at 33 kPa" begin
        run = _VB.BoosterPATHTransient()
        m = symbolic_container(run)
        t, p_r, p_f = run.sol.t, run.sol[m.booster.p_r], run.sol[m.booster.p_f]
        @test string(run.sol.retcode) == "Success"
        @test p_r[1] ≈ 33e3 atol = 1e3
        @test p_f[1] ≈ 33e3 atol = 1e3
        # PATH's rear chamber reaches 72-74 kPa; with the assumed servo ratio and jump-in the
        # model's apply branch needs about 4 kPa less.
        @test_broken 70e3 <= maximum(p_r) <= 76e3
        @test 35e3 <= maximum(p_f) <= 41e3
        @test abs(p_f[end] - 33e3) < 1e3
    end

    @testset "TestBoosterCharacteristic: slow triangle past run-out" begin
        run = _VB.BoosterCharacteristicTransient()
        m = symbolic_container(run)
        t, F_in, F_out = run.sol.t, run.sol[m.booster.F_in], run.sol[m.booster.F_out]
        p_r, p_mc = run.sol[m.booster.p_r], run.sol[m.master.p_mc]
        apply_err, mid_err = Float64[], Float64[]
        for F in 150.0:50.0:750.0
            ia = findfirst(k -> t[k] < 10.5 && F_in[k] >= F, eachindex(t))
            ir = findfirst(k -> t[k] > 10.5 && F_in[k] <= F, eachindex(t))
            s = _static_F_out(F)
            push!(apply_err, F_out[ia] / s - 1)
            push!(mid_err, (F_out[ia] + F_out[ir]) / 2 / s - 1)
            # The loop stays open on release by about SR·(F_app + F_rel).
            @test F_out[ir] - F_out[ia] > 50.0
        end
        @test maximum(abs, mid_err) < 0.05
        # The apply branch trails StaticBooster by about SR·(F_app + F_w/2) = 100 N, which is
        # just over 5 % at the bottom of the boosted region.
        @test_broken maximum(abs, apply_err) < 0.05
        i_runout = findfirst(k -> t[k] < 10.5 && p_r[k] >= _P_ATM - 1e3, eachindex(t))
        @test 80e5 <= p_mc[i_runout] <= 100e5
    end

    @testset "TestBoosterStep: rear-chamber rise after a 200 N pedal step" begin
        run = _VB.BoosterStepTransient()
        m = symbolic_container(run)
        @test 0.1 <= _rise_10_90(run.sol.t, run.sol[m.booster.p_r], 0.5, 2.4) <= 0.4
    end
end

# Assist available before each application: A_d·(p_atm − p_f) − F_rs0.
_assist_before(run, m, starts) = [run.sol(a - 1e-3, idxs = m.booster.F_assist_max) for a in starts]

@testset "Vacuum booster 2c: manifold, reserve and pump" begin
    @testset "BrakeVacuumIdleTransient: release bump" begin
        run = _VB.BrakeVacuumIdleTransient()
        m = symbolic_container(run)
        t, p_m = run.sol.t, run.sol[m.air.p_m]
        p_idle = run.sol(0.99, idxs = m.air.p_m)
        t_release = 3.0
        after = t .>= t_release
        @test maximum(p_m[after]) - p_idle > 5e3
        i_last = findlast(k -> abs(p_m[k] - p_idle) > 2e3, eachindex(t))
        @test t[i_last] - t_release < 2.0
    end

    starts = 1.0 .+ 4.0 .* (0:4)
    off = _VB.BrakeVacuumReserveTransient()
    m_off = symbolic_container(off)
    assist_off = _assist_before(off, m_off, starts)
    @testset "BrakeVacuumReserveTransient: engine off" begin
        # The shut check valve keeps the front chamber's air, so each release mixes it with a
        # rear chamber full of atmosphere: Δ' = (V_f0·Δ − p_atm·A_d·x)/(V_f0 + V_r0), Δ = p_atm − p_f.
        # From 33 kPa at x = 8 mm that is 3.5, 2.2, 1.0 kN, then none.
        expected = [3.5e3, 2.2e3, 1.0e3]
        @test all(isapprox.(assist_off[1:3], expected; rtol = 0.15))
        @test assist_off[4] < 0.5e3
        @test 2 <= count(>(1.0e3), assist_off) <= 3
    end

    @testset "BrakeVacuumWOTTransient: like engine off" begin
        wot = _VB.BrakeVacuumWOTTransient()
        m = symbolic_container(wot)
        assist_wot = _assist_before(wot, m, starts)
        @test all(isapprox.(assist_wot[1:3], assist_off[1:3]; rtol = 0.02))
    end

    @testset "EVVacuumPumpTransient: pump-down and cycling" begin
        run = _VB.EVVacuumPumpTransient()
        m = symbolic_container(run)
        t, p_f, y = run.sol.t, run.sol[m.booster.p_f], run.sol[m.pump.y]
        @test 5.0 <= t[findfirst(<=(50e3), p_f)] <= 7.5
        switches = [k for k in 2:length(t) if (y[k-1] < 0.5) != (y[k] < 0.5)]
        @test length(switches) >= 2
        for k in switches
            if y[k] < 0.5
                @test p_f[k] < 17e3 + 200.0
            else
                @test p_f[k] > 40e3 - 200.0
            end
        end
    end
end

@testset "Lecture 3 VacuumPedalStop" begin
    pedal_stop = VehicleSystemsComponents.HandsOn03.PedalStopTransient
    static = pedal_stop(pedal = 0.3)
    idle = _VL3.VacuumPedalStopTransient()
    d_idle = _VV.braking_distance(idle)
    @test d_idle ≈ 36.0 rtol = 0.10
    @test d_idle > _VV.braking_distance(static)
    m_s, m_v = symbolic_container(static), symbolic_container(idle)
    rise_s = _rise_10_90(static.sol.t, static.sol[m_s.master.p_mc], 0.5, 2.0)
    rise_v = _rise_10_90(idle.sol.t, idle.sol[m_v.master.p_mc], 0.5, 2.0)
    @test rise_v > rise_s + 0.1

    @test _VV.braking_distance(pedal_stop()) ≈ 43.708 atol = 1e-3
    @test _VV.braking_distance(static) ≈ 35.958 atol = 1e-3
    @test _VV.braking_distance(_VV.IdealBrakeTransient()) ≈ 34.4453 atol = 1e-4
    @test _VV.braking_distance(_VV.ABSBrakeTransient()) ≈ 38.6980 atol = 1e-4
end
