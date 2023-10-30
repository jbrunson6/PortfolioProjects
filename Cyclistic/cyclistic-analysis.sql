
-- Exploration of the Data


-- Checking to see if there are duplicates in ride_id

SELECT ride_id, COUNT(ride_id)
FROM biketrips
GROUP BY ride_id
HAVING COUNT(ride_id) > 1

SELECT *
FROM biketrips
WHERE ride_id LIKE '%E+%'

-- Some of the ride_ids got changed formats somehow but it shouldnt affect anything and there were no duplicates

-- Trying some calculations out using the long/lat data to see if it will be useful to keep
-- I found 2 calcuations on calculating distance, one with radians and one without. The radians calc seems to be more accurate, checking vs online calcs and margin of error is less than 1%

SELECT rideable_type, acos(sin(start_lat)*sin(end_lat)+cos(start_lat)*cos(end_lat)*cos(end_lng-start_lng))*6371.0 as distance_traveled,
	ACOS((SIN(RADIANS(start_lat)) * SIN(RADIANS(end_lat))) + (COS(RADIANS(start_lat)) * COS(RADIANS(end_lat))) * (COS(RADIANS(end_lng) - RADIANS(start_lng)))) * 6371.0 as with_radians
FROM biketrips
WHERE start_lat IS NOT NULL
	AND end_lat IS NOT NULL
	AND start_lng IS NOT NULL
	AND end_lng IS NOT NULL
	AND start_lat != end_lat
	AND ride_id = 'C2F7DD78E82EC875'
	
-- Checking to see how many rides were less than 1 minute log
-- After some initial checks there are around 120,00 rides less than 1 minute long but only 2200 with different start and end points that are more than 100 meters apart
-- Using the distance calc from the previous query we are able to calculate Kilometers Per Hour (KPH)
-- After doing some reseach I found that Mark Cavendish's tops sprint speed is 78 KM but that doesnt account for downhill
-- The current downhill record is 144 kph by Todd Reichert set in 2016
-- With that knowledge, lets only include those that are less than "The Manx Missile" Mark Cavendish's top speed of 78 droping total count to 1938
-- Also the distance calculated is a direct path, hopefully no buildings were destroyed by people going 10000 kpm past or through those buildings

WITH t1 AS
(SELECT ride_id, EXTRACT(epoch FROM ended_at - started_at) as seconds, ended_at - started_at, start_station_name, end_station_name, start_station_id, end_station_id, ACOS((SIN(RADIANS(start_lat)) * SIN(RADIANS(end_lat))) + (COS(RADIANS(start_lat)) * COS(RADIANS(end_lat))) * (COS(RADIANS(end_lng) - RADIANS(start_lng)))) * 6371.0 as distance_km
FROM biketrips
WHERE EXTRACT(epoch FROM ended_at - started_at) < 60 
	AND ended_at >= started_at
	AND (start_station_name IS NOT NULL AND end_station_name IS NOT NULL 
		 OR 
		 start_station_id IS NOT NULL AND end_station_id IS NOT NULL)
	AND (start_station_name != end_station_name 
		 OR 
		 start_station_id != end_station_id)
ORDER BY 2 ASC),
t2 AS

(	SELECT *, 
		CASE
			WHEN seconds::integer = 0 THEN 99999999999999999 -- infinity speed
			WHEN seconds::integer != 0 THEN (distance_km::numeric)/(seconds/3600)
		END as kph
	FROM t1
	WHERE distance_km >= .1
	ORDER BY 9 ASC)

SELECT *
FROM t2
WHERE kph < 78
	
	

-- Splitting date time into more usable columns, all columns have a start and end time

SELECT ride_id, 
FROM biketrips
WHERE started_at IS null

SELECT ride_id,
FROM biketrips
WHERE ended_at IS NULL

