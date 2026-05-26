const HDOTS = "\u2026"
const VDOTS = "\u22ee"

# This is used to potentially share context between interface functions of PlutoShowHelpers. For example, it can be used to set some flag in the `show_namedtuple` function to modify the output returned by `shortname`.
const CONTEXT = ScopedValue{}(Dict())