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
GO

-- let's insert a row
INSERT INTO CUSTOMER
(
    CustomerID,
    SalesAmount
)
VALUES
(0, 100);
GO