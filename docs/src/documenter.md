```@meta
CurrentModule = PlutoShowHelpers
```

# [Use These Types in Documenter](@id documenter)

Documenter's `@example` blocks display a result using the richest MIME type the value
supports, and ask `Base.showable` which those are. Because `@default_show_overload` and
[`CustomShowable`](@ref) both define a `text/html` method, `@example` blocks pick HTML —
which outside Pluto falls back to
[`show_outside_pluto`](@ref PlutoShowHelpers.show_outside_pluto) and is rarely what you
want in a manual.

## Render `@example` blocks as text

Call [`disable_html_show!`](@ref PlutoShowHelpers.disable_html_show!) once per build to
make those blocks use the REPL (`text/plain`) rendering instead. Either from `make.jl`,
before `makedocs`:

```julia
using MyPackage
using PlutoShowHelpers

PlutoShowHelpers.disable_html_show!()
```

or from a `@setup` block in a page:

````markdown
```@setup tutorial
using PlutoShowHelpers
PlutoShowHelpers.disable_html_show!()
```
````

One call covers the whole build, including types that do not exist yet when it runs.
Subtypes of [`CustomShowable`](@ref) are caught because their method sits on the abstract
type, and [`@default_show_overload`](@ref) checks whether the call has happened and emits
the `showable` method itself — so a type defined inside an `@example` block is covered
without a second call.

`@repl` blocks never consult `showable`, so they are already text-only and need none of
this. The call also leaves `show(io, MIME"text/html"(), x)` and Pluto rendering untouched —
it changes only which MIME Documenter asks for.

## Include hand-written types, or keep some as HTML

`disable_html_show!` picks up every type registered by
[`@default_show_overload`](@ref) and every subtype of [`CustomShowable`](@ref)
automatically. Pass types whose `text/html` show you wrote by hand as positional
arguments, and types that should keep rendering as HTML via `exclude`:

```julia
PlutoShowHelpers.disable_html_show!(MyHandWrittenType; exclude = (MyPlotType,))
```

This documentation is built with the call in place, so the `@example` blocks throughout
these pages show the same output you would get in the REPL.
