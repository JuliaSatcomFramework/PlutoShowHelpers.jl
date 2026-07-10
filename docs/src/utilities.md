```@meta
CurrentModule = PlutoShowHelpers
```

# Utility Types

PlutoShowHelpers includes a few ready-made display types for common use cases.

## DualDisplayAngle

[`DualDisplayAngle`](@ref) takes an angle **in radians** and displays it in both degrees
and radians. In compact contexts only degrees are shown.

```@example angles
using PlutoShowHelpers

a = DualDisplayAngle(π/4)
nothing # hide
```

```@repl angles
a
repr(a)
```

Control precision with `digits` or `sigdigits` (mutually exclusive):

```@repl angles
DualDisplayAngle(π/6; digits=2)
DualDisplayAngle(1.23456; sigdigits=4)
```

`Float32` values are preserved in the display:

```@repl angles
DualDisplayAngle(Float32(π/3); digits=2)
```

Inside Pluto, both representations are shown side by side, with radians hidden
when the tree is collapsed.

## DisplayLength

[`DisplayLength`](@ref) displays a length value in meters or kilometers, switching
to km when the absolute value reaches 1000 m.

```@example lengths
using PlutoShowHelpers

l = DisplayLength(456.789)
nothing # hide
```

```@repl lengths
l
DisplayLength(12345.6)
DisplayLength(-7500.0; digits=1)
DisplayLength(NaN)
```

## [Ellipsis](@id ellipsis-utility)

[`Ellipsis`](@ref PlutoShowHelpers.Ellipsis) renders as context-appropriate dots — horizontal (`…`) in compact
(2-arg) show and vertical (`⋮`) in expanded (3-arg) show. See the
[guide section on Ellipsis](@ref guide) for a usage example.
