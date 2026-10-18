---
name: dyad-studio-gui
description: Drive Dyad Studio's GUI (VS Code, Theia desktop or web at localhost:3000) from Claude in Chrome to build, wire, run or screenshot Dyad models, or to rehearse a hands-on as a student would. Load before the first click in a Studio diagram, the Components tree, the + library popup, Edit Parameters, or the Studio Julia REPL.
---

# Driving Dyad Studio from Claude in Chrome

Verified in Dyad Studio web (Theia build, dyad 3.4.0), window `resize_window(1600, 1000)`. Items
marked **(unverified)** were not reproduced; treat them as hints.

## Orientation: what text tools can and cannot see

The diagram is HTML custom elements inside a cross-origin webview iframe
(`*.webview.localhost:3000`). Top-page `find`, `read_page` and `javascript_tool` cannot reach it,
so everything on the canvas is pixel-only. Plenty of the Studio outside the canvas is
text-addressable, and is cheaper to drive by `ref`:

| Thing | Text tools? | How |
| --- | --- | --- |
| Components tree (`module: MyCar`, `component: MyCar.Manifold`, `Add Item (Components)`) | yes | `read_page` on the Dyad tab panel, or `find` |
| Editor title actions: **Run Analysis** (▷), **Toggle Between Code and Diagram View** (⇄) | yes, only while a diagram has focus | click the canvas first, then `find "Run Analysis"` → click by ref |
| Editor tab **Close** buttons | yes | `find "close button for X tab"` |
| Toasts and their buttons (Run, Cancel) | yes | `find` |
| Diagram blocks, ports, wires, + popup, Edit Parameters panel | no | screenshot / `zoom` |
| Terminal and REPL output (xterm) | no | write it to a file (see REPL) or `zoom` |
| The model itself | yes | read the `.dyad` file on disk |

The `.dyad` file **is** the diagram state: instances, parameter values, `connect`s and every
placement (`metadata._links.<name>.Dyad.placement.diagram`). Diagram edits are written to disk at
once, so `grep` or `cat` the file instead of screenshotting to check a result. There is no `dyad`
CLI on PATH, and the "Render Diagram" code lens only opens the diagram editor.

Coordinates below are for the 1372×868 screenshot frame that `resize_window(1600, 1000)` produces
(browser zoom 110 %), with the Dyad sidebar open.

## Setup

- **Tabs:** call `tabs_context_mcp`, then open one tab and navigate to `http://localhost:3000/#<abs path of the
  workspace>`. Each Studio browser tab starts its own plugin host, a Julia language server (~2.6 GB) and
  a Julia REPL (~2.3 GB), and they keep running after the tab closes. Never open a second Studio tab.
- **Trust prompt:** if one appears, click "Yes, I trust the authors". Accept nothing else.
- **Sidebar:** the Dyad activity icon is the 4th in the left activity bar, below Source Control. Collapse
  ACTIONS so COMPONENTS gets room. Keep the sidebar either open or closed for a whole placement
  sequence: it can re-open by itself and shift the canvas.
- **Commands:** F1 opens the command palette (Chrome may eat Ctrl+Shift+P). Use `Dyad: Compile` and
  `Dyad: Open Julia REPL` from there.
- **Panel:** Ctrl+J toggles the bottom panel, but only while focus is not in the terminal.

## Diagram landmarks

- **Toolbar:** top left of the canvas. Left to right: Search, Zoom In, Zoom Out, **Reset view**,
  **+** (Add Component), **Edit Parameters**, Autolayout, ⚠ (placement warnings). At 1600×1000 they
  sit at y = 87, x = 289, 325, 351, 377, 413, 449, 485, 511.
- **Reset view:** fits the dashed 1000×1000 outline. With the sidebar open it spans x 416–1175 and
  y 75–833 (0.759 px per unit). Zoom In zooms about the canvas center.
- **Tabs:** a diagram opened from the tree is a *preview* tab (italic title), and the next tree
  double-click replaces it. To keep it, double-click the tab title (unverified).

## Open, create or rename a component

- **Open:** double-click it in COMPONENTS (a single click only selects).
- **Create:**
  1. Right-click the library (`MyCar`). If no menu appears, right-click again; the first one
     sometimes shows nothing.
  2. Click **Add Component** (or Add Module / Add Connector).
  3. Wait 1 s, or click the `ComponentName` box at the top center. Text typed sooner lands in the
     tree's type-to-filter box instead; close that box with its ×.
  4. Type the name and press Enter. The diagram opens. The file is `dyad/<lowercase name>.dyad`.