-- New columns to add bases on time
SELECT 
	ROUND(EXTRACT(epoch FROM ended_at - started_at), 0)::integer as duration_in_secs,
	EXTRACT(month FROM started_at)::integer as month,
	EXTRACT(DOW FROM started_at)::integer as day_of_week,
	EXTRACT(quarter FROM started_at)::integer as quarter,
	EXTRACT(HOUR FROM started_at)
FROM biketrips

ALTER TABLE biketrips
ADD COLUMN duration_in_secs integer,
ADD COLUMN day_of_week integer,
ADD COLUMN month integer,
ADD COLUMN hour integer

UPDATE biketrips
SET duration_in_secs = ROUND(EXTRACT(epoch FROM ended_at - started_at), 0)::integer

UPDATE biketrips
SET day_of_week = EXTRACT(DOW FROM started_at)::integer

UPDATE biketrips
SET month = EXTRACT(month FROM started_at)::integer

UPDATE biketrips
SET hour = EXTRACT(HOUR FROM started_at)::integer

-- Top stations used

SELECT start_station_name, member_casual, COUNT(start_station_name), SUM(COUNT(start_station_name)) OVER(PARTITION BY start_station_name)
FROM biketrips
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 20

-- Member Vs Casual

SELECT member_casual, AVG(duration_in_secs) as seconds, AVG(duration_in_secs)/60 as minutes, MAX(duration_in_secs/3600) as max_hours
FROM biketrips
WHERE (duration_in_secs)/3600 <= 24
GROUP BY 1

SELECT member_casual, duration_in_secs/60
FROM biketrips
ORDER BY 2 DESC
LIMIT 1000
	
WITH t1 AS
(
	SELECT member_casual, COUNT(*), COUNT(*)*100.0/(SUM(COUNT(*)) OVER()), SUM(duration_in_secs)/(3600*24.0) as days
	FROM biketrips
	WHERE (duration_in_secs)/3600 >= 24
	GROUP BY 1)
SELECT *, SUM(days) OVER(), days*100.0/(SUM(days) OVER())
FROM t1

SELECT member_casual, rideable_type, COUNT(*), AVG(duration_in_secs)/60

SELECT *
FROM biketrips

-- Sampling the data to be able to upload in Tableau because its too slow to work with. Using 5% sampling based on month to keep an even distribution of timing of logged events

CREATE TABLE IF NOT EXISTS sample AS(
WITH t1 AS
	(SELECT *
	FROM biketrips
	ORDER BY RANDOM()),
t2 AS
	(SELECT *, NTILE(20) OVER(PARTITION BY month) as sample
	FROM t1)
SELECT *
FROM t2
WHERE sample = 1
)

-- Looking at the most used stations for non members by quarters

WITH t1 AS

	(SELECT start_station_name, EXTRACT(quarter FROM started_at) as quarter, COUNT(*), RANK() OVER (PARTITION BY EXTRACT(quarter FROM started_at) ORDER BY COUNT(*) DESC) as ranking
	FROM sample
	WHERE member_casual = 'casual'
		AND start_station_name IS NOT NULL
	GROUP BY 1,2)
	
SELECT *
FROM t1
WHERE ranking <= 10


WITH t1 AS

	(SELECT end_station_name, EXTRACT(quarter FROM started_at) as quarter, COUNT(*), RANK() OVER (PARTITION BY EXTRACT(quarter FROM started_at) ORDER BY COUNT(*) DESC) as ranking
	FROM sample
	WHERE member_casual = 'casual'
		AND end_station_name IS NOT NULL
	GROUP BY 1,2)
	
SELECT *
FROM t1
WHERE ranking <= 10

-- percentages
-- members vs casual

SELECT member_casual, COUNT(*) as user_type_count, COUNT(*)*100.0/SUM(COUNT(*)) OVER () as perc_of_users
FROM sample
GROUP BY 1

-- bike type by casual riders

SELECT rideable_type, COUNT(*) as rider_count, COUNT(*)*100.0/SUM(COUNT(*)) OVER () as perc_of_users
FROM sample
WHERE member_casual = 'casual'
GROUP BY 1


