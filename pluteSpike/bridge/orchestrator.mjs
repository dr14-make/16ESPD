// Serves the deck and hands it a ready notebook.
//
// Rainbow's createWorker() concatenates `${server_url}/notebookupload` and never forwards
// the secret, so it cannot open a notebook on a secret-protected server. The upload happens
// here instead; the browser then attaches to the returned id over the websocket, which does
// carry the secret.

import { createServer } from "node:http"
import { readFile } from "node:fs/promises"
import { existsSync, readFileSync } from "node:fs"
import { join, extname, dirname, normalize } from "node:path"
import { fileURLToPath } from "node:url"

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = join(HERE, "..")
const FRONTEND = join(ROOT, "frontend")
const SESSION_FILE = join(ROOT, "backend", ".session")
const NOTEBOOK = join(ROOT, "backend", "notebook.jl")
const PORT = Number(process.env.PLUTE_UI_PORT ?? 8099)

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

function readSession() {
  if (!existsSync(SESSION_FILE)) return null
  const [port, secret] = readFileSync(SESSION_FILE, "utf8").trim().split("\n")
  if (!port || !secret) return null
  return { port: Number(port), secret, url: `http://localhost:${port}` }
}

async function waitForPluto(timeoutMs = 180000) {
  const t0 = Date.now()
  let announced = false
  while (Date.now() - t0 < timeoutMs) {
    const s = readSession()
    if (s) {
      if (!announced) { console.log(`[bridge] waiting for Pluto on ${s.url} …`); announced = true }
      try {
        const r = await fetch(`${s.url}/?secret=${s.secret}`)
        if (r.ok) return s
      } catch {}
    }
    await sleep(500)
  }
  throw new Error(`Pluto did not come up within ${timeoutMs / 1000}s`)
}

async function openNotebook(session) {
  // /open?path= runs the file where it lives, so edits made in the Pluto editor save back to
  // backend/notebook.jl. /notebookupload instead copies it to ~/.julia/pluto_notebooks under
  // an auto-generated name, and the repo file then silently stops being the one running.
  // execution_allowed keeps it out of `waiting_for_permission`, which no deck can clear.
  const q = new URLSearchParams({
    secret: session.secret,
    path: NOTEBOOK,
    execution_allowed: "true",
  })
  const res = await fetch(`${session.url}/open?${q}`, { method: "POST" })
  if (!res.ok) throw new Error(`open failed: ${res.status} ${res.statusText}`)
  return (await res.text()).trim()
}

const session = await waitForPluto()
console.log(`[bridge] Pluto up on ${session.url}`)
const notebook_id = await openNotebook(session)
console.log(`[bridge] notebook opened: ${notebook_id}`)

const editUrl = `${session.url}/edit?id=${notebook_id}&secret=${session.secret}`
console.log(`[bridge] notebook editor: ${editUrl}`)

const info = JSON.stringify({ plutoUrl: session.url, secret: session.secret, notebook_id, editUrl })

createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`)

  if (url.pathname === "/api/session") {
    res.writeHead(200, { "content-type": MIME[".json"], "cache-control": "no-store" })
    return res.end(info)
  }

  const rel = url.pathname === "/" ? "/index.html" : url.pathname
  const file = join(FRONTEND, normalize(rel).replace(/^(\.\.[/\\])+/, ""))
  if (!file.startsWith(FRONTEND)) {
    res.writeHead(403)
    return res.end("forbidden")
  }
  try {
    const body = await readFile(file)
    res.writeHead(200, {
      "content-type": MIME[extname(file)] ?? "application/octet-stream",
      "cache-control": "no-store",
    })
    res.end(body)
  } catch (e) {
    // Only a genuinely absent file is a 404. Anything else is a bug in here, and answering
    // 404 for it hides the cause behind a page that merely looks unserved.
    if (e.code === "ENOENT") {
      res.writeHead(404, { "content-type": "text/plain" })
      return res.end("not found")
    }
    console.error(`[bridge] failed serving ${rel}:`, e)
    res.writeHead(500, { "content-type": "text/plain" })
    res.end(`server error: ${e.message}`)
  }
}).listen(PORT, "127.0.0.1", () => {
  console.log(`[bridge] deck on http://localhost:${PORT}`)
})
