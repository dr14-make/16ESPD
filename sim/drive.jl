# Optional UI packages live in sim/, never in the library's required dependencies.
# Include in a warm REPL and call main(spec) repeatedly; inclusion opens no devices/windows.
(@__DIR__) in LOAD_PATH || push!(LOAD_PATH, @__DIR__)
using VehicleSystemsComponents
using DyadInterface: run_analysis
using GLMakie
using SimpleDirectMediaLayer

"Run a supplied drive specification, or open the lecture drive with optional overrides."
main(spec) = run_analysis(spec)
main(; kwargs...) = VehicleSystemsComponents.PlanarBEVByHandDrive(; kwargs...)

abspath(PROGRAM_FILE) == (@__FILE__) && main()
