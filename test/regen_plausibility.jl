# Lecture 4 step 05: series regenerative braking on the Lecture 3 brakes. `RegenBlend` gives the
# machine the brake demand up to the smallest of its torque limit, the battery's charge-power limit
# and a low-speed fade, and the rest to the friction brakes. On Lecture 3's hard stop the limits
# bind one after another and friction carries half the braking; on WLTC none binds above walking
# pace, and the recovered share is the plan's headline number.

using DyadInterface: symbolic_container

const _RG_PL = VehicleSystemsComponents.Vehicle.Planar
const _RG_H4 = VehicleSystemsComponents.HandsOn04

const _RG_RATIO = 8.193
const _RG_RADIUS = 0.31
const _RG_TAU_MAX = 320.0
const _RG_P_CHARGE = 80.5e3
const _RG_V_FADE = 10.0

# The regenerative envelope `RegenBlend` draws, in N·m at the machine, against car speed in km/h.
_rg_machine_speed(v_kmh) = v_kmh / 3.6 * _RG_RATIO / _RG_RADIUS
_rg_envelope(v_kmh) = min(_RG_TAU_MAX, _RG_P_CHARGE / max(_rg_machine_speed(v_kmh), 1.0),
    _RG_TAU_MAX * clamp(v_kmh / _RG_V_FADE, 0.0, 1.0))
# Where the charge-power ceiling meets the torque limit: 34.3 km/h.
const _RG_V_CORNER = _RG_P_CHARGE / _RG_TAU_MAX * _RG_RADIUS / _RG_RATIO * 3.6

# Braking distance from the brake application at 0.5 s to the first sample under 0.5 m/s, on the
# grid `test/esp_plausibility.jl` uses for Lecture 3's straight ABS stop.
function _rg_stop(run)
    m = symbolic_container(run)
    s = run.sol
    ts = collect(0.5:0.005:s.t[end])
    v = s(ts; idxs = m.car.bus.vx).u
    i = findfirst(<(0.5), v)
    return (; t = ts[i], d = s(ts[i]; idxs = m.car.bus.x) - s(0.5; idxs = m.car.bus.x))
end

function _rg_stops(t, ref; min_len = 2.0)
    windows = Tuple{Float64,Float64}[]
    i = 1
    while i <= length(t)
        if ref[i] == 0
            j = i
            while j < length(t) && ref[j+1] == 0
                j += 1
            end
            t[j] - t[i] >= min_len && push!(windows, (t[i], t[j]))
            i = j + 1
        else
            i += 1
        end
    end
    return windows
end

const _rg_stop_run = _RG_PL.PlanarBEVHardStopTransient()
const _rg_abs_run = _RG_PL.PlanarBEVHardStopTransient(withdraw = 1.0)
const _rg_wltc_run = _RG_PL.PlanarBEVRegenWLTCTransient()

@testset "Lecture 4 step 05: the regenerative envelope on the hard stop" begin
    run = _rg_stop_run
    m = symbolic_container(run)
    s = run.sol
    @test string(s.retcode) == "Success"
    @test _RG_V_CORNER ≈ 34.27 atol = 0.01
    # Once the pedal is down, the machine regenerates exactly the envelope: the demand (1221 N·m
    # at the machine) is far above every ceiling.
    tg = collect(0.65:0.002:3.6)
    v = s(tg; idxs = m.kmh.y).u
    regen = s(tg; idxs = m.blend.tau_regen).u
    @test maximum(abs, regen .- _rg_envelope.(v)) < 1e-6
    # Which limit binds where: charge power above the corner speed, torque down to v_fade, the fade
    # below; measured at the speeds the guide reads off.
    at(vq) = findfirst(<(vq), v)
    j = at(60.0)    # 182.8 N·m
    @test regen[j] ≈ _RG_P_CHARGE / _rg_machine_speed(v[j]) rtol = 1e-6
    @test regen[j] < _RG_TAU_MAX
    j = at(20.0)
    @test regen[j] ≈ _RG_TAU_MAX
    j = at(5.0)     # 160 N·m
    @test regen[j] ≈ _RG_TAU_MAX * v[j] / _RG_V_FADE rtol = 1e-6
    # The drive gives the machine torque asked for, to the current loop's lag.
    late = s.t .> 0.7
    @test maximum(abs, (s[m.drive.machine.tau_em] .- s[m.blend.tau_motor])[late]) < 2.0
    # The battery never takes more than its limit: the limit is on the electromagnetic power, the
    # losses come off before the terminals. Measured 79.0 kW and 75.9 kW.
    P_em = -s[m.drive.machine.tau_em] .* s[m.drive.machine.w]
    @test maximum(P_em) <= _RG_P_CHARGE * 1.001
    @test maximum(-s[m.P_dc]) < _RG_P_CHARGE
    @test maximum(-s[m.P_dc]) ≈ 75.9e3 rtol = 2e-3
