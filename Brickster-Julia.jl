module Brickster

# Import modules
using Printf
using HTTP
using JSON3
using DataFrames
using Match

# Functions to be used
export BricksterClient, list_computes, compute_connect

# Creating a struct to pass objects
struct BricksterClient
    token :: String
    host_name :: String
    warehouse_map :: Dict
end 


# Function to get dict of all computes within a warehouse
function BricksterClient(token, host_name)
    
    # Creating the headers for the request
    header = [
        "Authorization" => "Bearer $token"
        "Content-Type" => "application/json"
            ]

    # Grabbing Warehouses
    warehouses =  HTTP.get(
    "$host_name/api/2.0/sql/warehouses"
    ,["Authorization" => "Bearer $token"]
                        )

    # Parsing the request and making dict
    warehouses_parsed = JSON3.read(warehouses.body)
    warehouse_map = Dict(w[:id] => w[:name] for w in warehouses_parsed[:warehouses])

    BricksterClient(token, host_name, warehouse_map)
end 

# Function to list all computes within a warehouse
function list_computes(warehouse :: BricksterClient)
    # Printing compute names
    @printf("These are the available computes in your warehouse: %s",values(warehouse.warehouse_map))
    
end

function compute_connect(warehouse :: BricksterClient, compute_name )

    # Attributes
    compute_match_key = nothing


    # Trying to match to compute of Interest
    for (k,v) in warehouse_map
        if occursin(r"compute_name"i, v)
            compute_match_key = k
            break   # Break the loop if there's a match
        end
    end

    # Catching if Fails
    if isnothing(compute_match_key)
        erorr("No Matching Databricks Compute for: $compute")

    else 
        @printf("This is the compute you selected %s",compute_match_key)
    end

    return compute_match_key

end


end # Module end