--

SELECT month, member_casual, EXTRACT(quarter from started_at), COUNT(*)
FROM sample
GROUP BY 1,2,3
ORDER by 2,1

SELECT day_of_week,
	CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		WHEN day_of_week = 1 THEN 'MONDAY'
		WHEN day_of_week = 2 THEN 'TUESDAY'
		WHEN day_of_week = 3 THEN 'WEDNESDAY'
		WHEN day_of_week = 4 THEN 'THURSDAY'
		WHEN day_of_week = 5 THEN 'FRIDAY'
		WHEN day_of_week = 6 THEN 'SATURDAY'
	END as dow, 
	member_casual, 
	COUNT(*),
	COUNT(*)*100.0/SUM(COUNT(*)) OVER(PARTITION BY member_casual) as perc
FROM sample
GROUP BY 1,2,3
ORDER by 1,3


SELECT hour, 
	CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END as day_of_week,
	COUNT(*),
	COUNT(*)*100.0/SUM(COUNT(*)) OVER(PARTITION BY CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END )
FROM sample
WHERE member_casual = 'casual'
AND day_of_week IN (0,6)
GROUP BY 1,2
ORDER BY 2,4 DESC



SELECT hour, 
	CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END as day_of_week,
	COUNT(*) as rides,
	SUM(COUNT(*)) OVER(PARTITION BY CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END ORDER BY hour ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING) as eight_hour_shift_rides,
	SUM(COUNT(*)) OVER(PARTITION BY CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END) total_rides,
	SUM(COUNT(*)) OVER(PARTITION BY CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END ORDER BY hour ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING)*100.0/SUM(COUNT(*)) OVER(PARTITION BY CASE 
		WHEN day_of_week = 0 THEN 'SUNDAY'
		ELSE 'SATURDAY' 
	END) as percent_of_rides_covered_per_shift
FROM sample
WHERE member_casual = 'casual'
AND day_of_week IN (0,6)
GROUP BY 1,2
ORDER BY 2,4 DESC

-- Rewriting code with CTE for more efficeincy and adding in Friday 

WITH t1 as 

	(SELECT
		hour, 
		CASE 
			WHEN day_of_week = 0 THEN 'Sunday'
	 		WHEN day_of_week = 5 THEN 'Friday'
			WHEN day_of_week = 6 THEN 'Saturday'
		END as dow,
		COUNT(*) as rides,
	 	ROW_NUMBER() OVER(ORDER BY CASE 
				WHEN day_of_week = 0 THEN 'Sunday'
				WHEN day_of_week = 5 THEN 'Friday'
				WHEN day_of_week = 6 THEN 'Saturday'
			END, hour) as weekend_hour
	FROM sample
	WHERE day_of_week IN (0,5,6)
		AND member_casual = 'casual'
	GROUP BY 1,2),
	
t2 AS	

(	SELECT *, 
		SUM(rides) OVER(PARTITION BY dow) as total_rides,
		SUM(rides) OVER(PARTITION BY dow ORDER BY hour ASC ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING) as eight_hr_shift,
		SUM(rides) OVER(PARTITION BY dow ORDER BY hour ASC ROWS BETWEEN CURRENT ROW AND 9 FOLLOWING) as ten_hr_shift,
		SUM(rides) OVER(PARTITION BY dow ORDER BY hour ASC ROWS BETWEEN CURRENT ROW AND 11 FOLLOWING) as twelve_hr_shift,
		SUM(rides) OVER(ORDER BY weekend_hour ROWS BETWEEN CURRENT ROW AND 11 FOLLOWING) as full_weekend
	FROM t1),
	
