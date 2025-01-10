using PlutoShowHelpers
using Documenter

DocMeta.setdocmeta!(PlutoShowHelpers, :DocTestSetup, :(using PlutoShowHelpers); recursive = true)

const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
    file != "index.md" && splitext(file)[2] == ".md"
]

makedocs(;
    modules = [PlutoShowHelpers],
    authors = "Alberto Mengali <a.mengali@gmail.com>",
    repo = "https://github.com/disberd/PlutoShowHelpers.jl/blob/{commit}{path}#{line}",
    sitename = "PlutoShowHelpers.jl",
    format = Documenter.HTML(; canonical = "https://disberd.github.io/PlutoShowHelpers.jl"),
    pages = ["index.md"; numbered_pages],
)

deploydocs(; repo = "github.com/disberd/PlutoShowHelpers.jl")
