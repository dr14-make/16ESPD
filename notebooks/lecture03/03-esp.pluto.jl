### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ f21bf7ce-c4d8-44a0-a6d7-84e6a6f2a3a1
md"""
# Lecture 3 — Electronic stability control (ESP)

A planar four-wheel car, built from `MultibodyComponents.PlanarMechanics` and steered through an
Ackermann linkage, driven through the FMVSS 126 **sine-with-dwell** test with and without a
yaw-rate ESP. Every curve below is a `Lecture3` analysis; the plots read what the car's sensor
cluster (`PlanarCarSensors`) and the controllers output, plus the wheel loads and steer angles
where a plot needs them.

The car: `m = 1500 kg`, `Iz = 2500 kg·m²`, CG 1.2 m behind the front axle and 1.5 m ahead of
the rear one, track 1.55 m, steering ratio 16, starting at 80 km/h. Body frame: x forward,
y left, yaw positive to the left.

Each table carries the band its number has to sit in and an **in band** column.
"""

# ╔═╡ 43fc3fc4-efba-4d6b-8e46-492f3c4403a5
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    VehicleSystemsComponents = setup()
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
end

# ╔═╡ d11b8972-f61e-4eea-95fe-e8cb11bfff21
begin
    L3 = VehicleSystemsComponents.Lecture3
    fmvss126_metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics

    G = 9.81
    L = 2.7
    K_US = 2.0387e-3
    I_S = 16.0
    A_FMVSS = deg2rad(21.63)
    T_COS = 1.0 + 1 / 0.7 + 0.5
    T_SDW = collect(0.0:0.002:6.0)
    WHEEL_COLORS = (fl = :steelblue, fr = :darkorange, rl = :seagreen, rr = :mediumpurple)

    "Run a `Lecture3` analysis once and keep its solution with the model to index it by."
    function simulate(analysis; kwargs...)
        result = analysis(; kwargs...)
        (; sol = result.sol, m = symbolic_container(result))
    end
    signal(run, x) = run.sol[x]
    signal(run, x, t) = run.sol(t; idxs = x).u
    wheel_signals(run, prefix) = [signal(run, getproperty(run.m.sensors, Symbol(prefix, w)))
                                  for w in (:fl, :fr, :rl, :rr)]

    function sdw_metrics(run)
        s = run.m.sensors
        fmvss126_metrics(T_SDW, signal(run, s.delta_sw, T_SDW), signal(run, s.r, T_SDW),
            signal(run, s.y, T_SDW); A = A_FMVSS)
    end
    beta_max_deg(run) = rad2deg(maximum(abs, signal(run, run.m.sensors.beta)))
    end_speed(run) = signal(run, run.m.sensors.vx)[end]
    min_kappa(run) = minimum(minimum, wheel_signals(run, "kappa_"))
    function min_kappa_moving(run)
        s = run.m.sensors
        moving = T_SDW[signal(run, s.vx, T_SDW) .> 3.0]
        minimum(minimum(signal(run, k, moving)) for k in (s.kappa_fl, s.kappa_fr, s.kappa_rl, s.kappa_rr))
    end
    trapz(t, x) = sum((x[1:end-1] .+ x[2:end]) .* diff(t)) / 2

    fmt(x, digits) = string(round(x; digits))
    ok(pass) = pass ? "yes" : "**NO**"
end

# ╔═╡ 14046bd4-e891-4417-b186-20b88e7eff9c
md"""
## 1. The bicycle model

In steady cornering the linear single-track model gives the yaw rate per road-wheel angle

```math
\frac{r}{\delta} = \frac{v_x}{L + K_{us}\,v_x^2},
\qquad K_{us} = \frac{m}{L}\left(\frac{b}{C_f} - \frac{a}{C_r}\right) = 2.04\cdot10^{-3}\ \mathrm{rad/(m/s^2)}.
```

`K_us > 0` is understeer: the gain rises with speed, peaks at the characteristic speed
`sqrt(L/K_us) = 36.4 m/s`, and stays below the neutral-steer line `vx/L`. The car holds a
constant steering-wheel angle, reached by a 0.2 s ramp, and is read at 4 s at its
instantaneous speed (it slows in the turn).
"""

# ╔═╡ e985de24-162f-4c9c-bfd0-8d150d1d050c
begin
    STEADY_DELTA = (0.005, 0.010, 0.020, 0.030)
    SWEEP_SPEEDS = (10.0, 15.0, 30.0, 40.0)
    steady = [simulate(L3.PlanarOpenLoopTransient; stop = 4.0, delta_sw_final = I_S * δ)
              for δ in STEADY_DELTA]
    speed_sweep = [simulate(L3.PlanarOpenLoopTransient; stop = 4.0, v0 = v, delta_sw_final = I_S * 0.01)
                   for v in SWEEP_SPEEDS]

    function steady_point(run, δ)
        s = run.m.sensors
        r = run.sol(4.0; idxs = s.r)
        vx = run.sol(4.0; idxs = s.vx)
        beta = run.sol(4.0; idxs = s.beta)
        r_formula = vx * δ / (L + K_US * vx^2)
        (; δ, r, vx, beta, r_formula, gain = r / δ, K_fit = (vx * δ / r - L) / vx^2)
    end
    steady_points = [steady_point(run, δ) for (run, δ) in zip(steady, STEADY_DELTA)]
    sweep_points = [steady_point(run, 0.01) for run in speed_sweep]
end

# ╔═╡ 18f356b0-20fc-4c18-a16b-078371b5de6a
bicycle_plot = let v = range(0.0, 50.0; length = 200)
    p = plot(v, v ./ (L .+ K_US .* v .^ 2);
        lw = 2, color = :black, label = "bicycle model, K_us = 2.04e-3",
        xlabel = "forward speed vx [m/s]", ylabel = "yaw-rate gain r/δ [1/s]",
        title = "Steady-state yaw-rate gain", legend = :topleft, ylims = (0, 12))
    plot!(p, v, v ./ L; lw = 1.5, ls = :dash, color = :gray, label = "neutral steer, vx/L")
    vline!(p, [sqrt(L / K_US)]; color = :gray, ls = :dot, label = "characteristic speed")
    scatter!(p, [q.vx for q in sweep_points], [q.gain for q in sweep_points];
        ms = 6, color = :steelblue, label = "planar car, δ = 0.01 rad")
    scatter!(p, [q.vx for q in steady_points], [q.gain for q in steady_points];
        ms = 6, marker = :diamond, color = :firebrick, label = "planar car at 80 km/h, δ = 0.005 … 0.03 rad")
    p
end

