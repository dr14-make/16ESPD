# 023 — Ctrl-C does not always stop `present` cleanly

- **Labels** — `bug` · `priority:high` · `complexity:m`
- **Depends on** — 006
- **Traces to** — DESIGN.md § One kernel per running instance; never a multi-tenant server

## Context

`present` exits non-zero on an interrupt, intermittently. Measured against `with_present`,
which asserts the process stops the way its own last line tells a lecturer it will:

| | runs | result |
|---|---|---|
| main, before 019's tests | 3 | clean every time |
| with 019's tests | 6 | 3 clean, 3 `exit 1` |
| with 025's tests | 4 | 3 clean, 1 `exit 1` |

019 added no Julia code. What it added is browser work that lengthens the window the interrupt
lands in, which is how a race already present became visible — the same way 017's duplicate
modebar only appeared once a card was placed on two slides.

The one trace captured ends in `jl_finish_task` / `start_task`: **the exception is in a
background task, not the main one.** `_block_until_interrupted` is built to catch an
`InterruptException` in the main task, and does. Nothing covers it arriving anywhere else. The
likely shape is that SIGINT lands off the root task, and `shutdown!` then waits on a task that
was already interrupted, so a `TaskFailedException` reaches top level and the process exits 1.

Three of the deaths during that investigation were `earlyoom` rather than this, on a box whose
swap was exhausted. Those are a separate signature — a SIGTERM and exit 143, not exit 1 — and
are not evidence here.

A second trace, from 025's suite, puts the arrival point one frame finer. The exception is not
merely off the main task; it lands in the scheduler's own task-switch path:

```
fatal: error thrown and no exception handler available.
InterruptException()
_jl_mutex_unlock at src/threading.c:1054
jl_mutex_unlock at src/julia_locks.h:80 [inlined]
ijl_task_get_next at src/scheduler.c:461
poptask at ./task.jl:1216
wait at ./task.jl:1228
task_done_hook at ./task.jl:868
jl_finish_task at src/task.c:342
start_task at src/task.c:1264
```

`task_done_hook` runs as a finishing task hands control back, so the interrupt arrives while the
scheduler holds its lock and there is no frame between it and `start_task` that could carry a
handler. That is consistent with the shape above and narrows where a fix has to catch.

**The open question below is answered for this instance, and the answer lowers the stakes.** The
process that exited 1 left no Pluto worker behind: immediately after the run, the only `julia`
processes on the box belonged to the editor's own Dyad Studio (`dyad-3x4x0`), and none from the
suite's channel (`dyad-3x3x0`) survived. So the `finally` does reach `shutdown!` while unwinding,
and what is wrong is the exit code rather than the cleanup. One observation is not every path —
the interrupt could land somewhere else next time — but nothing so far shows a leak.

## Why this is worth a `high`

The path is the one a lecturer uses every single time: Ctrl-C at the end of a class. `present`
holds a Pluto kernel of roughly 2 GB, and its `finally` calls `shutdown!` to take it down. An
exit that fails partway through that is how a kernel is left behind, and this repository has
already lost a session to accumulated orphans.

**Unverified, and worth establishing first:** whether an `exit 1` actually leaves the worker
alive. The finallys run during unwinding, so it may shut down correctly and merely report
badly. That is the difference between a cosmetic exit code and a leak, and it decides how much
the rest of this issue matters.

## Scope

- Establish whether an unclean exit leaves a Pluto worker alive.
- An interrupt stops `present` cleanly wherever it is delivered, not only when it lands in the
  main task.
- The kernel is taken down on every interrupt path.
- The harness's `stopped` report stays the assertion it is; it should have nothing left to
  catch.

## Done when

- Repeated interrupts of `present` under the browser suite stop cleanly, over enough runs to
  mean something against a 3-in-6 baseline.
- No Pluto worker outlives a `present` that was interrupted.
- `mise run deck` still stops on Ctrl-C with the same one-line report a lecturer sees now.

## Out of scope

- The deck's own report of an unreachable kernel — 021. Same family, opposite end: 021 is the
  page not noticing a kernel that died, this is the process not dying tidily.
- `present` not exiting within 60 s when driven with no browser at all, seen while isolating
  this. Pre-existing, separate, and not characterised.

## Note

Not marked `agent-ready`, for a reason that is part of the work: **a 3-in-6 flake cannot be
shown fixed by running it again.** Either the race gets a deterministic reproduction — driving
the interrupt into a chosen window rather than hoping — or the done-condition is a run count
somebody has to justify. Deciding which comes before the fix, not after.

Julia's signal handling is also the kind of thing where the obvious fix and the correct one
differ: `Base.exit_on_sigint`, a handler that closes the server rather than throwing, and
tolerating an already-failed task inside `shutdown!` are three different changes with three
different blast radii.
