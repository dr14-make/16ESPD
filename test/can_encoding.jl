using Test

# Pure layout/codec regression tests: no package load, compilation or simulation.
module CanEncodingUnit
include(joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "module.jl"))
end

@testset "CAN binary layout and codec" begin
    C = CanEncodingUnit
    signal(name, slot; id = 128, period = 0.01, lo = 0, hi = 255,
           scale = 1, offset = 0, signal_type = :real) =
        (; name, slot, id, period, net = "bus", n = 16, kind = :tx,
           raw_min = lo, raw_max = hi, scale, offset, signal_type,
           C._can_width(lo, hi)...)
    @test C._can_width(-1, 255) == (bits = 9, signed = true)
    @test C._can_width(0, 0) == (bits = 1, signed = false)
    @test C._can_width(typemin(Int64), typemax(Int64)).bits == 64
    @test C._can_width(0, typemax(UInt64)).bits == 64
    for bounds in ((0.5, 2), (2, 1), (0, Inf), (0, big(1) << 64))
        @test_throws ArgumentError C._can_width(bounds...)
    end
    signals = [signal("signed", 2; lo = -256, hi = 255, scale = 0.5, offset = 1),
               signal("flag", 1; hi = 1, signal_type = :boolean),
               signal("unsigned", 3; hi = 63)]
    frame = only(C._can_frames(signals))
    @test frame.bits == 16
    @test frame.bytes == 2
    @test [s.start_bit for s in frame.signals] == [0, 1, 10]
    bytes = C.can_encode(frame, [true, -0.5, 42])
    @test bytes == UInt8[0xfb, 0xab]
    @test C.can_decode(frame, bytes) == [true, -0.5, 42]
    @test C.can_decode(frame, C.can_encode(frame, [false, -1e6, 1e6])) == [false, -127, 63]
    @test C.can_decode(frame, C.can_encode(frame, [false, 1.25, 0])) == [false, 1.0, 0]
    @test_throws ArgumentError C.can_encode(frame, [1])
    @test_throws ArgumentError C.can_encode(frame, [true, NaN, 0])
    @test_throws ArgumentError C.can_decode(frame, [0])
    @test_throws ArgumentError C.can_decode(frame, [-1, 0])
    for (lo, hi) in ((typemin(Int64), typemax(Int64)), (0, typemax(UInt64)))
        f = only(C._can_frames([signal("wide", 1; lo, hi)]))
        @test C.can_decode(f, C.can_encode(f, [lo])) == [lo]
        @test C.can_decode(f, C.can_encode(f, [hi])) == [hi]
    end
    @test_throws ArgumentError C._can_frames([signal("a", 1), signal("b", 2; period = 0.02)])
    @test_throws ArgumentError C._can_frames([signal("a", 1; hi = typemax(UInt64)), signal("b", 2)])
end
