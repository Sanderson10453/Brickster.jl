module IO

## Import Modules
using HTTP
using Printf

## Functions to expose
export


# Creating a struct to pass objects
Base.@kwdef mutable struct BricksterClient
    token :: String         # Required keyword
    host_name :: String     # Required keyword
    header :: Vector{Pair{String, String}}         # Required keyword
    warehouse_map :: Dict
    compute :: Union{String, Nothing} = nothing
end


end
