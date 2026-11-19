# PQ24 drivetrain CAN encoding, independent of transport and wall-clock time.
module FabiaProtocol

export Bench, frame_schedule, frame!, setbits!, getbits, xorsum,
    motor_1, motor_2, motor_5, bremse_1, bremse_2, bremse_3,
    bsg_kombi, bsg_last, airbag_1, verbauliste_1, systeminfo_1

"Write `value` into `bytes` at Intel start bit `start` with `len` bits."
function setbits!(bytes::Vector{UInt8}, start::Int, len::Int, value::Integer)
    v = UInt64(value) & ((UInt64(1) << len) - 1)
    for k in 0:len-1
        bit = start + k
        mask = UInt8(1) << (bit % 8)
        bytes[bit ÷ 8 + 1] = (v >> k) & 1 == 1 ? bytes[bit ÷ 8 + 1] | mask : bytes[bit ÷ 8 + 1] & ~mask
    end
    return bytes
end
getbits(bytes, start, len) = sum(Int((bytes[(start + k) ÷ 8 + 1] >> ((start + k) % 8)) & 1) << k for k in 0:len-1)
xorsum(bytes) = reduce(xor, bytes; init = 0x00)

"Bench state read by builders; counters advance only after a frame is sent."
Base.@kwdef mutable struct Bench
    rpm::Float64 = 0
    kmh::Float64 = 0
    coolant::Float64 = 90
    left::Bool = false
    right::Bool = false
    hazard::Bool = false
    charging::Bool = false
    abs_lamp::Bool = false
    asr_lamp::Bool = false
    brake_lamp::Bool = false
    mil::Bool = false
    epc::Bool = false
    glow::Bool = false
    airbag_lamp::Bool = false
    dimming::Int = 0
    pulses::Float64 = 0
    # Bremse_2 integrates distance over the true interval since its previous frame.
    last_pulse_t::Float64 = 0
    count::Dict{UInt32,Int} = Dict{UInt32,Int}()
end

const TIRE = 1.793
const TEETH = 48
blink_on(t) = mod(t, 0.66) < 0.33
motor_1(b, t) = setbits!(zeros(UInt8, 8), 16, 16, round(Int, clamp(b.rpm, 0, 16256) * 4))

function motor_2(b, t)
    mux = (0x0C, 0x40, 0x8F, 0xC0)[mod(get(b.count, 0x288, 0) ÷ 4, 4) + 1]
    bytes = zeros(UInt8, 8); bytes[1] = mux
    setbits!(bytes, 8, 8, round(Int, clamp((b.coolant + 48) / 0.75, 0, 254)))
    setbits!(bytes, 20, 1, 1)
    return bytes
end

function motor_5(b, t)
    bytes = zeros(UInt8, 8); bytes[1] = 0x94
    setbits!(bytes, 9, 1, b.glow); setbits!(bytes, 10, 1, b.epc); setbits!(bytes, 11, 1, b.mil)
    bytes[8] = xorsum(bytes[1:7])
    return bytes
end

function bremse_1(b, t)
    bytes = zeros(UInt8, 8)
    setbits!(bytes, 8, 1, b.abs_lamp); setbits!(bytes, 9, 1, b.asr_lamp); setbits!(bytes, 10, 1, b.brake_lamp)
    setbits!(bytes, 17, 15, round(Int, clamp(b.kmh, 0, 326) * 100))
    bytes[5] = 0xFE; bytes[6] = 0xFE
    setbits!(bytes, 56, 4, mod(get(b.count, 0x1A0, 0), 16))
    return bytes
end

function bremse_3(b, t)
    bytes = zeros(UInt8, 8)
    for s in (1, 17, 33, 49)
        setbits!(bytes, s, 15, round(Int, clamp(b.kmh, 0, 326) * 100))
    end
    return bytes
end

function bremse_2(b, t)
    rev_s = b.kmh / 3.6 / TIRE
    b.pulses = mod(b.pulses + rev_s * 2 * TEETH * (t - b.last_pulse_t), 2048)
    b.last_pulse_t = t
    bytes = zeros(UInt8, 8); bytes[1] = 0x7F
    setbits!(bytes, 9, 15, round(Int, clamp(rev_s, 0, 65.278) / 0.002))
    setbits!(bytes, 40, 11, floor(Int, b.pulses))
    setbits!(bytes, 56, 6, TEETH)
    return bytes
end

function bsg_kombi(b, t)
    bytes = zeros(UInt8, 5)
    on = blink_on(t)
    setbits!(bytes, 0, 1, (b.left || b.hazard) && on)
    setbits!(bytes, 1, 1, (b.right || b.hazard) && on)
    setbits!(bytes, 3, 1, b.hazard)
    setbits!(bytes, 7, 1, b.charging)
    setbits!(bytes, 16, 7, clamp(b.dimming, 0, 100))
    bytes[4] = 0xFF
    return bytes
end

bsg_last(b, t) = UInt8[0x03, 0x00, round(UInt8, (13.8 - 5) / 0.05), 0x00]

function airbag_1(b, t)
    bytes = zeros(UInt8, 4)
    setbits!(bytes, 8, 1, b.airbag_lamp)
    setbits!(bytes, 20, 4, mod(get(b.count, 0x050, 0), 16))
    bytes[4] = xorsum(bytes[1:3])
    return bytes
end

# Motor, ABS, airbag and body module fitted; list valid, Škoda A0.
verbauliste_1(b, t) = UInt8[0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
systeminfo_1(b, t) = UInt8[0x80, 0x32, 0x40, 0x00, 0x00, 0x41]

# Without Verbauliste_1 and Systeminfo_1 the cluster ignores the ABS, ASR, brake and airbag lamps.
"(id, period s, builder) for every frame the cluster needs."
const frame_schedule = (
    (0x280, 0.010, motor_1), (0x288, 0.010, motor_2), (0x480, 0.020, motor_5),
    (0x1A0, 0.010, bremse_1), (0x4A0, 0.010, bremse_3), (0x5A0, 0.010, bremse_2),
    (0x470, 0.050, bsg_kombi), (0x570, 0.100, bsg_last), (0x050, 0.020, airbag_1),
    (0x5D8, 0.100, verbauliste_1), (0x5D0, 0.100, systeminfo_1))

"Build one transmitted frame and advance only its message counter."
function frame!(b::Bench, id, builder, t)
    bytes = builder(b, t)
    b.count[UInt32(id)] = get(b.count, UInt32(id), 0) + 1
    return bytes
end

end # module FabiaProtocol
