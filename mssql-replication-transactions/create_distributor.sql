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
GO
