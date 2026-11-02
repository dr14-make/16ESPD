# Lecture 4 power-electronics demo (plan S4): the switched buck chopper and H-bridge, checked
# against hand calculations. Power is averaged by the trapezoid rule over the solver's own steps:
# they resolve every switching edge, whereas sampling a fixed grid misses the nanosecond loss
# pulses, and the interpolant between steps misreads the fast currents that charge the switches'
# output capacitance (at 10 kHz both overstate the H-bridge loss severalfold).

using DyadInterface: symbolic_container

const _Esw = VehicleSystemsComponents.Vehicle.Electric

# The library diode (MSL defaults) on its linear branch, above 3.3 A: v = Vt (14 + i / (Ids e^15)).
_sw_vf(i) = 0.04 * (14 + i / (1e-6 * exp(15)))
# Hard-switching energy of one edge of the geometric resistance ramp (see `Switch`).
_sw_edge_energy(V, I, t_sw) = 2 * V * I * t_sw / log(1e6 / 10e-3)

"Time average of `x` over [t1, t2], trapezoid over the solver steps with the ends interpolated."
function _sw_mean(sol, x, t1, t2)
    t, y = sol.t, sol[x]
    k = findall(τ -> t1 < τ < t2, t)
    tt = vcat(t1, t[k], t2)
    yy = vcat(sol(t1, idxs = x), y[k], sol(t2, idxs = x))
    return sum((yy[1:end-1] .+ yy[2:end]) ./ 2 .* diff(tt)) / (t2 - t1)
end

"Average power of `P` over [t1, t2] split by the gate `g`: fully on, in transition, fully off."
function _sw_split(sol, P, g, t1, t2)
    t, p, gg = sol.t, sol[P], sol[g]
    on = trans = off = 0.0
    for k in 1:length(t)-1
        (t[k] >= t1 && t[k+1] <= t2) || continue
        e = (p[k] + p[k+1]) / 2 * (t[k+1] - t[k])
        if gg[k] >= 1 && gg[k+1] >= 1
            on += e
        elseif gg[k] <= 0 && gg[k+1] <= 0
            off += e
        else
            trans += e
        end
    end
    return (; on = on / (t2 - t1), trans = trans / (t2 - t1), off = off / (t2 - t1))
end

"Amplitudes of `y` at the frequencies `fs`, from a 1 µs grid over [t1, t2) (whole periods)."
function _sw_amplitudes(sol, y, t1, t2, fs)
    dt = 1e-6
    ts = range(t1, t2; step = dt)[1:end-1]
    v = sol(ts, idxs = y).u
    return map(fs) do f
        c = sum(v[k] * cis(-2π * f * (ts[k] - t1)) for k in eachindex(v)) / length(v)
        (f == 0 ? 1 : 2) * c
    end
end

function _sw_buck(run; window = (1.5e-3, 2.0e-3))
    m = symbolic_container(run)
    C, s = m.chopper, run.sol
    t1, t2 = window
    ts = range(t1, t2; length = 200_001)
    iL = s(ts, idxs = C.i_L).u
    P = Dict(k => _sw_mean(s, getproperty(C, k), t1, t2)
             for k in (:P_in, :P_out, :P_switch, :P_diode, :P_winding, :P_loss))
    return (; m, C, s, ps = s.ps, I = sum(iL) / length(iL), I_min = minimum(iL), I_max = maximum(iL),
        ripple = maximum(iL) - minimum(iL), P, eta = P[:P_out] / P[:P_in],
        duty = sum(s(ts, idxs = C.pwm.y).u) / length(ts),
        switch = _sw_split(s, C.P_switch, C.pwm.y, t1, t2))
end

@testset "Switching: buck chopper defaults" begin
    b = _sw_buck(_Esw.BuckChopperTransient())
    C, ps = b.C, b.ps
    @test string(b.s.retcode) == "Success"
    @test ps[C.f_s] == 20e3
    @test ps[C.L] == 100e-6
    @test ps[C.transistor.R_on] == 10e-3
    @test ps[C.transistor.R_off] == 1e6
    @test ps[C.pwm.band] ≈ 2 * 20e3 * 0.5e-6 rtol = 1e-12
end

