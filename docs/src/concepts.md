```@meta
CurrentModule = PlutoShowHelpers
```

# [How It Works](@id concepts)

This page explains the model behind the package. For step-by-step recipes, see the
[How-to Guide](@ref guide).

## The problem: one type, three `show` methods

Julia dispatches display through several `show` methods, and each fires in a different
situation:

| Method | When it fires |
|--------|--------------|
| `show(io, x)` | 2-arg: string interpolation, `repr(x)`, compact contexts |
| `show(io, MIME"text/plain"(), x)` | 3-arg: REPL display, multi-line output |
| `show(io, MIME"text/html"(), x)` | HTML rendering (Pluto, Jupyter, docs) |

Writing all three by hand means three places to keep in sync, and the third one has to
branch further: an interactive Pluto tree is a very different artefact from the static
HTML that Jupyter or a documentation build wants.

PlutoShowHelpers collapses this into a single customization point. You describe *what*
to show as a `NamedTuple`, and the package decides *how* to render it in each context.

## The two-context split

Everything HTML-related keys off one question: is this `IO` inside a Pluto notebook?
`is_inside_pluto(io)` answers it, and the two singleton types [`InsidePluto`](@ref) and
[`OutsidePluto`](@ref) let you dispatch on the answer.

Inside Pluto, output becomes Pluto's native collapsible tree widget, where a field can be
visible when collapsed, visible only when expanded, or never visible. Outside Pluto, there
is no tree — output falls back to the compact 2-arg form, which is why the compact and
"collapsed" columns of the visibility table behave alike.

## The routing

[`CustomShowable`](@ref) is the abstract type that carries the routing. Its `text/html`
method inspects the `IO` and forwards to either
[`show_inside_pluto`](@ref PlutoShowHelpers.show_inside_pluto) or
[`show_outside_pluto`](@ref PlutoShowHelpers.show_outside_pluto). Two concrete subtypes
ship with the package:

- [`DefaultShowOverload`](@ref) — the full pipeline. It reads
  [`show_namedtuple`](@ref PlutoShowHelpers.show_namedtuple) and renders it appropriately
  for all three `show` methods. [`@default_show_overload`](@ref) simply forwards your
  type's `show` methods to it.
- [`AsPlutoTree`](@ref) — the tree renderer alone, for when you want to hand-write the
  non-Pluto HTML but keep the tree inside Pluto.

Subtyping `CustomShowable` directly gets you the same routing without going through
`DefaultShowOverload`, which is the escape hatch when the `show_namedtuple` model does not
fit your type.

## Why a `NamedTuple`

[`show_namedtuple`](@ref PlutoShowHelpers.show_namedtuple) returns data, not formatted
text. That indirection is what lets one definition serve three contexts: the same tuple
becomes `Sat("ISS", 408.0)` in compact form, a labelled block in the REPL, and a tree in
Pluto.

It also composes. Values in the tuple need not be the original field values — they can be
computed summaries, wrapped in visibility markers like [`HideWhenCompact`](@ref), or
wrapped in `DefaultShowOverload` to recurse into a nested custom type without committing
type piracy on someone else's struct.

Field *labels* come from the tuple's keys, which is why suppressing a label uses Julia's
gensym key syntax (`var"#x"`) rather than a separate mechanism — an invisible label is
still a distinct key.

## CONTEXT

!!! warning "Experimental API"
    The `CONTEXT` mechanism is experimental and may change in future versions.

`CONTEXT` is a package-scoped `ScopedValue` holding a `Dict{Any,Any}`, set for the
duration of a show call.

It exists because `show_namedtuple` returns only field data, yet occasionally a type needs
to influence rendering decisions that sit outside that data — the current supported case
being which fields keep their labels in the compact 2-arg form. Rather than widening the
`show_namedtuple` return type for every such knob, the scoped dictionary acts as a side
channel between `show_namedtuple` and the renderer downstream of it.

The trade-off is deliberate and not free: it is implicit state, invisible in the function
signature, and the reason the API is marked experimental. Prefer expressing intent through
the returned `NamedTuple` where you can. See
[Print field labels in compact show](@ref howto-context) for the concrete usage.
