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

function can_stream_layout(model)
    clusters = NamedTuple[]
    function visit(s, path)
        if endswith(Vehicle.Planar._can_type(s), ".FabiaCluster")
            push!(clusters, (; path, state = FabiaProtocol.Bench(), last_pulse_time = Ref(0.0)))
        end
        for child in ModelingToolkit.get_systems(s)
            visit(child, [path; nameof(child)])
        end
    end
    visit(model, Symbol[])
    adapters = filter(b -> b.kind == :adapter, Vehicle.Planar._can_tree(model))
    frames = Any[]
    if !isempty(adapters)
        append!(frames, Vehicle.Planar.can_layout(model).frames)
    end
    isempty(clusters) && isempty(adapters) && throw(ArgumentError("CAN: model has no CanAdapter or FabiaCluster"))
    for c in clusters, (id, period, builder) in FabiaProtocol.schedule(c.state)
        push!(frames, (; id, period, builder, cluster = c, signals = []))
    end
    ids = [f.id for f in frames]
    length(unique(ids)) == length(ids) || throw(ArgumentError("CAN: overlapping frame ids on one interface"))
    return (; frames)
end

function fabia_values!(state, values)
    state.kmh = max(0.0, values[1] * 3.6)
    state.rpm, state.coolant = values[2:3]
    state.dimming = round(Int, 100 * clamp(values[end], 0, 1))
    for (field, value) in zip(FABIA_INPUTS[4:end-1], values[4:end-1])
        setproperty!(state, field, value > 0.5)
    end
    return state
end

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
        stream.getters = [ModelingToolkit.getu(sys, hasproperty(f, :cluster) ?
            [getproperty(foldl(getproperty, f.cluster.path; init = sys), field) for field in FABIA_INPUTS] :
            [foldl(getproperty, s.wire_path; init = sys) for s in f.signals]) for f in frames]
        for f in frames
            hasproperty(f, :cluster) || continue
            empty!(f.cluster.state.count)
            f.cluster.state.pulses = 0.0
            f.cluster.last_pulse_time[] = 0.0
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
        for (i, f) in enumerate(frames)
            if ticks[i] * f.period <= integ.t + 1e-10
                bytes = if hasproperty(f, :cluster)
                    b = fabia_values!(f.cluster.state, stream.getters[i](integ))
                    build = f.builder
                    interval = integ.t - f.cluster.last_pulse_time[]
                    build === :bremse_2 && (f.cluster.last_pulse_time[] = integ.t)
                    FabiaProtocol.frame!(b, f.id, build, integ.t, interval)
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
