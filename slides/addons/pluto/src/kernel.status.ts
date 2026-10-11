// The one kernel state a window puts on its page, as `data-kernel` on its body, where the live
// suite reads it: a total function over what the kernel reports.

/** Pluto's own `process_status`, or null before there is one. */
type ProcessStatus = "ready" | "starting" | "no_process" | "waiting_for_permission"

type KernelState = "ready" | "connecting" | "offline" | "error"

export interface KernelReport {
  /** Set when connecting threw. */
  readonly failure?: string | null
  readonly connected?: boolean
  // The four Pluto reports, kept open: a status Pluto grows later must reach the `default`
  // branch rather than fail to compile.
  readonly process?: ProcessStatus | (string & {}) | null
}

const NO_REPORT: Required<KernelReport> = { failure: null, connected: true, process: null }

/** Which of the four states the kernel is in. */
export function kernelState(report: KernelReport = {}): KernelState {
  const { failure, connected, process } = { ...NO_REPORT, ...report }

  if (failure !== null) {
    return "error"
  }
  if (!connected) {
    return "offline"
  }

  switch (process) {
    case "ready":
      return "ready"
    case "starting":
    case null:
      return "connecting"
    case "no_process":
      return "offline"
    // Pluto parks a notebook here when it was opened without `execution_allowed`. A Pluto the
    // deck starts always allows it, so this is a notebook on a server someone else runs, which
    // its owner has to let run.
    case "waiting_for_permission":
    default:
      return "error"
  }
}
