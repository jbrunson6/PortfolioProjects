-- Data from https://ourworldindata.org/covid-deaths
-- Data initially cleaned in Excel removing unnecessary columns
-- Check out my tableau dashboard here: https://public.tableau.com/app/profile/jay.brunson/viz/Covid-19Tracker_16974775070770/Dashboard1

-- Creating initial tables

DROP TABLE IF EXISTS public.covid;

CREATE TABLE IF NOT EXISTS covid (
	iso_code text,
	continent text,
	location text,
	date date,
	population bigint,
	total_cases bigint,
	new_cases bigint,
	total_deaths bigint,
	new_deaths bigint,
	total_tests bigint,
	new_tests bigint,
	positive_rate numeric,
	tests_per_case numeric,
	tests_units text,
	total_vaccinations bigint,
	people_vaccinated bigint,
	people_fully_vaccinated bigint,
	total_boosters bigint,
	new_vaccinations bigint,
	population_density numeric,
	median_age numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita numeric,
	extreme_poverty numeric,
	female_smokers numeric,
	male_smokers numeric,
	handwashing_facilities numeric,
	hospital_beds_per_thousand numeric,
	life_expectancy numeric
);
 
--Splitting tables to smaller 

CREATE TABLE IF NOT EXISTS covid_deaths (
	iso_code text,
	continent text,
	location text,
	date date,
	population bigint,
	total_cases bigint,
	new_cases bigint,
	total_deaths bigint,
	new_deaths bigint,
	total_tests bigint,
	new_tests bigint,
	positive_rate numeric,
	tests_per_case numeric,
	tests_units text

);

CREATE TABLE IF NOT EXISTS covid_vaccines (
	iso_code text,
	continent text,
	location text,
	date date,
	total_vaccinations bigint,
	people_vaccinated bigint,
	people_fully_vaccinated bigint,
	total_boosters bigint,
	new_vaccinations bigint,
	population_density numeric,
	median_age numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita numeric,
	extreme_poverty numeric,
	female_smokers numeric,
	male_smokers numeric,
	handwashing_facilities numeric,
	hospital_beds_per_thousand numeric,
	life_expectancy numeric
);




-- Exploring parts of the data

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population
FROM covid
ORDER BY 1,2

-- Total cases vs Pop

SELECT location, date, total_cases, population, (total_cases::numeric/population::numeric)*100 as death_percent
FROM covid
WHERE location ILIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases Vs Total Deaths
-- Shows how likely to die if you contract in USA over time

SELECT location, date, total_cases, total_deaths, (total_deaths*100.0/total_cases)as death_percent
FROM covid
WHERE location ILIKE '%states%'
ORDER BY 1,2

-- Calculating total rolling cases and rolling AVG

WITH t1 AS
	(SELECT d.location, 
		d.date,
		new_cases, 
		SUM(new_cases) OVER(PARTITION BY d.location ORDER BY d.location, d.date ) as totalcases
	FROM covid_deaths d
	JOIN covid_vaccines v
		ON d.location = v.location AND d.date = v.date)
SELECT *,
	AVG(totalcases) OVER(PARTITION BY location ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg
FROM t1;

-- Creating separate table for Continents/Income VS Country

CREATE TABLE IF NOT EXISTS covid_continents AS (
SELECT *
FROM covid
WHERE continent IS NULL);


-- Creating separate table for Continents/Income VS Country

CREATE TABLE IF NOT EXISTS covid_countries AS (
SELECT *
FROM covid
WHERE continent IS NOT NULL);


-- By Country, looking at total death of total case and percentage of population deaths, as well as ranking by
WITH t1 AS
(	SELECT location,
		population, 
		SUM(new_cases) as total_cases, 
		SUM(new_deaths) as total_deaths
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY 1,2)
SELECT *, 
	CASE 
		WHEN total_deaths = 0 THEN 0
		ELSE ROUND((total_deaths::numeric)/((total_cases::numeric)/1000), 2)
	END as death_per_thous_cases,
	CASE 
		WHEN total_cases = 0 THEN 0 
		ELSE ROUND(total_deaths*100.0/total_cases , 4)
	END AS perc_deaths_per_case,
	RANK() OVER(ORDER BY (CASE 
		WHEN total_cases = 0 THEN 0 
		ELSE ROUND(total_deaths*100.0/total_cases , 4)
	END ) DESC) as death_perc_rank_by_pop,
	ROUND(total_deaths*100.0/population , 5) as percentage_pop_deaths,
	RANK() OVER(ORDER BY (total_deaths*100.0/population) DESC) as death_perc_rank_by_pop
FROM t1
WHERE total_cases IS NOT NULL;


CREATE TABLE IF NOT EXISTS covid_countries_clean AS
	(SELECT 
		d.location,
		d.date, 
		d.population, 
		new_cases, 
		new_deaths, 
		new_tests, 
		new_vaccinations, 
		population_density, 
		median_age, 
		gdp_per_capita, 
		life_expectancy
	FROM covid_deaths d
	JOIN covid_vaccines v
		ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL);

WITH t1 AS

-- Creating running totals of cases, deaths, tests, and vaccinations by country

	(SELECT *, 
		SUM(new_cases) OVER(PARTITION BY location ORDER BY date ASC) as total_running_cases,
		SUM(new_deaths) OVER(PARTITION BY location ORDER BY date ASC) as total_running_deaths,
		SUM(new_tests) OVER(PARTITION BY location ORDER BY date ASC) as total_running_tests,
		SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY date ASC) as total_running_vaccinations
	FROM covid_countries_clean ),

-- random calcs

t2 AS

	(SELECT date,
		SUM(new_cases) as daily_cases, 
		SUM(new_deaths) as daily_deaths,
		SUM(new_tests) as daily_tests,
		SUM(new_vaccinations) as daily_vaccines
	FROM t1
	GROUP BY 1)

SELECT date,
	daily_cases,
	AVG(daily_cases) OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)as avg_daily_cases, 
	daily_deaths,
	AVG(daily_deaths) OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)as avg_daily_deaths,
	daily_tests,
	AVG(daily_tests) OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)as avg_daily_tests,
	daily_vaccines,
	AVG(daily_vaccines) OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)as avg_daily_vaccines
FROM t2

-- Countries with highest infection rate by population
SELECT location, population, MAX(total_cases) as max_infection_count, MAX((total_cases*100.0/population)) as percent_population_infected
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY 1,2
ORDER BY 4 DESC


-- Countries with highest death cout per pop, excluding continents/world

SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY 1
HAVING MAX(total_deaths) > 0
ORDER BY 2 DESC

-- Continents with highest death cout per pop, excluding individual countries

SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
GROUP BY 1
ORDER BY 2 DESC

