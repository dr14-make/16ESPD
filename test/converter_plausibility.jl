# Lecture 4 step 02 checkpoints: the average converter driving the step 01 machine through its
# field input, on a dyno that sweeps from standstill to 10 000 rpm at full current. The library
# pair and the hands-on 04 reference must both give the envelope the guide states: 320 N·m to
# the base speed of 3283 rpm, then a torque falling as 1/ω at 110 kW, where the converter's
# voltage runs out and it weakens the field. The expectations are hand calculations from the
# Leaf ZE1 defaults.

using DyadInterface: symbolic_container

const _E4c = VehicleSystemsComponents.Vehicle.Electric
const _H4c = VehicleSystemsComponents.HandsOn04

const _rpm_c = 30 / pi
const _R_c = 0.05
const _J_c = 0.05
const _I_max_c = 332.2
const _V_c = 350.0
const _loss_c = (T_f = 0.5, K_i = 1.0, k_w = 300 / (10100 * pi / 30)^3, C = 200.0)
# Shaft loss torque above w_reg = 10 rad/s, where every term is exactly the deck's.
_loss_torque_c(w) = _loss_c.T_f + _loss_c.K_i + _loss_c.k_w * w^2 + _loss_c.C / w
# The dyno ramps 10 000 rpm in 100 s; along the ramp the rotor takes J times that.
const _J_alpha_c = _J_c * 10000 / _rpm_c / 100

function _drive_traces(run, ts)
    m = symbolic_container(run)
    M, C = m.machine, m.converter
    at(x) = run.sol(ts, idxs = x).u
    return (; w = at(M.w), tau = at(M.tau), tau_em = at(M.tau_em), i = at(M.i), E = at(M.E),
        P_mech = at(M.P_mech), P_elec = at(M.P_elec), field = at(C.field), d = at(C.d),
        v_in = at(C.v_in), v_out = at(C.v_out), i_out = at(C.i_out), P_in = at(C.P_in),
        P_out = at(C.P_out), P_cond = at(C.P_cond), P_sw = at(C.P_sw), P_loss = at(C.P_loss),
        P_supply = -at(m.supply.v) .* at(m.supply.i))
end

_k_of(run) = run.sol.ps[symbolic_container(run).machine.k]
# Speed at which the voltage runs out: k w + R i = d_max V, at full field.
_base_w(k, V, I) = (V - _R_c * I) / k
# First sample at which the converter has started to weaken the field.
_fw_onset_rpm(t) = t.w[findfirst(<(0.999), t.field)] * _rpm_c

@testset "Lecture 4 step 02: converter defaults are a Leaf ZE1-class inverter" begin
    run = _E4c.ConverterTransient()
    m = symbolic_container(run)
    C, M = m.converter, m.machine
    ps = run.sol.ps
    @test ps[C.I_max] == _I_max_c
    @test ps[C.d_max] == 1.0
    @test ps[C.V_on] == 1.2
    @test ps[C.f_s] == 5.0e3
    @test ps[C.t_sw] == 1.0e-6
    # The current limit is the armature current at which the machine gives 320 N·m at base
    # speed, and the voltage limit at 350 V puts that corner at the ZE1's 3283 rpm.
    @test (ps[M.T_max] + ps[M.tau_loss_base]) / ps[M.k] ≈ _I_max_c atol = 0.05
    @test _base_w(ps[M.k], _V_c, _I_max_c) * _rpm_c ≈ 3283.0 atol = 0.05
    # The machine runs with its field input, so its flux is the converter's to set.
    @test run.sol[M.E][end] ≈ run.sol[C.field][end] * ps[M.k] * run.sol[M.w][end] rtol = 1e-9
end

