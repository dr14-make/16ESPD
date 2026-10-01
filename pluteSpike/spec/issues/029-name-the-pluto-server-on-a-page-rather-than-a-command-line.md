# 029 — Name the Pluto server on a page rather than a command line

- **Labels** — `enhancement` · `priority:low` · `complexity:m`
- **Depends on** — 026
- **Traces to** — 026 § How, "Attaching is opt-in and explicit"

## Context

026 attaches to a running Pluto by argument: `present(deck; pluto_url, pluto_secret)`. That is
the right shape for the caller it was designed around — the Pluto VS Code extension knows the
URL because it started the server — and the wrong shape for a lecturer, who has to find the URL
and, if their server has one, the secret, and get both onto a command line before a class.

The secret is the awkward half. 026's own reasoning notes it: a lecturer copying a secret out of
one terminal into another, minutes before a room fills, is a bad place to put a typo.

## Scope

- A page the deck serves that takes the Pluto URL and, optionally, the secret, and attaches once
  it is submitted.
- The three faults 026 fails at startup on — unreachable URL, rejected secret, notebook not
  runnable — are shown on that page, against the field that caused them, rather than in a
  terminal the lecturer has already stopped looking at.
- The argument form keeps working unchanged. A run given `pluto_url` never sees the page.

## Out of scope

- Choosing the notebook. The deck file names it and `load_deck` resolves every card against it
  before anything starts; a picker would make the deck no longer the thing that decides what it
  presents.
- Choosing the deck file. That is a launcher, not a form, and it inverts `present` — today the
  deck is validated before a port is bound, and a `DeckLoadError` is a terminal message rather
  than a rendered page.
- Discovery. Still not this, and for the reasons 026 gives.

## Done when

- A lecturer with a Pluto running and no flag typed reaches an attached deck through the browser
  alone.
- A wrong secret and an unreachable URL are correctable in place, without restarting `present`.

## Note

Not `agent-ready`. Where the form lives is undecided and the answer changes the work: served at
the deck's root before a session exists, which means the deck's own server comes up before the
kernel does and every page has to tolerate a session that is not there yet; or served as an
interstitial only when attaching was asked for without a URL, which keeps today's startup order
and costs a second entry point.
