# Bench helpers for a Škoda Fabia (PQ24) cluster on 500 kbit/s drivetrain CAN.
# Layouts from the VW PQ24 drivetrain CAN matrix V4.1.1. All signals are Intel, unsigned.
(dirname(@__DIR__)) in LOAD_PATH || push!(LOAD_PATH, dirname(@__DIR__))
import CANBus
using Printf

const IFACE = get(ENV, "FABIA_CAN", "can0")
const RESULTS = joinpath(@__DIR__, "results.txt")

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
getbits(bytes, start, len) = sum(((bytes[(start + k) ÷ 8 + 1] >> ((start + k) % 8)) & 1) << k for k in 0:len-1)

xorsum(bytes) = reduce(xor, bytes; init = 0x00)

"Bench state the frame builders read; tests change it while the sender runs."
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
    # Without Verbauliste_1 this cluster ignores the ABS, ASR, brake and airbag lamp bits.
    send_installed::Bool = true
    dimming::Int = 0
    pulses::Float64 = 0
    # Frames sent per id; drives each message's own counter and multiplex.
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

# Verbauliste_1: motor, ABS, airbag and body module fitted. Systeminfo_1: list valid, Škoda A0.
verbauliste_1(b, t) = UInt8[0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
systeminfo_1(b, t) = UInt8[0x80, 0x32, 0x40, 0x00, 0x00, 0x41]

"(id, period s, builder) for every frame the bench sends."
function schedule(b::Bench)
    frames = Any[
        (0x280, 0.010, motor_1), (0x288, 0.010, motor_2), (0x480, 0.020, motor_5),
        (0x1A0, 0.010, bremse_1), (0x4A0, 0.010, bremse_3), (0x5A0, 0.010, :bremse_2),
        (0x470, 0.050, bsg_kombi), (0x570, 0.100, bsg_last)]
    b.send_airbag && push!(frames, (0x050, 0.020, airbag_1))
    b.send_installed && append!(frames, [(0x5D8, 0.100, verbauliste_1), (0x5D0, 0.100, systeminfo_1)])
    return frames
end

"Cluster echo from Kombi_1 0x320 and Kombi_2 0x420."
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

function listen!(echo::Echo, iface, running)
    while running[]
        f = CANBus.recv(iface; timeout_s = 0.1)
        f === nothing && continue
        d = f.data
        if f.id == 0x320 && length(d) == 8
            raw, shown = getbits(d, 25, 15), getbits(d, 46, 10)
            echo.kmh = raw == 32767 ? NaN : raw * 0.01
            echo.shown_kmh = shown == 1023 ? NaN : shown * 0.32
            echo.left = getbits(d, 44, 1) == 1
            echo.right = getbits(d, 45, 1) == 1
            echo.frames += 1
        elseif f.id == 0x420 && length(d) == 8
            raw = getbits(d, 32, 8)
            echo.coolant = raw == 255 ? NaN : raw * 0.75 - 48
            echo.fault = getbits(d, 7, 1) == 1
        elseif f.id == 0x520 && length(d) == 8 && getbits(d, 14, 2) == 3
            echo.installed = getbits(d, 0, 14)
        end
    end
end

open_iface() = CANBus.Interface(CANBus.InterfaceConfig(CANBus.SOCKETCAN, IFACE, CANBus.CAN_20, 500_000))

"""
    bench(test; only = nothing, kwargs...)

Run `test(b, echo)` while every frame in `schedule(b)` is sent at its period on `IFACE`
(`FABIA_CAN` env, default can0), decoding the cluster's replies into `echo`. `only` restricts the
frames to a list of ids; `kwargs` set `Bench` fields.
"""
function bench(test::Function; only = nothing, kwargs...)
    b = Bench(; kwargs...)
    echo = Echo()
    tx, rx = open_iface(), open_iface()
    running = Ref(true)
    t0 = time()
    sender = @async begin
        frames = filter(f -> only === nothing || f[1] in only, schedule(b))
        println("sending on $IFACE: ", join((string(f[1]; base = 16) for f in frames), ", "))
        due = fill(0.0, length(frames))
        while running[]
            t = time() - t0
            for (i, (id, period, build)) in enumerate(frames)
                t >= due[i] || continue
                bytes = build === :bremse_2 ? bremse_2(b, t, period) : build(b, t)
                CANBus.send(tx, CANBus.Frame(UInt32(id), bytes))
                # Skip missed slots rather than bursting to catch up after a pause.
                due[i] = max(due[i] + period, t)
                b.count[id] = get(b.count, id, 0) + 1
            end
            sleep(max(0.001, minimum(due) - (time() - t0)))
        end
    end
    listener = @async listen!(echo, rx, running)
    try
        test(b, echo)
    finally
        running[] = false
        wait(sender); wait(listener)
        CANBus.shutdown(tx); CANBus.shutdown(rx)
    end
end

status(echo) = @sprintf("cluster: speed %.1f km/h (shown %.1f), coolant %.0f °C, blinker L%d R%d, fault %d, installed ABS %d airbag %d",
    echo.kmh, echo.shown_kmh, echo.coolant, echo.left, echo.right, echo.fault,
    (echo.installed >> 2) & 1, (echo.installed >> 4) & 1)

"Hold a step for `seconds`, printing the cluster echo, then ask the operator what they saw."
function step(name, echo, seconds; ask = true)
    println("\n>>> ", name)
    t_end = time() + seconds
    while time() < t_end
        sleep(1.0)
        println("    ", status(echo))
    end
    ask || return
    print("    Did the dashboard show it? [y/n/comment]: ")
    answer = something(readline(), "")
    open(RESULTS, "a") do io
        println(io, "$(basename(PROGRAM_FILE)) | $name | $answer | $(status(echo))")
    end
end