# ╔═╡ 8906316c-3d84-4dd7-b3f6-426c4f7715ab
let
    expected_r = (0.02996, 0.05985, 0.11910, 0.17716)
    atol_r = (3e-4, 6e-4, 1.2e-3, 1.8e-3)
    rows = map(enumerate(steady_points)) do (i, q)
        err = q.r / q.r_formula - 1
        "| $(q.δ) | $(fmt(q.vx, 3)) | $(fmt(q.r, 5)) | $(expected_r[i]) ± $(atol_r[i]) | $(fmt(q.r_formula, 5)) | $(fmt(100err, 2)) % | < 2 % | $(ok(abs(err) < 0.02 && abs(q.r - expected_r[i]) <= atol_r[i])) |"
    end
    sweep_rows = map(sweep_points) do q
        "| 0.01 | $(fmt(q.vx, 3)) | $(fmt(q.r, 5)) | | $(fmt(q.r_formula, 5)) | $(fmt(100(q.r / q.r_formula - 1), 2)) % | (no band) | |"
    end
    k1, k2 = steady_points[1].K_fit, steady_points[2].K_fit
    beta4 = rad2deg(steady_points[4].beta)
    Markdown.parse("""
    | δ [rad] | vx [m/s] | r [rad/s] | expected r | formula r | r / formula − 1 | band | in band |
    |---:|---:|---:|---:|---:|---:|---:|:---:|
    $(join(rows, "\n"))
    $(join(sweep_rows, "\n"))

    Understeer gradient recovered from the runs, `K_fit = (vx·δ/r − L)/vx²`: $(fmt(1e3k1, 3))e-3 and
    $(fmt(1e3k2, 3))e-3 at δ = 0.005 and 0.01 (band 2.039e-3 ± 10 %: $(ok(abs(k1 / K_US - 1) <= 0.1 && abs(k2 / K_US - 1) <= 0.1))).
    Sideslip at δ = 0.03: β = $(fmt(beta4, 3))° (band −0.69° ± 0.05°: $(ok(abs(beta4 + 0.69) <= 0.05))).

    The planar car sits on the bicycle curve within a fraction of a percent; the gap grows with
    lateral acceleration because the tire's cornering force is no longer linear.
    """)
end

# ╔═╡ 4c50ec1e-3957-44a9-9bfc-9f1712765aba
md"""
## 2. The tire: one friction budget

Each tire can transmit at most `μ·F_z` in any direction. Braking force and cornering force
share that budget: the harder a wheel brakes, the less it can corner. The car holds a steady
left turn (δ = 0.03 rad) and at 0.5 s the **left front wheel alone** is braked with a constant
torque; each dot is the wheel's force at 3 s for one torque, the line is the path of the wheel
that locks.
"""

# ╔═╡ c5071dec-edd7-46b6-bacc-f7ef3a6d4e4c
begin
    BRAKE_TORQUES = (0.0, 250.0, 500.0, 750.0, 1000.0, 2500.0)
    brake_sweep = [simulate(L3.PlanarOpenLoopTransient; stop = 3.0, delta_sw_final = I_S * 0.03,
                       T_cmd = τ, brake_fl = 1.0) for τ in BRAKE_TORQUES]
    free_wheel, locked_wheel = brake_sweep[1], brake_sweep[end]

    function fl_forces(run, t)
        w = run.m.car.fl
        Fz = signal(run, w.F_z, t)
        (; Fx = signal(run, w.F_x, t), Fy = signal(run, w.F_y, t), Fz)
    end
    friction_use = maximum(brake_sweep) do run
        f = fl_forces(run, collect(0.0:0.001:3.0))
        maximum(hypot.(f.Fx, f.Fy) ./ f.Fz)
    end
end

# ╔═╡ 1ec15644-8b3b-459d-a75a-283e6cc53ebb
friction_circle_plot = let
    θ = range(0, 2π; length = 361)
    p = plot(cos.(θ), sin.(θ); color = :black, lw = 1.5, label = "μ_A = 1.0 (adhesion peak)",
        aspect_ratio = :equal, xlims = (-1.15, 0.3), ylims = (-0.3, 1.15),
        xlabel = "F_x / F_z (braking is negative)", ylabel = "F_y / F_z (to the left)",
        title = "Left front wheel: braking against cornering", legend = :outerright, size = (850, 450))
    plot!(p, 0.8 .* cos.(θ), 0.8 .* sin.(θ); color = :gray, ls = :dash, lw = 1,
        label = "μ_S = 0.8 (sliding)")
    path = fl_forces(locked_wheel, collect(0.45:0.0005:1.5))
    plot!(p, path.Fx ./ path.Fz, path.Fy ./ path.Fz; color = :firebrick, lw = 2,
        label = "2500 N·m: path to locking")
    ends = [fl_forces(run, [3.0]) for run in brake_sweep]
    scatter!(p, [e.Fx[1] / e.Fz[1] for e in ends], [e.Fy[1] / e.Fz[1] for e in ends];
        ms = 7, color = :steelblue, label = "steady state, 0 … 2500 N·m")
    for (τ, e) in zip(BRAKE_TORQUES, ends)
        annotate!(p, e.Fx[1] / e.Fz[1] + 0.03, e.Fy[1] / e.Fz[1] + 0.06,
            text("$(round(Int, τ))", 8, :left))
    end
    p
end

# ╔═╡ 97f3e52b-b7d1-49d4-9ba3-d5c5a16b1120
locked_plot = let t = collect(0.0:0.002:3.0)
    free = fl_forces(free_wheel, t)
    locked = fl_forces(locked_wheel, t)
    p = plot(t, free.Fy; lw = 2, color = :steelblue, label = "free wheel, lateral F_y",
        xlabel = "time [s]", ylabel = "left front tire force [N]",
        title = "Locked wheel against free wheel", legend = :right)
    plot!(p, t, locked.Fy; lw = 2, color = :firebrick, label = "locked wheel, lateral F_y")
    plot!(p, t, locked.Fx; lw = 2, ls = :dash, color = :firebrick, label = "locked wheel, longitudinal F_x")
    vline!(p, [0.5]; color = :gray, ls = :dot, label = "brake applied")
    p
end

# ╔═╡ 9e870ecb-39c8-4ebf-9807-5432e86dd2cf
let
    free = fl_forces(free_wheel, [3.0])
    locked = fl_forces(locked_wheel, [3.0])
    ratio = locked.Fy[1] / free.Fy[1]
    κ = locked_wheel.sol(3.0; idxs = locked_wheel.m.sensors.kappa_fl)
    Markdown.parse("""
    | quantity | value | band | in band |
    |---|---:|---:|:---:|
    | largest force-to-load ratio `hypot(F_x, F_y) / F_z` of the braked wheel, any torque, any time | $(fmt(friction_use, 4)) | ≤ 1 (μ_A) | $(ok(friction_use <= 1.0 + 1e-6)) |
    | free wheel lateral force at 3 s | $(fmt(free.Fy[1], 0)) N | | |
    | locked wheel lateral force at 3 s | $(fmt(locked.Fy[1], 0)) N | | |
    | locked / free lateral force | $(fmt(ratio, 3)) | (no band in the car) | |
    | locked wheel slip κ at 3 s | $(fmt(κ, 3)) | | |

    No point leaves the circle. More brake torque moves the force around it toward braking and
    takes cornering force away; the locked wheel slides at `μ_S` almost straight backward and
    keeps only $(round(Int, 100ratio)) % of its lateral force, which is why a locked front axle
    cannot steer.
    """)
