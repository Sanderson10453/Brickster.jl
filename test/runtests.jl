### Import Modules
using Test
using Mocking
using Brickster

### Setting up Mocking and fake data

Mocking.activate()

## Fake Data 
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
fake_results = Dict(
    name            = fake_catalog[:name]
    ,full_name      = fake_catalog[:full_name]
    ,id             = fake_catalog[:id]
    ,owner          = fake_catalog[:owner]
    ,created_at     = fake_catalog[:created_at]
    ,created_by     = fake_catalog[:created_by]
        )

# HTTP Result

result = Dict(
            "status"                => Dict("state" => "SUCCEEDED")
            ,"manifest"             => Dict(
                                            "schema" => Dict(
                                                "columns" => [
                                                    Dict("name" => "id")
                                                    ,Dict("name" => "name")
                                                            ]
                                                            )
                                            )
            ,"result"               => Dict(

                                            )


        
        )


### Start Test
@testset "BricksterClient" begin
    
    ## Testing the string searches
    @testset "compute matching regexes" begin

        @test occursin(Regex("serverless", "i"), "serverless Starter Warehouse")
        @test occursin(Regex("SERVERLESS", "i"), "serverless Starter Warehouse")
        @test !occursin(Regex("serverless", "i"), "SQL Pro Warehouse")
        
    end
    
    ## Testing the tuple comprehension
    @testset "catalog matching tuples" begin
        
        
        # Running tests to check
        @test result.name == "catalog123"
        @test result.owner == "user1"
        @test result.created_by == "governance@fakedatabricks.net"
    end
        

    ## Testing whether errors are thrown correctly
    @testset "query_db function error tests" begin
        
        # Fake data
        fake_token = "token123"
        fake_db = BricksterClient(
            token           = fake_token
            ,host_name      = "https://thisisnotdatabricks.net"
            ,header         = ["Authorization" => "Bearer $fake_token"]
            ,warehouse_map  = Dict("fakewarehouse123" => "Serverless Warehouse")
            ,compute        = nothing
        )
        
        fake_query = "select * from dummycatalog.fauxschema.badtable limit 10"

        @test_throws ErrorException query_db(fake_db, fake_query, "dummycatalog", "fauxschema   ")
    end
    
end

### Testing the requests
@testset "HTTP function tests" begin
    
    ## Proper Ttesting of BricksterClient constructor
    @testset "BricksterClient constructor test" begin
        
    end
end
