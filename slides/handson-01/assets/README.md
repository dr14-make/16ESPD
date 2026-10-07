# Deck assets

Everything the hands-on deck loads is in this directory. The deck is presented from a lecture
hall and must render with the network off, so nothing here is fetched from a CDN at run time.

| Path | What | Version |
|---|---|---|
| `reveal/` | reveal.js — `dist/`, and the `notes`, `highlight`, `math`, `zoom`, `search` plugins | 5.2.1 |
| `katex/` | KaTeX, loaded by reveal's math plugin through `katex: { local: 'assets/katex' }` | 0.16.11 |
| `deck.css` | light-theme overrides, demo cards, callouts | — |
| `deck.js` | copy buttons, the on-slide cue panel, the footer | — |
| `highlight-light.css` | light syntax theme; the bundled reveal themes are both dark | — |

Trimmed from the upstream packages: source maps, ESM builds, the MathJax variants of the math
plugin, the unused reveal themes, KaTeX's `.ttf` fonts (`.woff2`/`.woff` cover every browser
that runs reveal.js 5), and reveal's League Gothic face.

`index.html` is assembled from `../src/` by `../build.py`; run it after editing a section and
commit both.
