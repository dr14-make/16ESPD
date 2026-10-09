# PlutoDeck — design

A Julia package that turns a Pluto notebook into a slide deck.

Cells opt in by declaring a `card` name. A hand-authored `deck.json` arranges those cards onto
slides using gridstack layouts. The package serves a prebuilt TypeScript frontend that renders
each card with Pluto's own renderer, so plots stay interactive and `@bind` widgets defined in
Julia keep working.

The presentation layer owns layout and nothing else. Every piece of content — plots, widgets,
readouts, prose — is authored in Julia, in a notebook that remains a normal Pluto notebook you
can open and edit in Pluto. Slide titles are the one exception, for the reason § Open records.
Speaker cues are not a second one: a cue is never shown to the room, so it is not content the
presentation layer owns, and § Speaker cues says where it lives instead.

This document records what was decided and why. `README.md` in this directory covers the
working spike the decisions were tested against, including the gotchas that shaped them.

## Shape

```
PlutoDeck.jl/
├── Project.toml
├── src/
│   ├── PlutoDeck.jl      present(deck_path), CLI entry
│   ├── session.jl        start Pluto, open the notebook with execution_allowed=true
│   ├── deck.jl           load deck.json, validate card references against the notebook
│   ├── cards.jl          read the `card` key out of cell metadata
│   └── server.jl         HTTP.jl: serve frontend_directory(), /api/session, /api/deck
├── frontend/             TypeScript source, served in development
├── frontend-dist/        built bundle, served in production
└── test/
```

The course repository holds only its own material:

```
VehicleSystemsComponents/
├── notebooks/lecture01/lecture-01.jl     cells carry `card = "..."`
└── decks/lecture-01.deck.json
```

The package knows nothing about any particular course, and a course repository knows nothing
about TypeScript. The entire contract between them is the `card` keys and the deck schema.

`frontend_directory(; allow_bundled)` selects source or bundle the way Pluto's own does, so
editing TypeScript is a rebuild-and-refresh loop and presenting never touches Node.

## Decisions

### A Julia package serving a prebuilt TypeScript bundle

The audience is students and lecturers who already have Julia installed for the course.
Requiring a Node runtime to present is a second toolchain to install, to version, and to fail
before a class. Building in TypeScript and shipping the artifact means `npm` is a tool only the
package author runs.

Pluto itself is the precedent: `frontend/` for source, `frontend-dist/` for the built bundle,
`frontend-dist-offline/` for a network-free variant, and `frontend_directory(; allow_bundled)`
to choose, with `JULIA_PLUTO_FORCE_BUNDLED` to override during development.

This buys no same-origin benefit. Pluto's router is not publicly extensible, so PlutoDeck runs
its own HTTP server in the same Julia process on its own port and the browser talks to Pluto
directly on Pluto's port. That is fine: Pluto answers `Access-Control-Allow-Origin: *` and
accepts websockets from any origin. The benefit is the absence of Node, nothing more.

### The built bundle is gitignored in development and force-added on the release commit

A content-hashed bundle changes in its entirety on every frontend edit. Committing it normally
adds megabytes per commit for files no one will read again.

Pluto's `.gitignore` carries `frontend-dist` and `frontend-dist-*`, yet an installed Pluto has
12 MB of `frontend-dist` and neither an `Artifacts.toml` nor a `deps/build.jl`. The bundle is
force-added onto the release commit, past the ignore rule.

No CI is required to start; force-add by hand when tagging. The one rule is that a tag is never
cut without a rebuild. A Julia Artifact pointing at a GitHub release — as PlutoPlotly does for
its offline Plotly bundle — is where to go if clone size ever becomes painful, and nothing here
blocks that move.

### The deck is a separate JSON file

Pluto owns the notebook file and rewrites it on every cell edit; it canonicalizes a notebook the
moment it opens one. Storing the deck inside that file puts the deck editor in a write race with
another process that is actively saving, and losing that race corrupts a lecturer's slides
during a lecture.

Notebook frontmatter would technically work — `DEFAULT_NOTEBOOK_METADATA` is empty, so every key
is written, and `TOML.print` preserves nesting. It is rejected for the write race, not for
capability.

A separate file also lets one notebook back several decks: the ninety-minute lecture, a
twenty-minute revision deck, and a student-facing version with scratch cards omitted. For
teaching material that reuse is most of the value.

### Cards address cells by a `card` key in the cell's own metadata

