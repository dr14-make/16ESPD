using JSON

@testset "Fabia canvas wiring and geometry" begin
    definitions, connectors = Dict{String,Any}(), Set{String}()
    root = joinpath(@__DIR__, "..")
    index_canvas_components!(definitions, connectors, joinpath(root, "dyad"),
        "VehicleSystemsComponents"; local_source = true)
    for library in ("BlockComponents", "MultibodyComponents", "RotationalComponents")
        entry = Base.find_package(library)
        index_canvas_components!(definitions, connectors,
            joinpath(dirname(dirname(entry)), "dyad"), library; local_source = false)
    end
    (; canvas) = canvas_audit(definitions, connectors)
    models = ["VehicleSystemsComponents.Vehicle.Planar.FabiaCluster",
        "VehicleSystemsComponents.Vehicle.Planar.FabiaClusterNode",
        "VehicleSystemsComponents.PlanarBEVFabiaScriptedDrive",
        "VehicleSystemsComponents.PlanarBEVByHandFabia"]
    violations = String[]
    for key in models
        text = definitions[key].text
        code = first(split(code_only(text), "metadata"))
        links = get(JSON.parse(match(r"metadata\s*(\{[\s\S]*\})\s*end", text)[1]), "_links", Dict())
        view = canvas(key)
        append!(violations, view.unresolved)
        blocks = view.blocks
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
        for c in eachmatch(r"connect\(([^)]*)\)(?:\s*\{\^(\w+)\})?", code)
            tag = c[2]
            if isnothing(tag) || !haskey(links, tag)
                push!(violations, "$key unplaced connection")
                continue
            end
            @test !isempty(links[tag]["Dyad"]["edges"])
            for endpoint in strip.(split(c[1], ','))
                length(split(endpoint, '.')) <= 2 || push!(violations, "$key non-child endpoint $endpoint")
            end
        end
        for (tag, path) in view.wires
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
