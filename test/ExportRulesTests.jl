using PhysiCellXMLRules

function compare_csvs(csv_original::AbstractString, csv_exported::AbstractString)
    csv_original_text = readlines(csv_original)
    csv_exported_test = readlines(csv_exported)

    for line in csv_original_text
        if isempty(line) || startswith(line, "//")
            continue
        end
        @test line in csv_exported_test
    end
    
    for line in csv_exported_test
        line = lstrip(line)
        if isempty(line) || startswith(line, "//")
            continue
        end
        @test line in csv_original_text
    end
end

xml_csv_pairs = [
    ("./test.xml", "./cell_rules.csv"),
    ("./test_empty.xml", "./cell_rules_empty.csv"),
    ("./test_emptyish.xml", "./cell_rules_emptyish.csv"),
    ("./test_advanced.xml", "./cell_rules_advanced.csv"),
]

for (path_to_xml, path_to_original_csv) in xml_csv_pairs
    path_to_csv = "$(split(path_to_original_csv, ".csv")[1])_exported.csv"
    exportCSVRules(path_to_csv, path_to_xml)
    compare_csvs(path_to_original_csv, path_to_csv)
end

exportCSVRules("./test_super_advanced.csv", "./test_super_advanced.xml")

#! test export without specifying elementary signal type
xml_doc = XMLDocument()
xml_root = create_root(xml_doc, "behavior_rulesets")

cell_type = "cd8"
e = new_child(xml_root, "behavior_ruleset")
set_attribute(e, "name", cell_type)

behavior_name = "attack cancer"
e = new_child(e, "behavior")
set_attribute(e, "name", behavior_name)

e_decreasing = new_child(e, "decreasing_signals") 
e_max_response = new_child(e_decreasing, "max_response")
set_content(e_max_response, "0.5")
e_signal = new_child(e_decreasing, "signal")
set_attribute(e_signal, "name", "pressure")

e_half_max = new_child(e_signal, "half_max")
set_content(e_half_max, "4.0")
e_hill_power = new_child(e_signal, "hill_power")
set_content(e_hill_power, "2.0")
e_applies_to_dead = new_child(e_signal, "applies_to_dead")
set_content(e_applies_to_dead, "0")

save_file(xml_doc, "./test_elementary_sans_type.xml")
exportCSVRules("./test_elementary_sans_type.csv", "./test_elementary_sans_type.xml")

@test_throws AssertionError exportCSVRules("./test_elementary_sans_type.csv", "./test_elementary_sans_type.xml")
exportCSVRules("./test_elementary_sans_type.csv", "./test_elementary_sans_type.xml"; force=true)
