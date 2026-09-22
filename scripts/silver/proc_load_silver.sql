/*
=======================================================================================
  Criação da procedure para carregamento de dados na camada silver.
=======================================================================================
  A procedure criada tem a função de carregar os dados das tabelas do schema bronze nas tabelas do schema silver, realizando o processo de ETL.  
  Para essa procedure foram utilizados os métodos:
   - TRUNCATE: para limpar todos os dados das tabelas da camada silver;
  Todos os processos dentro da procedure são marcados com data de início e fim e no final é calculado a diferença entre elas.
=======================================================================================
*/

/* 
    Preenchendo a tabela silver.crm_cust_info com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
    BEGIN TRY
		PRINT '===========================================================';
		PRINT 'Preenchendo a camada silver';
		PRINT '===========================================================';

		PRINT '===========================================================';
		PRINT 'Preenchendo as tabelas de CRM';
		PRINT '===========================================================';

        set @end_batch_time = GETDATE();
        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT 'Inserindo dados na tabela: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id, 
            cst_key, 
            cst_firstname, 
            cst_lastname, 
            cst_marital_status,
            cst_gndr,
            cst_create_date)
            SELECT 
                cst_id,
                cst_key,
                TRIM(cst_firstname),    -- Tirando os espaços desnecessários
                TRIM(cst_lastname),     -- Tirando os espaços desnecessários       
                CASE
                    WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'    -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                    WHEN UPPER(TRIM(cst_marital_status))= 'M' THEN 'Marriage'   -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                    ELSE 'n/a'
                END cst_marital_status,
                CASE
                    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'  -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                    WHEN UPPER(TRIM(cst_gndr))= 'M' THEN 'Male'     -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                    ELSE 'n/a'
                END cst_gndr,
                cst_create_date
            FROM (
            SELECT *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag   -- Fazendo a contagem de vezes que o "cst_id" aparece na tabela e ordenando de forma descendente a data de criação
            FROM bronze.crm_cust_info)t
            WHERE t.flag = 1 AND cst_id IS NOT NULL     -- Filtrando apenas os registros pela data de criação mais recente após verificar os "cst_id" duplicados e removendo os "cst_id" vazios

        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';
        /* 
            Preenchendo a tabela silver.crm_prd_info com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
        */
        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT 'Inserindo dados na tabela: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info(
            prd_id, 
            cat_id, 
            prd_key, 
            prd_nm, 
            prd_cost, 
            prd_line, 
            prd_start_dt, 
            prd_end_dt)
            SELECT
                prd_id,
                REPLACE(SUBSTRING(prd_key,1,5), '-', '_') as cat_id,    -- Criando a coluna cat_id com os 5 primeiros caracteres da "prd_key" e substituindo o hífen por underline para "conectar" com a coluna "id" da tabela "erp_px_cat_g1v2"
                SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,     -- Criando a coluna prd_key a partir do 7 caractere até o fim da string com a função LEN        
                prd_nm,
                ISNULL(prd_cost, 0) as prd_cost,    -- Verificando se na coluna prd_cost tem algum dado NULL, caso sim, ele é substituido com 0
                CASE UPPER(TRIM(prd_line))  -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                    WHEN 'M' THEN 'Montain'
                    WHEN 'R' THEN 'Road' 
                    WHEN 'S' THEN 'Other Sales' 
                    WHEN 'T' THEN 'Touring' 
                    ELSE 'n/a'
                END prd_line,
                CAST (prd_start_dt AS DATE) as prd_start_dt,    -- Utilizando CAST AS DATE para remover os "00:00" do date time 
                CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) as prd_end_dt  -- Utilizando o dia anterior ao "prd_start_dt" e subtraindo 1 dia e utilizando esse resultado como valor na coluna prd_end_dt
            FROM bronze.crm_prd_info
        
        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

        /* 
            Preenchendo a tabela silver.crm_prd_info com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
        */

        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT 'Inserindo dados na tabela: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details(
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price)
            SELECT
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,
                CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) !=8 THEN NULL          -- Verifica se a sls_order_dt é menor ou igual a 0 ou se o tamanho é diferente de 8, caso sim, o campo fica como NULL
                    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,   -- Converte o campo sls_order_dt que estava como INT em VARCHAR e depois converte em DATE
                CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) !=8 THEN NULL            -- Verifica se a sls_ship_dt é menor ou igual a 0 ou se o tamanho é diferente de 8, caso sim, o campo fica como NULL
                    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,     -- Converte o campo sls_ship_dt que estava como INT em VARCHAR e depois converte em DATE
                CASE WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) !=8 THEN NULL              -- Verifica se a sls_due_dt é menor ou igual a 0 ou se o tamanho é diferente de 8, caso sim, o campo fica como NULL
                    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,       -- Converte o campo sls_due_dt que estava como INT em VARCHAR e depois converte em DATE
                CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price) -- Verifica se o valor do campo sls_sales é NULL, menor ou igual a 0, se é diferente do da quantidade * pelo preço absoluto, caso sim o sls_sales passa a ser sls_quantity * ABS(sls_price)
                    ELSE sls_sales END AS sls_sales, -- Caso não, continua o mesmo valor que antes
                sls_quantity,
                CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)  -- Verifica se o sls_price é NULL ou menor/igual a 0, caso sim, o sls_price passa a ser o resultado de sls_sales pela sls_quantity
                    ELSE sls_price END AS sls_price -- Caso não, continua o mesmo valor que antes
            FROM bronze.crm_sales_details

        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';
        /* 
            Preenchendo a tabela silver.erp_cust_az12 com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
        */
    
	    PRINT '===========================================================';
		PRINT 'Preenchendo as tabelas de ERP';
		PRINT '===========================================================';

        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT 'Inserindo dados na tabela: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
            SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))  -- Verificando se o "cid" inicia com 'NAS', caso sim, ele será removido.
                ELSE cid END cid,
            CASE WHEN bdate > GETDATE() THEN NULL   -- Deixando o campo "bdate" NULL caso ele seja maior que a data atual
                ELSE bdate END bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'     -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                 ELSE 'n/a' END AS gen
            FROM bronze.erp_cust_az12

        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';
        /* 
            Preenchendo a tabela silver.erp_loc_a101 com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
        */

        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT 'Inserindo dados na tabela: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101
        (
        cid,
        cntry
        )
            SELECT 
            REPLACE(cid, '-', '') cid, -- Remoção do hífen do "cid"
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'                 -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                 WHEN TRIM(cntry) IN ('USA', 'US') THEN 'United Sates'  -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'      -- Alterando a abreviação para a categorização completa (deixando mais amigável)
                 ELSE TRIM(cntry) END AS cntry
            FROM bronze.erp_loc_a101

        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';
        /* 
            Preenchendo a tabela silver.erp_px_cat_g1v2 com os dados limpos, categorizados, não duplicados e com tratamento para dados vazios
        */
        set @start_time = GETDATE();
        PRINT 'Limpando a tabela: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT 'Inserindo dados na tabela: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance)
            SELECT
            *       -- Após verificar que todos os campos estavam com valores formatados corretamente, não precisamos fazer correção
            FROM bronze.erp_px_cat_g1v2

        SET @end_time = GETDATE();
		PRINT 'Total de segundos para inserir os dados: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(50)) + ' segundos';
		PRINT '-----------------------------';

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

exec silver.load_silver
