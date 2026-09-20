# 005 — HTTP server and the frontend_directory toggle

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 001, 003, 004
- **Traces to** — DESIGN.md § Shape / A Julia package serving a prebuilt TypeScript bundle

## Context

Mirrors Pluto's own static-serving arrangement: source in development, bundle in production, one toggle, content-hashed assets cached hard.

## Scope

- `frontend_directory(; allow_bundled)` choosing `frontend-dist/` when present and `frontend/` otherwise, with an environment override to force the bundle during development.
- Serve that directory, plus `/api/session` (Pluto URL, secret, notebook id) and `/api/deck` (the validated deck).
- Long cache headers only for content-hashed filenames.
- Answer 404 only for a genuinely absent file; any other error is a logged 500.

## Done when

- Each route returns the expected status and content type.
- A test covers development-versus-bundled selection.
- A handler that throws produces a logged 500, never a silent 404.

## Out of scope

- Reverse-proxying Pluto. The browser talks to Pluto directly; Pluto answers `Access-Control-Allow-Origin: *` and accepts websockets from any origin.
- TLS, authentication beyond Pluto's own secret, or any exposure beyond loopback.

## Note

The 404-versus-500 rule is not incidental. In the spike a missing import made every page request throw, the handler answered 404, and the deck looked merely unserved while the real cause stayed invisible.
