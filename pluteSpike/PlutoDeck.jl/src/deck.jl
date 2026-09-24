"""
The number of columns a slide's grid offers.

The frontend lays a slide out as `repeat(12, 1fr)`, so a card reaching past column 12 lands in
an implicit column that no other card shares and the slide's proportions silently change.
"""
const GRID_COLUMNS = 12

"The keys a card placement may carry. `snapshot` names a cached rendering; the loader carries it without interpreting it."
const CARD_PLACEMENT_KEYS = ("card", "x", "y", "w", "h", "snapshot")
const SLIDE_KEYS = ("title", "notes", "cards")
const DECK_KEYS = ("notebook", "preamble", "slides")

"""
    CardPlacement(name, x, y, w, h, snapshot)

One card on one slide, with its gridstack geometry in grid units.
"""
struct CardPlacement
    name::String
    x::Int
    y::Int
    w::Int
    h::Int
    snapshot::Union{Nothing,String}
end

"""
    Slide(title, notes, cards)

One slide: the cards placed on it, in the order the deck file lists them.

`title` is the deck's own heading for the slide, or `nothing` to leave it numbered. It lives
here rather than in the notebook because one notebook backs several decks — the full lecture,
a revision deck, a student-facing cut — and each titles the same cards for its own audience.

`notes` is the resolved path of the slide's speaker cues, or `nothing`. The path is held, never
the text: a cue rewritten five minutes before a lecture has to cost a browser refresh rather
than a kernel restart, so the file is read when `/api/deck` is asked.
"""
struct Slide
    title::Union{Nothing,String}
    notes::Union{Nothing,String}
    cards::Vector{CardPlacement}
end

"""
    Deck(path, notebook_path, preamble, slides, cards)

A loaded deck. Every card name in `preamble` and on every slide resolves to a cell of
`notebook_path`; `cards` carries that resolution for the whole notebook, including cards the
deck does not use.

`preamble` names cards that are rendered before any slide and never shown. A cell whose output
is a side-effecting script has to have run before a card that depends on it renders, and
belongs on no slide.
"""
struct Deck
    path::String
    notebook_path::String
    preamble::Vector{String}
    slides::Vector{Slide}
    cards::Dict{String,UUID}
end

"""
    DeckLoadError(path, problems, hints)

A deck file cannot be loaded. `problems` lists every fault found, each naming what a human has
to fix and where; `hints` carries context that helps fix them but is not itself a fault.
"""
struct DeckLoadError <: Exception
    path::String
    problems::Vector{String}
    hints::Vector{String}
end

DeckLoadError(path::AbstractString, problems::Vector{String}) =
    DeckLoadError(path, problems, String[])

function Base.showerror(io::IO, err::DeckLoadError)
    println(io, "DeckLoadError: ", err.path, " cannot be loaded.")
    for problem in err.problems
        println(io, "  ", problem)
    end
    for hint in err.hints
        println(io, hint)
    end
    print(io, length(err.problems), " problem", length(err.problems) == 1 ? "" : "s", " found.")
end

"""
    load_deck(path) -> Deck

Load and validate a deck file, resolving every card name against the notebook it names.

Every fault is collected before anything is thrown, so one load reports everything that is
wrong with a hand-authored file rather than one fault per attempt.
"""
function load_deck(path::AbstractString)::Deck
    deck_path = abspath(String(path))
    isfile(deck_path) || throw(DeckLoadError(deck_path, ["no such file"]))

    raw = try
        JSON.parsefile(deck_path)
    catch err
        err isa InterruptException && rethrow()
        throw(DeckLoadError(deck_path, ["the file is not valid JSON: " * sprint(showerror, err)]))
    end
    raw isa Dict || throw(DeckLoadError(deck_path,
        ["the deck must be a JSON object carrying \"notebook\" and \"slides\""]))

    problems = String[]
    _reject_unknown_keys!(problems, raw, DECK_KEYS, "the deck")

    notebook_ref = _string_field(problems, raw, "notebook", "the deck")
    preamble = _parse_preamble(problems, raw)
    slides = _parse_slides(problems, raw, dirname(deck_path))
    _reject_unplaceable!(problems, slides)

    notebook_path = if notebook_ref === nothing
        nothing
    else
        resolved = isabspath(notebook_ref) ? notebook_ref :
            normpath(joinpath(dirname(deck_path), notebook_ref))
        isfile(resolved) || push!(problems, "\"notebook\": no such file: $resolved")
        resolved
    end

    # Card names cannot be resolved without the notebook, and reporting every placement as
    # unresolved when the notebook path is simply wrong buries the one fault that matters.
    (isempty(problems) && notebook_path !== nothing) || throw(DeckLoadError(deck_path, problems))

    published = cards(notebook_path)
    hints = _resolve_cards!(problems, preamble, slides, published, notebook_path)
    isempty(problems) || throw(DeckLoadError(deck_path, problems, hints))

    return Deck(deck_path, notebook_path, preamble, slides, published)
