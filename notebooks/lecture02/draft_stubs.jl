"""
Placeholder analyses for the lecture 2 notebooks, standing in for the Dyad tasks of
`docs/lecture-02-dyad-tasks.md` until they land:

| Stub | Task | Notebook |
|---|---|---|
| `EngineDynoTransient` | 2 | 03 |
| `TipInTestTransient` | 3 | 04 |
| `InjectorPulseTransient` | 4 | 05 |
| `LambdaLoopTransient`, `LambdaSensorRampTransient` | 5 | 06 |

Delete a stub when its task lands, and this file when the last one has. Each notebook's setup
cell binds the real `VehicleSystemsComponents.Lecture2` analyses for whatever this file does not
define, every "PLACEHOLDER —" figure becomes the real one, and every PENDING check asserts.

Nothing here is a model of the engine, and no number it produces is a result. Each function
returns the shape of the real result (a time vector and the harness signals named in
`Lecture02Support`) from closed-form surrogates chosen only to look qualitatively right:

- the two-step loop is the exact jump/ramp waveform of an ideal relay loop with a pure delay;
- the switching sensor is the task 5 tanh characteristic with a first-order lag;
- the catalyst is a clamped (limited) integrator of the oxygen excess;
- disturbances decay along hand-picked envelopes;
- the engine is the task 1–2 steady-state equations with a first-order manifold and a pure
  induction delay between operating points;
- the fuel film is the x–τ filter, the injector a pickup threshold on an RL current rise.
"""
module DraftStubs

import ..Lecture01Support
import ..Lecture02Support
using ..Lecture02Support: rad_per_s, ENGINE, afr_map_slide44, bilinear,
    OMEGA, P_M, MDOT_THR, MDOT_CYL, TAU_E, ETA_B, MDOT_FUEL, U_THR,
    T_INJ, MDOT_F_CMD, LAMBDA_TGT, M_FILM,
    ACTIVATION, I_COIL, LIFT, MDOT_INJ, FUEL_MASS, V_SWITCH,
    LAMBDA_CYL, LAMBDA_TRIM, F_I, V_UP, LAMBDA_IN, LAMBDA_OUT, THETA_CAT, V_DOWN, TRIM_SHIFT,
    LAMBDA_MEAS, LOOP_DELAY,
    RAMP_LAMBDA, RAMP_V_SWITCHING, RAMP_I_PUMP, RAMP_LAMBDA_MEAS
using Markdown

struct PlaceholderRun
    analysis::String
    knobs::NamedTuple
    t::Vector{Float64}
    signals::Dict{String, Vector{Float64}}
end

Lecture02Support.is_placeholder(::PlaceholderRun) = true

function Lecture01Support.signal(run::PlaceholderRun, path::Union{AbstractString, Symbol})
    key = String(path)
    haskey(run.signals, key) || throw(ArgumentError(
        "placeholder `$(run.analysis)` has no signal `$key`; it provides " *
        join(sort!(collect(keys(run.signals))), ", ")))
    return (copy(run.t), copy(run.signals[key]))
end

"""
    show_dyad(name)

The real `show_dyad` when `name` exists under `dyad/`, otherwise a placeholder note.
"""
function show_dyad(name::AbstractString)
    try
        return Lecture01Support.show_dyad(name)
    catch err
        err isa ArgumentError || rethrow()
        return Markdown.parse("""
            **PLACEHOLDER —** `$name` is not built yet (see its task in
            `docs/lecture-02-dyad-tasks.md`). This cell will show its Dyad source.
            """)
    end
end

# Surrogate constants. Sensor and controller values repeat the task 5 defaults; the rest are
# picked for shape only.
const DT = 1e-3
const V_RICH, V_LEAN, W_SWITCH, TAU_S = 0.9, 0.1, 0.005, 0.07
const PHI_IND, PHI_EXH, THETA_0 = pi, 3pi, 0.03
const OMEGA_MIN = 10.0
const O2_FRACTION = 0.23
const C_O2 = 0.5e-3
const ALPHA = 1.0
const BETA_EQ = 0.004
const K_TRIM = 0.02
const V_REF_DOWN = 0.5
const PURGE_FRACTION = 0.08
const TAU_WB = 0.1

