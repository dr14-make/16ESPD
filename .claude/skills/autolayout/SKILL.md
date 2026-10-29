---
name: autolayout
description: Lay out a Dyad diagram by editing its .dyad metadata, prove the change is metadata-only, and check it in a render.
disable-model-invocation: true
argument-hint: <Library.Module.Component> ...
---

# Laying out Dyad diagrams

Lay out $ARGUMENTS. Layout is written by hand in the `.dyad` file and checked in a render. Dyad's
`agent_resources/docs/metadata.md` leaves layout to the GUI; this repo writes it on purpose, and every
change is proven metadata-only.

Studio is read-only here: look in it, edit the file. A single Ctrl+S in Studio rewrites the whole file
(docstrings, declaration order, wire ids), and the metadata-only proof fails.

## Steps

1. **Check the structure is settled.** Layout comes last: a new connector or a rebuilt bench moves
   everything. Fix these in the model first, and report them instead of routing around them:
   - two wires looping between the same two blocks are one physical link, so make them one connector
     (as `Vehicle.GasPort` did for engine↔booster);
   - a signal set by an equation draws no wire, so its loop looks open until it is wired through blocks;
   - one output fed to several inputs through separate two-ended `connect`s branches with no junction
     dot, so a branch looks like a bend; one `connect` listing every end gets junctions (rule 4).

   Done when every block, port and `connect` exists and the user has no structural change pending.

2. **Render and check the baseline.** Record `<base>` with `git rev-parse HEAD`. `Lib.A.B.Name` lives in
   a file under `dyad/A/B/`; `grep -rlw "component Name" dyad/` finds it. From the repo root, with
   `K=.claude/skills/autolayout` and an absolute PNG path in your scratchpad:
   ```sh
   $K/render.sh <Lib.A.B.Name> <scratchpad>/before.png      # also writes before.svg
   julia $K/check.jl <file.dyad> <Name> <scratchpad>/before.svg
   ```
   The `.jl` scripts run on Dyad's own Julia, which bundles their JSON and OrderedCollections; run
   them without `--project`, so the bundled copies load.
   This renders the file as it is on disk, uncommitted edits included. `check.jl` lists diagonals,
   crossings, overlapping wires, wires through blocks or labels, and anything outside the outline; its
   exit status is the problem count. Read the PNG too, for what a script can't judge: flow, lanes, empty
   canvas, a wire looping around its target, and labels drawn above a block. At the default size, PNG
   pixel = diagram coordinate + 200. A child's port positions are in the child's own file, but the
   exact point a wire meets (a `Constant` output sits at x2 + 4, not x2) is the end of its SVG path.

