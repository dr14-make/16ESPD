using SHA

function fabia_frame_fingerprint(frames)
    bytes = UInt8[]
    for (id, payload) in frames
        append!(bytes, UInt8[(id >> shift) & 255 for shift in (0, 8, 16, 24)])
        append!(bytes, payload)
    end
    bytes2hex(sha256(bytes))
end


const FP = CanV.FabiaProtocol

@testset "Fabia scripted cluster stream" begin
    model = CanV.PlanarBEVFabiaScriptedDrive(name = :model)
    recording = RecordingCan([], false)
    spec = CanV.RealtimeDriveSpec(; model, duration = 36.0, frame = .01, can_interface = "recording")
    result = DyadInterface.run_analysis(spec; open_can = _ -> recording, can_paced = false)
    sys = DyadInterface.symbolic_container(result)
    @test recording.closed
    @test fabia_frame_fingerprint(recording.frames) ==
        "6ffd492aaa990f4b63434674692518b8d699a399d684cca5be32a19f69b4c3a0"
    payloads(id) = [b for (key, b) in recording.frames if key == id]
    for (id, period, _) in FP.schedule(FP.Bench())
        @test length(payloads(id)) == round(Int, spec.duration / period)
    end
    for (id, start, period) in ((0x1a0, 56, .01), (0x050, 20, .02))
        @test [FP.getbits(b, start, 4) for b in payloads(id)] ==
            [mod(k - 1, 16) for k in 1:round(Int, 36 / period)]
    end
    for (k, b) in enumerate(payloads(0x1a0))
        expected = result.sol(k * .01; idxs = sys.cluster.display.speed_value) * 3.6
        @test abs(FP.getbits(b, 17, 15) * .01 - expected) <= .010001
        @test FP.getbits(b, 8, 1) == 0
    end
    for (k, b) in enumerate(payloads(0x280))
        expected = result.sol(k * .01; idxs = sys.cluster.display.rpm_value)
        @test abs(FP.getbits(b, 16, 16) / 4 - expected) <= .250001
    end
    pulses = 0.0
    for (k, b) in enumerate(payloads(0x5a0))
        speed = result.sol(k * .01; idxs = sys.cluster.display.speed_value)
        pulses = mod(pulses + speed / FP.TIRE * 96 * .01, 2048)
        @test abs(FP.getbits(b, 40, 11) - floor(Int, pulses)) <= 1
    end

    body = payloads(0x470)
    @test all(FP.getbits(b, 16, 7) == 100 for b in body)

    for (k, b) in enumerate(body)
        t = k * .05
        if 12.05 < t < 17.95
            # Floating-point frame times can straddle the exact blink edge.
            if min(mod(t, .33), .33 - mod(t, .33)) > 1e-8
                @test FP.getbits(b, 0, 1) == FP.blink_on(t)
            end
            @test FP.getbits(b, 1, 1) == 0
        end
    end
    left = [FP.getbits(body[k], 0, 1) for k in 241:359]
    @test 16 <= count(!=(0), diff(left)) <= 20
    @test any(FP.getbits(b, 3, 1) == 1 for b in body[481:600])
    @test all(FP.getbits(b, 3, 1) == 0 for b in body[1:470])
    asr = [FP.getbits(b, 9, 1) for b in payloads(0x1a0)[2401:2800]]
    @test any(==(1), asr)
    @test count(!=(0), diff(asr)) >= 10
    @test all(b == FP.verbauliste_1(FP.Bench(), 0) for b in payloads(0x5d8))
    @test maximum(result.sol[sys.cluster.display.rpm_value]) < 6000
    @test abs(result.sol(36; idxs = sys.cluster.display.speed_value)) < .1
    println("Fabia tachometer range: ", extrema(result.sol[sys.cluster.display.rpm_value]))
end

@testset "Fabia paced SocketCAN stream" begin
    sim = joinpath(@__DIR__, "..", "sim")
    sim in LOAD_PATH || push!(LOAD_PATH, sim)
    pkg = Base.PkgId(Base.UUID("bffc1db9-6142-4b2c-b5cf-b017e7edc3de"), "CANBus")
    if !isdir("/sys/class/net/vcan0") || Base.locate_package(pkg) === nothing
        @test_skip false
    else
        metrics = Ref{Any}()
        function measure_drive(integ, sys, spec)
            stats = CanV.unpaced_drive!(integ, sys, spec)
            stream = task_local_storage(:vehicle_can_stream)
            metrics[] = (; sent = stream.sent, late = stream.late,
                max_lateness = stream.max_lateness, wall = stats.wall, simulated = integ.t,
                counts = Dict(f.id => stream.ticks[i] - 1 for (i, f) in enumerate(stream.layout.frames)))
            return stats
        end
        model = CanV.PlanarBEVFabiaScriptedDrive(name = :model)
        spec = CanV.RealtimeDriveSpec(; model, duration = 36., can_interface = "vcan0")
        DyadInterface.run_analysis(spec; run_drive = measure_drive)
        m = metrics[]
        @test m.sent == 41760
        @test .85 < m.simulated / m.wall < 1.05
        for (id, period, _) in FP.schedule(FP.Bench())
            @test m.counts[id] == round(Int, 36 / period)
        end
        println("Fabia vcan0 timing: ", m, " real_time_factor=", m.simulated / m.wall)
    end
end


@testset "Fabia by-hand headless mock stream" begin
    model = CanV.PlanarBEVByHandFabia(name = :model)
    recording = RecordingCan([], false)
    spec = CanV.RealtimeDriveSpec(; model, duration = 10.0, frame = .01,
        window = false, can_interface = "recording")
    result = DyadInterface.run_analysis(spec; open_can = _ -> recording, can_paced = false)
    sys = DyadInterface.symbolic_container(result)
    @test recording.closed
    @test fabia_frame_fingerprint(recording.frames) ==
        "828fb69876a0ba9f631c3b8651c6902df8be024ebd9e921e4b827afd407a24d0"
    for (id, period, _) in FP.schedule(FP.Bench())
        @test count(frame -> first(frame) == id, recording.frames) == round(Int, 10 / period)
    end
    speed_frames = [payload for (id, payload) in recording.frames if id == 0x1a0]
    for (k, payload) in enumerate(speed_frames)
        expected = max(0., result.sol(k * .01; idxs = sys.vehicle.motion.vx)) * 3.6
        @test abs(FP.getbits(payload, 17, 15) * .01 - expected) <= .010001
    end
end

include("fabia_canvas.jl")
