# Hands-on 03 checkpoints: the students' reference models against the library analyses the
# Lecture 3 deck quotes, and the numbers the hands-on deck states.

using DyadInterface: symbolic_container, ODEAlg

const _V = VehicleSystemsComponents.Vehicle
const _H3 = VehicleSystemsComponents.HandsOn03
const _G = 9.80665

# The notebook's rule: the slowest stop it can be, the locked one or one at `a_max`, plus margin.
_stop_time(mu, a_max = Inf) = 0.5 + 1.5 * 25 / min(0.7 * mu * _G, a_max) + 1.0

# The library analyses default to an automatic solver; explicit torque benches use Tsit5.
_tsit5 = (alg = ODEAlg.Tsit5(), dtmax = 1e-3)

function _max_speed_gap(a, b, stop)
    ma, mb = symbolic_container(a), symbolic_container(b)
    ts = range(0, stop, length = 2001)
    va = a.sol(ts, idxs = ma.body.mass.v).u
    vb = b.sol(ts, idxs = mb.body.mass.v).u
    return maximum(abs.(va .- vb))
end

@testset "Hands-on 03 braking_distance" begin
    # 25 m/s, 0.5 s of coasting at constant speed, then 8 m/s² to rest: 25²/16 = 39.0625 m.
    t = collect(range(0, 4, length = 400_001))
    v = [ti < 0.5 ? 25.0 : max(25.0 - 8.0 * (ti - 0.5), 0.0) for ti in t]
    s = [0.0; cumsum((v[1:end-1] .+ v[2:end]) ./ 2 .* diff(t))]
    # Stops counting at 0.5 m/s, (0.5)²/16 short of the full stop.
    @test _V.braking_distance(t, s, v) ≈ 25^2 / 16 - 0.5^2 / 16 atol = 1e-3
    @test _V.braking_distance(t, s, v; v_stop = 1e-9) ≈ 25^2 / 16 atol = 1e-3
    # Counted from t_brake: starting 0.25 s earlier adds 0.25 s at 25 m/s.
    @test _V.braking_distance(t, s, v; t_brake = 0.25) - _V.braking_distance(t, s, v) ≈ 6.25 atol = 1e-6
    @test_throws ErrorException _V.braking_distance(t[1:1000], s[1:1000], v[1:1000])
end

@testset "Hands-on 03 step 02: hydraulic pedal stop" begin
    for (mu, expected) in ((1.0, 43.7), (0.5, 85.1), (0.3, 136.8))
        stop = _stop_time(mu)
        run = _H3.PedalStopTransient(road_mu = mu, stop = stop)
        @test _V.braking_distance(run) ≈ expected atol = 0.1
    end
    run = _H3.PedalStopTransient()
    m = symbolic_container(run)
    t, kappa, v = run.sol.t, run.sol[m.wheel.kappa], run.sol[m.body.mass.v]
    @test t[findfirst(<(-0.99), kappa)] - 0.5 < 0.2
    @test 3.9 < t[findfirst(i -> t[i] > 0.5 && v[i] < 0.5, eachindex(t))] < 4.0
    @test maximum(run.sol[m.master.p_mc]) / 1e5 ≈ 89.0 rtol = 0.03
end

@testset "Hands-on 03 step 03: slip ABS" begin
    for (mu, expected) in ((1.0, 34.2), (0.5, 64.6), (0.3, 106.1))
        stop = _stop_time(mu)
        mine = _H3.ABSStopTransient(road_mu = mu, stop = stop)
        @test _V.braking_distance(mine) ≈ expected atol = 0.1
        @test _V.braking_distance(mine) < _V.braking_distance(_H3.PedalStopTransient(road_mu = mu, stop = stop))
        m = symbolic_container(mine)
        @test all(mine.sol[m.wheel.caliper_f.p] .<= mine.sol[m.master.p_mc] .+ 0.2e5)
        @test all(mine.sol[m.wheel.caliper_r.p] .<= mine.sol[m.master.p_mc] .+ 0.2e5)
    end

    inactive = _H3.ABSStopTransient(pedal = 0.3)
    baseline = _H3.PedalStopTransient(pedal = 0.3)
    @test _V.braking_distance(inactive) ≈ _V.braking_distance(baseline) atol = 0.1

    # Without the look-ahead the controller dumps 30 ms late, overshoots into sliding and stops
    # longer than the locked wheel.
    present = _H3.ABSStopTransient(T_p = 0.0)
    ahead = _H3.ABSStopTransient()
    @test _V.braking_distance(present) ≈ 53.4 atol = 0.1
    @test _V.braking_distance(present) > _V.braking_distance(_H3.PedalStopTransient())
    for run in (present, ahead)
        m = symbolic_container(run)
        t, v = run.sol.t, run.sol[m.body.mass.v]
        pressure = run.sol[m.wheel.caliper_f.p]
        win = (t .>= 1.0) .& (v .> 3.0)
        @test cycle_frequency(t[win], pressure[win]) > 1.0
        @test all(run.sol[m.abs.p_cmd] .>= 0.0)
    end
