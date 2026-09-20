# 015 — Release process: build, force-add bundle, tag

- **Labels** — `enhancement` · `tech-debt` · `priority:medium` · `complexity:s` · `agent-ready`
- **Depends on** — 001, 007
- **Traces to** — DESIGN.md § The built bundle is gitignored in development and force-added on the release commit

## Context

A content-hashed bundle changes wholesale on every frontend edit, so it is ignored day to day and force-added only when tagging. The failure mode is tagging a stale bundle, and nothing warns you.

## Scope

- A documented release sequence: rebuild, force-add `frontend-dist/`, commit, tag.
- A check that refuses to tag when the bundle is older than any `frontend/` source file.
- Note in the document that this stays manual until CI does it.

## Done when

- The documented sequence produces a tag whose tree contains the bundle.
- The staleness check fails loudly against a deliberately stale bundle.

## Out of scope

- CI automation. The manual path has to work first.

## Note

Carries `tech-debt`: the payoff is lower future cost rather than new capability.
