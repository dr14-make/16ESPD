// Handing a published payload to a script that treats it as scratch space.
//
// Separate from `render.js` because it is decidable without a browser: a total function from a
// payload to a payload.

/** Whether `value` is an object literal, rather than an instance of something. */
const isPlainObject = (value) => {
  if (typeof value !== "object" || value === null) return false
  const prototype = Object.getPrototypeOf(value)
  return prototype === Object.prototype || prototype === null
}

/**
 * A copy of `value` that one draw may write to without the next draw seeing it.
 *
 * `published_to_js` sends one payload per cell, and every render of that cell is handed the
 * same object. A script that writes to what it was given therefore writes into what the next
 * render will read — PlutoPlotly appends its modebar buttons to `config` on every draw, and
 * Plotly refuses a second button of a name it already has, which aborts the draw after the
 * traces are attached and before any line is painted. A card placed on two slides draws twice.
 *
 * Only the spine is copied. A typed array, a string and anything that is not an object literal
 * or an array are shared, which is what keeps this cheap: the offline Plotly bundle is a 3.82 MB
 * string and a trace's coordinates are typed arrays, so neither is ever copied.
 */
export function isolate(value) {
  if (Array.isArray(value)) return value.map(isolate)
  if (!isPlainObject(value)) return value

  const copy = {}
  for (const key of Object.keys(value)) copy[key] = isolate(value[key])
  return copy
}
