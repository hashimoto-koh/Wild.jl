using Wild
using Documenter

makedocs(;
    modules=[Wild],
    authors="Koh Hashimoto",
    repo="https://github.com/hashimoto-koh/Wild.jl/blob/{commit}{path}#L{line}",
    sitename="Wild.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://hashimoto-koh.github.io/Wild.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/hashimoto-koh/Wild.jl",
)
