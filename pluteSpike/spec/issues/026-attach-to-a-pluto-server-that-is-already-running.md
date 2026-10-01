# 026 — Attach to a Pluto server that is already running

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 004, 021
- **Traces to** — DESIGN.md § One kernel per running instance; never a multi-tenant server

## Context

`present` always starts its own Pluto. `start_session` calls `Pluto.run!` unconditionally and
there is no way to point it at a server that already exists — so a lecturer who has the notebook
open in Pluto, editing it, and then presents, gets a **second** Pluto server with a second
worker, a second cold start, and the same notebook file open in both.

That last part is the sharp end. `DESIGN.md` puts the deck in a separate file precisely because
Pluto owns the notebook and rewrites it on every edit; two servers with one notebook open are two
processes canonicalising and saving the same path. The design's own reasoning about a write race
applies to this case and nothing prevents it today.

The rest is cost. A worker is roughly 2 GB and a cold start is 29 s on a notebook that loads no
packages, minutes on this course's stack. A lecturer who was already working in Pluto pays both
again, and ends up driving a kernel that is not the one they were just editing in.

**The frontend already attaches to a server it did not start.** `spec/START-HERE.md`'s table of
proven techniques names it — "connect with secret, attach by id, restart if not ready" — and the
browser takes `plutoUrl`, `secret` and `notebook_id` from `/api/session` and connects to Pluto
directly. Nothing in the client knows or cares who started that server. The Julia side is the
only thing insisting.

The `Session` struct is already close enough to prove it: the browser suite's
`kernel_less_session` fabricates a `ServerSession` and a `RunningPlutoServer` to build a Session
pointing at a port nothing listens on, and everything downstream works. Those two fields are
carried for shutdown, not for serving.

## Scope

- `present` can be given a Pluto that is already running, and uses it instead of starting one.
- The notebook is opened on that server if it is not already, with `execution_allowed` set, or
  resolved to the id it already has if it is.
- **A session the deck did not start is never shut down by the deck.** `shutdown!` closes the
  worker and the server unconditionally today; attaching means not owning the lifecycle, and
  taking down a lecturer's editor at the end of a class would be worse than the cost this saves.
- Which mode a run is in is stated where the deck already prints its URLs, so a lecturer can see
  whether Ctrl-C will take a kernel with it.
- A notebook parked in `waiting_for_permission` on someone else's server fails at startup naming
  that, rather than serving a deck whose cards never fill.

## Done when

- Presenting against a running Pluto starts no second server and no second worker, and the cards
  fill from the kernel that was already there.
- Interrupting that run leaves the Pluto server and its worker running.
- Presenting without one behaves exactly as it does now, including shutdown.
- A wrong secret, an unreachable URL and a notebook that is not runnable each fail at startup
  with what a human has to fix.

## Out of scope

- Serving the deck from Pluto's own HTTP server. `http_router_for` is not exported and `run`
  takes no middleware, so adding a route means method-piracy on an internal function of a
  fast-moving dependency. `DESIGN.md` records this; the deck's own server is 173 lines in the
  same process and costs a port, not a runtime.
- Multi-tenancy. This shares a kernel the lecturer already had; it does not serve two of them.
- Noticing that an attached server has died. That is 021, and this issue makes 021 matter more:
  a kernel the deck does not own can go away while the deck is still up.
- Naming the server anywhere but the call. A page that takes the URL instead of a command line
  is 029, and it rewrites this issue's failure modes rather than adding to them: all four of
  the Done-when sentences below put the fault in a terminal at startup.

## How

Cross-process, over Pluto's own HTTP routes. The deck holds no `ServerSession` and no `Notebook`
for a server it did not start, so everything it needs comes over the wire:

| Route | What it answers |
|---|---|
| `GET /auth-check` | Both reachability and the secret. `/ping` cannot: it is exempt from auth. |
| `GET /notebooklist` | The ids that existed before the deck asked. |
| `POST /open?path=…&execution_allowed=true` | The notebook id, whether it opened one or found one. |
| `GET /statefile?id=…` | `process_status`, per-cell `queued`/`running`/`errored`, `in_temp_dir`. |

None of these is exported Julia, but none is method piracy either — they are the routes the
Pluto frontend itself speaks. `Pluto.unpack` decodes the two MsgPack bodies.

**Attaching is opt-in and explicit.** `present(deck; pluto_url, pluto_secret)`. No discovery:
something that finds a Pluto on localhost and adopts it is what a malicious page would like to
be, and the servers this attaches to have no secret to fail against. `pluto_url` together with
`pluto_port` is a contradiction and errors.

**Ownership is decided by id, never by path.** `SessionActions.open` dedupes on
`realpath(notebook.path) == realpath(tamepath(path))`; a deck comparing paths for itself can
disagree with Pluto about identity, and that disagreement is the one that decides whether a
worker dies. So: take the id set from `/notebooklist`, call `/open`, and own the worker only if
the id that came back is new. Any doubt — a `/notebooklist` that failed — owns nothing. Leaking
a worker costs 2 GB until the lecturer closes it; releasing one the deck did not own takes down
a live editing session mid-class.

A lecturer who opens the notebook in the window between the list and the open makes the deck
believe it owns their worker. Milliseconds wide, and the only path that ends in killing someone
else's kernel, so it belongs in a comment at the release site rather than in a surprise.

**Readiness polls `/statefile`, in both modes.** The owned run pays a localhost round trip and a
MsgPack decode to read two booleans it could read off a struct. That is the price of one
implementation of the behavior "presenting without an attached server behaves exactly as it does
now" promises is unchanged; two implementations are how that promise quietly stops being true.

**`Session` stays one type** — `url`, `secret`, `notebook_id`, and an ownership record whose only
consumer is `shutdown!`. The two Pluto objects are reached from four places today and two of them
stop needing them: the id is a `UUID`, and `notebook_to_js` ships `in_temp_dir` as a key. This
also retires `kernel_less_session`, which fabricates a `ServerSession` and a `RunningPlutoServer`
only because the struct demands them.

**Adopted state is kept as found.** Over HTTP the only reset available is `/shutdown` then
`/open`, which is a fresh worker and a cold start — the cost this issue exists to avoid, paid to
reach a state that not attaching would have given for free. `deck_theme` needs no special case:
the deck asserts it on connect already.

**A notebook already parked in `waiting_for_permission` cannot be rescued.** `execution_allowed`
is applied on the load path, after the `NotebookIsRunningException` throw, so passing it does
nothing for a notebook that is already open. Failing is the only option, not a preference.

**What Ctrl-C takes is printed where the URLs are.** The line that already says
`Press Ctrl-C to stop.` says which of the three cases this run is, and the exit message matches
rather than claiming to stop a kernel it leaves running. `edit_url` drops `&secret=` when there
is nothing to put in it.

One line more, in both modes and only when the count is nonzero: how many cards come from cells
that errored. It is the one part of adopted state the deck can call wrong rather than merely
set, and it is the part that shows up on the projector.

Nothing warns that the server has no authentication. `session.jl`'s comment refusing to create a
secretless server has to say why attaching to one is different, or the file argues with itself.

## Done when

- Presenting against a running Pluto starts no second server and no second worker, and the cards
  fill from the kernel that was already there.
- Interrupting that run leaves the Pluto server and its worker running.
- Presenting without one behaves exactly as it does now, including shutdown.
- A wrong secret, an unreachable URL and a notebook that is not runnable each fail at startup
  with what a human has to fix.
