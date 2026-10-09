module PlutoDeck

import HTTP
import JSON
import Pluto
import YAML

export present

include("session.jl")
include("deck.jl")

"""
    present(deck_path; pluto_port, host, io)

Run the live deck at `deck_path`, a Slidev deck naming its notebook in its headmatter: start a
Pluto server, open that notebook in place with execution allowed, and wait until every cell has
run. Then write Pluto's URL and secret to the deck's session file, which `slidev dev` hands the
page, and block until interrupted, taking the kernel and the session file down with it.

The browser talks to Pluto directly, over Pluto's own websocket, and finds the notebook among
the ones Pluto is running by its path.

A notebook that declares a bond named `deck_theme` is told which color scheme the deck is
being shown in, as `"light"` or `"dark"`, which is how a Julia-rendered plot follows the deck
into dark mode.
"""
function present(deck_path::AbstractString;
        pluto_port::Union{Nothing,Integer}=nothing,
        host::AbstractString=HOST_DEFAULT,
        io::Union{IO,Nothing}=stdout)
    deck = load_deck(deck_path)
    _report(io, "PlutoDeck · ", deck.path)
    _report(io, "  notebook ", deck.notebook_path)

    session = start_session(deck.notebook_path; port=pluto_port, host, io)
    try
        file = write_session_file(deck, session)
        try
            _report(io, "  editor   ", edit_url(session))
            _report(io, "  session  ", file)
            _report(io, "Press Ctrl-C to stop.")
            _block_until_interrupted(session, io)
        finally
            rm(file; force=true)
        end
    finally
        _report(io, "Stopping the kernel…")
        shutdown!(session)
    end
    return nothing
end

"Hold the main task so an interrupt lands here rather than inside Pluto's server task."
function _block_until_interrupted(session::Session, io::Union{IO,Nothing})
    try
        while isopen(session.server.http_server)
            sleep(0.1)
        end
    catch err
        err isa InterruptException || rethrow()
        _report(io)
    end
    return nothing
end

end # module
