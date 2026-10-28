# Lecture 4 step 01 checkpoints: the DC-equivalent machine with its shaft losses, on a dyno that
# holds base speed and then ramps it on a fixed 350 V supply. The library machine and the
# hands-on 04 reference must both give the numbers the guide states, which are hand
# calculations from the Leaf ZE1 defaults.

using DyadInterface: symbolic_container

const _E4m = VehicleSystemsComponents.Vehicle.Electric
const _H4m = VehicleSystemsComponents.HandsOn04

const _rpm = 30 / pi
const _w_base = 3283 * pi / 30
const _R = 0.05
const _loss_coeffs = (T_f = 0.5, K_i = 1.0, k_w = 300 / (10100 * pi / 30)^3, C = 200.0)
_loss_torque(w) = _loss_coeffs.T_f + _loss_coeffs.K_i + _loss_coeffs.k_w * w^2 + _loss_coeffs.C / w

function _machine_traces(run, ts)
    M = symbolic_container(run).machine
    at(x) = run.sol(ts, idxs = x).u
    return (; w = at(M.w), v = at(M.v), i = at(M.i), E = at(M.E), tau_em = at(M.tau_em),
        tau = at(M.tau), P_elec = at(M.P_elec), P_mech = at(M.P_mech), P_cu = at(M.P_cu),
        P_fric = at(M.P_fric), P_iron = at(M.P_iron), P_wind = at(M.P_wind),
        P_const = at(M.P_const), P_loss = at(M.P_loss))
end

# Supply voltage that holds shaft torque T at speed w in steady state.
_volts_for(k, w, T) = k * w + _R * (T + _loss_torque(w)) / k

@testset "Lecture 4 step 01: machine defaults are a Leaf ZE1-class machine" begin
    run = _E4m.DCMachineTransient()
    M = symbolic_container(run).machine
    ps = run.sol.ps
    @test ps[M.T_max] == 320.0
    @test ps[M.w_base] * _rpm ≈ 3283.0 rtol = 1e-12
    @test ps[M.R] == _R
    @test ps[M.k_w] ≈ _loss_coeffs.k_w rtol = 1e-12
    # k is the root of k w_base + R (T_max + losses) / k = 350 V: 0.9697 N·m/A.
    k = ps[M.k]
    @test k ≈ 0.96974 atol = 1e-5
    @test _volts_for(k, _w_base, 320.0) ≈ 350.0 rtol = 1e-12
    @test ps[M.tau_loss_base] ≈ _loss_torque(_w_base) rtol = 1e-12
end

