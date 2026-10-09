# The deck's own HTTP server: /api/session and /api/deck.

const DECK_PORT_DEFAULT = 8099

"""
    DeckServer(http, url, deck, session)

The deck's HTTP server. It answers `/api/session` and `/api/deck`, which `slidev dev` proxies;
it never proxies Pluto, because the browser talks to Pluto directly on Pluto's own port.
"""
struct DeckServer
    http::HTTP.Server
    url::String
    deck::Deck
    session::Session
end

Base.close(server::DeckServer) = close(server.http)
Base.isopen(server::DeckServer) = isopen(server.http)

"""
    serve(deck, session; port, host, listenany) -> DeckServer

Serve `deck` against `session` on `port`, and return once the server is listening.

Loopback only, and unauthenticated: the one secret in play is Pluto's, and it is handed to
the browser by `/api/session` so the browser can open its own websocket to Pluto.

`port` is taken as given, so a port already in use is an error rather than a deck quietly
served somewhere else; `listenany` takes the first free port from `port` instead.
"""
function serve(deck::Deck, session::Session;
        port::Integer=DECK_PORT_DEFAULT,
        host::AbstractString=HOST_DEFAULT,
        listenany::Bool=false)
    http = HTTP.serve!(_handler(deck, session), host, port; listenany, verbose=-1)
    return DeckServer(http, _origin(host, HTTP.Servers.port(http)), deck, session)
end

function _handler(deck::Deck, session::Session)
    return function (request::HTTP.Request)
        path = HTTP.URI(request.target).path
        path == "/api/session" && return _json_response(_session_json(session))
        path == "/api/deck" && return _json_response(_deck_json(deck))
        return HTTP.Response(404, ["Content-Type" => "text/plain; charset=utf-8"], "not found")
    end
end

"What the browser needs to reach Pluto: the deck does not proxy it, so it connects there itself."
_session_json(session::Session) = Dict{String,Any}(
    "plutoUrl" => session.url,
    "secret" => session.secret,
    "notebook_id" => string(notebook_id(session)),
    "editUrl" => edit_url(session),
)

"""
The deck's notebook, with every card it declares resolved to the cell that publishes it.

`cards` covers the whole notebook rather than only the placed cards, so a live card can tell a
card that is missing from this deck from one that no cell declares.
"""
_deck_json(deck::Deck) = Dict{String,Any}(
    "path" => deck.path,
    "notebook" => deck.notebook_path,
    "cards" => Dict(name => string(cell_id) for (name, cell_id) in deck.cards),
)

_json_response(body) = HTTP.Response(200,
    ["Content-Type" => "application/json; charset=utf-8", "Cache-Control" => "no-store"],
    JSON.json(body))

