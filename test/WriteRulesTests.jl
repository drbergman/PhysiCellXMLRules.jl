using CSV, DataFrames, PhysiCellXMLRules

csv_text = """
cell_type_1,pressure,decreases,cycle entry,0,0.5,4,0
cell_type_1,contact with cell_type_5,increases,transform to cell_type_2,0.0001,0.01,4,0
cell_type_2,substrate_1,decreases,migration speed,0,0.5,4,0
cell_type_2,substrate_2,decreases,transform to cell_type_1,0.0,0.2,4,0
cell_type_3,pressure,decreases,cycle entry,0,1.0,4,0
cell_type_3,contact with cell_type_5,increases,transform to cell_type_4,0.0001,0.01,4,0
cell_type_4,substrate_1,decreases,migration speed,0,0.5,4,0
cell_type_4,substrate_2,decreases,transform to cell_type_3,0.0,0.2,4,0
"""

open("cell_rules.csv", "w") do f
    write(f, csv_text)
end

writeRules("./test.xml", "./cell_rules.csv")

open("cell_rules_empty.csv", "w") do f
    write(f, "")
end

writeRules("./test_empty.xml", "./cell_rules_empty.csv")

open("cell_rules_emptyish.csv", "w") do f
    write(f, "//\n")
end

writeRules("./test_emptyish.xml", "./cell_rules_emptyish.csv")
