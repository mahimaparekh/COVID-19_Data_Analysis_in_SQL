
/**
	Converting all important numeric data from nvarchar to data type float 
*/
ALTER TABLE COVIDDEATHS
ALTER COLUMN TOTAL_DEATHS FLOAT

ALTER TABLE COVIDDEATHS
ALTER COLUMN NEW_DEATHS FLOAT

ALTER TABLE COVIDDEATHS
ALTER COLUMN TOTAL_CASES FLOAT

ALTER TABLE COVIDDEATHS
ALTER COLUMN NEW_CASES FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN TOTAL_TESTS FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN NEW_TESTS FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN TOTAL_VACCINATIONS FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN PEOPLE_VACCINATED FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN NEW_VACCINATIONS FLOAT

ALTER TABLE COVIDVACCINATIONS
ALTER COLUMN PEOPLE_FULLY_VACCINATED FLOAT

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='COVIDVACCINATIONS'

/**
	Performing some data cleaning by setting total_cases = 0 wherever total_cases = NULL and new_cases = 0
	Applying the same concept for total_cases and new_cases
*/
ALTER TABLE COVIDDEATHS
ADD TC INT

UPDATE COVIDDEATHS
SET TC = 
CASE WHEN TOTAL_DEATHS IS NULL AND NEW_DEATHS = 0 THEN 0 ELSE TOTAL_DEATHS END

UPDATE COVIDDEATHS
SET TOTAL_DEATHS = TC

ALTER TABLE COVIDDEATHS
DROP COLUMN TC

/**
	Deleting unnecessary columns
*/
ALTER TABLE COVIDVACCINATIONS
DROP COLUMN NEW_TESTS

/**
	Idenitfying countries with no deaths
*/
SELECT LOCATION, SUM(NEW_DEATHS) DEATH_COUNT
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION
HAVING SUM(NEW_DEATHS) = 0

/**
	Identifying the first case and first deaths in each country (taking India as a sample case)
*/
SELECT CONTINENT, LOCATION, MIN(DATE) DATE, MIN(NEW_CASES) CASES
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL AND NEW_CASES <> 0 and location = 'India'
GROUP BY CONTINENT, LOCATION
ORDER BY 3 ASC

SELECT CONTINENT, LOCATION, MIN(DATE) DATE, MIN(NEW_DEATHS) DEATHS
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL AND NEW_DEATHS <> 0 and location = 'India'
GROUP BY CONTINENT, LOCATION
ORDER BY 3 DESC

/**
	Identifying countries with the highest number of covid-19 deaths
*/
SELECT CONTINENT, LOCATION, MAX(TOTAL_DEATHS) TOTAL_DEATH_COUNT
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT, LOCATION
HAVING MAX(TOTAL_DEATHS) IS NOT NULL
ORDER BY 3 DESC

/**
   Calculating the case fatality rate (CFR) by country, which is the percentage of individuals who have 
   died out of the total confirmed COVID-19 cases. 
*/
SELECT LOCATION, POPULATION, SUM(NEW_CASES) TOTAL_CASES, SUM(NEW_DEATHS) TOTAL_DEATHS,
(MAX(TOTAL_DEATHS)/MAX(TOTAL_CASES))*100 AS CASE_FATALITY_RATE
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION, POPULATION
HAVING SUM(NEW_CASES) IS NOT NULL AND SUM(NEW_CASES)<>0
ORDER BY 5 DESC

/**
	Mortality Rate Per Million
*/
SELECT LOCATION, POPULATION, (SUM(NEW_DEATHS)/POPULATION)*1000000 MORTALITY_RATE_PER_MILLION
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION, POPULATION
HAVING (SUM(NEW_DEATHS)/POPULATION)*1000000 IS NOT NULL
ORDER BY 3 DESC

/**
	Comparing the infection rate of each country
*/
SELECT LOCATION, (SUM(NEW_CASES)/MAX(POPULATION))*1000000 AS INFECTION_RATE_PER_MILLION
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION
HAVING (SUM(NEW_CASES)/MAX(POPULATION))*1000000 IS NOT NULL
ORDER BY 2 desc

/**
	Comparing infection rate with the case fatality rate
*/
SELECT LOCATION, POPULATION, (SUM(NEW_CASES)/MAX(POPULATION))*100 AS INFECTION_RATE, 
(MAX(TOTAL_DEATHS)/MAX(TOTAL_CASES))*100 AS CASE_FATALITY_RATE
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION, POPULATION
HAVING MAX(TOTAL_CASES) <> 0
ORDER BY 3 asc

/**
   Countries where more than 50% of their population has been infected with COVID-19.
*/
WITH CTE AS(
	SELECT LOCATION, MAX(TOTAL_CASES) TOTAL_CASES, MAX(POPULATION) POPULATION, (MAX(TOTAL_CASES)/MAX(POPULATION))*100 INFECTION_RATE
	FROM COVIDDEATHS
	WHERE CONTINENT IS NOT NULL
	GROUP BY LOCATION
)

