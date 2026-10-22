# Hands-on 03 checkpoints: the students' reference models against the library analyses the
# Lecture 3 deck quotes, and the numbers the hands-on deck states.

using DyadInterface: symbolic_container, ODEAlg

const _V = VehicleSystemsComponents.Vehicle
const _H3 = VehicleSystemsComponents.HandsOn03
const _G = 9.80665

# The notebook's rule: the slowest stop it can be, the locked one or one at `a_max`, plus margin.
_stop_time(mu, a_max = Inf) = 0.5 + 1.5 * 25 / min(0.7 * mu * _G, a_max) + 1.0

# The library analyses default to an automatic solver; the hands-on ones run Tsit5 at dtmax 1 ms.
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

@testset "Hands-on 03 step 02: locked stop" begin
    for (mu, expected) in ((1.0, 43.7), (0.5, 85.1), (0.3, 136.8))
        stop = _stop_time(mu)
        mine = _H3.LockedStopTransient(road_mu = mu, stop = stop)
        lib = _V.LockedBrakeTransient(; road_mu = mu, stop, _tsit5...)
        @test _max_speed_gap(mine, lib, stop) < 1e-6
        @test _V.braking_distance(mine) ≈ _V.braking_distance(lib) atol = 1e-6
        @test _V.braking_distance(mine) ≈ expected atol = 0.05
    end
    run = _H3.LockedStopTransient()
    m = symbolic_container(run)
    t, kappa, v = run.sol.t, run.sol[m.wheel.kappa], run.sol[m.body.mass.v]
    # Locked within 0.2 s of the 0.5 s step: the 30 ms brake lag, then the wheel's spin-down.
    @test t[findfirst(<(-0.99), kappa)] - 0.5 < 0.2
    @test 3.9 < t[findfirst(i -> t[i] > 0.5 && v[i] < 0.5, eachindex(t))] < 4.0
end

@testset "Hands-on 03 step 03: slip ABS" begin
    for (mu, expected) in ((1.0, 34.4), (0.5, 63.4), (0.3, 102.2))
        stop = _stop_time(mu)
        mine = _H3.ABSStopTransient(road_mu = mu, stop = stop)
        lib = _V.IdealBrakeTransient(; road_mu = mu, stop, _tsit5...)
        @test _max_speed_gap(mine, lib, stop) < 1e-6
        @test _V.braking_distance(mine) ≈ _V.braking_distance(lib) atol = 1e-6
        @test _V.braking_distance(mine) ≈ expected atol = 0.05
    end

    # Without the look-ahead the controller dumps 30 ms late, overshoots into sliding and stops
    # longer than the locked wheel.
    present = _H3.ABSStopTransient(T_p = 0.0)
    ahead = _H3.ABSStopTransient()
    @test _V.braking_distance(present) ≈ 53.8 atol = 0.05
    for (run, slide_share, f_cycle) in ((present, 0.26, 2.6), (ahead, 0.0, 31.0))
        m = symbolic_container(run)
        t, kappa = run.sol.t, run.sol[m.wheel.kappa]
        tau, v = run.sol[m.wheel.brake.tau_actual], run.sol[m.body.mass.v]
        win = (t .>= 1.0) .& (v .> 3.0)
        dt = diff(t[win])
        @test sum(dt[kappa[win][1:end-1] .< -0.12]) / sum(dt) ≈ slide_share atol = 0.01
        @test cycle_frequency(t[win], tau[win]) ≈ f_cycle atol = 0.2
        cmd, demand = run.sol[m.abs.tau_cmd], run.sol[m.demand.y]
        @test all(cmd .<= demand .+ 1e-6)
    end
end

@testset "Hands-on 03 steps 04-05: wheel speed only" begin
    for (mu, mine_expected, lib_expected) in ((1.0, 46.9, 38.7), (0.5, 90.7, 83.2), (0.3, 129.6, 141.3))
        stop = _stop_time(mu, 8.0)
        mine = _V.braking_distance(_H3.ABSStopWheelOnlyTransient(road_mu = mu, stop = stop))
        lib = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = mu, stop, _tsit5...))
        @test mine ≈ mine_expected atol = 0.05
        @test lib ≈ lib_expected atol = 0.05
    end
    # The trap is the library ECU's: on snow, a_ref = 8 makes it stop longer than the locked
    # wheel, and a_ref = 0.8 μ g brings it back under.
    locked = _V.braking_distance(_H3.LockedStopTransient(road_mu = 0.3, stop = _stop_time(0.3)))
    lib_trap = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = 0.3, stop = _stop_time(0.3, 8.0), _tsit5...))
    lib_fixed = _V.braking_distance(_V.ABSBrakeTransient(; road_mu = 0.3, a_ref = 2.4, stop = _stop_time(0.3, 2.4), _tsit5...))
    mine_fixed = _V.braking_distance(_H3.ABSStopWheelOnlyTransient(road_mu = 0.3, a_ref = 2.4, stop = _stop_time(0.3, 2.4)))
    @test lib_trap > locked
    @test lib_fixed ≈ 128.4 atol = 0.05
    @test mine_fixed ≈ 127.0 atol = 0.05
    @test mine_fixed < locked

    run = _H3.ABSStopWheelOnlyTransient()
    m = symbolic_container(run)
    t, v_ref, v = run.sol.t, run.sol[m.est.v_ref], run.sol[m.body.mass.v]
    # Between dumps the estimate rides the slipping wheel down, below the car's true speed.
    win = (t .>= 1.0) .& (v .> 3.0)
    @test all(v_ref[win] .<= v[win] .+ 1e-6)
end