@testset "Switching: buck chopper at its design point (48 V, d = 0.3, 0.7 Ω, 20 kHz)" begin
    b = _sw_buck(_Esw.BuckChopperTransient())
    C, s, P = b.C, b.s, b.P
    V_in, d, R_load, R_L, R_on, L, f_s, t_sw = 48.0, 0.3, 0.7, 10e-3, 10e-3, 100e-6, 20e3, 0.5e-6
    # The gate averages exactly the duty command (sampled every 2.5 ns, which resolves its ramps).
    @test b.duty ≈ d atol = 1e-5
    # The inductor current starts from rest and settles with L / R = 0.14 ms: by 1 ms, seven time
    # constants, the mean is within 19 A e^-7 of its final value.
    @test s(0.0, idxs = C.i_L) == 0.0
    @test _sw_mean(s, C.i_L, 1.0e-3, 1.5e-3) ≈ b.I atol = 19 * exp(-7)
    # Average circuit. The switch node is high for d T + (1 - 2 g*) t_sw, where g* is the gate at
    # which the switch resistance equals V / I (0.70 here): the effective duty is 0.296. The
    # node then averages d_eff V_in less the diode drop in the off time.
    g_star = log(1e6 * b.I / V_in) / log(1e6 / R_on)
    d_eff = d + (1 - 2 * g_star) * t_sw * f_s
    @test 0.295 < d_eff < 0.297
    I_avg = (d_eff * V_in - (1 - d_eff) * _sw_vf(b.I)) / (R_load + R_L + d * R_on)
    @test b.I ≈ I_avg rtol = 5e-3
    @test b.I ≈ 19.07 atol = 0.01
    @test P[:P_out] ≈ R_load * _sw_mean(s, C.i_L^2, 1.5e-3, 2.0e-3) rtol = 1e-6
    # Ripple: the off-time slope (V_out + R_L I + V_f) / L for (1 - d_eff) / f_s, 5.04 A, a quarter
    # of the load current: visible.
    ripple = (R_load * b.I + R_L * b.I + _sw_vf(b.I)) * (1 - d_eff) / (L * f_s)
    @test b.ripple ≈ ripple rtol = 0.01
    @test 0.2 < b.ripple / b.I < 0.3
    # The energy chain closes over whole periods.
    @test abs(P[:P_in] - P[:P_out] - P[:P_loss]) / P[:P_in] < 1e-4
    @test P[:P_loss] ≈ P[:P_switch] + P[:P_diode] + P[:P_winding] rtol = 1e-9
    # The deck's "over 90 %": 93.6 %.
    @test b.eta > 0.90
    @test b.eta ≈ 0.936 atol = 0.002
    # The deck's four losses, each from its own part. Conduction is R_on i^2 while fully on;
    # switching is the edges, 2 V I t_sw / ln(R_off / R_on) per edge at the current of that edge;
    # the winding is R_L i_rms^2; the diode, about 0.8 V at 19 A for 70 % of the time, is the
    # largest.
    on = _sw_split(s, C.transistor.channel.i^2, C.pwm.y, 1.5e-3, 2.0e-3).on
    @test b.switch.on ≈ R_on * on rtol = 1e-6
    @test b.switch.on ≈ 1.07 atol = 0.01
    E_sw = _sw_edge_energy(V_in + _sw_vf(b.I_min), b.I_min, t_sw) +
           _sw_edge_energy(V_in + _sw_vf(b.I_max), b.I_max, t_sw)
    @test b.switch.trans ≈ E_sw * f_s rtol = 0.05
    @test b.switch.off < 2e-3
    @test P[:P_winding] ≈ R_L * _sw_mean(s, C.i_L^2, 1.5e-3, 2.0e-3) rtol = 1e-6
    @test 10.0 < P[:P_diode] < 11.5
    @test P[:P_diode] > P[:P_winding] > b.switch.trans > b.switch.on

    # Slide 28's three currents: the source supplies the inductor while the switch is on, the
    # diode carries it while the switch is off, and their sum is the load current.
    i_T, i_D, i_L, g = s[C.transistor.i], s[C.diode.i], s[C.i_L], s[C.pwm.y]
    late = s.t .>= 1.5e-3
    @test maximum(abs.(i_T .+ i_D .- i_L)) < 1e-9
    @test maximum(abs.(i_D[late .& (g .>= 1)])) < 1e-3
    @test maximum(abs.(i_T[late .& (g .<= 0)])) < 1e-3
end

