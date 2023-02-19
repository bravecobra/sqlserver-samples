-- make sure were on the right server
SELECT @@version AS Version;
SELECT @@SERVERNAME AS Server_Name;

-- tell the publisher who the remote distributor is
EXEC sp_adddistributor @distributor = 'distributor',
                       @password = 'Password1';