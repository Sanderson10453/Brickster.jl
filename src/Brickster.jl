module Brickster

# Import modules
using HTTP
using JSON3
using Printf
using DataFrames

# Functions to be used
export BricksterClient, list_computes, compute_connect, list_catalogs, list_schemas, list_tables, query_db

# Creating a struct to pass objects
Base.@kwdef mutable struct BricksterClient
    token :: String         # Required keyword
    host_name :: String     # Required keyword
    header :: Vector{Pair{String, String}}         # Required keyword
    warehouse_map :: Dict
    compute :: Union{String, Nothing} = nothing
end

"""
    _parse_field(field)

An internal method used to parse string and dict fields that
are returned from the Databricks api

# Arguments
- `field`: This is the field that will be formatted

# Returns
- The values of the field as a string
"""
function _parse_field(field)
    if field isa JSON3.Object
        return field[:str]

    elseif isnothing(field) # Dealing wirth null values from Databricks
        return missing

    else
        return String(field)
    end

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
    query_db(workspace :: BricksterClient
                    ,sql_query :: String
                    ,catalog :: String
                    ,schema :: String
                    )

This function will pull data from a databricks table. It will try to pull the data inline
before switching to use external links for large data pulls. The output will be a Julia DataFrame

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `sql_query`: The sql query for the data you want to pull
- `catalog`: The catalog where you want to see the tables from
- `schema`: The schema where you want to see the tables from

# Returns
- A DataFrame.jl dataframe
"""
function query_db(workspace :: BricksterClient
                    ,sql_query :: String
                    ,catalog :: String
                    ,schema :: String
                    )

    # Error if No Compute
    if isnothing(workspace.compute)
        error("No compute selected - please run compute_connect()")
    end

    ## Params
    byte_lim = 25000000

    ## Attempt 1: Testing whether inline will work
    statement_id = _create_response(workspace, sql_query, catalog, schema, "INLINE"; byte_limit  = byte_lim)

    # Polling the response
    parsed_response = _query_db_poll_for_success(workspace, statement_id)

    ## Creating a DataFrame
    # Checking if empty
    if getproperty(parsed_response.manifest, :total_row_count) == 0
        println("Query returned no results...")
        return DataFrame()
    end

    ## Checking if the results are truncated
    if !get(parsed_response.manifest, :truncated, false)

        # Read the data frame and return
        df_cols = [col[:name] for col in parsed_response[:manifest][:schema][:columns]]
        df_rows = [[_parse_field(field) for field in row] for row in parsed_response[:result][:data_array]]

        return DataFrame([col => [row[i] for row in df_rows] for (i, col) in enumerate(df_cols)])

    end

        ## Attempt 2: If external links needed
        statement_id = _create_response(workspace, sql_query, catalog, schema, "EXTERNAL_LINKS")

        # Parsing the results
        # parsed_response = JSON3.read(response.body)

        # Polling to get results
        parsed_response = _query_db_poll_for_success(workspace, statement_id)

            return _query_db_lf(workspace, parsed_response)

end

"""
    _query_db_poll_for_success(workspace :: BricksterClient, statement_id :: String, interval :: Float64 = 2.0)

This internal function will send GET request until the request has successfully completed. At this point,
it will use the last statement_id to grab data.

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `statement_id`: The initial statement_id from your request
- `interval`: The wait interval
"""
function _query_db_poll_for_success(workspace :: BricksterClient, statement_id :: String, interval :: Float64 = 2.0)
    ### Starting the polling loop
    while true

        # Checking to see if the data is available for the query
        poll_response = HTTP.get(
            "$(workspace.host_name)/api/2.0/sql/statements/$statement_id"
            ,workspace.header
        )

        ## Parsing the results
        parsed_response = JSON3.read(poll_response.body)

        # If we get a successful status, return data
        if getproperty(parsed_response.status, :state) == "SUCCEEDED"
                return parsed_response

        # If it's still running, try again shortly
        elseif getproperty(parsed_response.status, :state) in ("PENDING", "RUNNING")
            @printf("Query still incomplete - waiting %.1fs...\n", interval)
            sleep(interval)

        # For failed, cancelled, or closed statuses
        else
            if haskey(parsed_response.status, :error)
                error_message = parsed_response.status.error.message
            else
                error_message = "Query $(parsed_response.status.state) errored out without a message"
            end
            # Raising error
            error(error_message)
        end
    end
end

"""
    _fetch_rows(links)

