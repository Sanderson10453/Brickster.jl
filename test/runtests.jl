### Import Modules
using Test
using HTTP
using JSON3
using DataFrames
using Brickster

## Helper Function
function fake_response(body)
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
# Fake Statements - one for the inline, one for external links, one for succeeded but empty
fake_columns = [Dict("name" => "id"), Dict("name" => "name")]
fake_schema = Dict("columns" => fake_columns)
fake_statement = Dict(
    "statement_inline"  => Dict(
            "statement_id"  => "statement_inline"
            ,"status"       => Dict("state" => "SUCCEEDED")
            ,"manifest"     => Dict("truncated" => false
                                    ,"total_row_count" => 2
                                    ,"schema" => fake_schema)
            ,"result"       => Dict("data_array" => [["1", "User234"], ["2", nothing]])
                            )

    ,"statement_empty" => Dict(
            "statement_id"  => "statement_empty"
            ,"status"       => Dict("state" => "SUCCEEDED")
            ,"manifest"     => Dict("truncated" => false
                                    ,"total_row_count" => 0
                                    ,"schema" => fake_schema)
            ,"result"       => Dict()
                                )
                                
    ,"statement_truncated" => Dict(
                "statement_id" => "statement_truncated"
                ,"status"      => Dict("state" => "SUCCEEDED")
                ,"manifest"    => Dict("truncated" => true
                                        ,"total_row_count" => 1
                                        ,"schema" => fake_schema)
                ,"result"      => Dict("data_array" => [["1", "User234"]])
                                )
    ,"statement_external" => Dict(
                "statement_id" => "statement_external"
                ,"status"      => Dict("state" => "SUCCEEDED")
                ,"manifest"    => Dict("truncated" => false
                                        ,"total_row_count" => 3
                                        ,"total_chunk_count" => 2
                                        ,"schema" => fake_schema)
                ,"result"      => Dict("external_links" => [Dict("external_link" => "$fake_url/fake-chunk-0")]
                                    ,"next_chunk_index" => 1)
                                )
    ,"statement_failed" => Dict(
                "statement_id" => "statement_failed"
                ,"status"      => Dict("state" => "FAILED"
                                        ,"error" => Dict("message" => "PARSE_SYNTAX_ERROR near select"))
                                )
)

# Fake External links chunks
fake_chunks = Dict(
    "fake-chunk-0"  => [["1", "User234"], ["2", "User345"]]
    ,"fake-chunk-1" => [["3", "User456"]]
)

## Setting up HTTP to route through local server for testing
const ROUTER = HTTP.Router()

# Warehouses api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.0/sql/warehouses"
                ,req -> fake_response(fake_warehouse_pl))

# Catalogs api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.1/unity-catalog/catalogs"
                ,req -> fake_response(Dict("catalogs" => [fake_catalog])))

# Schemas api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.1/unity-catalog/schemas"
                ,req -> fake_response(fake_schemas_pl))

# Tables api
HTTP.register!(ROUTER
                ,"GET"
                ,"/api/2.1/unity-catalog/tables"
                ,req -> fake_response(fake_tables))

# Query api
HTTP.register!(ROUTER
                ,"POST"
                ,"/api/2.0/sql/statements"
                ,req -> begin 
                    body = JSON3.read(String(req.body))
                    statement = body.statement

                    id = if occursin("--empty", statement)
                            "statement_empty"

                        elseif occursin("--failed", statement)
                            "statement_failed"

                        elseif occursin("--large", statement)
                            body.disposition == "INLINE"  ? "statement_trunc" : "statement_ext"

                        else 
                            "statement_inline"

                    end
                
                
                fake_response(Dict("statement_id" => id
                                    ,"status" => Dict("state" => "PENDING")))
                end)

# Test poll query 
for (id, pl) in fake_statement
    HTTP.register!(ROUTER
                    ,"GET"
                    ,"/api/2.0/sql/statements/$id"
                    ,req -> fake_response(pl))
end

# Second chunk of external links
 HTTP.register!(ROUTER
                    ,"GET"
                    ,"/api/2.0/sql/statements/statement_external/result/chunks/1"
                    ,req -> fake_response(Dict("external_link" => [Dict("external_link" => "$fake_url/fake-chunk-1")])))

for (name, rows) in fake_chunks
    HTTP.register!(ROUTER, "GET", "/$name", req -> fake_response(rows))
end


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
   @testset "Query_db tests" begin
        client = BricksterClient(fake_token, fake_url)
        compute_connect(client, "Serverless")
 
        @testset "Testing inline result" begin
            df = query_db(client, fake_query, "dummycatalog", "fauxschema")
 
            @test df isa DataFrame
            @test names(df) == ["id", "name"]
            @test size(df) == (2, 2)
            @test df.id == ["1", "2"]
            @test df.name[1] == "User234"
            @test ismissing(df.name[2])
        end
 
        @testset "Test what happens with an empty result" begin
            df = query_db(client, fake_query * " -- empty", "dummycatalog", "fauxschema")
 
            @test df isa DataFrame
            @test nrow(df) == 0
        end
 
        @testset "Test to ensure truncated inline falls back to external links disposition" begin
            df = query_db(client, fake_query * " -- large", "dummycatalog", "fauxschema")
 
            @test size(df) == (3, 2)
            @test df.id == ["1", "2", "3"]
            @test df.name == ["User234", "User345", "User456"]
        end
 
        @testset "Test that failed statement raises error" begin
            @test_throws "PARSE_SYNTAX_ERROR" query_db(client, fake_query * " -- failed", "dummycatalog", "fauxschema")
        end
    end
    
    # Close local server
    close(server)
end