SELECT COUNT(LOCATION) LOCATION
FROM CTE
WHERE INFECTION_RATE>=50

/**
   Identifying the continents with the highest death count due to COVID-19
   and comparing it with their total population
*/
SELECT CONTINENT, MAX(POPULATION) POPULATION, SUM(NEW_DEATHS) TOTAL_DEATH_COUNT
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
ORDER BY 3 ASC

/**
	Spread Patterns - analyzing how the virus initially spread
*/
SELECT *
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL AND NEW_CASES>0
ORDER BY 4 ASC, 3 ASC

/**
   Global Overview of the total number of cases and total number of deaths worldwide, along with the global infection rate and global death rate
*/
SELECT SUM(NEW_CASES) TOTAL_CASES, SUM(NEW_DEATHS) TOTAL_DEATHS,
(SUM(NEW_CASES)/MAX(POPULATION))*100 GLOBAL_INFECTION_RATE,
(SUM(NEW_DEATHS)/SUM(NEW_CASES))*100 GLOBAL_DEATH_RATE
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL

/**
	Total vaccinations per country
*/
SELECT CONTINENT, LOCATION, MAX(TOTAL_VACCINATIONS) TOTAL_VACCINATIONS
FROM COVIDVACCINATIONS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT,LOCATION
ORDER BY 3 DESC

/**
	Total vaccinations by continent
*/

SELECT CONTINENT, MAX(TOTAL_VACCINATIONS) TOTAL_VACCINATIONS
FROM COVIDVACCINATIONS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
ORDER BY 2 ASC

/**
	Analyzing how death rates were impacted due to vaccinations in India
*/
SELECT CD.LOCATION, CD.DATE, CD.new_deaths, CV.TOTAL_VACCINATIONS
FROM COVIDDEATHS CD
JOIN COVIDVACCINATIONS CV
ON CD.LOCATION = CV.LOCATION AND CD.DATE = CV.DATE
WHERE CD.CONTINENT IS NOT NULL AND CD.LOCATION  = 'INDIA'
ORDER BY 2 asc, 4 asc

/**
	Comparing death rates in each country with total vaccinated people
*/
--death count
SELECT CV.LOCATION, MAX(CD.TOTAL_DEATHS) TOTAL_DEATHS, MAX(CV.PEOPLE_VACCINATED) TOTAL_VACCINATIONS
FROM COVIDVACCINATIONS CV
JOIN COVIDDEATHS CD
ON CV.LOCATION = CD.LOCATION AND CD.DATE = CV.DATE
WHERE CV.CONTINENT IS NOT NULL
GROUP BY CV.LOCATION
ORDER BY 2 DESC

--vaccination count
SELECT TOP 10 CV.LOCATION, MAX(CD.TOTAL_DEATHS) TOTAL_DEATHS, MAX(CV.PEOPLE_VACCINATED) TOTAL_VACCINATIONS
FROM COVIDVACCINATIONS CV
JOIN COVIDDEATHS CD
ON CV.LOCATION = CD.LOCATION AND CD.DATE = CV.DATE
WHERE CV.CONTINENT IS NOT NULL
GROUP BY CV.LOCATION
ORDER BY 3 DESC

/**
	Overview of the total vaccinations received globally
*/
WITH CTE AS(
	SELECT POPULATION, SUM(CD.NEW_DEATHS) DEATHS , MAX(CV.PEOPLE_VACCINATED) VACCINES
	FROM COVIDVACCINATIONS CV
	JOIN COVIDDEATHS CD
	ON CV.LOCATION = CD.LOCATION AND CD.DATE = CV.DATE
	WHERE CV.CONTINENT IS NOT NULL
	GROUP BY POPULATION
	)

SELECT SUM(POPULATION) GLOBAL_POPULATION, SUM(DEATHS) GLOABL_DEATH_COUNT, SUM(VACCINES) GLOBAL_VACCINATION_COUNT,
(SUM(VACCINES)/SUM(POPULATION)) * 100 GLOBAL_VACCINATION_RATE
FROM CTE

/**
	Analyzing yearly global covid data in India
*/
SELECT CD.LOCATION LOCATION, YEAR(CD.DATE) AS YEAR, SUM(CD.NEW_DEATHS) DEATHS, MAX(CV.PEOPLE_VACCINATED) VACCINES
FROM COVIDDEATHS CD
JOIN COVIDVACCINATIONS CV
ON CD.LOCATION = CV.LOCATION AND CD.DATE = CV.DATE
WHERE CD.CONTINENT IS NOT NULL AND CD.LOCATION ='INDIA'
GROUP BY CD.LOCATION, YEAR(CD.DATE)
ORDER BY 1 ASC, 2 ASC
