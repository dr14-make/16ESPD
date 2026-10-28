# The warm session in a Herdr pane

For when `HERDR_ENV=1`. Load the `herdr` skill for the CLI itself.

## Start

```bash
P=$(herdr pane split --current --direction down --cwd <worktree> --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$P" "julia +dyad-3.5.0 --project=. --startup-file=no"
herdr pane wait-output "$P" --regex '(?m)^julia> $' --timeout 120000
```

First step sent: `using Revise`, then `using VehicleSystemsComponents, DyadInterface` — Revise tracks
only packages loaded after it. One pane per worktree: the session is bound to one project.

## Send a step

Write the step to a script at an absolute path, then send one line:

```bash
herdr pane run "$P" 'include("/abs/path/step.jl"); println("__DONE_", 6*7, "__")'
herdr pane wait-output "$P" --regex '(?m)^__DONE_42__\s*$' --timeout 300000
```

The sentinel is computed and matched on its own line, because the pane echoes the command: a
literal sentinel matches the echo before Julia has run anything.

The script writes its results to a file; read that file. Read the pane
(`herdr pane read "$P" --source recent-unwrapped --lines 40`) for errors and stack traces.

## After a compile

`Revise.revise()` at the top of the next step picks up changed and added definitions in the same
session. After deleting or renaming a component, restart: send `exit()`, then the start lines
again — Revise keeps the old name defined.

## End

The pane is the user's to see. Leave it running when the task ends unless the user says
otherwise.
