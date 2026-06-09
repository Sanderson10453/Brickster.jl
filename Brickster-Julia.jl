module Brickster

# Import modules
using Printf
using HTTP
using JSON3
using DataFrames
using Match

# Functions to be used
export BricksterClient, list_computes, compute_connect, list_schemas, list_schemas

# Creating a struct to pass objects
Base.@kwdef mutable struct BricksterClient
    token :: String         # required keyword
    host_name :: String     # required keyword
    header :: Vector{Pair{String, String}}         # required keyword
    warehouse_map :: Dict   
    compute :: Union{String, Nothing} = nothing # this will be updated
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

    BricksterClient(token = token 
                    ,host_name = host_name
                    ,header = header
                    ,warehouse_map = warehouse_map
                    ,compute = nothing
                    )
end 

# Function to list all computes within a warehouse
function list_computes(workspace :: BricksterClient)
    # Printing compute names
    @printf("These are the available computes in your warehouse: %s",values(workspace.warehouse_map))
    
end

function compute_connect(workspace :: BricksterClient, compute_name )

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
        error("No Matching Databricks Compute for: $compute_name")

    else 
        workspace.compute = compute_match_key
        @printf("This is the compute you selected %s",compute_match_key)
    end

    # return updated struct
    return workspace

end

# List the catalogs within a workspace
function list_catalogs(workspace)

    # Sending the request
    catalog_response = HTTP.get(
        "$host_name/api/2.1/unity-catalog/catalogs"
        ,header
        ,query = ["max_results" => "0"]
    )

    # Parsing the body
    catalogs_parsed = JSON3.read(catalog_response.body)
    catalog_tuple = [(
                        name            = c[:name]
                        ,full_name      = c[:full_name]
                        ,id             = c[:id]
                        ,owner          = c[:owner]
                        ,created_date   = c[:created_at]
                        ,created_by     = c[:created_by]
                        ) 
                    for c in catalogs_parsed[:catalogs]
                    ]
    # Creating a Dataframe                
    cat_df = DataFrame(catalog_tuple)

    # Add option to add DataFrame to struct rather than recreate it

    # Printing the catalog names
    print("These are the catalogs in your workspace:")
    for c in catalogs_parsed[:catalogs]
        @printf("%s \n", c[:name])
    end

end

# List the Schemas within a catalog
function list_schemas(workspace)

    # sending he request
    schema_response = HTTP.get(
        "$host_name/api/2.1/unity-catalog/schemas"
        ,header
        ,query = ["max_results" => "0"]
    )

    # Parsing he body
    schemas_parsed = JSON3.read(schema_response.body)
    catalog_tuple = [(
                        name            = c[:name]
                        ,full_name      = c[:full_name]
                        ,id             = c[:id]
                        ,owner          = c[:owner]
                        ,created_date   = c[:created_at]
                        ,created_by     = c[:created_by]
                        ) 
                    for c in catalogs_parsed[:catalogs]
                    ]

end

function query_db(workspace :: BricksterClient, query :: String, schema :: String, catalog :: String)

    # Params 
    body = JSON3.write(Dict(
        "statement"    => sql,
        "warehouse_id" => client.compute,       # from your compute_connect step
        "catalog"      => catalog,
        "schema"       => schema,
        "wait_timeout" => "30s",                # wait up to 30s for results
        "disposition"  => "INLINE"              # return results directly in response
    ))
# Sending the request to Databricks
response = HTTP.post(
    "$host/api/2.0/sql/statements"
    ,header

)


# Creating a DataFrame

end


end # Module end