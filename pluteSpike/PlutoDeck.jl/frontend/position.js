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

/**
 * Announce where this deck window is.
 *
 * `source` is per window and `deck` is per server. Two windows showing the same deck are
 * same-origin and carry the same path, so `source` is the only thing that tells them apart, and
 * a follower needs to tell them apart to say that two decks are driving it rather than flipping
 * silently between them.
 */
export class Position {
  #channel = new BroadcastChannel(CHANNEL)
  // Not `crypto.randomUUID`: that is undefined outside a secure context, and a deck reached
  // over http at a LAN address rather than at localhost would throw here and take the whole
  // page with it. Telling two windows apart needs no more than this.
  #source = Math.random().toString(36).slice(2)
  #deck
  #index = 0

  constructor({ deck }) {
    this.#deck = deck

    // A speaker page opened between two beats of a deck nobody is paging would otherwise sit on
    // "no deck" for up to a heartbeat with a deck right there.
    this.#channel.addEventListener("message", ({ data }) => {
      if (data?.type === "hello") this.#post("at")
    })

    setInterval(() => this.#post("at"), HEARTBEAT_MS)

    // Closing and reloading are the two cases a timer would only catch `STALE_MS` late, and a
    // reload that says nothing leaves the follower briefly believing two decks are open. The
    // timer is what covers a window that never got to say this — `pagehide` can be skipped.
    window.addEventListener("pagehide", () => this.#post("gone"))

    this.#post("at")
  }

  /** The deck is showing slide `index`. */
  moved(index) {
    this.#index = index
    this.#post("at")
  }

  #post(type) {
    this.#channel.postMessage({ type, deck: this.#deck, source: this.#source, index: this.#index })
  }
}

/**
 * Follow whichever deck window is talking, and notice when none is.
 *
 * `onChange` is handed `{ status, index, decks }`, where `status` is `"waiting"` until a deck
 * has been heard from at all, `"live"` while one is, and `"lost"` once every deck that was has
 * fallen silent. `decks` counts the windows heard from inside the staleness window.
 *
 * Messages naming another `deck` are ignored rather than followed: the path is the guard that a
 * channel name shared across deck servers cannot be.
 */
export class Following {
  #channel = new BroadcastChannel(CHANNEL)
  #onChange
  #deck
  #index = null
  #heard = new Map()

  constructor({ deck, onChange }) {
    this.#deck = deck
    this.#onChange = onChange

    this.#channel.addEventListener("message", ({ data }) => this.#heardFrom(data))
    setInterval(() => this.#prune(), HEARTBEAT_MS / 2)

    this.#channel.postMessage({ type: "hello", deck })
    this.#report()
  }

  #heardFrom(message) {
    if (message?.deck !== this.#deck) return

    if (message.type === "gone") {
      this.#heard.delete(message.source)
    } else if (message.type === "at") {
      this.#heard.set(message.source, performance.now())
      this.#index = message.index
    } else {
      return
    }
    this.#report()
  }

  #prune() {
    const cutoff = performance.now() - STALE_MS
    let dropped = false
    for (const [source, at] of this.#heard) {
      if (at < cutoff) dropped = this.#heard.delete(source) || dropped
    }
    if (dropped) this.#report()
  }

  #report() {
    this.#onChange({
      status: this.#index === null ? "waiting" : this.#heard.size === 0 ? "lost" : "live",
      index: this.#index,
      decks: this.#heard.size,
    })
  }
}
