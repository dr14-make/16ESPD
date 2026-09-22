import { LitElement } from "lit"

/**
 * A component that renders into the document rather than into a shadow root.
 *
 * Everything on the path from the document to a card's rendered output extends this. Pluto's
 * renderer resolves a `published_to_js` payload through `root_node.closest("pluto-cell")`, and
 * `closest` does not cross a shadow boundary — a card under one reaches no payload, and its
 * script dies with no exception and nothing rendered. `deck.css` reaches a card's output for
 * the same reason: a card renders Pluto's HTML without Pluto's stylesheet, so the readout
 * tables a notebook emits are styled by `.card-body table` from the document's own sheet.
 *
 * `browser.jl` asserts that no element between a card and the document has a shadow root.
 */
export abstract class LightDomElement extends LitElement {
  protected override createRenderRoot(): HTMLElement {
    return this
  }
}
