# Live decks publish from snapshots

A live deck is one deck for the lecture hall, Pages and the handout. Each live card first paints
its cell's output from its notebook's snapshot, then switches to the live cell once that notebook's
kernel is ready. A snapshot is Pluto's own `.plutostate`, the state `Pluto.notebook_to_js` returns:
cell code and metadata, outputs, published objects and bond values. It is written by running the
notebook headless and is committed beside the notebook. Pages and `slidev export` have no kernel,
so they render the snapshot, and a live deck is built and published like any static deck. ADR 0003
kept live decks out of the build because Pages could not run them. Keeping a separate static deck
with SVG figures alongside the live one would mean two sources that drift apart. Precomputing bond
states across a grid of input values, which is PlutoSliderServer's approach, would make sliders
work offline, but it costs a run for every combination of inputs and more tooling.

Lecture 1 is the first to move. Each section's Jupyter notebook gets a Pluto twin. A twin runs the
real Dyad models, not a surrogate, and it activates the repo's project rather than using Pluto's
built-in package manager.

## Consequences

- Offline, inputs draw at their saved value and do nothing, while plots still zoom and hover.
  Responding sliders need the lecture hall's kernel.
- CI has no Julia, so snapshots are refreshed locally and committed, the way `save_figure`'s SVGs
  were. The workspace check fails when a card names a cell that no snapshot holds, or when a
  snapshot's code no longer matches its notebook.
- The deck build keeps building every deck. The filter at f3ef6bb that skipped decks with a
  notebook does not come back.
- A deck can draw on several notebooks, one per section, so a `PlutoCard` names its notebook as
  well as its card, and PlutoDeck runs one kernel per notebook.
- The Dyad stack runs only on the `dyad-3.4.0` Julia channel with packages from the Dyad depot,
  which Pluto's package manager cannot install. The repo's `Manifest.toml` is the only pin, so a
  notebook is reproducible from a checkout of the repo, not on its own.
- A notebook's first result takes about 30 s after its kernel starts, almost all of it the first
  model compile. PlutoDeck starts every notebook when it launches, and the snapshot covers each one
  until it is ready. A slider move then takes tens of milliseconds, most of it drawing the plot.
  Sliders bind only tunable parameters, because a structural change builds a new model, which
  takes seconds.
- `save_figure` and the deck's SVG figures retire once every section shows live cards.
