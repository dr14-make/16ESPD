# Decks are Slidev; the Lit shell is not built

Every deck — static, live and hands-on — is a Slidev deck written in Markdown, built from one
workspace in `slides/` with the live-card code as a local addon beside it. ADR 0001 chose to build
our own Lit shell for the same job; Slidev already has the navigation, presenter mode, overview
and PDF export that shell would have rebuilt, and writing a slide in Markdown is far less markup
than composing it from components. A one-slide spike (branch `spike-slidev-pluto`) showed
Pluto's renderer, plots and bound widgets working unchanged inside Vue, which renders into light
DOM as Pluto's renderer requires. Nothing of `ui/` had been built, so the reversal costs no code.
The hands-on guide and the landing page stay plain HTML.

## Consequences

- A built deck needs a web server: Chrome and Firefox refuse its module script over `file://`.
  The offline copy for a lecture hall is the exported PDF. A single-file build that does open
  from a file was shown to work and is not yet adopted.
- Sections are a grouping, not a navigation direction: a deck is one line of slides, and a deep
  link names a section's cover rather than its position.
- Authored math is KaTeX, Slidev's own; only a live card's math is MathJax, as Pluto renders it.
- Slidev mounts only the slides around the current one, so a live deck renders every bound
  widget once, hidden, to make it report its value; PlutoDeck could rely on mounting every slide.
- Presenter mode renders live cards in a second window, which holds its own connection to Pluto.
