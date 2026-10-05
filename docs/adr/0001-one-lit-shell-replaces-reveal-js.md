# One Lit component library replaces reveal.js and PlutoDeck's own shell

Static decks, hands-on guides, the landing page and PlutoDeck's live decks all compose the same
`deck-*` Lit components from one package, `ui/`, instead of static decks running on reveal.js
while PlutoDeck carries a second shell of its own. One framework was the goal; keeping reveal.js
would have meant two navigation models, two speaker views and two copies of the palette, drifting
apart. The shell rebuilds only what the decks use — navigation, `#/N/M` deep links, scaling to
1280×760, the speaker view (second window, with an overlay for a single screen), the overview
grid and printing the handout — and drops fragments, zoom and search, which no slide used.

## Consequences

- Static decks must open over `file://` with no build step and no network, which module scripts
  cannot do: `ui/` ships a committed classic bundle into `slides/assets/` for them, while
  PlutoDeck bundles the same sources with its own esbuild.
- Equations are MathJax everywhere, matching what Pluto's own cards emit; KaTeX leaves the
  static decks.
- `ui/` is built on Web Awesome (`@awesome.me/webawesome`, MIT core), wrapped rather than
  exposed: authors write only `deck-*`, a component composes `wa-*` parts inside its shadow root,
  and Web Awesome's design tokens are the base of the library's own. Only the free core is used,
  components are imported one by one into the bundle, and nothing — assets, icons — may be
  fetched at run time, so its base path and icon library point at bundled files.
