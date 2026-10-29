# Find layout defects in a rendered diagram: diagonal wire segments, crossings, overlapping wires,
# wires through blocks or instance labels, anything outside the outline, and blocks whose label
# draws sideways or mirrored.
#
# Usage: julia check.jl <file.dyad> <Component> <render.svg>
#
# Wires come from the SVG (diagram coordinates, rounded to whole units); blocks from the `_links`
# placements of the component and of every base it extends inside this library. A base outside the
# library is named in a `note` line and its parts go unchecked. Placements written inline on a
# declaration or `connect` are not read, so they count as a problem until moved into `_links`.
# Each default `$(instance)` label is estimated as a box from y2 + 0.07 h to y2 + 0.2 h, 0.11 h wide
# per character. Custom `labels` are estimated the same way, so read the render for those.
#
# A wire running exactly along a block's edge, as one leaving or reaching a bottom-center port
# sideways does, is a graze, not a hit. A wire is not checked against the block of a port it ends at,
# but is checked against that block's label. Wires leaving the same port may overlap, and wires
# sharing a trunk count one crossing per point. The component's own ports may straddle the 0..1000
# outline. A wire looping around its target, and labels drawn above a block (Constant names, Gain
# `k=`), show only in the PNG. Exit status is the number of problems, so a non-zero exit is a
# finding, not a crash.
using JSON, OrderedCollections

dyad_path, component, svg_path = ARGS

problems = 0

function report(kind, what...)
    kind in ("graze", "note") || (global problems += 1)
    println(join((kind, what...), " "))
end

body_of(text, name) = match(Regex("^(?:\\w+ )*component $name\\b.*?^end\\b", "ms"), text)

# The `dyad/` directory; a base `Lib.A.B.Name` is defined in a file under `dyad/A/B/`.
root = let d = dirname(abspath(dyad_path))
    while basename(d) != "dyad" && dirname(d) != d
        d = dirname(d)
    end
    d
end

function find_base(qualified)
    parts = split(qualified, '.')
    dir = joinpath(root, parts[2:end-1]...)
    isdir(dir) || return nothing
    for f in readdir(dir; join=true)
        endswith(f, ".dyad") || continue
        b = body_of(read(f, String), parts[end])
        b === nothing || return b.match
    end
    nothing
end

# The component's own ports: a `connect` names them bare, and a part's ports as `part.port`.
own = Set{String}()

"`_links` of a component body, its library bases' entries first, so its own override them."
function links_of(text, seen=Set{String}())
    links = OrderedDict{String,Any}()
    for c in eachmatch(r"^\s*connect\(([^)]*)\)"m, text), arg in split(c[1], ',')
        occursin('.', arg) || push!(own, strip(arg))
    end
    for e in eachmatch(r"^\s*extends\s+([\w.]+)"m, text)
        base = e[1]
        base in seen && continue
        push!(seen, base)
        btext = find_base(base)
        if btext === nothing
            report("note", "base $base is outside this library; its parts are not checked")
        else
            merge!(links, links_of(btext, seen))
        end
    end
    meta = match(r"^metadata (\{.*?^\})\s*$"ms, text)
    declarations = meta === nothing ? text : text[1:prevind(text, meta.offset)]
    if occursin(r"\{\s*\"Dyad\"\s*:\s*\{\s*\"(placement|edges)\""m, declarations)
        name = something(match(r"component (\w+)", text), ["?"])[1]
        report("inline", name, "places parts inline; move them into `_links` with `{^tag}`s")
    end
    meta === nothing ||
        merge!(links, get(JSON.parse(meta[1]; dicttype=OrderedDict{String,Any}), "_links", Dict()))
    links
end

body = body_of(read(dyad_path, String), component)
body === nothing && (println(stderr, "component $component not found in $dyad_path"); exit(1))
links = links_of(body.match)

blocks, labels, ports = Pair{String,NTuple{4,Real}}[], Pair{String,NTuple{4,Real}}[], Set{String}()
for (name, link) in links
    placement = get(get(link, "Dyad", Dict()), "placement", Dict())
    box = get(placement, "diagram", nothing)
    box === nothing && continue
    x1, x2 = minmax(box["x1"], box["x2"])
    y1, y2 = minmax(box["y1"], box["y2"])
    push!(blocks, name => (x1, y1, x2, y2))
    if name in own || haskey(placement, "icon")  # the component's own ports draw no label
        push!(ports, name)
    else
        h, cx = y2 - y1, (x1 + x2) / 2
        half = 0.055 * h * length(name)
        # glyphs start a little below the edge, leaving room for a bottom port's wire stub
        push!(labels, name => (cx - half, y2 + 0.07 * h, cx + half, y2 + 0.2 * h))
        # a rotated or flipped block turns its label with it
        rot = mod(get(box, "rot", 0), 360)
        rot == 0 || report("rotated", name, "rot=$rot")
        (box["x1"] > box["x2"] || box["y1"] > box["y2"]) && report("mirrored", name)
    end
