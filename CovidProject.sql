SELECT*
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT*
--FROM PortfolioProject1..CovidVaccinations
--ORDER BY 3,4

--Select Data that we are going to be using

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases VS Total Deaths
--Shows the likelihood of dying if you contract covid in Brazil

SELECT location,date,total_cases,total_deaths,((total_deaths*100)/total_cases) AS DeathPercentage
FROM CovidProject..covid_deaths
WHERE location='Brazil'
AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases VS Population
--Show what percentage of population got Covid

SELECT location,date,population,total_cases,((total_cases*100)/population) AS infected_ppl_perc
FROM CovidProject..covid_deaths
WHERE location='Brazil'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location,population,MAX(total_cases) AS highest_infection_count,MAX((total_cases*100)/population) AS infected_ppl_perc
FROM CovidProject..covid_deaths
GROUP BY population,location
ORDER BY infected_ppl_perc DESC

--Showing Countries with Highest Death Count per Population 

SELECT location,MAX(population) AS population,MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--LET'S BREAK DOWN THINGS BY CONTINENT

--Showing continent with highest death count per population

SELECT continent,MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

--GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases,SUM(CAST(new_deaths AS INT)) AS total_deaths,SUM((new_deaths)*100)/SUM(new_cases) AS death_percentage
FROM CovidProject..covid_deaths
--WHERE location='Brazil'
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Population VS Vaccination

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
FROM CovidProject..covid_deaths dea
JOIN CovidProject..covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USING A CTE WITH THE CODE ABOVE

WITH PopVsVac(continent,location,date,population,new_vaccinations,rolling_ppl_vaccinated)
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_ppl_vaccinated
FROM CovidProject..covid_deaths dea
JOIN CovidProject..covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,(rolling_ppl_vaccinated/population*100) AS rolling_ppl_vaccination_perc
FROM PopVsVac

--The code above isn't working. Tem porcentagem de mais de 100% na última coluna.

--TEMP TABLE

DROP TABLE IF EXISTS #PercPopulationVaccinated
CREATE TABLE #PercPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaccinated numeric
)

INSERT INTO #PercPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_ppl_vaccinated
FROM CovidProject..covid_deaths dea
JOIN CovidProject..covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
--WHERE dea.continent IS NOT NULL

SELECT *,(rolling_ppl_vaccinated/population*100)
FROM #PercPopulationVaccinated

--Create view  to store data for later visualization

CREATE VIEW PercPopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_ppl_vaccinated
FROM CovidProject..covid_deaths dea
JOIN CovidProject..covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercPopulationVaccinated
