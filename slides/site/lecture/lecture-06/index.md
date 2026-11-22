---
title: Lecture 6 — put the car on a CAN bus
---

[← Vehicle Systems & Components](../../index.html) · [Lecture deck →](../../lecture-06/index.html){target="_self"}

# Lecture 6: put the car on a CAN bus

Written for Dyad Studio 3.5.1.

**What you do.** You take the electric car from Lectures 3 and 4, split into ECUs as a real EV is,
and move its signals from their own wires onto one CAN bus. Then you measure what the bus costs. A
bus trades wires for time: every signal on it arrives late, rounded and on a schedule. You find
out where that matters, in a hard ABS stop from 80 km/h, and why a real car keeps its brake loops
off the bus.

| Step | What you do | Time |
| --- | --- | --- |
| [0 · Setup](#step-0) | clone the course repository at its tag, compile, start the Julia REPL | 10 min |
| [1a · From wires to an ideal bus](#step-1a) | delete 3 wires, set one flag; run | 15 min |
| [1b · The regen message](#step-1b) | find the missing message with `check_can`, add the transmitter, delete the bypass | 15 min |
| [2 · Two transmitters on one slot](#step-2) | read `check_can`, remove the duplicate transmitter | 10 min |
| [3 · Architecture against period](#step-3) | run the stop at 10, 20 and 40 ms; compare with the brake request on the bus | 25 min |
| [4 · Bus load](#step-4) | run `can_schedule` at 500 and 250 kbit/s | 10 min |

**The car.** Every step builds on `WiringStop`: a hard ABS stop from 80 km/h, with the brake pedal
pressed at 0.5 s. Its canvas shows the car split the way a real EV is:

- The **brake ECU** (`WiringBrakeNode`) reads the brake pedal and the four wheel-speed sensors on
  its own wires, and drives the four calipers on its own wires. Inside it, the wheel-only estimator
  computes speed and slip, `RegenBlend` splits the brake demand between the motor and the discs,
  and `AbsControlHold` holds the ABS status.
- The **VCU** (`WiringDriveNode`) reads the accelerator on its own wire and adds the regen request
  from the brake ECU.
- Only **coordination** crosses the bus: vehicle speed, the four wheel speeds, steering angle, yaw
  rate, the regen request and the held ABS status.

So the loops that stop the car stay local: pedal → brake ECU → calipers, and wheel sensors → ABS →
calipers, never touch the bus. What crosses it is what other ECUs need to know. The model does not
report the motor's actual torque back to the brake ECU.

**Starters.** Each step opens a starter model in `HandsOn06`: `Step1PointToPointStop`,
`Step1bMissingRegenStop`, `Step2DuplicateSlotStop` and `Step3CanStop`. Each comes with its analysis
(`Step1PointToPointStopTransient` and so on), so you do not create one. Each step also names a
reference model: your finished starter stops at the same distance, so compare with the checkpoint.
The starters do not depend on each other: if you fall behind, start the next step from its own
starter.

**Working in Studio.**

- Open a model: in COMPONENTS, double-click it (or click it once and press Enter).
- Most edits today are flags of the starter, such as `networked` or `chassis_period`. Click an
  empty spot on the canvas so nothing is selected, open **Edit Parameters**, and tick the flag or
  type the value. Studio writes it into the starter's `extends WiringStop(…)` line and redraws
  the canvas at once.
- Delete a wire: hover over it to see its tooltip, `connect(a, b)`, then click it and press
  Delete. This guide names each wire by its two ends. Its tag in code view, such as
  `{^direct_regen}`, does not last: after any canvas edit Studio renames the remaining tags to
  `id1`, `id2`, ….
- Code view (⇄) works for every edit too. After a code-view edit, close the diagram and reopen
  it before you touch the canvas again; otherwise later canvas edits draw but are not saved.
- Save (Ctrl+S) and wait for compilation to finish before you run.
- Run: with the starter's diagram focused, press ▷ (Run Analysis) and click the step's analysis,
  the second row. Enter on the highlighted first row creates a new analysis instead.
- The REPL grows with every run, and a laptop runs out of memory after five or six. Start each
  step with a fresh REPL: F1 › **Dyad: Open Julia REPL**, then paste the `stop_distance` block
  below again. If the REPL tab disappears, it ran out of memory; open a new one the same way.
- `check_can` raises an error that names the mistake. When the bus is right it returns the whole
  model, which fills the terminal, so the snippets below end in `; "ok"`.

**Reading the stop distance.** `solution` always holds the most recent run. The stop distance is
measured from the pedal press at 0.5 s until the speed first falls below 0.5 m/s, on a 5 ms grid.
Paste this into the REPL once, then call `stop_distance(solution)` after each run:

```julia
using DyadInterface: symbolic_container
using VehicleSystemsComponents
const Planar = VehicleSystemsComponents.Vehicle.Planar
const H06 = VehicleSystemsComponents.HandsOn06
function stop_distance(r; car = symbolic_container(r).car)
    s, ts = r.sol, 0.5:0.005:6.0
    k = findfirst(<(0.5), s(ts, idxs=car.bus.vx).u)
    s(ts[k], idxs=car.bus.x) - s(0.5, idxs=car.bus.x)
end
```

Paste code blocks rather than typing them: the REPL closes brackets for you, and a typed line
break submits half a call. Each run first prints a screenful of `WARNING: import of … conflicts
with an existing identifier; ignored.` lines; they are harmless. The tests check every stop distance below to within 1 mm.

## 0 · Setup — 10 min {#step-0}

Start this before the talk ends: the first compile and the first REPL start take several minutes.
Today you edit the starters inside the course repository itself, at the tag
`lecture-06-dyad-3.5-r1`: the Lecture 6 version for Dyad 3.5. Clone it before class if you can.

1. In Studio, press F1 › **Git: Clone**, paste `https://github.com/dr14-make/16ESPD`, pick an
   empty folder, and click **Open** when asked. At the trust prompt, choose "Yes, I trust the
   authors".
2. Press F1 › **Git: Create Branch From…**, type `handson-06`, and pick the tag
   `lecture-06-dyad-3.5-r1` from the list.

   From a terminal instead, then open the `16ESPD` folder in Studio and trust it the same way:

   ```sh
   git clone --branch lecture-06-dyad-3.5-r1 https://github.com/dr14-make/16ESPD
   cd 16ESPD && git switch -c handson-06
   ```

3. Open the Dyad sidebar (its icon in the left activity bar). COMPONENTS lists
   `VehicleSystemsComponents`.
4. Press F1 › **Dyad: Compile** and wait until it finishes.
5. Press F1 › **Dyad: Open Julia REPL**. Leave it loading while you start step 1a, then paste the
   `stop_distance` block above.

To put one starter back as shipped, discard your changes to that file: **Source Control** ›
right-click it › **Discard Changes**, or from a terminal
`git restore dyad/HandsOn06/Step1PointToPointStop.dyad`.

::: tip Checkpoint 0

COMPONENTS shows `HandsOn06` with `Step1PointToPointStop`, `Step1bMissingRegenStop`,
`Step2DuplicateSlotStop` and `Step3CanStop`, and the REPL panel shows a `julia>` prompt.

:::

## 1a · From wires to an ideal bus — 15 min {#step-1a}

Lecture deck: [our car, wired and bused](../../lecture-06/index.html#/our-car-wired){target="_self"}

#### Goal

Move the coordination signals from their own wires onto the bus, and show that an ideal bus
behaves exactly like wires. Count the wires before and after.

#### Given

`HandsOn06 › Step1PointToPointStop` is the car with the bus off (`networked = false`). Three
signals run on direct wires on the canvas: the regen request from `ecu.regen` to `drive.regen`
(brake ECU → VCU), and the steering angle and yaw rate from `motion.steering` and `motion.yaw` to
`ecu.steering` and `ecu.yaw` (sensors → brake ECU). The bus backbone is already connected, so the CAN ports stay
balanced while you rewire.

#### Do this

1. Run `Step1PointToPointStopTransient` once as it ships and note `stop_distance(solution)`.
2. Delete the three direct wires: `ecu.regen`–`drive.regen`, `motion.steering`–`ecu.steering`
   and `motion.yaw`–`ecu.yaw`.
3. In Edit Parameters, tick `networked`.
4. Keep the pedal, wheel-speed and caliper wires: those loops stay local.
5. Save, run `Step1PointToPointStopTransient` again and read `stop_distance(solution)`.

::: tip Checkpoint 1a

| Car | Stop distance |
| --- | --- |
| Point to point, as shipped | 28.185 m |
| Your car on the ideal bus | 28.185 m |

An ideal bus delivers every value at once and unrounded, so it is indistinguishable from wires.
What it saves is wiring. Each top-level signal net counts once, the bus included; the six
mechanical nets don't count:

| Car | Point to point | On the bus |
| --- | ---: | ---: |
| This hands-on's starter | 22 nets | 19 nets |
| Library car (`PlanarBEVDriveEstimated` / `PlanarBEVCanDrive`) | 31 nets | 19 nets |

The library's point-to-point car draws the estimator and the blend at the top level, so it has
more nets than the starter.

:::

#### Fell behind?

`HandsOn06.Step1IdealBusStop` is the finished step (also `IdealBusStop`, analysis
`IdealBusStopTransient`).

## 1b · Build the regen message by hand — 15 min {#step-1b}

Lecture deck: [the same fields on a Dyad block](../../lecture-06/index.html#/fields-on-a-block){target="_self"}

#### Goal

Put one signal on the bus yourself: choose its slot, identifier, period and scaling, and wire the
transmitter. Learn what `check_can` tells you when a message is missing.

#### Given

`HandsOn06 › Step1bMissingRegenStop` is on the bus, but the brake ECU does not send the regen
request yet (`transmit_regen = false`), and the VCU still reads it from a direct wire from
`ecu.regen` to `drive.regen` (`drive_networked = false`). The VCU's receiver, `CanRxReal(slot = 6, id = 272)` in
`WiringDriveNode`, is already on the bus, waiting for a transmitter.

#### Do this

1. Ask `check_can` what is wrong:

   ```julia
   Planar.check_can(H06.Step1bMissingRegenStop(name = :exercise)); "ok"
   ```

   It raises `CAN: drive.regen_rx receives slot 6, but nobody transmits on it.`: a receiver listens
   for a message no ECU sends.
2. Open `WiringBrakeNode` and find the regen transmitter `regen_tx`. These are its fields:

   | Field | Value |
   | --- | --- |
   | slot | 6 |
   | identifier | 272 (110h) |
   | period | `regen_period` (= `chassis_period`) |
   | scale | 0.1 N·m per bit |
   | raw range | −32768…32767 |

   It reads `blend.tau_motor`, the motor's share of the brake demand, and connects to `bus`. It
   exists only while `transmit_regen` is true. Its two wires sit inside an `if` block, and Studio
   does not draw those: the block appears with the flag, its wires never do. `check_can` is how
   you see that they are there.
3. Back in the starter, tick `transmit_regen` and `drive_networked` in Edit Parameters, so the
   brake ECU sends the regen request and the VCU takes it from the bus.
4. Delete the direct wire from `ecu.regen` to `drive.regen`.
5. Save and run `Step1bMissingRegenStopTransient`. The run reloads the library in the REPL, so
   the `check_can` line now prints `"ok"`.

::: tip Checkpoint 1b

`check_can` passes, and the car stops in **28.185 m**, the same as before: on the ideal bus, the
message you built is as good as the wire it replaces.

:::

#### Fell behind?

`HandsOn06.RegenMessageStop` is the finished step; run `RegenMessageStopTransient`.

## 2 · Two transmitters on one slot — 10 min {#step-2}

Lecture deck: [`check_can` checks the model](../../lecture-06/index.html#/check-can){target="_self"}

#### Goal

Read a wiring mistake from `check_can` instead of from a failed solve, and learn that a slot can
have only one owner.

#### Given

`HandsOn06 › Step2DuplicateSlotStop` is the car on a real bus (`ideal = false`) with one mistake in
it: a second regen transmitter, the block `duplicate`, wired from `ecu.regen` and to `ecu.bus`. Its
analysis fails until you repair it.

#### Do this

1. Run `check_can` before you solve:

   ```julia
   Planar.check_can(H06.Step2DuplicateSlotStop(name = :exercise)); "ok"
   ```

   It raises `CAN: duplicate and ecu.regen_tx both transmit on slot 6.` The two have different
   identifiers, 273 and 272, but share slot **6**.
2. Changing only the ID does not fix it: the slot still has two owners. In the model, the slot is
   the place on the bus that carries the signal, and one transmitter owns it.
3. Delete the block `duplicate`; Studio deletes its two wires with it.
4. Save and run `Step2DuplicateSlotStopTransient`.

::: tip Checkpoint 2

`check_can` passes and the car stops in **29.056 m**. That is 0.871 m more than on the ideal bus:
this bus is real, so every message waits for its frame. Step 3 measures that cost.

:::

#### Fell behind?

`HandsOn06.CanStop` is the repaired car; run `CanStopTransient`.

## 3 · Architecture against period — 25 min {#step-3}

Lecture deck: [timing in the model](../../lecture-06/index.html#/timing-in-the-model){target="_self"}
· [where the brake request lives](../../lecture-06/index.html#/where-the-brake-request-lives){target="_self"}
· [what the bus costs the ABS](../../lecture-06/index.html#/what-the-bus-costs-the-abs){target="_self"}

#### Goal

Measure how the period of the chassis messages lengthens the stop, and how much worse it gets when
the brake request itself rides the bus.

#### Given

`HandsOn06 › Step3CanStop` is the car on a real bus with a chassis period of 10 ms. Speed, wheel
speeds, steering, yaw, regen and ABS status follow `chassis_period`; the dashboard frames use
100 ms. In the model, a value is sampled once per period and delivered one period later, so it
arrives between one and two periods late.

#### Do this

1. Run `Step3CanStopTransient` (10 ms) and read `stop_distance(solution)`.
2. In Edit Parameters, set `chassis_period` to `0.02`, save, and run again. Then `0.04`. The
   period is in seconds. `HandsOn06.Step4SlowCanStop` is the 40 ms car, and the references
   `CanStopTransient`, `Can20msStopTransient` and `Can40msStopTransient` run the three periods
   without editing.
3. Compare with the counterexample, where the brake request crosses the bus twice: from the pedal
   to a separate blend ECU, then as a friction request to the brake ECU. Its numbers are in the
   table below. If you have time, start a fresh REPL and run one from the library: open
   `Vehicle › Planar › CanBusBrake10msStopBench` (or the 20 or 40 ms bench), press ▷ and click
   `CanBusBrake10msStop`. Its car sits one level deeper, so read the distance with
   `stop_distance(solution; car = symbolic_container(solution).vehicle.car)`.

One stop depends on where the pedal press falls between frames. So
`assets/data/lecture06/can_stop.csv` repeats every case for six pedal-onset offsets from 0 to
40 ms; `scripts/lecture06_can_sweep.jl` writes it. Your runs give the **Default onset** column.

::: tip Checkpoint 3

| Layout, period | Default onset [m] | Sweep mean [m] | Min–max [m] |
|---|---:|---:|---:|
| Real, 10 ms | 29.056 | 28.902 | 28.617–29.056 |
| Real, 20 ms | 30.018 | 29.496 | 28.982–30.018 |
| Real, 40 ms | 30.442 | 30.224 | 30.017–30.442 |
| Brake request on the bus, 10 ms | 30.743 | 30.144 | 29.053–30.743 |
| Brake request on the bus, 20 ms | 29.320 | 29.595 | 29.320–29.949 |
| Brake request on the bus, 40 ms | 33.934 | 33.638 | 31.792–35.779 |

The ideal bus stops in 28.185 m at every period. The real layout costs 0.8–2.1 m against it,
because the regen request still waits for its frame. The counterexample also waits for the brake
request and the friction request; at 40 ms it stops about 5.5 m later than the ideal bus on
average, and up to 4 m apart on the same car depending on where the press falls. The real layout
never locks a wheel; the counterexample briefly locks a rear wheel at 10 ms with a 30 ms onset
offset.

The counterexample does not grow steadily with the period: its 20 ms stop is shorter than its
10 ms one, because the sampled ABS cycles fall differently against the frames. Read the range as
well as the mean.

:::

This is why a real EV wires its brake pedal, wheel sensors and calipers to the brake ECU: the
loops that decide the stop never wait for a frame.

## 4 · Bus load at two bitrates — 10 min {#step-4}

Lecture deck: [bus load](../../lecture-06/index.html#/bus-load){target="_self"}
· [load against bitrate](../../lecture-06/index.html#/load-vs-bitrate){target="_self"}

#### Goal

Calculate how busy the bus is and how long each frame can wait for the wire, at two bitrates.

#### Do this

```julia
car = H06.CanStop(name = :exercise)
fast = Planar.can_schedule(car; bitrate = 500_000)
slow = Planar.can_schedule(car; bitrate = 250_000)
round.(100 .* (fast.load, slow.load); digits = 2)                 # load in %
round.([f.response_time for f in fast.frames] .* 1000; digits = 2)  # ms, by priority
```

::: tip Checkpoint 4

| Bitrate | Load | Worst-case response times, by priority [ms] |
| --- | ---: | --- |
| 500 kbit/s | 13.45 % | 0.28, 0.43, 0.58, 0.73, 0.88, 1.03, 1.18, 1.33, 1.48, 1.48 |
| 250 kbit/s | 26.9 % | twice the 500 kbit/s values |

Halving the bitrate doubles the load and every response time. Even so, every frame is on the wire
within 3 ms, while the chassis period is 10 to 40 ms.

:::

The schedule is calculated, not simulated: it does not change the delay in the model, which comes
from the periods. A higher priority would not shorten the stop. The period is the delay.
