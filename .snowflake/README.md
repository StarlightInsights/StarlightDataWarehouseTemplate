# Snowflake setup

## Architectural overview

### Databases

You will primarily work with two types of databases: one analytical database and one database per data loader.

**The analytical database** is managed by dbt.

If you have multiple dbt projects, then have one analytical database for each dbt project.

**The data loader databases** store raw data from data loaders.

Each data loader should have its own database.

#### Schemas

**In the analytical database,** use one schema per developer, one schema per PR for CI/CD, and one production schema.

**In the data loader database,** use one schema per source system.

#### Database example

```text
finance <- database
 - datawarehouse <- schema
 - dbt_developer_1
 - dbt_developer_2
 - github_pr_1
 - github_pr_2
marketing
 - datawarehouse
 - dbt_developer_1
 - dbt_developer_2
 - github_pr_1
 - github_pr_2
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
development <- warehouse
github
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
create database if not exists snowflake_policies;
create schema if not exists snowflake_policies.authentication_policies;
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

grant create database on account to role developer;

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
    default_warehouse = developer;

alter user identifier($username)
    set authentication policy snowflake_policies.authentication_policies.require_mfa;

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
use role accountadmin;
set database_name = 'finance';
--set database_name = 'marketing';
create database if not exists identifier($database_name);
set database_schema = concat($database_name, '.datawarehouse');
create schema if not exists identifier($database_schema);
grant ownership on database identifier($database_name) to role developer;
grant usage, create schema on database identifier($database_name) to role github;
grant ownership on schema identifier($database_schema) to role github;

```

### Remove analytical databases

```sql
use role accountadmin;
set database_name = 'finance';
--set database_name = 'marketing';
drop database if exists identifier($database_name);

```

## Data loader

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
grant role identifier($dataloader) to role github;
grant role identifier($dataloader) to role developer;
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
set upper_resource_monitor = upper($dataloader);
alter warehouse identifier($dataloader) set resource_monitor = $upper_resource_monitor;

create role if not exists identifier($bitool);
create user if not exists identifier($bitool)
    must_change_password = false
    password = $password
    default_role = $bitool
    default_warehouse = $bitool;
grant role identifier($bitool) to user identifier($bitool);
grant role identifier($bitool) to role developer;
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
