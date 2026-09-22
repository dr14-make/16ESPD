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
├── frontend/             TypeScript source, its npm manifest, and the esbuild build
├── frontend-dist/        the bundle esbuild writes: committed, and what is always served
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

`frontend_directory()` names one directory rather than choosing between two, because a browser
cannot run TypeScript and the bundle is therefore the only servable form. Editing the frontend is
a rebuild-and-refresh loop — `mise run deck` rebuilds on every save, in about 200 ms — and
presenting never touches Node.

## Decisions

### A Julia package serving a prebuilt TypeScript bundle

The audience is students and lecturers who already have Julia installed for the course.
Requiring a Node runtime to present is a second toolchain to install, to version, and to fail
before a class. Building in TypeScript and shipping the artifact means `npm` is a tool only the
package author runs.

Pluto is the precedent for the layout: `frontend/` for source and `frontend-dist/` for the built
bundle. It is not the precedent for choosing between them. Pluto's `frontend/` is servable
JavaScript, so it can offer `frontend_directory(; allow_bundled)` and a
`JULIA_PLUTO_FORCE_BUNDLED` override; ours is TypeScript, so there is nothing to choose and no
inverse to want. Every dependency comes from npm and is bundled, which is what makes the shipped
artifact self-contained — see § The bundler is what replaced the browser shim.

This buys no same-origin benefit. Pluto's router is not publicly extensible, so PlutoDeck runs
its own HTTP server in the same Julia process on its own port and the browser talks to Pluto
directly on Pluto's port. That is fine: Pluto answers `Access-Control-Allow-Origin: *` and
accepts websockets from any origin. The benefit is the absence of Node, nothing more.

### The built bundle is committed

`frontend-dist/` is in the tree, and it is what `frontend_directory()` serves in a checkout and
in an installed package alike.

It is committed because it is the only servable form: `frontend/` holds TypeScript, so an
ignored bundle would mean a fresh clone can neither present a deck nor run the browser half of
`] test PlutoDeck` until someone has installed Node and built one — which is the dependency this
package exists to keep out of a lecturer's way. At 2.6 MB it is also smaller than the 4.2 MB of
hand-copied dependencies the tree carried before it, and source maps are written only by
`npm run dev` — `.gitignore` keeps them out.

The cost is real and pulls the other way: a content-hashed bundle changes in its entirety on
every frontend edit, so a one-line change to a component reads in a diff as a rewritten 2.1 MB
file. Review the source; the bundle is output. This decision replaced an earlier one to gitignore
the bundle and force-add it onto the release commit, which is the state the paragraph below
describes returning to.

**What would move us back.** A frontend edited often enough for the repository to feel it, or a
second bundle variant to keep in step. The move is the one Pluto makes — ignore `frontend-dist`,
force-add it onto the release commit — and what it needs is that a missing bundle fails loudly
rather than silently serving nothing, which `serve` already does. Either way a tag is never cut
without a rebuild, which is 015's to enforce. A Julia Artifact pointing at a GitHub release, as
PlutoPlotly does for its offline Plotly bundle, is the step past that, and nothing here blocks
it.

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
Bundled and minified, the deck entry is 2.1 MB of that; the speaker page shares none of it.

### The chrome is Lit; a card's own output is light DOM, and that is not a preference

The deck chrome, the navigation, the cue overlay and the speaker page are Lit components with
shadow roots of their own. What those four have in common is that they hold no cards.

**A card renders into light DOM, and so does every element above it.** Two separate mechanisms
break the moment a shadow boundary appears on the path from the document to a card's output, and
both break silently, with no exception and nothing rendered. Pluto's renderer resolves a
`published_to_js` payload through `root_node.closest("pluto-cell")`, and `closest` does not cross
a shadow root — which is how PlutoPlotly reaches both its library and its plot data. And
`deck.css` reaches a card's output from the document: a card renders Pluto's HTML *without*
Pluto's stylesheet, so every readout table a notebook emits is styled by `.card-body table` and
its neighbours. A document stylesheet does not cross a shadow root either. So `deck-app`,
`deck-slide` and `deck-card` all render into light DOM, which `LightDomElement` carries and which
`browser.jl` asserts rather than leaving to a comment.

**Rainbow is Preact, and it stays Preact.** `deck-card` owns the box and hands Pluto's renderer a
plain element to paint into; the two renderers are not unified. A card's body is therefore a node
Lit creates once and never revisits, which is why `render` returns one constant template with no
bindings inside it.

### Shared state travels through `@lit/context`

The kernel client, the loaded deck, the current slide index and the kernel status were
module-level `let` bindings in `deck.js`, reached by closure. Every one of them is read by
something that is not the module that owns it — the chrome reads the status, the nav and the cue
overlay read the slide index, every card reads its own content — so `<deck-app>` provides them
and everything below it consumes. The provider boundary is the element, which is what makes it
inspectable.

One of the four does not cross that boundary as itself. The kernel has exactly one consumer, the
painter that closes over it, and § Cards show placeholders until the kernel is live says a card
holds no worker reference of its own so that a second source of content stays one more `show`
call rather than a second renderer. So what is provided is the painter and a map of content by
card name, and the kernel stays inside `<deck-app>`. A card consuming a kernel would be able to
pull, and the state machine only stays a state machine while it cannot.

### The bundler is what replaced the browser shim

