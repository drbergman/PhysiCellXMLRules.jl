using CSV, DataFrames, PhysiCellXMLRules, LightXML

csv_text = """
// rules
cell_type_1,pressure,decreases,cycle entry,0,0.5,4,0
cell_type_1,contact with cell_type_5,increases,transform to cell_type_2,0.0001,0.01,4,0
cell_type_2,substrate_1,decreases,migration speed,0,0.5,4,0
cell_type_2,substrate_2,decreases,transform to cell_type_1,0.0,0.2,4,0
cell_type_3,pressure,decreases,cycle entry,0,1.0,4,0
cell_type_3,contact with cell_type_5,increases,transform to cell_type_4,0.0001,0.01,4,0
cell_type_4,substrate_1,decreases,migration speed,0,0.5,4,0
cell_type_4,substrate_2,decreases,transform to cell_type_3,0.0,0.2,4,0
cell_type_5,custom:sample,increases,custom:sample,100,0.01,4,0
"""

open("cell_rules.csv", "w") do f
    write(f, csv_text)
end

writeRules("./test.xml", "./cell_rules.csv")
n_rules = readchomp(`grep -c "<signal" ./test.xml`) |> x->parse(Int, x)
@test n_rules == countlines(IOBuffer(csv_text)) - 1
xml_lines = readlines("./test.xml")
@test [contains(xml_line, "<behavior name=\"custom sample\">") for xml_line in xml_lines] |> sum == 1 # should be exactly one custom sample behavior
@test [contains(xml_line, "<signal name=\"custom sample\">") for xml_line in xml_lines] |> sum == 1 # should be exactly one custom sample signal

# ----------------------------
open("cell_rules_empty.csv", "w") do f
    write(f, "")
end

writeRules("./test_empty.xml", "./cell_rules_empty.csv")
n_lines = open("./test_empty.xml", "r") do f; countlines(f); end
@test n_lines == 2 # the encoding line and the </hypothesis_rulesets> line

# ----------------------------
open("cell_rules_emptyish.csv", "w") do f
    write(f, "//\n")
end

writeRules("./test_emptyish.xml", "./cell_rules_emptyish.csv")
n_lines = open("./test_emptyish.xml", "r") do f; countlines(f); end
@test n_lines == 2 # the encoding line and the </hypothesis_rulesets> line

# test errors
@test_throws ArgumentError PhysiCellXMLRules.Behavior("cycle entry", :increasing, "2.0")

behavior_element = new_element("behavior")
@test_throws ArgumentError PhysiCellXMLRules.getElement(behavior_element, "signals"; require_exist=true)

increasing_signals = PhysiCellXMLRules.createElement(behavior_element, "increasing_signals")
@test_throws ArgumentError PhysiCellXMLRules.createElement(behavior_element, "increasing_signals")

PhysiCellXMLRules.createElementByAttribute(increasing_signals, "signal", "name", "pressure")
@test_throws ArgumentError PhysiCellXMLRules.createElementByAttribute(increasing_signals, "signal", "name", "pressure")

@test_throws ArgumentError PhysiCellXMLRules.getElementByAttribute(increasing_signals, "signal", "name", "oxygen"; require_exist=true)

# test adding/updating rules
xml_doc = parse_file("./test.xml")
xml_root = root(xml_doc)
behavior = PhysiCellXMLRules.Behavior("cycle entry", :increases, "1.0")
signal = PhysiCellXMLRules.Signal("oxygen", "1.0", "2", "1")
rule = PhysiCellXMLRules.Rule("cell_type_1", behavior, signal)
PhysiCellXMLRules.addRule(xml_root, rule)

behavior = PhysiCellXMLRules.Behavior("cycle entry", :decreases, "2.0")
rule = PhysiCellXMLRules.Rule("cell_type_1", behavior, signal)
@test_throws ArgumentError PhysiCellXMLRules.addRule(xml_root, rule)
PhysiCellXMLRules.addRule(xml_root, rule; require_max_response_unchanged=false)