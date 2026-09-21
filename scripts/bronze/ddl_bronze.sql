/* 

Criação da B.dados e Schemas

Nesse script, é criado uma nova b.dados chamada DataWarehouse, após verificar se ela já existe, caso ela já exista, será dropada e recriada.
Além disso, também realizado a criação dos schemas: "bronze", "silver" e "gold".

*/

USE master;
GO

-- Verificar se existe alguma b.dados chamada DataWarehouse, caso sim, ela será dropada.

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE.
	DROP DATABASE DataWarehouse;
END;
GO

-- Criar e usar a b.dados DataWarehouse

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Criação dos Schemas

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
