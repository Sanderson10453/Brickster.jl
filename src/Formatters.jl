module Formatters

## Import Modules
using JSON3
using Printf

## Exporting



## Functions
"""This function will fix the dictionaries cominng from databricks"""
function _parse_field(field)
    if field isa JSON3.Object
        return field[:str]

    elseif isnothing(field) # Dealing wirth null values from Databricks
        return missing

    else
        return String(field)
    end

end

end