end

@testset "Lecture 4 step 05: motor versus friction on the hard stop" begin
    run = _rg_stop_run
    m = symbolic_container(run)
    s = run.sol
    e(x) = s[x][end]
    E0 = s[m.E_kin][1]
    E_motor, E_friction = e(m.E_shaft_in), e(m.E_brake)
    # 380.7 kJ of the car's kinetic energy: the machine takes 176.9 kJ back, the friction brakes
    # burn 181.8 kJ, tire slip 22.0 kJ. Friction carries half the braking.
    @test E0 ≈ 380.7e3 rtol = 1e-3
    @test E_motor ≈ 176.9e3 rtol = 5e-3
    @test E_friction ≈ 181.8e3 rtol = 5e-3
    share = E_motor / (E_motor + E_friction)
    @test share ≈ 0.4932 atol = 0.00005
    @test share < 0.5
    println("Dry hard stop: ", (; distance = _rg_stop(run).d, motor_share = 100share, motor_kJ = E_motor/1000, friction_kJ = E_friction/1000))
    # The links close on the kinetic energy; measured 1e-9.
    @test abs(E0 - e(m.E_kin) - (E_motor - e(m.E_shaft_out)) - E_friction - e(m.E_tire)) / E0 < 1e-6
    # 170.2 kJ reach the battery: what the shaft gave back plus the rotor's own energy, less the
    # machine's, converter's and battery's losses and the auxiliaries.
    @test e(m.E_dc_in) ≈ 170.2e3 rtol = 5e-3
    @test e(m.E_dc_in) < E_motor
    # The machine is outside the ABS loop: from about 62 km/h its torque holds the front slip past
    # the ABS's recovery threshold, so the ABS keeps the front friction brakes off, and the rear
    # ones carry the friction share.
    tg = collect(1.4:0.005:3.2)
    @test maximum(abs, s(tg; idxs = m.car.fl.brake.tau_friction).u) < 5.0
    @test minimum(s(tg; idxs = m.car.rl.brake.tau_friction).u) > 500.0
    # Every wheel stays inside Lecture 3's slip bound while the car moves above 3 m/s; measured
    # -0.102 front, -0.058 rear.
    ts = collect(0.5:0.005:s.t[end])
    moving = s(ts; idxs = m.car.bus.vx).u .> 3.0
    for k in (m.car.bus.kappa_fl, m.car.bus.kappa_fr, m.car.bus.kappa_rl, m.car.bus.kappa_rr)
        @test minimum(s(ts[moving]; idxs = k).u) >= -0.2
    end
    @test maximum(abs, s[m.car.bus.r]) < 1e-8
end

@testset "Lecture 4 step 05: regeneration does not lengthen the stop" begin
    with = _rg_stop(_rg_stop_run)
    friction_only = _RG_PL.PlanarBEVHardStopTransient(P_charge = 0.0)
    without = _rg_stop(friction_only)
    # 36.2 m with regeneration against 38.8 m on friction alone: on friction alone the front ABS
    # works the front tires at about 62 % of their grip; below the corner speed the machine's
    # 320 N·m holds them at 93 %.
    @test with.d ≈ 36.22 atol = 0.005
    @test without.d ≈ 38.82 atol = 0.1
    @test with.d < without.d
    s0 = friction_only.sol
    m0 = symbolic_container(friction_only)
    @test s0[m0.E_dc_in][end] < 1.0
    @test s0[m0.E_brake][end] > 0.95 * s0[m0.E_kin][1]
end

