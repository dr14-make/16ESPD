# Context

The glossary for PlutoDeck: what each word means here, and which distinctions are load-bearing.
Terms only — no implementation, no decisions. Decisions live in `DESIGN.md` and `docs/adr/`.

## Pluto server

One HTTP server holding many notebooks, authenticated (or not) by a single secret covering all
of them. Naming a server and naming a notebook are separate acts: the secret authenticates the
server, the notebook id selects one of its notebooks.

## Worker

The Julia process that runs one notebook's cells. One per notebook, roughly 2 GB. A server with
three notebooks open is one server process and three workers.

Distinct from **kernel**, which this project uses loosely for the same thing seen from the
deck's side — what the cards' content comes from. Prefer *worker* when the count or the cost is
what matters, *kernel* when its liveness is.

## Session

The deck's handle on one notebook running on one Pluto server. It is what the deck presents
against, and it is not the same thing as a Pluto server: several sessions could name one server.

## Owned, attached

A session is **owned** where the deck caused the thing to exist, and **attached** where it found
it already there. The two apply per resource rather than per run: a deck can attach to a server
and own the worker it caused that server to start.

Ownership is the release rule and nothing else — the deck releases what it owns and never what
it attached to.

## Adoption

Presenting against a notebook whose state — bond values, cell outputs — is whatever the previous
driver left. The state is inherited as found, not reset. Adoption is what attaching to a live
notebook buys and what it costs, in the same breath.