end

svg = read(svg_path, String)
paths = [[(round(Int, parse(Float64, p[1])), round(Int, parse(Float64, p[2])))
          for p in eachmatch(r"(-?[\d.]+) (-?[\d.]+)", d[1])]
         for d in eachmatch(r"<path d=\"(M [^\"]*)\" stroke-stroke", svg)]
segs = [(i, a, b) for (i, p) in enumerate(paths) for (a, b) in zip(p, p[2:end]) if a != b]
ends = [Set([p[1], p[end]]) for p in paths]

for (name, (x1, y1, x2, y2)) in blocks
    lo, hi = name in ports ? (-50, 1050) : (0, 1000)  # own ports straddle the outline
    (x1 < lo || y1 < lo || x2 > hi || y2 > hi) && report("outside", name, (x1, y1, x2, y2))
end
for (i, p) in enumerate(paths)
    any(v -> !(-50 <= v <= 1050), Iterators.flatten(p)) && report("outside", "wire $i", p)
end

for (i, a, b) in segs
    a[1] != b[1] && a[2] != b[2] && report("diagonal", "wire $i", a, b)
end

# Wires sharing a trunk cross another wire at one point; that is one crossing on screen.
crossed = Set{Tuple{Int,Int}}()
for x in eachindex(segs), y in x+1:lastindex(segs)
    (i, a, b), (j, c, d) = segs[x], segs[y]
    i == j && continue
    vert1, vert2 = a[1] == b[1], c[1] == d[1]
    if vert1 != vert2
        (p, q), (r, s) = vert1 ? ((a, b), (c, d)) : ((c, d), (a, b))
        lo, hi = minmax(r[1], s[1])
        ylo, yhi = minmax(p[2], q[2])
        point = (p[1], r[2])
        if lo < p[1] < hi && ylo < r[2] < yhi && !(point in crossed)
            push!(crossed, point)
            report("cross", "wires $i and $j", point)
        end
    elseif vert1 && a[1] == c[1] || !vert1 && a[2] == c[2]
        k = vert1 ? 2 : 1
        lo1, hi1 = minmax(a[k], b[k])
        lo2, hi2 = minmax(c[k], d[k])
        if max(lo1, lo2) < min(hi1, hi2) && isempty(ends[i] ∩ ends[j])
            report("overlap", "wires $i and $j", a, b)
        end
    end
end

"A port's wire end sits a few units off its block's edge."
inside((x1, y1, x2, y2), pt; margin=5) =
    x1 - margin <= pt[1] <= x2 + margin && y1 - margin <= pt[2] <= y2 + margin

"`:hit` if the segment passes through the box's interior, `:graze` if it runs along its edge."
function hits((x1, y1, x2, y2), a, b)
    if a[1] == b[1]
        fixed, (lo, hi), (flo, fhi), (slo, shi) = a[1], minmax(a[2], b[2]), (x1, x2), (y1, y2)
    else
        fixed, (lo, hi), (flo, fhi), (slo, shi) = a[2], minmax(a[1], b[1]), (y1, y2), (x1, x2)
    end
    (max(lo, slo) >= min(hi, shi) || !(flo <= fixed <= fhi)) && return nothing
    return flo < fixed < fhi ? :hit : :graze
end

for (i, a, b) in segs
    a[1] != b[1] && a[2] != b[2] && continue
    for (kind, boxes) in (("block", blocks), ("label", labels))
        for (name, box) in boxes
            # the wire's own port sits in this block
            kind == "block" && any(e -> inside(box, e), ends[i]) && continue
            result = hits(box, a, b)
            if result === :hit
                report("through-$kind", name, "wire $i", a, b)
            elseif result === :graze && kind == "label"
                report("graze", name, "wire $i", a, b)
            end
        end
    end
end

println("$problems problem(s)")
exit(min(problems, 255))