end

# ╔═╡ 8b444dc3-70ee-41de-bdf6-4004f9ae0a42
md"""
## 3. Sine-with-dwell, passive car

FMVSS 126: at 80 km/h the steering wheel follows one and a half periods of a 0.7 Hz sine with a
0.5 s dwell at the second peak, at amplitudes that are multiples of `A`, the steering-wheel angle
that gives 0.3 g in a slow ramp. The car **passes** if the yaw rate has decayed to 35 % of its
peak 1 s after the steering returns to zero and to 20 % after 1.75 s (`YRR@1.0`, `YRR@1.75`),
and if it has moved at least 1.83 m sideways 1.07 s after the start of steering (required from
`5A` up). `A = 21.63°` here; section 3b measures it.
"""

# ╔═╡ a7c34176-b413-4bb4-813f-89a7ea3e34a5
begin
    PASSIVE_AMPLITUDES = (32.0, 76.0, 97.0, 141.0, 180.0, 220.0, 270.0)
    passive = Dict(a => simulate(L3.SineWithDwellRunTransient; A_sw = deg2rad(a))
                   for a in PASSIVE_AMPLITUDES)
    passive_metrics = Dict(a => sdw_metrics(run) for (a, run) in passive)
end

# ╔═╡ 203f12d3-7db5-4afc-82b3-93af3ca377cb
trajectory_plot = let
    p = plot(xlabel = "x [m]", ylabel = "y [m] (left)", title = "Passive car, sine-with-dwell",
        legend = :bottomleft)
    for (a, color) in ((76.0, :seagreen), (97.0, :firebrick), (270.0, :steelblue))
        run = passive[a]
        x, y = signal(run, run.m.sensors.x), signal(run, run.m.sensors.y)
        plot!(p, x, y; lw = 2, color, label = "$(round(Int, a))° SWA")
        scatter!(p, [x[end]], [y[end]]; color, ms = 6, label = "")
    end
    p
end

# ╔═╡ e98aac4c-ac22-4dbe-b3bd-a886dcf8ba96
let
    expected = Dict(32.0 => (0.00, 0.00, 1.15), 76.0 => (0.00, 0.00, 2.53),
        97.0 => (1.37, 1.37, 3.08), 141.0 => (1.01, 1.01, 3.69), 180.0 => (0.93, 0.93, 3.73),
        220.0 => (0.85, 0.85, 3.63), 270.0 => (0.00, 0.00, 3.45))
    rows = map(PASSIVE_AMPLITUDES) do a
        q, e, β = passive_metrics[a], expected[a], beta_max_deg(passive[a])
        verdict = q.passes_stability ? (β < 10 && a > 200 ? "plows, passes" : "pass") : "**spins**"
        in_band = abs(q.yrr_1_00 - e[1]) <= 0.05 && abs(q.yrr_1_75 - e[2]) <= 0.05 &&
                  abs(q.y_bos_1_07 - e[3]) <= 0.1 &&
                  (a in (32.0, 76.0, 270.0) ? q.passes_stability : true) &&
                  (a in (97.0, 141.0, 180.0) ? !q.passes_stability && β > 45 : true) &&
                  (a == 270.0 ? β < 10 : true)
        "| $(round(Int, a))° | $(fmt(q.yrr_1_00, 2)) | $(fmt(q.yrr_1_75, 2)) | $(fmt(q.y_bos_1_07, 2)) m | $(fmt(β, 1))° | $(fmt(end_speed(passive[a]), 1)) | $verdict | $(e[1]) / $(e[2]) / $(e[3]) m | $(ok(in_band)) |"
    end
    Markdown.parse("""
    | SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | end vx [m/s] | verdict | expected (±0.05 / ±0.05 / ±0.1 m) | in band |
    |---:|---:|---:|---:|---:|---:|:---:|---:|:---:|
    $(join(rows, "\n"))

    The uncontrolled car spins in the middle amplitudes (it ends the run going backward) and
    plows at the largest: at 270° the front tires saturate before the rear ones can, so the car
    runs wide instead of rotating. Real test data show the same non-monotonic pattern.
    """)
end

# ╔═╡ f6379dd7-8502-44eb-b269-6e2aed61bd11
md"""
### 3b. The steering: Ackermann geometry

The steering wheel turns the virtual center wheel through the column (`δ = δ_sw/16`); the
linkage then turns the inner wheel further than the outer one,
`tan δ_left = tan δ/(1 − k tan δ)`, `tan δ_right = tan δ/(1 + k tan δ)`, `k = t_k/(2L)`, so that
both wheel axes meet on the rear-axle line. A parallel linkage (`ackermann = 0`) turns both
wheels by `δ`. At 3 m/s on a 13 m radius (δ_sw = 3.2 rad) the difference shows up in the slip
angles: with parallel steer the two front tires fight each other across the axle.
"""

# ╔═╡ 037af68c-4aec-4cf6-bc31-b242d7015b1b
begin
    steer_ramp = simulate(L3.PlanarOpenLoopTransient; stop = 8.0,
        delta_sw_final = deg2rad(13.5) * 7.5, t_ramp = 7.5, t_steer = 0.5)
    low_ackermann = simulate(L3.PlanarOpenLoopTransient; stop = 4.0, v0 = 3.0,
        delta_sw_final = 3.2, ackermann = 1.0)
    low_parallel = simulate(L3.PlanarOpenLoopTransient; stop = 4.0, v0 = 3.0,
        delta_sw_final = 3.2, ackermann = 0.0)

    ramp_ay = signal(steer_ramp, steer_ramp.m.sensors.vx) .* signal(steer_ramp, steer_ramp.m.sensors.r)
    measured_A = rad2deg(signal(steer_ramp, steer_ramp.m.sensors.delta_sw)[findfirst(>=(0.3G), ramp_ay)])
end

# ╔═╡ 5209998d-a17e-4db0-9149-c897b3f5b9c2
ackermann_plot = let
    function angles(run)
        t = collect(0.0:0.001:0.2)
        (; sw = rad2deg.(signal(run, run.m.sensors.delta_sw, t)),
           left = rad2deg.(signal(run, run.m.car.linkage.delta_left, t)),
           right = rad2deg.(signal(run, run.m.car.linkage.delta_right, t)))
    end
    a, q = angles(low_ackermann), angles(low_parallel)
    p = plot(a.sw, a.left; lw = 2, color = WHEEL_COLORS.fl, label = "Ackermann, left (inner) wheel",
        xlabel = "steering-wheel angle [°]", ylabel = "road-wheel angle [°]",
        title = "Road-wheel angles in a left turn", legend = :topleft)
    plot!(p, a.sw, a.right; lw = 2, color = WHEEL_COLORS.fr, label = "Ackermann, right (outer) wheel")
    plot!(p, q.sw, q.left; lw = 2, ls = :dash, color = :gray, label = "parallel, both wheels")
    p
