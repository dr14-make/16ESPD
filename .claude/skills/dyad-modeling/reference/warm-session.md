# The warm session in a Herdr pane

For when `HERDR_ENV=1`. Load the `herdr` skill for the CLI itself.

## Revise, once per machine

Revise lives in its own shared environment so loading it leaves the project's `Project.toml` and
Manifest untouched. Check for `~/.julia/environments/revise/`; create it if missing:

```bash
julia +dyad-3.5.0 --project=@revise -e 'using Pkg; Pkg.add("Revise")'
```

## Start

```bash
P=$(herdr pane split --current --direction down --cwd <worktree> --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$P" "julia +dyad-3.5.0 --project=. --startup-file=no"
herdr pane run "$P" 'println("__READY", "__")'
herdr pane wait-output "$P" --regex '(?m)^__READY__\s*$' --timeout 100000
```

Julia reads the queued line once its REPL is up, so the sentinel marks readiness; the prompt itself
is drawn in a way no regex on the pane matches reliably.

Keep every `--timeout` under the Bash tool's 120 s default, or the call moves to the background.

First step sent, in this order — Revise tracks only packages loaded after it:

```julia
push!(LOAD_PATH, "@revise"); using Revise
using VehicleSystemsComponents, DyadInterface
```

Then `git diff --stat Project.toml` should be empty. One pane per worktree: the session is bound to
one project.

## Send a step

Number every send, not every step: a step re-sent after an edit gets a new number, so the old
sentinel still on screen cannot end the wait. Write send `n` to a script in a directory of this
task's own (create a fresh one; a shared scratch directory holds other tasks' `step3.jl`), then
send one line whose sentinel carries `n`:

```bash
herdr pane run "$P" 'try include("/abs/dir/step3.jl") catch err; write("/abs/dir/step3.err", first(sprint(showerror, err), 600)) end; println("__STEP", 3, "_DONE__")'
herdr pane wait-output "$P" --regex '(?m)^__STEP3_DONE__\s*$' --timeout 100000
```

The sentinel is computed, so the echoed command cannot match it. The `try` makes a failing step
reach its sentinel at once and leaves its error in `step3.err`; read that file, not the pane,
where a backtrace scrolls the real line away and an earlier step's error stays on screen. A step
that runs longer than the timeout: wait again on the same sentinel.

The script writes its results to a file; read that file. Write summaries: counts, maxima, a few
named values. A ModelingToolkit problem's kwargs or a whole solution prints the full symbolic
system recursively (one print reached 86 MB). Output that only prints, such as a `@testset`
report, reaches the file through a block that closes it, or the file stays empty:

```julia
open("/abs/dir/step4.out", "w") do io
    redirect_stdio(stdout = io, stderr = io) do
        include("/abs/dir/step4_body.jl")
    end
end
```

A step that runs away: `herdr pane send-keys "$P" ctrl+c`, then send it again under a new number,
since a line queued behind the interrupt is lost.

## After a compile

`Revise.revise()` at the top of the next step picks up changed and added definitions, new
sublibraries included, in the same session. After deleting or renaming a component, restart:
send `exit()`, then the start lines again — Revise keeps the old name defined.

## Before tests, and at the end

An idle session may stay open through a compile or a render. Send `exit()` before running a test
group: the session holds every model it has compiled, and the machine runs one heavy process at a
time (SKILL.md, setup). When the task ends, `herdr pane close "$P"` — the
pane you split, and no other.
