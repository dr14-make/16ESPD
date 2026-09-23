# 025 — Render the math a control-theory lecture is made of

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 007, 009, 018
- **Traces to** — DESIGN.md § Cards render through Pluto's own renderer, § Speaker cues are the
  deck's, and reach the lecturer without a popup

## Context

Nothing under `frontend/src/` mentions MathJax, KaTeX or `.tex`. The deck renders no math at
all, and the course it exists for is a control-theory lecture whose equations are most of its
content — the reveal deck in `docs/slides/lecture-01/` carries fifteen display-math blocks
across six sections.

The gap is invisible today only because the lecture-1 notebook happens to contain none. Two
things break the moment one does:

- A notebook `md` cell carrying math renders its LaTeX as literal `$…$` on the card.
- A cue `.md` file carrying math does the same, because `marked` has no math support.

Pluto has already solved the card half, and the deck should match it so that one formula reads
identically in the notebook, on a card and in the speaker window.

**The markup already arrives.** `PlutoRunner/src/display/LaTeX.jl` overrides Julia's Markdown
HTML writer inside the kernel: `Markdown.htmlinline` writes `<span class="tex">$formula$</span>`
and `Markdown.html` writes `<p class="tex">$$formula$$</p>`. So every card the deck paints
already carries `.tex` elements, with inline and display distinguished by the tag and by the
delimiter. There is nothing to parse and no text to scan for `$`, so a literal dollar in prose
is not a false positive. The override lives in PlutoRunner rather than in `Markdown`, so a bare
`julia -e 'using Markdown'` does not show it.

## Scope

**Renderer.** MathJax 3.2.2, `tex-svg-full`, configured as Pluto configures it in
`frontend/common/SetupMathJax.js`: `processHtmlClass: "tex"`, `inlineMath` carrying `$…$` as
well as `\(…\)`, and SVG output.

**SVG output** is the part that is load-bearing: it draws glyphs as paths, so there are no font
files to serve. That is why MathJax rather than KaTeX, whose `.woff2` assets would have to be
bundled too.

**The font cache must be `local`, not the `global` Pluto uses.** A global cache reaches its
glyphs through `<use href="#…">` into one `<svg>` in the document, and that reference does not
cross a shadow boundary — so every formula in a cue is a correctly sized box with nothing drawn
in it. Assert the glyphs, not the container.

**No `MathJax.Hub` shim.** Pluto carries one and its comment says *"plotly uses MathJax 2, so we
have this shim to make it work kindof."* Check that against the Plotly the notebook actually
loads before copying it: Plotly 2.x takes the MathJax 3 path and never calls `Hub`, and Plotly
1.x calls `Hub.Typeset` with a single element and then reads `.MathJax_SVG` back, which MathJax 3
never writes. Neither can be served. A `Hub` that accepts a call and drops it is worse than
none, because `Hub` is what a caller feature-detects on.

**`ignoreHtmlClass` / `processHtmlClass`** are to be carried verbatim but not described as
load-bearing without establishing that they do anything: both govern the walk inside the
elements a pass is handed, and those are the `.tex` nodes themselves.

**Offline.** Pluto's normal build loads `mathjax@3.2.2/es5/tex-svg-full.js` from jsdelivr; its
offline build ships the same file locally. This deck does the latter, content hashed into
`frontend-dist/` by the same build that writes the bundle. Nothing is fetched at
run time. The guarantee is stated three times in the reveal deck this one replaces and it holds
here: a lecture hall's network is not the lecturer's to rely on.

**Cues.** `marked` output carries no `.tex`. Rather than bolting a math extension onto marked
with conventions of its own, the cue renderer emits Pluto's markup, so one typeset pass covers
cards and cues and the codebase carries one convention rather than two. Inline math follows
Julia's own delimiter rule — `parse_inline_wrapper` refuses whitespace after an opening
delimiter and before a closing one — which is what leaves `costs $5 and $6` as the prose it is.
Where following Julia would cost the lecturer more than it buys, it is not followed; a cue is
authored by hand and never round-trips through Julia, so there is no parser to stay compatible
with. `DESIGN.md` carries the list. The clearest case is display math spaced inside its
delimiters, the form every equation in the reveal deck is written in: a cue renders it, and a
notebook cell carrying the same line throws `UndefVarError` and loses the whole card, because
Julia leaves a bare `$` in the tree for the `md` macro to interpolate. `renderCues` is already shared by the overlay and the
speaker page and stays that way.

**Where it hooks.** Cards paint through the Preact renderer; cues render through `renderCues`.
One typeset function, two callers.

**Loading order.** Pluto loads MathJax behind `requestIdleCallback` and typesets whatever has
arrived, because a cell can render before the script lands. Cues are deliberately readable in
the twenty seconds before a kernel exists and after one has been killed, so a cue whose formula
was skipped for arriving early would be showing its dollars for the whole of the window the
cues exist for. The pass therefore ends with the math typeset rather than silently skipped.

**Shadow DOM.** The chrome is Lit. `querySelectorAll` does not cross a shadow boundary and
neither does a document-wide MathJax pass, so each pass names the container it just rendered
into. Nor does a stylesheet: MathJax writes one into `document.head`, so a root that has not
been handed a copy renders the assistive MathML behind every formula as visible text beside the
glyphs. Card content stays in light DOM regardless, for the reasons `LightDomElement` records.

**Dependency.** `mathjax` is added to `frontend/package.json`, pinned exactly, like every other
npm dependency since 007.

## Done when

- A notebook `md` cell carrying inline and display math renders drawn glyphs on its card —
  `mjx-container` with an `<svg>` where the formula was, and no `$` delimiters left in the
  card's text.
- Display and inline stay distinct: a `$$…$$` block is set as display, a `$…$` in a sentence
  inline.
- A cue carrying the same two shapes renders the same way, through the same markup.
- A display equation copied out of `docs/slides/lecture-01/` — spaced inside its delimiters —
  renders as the equation it is.
- An inline formula in a cue is laid out as it is on a card, measured rather than inferred: a
  shadow root gets MathJax's stylesheet, or the MathML behind every formula is visible text.
- A cue's formulas are drawn, not merely sized: every glyph resolves inside the formula's own
  subtree, which a global font cache does not survive a shadow boundary to do.
- Cue math renders with no kernel reachable, which the suite already stages.
- Cue math renders on the speaker page, whose cues are inside a shadow root.
- A price in cue prose — `costs $5 and $6` — is left as prose.
- MathJax is served by the deck under a content-hashed name, and no script on either page is
  loaded from another origin — including a component MathJax's own loader might fetch.
- The drawn math carries the assistive MathML a screen reader reads, which SVG glyph paths are
  not.
- The browser fixture's math cell is written by `test/fixtures/generate.jl` through Pluto's own
  writer, never by hand.
- `] test PlutoDeck` is green, browser suite included, and the frontend typechecks, lints and
  passes `node --test`.

## Out of scope

- **Math in a slide title.** Titles are authored in `deck.json` and rendered by the chrome,
  which holds no cards; giving them a parser is a third convention for one string.
- **A KaTeX option.** The renderer is a decision, not a setting: two of them is two sets of
  glyph metrics and two failure modes for one formula.
- **Typesetting a card's scripts' output.** Pluto typesets after `execute_scripttags`
  completes; the deck typesets after the paint that starts them. What a script injects later is
  not markdown and does not carry `.tex`.
- **Chemical or code highlighting.** Pluto's `apply_enhanced_markup_features` also runs
  highlight.js over a cell; that is a separate gap and not this one.
