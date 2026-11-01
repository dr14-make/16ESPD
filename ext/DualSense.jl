"""
SDL controller transport and DualSense effects. No device is opened on import.
The caller owns polling and sending; close and process exit quiet all open pads.
"""
module DualSense
using SimpleDirectMediaLayer.LibSDL2
export Pad, PadState, open_pad, poll!, send!, quiet!, rumble!, trigger!, lightbar!, player_leds!
export TriggerOff, Rigid, Section, Feedback, Vibration
const EFFECT_LEN = 47
const RUMBLE_MS = 250
struct TriggerOff end
struct Rigid
    start::Float64
    force::Float64
end
struct Section
    start::Float64
    stop::Float64
    force::Float64
end
struct Feedback
    position::Int
    strength::Float64
end
struct Vibration
    position::Int
    amplitude::Float64
    frequency::Int
end
const TriggerEffect = Union{TriggerOff,Rigid,Section,Feedback,Vibration}
struct PadState
    lx::Float64
    ly::Float64
    rx::Float64
    ry::Float64
    l2::Float64
    r2::Float64
    dpad::UInt8
    buttons::UInt32
end
const BUTTONS = (
    square = 0x0000_0010, cross = 0x0000_0020, circle = 0x0000_0040, triangle = 0x0000_0080,
    l1 = 0x0000_0100, r1 = 0x0000_0200, l2 = 0x0000_0400, r2 = 0x0000_0800,
    create = 0x0000_1000, options = 0x0000_2000, l3 = 0x0000_4000, r3 = 0x0000_8000,
    ps = 0x0001_0000, touchpad = 0x0002_0000, mute = 0x0004_0000)
const SDL_BUTTONS = (
    square = SDL_CONTROLLER_BUTTON_X, cross = SDL_CONTROLLER_BUTTON_A,
    circle = SDL_CONTROLLER_BUTTON_B, triangle = SDL_CONTROLLER_BUTTON_Y,
    l1 = SDL_CONTROLLER_BUTTON_LEFTSHOULDER, r1 = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
    create = SDL_CONTROLLER_BUTTON_BACK, options = SDL_CONTROLLER_BUTTON_START,
    l3 = SDL_CONTROLLER_BUTTON_LEFTSTICK, r3 = SDL_CONTROLLER_BUTTON_RIGHTSTICK,
    ps = SDL_CONTROLLER_BUTTON_GUIDE, touchpad = SDL_CONTROLLER_BUTTON_TOUCHPAD,
    mute = SDL_CONTROLLER_BUTTON_MISC1)
const TRIGGER_PRESSED = 0.1
Base.getindex(s::PadState, b::Symbol) = (s.buttons & BUTTONS[b]) != 0
mutable struct Pad
    gc::Ptr{SDL_GameController}
    path::String
    dualsense::Bool
    state::PadState
    motor_low::UInt8
    motor_high::UInt8
    left::TriggerEffect
    right::TriggerEffect
    rgb::NTuple{3,UInt8}
    players::UInt8
    effect::Vector{UInt8}
    status::Cint
end
# SDL stays initialized so a warm session can reopen pads.
function init_sdl()
    SDL_WasInit(SDL_INIT_GAMECONTROLLER) != 0 && return
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5, "1")
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE, "1")
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1")
    SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) == 0 ||
        error("SDL controller init failed: ", sdl_error())
    SDL_JoystickEventState(SDL_IGNORE)
    SDL_GameControllerEventState(SDL_IGNORE)
    return
end
sdl_error() = unsafe_string(SDL_GetError())
is_dualsense(index) = SDL_GameControllerTypeForIndex(index) == SDL_CONTROLLER_TYPE_PS5
const OPEN_PADS = Set{Pad}()
const EXIT_HOOK = Ref(false)
function open_pad(index::Union{Nothing,Integer} = nothing)
    init_sdl()
    SDL_GameControllerUpdate()
    if index === nothing
        candidates = filter(i -> SDL_IsGameController(i) == SDL_TRUE, 0:SDL_NumJoysticks()-1)
        isempty(candidates) && error("no game controller found")
        index = candidates[something(findfirst(is_dualsense, candidates), 1)]
    end
    gc = SDL_GameControllerOpen(index)
    gc == C_NULL && error("cannot open controller $index: ", sdl_error())
    name = unsafe_string(SDL_GameControllerName(gc))
    p = SDL_GameControllerPath(gc)
    path = p == C_NULL ? name : "$name ($(unsafe_string(p)))"
    neutral = PadState(0, 0, 0, 0, 0, 0, 0x08, 0)
    pad = Pad(gc, path, SDL_GameControllerGetType(gc) == SDL_CONTROLLER_TYPE_PS5, neutral,
        0, 0, TriggerOff(), TriggerOff(), (0, 0, 64), 0b00100, zeros(UInt8, EFFECT_LEN), 0)
    finalizer(close, pad)
    push!(OPEN_PADS, pad)
    if !EXIT_HOOK[]
        atexit(() -> foreach(close, collect(OPEN_PADS)))
        EXIT_HOOK[] = true
    end
    return pad