# Bosch LSU 4.9 datasheet, pump current [mA] against λ (teaching materials §4).
const LSU49_LAMBDA = [0.65, 0.75, 0.80, 0.85, 0.90, 0.95, 0.99, 1.003, 1.05, 1.10, 1.179,
    1.429, 1.701, 1.99, 2.434, 3.413, 5.391, 10.119]
const LSU49_IP = [-2.000, -1.243, -0.927, -0.652, -0.405, -0.183, -0.040, 0.0, 0.097, 0.193,
    0.329, 0.671, 0.938, 1.150, 1.385, 1.700, 2.000, 2.250]

function interp(xs, ys, x)
    j = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    return ys[j] + (x - xs[j]) / (xs[j + 1] - xs[j]) * (ys[j + 1] - ys[j])
end

switching_voltage(lambda; bias = 0.0) =
    V_LEAN + (V_RICH - V_LEAN) / 2 * (1 + tanh((1 + bias - lambda) / W_SWITCH))

function lag(u::AbstractVector, tau; dt = DT)
    a = exp(-dt / tau)
    y = similar(u)
    y[1] = u[1]
    for k in 2:length(u)
        y[k] = a * y[k - 1] + (1 - a) * u[k]
    end
    return y
end

delayed(y::AbstractVector, d; dt = DT) = (n = round(Int, d / dt); [y[max(k - n, 1)] for k in eachindex(y)])

air_flow(omega, u_thr) = 2.1e-3 * (omega / rad_per_s(800)) * (1 + 4u_thr)

"""
Jump/ramp waveform of an ideal relay loop with pure delay `theta`: sensor sign `s`, ramp state
`F`, and the controller output. `k_shift` enlarges the jump toward rich.
"""
function jump_ramp(t, theta, k_jump, k_ramp, k_shift)
    A = k_ramp * theta / 2 <= k_jump ? k_ramp * theta / 2 : k_ramp * theta - k_jump
    H = 2A / k_ramp
    s = [mod(ti, 2H) < H ? -1.0 : 1.0 for ti in t]
    F = [mod(ti, 2H) < H ? -A + k_ramp * mod(ti, 2H) : A - k_ramp * (mod(ti, 2H) - H) for ti in t]
    trim = @. 1 + F - k_jump * s + k_shift * (s < 0)
    return s, F, trim
end

