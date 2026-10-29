# Set `_links` entries of one component in a .dyad file from a JSON spec, keeping every other byte.
#
# Usage: julia apply.jl <file.dyad> <Component> <spec.json>
#
# The spec maps a tag to its new value, e.g.
#   {"engine": {"Dyad": {"placement": {"diagram": {"x1": 105, "y1": 35, "x2": 185, "y2": 115}}}},
#    "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 100, "y": 115}], "E": 2}]}}}
# An existing entry must be written on one line; new tags are added at the top of `_links`,
# in spec order. Tags are looked up only inside <Component>, since test components reuse wire tags.
using JSON, OrderedCollections

fail(msg) = (println(stderr, msg); exit(1))

# The .dyad files space their JSON as `{"k": v, "k2": [a, b]}`; JSON.json writes it compact.
dumps(v::AbstractDict) = "{" * join(("$(JSON.json(string(k))): $(dumps(x))" for (k, x) in v), ", ") * "}"
dumps(v::AbstractVector) = "[" * join(dumps.(v), ", ") * "]"
dumps(v) = JSON.json(v)

path, component, spec_path = ARGS
src = read(path, String)
body = match(Regex("^(?:\\w+ )*component $component\\b.*?^end\\b", "ms"), src)
body === nothing && fail("component $component not found in $path")
text = String(body.match)
added = Pair{String,Any}[]

for (tag, value) in JSON.parse(read(spec_path, String); dicttype=OrderedDict{String,Any})
    entry = Regex("^(\\s*\"\\Q$tag\\E\": )\\{.*\\}(,?)\$", "m")
    n = length(collect(eachmatch(entry, text)))
    if n == 1
        global text = replace(text, entry => m -> (e = match(entry, m); e[1] * dumps(value) * e[2]))
        continue
    end
    if n > 1 || occursin(Regex("^\\s*\"\\Q$tag\\E\":", "m"), text)
        fail("$tag: entry is not a single line; edit it by hand")
    end
    push!(added, tag => value)
end

if !isempty(added)
    links = r"^(\s*)\"_links\": \{\n"m
    occursin(links, text) || fail("$(first(added[1])): no multi-line \"_links\" block in $component to add to")
    text = replace(text, count=1, links => m -> (l = match(links, m);
        m * join("$(l[1])  \"$tag\": $(dumps(value)),\n" for (tag, value) in added)))
end

write(path, string(SubString(src, 1, prevind(src, body.offset)), text,
                   SubString(src, body.offset + ncodeunits(body.match))))
