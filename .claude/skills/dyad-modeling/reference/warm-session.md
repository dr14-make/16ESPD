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
herdr pane wait-output "$P" --regex 'julia> \s*$' --timeout 100000
```

Keep every `--timeout` under the Bash tool's 120 s default, or the call moves to the background.

First step sent, in this order — Revise tracks only packages loaded after it:

```julia
push!(LOAD_PATH, "@revise"); using Revise
using VehicleSystemsComponents, DyadInterface
```

Then `git diff --stat Project.toml` should be empty. One pane per worktree: the session is bound to
one project.

## Send a step

Number the steps. Write step `n` to a script at an absolute path, then send one line whose sentinel
carries `n`:

```bash
herdr pane run "$P" 'include("/abs/path/step3.jl"); println("__STEP", 3, "_DONE__")'
herdr pane wait-output "$P" --regex '(?m)^__STEP3_DONE__\s*$' --timeout 100000
```

The sentinel is computed, so the echoed command cannot match it, and it is unique per step, so an
earlier step's sentinel still on screen cannot match it either. A step that runs longer than the
timeout: wait again on the same sentinel.

The script writes its results to a file; read that file. Read the pane
(`herdr pane read "$P" --source recent-unwrapped --lines 40`) for errors and stack traces.

## After a compile

`Revise.revise()` at the top of the next step picks up changed and added definitions, new
sublibraries included, in the same session. After deleting or renaming a component, restart:
send `exit()`, then the start lines again — Revise keeps the old name defined.

## Before tests, and at the end

Send `exit()` before running a test group, and when the task ends: the session holds every model it
has compiled, and the machine runs one model-loading Julia at a time.
