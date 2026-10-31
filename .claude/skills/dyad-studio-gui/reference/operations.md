# Studio GUI operations

Each operation with its known Studio bugs beside it. Coordinates are examples from
`resize_window(1600, 1000)` (browser zoom 110 %) with the Dyad sidebar open; the screenshot frame
that gives varies by build and session (1372×868, 1366×896, 1372×882). Take one screenshot per
session and re-measure every landmark from it before clicking.
Items marked **(unverified)** were not reproduced; treat them as hints. After every operation,
**read the file**: `grep` the `.dyad` file for the instance, value, `connect` or placement.

## Diagram landmarks

- **Toolbar**, top left of the canvas, left to right: Search, Zoom In, Zoom Out, **Reset view**,
  **+** (Add Component), **Edit Parameters**, Autolayout, ⚠ (placement warnings). Examples: dyad
  3.4.0, y = 87, x = 289, 325, 351, 377, 413, 449, 485, 511; plugin 3.4.0-rc2, y ≈ 81, Reset view
  x ≈ 369, + 403, Edit Parameters 436, and Reset view x ≈ 147 with the sidebar closed.
- **Reset view** fits the dashed 1000×1000 outline: with the sidebar open it spans x 416–1175 and
  y 75–833 (0.759 px per unit). Zoom In zooms about the canvas center.
- **Preview tabs:** a diagram opened from the tree is a preview tab (italic title) that the next
  tree double-click replaces. Double-click the tab title to keep it (unverified).

## Open, create or rename a component

- **Open:** in COMPONENTS, single-click the component, then press Enter. A double-click sometimes
  does nothing. Reach a tree item by scrolling the tree: `scroll_to` on its ref can scroll the
  whole Theia page and shift every coordinate.
- **Create:**
  1. Right-click the library (`MyCar`); if no menu appears, right-click again.
  2. Click **Add Component** (or Add Module / Add Connector).
  3. Click the `ComponentName` box at the top center (or wait 1 s): text typed sooner lands in the
     tree's type-to-filter box — close that box with its ×.
  4. Type the name and press Enter. The diagram opens; the file is `dyad/<lowercase name>.dyad`.
- **Rename a block:** select it → **Edit Parameters** → pencil next to the name → `zoom` to see the
  name box open and selected → type → Enter. Set parameters before renaming: a rename empties the
  parameter list until the block is reselected.

## Place parts

1. Click **+**. Search has focus and keeps the last term for this diagram: triple-click it, then
   type part of the name.
2. `zoom` on the popup (≈ x 270–530, y 100–640): results are a tree grouped by library, not
   text-readable. Check the library path in the row — hits include look-alikes (`IntakeManifold`
   for "Manifold", four Throttles) and `HandsOn02`/`Test*` models that are a course's answers.
3. `left_click_drag` the result row onto the canvas (a click or Enter on the row does nothing). The
   first drag after a fresh search sometimes drops nothing: check the canvas and drag again. The
   popup stays open for more drops; click **+** again to close it.

Move a placed block by `left_click_drag` from its body.

## Ports

