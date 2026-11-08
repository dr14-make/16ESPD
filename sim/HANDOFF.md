# Handoff: the drivable planar BEV

Realtime drive is a library analysis with optional UI extensions. Read this, then
`sim/regen-braking-observations.md`.

## Extension integration contract

- `VehicleSystemsComponents.drive_window(integ, sys, spec)` is implemented by
  `ext/VehicleSystemsComponentsGLMakieExt.jl`; core declares the empty extension seam.
- GLMakie alone gives keyboard driving. Loading both GLMakie and SimpleDirectMediaLayer enables
  `VehicleSystemsComponentsPadExt`, selected at call time through `Base.get_extension`; device
  discovery occurs only on an explicit drive call. Failed discovery falls back to keyboard.
- The window uses the caller's integrator and system and returns `(; frames, wall, integrator)`.
  For `HumanDriver`, it writes `set_human_commands!(; throttle, brake, steer)` each driving frame.
  The Julia buffer is sampled on a 100 Hz periodic clock (`HumanDriver.period`, a structural
  parameter) and the three outputs are held between ticks. Sampled simulation time keeps the
  registered Julia reads on the clock; returned solutions retain the held command history.
- `reset_human_commands!()` clears the session-wide buffer to (0, 0, 0). The analysis clears it
  before setup, warm-up clears it afterward, reset clears it before initializing, and window
  exit clears it. Direct integrator users must clear it before initializing each run. One
  interactive drive owns this buffer at a time; concurrent human drives are not supported.
- Model parameter values and signal getters are local to each window. A scripted assembly has
  no buffer reader: the window only draws it and never opens a pad or writes commands.
  ESP, ABS and uniform road grip are fixed analysis settings, not runtime commands.
- Reset initializes a new integrator from the initial problem with empty command histories.
  The window returns that current integrator to the analysis, so the returned solution is the
  drive since the last reset. UI toggles/mode/lock survive reset. `reinit!` alone does not erase
  discrete histories in the installed solver.
- Warm-up uses a separate integrator with copied parameters once per integrator type/session.
  It computes feedback without sending it and ends with a quiet report. Pause releases motors/triggers while lights
  show state. Pad ownership is protected by `finally`, including warm-up/window-creation errors;
  the transport retains its close/finalizer/exit-hook quieting.
- `sim/drive.jl` only loads optional packages from the stacked sim environment and runs an
  analysis. `main(spec)` calls `DyadInterface.run_analysis(spec)`; the zero-argument convenience
  calls `VehicleSystemsComponents.PlanarBEVByHandDrive()`. Studio and Orchestrator list
  `PlanarBEVRealtimeDrive` (scripted on the road car `PlanarBEVOnRoad`, 22 seconds, no window)
  and `PlanarBEVByHandDrive` (human, window on, runs until closed). Both take road files. Set
  `window = false, duration = 3` for neutral driving.
- The by-hand drive runs on OpenCRG files: `PlanarBEVByHandDrive(road_file = "dyad://VehicleSystemsComponents/roads/ice_patch_mu.crg")`,
  likewise `height_file`. The files are structural, so `drive_model` rebuilds the model with them;
  its docstring says why and what else that resets. Empty files keep the model's own.
- Beyond a file's grid the road blends, over `blend_width` (2 m), to `default_grip` (1.0) and
  `default_height` (0 m), structural parameters next to the road files. The shipped height files
  are 2 m wide strips: a car leaving one sideways meets that blend, a cliff where the strip's
  edge is high (ramps reach 10 m, the hill crest 4.1 m).
- The window learns the files from the spec, not the compiled model, and draws a static map of
  road μ (the run's `mu` times the file's grip) and height contours (`drive_road`, sampled once by
  `road_mesh`) under the course. The HUD shows the same μ under each wheel. A model passed in with its own road files gets no map.
- A window request loads GLMakie and SimpleDirectMediaLayer by itself when the environment stack
  provides them (`sim/` on `LOAD_PATH`, or both added to the default `@v1.13` environment);
  otherwise it raises the "load GLMakie" error. Students without them never resolve them.
- From Dyad Studio's play button, set the analysis loading strategy to `:using`. With the
  default `:include`, Studio runs a private copy `Main.VehicleSystemsComponents`; package
  extensions attach only to the real package, so the copy has no window. Studio's bundled
  compiler must match the repository's (3.5.x): an older one rewrites `generated/` on play.
- `sim/DualSense.jl` is a compatibility include of `ext/DualSense.jl`, so `probe.jl` needs no
  GLMakie and retains the transport API. Do not open a window/pad during import or tests.
- Automated validation is headless. `test/realtime_extensions.jl` separately loads the optional
  packages and checks reset isolation, geometry, warm-up, and in-memory haptic encoding without
  displaying a window or opening a pad. Window rendering, keyboard input, controller input,
  adaptive triggers, rumble, lights, and interactive reset still require human verification.
- Plot and table artifacts work in process. A serialization probe with the installed sampled
  ABS stack raises a `SynchJulia.DNode` / `Core.CodeInfo` TypeError; round-tripping is not verified.

