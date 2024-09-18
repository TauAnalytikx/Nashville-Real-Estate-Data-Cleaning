# Nashville-Real-Estate-Data-Cleaning

# Nashville-Housing-Project

## Data Cleaning and Transformation

###OVERVIEW
SQL queries [PostgreSQL] demonstrate data cleaning and transformation tasks on the dataset named **Nashville Housing**. The steps include but are not limited to the following:
```
	1. Standardizing Date Format
	2. View blank spaces of the property address column and update the table using self-join
	3. Breaking down property_address 	
	4. Breaking down the Owner's Address 
	5. Changing Y and N to Yes and No in the sold as vacant column
	6. Removing Duplicates
	7. Remove unused columns
``` 
### DATA CLEANING PROCESS
📈 Dataset [Click Here](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx)

 💻 Tools Used: PostgreSQL, pgAdmin4, Azure Data Studio

 SQL Code :  [Click Here](https://github.com/TauAnalytikx/Nashville-Real-Estate-Data-Cleaning/blob/main/Nashville%20Housing%20Data%20Cleaning%20.sql)

##### View first 1000 rows
```
SELECT * FROM public.project_nashville_housing LIMIT 1000
```
- This query is used to view the **initial state of the dataset.** 
- This step provides an **overview of the structure of the dataset and helps you identify patterns, anomalies, or issues (like NULL values, incorrect formats, etc.)** that need to be addressed.

##### Standardizing Date Format: Converts the "sale date" column to a consistent date format and creates a new column "sale date only"

```
ALTER TABLE project_nashville_housing
ADD COLUMN sale_date_only DATE;

UPDATE project_nashville_housing
SET sale_date_only = sale_date::DATE;
```

- Date fields in the dataset may include both date and time, but for many analyses, only the date portion is relevant. Here, we:
	- Add a new column sale_date_only to store the date part only (excluding time).
	- Update this new column by converting the sale_date from a timestamp to a date using the ::DATE casting.
- This standardizes the date format, which simplifies analyses like filtering or grouping by date.

##### View blank spaces of the property address column and update the table using self-join

```
SELECT  *
FROM public.project_nashville_housing
WHERE property_address IS NULL
LIMIT 1000

-- use self-join
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
```
- Some properties may share the same "parcel id" but have missing property_address values. This step:
	- Uses a self-join to find other records with the same "parcel_id" and fills missing "property_address" values using the non-NULL values from the other rows.
- This technique is used to fill in missing data when possible, ensuring that important fields like property_address are as complete as possible.
- Populating a.property address with b.property address using UPDATE & SET clauses
- *In the dataset various properties have the same parcel id but differ in unique id, when that happens there are times when only one of the properties has the property address populated*


##### Breaking down property_address into Columns - address, city, state

```
-- Splitting property_address into new_property_address and new_property_city components
SELECT 
    SUBSTR(property_address, 1, POSITION(',' IN property_address) - 1) AS new_property_address,
    SUBSTR(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address)) AS new_property_city
FROM project_nashville_housing;

####OR
-- Using SUBSTRING and POSITION to select the address (everything before the ',') and the city (everything after the ',')
SELECT 
  SUBSTRING(TRIM(property_address), 1, POSITION(',' IN property_address) - 1) AS new_property_address,
  SUBSTRING(TRIM(property_address), POSITION(',' IN property_address) + 2, LENGTH(property_address)) AS new_property_city
FROM project_nashville_housing;

-- Adding new_property_address column
ALTER TABLE project_nashville_housing
ADD COLUMN new_property_address VARCHAR(255);

-- Updating new_property_address column with the street address
UPDATE project_nashville_housing
SET new_property_address = SUBSTRING(property_address, 1, POSITION(',' IN property_address) - 1);

-- Adding new_property_city column
ALTER TABLE project_nashville_housing
ADD COLUMN new_property_city VARCHAR(255);

-- Updating the new_property_address column with the city portion
UPDATE project_nashville_housing
SET new_property_city = SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address));

```
**SUBSTR():**

- This function extracts a substring from a string.
- SUBSTR(property_address, 1, POSITION(',' IN property_address) - 1): 
	- This extracts the substring from the start of 	  property_address (position 1) up to the character just before the comma (hence, POSITION() - 1).
- **Result:** This gives the part of property_address before the first comma, which is assumed to be the street address.

**POSITION():**

- This function finds the position of a substring within a string.
	- Syntax: POSITION(substring IN string)
substring: 
	- The string you want to find (in this case, the comma ','). string: 
		- Returns: The position of the first occurrence of the substring (comma) in "property_address."
	- POSITION(',' IN property_address) + 1: 
	  - This moves the starting position to the character right after the comma (hence, + 1).

 **LENGTH(property_address):** 
- This returns the total length of property_address, which is used as the length of the substring.

**Improvements:**
Use of TRIM() clause to remove any leading or trailing spaces in new_property_city:

##### Breaking down Owner Address: Divides the owner address into columns for address, city, and state.
```
SELECT owner_address
FROM project_nashville_housing 
-- Useful for understanding the structure of the data before transforming it

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
```
- **SPLIT_PART Function:** This function splits a string into parts based on a specified delimiter (in this case, a comma,) and returns a specified part.

		- "SPLIT_PART"(owner_address, delimiter, field_number)
- The SPLIT_PART function works on the existing data, showing the individual parts that will later be stored in new columns.


##### Changing Y and N to Yes and No in the sold as vacant column
```
-- Id how many Ys and Ns there are and the most populated and convert them to their respective Yes and No

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
```

- DISTINCT extracts the unique values from the sold_as_vacant column.
	- It helps to identify what values exist in the column (Y, N, or possibly others).
- COUNT(sold_as_vacant):
	- This counts how many times each distinct value appears in the sold_as_vacant column.
		- It shows the frequency of each unique value
		- The sold_as_vacant column likely contains data that indicates whether a property was sold as vacant. 
	- The values 'Y' (yes) and 'N' (no) are shorthand entries.
- The goal of this query is to improve the readability of the data by converting these shorthand values into more meaningful, user-friendly terms ('Yes' and 'No').
- **This is part of data standardisation and cleaning, which is essential for improving the usability of the dataset, especially when sharing it with non-technical stakeholders or using it in reports or visualisations.**

##### Removing Duplicates
```
-- Using a CTE + ROW_NUMBER to find duplicates

WITH row_number_cte AS
(
  SELECT *,
    ROW_NUMBER() OVER
                    (PARTITION BY parcel_id, 
                                  property_address, 
                                  sale_date, 
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
                                  sale_date, 
                                  sale_price, 
                                  legal_reference 
                    ORDER BY parcel_id) AS row_num
  FROM project_nashville_housing
)
DELETE FROM project_nashville_housing
WHERE parcel_id IN (
  SELECT parcel_id FROM row_number_cte WHERE row_num > 1
);
```
- This step removes duplicate records based on key fields. 
- It uses ROW_NUMBER() to identify duplicate rows and delete them.
- Duplicates can distort analysis results, so identifying and removing them is critical for data integrity.
- 233 records were deleted 

##### Remove unused columns - we have split them
```
ALTER TABLE project_nashville_housing
DROP COLUMN property_address,
DROP COLUMN owner_address,
DROP COLUMN tax_district
DROP COLUMN sale_date;
```
- After splitting and cleaning, the original "property_address" and "owner_address" columns are no longer needed, as well as other unnecessary columns like "tax_district".
- Dropping unused columns helps to streamline the dataset and focus only on relevant fields for analysis. This also optimizes query performance.


##### Significant NULLS out of total rows of 56244
```
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
--AND new_owner_state -- Can not be added - cant take nulls
```
- Most columns that have NULL values do not affect our analysis but they can't be deleted as they will affect our dataset 
- 30 330 rows out of 56244 but they are not much of significance to our exploratory analysis 

REFERENCES 
AlexTheAnalyst [Data Analyst Portfolio Project Series](https://www.youtube.com/watch?v=8rO7ztF4NtU)



 
