# A small Chrome DevTools Protocol client, enough to drive a deck in a real browser.
#
# A Node-side DOM harness cannot see this class of bug: the Rainbow bundle needs `process`
# shimmed before it is imported, and Node defines `process` itself, so a jsdom run passes over a
# page that is broken in every browser. Only a real one is evidence.

import HTTP
import JSON

const CHROME_BINARIES = ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser")

"How long a DevTools command may take before the run is called off, in seconds."
const COMMAND_TIMEOUT = 30.0

"How long Chrome may take to write its debugging port, in seconds."
const LAUNCH_TIMEOUT = 30.0

"""
How long a page may take to fire its load event, in seconds.

A module script delays that event until it has finished evaluating, and the deck's entry module
awaits its kernel connection at the top level, so this covers a cold websocket too.
"""
const NAVIGATION_TIMEOUT = 180.0

"""
    chrome_binary() -> Union{String,Nothing}

The headless browser to drive, or `nothing` if none is installed.
"""
function chrome_binary()
    for name in CHROME_BINARIES
        binary = Sys.which(name)
        binary === nothing || return binary
    end
    return nothing
end

"""
    Browser(process, websocket, ...)

A running headless Chrome and the websocket carrying its DevTools protocol.

Commands and events share one connection: a command carries an `id` and is answered by a
message carrying the same `id`, while everything else is an event. A reader task sorts the two,
so `command` can wait for its own answer without losing the events that arrive meanwhile.
"""
mutable struct Browser
    process::Base.Process
    websocket::HTTP.WebSockets.WebSocket
    pending::Dict{Int,Channel{Any}}
    problems::Dict{String,Vector{String}}
    loads::Dict{String,Int}
    lock::ReentrantLock
    last_id::Int
end

"""
    ProtocolError(method, message)

A DevTools command was refused, or the page it ran in threw.
"""
struct ProtocolError <: Exception
    method::String
    message::String
end

Base.showerror(io::IO, err::ProtocolError) = print(io, "ProtocolError: ", err.method, ": ", err.message)

"""
Resolve nothing but the loopback, so a fetch off this machine fails the way it would in a
lecture hall with no wifi.

A deck holds every library it draws with, and every way it can stop doing so is silent at a
desk: a plot falls through to esm.sh when the bundled Plotly version and the notebook's
disagree, and PlutoPlotly's own script imports lodash and interact.js from a CDN outright. A
machine with wifi cannot tell any of them from working. See issue 028.
"""
const NO_NETWORK = "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost, EXCLUDE 127.0.0.1"

"""
    with_browser(body; arguments) -> Any

Run `body(browser)` against a freshly launched headless Chrome, and take the browser down
afterwards however `body` ends. `arguments` are extra flags for that Chrome.

A leaked headless instance is not a tidiness problem here: `earlyoom` on this machine prefers
these processes, and accumulated browsers are what got a Pluto kernel killed twice.
"""
function with_browser(body; arguments::Vector{String}=String[])
    binary = chrome_binary()
    binary === nothing && error("no Chrome on PATH; looked for " * join(CHROME_BINARIES, ", "))

    # `mktempdir` deletes the profile when this process exits, which is the only moment Chrome
    # is reliably finished with it; deleting it here races the renderers still shutting down.
    profile = mktempdir()
    process = run(pipeline(`$binary
            --headless=new
            --remote-debugging-port=0
            --user-data-dir=$profile
            --no-first-run
            --no-default-browser-check
            --disable-gpu
            --disable-dev-shm-usage
            --disable-extensions
            --disable-background-networking
            --disable-component-update
            $arguments
            about:blank`; stdout=devnull, stderr=devnull); wait=false)

    try
        HTTP.WebSockets.open(_debugger_url(process, profile)) do websocket
            browser = Browser(process, websocket, Dict{Int,Channel{Any}}(),
                Dict{String,Vector{String}}(), Dict{String,Int}(), ReentrantLock(), 0)
            reader = @async _read_loop(browser)
            try
                body(browser)
            finally
                close(websocket)
                wait(reader)
            end
        end
    finally
        kill(process)
        wait(process)
    end
end

