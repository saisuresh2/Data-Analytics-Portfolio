
--SELECT *
--FROM CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1, 2 

-- Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths,
	(CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

-- Total Cases vs Total Population

SELECT location, date, total_cases, population,
	(CONVERT(float,total_cases)/population)*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

-- Countries with Highest Infection Rate

SELECT location, 
	MAX(cast(total_cases as int)) as HighestInfectionCount, 
	population,
	MAX((CONVERT(float,total_cases)/population)*100) AS PerecentPopInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PerecentPopInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, 
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--- break up by continent
-- Continents with Highest Death Count per Population
SELECT continent, 
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
-- by each day
SELECT  
	SUM(new_cases) as TotalCases,
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage,
	((CAST(total_deaths as int)/CAST(total_cases as int))*100) as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- overall
SELECT  
	SUM(new_cases) as TotalCases,
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Use a CTE to Find Rolling Vaccine Count per Population

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingVaccineCount)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingVaccineCount/Population)*100 as PercentVaccinated
FROM PopvsVac

-- Use a Temp Table to Find Rolling Vaccine Count per Population

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingVaccineCount numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingVaccineCount/Population)*100 as PercentVaccinated
FROM #PercentPopulationVaccinated


-- Creating Views to Store Data for Later Visualizations

-- Rolling Percent Population Vaccinated
DROP VIEW if exists PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- Each Country's Total Death Count
DROP VIEW if exists TotalDeathsByCountry

CREATE VIEW TotalDeathsByCountry as
SELECT location, 
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

-- Each Country's Maximum Infection Rate
DROP VIEW if exists MaxInfectionRate

CREATE VIEW MaxInfectionRate as
SELECT location, 
	MAX(cast(total_cases as int)) as HighestInfectionCount, 
	population,
	MAX((CONVERT(float,total_cases)/population)*100) AS PerecentPopInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population


