"""
Signal names, readouts and figure helpers for the lecture 2 notebooks.

Include after `notebooks/lecture01/support.jl`:

    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    include(joinpath(@__DIR__, "support.jl"))
    using .Lecture01Support, .Lecture02Support

Like `Lecture01Support`, this module holds no pedagogy: equations and reasoning stay in the
notebook cells.
"""
module Lecture02Support

import ..Lecture01Support
using Markdown
using PlutoUI: LocalResource, ExperimentalLayout

export ENGINE, rpm, rad_per_s, kpa,
    limit_cycle, cycle_mean, first_time, crossing, step_response, linear_fit,
    operating_grid, regrid, afr_map_slide44, bilinear,
    deck_figure, compare, captioned,
    bind_analysis, is_placeholder, figure_title, placeholder_note, check, measured,
    LAMBDA_CYL, LAMBDA_TRIM, F_I, V_UP, LAMBDA_IN, LAMBDA_OUT, THETA_CAT, V_DOWN, TRIM_SHIFT,
    LAMBDA_MEAS, LOOP_DELAY,
    RAMP_LAMBDA, RAMP_V_SWITCHING, RAMP_I_PUMP, RAMP_LAMBDA_MEAS,
    OMEGA, P_M, MDOT_THR, MDOT_CYL, TAU_E, ETA_B, MDOT_FUEL, U_THR,
    T_INJ, MDOT_F_CMD, LAMBDA_TGT, M_FILM,
    ACTIVATION, I_COIL, LIFT, MDOT_INJ, FUEL_MASS, V_SWITCH

# ---------------------------------------------------------------------------------------
# Engine constants
# ---------------------------------------------------------------------------------------

"""
    ENGINE

The shared engine constants of `docs/lecture-02-dyad-tasks.md` § "Engine constants", for the
annotations and hand formulas a notebook draws next to a simulated curve. The models carry their
own copies; these never feed a simulation.

| Field | Meaning | Unit |
|---|---|---|
| `V_d` | displacement | m³ |
| `V_m` | intake manifold volume | m³ |
| `n_cyl` | cylinders | – |
| `R` | gas constant of air | J/(kg·K) |
| `T_m` | intake air temperature | K |
| `p_a` | ambient pressure | Pa |
| `AFR_s` | stoichiometric air-fuel ratio | – |
| `H_l` | lower heating value of gasoline | J/kg |
| `rho_f` | gasoline density | kg/m³ |
| `q_static` | injector static flow at 3 bar (Bosch EV14) | cm³/min |
"""
const ENGINE = (
    V_d = 1.5e-3,
    V_m = 1.0e-3,
    n_cyl = 4,
    R = 287.05,
    T_m = 298.15,
    p_a = 101_325.0,
    AFR_s = 14.7,
    H_l = 43.4e6,
    rho_f = 740.0,
    q_static = 146.0,
)

# ---------------------------------------------------------------------------------------
# Signal names
#
# Paths into the `Lecture2` harnesses, as the notebooks' model contracts request them. A
# mismatch with a built harness surfaces as `signal`'s "no signal" error listing what the
# harness does provide.
# ---------------------------------------------------------------------------------------

# `EngineDyno`, `TipInTest` and `LambdaLoop` all name their `MeanValueEngine` `engine`.
"Engine speed [rad/s]."
const OMEGA = "engine.omega"
"Intake manifold pressure [Pa]."
const P_M = "engine.p_m"
"Air mass flow through the throttle [kg/s], what an air-mass sensor sees."
const MDOT_THR = "engine.mdot_thr"
"Air mass flow into the cylinders [kg/s]."
const MDOT_CYL = "engine.mdot_cyl"
"Brake torque [N·m]."
const TAU_E = "engine.tau_e"
"Brake efficiency [–]."
const ETA_B = "engine.eta_b"
"Fuel mass flow the dyno's open-loop metering injects [kg/s]."
const MDOT_FUEL = "fuel.y"
"Throttle command [–], 0 closed to 1 wide open."
const U_THR = "throttle.y"

"Injection pulse width [s]."
const T_INJ = "metering.t_inj"
"Commanded fuel mass flow [kg/s]."
const MDOT_F_CMD = "metering.mdot_f_cmd"
"λ target read from the slide 44 map."
const LAMBDA_TGT = "metering.lambda_tgt"
"Fuel mass held in the port-wall film [kg]."
const M_FILM = "engine.film.m_film"

"Injector driver command [–], 1 while the switch conducts."
const ACTIVATION = "pulse.y"
"Injector coil current [A]."
const I_COIL = "injector.solenoid.i"
"Needle lift [m]."
const LIFT = "injector.lift"
"Fuel mass flow through the injector [kg/s]."
const MDOT_INJ = "injector.mdot_f"
"Fuel mass injected since the start of the run [kg]."
const FUEL_MASS = "fuel_mass.y"
"Voltage across the driver's low-side switch [V]."
const V_SWITCH = "switch.v"