"""
    renderer_rss(browser) -> Vector{Int}

The resident size of every renderer process `browser` is running, in kilobytes, read from
`/proc`.

The renderer 027 measured held 7.0 GB of Blink strings against a 40.6 MB JavaScript heap, so
`performance.memory` and `Runtime.queryObjects` are blind to this class of bug by construction.
Only the process's own resident size sees those bytes, and only Linux publishes it here.

Every renderer rather than one, because a browser driving several pages has several and the
page under test is not identifiable from out here: what a caller asserts is the largest.
"""
function renderer_rss(browser::Browser)
    sizes = Int[]
    for pid in _descendants(getpid(browser.process))
        cmdline = _proc_read("/proc/$pid/cmdline")
        (cmdline === nothing || !occursin("--type=renderer", cmdline)) && continue
        status = _proc_read("/proc/$pid/status")
        status === nothing && continue
        matched = match(r"VmRSS:\s+(\d+) kB", status)
        matched === nothing || push!(sizes, parse(Int, matched[1]))
    end
    return sizes
end

"A process that exited between the scan and the read is gone, not a failure to read it."
function _proc_read(path::AbstractString)
    return try
        read(path, String)
    catch err
        err isa InterruptException && rethrow()
        nothing
    end
end

"""
Every descendant of `pid`, transitively.

A renderer is a grandchild rather than a child — Chrome forks them from its zygote — so the
whole tree is walked rather than one generation of it.
"""
function _descendants(pid::Integer)
    children = Dict{Int,Vector{Int}}()
    for entry in readdir("/proc")
        all(isdigit, entry) || continue
        stat = _proc_read(joinpath("/proc", entry, "stat"))
        stat === nothing && continue
        # A process name can hold spaces and parentheses, so the fields after it are read from
        # the last `)` rather than by splitting the whole line.
        closing = findlast(')', stat)
        closing === nothing && continue
        parent = tryparse(Int, split(strip(stat[(closing + 1):end]))[2])
        parent === nothing || push!(get!(children, parent, Int[]), parse(Int, entry))
    end

    found, queue = Int[], [Int(pid)]
    while !isempty(queue)
        for child in get(children, popfirst!(queue), Int[])
            push!(found, child)
            push!(queue, child)
        end
    end
    return found
end

"""
    page(browser) -> String

Open a blank page and return the session id that addresses it.

A page is created blank and navigated afterwards, so console output is captured from the first
line it runs rather than from whenever the harness caught up with it.
"""
function page(browser::Browser)
    target = command(browser, "Target.createTarget", Dict("url" => "about:blank"))["targetId"]
    session = command(browser, "Target.attachToTarget",
        Dict("targetId" => target, "flatten" => true))["sessionId"]

    lock(browser.lock) do
        browser.problems[session] = String[]
        browser.loads[session] = 0
    end
    for domain in ("Runtime", "Log", "Page")
        command(browser, "$domain.enable"; session)
    end
    return session
end

"""
    navigate(browser, session, url; before)

Send a page to `url` and return once it has loaded.

`before` is JavaScript evaluated in the fresh document before any of the page's own scripts run,
which is the only way to observe a card's first state: by the time the harness can evaluate
anything, the deck has already replaced its placeholders.
"""
function navigate(browser::Browser, session::AbstractString, url::AbstractString;
        before::Union{Nothing,AbstractString}=nothing)
    before === nothing || command(browser, "Page.addScriptToEvaluateOnNewDocument",
        Dict("source" => before); session)

    # A page that has not navigated yet is a complete `about:blank`, so waiting on `readyState`
    # alone reports the *previous* document as loaded and every assertion that follows runs
    # against an empty DOM — where `every` over no cards is vacuously true.
    loaded = _loads(browser, session)
    command(browser, "Page.navigate", Dict("url" => url); session)
    _await(() -> _loads(browser, session) > loaded, "$url to load"; timeout=NAVIGATION_TIMEOUT)
    return nothing
end

_loads(browser::Browser, session::AbstractString) =
    lock(browser.lock) do
        get(browser.loads, session, 0)
    end

"""
    evaluate(browser, session, expression) -> Any

Evaluate `expression` in the page and return its value, awaiting a promise if it is one.

Throws [`ProtocolError`](@ref) if the expression throws, so a broken assertion reads as a
failure rather than as a `nothing` that silently passes.
"""
function evaluate(browser::Browser, session::AbstractString, expression::AbstractString)
    return get(_evaluate_raw(browser, session, expression), "value", nothing)
end

"""
    await(browser, session, expression; what, timeout)

Poll `expression` in the page until it is truthy.

A deck is asynchronous from the browser's side in every direction — the websocket, the reactive
run, the scripts a card executes — so every assertion about it is eventually-true.
"""
function await(browser::Browser, session::AbstractString, expression::AbstractString;
        what::AbstractString=expression, timeout::Real=120)
    _await(() -> evaluate(browser, session, "!!($expression)") === true, what; timeout)
