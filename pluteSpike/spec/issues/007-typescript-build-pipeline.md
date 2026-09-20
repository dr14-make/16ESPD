# 007 — TypeScript build pipeline

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 001
- **Traces to** — DESIGN.md § Shape / The built bundle is gitignored in development and force-added on the release commit

## Context

TypeScript is the authoring language; the shipped artifact is a bundle. Node has to be a build-time tool only, never a runtime dependency.

## Scope

- `frontend/package.json`, `tsconfig.json`, and a bundler producing content-hashed output into `frontend-dist/`.
- Emit an `index.html` referencing the hashed assets.
- Vendor `gridstack` and `@plutojl/rainbow`; neither may be fetched at run time.

## Done when

- `npm run build` emits a bundle that `frontend_directory()` serves unmodified.
- The built deck loads with no network access beyond the Pluto server.

## Out of scope

- Publishing the frontend to npm. It may happen later; it is not needed to ship.