Work on ports **in the component that owns them**: open it from the tree, or right-click an
instance → **Go to definition** (opens or focuses the owner's diagram; press Reset view).

- **Add:** + → `Dyad` › `RealInput` / `RealOutput` (or a library connector such as `Spline`); drop
  it on the outline, or anywhere and move it after.
- **Select:** click the ~20 px **ring just outside the port icon**, e.g. 12 px right of its right
  edge; handles appear. The icon itself starts a wire.
- **Move:** `left_click_drag` from that same ring point; the port moves by the drag delta, so aim at
  the target plus the same offset. Works for ports without placements too: the first move writes
  default placements for all of them.
- **Rename:** port selected → **Edit Parameters** → pencil → `zoom` to see the box open → type →
  Enter. Declaration, relations, `_links` key and `connect`s in other components follow.
- **Orient:** port selected; `r` rotates 90° clockwise (`r` three times for counter-clockwise —
  `Shift+R` from the tool does nothing), `v` flips vertically. `h` and Delete (unverified). Arrow
  keys pan the canvas.
- **Instances follow:** other diagrams redraw the ports at once. A port with one placement uses it
  for both the diagram and the icon; a port whose `icon` and `diagram` boxes are set separately
  keeps them apart, so moving it in its owner's diagram leaves where parents see it.
- **Inherited pins are fixed:** pins that come through `extends` (`TwoPin`'s `p` and `n`) draw
  where the base puts them and ignore the component's own placement metadata. To place them,
  declare the pins directly instead of extending.
- **Ports stacked at the center** (⚠ "connector-placement … add missing metadata"): the component
  has no port placements. Move them in the owner as above, or write them:
  ```dyad
  mdot_thr = RealInput() {"Dyad": {"placement": {"diagram": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}}}}
  ```

## Wire

- `hover` each port to read its tooltip first: icons do not say which input is which.
- `left_click_drag` from the source port icon to the target port icon; a wired port still starts a
  new wire. Ctrl+Z undoes a wrong one.
- Click empty canvas between wire drags: the drag right after a wire is drawn is swallowed.
- **Overlapping ports** (e.g. `spline` under MappedEngine's output triangles): drag the block to the
  canvas center, Zoom In, hover until the tooltip names the port, and wire at that zoom.
- Count `connect(` lines in the file.

## Parameters

Select the block → **Edit Parameters** (with nothing selected, the panel edits the component or the
analysis, e.g. `stop`). For each field: click it → **End** → **Shift+Home** → type → Enter; the value
is written at once. Select field text only this way: Ctrl+A covers the webview in a select-all
overlay that only switching to a *text* editor tab and back clears.

**Add parameter** (nothing selected → Edit Parameters → Add parameter): name, a type from `Real`,
`Integer`, `Boolean` and `String` only, **Value** and **Unit**, then **Create**. A `Voltage` or
`Torque` parameter is `Real` with its unit.

## Code view and editing on disk

- **⇄** opens the code as a separate text tab; the diagram tab stays open.
- **Edit on disk** is the cheapest way to enter code: an open diagram reloads at once, and a later
  Ctrl+S in Studio keeps the disk edit. In a rehearsal, enter code the way a student would.
- **Paste in the GUI:** click in the editor, set the clipboard with
  `navigator.clipboard.writeText(code)` via `javascript_tool`, then Ctrl+A, Ctrl+V, Ctrl+S. To
  insert at a line instead: Ctrl+G, the line number, Enter, End, Ctrl+V. For long code, serve the
  snippets from a small local HTTP server that allows CORS and `fetch` them in the page before
  `writeText`, rather than inlining them in the script. If `writeText` hangs (CDP timeout), the old
  clipboard pastes: `type` the code without leading spaces instead, since Monaco auto-indents and
  auto-closes brackets.
- A "Render Diagram | Flatten Component" code-lens line shifts text ~17 px below where the gutter
  suggests.
- A new component's template ends in a `metadata {…}` block; put `initial` lines and the like
  before it.

## Save

Press Ctrl+S, wait a second, press it again: the first one often leaves the tab dirty (●), and with
the same file's text tab open it once saved the state from before the last wire. The ● proves
nothing either way — diagram edits reach the file without Ctrl+S. Read the file. On plugin
3.4.0-rc2 every Ctrl+S raises "Task Dyad Auto-Compile is already running" and "Run task config does
not return" toasts; they are harmless, close them.

## Analyses

On plugin 3.4.0-rc2, ▷ opens a picker of the library's components and analyses to run, with no
"+ Create New Analysis": paste the `analysis` block as code into the component's `.dyad` file
instead, then pick it from ▷. On dyad 3.4.0:

1. Focus a component's diagram → ▷ (`find "Run Analysis"`) → Enter on "+ Create New Analysis".
2. At "Choose Analysis Type" type `Transient`, Enter.
3. The name box is pre-filled and selected: type the name, Enter. The analysis diagram opens with a
   "[Run]" toast.
4. Set `stop` with Edit Parameters and nothing selected, or in the file.
5. ▷ on the analysis tab: Studio pastes `DyadOrchestrator.run_analysis(…)` into the REPL, compiles,
   runs, and opens a "Julia Plots" tab. The result is the global `solution`.

Run ▷ once before any `MyCar.<Analysis>()` call: the REPL loads `MyCar` at start, and components
created later are undefined there (`isdefined(MyCar, :X)` is false) until a ▷ run reloads them.

## REPL

- Use the REPL Studio started (`Julia REPL (v…)` in the panel). Click into the terminal before
  `type`; newlines submit, multi-line blocks are fine.
- Read output as text: `write("<scratchpad>/out.txt", repr(x))`, then read the file from Bash.
- Signals: `solution.sol(t; idxs = solution."block.var")` with literal names — `r."a.$n"`
  interpolation fails.

## Plots and screenshots

- Plots use Plotly by default and every GUI run resets it, so call `gr()` before `savefig` to PNG.
  At `size = (990, 528)` add `margin = 5Plots.mm` so axis labels are not clipped.
- Diagram shots: hide the sidebar and the panel, then Reset view, then `hover` outside the region
  so the cursor and tooltips stay out of the shot. `zoom` with `save_to_disk` writes a
  full-resolution PNG of the region (honoring `scale`, so save at scale 1); `screenshot` with
  `save_to_disk` writes a JPEG of the frame.

## Toasts

Close toasts with their ×: the "Dyad: compiling…" toast's Cancel sits where a dismiss click lands.
Undo after Rotate restores the file but not the drawing; any other action redraws it.
