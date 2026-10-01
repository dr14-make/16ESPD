# Attach to a running Pluto over HTTP, not in-process

The deck can present against a Pluto server it did not start. The server that matters is the one
the Pluto VS Code extension launches, which is a different process, so the deck holds no
`ServerSession` and no `Notebook` for it and reaches everything over Pluto's own HTTP routes —
`/auth-check`, `/notebooklist`, `/open`, `/statefile` — decoding the MsgPack bodies with the
unexported `Pluto.unpack`. These are the routes Pluto's own frontend speaks, and the deck's
frontend is already coupled to the `notebook_to_js` payload shape they carry.

## Considered options

**In-process.** Thread a `ServerSession` into `present` and skip `Pluto.run!`. Nearly free —
`SessionActions.open`, the `Notebook` object and the existing readiness loop all keep working.
Rejected because it serves only a lecturer who started Pluto programmatically from the REPL they
present from, and the case that motivates the feature is a server in another process.

**Speak Pluto's websocket from Julia.** Live diffs, no polling, and the real protocol. Rejected
for its size and for the surface it would take on a fast-moving dependency, to arrive at the two
booleans `/statefile` already carries.

## Consequences

Readiness polls `/statefile` in **both** modes, including the owned one — so an owned run makes a
localhost round trip and a MsgPack decode to read state it holds in a struct, and gains a failure
mode ("could not reach my own server") it does not have today. This is deliberate. `present`
promises that running without an attached server behaves exactly as it did before, and two
implementations of readiness are how that promise stops being true without anyone noticing.

`Session` therefore carries `url`, `secret` and `notebook_id`, and keeps the Pluto objects only in
an ownership record that nothing but `shutdown!` reads.

Ownership is decided by comparing notebook ids across `/notebooklist` and `/open`, never by
comparing paths: `SessionActions.open` dedupes on `realpath ∘ tamepath`, and a deck that computes
its own path match can disagree with Pluto about whether a notebook was already open. That
disagreement is what decides whether a worker is killed.
