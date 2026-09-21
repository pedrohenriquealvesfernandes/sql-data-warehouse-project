/*
=======================================================================================
  Criação da procedure para carregamento de dados na camada bronze.
=======================================================================================
  A procedure criada tem a função de carregar os dados dentro do schema "bronze" de arquivos CSV externos.
  Para essa procedure foram utilizados os métodos:
   - TRUNCATE: para limpar todos os dados das tabelas da camada bronze;
   - BULK INSERT: para carregar os dados dos arquivos .CSV para dentro das tabelas da camada "bronze".
  Todos os processos dentro da procedure são marcados com data de início e fim e no final é calculado a diferença entre elas.
=======================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
	BEGIN TRY
		PRINT '===========================================================';
		PRINT 'Preenchendo a camada bronze';
		PRINT '===========================================================';

		PRINT '===========================================================';
		PRINT 'Preenchendo as tabelas de CRM';
		PRINT '===========================================================';
		
		SET @start_batch_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT 'Inserindo dados na tabela: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT 'Inserindo dados na tabela: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT 'Inserindo dados na tabela: crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		PRINT '===========================================================';
		PRINT 'Preenchendo as tabelas de ERP';
		PRINT '===========================================================';

		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT 'Inserindo dados na tabela: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT 'Inserindo dados na tabela: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_erp\loc_a101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		SET @start_time = GETDATE();
		PRINT 'Limpando a tabela: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
			PRINT 'Inserindo dados na tabela: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\Pedro\Desktop\ESTUDOS\ANALISE_DADOS\PROJETOS\PROJETO_DATAWAREHOUSE\datasets\source_erp\px_cat_g1v2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

		SET @end_batch_time = GETDATE()
		PRINT '==========================================================='
		PRINT 'Total de segundos para inserir TODOS os dados: ' + CAST(DATEDIFF(second, @start_batch_time, @end_batch_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '==========================================================='
	END TRY
	BEGIN CATCH 
		PRINT '===========================================================';
		PRINT 'OCORRÊNCIA DE ERRO NA CAMADA DE BRONZE';
		PRINT 'Mensagem de erro:' + ERROR_MESSAGE();
		PRINT 'Número do erro:' + CAST (ERROR_NUMBER() AS NVARCHAR(50));
		PRINT 'Status erro:' + CAST (ERROR_STATE() AS NVARCHAR(50));
		PRINT '===========================================================';
	END CATCH
END;

EXEC bronze.load_bronze
