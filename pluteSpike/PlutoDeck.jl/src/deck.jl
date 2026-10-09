"""
    Deck(path, notebook_path)

A live deck: a Slidev deck whose headmatter names the notebook it runs against, as
`pluto.notebook`, relative to the deck file.
"""
struct Deck
    path::String
    notebook_path::String
end

"A deck that names no notebook PlutoDeck can open."
struct DeckLoadError <: Exception
    path::String
    problem::String
end

Base.showerror(io::IO, err::DeckLoadError) =
    print(io, "DeckLoadError: ", err.path, ": ", err.problem)

"""
    load_deck(path) -> Deck

Read the notebook a Slidev deck names in its headmatter.

The notebook's path is resolved through symlinks, as the addon's dev server resolves the one it
hands the page: the page finds its notebook among the ones Pluto runs by comparing the two.
"""
function load_deck(path::AbstractString)::Deck
    deck_path = abspath(String(path))
    isfile(deck_path) || throw(DeckLoadError(deck_path, "no such file"))

    headmatter = match(r"\A---\r?\n(.*?)\r?\n---\r?$"ms, read(deck_path, String))
    parsed = headmatter === nothing ? nothing : YAML.load(headmatter[1])
    pluto = parsed isa AbstractDict ? get(parsed, "pluto", nothing) : nothing
    reference = pluto isa AbstractDict ? get(pluto, "notebook", nothing) : nothing
    reference isa AbstractString || throw(DeckLoadError(deck_path,
        "the headmatter names no notebook; a live deck carries pluto: { notebook: path/to/notebook.jl }"))

    notebook_path = normpath(joinpath(dirname(deck_path), reference))
    isfile(notebook_path) || throw(DeckLoadError(deck_path, "pluto.notebook: no such file: $notebook_path"))
    return Deck(deck_path, realpath(notebook_path))
end

"The file beside `deck` that the addon's dev server reads Pluto's URL and secret from."
session_file(deck::Deck) = joinpath(dirname(deck.path), ".pluto-session.json")

"""
    write_session_file(deck, session) -> String

Tell the deck's dev server where `session`'s Pluto is, and return the file that says so.

Readable by its owner alone, since the secret lets whoever holds it run Julia on this machine.
Written whole and then moved into place, because the dev server reloads the page on the first
sign of the file and would otherwise read it half-written.
"""
function write_session_file(deck::Deck, session::Session)
    file = session_file(deck)
    partial = file * ".partial"
    touch(partial)
    chmod(partial, 0o600)
    write(partial, JSON.json(Dict("plutoUrl" => session.url, "secret" => session.secret)))
    mv(partial, file; force=true)
    return file
end
