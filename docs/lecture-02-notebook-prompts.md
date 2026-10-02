# Notebook agent prompts — Lecture 2

One prompt per notebook, plus the shared support module first. Each is self-contained: hand it
to a fresh agent as is, after the Dyad tasks it depends on have landed. Tier 1 (03–06) first.

| Prompt | Notebook | Needs Dyad tasks |
|---|---|---|
| N00 | shared `support.jl` + deck assets | 2 (for signal names; stub the rest) |
| N03 | 03 — The engine as a plant | 1, 2 |
| N04 | 04 — How much fuel | 3 |
| N05 | 05 — Inside an injector | 4 |
| N06 | 06 — Lambda control and the catalyst | 5 |
| N02 | 02 — The cycle and the spark | 6 |
| N07 | 07 — Idle speed control | 7 |
| N01 | 01 — Where the energy goes | 8 |
| N08 | 08 — Ignition coil, dwell and knock | 9 |
| N09 | 09 — Sensors | 10 |
| N10 | 10 — Warm-up and cooling | 11 |
| N11 | 11 — The whole ECU in the car | 12 |

Paste this preamble above every prompt.

> **Preamble.** Repository: `/home/dr14/CVUT/VehicleSystemsComponents`. Work in your own worktree:
> `wt switch --create feat/lecture02-notebook-<NN>` (it prints the path; work there by path). Read,
> in order: `docs/lecture-02-plan.md` (thesis, settled decisions, reality anchors, "Agent quick
> start", deck-figure map); `docs/lecture-02-notebooks.md` § "Shared conventions" and your
> notebook's section; the Dyad models your notebook runs, in `dyad/` (their docstrings carry
> the provenance tags you must repeat); `notebooks/lecture03/01-abs.pluto.jl` (the Pluto pattern to
> copy); `notebooks/lecture01/support.jl` (helpers to reuse: `setup`, `signal`, `sweep`, `rerun`,
> `show_dyad`). Do not change anything under `dyad/` or `generated/`. If a knob your notebook needs
> is not exposed on an analysis, stop and report which knob and which analysis, rather than using a
> nested `a__b__c` override. The deck is `materials/ControlTheory/2. Engine CS.pptx`; unzip it to a
> scratch directory and copy the figures you show from `ppt/media/` into
> `notebooks/lecture02/assets/`. Done means
> `julia +dyad-3.4.0 --project=. notebooks/lecture02/<file>.pluto.jl` runs to completion with every
> check cell passing. Quote numbers from the run; where the spec's numbers differ, correct
> `docs/lecture-02-notebooks.md` in the same PR. Stage files by name, Conventional Commits, US
> English. Report the check-cell numbers and any spec corrections.

---

## D-NN — Content-first draft (before the models exist)

Use this to fix a notebook's teaching content before its Dyad task lands. Replace `<NN>` and
`<name>` with the notebook from `docs/lecture-02-notebooks.md`. Paste the preamble above it; the
"done means" line in the preamble still applies.

> Build a **content-complete draft** of notebook `<NN>` as
> `notebooks/lecture02/<NN>-<name>.pluto.jl`, following its section in
> `docs/lecture-02-notebooks.md`. The Dyad models it needs do not exist yet. The purpose of this
> draft is for the lecturer to review the teaching content (story, explanations, equations, figure
> choices, slider choices) before any model is built. The plots are placeholders.
>
> 1. **Final-form content.** Write every markdown cell as it will ship: thesis, explanations,
>    typeset equations, slide citations, the honest-numbers caveats, and "What this bought us".
>    Copy the deck figures the notebook shows into `notebooks/lecture02/assets/` and display them.
> 2. **Placeholders behind one seam.** Every cell that will run a model calls a function in
>    `notebooks/lecture02/draft_stubs.jl` named after the real analysis (e.g.
>    `LambdaLoopTransient(; omega_set, k_jump)`). Each stub returns data shaped like the real
>    result: a time vector and named signals, using the signal names from
>    `docs/lecture-02-dyad-tasks.md`. Generate it from a closed-form surrogate that shows the right
>    qualitative shape (a first-order step, a relay sawtooth, a tanh characteristic), not random
>    numbers. Swapping in the real model must mean deleting the stub and nothing else in the
>    notebook.
> 3. **Mark every placeholder.** Each placeholder plot carries the title prefix
>    "PLACEHOLDER —" and a caption naming the analysis and signal that will replace it. No
>    surrogate number appears in prose as a result. Where the text needs a number, quote the band
>    from the plan's reality-anchor table and say it is the expected band.
> 4. **Check cells written but pending.** Write each check cell with its real assertion and band,
>    guarded so that on stub data it prints `PENDING: needs <analysis>` instead of asserting.
> 5. **Model contract.** End the notebook with a collapsed cell listing everything it needs from
>    the Dyad side: each analysis, the knobs it forwards (names, units, defaults, slider ranges),
>    the signals read, and the numbers each check expects. Compare that list with
>    `docs/lecture-02-dyad-tasks.md` and fix nothing there; report the mismatches instead.
>
> Report: the cell outline (one line per cell); the model contract; every mismatch with the Dyad
> spec (a missing knob, a signal not specified, a band that disagrees); and up to five content
> questions for the lecturer (where the deck and the spec disagree, or where the story has a
> gap). Do not build any Dyad component.

