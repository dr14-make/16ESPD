// Where the deck is, crossing to the speaker window.
//
// `BroadcastChannel` has no presence and no disconnect event: a deck that was closed and a deck
// that has not been paged for a minute are the same silence. So a deck repeats where it is on a
// timer as well as on every move, and a follower that has heard nothing for `STALE_MS` says it
// has lost the deck. A slide number that was true once, sitting there looking live, is the one
// failure worse than the blocked popup this replaces.

/** Same-origin by construction: the two windows are served by the one deck server. */
const CHANNEL = "plutodeck-position"

/** How often a deck repeats where it is, whether or not it has moved. */
export const HEARTBEAT_MS = 2000

/**
 * How long a follower waits before calling what it was told stale.
 *
 * Three heartbeats, because one missed beat is a busy main thread — a reactive run repainting
 * every card — and blaming a deck that is fine is its own way of being wrong in front of a room.
 */
export const STALE_MS = 3 * HEARTBEAT_MS

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

type PositionMessage =
  | { readonly type: "hello"; readonly deck: string }
  | {
      readonly type: "at" | "gone"
      readonly deck: string
      readonly source: string
      readonly index: number
    }

function isPositionMessage(data: unknown): data is PositionMessage {
  if (!isRecord(data)) {
    return false
  }
  const message = data
  if (typeof message.deck !== "string") {
    return false
  }
  if (message.type === "hello") {
    return true
  }
  // A follower tells two deck windows apart by `source` and renders a slide by `index`, so a
  // message missing either is one it cannot act on.
  return (
    (message.type === "at" || message.type === "gone") &&
    typeof message.source === "string" &&
    typeof message.index === "number"
  )
}

/** Whether a follower has heard from a deck, and whether what it heard is still current. */
export type FollowStatus = "waiting" | "live" | "lost"

export interface FollowReport {
  readonly status: FollowStatus
  readonly index: number | null
  /** How many deck windows were heard from inside the staleness window. */
  readonly decks: number
}

/**
 * Announce where this deck window is.
 *
 * `source` is per window and `deck` is per server. Two windows showing the same deck are
 * same-origin and carry the same path, so `source` is the only thing that tells them apart, and
 * a follower needs to tell them apart to say that two decks are driving it rather than flipping
 * silently between them.
 */
export class Position {
  readonly #channel = new BroadcastChannel(CHANNEL)
  // Not `crypto.randomUUID`: that is undefined outside a secure context, and a deck reached
  // over http at a LAN address rather than at localhost would throw here and take the whole
  // page with it. Telling two windows apart needs no more than this.
  readonly #source = Math.random().toString(36).slice(2)
  readonly #deck: string
  #index = 0
  #beat: ReturnType<typeof setInterval> | null = null

  constructor(deck: string) {
    this.#deck = deck

    // A speaker page opened between two beats of a deck nobody is paging would otherwise sit on
    // "no deck" for up to a heartbeat with a deck right there.
    this.#channel.addEventListener("message", ({ data }: MessageEvent<unknown>) => {
      if (isPositionMessage(data) && data.type === "hello") {
        this.#post("at")
      }
    })

    this.#beat = setInterval(() => this.#post("at"), HEARTBEAT_MS)

    // Closing and reloading are the two cases a timer would only catch `STALE_MS` late, and a
    // reload that says nothing leaves the follower briefly believing two decks are open. The
    // timer is what covers a window that never got to say this — `pagehide` can be skipped.
    window.addEventListener("pagehide", () => this.#post("gone"))

    this.#post("at")
  }

  /** Say this window is going, and stop announcing. */
  stop(): void {
    this.#post("gone")
    if (this.#beat !== null) {
      clearInterval(this.#beat)
      this.#beat = null
    }
    this.#channel.close()
  }

  /** The deck is showing slide `index`. */
  moved(index: number): void {
    this.#index = index
    this.#post("at")
  }

  #post(type: "at" | "gone"): void {
    this.#channel.postMessage({
      type,
      deck: this.#deck,
      source: this.#source,
      index: this.#index,
    })
  }
}

/**
 * Follow whichever deck window is talking, and notice when none is.
 *
 * Messages naming another `deck` are ignored rather than followed: the path is the guard that a
 * channel name shared across deck servers cannot be.
 */
export class Following {
  readonly #channel = new BroadcastChannel(CHANNEL)
  readonly #onChange: (report: FollowReport) => void
  readonly #deck: string
  #index: number | null = null
  readonly #heard = new Map<string, number>()
  #sweep: ReturnType<typeof setInterval> | null = null

  constructor(deck: string, onChange: (report: FollowReport) => void) {
    this.#deck = deck
    this.#onChange = onChange

    this.#channel.addEventListener("message", ({ data }: MessageEvent<unknown>) => {
      if (isPositionMessage(data)) {
        this.#heardFrom(data)
      }
    })
    this.#sweep = setInterval(() => this.#prune(), HEARTBEAT_MS / 2)

    this.#channel.postMessage({ type: "hello", deck })
    this.#report()
  }

  /** Stop following, and stop reporting. */
  stop(): void {
    if (this.#sweep !== null) {
      clearInterval(this.#sweep)
      this.#sweep = null
    }
    this.#channel.close()
  }

  #heardFrom(message: PositionMessage): void {
    if (message.deck !== this.#deck || message.type === "hello") {
      return
    }

    if (message.type === "gone") {
      this.#heard.delete(message.source)
    } else {
      this.#heard.set(message.source, performance.now())
      this.#index = message.index
    }
    this.#report()
  }

  #prune(): void {
    const cutoff = performance.now() - STALE_MS
    let dropped = false
    for (const [source, at] of this.#heard) {
      if (at < cutoff) {
        dropped = this.#heard.delete(source) || dropped
      }
    }
    if (dropped) {
      this.#report()
    }
  }

  #report(): void {
    this.#onChange({
      status: this.#index === null ? "waiting" : this.#heard.size === 0 ? "lost" : "live",
      index: this.#index,
      decks: this.#heard.size,
    })
  }
}
