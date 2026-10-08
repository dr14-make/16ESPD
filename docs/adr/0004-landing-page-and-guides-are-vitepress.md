# The landing page and the hands-on guides are VitePress

The landing page and each hands-on guide are Markdown pages of one VitePress site in
`slides/site/`, built in the same npm workspace as the decks and into the same `dist/`. ADR 0003
kept them as hand-written HTML. A guide is long, structured prose: steps, parts tables, numbered
actions, checkpoints and code to copy. As HTML it carried its own stylesheet and copy script, and
the build needed its own copy step. VitePress gives Markdown, a copy button, an outline and a
dead-link check with no custom theme. The site uses the default theme, with checkpoints, notes and
solutions mapped onto its built-in `tip`, `warning` and `details` containers.

## Consequences

- A guide no longer opens from a memory stick. Like a deck, it needs a web server, because its
  pages use absolute `/16ESPD/` paths. A deck's handout PDF remains the offline copy.
- Published URLs are unchanged. The site builds into the root of `dist/` and empties it first, so
  it builds before any deck. `cleanUrls` stays off, so a link that names `index.html` still
  resolves.
- A heading a deck links to pins its id with `{#id}`, so rewording the heading cannot break the
  link.
- A link from the site into a deck carries `target="_self"`, so that the browser loads the deck's
  page instead of VitePress's router. VitePress does not dead-link check such links.
- An image both a deck and the site publish lives once under `slides/images/`. Each tool serves
  only its own `public/`, so `scripts/images.mjs` copies it into both before every build and dev
  server. The copies are gitignored, and the screenshots keep the URLs they had before.
