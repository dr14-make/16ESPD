// The one global kernel state the deck chrome shows.
//
// Separate from `deck.js` because it is the only part of the chrome that can be decided without
// a browser: everything else is DOM, and this is a total function over what the kernel reports.

/**
 * Which of the four states the chrome is in, and what to say about it.
 *
 * `failure` is set when connecting threw; `connected` is the websocket; `process` is Pluto's
 * own `process_status`, or null before there is one.
 *
 * The message carries the warming-up wording, which is why a card's placeholder is only ever
 * its own name: one explanation on the chrome beats the same sentence on every card.
 */
export function kernelStatus({ failure = null, connected = true, process = null } = {}) {
  if (failure != null) return { state: "error", message: String(failure) }
  if (!connected) return { state: "offline", message: "the kernel connection dropped" }

  switch (process) {
    case "ready":
      return { state: "ready", message: "kernel ready" }
    case "starting":
    case null:
    case undefined:
      return { state: "connecting", message: "the kernel is starting; cards fill in when it is" }
    case "no_process":
      return { state: "offline", message: "the kernel is not running" }
    // Pluto parks a notebook here when it was opened without `execution_allowed`, which
    // `start_session` always sets — so reaching this state means the session is not ours.
    case "waiting_for_permission":
      return { state: "error", message: "the notebook is waiting for permission to run" }
    default:
      return { state: "error", message: `the kernel reports ${String(process).replace(/_/g, " ")}` }
  }
}