- **Rename a block:** select it → **Edit Parameters** → pencil next to the name. **Zoom to check
  that the name box is open and selected**, then type and press Enter. Text typed before the box
  opens is lost. A rename empties the parameter list until you reselect the block, so set
  parameters first.

## Place parts

1. Click **+**. The Search box has focus and keeps the last term for this diagram, so triple-click
   it before typing a new one.
2. Type part of the name. Results are a tree grouped by library, and nothing on it is
   text-readable, so `zoom` on the popup (≈ x 270–530, y 100–640).
3. `left_click_drag` from the result row to the canvas. Clicking a row or pressing Enter does
   nothing. The popup stays open for more drops; click **+** again to close it (Escape does not).

Search hits include look-alikes, such as `IntakeManifold` for "Manifold", four Throttles, and
`HandsOn02`/`Test*` models that are a course's answers. Check the library path in the row.
To move a placed block, `left_click_drag` from its body.

## Ports belong to their component

Place, move and rename ports **in the component that owns them**, never on an instance in another
diagram. To get there:

- open the component from the Components tree; or
- right-click the instance in the other diagram → **Go to definition**. This opens or focuses the
  owner's diagram (a new preview tab if it was closed; press Reset view).

Then, in the owner's diagram:

- **Add:** + → `Dyad` › `RealInput` / `RealOutput` (or a library connector such as `Spline`). Drop it
  straight on the outline, or anywhere and move it after.
- **Select:** click the ~20 px **ring just outside the port icon**, e.g. 12 px right of its right
  edge. Handles appear. Clicking the icon itself starts a wire, and Edit Parameters then shows the
  parent component instead. Clicking further than the ring away deselects.
- **Move:** `left_click_drag` starting from that same ring point. The port moves by the drag delta,
  so aim the end point at the target plus the same offset. This works for ports that have no placement
  yet, too: Studio writes default placements for all of them on the first move.
- **Rename:** with the port selected → **Edit Parameters** → pencil → check the box is open →
  type → Enter. The declaration, the relations and the `_links` key are renamed, and so are
  `connect`s to it in other components (seen with one user component).
- **Orient:** with the port selected, `r` rotates 90° clockwise and `v` flips vertically. `Shift+R`
  sent by the tool does nothing; press `r` three times instead. `h` (flip horizontal) is
  unverified. Delete removes (unverified). Arrow keys pan the canvas; they do not nudge.
- **Instances follow:** another diagram using the component redraws its ports at once, no save
  needed. The diagram placement is also used for the icon.

A component pasted or written without port placements draws all ports stacked at its center in other
diagrams (⚠ "connector-placement … add missing metadata"). Fix it by moving the ports in the owner,
as above, or by writing placements in code:

```dyad
mdot_thr = RealInput() {"Dyad": {"placement": {"diagram": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}}}}
```

## Wire

- **Read the ports first:** port icons do not say which input is which. `hover` each port to read
  its tooltip.
- **Draw:** `left_click_drag` from the source port icon to the target port icon. Dragging from a port
  that is already wired starts a new wire.
- **Undo:** Ctrl+Z undoes a wrong wire.
- **Check:** grep the file for `connect(` and count them.
- **Hidden ports:** if two ports overlap, as `spline` does under MappedEngine's output triangles, drag the block to
  the canvas center, Zoom In, hover until the tooltip names the port, then wire at that zoom (notes).

## Parameters

Select the block, then click **Edit Parameters**. With nothing selected, the panel edits the
component itself or the analysis (e.g. `stop`). To set a field:

1. Click the field.
2. Press **End**, then **Shift+Home**.
3. Type the value and press Enter. The value is written at once.

Never press Ctrl+A in the panel. The value is still written, but the whole webview gets a blue
select-all overlay. Only switching to a *text* editor tab and back clears it; another diagram tab
does not. Triple-click worked once in the probes and failed once in the rehearsal. Verify with
`grep <instance> dyad/<file>.dyad`.

## Code view, pasting, and editing on disk

- **Toggle:** ⇄ opens the code as a separate text tab; the diagram tab stays open.
- **Edit on disk:** writing the `.dyad` file with the shell is the cheapest way to enter code. An
  open diagram reloads at once, and a later Ctrl+S in Studio does not overwrite the disk edit.
  Mind a rehearsal's rules: a student would type in the GUI.
- **Paste in the GUI:** click in the editor, then set the clipboard with
  `navigator.clipboard.writeText(code)` via `javascript_tool`, then Ctrl+A, Ctrl+V, Ctrl+S (notes).
  If `writeText` hangs (CDP timeout), the old clipboard pastes; clear it and `type` the code without
  leading spaces, because Monaco auto-indents and auto-closes brackets.
