import HTTP
import JSON
import PlutoPlotly

using PlutoDeck: Session, load_deck

"""
A `Session` with nothing running behind it.

Every route this file exercises reads the session as data, so a server and a kernel would
only buy thirty seconds of start-up per assertion. `test/session.jl` drives the same routes
against a real one.
"""
fake_session() = Session(
    Pluto.ServerSession(),
    Pluto.RunningPlutoServer(nothing, @task nothing),
    Pluto.Notebook([cell("x = 1")], THREE_CARDS),
    "http://localhost:1234",
    "s3cr3t42",
)

request(handler, target) = handler(HTTP.Request("GET", target))

@testset "server" begin
    # The head the `pluto` Slidev addon puts on every live deck.
    page = read(joinpath(SLIDES, "addons", "pluto", "index.html"), String)

    @testset "the addon's Plotly is the version a plot cell will ask for" begin
        # A plot cell reads `window.plutoplotly_imports[get_plotly_version()]` and falls
        # through to esm.sh for any other key — silently, so the deck works at a desk and every
        # plot on it is blank in a lecture room. A bumped PlutoPlotly has to move
        # `plotly.js-dist-min` in `slides/package.json` with it, and this is what says so.
        declared = match(r"rel=\"plotly-source\"[^>]*data-version=\"([^\"]+)\"", page)

        @test declared !== nothing
        @test declared[1] == string(PlutoPlotly.get_plotly_version())
    end

    @testset "every library a plot script imports by URL is one the deck serves" begin
        # PlutoPlotly's scripts import lodash and interact.js from a CDN by absolute URL, with a
        # top-level await, so a specifier the import map does not name is a plot card that draws
        # nothing in a room with no wifi. The browser suite covers it too, but only where Chrome
        # is installed and only after a cold kernel; this costs nothing and always runs.
        #
        # Read out of the installed PlutoPlotly rather than written down, so a release that
        # moves a URL fails here naming the one that drifted.
        imported = Set{String}()
        for (root, _, files) in walkdir(joinpath(pkgdir(PlutoPlotly), "src")), file in files
            text = read(joinpath(root, file), String)
            for matched in eachmatch(r"import\(\s*[\"'](https://[^\"']+)[\"']\s*\)", text)
                push!(imported, matched[1])
            end
        end

        declared = match(r"<script type=\"importmap\">(.*?)</script>"s, page)

        # A PlutoPlotly that stops importing by URL has to fail here rather than pass vacuously.
        @test !isempty(imported)
        @test declared !== nothing
        @test imported ⊆ keys(JSON.parse(declared[1])["imports"])
    end

    handler = PlutoDeck._handler(load_deck(LECTURE_DECK), fake_session())

    @testset "/api/session carries what the browser needs to reach Pluto" begin
        response = request(handler, "/api/session")
        body = JSON.parse(String(response.body))

        @test response.status == 200
        @test HTTP.header(response, "Content-Type") == "application/json; charset=utf-8"
        @test body["plutoUrl"] == "http://localhost:1234"
        @test body["secret"] == "s3cr3t42"
        @test occursin(body["notebook_id"], body["editUrl"])
        @test occursin(body["secret"], body["editUrl"])
    end

    @testset "/api/deck carries the deck's notebook and every card it declares" begin
        response = request(handler, "/api/deck")
        body = JSON.parse(String(response.body))

        @test response.status == 200
        @test body["notebook"] == THREE_CARDS
        @test body["cards"]["metrics"] == "a1000000-0000-4000-8000-000000000004"
        @test Set(keys(body)) == Set(["path", "notebook", "cards"])
    end

    @testset "any other path is a 404" begin
        @test request(handler, "/").status == 404
        @test request(handler, "/api/other").status == 404
    end
end