# `LambdaLoop` and `LambdaSensorRamp` (notebook 06).

"λ in the cylinder, after the wall film and the induction delay."
const LAMBDA_CYL = "engine.lambda_cyl"
"The controller's fuel multiplier, the slide 57 manipulated variable."
const LAMBDA_TRIM = "controller.lambda_trim"
"The two-step controller's integral (ramp) state."
const F_I = "controller.F_I"
"Upstream switching sensor voltage [V]."
const V_UP = "sensor_up.V"
"λ entering the catalyst, at the upstream sensor location."
const LAMBDA_IN = "catalyst.lambda_in"
"λ leaving the catalyst."
const LAMBDA_OUT = "catalyst.lambda_out"
"Catalyst oxygen-storage fraction θ ∈ [0, 1]."
const THETA_CAT = "catalyst.theta"
"Downstream switching sensor voltage [V]."
const V_DOWN = "sensor_down.V"
"Post-cat trim output: the shift it applies to the two-step loop."
const TRIM_SHIFT = "post_cat.shift"
"The ECU's λ estimate from the wideband sensor."
const LAMBDA_MEAS = "sensor_wb.lambda_meas"
"Injection-to-upstream-sensor transport delay [s], induction plus exhaust."
const LOOP_DELAY = "loop_delay"

"λ imposed by the sensor-ramp harness."
const RAMP_LAMBDA = "lambda_src.y"
"Switching sensor voltage in the sensor-ramp harness [V]."
const RAMP_V_SWITCHING = "switching.V"
"Wideband pump current in the sensor-ramp harness [mA]."
const RAMP_I_PUMP = "wideband.I_p"
"Wideband λ estimate in the sensor-ramp harness."
const RAMP_LAMBDA_MEAS = "wideband.lambda_meas"

# ---------------------------------------------------------------------------------------
# Units, for plotting and slider conversion only
# ---------------------------------------------------------------------------------------

rpm(omega) = omega * 30 / pi
rad_per_s(n) = n * pi / 30
kpa(p) = p / 1000

# ---------------------------------------------------------------------------------------
# Readouts
# ---------------------------------------------------------------------------------------

"""
    limit_cycle(t, y; settle = 0.5) -> (; period, frequency, amplitude, mean)

Period and half peak-to-peak amplitude of a settled oscillation.

Only the part of the run after `settle` (a fraction of the time span) is used, so a start-up
transient does not count. The period is the mean spacing of upward crossings of the mean,
interpolated linearly between samples. `period` is `NaN` when fewer than two crossings exist.
"""
function limit_cycle(t::AbstractVector, y::AbstractVector; settle = 0.5)
    t0 = first(t) + settle * (last(t) - first(t))
    i0 = searchsortedfirst(t, t0)
    ts, ys = t[i0:end], y[i0:end]
    m = sum(ys) / length(ys)
    ups = Float64[]
    for i in 2:length(ys)
        if ys[i - 1] < m <= ys[i]
            push!(ups, ts[i - 1] + (m - ys[i - 1]) / (ys[i] - ys[i - 1]) * (ts[i] - ts[i - 1]))
        end
    end
    period = length(ups) < 2 ? NaN : (last(ups) - first(ups)) / (length(ups) - 1)
    return (; period, frequency = 1 / period, amplitude = (maximum(ys) - minimum(ys)) / 2, mean = m)
end

"""
    cycle_mean(t, y, window) -> Vector

Moving mean of `y` over the trailing `window` seconds, sampled at `t`.

Averaging over one limit-cycle period removes the oscillation and leaves the slow drift that a
disturbance or a shift causes. Trapezoidal, so a solver's uneven time steps are weighted
correctly.
"""
function cycle_mean(t::AbstractVector, y::AbstractVector, window::Real)
    area = zeros(length(t))
    for i in 2:length(t)
        area[i] = area[i - 1] + (y[i] + y[i - 1]) / 2 * (t[i] - t[i - 1])
    end
    interp(tq) = begin
        j = clamp(searchsortedlast(t, tq), 1, length(t) - 1)
        s = (tq - t[j]) / (t[j + 1] - t[j])
        area[j] + s * (area[j + 1] - area[j])
    end
    return map(eachindex(t)) do i
        ta = max(first(t), t[i] - window)
        t[i] == ta ? y[i] : (area[i] - interp(ta)) / (t[i] - ta)
    end
end

