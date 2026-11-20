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

const FABIA_INPUTS = (:speed, :rpm, :coolant, :left, :right, :hazard, :abs_lamp,
    :asr_lamp, :brake_lamp, :mil, :epc, :charging, :airbag_lamp, :dimming)

"A `FabiaCluster` in the model: its path, encoder state and the tick its inputs were last read."
mutable struct FabiaSource
    path::Vector{Symbol}
    state::FabiaProtocol.Bench
    getter::Any
    read_at::Float64
end

function can_stream_layout(model)
    clusters = FabiaSource[]
    blocks = Vehicle.Planar._can_tree(model)
    for b in blocks
        b.kind == :fabia || continue
        push!(clusters, FabiaSource(b.path, FabiaProtocol.Bench(), nothing, NaN))
    end
    adapters = filter(b -> b.kind == :adapter, blocks)
    frames = Any[]
    if !isempty(adapters)
        append!(frames, Vehicle.Planar.can_layout(model).frames)
    end
    isempty(clusters) && isempty(adapters) && throw(ArgumentError("CAN: model has no CanAdapter or FabiaCluster"))
    for c in clusters, (id, period, builder) in FabiaProtocol.frame_schedule
        push!(frames, (; id, period, builder, cluster = c, signals = []))
    end
    ids = [f.id for f in frames]
    length(unique(ids)) == length(ids) || throw(ArgumentError("CAN: overlapping frame ids on one interface"))
    return (; frames, clusters)
end

function fabia_values!(state, v)
    state.kmh = max(0.0, v[1] * 3.6)
    state.rpm = v[2]
    state.coolant = v[3]
    state.left = v[4] > 0.5
    state.right = v[5] > 0.5
    state.hazard = v[6] > 0.5
    state.abs_lamp = v[7] > 0.5
    state.asr_lamp = v[8] > 0.5
    state.brake_lamp = v[9] > 0.5
    state.mil = v[10] > 0.5
    state.epc = v[11] > 0.5
    state.charging = v[12] > 0.5
    state.airbag_lamp = v[13] > 0.5
    state.dimming = round(Int, 100 * clamp(v[14], 0, 1))
    return state
end

"Frames due later than this are not sent back to back; the stream clock moves forward instead."
const CAN_MAX_CATCH_UP = 0.05

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
    clusters = get(stream.layout, :clusters, FabiaSource[])
    if stream.getters === nothing || integ.t == 0
        stream.getters = [hasproperty(f, :cluster) ? nothing :
            ModelingToolkit.getu(sys, [foldl(getproperty, s.wire_path; init = sys) for s in f.signals])
            for f in frames]
        for c in clusters
            node = foldl(getproperty, c.path; init = sys)
            c.getter = ModelingToolkit.getu(sys, [getproperty(node, field) for field in FABIA_INPUTS])
            c.state = FabiaProtocol.Bench()
            c.read_at = NaN
        end
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
        stream.paced && lateness > CAN_MAX_CATCH_UP && (stream.wall_start += lateness)
        for (i, f) in enumerate(frames)
            if ticks[i] * f.period <= integ.t + 1e-10
                bytes = if hasproperty(f, :cluster)
                    c = f.cluster
                    if c.read_at != integ.t
                        fabia_values!(c.state, c.getter(integ))
                        c.read_at = integ.t
                    end
                    FabiaProtocol.frame!(c.state, f.id, f.builder, integ.t)
                else
                    Vehicle.Planar.can_encode(f, stream.getters[i](integ))
                end
                Base.invokelatest(can_send, stream.transport, f.id, bytes)
                stream.sent += 1
                stream.late += stream.paced && lateness > 0.002
                ticks[i] += 1
            end
        end
    end
    return nothing
end
