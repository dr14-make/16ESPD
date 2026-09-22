import { css } from "lit"
import type { CSSResult } from "lit"

/**
 * The typography of rendered cue markdown, shared by the overlay and the speaker page.
 *
 * Both render the same markdown through the same parser into a shadow root of their own, so the
 * rules travel with the markup rather than being restated per page.
 */
export const cueBodyStyles: CSSResult = css`
  .cue-body {
    & :first-child {
      margin-block-start: 0;
    }

    & :last-child {
      margin-block-end: 0;
    }

    & code {
      font-family: ui-monospace, monospace;
      font-size: 0.9em;
    }

    & a {
      color: inherit;
    }

    & .cue-absent {
      color: var(--muted);
      font-style: italic;
    }
  }
`