"""
    first_time(t, cond) -> time or `nothing`

The first sample time at which `cond` holds and keeps holding to the end of the run.
"""
function first_time(t::AbstractVector, cond::AbstractVector{Bool})
    i = findlast(!, cond)
    isnothing(i) && return first(t)
    return i == length(t) ? nothing : t[i + 1]
end

"""
    crossing(t, y, level; after = first(t)) -> time or `nothing`

The first time strictly after `after` at which `y` crosses `level` in either direction,
interpolated linearly between samples. Strictly, so that passing a crossing's own time as `after`
finds the next one.
"""
function crossing(t::AbstractVector, y::AbstractVector, level; after = first(t) - 1)
    for i in max(2, searchsortedfirst(t, after)):length(t)
        a, b = y[i - 1] - level, y[i] - level
        (a == 0 || a * b < 0) || continue
        tc = t[i - 1] + (level - y[i - 1]) / (y[i] - y[i - 1]) * (t[i] - t[i - 1])
        tc > after && return tc
    end
    return nothing
end

"""
    step_response(t, y, t_step) -> (; t, y, tau, t50)

A step response normalized to run from 0 to 1, on time measured from `t_step`, with the time to
63.2 % (`tau`, the first-order time constant) and to 50 % (`t50`, where a delay is read). The
initial value is the last sample before the step and the final value the last sample of the run,
so the run must be long enough to settle.
"""
function step_response(t::AbstractVector, y::AbstractVector, t_step)
    i0 = max(1, searchsortedlast(t, t_step))
    y0, y1 = y[i0], last(y)
    yn = (y .- y0) ./ (y1 - y0)
    ts = t .- t_step
    tau = crossing(ts, yn, 1 - exp(-1); after = 0.0)
    t50 = crossing(ts, yn, 0.5; after = 0.0)
    return (; t = ts, y = yn, tau, t50)
end

"""
    linear_fit(x, y) -> (; slope, intercept)

Least-squares straight line through `(x, y)`.
"""
function linear_fit(x::AbstractVector, y::AbstractVector)
    mx, my = sum(x) / length(x), sum(y) / length(y)
    slope = sum((x .- mx) .* (y .- my)) / sum((x .- mx) .^ 2)
    return (; slope, intercept = my - slope * mx)
end

# ---------------------------------------------------------------------------------------
# Operating-point grids and maps
# ---------------------------------------------------------------------------------------

"""
    operating_grid(analysis, paths; speeds, throttles, kwargs...) -> (; rpm, u_thr, runs, values)

Run `analysis(; omega_set, u_thr, kwargs...)` once per engine speed (rpm) and throttle opening
and read the final value of each signal in `paths`. `values[path]` is a matrix with one row per
speed and one column per throttle opening. The analysis must start at its steady operating point
(task ground rules), so the final value of a short run is the steady state.
"""
function operating_grid(analysis, paths; speeds, throttles, kwargs...)
    runs = [analysis(; omega_set = rad_per_s(n), u_thr = u, kwargs...) for n in speeds, u in throttles]
    values = Dict(p => map(r -> last(last(Lecture01Support.signal(r, p))), runs) for p in paths)
    return (; rpm = collect(speeds), u_thr = collect(throttles), runs, values)
end

"""
    regrid(y, z, ygrid) -> Matrix

Re-sample a map from throttle columns onto a common grid of another quantity that rises with
throttle at each speed (load, torque). `y` and `z` have one row per speed; the result has one row
per speed and one column per `ygrid` value, `NaN` outside the range that speed reaches. This puts
a throttle sweep onto the speed × load layout of slide 44.
"""
function regrid(y::AbstractMatrix, z::AbstractMatrix, ygrid::AbstractVector)
    out = fill(NaN, size(y, 1), length(ygrid))
    for i in axes(y, 1)
        order = sortperm(y[i, :])
        ys, zs = y[i, order], z[i, order]
        for (j, yq) in enumerate(ygrid)
            first(ys) <= yq <= last(ys) || continue
            k = clamp(searchsortedlast(ys, yq), 1, length(ys) - 1)
            out[i, j] = zs[k] + (yq - ys[k]) / (ys[k + 1] - ys[k]) * (zs[k + 1] - zs[k])
        end
    end
    return out
end

const DATA = normpath(@__DIR__, "..", "..", "data", "engine")

"""
    afr_map_slide44() -> (; rpm, load, afr)

The slide 44 air-fuel-ratio map as transcribed in `data/engine/afr_map_slide44.csv`: engine
speed in rpm (rows), load in % (columns), AFR as a matrix with one row per speed.
"""
function afr_map_slide44()
    lines = filter(l -> !startswith(l, "#") && !isempty(strip(l)),
        readlines(joinpath(DATA, "afr_map_slide44.csv")))
    header = split(first(lines), ",")
    load = parse.(Float64, header[2:end])
    rows = [parse.(Float64, split(l, ",")) for l in lines[2:end]]
    return (; rpm = [r[1] for r in rows], load, afr = permutedims(reduce(hcat, [r[2:end] for r in rows])))
