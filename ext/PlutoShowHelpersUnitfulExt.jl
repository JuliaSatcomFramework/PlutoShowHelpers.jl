module PlutoShowHelpersUnitfulExt

using PlutoShowHelpers: DualDisplayAngle, DisplayLength
using Unitful: Unitful, Quantity, NoDims, uconvert, ustrip

# Unitful gives no dimension of its own to angles. Degrees, radians, percent and
# steradian are all NoDims, and `uconvert` turns any of them into radians. The two
# angle units are therefore listed.
const AngleQuantity{T <: Real} = Union{
    Quantity{T, NoDims, typeof(Unitful.°)},
    Quantity{T, NoDims, typeof(Unitful.rad)},
}

DualDisplayAngle(x::AngleQuantity; kwargs...) =
    DualDisplayAngle(ustrip(uconvert(Unitful.rad, x)); kwargs...)

# Lengths carry the 𝐋 dimension, so every length unit is accepted. `Quantity` is
# used instead of `Unitful.Length` because that alias also covers logarithmic
# units, which are not lengths.
DisplayLength(x::Quantity{<:Real, Unitful.𝐋}; kwargs...) =
    DisplayLength(ustrip(uconvert(Unitful.m, x)); kwargs...)

end
