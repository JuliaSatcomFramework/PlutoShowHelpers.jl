using Documenter
using DocumenterVitepress
using PlutoShowHelpers

# Documenter's @example blocks prefer text/html; this makes them fall through to the
# text/plain rendering these types are designed for.
PlutoShowHelpers.disable_html_show!()

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
