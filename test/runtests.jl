### Import Modules
using Test
using HTTP
using JSON3
using DataFrames
using Brickster

## Helper Function 
function fake_response(body :: Dict)
    return HTTP.Response(
        200
        ,["Content-Type" => "application/json"]
        ,JSON3.write(body)
    )
end

## Fake Data 
fake_token = "token123"
fake_url      = "http://127.0.0.1:8080"
fake_query = "select * from dummycatalog.fauxschema.badtable limit 10"

# Warehouse 
fake_warehouse_pl = Dict(
                    "warehouses" => [Dict("id" => "w123"
                                            ,"name" => "Serverless Starter Warehouse")
                                    ,Dict("id" => "w234"
                                            ,"name" => "SQL Pro Warehouse")

                                    ]
                        )
# Catalog
fake_catalog = Dict(
                :name           => "catalog123"
                ,:full_name     => "catalog123"
                ,:id            => "c123"
                ,:owner         => "user1"
                ,:created_at    => "2026-07-01"
                ,:created_by    => "governance@fakedatabricks.net"
                    )

# Table
fake_tables = Dict(
                "tables" => [
                    Dict(
                        "name"          => "table123"
                        ,"full_name"    => "catalog123.schema123.table123"
                        ,"table_id"     => "123abc"
                        ,"owner"        => "user1"
                        ,"created_at"   => "2026-07-01"
                        ,"created_by"   => "governance@fakedatabricks.net"   
                        )
                        
                        ]
                    
                )
# Result 
fake_results_tuple = (
    name            = fake_catalog[:name]
    ,full_name      = fake_catalog[:full_name]
    ,id             = fake_catalog[:id]
    ,owner          = fake_catalog[:owner]
    ,created_at     = fake_catalog[:created_at]
    ,created_by     = fake_catalog[:created_by]
                    )


# Fake Schema Payload
fake_schemas_pl = Dict(
                    "schemas" => [
                        Dict(
                            "name"          => "schema123"
                            ,"full_name"    => "catalog123.schema123"
                            ,"schema_id"     => "s123"
                            ,"owner"        => "user1"
                            ,"created_at"   => "2026-07-01"
                            ,"created_by"   => "governance@fakedatabricks.net"   
                            )
                        
                                ]
                        ) 

# Fake HTTP payload
fake_result = Dict(
            "status"        => Dict("state" => "SUCCEEDED")
            ,"manifest"     => Dict("schema" => Dict(
                                                "columns" => [
                                                    Dict("name" => "id")
                                                    ,Dict("name" => "name")
                                                            ]
                                                        )
                                    )
            ,"result"       => Dict("data_array" => [[Dict("str" => "1"), Dict("str" => "User234")]
                                                    ,[Dict("str" => "2"), Dict("str" => "User345")]]
                                    )
                    )

## Setting up HTTP to route through local server for testing
const ROUTER = HTTP.Router()

# Warehouses api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.0/sql/warehouses"
                ,req -> fake_response(fake_warehouse_pl))

# Schemas api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.1/unity-catalog/schemas"
                ,req -> fake_response(fake_schemas_pl))

# Query api
HTTP.register!(ROUTER
                ,"POST"
                ,"/api/2.0/sql/statements"
                ,req -> fake_response(fake_result))

server = HTTP.serve!(ROUTER, "127.0.0.1", 8080)

### Start Test
@testset "BricksterClient" begin
    
    ## Testing the string searches
    @testset "Compute matching regexes" begin

        @test occursin(Regex("serverless", "i"), "serverless Starter Warehouse")
        @test occursin(Regex("SERVERLESS", "i"), "serverless Starter Warehouse")
        @test !occursin(Regex("serverless", "i"), "SQL Pro Warehouse")
        
    end
    
    ## Testing the tuple comprehension
    @testset "Catalog matching tuples" begin
        
        # Running tests to check
        @test fake_results_tuple.name == "catalog123"
        @test fake_results_tuple.owner == "user1"
        @test fake_results_tuple.created_by == "governance@fakedatabricks.net"
    end
        

    ## Testing whether errors are thrown correctly
    @testset "Query_db function error tests" begin
        
        # Fake data
        fake_db = BricksterClient(
            token           = fake_token
            ,host_name      = fake_url
            ,header         = ["Authorization" => "Bearer $fake_token"]
            ,warehouse_map  = Dict("fakewarehouse123" => "Serverless Starter Warehouse")
            ,compute        = nothing
        )

        @test_throws ErrorException query_db(fake_db, fake_query, "dummycatalog", "fauxschema")
    end
    
end

### Testing the requests
@testset "HTTP function tests" begin
    
    ## Proper Ttesting of BricksterClient constructor
    @testset "BricksterClient constructor test" begin
            databricks_client = BricksterClient(fake_token, fake_url)

            @test databricks_client.token == "token123"
            @test databricks_client.host_name == "http://127.0.0.1:8080"
            @test databricks_client.warehouse_map["w123"] ==  "Serverless Starter Warehouse"
            @test isnothing(databricks_client.compute)
    end

    ## Testing connecting to compute
    @testset "Compute connect test" begin
            databricks_client = BricksterClient(fake_token, fake_url)
            compute_connect(databricks_client, "Serverless")

            @test databricks_client.compute == "w123"
            @test_throws ErrorException compute_connect(databricks_client, "ThisIsNotACompute")
    end

    ## Testing the list schemas with fake requests
    @testset "List schemas tests" begin
            databricks_client = BricksterClient(token = fake_token
                                                ,host_name = fake_url
                                                ,header = ["Authorization" => "Bearer $fake_token"]
                                                ,warehouse_map = Dict("w123" => "Serverless Starter Warehouse")
                                                ,compute = "co123")

            result = list_schemas(databricks_client, "catalog123", true)

            # Test to ensure schema list is as expected
            @test result[1].name == "schema123"
            @test result[1].full_name == "catalog123.schema123"
    end

    # Testing the query with fake requests
    @testset "Query_db returns DF test" begin

            databricks_client = BricksterClient(fake_token, fake_url)
            compute_connect(databricks_client, "Serverless")

            # Creating DataFrame 
            df = query_db(databricks_client, fake_query, "fauxschema", "dummycatalog")
            
            # Test
            @test df isa DataFrame
        
    end

    # Closing the local server
    close(server)
end
