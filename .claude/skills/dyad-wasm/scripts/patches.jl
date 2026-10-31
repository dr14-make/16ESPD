# Workarounds DyadWasm.build_component needs on dyad-lang #2621's env v3.4 (d62a79d); each is
# explained, with its error, in ../reference/blockers.md. Include after `using DyadWasm`.
import WasmCodegen
# With `ODEProblem{true, FullSpecialize}` (as build_component builds it), MTK's initialization
# returns MTKParameters whose discrete buffer is blocked by an `SVector` axis and whose constant
# buffer is a `Vector{Bool}`, while the integrator's p holds `Vector{Int}` blocks and a `BitVector`:
# `integrator.p = p` in OrdinaryDiffEqCore's `_initialize_dae!` then fails to convert. This converts
# buffer by buffer. It runs only at build time: a clocked unit starts from the baked state.
using ModelingToolkit: MTKParameters
_conv(::Type{T}, x::T) where {T} = x
_conv(::Type{T}, x::Tuple) where {T <: Tuple} = ntuple(i -> _conv(fieldtype(T, i), x[i]), length(x))
_conv(::Type{BitVector}, x::AbstractVector{Bool}) = BitVector(x)
function _conv(::Type{T}, x::AbstractVector) where {T <: AbstractVector}
    nameof(T) === :BlockedArray || return convert(T, x)
    Ax = fieldtype(fieldtype(T, :axes), 1)
    T(Vector{Float64}(x.blocks), (Ax.name.wrapper(Vector{Int}(x.axes[1].lasts)),))
end
_conv(::Type{T}, x) where {T} = convert(T, x)
function Base.convert(::Type{MTKParameters{T, I, D, C, N, H}}, p::MTKParameters) where {T, I, D, C, N, H}
    MTKParameters{T, I, D, C, N, H}(_conv(T, p.tunable), _conv(I, p.initials), _conv(D, p.discrete),
                                    _conv(C, p.constant), _conv(N, p.nonnumeric), _conv(H, p.caches))
end

# WasmCodegen records each statement it cannot compile with its type printed in full, which for
# the integrator's types runs to megabytes per record; this records it with `:limit` and logs it.
@eval WasmCodegen function emit_stmt_or_trap!(fc::FnCtx, @nospecialize(stmt), @nospecialize(typ))
    mark = length(fc.b.func.body)
    stack = copy(fc.b.stack); frames = copy(fc.b.frames); inits = copy(fc.b.inits); depth = fc.depth
    try
        return emit_stmt!(fc, stmt, typ)
    catch err
        err isa Unsupported || rethrow()
        resize!(fc.b.func.body, mark)
        fc.b.stack = stack; fc.b.frames = frames; fc.b.inits = inits; fc.depth = depth
        lim(x) = (s = sprint(show, x; context = :limit => true); length(s) > 400 ? s[1:400] * "…" : s)
        push!(err.context, string("the statement ", lim(stmt), "::", lim(typ)))
        push!(err.context, fc.info.mi)
        push!(fc.cgm.diagnostics, fc.info.mi => err)
        println(stderr, "UNSUPPORTED: ", lim(join(string.(err.parts))), "\n    stmt: ", lim(stmt), "\n    in: ", lim(fc.info.mi))
        unreachable!(fc.b)
        return bottom()
    end
end


# MTK builds the initialization of a square system as an SCCNonlinearProblem (here of
# LinearProblems); DyadWasm's `cut_initdata` reads `initializeprob.u0`, which that type lacks
# (FieldError). As a plain NonlinearProblem (MTK's `use_scc = false`, which build_component does
# not pass), it is what `cut_initdata` handles. Only units without callbacks initialize in the
# module, and only they need this (WASM_PLAIN_INIT=1): for this model a plain NonlinearProblem
# initialization fails natively in NonlinearSolve's trust region (`restructure(::Vector, ::Nothing)`).
get(ENV, "WASM_PLAIN_INIT", "0") == "1" && @eval ModelingToolkit function MTKBase.get_initialization_problem_type(sys::System, isys::System;
                                                                     warn_initialize_determined = true, use_scc = true, kwargs...)
    neqs = length(equations(isys))
    nunknown = length(unknowns(isys))
    neqs == nunknown ? MTKBase.get_nonlinear_problem_type(isys) : NonlinearLeastSquaresProblem
end