@testset "Switching: buck ripple falls with frequency and inductance, switching loss rises" begin
    base = _sw_buck(_Esw.BuckChopperTransient())
    fast = _sw_buck(_Esw.BuckChopperTransient(f_s = 40e3))
    # Doubling f_s halves the ripple and doubles the switching loss. Conduction drops a little,
    # because the edges take a larger share of a shorter on-time.
    @test fast.ripple / base.ripple ≈ 0.5 rtol = 0.03
    @test fast.switch.trans / base.switch.trans ≈ 2.0 rtol = 0.05
    @test 0.9 < fast.switch.on / base.switch.on < 1.0
    @test fast.eta < base.eta
    # Doubling L halves the ripple too; it needs twice the settling time.
    big = _sw_buck(_Esw.BuckChopperTransient(L = 200e-6, stop = 4e-3); window = (3.5e-3, 4.0e-3))
    @test big.ripple / base.ripple ≈ 0.5 rtol = 0.03
    @test big.I ≈ base.I rtol = 0.01
end

function _sw_hbridge(run; t1 = 0.02, t2 = 0.06)
    m = symbolic_container(run)
    B, s = m.bridge, run.sol
    P = Dict(k => _sw_mean(s, getproperty(B, k), t1, t2) for k in (:P_dc, :P_ac, :P_loss))
    return (; m, B, s, P, t1, t2)
end

_sw_line(h, x, f) = only(_sw_amplitudes(h.s, x, h.t1, h.t2, [f]))

@testset "Switching: H-bridge with sine PWM (350 V, m = 0.8, 50 Hz, 1 kHz carrier, 10 Ω + 10 mH)" begin
    h = _sw_hbridge(_Esw.HBridgeTransient())
    B, s, P = h.B, h.s, h.P
    @test string(s.retcode) == "Success"
    Z(f) = 10.0 + im * 2π * f * 10e-3
    # Fundamental: m V_dc = 280 V, and the load answers with 280 / |Z| = 26.7 A, 17.4° behind.
    V1, I1 = _sw_line(h, B.v_ab, 50.0), _sw_line(h, B.i_ab, 50.0)
    @test abs(V1) ≈ 0.8 * 350 rtol = 0.005
    @test abs(I1) ≈ 280 / abs(Z(50)) rtol = 0.005
    @test rad2deg(angle(V1) - angle(I1)) ≈ rad2deg(angle(Z(50))) atol = 0.2
    # Switching harmonics: every line from 200 Hz to 3 kHz on the 25 Hz grid of two cycles. The
    # two largest are the carrier's sidebands f_c ± f_1, and the second carrier harmonic carries a
    # cluster of its own.
    fs = collect(200.0:25.0:3000.0)
    Av = abs.(_sw_amplitudes(s, B.v_ab, h.t1, h.t2, fs))
    top = fs[sortperm(Av; rev = true)[1:2]]
    @test Set(top) == Set([950.0, 1050.0])
    @test maximum(Av[(fs .> 1500) .& (fs .< 2500)]) > 0.1 * abs(V1)
    # The inductance filters them: each current line is its voltage line over |Z| at that frequency.
    Ai = abs.(_sw_amplitudes(s, B.i_ab, h.t1, h.t2, [950.0, 1050.0]))
    @test Ai ≈ Av[indexin([950.0, 1050.0], fs)] ./ abs.(Z.([950.0, 1050.0])) rtol = 0.02
    # The deck's gate pattern: D on through the positive half, A modulated; B and C mirror it.
    # No leg ever has both switches on, so the bridge never shorts the DC link.
    gA, gB, gC, gD, u = s[B.switch_a.g], s[B.switch_b.g], s[B.switch_c.g], s[B.switch_d.g], s[B.u]
    @test maximum(min.(gA, gC)) == 0
    @test maximum(min.(gB, gD)) == 0
    @test all(gD[u .> 1e-3] .== 1) && all(gB[u .< -1e-3] .== 1)
    @test all(gC[u .>= 0] .== 0) && all(gA[u .<= 0] .== 0)
    @test all(-352 .< s[B.v_ab] .< 352)
    # Energy closes, and the bridge loses 13 W of 3.6 kW.
    @test abs(P[:P_dc] - P[:P_ac] - P[:P_loss]) / P[:P_dc] < 1e-6
    @test P[:P_ac] / P[:P_dc] > 0.99
end

