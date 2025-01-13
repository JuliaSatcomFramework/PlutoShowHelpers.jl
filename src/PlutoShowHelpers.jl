module PlutoShowHelpers

using AbstractPlutoDingetjes: is_inside_pluto, AbstractPlutoDingetjes, Display.published_to_js
using NamedTupleTools: NamedTupleTools, fieldnames, ntfromstruct
using HypertextLiteral: HypertextLiteral, @htl

include("consts.jl")

include("typedef.jl")
export AsPlutoTree, DefaultShowOverload, HideWhenCompact, HideWhenFull, HideAlways, DualDisplayAngle, DisplayLength, Ellipsis, InsidePluto, OutsidePluto

include("functions.jl")

end
