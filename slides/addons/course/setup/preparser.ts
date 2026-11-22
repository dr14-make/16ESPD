import { definePreparserSetup } from '@slidev/types'

// A deck's short version builds from the same source when SLIDEV_CUT is set: every slide whose
// frontmatter has `skipInCut: true` is hidden, which drops it from the deck and its export.
// Without SLIDEV_CUT nothing is hidden, so the full deck and the handout keep every slide.
export default definePreparserSetup(() => {
  if (!process.env.SLIDEV_CUT) return []
  return [{
    transformSlide(_content, frontmatter) {
      if (frontmatter.skipInCut) frontmatter.hide = true
      return undefined
    },
  }]
})
