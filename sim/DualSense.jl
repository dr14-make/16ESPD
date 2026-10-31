"""
A game controller, preferably a Sony DualSense, reached through SDL2 on Linux, macOS and Windows.

SDL owns the transport: it reads input, and frames output reports for USB or Bluetooth with the
CRC Bluetooth needs. The DualSense's feedback goes out as the 47-byte effect block SDL passes
through `SDL_GameControllerSendEffect` (SDL's `DS5EffectsState_t`), which this module fills
itself because no library encodes the adaptive-trigger effects. Block layout follows the Linux
`hid-playstation` driver; the trigger effect encodings are reverse-engineered and not published
by Sony.

Any other controller SDL recognizes still gives input, rumble and, where it has one, a colored
light; trigger effects and player LEDs do nothing on it.

The pad never reads or writes on its own: `poll!` reads the current input and `send!` writes the
accumulated feedback once. The caller owns the clock.
"""
module DualSense

using SimpleDirectMediaLayer.LibSDL2

export Pad, PadState, open_pad, poll!, send!, rumble!, trigger!, lightbar!, player_leds!
export TriggerOff, Rigid, Section, Feedback, Vibration

const EFFECT_LEN = 47

# Longer than any frame, so motors stop by themselves if the caller stops sending.
const RUMBLE_MS = 250

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

"""
Controller input, sticks in -1..1 with up and right positive, triggers in 0..1. `dpad` is a hat
code: 0 up, 1 up-right, 2 right, … 7 up-left, 8 released.
"""
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
    ps = 0x0001_0000, touchpad = 0x0002_0000, mute = 0x0004_0000,
)

const SDL_BUTTONS = (
    square = SDL_CONTROLLER_BUTTON_X, cross = SDL_CONTROLLER_BUTTON_A,
    circle = SDL_CONTROLLER_BUTTON_B, triangle = SDL_CONTROLLER_BUTTON_Y,
    l1 = SDL_CONTROLLER_BUTTON_LEFTSHOULDER, r1 = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
    create = SDL_CONTROLLER_BUTTON_BACK, options = SDL_CONTROLLER_BUTTON_START,
    l3 = SDL_CONTROLLER_BUTTON_LEFTSTICK, r3 = SDL_CONTROLLER_BUTTON_RIGHTSTICK,
    ps = SDL_CONTROLLER_BUTTON_GUIDE, touchpad = SDL_CONTROLLER_BUTTON_TOUCHPAD,
    mute = SDL_CONTROLLER_BUTTON_MISC1,
)

# Travel at which L2/R2 count as pressed buttons.
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
    "SDL's return code from the last feedback call, 0 when accepted."
    status::Cint
end

# SDL is initialized once per Julia session and never shut down, so a warm session can close
# and reopen pads.
function init_sdl()
    SDL_WasInit(SDL_INIT_GAMECONTROLLER) != 0 && return
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5, "1")
    # Enhanced reports; without them SDL refuses effects over Bluetooth.
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE, "1")
    # The focused window belongs to the caller, not to SDL.
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1")
    SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) == 0 ||
        error("SDL controller init failed: ", sdl_error())
    # State is read by polling; queued events would only pile up unread.
    SDL_JoystickEventState(SDL_IGNORE)
    SDL_GameControllerEventState(SDL_IGNORE)
    return
end

sdl_error() = unsafe_string(SDL_GetError())

is_dualsense(index) = SDL_GameControllerTypeForIndex(index) == SDL_CONTROLLER_TYPE_PS5

"""
    open_pad(index = nothing) -> Pad

Open the controller at SDL joystick `index`, or else the first DualSense, or else the first
controller SDL knows.
"""
function open_pad(index::Union{Nothing,Integer} = nothing)
    init_sdl()
    SDL_GameControllerUpdate()  # picks up controllers connected since the last call
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
    return pad
end

function Base.close(pad::Pad)
    pad.gc == C_NULL && return
    pad.motor_low = pad.motor_high = 0
    pad.left = pad.right = TriggerOff()
    pad.players = 0
    try
        send!(pad)
    catch
    end
    SDL_GameControllerClose(pad.gc)
    pad.gc = C_NULL
    return
end

"""
    poll!(pad) -> PadState

Read the controller's current input. Never blocks.
"""
function poll!(pad::Pad)
    SDL_GameControllerUpdate()
    gc = pad.gc
    raw(a) = SDL_GameControllerGetAxis(gc, a) / 32767
    stick(a) = clamp(raw(a), -1.0, 1.0)
    # SDL's stick Y axes are positive downward.
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
    y = up - down
    x = right - left
    x == 0 && y == 0 && return 0x08
    # Clockwise from up, eight steps.
    return UInt8(mod(round(Int, atan(x, y) / (π / 4)), 8))
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

Set the adaptive-trigger effect on `:left` (L2) or `:right` (R2). Takes effect at the next
`send!`; ignored on controllers other than a DualSense.
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

"""Set the five player LEDs from the low five bits of `mask`. DualSense only."""
function player_leds!(pad::Pad, mask::Integer)
    pad.players = UInt8(mask & 0x1f)
    return pad
end

to_byte(x) = round(UInt8, 255 * clamp(Float64(x), 0.0, 1.0))

"""
    send!(pad)

Write the current rumble, trigger, lightbar and player-LED settings. SDL's return code is kept in
`pad.status`; a refusal warns once instead of throwing, so a frame loop keeps running.
"""
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

end
