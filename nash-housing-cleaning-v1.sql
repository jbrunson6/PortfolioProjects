-- CLEANING DATA FOR NASHVILLE HOUSING

-- DATA CAN BE FOUND AT: https://www.kaggle.com/datasets/tmthyjames/nashville-housing-data

-- STEP 1: UPDATE THE COLUNM NAMES SINCE PGADMIN REQUIRES DOUBLE QUOTES ON COLUMN NAMES IF THEY START WITH A CAPITAL LETTER


ALTER TABLE nash_housing RENAME COLUMN "UniqueID" TO unique_id;
ALTER TABLE nash_housing RENAME COLUMN "ParcelID" TO parcel_id;
ALTER TABLE nash_housing RENAME COLUMN "LandUse" TO land_use;
ALTER TABLE nash_housing RENAME COLUMN "PropertyAddress" TO property_address;
ALTER TABLE nash_housing RENAME COLUMN "SaleDate" TO sale_date;
ALTER TABLE nash_housing RENAME COLUMN "SalePrice" TO sale_price;
ALTER TABLE nash_housing RENAME COLUMN "LegalReference" TO legal_reference;
ALTER TABLE nash_housing RENAME COLUMN "SoldAsVacant" TO sold_vacant;
ALTER TABLE nash_housing RENAME COLUMN "OwnerName" TO owner_name;
ALTER TABLE nash_housing RENAME COLUMN "OwnerAddress" TO owner_address;
ALTER TABLE nash_housing RENAME COLUMN "Acreage" TO acreage_acreage;
ALTER TABLE nash_housing RENAME COLUMN "TaxDistrict" TO tax_district;
ALTER TABLE nash_housing RENAME COLUMN "LandValue" TO land_value;
ALTER TABLE nash_housing RENAME COLUMN "BuildingValue" TO building_value;
ALTER TABLE nash_housing RENAME COLUMN "TotalValue" TO total_value;
ALTER TABLE nash_housing RENAME COLUMN "YearBuilt" TO year_built;
ALTER TABLE nash_housing RENAME COLUMN "Bedrooms" TO bedrooms_bedrooms;
ALTER TABLE nash_housing RENAME COLUMN "FullBath" TO full_bath;
ALTER TABLE nash_housing RENAME COLUMN "HalfBath" TO half_bath;


-- STEP 2: UPDATE COLUMN DATA TYPES THAT WERE IMPORTED INCORRECTLY


ALTER TABLE nash_housing 
ALTER COLUMN unique_id TYPE INT
USING unique_id::INT

ALTER TABLE nash_housing 
ALTER COLUMN sale_price TYPE numeric
USING sale_price::numeric

ALTER TABLE nash_housing 
ALTER COLUMN sale_price TYPE integer
USING sale_price::integer

-- Testing conversion method
	-- SELECT *, sale_price::numeric::integer
	-- FROM nash_housing
	-- ORDER BY 20 DESC
	
	

-- STEP 3: FILLING IN MISSING DATA FROM PROPERTY ADDRESS. ALSO CREATING A BACKUP TABLE IN CASE ERRORS
	-- 	ROWS WITH THE SAME PARCEL_ID HAVE THE SAME PROPERTY ADDRESS SO WE WILL USE THOSE TO FILL IN MISSING DATA
	
	
