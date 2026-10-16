# Lecture 2 — Studio screenshots

The theory deck shows the Dyad models behind its plots as Studio screenshots, as the Lecture 1
decks do. The plots themselves are not screenshots: they are notebook cells exported by
`mise run cards:lecture-02`, so a model change is one re-run away from new figures. Until a
screenshot exists, the slide shows a hand-drawn SVG of the same block structure from
`slides/decks/lecture-02/public/diagrams/`, and its speaker notes name the file that replaces it.
Save the files to `slides/images/lecture-02/` under the names given; `slides/scripts/images.mjs`
copies them to the deck, where a slide references them as `/img/lecture-02/<file>`.

The Lecture 1 conventions apply to every diagram:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- A shot that needs a parameter panel shows it over the diagram, with the toolbar masked out.
- Same window size for every shot. About 1600 × 1000 matches the Lecture 1 images.

Every model below lives in `dyad/Vehicle/Engine/`; its harness and analysis live in
`dyad/Lecture2/`.

## Section 04 — sensors

| File | Model | What must be visible | Replaces on the slide |
| ---- | ----- | -------------------- | --------------------- |
| `tps-sensor.png` | `ThrottlePositionSensor` | The whole diagram: `reference` (5 V) feeding `top1` → `track1` → `bottom1` and `top2` → `track2` → `bottom2` to `ground`, with `track2` wired the other way round (`top2` on its `pin_n`); `wiper_drive` from the `phi` input into both tracks' `r`; `wiper1`, `input1`, `sense1` → `V1` and `wiper2`, `input2`, `sense2` → `V2`. Show the parameter panel of `track1` with `R = R_track`. | `diagrams/04-tps-circuit.svg` on `tps` |
| `etc-diagram.png` | `ElectronicThrottle` | The whole loop: `u_cmd` → `controller` (`LimPID`) → `bridge` → `current_sensor`, `armature_R`, `armature_L` → `emf` → `rotor` → `gearbox` → `plate`; `return_spring`, `stops` and `bearing` between `housing` and `plate`; `angle_sensor` → `tps` → `estimate` back into `controller.u_m`. | `diagrams/04-etc-loop.svg` on `etc` |
| `etc-pedal-step.png` | `ThrottlePedalStep` | The harness: `step` and `ramp` into `command` (`Add`) into `etc.u_cmd`. Optional, for the notes or the hands-on. | — |

## Section 05 — fuel injection

| File | Model | What must be visible | Replaces on the slide |
| ---- | ----- | -------------------- | --------------------- |
| `injector-model.png` | `FuelInjector` | The whole diagram: `solenoid` between `p` and `n`, its `flange` on the `needle` (`Mass`) and its `support` on `housing`; `spring`, `seat` and `stop` between `housing` and `needle`; `lift_sensor` → `lift`; the `ambient` heat sink. Show the parameter panel with `R`, `L_inf`, `L_0`, `g_0`, `lift_max` and `F_pre`. | nothing yet: a candidate for `fuel-injector` (pptx 43), beside the cutaway |
| `injector-pulse.png` | `InjectorPulse` | The harness: `battery_level` → `battery`, `injector`, `transistor` with the `zener` across it, `pulse` → `gate_drive` → `transistor.G`, `rail` → `injector.dp_rail`, `injector.mdot_f` → `fuel_mass`. | nothing yet: a candidate for `injector-activation` (pptx 45) speaker notes |
