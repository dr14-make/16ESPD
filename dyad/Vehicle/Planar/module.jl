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


export check_can, can_schedule, can_layout, can_encode, can_decode, can_dbc

# Width describes the actual binary representation, not the number of allowed values.
# In particular, asymmetric signed ranges still need a two's-complement sign bit.
function _can_width(raw_min, raw_max)
    all(x -> isfinite(x) && isinteger(x), (raw_min, raw_max)) ||
        throw(ArgumentError("CAN: raw bounds must be finite integers."))
    lo, hi = BigInt(raw_min), BigInt(raw_max)
    lo <= hi || throw(ArgumentError("CAN: raw_min must not exceed raw_max."))
    signed = lo < 0
    for bits in 1:64
        lower = signed ? -(big(1) << (bits - 1)) : big(0)
        upper = (big(1) << (signed ? bits - 1 : bits)) - 1
        lower <= lo && hi <= upper && return (; bits, signed)
    end
    throw(ArgumentError("CAN: raw bounds exceed a 64-bit CAN signal."))
end

function _can_scaling(scale, offset)
    isfinite(scale) && scale > 0 || throw(ArgumentError("CAN: scale must be finite and positive."))
    isfinite(offset) || throw(ArgumentError("CAN: offset must be finite."))
end

_can_symbol(model, path) = foldl(getproperty, Symbol.(split(path, '₊')); init = model)

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
        Symbolics.value(v)
    end
    blocks = NamedTuple[]
    for (path, s) in sort!(collect(nodes); by = first)
        type = _can_type(s)
        tx = occursin(r"\.CanTx(Real|Integer|Boolean)$", type)
        rx = occursin(r"\.CanRx(Real|Integer|Boolean)$", type)
        term = endswith(type, ".CanTermination")
        adapter = endswith(type, ".CanAdapter")
        (tx || rx || term || adapter) || continue
        bus = isempty(path) ? "bus" : path * "₊bus"
        name = replace(path, "₊" => ".")
        if term || adapter
            push!(blocks, (; name, net = root(bus), kind = adapter ? :adapter : :termination))
        else
            slot, n, id = Int(value(path, :slot_index)), Int(value(path, :slot_count)), Int(value(path, :id))
            if tx
                period = value(path, :frame_period)
                signal_type = endswith(type, "Boolean") ? :boolean : endswith(type, "Integer") ? :integer : :real
                boolean = signal_type == :boolean
                scale, offset = boolean ? (1, 0) : (value(path, :scale), value(path, :offset))
                raw_min, raw_max = boolean ? (0, 1) : (value(path, :raw_min), value(path, :raw_max))
                _can_scaling(scale, offset)
                bits, signed = _can_width(raw_min, raw_max)
                wire_path = isempty(path) ? "wire" : path * "₊wire"
                wire = _can_symbol(model, wire_path)
                push!(blocks, (; name, net = root(bus), kind = :tx, slot, n, id, period,
                               bits, signed, scale, offset, raw_min, raw_max, signal_type,
                               wire_path = Tuple(Symbol.(split(wire_path, '₊'))), wire))
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
    blocks = filter(b -> b.kind != :adapter, _can_tree(model))
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

# Shared deterministic Intel/little-endian frame layout: ascending slot, then name.
function _can_frames(txs)
    frames = NamedTuple[]
    for net in sort!(unique(b.net for b in txs))
        for id in sort!(unique(b.id for b in txs if b.net == net))
            0 <= id <= 2047 || throw(ArgumentError("CAN: identifier $id is outside 0:2047."))
            members = sort!(filter(b -> b.net == net && b.id == id, txs); by = b -> (b.slot, b.name))
            periods = unique(b.period for b in members)
            length(periods) == 1 || throw(ArgumentError("CAN: identifier $id has two periods."))
            period = only(periods)
            isfinite(period) && period > 0 || throw(ArgumentError("CAN: identifier $id needs a positive period."))
            signals = NamedTuple[]
            bits = 0
            slots = Set{Int}()
            for b in members
                1 <= b.slot <= b.n || throw(ArgumentError("CAN: $(b.name) uses slot $(b.slot), outside 1:$(b.n)."))
                b.slot in slots && throw(ArgumentError("CAN: identifier $id has multiple transmitters on slot $(b.slot)."))
                push!(slots, b.slot)
                push!(signals, (; b..., start_bit = bits))
                bits += b.bits
            end
            bytes = cld(bits, 8)
            bytes <= 8 || throw(ArgumentError("CAN: identifier $id exceeds the classic CAN eight-byte payload."))
            push!(frames, (; bus = replace(net, "₊" => "."), id, period, bits, bytes, signals))
        end
    end
    frames
end