end

@testset "Hands-on 03 steps 04-05: wheel speed only" begin
    for (mu, mine_expected, lib_expected) in ((1.0, 38.56, 38.7), (0.5, 78.0, 83.2), (0.3, 130.6, 141.3))
        stop = _stop_time(mu, 8.0)
        mine = _V.braking_distance(_H3.ABSStopWheelOnlyTransient(road_mu = mu, stop = stop))
        lib = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = mu, stop, _tsit5...))
        baseline = _V.braking_distance(_H3.PedalStopTransient(road_mu = mu, stop = _stop_time(mu)))
        # The controller switches on thresholds every few milliseconds; 0.1 m absorbs solver drift.
        @test mine ≈ mine_expected atol = 0.1
        @test lib ≈ lib_expected atol = 0.05
        @test mine < baseline
    end
    # The trap is the library ECU's: on snow, a_ref = 8 makes it stop longer than the locked
    # wheel, and a_ref = 0.8 μ g brings it back under. The students' ABS dumps on the wheel's
    # deceleration, which needs no speed estimate, so a_ref = 8 does not trap it.
    baseline = _V.braking_distance(_H3.PedalStopTransient(road_mu = 0.3, stop = _stop_time(0.3)))
    lib_trap = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = 0.3, stop = _stop_time(0.3, 8.0), _tsit5...))
    lib_fixed = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = 0.3, a_ref = 2.4, stop = _stop_time(0.3, 2.4), _tsit5...))
    mine_fixed = _V.braking_distance(_H3.ABSStopWheelOnlyTransient(road_mu = 0.3, a_ref = 2.4, stop = _stop_time(0.3, 2.4)))
    @test lib_trap > baseline
    @test lib_fixed ≈ 128.4 atol = 0.05
    @test mine_fixed ≈ 130.9 atol = 0.1
    @test mine_fixed < baseline
    # An a_ref below the car's real deceleration lets the estimate run above the car, and the
    # slip trigger dumps on slip that is not there.
    @test _V.braking_distance(_H3.ABSStopWheelOnlyTransient(a_ref = 2.4, stop = _stop_time(1.0, 2.4))) ≈ 106.3 atol = 0.1

    for (mu, phases, f_dump) in ((1.0, (-1, 1), 9.2), (0.5, (-1, 0, 1), 4.1))
        run = _H3.ABSStopWheelOnlyTransient(road_mu = mu, stop = _stop_time(mu, 8.0))
        m = symbolic_container(run)
        t, v, phase, p = run.sol.t, run.sol[m.body.mass.v], run.sol[m.abs.phase], run.sol[m.abs.pressure.p]
        win = (t .>= 1.0) .& (v .> 3.0)
        # On a dry road the dump ends before the wheel turns round, so it never reaches HOLD.
        @test Set(round.(Int, phase[win])) == Set(phases)
        dumps = count(i -> win[i] && phase[i] < -0.5 && phase[i-1] > -0.5, 2:length(t))
        @test dumps / (t[win][end] - t[win][1]) ≈ f_dump atol = 0.3
        held = [win[i] && win[i-1] && abs(phase[i]) < 0.5 && abs(phase[i-1]) < 0.5 for i in 2:length(t)]
        @test maximum(abs.(diff(p)[held]); init = 0.0) < 1e-9
        cmd, demand = run.sol[m.abs.p_cmd], run.sol[m.master.p_mc]
        active = run.sol[m.abs.cycled] .> 0.5
        @test all(cmd[active] .<= demand[active] .+ 1e-6)
    end

    # On a dry road a_ref = 8 is below the car's deceleration, so the estimate runs above the car;
    # on a wet one it is above it, and the estimate rides the slipping wheel down below the car.
    for (mu, above) in ((1.0, true), (0.5, false))
        run = _H3.ABSStopWheelOnlyTransient(road_mu = mu, stop = _stop_time(mu, 8.0))
        m = symbolic_container(run)
        t, v_ref, v = run.sol.t, run.sol[m.est.v_ref], run.sol[m.body.mass.v]
        win = (t .>= 1.0) .& (v .> 3.0)
        share = sum(above ? v_ref[win] .> v[win] : v_ref[win] .<= v[win] .+ 1e-6) / count(win)
        @test share > 0.85
    end
end