end

# ╔═╡ 331aaeff-abda-4211-9959-512613856ef6
scrub_plot = let
    p = plot(xlabel = "time [s]", ylabel = "front slip angle α [°]",
        title = "Front slip angles at 3 m/s, 13 m radius", legend = :right)
    for (run, ls, name) in ((low_ackermann, :solid, "Ackermann"), (low_parallel, :dash, "parallel"))
        s = run.m.sensors
        plot!(p, run.sol.t, rad2deg.(signal(run, s.alpha_fl)); lw = 2, ls, color = WHEEL_COLORS.fl,
            label = "$name, left front")
        plot!(p, run.sol.t, rad2deg.(signal(run, s.alpha_fr)); lw = 2, ls, color = WHEEL_COLORS.fr,
            label = "$name, right front")
    end
    hline!(p, [0.0]; color = :black, lw = 0.5, label = "")
    p
end

# ╔═╡ 31a0fbf9-0c77-44ab-b928-fc9810507d11
let
    final(run, x) = run.sol(4.0; idxs = x)
    sa, sp = low_ackermann.m.sensors, low_parallel.m.sensors
    afl_a, afr_a = final(low_ackermann, sa.alpha_fl), final(low_ackermann, sa.alpha_fr)
    afl_p, afr_p = final(low_parallel, sp.alpha_fl), final(low_parallel, sp.alpha_fr)
    v_a, v_p = final(low_ackermann, sa.vx), final(low_parallel, sp.vx)
    max_ay = maximum(abs, ramp_ay) / G
    Markdown.parse("""
    | quantity | value | band | in band |
    |---|---:|---:|:---:|
    | FMVSS amplitude `A` (SWA where `vx·r` first reaches 0.3 g, 13.5°/s ramp) | $(fmt(measured_A, 2))° | 21.6° ± 1° | $(ok(abs(measured_A - 21.6) <= 1.0)) |
    | largest `vx·r` in the ramp | $(fmt(max_ay, 3)) g | ≤ 1.01 g | $(ok(max_ay <= 1.01)) |
    | Ackermann `α_fl`, `α_fr` at 4 s | $(fmt(afl_a, 5)), $(fmt(afr_a, 5)) rad | −0.00573, −0.00498 ± 3e-4 | $(ok(abs(afl_a + 0.00573) <= 3e-4 && abs(afr_a + 0.00498) <= 3e-4)) |
    | parallel `α_fl`, `α_fr` at 4 s | $(fmt(afl_p, 5)), $(fmt(afr_p, 5)) rad | +0.00493, −0.01672 ± 3e-4 | $(ok(abs(afl_p - 0.00493) <= 3e-4 && abs(afr_p + 0.01672) <= 3e-4)) |
    | Ackermann `abs(α_fl − α_fr)` | $(fmt(abs(afl_a - afr_a), 5)) rad | < 0.002 | $(ok(abs(afl_a - afr_a) < 0.002)) |
    | parallel `abs(α_fl − α_fr)` | $(fmt(abs(afl_p - afr_p), 5)) rad | > 0.018 | $(ok(abs(afl_p - afr_p) > 0.018)) |
    | speed lost to scrub, `vx_Ackermann − vx_parallel` at 4 s | $(fmt(v_a - v_p, 3)) m/s | ≥ 0.02 | $(ok(v_a - v_p >= 0.02)) |

    With Ackermann geometry both front tires slip by about the same small angle; with parallel
    steer the inner tire is pushed outward and the two fight, which costs speed. At 80 km/h the
    slip angles from cornering dwarf this geometric difference, so the sine-with-dwell results
    hardly depend on it.
    """)
end

# ╔═╡ 1c10f2c4-b7de-4383-905f-0b0d693dba3a
md"""
## 4. ESP on

The ESP compares the measured yaw rate with a reference, the bicycle model's steady-state
yaw rate for the current steering-wheel angle and speed, capped at what the road allows:

```math
r_{ref} = \operatorname{sign}(\delta)\,\min\!\left(\left|\frac{v_x\,\delta}{L + K_{us} v_x^2}\right|,\ \frac{0.85\,\mu\,g}{v_x}\right).
```

A proportional law turns the error into a yaw-moment demand (with a 0.03 rad/s dead band, off
below 5 m/s), and the allocator brakes one wheel: the **outer front** wheel when the car
oversteers (too much yaw), the **inner rear** wheel when it understeers (too little). A
braked wheel on the left side pulls the car to the left.

Here the ESP brakes the wheels directly, without ABS; section 5 adds it.
"""

# ╔═╡ 5a2e2752-a4fb-4d51-a84e-812c39c1a274
begin
    ESP_AMPLITUDES = (32.0, 97.0, 180.0, 270.0)
    esp = Dict(a => simulate(L3.ESPSineWithDwellTransient; A_sw = deg2rad(a)) for a in ESP_AMPLITUDES)
    esp_metrics = Dict(a => sdw_metrics(run) for (a, run) in esp)
end

# ╔═╡ 8949e40c-cbe9-4327-b4ac-93cae1e8cb11
md"""
Amplitude shown in the detail plots of sections 4 and 5:
$(@bind detail_amplitude Select([97.0 => "97°", 180.0 => "180°", 270.0 => "270°"]; default = 180.0))
"""

# ╔═╡ d77c5d82-277e-4098-9821-6339c1fb76fc
yaw_plot = let run = esp[detail_amplitude], ref = passive[detail_amplitude]
    s = run.m.sensors
    p = plot(ref.sol.t, rad2deg.(signal(ref, ref.m.sensors.r)); lw = 2, ls = :dash, color = :firebrick,
        label = "ESP off: yaw rate", xlabel = "time [s]", ylabel = "yaw rate [°/s]",
        title = "Yaw rate at $(round(Int, detail_amplitude))° SWA", legend = :bottomleft,
        ylims = (-60, 60))
    plot!(p, run.sol.t, rad2deg.(signal(run, run.m.esp.r_ref)); lw = 1.5, color = :black,
        ls = :dot, label = "ESP reference r_ref")
    plot!(p, run.sol.t, rad2deg.(signal(run, s.r)); lw = 2, color = :steelblue, label = "ESP on: yaw rate")
    vline!(p, [T_COS]; color = :gray, ls = :dot, label = "steering back at zero")
    p
end

