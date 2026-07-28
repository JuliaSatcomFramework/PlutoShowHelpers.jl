```@meta
CurrentModule = PlutoShowHelpers
```

# PlutoShowHelpers

A framework for customizing how Julia types are displayed across different contexts:

- **REPL** — 2-arg `show` (compact, single-line) and 3-arg `show` with `text/plain` (expanded, multi-line)
- **Pluto notebooks** — interactive tree structure with collapsible fields
- **Other HTML contexts** — through `show_outside_pluto`

Define one function ([`show_namedtuple`](@ref)) to control which fields are shown and how, and the package handles rendering in each context automatically.

## Quick Start

```@example quickstart
using PlutoShowHelpers

struct Satellite
    name::String
    altitude_km::Float64
    inclination_deg::Float64
    active::Bool
end

# Automatically defines show methods for 2-arg, text/plain, and text/html
@default_show_overload Satellite

# Control which fields are shown and how they are displayed
PlutoShowHelpers.show_namedtuple(s::Satellite) = (;
    name = s.name,
    altitude = s.altitude_km,
    inclination = s.inclination_deg,
    active = HideWhenCompact(s.active), # hidden in compact (2-arg) show
)

PlutoShowHelpers.shortname(::Satellite) = "Sat"             # compact name: Sat(...)
PlutoShowHelpers.repl_summary(s::Satellite) = "Satellite($(s.name))" # expanded header
nothing # hide
```

```@repl quickstart
sat = Satellite("ISS", 408.0, 51.6, true)
```

The compact (2-arg) form hides field labels by default and omits `active` because it's wrapped in [`HideWhenCompact`](@ref):

```@repl quickstart
show(stdout, sat)
```

## Where to go next

- [How It Works](@ref concepts) — the dispatch model, the Pluto/non-Pluto split, and why
  customization goes through a single `NamedTuple`.
- [How-to Guide](@ref guide) — recipes for hiding fields, renaming, nesting, and
  context-specific rendering.
- [Use These Types in Documenter](@ref documenter) — make `@example` blocks in your own
  docs render as text rather than HTML.
- [Utility Types](@ref) and the [API Reference](@ref) — ready-made display types, and exact
  signatures and defaults.