@testset "Switching: H-bridge low-order harmonics come from the lagging current" begin
    # For 17° after each zero crossing the current still flows the old way, the diode of the off
    # switch clamps the output to the full rail, and the 3rd, 5th and 7th appear at about 5 %.
    # A nearly resistive load has no lag and none of them.
    for (L_load, lo, hi) in ((10e-3, 0.04, 0.06), (0.2e-3, 0.0, 1e-3))
        h = _sw_hbridge(_Esw.HBridgeTransient(L_load = L_load))
        A = abs.(_sw_amplitudes(h.s, h.B.v_ab, h.t1, h.t2, [50.0, 150.0, 250.0, 350.0]))
        @test all(lo .<= A[2:end] ./ A[1] .<= hi)
    end
end

@testset "Switching: H-bridge at 10 kHz and in square-wave operation" begin
    # A real inverter's carrier: the same fundamental, a tenth of the switching ripple current.
    slow = _sw_hbridge(_Esw.HBridgeTransient())
    fast = _sw_hbridge(_Esw.HBridgeTransient(f_s = 10e3))
    @test abs(_sw_line(fast, fast.B.v_ab, 50.0)) ≈ 280 rtol = 0.01
    ripple_slow = abs(_sw_line(slow, slow.B.i_ab, 950.0))
    ripple_fast = abs(_sw_line(fast, fast.B.i_ab, 9950.0))
    @test ripple_fast / ripple_slow < 0.12
    @test fast.P[:P_loss] > slow.P[:P_loss]
    @test abs(fast.P[:P_dc] - fast.P[:P_ac] - fast.P[:P_loss]) / fast.P[:P_dc] < 1e-6
    # A reference far beyond 1 holds A and D, then B and C, on for whole half cycles (slide 30):
    # the square wave's fundamental is 4 V_dc / pi, its third harmonic a third of that, and the
    # current settles each half cycle at (V_dc / R) tanh(T / 4 tau) = 35.0 A.
    sq = _sw_hbridge(_Esw.HBridgeTransient(m = 20.0))
    A = abs.(_sw_amplitudes(sq.s, sq.B.v_ab, sq.t1, sq.t2, [50.0, 150.0]))
    @test A[1] ≈ 4 * 350 / π rtol = 0.005
    @test A[2] / A[1] ≈ 1 / 3 atol = 0.005
    i = sq.s(range(sq.t1, sq.t2; length = 40_001), idxs = sq.B.i_ab).u
    @test maximum(i) ≈ 35.0 * tanh(0.02 / 4 / 1e-3) rtol = 0.005
    @test minimum(i) ≈ -maximum(i) rtol = 1e-3
end


@testset "Switching: boost mean, ripple and energy at two duties" begin
    for d in (0.25, 0.5)
        r = _Esw.BoostChopperTransient(d = d)
        s, C = r.sol, symbolic_container(r).chopper
        a, b = 5e-3, 6e-3 # 20 whole switching periods, after settling
        I = _sw_mean(s, C.i_L, a, b)
        V = _sw_mean(s, C.v_out, a, b)
        # Volt-second balance with winding, switch and diode conduction drops.
        predicted = (48 - I * (0.01 + d * 0.01)) / (1 - d) - _sw_vf(I)
        # 2% covers finite 0.5 us gate edges (1% of a period), effective duty
        # and capacitor ripple: measured corrections to this DC estimate are 0.9–1.7%.
        @test string(s.retcode) == "Success"
        @test V ≈ predicted rtol = 0.02
        @test V < 48 / (1 - d)
        # Under 0.01 V drift between successive 20-period windows: <0.016%.
        @test V ≈ _sw_mean(s, C.v_out, 4e-3, 5e-3) atol = 0.01
        ts = range(b - 1 / 20e3, b; length = 5001)
        ii = s(ts, idxs = C.i_L).u
        @test minimum(ii) > 0 # textbook ripple assumes continuous conduction
        # Ideal 6/12 A ripple: <0.4 V conduction drop during on-time and
        # finite-edge timing account for about 2%; allow 4% including C ripple.
        @test maximum(ii) - minimum(ii) ≈ 48 * d / (100e-6 * 20e3) rtol = 0.04
        P = Dict(k => _sw_mean(s, getproperty(C, k), a, b)
                 for k in (:P_in, :P_out, :P_loss, :P_switch, :P_diode, :P_winding))
        # Solver-step quadrature resolves edge loss. 0.01% (0.04–0.09 W)
        # allows quadrature error and residual stored-energy drift, not missing loss.
        @test abs(P[:P_in] - P[:P_out] - P[:P_loss]) / P[:P_in] < 1e-4
        @test P[:P_loss] ≈ P[:P_switch] + P[:P_diode] + P[:P_winding] rtol = 1e-9
    end
end
