import JSON
import PlutoPlotly

@testset "addon" begin
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
        # nothing in a room with no wifi. The addon's live suite covers it too, but only after a
        # cold kernel; this costs nothing and always runs.
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
end
