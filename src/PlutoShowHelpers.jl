module PlutoShowHelpers

using AbstractPlutoDingetjes: is_inside_pluto, AbstractPlutoDingetjes, Display.published_to_js
using ConstructionBase: ConstructionBase, getfields
using HypertextLiteral: HypertextLiteral, @htl

export is_inside_pluto

include("consts.jl")

include("typedef.jl")
export AsPlutoTree, DefaultShowOverload, HideWhenCompact, HideWhenFull, HideAlways, DualDisplayAngle, DisplayLength, Ellipsis, InsidePluto, OutsidePluto

include("utils.jl")

include("interface_functions.jl")
end
