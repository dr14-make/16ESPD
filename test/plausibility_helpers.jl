# Derived metrics shared by the plausibility suites. Each takes a time vector and a signal.

"""
    rise_time(t, y, frac; t0 = first(t)) -> Float64

Time after `t0` at which `y` first covers `frac` of its change from `y(t0)` to its final value,
in either direction. `frac = 0.632` gives a first-order time constant.
"""
function rise_time(t, y, frac; t0 = first(t))
    i0 = findfirst(>=(t0), t)
    y0, y1 = y[i0], y[end]
    target = y0 + frac * (y1 - y0)
    i = findfirst(k -> k >= i0 && sign(y1 - y0) * (y[k] - target) >= 0, eachindex(y))
    # Interpolate inside the crossing step so the result does not depend on the save grid.
    i == i0 && return 0.0
    w = (target - y[i-1]) / (y[i] - y[i-1])
    return t[i-1] + w * (t[i] - t[i-1]) - t0
end

"""
    max_rate(t, y) -> Float64

Largest absolute slope of `y` between consecutive samples.
"""
max_rate(t, y) = maximum(abs.(diff(y) ./ diff(t)))

"""
    cycle_frequency(t, y) -> Float64

Mean frequency of the oscillation in `y`, from the zero crossings of `y` minus its mean.
"""
function cycle_frequency(t, y)
    d = y .- sum(y) / length(y)
    crossings = [t[k] for k in 2:length(d) if signbit(d[k-1]) != signbit(d[k])]
    length(crossings) < 3 && return 0.0
    return (length(crossings) - 1) / 2 / (crossings[end] - crossings[1])
end

function code_only(text)
    replace(text, r"\"\"\"[\s\S]*?\"\"\"|\"(?:\\.|[^\"\\])*\"|#[^\n]*" =>
        s -> replace(s, r"[^\n]" => c -> repeat(" ", ncodeunits(c))))
end
function component_sections(source)
    starts = collect(eachmatch(r"(?m)^(?:test |partial )?component (\w+)", code_only(source)))
    [(; name = component.captures[1], offset = component.offset,
        text = source[component.offset:(index < length(starts) ?
            prevind(source, starts[index + 1].offset) : lastindex(source))])
     for (index, component) in enumerate(starts)]
end

function index_canvas_components!(definitions, connectors, root, prefix; local_source)
    for (dir, _, names) in walkdir(root), name in names
        endswith(name, ".dyad") || continue
        file = joinpath(dir, name)
        source = read(file, String)
        # relpath(root, root) is ".", not a namespace segment.
        namespace = join([prefix; filter(x -> x != ".", splitpath(relpath(dir, root)))], ".")
        for m in eachmatch(r"(?m)^connector (\w+)", code_only(source))
            push!(connectors, namespace * "." * m.captures[1])
        end
        for c in component_sections(source)
            key = namespace * "." * c.name
            # Analyses and functions are not members of the component type.
            boundary = match(r"(?m)^(?:analysis|function|connector|type)\s", code_only(c.text))
            text = isnothing(boundary) ? c.text : c.text[1:prevind(c.text, boundary.offset)]
            definitions[key] = (; c..., text, file, namespace, local_source,
                first_line = count(==('\n'), source[1:prevind(source, c.offset)]))
        end
    end
end

function on_canvas(box, u, v)
    for _ in 1:(mod(Int(get(box, "rot", 0)), 360) ÷ 90)
        u, v = 1000 - v, u
    end
    (box["x1"] + (box["x2"] - box["x1"]) * u / 1000, box["y1"] + (box["y2"] - box["y1"]) * v / 1000)
end


function canvas_crossings(wires)
    segments = [(tag, a, b) for (tag, path) in wires for (a, b) in zip(path, path[2:end]) if a != b]
    crossings = []
    for i in eachindex(segments), j in (i + 1):length(segments)
        ta, a, b = segments[i]
        tb, c, d = segments[j]
        ta == tb && continue
        lo = max.(min.(a, b), min.(c, d))
        hi = min.(max.(a, b), max.(c, d))
        all(lo .<= hi) || continue
        # A point contact is legal only at endpoints of both segments; overlaps are not junctions.
        lo == hi && lo in (a, b) && lo in (c, d) && continue
        push!(crossings, (ta, tb, lo, hi))
    end
    crossings
end

