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