"""
    LambdaLoopTransient(; omega_set, u_thr, k_jump, k_ramp, k_jump_shift, lambda_bias,
        with_wideband, with_trim, t_purge, stop)

Placeholder for `Lecture2.LambdaLoopTransient`. Keywords and defaults are the ones notebook 06's
model contract requests.
"""
function LambdaLoopTransient(; omega_set = rad_per_s(800), u_thr = 0.0, k_jump = 0.03,
        k_ramp = 0.05, k_jump_shift = 0.0, lambda_bias = 0.0, with_wideband = false,
        with_trim = false, t_purge = 1e3, stop = 10.0)
    t = collect(0.0:DT:stop)
    n = length(t)
    w = max(omega_set, OMEGA_MIN)
    theta_ind = PHI_IND / w
    theta_exh = PHI_EXH / w + THETA_0
    theta = theta_ind + theta_exh
    theta_eff = theta + TAU_S
    mdot_air = air_flow(omega_set, u_thr)

    purge = [ti >= t_purge ? PURGE_FRACTION : 0.0 for ti in t]
    # Purge fuel the loop has not yet removed.
    excess = map(t) do ti
        tau = ti - t_purge - theta_eff
        ti < t_purge ? 0.0 :
        tau < 0 ? PURGE_FRACTION :
        with_wideband ? PURGE_FRACTION * exp(-tau / (2theta_eff)) * cos(pi * tau / (4theta_eff)) :
        max(0.0, PURGE_FRACTION - k_jump - k_ramp * tau)
    end
    if with_wideband
        s, F, cycle = zeros(n), zeros(n), ones(n)
    else
        s, F, cycle = jump_ramp(t, theta_eff, k_jump, k_ramp, k_jump_shift)
    end
    fuel_factor = delayed(cycle .* (1 .+ excess), theta_ind)

    lam_cyl, lam_in, lam_out = zeros(n), zeros(n), zeros(n)
    theta_c, v_down, shift = zeros(n), zeros(n), zeros(n)
    th, sh, vd = 0.5, 0.0, switching_voltage(1.0)
    n_exh = round(Int, theta_exh / DT)
    a_s = exp(-DT / TAU_S)
    for k in 1:n
        lam_cyl[k] = (1 + lambda_bias - sh) / fuel_factor[k]
        lam_in[k] = lam_cyl[max(k - n_exh, 1)]
        o2 = O2_FRACTION * mdot_air * (lam_in[k] - 1) / lam_in[k]
        leak = o2 > 0 ? th^8 : (1 - th)^8
        lam_out[k] = 1 + (lam_in[k] - 1) * leak + BETA_EQ * (th - 0.5)
        vd = a_s * vd + (1 - a_s) * switching_voltage(lam_out[k])
        theta_c[k], v_down[k], shift[k] = th, vd, sh
        rate = ALPHA * (o2 > 0 ? 1 - th^8 : 1 - (1 - th)^8)
        th = clamp(th + DT * rate * o2 / C_O2, 0.0, 1.0)
        with_trim && (sh += DT * K_TRIM * (V_REF_DOWN - vd))
    end

    signals = Dict(
        LAMBDA_CYL => lam_cyl,
        LAMBDA_TRIM => cycle .* (1 .+ excess) ./ (1 .+ purge),
        V_UP => lag(switching_voltage.(lam_in; bias = lambda_bias), TAU_S),
        LAMBDA_IN => lam_in,
        LAMBDA_OUT => lam_out,
        THETA_CAT => theta_c,
        V_DOWN => v_down,
        TRIM_SHIFT => shift,
        LOOP_DELAY => fill(theta, n),
    )
    if with_wideband
        signals[LAMBDA_MEAS] = lag(lam_in, TAU_WB)
    else
        signals[F_I] = F
    end
    knobs = (; omega_set, u_thr, k_jump, k_ramp, k_jump_shift, lambda_bias, with_wideband,
        with_trim, t_purge, stop)
    return PlaceholderRun("LambdaLoopTransient", knobs, t, signals)
end

"""
    LambdaSensorRampTransient(; lambda_start, lambda_stop, stop)

Placeholder for `Lecture2.LambdaSensorRampTransient`: λ ramped slowly through both sensor
models.
"""
function LambdaSensorRampTransient(; lambda_start = 0.9, lambda_stop = 1.1, stop = 20.0)
    t = collect(0.0:DT:stop)
    lambda = @. lambda_start + (lambda_stop - lambda_start) * t / stop
    i_p = [interp(LSU49_LAMBDA, LSU49_IP, l) for l in lambda]
    lambda_meas = lag([interp(LSU49_IP, LSU49_LAMBDA, i) for i in i_p], TAU_WB)
    signals = Dict(
        RAMP_LAMBDA => lambda,
        RAMP_V_SWITCHING => lag(switching_voltage.(lambda), TAU_S),
        RAMP_I_PUMP => i_p,
        RAMP_LAMBDA_MEAS => lambda_meas,
    )
    return PlaceholderRun("LambdaSensorRampTransient", (; lambda_start, lambda_stop, stop), t, signals)
end


# ---------------------------------------------------------------------------------------
# Engine (task 2): EngineDynoTransient
# ---------------------------------------------------------------------------------------

const GAMMA, C_D, D_THR, A_IDLE, ALPHA_0 = 1.4, 0.8, 0.05, 13e-6, deg2rad(7)
const ETA_I, K_F, P_EXH = 0.40, 0.6, 1.05 * 101_325.0

throttle_area(u) = A_IDLE + pi * D_THR^2 / 4 *
    (1 - cos(ALPHA_0 + clamp(u, 0, 1) * (pi / 2 - ALPHA_0)) / cos(ALPHA_0))