function canvas_audit(definitions, connectors)
    meta_of(text) = (m = match(r"(?s)metadata (\{.*?\})\nend", text); isnothing(m) ? nothing : JSON.parse(m.captures[1]))
    placement(links, name, kind) = get(get(get(get(links, name, Dict()), "Dyad", Dict()), "placement", Dict()), kind, nothing)
    function resolve_type(type, owner)
        haskey(definitions, type) && return type
        namespace = split(definitions[owner].namespace, '.')
        while !isempty(namespace)
            candidate = join([namespace; type], ".")
            haskey(definitions, candidate) && return candidate
            pop!(namespace)
        end
        nothing
    end
    function bases(key)
        [m.captures[1] for m in eachmatch(r"(?m)^\s*extends\s+([\w.]+)", code_only(definitions[key].text))]
    end
    function declarations(key)
        text = first(split(code_only(definitions[key].text), r"(?m)^relations\s*$"; limit = 2))
        Dict(m.captures[1] => m.captures[2] for m in
            eachmatch(r"(?m)^\s*(\w+)\s*=\s*([\w.]+)\s*\(", text))
    end
    member_cache = Dict{String,Dict{String,Tuple{String,String}}}()
    function members(key, seen = Set{String}())
        haskey(member_cache, key) && return member_cache[key]
        key in seen && error("Cyclic component inheritance: $key")
        result = Dict{String,Tuple{String,String}}()
        for base in bases(key)
            parent = resolve_type(base, key)
            isnothing(parent) && error("Unresolved base $base in $key")
            merge!(result, members(parent, union(seen, [key])))
        end
        for (name, type) in declarations(key)
            result[name] = (type, key)
        end
        member_cache[key] = result
    end
    # Studio draws a component from its own metadata merged over its bases'.
    own_meta(key) = something(meta_of(definitions[key].text), Dict{String,Any}())
    meta_cache = Dict{String,Any}()
    function merged_meta(key)
        get!(meta_cache, key) do
            links, labels = Dict{String,Any}(), nothing
            for base in bases(key)
                parent = resolve_type(base, key)
                isnothing(parent) && continue
                l, lab = merged_meta(parent)
                merge!(links, l)
                isnothing(lab) || (labels = lab)
            end
            meta = own_meta(key)
            merge!(links, get(meta, "_links", Dict{String,Any}()))
            lab = get(get(meta, "Dyad", Dict{String,Any}()), "labels", nothing)
            (links, isnothing(lab) ? labels : lab)
        end
    end
    # Maps a point of a child's 0-1000 icon frame onto the parent canvas; a box with x1 > x2
    # or y1 > y2 is mirrored and "rot" turns it clockwise.
    is_component(type, owner) = !isnothing(resolve_type(type, owner))
    # Connectors the Dyad language defines; library connectors are indexed from source.
    builtin_connectors = Set(("RealInput", "RealOutput", "BooleanInput", "BooleanOutput",
        "IntegerInput", "IntegerOutput", "Spline", "Pin", "Frame", "Flange", "HeatPort"))
    function is_connector(type, owner)
        type in builtin_connectors && return true
        namespace = split(definitions[owner].namespace, '.')
        while true
            join([namespace; type], ".") in connectors && return true
            isempty(namespace) && return false
            pop!(namespace)
        end
    end
    function canvas(key)
        links, _ = merged_meta(key)
        ports, blocks = Dict{String,Tuple{Float64,Float64}}(), Dict{String,Any}()
        unresolved = String[]
        for (name, (type, owner)) in members(key)
            box = placement(links, name, "diagram")
            isnothing(box) && continue
            if is_component(type, owner)
                child = resolve_type(type, owner)
                child_links, child_labels = merged_meta(child)
                for (port, (ptype, powner)) in members(child)
                    is_component(ptype, powner) && continue
                    icon = something(placement(child_links, port, "icon"), placement(child_links, port, "diagram"), Some(nothing))
                    isnothing(icon) && continue
                    is_connector(ptype, powner) || (push!(unresolved, "$name.$port::$ptype"); continue)
                    ports[name * "." * port] = on_canvas(box, (icon["x1"] + icon["x2"]) / 2, (icon["y1"] + icon["y2"]) / 2)
                end
                anchors = something(child_labels, [Dict("x" => 500, "y" => 1100)])
                label_ys = [on_canvas(box, l["x"], l["y"])[2] for l in anchors]
                x1, x2 = minmax(box["x1"], box["x2"])
                y1, y2 = minmax(box["y1"], box["y2"])
                # A label is about 16 units tall, centered on its anchor; no labels, no band.
                blocks[name] = isempty(label_ys) ? (x1, y1, x2, y2) :
                    (x1, min(y1, minimum(label_ys) - 8), x2, max(y2, maximum(label_ys) + 8))
            elseif is_connector(type, owner)
                ports[name] = ((box["x1"] + box["x2"]) / 2, (box["y1"] + box["y2"]) / 2)
            else
                push!(unresolved, "$name::$type")
            end
        end
        wires = Tuple{String,Vector{Tuple{Float64,Float64}}}[]
        junctions = Tuple{String,Float64,Float64}[]
        function collect_connects(k)
            for base in bases(k)
                parent = resolve_type(base, k)
                isnothing(parent) || collect_connects(parent)
            end
            # An untagged connect has no metadata and is drawn as one straight edge per target.
            for c in eachmatch(r"connect\(([^)]*)\)(?:\s*\{\^(\w+)\})?", code_only(definitions[k].text))
                ends = strip.(split(c.captures[1], ','))
                tag = something(c.captures[2], "untagged connect(" * c.captures[1] * ")")
                dyad = get(get(links, tag, Dict()), "Dyad", Dict())
                js = [(j["x"], j["y"]) for j in get(dyad, "junctions", [])]
                append!(junctions, [(tag, x, y) for (x, y) in js])
                point(i) = i < 0 ? js[-i] : get(ports, ends[i], nothing)
                for edge in get(dyad, "edges", [Dict("S" => 1, "E" => i, "M" => []) for i in 2:length(ends)])
                    a, b = point(edge["S"]), point(edge["E"])
                    if isnothing(a) || isnothing(b)
                        push!(unresolved, "wire $tag: " * join(ends[[i for i in (edge["S"], edge["E"]) if i > 0]], " -> "))
                        continue
                    end
                    push!(wires, (tag, [a; [(m["x"], m["y"]) for m in edge["M"]]; b]))
                end
            end
        end
        collect_connects(key)
        (; blocks, wires, junctions, unresolved, ports)
    end
    (; canvas, resolve_type, bases, declarations, members)
end
