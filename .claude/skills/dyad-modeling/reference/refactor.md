# Refactors: proving the numbers did not move

For a change that must leave every result as it was. The anchor is the old model itself, so the
proof starts before the first edit.

## 1. Find every run the change reaches

`grep -rn <Name> dyad/ test/ notebooks/ slides/`, then list every analysis and every generated
test case whose model contains the component, through any parent. Notebooks and guides that read a
variable by path (`m.body.drag.f`) are users too.

## 2. Capture the baseline from the old code

In the warm session, before editing: run each of those cases and write, per case, `sol.t`, every
unknown and observed variable on a fixed grid, and the step count, to a file. Keep a copy of the
old `generated/<Sub>/<Name>_definition.jl`.

## 3. Keep every name, so the result can be bit-identical

ModelingToolkit orders summed terms by variable name. A refactor that renames a variable
(`body.drag` → `body.roadload.drag`) moves the last bit of the derivative, and a model with on/off
switching (ABS, PWM, a limiter) amplifies that into a visible change: one ABS braking distance
moved 5e-4 m, past a pin of 1e-4, from a rename alone. Prefer the shape that keeps every name and
path: `extends` the extracted part rather than nesting it, or keep the old instance names.

## 4. Compare

After the compile, re-run the same cases and compare against the baseline: bit-identical `sol.t`
and states is the pass. When something differs, find where:

- include the old `_definition.jl` and the new one in turn in the same session, and compare
  `equations` and `observed` of the compiled systems with names mapped, and the derivative function
  at a few states;
- the first step at which the trajectories part shows whether it is ordering (differences near
  1e-16 that grow) or physics (a difference from the first step).

A difference that is ordering, on a switching model, is the rename of step 3; a test pin finer
than the solver's own noise (vary `reltol` by 10 % on the old model to see it) is a finding for
the report, not a pin to widen silently.

## 5. Run the groups

Every group whose models contain the component, one at a time, then `generated` with its known
failure count from HANDOVER. Snapshot `.ref` files stay unchanged.