- **Click offset:** a "Render Diagram | Flatten Component" code-lens line shifts text ~17 px below
  where the gutter suggests (notes).
- **Template:** a new component's template ends in a `metadata {…}` block; put `initial`
  lines and the like before it.

## Save and verify on disk

- **Save twice:** press Ctrl+S, wait a second, and press it again. Right after a diagram edit, the
  first Ctrl+S often leaves the tab dirty (●). In the rehearsal, with the text tab of the same file
  open, it also saved the state from before the last wire.
- **Verify:** the tab's ● is not proof either way. Diagram edits reach the file without any
  Ctrl+S, so grep the file.

## Analyses: ▷ first, then the REPL

1. **Create:** focus a component's diagram → ▷ (`find "Run Analysis"`) → Enter on "+ Create New
   Analysis".
2. **Type:** at "Choose Analysis Type", type `Transient` and press Enter.
3. **Name:** the box is pre-filled and selected, so type the name and press Enter. The analysis
   diagram opens with a toast "[Run]".
4. **Set parameters:** set `stop` with Edit Parameters and nothing selected, or in the file.
5. **Run:** ▷ on the analysis tab. Studio pastes `DyadOrchestrator.run_analysis(…)` into the REPL,
   compiles, runs, and opens a plot in a "Julia Plots" tab. The result is the global `solution`.

Do this before any `MyCar.<Analysis>()` call. The REPL loads `MyCar` once at start, and components
created later are undefined there (`isdefined(MyCar, :X)` is false) until a ▷ run reloads them.

## REPL

- Click into the terminal before `type`. Newlines submit, and multi-line blocks are fine.
- Use the REPL Studio already started (`Julia REPL (v…)` in the panel); start no other Julia.
- **Read output as text:** have Julia write to a file and `cat` it from Bash:
  `write("<scratchpad>/out.txt", repr(x))`. This beats zooming on the xterm.
- **Signals:** `solution.sol(t; idxs = solution."block.var")`. Use literal names: `r."a.$n"`
  interpolation fails (notes).

## Plots and screenshots

- Plots open in a "Julia Plots" tab, with the Plotly backend by default, so `savefig` to PNG fails.
  Call `gr()` first; every GUI run resets the backend to Plotly. At `size = (990, 528)` add
  `margin = 5Plots.mm` so the axis labels are not clipped (notes).
- **Diagram shots:** hide the sidebar and the panel, then press Reset view.
- `save_to_disk` screenshots come out 1372×868 at this window size. Save at scale 1.
- Use `zoom` with `scale` ≈ 0.4–0.6 on the region you need instead of full screenshots.

## Known Studio bugs and workarounds

| Bug | Workaround |
| --- | --- |
| First right-click on the tree sometimes shows no menu | right-click again |
| Typing right after Add Component goes to the tree filter | wait 1 s or click the name box |
| Ctrl+S leaves the tab dirty and can save the state before the last edit | Ctrl+S twice, then grep |
| Ctrl+A in the parameter panel covers the webview with a select-all overlay | End, Shift+Home; to clear the overlay, switch to a text tab and back |
| Rename empties the parameter list | set parameters first, or reselect the block |
| Rename box opens late, so typed text is lost | zoom to check the box first |
| Placement-less ports stack in the center | move them in the owner (ring-drag), or write placements |
| Port icon click never selects the port | click the ring just outside the icon |
| `Shift+R` from the tool does nothing | `r` three times |
| REPL misses components made after it started | ▷ the analysis first |
| "Dyad: compiling…" toast's Cancel sits where you click to dismiss | close toasts with their × |
| Escape does not close the + popup | click + again |
| Undo after Rotate restores the file but not the drawing (notes) | do any other action |

## Cost

- **Read, don't look:** the `.dyad` file answers "did it work?" for instances, parameters, wires,
  names and placements. Grep it after every batch instead of taking a screenshot.
- **Batch:** use `browser_batch` for predictable sequences (select → Edit Parameters → pencil, or a
  run of wires), and end the batch with one small `zoom` rather than a full screenshot.
- **Use refs:** the tree, ▷, ⇄, tab closing and toasts are cheaper by `find` and ref than by
  pixel hunting.
- **When to zoom:** to read port tooltips, popup rows and panel fields, and to find overlapping
  ports. Full screenshots only after layout changes: a new tab, the sidebar toggled, or Reset view.
