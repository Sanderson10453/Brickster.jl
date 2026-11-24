"""
Main module for `Brickster.jl` -- a 

Seven functions are exported from this module for public use:

- [`BricksterClient`](@ref). Generates the class that will allow users to interface with Databricks.
- [`compute_connect`](@ref). Connects to a specific compute within a workspace.
- [`list_catalogs`](@ref). Lists the catalogs within a workspace.
- [`list_schemas`](@ref). Lists the schemas within a specific catalog.
- [`list_tables`](@ref). Lists the tables within a schema.
- [`list_computes`](@ref). Lists the tables within a schema.
- [`query_db`](@ref). Pulls data from Databricks via a user-defined query and returns a DataFrame.

"""
module Brickster

## Import modules
using DataFrames
using HTTP
using JSON3
using Printf

include("Setup.jl")
include("Attributes.jl")
include("Query.jl")


## Export Modules for use
# ------------------------
export BricksterClient, compute_connect, list_catalogs, list_schemas, list_tables, query_db

end # Module end
