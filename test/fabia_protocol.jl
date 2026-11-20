using Test
using VehicleSystemsComponents.FabiaProtocol

# The confirmed bench bytes override the reference's extra Motor_2 fields.
@testset "Fabia protocol golden frames" begin
    b = Bench(rpm = 3000, kmh = 100)
    @test motor_1(b, 0) == UInt8[0, 0, 0xe0, 0x2e, 0, 0, 0, 0]
    @test bremse_1(b, 0) == UInt8[0, 0, 0x20, 0x4e, 0xfe, 0xfe, 0, 0]
    b.abs_lamp = true
    @test bremse_1(b, 0) == UInt8[0, 1, 0x20, 0x4e, 0xfe, 0xfe, 0, 0]
    @test bremse_2(b, 0.01) == UInt8[0x7f, 0x84, 0x3c, 0, 0, 0x0e, 0, 0x30]

    @test bremse_3(b, 0) == UInt8[0x20, 0x4e, 0x20, 0x4e, 0x20, 0x4e, 0x20, 0x4e]
    for (n, mux) in enumerate(UInt8[0x0c, 0x0c, 0x0c, 0x0c,
            0x40, 0x40, 0x40, 0x40, 0x8f, 0x8f, 0x8f, 0x8f,
            0xc0, 0xc0, 0xc0, 0xc0, 0x0c])
        b.count[0x288] = n - 1
        @test motor_2(b, 0) == UInt8[mux, 0xb8, 0x10, 0, 0, 0, 0, 0]
    end
    b.abs_lamp = b.asr_lamp = b.brake_lamp = true
    for (count, last) in ((0, 0x00), (15, 0x0f), (16, 0x00), (17, 0x01))
        b.count[0x1a0] = count
        @test bremse_1(b, 0) == UInt8[0, 7, 0x20, 0x4e, 0xfe, 0xfe, 0, last]
    end
    @test motor_5(b, 0) == UInt8[0x94, 0, 0, 0, 0, 0, 0, 0x94]
    for (field, bit, checksum) in ((:glow, 0x02, 0x96), (:epc, 0x04, 0x90), (:mil, 0x08, 0x9c))
        setproperty!(b, field, true)
        @test motor_5(b, 0) == UInt8[0x94, bit, 0, 0, 0, 0, 0, checksum]
        setproperty!(b, field, false)
    end
    b.airbag_lamp = true
    for (count, nibble, checksum) in ((0, 0x00, 0x01), (15, 0xf0, 0xf1), (16, 0x00, 0x01))
        b.count[0x050] = count
        @test airbag_1(b, 0) == UInt8[0, 1, nibble, checksum]
    end
    @test verbauliste_1(b, 0) == UInt8[0x55, 0, 0, 0, 0, 0, 0, 0]
    @test systeminfo_1(b, 0) == UInt8[0x80, 0x32, 0x40, 0, 0, 0x41]
    @test bsg_last(b, 0) == UInt8[3, 0, 0xb0, 0]
    b.left = true
    @test bsg_kombi(b, 0) == UInt8[1, 0, 0, 0xff, 0]
    @test bsg_kombi(b, 0.33) == UInt8[0, 0, 0, 0xff, 0]
    b.left = false; b.right = true
    @test bsg_kombi(b, 0) == UInt8[2, 0, 0, 0xff, 0]
    b.hazard = true; b.charging = true; b.dimming = 100
    @test bsg_kombi(b, 0) == UInt8[0x8b, 0, 0x64, 0xff, 0]
    @test bsg_kombi(b, 0.33) == UInt8[0x88, 0, 0x64, 0xff, 0]

    p = Bench(kmh = 64.548, pulses = 2045)
    @test bremse_2(p, 0.01) == UInt8[0x7f, 0x10, 0x27, 0, 0, 6, 0, 0x30]
    @test p.pulses ≈ 6.6
    @test bremse_2(p, 0.02) == UInt8[0x7f, 0x10, 0x27, 0, 0, 16, 0, 0x30]
    @test p.pulses ≈ 16.2
    @test isempty(p.count) # Builders do not advance sent-frame counters.
end

@testset "Fabia schedule" begin
    @test [(id, period) for (id, period, _) in frame_schedule] == [
        (0x280, .010), (0x288, .010), (0x480, .020), (0x1a0, .010),
        (0x4a0, .010), (0x5a0, .010), (0x470, .050), (0x570, .100),
        (0x050, .020), (0x5d8, .100), (0x5d0, .100)]
    @test [build for (_, _, build) in frame_schedule] == [motor_1, motor_2, motor_5,
        bremse_1, bremse_3, bremse_2, bsg_kombi, bsg_last, airbag_1, verbauliste_1, systeminfo_1]
    @test getbits(UInt8[0xff, 0x7f], 0, 15) == 32767
end
