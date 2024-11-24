# Snowflake setup

How to set up Snowflake.

## Architectural overview

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

### Resource monitors

Have one resource monitor for the account and one for each warehouse.

### Users and roles

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

### BI tools

Handling permissions for BI tools is somewhat challenging due to the limitations of permissions in Snowflake and the interaction between Snowflake and dbt.

Generally, you have three options, each with its own drawbacks.

**1. Grant total permission to the data warehouse schema for the BI tool.** This requires that the BI tool can manage the permissions appropriately.

**2. The BI tool will only have access to views.** Materialize all dbt models as tables, except for those that the BI tool should access. Those should be materialized as views.

**3. Use [dbt grants](https://docs.getdbt.com/reference/resource-configs/grants).**

## Account

Set a resource monitor on the account level.

```sql
use role accountadmin;
create or replace resource monitor account_level
credit_quota = 100
frequency = 'monthly' 
start_timestamp = 'immediately'
triggers 
    on 95 percent do suspend 
    on 100 percent do suspend_immediate 
    on 80 percent do notify;

alter account set resource_monitor = account_level;
```

### STATEMENT_TIMEOUT_IN_SECONDS

Snowflake has a rare bug where queries will keep running and continue incurring costs.

By setting `STATEMENT_TIMEOUT_IN_SECONDS` you can cap the max runtime and avoid overspending.

```sql
use role accountadmin;
alter account set STATEMENT_TIMEOUT_IN_SECONDS = 3600;  -- one hour
show parameters like 'STATEMENT_TIMEOUT_IN_SECONDS';
```

## Developers

### Create developers

```sql
use role accountadmin;

create warehouse if not exists developer
    warehouse_size = small
    auto_suspend = 120
    auto_resume = true
    initially_suspended = true;

create or replace resource monitor developer
with 
  credit_quota = 50
  frequency = monthly
  start_timestamp = immediately
  triggers
    on 80 percent do notify
    on 90 percent do suspend
    on 100 percent do suspend_immediate;
alter warehouse developer set resource_monitor = 'DEVELOPER';

create role if not exists developer;
grant role developer to role accountadmin;

grant usage on warehouse developer to role developer;
```

### Remove developers

```sql
use role accountadmin;
drop resource monitor if exists developer;
drop warehouse if exists developer;
drop role if exists developer;
```

## GitHub Action

### Create GitHub Action

```sql
use role accountadmin;

create warehouse if not exists github
    warehouse_size = small
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;

create or replace resource monitor github
with 
  credit_quota = 50
  frequency = monthly
  start_timestamp = immediately
  triggers
    on 80 percent do notify
    on 90 percent do suspend
    on 100 percent do suspend_immediate;

alter warehouse github set resource_monitor = 'GITHUB';

create role if not exists github;
grant role github to role accountadmin;

grant usage on warehouse github to role github;

create user if not exists github
    must_change_password = false
    password = '' -- set password
    default_role = 'github'
    default_warehouse = 'github';

grant role github to user github;
```

### Remove GitHub Action

```sql
drop resource monitor if exists github;
drop warehouse if exists github;
drop role if exists github;
drop user if exists github;
```

## Analytical databases

### Create analytical databases

```sql
use role developer;
set database_name = 'finance';
--set database_name = 'marketing';
create database if not exists identifier($database_name);
set database_schema = concat($database_name, '.datawarehouse');
create schema if not exists identifier($database_schema);
grant ownership on database finance to role developer;
```

### Remove analytical databases

```sql
use role developer;
drop database finance;
drop database marketing;
```

## Data loader

A common approach to handling data loader databases is to assign the data loader role as the owner of the database.

### Setup data loader

```sql
use role accountadmin;
set dataloader = 'fivetran';
--set dataloader = 'airbyte';
set password = '<long_password_min_20_characters>';  -- don't store password in GitHub

create warehouse if not exists identifier($dataloader)
    warehouse_size = xsmall
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;
    
create database if not exists identifier($dataloader);
create role if not exists identifier($dataloader);
create user if not exists identifier($dataloader)
    must_change_password = false
    password = $password
    default_role = $dataloader
    default_warehouse = $dataloader
    default_namespace = $dataloader;

grant role identifier($dataloader) to user identifier($dataloader);
grant ownership on database identifier($dataloader) to role identifier($dataloader);
grant usage on warehouse identifier($dataloader) to role identifier($dataloader);

create or replace resource monitor identifier($dataloader)
with 
  credit_quota = 50
  frequency = monthly
  start_timestamp = immediately
  triggers
    on 80 percent do notify
    on 90 percent do suspend
    on 100 percent do suspend_immediate;
set upper_warehouse = upper($dataloader);
alter warehouse identifier($dataloader) set resource_monitor = $upper_warehouse;
```

### Remove data loader

```sql
use role accountadmin;
set dataloader = 'fivetran';
--set dataloader = 'airbyte';
grant ownership on database identifier($dataloader) to role accountadmin;
drop database if exists identifier($dataloader);
drop resource monitor if exists identifier($dataloader);
drop warehouse if exists identifier($dataloader);
drop role if exists identifier($dataloader);
drop user if exists identifier($dataloader);

```

## BI tools scripts

### Create BI tools

```sql
use role accountadmin;
set bitool = 'powerbi';
--set bitool = 'lighdash';
set password = '<long_password_min_20_characters>';  -- don't store password in GitHub

create warehouse if not exists identifier($bitool)
    warehouse_size = xsmall
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;

create or replace resource monitor identifier($bitool)
with 
  credit_quota = 50
  frequency = monthly
  start_timestamp = immediately
  triggers
    on 80 percent do notify
    on 90 percent do suspend
    on 100 percent do suspend_immediate;
set upper_warehouse = upper($bitool);
alter warehouse identifier($bitool) set resource_monitor = $upper_warehouse;

create role if not exitsts identifier($bitool);
create user if not exists identifier($bitool)
    must_change_password = false
    password = $password
    default_role = $bitool
    default_warehouse = $bitool
    default_namespace = $bitool;
grant role identifier($bitool) to user identifier($bitool);
grant usage on warehouse identifier($bitool) to role identifier($bitool);
```

### Remove BI tools

```sql
use role accountadmin;
set bitool = 'powerbi';
--set bitool = 'lighdash';
drop resource monitor if exists identifier($bitool);
drop warehouse if exists identifier($bitool);
drop role if exists identifier($bitool);
drop user if exists identifier($bitool);

```

### 1. Grant total permission to the data warehouse schema for the BI tool

```sql
use role accountadmin;
set bitool = 'powerbi';



```


### 2. The BI tool will only have access to views
