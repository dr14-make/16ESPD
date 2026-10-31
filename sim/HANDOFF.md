# Handoff: the drivable planar BEV

State of `feat/dualsense-driver` for a fresh session. Read this, then `sim/regen-braking-observations.md`.

## What this branch is

A battery-electric planar car from the library, driven in real time from a PS5 DualSense or the
keyboard, rendered top-down with GLMakie. The library is unchanged; everything lives under `sim/`,
in its own environment so GLMakie never becomes a library dependency (ADR-0002's student never
resolves it).

| File | Role |
|---|---|
| `drive.jl` | The real-time loop and window: builds `PlanarBEVDrive`, steps the integrator in wall-clock slices, reads the pad and keyboard, draws, sends haptics. Car geometry, mass, brake torque and gear ratio are read from the compiled model's parameters. |
| `DualSense.jl` | DualSense driver over SDL2 on Linux, macOS and Windows: input, rumble, adaptive triggers, lightbar, player LEDs, USB and Bluetooth. Other controllers SDL knows give input, rumble and light. |
| `probe.jl` | Walks a connected pad through every input and feedback channel; run it first on a new machine. |
| `bench_realtime.jl` | Headless timing under a scripted drive; the real-time check. |
| `check_coast_brake.jl` | Coast-down and full-brake run printing road load, motor torque, per-wheel friction and slip. |
| `regen-braking-observations.md` | What the sim showed about coasting and braking, with the validation asks; researched in PR #155. |

The car is the library component `Vehicle.Planar.PlanarBEVDrive`
(`dyad/Vehicle/Planar/PlanarBEVDrive.dyad`): `PlanarCar`, `ElectricDrive` on the front axle via
`DifferentialGear`, `RegenBlend`, `BrakeControlUnit` and `PlanarRoadLoad`. `drive.jl`,
`bench_realtime.jl` and `check_coast_brake.jl` all build it from `generated/`, so editing the
`.dyad` file and recompiling (see Compiler) changes the car the sim drives. The driver sets its
top-level parameters `throttle`, `brake`, `steer`, `esp_on` and `abs_on`; road friction is
`car.mu_scale_fl/fr/rl/rr`.

## Run

From the worktree root, Dyad 3.5.0 Julia:

    julia +dyad-3.5.0 --project=. sim/probe.jl          # pad check, ~30 s, hold the controller
    julia +dyad-3.5.0 --project=. sim/drive.jl          # ~3 min compile and warm-up, then the window

For a lecture, keep one warm session instead: start `julia +dyad-3.5.0 --project=.`, run
`include("sim/drive.jl"); main()` before class (about 3 minutes), and after closing the window
`main()` opens it again in seconds. Including the file does not start the sim; running it as a
script does.

`drive.jl` stacks `sim/` behind the library environment on `LOAD_PATH`. The first run needs
`sim/`'s environment instantiated (`julia +dyad-3.5.0 --project=sim -e 'using Pkg; Pkg.instantiate()'`,
about 5 minutes for GLMakie).

Verified only with a USB DualSense on Linux. Bluetooth, macOS, Windows and non-DualSense
controllers are implemented but untested.

On Linux, SDL drives the DualSense's effects only through its `/dev/hidraw*` node; without
read-write access there (desktop sessions usually grant it to the seat user) SDL falls back to
evdev, input still works, and `probe.jl` reports the refused feedback sends.

Controls: R2/L2 or W/S throttle and brake, left stick or A/D steer, △/E ESP, □/Q ABS, ○/R road
surface (dry, wet, snow, split-µ), ×/M drive mode (N, D, e-Pedal), D-pad or `[` `]` steering lock,
Options/Backspace reset, PS/P pause.

## Numbers that should hold

- Real time: about 12× faster than real time natively (`bench_realtime.jl`), 34 unknowns.
- Coast-down from about 105 km/h: N 0.035 g, D 0.059 g, e-Pedal 0.222 g, friction brakes at 0.
- Road load at 105.6 km/h: 502 N (325 N drag at CdA 0.63 m², 177 N rolling at f_r 0.012).

If one of these moves, something changed the physics; find out what before continuing.

## Decisions and why

- **Driver commands as parameters**, changed between solver steps with `setp`. Each passes through
  a 50 ms first-order lag (`foot`, `hands`) so a step in torque never makes the converter's
  algebraic variable jump at an instant the solver has no event for.
- **Device I/O never runs inside the equations** (same reason as ADR-0004): the loop polls the pad
  and sends one feedback report per frame.
- **The pad is quiet whenever the sim is not driving it.** A DualSense keeps its last motor and
  trigger bytes with no timeout, so warm-up computes the haptics without sending them and ends with
  one quiet report, pause sends no rumble or trigger effect (the lightbar and player LEDs still show
  state), and `close`, plus an exit hook for a hard Ctrl-C, zeroes every open pad.
- **ESP, ABS and road surface are set on the integrator only when they change**; throttle, brake
  and steering every frame.
- **SDL for transport, our own effect block**: SDL2 (`SimpleDirectMediaLayer`) reads input and
  frames output for USB and Bluetooth on all three OSes. No library encodes the adaptive triggers,
  so `DualSense.jl` fills the 47-byte DualSense effect block itself and hands it to
  `SDL_GameControllerSendEffect`. The trigger effect bytes (modes 0x01, 0x02, 0x21, 0x26) are
  community reverse-engineering, verified by feel on this pad.
- **Lift-off regen as a light brake request** when the throttle is released: `RegenBlend` only
  regenerates on a brake request, so this needs no model change. D is 0.025 g of regen beyond road
  load (Argonne's 2013 Leaf coast-down), e-Pedal 0.2 g (Nissan); sources in #155's research note.
- **Steering lock** fades with speed, `lock / (1 + v / 45)`, from 34° at the road wheel at
  standstill.

## Known issues, tracked in the library

- **#140** regen is not withdrawn under ABS, and `RegenBlend` splits the friction remainder equally
  over four wheels, so the front friction brakes sit at 0 during a hard stop while the motor brakes
  the front alone. The HUD shows regen beside friction so this is visible.
- **#156** the ABS stop reaches about 0.65 g instead of about 1 g.
- **#157** ESP rarely acts under ABS, and the car cannot be steered with both on.
- The course road law decelerates faster than EPA's Leaf below about 50 km/h; kept on purpose and
  documented as a known limit.

## Compiler

Compile with the published CLI, not `~/julia/dyad-lang/apps/cli/dyad`:

    npx -y @juliacomputing/dyad-cli@3.5.0 compile .

That local binary is a gitignored build artifact from 2026-06-25 and still reports 3.2.0; it fails
on this repo (`Unknown element x0 in definition InitialCondition`). After every compile, run
`git diff generated/` and revert changes to files you did not edit.

## Local only

`sim/wasm/` (gitignored) holds a WebAssembly build of this car and its notes. It depends on
pre-release tooling that is not public, so it stays out of this public repository.

## Open

- Give `PlanarBEVDrive` real `RealInput` connectors for throttle, brake and steering instead of
  parameters (ADR-0001: the driver is a signal source).
- `HapticFeedback` as a Dyad component: the mapping from slip, ABS activity and ESP braking to rumble,
  trigger and lightbar now lives in `drive.jl`; as a component it could be graded by signal match.
