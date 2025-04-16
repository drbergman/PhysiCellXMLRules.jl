module PhysiCellXMLRules
using LightXML, DataFrames, CSV

export writeRules, exportRulesToCSV

"""
    standardizeCustomName(name::AbstractString)

If the name for a signal or behavior starts with "custom:", use the synonym "custom <name>" instead.

pcvct uses `:` to use attributes to specify elements in an XML path. So, we use `custom <name>` to avoid incorrect splitting on `:`.
"""
function standardizeCustomName(name)
    if !startswith(name, "custom:")
        return name
    end
    # store all custom behaviors as "custom <name>" to only use `:` for indicating attribute on xml paths
    name = name[8:end] |> lstrip
    return "custom $name"
end

struct Behavior
    name::AbstractString
    response::Symbol
    max_response::AbstractString
    function Behavior(name::AbstractString, response::AbstractString, max_response::AbstractString)
        return Behavior(name, Symbol(response), max_response)
    end
    function Behavior(name::AbstractString, response::Symbol, max_response::AbstractString)
        name = standardizeCustomName(name)
        if response != :increases && response != :decreases
            throw(ArgumentError("The response must be either :increases or :decreases. Got $response for $name."))
        end
        new(name, response, max_response)
    end
end

struct Signal
    name::AbstractString
    half_max::AbstractString
    hill_power::AbstractString
    applies_to_dead::AbstractString
    function Signal(name::AbstractString, half_max::AbstractString, hill_power::AbstractString, applies_to_dead::AbstractString)
        name = standardizeCustomName(name)
        new(name, half_max, hill_power, applies_to_dead)
    end
end

struct Rule
    cell_type::AbstractString
    behavior::Behavior
    signal::Signal
end

function getElement(parent_element::XMLElement, element_name::AbstractString; require_exist::Bool=false)
    ce = find_element(parent_element, element_name)
    if isnothing(ce) && require_exist
        throw(ArgumentError("Element '$element_name' not found in parent element '$parent_element'"))
    end
    return ce
end

function createElement(parent_element::XMLElement, element_name::AbstractString; require_new::Bool=true)
    if require_new && !isnothing(getElement(parent_element, element_name; require_exist=false))
        throw(ArgumentError("Element '$element_name' already exists in parent element '$parent_element'"))
    end
    return new_child(parent_element, element_name)
end

function getOrCreateElement(parent_element::XMLElement, element_name::AbstractString)
    ce = getElement(parent_element, element_name; require_exist=false)
    if isnothing(ce)
        ce = createElement(parent_element, element_name; require_new=false) # since we already checked it doesn't exist, don't need it to be new
    end
    return ce
end

function getElementByAttribute(parent_element::XMLElement, element_name::AbstractString, attribute_name::AbstractString, attribute_value::AbstractString; require_exist::Bool=false)
    candidate_elements = get_elements_by_tagname(parent_element, element_name)
    for ce in candidate_elements
        if attribute(ce,attribute_name)==attribute_value
            return ce
        end
    end
    if require_exist
        throw(ArgumentError("Element '$element_name' not found in parent element '$parent_element' with attribute '$attribute_name' = '$attribute_value'"))
    end
    return nothing
end

function createElementByAttribute(parent_element::XMLElement, element_name::AbstractString, attribute_name::AbstractString, attribute_value::AbstractString; require_new::Bool=true)
    if require_new && !isnothing(getElementByAttribute(parent_element, element_name, attribute_name, attribute_value; require_exist=false))
        throw(ArgumentError("$(element_name) already exists with (attribute, value) = ($(attribute_name), $(attribute_value)).")) # improve this to name the parent element and the new element name
    end
    ce = new_child(parent_element, element_name)
    set_attribute(ce, attribute_name, attribute_value)
    return ce
end

function getOrCreateElementByAttribute(parent_element::XMLElement, element_name::AbstractString, attribute_name::AbstractString, attribute_value::AbstractString)
    ce = getElementByAttribute(parent_element, element_name, attribute_name, attribute_value; require_exist=false)
    if isnothing(ce)
        ce = createElementByAttribute(parent_element, element_name, attribute_name, attribute_value; require_new=false) # since we already checked it doesn't exist, don't need it to be new
    end
    return ce
