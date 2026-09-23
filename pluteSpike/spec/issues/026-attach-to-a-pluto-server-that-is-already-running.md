# 026 — Attach to a Pluto server that is already running

- **Labels** — `enhancement` · `priority:high` · `complexity:m`
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

## Note

Not marked `agent-ready`. Two decisions come before the work.

**How the server is named.** An explicit URL and secret is the safe answer and an awkward one — a
secret on a command line, and a lecturer copying it out of a terminal before a class. Discovery
is friendlier and is a security decision, not a convenience: something that finds a Pluto on
localhost and attaches to it is also something a malicious page would like to do. Pluto itself
requires the secret for exactly this reason.

**What happens when the notebook is already open there.** Reusing the open notebook is the point,
but its state is whatever the lecturer left it in — bonds already moved, cells already run, a
`deck_theme` that is not this deck's. Deciding whether the deck adopts that state or resets it is
a behavioural choice a lecturer will notice.
