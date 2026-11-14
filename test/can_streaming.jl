using DyadInterface
using ModelingToolkit
const CanV = VehicleSystemsComponents
const CanP = CanV.Vehicle.Planar
mutable struct RecordingCan
    frames::Vector{Tuple{Int,Vector{UInt8}}}
    closed::Bool
end
CanV.can_send(r::RecordingCan, id, bytes) = push!(r.frames, (id, copy(bytes)))
CanV.can_close(r::RecordingCan) = (r.closed = true)

@testset "CAN cruise stream and DBC" begin
    model = CanP.CanCruise(name = :model)
    layout = CanP.can_layout(model)
    mktemp() do path, io
        CanP.can_dbc(model, path)
        text = read(path, String)
        for f in layout.frames
            @test occursin("BO_ $(f.id) Frame_$(f.id): $(f.bytes) Dyad", text)
            for s in f.signals
                sign = s.signed ? "-" : "+"
                @test occursin("$(s.start_bit)|$(s.bits)@1$sign ($(s.scale),$(s.offset))", text)
            end
        end
    end
    recording = RecordingCan([], false)
    spec = CanV.RealtimeDriveSpec(; model, duration = 2.0, can_interface = "recording")
    result = DyadInterface.run_analysis(spec; open_can = _ -> recording, can_paced = false)
    sys = DyadInterface.symbolic_container(result)
    @test recording.closed
    for f in layout.frames
        received = filter(p -> first(p) == f.id, recording.frames)
        @test length(received) == floor(Int, spec.duration / f.period)
        for (k, (_, bytes)) in enumerate(received)
            decoded = CanP.can_decode(f, bytes)
            for (s, value) in zip(f.signals, decoded)
                wire = foldl(getproperty, s.wire_path; init = sys)
                expected = result.sol(k * f.period; idxs = wire)
                @test abs(value - expected) <= abs(s.scale) + 1e-8
            end
        end
    end
    println("Mock sample: ", recording.frames[1:8])
end

@testset "SocketCAN live loopback" begin
    pkg = Base.PkgId(Base.UUID("bffc1db9-6142-4b2c-b5cf-b017e7edc3de"), "CANBus")
    if !isdir("/sys/class/net/vcan0") || Base.locate_package(pkg) === nothing
        @test_skip false
    else
        Base.require(pkg)
        C = Base.loaded_modules[pkg]
        a = Base.invokelatest(C.Interface, Base.invokelatest(C.InterfaceConfig, C.SOCKETCAN, "vcan0", C.CAN_20, 500000))

        b = CanV.can_open("vcan0")
        try
            for k in 1:3
                Base.invokelatest(CanV.can_send, b, 0x6f0 + k, UInt8[k, 2, 3])
                frame = Base.invokelatest(C.recv, a; timeout_s = 1)
                @test frame !== nothing
                @test frame.id == 0x6f0 + k
                @test frame.data == UInt8[k, 2, 3]
            end
        finally
            Base.invokelatest(C.shutdown, a)
            Base.invokelatest(CanV.can_close, b)
        end
    end
end

@testset "Scripted CAN car signals" begin
    model = CanV.PlanarBEVCanScriptedDrive(name = :model)
    recording = RecordingCan([], false)
    spec = CanV.RealtimeDriveSpec(; model, duration = 30.0, can_interface = "recording")
    DyadInterface.run_analysis(spec; open_can = _ -> recording, can_paced = false)
    ranges = Dict{Int,Any}()
    for f in CanP.can_layout(model).frames
        values = [only(CanP.can_decode(f, b)) for (id, b) in recording.frames if id == f.id]
        @test length(values) == round(Int, spec.duration / f.period)
        ranges[f.id] = extrema(values)
    end
    @test ranges[112] == (0, 1)
    @test ranges[128][2] > 20
    @test ranges[768][2] > 20
    @test ranges[256][2] > 2000
    @test ranges[272][1] < 0 < ranges[272][2]
    @test recording.closed
end
