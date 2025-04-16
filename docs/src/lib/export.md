```@meta
CollapsedDocStrings = true
```

# Export

Exports XML-based behavior rulesets into CSV approximations.
Note, hiearchical rulesets (those with mediators and aggregators below the top two levels) are possibly lossy.
This is meant, at the moment, to create an easier, human-readable format for understanding the rules in the XML file.

```@autodocs
Modules = [PhysiCellXMLRules]
Pages = ["export.jl"]
```