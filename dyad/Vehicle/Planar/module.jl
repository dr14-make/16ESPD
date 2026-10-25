import DyadInterface


export fmvss126_metrics

function _linear_sample(t, x, tq)
    i = searchsortedlast(t, tq)
    i == 0 && throw(ArgumentError("sample time precedes the signal"))
    i == length(t) && return tq == t[end] ? x[end] : throw(ArgumentError("sample time follows the signal"))
    fraction = (tq - t[i]) / (t[i + 1] - t[i])
    return x[i] + fraction * (x[i + 1] - x[i])
end

"""Compute the FMVSS 126 yaw-rate and lateral-displacement metrics."""
function fmvss126_metrics(t, swa, r, y; A, f = 0.7, t0 = 1.0, T_dwell = 0.5)
    n = length(t)
    n == length(swa) == length(r) == length(y) || throw(ArgumentError("signals must have equal lengths"))
    n >= 2 || throw(ArgumentError("signals must contain at least two samples"))
    issorted(t) || throw(ArgumentError("time must be sorted"))

    bos_threshold = deg2rad(5.0)
    crossing = findfirst(i -> abs(swa[i]) >= bos_threshold, 2:n)
    isnothing(crossing) && throw(ArgumentError("steering-wheel angle never reaches 5 degrees"))
    i = crossing
    a0 = abs(swa[i - 1])
    a1 = abs(swa[i])
    t_bos = t[i - 1] + (bos_threshold - a0) * (t[i] - t[i - 1]) / (a1 - a0)

    t_cos = t0 + 1 / f + T_dwell
    peak_start = t0 + 0.5 / f
    peak_indices = findall(ti -> peak_start <= ti <= t_cos, t)
    isempty(peak_indices) && throw(ArgumentError("no yaw-rate samples in the peak window"))
    peak_index = peak_indices[argmax(abs.(r[peak_indices]))]
    r_peak = r[peak_index]
    iszero(r_peak) && throw(ArgumentError("yaw-rate peak is zero"))

    yrr_1_00 = _linear_sample(t, r, t_cos + 1.0) / r_peak
    yrr_1_75 = _linear_sample(t, r, t_cos + 1.75) / r_peak
    y_bos_1_07 = _linear_sample(t, y, t_bos + 1.07)
    passes_stability = abs(yrr_1_00) <= 0.35 && abs(yrr_1_75) <= 0.20
    responsiveness_required = maximum(abs, swa) >= 5 * A
    passes_responsiveness = !responsiveness_required || y_bos_1_07 >= 1.83

    return (; t_bos, t_cos, r_peak, yrr_1_00, yrr_1_75, y_bos_1_07,
            passes_stability, passes_responsiveness)
end


"""
    render_planar_car(result; sensors=:sensors, car=:car, framerate=30,
                      filename=nothing, trail=true, figure_kwargs=NamedTuple())

Create a Makie top-view animation for an analysis containing `PlanarCar` and
`PlanarCarSensors`. The active Makie backend controls notebook display and recording.
Returns the `Figure` when `filename` is omitted, otherwise records the animation and
returns the filename.

The method lives in the package's Makie extension: load a backend first, for example
`using CairoMakie` or `using GLMakie`.
"""
function render_planar_car end

function __init__()
    Base.Experimental.register_error_hint(MethodError) do io, exc, _, _
        exc.f === render_planar_car &&
            print(io, "\n`render_planar_car` needs Makie: run `using CairoMakie` (or another Makie backend) first.")
    end
end

export render_planar_car
