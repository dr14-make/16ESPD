using Revise
using VehicleSystemsComponents
using DyadInterface: symbolic_container
using JSON
import BlockComponents, RotationalComponents, MultibodyComponents

const _CAN = VehicleSystemsComponents.Vehicle.Planar

function _can_stop(run, car)
    s = run.sol
    ts = collect(0.5:0.005:6.0)
    v = s(ts; idxs = car.car.bus.vx).u
    i = findfirst(<(0.5), v)
    @test !isnothing(i)
    return s(ts[i]; idxs = car.car.bus.x) - s(0.5; idxs = car.car.bus.x)
end

@testset "CAN timing and DBC resolution" begin
    run = _CAN.CanTxStepTransient()
    m, s = symbolic_container(run), run.sol
    period = s.prob.ps[m.source.start_time] / 5
    sent = s(7period; idxs = m.source.y)
    received = s(7period; idxs = m.tx.y)
    before = s(6period - period / 100; idxs = m.tx.y)
    after = s(6period + period / 100; idxs = m.tx.y)
    @test string(s.retcode) == "Success"
    @test before == 0.0
    @test after == received
    changed = first(t for t in s.t if s(t; idxs = m.tx.y) > 0)
    latency = changed - 5period
    @test latency ≈ period atol = 1e-10
    @test abs(received - sent) <= s.prob.ps[m.tx.scale] / 2
    println("CAN transmitter: ", (; period, latency, sent, received, error = abs(received - sent)))
    drive = _CAN.CanDriveStepTransient()
    d = symbolic_container(drive)
    @test string(drive.sol.retcode) == "Success"
    @test drive.sol(0.25; idxs = d.drive.machine.tau_em) ≈ 100 atol = 0.1
end

@testset "CAN hard straight-line ABS stop" begin
    reference = _CAN.CanReferenceStop()
    ideal = _CAN.CanIdealStop()
    mr, mi = symbolic_container(reference).reference, symbolic_container(ideal).vehicle
    @test string(reference.sol.retcode) == "Success"
    @test string(ideal.sol.retcode) == "Success"
    dr, di = _can_stop(reference, mr), _can_stop(ideal, mi)
    ts = collect(0.01:0.005:6.0)
    deviation = maximum(abs, reference.sol(ts; idxs = mr.car.bus.vx).u - ideal.sol(ts; idxs = mi.car.bus.vx).u)
    @test deviation < 1e-6
    @test di ≈ dr atol = 1e-6
    distances = Float64[]
    for analysis in (_CAN.Can10msStop, _CAN.Can20msStop, _CAN.Can40msStop)
        run = analysis()
        @test string(run.sol.retcode) == "Success"
        push!(distances, _can_stop(run, symbolic_container(run).vehicle))
    end
    @test distances[end] >= di
    println("CAN stopping distance (m): ", (; reference = dr, ideal = di, ms10 = distances[1], ms20 = distances[2], ms40 = distances[3], max_speed_deviation = deviation))
end

@testset "CAN top-level canvas" begin
    source = read(joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "PlanarBEVCanDrive.dyad"), String)
    meta = JSON.parse(match(r"(?s)metadata (\{.*\})\nend", source).captures[1])["_links"]
    connections = collect(eachmatch(r"connect\(([^)]*)\)\s*\{\^(\w+)\}", source))
    @test length(connections) == 23
    unresolved = String[]
    definitions = Dict{String,String}()
    roots = [("", joinpath(@__DIR__, "..", "dyad"))]
    append!(roots, [(string(nameof(lib)), joinpath(Base.pkgdir(lib), "dyad")) for lib in (BlockComponents, RotationalComponents, MultibodyComponents)])
    for (prefix, dir) in roots
        for (folder, _, files) in walkdir(dir; follow_symlinks = true), file in files
            endswith(file, ".dyad") || continue
            text = read(joinpath(folder, file), String)
            for section in eachmatch(r"(?ms)^(?:partial )?component (\w+)(?:@[^\n]*)?\s*\n.*?^end", text)
                key = section.captures[1]
                type_path = splitpath(relpath(joinpath(folder, file), dir))
                parts = isempty(prefix) ? type_path[1:end-1] : [prefix; type_path[1:end-1]]
                definitions[join([parts; key], '.')] = section.match
                get!(definitions, key, section.match)
            end
        end
    end
    function port_icon(type, port)
        text = get(definitions, replace(type, "VehicleSystemsComponents." => ""), get(definitions, last(split(type, '.')), ""))
        mm = match(r"(?s)metadata (\{.*\})\nend", text)
        if !isnothing(mm)
            links = get(JSON.parse(mm.captures[1]), "_links", Dict())
            place = get(get(get(links, port, Dict()), "Dyad", Dict()), "placement", Dict())
            haskey(place, "icon") && return place["icon"]
            haskey(place, "diagram") && return place["diagram"]
        end
        base = match(r"extends ([\w.]+)", text)
        isnothing(base) ? nothing : port_icon(base.captures[1], port)
    end
    points = Dict{String,Tuple{Float64,Float64}}()
    for declaration in eachmatch(r"(?m)^  (\w+) = ([\w.]+)\(", source)
        name, type = declaration.captures
        box = get(get(get(get(meta, name, Dict()), "Dyad", Dict()), "placement", Dict()), "diagram", nothing)
        isnothing(box) && continue
        if type == "RealInput"
            points[name] = ((box["x1"] + box["x2"]) / 2, (box["y1"] + box["y2"]) / 2)
        else
            ports = unique(last(split(strip(e), '.')) for c in connections for e in split(c.captures[1], ',') if startswith(strip(e), name * "."))
            for port in ports
                icon = port_icon(type, port)
                isnothing(icon) && continue
                u, v = (icon["x1"] + icon["x2"]) / 2, (icon["y1"] + icon["y2"]) / 2
                for _ in 1:(mod(Int(get(box, "rot", 0)), 360) ÷ 90)
                    u, v = 1000 - v, u
                end
                points[name * "." * port] = (box["x1"] + (box["x2"] - box["x1"]) * u / 1000, box["y1"] + (box["y2"] - box["y1"]) * v / 1000)
            end
        end
    end
    for c in connections
        ends = strip.(split(c.captures[1], ','))
        append!(unresolved, filter(e -> !haskey(points, e), ends))
        tag = c.captures[2]
        dyad = get(get(meta, tag, Dict()), "Dyad", Dict())
        edges = get(dyad, "edges", [])
        js = get(dyad, "junctions", [])
        isempty(edges) && push!(unresolved, tag)
        point(i) = i < 0 ? (js[-i]["x"], js[-i]["y"]) : get(points, ends[i], nothing)
        for edge in edges
            for i in (edge["S"], edge["E"])
                valid = i > 0 ? i <= length(ends) : 1 <= -i <= length(js)
                valid || push!(unresolved, "$tag endpoint $i")
            end
            a, b = point(edge["S"]), point(edge["E"])
            (isnothing(a) || isnothing(b)) && continue
            path = [a; [(m["x"], m["y"]) for m in edge["M"]]; b]
            @test all(path[i][1] == path[i-1][1] || path[i][2] == path[i-1][2] for i in 2:length(path))
        end
    end
    @test isempty(unresolved)
end
