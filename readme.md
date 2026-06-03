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
```