```julia
# ╔═╡ a1000000-0000-4000-8000-000000000002
# ╠═╡ card = "target-speed"
@bind v_ref_kmh html"<input type=range min=60 max=160 value=110>"
```

and the deck refers to `"target-speed"`.

Cell metadata is written into the `.jl` file as TOML on `# ╠═╡ ` lines, and
`get_metadata_no_default` writes any key that is not a Pluto default, so custom keys survive a
save and load round-trip. This needs no change to Pluto.

The key property is not readability but that the notebook declares its own public surface. A
cell carrying a `card` key is published; a cell without one is scratch work that cannot reach a
slide. A lecture notebook accumulates debugging cells, and what students can see deserves a
hard rule rather than a remembered convention.

A card reference resolves at load time. Asking for a name the notebook does not offer fails
loudly, naming something a human can act on. Cell UUIDs remain the internal handle the runtime
resolves to, and never appear in a file a person edits.

### The layout schema is gridstack-shaped, and hand-authored first

GridStack 13.3.0 is MIT, has no runtime dependencies, and ships its own type definitions.

Its value is drag-and-drop authoring, which belongs in a visual editor that writes `deck.json`
back. That editor is what makes this a product rather than a script — a lecturer rearranging a
slide in front of students is the compelling demo — but it is also where most of the work is,
and it cannot be designed well before the hand-authored version has carried one real lecture.

Writing `{x, y, w, h}` into the schema from the start costs nothing and makes the editor
additive rather than a migration.

What this decision buys is the *schema*, not the library. A 12-column CSS grid with a fixed row
track renders `{x, y, w, h}` exactly and in no bytes, so GridStack is a dependency of the
editor rather than of version one. It does not carry the schema, and nothing here waits on it.
What a plain grid does not do is refuse a layout that cannot work, so the loader checks overlap
and grid width instead.

### Cards render through Pluto's own renderer

`@plutojl/rainbow/ui` exports `CellOutput`, `OutputBody`, `RawHTMLContainer`, and the bond
helpers `set_bound_elements_to_their_value`, `add_bonds_listener`, `get_input_value` and
`set_input_value`.

`RawHTMLContainer` re-creates script nodes so they execute and resolves `published_to_js`
payloads — confirmed in the bundle by `execute_scripttags`, `createElement("script")`,
`published_objects` and `getBoundElementValueLikePluto`.

Assigning to `innerHTML` never executes inserted `<script>` tags, which is a DOM rule rather
than a Pluto quirk. Anything whose output is a container plus a script that fills it — Plotly,
PlutoUI widgets, most `@bind` elements — renders as an empty box under `innerHTML`. Using
Pluto's renderer is what makes interactive plots and Julia-defined widgets work at all.

The cost is the bundle: `dist/ui/ui.esm.js` is 3.7 MB against 464 KB for the standalone client.

### The deck tells the notebook which color scheme it is being shown in

A card's colors are the deck's; a plot's colors are the kernel's. No stylesheet reaches
inside a rendered Plotly figure, because its palette is in the payload the kernel sent — so a
dark deck otherwise carries a white slab per plot, the one bright rectangle in a dark hall.

The deck therefore sets one bond, `deck_theme`, to `"light"` or `"dark"` on connect and
whenever the viewer's scheme changes. A notebook opts in by declaring it:

```julia
@bind deck_theme html"<span></span>"

plot_template = templates[coalesce(deck_theme, "light") == "dark" ? :plotly_dark : :plotly_white]
```

The element reports no value of its own, which is the point: the deck is the only writer, and
a repaint cannot clobber what it set. A notebook that declares no bond of that name is
untouched, and one opened directly in Pluto reads `missing` and falls back to light.

This adds no machinery. Bonds already carry values from the browser into the kernel and a
reactive run already repaints every card downstream, so the scheme travels the path a slider
travels. The name is a contract with every notebook that opts in, which is why it is fixed
here rather than left to each deck.

### Speaker cues are the deck's, and reach the lecturer without a popup

A cue — timing, what to say, what to do when a demo misbehaves — cannot live in the notebook at
all, and not as a matter of taste. The card contract is that a cell carrying a `card` key is
published and a cell without one cannot reach a slide. A cue is the opposite of published: in
the notebook it is either visible to every student who opens the file, or it is scratch work no
deck can read.

Cues are a slide-level key with no geometry, because they are not placed anywhere:

