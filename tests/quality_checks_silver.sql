/*
========================================================
Data Quality Checks
========================================================
Script purpose:
	This script performs various quality checks for data 
	consistency, accuracy, and standardization across the
	'silver' schema. It includes checks for:
	- Null or duplicate primary keys.
	- Unwanted spaces in string fields.
	- Data Standardization and consistency.
	- Invalid date ranges and orders.
	- Data consistency between related fields.

Use:
	- Run these checks after data loading the silver layer
	- Investigate and resolve any discrepancies found during the checks


*/

--====================================================
--Silver.crm_cust_info
--=====================================================

SELECT 
	cst_id,
	COUNT(*)
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;

--2. Check for unwanted spaces in string values
	--Expectation: no results

--firstname: 15 rows
SELECT cst_firstname 
FROM Silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) --if original value is not equal to the same value after trimming, then there are spaces

--lastname:17 rows
SELECT cst_lastname 
FROM Silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

--marital_status: none
SELECT cst_marital_status 
FROM Silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status)

--gender:none
SELECT cst_gndr 
FROM Silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

--3. Check the consistency of values in low cardinality columns
-- In our dw we aim to store clear and meaningful values rather than using abbreviations
SELECT DISTINCT cst_gndr
FROM Silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM Silver.crm_cust_info

--====================================================
--Silver.crm_prd_info
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
FROM Silver.crm_prd_info


--Check for Unwanted Spaces
	--No extra spaces found
SELECT prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm!= TRIM(prd_nm)

---Check for NULLS or Negative and invalid values
--Expectation: NO Results
SELECT prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost <0 OR prd_cost IS NULL --Nulls found; Replace with 0 if the business allows

--Data Standardization * Consistency
SELECT DISTINCT prd_line
FROM Silver.crm_prd_info

--Check for Invalid Date Orders
--Result: End date must not be earlier than the start date
SELECT *
FROM Silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

--====================================================
--Silver.crm_sales_details
--=====================================================

--check for invalid dates
SELECT sls_due_dt
FROM Silver.crm_sales_details
WHERE sls_due_dt <=0  or LEN(sls_due_dt) !=8

--check for invalid dates
--Order Date must alwasy be earlier than the shipping date or due date
SELECT *
FROM Silver.crm_sales_details
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
FROM Silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0



--=============================================ERP=======================================================

--------------------------erp_cust_az12--------------------------------

--Check consistency in customer id/key in crm

SELECT DISTINCT bdate
FROM Silver.erp_cust_az12
WHERE bdate> GETDATE()

--Data Standardization and consistency
SELECT DISTINCT 
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'Female') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'Male') THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM Silver.erp_cust_az12


--------------------------erp_loc_a101---------------------------------
SELECT
REPLACE(cid, '-', '') AS cid,
CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) IN ('USA', 'US') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) ='' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry --Normalize and Handle missing blank country codes
FROM Silver.erp_loc_a101


--Data standardization & consistency
SELECT DISTINCT cntry
FROM Silver.erp_loc_a101
ORDER BY cntry


--------------------------erp_px_cat_g1v2------------------------------

--Check for unwanted spaces
SELECT * 
FROM Silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

--Data Standardization
--None from the 3 columns
SELECT DISTINCT 
cat
FROM Silver.erp_px_cat_g1v2