end

"""
    bilinear(xs, ys, z, x, y)

Bilinear interpolation in a table `z` with one row per `xs` and one column per `ys`, clamped at
the edges.
"""
function bilinear(xs, ys, z, x, y)
    i = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    j = clamp(searchsortedlast(ys, y), 1, length(ys) - 1)
    u = clamp((x - xs[i]) / (xs[i + 1] - xs[i]), 0, 1)
    v = clamp((y - ys[j]) / (ys[j + 1] - ys[j]), 0, 1)
    return (1 - u) * (1 - v) * z[i, j] + u * (1 - v) * z[i + 1, j] +
           (1 - u) * v * z[i, j + 1] + u * v * z[i + 1, j + 1]
end

# ---------------------------------------------------------------------------------------
# Deck figures and layout
# ---------------------------------------------------------------------------------------

const ASSETS = normpath(@__DIR__, "assets")

"""
    deck_figure(name; width = 420)

A figure copied from the lecture deck into `notebooks/lecture02/assets/`, for display.
"""
function deck_figure(name::AbstractString; width = 420)
    path = joinpath(ASSETS, name)
    isfile(path) || throw(ArgumentError("no deck figure `$name` in $ASSETS"))
    return LocalResource(path, :width => width)
end

"""
    compare(original, simulated)

Deck figure on the left, regenerated figure on the right.
"""
compare(original, simulated) = ExperimentalLayout.hbox([original, simulated];
    style = Dict("gap" => "1.5em", "align-items" => "center", "flex-wrap" => "wrap"))

"""
    captioned(content, caption)

`content` with a caption under it. `caption` is a string of Markdown.
"""
captioned(content, caption::AbstractString) =
    ExperimentalLayout.vbox([content, Markdown.parse(caption)])

# ---------------------------------------------------------------------------------------
# Placeholder handling
#
# A notebook drafted before its model exists runs on placeholder results. These helpers let
# the same cells serve both: a placeholder result marks its plots and turns its checks into
# PENDING notices, and a real analysis result passes through unchanged.
# ---------------------------------------------------------------------------------------

"""
    bind_analysis(name, library; stubs = nothing)

The analysis `name` (a `Symbol`) from the placeholder module `stubs` while it still defines one,
otherwise from `library.Lecture2`. Each analysis switches to the real one as soon as its stub is
deleted, independently of the others.
"""
function bind_analysis(name::Symbol, library; stubs = nothing)
    !isnothing(stubs) && isdefined(stubs, name) && return getfield(stubs, name)
    return getfield(getfield(library, :Lecture2), name)
end

"""
    is_placeholder(run) -> Bool

True when `run` is a placeholder result rather than a solved analysis. Placeholder types add
a method; everything else is real.
"""
is_placeholder(run) = false
is_placeholder(runs::Union{Tuple, AbstractArray}) = any(is_placeholder, runs)

"""
    figure_title(run, title)

`title`, prefixed with "PLACEHOLDER —" when `run` (or any run in a collection) is a
placeholder.
"""
figure_title(run, title::AbstractString) = is_placeholder(run) ? "PLACEHOLDER — " * title : title

"""
    placeholder_note(run, replaced_by) -> String

A caption suffix naming the analysis and signals that will replace a placeholder figure, or
the empty string for a real run.
"""
placeholder_note(run, replaced_by::AbstractString) = is_placeholder(run) ?
    "\n\n**PLACEHOLDER —** surrogate data from `draft_stubs.jl`, not a model result. " *
    "Replaced by $replaced_by." : ""

"""
    check(f, needs, runs...)

A check cell's body. `f()` returns `(passed::Bool, message)` where the message states the
measured value and the band. On placeholder data it prints "PENDING: needs <needs>" and
asserts nothing; on real data it asserts and prints "PASS: <message>".
"""
function check(f, needs::AbstractString, runs...)
    if is_placeholder(runs)
        println("PENDING: needs ", needs)
        return Markdown.parse("**PENDING:** needs $needs")
    end
    passed, message = f()
    @assert passed message
    println("PASS: ", message)
    return Markdown.parse("**PASS:** $message")
end

"""
    measured(f, run; digits = 3)

`f()` rounded for a results table, or "pending" when `run` is a placeholder, so a surrogate
number never reads as a result.
"""
measured(f, run; digits = 3) = is_placeholder(run) ? "pending" : string(round(f(); digits))

end
