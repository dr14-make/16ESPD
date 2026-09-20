# 008 — Kernel client: connect, bonds, settle

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 007
- **Traces to** — DESIGN.md § Implementation notes carried from the spike

## Context

This is where every one of the spike's findings lives. Each bullet below already cost real debugging time once.

## Scope

- Connect with `Host(url + "?secret=")` and attach the worker by notebook id; do not create one.
- Import a shim defining `process`, `process.env.NODE_ENV`, `process.cwd` and `global` **before** the Rainbow bundle. The published ESM build expects a bundler and otherwise throws `ReferenceError: process is not defined`.
- Write a whole batch of bond changes as a single notebook update. One `setBond` per call is one reactive run each, and the early runs see bonds still `missing`.
- Treat a run as settled only when every watched cell's `last_run_timestamp` has advanced **and** the worker is idle. `isIdle()` alone returns true before the run has started.
- Watch every cell the deck reads, not only the root. Downstream cells finish after their dependency, so watching the root hands back the previous run's output.
- State every bond once on load; a widget's own default value is never reported by itself.

## Done when

- An integration test against a fixture notebook drives a bond and observes the dependent cell change.
- Setting six bonds at once produces exactly one reactive run.

## Out of scope

- `worker.execute()`. It races workspace rotation and throws `UndefVarError` for variables the current run has not republished, and its first call writes a hidden cell into the notebook file. Anything the deck needs is published as an ordinary cell.
