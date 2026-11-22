using Revise
using VehicleSystemsComponents
using DyadInterface: symbolic_container
using JSON
import BlockComponents, RotationalComponents, MultibodyComponents, ModelingToolkit, DyadInterface

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
    received = s(7period; idxs = m.rx.y)
    before = s(6period - period / 100; idxs = m.rx.y)
    after = s(6period + period / 100; idxs = m.rx.y)
    @test string(s.retcode) == "Success"
    @test before == 0.0
    @test after == received
    changed = first(t for t in s.t if s(t; idxs = m.rx.y) > 0)
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
    @test all(d -> d >= di, distances)
    @test dr ≈ 26.839 atol = 1e-3
    @test di ≈ 26.839 atol = 1e-3
    @test distances[1] ≈ 27.496 atol = 1e-3
    @test distances[2] ≈ 28.415 atol = 1e-3
    @test distances[3] ≈ 28.210 atol = 1e-3
    println("CAN stopping distance (m): ", (; reference = dr, ideal = di, ms10 = distances[1], ms20 = distances[2], ms40 = distances[3], max_speed_deviation = deviation))
end

@testset "CAN top-level canvas" begin
    source = read(joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "PlanarBEVCanDrive.dyad"), String)
    meta = JSON.parse(match(r"(?s)metadata (\{.*\})\nend", source).captures[1])["_links"]
    connections = collect(eachmatch(r"connect\(([^)]*)\)\s*\{\^(\w+)\}", source))
    @test length(connections) == 23
    unresolved = String[]
    definitions = Dict{String,Any}()
    connectors = Set{String}()
    roots = [("VehicleSystemsComponents", joinpath(@__DIR__, "..", "dyad"))]
    append!(roots, [(string(nameof(lib)), joinpath(Base.pkgdir(lib), "dyad")) for lib in (BlockComponents, RotationalComponents, MultibodyComponents)])
    for (prefix, dir) in roots
        index_canvas_components!(definitions, connectors, dir, prefix; local_source = prefix == "VehicleSystemsComponents")
    end
    function port_icon(type, port)
        key = haskey(definitions, type) ? type : "VehicleSystemsComponents.Vehicle.Planar." * type
        text = haskey(definitions, key) ? definitions[key].text : ""
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
                points[name * "." * port] = on_canvas(box, u, v)
            end
        end
    end
    wires = Tuple{String,Vector{Tuple{Float64,Float64}}}[]
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
            push!(wires, (tag, path))
            @test all(path[i][1] == path[i-1][1] || path[i][2] == path[i-1][2] for i in 2:length(path))
        end
    end
    @test isempty(unresolved)
    crossings = canvas_crossings(wires)
    println("CAN canvas: ", length(connections), " connections, ", length(crossings), " crossings")
    @test isempty(crossings)
end


@testset "CAN typed links and cruise" begin
    run = _CAN.CanTypedStepRun()
    m, s = symbolic_container(run), run.sol
    @test string(s.retcode) == "Success"
    @test !s(0.119; idxs = m.boolean_rx.y)
    @test s(0.121; idxs = m.boolean_rx.y)
    @test s(0.119; idxs = m.integer_rx.y) == 0
    @test s(0.121; idxs = m.integer_rx.y) == 8
    ideal, realistic = _CAN.CanCruiseIdealRun(), _CAN.CanCruiseRun()
    mi, mr = symbolic_container(ideal), symbolic_container(realistic)
    @test string(ideal.sol.retcode) == "Success"
    @test string(realistic.sol.retcode) == "Success"
    @test ideal.sol(20; idxs = mi.speed) ≈ 20 atol = 0.001
    @test realistic.sol(20; idxs = mr.speed) ≈ ideal.sol(20; idxs = mi.speed) atol = 0.001
end

@testset "CAN topology checks and schedule" begin
    @test _CAN.check_can(_CAN.Can10msStopBench(name = :car)) isa ModelingToolkit.System
    function scratch_bus(; slot = 2, id = 256, period = 0.02, receiver = 1, termination = true, duplicate = true)
        tx1 = _CAN.CanTxReal(name = :tx1, n = 2, slot = 1, id = 128, ideal = true, period = 0.01, raw_max = 255)
        tx2 = _CAN.CanTxReal(name = :tx2, n = 2, slot = slot, id = id, ideal = true, period = period, raw_max = 255)
        rx = _CAN.CanRxReal(name = :rx, n = 2, slot = receiver)
        term = _CAN.CanTermination(name = :term, n = 2)
        systems = [tx1, rx]
        duplicate && push!(systems, tx2)
        termination && push!(systems, term)
        eqs = [ModelingToolkit.connect([getproperty(s, :bus) for s in systems]...)]
        ModelingToolkit.System(eqs, _CAN.t, [], []; systems, name = :scratch)
    end
    cases = [
        (scratch_bus(slot = 1), "CAN: tx1 and tx2 both transmit on slot 1."),
        (scratch_bus(receiver = 2, duplicate = false), "CAN: rx receives slot 2, but nobody transmits on it."),
        (scratch_bus(termination = false), "CAN: the bus containing rx needs a CanTermination."),
        (scratch_bus(slot = 3), "CAN: tx2 uses slot 3, outside 1:2."),
        (scratch_bus(id = 128, period = 0.01), "CAN: identifier 128 is assigned to two slots in tx1 and tx2."),
        (scratch_bus(id = 128), "CAN: identifier 128 has two periods in tx1 and tx2."),
    ]
    for (model, message) in cases
        err = try
            _CAN.check_can(model)
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test err.msg == message
        println(message)
    end
    schedule = _CAN.can_schedule(scratch_bus())
    @test schedule.load ≈ 0.0195
    @test [f.frame_bits for f in schedule.frames] == [65, 65]
    @test [f.response_time for f in schedule.frames] ≈ [0.00026, 0.00026]
    @test [f.blocking for f in schedule.frames] ≈ [0.00013, 0.0]
    @test_throws ArgumentError _CAN.can_schedule(scratch_bus(); bitrate = 0)
    compiled = DyadInterface.simplify_model(_CAN.CanCruiseIdeal(name = :cruise))
    @test _CAN.can_schedule(compiled).load ≈ _CAN.can_schedule(_CAN.CanCruiseIdeal(name = :cruise)).load
    println("CAN car schedule: ", _CAN.can_schedule(_CAN.Can10msStopBench(name = :car)))
end
