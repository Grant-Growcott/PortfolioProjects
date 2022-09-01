SELECT *
FROM ProjectPortfolio..CovidDeaths
ORDER BY 3,4

SELECT *
FROM ProjectPortfolio..CovidVaccinations
ORDER BY 3,4


-- Select data that we are going to be using

SELECT Location, date, total_cases, total_deaths, population
FROM ProjectPortfolio..CovidDeaths
ORDER BY 1,2


-- Looking at the total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country 


SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE location like 'Canada'
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of the population got Covid


SELECT Location, date, total_cases, population, (total_cases/population) * 100 AS population_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE Location like 'Canada'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to population


SELECT Location, Population, Max(total_cases) AS highest_infection_count, MAX((total_cases/population)) * 100 AS percent_population_infected
FROM ProjectPortfolio..CovidDeaths
--WHERE Location like 'Canada'
GROUP BY Location, Population
ORDER BY percent_population_infected DESC


-- Showing the countries with the Highest Death Count per Population
-- The IS NOT NULL line is because the location and continent column is giving different outcomes. We only want to use the continent column that has the appropriate continent for each country.


SELECT Location, Max(cast(total_deaths AS int)) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY total_death_count DESC



--Let's break things down by Continent

--Showing continents with the highest death count per population

SELECT continent, Max(cast(total_deaths AS int)) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC



-- Global Numbers on a  day by day basis 


SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Finding the total number irrespective of date (overall statistic)

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

 -- When using order by,  the 1,2,3 indicates that the columns will appear with continent, then location, then date because that is how the code is written
-- We are going to sum the new vaccinations and convert them from nvarchar to integer. We want to create a running total
-- The running  total is acomplished by using OVER and Partition BY so that the numbers don't continuously keeping adding regardless of country. 



 -- USE CTE ( this will allow us to use a previous nested query for calculations)

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths dea
Join ProjectPortfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



 --Using a temporary table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths dea
Join ProjectPortfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




 --Creating view to store data for later visualizations


 --This view will allow us to query off of and is found in the Views folder in the ProjectPortfolio

Create View PercentVaccinated AS 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From ProjectPortfolio..CovidDeaths dea
Join ProjectPortfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


