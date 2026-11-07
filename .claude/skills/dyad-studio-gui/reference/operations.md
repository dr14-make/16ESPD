# Studio GUI operations

Each operation with its known Studio bugs beside it. Coordinates are examples from
`resize_window(1600, 1000)` (browser zoom 110 %) with the Dyad sidebar open; the screenshot frame
that gives varies by build and session (1372×868, 1366×896, 1372×882, 1347×896, 1376×868) and can
change in the middle of a session; `resize_window` does not restore it. Take one screenshot per
session, and another whenever clicks start missing, and re-measure every landmark from it.
Items marked **(unverified)** were not reproduced; treat them as hints. After every operation,
**read the file**: `grep` the `.dyad` file for the instance, value, `connect` or placement.

## Studio web at a release

Dyad Studio releases (JuliaComputing/dyad-theia) ship desktop installers only, so build the web app
from the dyad-theia repo at the release tag; v3.5.1 pins the Dyad Studio plugin at 3.5.1. Build in
a fresh worktree at the tag, so the build holds the release and nothing else:

```sh
wt -C <dyad-theia> switch --create <local-branch> --base v3.5.1   # prints the worktree path
cd <worktree> && export GITHUB_TOKEN=$(gh auth token)              # install and build download the plugin
pnpm install && pnpm build:web
cd apps/web && npx theia start <workspace> --hostname=127.0.0.1 --port=3000 --plugins=local-dir:plugins
```

Start the last line as a background task: it is the Theia task to stop when done (SKILL.md,
Finish). The CLI and Julia stay where HANDOVER puts them: `npx -y @juliacomputing/dyad-cli@3.5.0`
(the newest on npm) and `julia +dyad-3.5.0`.

## Diagram landmarks

- **Toolbar**, top left of the canvas, left to right: Search, Zoom In, Zoom Out, **Reset view**,
  **+** (Add Component), **Edit Parameters**, Autolayout, ⚠ (placement warnings). Examples: dyad
  3.4.0, y = 87, x = 289, 325, 351, 377, 413, 449, 485, 511; plugin 3.4.0-rc2, y ≈ 81, Reset view
  x ≈ 369, + 403, Edit Parameters 436, and Reset view x ≈ 147 with the sidebar closed.
- **Reset view** fits the dashed 1000×1000 outline: with the sidebar open it spans x 416–1175 and
  y 75–833 (0.759 px per unit). Zoom In zooms 2× about the canvas center.
- **Pan** with horizontal mouse scroll (`scroll` left/right) and vertical scroll; arrow keys do not
  pan.
- **Preview tabs:** a diagram opened from the tree is a preview tab (italic title) that the next
  tree double-click replaces. Double-click the tab title to keep it (unverified).

## Open, create or rename a component

- **Open:** in COMPONENTS, single-click the component, then press Enter. A double-click sometimes
  does nothing. Quick-open (Ctrl+P) of a `.dyad` file opens the text editor; its "Render Diagram"
  code lens opens the diagram. Reach a tree item by scrolling the tree: `scroll_to` on its ref can
  scroll the whole Theia page and shift every coordinate.
- **Create:**
  1. Right-click the library (`MyCar`); if no menu appears, right-click again.
  2. Click **Add Component** (or Add Module / Add Connector).
  3. Click the `ComponentName` box at the top center (or wait 1 s): text typed sooner lands in the
     tree's type-to-filter box — close that box with its ×.
  4. Type the name and press Enter. The diagram opens; the file is `dyad/<lowercase name>.dyad`.
     The box rejects a dotted name (`MyModule.Name`).
- **Create inside a module:** Add Module creates an empty folder `dyad/<Module>/`, and COMPONENTS
  does not show it until it holds a `.dyad` file and the library recompiles; right-clicking a
  module row shows no menu.
  1. Create the component at the library root as above.
  2. Before placing it anywhere, close its diagram and move its file into the module folder on
     disk. The move changes its qualified name (`MyCar.X` → `MyCar.Module.X`): update every
     reference to the old name.
  3. F1 › `Dyad: Compile` (auto-compile can be off). The module now shows in COMPONENTS. The
     generated files for the old root path stay behind; the `generated/` check below lists them.
  4. Use the **+** on the module's row (Component / Connector / Module) for every further
     component: it creates `dyad/<Module>/<lowercase name>.dyad`.
- **Compile rewrites `generated/`:** `Dyad: Compile` rewrites committed `generated/*.jl` files
  (`module.jl`, `tests.jl`, and any whose docstrings have drifted). After each compile run
  `git status --short generated/`:
  - a tracked file the task did not mean to change (` M`): hand the user a `git restore <file>`
    line;
  - an untracked new file (`??`), stale ones from a moved component included: list it for the
    user to remove (`git restore` does not touch untracked files).
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
4. A part with conditional connectors (MappedEngine's `fuel_enable`, EnergyManager's `T_lim` and
   `available_torque`) raises a placement-warning toast on each drop and draws those ports even
   when their condition is false. Close the toast; the part is fine.

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
  `Shift+R` from the tool does nothing), `v` flips vertically. `h` and Delete (unverified).
