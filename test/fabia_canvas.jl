using JSON

@testset "Fabia canvas wiring and geometry" begin
    definitions, connectors = Dict{String,Any}(), Set{String}()
    root = joinpath(@__DIR__, "..")
    index_canvas_components!(definitions, connectors, joinpath(root, "dyad"),
        "VehicleSystemsComponents"; local_source = true)
    index_canvas_components!(definitions, connectors,
        joinpath(root, "agent_resources", "stdlib_reference", "BlockComponents"),
        "BlockComponents"; local_source = false)
    function resolve(type, owner)
        haskey(definitions, type) && return type
        namespace = split(owner, '.')[1:end-1]
        while !isempty(namespace)
            key = join([namespace; type], '.')
            haskey(definitions, key) && return key
            pop!(namespace)
        end
        error("Unknown canvas component $type in $owner")
    end
    function links_for(key)
        text = definitions[key].text
        links = Dict{String,Any}()
        for base in eachmatch(r"(?m)^  extends ([\w.]+)", code_only(text))
            merge!(links, links_for(resolve(base[1], key)))
        end
        meta = match(r"metadata\s*(\{[\s\S]*\})\s*end", text)
        isnothing(meta) || merge!(links, get(JSON.parse(meta[1]), "_links", Dict()))
        links
    end
    function placement(links, tag, layer)
        get(get(get(links, tag, Dict()), "Dyad", Dict()), "placement", Dict())[layer]
    end
    models = ["VehicleSystemsComponents.Vehicle.Planar.FabiaCluster",
        "VehicleSystemsComponents.Vehicle.Planar.FabiaClusterNode",
        "VehicleSystemsComponents.PlanarBEVFabiaScriptedDrive",
        "VehicleSystemsComponents.PlanarBEVByHandFabia"]
    violations = String[]
    for key in models
        text = definitions[key].text
        code = first(split(code_only(text), "metadata"))
        links = links_for(key)
        points = Dict{String,Tuple{Float64,Float64}}()
        blocks = Dict{String,NTuple{4,Float64}}()
        for member in eachmatch(r"(?m)^  (\w+) = ([\w.]+)\([^\n]*\)\s*\{\^(\w+)\}", code)
            name, type, tag = member.captures
            box = placement(links, tag, "diagram")
            if type in ("RealInput", "BooleanInput", "CanNet")
                points[name] = ((box["x1"] + box["x2"]) / 2, (box["y1"] + box["y2"]) / 2)
                continue
            end
            blocks[name] = (box["x1"], box["y1"], box["x2"], box["y2"] + 40)
            child_links = links_for(resolve(type, key))
            for (port, item) in child_links
                p = get(get(item, "Dyad", Dict()), "placement", Dict())
                icon = get(p, "icon", get(p, "diagram", nothing))
                isnothing(icon) && continue
                points[name * "." * port] = on_canvas(box,
                    (icon["x1"] + icon["x2"]) / 2, (icon["y1"] + icon["y2"]) / 2)
            end
        end
        for member in eachmatch(r"(?m)^  (\w+) = [\w.]+\(", code)
            haskey(links, member[1]) || push!(violations, "$key missing placement for $(member[1])")
        end
        relations = occursin("relations", code) ? last(split(code, "relations"; limit = 2)) : ""
        for line in split(relations, '\n')
            stripped = strip(line)
            isempty(stripped) && continue
            startswith(stripped, "connect(") && continue
            occursin(r"\b\w+\.\w+", stripped) && push!(violations, "$key equation references a child: $stripped")
            startswith(stripped, "if ") && push!(violations, "$key conditional wiring")
        end
        for connection in eachmatch(r"connect\(([^)]*)\)(?:\s*\{\^(\w+)\})?", code)
            ends = strip.(split(connection[1], ','))
            tag = connection[2]
            if isnothing(tag) || !haskey(links, tag)
                push!(violations, "$key unplaced connection"); continue
            end
            for endpoint in ends
                length(split(endpoint, '.')) <= 2 || push!(violations, "$key non-child endpoint $endpoint")
                haskey(points, endpoint) || push!(violations, "$key unresolved endpoint $endpoint")
            end
            all(e -> haskey(points, e), ends) || continue
            edges = links[tag]["Dyad"]["edges"]
            @test !isempty(edges)
            for edge in edges
                path = [points[ends[edge["S"]]];
                    [(m["x"], m["y"]) for m in edge["M"]]; points[ends[edge["E"]]]]
                for (x, y) in path
                    0 <= x <= 1000 && 0 <= y <= 1000 || push!(violations, "$key $tag outside frame")
                end
                for (p, q) in zip(path, path[2:end])
                    abs(p[1] - q[1]) <= .5 || abs(p[2] - q[2]) <= .5 ||
                        push!(violations, "$key $tag diagonal $p -> $q")
                    for (name, b) in blocks
                        if abs(p[1] - q[1]) <= .5
                            hit = b[1] + .5 < p[1] < b[3] - .5 &&
                                max(min(p[2], q[2]), b[2]) < min(max(p[2], q[2]), b[4]) - .5
                        else
                            hit = b[2] + .5 < p[2] < b[4] - .5 &&
                                max(min(p[1], q[1]), b[1]) < min(max(p[1], q[1]), b[3]) - .5
                        end
                        hit && push!(violations, "$key $tag crosses $name or its label")
                    end
                end
            end
        end
        names = sort!(collect(keys(blocks)))
        for (i, a) in enumerate(names), b in names[i+1:end]
            A, B = blocks[a], blocks[b]
            A[1] < B[3] && B[1] < A[3] && A[2] < B[4] && B[2] < A[4] &&
                push!(violations, "$key overlapping boxes/labels: $a, $b")
        end
    end
    isempty(violations) || @error "Fabia canvas violations" violations
    @test isempty(violations)
end
