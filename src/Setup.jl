# Creating a struct to pass objects
Base.@kwdef mutable struct BricksterClient
    token :: String         # Required keyword
    host_name :: String     # Required keyword
    header :: Vector{Pair{String, String}}         # Required keyword
    warehouse_map :: Dict
    compute :: Union{String, Nothing} = nothing
end

function BricksterClient(token, host_name)

    # Creating the headers for the request
    header = [
        "Authorization" => "Bearer $token"
        ,"Content-Type" => "application/json"
            ]

    # Grabbing Warehouses
    warehouses =  HTTP.get(
    "$host_name/api/2.0/sql/warehouses"
    ,["Authorization" => "Bearer $token"]
                        )

    # Parsing the request and making dict
    warehouses_parsed = JSON3.read(warehouses.body)
    warehouse_map = Dict(w[:id] => w[:name] for w in warehouses_parsed[:warehouses])

    BricksterClient(token = token
                    ,host_name = host_name
                    ,header = header
                    ,warehouse_map = warehouse_map
                    ,compute = nothing
                    )
end

"""
    compute_connect(workspace :: BricksterClient, compute_name :: String )

This function connects to a specific compute within your workspace.
It will update the workspace computer attribute

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `compute_name`: This is the string approximation of the compute you want to connect to. 
                    If you are unsure, please use the list_computes function to see the available 
                    computes.
# Returns
- An updated workspace with the selected compute
"""
function compute_connect(workspace :: BricksterClient
                        ,compute_name :: String )

    # Attributes
    compute_match_key = nothing


    # Trying to match to compute of Interest
    for (k,v) in workspace.warehouse_map
        if occursin(Regex(compute_name, "i"), v)
            compute_match_key = k
            break   # Break the loop if there's a match
        end
    end

    # Catching if Fails
    if isnothing(compute_match_key)
        error("No Matching Databricks Compute for: $compute_name \n")

    else
        workspace.compute = compute_match_key
        @printf("This is the compute you selected %s \n", compute_match_key)
    end

    # return updated struct
    return workspace

end