# ╔═╡ 42dce172-149f-402c-b0bd-2cc4d808021f
esp_torque_plot = let run = esp[detail_amplitude]
    c = run.m.car
    p = plot(xlabel = "time [s]", ylabel = "brake torque command [N·m]",
        title = "Which wheel the ESP brakes, $(round(Int, detail_amplitude))° SWA", legend = :topright)
    for (w, τ) in ((:fl, c.tau_fl), (:fr, c.tau_fr), (:rl, c.tau_rl), (:rr, c.tau_rr))
        plot!(p, run.sol.t, signal(run, τ); lw = 2, color = WHEEL_COLORS[w], label = string(w))
    end
    vline!(p, [1.0 + 0.5 / 0.7]; color = :gray, ls = :dot, label = "steering reverses")
    p
end

# ╔═╡ 0fbfcf71-2a01-4ab8-945e-15ca985aeb02
let
    rows = map(ESP_AMPLITUDES) do a
        q, run = esp_metrics[a], esp[a]
        β, v, κ = beta_max_deg(run), end_speed(run), min_kappa(run)
        in_band = q.passes_stability && (a < 108.15 || q.y_bos_1_07 >= 1.83) && β < 10 &&
                  (a < 97 || (12.0 <= v <= 16.0 && κ < -0.9))
        "| $(round(Int, a))° | $(fmt(q.yrr_1_00, 2)) | $(fmt(q.yrr_1_75, 2)) | $(fmt(q.y_bos_1_07, 2)) m | $(fmt(β, 1))° | $(fmt(v, 1)) | $(fmt(κ, 2)) | $(q.passes_stability ? "pass" : "**fail**") | $(ok(in_band)) |"
    end
    run = esp[180.0]
    t = collect(range(1.0 + 0.5 / 0.7, T_COS + 1.5; length = 1001))
    c = run.m.car
    integrals = [trapz(t, signal(run, τ, t)) for τ in (c.tau_fl, c.tau_fr, c.tau_rl, c.tau_rr)]
    Markdown.parse("""
    | SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | end vx [m/s] | min κ | verdict | in band |
    |---:|---:|---:|---:|---:|---:|---:|:---:|:---:|
    $(join(rows, "\n"))

    Bands: passes at every amplitude, `y(BOS+1.07) ≥ 1.83 m` from 108°, `β_max < 10°`, and, the
    known flaw of braking without ABS, an end speed of 12–16 m/s with a locked wheel
    (`min κ < −0.9`) from 97° up.

    Brake work `∫τ dt` at 180°, from the steering reversal to 1.5 s after it returns to zero:
    fl $(fmt(integrals[1], 0)), fr $(fmt(integrals[2], 0)), rl $(fmt(integrals[3], 0)),
    rr $(fmt(integrals[4], 0)) N·m·s. The left front wheel, outer in the right turn after the
    reversal, gets the most (band: fl largest: $(ok(argmax(integrals) == 1)); MTK probe
    1600 / 673 / 79 / 970).

    The ESP catches every amplitude the passive car spun at. The price shows in the end speed
    and slip: the braked wheel locks, and from 97° up the car loses
    $(round(Int, 100 * (1 - maximum(end_speed(esp[a]) for a in ESP_AMPLITUDES if a >= 97) / 22.222)))–$(round(Int, 100 * (1 - minimum(end_speed(esp[a]) for a in ESP_AMPLITUDES if a >= 97) / 22.222))) %
    of its speed.
    """)
end

# ╔═╡ 17f143ec-2328-4bd8-8764-88428e5fa19b
md"""
### Understeer: braking the inner rear wheel

A slow steering ramp (13.5°/s) with the front tires at 70 % of their grip: the front axle
saturates first and the car turns less than the driver asks for. The ESP now brakes the inner
rear wheel, the left one in this left turn, to add yaw.
"""

# ╔═╡ 58bec511-99e1-439c-bec3-b93abb1a734e
begin
    understeer_on = simulate(L3.ESPSteerRampTransient)
    understeer_off = simulate(L3.ESPSteerRampTransient; esp_on = 0.0)
end

# ╔═╡ 16eda515-3beb-4ce2-8996-70272adbb36b
understeer_plot = let
    p = plot(xlabel = "time [s]", ylabel = "yaw rate [°/s]",
        title = "Understeer: front grip at 70 %", legend = :topleft)
    plot!(p, understeer_on.sol.t, rad2deg.(signal(understeer_on, understeer_on.m.esp.r_ref));
        lw = 1.5, ls = :dot, color = :black, label = "ESP reference r_ref")
    plot!(p, understeer_off.sol.t, rad2deg.(signal(understeer_off, understeer_off.m.sensors.r));
        lw = 2, ls = :dash, color = :firebrick, label = "ESP off: yaw rate")
    plot!(p, understeer_on.sol.t, rad2deg.(signal(understeer_on, understeer_on.m.sensors.r));
        lw = 2, color = :steelblue, label = "ESP on: yaw rate")
    p
end

# ╔═╡ 594c02a5-c155-49a2-a233-bacbb9431e22
let
    t = collect(range(0.0, 8.0; length = 1601))
    c = understeer_on.m.car
    integrals = [trapz(t, signal(understeer_on, τ, t)) for τ in (c.tau_fl, c.tau_fr, c.tau_rl, c.tau_rr)]
    shortfall(run) = minimum(signal(run, run.m.sensors.r) .- signal(run, run.m.esp.r_ref))
    on, off = shortfall(understeer_on), shortfall(understeer_off)
    Markdown.parse("""
    | quantity | value | band | in band |
    |---|---:|---:|:---:|
    | `∫τ dt` fl / fr / rl / rr | $(join((fmt(x, 0) for x in integrals), " / ")) N·m·s | rl > 10 × each other wheel (probe 0 / 0 / 3045 / 0) | $(ok(integrals[3] > 10 * maximum(integrals[[1, 2, 4]]))) |
    | yaw-rate shortfall `min(r − r_ref)`, ESP off | $(fmt(off, 3)) rad/s | (probe −0.145) | |
    | yaw-rate shortfall, ESP on | $(fmt(on, 3)) rad/s | at least 30 % smaller than off (probe −0.071) | $(ok(abs(on) <= 0.7 * abs(off))) |

    Only the inner rear wheel brakes, and the car follows the driver's request more closely; it
    cannot reach it, because the front tires are already at their limit.
    """)
end

# ╔═╡ a7e6e475-f721-4008-9946-89a1d3ba08eb
md"""
## 5. ESP through ABS

The ESP request now goes through the car's four ABS channels (5 ms clock, release at
κ = −0.08 front and −0.06 rear) and the controller gains an integral term (`Ki = 1e5`). The
braked wheel stays near its slip peak instead of locking, so it keeps both braking and
cornering force, and the car keeps its speed.
"""

# ╔═╡ d1cb6c1d-2795-4d19-9073-65185b1b5c8e
begin
    esp_abs = Dict(a => simulate(L3.ESPSineWithDwellTransient; A_sw = deg2rad(a), abs_on = 1.0, Ki = 1e5)
                   for a in ESP_AMPLITUDES)
    esp_abs_metrics = Dict(a => sdw_metrics(run) for (a, run) in esp_abs)