Downloads every row from the external s3 links 

# Arguments
- `links`: These are the external signed urls
"""
function _fetch_rows(links)
    
    ## Attributes
    rows = []
    for info in links

        # Appending the rows to the list
        append!(rows, JSON3.read(HTTP.get(info.external_link).body))
    end

    return rows

end

"""
    _query_db_lf(workspace :: BricksterClient, parsed_response)

This internal function will get the results JSON from Databricks and turn it into a dataframe.

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `parsed_response`: The JSON3 object response

# Returns
- A DataFrame.jl dataframe
"""
function _query_db_lf(workspace :: BricksterClient, parsed_response)

    # Params
    statement_id = parsed_response.statement_id
    data = []

    # Catching cases when successful but no data - pretty frustrating error
    if parsed_response.manifest.total_chunk_count == 0 || isempty(parsed_response.result)
        error("Statement $statement_id succeeded but returned no chunks " *
              "(rows=$(parsed_response.manifest.total_row_count), truncated=$(parsed_response.manifest.truncated))")
    end

    # Grabbing links for external data - MAKE A HELPER
    links = get(parsed_response.result, :external_links, nothing)

    # Catching errors when there's no links but the result came back successful
    if isnothing(links)
        error("No external_links in parsed_response results. The following keys exist: $(keys(parsed_response.result))")
    end

    # Need col names from first chunk header
    df_cols = [col[:name] for col in parsed_response[:manifest][:schema][:columns]]

    # Grabbing first chunk of data
    data = _fetch_rows(links)

    ## Checking for more chunks
    next_chunk = get(parsed_response.result, :next_chunk_index, nothing)

    # If there are more chunks, grab them
    while !isnothing(next_chunk)
        chunk_res = HTTP.get("$(workspace.host_name)/api/2.0/sql/statements/$statement_id/result/chunks/$next_chunk"
                            ,workspace.header
                            )
        chunk_parsed = JSON3.read(chunk_res.body)

        # Creating list of data - MAKE A HELPER
        append!(data, _fetch_rows(chunk_parsed.external_links))

        next_chunk = get(chunk_parsed, :next_chunk_index, nothing)
    end

    # Grabbing dataframe rows
    df_rows = [[_parse_field(field) for field in row] for row in data]

    return DataFrame([col => [row[i] for row in df_rows]
                        for (i, col) in enumerate(df_cols) ])
end

"""
    _create_response(workspace :: BricksterClient, query :: String, catalog :: String, schema :: String, disposition :: String; byte_limit = nothing)

This internal function will create the request params and then send them to get the initial response

# Arguments
- `workspace`: This is the workspace object created from BricksterClient
- `query`: The query string used to pull data
- `schema`: The schema we are pulling data from
- `disposition`: Whether to use an INLINE or EXTERNAL_LINKS disposition for the request params

# Returns
- The response statement_id
"""
function _create_response(workspace :: BricksterClient, query :: String, catalog :: String, schema :: String, disposition :: String; byte_limit = nothing)
    ## Attributes
    # Request body
    params = Dict{String,Any}(
        "statement"         => query
        ,"warehouse_id"     => workspace.compute
        ,"catalog"          => catalog
        ,"schema"           => schema
        ,"wait_timeout"     => "0s"
        ,"on_wait_timeout"  => "CONTINUE"
        ,"disposition"      => disposition
        ,"format"           => "JSON_ARRAY"
                    )
    
    # Adding byte limit if it is not nothing
    if !isnothing(byte_limit)
        params["byte_limit"] = byte_limit 
    end

    # Transforming the dict to a json object
    params = JSON3.write(params)

    ## Creating the request
    response = HTTP.post(
        "$(workspace.host_name)/api/2.0/sql/statements"
        ,workspace.header
        ,params
        )
    return JSON3.read(response.body).statement_id
end

function _build_dataframe(cols, rows)
    df_rows = [[_parse_field(field) for field in row] for row in data]
    return DataFrame([col => [row[i] for row in rows]
                        for (i, col) in enumerate(cols) ])
end

end # Module end
