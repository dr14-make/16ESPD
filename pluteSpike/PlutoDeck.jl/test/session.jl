import HTTP
import JSON
import Pluto

using PlutoDeck: SessionStartError, edit_url, in_temp_dir, load_deck, notebook_id, serve,
    shutdown!, start_session

"A notebook and a deck of its own, outside the repository, since Pluto rewrites what it opens."
function workspace_deck()
    workspace = mktempdir()
    cp(RUNNABLE, joinpath(workspace, "runnable.jl"))
    write(joinpath(workspace, "runnable.deck.json"), """
    {
      "notebook": "runnable.jl",
      "slides": [
        {
          "cards": [
            { "card": "frequency", "x": 0, "y": 0, "w": 4, "h": 2 },
            { "card": "samples", "x": 4, "y": 0, "w": 8, "h": 4 }
          ]
        },
        { "cards": [{ "card": "readout", "x": 0, "y": 0, "w": 12, "h": 2 }] }
      ]
    }
    """)
    return load_deck(joinpath(workspace, "runnable.deck.json"))
end

"""
    bond_round_trip(session, symbol, value, cell_id) -> Bool

Whether setting a bond re-runs the cell that reads it.

An HTTP 200 is not a health check — the spike twice served one over a dead kernel. The only
honest probe changes a bond and confirms a watched cell's `last_run_timestamp` advances.
"""
function bond_round_trip(session, symbol::Symbol, value, cell_id)
    watched = session.notebook.cells_dict[cell_id]
    before = watched.output.last_run_timestamp

    session.notebook.bonds[symbol] = Pluto.BondValue(value)
    Pluto.set_bond_values_reactive(;
        session=session.pluto, notebook=session.notebook,
        bound_sym_names=[symbol], run_async=false)

    return watched.output.last_run_timestamp > before
end

@testset "session" begin
    @testset "a notebook that is not there is refused before Pluto starts" begin
        @test_throws SessionStartError start_session(joinpath(FIXTURES, "nothing-here.jl"))
    end

    deck = workspace_deck()
    session = start_session(deck.notebook_path; io=nothing)
    workspace = Pluto.WorkspaceManager.get_workspace((session.pluto, session.notebook);
        allow_creation=false)
    server = nothing

    try
        @testset "the kernel reaches ready with every cell terminal" begin
            @test session.notebook.process_status == Pluto.ProcessStatus.ready
            @test all(cell -> !cell.queued && !cell.running, session.notebook.cells)
            @test !any(cell -> cell.errored, session.notebook.cells)
        end

        @testset "the notebook runs from the file the deck names" begin
            @test session.notebook.path == deck.notebook_path
            @test !in_temp_dir(session)
        end

        @testset "a bond change re-runs the cell that reads it" begin
            @test bond_round_trip(session, :freq, 4, deck.cards["samples"])
        end

        server = serve(deck, session; port=0, listenany=true)

        @testset "the deck serves its own pages on its own port" begin
            response = HTTP.get("$(server.url)/")

            @test response.status == 200
            @test occursin("PlutoDeck", String(response.body))
        end

        @testset "/api/session points the browser straight at Pluto" begin
            body = JSON.parse(String(HTTP.get("$(server.url)/api/session").body))

            @test body["plutoUrl"] == session.url
            @test body["notebook_id"] == string(notebook_id(session))
            @test body["editUrl"] == edit_url(session)
            @test HTTP.get(body["editUrl"]).status == 200
        end

        @testset "/api/deck carries the deck the session is running" begin
            body = JSON.parse(String(HTTP.get("$(server.url)/api/deck").body))

            @test body["notebook"] == deck.notebook_path
            @test length(body["slides"]) == 2
            @test keys(body["cards"]) == Set(["frequency", "samples", "readout"])
        end
    finally
        server === nothing || close(server)
        shutdown!(session)
    end

    @testset "shutting down leaves no worker behind" begin
        @test !Base.process_running(workspace.worker.proc)
        @test !isopen(session.server.http_server)
        @test isempty(session.pluto.notebooks)
    end
end