## What this branch is

A battery-electric planar car from the library, driven in real time from a PS5 DualSense or the
keyboard, rendered top-down with GLMakie. The UI and pad are package extensions under `ext/`;
optional packages remain in the `sim/` environment and library weak dependencies, not required
dependencies (ADR-0002's student never needs to resolve them).

| File | Role |
|---|---|
| `drive.jl` | Thin launcher for the realtime analysis, loading optional packages from the sim environment. |
| `../ext/VehicleSystemsComponentsGLMakieExt.jl` | Keyboard, window, wall-clock stepping, local model geometry/getters, reset and quiet warm-up. |
| `../ext/VehicleSystemsComponentsPadExt.jl` | Optional pad discovery, input, haptics and lifetime. |
| `DualSense.jl` | Probe compatibility shim for `../ext/DualSense.jl`, the SDL2 transport and DualSense effect encoding. |
| `probe.jl` | Walks a connected pad through every input and feedback channel; run it first on a new machine. |
| `bench_realtime.jl` | Headless timing under a scripted drive; the real-time check. |
| `check_coast_brake.jl` | Coast-down and full-brake run printing road load, motor torque, per-wheel friction and slip. |
| `regen-braking-observations.md` | What the sim showed about coasting and braking, with the validation asks; researched in PR #155. |

The by-hand car is the library component `Vehicle.Planar.RoadBEVDrive`
(`dyad/Vehicle/Planar/RoadBEVDrive.dyad`); the scripted one is `Vehicle.Planar.PlanarBEVDrive`,
the same assembly on a uniform flat road: `PlanarCar` (`RoadCar` on the road), `ElectricDrive` on the front axle via
`DifferentialGear`, `RegenBlend`, `BrakeControlUnit` and `PlanarRoadLoad`, plus `RoadGrade` on
the road. The realtime analysis
owns model/integrator construction; the extension only consumes them. `bench_realtime.jl`
fills the human buffer between frame steps; `check_coast_brake.jl` uses the scripted hard-stop preset.

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

The former standalone driver was verified with a USB DualSense on Linux. The extension layout
still needs human verification, including keyboard and haptics. Bluetooth, macOS, Windows and
non-DualSense controllers remain untested.

On Linux, SDL drives the DualSense's effects only through its `/dev/hidraw*` node; without
read-write access there (desktop sessions usually grant it to the seat user) SDL falls back to
evdev, input still works, and `probe.jl` reports the refused feedback sends.

Controls: R2/L2 or W/S throttle and brake, left stick or A/D steer, ×/M drive mode
(N, D, e-Pedal), D-pad or `[` `]` steering lock,
Options/Backspace reset, PS/P pause.

## Numbers that should hold

- Real time: the by-hand road car, about 11× faster than real time natively
  (`bench_realtime.jl`), 35 unknowns. Each road grip lookup costs about 20 ns and each slope
  lookup about 35 ns, allocation-free, four grips and one slope per right-hand side.
- Coast-down from about 105 km/h: N 0.035 g, D 0.059 g, e-Pedal 0.222 g, friction brakes at 0.
- Road load at 105.6 km/h: 502 N (325 N drag at CdA 0.63 m², 177 N rolling at f_r 0.012).

If one of these moves, something changed the physics; find out what before continuing.

## Decisions and why

- **Driver commands as clocked causal signals**, emitted by `HumanDriver` from a Julia buffer.
  The loop writes between steps; the model samples and holds commands, and the solver records
  their discrete history. The car retains its 50 ms actuator response so any driver can use
  the same socket without moving solver protection into the driver.
- **Device I/O never runs inside the equations** (same reason as ADR-0004): the loop polls the pad
  and sends one feedback report per frame.
- **The pad is quiet whenever the sim is not driving it.** A DualSense keeps its last motor and
  trigger bytes with no timeout, so warm-up computes the haptics without sending them and ends with
  one quiet report, pause sends no rumble or trigger effect (the lightbar and player LEDs still show
  state), and `close`, plus an exit hook for a hard Ctrl-C, zeroes every open pad.
- **ESP, ABS and road surface are fixed per run**; their pad and keyboard buttons are dropped
  until the CAN bus lectures. Throttle, brake and steering are buffered every driving frame.
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

- **#140 follow-up:** `PlanarBEVDrive` now uses `RegenBlend(abs_rule = true)` with
  `BrakeControlUnit.front_active` wired to `blend.abs_active`, withdrawing regen under front ABS
  as the hard-stop benches do. The coast/brake check no longer reverses the front wheels.
  `RegenBlend` still splits the friction remainder equally over four wheels; the HUD shows regen
  beside friction.
- **#156** the planar ABS stop reached about 0.65 g; PR #162 recalibrates it to 26.5 m from
  80 km/h, about 0.95 g.
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

- `HapticFeedback` as a Dyad component: the mapping from slip, ABS activity and ESP braking to rumble,
  trigger and lightbar now lives in the pad extension; as a component it could be graded by signal match.