end

function getResponse(xml_root::XMLElement, cell_type::AbstractString, behavior::Behavior) # this could be called "getOrCreateResponse", but I don't think it will ever be needed to either only get or only create it
    response_signals = (behavior.response == :decreases) ? "decreasing_signals" : "increasing_signals"
    cell_type_element = getOrCreateElementByAttribute(xml_root, "hypothesis_ruleset", "name", cell_type)
    behavior_element = getOrCreateElementByAttribute(cell_type_element, "behavior", "name", behavior.name)
    return getOrCreateElement(behavior_element, response_signals)
end

function addSignal(response_element::XMLElement, signal::Signal)
    signal_element = createElementByAttribute(response_element, "signal", "name", signal.name; require_new=true)
    setSignalParameters(signal_element, signal)
    return signal_element
end

function setSignalParameters(signal_element::XMLElement, signal::Signal)
    half_max_element = getOrCreateElement(signal_element, "half_max")
    set_content(half_max_element, signal.half_max)
    hill_power_element = getOrCreateElement(signal_element, "hill_power")
    set_content(hill_power_element, signal.hill_power)
    applies_to_dead_element = getOrCreateElement(signal_element, "applies_to_dead")
    set_content(applies_to_dead_element, signal.applies_to_dead)
end

function addRule(xml_root::XMLElement, rule::Rule; require_max_response_unchanged::Bool=true)
    cell_type = rule.cell_type
    behavior = rule.behavior
    signal = rule.signal
    response_element = getResponse(xml_root, cell_type, behavior)

    max_response_element = getOrCreateElement(response_element, "max_response")
    max_response = content(max_response_element)
    if isempty(max_response)
        set_content(max_response_element, rule.behavior.max_response)
    else
        previous_max_response = parse(Float64, max_response)
        if previous_max_response == parse(Float64, rule.behavior.max_response)
        elseif require_max_response_unchanged
            throw(ArgumentError("In adding the new rule, the max_response is being changed"))
        else
            set_content(max_response_element, rule.behavior.max_response)
        end
    end
    addSignal(response_element, signal)
end

function addRules(xml_root::XMLElement, data_frame::DataFrame)
    for row in eachrow(data_frame)
        cell_type = row[:cell_type]
        signal_name = row[:signal]
        response = row[:response]
        behavior_name = row[:behavior]
        max_response = row[:max_response]
        half_max = row[:half_max]
        hill_power = row[:hill_power]
        applies_to_dead = row[:applies_to_dead]
        @assert !ismissing(applies_to_dead) "The following CSV row is missing applies_to_dead. The row is likely missing a column:\n\t$(join(row, ","))"
        behavior = Behavior(behavior_name, response, max_response)
        signal = Signal(signal_name, half_max, hill_power, applies_to_dead)
        rule = Rule(cell_type, behavior, signal)
        addRule(xml_root, rule)
    end
    return
end

function addRules(xml_root::XMLElement, path_to_csv::AbstractString)
    @assert splitext(path_to_csv)[2] == ".csv" "The path to the CSV file must end with .csv. Got $(path_to_csv)"
    @assert isfile(path_to_csv) "The path to the CSV file must be a file. $(path_to_csv) is not a file."
    header = [:cell_type, :signal, :response, :behavior, :max_response, :half_max, :hill_power, :applies_to_dead]
    df = CSV.read(path_to_csv, DataFrame; header=header, types=String, comment="//")
    if isempty(df)
        return
    end
    addRules(xml_root, df)
    return
end

function writeRules(xml_doc::XMLDocument, path_to_csv::AbstractString)
    xml_root = create_root(xml_doc, "hypothesis_rulesets")
    addRules(xml_root, path_to_csv)
    return xml_doc
end

"""
    writeRules(path_to_xml::AbstractString, path_to_csv::AbstractString)

Write the rules from the CSV file at `path_to_csv` to the XML file at `path_to_xml`.

Note: this is not the inverse of [`exportRulesToCSV`](@ref) as `writeRules` discards comments in the original CSV and `exportRulesToCSV` adds comments to the exported CSV file.
"""
function writeRules(path_to_xml::AbstractString, path_to_csv::AbstractString; force::Bool=false)
    @assert splitext(path_to_xml)[2] == ".xml" "The path to the XML file must end with .xml. Got $(path_to_xml)"
    @assert force || !isfile(path_to_xml) "The path to the XML file must not exist. $(path_to_xml) is a file. Use writeRules(...; force=true) to overwrite it."
    xml_doc = XMLDocument()
    writeRules(xml_doc, path_to_csv)
    save_file(xml_doc, path_to_xml)
    free(xml_doc)
    return