`@plutojl/rainbow` publishes an ESM build meant to be handed to a bundler rather than to a page.
The root bundle embeds immer, which reads `process.env.NODE_ENV` as a bare global six times, so
importing it into a page throws `ReferenceError: process is not defined` before anything
connects. `frontend/vendor/browser-shim.js` existed for that and for nothing else, and it had to
stay the first import in the module that reached Rainbow — an ordering nothing enforced and no
Node-side harness could check, because Node defines `process` itself.

esbuild's `define` substitutes the value at build time, so the bundle imports into a page that
defines nothing for it. That is what makes the shim unnecessary rather than merely relocated,
and it is the substantive reason this package has a build step at all.

`global` needs no substitution and gets none: every reference in either Rainbow bundle is the
browserify `typeof global !== "undefined" ? global : …` probe, and `typeof` on an undeclared name
does not throw. `dist/ui/ui.esm.js` additionally assigns `window.process` itself, in a `try`, for
the same reason the shim existed. Defining `global` anyway would be a substitution that provably
changes no byte, so it is left out rather than carried as insurance.

`inject` was not needed. It is where a module-scoped polyfill would go if a dependency ever needs
a real object rather than a value, and the test below is what would catch that.

**How this is checked.** `browser.jl` imports the built entry into a 404 page on the deck's own
origin — a document whose module graph is empty, so nothing has run ahead of the import and no
shim can be hiding the failure — and asserts it resolves. That test replaced one that asserted
the *unshimmed* import throws, which is the same question asked from the other side. Neither can
be answered in Node, and this is the one finding in `README.md` that a Node harness is
structurally unable to reach.

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

The browser renders the markdown, with `marked` taken from npm and bundled like every other
dependency. Julia's `Markdown` stdlib needs a live kernel, and a cue is worth
most when the kernel is slow to start or has been killed — exactly the case a round-trip would
fail. A hand-written subset was the tempting middle, and the gridstack decision above rejected a
2.1 MB dependency for ten lines of CSS on what looks like the same reasoning. It does not
transfer: `{x, y, w, h}` is a closed problem a CSS grid implements exactly, while markdown has
no bottom, and a subset fails by rendering a nested list flat, with no error, in front of a
room. Against the Rainbow UI bundle the deck already carries, a parser is a rounding error.

Cues reach the lecturer through an on-slide overlay bound to a key, which is what the reveal.js
deck in `docs/slides/lecture-01/` already does, for a reason recorded in its `deck.js`: a second
window can be blocked, so "the guidance is never stranded". That constraint holds here and is
stronger than it looks. A laptop plugged into a projector mirrors by default, and mirrored, a
second window shows the cues to the room exactly as the overlay does. An extended display is
arranged in a quiet office and forgotten in a strange lecture hall, so the overlay is the path
that works without preparation rather than the degraded one.

A cue-only speaker window follows it, separately. It renders no cards — no kernel, no Rainbow
bundle, no bonds, only the cue text and which slide it belongs to — so it is a second page
rather than a second renderer. That is what rules out reveal's answer to the same problem, which
loads the whole deck into two `<iframe>`s to preview the current and the next slide: here each
frame would open its own kernel connection, and writing the `deck_theme` bond is a reactive run,
so a preview would make the presentation re-run cells. What the page can say about what is
coming is the next slide's title and the opening of its cue, which is also what distinguishes
slides whose pictures barely differ. Reveal's `S` is blocked because a keypress calls `window.open`
from code; a link in the deck chrome is a click the viewer made and is not, and the two windows
are same-origin, so the slide number crosses on a `BroadcastChannel`.

**What that page shows when no deck is driving it is the decision the page turns on.**
`BroadcastChannel` carries no presence and fires no disconnect event, so a deck that was closed
and a deck nobody has paged for a minute are the same silence. A handshake alone — the page
announces itself on open, any deck answers with its index — meets every condition 019 lists,
including re-establishing after a reload, and still leaves a slide number that was true once
sitting there looking live in front of a room. So a deck repeats where it is every two seconds
as well as on every move, and a page that has heard nothing for three beats says it has lost the
deck instead of freezing on what it was last told. Three beats rather than one, because a missed
beat is a busy main thread repainting every card, and blaming a deck that is fine is its own way
of being wrong in a lecture hall. The cues stay on screen through it — the lecturer is still
talking to that slide — and it is the chrome that turns red.

A window also announces its departure on `pagehide`, which is what keeps a reload from costing a
whole staleness window, with the timer underneath for the close that never got to say it. Every
message carries the deck's path and a per-window id: two windows on one deck are same-origin and
same-path, so only the id tells them apart, and a speaker page that can only follow whichever
spoke last has to say that rather than flip between them.

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
- The published ESM build reads `process.env.NODE_ENV` as a bare global, and no Node-side test
  harness can catch that, because Node defines `process` itself. The build substitutes it; see
  § The bundler is what replaced the browser shim.

`createWorker` cannot reach a secret-protected server, which is why the spike needs a Node
bridge. Opening the notebook from Julia removes that constraint along with the bridge.

## Provenance

Every measurement here was taken against Pluto 1.0.3 on Julia 1.12.7-dyad, driving the spike in
this directory. Every claim about Pluto or Rainbow internals was read from the installed
sources: `~/.julia/packages/Pluto/F6SNP/src` and the `@plutojl/rainbow` 0.6.21 package.
