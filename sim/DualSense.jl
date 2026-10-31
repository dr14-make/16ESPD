"""
A Sony DualSense controller reached through its Linux `hidraw` node.

Input, rumble, adaptive triggers and the lightbar all travel as raw HID reports, so one device
file carries everything and no native library is needed. Report layouts follow the kernel's
`hid-playstation` driver; the trigger effect encodings are reverse-engineered and not published
by Sony.

The pad never reads or writes on its own: `poll!` drains whatever input has arrived and
`send!` writes the accumulated feedback as one report. The caller owns the clock.
"""
module DualSense

export Pad, PadState, open_pad, poll!, send!, rumble!, trigger!, lightbar!, player_leds!
export TriggerOff, Rigid, Section, Feedback, Vibration

const VENDOR = 0x054c
const PRODUCTS = (0x0ce6, 0x0df2)  # DualSense, DualSense Edge

const O_RDWR = Cint(0o2)
const O_NONBLOCK = Cint(0o4000)
const EAGAIN = 11

const USB_INPUT_ID = 0x01
const BT_INPUT_ID = 0x31
const USB_OUTPUT_LEN = 48
const BT_OUTPUT_LEN = 78

"""Trigger effect: no resistance."""
struct TriggerOff end

"""Trigger effect: constant resistance from `start` (0 released .. 1 pressed) to full travel."""
struct Rigid
    start::Float64
    force::Float64
end

"""Trigger effect: resistance only between `start` and `stop`, like a detent."""
struct Section
    start::Float64
    stop::Float64
    force::Float64
end

"""Trigger effect: resistance from zone `position` (0..9) onward, `strength` 0..1."""
struct Feedback
    position::Int
    strength::Float64
end

"""Trigger effect: the trigger buzzes from zone `position` (0..9) onward at `frequency` Hz."""
struct Vibration
    position::Int
    amplitude::Float64
    frequency::Int
end

const TriggerEffect = Union{TriggerOff,Rigid,Section,Feedback,Vibration}

"""Controller input, sticks in -1..1 with up and right positive, triggers in 0..1."""
struct PadState
    lx::Float64
    ly::Float64
    rx::Float64
    ry::Float64
    l2::Float64
    r2::Float64
    dpad::UInt8
    buttons::UInt32
    seq::UInt8
end

const BUTTONS = (
    square = 0x0000_0010, cross = 0x0000_0020, circle = 0x0000_0040, triangle = 0x0000_0080,
    l1 = 0x0000_0100, r1 = 0x0000_0200, l2 = 0x0000_0400, r2 = 0x0000_0800,
    create = 0x0000_1000, options = 0x0000_2000, l3 = 0x0000_4000, r3 = 0x0000_8000,
    ps = 0x0001_0000, touchpad = 0x0002_0000, mute = 0x0004_0000,
)

Base.getindex(s::PadState, b::Symbol) = (s.buttons & BUTTONS[b]) != 0

mutable struct Pad
    fd::Cint
    path::String
    bluetooth::Bool
    inbuf::Vector{UInt8}
    state::PadState
    motor_low::UInt8
    motor_high::UInt8
    left::TriggerEffect
    right::TriggerEffect
    rgb::NTuple{3,UInt8}
    players::UInt8
    bt_seq::UInt8
end

"""
    open_pad(path = nothing) -> Pad

Open the first DualSense found under `/sys/class/hidraw`, or the node at `path`.
"""
function open_pad(path::Union{Nothing,AbstractString} = nothing)
    node, bus = path === nothing ? find_node() : (path, bus_of(basename(path)))
    fd = ccall(:open, Cint, (Cstring, Cint), node, O_RDWR | O_NONBLOCK)
    fd < 0 && error("cannot open $node: ", Libc.strerror(Libc.errno()),
                    " (raw HID nodes are root-only without a udev rule)")
    neutral = PadState(0, 0, 0, 0, 0, 0, 0x08, 0, 0)
    pad = Pad(fd, node, bus == 0x0005, zeros(UInt8, 128), neutral,
              0, 0, TriggerOff(), TriggerOff(), (0, 0, 64), 0b00100, 0)
    finalizer(close, pad)
    return pad
