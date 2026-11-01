# Lecture 4 build — Studio screenshots

The Studio screenshots of the Lecture 4 live build, one table per step of the build guide
(`slides/site/lecture/lecture-04/`). Step 00's is the **+** library panel in a student's
`MyCar`, under the last item of its **Do this**. From step 01 on, each is a diagram of a
`dyad/HandsOn04/` reference model, which holds the component exactly as the guide builds it, under
the guide's names and with the course library's icons. Save the files to
`slides/images/lecture-04/` under the names given; `scripts/images.mjs` copies them into the theory
deck (`/img/lecture-04/`, on the build slides) and the guide page (`/lecture/lecture-04/img/`, at
the top of each step's **Do this**). Step 06 has no picture: `BEVEnergyBill` is a paste that `extends` step 04's bench and draws the same
diagram.

The conventions for a re-capture:

- The diagram view, fitted with **Reset view**, with the Dyad sidebar and the bottom panel closed,
  and no tooltip or cursor over the canvas.
- Same window size for every shot: `resize_window(1600, 1000)`, which gives a landscape canvas. Reset
  view fits the dashed outline to the canvas's shorter side, so on a portrait canvas the ports on
  the left and right edges fall outside it.
- Capture the canvas pane only, at full resolution (`zoom` over the pane with `save_to_disk`, which
  writes a PNG), then crop to the drawing with a margin of about 24 px: no toolbar, tabs, activity
  bar or status bar. The 2026-10 shots are 1392 px across the pane before cropping.
- A model whose ports sit on the outline's top and bottom edges (`ElectricDrive`) does not fit at
  Reset view, and one Zoom Out halves it. Take two captures one canvas scroll apart and stitch
  them, matching the overlap.
- The plots in the deck are SVG figures rendered from the reference models
  (`mise run figures:lecture-04`), not Studio screenshots.

## Step 00 — the course library

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step00-electric-library.png` | any diagram (`Body`), rehearsal `MyCar` on `handson-04` from `lecture-04-start` with the library at `lecture-04-dyad-3.5` | The **+** library panel open at `VehicleSystemsComponents › Vehicle › Electric`, listing `AuxLoad`, `Battery`, `Converter`, `DCMachine`, `FieldEMF`, `RegenBlend`; `HandsOn04` visible one level up. The full Studio window, as Lecture 3's `step00-wheel-library.png`, taken in Studio web with the Dyad Studio plugin 3.5.1. |

## Step 01 — the machine on a dyno

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step01-machine.png` | `HandsOn04.DCMachine` with `field` absent (the step 01 version, `RotationalEMF`), or a student's `DCMachine` built from the guide | The machine's internal diagram: `p` and `n` on the left edge, `resistor` → `inductor` → `emf` along the top and back to `n`; `emf.rotor` → `rotor` → `spline` on the right; `friction`, `iron`, `windage` and `constant_loss` in a row below, each on the rotor node and on `support` at the bottom. A student's `DCMachine` built from guide step 01 in Studio web 3.5.1. Three auto-routed segments (`emf.n` → `n`, `iron.spline`, `emf.housing`) are dragged clear of the `emf`, and the loss risers are moved to x = 700; the canvas is panned two arrow-key steps down so `support` fits. 980 × 827. |
| `step01-dyno.png` | `HandsOn04.DCMachineDyno` | `voltage` (k = V) into the top of `supply`, `ground` under `supply`; `machine` at the top right with its machine icon, `p` and `n` on its left edge wired to `supply`; `speed` into `dyno`, `machine.spline` to `dyno`, both supports down to `mounts`. |

## Step 02 — the converter

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step02-converter-dyno.png` | `HandsOn04.ConverterDyno` | Step 01's layout with `converter` between `supply` and `machine`: `current` (k = I_ref) into the top of `converter`, `supply` into `p_in`, `p_out` into `machine.p`, the Φ output into `machine.field`, `converter.n`, `machine.n`, `supply.n` and `ground` on one node. |

## Step 03 — the battery

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step03-battery.png` | `HandsOn04.Battery`, or a student's `Battery` built from the guide | Not captured yet. The battery's internal diagram: `p` on the left edge, `n` on the right, `SoC` on top; `cell` upright on the left with `ocv` (k = E) into its `V`; `cell.p` → `resistor` → `meter` along the top and from `meter.n` round to `p`; `n` along the bottom to `cell.n`; `meter.i` down into `counter` and `counter.y` up to `SoC`. |
| `step03-battery-discharge.png` | `HandsOn04.BatteryDischarge` | `load_profile` into the top of `load`; `load` across `battery`, `p` to `p` on the left and `n` to `n` on the right; `battery.n` to `ground`, branching from the `n` wire at a junction dot; the battery's unconnected `SoC` output on top. Portrait, 413 × 633. |

## Step 04 — the car

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step04-electric-drive.png` | `HandsOn04.ElectricDrive` | `battery` and `aux` across one positive and one negative rail, `converter` fed from the positive rail, `p_out` and Φ into `machine`, `machine.n` and `ground` on the negative rail; `machine` into `reduction` into the `spline` port; `battery.SoC` up to the `SoC` port, `tau_ref` top left, `support` at the bottom. Stitched from two captures, 970 × 996. |

## Step 05 — regen blending

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step05-regen-blend.png` | `HandsOn04.BEVHardStop` | `pedal` and `kmh` into `blend`; `blend.tau_motor` into `drive`, `blend.tau_brake` into the ABS; `drive` through `differential` to the car's front spins; `zero` and `slips` into the ABS, its four outputs into the car's brakes; `abs.front_active` into `blend.abs_active`, the ABS rule; `motion` reading the bus. `RegenBlend`'s own diagram holds only its ports, so the bench shows it in place. Taken from `main`'s `HandsOn04.BEVHardStop`: the `lecture-04-dyad-3.5` tag predates the `abs.front_active` → `blend.abs_active` wire. 887 × 834. |