```json
{ "title": "Proportional", "notes": "notes/proportional.md", "cards": [ … ] }
```

Giving them `x, y, w, h` would add four numbers the loader then has to remember to ignore.

The text is a `.md` file beside the deck, never inline in `deck.json`. JSON's `\n` does reach
markdown as a real newline — the parser unescapes it — so that is an authoring cost rather than
a rendering one: a three-hundred-word cue inline is one enormous line, with no spellcheck, whose
every typo fix reads in a diff as the whole paragraph changing. One file per deck with the
slides marked off inside it fails differently: any marker based on position re-attaches every
note when a slide moves, which is what ruled out addressing cards by index.

The loader resolves a relative path against the deck file and refuses a deck naming a file that
is not there, which is what `"notebook"` already does, and enforces no layout beyond that. A
folder per deck is convention, carried by the example deck, and it is what keeps two decks'
wording from colliding:

```
decks/
├── lecture-01.deck.json
├── lecture-01/notes/proportional.md
├── lecture-01-revision.deck.json
└── lecture-01-revision/notes/proportional.md
```

Paths are checked once, at load; the text is read per request, so `/api/deck` reflects an edit
on the next browser refresh with the kernel untouched. Baking it into the loaded `Deck` would
make fixing one word cost a thirty-second kernel restart, and wording that expensive to look at
gets written blind.

The browser renders the markdown, with a parser vendored into `frontend/vendor/` beside the two
Rainbow bundles already there. Julia's `Markdown` stdlib needs a live kernel, and a cue is worth
most when the kernel is slow to start or has been killed — exactly the case a round-trip would
fail. A hand-written subset was the tempting middle, and the gridstack decision above rejected a
2.1 MB dependency for ten lines of CSS on what looks like the same reasoning. It does not
transfer: `{x, y, w, h}` is a closed problem a CSS grid implements exactly, while markdown has
no bottom, and a subset fails by rendering a nested list flat, with no error, in front of a
room. Against the 3.7 MB of `rainbow-ui.esm.js` already served by hand, a parser is a rounding
error.

Cues reach the lecturer through an on-slide overlay bound to a key, which is what the reveal.js
deck in `docs/slides/lecture-01/` already does, for a reason recorded in its `deck.js`: a second
window can be blocked, so "the guidance is never stranded". That constraint holds here and is
stronger than it looks. A laptop plugged into a projector mirrors by default, and mirrored, a
second window shows the cues to the room exactly as the overlay does. An extended display is
arranged in a quiet office and forgotten in a strange lecture hall, so the overlay is the path
that works without preparation rather than the degraded one.

A cue-only speaker window follows it, separately. It renders no cards — no kernel, no Rainbow
bundle, no bonds, only the cue text and which slide it belongs to — so it is a second page
rather than a second renderer. Reveal's `S` is blocked because a keypress calls `window.open`
from code; a link in the deck chrome is a click the viewer made and is not, and the two windows
are same-origin and share a slide number over `BroadcastChannel` with no handshake.

**Guidance prose on the slide is deferred, not rejected.** A sentence like "drag Kp until it
oscillates" could be authored in the deck as well, and for a while this design said it should
be. It is not built, because a notebook `md` cell carrying a `card` key already renders both in
Pluto and on the slide from a single source, which is one fewer thing to keep in step. Two cases
would bring it back: wording that must differ between the lecture, the revision deck and the
student-facing cut over one notebook — the argument that moved slide titles — and a sentence
that has to be readable in the twenty seconds before a kernel exists, which a notebook cell
never is. Neither is pressing, and the machinery cues need is most of what it would take.

### One kernel per running instance; never a multi-tenant server

Measured on a developer laptop, with a notebook that loads no packages whatsoever:

```
2130 MB   Pluto server process
1926 MB   the notebook's worker process
```

Roughly 2 GB per worker at the floor. A thirty-student class served centrally is about 60 GB
before any real package loads. That is arithmetic, not tuning.

So the deck assumes one kernel and one person driving it. Students who need their own run their
own copy locally, which is how the course already distributes work. The value of stating this
as a decision is the work it forecloses: no session isolation, no per-user bond namespacing, no
queue, no machine sizing.

The case this does not cover is a student opening a link on a phone. That is
PlutoSliderServer.jl — it precomputes bond outcomes and serves them statically with no per-user
Julia — and it is a separate target rather than a mode of this package. Both consume the same
notebook and the same `card` keys, so choosing this now does not block it.

