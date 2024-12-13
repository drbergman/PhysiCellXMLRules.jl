using PhysiCellXMLRules
using Test

@testset "PhysiCellXMLRules.jl" begin
    # Write your tests here.
    include("./WriteRulesTests.jl")
    include("./ExportRulesTests.jl")
end
