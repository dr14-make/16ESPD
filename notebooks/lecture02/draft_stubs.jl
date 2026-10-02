"""
Placeholder analyses for notebook 06, standing in for Dyad task 5 (`docs/lecture-02-dyad-tasks.md`
§ "exhaust, λ sensors, catalyst, λ control").

Delete this file when task 5 lands. The notebook's setup cell then binds
`VehicleSystemsComponents.Lecture2.LambdaLoopTransient` and `LambdaSensorRampTransient` instead,
every "PLACEHOLDER —" figure becomes the real one, and every PENDING check asserts.

Nothing here is a model of the engine, and no number it produces is a result. Each function
returns the shape of the real result (a time vector and the harness signals named in
`Lecture02Support`) from closed-form surrogates chosen only to look qualitatively right:

- the two-step loop is the exact jump/ramp waveform of an ideal relay loop with a pure delay;
- the switching sensor is the task 5 tanh characteristic with a first-order lag;
- the catalyst is a clamped (limited) integrator of the oxygen excess;
- disturbances decay along hand-picked envelopes.
"""
module DraftStubs

import ..Lecture01Support
import ..Lecture02Support
using ..Lecture02Support: rad_per_s,
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
            **PLACEHOLDER —** `$name` is not built yet (Dyad task 5,
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

function lag(u::AbstractVector, tau)
    a = exp(-DT / tau)
    y = similar(u)
    y[1] = u[1]
    for k in 2:length(u)
        y[k] = a * y[k - 1] + (1 - a) * u[k]
    end
    return y
end

delayed(y::AbstractVector, d) = (n = round(Int, d / DT); [y[max(k - n, 1)] for k in eachindex(y)])

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

end