@testset "Lecture 4 step 02: the envelope on the dyno" begin
    ts = range(0.05, 102.0, length = 2040)
    lib, mine = _E4c.ConverterTransient(), _H4c.ConverterDynoTransient()
    for run in (lib, mine)
        @test string(run.sol.retcode) == "Success"
        k = _k_of(run)
        t = _drive_traces(run, ts)
        wb = _base_w(k, _V_c, _I_max_c)
        # Asked for 500 A, the converter delivers its limit at every speed, and the machine
        # carries it. The current loop has settled 50 ms in (T_i = 1 ms).
        @test all(isapprox.(t.i_out, _I_max_c; atol = 1e-6))
        @test all(t.i .== t.i_out)
        # Neither limit is ever passed. The 1e-3 allows for the interpolant of the saved points,
        # which overshoots the corner by up to 2e-4 where a solver step straddles it.
        @test maximum(abs.(t.d)) <= 1 + 1e-3
        @test maximum(t.field) <= 1 + 1e-3

        # Below base speed: full field, the duty rising with the back-EMF, and constant torque.
        lo = findall(w -> 300 < w * _rpm_c < 3150, t.w)
        @test all(isapprox.(t.field[lo], 1.0; atol = 1e-6))
        @test all(isapprox.(t.d[lo], (k .* t.w[lo] .+ _R_c * _I_max_c) ./ _V_c; atol = 1e-6))
        @test all(isapprox.(t.tau_em[lo], k * _I_max_c; rtol = 1e-5))
        @test all(isapprox.(t.tau[lo], k * _I_max_c .- _loss_torque_c.(t.w[lo]) .- _J_alpha_c; atol = 2e-3))

        # The voltage runs out at base speed, 3283 rpm, and the field starts to fall there.
        @test 3283.0 < _fw_onset_rpm(t) < 3290.0

        # Above base speed: the duty held at 1, the field falling as 1/ω, and the torque with it,
        # at a constant electromagnetic power (V − R I_max) I_max = 110.75 kW.
        hi = findall(w -> 3450 < w * _rpm_c < 9950, t.w)
        @test all(isapprox.(t.d[hi], 1.0; atol = 1e-6))
        @test all(isapprox.(t.field[hi], wb ./ t.w[hi]; rtol = 1e-5))
        @test all(isapprox.(t.tau_em[hi] .* t.w[hi], (_V_c - _R_c * _I_max_c) * _I_max_c; rtol = 1e-5))
        @test all(isapprox.(t.tau[hi], k * _I_max_c .* wb ./ t.w[hi] .- _loss_torque_c.(t.w[hi]) .- _J_alpha_c; atol = 2e-3))
        # At the shaft that is 110 kW less the speed losses, which grow to 2.1 kW at 10 000 rpm.
        P_hi = t.tau[hi] .* t.w[hi] ./ 1e3
        @test all(108.0 .< P_hi .< 110.1)

        # Held at 10 000 rpm: field 0.328, 103.8 N·m and 108.7 kW. The filtered dyno is still
        # settling 1 s into the hold, which takes 0.02 N·m.
        @test t.field[end] ≈ 0.3283 atol = 1e-4
        @test t.tau[end] ≈ 103.81 atol = 0.01
        @test t.P_mech[end] / 1e3 ≈ 108.71 atol = 0.01

        # Power is conserved through the converter apart from its stated losses: what the
        # supply gives is what the machine takes plus conduction and switching, at every instant.
        @test all(isapprox.(t.P_supply, t.P_in; rtol = 1e-9))
        @test all(isapprox.(t.P_out, t.P_elec; rtol = 1e-9))
        @test all(isapprox.(t.P_in .- t.P_out, t.P_cond .+ t.P_sw; atol = 1e-6))
        @test all(isapprox.(t.P_loss, t.P_cond .+ t.P_sw; rtol = 1e-12))
        @test all(isapprox.(t.P_cond, 1.2 .* abs.(t.i_out); rtol = 1e-12))
        @test all(isapprox.(t.P_sw, 5.0e3 * 1.0e-6 .* t.v_in .* abs.(t.i_out); rtol = 1e-12))
        # Both losses track the current, so at the 350 V output the converter is 99.2 % efficient.
        @test t.P_out[end] / t.P_in[end] ≈ 350 / 352.95 atol = 1e-5
        @test t.P_in[end] / 1e3 ≈ 117.25 atol = 0.01
    end
    # The reference solution is the library pair under other names.
    ml, mm = symbolic_container(lib), symbolic_container(mine)
    @test lib.sol(ts, idxs = ml.machine.tau).u ≈ mine.sol(ts, idxs = mm.machine.tau).u atol = 1e-9
    @test lib.sol(ts, idxs = ml.converter.P_in).u ≈ mine.sol(ts, idxs = mm.converter.P_in).u atol = 1e-6
end

