---
name: dyad-studio-gui
description: Drive Dyad Studio's GUI from Claude in Chrome — build, wire, run and screenshot Dyad models, or rehearse a hands-on as a student would.
disable-model-invocation: true
---

# Driving Dyad Studio from Claude in Chrome

Drive Dyad Studio web (Theia at `localhost:3000`) built at the release tag v3.5.1, with the window
at `resize_window(1600, 1000)`. Exercised on 3.5.1 with the dyad-3.5.0 REPL: setup, compile,
creating components and modules, placing parts, adding, renaming and moving ports, signal and shaft
wires, Edit Parameters and Add parameter, code-view and on-disk edits, creating and running
transient analyses, the REPL, plots and diagram screenshots. Not rechecked on 3.5.1: items marked
**(unverified)**, the toolbar x/y coordinates and the port orientation keys (measured on dyad
3.4.0 or plugin 3.4.0-rc2). Re-measure those, and wherever 3.5.1 behaves otherwise, trust what you
see and report the deviation to the user.
Every operation is in [`reference/operations.md`](reference/operations.md), each with its known
Studio bugs beside it. Open the section for the operation in front of you.

Three bugs cost the most; avoid them up front:

- `connect` only ports. A nested non-port reference such as `connect(engine.speed.w, y)` stops
  the diagram from drawing; write `y = engine.speed.w` instead.
- Close a diagram before editing its `.dyad` file as text: GUI edits made after a text edit can
  draw but never save.
- Watch memory before every ▷ ([Memory](reference/operations.md#memory)): earlyoom kills the
  REPL, or the plugin host, without a message.

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
   beforeunload prompt that hangs the extension (see [Memory](reference/operations.md#memory) for
   a tab stuck behind "Leave site?").
3. On the trust prompt, click "Yes, I trust the authors"; answer any other prompt by asking the
   user.
4. Open the Dyad sidebar by clicking its activity icon (4th, below Source Control; Ctrl+B is
   swallowed while the diagram has focus) and collapse ACTIONS so
   COMPONENTS has room. Section headers ignore the first clicks after a page load and can toggle
   the wrong section: check which one moved, then click again. Keep the sidebar in one state for a
   whole placement sequence: it can re-open by itself and shift the canvas.
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

Check `generated/` as operations.md's "Compile rewrites `generated/`" says
([Open, create or rename](reference/operations.md#open-create-or-rename-a-component)). Stop the
Theia task you started, then list what it left behind: `ps -eo pid,cmd | grep '[l]anguage-julia'`.
Studio orphans its Julia language servers whenever Theia stops or restarts, and they keep their
memory and CPU. Report every PID listed to the user.
