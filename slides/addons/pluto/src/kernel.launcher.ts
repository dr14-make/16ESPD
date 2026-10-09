// Runs the Pluto server a live deck's cards connect to, for as long as `slidev dev` serves the
// deck, and takes every process it started down with it.
//
// Pluto starts each notebook's worker in a session of its own, so neither a signal to Julia nor
// one to its process group reaches the workers. What does is the process tree, read before
// anything in it is stopped, since a worker whose server is gone is no longer Julia's child.

import { execFileSync, spawn } from "node:child_process"
import { randomBytes } from "node:crypto"
import { createServer } from "node:net"
import { createInterface } from "node:readline"
import { setTimeout as sleep } from "node:timers/promises"
import { fileURLToPath } from "node:url"

/** The Julia project and script that start Pluto. */
const KERNEL = fileURLToPath(new URL("../kernel/", import.meta.url))

/** How long Julia gets to stop its workers once told to, before everything is killed. */
const GRACE_MS = 5_000

/** How often to ask a starting Pluto whether it answers yet. */
const PING_MS = 500

/** Signals that end Node without an `exit` event unless something listens for them. */
const FATAL_SIGNALS = ["SIGINT", "SIGHUP"] as const

export interface Supervised {
  /** The process's id, once it has started. */
  readonly pid: number | undefined
  /** Resolves once the process has exited, or failed to start. */
  readonly exited: Promise<void>
  /** Close its stdin, then kill whatever of its tree is left after the grace period. */
  stop(): Promise<void>
}

/**
 * Start `file`, pass each line it prints to `log`, and make sure that it, and every process it
 * starts, ends no later than this one does.
 *
 * Stopping closes the child's stdin and is the only request it gets: anything still running after
 * `grace` is killed. When Node exits first, or dies of SIGINT or SIGHUP, there is no time to wait,
 * and the tree is killed at once. A child whose Node was killed outright sees its stdin close.
 */
export function supervise(
  file: string,
  args: readonly string[],
  log: (line: string) => void,
  grace = GRACE_MS,
): Supervised {
  const child = spawn(file, args, { detached: true, stdio: ["pipe", "pipe", "pipe"] })
  createInterface({ input: child.stdout }).on("line", log)
  createInterface({ input: child.stderr }).on("line", log)

  let stopping = false
  const exited = new Promise<void>((done) => {
    child.once("error", (error) => {
      log(`could not start ${file}: ${error.message}`)
      done()
    })
    child.once("exit", (code, signal) => {
      if (!stopping) {
        log(`${file} exited with ${code ?? signal ?? "nothing"}`)
      }
      done()
    })
  })

  const running = () =>
    child.pid !== undefined && child.exitCode === null && child.signalCode === null

  const killNow = (): void => {
    if (running() && child.pid !== undefined) {
      kill(processTree(child.pid), "SIGKILL")
    }
  }
  const onSignal = (signal: NodeJS.Signals): void => {
    killNow()
    release()
    // Raised again with this listener gone, so that Node's default, or whatever else listens,
    // ends the process as it would have. Left alone, a listener such as signal-exit's, which
    // stands down while another one is registered, would keep it alive.
    process.kill(process.pid, signal)
  }
  const release = (): void => {
    process.off("exit", killNow)
    for (const signal of FATAL_SIGNALS) {
      process.off(signal, onSignal)
    }
  }
  process.once("exit", killNow)
  for (const signal of FATAL_SIGNALS) {
    process.once(signal, onSignal)
  }
  void exited.then(release)

  return {
    pid: child.pid,
    exited,
    async stop() {
      if (stopping) {
        return exited
      }
      stopping = true
      release()
      if (!running() || child.pid === undefined) {
        return exited
      }
      const tree = processTree(child.pid)
      child.stdin.end()
      await Promise.race([exited, sleep(grace, undefined, { ref: false })])
      kill(tree, "SIGKILL")
      await exited
    },
  }
}

/** `root` and every process descended from it, parents first. */
export function processTree(root: number): number[] {
  const children = new Map<number, number[]>()
  const table = execFileSync("ps", ["-A", "-o", "pid=,ppid="], { encoding: "utf8" })
  for (const line of table.split("\n")) {
    const [pid, ppid] = line.trim().split(/\s+/).map(Number)
    if (pid !== undefined && ppid !== undefined && !Number.isNaN(pid) && !Number.isNaN(ppid)) {
      children.set(ppid, [...(children.get(ppid) ?? []), pid])
    }
  }
  const tree = [root]
  // An array iterator reads the length on every step, so this walks what it appends.
  for (const pid of tree) {
    tree.push(...(children.get(pid) ?? []))
  }
  return tree
}

function kill(pids: readonly number[], signal: NodeJS.Signals): void {
  for (const pid of pids) {
    try {
      process.kill(pid, signal)
    } catch {
      // Already gone.
    }
  }
}

/** Where a running Pluto server is, and how to stop it. */
export interface PlutoServer {
  readonly plutoUrl: string
  readonly secret: string
  /**
   * Whether Pluto answered before Julia exited. It opens its notebooks before it listens, so an
   * answer means they are listed.
   */
  readonly ready: Promise<boolean>
  stop(): Promise<void>
}

/**
 * Start Pluto with `notebooks` open, on a free port of this machine and behind a fresh secret.
 *
 * Julia is `$JULIA`, or `julia` on the path; juliaup's `JULIAUP_CHANNEL` picks its channel. Pluto
 * runs every worker on the binary the server runs on, so this is the Julia the notebooks get too.
 */
export async function launchPluto(
  notebooks: readonly string[],
  log: (line: string) => void,
): Promise<PlutoServer> {
  const port = await freePort()
  const secret = randomBytes(16).toString("hex")
  const args = [
    "--startup-file=no",
    `--project=${KERNEL}`,
    `${KERNEL}pluto.jl`,
    String(port),
    secret,
    ...notebooks,
  ]
  const server = supervise(process.env.JULIA ?? "julia", args, log)
  return {
    plutoUrl: `http://localhost:${port}`,
    secret,
    ready: answers(`http://127.0.0.1:${port}/ping`, server.exited),
    stop: () => server.stop(),
  }
}

/** Ask `url` until it answers, or until `exited` settles. */
async function answers(url: string, exited: Promise<void>): Promise<boolean> {
  const gone = exited.then(() => false)
  for (;;) {
    if (await fetch(url).then((response) => response.ok, () => false)) {
      return true
    }
    if (!(await Promise.race([gone, sleep(PING_MS, true)]))) {
      return false
    }
  }
}

/** A port nothing listens on yet. Pluto may lose it to another process before it binds. */
async function freePort(): Promise<number> {
  const server = createServer().listen(0, "127.0.0.1")
  await new Promise((done) => server.once("listening", done))
  const address = server.address()
  await new Promise((done) => server.close(done))
  if (address === null || typeof address === "string") {
    throw new Error("the loopback interface handed out no port")
  }
  return address.port
}
