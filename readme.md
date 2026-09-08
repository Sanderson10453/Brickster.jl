[![CI](https://github.com/Sanderson10453/Brickster.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/Sanderson10453/Brickster.jl/actions/workflows/CI.yml)

# Overview
Brickster is a library written for R that includes:
    - Wrappers for Databricks APIs
    - ODBC Connections
    - Other tools for using Databricks from R

Currently, similar functionality is lacking in Julia - this library brings some of this functionality to Julia.

# Installation
Within the Julia REPL:
```
pkg> add Brickster

julia> using Brickster

```


## Basics
1. Trying to connect to a warehouse and list available computes
```
# Import
using Brickster

# Create the client
client = Brickster(token, host_name)

# List the computes
list_computes(client)

# Connect to a specific compute
con = connect_compute(client, "Serverless")

# Create a dataframe from databricks query
query = "select * from test_catalog.test_schema.table limit 10"
df = query_db(client, query, "test_schema", "test_catalog)
```



## API Coverage

| API | Available | Version | 
|-----|-----------|---------|
| Clusters | Yes | 0.1 |
| Unity Catalog - Catalogs | Yes | 0.1 |
| Unity Catalog - Schemas | Yes | 0.1 |
| SQL Statements | Yes | 0.1 |
| Volumes | No | N/A | 
