# 004 — Pluto session lifecycle

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 001
- **Traces to** — DESIGN.md § A Julia package serving a prebuilt TypeScript bundle / Runtime

## Context

The spike needed a Node bridge purely because Rainbow's `createWorker` concatenates its upload URL and never forwards the secret. Opening the notebook from Julia removes the bridge and the constraint together.

## Scope

- Start a `Pluto.ServerSession` with the secret required, on a configurable port.
- Open the deck's notebook **in place**, so edits made in the Pluto editor save back to the repository file.
- Set `execution_allowed=true`; without it the notebook parks in `waiting_for_permission`, waiting for a human to click a button no deck can reach.
- Wait for `process_status == "ready"` before reporting the session up.
- Expose the Pluto URL, secret, notebook id, and the Pluto editor URL.

## Done when

- An integration test asserts `process_status` reaches `ready` and every cell reaches a terminal status.
- The running notebook's `path` is the repository file and `in_temp_dir` is false.

## Out of scope

- Any use of `/notebookupload`. It copies the notebook into a scratch directory under a generated name, which silently detaches the running notebook from the repository file.
