# Overview
Brickster is a library written for R that includes:
    - Wrappers for Databricks APIs
    - ODBC Connections

We want to create the same functionality within Julia.


## Examples
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

df = con
```

2. Listing the available tables within a schema
```
# Assuming you are using the same client as above
list_tables(client, "test_catalog", "test_schema")

# if you would like a tuple of tables
tbl_tuple = list_tables(client, "test_catalog", "test_schema")
```


3. Selecting data via a query



## Feature List
1. List warehouse computes
    - COMPLETE
2. List workspace catalogs
    - COMPLETE
3. Get data from catalogs with query
    - COMPLETE
4. Read from volume
5. Upload to volume