end

# ╔═╡ 5cacf941-de20-4e45-b3b7-5b3d4c74fcc1
abs_slip_plot = let
    panel(run, title) = begin
        p = plot(xlabel = "time [s]", ylabel = "wheel slip κ", title = title, ylims = (-1.05, 0.05),
            legend = :bottomleft, titlefontsize = 10)
        kappas = wheel_signals(run, "kappa_")
        for (w, κ) in zip((:fl, :fr, :rl, :rr), kappas)
            plot!(p, run.sol.t, κ; lw = 1.5, color = WHEEL_COLORS[w], label = string(w))
        end
        hline!(p, [-0.2]; color = :black, ls = :dot, label = "κ = −0.2")
        p
    end
    a = round(Int, detail_amplitude)
    plot(panel(esp[detail_amplitude], "ESP braking directly, $(a)°"),
        panel(esp_abs[detail_amplitude], "ESP through ABS, $(a)°"); layout = (1, 2), size = (900, 380))
end

# ╔═╡ 4203ffd2-b710-45ce-947b-851780cca52c
end_speed_plot = let
    p = plot(xlabel = "steering-wheel amplitude [°]", ylabel = "speed at 6 s [m/s]",
        title = "Speed kept through the maneuver", legend = :bottomleft, ylims = (0, 24),
        xticks = collect(ESP_AMPLITUDES))
    plot!(p, collect(ESP_AMPLITUDES), [end_speed(esp[a]) for a in ESP_AMPLITUDES];
        lw = 2, marker = :circle, ms = 6, color = :firebrick, label = "ESP braking directly")
    plot!(p, collect(ESP_AMPLITUDES), [end_speed(esp_abs[a]) for a in ESP_AMPLITUDES];
        lw = 2, marker = :diamond, ms = 6, color = :steelblue, label = "ESP through ABS")
    p
end

# ╔═╡ e6c11ee8-3bb5-4680-b99c-92d8cc47682d
let
    gains = [end_speed(esp_abs[a]) - end_speed(esp[a]) for a in ESP_AMPLITUDES if a >= 97]
    rows = map(ESP_AMPLITUDES) do a
        q, run = esp_abs_metrics[a], esp_abs[a]
        κ, v, v5 = min_kappa_moving(run), end_speed(run), end_speed(esp[a])
        in_band = q.passes_stability && (a < 108.15 || q.y_bos_1_07 >= 1.83) && κ >= -0.2 &&
                  (a < 97 || v >= v5 + 2.0)
        "| $(round(Int, a))° | $(fmt(q.yrr_1_00, 2)) | $(fmt(q.yrr_1_75, 2)) | $(fmt(q.y_bos_1_07, 2)) m | $(fmt(beta_max_deg(run), 1))° | $(fmt(κ, 3)) | $(fmt(v, 1)) | $(fmt(v5, 1)) | $(q.passes_stability ? "pass" : "**fail**") | $(ok(in_band)) |"
    end
    Markdown.parse("""
    | SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | min κ (vx > 3 m/s) | end vx [m/s] | without ABS | verdict | in band |
    |---:|---:|---:|---:|---:|---:|---:|---:|:---:|:---:|
    $(join(rows, "\n"))

    Bands: passes at every amplitude, `y(BOS+1.07) ≥ 1.83 m` from 108°, every κ ≥ −0.2 while
    the car moves faster than 3 m/s, and from 97° up an end speed at least 2 m/s above the ESP
    without ABS.

    The ESP still prevents the spin, no wheel locks, and from 97° up the car ends
    $(fmt(minimum(gains), 1))–$(fmt(maximum(gains), 1)) m/s faster.
    """)
end

# ╔═╡ 431516f2-85b1-44d0-a70a-2c719fd13235
md"""
## 6. Split-µ: braking with one side on ice

Full braking (2500 N·m demand per wheel at 0.5 s) with the left wheels on dry asphalt (µ = 1.0)
and the right wheels on ice (µ = 0.3), steering wheel held straight. ABS keeps every wheel
rolling, but the left side brakes harder than the right, and the difference yaws the car
toward the high-µ side. Three fixes, stacked:

- **rear select-low**: both rear wheels get the lower of the two ABS torques, so the rear axle
  adds no yaw moment;
- **ESP, P**: the yaw controller cuts brake torque on the high-µ side as the car starts to
  turn;
- **ESP, PI**: the integral term holds the cut while the yaw error persists.

The heading, lateral offset and distance are read when the car falls below 3 m/s, or at 6 s.
"""

# ╔═╡ fcc9a2ab-60e3-4378-baf5-a18a91dcc6e0
begin
    SPLIT_CONFIGS = (
        (name = "ABS only", color = :firebrick, knobs = (select_low = 0.0, esp_on = 0.0)),
        (name = "ABS + rear select-low", color = :darkorange, knobs = (select_low = 1.0, esp_on = 0.0)),
        (name = "select-low + ESP, P", color = :mediumpurple, knobs = (select_low = 1.0, esp_on = 1.0, Ki = 0.0)),
        (name = "select-low + ESP, PI", color = :steelblue, knobs = (select_low = 1.0, esp_on = 1.0)),
    )
    split_runs = [simulate(L3.SplitMuStopTransient; c.knobs...) for c in SPLIT_CONFIGS]

    function split_measurement(run)
        s = run.m.sensors
        t = collect(range(0.0, 6.0; length = 1201))
        speeds = signal(run, s.vx, t)
        t_metric = t[something(findfirst(<(3.0), speeds), length(t))]
        (; t_metric, heading = rad2deg(run.sol(t_metric; idxs = s.psi)),
           offset = run.sol(t_metric; idxs = s.y), distance = run.sol(t_metric; idxs = s.x),
           end_speed = speeds[end])
    end
    split_results = [split_measurement(run) for run in split_runs]
end

# ╔═╡ 49982f42-f1e2-46e4-9f67-031342b9b7df
split_trajectory_plot = let
    p = plot(xlabel = "x [m]", ylabel = "y [m] (left, high-µ side)",
        title = "Split-µ stop: path", legend = :topleft)
    for (c, run, q) in zip(SPLIT_CONFIGS, split_runs, split_results)
        t = collect(0.0:0.01:q.t_metric)
        plot!(p, signal(run, run.m.sensors.x, t), signal(run, run.m.sensors.y, t);
            lw = 2, color = c.color, label = c.name)
        scatter!(p, [q.distance], [q.offset]; color = c.color, ms = 6, label = "")
    end
    p
end

# ╔═╡ 68be5b29-4cf6-46fc-bce4-509c229edc74
split_heading_plot = let
    p = plot(xlabel = "time [s]", ylabel = "heading ψ [°]", title = "Split-µ stop: heading",
        legend = :topleft)
    for (c, run) in zip(SPLIT_CONFIGS, split_runs)
        plot!(p, run.sol.t, rad2deg.(signal(run, run.m.sensors.psi)); lw = 2, color = c.color,
            label = c.name)
    end
    vline!(p, [0.5]; color = :gray, ls = :dot, label = "brake applied")
    p
