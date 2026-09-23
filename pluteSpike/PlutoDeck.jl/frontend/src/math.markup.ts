// The math markup a card already arrives with, emitted from the markdown a cue is written in.
//
// PlutoRunner overrides Julia's Markdown HTML writer inside the kernel, so a notebook's math
// reaches the deck already marked up: `<span class="tex">$…$</span>` inline and
// `<p class="tex">$$…$$</p>` display. `marked` has no math, so this emits the same and one
// typeset pass covers both. See DESIGN.md § Math is Pluto's markup.
//
// The delimiters stay in the text because they are what MathJax scans for; the class is what
// the pass is aimed at.

import type { MarkedExtension, TokenizerAndRendererExtension, Tokens } from "marked"

/**
 * Inline math, by the rule Julia's own parser applies.
 *
 * `parse_inline_wrapper` opens on a run of delimiters, refuses whitespace straight after it,
 * and closes on a run of the same length whose preceding character is neither whitespace nor a
 * newline. That last clause is the whole of what leaves a price — `costs $5 and $6` — as the
 * prose it is rather than as a formula swallowing the words between.
 *
 * The run may be longer than one, and `Markdown.htmlinline` writes a single `$` whatever it
 * was, so a `$$…$$` that never started a block is inline math here exactly as it is in Pluto.
 *
 * The one-character alternative comes first: a lazy quantifier still prefers the branch to its
 * left, so `$a$ and $b$` with the longer branch leading closes on the last delimiter and eats
 * the sentence.
 */
const INLINE = /^(\$+)([^\s$]|[^\s$][\s\S]*?[^\s$])\1(?!\$)/

/**
 * Display math, which is a block of its own.
 *
 * Whitespace inside the delimiters is allowed, which Julia refuses — `$$ u = k e $$` and the
 * form broken over three lines are both refused by `parse_inline_wrapper`. Every display
 * equation in `docs/slides/lecture-01/` is written with the spaces, and copying one of those
 * into a cue is the likeliest thing an author will ever do with this. Two delimiters are
 * unambiguous on their own, so nothing is being guessed at by accepting it.
 *
 * The same line in a notebook cell does not degrade to prose: Julia leaves a bare `$` in the
 * tree and the `md` macro throws `UndefVarError`, losing the whole card.
 *
 * Exactly two, rather than Julia's run of any length: a paragraph that merely opens with `$…$`
 * becomes a display block there and stays the paragraph it reads as here.
 *
 * The body cannot cross a `$$`, so a closing delimiter with prose after it on its line fails the
 * block and falls through to the inline rule. An untempered body reaches past it to whichever
 * later `$$` happens to end a line, and sets the prose between them as one display equation.
 *
 * See DESIGN.md § Math is Pluto's markup for the full list of where the two part company.
 */
const BLOCK = /^ {0,3}\$\$(?!\$)((?:(?!\$\$)[\s\S])*?)\$\$(?:\n+|$)/

/**
 * Where the next delimiter could open, so `marked` ends its run of plain text there.
 *
 * An escaped `$` is not one: without the lookbehind the text run ends on the backslash, which
 * is then emitted as the character it was meant to hide.
 */
function nextInline(src: string): number | undefined {
  return /(?<!\\)\$/.exec(src)?.index
}

/**
 * The three characters a formula cannot carry into the document raw.
 *
 * LaTeX spends all of them freely — `$a < b$`, an `&` aligning an equation — and raw they would
 * close the span or open a tag. Escaped, the DOM hands MathJax back what the author wrote,
 * which is what `htmlesc` achieves on the Julia side by escaping a great deal more.
 */
function escapeHtml(formula: string): string {
  return formula.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
}

/** The formula a tokenizer stored, which is the only field these tokens carry beyond `marked`'s own. */
interface TexToken extends Tokens.Generic {
  formula: string
}

function isTexToken(token: Tokens.Generic): token is TexToken {
  return typeof token.formula === "string"
}

const inlineTex: TokenizerAndRendererExtension = {
  name: "inlineTex",
  level: "inline",
  start: nextInline,
  tokenizer(src) {
    const match = INLINE.exec(src)
    return match?.[2] === undefined
      ? undefined
      : { type: "inlineTex", raw: match[0], formula: match[2] }
  },
  renderer(token) {
    // Nothing at all rather than a stray pair of delimiters on a slide.
    return isTexToken(token) ? `<span class="tex">$${escapeHtml(token.formula)}$</span>` : ""
  },
}

/**
 * No `start`: a block-level one tells `marked` where a paragraph may be cut short, and display
 * math cannot interrupt a paragraph any more than it can in Julia — it opens a block or it is
 * the inline form. Offering one cuts every paragraph at its first `$`.
 */
const blockTex: TokenizerAndRendererExtension = {
  name: "blockTex",
  level: "block",
  tokenizer(src) {
    const match = BLOCK.exec(src)
    if (match?.[1] === undefined) {
      return undefined
    }
    // Trimmed here rather than in the pattern, so that `$$  $$` is the empty formula it looks
    // like and falls through to prose instead of reaching MathJax as nothing at all.
    const formula = match[1].trim()
    return formula === "" ? undefined : { type: "blockTex", raw: match[0], formula }
  },
  renderer(token) {
    return isTexToken(token) ? `<p class="tex">$$${escapeHtml(token.formula)}$$</p>\n` : ""
  },
}

/**
 * Math for a `Marked` instance.
 *
 * A tokenizer, because `_`, `*` and `\` are markdown's too: `$a_1 + b_2$` left to the inline
 * lexer arrives as emphasis wrapped around half a formula, with the underscores gone and
 * nothing to say they were ever there.
 */
export const texMarkup: MarkedExtension = { extensions: [blockTex, inlineTex] }
