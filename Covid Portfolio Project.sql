USE PortfolioProjectCovid;

SELECT  *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM CovidVaccinations
ORDER BY 3,4;

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, 
	(CONVERT(float, total_deaths)/CONVERT(FLOAT, total_cases))*100 AS "fatality_rate"
FROM CovidDeaths
WHERE continent IS NOT NULL
AND location = 'New Zealand'
ORDER BY 1,2;

-- Looking at total cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS "prevalence"
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS "highest_infection_count", MAX(total_cases/population)*100 AS "prevalence"
FROM CovidDeaths
--WHERE location = 'New Zealand'
WHERE DATE < '01-01-2021'
AND continent IS NOT NULL
GROUP BY location, population
ORDER BY prevalence DESC;

-- Showing countries with highest death count 
SELECT location, MAX(CONVERT(FLOAT, total_deaths)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Showing continent with highest death count 
SELECT continent, MAX(CONVERT(FLOAT, total_deaths)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- REPEAT - Showing continent with highest death count 
--More accurate due to how data is labelled
SELECT location, MAX(CONVERT(FLOAT, total_deaths)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

--Global numbers
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 AS "fatality_rate"
FROM CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- Looking at total population vs vaccination
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(float, new_vaccinations)) OVER 
		(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS total_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
	ON (cd.location = cv.location)
	AND (cd.date = cv.date)
WHERE cd.continent IS NOT NULL
ORDER BY 2,3;

--Create a CTE
WITH PopVaccinated (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(float, new_vaccinations)) OVER 
		(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
	ON (cd.location = cv.location)
	AND (cd.date = cv.date)
WHERE cd.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (rolling_vaccinations/population)*100 
FROM PopVaccinated;

-- Create a temp table
DROP TABLE IF EXISTS #PopVaccinated
CREATE TABLE #PopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric,
)

INSERT INTO #PopVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(float, new_vaccinations)) OVER 
		(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
	ON (cd.location = cv.location)
	AND (cd.date = cv.date)
WHERE cd.continent IS NOT NULL;
-- ORDER BY 2,3

SELECT *, (rolling_vaccinations/population)*100 
FROM #PopVaccinated;

--Create a view to store data for later visualisations

CREATE VIEW PopVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(float, new_vaccinations)) OVER 
		(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
	ON (cd.location = cv.location)
	AND (cd.date = cv.date)
WHERE cd.continent IS NOT NULL;