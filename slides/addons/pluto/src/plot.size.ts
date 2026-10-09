// Sizing a plot to its card on a scaled slide.
//
// PlutoPlotly sizes a plot to `getBoundingClientRect()` of the container it draws into, and
// Slidev fits a slide to the window with a CSS `transform: scale(…)`. The rectangle is the
// transformed one, so a plot is drawn at the slide's scale times its card's size and then scaled
// again: smaller than its card in a small window, spilling out of it on a projector. Neither
// scale changes layout, so no resize ever corrects it.
//
// The container is the one element whose rectangle PlutoPlotly sizes from, so only its answer
// is replaced, with its layout size. Plotly's own pointer math reads the plot element, which is
// left alone: there the transformed rectangle is the right one.

/** The element PlutoPlotly draws a plot into and measures. */
const CONTAINER = "plutoplotly-container"

/**
 * Marks the replacement, under a key every evaluation of this module shares, so that a second
 * call or a hot reload finds it installed rather than wrapping it again.
 */
const INSTALLED = Symbol.for("slidev-addon-pluto.sizePlotsToTheirCards")

export function sizePlotsToTheirCards(): void {
  // Only ever called through `.call` with the element being measured as its receiver.
  // eslint-disable-next-line @typescript-eslint/unbound-method
  const measured = Element.prototype.getBoundingClientRect
  if (Reflect.get(measured, INSTALLED) === true) {
    return
  }
  const sized = function (this: Element): DOMRect {
    const rect = measured.call(this)
    if (this.classList.contains(CONTAINER) && this instanceof HTMLElement) {
      return new DOMRect(rect.x, rect.y, this.offsetWidth, this.offsetHeight)
    }
    return rect
  }
  Reflect.set(sized, INSTALLED, true)
  Element.prototype.getBoundingClientRect = sized
}