end

"""
    exportRulesToCSV(path_to_csv::AbstractString, path_to_xml::AbstractString)

Export the rules from the XML file at `path_to_xml` to the CSV file at `path_to_csv`.

Note: this is not the inverse of [`writeRules`](@ref) as `writeRules` discards comments in the original CSV and `exportRulesToCSV` adds comments to the exported CSV file.
"""
function exportRulesToCSV(path_to_csv::AbstractString, path_to_xml::AbstractString)
    xml_doc = parse_file(path_to_xml)
    xml_root = root(xml_doc)
    open(path_to_csv, "w") do io
        println(io, "// XML Rules Export")
        println(io, "// cell_type,signal,response,behavior,max_response,half_max,hill_power,applies_to_dead\n")
    end
    for hypothesis_ruleset in get_elements_by_tagname(xml_root, "hypothesis_ruleset")
        exportCellToCSV(path_to_csv, hypothesis_ruleset)
    end
    free(xml_doc)
end

function exportCellToCSV(path_to_csv::AbstractString, hypothesis_ruleset::XMLElement)
    cell_type = attribute(hypothesis_ruleset, "name")
    printlnToCSV(path_to_csv, "// $cell_type")
    for behavior in get_elements_by_tagname(hypothesis_ruleset, "behavior")
        exportBehaviorToCSV(path_to_csv, cell_type, behavior)
    end
    printlnToCSV(path_to_csv, "")
end

function exportBehaviorToCSV(path_to_csv::AbstractString, cell_type::AbstractString, behavior::XMLElement)
    behavior_name = attribute(behavior, "name") |> standardizeCustomNameExport
    printlnToCSV(path_to_csv, "// └─$behavior_name")
    decreasing_signals_element = find_element(behavior, "decreasing_signals")
    if !isnothing(decreasing_signals_element)
        max_response = content(find_element(decreasing_signals_element, "max_response"))
        printlnToCSV(path_to_csv, "//   └─decreasing to $max_response")
        exportSignalsToCSV(path_to_csv, cell_type, behavior_name, max_response, decreasing_signals_element, :decreases)
    end
    increasing_signals_element = find_element(behavior, "increasing_signals")
    if !isnothing(increasing_signals_element)
        max_response = content(find_element(increasing_signals_element, "max_response"))
        printlnToCSV(path_to_csv, "//   └─increasing to $max_response")
        exportSignalsToCSV(path_to_csv, cell_type, behavior_name, max_response, increasing_signals_element, :increases)
    end
end

function exportSignalsToCSV(path_to_csv::AbstractString, cell_type::AbstractString, behavior_name::AbstractString, max_response::AbstractString, signals_element::XMLElement, response::Symbol)
    for signal in get_elements_by_tagname(signals_element, "signal")
        signal_name = attribute(signal, "name") |> standardizeCustomNameExport
        half_max = content(find_element(signal, "half_max"))
        hill_power = content(find_element(signal, "hill_power"))
        applies_to_dead = content(find_element(signal, "applies_to_dead"))
        row = (cell_type, signal_name, response, behavior_name, max_response, half_max, hill_power, applies_to_dead)
        printlnToCSV(path_to_csv, join(row, ","))
    end
end

function printlnToCSV(path_to_csv::AbstractString, line::AbstractString)
    open(path_to_csv, "a") do io
        println(io, line)
    end
end

"""
    standardizeCustomNameExport(name::AbstractString)

If the name for a signal or behavior starts with "custom ", use the synonym "custom:<name>" instead when exporting to a CSV.

Both are acceptable, but this function will convert it to the more standard format in PhysiCell.
"""
function standardizeCustomNameExport(name)
    if !startswith(name, "custom ")
        return name
    end
    return "custom:" * lstrip(name[8:end])
end

end