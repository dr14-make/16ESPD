"Open a SocketCAN sender supplied by the optional CANBus extension."
function can_open(interface::String)
    pkg = Base.PkgId(Base.UUID("bffc1db9-6142-4b2c-b5cf-b017e7edc3de"), "CANBus")
    Base.locate_package(pkg) === nothing && error("CAN streaming requires CANBus from the sim/ environment: run `mise run drive:setup` and put sim/ on LOAD_PATH, or use sim/can_stream.jl")
    Base.require(pkg)
    return Base.invokelatest(can_open_loaded, interface)
end
function can_open_loaded end
function can_send end
can_close(transport) = close(transport)

mutable struct CanStream
    layout::Any
    transport::Any
    paced::Bool
    wall_start::Float64
    sent::Int
    late::Int
    max_lateness::Float64
    ticks::Vector{Int}
    getters::Any
end
CanStream(layout, transport; paced = true) = CanStream(layout, transport, paced, NaN, 0, 0, 0.0,
    ones(Int, length(layout.frames)), nothing)

function can_step!(integ, dt, sys)
    stream = get(task_local_storage(), :vehicle_can_stream, nothing)
    stream === nothing && return step!(integ, dt, true)
    frames, ticks = stream.layout.frames, stream.ticks
    if stream.getters === nothing || integ.t == 0
        stream.getters = [ModelingToolkit.getu(sys,
            [foldl(getproperty, s.wire_path; init = sys) for s in f.signals]) for f in frames]
        fill!(ticks, 1)
        stream.wall_start = NaN
    end
    target = integ.t + dt
    while integ.t < target - 1e-10
        next = minimum((ticks[i] * f.period for (i, f) in enumerate(frames)); init = Inf)
        stop = min(next, target)
        step!(integ, stop - integ.t, true)
        stepping(integ) || return nothing
        isnan(stream.wall_start) && (stream.wall_start = time() - integ.t)
        if stream.paced
            sleep(max(0.0, stream.wall_start + integ.t - time()))
        end
        lateness = max(0.0, time() - stream.wall_start - integ.t)
        stream.max_lateness = max(stream.max_lateness, lateness)
        for (i, f) in enumerate(frames)
            if ticks[i] * f.period <= integ.t + 1e-10
                Base.invokelatest(can_send, stream.transport, f.id,
                    Vehicle.Planar.can_encode(f, stream.getters[i](integ)))
                stream.sent += 1
                stream.late += stream.paced && lateness > 0.002
                ticks[i] += 1
            end
        end
    end
    return nothing
end
