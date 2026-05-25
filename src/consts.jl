const HDOTS = "\u2026"
const VDOTS = "\u22ee"

"""
    CURRENT_IO::ScopedValue{IOContext}
Package-scoped [`ScopedValue`](https://docs.julialang.org/en/v1/base/scopedvalues/) that holds
the current [`IOContext`](@ref) set by [`with_iocontext`](@ref).
It is populated for the duration of a `with_iocontext` block and can be read via
[`get_from_iocontext`](@ref) from any code called inside that block.
"""
const CURRENT_IO = ScopedValue{IOContext}()