function flow_function(Pi)
    psi(x) = sqrt(2GAMMA / (GAMMA - 1) * (x^(2 / GAMMA) - x^((GAMMA + 1) / GAMMA)))
    Pi_cr = (2 / (GAMMA + 1))^(GAMMA / (GAMMA - 1))
    Pi <= 0.95 && return psi(max(Pi, Pi_cr))
    return psi(0.95) * (1 - Pi) / 0.05
end

mdot_throttle(u, p) = C_D * throttle_area(u) * ENGINE.p_a / sqrt(ENGINE.R * ENGINE.T_m) *
    flow_function(p / ENGINE.p_a)
eta_v(n, p) = (0.55 + 0.35 * clamp(p / ENGINE.p_a, 0, 1)) * (1 - 0.12 * ((n - 3500) / 3000)^2)
mdot_cylinder(w, p) = eta_v(w * 30 / pi, p) * ENGINE.V_d * w / (4pi) * p / (ENGINE.R * ENGINE.T_m)

function steady_pm(w, u)
    lo, hi = 1e3, ENGINE.p_a
    for _ in 1:60
        mid = (lo + hi) / 2
        mdot_throttle(u, mid) > mdot_cylinder(w, mid) ? (lo = mid) : (hi = mid)
    end
    return (lo + hi) / 2
end

"Local manifold time constant: storage over the net outflow's pressure sensitivity."
function manifold_tau(w, u, p)
    h = 1.0
    d = (mdot_cylinder(w, p + h) - mdot_cylinder(w, p - h) -
         mdot_throttle(u, p + h) + mdot_throttle(u, p - h)) / 2h
    return ENGINE.V_m / (ENGINE.R * ENGINE.T_m) / d
end

function brake_torque(w, p, mdot_air)
    fuel = mdot_air / ENGINE.AFR_s
    n = w * 30 / pi
    fmep = K_F * (0.97e5 + 0.15e5 * (n / 1000) + 0.05e5 * (n / 1000)^2)
    return ETA_I * ENGINE.H_l * fuel / w - ENGINE.V_d / (4pi) * (fmep + P_EXH - p)
end

"""
    EngineDynoTransient(; omega_set, u_thr, du_thr, t_step, sigma, stop)

Placeholder for `Lecture2.EngineDynoTransient`: the engine held at `omega_set` with the throttle
at `u_thr`, stepped by `du_thr` at `t_step`.
"""
function EngineDynoTransient(; omega_set = rad_per_s(800), u_thr = 0.0, du_thr = 0.0,
        t_step = 0.5, sigma = nothing, stop = 2.0, dt = 2e-4)
    t = collect(0.0:dt:stop)
    w = omega_set
    u1 = clamp(u_thr + du_thr, 0, 1)
    p0, p1 = steady_pm(w, u_thr), steady_pm(w, u1)
    tau = manifold_tau(w, u1, p1)
    p = [ti < t_step ? p0 : p1 + (p0 - p1) * exp(-(ti - t_step) / tau) for ti in t]
    u = [ti < t_step ? u_thr : u1 for ti in t]
    mcyl = mdot_cylinder.(w, p)
    mthr = [mdot_throttle(ui, pi_) for (ui, pi_) in zip(u, p)]
    mcyl_late = delayed(mcyl, pi / w; dt)
    torque = brake_torque.(w, p, mcyl_late)
    fuel = mcyl_late ./ ENGINE.AFR_s
    signals = Dict(
        OMEGA => fill(w, length(t)), P_M => p, MDOT_THR => mthr, MDOT_CYL => mcyl,
        TAU_E => torque, MDOT_FUEL => fuel, U_THR => u, LAMBDA_CYL => ones(length(t)),
        ETA_B => torque .* w ./ (ENGINE.H_l .* fuel),
    )
    return PlaceholderRun("EngineDynoTransient",
        (; omega_set, u_thr, du_thr, t_step, sigma, stop), t, signals)
end

