# Start here — brief for the first implementing agent

You are picking up a designed, specified, partly de-risked project. Nothing of the package
exists yet. This file tells you what to build first and which rules are not yours to relax.

## Read in this order

1. `../HANDOFF.md` — state of the world, what is proven, four open risks.
2. `PLAN.md` — the fifteen issues, dependency order, status. **Status lives only here.**
3. `../DESIGN.md` — the eight decisions and why each went that way. Do not reopen these.
4. Your issue file in `issues/`.

`../README.md` documents the spike and its ten findings. Read it before writing any frontend
code; every finding cost real debugging time once already.

## Your first task

**Issues 001 + 002 + 003, as one slice.** Package skeleton, read `card` keys from cell
metadata, load and validate `deck.json`.

Take them together because 001 alone is ceremony, and 002 and 003 are the two halves of the
card contract — the thing every later issue depends on. The slice is pure Julia: no browser, no
TypeScript, no Pluto server needed to test it. That is deliberate. It is the only part of this
project you can get fully right without fighting a kernel.

**Done when:** `] test PlutoDeck` is green; a fixture notebook with three carded cells, one
uncarded cell and one duplicate behaves as issue 002 specifies; a deck referencing an unknown
card fails at load naming that card and its slide index.

**Then** 004 + 005 + 006 (open the notebook from Julia, so Node leaves the runtime — the
single biggest quality jump available), then 008, then 011 with 010 and 012 minimal, then 014.

**Skip 007 for now.** Serve ES modules straight from `PlutoDeck.jl/frontend/`, which is what
`frontend_directory()` already does when no bundle is there. A bundler buys content hashing and a smaller
payload, and neither matters until you tag. Standing up a build toolchain before anything
renders is how you spend two days with nothing to show. 013 and 015 likewise wait.

## Ground rules

**Never write under `generated/`.** It is Dyad codegen output and the user regenerates it. It
is frequently dirty for reasons that have nothing to do with you.

**Never hand-edit `backend/notebook.jl` or any Pluto notebook.** Pluto owns that file and
rewrites it on every cell edit; editing it while a kernel is running is a write race, and it is
the reason `DESIGN.md` puts the deck in a separate file. To add or change a cell, go through
the websocket — `waitSnippet` / `updateSnippetCode` — and let Pluto write to disk. This is
proven: the `freq` slider cell was added that way and survived an OOM kill.

**An HTTP 200 is not a health check.** The deck's server has twice kept serving `200` over a
kernel that was dead. The only honest probe changes a bond and confirms a watched cell's
`last_run_timestamp` advances. Write that probe early; you will use it constantly.

**Watch memory, and close what you open.** `earlyoom` here runs `--prefer (julia|node)` and
will kill your kernel without warning. Each Pluto worker is about 2 GB. If you drive a headless
browser, close the tab and kill the browser after each run — do not let instances accumulate.
Check `free -h` before starting anything heavy.

**Do not use `worker.execute()`.** It races Pluto's workspace rotation and throws
`UndefVarError` for variables the current run has not republished, and its first call writes a
hidden cell into the notebook file. Publish anything the deck needs as an ordinary cell.

## Techniques already proven — copy them, do not rediscover them

Working reference code is in the package, at the paths below. These are not suggestions; each
one is a silent failure if you get it wrong.

| What | Where |
|---|---|
| connect with secret, attach by id, restart if not ready | `PlutoDeck.jl/frontend/kernel.js` |
| batch bonds into **one** `update_notebook` | `kernel.js` |
| settle on watched cells' `last_run_timestamp`, not `isIdle()` | `kernel.js` |
| `process` / `global` shim, imported **before** the bundle | `frontend/vendor/browser-shim.js` |
| render a cell through `rainbow/ui`, with the contexts | `frontend/render.js` |
| `<pluto-cell>` wrapper carrying `getPublishedObject` | `frontend/render.js` |
| repaint a card only when its own cell re-ran | `frontend/card.js` |
| one payload per draw, so a card on two slides draws twice | `frontend/published.js` |
| open a notebook in place with `execution_allowed=true` | `src/session.jl` |

The three that fail **silently**, with no exception and nothing rendered:

- `PlutoJSInitializingContext` given anything other than a `Set` — no script runs at all.
- A card with no `<pluto-cell>` ancestor — `execute_scripttags` resolves published objects
  through `root_node.closest("pluto-cell")`, gets null, and the script dies.
- Watching only the root cell when settling — you read the previous run's downstream output,
  which looks exactly like bonds not working.

## The shape of the tree

`PlutoDeck.jl/` is the package and the only code. `backend/` holds the lecture-1 notebook, its
deck file and its speaker cues — content, not implementation.

The spike this directory is named after is gone: its `frontend/`, its Node `bridge/` and
`start.sh` were removed once every technique they proved had a home in the package. `README.md`
keeps the findings, which have not expired. Read the code itself in the history.

`backend/notebook.jl` still carries four cells that are spike scaffolding rather than design —
`script_probe`, `plotly_offline`, `plotly_demo`, `@bind freq` — plus a hidden `eval_in_pluto`
cell left by `worker.execute()` diagnostics. A cell with no `card` key cannot reach a slide, so
they are invisible to every deck; removing them means going through the websocket, because
Pluto owns that file.

## Handing back

Update the status column in `PLAN.md` and nothing else — an issue file is a specification, not
a worklog. If you learn something that changes a decision, say so explicitly rather than
quietly working around it; two findings already did that, and both are recorded in
`../HANDOFF.md` rather than buried in code.
