module Attributes

## Import Modules
using HTTP
using JSON3
using Printf

## Exported modules


## Functions
"""This function will list the warehouses in a databricks workspace"""
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

"""This method will list all the computes for a workspace."""
function list_computes(workspace :: BricksterClient)
    # Printing compute names
    @printf("These are the available computes in your warehouse: %s \n", values(workspace.warehouse_map))

    # TODO: Create DataFrame or Vector of computes

end
"""This method will list the catalogs within a workspace"""
function list_catalogs(workspace :: BricksterClient
                        ,return_tuple :: Bool = false)

    # Sending the request
    catalog_response = HTTP.get(
        "$(workspace.host_name)/api/2.1/unity-catalog/catalogs"
        ,workspace.header
        ,query = ["max_results" => "0"]
    )

    # Parsing the body
    catalogs_parsed = JSON3.read(catalog_response.body)

    if return_tuple

        return [(
                            name            = c[:name]
                            ,full_name      = c[:full_name]
                            ,id             = c[:id]
                            ,owner          = c[:owner]
                            ,created_date   = c[:created_at]
                            ,created_by     = c[:created_by]
                            )
                        for c in catalogs_parsed[:catalogs]
                        ]
    else
        # Printing the catalog names
        println("These are the catalogs in your workspace:")

        for c in catalogs_parsed[:catalogs]
            @printf("%s \n", c[:name])
        end
    end

end
"""This method lists the schema present in a workspace"""
function list_schemas(workspace :: BricksterClient
                        ,catalog :: String
                        ,return_tuple :: Bool = false)

    # sending the request
    schema_response = HTTP.get(
        "$(workspace.host_name)/api/2.1/unity-catalog/schemas"
        ,workspace.header
        ,query = [
                    "catalog_name" => "$catalog"
                    ,"max_results" => "0"
                ]
    )

    # Parsing the body
    schemas_parsed = JSON3.read(schema_response.body)

    # Creating tuple if arg
    if return_tuple
        return  [(
                            name            = sch[:name]
                            ,full_name      = sch[:full_name]
                            ,id             = sch[:schema_id]
                            ,owner          = sch[:owner]
                            ,created_date   = sch[:created_at]
                            ,created_by     = sch[:created_by]
                            )
                        for sch in schemas_parsed[:schemas]
                        ]

    else
        println("These are your schemas:")

        for sch in schemas_parsed[:schemas]
            @printf("%s \n", sch[:name])
        end
    end
end

"""This method lists the tables associated with a workspace.
"""
function list_tables(workspace :: BricksterClient
                        ,catalog :: String
                        ,schema :: String
                        ,omit_properties :: Bool = true
                        ,return_tuple :: Bool = true )

    # sending he request
    tables_response = HTTP.get(
        "$(workspace.host_name)/api/2.1/unity-catalog/tables"
        ,workspace.header
        ,query = [
                    "catalog_name" => "$catalog"
                    ,"schema_name" => "$schema"
                    ,"omit_properties" => "$omit_properties"
                    ,"max_results" => "0"
                ]
    )

    # Parsing the body
    tables_parsed = JSON3.read(tables_response.body)

    # Printing them
    println("These are the tables in the $catalog catalog...")
    for tbl in tables_parsed[:tables]
        @printf("%s \n", tbl[:full_name])
    end

    if return_tuple
        # Creating the tuple
        return [(
                            name            = tbl[:name]
                            ,full_name      = tbl[:full_name]
                            ,id             = tbl[:table_id]
                            ,owner          = tbl[:owner]
                            ,created_date   = tbl[:created_at]
                            ,created_by     = tbl[:created_by]
                )
                for tbl in tables_parsed[:tables]
                ]

        end
end


"""This method will connect a user to a specific compute. Further, it will update the compute associated with the module."""
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


end
