// The state the deck chrome, the cards, the cue overlay and the speaker page all read.
//
// `<deck-app>` provides them and is the only writer; everything below it consumes. A card consumes content and a painter, never the kernel: it is given what to show and
// cannot go looking, which is what keeps a second source of content one more entry in the map
// rather than a second renderer.

import { createContext } from "@lit/context"
import type { CardContent, Deck } from "./deck.interface.js"
import type { KernelStatus } from "./kernel.status.js"
import type { Painter } from "./render.painter.js"

export const deckContext = createContext<Deck | null>(Symbol.for("plutodeck.deck"))

/** Where the notebook opens in Pluto. Null until `/api/session` has answered. */
export const editUrlContext = createContext<string | null>(Symbol.for("plutodeck.edit-url"))

export const slideIndexContext = createContext<number>(Symbol.for("plutodeck.slide-index"))

export const kernelStatusContext = createContext<KernelStatus>(Symbol.for("plutodeck.kernel-status"))

/** What each card is currently showing, keyed by the card name the deck placed. */
export type CardContents = ReadonlyMap<string, CardContent>

export const cardContentContext = createContext<CardContents>(Symbol.for("plutodeck.card-content"))

/** Null until the kernel is reached, which is the whole window a card spends as a placeholder. */
export const painterContext = createContext<Painter | null>(Symbol.for("plutodeck.painter"))
