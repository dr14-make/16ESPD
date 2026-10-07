// The one global kernel state the deck chrome shows: a total function over what the kernel
// reports, and the four states the chrome can be in.

/** Pluto's own `process_status`, or null before there is one. */
export type ProcessStatus = "ready" | "starting" | "no_process" | "waiting_for_permission"

export type KernelState = "ready" | "connecting" | "offline" | "error"

export interface KernelStatus {
  readonly state: KernelState
  readonly message: string
}

export interface KernelReport {
  /** Set when connecting threw. */
  readonly failure?: string | null
  readonly connected?: boolean
  // The four Pluto reports, kept open: a status Pluto grows later must reach the `default`
  // branch and name itself rather than fail to compile.
  readonly process?: ProcessStatus | (string & {}) | null
}

const NO_REPORT: Required<KernelReport> = { failure: null, connected: true, process: null }

/**
 * Which of the four states the chrome is in, and what to say about it.
 *
 * The message carries the warming-up wording, which is why a card's placeholder is only ever
 * its own name: one explanation on the chrome beats the same sentence on every card.
 */
export function kernelStatus(report: KernelReport = {}): KernelStatus {
  const { failure, connected, process } = { ...NO_REPORT, ...report }

  if (failure !== null) {
    return { state: "error", message: failure }
  }
  if (!connected) {
    return { state: "offline", message: "the kernel connection dropped" }
  }

  switch (process) {
    case "ready":
      return { state: "ready", message: "kernel ready" }
    case "starting":
    case null:
      return { state: "connecting", message: "the kernel is starting; cards fill in when it is" }
    case "no_process":
      return { state: "offline", message: "the kernel is not running" }
    // Pluto parks a notebook here when it was opened without `execution_allowed`, which
    // `start_session` always sets — so reaching this state means the session is not ours.
    case "waiting_for_permission":
      return { state: "error", message: "the notebook is waiting for permission to run" }
    default:
      return { state: "error", message: `the kernel reports ${process.replace(/_/g, " ")}` }
  }
}
