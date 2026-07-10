using Documenter
using DocumenterVitepress
using PlutoShowHelpers

makedocs(;
    sitename = "PlutoShowHelpers",
    authors = "Alberto Mengali",
    modules = [PlutoShowHelpers],
    warnonly = [:missing_docs],
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/JuliaSatcomFramework/PlutoShowHelpers.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Utility Types" => "utilities.md",
        "API Reference" => "api.md",
    ],
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/JuliaSatcomFramework/PlutoShowHelpers.jl",
    devbranch = "main",
    push_preview = true,
)