- **Instances follow:** other diagrams redraw the ports at once. A port with one placement uses it
  for both the diagram and the icon; a port whose `icon` and `diagram` boxes are set separately
  keeps them apart, so moving it in its owner's diagram leaves where parents see it.
- **Inherited pins are fixed:** pins that come through `extends` (`TwoPin`'s `p` and `n`) draw
  where the base puts them and ignore the component's own placement metadata. To place them,
  declare the pins directly instead of extending.
- **Not every reference is a port.** Variables inside a part — `engine.speed.w`,
  `drive.machine.tau`, `k0.position`, `drive.battery.E`, `drive.battery.i`,
  `engine.torque_map.full_load.y` — have no port icon and cannot be wired in the diagram. Export
  one through an output port with an equation in code, never a `connect`:
  ```dyad
  engine_speed = engine.speed.w
  ```
  `connect(engine.speed.w, engine_speed)` stops Studio from drawing the whole diagram ("Connector
  reference engine.speed.w isn't supported").
- **Ports stacked at the center** (⚠ "connector-placement … add missing metadata"): the component
  has no port placements. Move them in the owner as above, or write them:
  ```dyad
  mdot_thr = RealInput() {"Dyad": {"placement": {"diagram": {"x1": -50, "x2": 50, "y1": 200, "y2": 300}}}}
  ```

## Wire

- `hover` each port to read its tooltip first: icons do not say which input is which.
- `left_click_drag` from the source port icon to the target port icon; a wired port still starts a
  new wire. Ctrl+Z undoes a wrong one.
- Click empty canvas between wire drags: the drag right after a wire is drawn is swallowed. Some
  drags are swallowed even so: retry, and count `connect(` lines in the file after each batch.
  If the count never moves although the wire draws, the diagram has gone stale after a text edit:
  close and reopen it ([Code view](#code-view-and-editing-on-disk)).
- **Overlapping ports** (e.g. `spline` under MappedEngine's output triangles): drag the block to the
  canvas center, Zoom In, hover until the tooltip names the port, and wire at that zoom.
- **Ports that cannot be hit:** MappedEngine's `mdot_fuel` (eight outputs stacked on its right edge;
  drops land on `lambda` or `mdot_co2` at 1× and 2×) and PlanarCar's `spin_fr` (under `tau_fr`; the
  drop raises "incompatible connectors Spline → RealInput"). Write those `connect`s in code.
- `connect`s inside an `if` block are not drawn. `connect`s entered in code draw as diagonals; to
  tidy a diagram for a screenshot, see [Plots and screenshots](#plots-and-screenshots).

## Parameters

Select the block → **Edit Parameters** (with nothing selected, the panel edits the component or the
analysis, e.g. `stop`). For each field: click it → **End** → **Shift+Home** → type → Enter; the value
is written at once. Select field text only this way: Ctrl+A covers the webview in a select-all
overlay that only switching to a *text* editor tab and back clears.

**Add parameter** (nothing selected → Edit Parameters → Add parameter): name, a type from `Real`,
`Integer`, `Boolean` and `String` only, **Value** and **Unit**, then click **Create** twice (the
first click does nothing). A `Voltage` or `Torque` parameter is `Real` with its unit. The form has
no structural option: write `structural parameter …` in code, along with conditional declarations
(`… if flag`), conditional `connect`s and `ifelse` values.

## Code view and editing on disk

- **⇄** opens the code as a separate text tab; the diagram tab stays open.
- **After any text edit, close the diagram and reopen it**, then confirm one GUI edit reaches the
  file by grepping it. Edited on disk with the diagram open, the diagram redraws the edit, yet
  every later GUI move or wire in that tab draws and is never written. Whether a Ctrl+S in the ⇄
  text tab desyncs the open diagram the same way is **(unverified)**: apply the same rule.
- **Edit on disk** is the cheapest way to enter code; close the diagram first. In a rehearsal,
  enter code the way a student would.
- **Paste in the GUI:** click in the editor, set the clipboard with
  `navigator.clipboard.writeText(code)` via `javascript_tool`, then Ctrl+A, Ctrl+V, Ctrl+S, then
  close and reopen the diagram as above. To
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

1. Focus a component's diagram → ▷ (`find "Run Analysis"`) → Enter on "+ Create New Analysis".
2. At "Choose Analysis Type" type `Transient`, Enter.
3. The name box is pre-filled and selected: type the name, Enter. The analysis diagram opens with a
   "[Run]" toast.
4. Edit Parameters with nothing selected sets `stop`, `dtmax` and the rest; the **alg** and
   **optimize** dropdowns write `Dyad.ODEAlg.Rodas5P()` and `Dyad.OptimizationLevel.None()`.
5. ▷ on the analysis tab: Studio pastes `DyadOrchestrator.run_analysis(…)` into the REPL, compiles,
   runs, and opens a "Julia Plots" tab. The result is the global `solution`.

An analysis cannot set a structural parameter of its model: make a `test component` that
`extends Model(flag = true)` and create the analysis on that. Plugin 3.4.0-rc2 has no "+ Create New
Analysis" in the ▷ picker: paste the `analysis` block into the `.dyad` file there.

Run ▷ once before any `MyCar.<Analysis>()` call: the REPL loads `MyCar` at start, and components
created later are undefined there (`isdefined(MyCar, :X)` is false) until a ▷ run reloads them.
After ▷, use `r = solution` rather than calling the analysis again: a second call re-solves and
doubles the memory peak.

## Memory

A long transient (1800 s) peaks at 3–4 GB in the REPL on top of the language server (~2.6 GB) and
the REPL itself (~2.3 GB). earlyoom kills the REPL, or the plugin host, right after Studio's
automatic plot, even with 8 GB available beforehand.

- Before each ▷, read the `available` column of `free -m` and require **12000 MB** (a chosen
  margin above the observed 8 GB failure; the threshold itself is **(unverified)**). Below it,
  start nothing heavy beside Studio and recheck every 2 minutes. After 10 minutes still below,
  stop: list the largest processes (`ps -eo pid,rss,cmd --sort=-rss | head`) for the user and wait
  for their answer instead of polling.
- Work in one Studio tab only.
- Close the "Julia Plots" tab as soon as it opens, and every earlier one.
- **REPL killed:** its terminal tab vanishes with no message. F1 › `Dyad: Open Julia REPL`, then
  ▷ again; every REPL global, `solution` included, is gone.
- **Plugin host killed:** Studio shows "Plugin runtime crashed … reload", and the tab's REPL and
  language server are gone. Open a new Studio tab (Setup step 2) and carry on there.
- **Tab stuck behind "Leave site?"** (a dead tab, or a tab closed with a dirty diagram): the
  extension can neither close nor reload it. Ask the user to close it and answer "Leave".

## REPL

- Use the REPL Studio started (`Julia REPL (v…)` in the panel). Click into the terminal before
  `type`; newlines submit, multi-line blocks are fine.
- Read output as text: `write("<scratchpad>/out.txt", repr(x))`, then read the file from Bash.
- Signals: `solution.sol(t; idxs = solution."block.var")` with literal names — `r."a.$n"`
  interpolation fails.
- **Check numbers at solver points or a fine grid:** `t = solution.sol.t`, or `0:0.01:T`. A 0.1 s
  grid misses peaks and thresholds (a max speed error 1.5 % low, a minimum speed 15 rpm high), so a
  claim checked there can pass or fail wrongly.

## Plots and screenshots

- The dyad-3.5 kernel has no GR (`gr()` throws "Package GR not found"), and plotly's `savefig`
  writes 700×500 whatever `size` says. Save SVG with the repo's own helper, which the figure
  export scripts use:
  ```julia
  using Plots; import PlotlyBase, PlotlyKaleido; plotly()
  include(joinpath(pkgdir(VehicleSystemsComponents), "scripts/plotly_svg.jl"))
  save_svg(plot(...; size = (990, 528)), "<run folder>/plot.svg")
  ```
- **PNG (unverified):** copy `save_svg`'s body with `format = "png"`. Keep all three of its fixes:
  `line.simplify = false` on every trace, `place_legends!` for per-subplot legends, and the
  non-empty file check. Then confirm the PNG exists and is non-empty before using it.
- Diagram shots: hide the sidebar and the panel, then Reset view, then `hover` outside the region
  so the cursor and tooltips stay out of the shot. While a port tooltip shows, `zoom` and
  `screenshot` time out (30 s): move the cursor off the canvas first. `zoom` with `save_to_disk`
  writes a full-resolution PNG of the region (honoring `scale`, so save at scale 1); `screenshot`
  with `save_to_disk` writes a JPEG of the frame.
- **Tidy a diagram for a shot** by editing placements on disk (diagram closed): set each block's
  `metadata._links.<name>.Dyad.placement.diagram` box to a clean grid, and line the ports up in a
  column on the outline (the `x1`/`x2` of one edge, evenly spaced `y1`/`y2`). A code-entered wire
  is a straight line between its two ports, so it lies flat only when they share a `y` (or `x`).

## Toasts

Close toasts with their ×: the "Dyad: compiling…" toast's Cancel sits where a dismiss click lands.
Undo after Rotate restores the file but not the drawing; any other action redraws it.
