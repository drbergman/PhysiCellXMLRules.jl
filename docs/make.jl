using PhysiCellXMLRules
using Documenter

DocMeta.setdocmeta!(PhysiCellXMLRules, :DocTestSetup, :(using PhysiCellXMLRules); recursive=true)

makedocs(;
    modules=[PhysiCellXMLRules],
    authors="Daniel Bergman <danielrbergman@gmail.com> and contributors",
    sitename="PhysiCellXMLRules.jl",
    format=Documenter.HTML(;
        canonical="https://drbergman.github.io/PhysiCellXMLRules.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/drbergman/PhysiCellXMLRules.jl",
    devbranch="main",
)
