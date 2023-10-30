CREATE TABLE IF NOT EXISTS january_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS february_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS march_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS april_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)

CREATE TABLE IF NOT EXISTS may_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS june_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS july_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS august_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS september_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS october_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS november_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
CREATE TABLE IF NOT EXISTS december_22 (
	ride_id varchar, 
	rideable_type varchar,	
	started_at timestamp without time zone,
	ended_at timestamp without time zone,
	start_station_name varchar,
	start_station_id varchar,
	end_station_name varchar,
	end_station_id varchar,
	start_lat numeric,
	start_lng numeric,
	end_lat numeric,
	end_lng numeric,
	member_casual varchar)
	
	
-- Data was imported from individual CSV files

-- Since all data is the same format (same columns and data types) I'm merging them all together to make it easier to clean data

CREATE TABLE IF NOT EXISTS biketrips AS
	
	(SELECT *
	FROM january_22
	UNION ALL
	SELECT *
	FROM february_22
	UNION ALL
	SELECT *
	FROM march_22
	UNION ALL
	SELECT *
	FROM april_22
	UNION ALL
	SELECT *
	FROM may_22
	UNION ALL
	SELECT *
	FROM june_22
	UNION ALL
	SELECT *
	FROM july_22
	UNION ALL
	SELECT *
	FROM august_22
	UNION ALL
	SELECT *
	FROM september_22
	UNION ALL
	SELECT *
	FROM october_22
	UNION ALL
	SELECT *
	FROM november_22
	UNION ALL
	SELECT *
	FROM december_22)