3. **Edit the `_links` entries** to fix every item. Write the new values as a JSON spec
   (`{"tag": <new value>}`) and run `julia $K/apply.jl <file.dyad> <Name> <spec.json>`. It replaces
   one-line entries and adds tags that have none yet. Syntax and its traps: [Metadata](#metadata).

4. **Prove it metadata-only:** `$K/metadata-only.sh <base> <file.dyad>` is silent and exits 0 when only
   `metadata` and `{^tag}`s changed; anything else prints a diff.

5. **Render and check again.** Repeat steps 3–5 until the diagram is **clean**: `check.jl` reports
   0 problems, or each remaining one is forced (rule 7) and named in your report with the blocks and
   ports that force it, and the PNG keeps every other rule.

6. **Compile:** `npx -y @juliacomputing/dyad-cli@3.5.0 compile .` prints "byte identical" for every
   generated file, and `git status --short generated/` is empty.

7. **Screenshots, only when a slide needs one:** follow `.claude/skills/dyad-studio-gui/SKILL.md`. Close
   and reopen the diagram after disk edits rather than trusting the live reload. Hide the sidebar
   (Ctrl+B) and panel (Ctrl+J), Reset view, park the mouse off the canvas, then `zoom` with
   `save_to_disk` on the diagram. Match the framing of the image it replaces and read the PNG back.

Report each component as **clean** or with its named exceptions, plus the `metadata-only.sh` result. A
layout you could not render is **unseen**; say so.

## Layout rules

1. **Signal flow left to right:** sources and inputs left, controller, plant, sensors and outputs right.
   Whole-car benches: driveline along the top, brake chain below it, grounds at the bottom, body and
   speed sensor on the right.
2. **Feedback returns in nested lanes** above, below or beside the main rows, nested in the order of
   the sensor's output ports so the lanes stay apart. One output feeding several blocks takes one lane
   with junctions.
3. **Port sides chosen on the owner's icon** so the parent's wires run straight: each port on the edge
   facing its partner, inputs level with the outputs that feed them.
4. **Every wire orthogonal.** Fan-outs bend at distinct x values; a connect with more than two ends
   gets junctions. A junction draws a dot, so it needs three or more edges; a corner is an `M` point.
5. **Wires clear of blocks and labels.** The usual defect is a ground or support wire dropping from a
   bottom-center port straight through the label below. Run sideways along the block's bottom edge
   (`check.jl` calls that a graze, which is allowed) until past the label's half-width, 0.055 × box
   height × characters, then turn down. A wire arriving at a bottom-center input such as
   `Feedback.u2` comes in the same way. When the label is wider than the block, run past the block's
   corner, or leave on the side away from the label.
6. **Everything inside the 0..1000 outline;** the component's own ports straddle it. A wire that
   leaves it or doubles back around its target has a port on the wrong side.
7. **Fewest crossings.** A crossing is forced, and named as an exception, when two inputs each feed
   the same two blocks; when two port pairs run in the same rotational order on both blocks; or when a
   child's port faces away from its partner across another lane.
8. **Readability first, then shared coordinates.** Benches that build on each other keep shared blocks
   at the same coordinates so successive slide shots line up, unless that costs readability. When it
   does, move the blocks and name the sibling benches whose shots no longer line up.
9. **Room for labels:** blocks 80–100 wide at 140–160 pitch, subsystems (controllers, plants, maps)
   160–200 square, small gains 70×70 at 120 vertical pitch. A block whose inputs line up with the
   component's own ports is tall enough that those ports' `diagram` boxes don't overlap. Keep 40 units between neighboring labels, computed from their
   widths. Labels scale with the block, so fill the outline: small blocks on an empty canvas give
   unreadable slides.

## Metadata

Copy from real files, which win over this page when they disagree, since Dyad owns the format:
`dyad/Vehicle/Planar/ESPController.dyad` (blocks, both port boxes, straight and bent wires),
`dyad/HandsOn03/ABSStop.dyad` (junctions), `dyad/Vehicle/Engine/MappedEngine.dyad` (junction chains),
`dyad/Vehicle/GasPort.dyad` (`labels`, wire color via `path.stroke`).

The traps those files don't explain:

- **Links:** a declaration or `connect` is laid out only if it carries a `{^tag}` keying an entry in
  `metadata { "_links": { … } }`. Inline `{"Dyad": …}` annotations escape `metadata-only.sh`; move them
  into `_links`.
- **Inherited parts are fixed:** components, connectors and `connect`s that come through `extends`
  take their placement from the base's file, so a derived diagram can't move them. Lay out around
  them, and report a move they need as a base change, since it shifts every derived diagram.
- **Coordinates:** y grows down. A block's `placement.diagram` box is where its 0..1000 icon square is
  drawn. The instance label sits centered below the box at icon (500, 1100), about 20 % of the box
  height tall. A `Gain` also draws `k=…` above; a `Constant` draws its name above and `k = …` below.
- **Two boxes per port:** `placement.icon` is where parents see the port, a 100×100 box straddling the
  owner's edge (left x −50..50, right 950..1050, top y −50..50, bottom 950..1050). `placement.diagram` is
  where it sits in the owner's own diagram. Given only one of them, it serves as both; given neither,
  the port draws at the block center.
- **Wires:** in `edges`, `S` and `E` are 1-based positions in the `connect(...)` argument list, and `-k`
  means `junctions[k-1]`, so an edge can run junction to junction (`{"S": -1, "E": -2}`). The path
  runs port-box center → each `M` point → port-box center in straight segments, so for an orthogonal
  wire the first `M` point shares the source port center's x or y and the last shares the target's.
- **Flips:** `y1 > y2` flips vertically, and a flipped box must be square or its ports draw away from
  the icon. The flip mirrors the instance label too, upside down above the block, so it is no way
  around a bottom port. **(unverified)** `rot` turns clockwise on screen, and `x1 > x2` flips horizontally; check
  in a render before relying on either.
- **CLI version:** `render.sh` uses `@juliacomputing/dyad-cli@3.5.0`; set `DYAD_CLI` to match the
  library's Dyad version, and use the same version to compile.
