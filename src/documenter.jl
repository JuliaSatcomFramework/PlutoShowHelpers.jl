"""
    uses_default_html_show(::Type) -> Bool

Return `true` for types whose `MIME"text/html"` show method is provided by
PlutoShowHelpers, either by subtyping [`CustomShowable`](@ref) or through
[`@default_show_overload`](@ref).

This trait exists so that [`disable_html_show!`](@ref) can find those types by walking
`methods(uses_default_html_show)`. Nothing else consults it, and declaring it has no effect
on how a type is shown.
"""
uses_default_html_show(::Type) = false
uses_default_html_show(::Type{<:CustomShowable}) = true

# Set by disable_html_show! and read by @default_show_overload at macro-expansion time, so
# that types defined after that call — such as those defined inside a Documenter @example
# block — are hidden from text/html rendering as well.
#
# Precompilation always runs in a fresh process where this is false, so the conditional
# method can never be baked into a downstream package's cache.
const HTML_SHOW_DISABLED = Ref(false)

# Recover `T` from the `::Type{<:T}` (or `::Type{T}`) annotation of a
# `uses_default_html_show` method. Returns `nothing` for the `::Type` fallback, whose type
# variable is bounded by `Any`.
function _traited_type(m::Method)
    T = m.sig.parameters[2]
    if T isa UnionAll
        ub = T.var.ub
        return ub === Any ? nothing : ub
    elseif T isa DataType && T <: Type && length(T.parameters) == 1
        p = T.parameters[1]
        return p isa Type ? p : nothing
    end
    return nothing
end

"""
    disable_html_show!(extra::Type...; exclude = ()) -> Vector{Type}

Make Documenter render PlutoShowHelpers-driven types with their REPL (`text/plain`)
representation instead of their HTML one, by defining

```julia
Base.showable(::MIME"text/html", ::T) = false
```

for every `T` for which [`uses_default_html_show`](@ref) is `true`, plus any `extra` types
given. Returns the vector of types that were disabled.

Documenter's `@example` blocks pick the richest available MIME and consult `Base.showable`
to decide whether `text/html` is available; with this method in place they fall through to
the `text/plain` output they already generate, rendered as a normal code block. `@repl`
blocks are text-only to begin with and are unaffected.

Call it once per documentation build, either from `make.jl` before `makedocs`, or from a
Documenter `@setup` block. See the guide for worked examples.

Types defined after the call are covered too: subtypes of [`CustomShowable`](@ref) through
the method installed on the abstract type, and [`@default_show_overload`](@ref) types
because the macro checks whether this function has run and emits the `showable` method
itself. A single call therefore covers a whole build, including types defined inside
`@example` blocks.

`extra` covers types whose `text/html` show method was written by hand rather than through
[`@default_show_overload`](@ref) or by subtyping [`CustomShowable`](@ref).

Types listed in `exclude` keep their HTML rendering. Because the `CustomShowable` method is
installed on an abstract type, omitting a subtype from the set would not spare it, so each
excluded type gets an explicit `Base.showable(::MIME"text/html", ::T) = true`, which is more
specific and therefore wins.

This only changes MIME negotiation. `show(io, MIME"text/html"(), x)` and
`repr(MIME"text/html"(), x)` still produce HTML, and Pluto rendering is untouched.

Because this defines methods, `showable` must not be queried for the affected types within
the same top-level expression that calls it; use `Base.invokelatest` if you need to. Each
Documenter block is evaluated separately, so this does not arise in a docs build.
"""
function disable_html_show!(extra::Type...; exclude = ())
    HTML_SHOW_DISABLED[] = true
    excluded = collect(Type, exclude)
    traited = Type[T for T in map(_traited_type, methods(uses_default_html_show)) if T !== nothing]
    types = setdiff(vcat(traited, collect(Type, extra)), excluded)
    for T in types
        @eval Base.showable(::MIME"text/html", ::$T) = false
    end
    for T in excluded
        @eval Base.showable(::MIME"text/html", ::$T) = true
    end
    return types
end