---

## N00 — Shared support module and assets

Create `notebooks/lecture02/support.jl` (module `Lecture02Support`) as specified in
`docs/lecture-02-notebooks.md` § "00". Read signal paths from the compiled analyses
(`VehicleSystemsComponents.Lecture2.*`); do not guess them. Functions whose Dyad task has not
landed yet are stubbed with an error naming the missing analysis.

Unzip the deck and copy every image listed in the plan's deck-figure map into
`notebooks/lecture02/assets/`, renamed by slide (`slide44-afr-map.png`, `slide45-injector.png`,
…). Add `notebooks/lecture02/assets/README.md` listing each file's source slide.

Done when a scratch script can `include` both support modules, call `setup()`, run
`EngineDynoTransient()` and plot `p_m` with the helpers. Report the signal names you exposed.

---

## N03 — The engine as a plant (Tier 1)

Build `notebooks/lecture02/03-engine-as-plant.pluto.jl` per § "03". The argument rests on cell 4
(time constant falls with speed) and cell 6 (honest comparison with Lecture 1's 0.3 s lag and
delay). Read `docs/HANDOVER.md` § "Risk 1" before writing cell 6, and state Lecture 1's reason
accurately. Slider: engine speed. Report: measured time constants at the three speeds against
`τ_m = 120·V_m/(η_v·V_d·N)`, idle `p_m`, peak torque, peak efficiency.

---

## N04 — How much fuel (Tier 1)

Build `notebooks/lecture02/04-fuel-metering.pluto.jl` per § "04". Show the transcribed AFR map
beside `slide44-afr-map.png`; if the transcription and the image disagree anywhere, report it.
Slider: estimate error in `Xh`. Report: λ excursions (uncompensated warm and cold, compensated,
compensated with 30 % estimate error) and `t_inj` at idle and WOT.

---

## N05 — Inside an injector (Tier 1)

Build `notebooks/lecture02/05-injector.pluto.jl` per § "05". The centerpiece is cell 2, a
stacked four-panel figure on a shared time axis beside `slide45-injector.png`. State in the cell
which injector parameters are assumed and which are Bosch datasheet values. Slider: battery
voltage. Report: dead time at 8–16 V, static flow, flyback peak.

---

## N06 — Lambda control and the catalyst (Tier 1)

Build `notebooks/lecture02/06-lambda-control.pluto.jl` per § "06". The centerpiece is cell 3,
beside `slide57-two-step.png`. Use `limit_cycle` from the support module for every period and
amplitude you quote. Sliders: engine speed and `k_jump`. Report: amplitude and frequency at idle,
2000 and 3000 rpm against `4 × loop delay`; catalyst `theta` range; post-cat trim recovery time.

---

## N02 — The cycle and the spark (Tier 2)

Build `notebooks/lecture02/02-cycle-and-spark.pluto.jl` per § "02". Cell 4 regenerates the slide 50
pressure traces beside `slide50-pressure-vs-ignition.png`. Cell 5 compares the MBT values found
here with the `sigma_mbt` table the mean-value engine uses (task 2). Report the differences; they
are expected, so explain them rather than hide them. Sliders: spark advance and engine speed.

---

## N07 — Idle speed control (Tier 2)

Build `notebooks/lecture02/07-idle-speed.pluto.jl` per § "07". Link Lecture 1's tuning notebook
(`notebooks/lecture01/08-tuning.ipynb`) where the air PI is tuned. Slider: spark reserve. Report:
speed dips air-only vs air+spark, minimum speed, the fuel cost of the reserve.

---

## N01 — Where the energy goes (Tier 2)

Build `notebooks/lecture02/01-energy.pluto.jl` per § "01". Cite the drive-cycle data source
(the header of the file in `data/drive_cycles/`) in the cell that loads it. Slider: rolling
resistance coefficient from the slide 17 table. Report: energy per km per term for both cycles
and the closure error.

---

## N08 — Ignition coil, dwell and knock (Tier 3)

Build `notebooks/lecture02/08-ignition-and-knock.pluto.jl` per § "08". Every coil number is
assumed (no open OEM data); say so in the first code cell. Report secondary peak, energy vs
dwell, knock sawtooth period and mean.

---

## N09 — Sensors (Tier 3)

Build `notebooks/lecture02/09-sensors.pluto.jl` per § "09". Show the Bosch NTC table as data with
its datasheet citation. Report the NTC sensitivity peak and the MAF closed/open response times.

---

## N10 — Warm-up and cooling (Tier 3)

Build `notebooks/lecture02/10-warm-up.pluto.jl` per § "10". Report warm-up time, thermostat band,
light-off times with and without retard.

---

## N11 — The whole ECU in the car (Tier 3)

Build `notebooks/lecture02/11-ecu-in-the-car.pluto.jl` per § "11". Open with the Lecture 1 quote
from `notebooks/lecture01/01-the-car.ipynb` cell 4, then answer it. Report the WOT terminal speed,
what limits it, and the cruise-step comparison with Lecture 1.
