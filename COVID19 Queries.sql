-- See data types for CovidVaccinations
USE PortfolioProject;
GO
EXEC sp_columns 'CovidVaccinations';

-- See data types for CovidDeaths
USE PortfolioProject;
GO
EXEC sp_columns 'CovidDeaths';

SELECT * FROM PortfolioProject..CovidDeaths WHERE continent is NOT NULL ORDER BY 3,4 


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE location like '%states%'
ORDER BY 1,2

-- Shows what percentage of population infected with Covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS DeathPopulationInfected
FROM PortfolioProject..CovidDeaths 
WHERE location like '%states%' and continent is NOT NULL
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths 
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY 4 DESC


-- Countries with Highest Death Count per Population
SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths 
WHERE continent is NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount desc

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths) / SUM(new_cases))*100 as DeathPerc
FROM PortfolioProject..CovidDeaths 
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

-- GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths) / SUM(new_cases))*100 as DeathPerc
FROM PortfolioProject..CovidDeaths 
WHERE continent is not NULL
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVac) as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (CAST(RollingPeopleVac AS float)/population)*100 
FROM PopvsVac

-- Creating View to store data for later visualizations

DROP TABLE IF EXISTS #PercentPopulationVac
CREATE TABLE #PercentPopulationVac(
continent nvarchar(255),
location nvarchar(255),
Date datetime2,
population bigint, 
new_vaccinations numeric,
RollingPeopleVac numeric
)

Insert into #PercentPopulationVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as numeric)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingPeopleVac/population)*100 
FROM #PercentPopulationVac

-- Creating View to store data for later visualizations

USE PortfolioProject
GO
CREATE VIEW PopvsVac AS
Select dea.location, 
       dea.date, 
       dea.population, 
       vacc.new_vaccinations,
       SUM(CAST(vacc.new_vaccinations AS int)) 
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_people_vaccinated
FROM PortfolioProject..[CovidDeaths] dea
JOIN PortfolioProject..[CovidVaccinations] vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date

--DROP VIEW Popvsvac;