# ---------------------------------------------------------------------------------------
# Fuel path (task 3): TipInTestTransient
# ---------------------------------------------------------------------------------------

const EV14_DEAD = ([8.0, 12.0, 14.0, 16.0], [2.0e-3, 0.903e-3, 0.80e-3, 0.558e-3])
const Q_INJ = ENGINE.q_static * 1e-6 / 60 * ENGINE.rho_f

film_X(T) = 0.5 + (0.3 - 0.5) * clamp((T - 20) / 70, 0, 1)
film_tau(T) = 0.6 + (0.2 - 0.6) * clamp((T - 20) / 70, 0, 1)
warmup_factor(T) = 1.3 + (1.0 - 1.3) * clamp((T - 20) / 60, 0, 1)

"Film model `x, τ`: fuel reaching the cylinder for the injected flow `u` (exact discretization)."
function film(u, X, tau, dt)
    a = exp(-dt / tau)
    m = X * tau * u[1]
    out = similar(u)
    for k in eachindex(u)
        out[k] = (1 - X) * u[k] + m / tau
        m = a * m + (1 - a) * X * tau * u[k]
    end
    return out
end

"Inverse film compensation with estimates `Xh, tauh`: the command that cancels the estimated film."
function compensate(des, Xh, tauh, dt)
    a = exp(-dt / tauh)
    m = Xh * tauh * des[1]
    cmd = similar(des)
    for k in eachindex(des)
        cmd[k] = max(0.0, (des[k] - m / tauh) / (1 - Xh))
        m = a * m + (1 - a) * Xh * tauh * cmd[k]
    end
    return cmd
end

"""
    TipInTestTransient(; omega_set, u_thr, u_tip, t_tip_in, t_tip_out, T_cool, with_air_model,
        with_comp, Xh, tauh, U_batt, stop)

Placeholder for `Lecture2.TipInTestTransient`: the engine held at `omega_set`, fuel from
`FuelMetering` reading the air-mass sensor (the throttle air flow), optionally through a
manifold model that estimates the cylinder air, throttle `u_thr` stepped to `u_tip` and back.
"""
function TipInTestTransient(; omega_set = rad_per_s(2000), u_thr = 0.05, u_tip = 0.15,
        t_tip_in = 1.0, t_tip_out = 3.0, T_cool = 90.0, with_air_model = false, with_comp = false,
        Xh = 0.3, tauh = 0.2,
        U_batt = 14.0, stop = 5.0, dt = 1e-3)
    t = collect(0.0:dt:stop)
    w = omega_set
    n = w * 30 / pi
    # The throttle plate follows its command with a 50 ms lag, as an electronic throttle does.
    u = lag([t_tip_in <= ti < t_tip_out ? u_tip : u_thr for ti in t], 0.05; dt)
    p = similar(t)
    p[1] = steady_pm(w, u[1])
    for k in 2:length(t)
        target = steady_pm(w, u[k])
        p[k] = target + (p[k - 1] - target) * exp(-dt / manifold_tau(w, u[k], target))
    end
    mcyl = mdot_cylinder.(w, p)
    mthr = [mdot_throttle(ui, pk) for (ui, pk) in zip(u, p)]
    afr = afr_map_slide44()
    lambda_tgt = [bilinear(afr.rpm, afr.load, afr.afr, n, 100 * pk / ENGINE.p_a) / ENGINE.AFR_s for pk in p]
    F = warmup_factor(T_cool)
    # An exact manifold model recovers the cylinder air from the sensor reading.
    air = with_air_model ? mcyl : mthr
    des = air ./ (ENGINE.AFR_s .* lambda_tgt) .* F
    cmd = with_comp ? compensate(des, Xh, tauh, dt) : des
    fuel_cyl = film(cmd, film_X(T_cool), film_tau(T_cool), dt)
    t_dead = interp(EV14_DEAD[1], EV14_DEAD[2], U_batt)
    t_inj = cmd .* (4pi / (w * ENGINE.n_cyl)) ./ Q_INJ .+ t_dead
    signals = Dict(
        OMEGA => fill(w, length(t)), P_M => p, MDOT_CYL => mcyl, MDOT_THR => mthr, U_THR => u,
        LAMBDA_CYL => mcyl ./ (ENGINE.AFR_s .* fuel_cyl),
        LAMBDA_TGT => lambda_tgt,
        MDOT_F_CMD => cmd, T_INJ => t_inj,
        M_FILM => film_X(T_cool) * film_tau(T_cool) .* cmd,
    )
    return PlaceholderRun("TipInTestTransient",
        (; omega_set, u_thr, u_tip, t_tip_in, t_tip_out, T_cool, with_air_model, with_comp, Xh, tauh,
            U_batt, stop),
        t, signals)