@testset "Lecture 4 step 05: recovered energy on WLTC" begin
    run = _rg_wltc_run
    m = symbolic_container(run)
    s = run.sol
    e(x) = s[x][end]
    @test string(s.retcode) == "Success"
    @test s.t[end] == 1800.0
    v_kmh = 3.6 .* s[m.car.bus.vx]
    ref = s[m.trace.y]
    @test maximum(abs, v_kmh .- ref) < 2.0
    km = e(m.car.bus.x) / 1000
    @test km ≈ 23.266 rtol = 5e-4
    # The friction brakes hold the car at every stop, and it never rolls backwards.
    @test minimum(v_kmh) > -1e-3
    for (t0, t1) in _rg_stops(s.t, ref)
        held = (s.t .>= t0 + 1.0) .& (s.t .<= t1)
        @test maximum(abs, v_kmh[held]) < 1e-3
    end
    # Neither the torque limit nor the charge-power limit binds: above walking pace the machine
    # takes the whole demand (WLTC asks at most 87 N·m and 32 kW of it).
    br = (s[m.blend.tau_demand] .> 0.1) .& (v_kmh .> 3.0)
    @test count(br) > 1000
    @test maximum(abs, (s[m.blend.tau_regen] .- s[m.blend.tau_demand])[br]) < 1e-9
    @test maximum(s[m.blend.tau_demand]) < 100.0
    @test maximum(-s[m.P_dc]) < 0.5 * _RG_P_CHARGE
    # So friction burns only what the fade leaves near standstill: 0.004 % of the braking.
    @test e(m.E_brake) < 1e-3 * e(m.E_shaft_in)
    # The recovered share: 34.25 Wh/km back into the battery terminals, 23.85 % of the 143.6 Wh/km
    # of traction at the shaft. The regen path returns 88.6 % of the 38.7 Wh/km the shaft takes
    # back, above Boretti's 72-87 % for the MY2013 Leaf; the reduction is ideal here.
    share = e(m.E_dc_in) / e(m.E_shaft_out)
    @test share ≈ 0.2385 atol = 5e-4
    @test e(m.E_dc_in) / 3600 / km ≈ 34.25 atol = 0.05
    @test 0.85 < e(m.E_dc_in) / e(m.E_shaft_in) < 0.93
    # The plan's anchor is 18-25 %: 25-26 % braking through a regen path of 70-87 % on the
    # measured Leaf, up to ~95 % with an ideal reduction. No limit binds on WLTC, so the share is
    # step 04's 23.8 %, in the upper half.
    @test 0.18 <= share <= 0.25
    # Battery DC consumption stays in the plan's band, a hair under step 04's 131.24 Wh/km.
    @test 120.0 <= e(m.E_dc) / 3600 / km <= 155.0
    @test e(m.E_dc) / 3600 / km ≈ 131.15 atol = 0.05
    # The links still add up to what left the cells.
    dkin = e(m.E_kin) - s[m.E_kin][1]
    links = e(m.E_road) + e(m.E_brake) + e(m.E_tire) + e(m.E_motor) + e(m.E_conv) + e(m.E_R0) +
            e(m.E_aux) + dkin
    @test abs(links - e(m.E_cells)) / e(m.E_cells) < 1e-6
end

@testset "Lecture 4 step 05: a charge limit low enough for the band burns WLTC braking" begin
    # At 15 kW the share falls to 21.40 %, the measured Leaf's 18-22 %, only because friction
    # takes 9.5 % of WLTC's braking energy, above S8's 4 % cap: the gap to the measured car is the
    # regen path's efficiency, which no charge limit S8 allows can close.
    run = _RG_PL.PlanarBEVRegenWLTCTransient(P_charge = 15.0e3)
    m = symbolic_container(run)
    s = run.sol
    e(x) = s[x][end]
    @test string(s.retcode) == "Success"
    @test maximum(abs, 3.6 .* s[m.car.bus.vx] .- s[m.trace.y]) < 2.0
    share = e(m.E_dc_in) / e(m.E_shaft_out)
    friction = e(m.E_brake) / (e(m.E_brake) + e(m.E_shaft_in))
    @test 0.18 <= share <= 0.22
    @test share ≈ 0.2140 atol = 5e-4
    @test friction > 0.04
    @test friction ≈ 0.0953 atol = 5e-4
end

@testset "Lecture 4 step 05: the hands-on reference is the library car" begin
    lib_stop, lib_wltc = _rg_stop_run, _rg_wltc_run
    h4_stop = _RG_H4.BEVHardStopTransient()
    h4_wltc = _RG_H4.BEVRegenWLTCTransient()
    @test string(h4_stop.sol.retcode) == "Success"
    @test string(h4_wltc.sol.retcode) == "Success"
    ml, mh = symbolic_container(lib_stop), symbolic_container(h4_stop)
    ts = collect(range(0.01, 6.0; length = 1200))
    # The library bench carries more meters, which moves the solver's steps by a hair.
    @test lib_stop.sol(ts, idxs = ml.car.bus.vx).u ≈ h4_stop.sol(ts, idxs = mh.car.bus.vx).u atol = 1e-5
    for (a, b) in ((ml.E_shaft_in, mh.E_shaft_in), (ml.E_brake, mh.E_brake), (ml.E_dc_in, mh.E_dc_in))
        @test lib_stop.sol[a][end] ≈ h4_stop.sol[b][end] rtol = 1e-4
    end
    mlw, mhw = symbolic_container(lib_wltc), symbolic_container(h4_wltc)
    tw = range(1.0, 1800.0; length = 3600)
    @test lib_wltc.sol(tw, idxs = mlw.car.bus.vx).u ≈ h4_wltc.sol(tw, idxs = mhw.car.bus.vx).u atol = 1e-4
    @test h4_wltc.sol[mhw.E_dc_in][end] / h4_wltc.sol[mhw.E_shaft_out][end] ≈
          lib_wltc.sol[mlw.E_dc_in][end] / lib_wltc.sol[mlw.E_shaft_out][end] rtol = 1e-4
