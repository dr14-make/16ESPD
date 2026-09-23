import assert from "node:assert/strict"
import { test } from "node:test"
import { Marked } from "marked"
import { texMarkup } from "./math.markup.ts"

const parser = new Marked(texMarkup)
const render = (markdown: string): string => parser.parse(markdown, { async: false })

test("inline math becomes the span PlutoRunner writes", () => {
  // `Markdown.htmlinline(io, ::Markdown.LaTeX)` writes exactly this, so a formula in a cue and
  // the same formula in a notebook cell reach the typesetter as the same element.
  assert.match(render("the gain $K_p$ rises"), /<span class="tex">\$K_p\$<\/span>/)
})

test("display math becomes the paragraph PlutoRunner writes", () => {
  assert.match(
    render("$$G(s) = \\frac{K}{\\tau s + 1}$$"),
    /<p class="tex">\$\$G\(s\) = \\frac\{K\}\{\\tau s \+ 1\}\$\$<\/p>/,
  )
})

test("markdown's own punctuation survives inside a formula", () => {
  // The reason this is a tokenizer and not a pass over rendered HTML: `_` is emphasis to the
  // inline lexer, so `$a_1 + b_2$` arrives as `<em>` wrapped around half a formula with the
  // underscores gone and nothing to say they were ever there.
  const html = render("$a_1 + b_2$")

  assert.match(html, /\$a_1 \+ b_2\$/)
  assert.doesNotMatch(html, /<em>/)
})

test("a formula's angle brackets and ampersands reach the DOM as characters", () => {
  // `htmlesc` does the same on the Julia side. Left raw they would close the span or open a
  // tag; escaped, `textContent` hands MathJax back what the author typed.
  assert.match(render("$a < b \\& c > d$"), /\$a &lt; b \\&amp; c &gt; d\$/)
})

test("a price is prose, not a formula swallowing the words between", () => {
  // Julia's `parse_inline_wrapper` refuses a closing `$` whose preceding character is
  // whitespace, which is the whole of what keeps this sentence readable.
  const html = render("it costs $5 and $6 together")

  assert.doesNotMatch(html, /class="tex"/)
  assert.match(html, /\$5 and \$6 together/)
})

test("an escaped dollar is a dollar", () => {
  const html = render("it costs \\$5")

  assert.doesNotMatch(html, /class="tex"/)
  assert.doesNotMatch(html, /\\/, "the backslash is markdown's, and is consumed by it")
  assert.match(html, /\$5/)
})

test("a display run that never started a block is inline math, as it is in Pluto", () => {
  // `Markdown.htmlinline` writes one `$` whatever the run was, so this is not a second
  // convention: it is the same formula reaching the typesetter the same way.
  assert.match(render("the plant $$G(s) = K$$ rolls off"), /<span class="tex">\$G\(s\) = K\$<\/span>/)
})

test("two formulas in a sentence stay two formulas", () => {
  // A one-character formula, because that is the case that pins the branch order: the longer
  // alternative cannot match it at all, so leading with that branch sends it past the first
  // delimiter to close on the last, swallowing the words between. A two-character formula is
  // matched minimally either way and would pass whichever branch leads.
  const html = render("$K$ against $K_i$")

  assert.equal((html.match(/<span class="tex">/g) ?? []).length, 2)
  assert.match(html, /against/)
})

test("display math survives the spacing the lecture slides are written in", () => {
  // Every display equation in `docs/slides/lecture-01/` carries the spaces, and copying one
  // into a cue is the likeliest thing anyone will do with this. Julia refuses the form; two
  // delimiters are unambiguous on their own, so accepting it guesses at nothing.
  const html = render("$$ G(s) \\;=\\; \\frac{K}{\\tau s + 1} $$")

  assert.match(html, /<p class="tex">\$\$G\(s\) \\;=\\; \\frac\{K\}\{\\tau s \+ 1\}\$\$<\/p>/)
})

test("display math broken over its own lines is display math", () => {
  assert.match(render("$$\nG(s) = K\n$$"), /<p class="tex">\$\$G\(s\) = K\$\$<\/p>/)
})

test("a closing delimiter with prose after it ends nothing", () => {
  // An untempered body reaches past that close to whichever later `$$` happens to end a line,
  // and sets the prose between the two as one display equation.
  const html = render("$$G(s)$$ is the plant and\n$$K$$\n")

  assert.equal((html.match(/<span class="tex">/g) ?? []).length, 2)
  assert.doesNotMatch(html, /<p class="tex">/)
  assert.match(html, /is the plant and/)
})

test("empty delimiters are prose, not a formula of nothing", () => {
  assert.doesNotMatch(render("$$   $$"), /class="tex"/)
})

test("prose around a formula is still markdown", () => {
  const html = render("- a **plant** $G(s)$\n  - and a *nested* $K_p$ below\n")

  assert.equal((html.match(/<span class="tex">/g) ?? []).length, 2)
  assert.match(html, /<strong>plant<\/strong>/)
  assert.match(html, /<em>nested<\/em>/)
  assert.equal((html.match(/<ul>/g) ?? []).length, 2, "a nested list still nests")
})
