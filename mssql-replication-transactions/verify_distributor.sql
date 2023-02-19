-- let's check the DB
USE distribution;
GO

-- see the repl commands table
SELECT *
FROM [dbo].[MSrepl_commands]
GO
-- and let's see the jobs we made
SELECT name, date_modified
FROM msdb.dbo.sysjobs
ORDER by date_modified desc
GO