### Cards show placeholders until the kernel is live

Cold start, measured with warm precompilation and a notebook loading no packages:

```
12.1 s   the deck is serving HTML
29.1 s   kernel ready, websocket connected
31.2 s   first card shows real content
```

The page is live and interactive at 12 s with nothing in it until 31 s, so a lecturer watches
roughly nineteen seconds of empty cards on a deck that looks broken. A notebook that loads this
course's stack turns that into minutes.

Version one shows a labelled placeholder per card, plus one global "kernel starting" state on
the deck chrome so the wait reads as warming up rather than broken.

A card is therefore a state machine over where its HTML came from — `placeholder` then `live` —
and holds no worker reference of its own. Cached snapshots, which would let a deck with no
Julia at all still be a complete presentation, then become one more source rather than a
rewrite of the renderer. `deck.json` should leave room for a per-card snapshot reference.

Snapshots are deferred rather than rejected. Their real cost is that a stale snapshot looks
exactly like a fresh one, so they will need a content hash of the notebook and the bond state
that produced them, a visible distinction between snapshot and live, and a regeneration step.

## Ruled out

**Addressing cards by index.** Inserting one cell renumbers every card in the deck, and Pluto
users insert cells constantly.

**Addressing cards by variable name.** `rootassignee` is `null` for every cell that is not a
plain assignment — every `@bind` cell and every bare expression. The two most common card
kinds, a live widget and a bare `plot(...)`, have no variable name at all.

**The deck inside notebook frontmatter.** Capable, but it puts the deck editor in a write race
with Pluto.

**A kernel per viewer.** See the memory measurements above.

**A Node runtime at presentation time.** The spike needs both Julia and Node running, and that
is its most fragile part.

**Cue text inline in `deck.json`.** Not for `\n`, which JSON unescapes into a real newline, but
for the diff: one enormous line, no spellcheck, and a one-word fix that reads as the whole
paragraph changing.

**One cue file per deck, with the slides marked off inside it.** Any marker based on position
re-attaches every note when a slide moves, which is the failure that ruled out addressing cards
by index.

**Rendering cues through Julia's `Markdown` stdlib.** It needs a live kernel, and a cue earns
its keep when the kernel is slow to start or has died.

**A hand-written markdown subset.** Its failure mode is silent — a nested list rendered flat,
with no error, in front of a room. The gridstack reasoning does not carry over, because
`{x, y, w, h}` is a closed problem and markdown is not.

**Speaker cues in the notebook.** The card contract publishes any cell carrying a `card` key, so
a cue there is either shown to every student or unreachable by the deck.

## Open

Deliberately unsettled, because they resolve better against real code than in the abstract:
`persist_js_state` and whether a Plotly card keeps its zoom across bond updates; the
sanitization posture, given `RawHTMLContainer` takes a `sanitize_html` flag and Pluto's security
model assumes a trusted notebook; and whether a slide is addressable by URL fragment.

Two of these have since settled against real code. Paging is by pointer and keyboard, and a
slide is not addressable by URL — the fragment question stays open on its own. The schema
gained one key, `title` on a slide, because the reason a deck is a separate file is that one
notebook backs several decks, and titles authored in Julia would force all of them to share
wording. A widget's label stays in Julia, where it is part of the widget.

## Implementation notes carried from the spike

All ten findings in `README.md` are load-bearing for any implementation. These in particular:

- A notebook opened over HTTP parks in `waiting_for_permission` without `execution_allowed=true`.
- `worker.isIdle()` returns true in the window between sending a bond and the run starting.
- Watching only the root cell hands back the previous run's downstream output.
- One `setBond` per call is one reactive run each; a batch belongs in a single notebook update.
- `worker.execute()` races workspace rotation and writes a hidden cell to the notebook file.
- Bonds start as `missing`; a widget's own default is never reported by itself.
- The published ESM build needs `process` and `global` shimmed before it is imported, and no
  Node-side test harness can catch that.

`createWorker` cannot reach a secret-protected server, which is why the spike needs a Node
bridge. Opening the notebook from Julia removes that constraint along with the bridge.

## Provenance

Every measurement here was taken against Pluto 1.0.3 on Julia 1.12.7-dyad, driving the spike in
this directory. Every claim about Pluto or Rainbow internals was read from the installed
sources: `~/.julia/packages/Pluto/F6SNP/src` and the `@plutojl/rainbow` 0.6.21 package.
