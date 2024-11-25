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

#### MFA and key pair

It is highly recommended to enforce MFA (Multi-Factor Authentication) for all Snowflake users that belong to a person.

For system users, it is recommended to use a **[key pair](https://docs.snowflake.com/en/user-guide/key-pair-auth)** instead of a password. Unfortunately, many tools that connect to Snowflake do not support key pair authentication.

### BI tools

Handling permissions for BI tools is somewhat challenging due to the limitations of permissions in Snowflake and the interaction between Snowflake and dbt.

Generally, you have three options, each with its own drawbacks.

**1. Grant total permission to the data warehouse schema for the BI tool.** This requires that the BI tool can manage the permissions appropriately.

**2. The BI tool will only have access to views.** Materialize all dbt models as tables, except for those that the BI tool should access. Those should be materialized as views.

**3. Use [dbt grants](https://docs.getdbt.com/reference/resource-configs/grants).**

The dbt grant approach is recommended since it follows the principle of least privilege.

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

### allow_client_mfa_caching

By setting `allow_client_mfa_caching` to **true**, you can enforce MFA at the user level without requiring the user to authenticate multiple times during a `dbt run`.

```sql
alter account set allow_client_mfa_caching = true;
```

### Require MFA

```sql
use role accountadmin;
create database snowflake_policies;
create schema snowflake_policies.authentication_policies;
create authentication policy if not exists snowflake_policies.authentication_policies.require_mfa
    mfa_enrollment = required;
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

## Developer

### Create developer

```sql
use role accountadmin;
set username = '';  -- don't store in GitHub
set email = '';  -- don't store in GitHub
set password = '<long_password_min_20_characters>';  -- don't store in GitHub

create user if not exists identifier($username)
    type = person
    must_change_password = true
    password = $password
    email = $email
    default_role = developer
    default_warehouse = developer
    default_namespace = developer;

alter user identifier($username)
    set authentication_policy = require_mfa;

grant role developer to user identifier($username);
```

### Remove developer

```sql
use role accountadmin;
set username = '';  -- don't store in GitHub
drop user if exists identifier($username);
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
    type = service
    default_role = github
    default_warehouse = github;

alter user github
set rsa_public_key = '-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuW9q7WSUZK+NsZGe59uU
57P0XMS2KDKtBTK8sPj+yzseAdAgM8aPMgAug8zAd+Ct83BL+mBfqICb3mlFYYRg
dzWjRR2CY3dL2NlsvHyc9qunLaAf1MmW8cb5un69IX7S3cnX+R6+sFL5STmHUDq3
ztBlPOo5qy+SzahleMB+zKi23KK9RKUsUdZuIoQmBUdLen++aOhTJwdMUwIqk4UY
7x77h00Ho06/DvlQqpl1YCjB691OM6ncnf3mGQpAZGBJJfOuYw1FgCS85ytpE70S
FberUOhoeFMkjGvG45AiTNJFDFZyD4NUMN8CFfvoi8Pq3qzxc4cnHfZ+xncxC5RJ
lQIDlQA1
-----END PUBLIC KEY-----';

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

create warehouse if not exists identifier($dataloader)
    warehouse_size = xsmall
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;
    
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

create database if not exists identifier($dataloader);
create role if not exists identifier($dataloader);
create user if not exists identifier($dataloader)
    type = service
    default_role = $dataloader
    default_warehouse = $dataloader
    default_namespace = $dataloader;

alter user identifier($dataloader)
set rsa_public_key = '-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuW9q7WSUZK+NsZGe59uU
57P0XMS2KDKtBTK8sPj+yzseAdAgM8aPMgAug8zAd+Ct83BL+mBfqICb3mlFYYRg
dzWjRR2CY3dL2NlsvHyc9qunLaAf1MmW8cb5un69IX7S3cnX+R6+sFL5STmHUDq3
ztBlPOo5qy+SzahleMB+zKi23KK9RKUsUdZuIoQmBUdLen++aOhTJwdMUwIqk4UY
7x77h00Ho06/DvlQqpl1YCjB691OM6ncnf3mGQpAZGBJJfOuYw1FgCS85ytpE70S
FberUOhoeFMkjGvG45AiTNJFDFZyD4NUMN8CFfvoi8Pq3qzxc4cnHfZ+xncxC5RJ
lQIDlQA1
-----END PUBLIC KEY-----';

grant role identifier($dataloader) to user identifier($dataloader);
grant ownership on database identifier($dataloader) to role identifier($dataloader);
grant usage on warehouse identifier($dataloader) to role identifier($dataloader);
```

**Specific for Fivetran:**

```sql
alter user fivetran set binary_input_format = 'BASE64';
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
set password = '<long_password_min_20_characters>';  -- don't store in GitHub

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
    default_warehouse = $bitool;
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