end

function find_node()
    for dev in readdir("/sys/class/hidraw")
        bus, vid, pid = hid_id(dev)
        vid == VENDOR && pid in PRODUCTS && return ("/dev/" * dev, bus)
    end
    error("no DualSense found under /sys/class/hidraw")
end

bus_of(dev) = hid_id(dev)[1]

function hid_id(dev)
    for line in eachline("/sys/class/hidraw/$dev/device/uevent")
        startswith(line, "HID_ID=") || continue
        bus, vid, pid = split(line[8:end], ':')
        return parse(UInt16, bus; base = 16), parse(UInt16, vid; base = 16),
               parse(UInt16, pid; base = 16)
    end
    return (0x0000, 0x0000, 0x0000)
end

function Base.close(pad::Pad)
    pad.fd < 0 && return
    pad.motor_low = pad.motor_high = 0
    pad.left = pad.right = TriggerOff()
    pad.players = 0
    try
        send!(pad)
    catch
    end
    ccall(:close, Cint, (Cint,), pad.fd)
    pad.fd = -1
    return
end

"""
    poll!(pad) -> PadState

Drain every input report that has arrived and return the newest. Never blocks; returns the
previous state when nothing new is waiting.
"""
function poll!(pad::Pad)
    while true
        n = ccall(:read, Cssize_t, (Cint, Ptr{UInt8}, Csize_t), pad.fd, pad.inbuf, length(pad.inbuf))
        if n < 0
            Libc.errno() == EAGAIN && break
            error("read from $(pad.path) failed: ", Libc.strerror(Libc.errno()))
        end
        n == 0 && break
        parsed = parse_input(pad.inbuf, n)
        parsed === nothing || (pad.state = parsed)
    end
    return pad.state
end

function parse_input(r, n)
    # Bluetooth reports carry one extra header byte before the same payload.
    if r[1] == USB_INPUT_ID && n >= 11
        o = 1
    elseif r[1] == BT_INPUT_ID && n >= 12
        o = 2
    else
        return nothing
    end
    axis(b) = clamp((Int(b) - 128) / 127.5, -1.0, 1.0)
    b0, b1, b2 = r[o+8], r[o+9], r[o+10]
    return PadState(axis(r[o+1]), -axis(r[o+2]), axis(r[o+3]), -axis(r[o+4]),
                    r[o+5] / 255, r[o+6] / 255, b0 & 0x0f,
                    UInt32(b0 & 0xf0) | UInt32(b1) << 8 | UInt32(b2 & 0x07) << 16, r[o+7])
end

"""
    rumble!(pad; low = 0, high = 0)

Set the two body motors, 0..1. `low` is the heavy left motor, `high` the light right one.
Takes effect at the next `send!`.
"""
function rumble!(pad::Pad; low = 0.0, high = 0.0)
    pad.motor_low = to_byte(low)
    pad.motor_high = to_byte(high)
    return pad
end

"""
    trigger!(pad, side, effect)

Set the adaptive-trigger effect on `:left` (L2) or `:right` (R2). Takes effect at the next `send!`.
"""
function trigger!(pad::Pad, side::Symbol, effect::TriggerEffect)
    side === :left ? (pad.left = effect) :
    side === :right ? (pad.right = effect) : throw(ArgumentError("side must be :left or :right"))
    return pad
end

"""
    lightbar!(pad, r, g, b)

Set the lightbar color, components 0..1. Takes effect at the next `send!`.
"""
function lightbar!(pad::Pad, r, g, b)
    pad.rgb = (to_byte(r), to_byte(g), to_byte(b))
    return pad
end

"""Set the five player LEDs from the low five bits of `mask`."""
function player_leds!(pad::Pad, mask::Integer)
    pad.players = UInt8(mask & 0x1f)
    return pad
end

to_byte(x) = round(UInt8, 255 * clamp(Float64(x), 0.0, 1.0))

