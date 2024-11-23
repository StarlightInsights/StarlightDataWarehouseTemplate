# Snowflake Setup

How to set up Snowflake.

## Architectural Overview

### Databases

You will mainly have two database types: one analytical and one per data loader.

**The analytical database** will store the schemas for dbt development and the schemas for your production datawarehouse.

If you have multiple dbt projects, then have one database for each dbt project.

**The data loader** databases will store raw data from your data loaders.

Each data loader will have one database.

#### Schemas

**In the analytical database,** you should have one schema per developer and one production schema.

**In the data loader database,** you should have one schema per source system.

#### Database example

```text
finance <- database
 - datawarehouse <- schema
 - dbt_developer_1
 - dbt_developer_2
marketing
 - datawarehouse
 - dbt_developer_1
 - dbt_developer_2
fivetran
 - google_sheets
 - google_analytics
airbyte
 - business_central
```

### Warehouses

There can be performance and cost optimization possibilities with having fewer warehouses.

As a rule of thumb, you should only split into multiple warehouses if you have a reason.

The main reason being that you want to track and limit spending.

Often you want to have a warehouse for production, development, for each data loader, and for each BI tool.

#### Warehouse example

```text
production <- warehouse
development
fivetran
airbyte
powerbi
lightdash
```

### Resource Monitors

Have one resource monitor for the account and one for each warehouse.

### Users and Roles

Each developer and system should have its own user.

Have one developer role and one role for every system.

#### Users and roles example

```text
developer <- role
 - developer_1 <- user
 - developer_2
github
 - github
fivetran
 - fivetran
airbyte
 - airbyte
powerbi
 - powerbi
lightdash
 - lightdash
```

## STATEMENT_TIMEOUT_IN_SECONDS

Snowflake has a rare bug where queries will keep running and continue incurring costs.

By setting `STATEMENT_TIMEOUT_IN_SECONDS` you can cap the max runtime and avoid overspending.

```sql
use role accountadmin;
alter account set STATEMENT_TIMEOUT_IN_SECONDS = 3600;  -- one hour
show parameters like 'STATEMENT_TIMEOUT_IN_SECONDS';
```

## Analytical database and dbt

## Data loader

## Developers

## BI tools

## GitHub Action
