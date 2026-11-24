## Functions
"""
    list_catalogs(workspace :: BricksterClient, return_tuple :: Bool = false)

This function will list the catalogs that are present in a workspace

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
"""
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

"""
    list_schemas(workspace :: BricksterClient, catalog :: String, return_tuple :: Bool = false)

This function will list the schemas present within a catalog. 

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `catalog`: The name of the catalog that you want to list schemas from
"""
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

"""
    list_tables(workspace :: BricksterClient
                        ,catalog :: String
                        ,schema :: String
                        ,omit_properties :: Bool = true
                        ,return_tuple :: Bool = true )

This function will list the tables present within a schema. 

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `catalog`: The name of the catalog that you want to list schemas from
- `schema`: The schema where you want to see the tables from
- `omit_properties`: Default, true. This will hide the properties associated with the table
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


"""
    list_computes(workspace :: BricksterClient)

Lists the computes that exists in a workspace into the console

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
"""
function list_computes(workspace :: BricksterClient)
    # Printing compute names
    @printf("These are the available computes in your warehouse: %s \n", values(workspace.warehouse_map))

    # TODO: Create DataFrame or Vector of computes

end
