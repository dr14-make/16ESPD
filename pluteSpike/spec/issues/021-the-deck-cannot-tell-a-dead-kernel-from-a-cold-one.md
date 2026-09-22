# 021 — The deck cannot tell a dead kernel from a cold one

- **Labels** — `bug` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 012
- **Traces to** — DESIGN.md § Cards show placeholders until the kernel is live

## Context

`deck.js` awaits `connect(session)` before it registers anything. Pluto's client retries a
refused websocket forever rather than rejecting, so against a Pluto that is not there the await
never settles: the `catch` beside it never runs, and every line after it — including the
`onConnectionChange` handler that would set `connected` — is never reached.

So `connected` stays `true`, `kernel` stays `null`, and `kernelStatus` reads `process` as
`null`, which is the cold-start case. The chrome says **"the kernel is starting; cards fill in
when it is"**, and goes on saying it. Watched for 96 seconds while proving the cues render
without a kernel, in the testset 018 added.

`kernelStatus` already has the states this needs. `offline` is reachable only from a drop
*after* a successful connect, and `error` only from a rejection that Pluto's client does not
produce. Both are unreachable on a first connection that never lands.

This is the lecture-hall case rather than a corner. `HANDOFF.md` Risk 2b records Pluto being
OOM-killed twice in one session with the server still answering 200 underneath — a lecturer who
reloads then gets a deck that looks like it is warming up and never will.

The cues themselves are unaffected and render throughout, which is what the browser suite
asserts. This is the chrome lying, not the deck failing.

## Scope

- The deck distinguishes a kernel that has not started yet from one it cannot reach, and says
  which, by probing Pluto's `/ping` while `connect` has not yet landed.
- `offline` and `error` become reachable from a first connection that does not land.
- The deck's own console stays silent about it; Pluto's client logs its own refusals.
- The browser suite asserts the distinction against the unreachable session 018 already builds.

## Done when

- A deck served against a Pluto that is not there reports a kernel it cannot reach, not one
  that is starting.
- A deck served against a Pluto that is slow to start still reports starting, for as long as it
  genuinely is.
- Cues, placeholders and paging keep working in both, as 018 asserts.

## Out of scope

- Reconnecting, retrying or recovering. Saying the true thing is the whole of this issue.
- Cached snapshots, which would let a deck with no kernel still be a complete presentation.
  Deferred in `DESIGN.md` and a much larger piece of work.

## The signal, which Pluto already provides

A timeout cannot tell these two apart — cold start is 29 s on a notebook loading no packages
and minutes on this course's stack, so any deadline short enough to catch a dead kernel would
accuse a live one that is merely slow, in front of a room. Pluto answers the question directly
instead, and answers it the way its own frontend asks it.

`GET /ping` returns `200 "OK!"`. `auth_required` exempts it by path, and `auth_middleware` sets
`Access-Control-Allow-Origin: *` on precisely the responses it did not require auth for — so
the deck's page can fetch it from its own origin, with no secret. Read from
`webserver/Router.jl` and `webserver/Authentication.jl` in Pluto 1.0.3.

That is the pattern Pluto uses on itself. `PlutoConnection.js` catches a failed connection,
waits, and calls `connect()` again — which is why nothing ever rejects — and separately fetches
`/auth-check` on a `CloseEvent` of code 1006 to find out whether it lost authentication or the
server went away. An HTTP probe beside an unresolved websocket is Pluto's own answer.

What `/ping` proves is that the Pluto **server** is alive, which is the case this issue is
about: `earlyoom` kills the Julia process, taking the server with it. The other shape — server
alive, the notebook's worker dead — is already covered, because the websocket connects and
`process_status` reports `no_process`, which `kernelStatus` already maps to `offline`.

So: probe `/ping` while `connect` is outstanding. It answers, and the kernel is genuinely
starting. It does not, and the kernel cannot be reached — which is a different sentence and the
true one.
