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
"""
function render_planar_car(result; sensors::Symbol=:sensors, car::Symbol=:car,
        framerate::Real=30, filename::Union{Nothing,AbstractString}=nothing,
        trail::Bool=true, a::Real=1.2, b::Real=1.5, track::Real=1.55,
        figure_kwargs::NamedTuple=NamedTuple())
    Base.find_package("Makie") === nothing && error("Makie is required; run `using Pkg; Pkg.add(\"Makie\")`")
    Makie = Base.require(Base.PkgId(Base.UUID("ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"), "Makie"))
    sol = hasproperty(result, :sol) ? result.sol : result
    model = DyadInterface.symbolic_container(result)
    hasproperty(model, sensors) || throw(ArgumentError("model has no `$(sensors)` PlanarCarSensors component"))
    hasproperty(model, car) || throw(ArgumentError("model has no `$(car)` PlanarCar component"))
    sens = getproperty(model, sensors)
    vehicle = getproperty(model, car)

    t = sol.t
    length(t) >= 2 || throw(ArgumentError("solution needs at least two saved times"))
    x = collect(sol[sens.x]); y = collect(sol[sens.y]); psi = collect(sol[sens.psi])
    delta_l = collect(sol[vehicle.steerL.phi]); delta_r = collect(sol[vehicle.steerR.phi])
    all(length(z) == length(t) for z in (x, y, psi, delta_l, delta_r)) ||
        throw(ArgumentError("planar-car render signals must share the solution time grid"))

    front = Float64(a)
    rear = Float64(b)
    track_width = Float64(track)
    body_length = front + rear + 1.0
    body_width = track_width + 0.35
    wheel_length = 0.65
    wheel_width = 0.20

    figure = Makie.Figure(; size=(900, 600), figure_kwargs...)
    axis = Makie.Axis(figure[1, 1]; xlabel="world x [m]", ylabel="world y [m]",
        title="Planar car", aspect=Makie.DataAspect())
    span = max(maximum(x) - minimum(x), maximum(y) - minimum(y), 10.0)
    margin = max(0.1 * span, 2.0)
    Makie.xlims!(axis, minimum(x) - margin, maximum(x) + margin)
    Makie.ylims!(axis, minimum(y) - margin, maximum(y) + margin)
    trail && Makie.lines!(axis, x, y; color=(:steelblue, 0.35), linewidth=2)

    index = Makie.Observable(1)
    rotation(p) = [cos(p) -sin(p); sin(p) cos(p)]
    rectangle(center, length, width, angle) = begin
        local_points = [[ length/2,  width/2], [ length/2, -width/2],
                        [-length/2, -width/2], [-length/2,  width/2]]
        R = rotation(angle)
        points = [center + R * p for p in local_points]
        Makie.Point2f[(p[1], p[2]) for p in points]
    end
    chassis_polygon = Makie.lift(index) do i
        rectangle([x[i], y[i]], body_length, body_width, psi[i])
    end
    Makie.poly!(axis, chassis_polygon; color=:royalblue, strokecolor=:navy, strokewidth=2)

    wheel_offsets = ((front, track_width/2, delta_l), (front, -track_width/2, delta_r),
                     (-rear, track_width/2, nothing), (-rear, -track_width/2, nothing))
    for (dx, dy, steer) in wheel_offsets
        polygon = Makie.lift(index) do i
            center = [x[i], y[i]] + rotation(psi[i]) * [Float64(dx), Float64(dy)]
            wheel_angle = psi[i] + (isnothing(steer) ? 0.0 : steer[i])
            rectangle(center, wheel_length, wheel_width, wheel_angle)
        end
        Makie.poly!(axis, polygon; color=:gray20, strokecolor=:black, strokewidth=1)
    end
    marker = Makie.lift(index) do i
        Makie.Point2f(x[i], y[i])
    end
    Makie.scatter!(axis, marker; color=:orange, markersize=10)
    time_label = Makie.lift(index) do i
        "t = $(round(t[i]; digits=2)) s"
    end
    Makie.Label(figure[2, 1], time_label)

    if isnothing(filename)
        display(figure)
        return figure
    end
    duration = t[end] - t[1]
    frame_times = range(t[1], t[end]; length=max(2, round(Int, duration * framerate) + 1))
    frame_indices = [clamp(searchsortedfirst(t, tq), 1, length(t)) for tq in frame_times]
    Makie.record(figure, filename, frame_indices; framerate=framerate) do i
        index[] = i
    end
    return filename
end

export render_planar_car