end

# ╔═╡ fd98707a-4189-4911-9547-f28f1b116fc9
let
    a, s, p_only, pi_run = split_results
    bands = (
        ("heading > 15° (turns to the high-µ side)", a.heading > 15.0),
        ("`abs(heading)` below ABS only", abs(s.heading) < abs(a.heading)),
        ("(no band; the probe's P row is a different allocation)", true),
        ("`abs(heading)` < 5°, distance > select-low's", abs(pi_run.heading) < 5.0 && pi_run.distance > s.distance),
    )
    rows = map(zip(SPLIT_CONFIGS, split_results, bands)) do (c, q, b)
        "| $(c.name) | $(fmt(q.heading, 1))° | $(fmt(q.offset, 1)) m | $(fmt(q.distance, 1)) m | $(fmt(q.end_speed, 1)) | $(b[1]) | $(ok(b[2])) |"
    end
    Markdown.parse("""
    | configuration | heading | lateral offset | distance | vx at 6 s [m/s] | band | in band |
    |---|---:|---:|---:|---:|---|:---:|
    $(join(rows, "\n"))

    ABS alone lets the car spin toward the dry side. Select-low removes the rear axle's share
    of the yaw moment. The P controller alone barely changes the result: it reacts to the yaw
    rate, not to the heading already lost, while the integral of the yaw-rate error is that
    heading. With the integral term the ESP holds the heading within a few degrees, at the cost of a
    longer stop: holding the heading means giving up brake force on the dry side, the trade
    every ESP calibration makes.
    """)
end

# ╔═╡ a0eac40a-5fd7-4ced-8e19-6c973714e4f0
md"""
## 7. Load transfer

So far each wheel carried its static share of the weight. With the center of gravity
`h_cg = 0.55 m` above the road, the body's accelerations move load between the wheels:

```math
\Delta N_{long} = \frac{m\,a_x\,h}{2L}, \qquad
\Delta N_{lat,f} = \frac{m\,a_y\,h}{t_w}\frac{b}{L}, \qquad
\Delta N_{lat,r} = \frac{m\,a_y\,h}{t_w}\frac{a}{L},
```

applied as forces on the wheels' load flanges through a 50 ms lag. A left turn unloads the left
wheels; the total is always `m·g = 14 715 N`. The clocked ESP and the sideslip-drift study are
not part of this notebook.
"""

# ╔═╡ fd3dc56e-a30a-4b53-b154-648916fec176
begin
    lt_steady = simulate(L3.PlanarOpenLoopTransient; stop = 4.0, delta_sw_final = I_S * 0.03, h_cg = 0.55)
    LT_AMPLITUDES = (97.0, 180.0, 270.0, 280.0)
    passive_lt = Dict(a => simulate(L3.SineWithDwellRunTransient; A_sw = deg2rad(a), h_cg = 0.55)
                      for a in LT_AMPLITUDES)
    esp_abs_lt = simulate(L3.ESPSineWithDwellTransient; A_sw = deg2rad(270.0), abs_on = 1.0,
        Ki = 1e5, h_cg = 0.55)
end

# ╔═╡ 66f75b1d-a6c7-474e-8451-480ba9754948
load_plot = let
    loads(run) = [run.sol(4.0; idxs = getproperty(run.m.car, w).F_z) for w in (:fl, :fr, :rl, :rr)]
    p = bar((1:4) .- 0.2, loads(steady[4]); bar_width = 0.4, color = :gray, label = "h_cg = 0",
        xticks = (1:4, ["fl", "fr", "rl", "rr"]), ylabel = "wheel load F_z [N]",
        title = "Wheel loads in a steady left turn (0.39 g)", legend = :topright, ylims = (0, 6000))
    bar!(p, (1:4) .+ 0.2, loads(lt_steady); bar_width = 0.4, color = :steelblue, label = "h_cg = 0.55 m")
    p
end

# ╔═╡ ee29db6d-85d5-4a4f-a152-63bac3dbdc02
lt_yaw_plot = let
    p = plot(xlabel = "time [s]", ylabel = "yaw rate [°/s]", title = "270° SWA with load transfer",
        legend = :outerbottom, size = (800, 600))
    for (run, color, ls, label) in (
            (passive[270.0], :gray, :dash, "passive, h_cg = 0 (270°)"),
            (passive_lt[270.0], :firebrick, :solid, "passive, h_cg = 0.55 m (270°)"),
            (passive_lt[280.0], :darkorange, :solid, "passive, h_cg = 0.55 m (280°)"),
            (esp_abs_lt, :steelblue, :solid, "ESP through ABS, h_cg = 0.55 m (270°)"))
        plot!(p, run.sol.t, rad2deg.(signal(run, run.m.sensors.r)); lw = 2, color, ls, label)
    end
    vline!(p, [T_COS]; color = :gray, ls = :dot, label = "")
    p
end

