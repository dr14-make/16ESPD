# PQ24 drivetrain CAN encoding, independent of transport and wall-clock time.
module FabiaProtocol

export Bench, Echo, schedule, decode_echo!, setbits!, getbits, xorsum,
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
    teeth::Int = 48
    send_airbag::Bool = true
    # Without Verbauliste_1 the cluster ignores ABS, ASR, brake and airbag lamp bits.
    send_installed::Bool = true
    dimming::Int = 0
    pulses::Float64 = 0
    count::Dict{UInt32,Int} = Dict{UInt32,Int}()
end

const TIRE = 1.793
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

function bremse_2(b, t, dt)
    rev_s = b.kmh / 3.6 / TIRE
    b.pulses = mod(b.pulses + rev_s * 2 * b.teeth * dt, 2048)
    bytes = zeros(UInt8, 8); bytes[1] = 0x7F
    setbits!(bytes, 9, 15, round(Int, clamp(rev_s, 0, 65.278) / 0.002))
    setbits!(bytes, 40, 11, floor(Int, b.pulses))
    setbits!(bytes, 56, 6, b.teeth)
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

"(id, period s, builder); :bremse_2 takes the period as its third argument."
function schedule(b::Bench)
    frames = Any[
        (0x280, 0.010, motor_1), (0x288, 0.010, motor_2), (0x480, 0.020, motor_5),
        (0x1A0, 0.010, bremse_1), (0x4A0, 0.010, bremse_3), (0x5A0, 0.010, :bremse_2),
        (0x470, 0.050, bsg_kombi), (0x570, 0.100, bsg_last)]
    b.send_airbag && push!(frames, (0x050, 0.020, airbag_1))
    b.send_installed && append!(frames, [(0x5D8, 0.100, verbauliste_1), (0x5D0, 0.100, systeminfo_1)])
    return frames
end

"Build one transmitted frame and advance only its message counter."
function frame!(b::Bench, id, builder, t, interval)
    bytes = builder === :bremse_2 ? bremse_2(b, t, interval) : builder(b, t)
    b.count[UInt32(id)] = get(b.count, UInt32(id), 0) + 1
    return bytes
end

"Cluster echo from Kombi_1 0x320, Kombi_2 0x420 and Kombi_3 0x520."
Base.@kwdef mutable struct Echo
    kmh::Float64 = NaN
    shown_kmh::Float64 = NaN
    left::Bool = false
    right::Bool = false
    coolant::Float64 = NaN
    fault::Bool = false
    installed::UInt16 = 0
    frames::Int = 0
end

"Decode one payload without transport I/O; irrelevant ids/lengths/multiplexes leave state unchanged."
function decode_echo!(echo::Echo, id::Integer, d::AbstractVector{UInt8})
    if id == 0x320 && length(d) == 8
        raw, shown = getbits(d, 25, 15), getbits(d, 46, 10)
        echo.kmh = raw == 32767 ? NaN : raw * 0.01
        echo.shown_kmh = shown == 1023 ? NaN : shown * 0.32
        echo.left = getbits(d, 44, 1) == 1
        echo.right = getbits(d, 45, 1) == 1
        echo.frames += 1
    elseif id == 0x420 && length(d) == 8
        raw = getbits(d, 32, 8)
        echo.coolant = raw == 255 ? NaN : raw * 0.75 - 48
        echo.fault = getbits(d, 7, 1) == 1
    elseif id == 0x520 && length(d) == 8 && getbits(d, 14, 2) == 3
        echo.installed = getbits(d, 0, 14)
    end
    return echo
end

end # module FabiaProtocol