end

function _parse_preamble(problems::Vector{String}, raw::Dict)
    preamble_raw = get(raw, "preamble", nothing)
    preamble_raw === nothing && return String[]
    if !(preamble_raw isa Vector)
        push!(problems, "the deck: \"preamble\" must be an array of card names, got $(_json_repr(preamble_raw))")
        return String[]
    end

    names = String[]
    for (index, name) in enumerate(preamble_raw)
        if !(name isa AbstractString) || isempty(strip(name))
            push!(problems, "preamble $index: must be a non-empty card name, got $(_json_repr(name))")
            continue
        end
        push!(names, String(name))
    end
    return names
end

function _parse_slides(problems::Vector{String}, raw::Dict, deck_directory::AbstractString)
    slides_raw = get(raw, "slides", nothing)
    if slides_raw === nothing
        push!(problems, "the deck: missing key \"slides\"")
        return Slide[]
    elseif !(slides_raw isa Vector)
        push!(problems, "the deck: \"slides\" must be an array of slides, got $(_json_repr(slides_raw))")
        return Slide[]
    end

    slides = Slide[]
    for (index, slide_raw) in enumerate(slides_raw)
        context = "slide $index"
        if !(slide_raw isa Dict)
            push!(problems, "$context: must be a JSON object carrying \"cards\", got $(_json_repr(slide_raw))")
            continue
        end
        _reject_unknown_keys!(problems, slide_raw, SLIDE_KEYS, context)

        cards_raw = get(slide_raw, "cards", nothing)
        if cards_raw === nothing
            push!(problems, "$context: missing key \"cards\"")
            continue
        elseif !(cards_raw isa Vector)
            push!(problems, "$context: \"cards\" must be an array of card placements, got $(_json_repr(cards_raw))")
            continue
        end

        title = if haskey(slide_raw, "title") && slide_raw["title"] !== nothing
            _string_field(problems, slide_raw, "title", context)
        else
            nothing
        end
        notes = _parse_notes(problems, slide_raw, deck_directory, context)

        placements = CardPlacement[]
        for (card_index, card_raw) in enumerate(cards_raw)
            placement = _parse_card(problems, card_raw, "$context, card $card_index")
            placement === nothing || push!(placements, placement)
        end
        push!(slides, Slide(title, notes, placements))
    end
    return slides
end

"""
Resolve a slide's speaker cues against the deck file, and report a file that is not there.

Checked here and never again: a deck that names cues it cannot find must fail at load rather
than start and show an empty panel in front of a room.
"""
function _parse_notes(problems::Vector{String}, slide_raw::Dict, deck_directory::AbstractString,
        context::String)
    (haskey(slide_raw, "notes") && slide_raw["notes"] !== nothing) || return nothing

    reference = _string_field(problems, slide_raw, "notes", context)
    reference === nothing && return nothing

    resolved = isabspath(reference) ? reference :
        normpath(joinpath(deck_directory, reference))
    isfile(resolved) || push!(problems, "$context: \"notes\": no such file: $resolved")
    return resolved
end

function _parse_card(problems::Vector{String}, raw, context::String)
    if !(raw isa Dict)
        push!(problems, "$context: must be a JSON object carrying \"card\", \"x\", \"y\", \"w\" and \"h\", got $(_json_repr(raw))")
        return nothing
    end
    _reject_unknown_keys!(problems, raw, CARD_PLACEMENT_KEYS, context)

    name = _string_field(problems, raw, "card", context)
    # Naming the card in the context makes a geometry fault findable in the file; a placement
    # that has not even named its card is located by its index alone.
    geometry_context = name === nothing ? context : "$context (\"$name\")"
    x = _grid_field(problems, raw, "x", 0, geometry_context)
    y = _grid_field(problems, raw, "y", 0, geometry_context)
    w = _grid_field(problems, raw, "w", 1, geometry_context)
    h = _grid_field(problems, raw, "h", 1, geometry_context)

    snapshot = if haskey(raw, "snapshot") && raw["snapshot"] !== nothing
        _string_field(problems, raw, "snapshot", context)
    else
        nothing
    end

    any(isnothing, (name, x, y, w, h)) && return nothing
    return CardPlacement(name, x, y, w, h, snapshot)
