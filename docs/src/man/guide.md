# Guide

To convert a PhysiCell rules file (in CSV format) into an XML format, use
```
using PhysiCellXMLRules
new_file = "rules.xml"
source_file = "rules.csv"
writeRules(new_file, source_file)
```

To convert from the XML format to the CSV format, use
```
using PhysiCellXMLRules
new_file = "rules.csv"
source_file = "rules.xml"
exportRulesToCSV(new_file, source_file)
```