@testset "Lecture 4 step 01: dyno at base speed and along the torque-speed line" begin
    ts_hold = range(0.5, 1.0, length = 11)
    ts_ramp = range(1.5, 10.5, length = 19)
    ts_all = range(0.0, 12.0, length = 1201)
    for run in (_E4m.DCMachineTransient(), _H4m.DCMachineDynoTransient())
        @test string(run.sol.retcode) == "Success"
        k = run.sol.ps[symbolic_container(run).machine.k]
        h = _machine_traces(run, ts_hold)
        # The corner point: 320 N·m at 3283 rpm is 110 kW at the shaft, for 332 A from 350 V.
        @test all(isapprox.(h.w .* _rpm, 3283.0; atol = 1e-6))
        @test all(isapprox.(h.tau, 320.0; atol = 1e-6))
        @test h.P_mech[end] / 1e3 ≈ 110.01 atol = 0.01
        @test h.i[end] ≈ 332.16 atol = 0.01
        @test h.E[end] ≈ 333.39 atol = 0.01
        # Copper loss 5.5 kW, the shaft losses 0.73 kW, and the motor is 94.6 % efficient there.
        @test h.P_cu[end] / 1e3 ≈ 5.517 atol = 1e-3
        @test (h.P_loss[end] - h.P_cu[end]) / 1e3 ≈ 0.726 atol = 1e-3
        @test h.P_mech[end] / h.P_elec[end] ≈ 0.9463 atol = 1e-4
        # In steady state the terminals' power is the shaft's plus every loss.
        @test all(isapprox.(h.P_elec, h.P_mech .+ h.P_loss; rtol = 1e-9))

        for t in (h, _machine_traces(run, ts_all))
            # T = KΦ·I and E = KΦ·ω hold at every instant, and the copper loss is I²R.
            @test all(isapprox.(t.tau_em, k .* t.i; rtol = 1e-12))
            @test all(isapprox.(t.E, k .* t.w; rtol = 1e-12))
            @test all(isapprox.(t.P_cu, _R .* t.i .^ 2; rtol = 1e-12, atol = 1e-9))
            # Each loss term is its own part, readable on its own, and the terms sum to P_loss.
            @test all(isapprox.(t.P_fric, _loss_coeffs.T_f .* t.w; rtol = 1e-12))
            @test all(isapprox.(t.P_iron, _loss_coeffs.K_i .* t.w; rtol = 1e-12))
            @test all(isapprox.(t.P_wind, _loss_coeffs.k_w .* t.w .^ 3; rtol = 1e-12))
            @test all(isapprox.(t.P_const, _loss_coeffs.C; rtol = 1e-12))
            @test all(isapprox.(t.P_loss, t.P_cu .+ t.P_fric .+ t.P_iron .+ t.P_wind .+ t.P_const;
                rtol = 1e-12))
        end

        # The ramp traces the steady line T = k (V − k ω) / R − losses, offset by a constant
        # 0.46 N·m: the inductance keeps the current 0.64 A above the falling back-EMF's
        # (+0.62 N·m) and the rotor inertia takes J dω/dt (−0.17 N·m).
        r = _machine_traces(run, ts_ramp)
        steady = k .* (350.0 .- k .* r.w) ./ _R .- _loss_torque.(r.w)
        @test all(isapprox.(r.tau .- steady, 0.458; atol = 1e-3))
        # The torque falls by k²/R = 1.97 N·m per rpm, through zero just below the no-load speed
        # V/k = 3447 rpm, and the machine ends generating: −304 N·m, 312 A back into the supply.
        slope = (r.tau[end] - r.tau[1]) / ((r.w[end] - r.w[1]) * _rpm)
        @test slope ≈ -k^2 / _R / _rpm rtol = 1e-3
        @test 350.0 / k * _rpm ≈ 3446.5 atol = 0.1
        a = _machine_traces(run, ts_all)
        z = findfirst(j -> a.tau[j] > 0 && a.tau[j + 1] <= 0, 100:length(ts_all) - 1) + 99
        @test 3445.0 < a.w[z] * _rpm < 3446.5
        @test a.tau[end] ≈ -304.31 atol = 0.01
        @test a.i[end] ≈ -311.67 atol = 0.01
        @test a.P_elec[end] < 0 && a.P_mech[end] < 0
    end
    # The reference solution is the library machine under another name.
    lib, mine = _E4m.DCMachineTransient(), _H4m.DCMachineDynoTransient()
    ts = range(0, 12, length = 1201)
    ml, mm = symbolic_container(lib).machine, symbolic_container(mine).machine
    @test lib.sol(ts, idxs = ml.tau).u ≈ mine.sol(ts, idxs = mm.tau).u atol = 1e-9
    @test lib.sol(ts, idxs = ml.P_loss).u ≈ mine.sol(ts, idxs = mm.P_loss).u atol = 1e-9
end

@testset "Lecture 4 step 01: a lower supply voltage shifts the line down in speed" begin
    # At 200 V the same slope crosses zero at 1968 rpm, just below V/k = 1969 rpm, and the
    # 922 N·m at 1500 rpm takes 953 A: far past the machine's rating, which step 02's converter
    # enforces.
    run = _H4m.DCMachineDynoTransient(V = 200.0, rpm_start = 1500.0, rpm_end = 2200.0)
    a = _machine_traces(run, range(0.0, 12.0, length = 1201))
    @test a.tau[101] ≈ 921.84 atol = 0.01
    @test a.i[101] ≈ 953.47 atol = 0.01
    z = findfirst(j -> a.tau[j] > 0 && a.tau[j + 1] <= 0, 100:1200) + 99
    @test 1967.5 < a.w[z] * _rpm < 1968.5
    @test a.tau[end] ≈ -456.46 atol = 0.01
end

@testset "Lecture 4 step 01: efficiency near ORNL's measured 2012 Leaf map" begin
    k = symbolic_container(_E4m.DCMachineTransient()).machine.k
    k = _E4m.DCMachineTransient().sol.ps[k]
    # Held speed, with the supply set so the shaft carries the torque asked for. Bands are the
    # motor-only map read by eye (ORNL slide 11): 88–93 % at 220 N·m, 1000–3000 rpm; a 97 %
    # island near 7300 rpm and 85 N·m; under 85 % only below about 15 N·m.
    for (rpm, T, lo, hi) in ((1000, 220, 0.88, 0.89), (2000, 220, 0.93, 0.94),
                             (7300, 85, 0.97, 0.975), (5000, 5, 0.70, 0.73))
        w = rpm / _rpm
        run = _E4m.DCMachineTransient(V = _volts_for(k, w, T), rpm_start = rpm, rpm_end = rpm)
        M = symbolic_container(run).machine
        @test run.sol[M.tau][end] ≈ T atol = 1e-6
        eta = run.sol[M.P_mech][end] / run.sol[M.P_elec][end]
        @test lo <= eta <= hi
    end
end