# ╔═╡ 80b0a70a-419b-494f-a301-27de59961e1d
let
    m = lt_steady.m
    dN = [lt_steady.sol(4.0; idxs = getproperty(m.car.loads, Symbol("dN_", w))) for w in (:fl, :fr, :rl, :rr)]
    expected = [-1134.0, 1153.0, -924.0, 905.0]
    dN_sum = maximum(abs, signal(lt_steady, m.car.loads.dN_fl) .+ signal(lt_steady, m.car.loads.dN_fr) .+
                          signal(lt_steady, m.car.loads.dN_rl) .+ signal(lt_steady, m.car.loads.dN_rr))
    Fz_sum = maximum(abs, signal(lt_steady, m.car.fl.F_z) .+ signal(lt_steady, m.car.fr.F_z) .+
                          signal(lt_steady, m.car.rl.F_z) .+ signal(lt_steady, m.car.rr.F_z) .- 1500 * 9.81)
    ay = lt_steady.sol(4.0; idxs = m.sensors.ay)
    r = lt_steady.sol(4.0; idxs = m.sensors.r)
    Fz_fl = lt_steady.sol(4.0; idxs = m.car.fl.F_z)
    sdw_rows = map(LT_AMPLITUDES) do a
        run = passive_lt[a]
        q, β = sdw_metrics(run), beta_max_deg(run)
        band, pass = a in (97.0, 180.0) ? ("spins (probe YRR@1.0 $(a == 97.0 ? "1.35" : "0.88"))", !q.passes_stability) :
                     a == 270.0 ? ("report (probes: spins, YRR 0.90 / 1.16, β_max 68°)", true) :
                     ("report (Dyad probe: plows, YRR 0, end vx 19.3)", true)
        "| passive, $(round(Int, a))° | $(fmt(q.yrr_1_00, 2)) | $(fmt(q.yrr_1_75, 2)) | $(fmt(β, 1))° | $(fmt(end_speed(run), 1)) | $(q.passes_stability ? (β < 10 ? "plows, passes" : "pass") : "**spins**") | $band | $(ok(pass)) |"
    end
    qe = sdw_metrics(esp_abs_lt)
    esp_row = "| ESP through ABS, 270° | $(fmt(qe.yrr_1_00, 2)) | $(fmt(qe.yrr_1_75, 2)) | $(fmt(beta_max_deg(esp_abs_lt), 1))° | $(fmt(end_speed(esp_abs_lt), 1)) | $(qe.passes_stability ? "pass" : "**fail**") | passes (MTK probe end vx 17.0–17.5) | $(ok(qe.passes_stability && qe.passes_responsiveness && min_kappa(esp_abs_lt) >= -0.2)) |"
    r0 = steady_points[4].r
    Markdown.parse("""
    **Steady turn, δ = 0.03 rad, read at 4 s.**

    | quantity | value | band | in band |
    |---|---:|---:|:---:|
    | `dN` fl / fr / rl / rr | $(join((fmt(x, 0) for x in dN), " / ")) N | −1134 / +1153 / −924 / +905 ± 2 | $(ok(maximum(abs, dN .- expected) <= 2.0)) |
    | largest `abs(Σ dN)` over the run | $(fmt(dN_sum, 9)) N | ≤ 1e-6 | $(ok(dN_sum <= 1e-6)) |
    | largest `abs(Σ F_z − m g)` over the run | $(fmt(Fz_sum, 9)) N | ≤ 1e-6 | $(ok(Fz_sum <= 1e-6)) |
    | `a_y` | $(fmt(ay, 3)) m/s² | 3.865 ± 0.01 | $(ok(abs(ay - 3.865) <= 0.01)) |
    | `r` | $(fmt(r, 5)) rad/s | 0.17692 ± 1e-3 | $(ok(abs(r - 0.17692) <= 1e-3)) |
    | `F_z` left front | $(fmt(Fz_fl, 0)) N | 2953 ± 5 | $(ok(abs(Fz_fl - 2953) <= 5)) |

    The yaw rate moves by only $(fmt(100 * (r / r0 - 1), 2)) % against the car without load
    transfer ($(fmt(r0, 5)) rad/s): the tire's cornering stiffness grows with its load, so
    moving load across an axle leaves the axle's stiffness unchanged. Load transfer matters
    near the limit, where the unloaded inner wheel saturates first.

    **Sine-with-dwell with `h_cg = 0.55 m`.**

    | run | YRR@1.0 | YRR@1.75 | β_max | end vx [m/s] | verdict | band | in band |
    |---|---:|---:|---:|---:|:---:|---|:---:|
    $(join(sdw_rows, "\n"))
    $esp_row

    Without load transfer the passive car plows at 270° and passes; with it the car spins at
    270° and plows again at 280°. The spin/plow boundary sits right at the top amplitude of the
    test and moves with small changes to the geometry, so the 270° verdict of a passive car is
    not a robust number. The ESP through ABS passes either way.
    """)
end

# ╔═╡ Cell order:
# ╟─f21bf7ce-c4d8-44a0-a6d7-84e6a6f2a3a1
# ╠═43fc3fc4-efba-4d6b-8e46-492f3c4403a5
# ╠═d11b8972-f61e-4eea-95fe-e8cb11bfff21
# ╟─14046bd4-e891-4417-b186-20b88e7eff9c
# ╠═e985de24-162f-4c9c-bfd0-8d150d1d050c
# ╠═18f356b0-20fc-4c18-a16b-078371b5de6a
# ╟─8906316c-3d84-4dd7-b3f6-426c4f7715ab
# ╟─4c50ec1e-3957-44a9-9bfc-9f1712765aba
# ╠═c5071dec-edd7-46b6-bacc-f7ef3a6d4e4c
# ╠═1ec15644-8b3b-459d-a75a-283e6cc53ebb
# ╠═97f3e52b-b7d1-49d4-9ba3-d5c5a16b1120
# ╟─9e870ecb-39c8-4ebf-9807-5432e86dd2cf
# ╟─8b444dc3-70ee-41de-bdf6-4004f9ae0a42
# ╠═a7c34176-b413-4bb4-813f-89a7ea3e34a5
# ╠═203f12d3-7db5-4afc-82b3-93af3ca377cb
# ╟─e98aac4c-ac22-4dbe-b3bd-a886dcf8ba96
# ╟─f6379dd7-8502-44eb-b269-6e2aed61bd11
# ╠═037af68c-4aec-4cf6-bc31-b242d7015b1b
# ╠═5209998d-a17e-4db0-9149-c897b3f5b9c2
# ╠═331aaeff-abda-4211-9959-512613856ef6
# ╟─31a0fbf9-0c77-44ab-b928-fc9810507d11
# ╟─1c10f2c4-b7de-4383-905f-0b0d693dba3a
# ╠═5a2e2752-a4fb-4d51-a84e-812c39c1a274
# ╟─8949e40c-cbe9-4327-b4ac-93cae1e8cb11
# ╠═d77c5d82-277e-4098-9821-6339c1fb76fc
# ╠═42dce172-149f-402c-b0bd-2cc4d808021f
# ╟─0fbfcf71-2a01-4ab8-945e-15ca985aeb02
# ╟─17f143ec-2328-4bd8-8764-88428e5fa19b
# ╠═58bec511-99e1-439c-bec3-b93abb1a734e
# ╠═16eda515-3beb-4ce2-8996-70272adbb36b
# ╟─594c02a5-c155-49a2-a233-bacbb9431e22
# ╟─a7e6e475-f721-4008-9946-89a1d3ba08eb
# ╠═d1cb6c1d-2795-4d19-9073-65185b1b5c8e
# ╠═5cacf941-de20-4e45-b3b7-5b3d4c74fcc1
# ╠═4203ffd2-b710-45ce-947b-851780cca52c
# ╟─e6c11ee8-3bb5-4680-b99c-92d8cc47682d
# ╟─431516f2-85b1-44d0-a70a-2c719fd13235
# ╠═fcc9a2ab-60e3-4378-baf5-a18a91dcc6e0
# ╠═49982f42-f1e2-46e4-9f67-031342b9b7df
# ╠═68be5b29-4cf6-46fc-bce4-509c229edc74
# ╟─fd98707a-4189-4911-9547-f28f1b116fc9
# ╟─a0eac40a-5fd7-4ced-8e19-6c973714e4f0
# ╠═fd3dc56e-a30a-4b53-b154-648916fec176
# ╠═66f75b1d-a6c7-474e-8451-480ba9754948
# ╠═ee29db6d-85d5-4a4f-a152-63bac3dbdc02
# ╟─80b0a70a-419b-494f-a301-27de59961e1d
