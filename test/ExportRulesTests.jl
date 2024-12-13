using PhysiCellXMLRules

function compare_csvs(csv_original::AbstractString, csv_exported::AbstractString)
    csv_original_text = String[]
    open(csv_original, "r") do f
        global csv_original_text = readlines(f)
    end

    csv_exported_test = String[]
    open(csv_exported, "r") do f
        global csv_exported_test = readlines(f)
    end

    for line in csv_original_text
        @test line in csv_exported_test
    end
    
    for line in csv_exported_test
        line = lstrip(line)
        if startswith(line, "//")
            continue
        end
        @test line in csv_original_text
    end
end

xml_csv_pairs = [
    ("./test.xml", "./cell_rules.csv"),
    ("./test_empty.xml", "./cell_rules_empty.csv"),
    ("./test_emptyish.xml", "./cell_rules_emptyish.csv")
]

for (path_to_xml, path_to_original_csv) in xml_csv_pairs
    path_to_csv = "$(split(path_to_original_csv, ".")[1])_exported.csv"
    exportRulesToCSV(path_to_csv, path_to_xml)
    compare_csvs(path_to_original_csv, path_to_csv)
end