t3 AS
	
	(SELECT *, 
		RANK() OVER(PARTITION BY dow ORDER BY eight_hr_shift DESC) as rank_8,
		RANK() OVER(PARTITION BY dow ORDER BY ten_hr_shift DESC) as rank_10,
		RANK() OVER(PARTITION BY dow ORDER BY twelve_hr_shift DESC) as rank_12,
		RANK() OVER(PARTITION BY dow ORDER BY full_weekend DESC) as rank_weekend,
		-- calculating avg rank of the 4 rankings to then determine top overall weekend selection times
		-- weighted avg
				(RANK() OVER(PARTITION BY dow ORDER BY eight_hr_shift DESC)*.3
				+ RANK() OVER(PARTITION BY dow ORDER BY ten_hr_shift DESC)*.3
				+ RANK() OVER(PARTITION BY dow ORDER BY twelve_hr_shift DESC)*.3
				+ RANK() OVER(PARTITION BY dow ORDER BY full_weekend DESC)*.1) as weighted_rank
		-- regular avg
	-- 	(RANK() OVER(PARTITION BY dow ORDER BY eight_hr_shift DESC)
	-- 	+ RANK() OVER(PARTITION BY dow ORDER BY ten_hr_shift DESC)
	-- 	+ RANK() OVER(PARTITION BY dow ORDER BY twelve_hr_shift DESC))/3.0 as avg_rank
	FROM t2),
	
t4 AS	

	(SELECT *, ROW_NUMBER() OVER(PARTITION BY dow ORDER BY weighted_rank) as overall_rank
	FROM t3)
	
SELECT hour, 
	dow, 
	total_rides, 
	eight_hr_shift, 
	ROUND(eight_hr_shift*100.0/total_rides,3) as percent_seen_8,
	ten_hr_shift, 
	ROUND(ten_hr_shift*100.0/total_rides,3) as percent_seen_10,
	twelve_hr_shift, 
	ROUND(twelve_hr_shift*100.0/total_rides,3) as percent_seen_12,
	full_weekend, 
	ROUND(full_weekend*100.0/total_rides,3) as percent_seen_12_full
FROM t4
WHERE overall_rank <=3
ORDER BY dow, overall_rank




SELECT start_station_name
FROM sample
WHERE start_station_name IN 

WITH t1 AS
(SELECT start_station_name, COUNT(*) as visits
FROM sample
WHERE start_station_name IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC)
SELECT start_station_name
FROM t1 
WHERE visits = (SELECT MAX(visits) FROM t1)



-- percent of riders not in jan, feb, march, april, nov, dec
-- almost 75.4% of people ride in these months
-- split by user, casuals ride in these months 82.6% and members ride 70.4%

SELECT member_casual,
	COUNT(*), 
	COUNT(*) FILTER (WHERE MONTH NOT IN(1,2,3,4,11,12)), 
	(COUNT(*) FILTER (WHERE MONTH NOT IN(1,2,3,4,11,12)))*100.0/COUNT(*)
FROM sample 
GROUP BY 1

-- Only Excluding winter months
-- 92.9% of riders ride outside of winter
-- Casuals ride are 96.2%
-- Members are 90.6%

SELECT member_casual,
	COUNT(*), 
	COUNT(*) FILTER (WHERE MONTH NOT IN(1,2,12)), 
	(COUNT(*) FILTER (WHERE MONTH NOT IN(1,2,12)))*100.0/COUNT(*)
FROM sample 
GROUP BY 1

-- Max average monthly usage is 13050/day for casuals (June) and MIN is 615 (Jan)
-- For Members Max is 13850 (July) and MIN is 2730 (Jan)
SELECT member_casual, month, COUNT(*)/MAX(EXTRACT(day FROM started_at))*20
FROM sample
GROUP BY 1,2

-- Checking the number of NULL values in starting and stoping posisitons

SELECT COUNT(*) FILTER (WHERE start_station_name IS NOT NULL AND start_station_id IS NOT NULL AND end_station_name IS NOT NULL AND end_station_id IS NOT NULL), COUNT(*)
FROM biketrips
