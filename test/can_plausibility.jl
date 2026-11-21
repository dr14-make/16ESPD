using Revise
using VehicleSystemsComponents
using DyadInterface: symbolic_container
using JSON
import BlockComponents, RotationalComponents, MultibodyComponents, ModelingToolkit, DyadInterface

const _CAN = VehicleSystemsComponents.Vehicle.Planar

include("../scripts/lecture06_can_sweep.jl")
const _CAN_DEFAULT_DISTANCE_PINS = (; reference = 28.185, ideal = 28.185, ms10 = 29.056, ms20 = 30.018, ms40 = 30.442)
const _CAN_40MS_EXCESS_MARGIN = 5.525

function _can_stop(run, car)
    s = run.sol
    ts = collect(0.5:0.005:6.0)
    v = s(ts; idxs = car.car.bus.vx).u
    i = findfirst(<(0.5), v)
    @test !isnothing(i)
    return s(ts[i]; idxs = car.car.bus.x) - s(0.5; idxs = car.car.bus.x)
end

@testset "Lecture 6 ABS-control hold" begin
    release = _CAN.AbsControlHoldRun()
    stop = _CAN.AbsControlHoldRun(release_time = 1.0, stop_time = 0.2)
    for run in (release, stop)
        model = symbolic_container(run)
        @test string(run.sol.retcode) == "Success"
        @test run.sol(0.04; idxs = model.hold.y) == 0
        @test run.sol(0.06; idxs = model.hold.y) == 1
        # The pressure-release pulse has ended, but ABS control remains active.
        @test run.sol(0.14; idxs = model.hold.y) == 1
        @test run.sol(0.19; idxs = model.hold.y) == 1
        @test run.sol(0.21; idxs = model.hold.y) == 0
        @test run.sol(0.36; idxs = model.hold.y) == 0
    end
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
    # With local continuous demand, first front activity is a genuine release, not build lag.
    arm_times = collect(0.5:0.001:1.0)
    activity = ideal.sol(arm_times; idxs = mi.ecu.ecu.front_active).u
    phases = ideal.sol(arm_times; idxs = mi.ecu.ecu.abs.abs.fl.modulator.phase_out).u
    @test findfirst(>(0.5), activity) == findfirst(<(-0.5), phases)
    for (run, vehicle) in ((reference, mr), (ideal, mi))
        times = collect(0.5:0.001:6.0)
        velocity = run.sol(times; idxs = vehicle.car.bus.vx).u
        for corner in (:fl, :fr, :rl, :rr)
            surface = 0.31 .* run.sol(times; idxs = getproperty(vehicle.car, corner).inertia.w).u
            @test !any((surface .< 0.1) .& (velocity .> 1.5))
        end
    end
    ts = collect(0.01:0.005:6.0)
    deviation = maximum(abs, reference.sol(ts; idxs = mr.car.bus.vx).u - ideal.sol(ts; idxs = mi.car.bus.vx).u)
    @test deviation < 1e-5
    @test di ≈ dr atol = 1e-6
    distances = Float64[]
    for analysis in (_CAN.Can10msStop, _CAN.Can20msStop, _CAN.Can40msStop)
        run = analysis()
        @test string(run.sol.retcode) == "Success"
        vehicle = symbolic_container(run).vehicle
        push!(distances, _can_stop(run, vehicle))
        lock_times = collect(0.5:0.001:6.0)
        velocity = run.sol(lock_times; idxs = vehicle.car.bus.vx).u
        for corner in (:fl, :fr, :rl, :rr)
            surface = 0.31 .* run.sol(lock_times; idxs = getproperty(vehicle.car, corner).inertia.w).u
            @test !any((surface .< 0.1) .& (velocity .> 1.5))
        end
    end
    @test all(d -> d >= di, distances)
    @test _CAN_DEFAULT_DISTANCE_PINS !== nothing
    if _CAN_DEFAULT_DISTANCE_PINS !== nothing
        pins = _CAN_DEFAULT_DISTANCE_PINS
        @test dr ≈ pins.reference atol = 1e-3
        @test di ≈ pins.ideal atol = 1e-3
        @test distances[1] ≈ pins.ms10 atol = 1e-3
        @test distances[2] ≈ pins.ms20 atol = 1e-3
        @test distances[3] ≈ pins.ms40 atol = 1e-3
    end
    println("CAN stopping distance (m): ", (; reference = dr, ideal = di, ms10 = distances[1], ms20 = distances[2], ms40 = distances[3], max_speed_deviation = deviation))
