module PlutoDeck

using UUIDs: UUID

import HTTP
import JSON
import MIMEs
import Pluto
import YAML

export present

include("cards.jl")
include("deck.jl")
include("session.jl")
include("server.jl")

"""
    present(deck_path; port, pluto_port, host)

Serve the live deck at `deck_path`, a Slidev deck naming its notebook in its headmatter: start
a Pluto session for that notebook, open it in place with execution allowed, and answer
`/api/session` and `/api/deck` for `slidev dev` to proxy. Blocks until interrupted, then
takes the kernel down with it.

The deck and Pluto are two ports of one Julia process. The browser talks to both: the deck
for its own pages, Pluto directly for the websocket that carries cell output and bonds.

A notebook that declares a bond named `deck_theme` is told which color scheme the deck is
being shown in, as `"light"` or `"dark"`, which is how a Julia-rendered plot follows the deck
into dark mode. See `DESIGN.md`.
"""
function present(deck_path::AbstractString;
        port::Integer=DECK_PORT_DEFAULT,
        pluto_port::Union{Nothing,Integer}=nothing,
        host::AbstractString=HOST_DEFAULT,
        io::Union{IO,Nothing}=stdout)
    deck = load_deck(deck_path)
    _report(io, "PlutoDeck · ", deck.path)
    _report(io, "  ", length(deck.cards), " cards · ", deck.notebook_path)

    session = start_session(deck.notebook_path; port=pluto_port, host, io)
    try
        server = serve(deck, session; port, host)
        try
            _report(io, "  deck    ", server.url)
            _report(io, "  editor  ", edit_url(session))
            _report(io, "Press Ctrl-C to stop.")
            _block_until_interrupted(server, io)
        finally
            close(server)
        end
    finally
        _report(io, "Stopping the kernel…")
        shutdown!(session)
    end
    return nothing
end

"Hold the main task so an interrupt lands here rather than inside the server's task."
function _block_until_interrupted(server::DeckServer, io::Union{IO,Nothing})
    try
        while isopen(server)
            sleep(0.1)
        end
    catch err
        err isa InterruptException || rethrow()
        _report(io)
    end
    return nothing
end

end # module
