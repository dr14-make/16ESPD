module VehicleSystemsComponentsMakieExt

import Makie
using DyadInterface: symbolic_container
using VehicleSystemsComponents.Vehicle: Planar

function Planar.render_planar_car(result; sensors::Symbol=:sensors, car::Symbol=:car,
        framerate::Real=30, filename::Union{Nothing,AbstractString}=nothing,
        trail::Bool=true, a::Real=1.2, b::Real=1.5, track::Real=1.55,
        figure_kwargs::NamedTuple=NamedTuple())
    sol = hasproperty(result, :sol) ? result.sol : result
    model = symbolic_container(result)
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

end # module