@testset "Lecture 4 step 02: the corner point held" begin
    # Held at 3283 rpm the shaft gives the ZE1's 320 N·m and 110 kW. Both limits are reached
    # there, so the rounded corner of the either-or costs 5e-5 of each: 0.02 N·m.
    run = _E4c.ConverterTransient(rpm_start = 3283.0, rpm_end = 3283.0)
    t = _drive_traces(run, [102.0])
    @test t.tau[1] ≈ 320.0 atol = 0.05
    @test t.P_mech[1] / 1e3 ≈ 110.0 atol = 0.05
    @test t.d[1] ≈ 1.0 atol = 1e-4
    @test t.field[1] ≈ 1.0 atol = 1e-4
    # Machine and converter together are 93.8 % efficient at the corner.
    @test t.P_mech[1] / t.P_in[1] ≈ 0.938 atol = 1e-3
end

@testset "Lecture 4 step 02: part load, regeneration and a lower supply" begin
    ts = range(0.05, 102.0, length = 2040)
    # At 150 A the voltage runs out a little later, at (V − R i)/k = 3373 rpm, and the
    # electromagnetic power above it is (V − R i) i = 51.4 kW.
    run = _H4c.ConverterDynoTransient(I_ref = 150.0)
    k = _k_of(run)
    t = _drive_traces(run, ts)
    @test all(isapprox.(t.i_out, 150.0; atol = 1e-6))
    @test _base_w(k, _V_c, 150.0) * _rpm_c ≈ 3372.7 atol = 0.1
    @test 3372.7 < _fw_onset_rpm(t) < 3380.0
    hi = findall(w -> 3550 < w * _rpm_c < 9950, t.w)
    @test all(isapprox.(t.tau_em[hi] .* t.w[hi], (_V_c - _R_c * 150.0) * 150.0; rtol = 1e-5))

    # Asked for −500 A, the converter brakes at −332.2 A and the power flows back. Above
    # (V + R I_max)/k = 3610 rpm the back-EMF would push more than 350 V back into the supply, so
    # the converter weakens the field here too and returns 115.3 kW. At standstill there is no
    # back-EMF to brake with, and the supply pays the copper loss: 6.5 kW in.
    run = _E4c.ConverterTransient(I_ref = -500.0)
    t = _drive_traces(run, ts)
    @test all(isapprox.(t.i_out, -_I_max_c; atol = 1e-6))
    @test all(t.tau[t.w .> 20] .< 0)
    @test maximum(abs.(t.d)) <= 1 + 1e-3
    @test 3610.1 < _fw_onset_rpm(t) < 3617.0
    @test t.P_in[1] / 1e3 ≈ 6.498 atol = 1e-3
    @test t.P_in[end] / 1e3 ≈ -115.29 atol = 0.01
    @test all(isapprox.(t.P_in .- t.P_out, t.P_cond .+ t.P_sw; atol = 1e-6))

    # On a 300 V supply the voltage runs out at 2791 rpm and the power above is 94.1 kW: the
    # corner moves with the DC link, which is what a sagging battery will do in step 03.
    run = _E4c.ConverterTransient(V = 300.0)
    k = _k_of(run)
    t = _drive_traces(run, ts)
    @test _base_w(k, 300.0, _I_max_c) * _rpm_c ≈ 2790.6 atol = 0.1
    @test 2790.6 < _fw_onset_rpm(t) < 2797.0
    hi = findall(w -> 2950 < w * _rpm_c < 9950, t.w)
    @test all(isapprox.(t.tau_em[hi] .* t.w[hi], (300.0 - _R_c * _I_max_c) * _I_max_c; rtol = 1e-5))
end

@testset "Lecture 4 step 02: converter efficiency in ORNL's inverter band" begin
    # ORNL's Leaf inverter map: mostly 96–98 %, 99 % at high speed. Held at 1000 rpm and asked
    # for 220 N·m, the converter gives 113 V and is 97.5 % efficient; at 350 V out, 99.2 %.
    run = _E4c.ConverterTransient(rpm_start = 1000.0, rpm_end = 1000.0, I_ref = 230.38)
    t = _drive_traces(run, [102.0])
    @test t.tau[1] ≈ 220.0 atol = 0.01
    @test t.v_out[1] ≈ 113.07 atol = 0.01
    eta = t.P_out[1] / t.P_in[1]
    @test eta ≈ 0.9746 atol = 1e-4
    @test 0.96 <= eta <= 0.98
end
