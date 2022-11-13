# MSSQL Replication

Ref: [https://medium.com/@gareth.newman/sql-server-replication-on-docker-a-glimpse-into-the-future-46086c7b3f2](https://medium.com/@gareth.newman/sql-server-replication-on-docker-a-glimpse-into-the-future-46086c7b3f2)

## Step 1: Custom Dockerfile

We want to use a custom Dockerfile where high avalability and sql agent is enabled from the root folder

```bash
docker build -t sqlag:ha .
```

## Step 2: Docker-compose with 3 nodes

Create three nodes with `docker-compose`:

* sqlNode1: publisher
* sqlNode2: subscriber
* sqlNode3: distributor

```bash
cd ./mssql-replication-docker
docker-compose up -d
```

## Create the distributor

```sql
SELECT @@version AS Version
SELECT @@SERVERNAME AS Server_Name

-- step 1, tell this server it is a distributor
EXEC sp_adddistributor @distributor = 'distributor', @password = 'Password1'

-- step 2, create the distribution db
EXEC sp_adddistributiondb @database = 'distribution';

-- step 3, tell the distributor who the publisher is
-- NOTE! (make the directory '/var/opt/mssql/ReplData',
-- it doesn't exist and this command will try and verify that it does.
-- We created that directory in the dockerfile itself,
-- but in case you need it afterwards, execute the following:
-- docker exec -it distributor bin/bash
-- mkdir /var/opt/mssql/ReplData
-- CTRL+Z get back out
EXEC sp_adddistpublisher @publisher = 'publisher', @distribution_db = 'distribution'

-- let's check the DB
USE distribution;
GO

-- see the repl commands table
SELECT *
FROM [dbo].[MSrepl_commands]

-- and let's see the jobs we made
SELECT name, date_modified
FROM msdb.dbo.sysjobs
ORDER by date_modified desc
```

## Create the publisher

```sql
-- make sure were on the right server
SELECT @@version AS Version;
SELECT @@SERVERNAME AS Server_Name;

-- tell the publisher who the remote distributor is
EXEC sp_adddistributor @distributor = 'distributor',
                       @password = 'Password1';
```

Now create a test database on the `publisher` that we want to replicate to the `subscriber`.

```sql
-- create a test database
CREATE DATABASE Sales;
GO

-- create a test table
USE [Sales];
GO
CREATE TABLE CUSTOMER
(
    [CustomerID] [INT] NOT NULL,
    [SalesAmount] [DECIMAL] NOT NULL
);
GO


-- add a PK (we can't replicate without one)
ALTER TABLE CUSTOMER ADD PRIMARY KEY (CustomerID);


-- let's insert a row
INSERT INTO CUSTOMER
(
    CustomerID,
    SalesAmount
)
VALUES
(0, 100);
```

Rerun the above script on the subscriber so they have a common starting point.

Now, let's enable the database for replication on the `publisher` with

```sql
-- lets enable the database for replication
USE [Sales];
EXEC sp_replicationdboption @dbname = N'Sales',
                            @optname = N'publish',
                            @value = N'true';

-- Add the publication (this will create the snapshot agent if we wanted to use it)
EXEC sp_addpublication @publication = N'SalesDB',
                       @description = N'',
                       @retention = 0,
                       @allow_push = N'true',
                       @repl_freq = N'continuous',
                       @status = N'active',
                       @independent_agent = N'true';

-- now let's add an article to our publication
USE [Sales];
EXEC sp_addarticle @publication = N'SalesDB',
                   @article = N'customer',
                   @source_owner = N'dbo',
                   @source_object = N'customer',
                   @type = N'logbased',
                   @description = NULL,
                   @creation_script = NULL,
                   @pre_creation_cmd = N'drop',
                   @schema_option = 0x000000000803509D,
                   @identityrangemanagementoption = N'manual',
                   @destination_table = N'customer',
                   @destination_owner = N'dbo',
                   @vertical_partition = N'false';

-- now let's add a subscriber to our publication
use [Sales]
exec sp_addsubscription
@publication = N'SalesDB',
@subscriber = 'subscriber',
@destination_db = 'sales',
@subscription_type = N'Push',
@sync_type = N'none',
@article = N'all',
@update_mode = N'read only',
@subscriber_type = 0

-- and add the push agent
exec sp_addpushsubscription_agent
@publication = N'SalesDB',
@subscriber = 'subscriber',
@subscriber_db = 'Sales',
@subscriber_security_mode = 0,
@subscriber_login =  'sa',
@subscriber_password =  'Password1',
@frequency_type = 64,
@frequency_interval = 0,
@frequency_relative_interval = 0,
@frequency_recurrence_factor = 0,
@frequency_subday = 0,
@frequency_subday_interval = 0,
@active_start_time_of_day = 0,
@active_end_time_of_day = 0,
@active_start_date = 0,
@active_end_date = 19950101
GO
-- by default it sets up the log reader agent with a default account that won’t work, you need to change that to something that will.
EXEC sp_changelogreader_agent @publisher_security_mode = 0,
                              @publisher_login = 'sa',
                              @publisher_password = 'Password1';
```

Now replication through transactions should be working. All changes made to the `customer` table on the `publisher` should replicate to the `subscriber`.
