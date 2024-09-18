-- 1. View first 1000 rows

select  *
from public.project_nashville_housing
--LIMIT 1000

-----------------------------------------------------------------------------
-- 2. Standardise the date format from datetime to date and update the sale_date column

/*SELECT DATE(sale_date) AS sale_date
FROM public.project_nashville_housing

-- Update the sale_date column

UPDATE project_nashville_housing
SET sale_date = DATE(sale_date)
*/

ALTER TABLE project_nashville_housing
ADD COLUMN sale_date_only DATE;

UPDATE project_nashville_housing
SET sale_date_only = sale_date::DATE;


------------------------------------------------------------------------------
-- 3. View blank spaces of the property address column

SELECT  *
FROM public.project_nashville_housing
WHERE property_address IS NULL
LIMIT 1000

-- use self join
SELECT
    a.parcel_id,
    a.property_address,
    b.parcel_id,
    b.property_address
FROM project_nashville_housing a
JOIN project_nashville_housing b 
ON a.parcel_id = b.parcel_id
AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL

--  Populating a.property_address with b.property_address using UPDATE & SET
 /* In the dataset there are various properties that have the same parcel_id but 
   differ in unique_id, when that happens there are times when only one of the 
   properties has the property_address populated */

UPDATE project_nashville_housing a
SET property_address = COALESCE(a.property_address, b.property_address)
FROM project_nashville_housing b
WHERE a.parcel_id = b.parcel_id
AND a.unique_id <> b.unique_id
AND a.property_address IS NULL;

-- Check if there are still NULL values or if it was done correctly

SELECT property_address
FROM project_nashville_housing
WHERE property_address IS NULL

----------------------------------------------------------------------------------------
-- 4. Breaking property_address into Columns - address, city, state

-- Splitting property_address into new_property_address and new_property_city components
SELECT 
    SUBSTR(property_address, 1, POSITION(',' IN property_address) - 1) AS new_property_address,
    SUBSTR(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address)) AS new_property_city
FROM project_nashville_housing;

-- OR
-- Using SUBSTRING and POSITION to select the address (everything before the ',') and the ity (everything after the ',')
SELECT 
  SUBSTRING(TRIM(property_address), 1, POSITION(',' IN property_address) - 1) AS new_property_address,
  SUBSTRING(TRIM(property_address), POSITION(',' IN property_address) + 2, LENGTH(property_address)) AS new_property_city
FROM project_nashville_housing;

-- Adding new_prperty_address column
ALTER TABLE project_nashville_housing
ADD COLUMN new_property_address VARCHAR(255);

-- Updating new_property_address column with the street address
UPDATE project_nashville_housing
SET new_property_address = SUBSTRING(property_address, 1, POSITION(',' IN property_address) - 1);

-- Adding new_property_city column
ALTER TABLE project_nashville_housing
ADD COLUMN new_property_city VARCHAR(255);

-- Updating new_property_address column with the city portion
UPDATE project_nashville_housing
SET new_property_city = SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address));

----------------------------------------------------------------------------------------
-- 5. Split owner address into respective columns - address , city , state

SELECT owner_address
FROM project_nashville_housing

-- Using SPLIT_PART to split owner_address column into new_owner_address , new_owner_city, new_owner_state

SELECT owner_address,
  SPLIT_PART(owner_address, ',', 1) AS new_owner_address,
  SPLIT_PART(owner_address, ',', 2) AS new_owner_city,
  SPLIT_PART(owner_address, ',', 3) AS new_owner_state
FROM project_nashville_housing

-- Creating new_owner_address , new_owner_city, new_owner_state columns

ALTER TABLE project_nashville_housing
ADD COLUMN new_owner_address VARCHAR(255),
ADD COLUMN new_owner_city VARCHAR(255),
ADD COLUMN new_owner_state VARCHAR(255);

-- Update new_owner_address , new_owner_city, new_owner_state columns from the owner_address column

UPDATE project_nashville_housing
SET
    new_owner_address =  SPLIT_PART(owner_address, ',', 1) ,
    new_owner_city = SPLIT_PART(owner_address, ',', 2),
    new_owner_state = SPLIT_PART(owner_address, ',', 3) 

----------------------------------------------------------------------------------------

-- 6. Changing Y and N to Yes and No in sold_as_vacant column

-- Check to see how many options there are and the most populated

SELECT 
  DISTINCT(sold_as_vacant),
  COUNT(sold_as_vacant) AS sold_as_vacant_count
FROM project_nashville_housing
GROUP BY sold_as_vacant
ORDER BY sold_as_vacant_count DESC

-- Use CASE WHEN to replace Y for Yes and N for No

UPDATE project_nashville_housing
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	                      WHEN sold_as_vacant = 'N' THEN 'No'
	                      ELSE sold_as_vacant
	                 END

----------------------------------------------------------------------------------------

-- 7. Removing Duplicates

-- Using a CTE + ROW_NUMBER to find duplicates

WITH row_number_cte AS
(
  SELECT *,
    ROW_NUMBER() OVER
                    (PARTITION BY parcel_id, 
                                  property_address, 
                                  sale_date_only, 
                                  sale_price, 
                                  legal_reference 
                    ORDER BY parcel_id) AS row_num
  FROM project_nashville_housing
)
SELECT *
FROM row_number_cte
WHERE row_num > 1 

-- Deleting the duplicates from the CTE

WITH row_number_cte AS
(
  SELECT *,
    ROW_NUMBER() OVER
                    (PARTITION BY parcel_id, 
                                  property_address, 
                                  sale_date_only, 
                                  sale_price, 
                                  legal_reference 
                    ORDER BY parcel_id) AS row_num
  FROM project_nashville_housing
)
DELETE FROM project_nashville_housing
WHERE parcel_id IN (
  SELECT parcel_id FROM row_number_cte WHERE row_num > 1
);

-- 233 duplicate fields were deleted

----------------------------------------------------------------------------------------

-- 9. Remove unused columns - we have split them

ALTER TABLE project_nashville_housing
DROP COLUMN property_address,
DROP COLUMN owner_address,
DROP COLUMN tax_district
DROP COLUMN sale_date;


-----------------------------------------------------------------------------------------

-- 10. Significant 30 330 NULLS out of total rows of 56244

SELECT *
FROM project_nashville_housing
WHERE owner_name IS NULL 
AND   land_value IS NULL
AND   building_value IS NULL
AND   total_value IS NULL 
AND year_built IS NULL
AND bedrooms IS NULL 
AND full_bath IS NULL
AND half_bath IS NULL
AND   acreage IS NULL 
AND new_owner_address IS NULL
AND new_owner_city IS NULL
--AND new_owner_state
  


