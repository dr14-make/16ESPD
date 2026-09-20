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
    with_browser(body) -> Any

Run `body(browser)` against a freshly launched headless Chrome, and take the browser down
afterwards however `body` ends.

A leaked headless instance is not a tidiness problem here: `earlyoom` on this machine prefers
these processes, and accumulated browsers are what got a Pluto kernel killed twice.
"""
function with_browser(body)
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
