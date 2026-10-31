---
name: dyad-studio-gui
description: Drive Dyad Studio's GUI from Claude in Chrome — build, wire, run and screenshot Dyad models, or rehearse a hands-on as a student would.
disable-model-invocation: true
---

# Driving Dyad Studio from Claude in Chrome

Drive Dyad Studio web (Theia at `localhost:3000`) built at the release tag v3.5.1, with the window
at `resize_window(1600, 1000)`. The observations here were made on dyad 3.4.0 and on the Dyad Studio
plugin 3.4.0-rc2 with the dyad-3.5.0 REPL; where those two differ, operations.md names the build.
A re-check on 3.5.1 is pending, so where 3.5.1 behaves otherwise, trust what you see and tell the
user. Every operation — components, parts, ports, wires, parameters, code, save, analyses, REPL,
plots — is in [`reference/operations.md`](reference/operations.md), each with its known Studio bugs
beside it. Open the section for the operation in front of you.

## Read the file

The `.dyad` file **is** the diagram state: instances, parameter values, `connect`s and every
placement (`metadata._links.<name>.Dyad.placement.diagram`). Diagram edits reach the disk at once,
without Ctrl+S. So after every batch of GUI actions, read the file — `grep` the instance, value,
`connect` or placement — and take a screenshot only when the question is visual.

## What text tools reach

The canvas is HTML inside a cross-origin webview iframe (`*.webview.localhost:3000`): top-page
`find`, `read_page` and `javascript_tool` cannot reach it, so the canvas is pixels only. The rest of
Studio is cheaper by `ref` than by pixel:

| Thing | Reach it by |
| --- | --- |
| Components tree (`module: MyCar`, `component: MyCar.Manifold`, `Add Item (Components)`) | `read_page` on the Dyad panel, or `find` |
| **Run Analysis** (▷), **Toggle Between Code and Diagram View** (⇄) | click the canvas, then `find` — they exist only while a diagram has focus |
| Editor tab close buttons; toasts and their buttons | `find` |
| Blocks, ports, wires, the + popup, the Edit Parameters panel | `zoom` |
| Terminal and REPL output | have Julia write it to a file; read the file |
| The model | the `.dyad` file on disk |

## Setup

1. Unless the user already serves Studio, build and start it as
   [Studio web at a release](reference/operations.md#studio-web-at-a-release) says. Theia and its
   Julia language server are the **one heavy process** while they run: start no compile, test
   group or warm session beside them.
2. `tabs_context_mcp`, then one new tab at `http://localhost:3000/#<absolute workspace path>`. Work
   in this one Studio tab for the whole task: each Studio tab starts its own plugin host, Julia
   language server (~2.6 GB) and Julia REPL (~2.3 GB), which keep running after the tab closes.
   Save every diagram before closing a Studio tab, or leave it open: a dirty diagram raises a
   beforeunload prompt that hangs the extension.
3. On the trust prompt, click "Yes, I trust the authors"; answer any other prompt by asking the
   user.
4. Open the Dyad sidebar by clicking its activity icon (4th, below Source Control; Ctrl+B is
   swallowed while the diagram has focus) and collapse ACTIONS so
   COMPONENTS has room. Keep the sidebar in one state for a whole placement sequence: it can
   re-open by itself and shift the canvas.
5. Commands go through F1 (Chrome can swallow Ctrl+Shift+P): `Dyad: Compile`, `Dyad: Open Julia
   REPL`. Ctrl+J toggles the bottom panel while focus is outside the terminal.

*Done when* the workspace's library shows in COMPONENTS.

## Cost

- **Batch** predictable sequences with `browser_batch` (select → Edit Parameters → pencil, or a run
  of wires) and end each batch with one small `zoom` (`scale` ≈ 0.4–0.6) on the region in question.
- **Zoom** to read port tooltips, popup rows and panel fields, and to find overlapping ports. Take a
  full screenshot only after a layout change: a new tab, the sidebar toggled, Reset view.
- **Refs** for the tree, ▷, ⇄, tab closing and toasts.

## Finish

Stop the Theia task you started, then list what it left behind:
`ps -eo pid,cmd | grep '[l]anguage-julia'`. Studio orphans its Julia language servers whenever
Theia stops or restarts, and they keep their memory and CPU. Report every PID listed to the user.