# Inlined linear SCCs are solved in the generated RHS by `numeric_ldiv!`, which keeps a LinearSolve
# cache in `task_local_storage()` (type-unstable by design: "a dynamic call of getproperty with
# argument types (Any, Symbol)" in `solve_into!`). This solves them by Gaussian elimination with
# partial pivoting instead, generic in the element type (ForwardDiff duals in the Jacobian).
# Not inlining them (`inline_linear_sccs = false`) leaves algebraic equations that are 0/0 at
# standstill: the DAE's algebraic residual is NaN at the initialized state.
const MTKTearing = parentmodule(ModelingToolkit.StructuralTransformations.DefaultReassembleAlgorithm)
@assert isdefined(MTKTearing, :numeric_ldiv!)
function MTKTearing.numeric_ldiv!(A::AbstractMatrix, b::AbstractVector)
    F = copy(A)
    n = length(b)
    @inbounds for k in 1:n
        p = k
        for i in (k + 1):n
            abs(F[i, k]) > abs(F[p, k]) && (p = i)
        end
        if p != k
            for j in 1:n
                F[k, j], F[p, j] = F[p, j], F[k, j]
            end
            b[k], b[p] = b[p], b[k]
        end
        for i in (k + 1):n
            l = F[i, k] / F[k, k]
            for j in (k + 1):n
                F[i, j] -= l * F[k, j]
            end
            b[i] -= l * b[k]
        end
    end
    @inbounds for k in n:-1:1
        s = b[k]
        for j in (k + 1):n
            s -= F[k, j] * b[j]
        end
        b[k] = s / F[k, k]
    end
    return b
end

# build_component exposes every tunable parameter that is not an input as an FMI parameter, through
# a tuple of SII getter/setter pairs that `_get`/`_setp` walk recursively with `Base.tail`. This
# model has thousands of scalar tunables (the multibody geometry, and MTK's `Initial(x)` ones), so
# inference of `do_step`/`get_float64` exceeds its frame limit and WasmCodegen rejects the
# long-tuple `Base.tail` ("splatting into a call of argtail"). Only DyadWasm calls the
# one-argument `tunable_parameters`; with `KEEP_TUNABLE` set it returns just those parameters, so
# the unit exposes nothing beyond its inputs. (MTK's `subset_tunables` would shrink the buffer
# instead, but SynchToolkit's clock runtime is generated against the full one.)
const KEEP_TUNABLE = Ref{Union{Nothing, Vector{String}}}(nothing)
function ModelingToolkit.tunable_parameters(sys::ModelingToolkit.AbstractSystem)
    keep = KEEP_TUNABLE[]
    all = filter(x -> ModelingToolkit.istunable(x, true), ModelingToolkit.parameters(sys; initial_parameters = true))
    keep === nothing && return all
    names = Set(keep)
    filter(x -> DyadWasm.varname(x) in names, all)
end

# A monolithic DAE unit keeps its algebraic variables consistent with `BrownFullBasicInit()`, whose
# `nlsolve = nothing` means NonlinearSolve's default polyalgorithm: abstractly typed caches and
# LAPACK foreign calls (Krylov's `dgeqrf_64_`) that WasmCodegen cannot compile. This defaults it to
# the Newton DyadWasm uses for in-module initialization.
import DiffEqBase, LinearSolve
const NonlinearSolve = DyadWasm.NonlinearSolve
using ADTypes: AutoForwardDiff
get(ENV, "WASM_STOCK_BFBI", "0") == "1" || @eval DiffEqBase function BrownFullBasicInit(; abstol = 1.0e-10,
        nlsolve = $(NonlinearSolve.NewtonRaphson(; autodiff = AutoForwardDiff(chunksize = 1),
                                                 linsolve = LinearSolve.LUFactorization())))
    return BrownFullBasicInit(abstol, nlsolve)
end

# build_component writes each start value into the manifest with `outs[i](view0(1))`,
# after compiling. For an observed output that getter calls a function `eval`ed inside
# build_component, so from build_component's world age it fails ("The applicable method may be
# too new"). This re-evaluates cosim.jl with that one call made through `invokelatest`.
let src = read(joinpath(pkgdir(DyadWasm), "src", "cosim.jl"), String)
    old = "Float64(outs[i](view0(1)))"
    occursin(old, src) || error("patches.jl: cosim.jl no longer has `$old`")
    # a start value that is not finite cannot be written as JSON: written as null, like `min`/`max`
    src = replace(src, old => "finite_or_nothing(Float64(Base.invokelatest(outs[i], view0(1))))",
                  "Float64(ins[i][1](view0(1)))" => "finite_or_nothing(Float64(ins[i][1](view0(1))))",
                  "Float64(ps[i][1](view0(1)))" => "finite_or_nothing(Float64(ps[i][1](view0(1))))")
    Base.include_string(DyadWasm, src,
                        joinpath(pkgdir(DyadWasm), "src", "cosim.jl"))
end
