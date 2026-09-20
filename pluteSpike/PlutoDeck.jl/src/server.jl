# The deck's own HTTP server: static frontend, /api/session and /api/deck.

const PACKAGE_ROOT = normpath(joinpath(@__DIR__, ".."))

"Set to `\"ja\"` to serve the built bundle from a development checkout. Mirrors `JULIA_PLUTO_FORCE_BUNDLED`."
const FORCE_BUNDLED_ENV = "JULIA_PLUTODECK_FORCE_BUNDLED"

const DECK_PORT_DEFAULT = 8099

"A bundled asset carries a content hash in its name, so it can be cached for as long as it exists."
const CONTENT_HASHED = r"\.[0-9a-f]{8}\."

const DAY_IN_SECONDS = 24 * 60 * 60

"""
    frontend_directory(root=PACKAGE_ROOT; allow_bundled=true) -> String

The directory the deck is served from: `frontend-dist/` when a bundle is there,
`frontend/` otherwise.

A development checkout serves its TypeScript source, so editing the frontend is a rebuild
and a refresh rather than a release. An installed package has no source to serve and takes
the bundle. Set `$FORCE_BUNDLED_ENV=ja` to serve the bundle from a checkout anyway.
"""
function frontend_directory(root::AbstractString=PACKAGE_ROOT; allow_bundled::Bool=true)
    bundle = joinpath(root, "frontend-dist")
    prefer_bundle = get(ENV, FORCE_BUNDLED_ENV, "nein") == "ja" || !_is_development_checkout(root)
    return allow_bundled && prefer_bundle && _holds_a_bundle(bundle) ? bundle :
        joinpath(root, "frontend")
end

"An empty `frontend-dist/` is a leftover directory, not a bundle."
_holds_a_bundle(bundle::AbstractString) = isdir(bundle) && !isempty(readdir(bundle))

_is_development_checkout(root::AbstractString) =
    !any(depot -> startswith(root, joinpath(depot, "packages")), DEPOT_PATH)

"""
    DeckServer(http, url, root, deck, session)

The deck's HTTP server. It serves `root`, the deck and the session; it never proxies Pluto,
because the browser talks to Pluto directly on Pluto's own port.
"""
struct DeckServer
    http::HTTP.Server
    url::String
    root::String
    deck::Deck
    session::Session
end

Base.close(server::DeckServer) = close(server.http)
Base.isopen(server::DeckServer) = isopen(server.http)

"""
    serve(deck, session; port, host, allow_bundled, listenany) -> DeckServer

Serve `deck` against `session` on `port`, and return once the server is listening.

Loopback only, and unauthenticated: the one secret in play is Pluto's, and it is handed to
the browser by `/api/session` so the browser can open its own websocket to Pluto.

`port` is taken as given, so a port already in use is an error rather than a deck quietly
served somewhere else; `listenany` takes the first free port from `port` instead.
"""
function serve(deck::Deck, session::Session;
        port::Integer=DECK_PORT_DEFAULT,
        host::AbstractString=HOST_DEFAULT,
        allow_bundled::Bool=true,
        listenany::Bool=false)
    root = frontend_directory(; allow_bundled)
    isdir(root) || throw(ArgumentError("the frontend directory is missing: $root"))

    http = HTTP.serve!(_handler(root, deck, session), host, port; listenany, verbose=-1)
    return DeckServer(http, _origin(host, HTTP.Servers.port(http)), root, deck, session)
end

function _handler(root::AbstractString, deck::Deck, session::Session)
    bundled = basename(root) == "frontend-dist"
    return function (request::HTTP.Request)
        try
            _respond(request, root, bundled, deck, session)
        catch err
            err isa InterruptException && rethrow()
            # Only a genuinely absent file is a 404. Answering 404 for anything else hides a
            # bug in here behind a page that merely looks unserved.
            @error "PlutoDeck failed serving $(request.target)" exception = (err, catch_backtrace())
            return _text_response(500, "server error: " * sprint(showerror, err))
        end
    end
end

function _respond(request::HTTP.Request, root::AbstractString, bundled::Bool,
        deck::Deck, session::Session)
    path = HTTP.URI(request.target).path
    path == "/api/session" && return _json_response(_session_json(session))
    path == "/api/deck" && return _json_response(_deck_json(deck))
    return _asset_response(root, bundled, path)
end

"What the browser needs to reach Pluto: the deck does not proxy it, so it connects there itself."
_session_json(session::Session) = Dict{String,Any}(
    "plutoUrl" => session.url,
    "secret" => session.secret,
    "notebook_id" => string(notebook_id(session)),
    "editUrl" => edit_url(session),
)

"""
The validated deck, with every card resolved to the cell that publishes it.

`cards` covers the whole notebook rather than only the placed cards, so a frontend can tell a
card that is missing from this deck from one that no cell declares.
"""
_deck_json(deck::Deck) = Dict{String,Any}(
    "path" => deck.path,
    "notebook" => deck.notebook_path,
    "preamble" => deck.preamble,
    "slides" => [Dict{String,Any}("cards" => _card_json.(slide.cards)) for slide in deck.slides],
    "cards" => Dict(name => string(cell_id) for (name, cell_id) in deck.cards),
)

_card_json(placement::CardPlacement) = Dict{String,Any}(
    "card" => placement.name,
    "x" => placement.x,
    "y" => placement.y,
    "w" => placement.w,
    "h" => placement.h,
    "snapshot" => placement.snapshot,
)

function _asset_response(root::AbstractString, bundled::Bool, path::AbstractString)
    file = _resolve_asset(root, path)
    file === nothing && return _text_response(403, "forbidden")
    isfile(file) || return _text_response(404, "not found")

    body = read(file)
    headers = ["Content-Type" => _content_type(file), "Content-Length" => string(length(body))]
    push!(headers, "Cache-Control" => bundled && occursin(CONTENT_HASHED, basename(file)) ?
        "public, max-age=$(30 * DAY_IN_SECONDS), immutable" : "no-store")
    return HTTP.Response(200, headers, body)
end

"The file `path` names inside `root`, or `nothing` if it escapes `root`."
function _resolve_asset(root::AbstractString, path::AbstractString)
    relative = lstrip(HTTP.unescapeuri(path), '/')
    file = normpath(joinpath(root, isempty(relative) ? "index.html" : relative))
    return startswith(file, rstrip(root, '/') * "/") ? file : nothing
end

_content_type(file::AbstractString) = MIMEs.contenttype_from_mime(
    MIMEs.mime_from_path(file, MIME"application/octet-stream"()))

_json_response(body) = HTTP.Response(200,
    ["Content-Type" => "application/json; charset=utf-8", "Cache-Control" => "no-store"],
    JSON.json(body))

_text_response(status::Integer, body::AbstractString) =
    HTTP.Response(status, ["Content-Type" => "text/plain; charset=utf-8"], body)