CREATE TABLE IF NOT EXISTS nash_housing_2 AS (
SELECT *
FROM nash_housing
ORDER BY 1;
	
	-- FOUND ROWS WITH SAME ADDRESS WITH DIFFERENT NUMBER OF SPACES THAT WAS GIVING ME DUPLICATES SO FIXING THAT NOW
UPDATE nash_housing
SET property_address = regexp_replace(property_address, E'  +', ' ', 'g');

	-- CREATING NEW ADDRESS COLUMN 
SELECT DISTINCT a.*, COALESCE(a.property_address, b.property_address) as prop_address
FROM nash_housing a
LEFT JOIN nash_housing b
	ON a.parcel_id = b.parcel_id
	AND a.unique_id != b.unique_id
ORDER BY a.unique_id

	-- OR
SELECT unique_id, parcel_id, land_use, 
	FIRST_VALUE(property_address) OVER(PARTITION BY parcel_id ORDER BY property_address ASC) as updated_address
FROM nash_housing
ORDER BY unique_id

	--UPDATING TABLE 
UPDATE nash_housing
SET property_address = subquery.updated_address
FROM (
	SELECT *,
		FIRST_VALUE(property_address) OVER(PARTITION BY parcel_id ORDER BY property_address ASC) as updated_address
	FROM nash_housing) subquery
WHERE nash_housing.unique_id = subquery.unique_id

SELECT *
FROM nash_housing
ORDER BY 1
	

-- STEP 4: BREAKING PROPERTY_ADDRESS IN TO ADDRESS, CITY
	
	
SELECT unique_id, property_address,
		SPLIT_PART(property_address, ',', 1) as property_address_split,
		SPLIT_PART(property_address, ',', 2) as property_city_split
FROM nash_housing

ALTER TABLE nash_housing
ADD COLUMN property_split_address varchar,
ADD COLUMN property_split_city varchar
	
UPDATE nash_housing
SET property_split_address = SPLIT_PART(property_address, ',', 1)
	
UPDATE nash_housing
SET property_split_city = SPLIT_PART(property_address, ',', 2)

	

-- STEP 5: BREAKING OWNER_ADRESS IN TO ADDRESS, CITY, STATE
	
	
SELECT unique_id, owner_address,
	SPLIT_PART(owner_address, ',', 1) as owner_address_split,
	SPLIT_PART(owner_address, ',', 2) as owner_city_split,
	SPLIT_PART(owner_address, ',', 3) as owner_state_split
FROM nash_housing

ALTER TABLE nash_housing
ADD COLUMN owner_split_address varchar,
ADD COLUMN owner_split_city varchar,
ADD COLUMN owner_split_state varchar
	
UPDATE nash_housing
SET owner_split_address = SPLIT_PART(owner_address, ',', 1)
	
UPDATE nash_housing
SET owner_split_city = SPLIT_PART(owner_address, ',', 2)
	
UPDATE nash_housing
SET owner_split_state = SPLIT_PART(owner_address, ',', 3)

	
	
-- STEP 6: MAKING SOLD VACANT UNIFORM 'YES' AND 'NO'
	
SELECT 	
	CASE
		WHEN sold_vacant = 'N' THEN 'No'
		WHEN sold_vacant = 'Y' THEN 'Yes'
		ELSE sold_vacant
	END AS sold_vacant
FROM nash_housing
	
	
UPDATE nash_housing
SET sold_vacant = (CASE
		WHEN sold_vacant = 'N' THEN 'No'
		WHEN sold_vacant = 'Y' THEN 'Yes'
		ELSE sold_vacant
	END)
	
SELECT *
FROM nash_housing
	

-- STEP 7: REMOVING DUPLICATE DATA -- Not actually removing it but finding 104 duplicate rows
	
	
WITH t1 AS
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference ORDER BY unique_id) as ranking
FROM nash_housing)
DELETE
FROM t1
WHERE ranking > 1
	
SELECT *
FROM nash_housing
	
	
-- STEP 8: CREATING A VIEW, GETTING RID OF ANY ROWS WE DONT NEED AND ADDING TOTAL_BATH CALCULATION, AND DOWNLOADING FILE
	
CREATE TABLE IF NOT EXISTS nash_housing_clean AS (
	SELECT 
		unique_id,
		parcel_id,
		land_use,
		sale_date,
		legal_reference,
		sold_vacant,
		owner_name,
		acreage_acreage as acreage,
		tax_district,
		land_value,
		building_value,
		total_value,
		year_built,
		bedrooms_bedrooms as bedrooms,
		full_bath,
		half_bath,
		full_bath + half_bath*0.5 as total_bath,
		property_split_address,
		property_split_city,
		owner_split_address,
		owner_split_city,
		owner_split_state
	FROM nash_housing
	ORDER BY unique_id
)
	
	