"""
    send!(pad)

Write the current rumble, trigger, lightbar and player-LED settings as one output report.
"""
function send!(pad::Pad)
    report = pad.bluetooth ? bt_report(pad) : usb_report(pad)
    n = ccall(:write, Cssize_t, (Cint, Ptr{UInt8}, Csize_t), pad.fd, report, length(report))
    n == length(report) || error("write to $(pad.path) failed: ", Libc.strerror(Libc.errno()))
    return pad
end

function usb_report(pad::Pad)
    report = zeros(UInt8, USB_OUTPUT_LEN)
    report[1] = 0x02
    fill_common!(view(report, 2:USB_OUTPUT_LEN), pad)
    return report
end

function bt_report(pad::Pad)
    report = zeros(UInt8, BT_OUTPUT_LEN)
    report[1] = 0x31
    report[2] = pad.bt_seq << 4
    report[3] = 0x10
    pad.bt_seq = (pad.bt_seq + 0x01) & 0x0f
    fill_common!(view(report, 4:50), pad)
    # The controller drops Bluetooth reports whose CRC, seeded with the HID output header, is wrong.
    crc = crc32(UInt8[0xa2; report[1:end-4]])
    report[end-3:end] .= reinterpret(UInt8, [htol(crc)])
    return report
end

# Offsets (1-based) into the 47-byte block the kernel calls dualsense_output_report_common.
function fill_common!(c, pad::Pad)
    c[1] = 0x01 | 0x02 | 0x04 | 0x08   # compatible vibration, haptics select, R2 and L2 effects
    c[2] = 0x04 | 0x10                 # lightbar, player LEDs
    c[3] = pad.motor_high
    c[4] = pad.motor_low
    c[11:21] .= encode(pad.right)
    c[22:32] .= encode(pad.left)
    # Firmware from 2.21 reads rumble only through this flag, older firmware only through c[1].
    c[39] = 0x04
    c[44] = pad.players
    c[45], c[46], c[47] = pad.rgb
    return c
end

function encode(::TriggerOff)
    e = zeros(UInt8, 11)
    e[1] = 0x05
    return e
end

function encode(t::Rigid)
    e = zeros(UInt8, 11)
    e[1] = 0x01
    e[2] = to_byte(t.start)
    e[3] = to_byte(t.force)
    return e
end

function encode(t::Section)
    e = zeros(UInt8, 11)
    e[1] = 0x02
    e[2] = to_byte(t.start)
    e[3] = to_byte(t.stop)
    e[4] = to_byte(t.force)
    return e
end

function encode(t::Feedback)
    t.strength <= 0 && return encode(TriggerOff())
    zones, strengths = zone_bits(t.position, t.strength)
    e = zeros(UInt8, 11)
    e[1] = 0x21
    e[2:3] .= reinterpret(UInt8, [htol(zones)])
    e[4:7] .= reinterpret(UInt8, [htol(strengths)])
    return e
end

function encode(t::Vibration)
    (t.amplitude <= 0 || t.frequency <= 0) && return encode(TriggerOff())
    zones, strengths = zone_bits(t.position, t.amplitude)
    e = zeros(UInt8, 11)
    e[1] = 0x26
    e[2:3] .= reinterpret(UInt8, [htol(zones)])
    e[4:7] .= reinterpret(UInt8, [htol(strengths)])
    e[10] = UInt8(clamp(t.frequency, 1, 255))
    return e
end

# Ten trigger zones, each with a 3-bit level stored as level-1, active from `position` to the end.
function zone_bits(position, level)
    lvl = UInt32(clamp(round(Int, 8 * level), 1, 8) - 1)
    zones = UInt16(0)
    strengths = UInt32(0)
    for i in clamp(position, 0, 9):9
        zones |= UInt16(1) << i
        strengths |= lvl << (3i)
    end
    return zones, strengths
end

const CRC_TABLE = let
    t = Vector{UInt32}(undef, 256)
    for n in 0:255
        c = UInt32(n)
        for _ in 1:8
            c = isodd(c) ? 0xedb88320 ⊻ (c >> 1) : c >> 1
        end
        t[n+1] = c
    end
    t
end

function crc32(data)
    c = 0xffffffff
    for b in data
        c = CRC_TABLE[((c ⊻ b) & 0xff)+1] ⊻ (c >> 8)
    end
    return ~c
end

end
