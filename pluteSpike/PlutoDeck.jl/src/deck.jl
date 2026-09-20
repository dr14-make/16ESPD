"The keys a card placement may carry. `snapshot` names a cached rendering; the loader carries it without interpreting it."
const CARD_PLACEMENT_KEYS = ("card", "x", "y", "w", "h", "snapshot")
const SLIDE_KEYS = ("cards",)
const DECK_KEYS = ("notebook", "slides")

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
    Slide(cards)

One slide: the cards placed on it, in the order the deck file lists them.
"""
struct Slide
    cards::Vector{CardPlacement}
end

"""
    Deck(path, notebook_path, slides, cards)

A loaded deck. Every card name on every slide resolves to a cell of `notebook_path`; `cards`
carries that resolution for the whole notebook, including cards no slide places.
"""
struct Deck
    path::String
    notebook_path::String
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
    slides = _parse_slides(problems, raw)

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
    hints = _resolve_cards!(problems, slides, published, notebook_path)
    isempty(problems) || throw(DeckLoadError(deck_path, problems, hints))

    return Deck(deck_path, notebook_path, slides, published)
end

function _parse_slides(problems::Vector{String}, raw::Dict)
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

        placements = CardPlacement[]
        for (card_index, card_raw) in enumerate(cards_raw)
            placement = _parse_card(problems, card_raw, "$context, card $card_index")
            placement === nothing || push!(placements, placement)
        end
        push!(slides, Slide(placements))
    end
    return slides
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

"Report every card no cell publishes, and return the hints that help place them."
function _resolve_cards!(problems::Vector{String}, slides::Vector{Slide},
        published::Dict{String,UUID}, notebook_path::String)
    unresolved = false
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
