# Handoff: the drivable planar BEV

State of `feat/dualsense-driver` for a fresh session. Read this, then `sim/regen-braking-observations.md`.

## What this branch is

A battery-electric planar car from the library, driven in real time from a PS5 DualSense or the
keyboard, rendered top-down with GLMakie. The library is unchanged; everything lives under `sim/`,
in its own environment so GLMakie never becomes a library dependency (ADR-0002's student never
resolves it).

| File | Role |
|---|---|
| `plant.jl` | `drive_model()`: the car wired from compiled library components (`PlanarCar`, `ElectricDrive` on the front axle via `DifferentialGear`, `RegenBlend`, `BrakeControlUnit`, `PlanarRoadLoad`). Driver commands are `Constant` sources whose `k` the loop sets. |
| `drive.jl` | The real-time loop and window: steps the integrator in wall-clock slices, reads the pad and keyboard, draws, sends haptics. |
| `DualSense.jl` | Dependency-free DualSense driver over `/dev/hidraw*`: input, rumble, adaptive triggers, lightbar, player LEDs, USB and Bluetooth. |
| `probe.jl` | Walks a connected pad through every input and feedback channel; run it first on a new machine. |
| `bench_realtime.jl` | Headless timing under a scripted drive; the real-time check. |
| `check_coast_brake.jl` | Coast-down and full-brake run printing road load, motor torque, per-wheel friction and slip. |
| `regen-braking-observations.md` | What the sim showed about coasting and braking, with the validation asks; researched in PR #155. |

`dyad/Vehicle/Planar/PlanarBEVDrive.dyad` (untracked) is the same car as a Dyad component. It is
not compiled and not committed: see "Compiler" below.

## Run

From the worktree root, Dyad 3.5.0 Julia:

    julia +dyad-3.5.0 --project=. sim/probe.jl          # pad check, ~30 s, hold the controller
    julia +dyad-3.5.0 --project=. sim/drive.jl          # ~2 min compile and warm-up, then the window

`drive.jl` stacks `sim/` behind the library environment on `LOAD_PATH`. The first run needs
`sim/`'s environment instantiated (`julia +dyad-3.5.0 --project=sim -e 'using Pkg; Pkg.instantiate()'`,
about 5 minutes for GLMakie).

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
- **Raw HID for everything** rather than evdev plus hidraw: one file carries input, rumble,
  triggers and lights. The trigger effect bytes (modes 0x01, 0x02, 0x21, 0x26) are community
  reverse-engineering, verified by feel on this pad.
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

`~/julia/dyad-lang/apps/cli/dyad` reports 3.2.0: it is a gitignored build artifact last built on
2026-06-25, and the checkout has no `node_modules`, so pulling the 3.5.0 source never rebuilt it.
It fails on this repo (`Unknown element x0 in definition InitialCondition`). Until it is rebuilt,
`PlanarBEVDrive.dyad` cannot be compiled, which is why `plant.jl` wires the same car in Julia.
Once it compiles, commit the `.dyad` with its regenerated `generated/` files and switch `plant.jl`
to the compiled component.

## Local only

`sim/wasm/` (gitignored) holds a WebAssembly build of this car and its notes. It depends on
pre-release tooling that is not public, so it stays out of this public repository.

## Open

- Commit or drop `PlanarBEVDrive.dyad` once the compiler works.
- Give `PlanarBEVDrive` real `RealInput` connectors for throttle, brake and steering instead of
  parameters (ADR-0001: the driver is a signal source).
- `HapticFeedback` as a Dyad component: the mapping from slip, ABS activity and ESP braking to rumble,
  trigger and lightbar now lives in `drive.jl`; as a component it could be graded by signal match.