end
function Base.close(pad::Pad)
    pad.gc == C_NULL && return
    delete!(OPEN_PADS, pad)
    pad.players = 0
    try
        quiet!(pad)
    catch
    end
    SDL_GameControllerClose(pad.gc)
    pad.gc = C_NULL
    return
end
function quiet!(pad::Pad)
    pad.motor_low = pad.motor_high = 0
    pad.left = pad.right = TriggerOff()
    return send!(pad)
end
function poll!(pad::Pad)
    SDL_GameControllerUpdate()
    gc = pad.gc
    raw(a) = SDL_GameControllerGetAxis(gc, a) / 32767
    stick(a) = clamp(raw(a), -1.0, 1.0)
    lx, ly = stick(SDL_CONTROLLER_AXIS_LEFTX), -stick(SDL_CONTROLLER_AXIS_LEFTY)
    rx, ry = stick(SDL_CONTROLLER_AXIS_RIGHTX), -stick(SDL_CONTROLLER_AXIS_RIGHTY)
    l2 = clamp(raw(SDL_CONTROLLER_AXIS_TRIGGERLEFT), 0.0, 1.0)
    r2 = clamp(raw(SDL_CONTROLLER_AXIS_TRIGGERRIGHT), 0.0, 1.0)
    down(b) = SDL_GameControllerGetButton(gc, b) != 0
    buttons = UInt32(0)
    for (name, b) in pairs(SDL_BUTTONS)
        down(b) && (buttons |= BUTTONS[name])
    end
    l2 > TRIGGER_PRESSED && (buttons |= BUTTONS.l2)
    r2 > TRIGGER_PRESSED && (buttons |= BUTTONS.r2)
    dpad = hat(down(SDL_CONTROLLER_BUTTON_DPAD_UP), down(SDL_CONTROLLER_BUTTON_DPAD_RIGHT),
        down(SDL_CONTROLLER_BUTTON_DPAD_DOWN), down(SDL_CONTROLLER_BUTTON_DPAD_LEFT))
    pad.state = PadState(lx, ly, rx, ry, l2, r2, dpad, buttons)
    return pad.state
end
function hat(up, right, down, left)
    y, x = up - down, right - left
    x == 0 && y == 0 && return 0x08
    return UInt8(mod(round(Int, atan(x, y) / (π / 4)), 8))
end
function rumble!(pad::Pad; low = 0.0, high = 0.0)
    pad.motor_low = to_byte(low)
    pad.motor_high = to_byte(high)
    return pad
end
function trigger!(pad::Pad, side::Symbol, effect::TriggerEffect)
    side === :left ? (pad.left = effect) :
        side === :right ? (pad.right = effect) : throw(ArgumentError("side must be :left or :right"))
    return pad
end
function lightbar!(pad::Pad, r, g, b)
    pad.rgb = (to_byte(r), to_byte(g), to_byte(b))
    return pad
end
function player_leds!(pad::Pad, mask::Integer)
    pad.players = UInt8(mask & 0x1f)
    return pad
end
to_byte(x) = round(UInt8, 255 * clamp(Float64(x), 0.0, 1.0))
function send!(pad::Pad)
    pad.gc == C_NULL && return pad
    if pad.dualsense
        fill_common!(pad.effect, pad)
        pad.status = SDL_GameControllerSendEffect(pad.gc, pad.effect, EFFECT_LEN)
    else
        pad.status = SDL_GameControllerRumble(pad.gc, UInt16(pad.motor_low) * 0x101,
            UInt16(pad.motor_high) * 0x101, RUMBLE_MS)
        SDL_GameControllerHasLED(pad.gc) == SDL_TRUE && SDL_GameControllerSetLED(pad.gc, pad.rgb...)
    end
    pad.status == 0 || @warn "controller refused feedback: $(sdl_error())" maxlog = 1
    return pad
end
# 1-based offsets in SDL's 47-byte DS5EffectsState_t / kernel common effect block.
function fill_common!(c, pad::Pad)
    c[1] = 0x01 | 0x02 | 0x04 | 0x08
    c[2] = 0x04 | 0x10
    c[3], c[4] = pad.motor_high, pad.motor_low
    c[11:21] .= encode(pad.right)
    c[22:32] .= encode(pad.left)
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
    e[2], e[3] = to_byte(t.start), to_byte(t.force)
    return e
end
function encode(t::Section)
    e = zeros(UInt8, 11)
    e[1] = 0x02
    e[2], e[3], e[4] = to_byte(t.start), to_byte(t.stop), to_byte(t.force)
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
function zone_bits(position, level)
    lvl = UInt32(clamp(round(Int, 8 * level), 1, 8) - 1)
    zones, strengths = UInt16(0), UInt32(0)
    for i in clamp(position, 0, 9):9
        zones |= UInt16(1) << i
        strengths |= lvl << (3i)
    end
    return zones, strengths
end
end
