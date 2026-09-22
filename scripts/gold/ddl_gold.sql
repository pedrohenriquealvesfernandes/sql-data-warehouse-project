/*
===============================================================================
Script DDL: Criação das views na camada Gold
===============================================================================
    Esse script verifica se a view existe na camada gold, caso exista, a view é removida e recriada, caso contrário apenas cria a view.
===============================================================================
*/

/* Criação da view gold.dim_customer */

IF OBJECT_ID('gold.dim_customer', 'V') IS NOT NULL
	DROP VIEW gold.dim_customer;
GO

CREATE VIEW gold.dim_customer AS
	SELECT        
		ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, 
		ci.cst_id AS customer_id, 
		ci.cst_key AS customer_number, 
		ci.cst_firstname AS first_name, 
		ci.cst_lastname AS last_name, 
		ci.cst_marital_status AS marital_status, 
		la.cntry AS country, 
		CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr 
			ELSE COALESCE (ca.gen, 'n/a') END gen, 
		CAST(COALESCE (ca.bdate, ci.cst_create_date) AS DATE) AS birth_date,
		ci.cst_create_date AS create_date
	FROM  silver.crm_cust_info AS ci 
	LEFT JOIN silver.erp_cust_az12 AS ca 
		ON ci.cst_key = ca.cid 
    LEFT JOIN silver.erp_loc_a101 AS la 
		ON ci.cst_key = la.cid

/* Criação da view gold.dim_product */

IF OBJECT_ID('gold.dim_product', 'V') IS NOT NULL
	DROP VIEW gold.dim_product;
GO

CREATE VIEW gold.dim_product AS
	SELECT 
		ROW_NUMBER() OVER (ORDER BY prd_start_dt, pn.prd_key) AS product_key,
		pn.prd_id AS product_id,
		pn.cat_id AS category_id,
		pn.prd_key AS product_number,
		pn.prd_nm AS product_name,
		pc.cat AS category, 
		pc.subcat AS subcategory,
		pc.maintenance,
		pn.prd_cost AS cost,
		pn.prd_line AS product_line,
		pn.prd_start_dt AS start_date
	FROM silver.crm_prd_info pn 
    LEFT JOIN silver.erp_px_cat_g1v2 AS pc 
		ON pn.cat_id = pc.id
	WHERE pn.prd_end_dt IS NULL

/* Criação da view gold.fact_sales */

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
	SELECT 
		sd.sls_ord_num AS order_number,
		dp.product_key,
		dc.customer_key,
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS ship_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price
	FROM silver.crm_sales_details sd
	LEFT JOIN gold.dim_product as dp
		ON sd.sls_prd_key = dp.product_number
	LEFT JOIN gold.dim_customer as dc
		ON sd.sls_cust_id = dc.customer_id