end


@testset "Regen withdraws and returns without losing brake demand" begin
    run = VehicleSystemsComponents.Vehicle.Electric.TestRegenBlendTransient()
    m = symbolic_container(run)
    s = run.sol
    @test string(s.retcode) == "Success"
    @test s(0.4; idxs = m.blend.allow) ≈ 1.0
    @test s(0.65; idxs = m.blend.allow) ≈ exp(-5) atol = 1e-5
    @test s(1.4; idxs = m.blend.tau_regen) < 1e-5
    @test s(2.0; idxs = m.blend.allow) ≈ 1 - exp(-1) atol = 1e-5
    @test s(3.0; idxs = m.blend.allow) ≈ 1 - exp(-3) atol = 1e-5
    @test maximum(abs, s[m.blend.tau_regen] .+ 4 .* s[m.blend.tau_brake] ./ _RG_RATIO .- 400) < 1e-8
end

@testset "ABS rule: dry stop against step 5" begin
    run = _rg_abs_run
    s, m = run.sol, symbolic_container(run)
    @test string(s.retcode) == "Success"
    @test _rg_stop(run).d ≈ 38.836 atol = 0.1
    @test _rg_stop(run).d > _rg_stop(_rg_stop_run).d
    motor, friction = s[m.E_shaft_in][end], s[m.E_brake][end]
    @test motor ≈ 5930 rtol = 0.01
    @test friction ≈ 360743 rtol = 0.01
    @test motor / (motor + friction) ≈ 0.01617 atol = 0.001
    E0 = s[m.E_kin][1]
    @test abs(E0 - s[m.E_kin][end] - motor + s[m.E_shaft_out][end] - friction - s[m.E_tire][end]) / E0 < 1e-6
    tg = 0.8:0.005:3.4
    @test minimum(s(tg; idxs = m.abs.front_active).u) == 1.0
    @test maximum(abs, s(tg; idxs = m.blend.tau_regen).u) < 0.1
end

@testset "ABS rule: low-grip front wheels no longer lock" begin
    with = _RG_PL.PlanarBEVLowGripStopTransient()
    # End the counterfactual after its stop, before the known exact-rest tire Jacobian singularity.
    without = _RG_PL.PlanarBEVLowGripStopTransient(withdraw = 0.0, stop = 12.0)
    for run in (with, without)
        @test string(run.sol.retcode) == "Success"
    end
    @test _rg_stop(with).d ≈ 275.02 atol = 0.5
    @test _rg_stop(without).d ≈ 112.35 atol = 0.5
    for (run, controlled) in ((with, true), (without, false))
        s, m = run.sol, symbolic_container(run)
        tg = collect(0.5:0.005:run.sol.t[end])
        moving = s(tg; idxs = m.car.bus.vx).u .> 3.0
        for k in (m.car.bus.kappa_fl, m.car.bus.kappa_fr)
            slip = s(tg[moving]; idxs = k).u
            @test controlled ? minimum(slip) > -0.2 : minimum(slip) < -1.0
            println("Low-grip slip: ", (; controlled, wheel = string(k), minimum_slip = minimum(slip)))
        end
    end
    hands_on = _RG_H4.BEVLowGripStopTransient()
    @test string(hands_on.sol.retcode) == "Success"
    # Different meter states perturb the adaptive integration of the sampled ABS (0.025 %).
    @test _rg_stop(hands_on).d ≈ _rg_stop(with).d atol = 0.1
    sh, mh = hands_on.sol, symbolic_container(hands_on)
    th = collect(0.5:0.005:sh.t[end])
    moving_h = sh(th; idxs = mh.car.bus.vx).u .> 3.0
    for k in (mh.car.bus.kappa_fl, mh.car.bus.kappa_fr)
        @test minimum(sh(th[moving_h]; idxs = k).u) > -0.2
    end
    println("ABS regen comparison: ", (; dry_before = _rg_stop(_rg_stop_run).d, dry_after = _rg_stop(_rg_abs_run).d, low_with = _rg_stop(with).d, low_without = _rg_stop(without).d, hands_on = _rg_stop(hands_on).d))
end