end

# ---------------------------------------------------------------------------------------
# Injector (task 4): InjectorPulseTransient
# ---------------------------------------------------------------------------------------

const R_COIL, TAU_OPEN, TAU_CLOSED = 12.0, 1.0e-3, 1.6e-3
const I_PICK, I_DROP, T_MOVE = 0.5, 0.25, 0.25e-3
const LIFT_MAX, R_OFF = 0.05e-3, 55.0

"""
    InjectorPulseTransient(; U_batt, t_pulse, t_start, stop)

Placeholder for `Lecture2.InjectorPulseTransient`: one injection pulse of length `t_pulse` from
battery voltage `U_batt` through the low-side switch.
"""
function InjectorPulseTransient(; U_batt = 14.0, t_pulse = 3e-3, t_start = 0.5e-3,
        stop = t_start + t_pulse + 3e-3, dt = 2e-6)
    t = collect(0.0:dt:stop)
    t_end = t_start + t_pulse
    i_inf = U_batt / R_COIL
    # Pickup: the time the current needs to reach the force balance, then the needle's travel.
    t_pick = I_PICK < i_inf ? -TAU_OPEN * log(1 - I_PICK / i_inf) : Inf
    t_open = t_start + t_pick
    smooth(x) = x <= 0 ? 0.0 : x >= 1 ? 1.0 : x^2 * (3 - 2x)
    i = map(t) do ti
        ti < t_start && return 0.0
        if ti < t_end
            tt = ti - t_start
            i_rise = i_inf * (1 - exp(-tt / TAU_OPEN))
            # The moving armature raises the inductance; back-EMF dents the current (the kink).
            dent = 0.12 * i_inf * sin(pi * smooth((ti - t_open) / T_MOVE)) * (ti > t_open)
            late = ti > t_open + T_MOVE ?
                i_inf - (i_inf - i_inf * (1 - exp(-(t_open + T_MOVE - t_start) / TAU_OPEN))) *
                exp(-(ti - t_open - T_MOVE) / TAU_CLOSED) : i_rise
            return (ti > t_open + T_MOVE ? late : i_rise) - dent
        end
        return 0.0
    end
    i_end = i[searchsortedlast(t, t_end) - 1]
    tau_off = TAU_CLOSED * R_COIL / (R_COIL + R_OFF)
    for k in eachindex(t)
        t[k] >= t_end && (i[k] = i_end * exp(-(t[k] - t_end) / tau_off))
    end
    t_drop = t_end + tau_off * log(max(i_end / I_DROP, 1.0))
    lift = map(t) do ti
        opened = LIFT_MAX * smooth((ti - t_open) / T_MOVE)
        ti < t_drop ? opened : opened * (1 - smooth((ti - t_drop) / T_MOVE))
    end
    mdot = Q_INJ .* lift ./ LIFT_MAX
    fuel = cumsum(mdot) .* dt
    v_switch = [t[k] < t_start ? U_batt : t[k] < t_end ? 0.1 * i[k] : U_batt + R_OFF * i[k]
                for k in eachindex(t)]
    signals = Dict(
        ACTIVATION => [t_start <= ti < t_end ? 1.0 : 0.0 for ti in t],
        I_COIL => i, LIFT => lift, MDOT_INJ => mdot, FUEL_MASS => fuel, V_SWITCH => v_switch,
    )
    return PlaceholderRun("InjectorPulseTransient", (; U_batt, t_pulse, t_start, stop), t, signals)
end

end