end

@testset "Lecture 6 CAN phase-sweep CSV" begin
    sweep = Lecture06CanSweep
    @test isfile(sweep.OUT)
    if isfile(sweep.OUT)
        rows, hash = sweep.read_sweep()
        @test hash == sweep.inputs_hash()
        expected = Set((a, p, o) for a in sweep.ARCHITECTURES
            for p in (a in ("point", "ideal") ? [0.0] : sweep.PERIODS)
            for o in sweep.OFFSETS)
        @test length(sweep.OFFSETS) >= 6
        @test length(rows) == length(expected)
        @test Set((r.architecture, r.period, r.offset) for r in rows) == expected
        @test all(r -> isfinite(r.distance) && r.distance > 0, rows)
        for (period, pin) in zip(sweep.PERIODS, (30.743, 29.320, 33.934))
            @test only(r.distance for r in rows if r.architecture == "bus_brake" &&
                r.period == period && r.offset == 0.0) ≈ pin atol = 1e-3
        end
        # Preserved counterexample briefly locks its rear wheels near the ABS low-speed cutoff.
        @test_broken all(r -> !r.wheel_lock, rows)
        @test [(r.architecture, r.period, r.offset) for r in rows if r.wheel_lock] ==
            [("bus_brake", 0.010, 0.030)]
        for offset in sweep.OFFSETS
            point = only(r.distance for r in rows if r.architecture == "point" && r.offset == offset)
            ideal = only(r.distance for r in rows if r.architecture == "ideal" && r.offset == offset)
            @test ideal ≈ point atol = 1e-5 rtol = 0
        end
        mean_distance(a, p) = sum(r.distance for r in rows
            if r.architecture == a && r.period == p) / length(sweep.OFFSETS)
        for period in sweep.PERIODS
            @test mean_distance("real", period) < mean_distance("bus_brake", period)
        end
        @test _CAN_40MS_EXCESS_MARGIN !== nothing
        if _CAN_40MS_EXCESS_MARGIN !== nothing
            @test _CAN_40MS_EXCESS_MARGIN > 0
            @test mean_distance("bus_brake", 0.040) - mean_distance("ideal", 0.0) ≈
                _CAN_40MS_EXCESS_MARGIN atol = 1e-3
        end
    end
end


@testset "CAN top-level canvas" begin
    source = read(joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "PlanarBEVCanDrive.dyad"), String)
    meta = JSON.parse(match(r"(?s)metadata (\{.*\})\nend", source).captures[1])["_links"]
    connections = collect(eachmatch(r"connect\(([^)]*)\)\s*\{\^(\w+)\}", source))
    @test length(connections) == 25
    wired_source = read(joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "PlanarBEVDriveEstimated.dyad"), String)
    wired_connections = collect(eachmatch(r"connect\(([^)]*)\)\s*\{\^(\w+)\}", wired_source))
    # Each car has six mechanical links; count multi-endpoint signal nets once.
    @test length(wired_connections) - 6 == 31
    # Six of these are mechanical; the shared CAN net counts as one signal connection.
    @test count(c -> !(c.captures[2] in ("w7", "w12", "w13", "w14", "w15", "w27")), connections) == 19
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
    car_schedule = _CAN.can_schedule(_CAN.Can10msStopBench(name = :car))
    @test car_schedule.load ≈ 0.1215
    @test [f.id for f in car_schedule.frames] == [128, 144, 160, 176, 177, 178, 179, 272, 768]
    @test [f.response_time for f in car_schedule.frames] ≈
        [0.30, 0.45, 0.60, 0.75, 0.90, 1.05, 1.20, 1.35, 1.35] ./ 1000
    counter = _CAN.CanBusBrake10msStopBench(name = :counter)
    @test _CAN.check_can(counter) === counter
    counter_schedule = _CAN.can_schedule(counter)
    @test counter_schedule.load ≈ 0.1495
    @test [f.id for f in counter_schedule.frames] == [112, 128, 144, 160, 176, 177, 178, 179, 192, 256, 272, 768]
    @test [f.response_time for f in counter_schedule.frames] ≈
        [0.28, 0.43, 0.58, 0.73, 0.88, 1.03, 1.18, 1.33, 1.48, 1.63, 1.78, 1.78] ./ 1000
    println("CAN car schedule: ", car_schedule)
    println("Bus-brake counterexample schedule: ", counter_schedule)
end
