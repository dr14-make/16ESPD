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


export check_can, can_schedule

_can_type(s) = (m = ModelingToolkit.get_gui_metadata(s); isnothing(m) ? "" : string(m.type))

function _can_tree(model)
    while isempty(ModelingToolkit.get_systems(model)) && !isnothing(ModelingToolkit.get_parent(model))
        model = ModelingToolkit.get_parent(model)
    end
    nodes = Dict{String,Any}()
    parent = Dict{String,String}()
    function visit(s, path)
        nodes[path] = s
        occursin(".CanNet", _can_type(s)) && (parent[path] = path)
        for child in ModelingToolkit.get_systems(s)
            visit(child, isempty(path) ? string(nameof(child)) : path * "₊" * string(nameof(child)))
        end
    end
    visit(model, "")
    function root(x)
        while parent[x] != x
            parent[x] = parent[parent[x]]
            x = parent[x]
        end
        x
    end
    for (path, s) in nodes, eq in ModelingToolkit.get_eqs(s)
        rhs = Symbolics.value(eq.rhs)
        rhs isa ModelingToolkit.Connection || continue
        all(e -> e isa ModelingToolkit.AbstractSystem, rhs.systems) || continue
        ends = [isempty(path) ? string(nameof(e)) : path * "₊" * string(nameof(e)) for e in rhs.systems]
        filter!(e -> haskey(parent, e), ends)
        for e in ends[2:end]
            parent[root(e)] = root(first(ends))
        end
    end
    values = Dict(ModelingToolkit.initial_conditions(model))
    merge!(values, ModelingToolkit.bindings(model))
    function value(path, field)
        key = isempty(path) ? string(field) : path * "₊" * string(field)
        matches = [v for (k, v) in values if string(k) == key]
        isempty(matches) && error("CAN: cannot read $key; pass the model before simplification.")
        v = only(matches)
        for _ in 1:100
            next = Symbolics.substitute(v, values)
            isequal(next, v) && break
            v = next
        end
        Float64(Symbolics.value(v))
    end
    blocks = NamedTuple[]
    for (path, s) in sort!(collect(nodes); by = first)
        type = _can_type(s)
        tx = occursin(r"\.CanTx(Real|Integer|Boolean)$", type)
        rx = occursin(r"\.CanRx(Real|Integer|Boolean)$", type)
        term = endswith(type, ".CanTermination")
        (tx || rx || term) || continue
        bus = isempty(path) ? "bus" : path * "₊bus"
        name = replace(path, "₊" => ".")
        if term
            push!(blocks, (; name, net = root(bus), kind = :termination))
        else
            slot, n, id = Int(value(path, :slot_index)), Int(value(path, :slot_count)), Int(value(path, :id))
            if tx
                period = value(path, :frame_period)
                bits = endswith(type, "Boolean") ? 1 : ceil(Int, log2(value(path, :raw_max) - value(path, :raw_min) + 1))
                push!(blocks, (; name, net = root(bus), kind = :tx, slot, n, id, period, bits))
            else
                push!(blocks, (; name, net = root(bus), kind = :rx, slot, n, id))
            end
        end
    end
    blocks
end

"""
    check_can(model)

Check a constructed, uncompiled CAN model before calling `simplify_model(model)`.
For example: `check_can(Can10msStopBench(name = :model))` before `Can10msStop()`.
Checks apply separately to each connected bus, including buses inside ECU assemblies.
"""
function check_can(model)
    blocks = _can_tree(model)
    for b in blocks
        b.kind == :termination && continue
        1 <= b.slot <= b.n || throw(ArgumentError("CAN: $(b.name) uses slot $(b.slot), outside 1:$(b.n)."))
        0 <= b.id <= 2047 || throw(ArgumentError("CAN: $(b.name) has identifier $(b.id), outside 0:2047."))
    end
    for net in unique(b.net for b in blocks)
        bs = filter(b -> b.net == net, blocks)
        txs = filter(b -> b.kind == :tx, bs)
        terms = filter(b -> b.kind == :termination, bs)
        isempty(terms) && throw(ArgumentError("CAN: the bus containing $(first(bs).name) needs a CanTermination."))
        length(terms) == 1 || throw(ArgumentError("CAN: the bus containing $(first(bs).name) needs exactly one CanTermination."))
        for (i, a) in enumerate(txs), b in txs[i+1:end]
            a.slot == b.slot && throw(ArgumentError("CAN: $(a.name) and $(b.name) both transmit on slot $(a.slot)."))
            if a.id == b.id
                a.period == b.period || throw(ArgumentError("CAN: identifier $(a.id) has two periods in $(a.name) and $(b.name)."))
                a.slot == b.slot || throw(ArgumentError("CAN: identifier $(a.id) is assigned to two slots in $(a.name) and $(b.name)."))
            end
        end
        for b in filter(b -> b.kind == :rx, bs)
            any(t -> t.slot == b.slot, txs) || throw(ArgumentError("CAN: $(b.name) receives slot $(b.slot), but nobody transmits on it."))
        end
    end
    return model
end

"""
    can_schedule(model; bitrate = 500_000)

Report classic 11-bit CAN worst-case load and response times; no arbitration is simulated.
The component tree must be retained (a Dyad-generated or MTK-compiled model, not flattened).
Payloads are byte-rounded; the bound includes worst-case stuffing, ACK, EOF and intermission.
Response-time analysis assumes zero release jitter and nonpreemptive fixed-priority frames.
Frames missing their period return `Inf`; this is a report, not a scheduling constraint.
"""
function can_schedule(model; bitrate = 500_000)
    bitrate > 0 || throw(ArgumentError("CAN bitrate must be positive."))
    txs = filter(b -> b.kind == :tx, _can_tree(model))
    reports = NamedTuple[]
    for net in unique(b.net for b in txs)
        frames = NamedTuple[]
        for id in sort!(unique(b.id for b in txs if b.net == net))
            members = filter(b -> b.net == net && b.id == id, txs)
            periods = unique(b.period for b in members)
            length(periods) == 1 || throw(ArgumentError("CAN: identifier $id has two periods."))
            period = only(periods)
            period > 0 || throw(ArgumentError("CAN: identifier $id needs a positive period."))
            bits = sum(b.bits for b in members)
            bytes = cld(bits, 8)
            bytes <= 8 || throw(ArgumentError("CAN: identifier $id exceeds the classic CAN eight-byte payload."))
            # Only SOF through the CRC sequence is subject to bit stuffing.
            frame_bits = 47 + 8bytes + fld(34 + 8bytes - 1, 4)
            push!(frames, (; id, period, bits, frame_bits, frame_time = frame_bits / bitrate))
        end
        for (i, f) in enumerate(frames)
            blocking = maximum((b.frame_time for b in frames[i+1:end]); init = 0.0)
            wait = blocking
            response = Inf
            for _ in 1:10000
                next = blocking + sum((ceil((wait + 1 / bitrate) / h.period) * h.frame_time for h in frames[1:i-1]); init = 0.0)
                if next + f.frame_time > f.period
                    break
                elseif abs(next - wait) < 1e-14
                    response = next + f.frame_time
                    break
                end
                wait = next
            end
            push!(reports, (; bus = replace(net, "₊" => "."), f..., blocking, response_time = response))
        end
    end
    load = sum((f.frame_time / f.period for f in reports); init = 0.0)
    (; bitrate, load, frames = reports)
end
