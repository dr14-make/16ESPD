# Pluto session lifecycle: one kernel per running instance, with the notebook opened in place.

"How often a slow start reports what it is waiting for, in seconds."
const PROGRESS_INTERVAL = 5.0

"How long a kernel may take to reach `ready` before the start is called off, in seconds."
const READY_TIMEOUT = 300.0

const HOST_DEFAULT = "127.0.0.1"

"""
    SessionStartError(message)

A Pluto session could not be brought up, or the notebook it opened never became ready.
"""
struct SessionStartError <: Exception
    message::String
end

Base.showerror(io::IO, err::SessionStartError) = print(io, "SessionStartError: ", err.message)

"""
    Session(pluto, server, notebook, url, secret)

A running Pluto server with one notebook open in it. One kernel per running instance: the
deck, the Pluto editor and every browser attached to either share this one notebook and its
one set of bonds.

`url` is the origin the browser talks to directly — the deck does not proxy Pluto — and
`secret` is what authenticates it there.
"""
struct Session
    pluto::Pluto.ServerSession
    server::Pluto.RunningPlutoServer
    notebook::Pluto.Notebook
    url::String
    secret::String
end

"The id the websocket attaches by."
notebook_id(session::Session) = session.notebook.notebook_id

"The URL that opens this notebook in the Pluto editor, secret included."
edit_url(session::Session) =
    string(session.url, "/edit?id=", notebook_id(session), "&secret=", session.secret)

"""
    in_temp_dir(session) -> Bool

Whether the running notebook is a copy in Pluto's scratch directory rather than the file the
deck names.

`/notebookupload` copies a notebook to `~/.julia/pluto_notebooks` under a generated name, so
the repository file silently stops being the one running and edits made in the editor never
reach it. Opening in place is what keeps this false.
"""
in_temp_dir(session::Session) =
    startswith(session.notebook.path, Pluto.new_notebooks_directory())

"""
    start_session(notebook_path; port, port_hint, host, timeout, io) -> Session

Start a Pluto server and open `notebook_path` in place, returning once the notebook is ready
and every cell has finished its first run.

`port` is Pluto's own port; `nothing` takes the first port free from `port_hint`. The secret
is required for both access and open links, because Pluto accepts websockets from any origin
and a server without a secret lets any page the browser visits run Julia on this machine.

Progress is reported to `io` while the kernel boots, which is tens of seconds even warm.
Throws [`SessionStartError`](@ref) if the kernel dies, parks waiting for permission, or does
not become ready within `timeout` seconds.
"""
function start_session(notebook_path::AbstractString;
        port::Union{Nothing,Integer}=nothing,
        port_hint::Integer=1234,
        host::AbstractString=HOST_DEFAULT,
        timeout::Real=READY_TIMEOUT,
        io::Union{IO,Nothing}=stdout)
    path = abspath(String(notebook_path))
    isfile(path) || throw(SessionStartError("no such notebook: $path"))

    pluto = Pluto.ServerSession()
    pluto.options.server.port = port
    pluto.options.server.port_hint = port_hint
    pluto.options.server.host = String(host)
    pluto.options.server.launch_browser = false
    pluto.options.server.dismiss_update_notification = true
    pluto.options.security.require_secret_for_access = true
    pluto.options.security.require_secret_for_open_links = true

    running = Pluto.run!(pluto)
    session = try
        # execution_allowed keeps the notebook out of waiting_for_permission, which is cleared
        # by a button in the Pluto editor that no deck can reach.
        notebook = Pluto.SessionActions.open(pluto, path; execution_allowed=true, run_async=true)
        Session(pluto, running, notebook, _origin(host, HTTP.Servers.port(running.http_server)),
            pluto.secret)
    catch
        close(running)
        rethrow()
    end

    try
        _wait_until_ready(session; timeout, io)
    catch
        shutdown!(session)
        rethrow()
    end
    return session
end

"""
    shutdown!(session)

Stop the notebook's worker process and the Pluto server. Returns once the worker is gone,
so an interrupted `present` leaves nothing behind.
"""
function shutdown!(session::Session)
    Pluto.SessionActions.shutdown(session.pluto, session.notebook; async=false, verbose=false)
    close(session.server)
    return nothing
end

"Cells that have not finished their run yet."
_pending_cells(notebook::Pluto.Notebook) =
    [cell for cell in notebook.cells if cell.queued || cell.running]

function _wait_until_ready(session::Session; timeout::Real, io::Union{IO,Nothing})
    notebook = session.notebook
    started = time()
    next_report = started + PROGRESS_INTERVAL

    while true
        status = notebook.process_status
        pending = _pending_cells(notebook)

        if status == Pluto.ProcessStatus.ready && isempty(pending)
            _report(io, "  kernel ready in ", _duration(time() - started))
            return session
        elseif status == Pluto.ProcessStatus.waiting_for_permission
            throw(SessionStartError("$(notebook.path) is waiting for permission to run. " *
                "Pluto refuses to run a notebook it has flagged as a risky file source, and " *
                "only a human clicking through the Pluto editor can clear that."))
        elseif status == Pluto.ProcessStatus.no_process
            throw(SessionStartError("the kernel running $(notebook.path) is gone. " *
                "A worker is around 2 GB, so on a loaded machine the most likely cause is " *
                "the out-of-memory killer."))
        end

        elapsed = time() - started
        if elapsed > timeout
            throw(SessionStartError("$(notebook.path) did not become ready within " *
                "$(_duration(timeout)): process_status is \"$status\" and " *
                "$(length(pending)) of $(length(notebook.cells)) cells are still running."))
        end
        if time() >= next_report
            _report(io, "  ", _duration(elapsed), " · ", status, " · ",
                length(pending), " of ", length(notebook.cells), " cells to go")
            next_report += PROGRESS_INTERVAL
        end
        sleep(0.1)
    end
end

"""
Report progress as it happens.

Julia buffers a stream that is not a terminal, so a start-up narrated over tens of seconds
arrives in one block at exit unless every line is flushed.
"""
function _report(io::Union{IO,Nothing}, parts...)
    io === nothing && return nothing
    println(io, parts...)
    flush(io)
    return nothing
end

"An origin a browser can be pointed at; `127.0.0.1` reads better as `localhost`."
_origin(host::AbstractString, port::Integer) =
    string("http://", host == "127.0.0.1" ? "localhost" : host, ":", port)

_duration(seconds::Real) = string(round(Int, seconds), "s")
