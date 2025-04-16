```@meta
CollapsedDocStrings = true
```

# Write XML

Writes the XML file for behavior rulesets.
Note, when importing a CSV to write to XML, the full expressiveness of the XML format is not available.
In particular, the following cannot be read in from a CSV:
- hierarchical rulesets (those with mediators and aggregators below the top two levels)
- mediator/aggregator functions
- attenuator/accumulator behaviors (only setters)

```@autodocs
Modules = [PhysiCellXMLRules]
Pages = ["write_xml.jl"]
```