"""
    can_layout(model)

Return `(bus, adapter, frames)` for the net attached to exactly one `CanAdapter`.
Requires a retained component tree. Frames are sorted by 11-bit identifier; signals
are packed consecutively by ascending slot (Intel byte order, zero-based start bits).
Each signal includes `wire` (a model symbolic index) and `wire_path` (property symbols
relative to the root) for sampling the transmitter's already delayed wire value.
Unlike `check_can`, a layout may group multiple distinct slots under one identifier.
"""
function can_layout(model)
    blocks = _can_tree(model)
    adapters = filter(b -> b.kind == :adapter, blocks)
    length(adapters) == 1 || throw(ArgumentError("CAN: can_layout requires exactly one CanAdapter; found $(length(adapters))."))
    adapter = only(adapters)
    frames = _can_frames(filter(b -> b.kind == :tx && b.net == adapter.net, blocks))
    (; bus = replace(adapter.net, "₊" => "."), adapter = adapter.name, frames)
end

"""
    can_encode(frame, values::AbstractVector)

Encode physical wire values in `frame.signals` order into `Vector{UInt8}`.
Uses nearest-integer rounding (ties to even) and saturation to the declared raw bounds;
negative raw values use two's complement. Unused high bits are zero.
"""
function can_encode(frame, values::AbstractVector)
    length(values) == length(frame.signals) || throw(ArgumentError("CAN: value count does not match frame signals."))
    payload = big(0)
    for (s, value) in zip(frame.signals, values)
        value isa Real && isfinite(value) || throw(ArgumentError("CAN: signal $(s.name) needs a finite real value."))
        # BigFloat/BigInt avoid overflow at signed/unsigned 64-bit endpoints.
        raw = round(BigInt, (BigFloat(value) - BigFloat(s.offset)) / BigFloat(s.scale))
        raw = clamp(raw, BigInt(s.raw_min), BigInt(s.raw_max))
        payload |= mod(raw, big(1) << s.bits) << s.start_bit
    end
    UInt8[(payload >> (8i)) & 0xff for i in 0:frame.bytes-1]
end

"""
    can_decode(frame, bytes::AbstractVector)

Decode an exact-length payload into physical values in `frame.signals` order.
Boolean signals return `Bool`; other signals return scaled physical values.
"""
function can_decode(frame, bytes::AbstractVector)
    length(bytes) == frame.bytes || throw(ArgumentError("CAN: payload length does not match frame."))
    all(b -> b isa Integer && 0 <= b <= 255, bytes) || throw(ArgumentError("CAN: payload elements must be bytes in 0:255."))
    payload = sum((BigInt(b) << (8(i - 1)) for (i, b) in enumerate(bytes)); init = big(0))
    map(frame.signals) do s
        raw = (payload >> s.start_bit) & ((big(1) << s.bits) - 1)
        s.signed && raw >= (big(1) << (s.bits - 1)) && (raw -= big(1) << s.bits)
        s.signal_type == :boolean ? !iszero(raw) : s.offset + s.scale * raw
    end
end

_can_dbc_name(name) = "S_" * replace(name, r"[^A-Za-z0-9_]" => "_")

"""
    can_dbc(model, path)

Write a classic 11-bit Intel DBC for the adapter-selected layout; return `path`.
Signal factors, offsets, physical limits and frame cycle times come from the same
metadata used by `can_encode` and `can_schedule`. Units are unspecified.
"""
function can_dbc(model, path)
    layout = can_layout(model)
    open(path, "w") do io
        println(io, "VERSION \"\"\n\nNS_ :\n\nBS_:\n\nBU_: Dyad\n")
        for f in layout.frames
            println(io, "BO_ $(f.id) Frame_$(f.id): $(f.bytes) Dyad")
            for (i, s) in enumerate(f.signals)
                # Index suffix also guarantees uniqueness after identifier sanitization.
                name = _can_dbc_name(s.name) * "_" * string(i)
                sign = s.signed ? "-" : "+"
                lo, hi = s.offset + s.scale * s.raw_min, s.offset + s.scale * s.raw_max
                println(io, " SG_ $name : $(s.start_bit)|$(s.bits)@1$sign ($(s.scale),$(s.offset)) [$lo|$hi] \"\" Vector__XXX")
            end
            println(io)
        end
        println(io, "BA_DEF_ BO_ \"GenMsgCycleTime\" INT 0 2147483647;")
        for f in layout.frames
            println(io, "BA_ \"GenMsgCycleTime\" BO_ $(f.id) $(round(BigInt, 1000 * f.period));")
        end
    end
    path
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
    layouts = _can_frames(filter(b -> b.kind == :tx, _can_tree(model)))
    reports = NamedTuple[]
    for bus in unique(f.bus for f in layouts)
        frames = NamedTuple[]
        for f in filter(f -> f.bus == bus, layouts)
            # Only SOF through the CRC sequence is subject to bit stuffing.
            frame_bits = 47 + 8f.bytes + fld(34 + 8f.bytes - 1, 4)
            push!(frames, (; id = f.id, period = f.period, bits = f.bits,
                           frame_bits, frame_time = frame_bits / bitrate))
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
            push!(reports, (; bus, f..., blocking, response_time = response))
        end
    end
    load = sum((f.frame_time / f.period for f in reports); init = 0.0)
    (; bitrate, load, frames = reports)
end
