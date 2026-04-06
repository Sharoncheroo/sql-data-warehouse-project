--Data Quality Checks

--====================================================
--bronze.crm_cust_info
--=====================================================
--1. Check for nulls and duplicates in primary key
	--Expectation: no results

SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;

--2. Check for unwanted spaces in string values
	--Expectation: no results

--firstname: 15 rows
SELECT cst_firstname 
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) --if original value is not equal to the same value after trimming, then there are spaces

--lastname:17 rows
SELECT cst_lastname 
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

--marital_status: none
SELECT cst_marital_status 
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status)

--gender:none
SELECT cst_gndr 
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

--3. Check the consistency of values in low cardinality columns
-- In our dw we aim to store clear and meaningful values rather than using abbreviations
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

--====================================================
--bronze.crm_prd_info
--=====================================================
SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS  cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS  prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
		 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Roads'
		 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
		 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	CAST (prd_start_dt AS DATE) AS prd_start_dt,
	CAST (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt_test
FROM bronze.crm_prd_info


--Check for Unwanted Spaces
	--No extra spaces found
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm!= TRIM(prd_nm)

---Check for NULLS or Negative and invalid values
--Expectation: NO Results
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost <0 OR prd_cost IS NULL --Nulls found; Replace with 0 if the business allows

--Data Standardization * Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

--Check for Invalid Date Orders
--Result: End date must not be earlier than the start date
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt

--====================================================
--bronze.crm_sales_details
--=====================================================

--check for invalid dates
SELECT sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <=0  or LEN(sls_due_dt) !=8

--check for invalid dates
--Order Date must alwasy be earlier than the shipping date or due date
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt OR sls_ship_dt > sls_due_dt

--Check data consistency between sales, quantity, and price
--Business rules: 
	--Sales = quantity * price
	--no negatives, zeros, and nulls
	--If sales is negative, zero, or null, derive it using quantity * price
	--If price is zero, or null, calculate using sales and quantity
	--If price is negative, convert it to a positive value
SELECT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0



--=============================================ERP=======================================================

--------------------------erp_cust_az12--------------------------------

--Check consistency in customer id/key in crm

SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate> GETDATE()

--Data Standardization and consistency
SELECT DISTINCT 
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'Female') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'Male') THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12


--------------------------erp_loc_a101---------------------------------
SELECT
REPLACE(cid, '-', '') AS cid,
CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) IN ('USA', 'US') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) ='' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry --Normalize and Handle missing blank country codes
FROM bronze.erp_loc_a101


--Data standardization & consistency
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry


--------------------------erp_px_cat_g1v2------------------------------

--Check for unwanted spaces
SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

--Data Standardization
--None from the 3 columns
SELECT DISTINCT 
cat
FROM bronze.erp_px_cat_g1v2
