// Copies the MathJax and Plotly builds PlutoDeck serves into public/vendor, so the head links in
// index.html resolve the same way they do in PlutoDeck's own page.
import { copyFile, mkdir } from "node:fs/promises"

const FRONTEND = new URL("../PlutoDeck.jl/frontend/node_modules/", import.meta.url)
const OUT = new URL("./public/vendor/", import.meta.url)

await mkdir(OUT, { recursive: true })
await copyFile(new URL("mathjax/es5/tex-svg-full.js", FRONTEND), new URL("tex-svg-full.js", OUT))
await copyFile(new URL("plotly.js-dist-min/plotly.min.js", FRONTEND), new URL("plotly.min.js", OUT))
