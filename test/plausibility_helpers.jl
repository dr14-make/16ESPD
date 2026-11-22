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