end

"""
The keys the harness can press: each `event.key` against the `event.code` and virtual key code
Chrome expects for it.

A `KeyboardEvent` built in `Runtime.evaluate` would prove only that a listener is attached to
something. `Input.dispatchKeyEvent` goes in where a keyboard goes, so what is under test is the
deck reacting to a key press — including whether the element holding focus swallowed it first.

`code` is the physical key and is not the name of the character it produces, which is why a
letter cannot be dispatched by repeating its `key`.
"""
const VIRTUAL_KEYS = Dict(
    "ArrowLeft" => ("ArrowLeft", 37), "ArrowUp" => ("ArrowUp", 38),
    "ArrowRight" => ("ArrowRight", 39), "ArrowDown" => ("ArrowDown", 40),
    "PageUp" => ("PageUp", 33), "PageDown" => ("PageDown", 34),
    "Home" => ("Home", 36), "End" => ("End", 35),
    "c" => ("KeyC", 67),
)

"""
    press(browser, session, key)

Press and release `key` in the page, wherever focus currently is.

`rawKeyDown` rather than `keyDown`: the latter also asks Chrome to insert text, which a
navigation key has none of.
"""
function press(browser::Browser, session::AbstractString, key::AbstractString)
    physical = get(VIRTUAL_KEYS, key, nothing)
    physical === nothing && error("press: no virtual key code for \"$key\"")
    code, virtual = physical

    for type in ("rawKeyDown", "keyUp")
        command(browser, "Input.dispatchKeyEvent", Dict(
            "type" => type,
            "key" => key,
            "code" => code,
            "windowsVirtualKeyCode" => virtual,
            "nativeVirtualKeyCode" => virtual,
        ); session)
    end
    return nothing
end

"""
    element(selector) -> String
    elements(selector) -> String

JavaScript resolving `selector`, crossing a shadow boundary wherever it reads `>>>`.

The deck chrome, the nav, the cue overlay and the speaker page are Lit components that render
into shadow roots, and `document.querySelector` does not cross one. A card is the deliberate
exception — its output stays in light DOM so that Pluto's renderer can resolve a payload
through `closest("pluto-cell")` — so a selector reaching a card carries no `>>>`, and one that
does names the component that owns the element.
"""
element(selector::AbstractString) = _resolve(selector, "querySelector")
elements(selector::AbstractString) = _resolve(selector, "querySelectorAll")

function _resolve(selector::AbstractString, final::AbstractString)
    steps = strip.(split(selector, ">>>"))
    js = "document"
    for (index, step) in enumerate(steps)
        last = index == length(steps)
        query = last ? final : "querySelector"
        js = index == 1 ? "$js.$query($(repr(String(step))))" :
                          "$js?.shadowRoot?.$query($(repr(String(step))))"
    end
    return js
end

"""
    click(browser, session, selector)

Click the element `selector` matches, with a real mouse press at its centre.

The element is scrolled into view first, because a click is dispatched at viewport coordinates
and the deck chrome sits below the fold on a short window.
"""
function click(browser::Browser, session::AbstractString, selector::AbstractString)
    centre = JSON.parse(evaluate(browser, session, """
        (() => {
          const element = $(element(selector))
          if (element === null) throw new Error("nothing matches $(selector)")
          element.scrollIntoView({ block: "center" })
          const box = element.getBoundingClientRect()
          return JSON.stringify({ x: box.x + box.width / 2, y: box.y + box.height / 2 })
        })()
        """))

    for type in ("mousePressed", "mouseReleased")
        command(browser, "Input.dispatchMouseEvent", Dict(
            "type" => type,
            "x" => centre["x"],
            "y" => centre["y"],
            "button" => "left",
            "buttons" => type == "mousePressed" ? 1 : 0,
            "clickCount" => 1,
        ); session)
    end
    return nothing
end

"""
    focus(browser, session, selector)

Put keyboard focus on the element `selector` matches.
"""
function focus(browser::Browser, session::AbstractString, selector::AbstractString)
    evaluate(browser, session, """$(element(selector)).focus()""")
    return nothing
end

"""
    problems(browser, session) -> Vector{String}

Every console error, uncaught exception and browser log error the page has produced.

A page that renders nothing and logs nothing is the failure mode this whole harness exists for,
so the absence of these is asserted rather than assumed.
"""
problems(browser::Browser, session::AbstractString) =
    lock(browser.lock) do
        copy(get(browser.problems, session, String[]))
    end