end

"""
Report every card that cannot be laid out where the deck puts it.

A hand-authored deck is the only kind this version has, and both faults below render as a
plausible slide rather than as an error: overlapping cards stack in the same grid area, and a
card reaching past the last column adds one no other card occupies.
"""
function _reject_unplaceable!(problems::Vector{String}, slides::Vector{Slide})
    for (index, slide) in enumerate(slides)
        for placement in slide.cards
            placement.x + placement.w <= GRID_COLUMNS && continue
            push!(problems, "slide $index: \"$(placement.name)\" reaches column " *
                "$(placement.x + placement.w) of a $GRID_COLUMNS-column grid; " *
                "\"x\" plus \"w\" may not exceed $GRID_COLUMNS")
        end
        for (i, a) in enumerate(slide.cards), b in slide.cards[(i + 1):end]
            _overlaps(a, b) || continue
            push!(problems, "slide $index: \"$(a.name)\" ($(_extent(a))) overlaps " *
                "\"$(b.name)\" ($(_extent(b)))")
        end
    end
    return nothing
end

_overlaps(a::CardPlacement, b::CardPlacement) =
    a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h

_extent(p::CardPlacement) =
    "columns $(p.x)-$(p.x + p.w - 1), rows $(p.y)-$(p.y + p.h - 1)"

"Report every card no cell publishes, and return the hints that help place them."
function _resolve_cards!(problems::Vector{String}, preamble::Vector{String},
        slides::Vector{Slide}, published::Dict{String,UUID}, notebook_path::String)
    unresolved = false
    for (index, name) in enumerate(preamble)
        haskey(published, name) && continue
        unresolved = true
        push!(problems, "preamble $index: no cell of $notebook_path declares card = \"$name\"")
    end
    for (index, slide) in enumerate(slides), placement in slide.cards
        haskey(published, placement.name) && continue
        unresolved = true
        push!(problems, "slide $index: no cell of $notebook_path declares card = \"$(placement.name)\"")
    end
    unresolved || return String[]

    return [isempty(published) ?
        "That notebook publishes no cards at all: a cell publishes itself by carrying card = \"some-name\" in its own metadata." :
        "That notebook publishes: " * join(("\"$name\"" for name in sort!(collect(keys(published)))), ", ") * "."]
end

function _reject_unknown_keys!(problems::Vector{String}, object::Dict, known::Tuple, context::String)
    for key in sort!(collect(keys(object)))
        key in known && continue
        push!(problems, "$context: unknown key \"$key\"; expected " *
            join(("\"$k\"" for k in known), ", "))
    end
    return nothing
end

function _string_field(problems::Vector{String}, object::Dict, key::String, context::String)
    haskey(object, key) || (push!(problems, "$context: missing key \"$key\""); return nothing)
    value = object[key]
    if !(value isa AbstractString) || isempty(strip(value))
        push!(problems, "$context: \"$key\" must be a non-empty string, got $(_json_repr(value))")
        return nothing
    end
    return String(value)
end

function _grid_field(problems::Vector{String}, object::Dict, key::String, least::Int, context::String)
    haskey(object, key) || (push!(problems, "$context: missing key \"$key\""); return nothing)
    value = object[key]
    if !(value isa Integer) || value isa Bool
        push!(problems, "$context: \"$key\" must be a whole number of grid units >= $least, got $(_json_repr(value))")
        return nothing
    elseif value < least
        push!(problems, "$context: \"$key\" must be >= $least, got $value")
        return nothing
    end
    return Int(value)
end

_json_repr(value::AbstractString) = repr(String(value))
_json_repr(::Nothing) = "null"
_json_repr(value::Bool) = string(value)
_json_repr(value::Vector) = "an array of $(length(value))"
_json_repr(value::Dict) = "an object"
_json_repr(value) = string(value)
