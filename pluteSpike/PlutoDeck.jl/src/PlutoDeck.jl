module PlutoDeck

using UUIDs: UUID

import HTTP
import JSON
import Pluto

export present

"""
    present(deck_path)

Serve the deck described by `deck_path`: start a Pluto session for its notebook, open that
notebook in place with execution allowed, and serve the deck frontend against it.
"""
function present end

include("cards.jl")
include("deck.jl")
include("session.jl")
include("server.jl")

end # module