"""
    command(browser, method, params; session) -> Dict

Send one DevTools command and return its result.

`session` addresses a page; without it the command goes to the browser itself.
"""
function command(browser::Browser, method::AbstractString, params::AbstractDict=Dict{String,Any}();
        session::Union{Nothing,AbstractString}=nothing)
    reply = Channel{Any}(1)
    id = lock(browser.lock) do
        id = browser.last_id += 1
        browser.pending[id] = reply
        id
    end

    message = Dict{String,Any}("id" => id, "method" => method, "params" => params)
    session === nothing || (message["sessionId"] = session)
    HTTP.WebSockets.send(browser.websocket, JSON.json(message))

    if timedwait(() -> isready(reply), COMMAND_TIMEOUT) !== :ok
        lock(browser.lock) do
            delete!(browser.pending, id)
        end
        throw(ProtocolError(method, "no answer within $(COMMAND_TIMEOUT)s"))
    end

    answer = take!(reply)
    haskey(answer, "error") && throw(ProtocolError(method, answer["error"]["message"]))
    return answer["result"]
end

function _evaluate_raw(browser::Browser, session::AbstractString, expression::AbstractString)
    result = command(browser, "Runtime.evaluate", Dict(
        "expression" => expression,
        "awaitPromise" => true,
        "returnByValue" => true,
    ); session)
    haskey(result, "exceptionDetails") &&
        throw(ProtocolError("Runtime.evaluate", _describe(result["exceptionDetails"])))
    return result["result"]
end

function _read_loop(browser::Browser)
    try
        for raw in browser.websocket
            _dispatch!(browser, JSON.parse(String(raw)))
        end
    catch err
        err isa HTTP.WebSockets.WebSocketError || err isa EOFError || rethrow()
    end
    return nothing
end

function _dispatch!(browser::Browser, message::AbstractDict)
    if haskey(message, "id")
        reply = lock(browser.lock) do
            pop!(browser.pending, message["id"], nothing)
        end
        reply === nothing || put!(reply, message)
    else
        _record!(browser, message)
    end
    return nothing
end

"Track what a page loaded, keep what a person would call an error, and ignore the rest."
function _record!(browser::Browser, event::AbstractDict)
    session = get(event, "sessionId", nothing)
    session === nothing && return nothing
    params = get(event, "params", Dict{String,Any}())

    if event["method"] == "Page.loadEventFired"
        lock(browser.lock) do
            browser.loads[session] = get(browser.loads, session, 0) + 1
        end
        return nothing
    end

    problem = if event["method"] == "Runtime.exceptionThrown"
        _describe(params["exceptionDetails"])
    elseif event["method"] == "Runtime.consoleAPICalled" && params["type"] in ("error", "assert")
        "console." * params["type"] * ": " * join(_render.(params["args"]), " ")
    elseif event["method"] == "Log.entryAdded" && params["entry"]["level"] == "error"
        params["entry"]["source"] * ": " * params["entry"]["text"]
    else
        return nothing
    end

    lock(browser.lock) do
        push!(get!(Vector{String}, browser.problems, session), problem)
    end
    return nothing
end

_describe(details::AbstractDict) = something(
    get(get(details, "exception", Dict{String,Any}()), "description", nothing),
    get(details, "text", nothing),
    "unknown exception",
)

_render(argument::AbstractDict) =
    string(get(argument, "description", get(argument, "value", get(argument, "type", "?"))))

"The websocket Chrome writes into its profile once it is listening."
function _debugger_url(process::Base.Process, profile::AbstractString)
    port_file = joinpath(profile, "DevToolsActivePort")
    _await(() -> isfile(port_file) && count(==('\n'), read(port_file, String)) >= 1,
        "Chrome to publish its debugging port"; timeout=LAUNCH_TIMEOUT,
        alive=() -> Base.process_running(process))

    port, path = split(strip(read(port_file, String)), '\n')
    return "ws://127.0.0.1:$port$path"
end

function _await(condition, what::AbstractString; timeout::Real=COMMAND_TIMEOUT, alive=() -> true)
    deadline = time() + timeout
    while !condition()
        alive() || error("waiting for $what: the browser exited")
        time() > deadline && error("waiting for $what: still false after $(timeout)s")
        sleep(0.05)
    end
    return nothing
end
