
Use PortfolioProject

Select *
From PortfolioProject.dbo.CovidDeath
order by 3,4

--Select *
--From PortfolioProject.dbo.CovidVax
--order by 3,4

-- Select data that we plan to use 
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.dbo.CovidDeath
order by 1,2

--Looking at total cases v. total deaths
--shows likelihood of dying if contracted Covid within own country (United States)
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeath
Where location like '%states%'
order by 1,2

-- Looking at total cases v. population
Select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
From PortfolioProject.dbo.CovidDeath
Where location like '%states%'
order by 1,2

-- Looking at countries w/ highest infections compared to population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopInfected
From PortfolioProject.dbo.CovidDeath
--Where location like '%states%'
group by population, location
order by PercentPopInfected desc

-- Looking at countries w/ highest deaths 
Select location, MAX(cast(total_deaths as bigint)) as HighestDeathRate
From PortfolioProject.dbo.CovidDeath
--Where location like '%states%'
where continent is NULL and location not like '%income%' 
group by location
order by HighestDeathRate desc




-- Looking at countries w/ highest deaths compared to population
Select location, population, MAX(total_deaths) as HighestDeathRate, MAX((total_deaths/population))*100 as PercentDeaths
From PortfolioProject.dbo.CovidDeath
--Where location like '%states%'
where continent is not NULL
group by population, location
order by PercentDeaths desc

-- Looking at CONTINENTS w/ highest deaths 
Select continent, MAX(cast(total_deaths as bigint)) as HighestDeathRate
From PortfolioProject.dbo.CovidDeath
--Where location like '%states%'
where continent is not NULL
group by continent
order by HighestDeathRate desc


--Global numbers
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as bigint)) as TotalDeaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as Percentage --total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeath
--Where location like '%states%'
where continent is not NULL
--group by date
order by 1 


--Using both datasets, Total Population v. Total Vaccinations

Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as bigint)) OVER (Partition by death.location
order by death.location, death.date) as RollingVaxxed
From PortfolioProject.dbo.CovidDeath death
JOIN PortfolioProject.dbo.CovidVax vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not NULL
order by 2,3

-- Use CTE (want to check rolling vaxxed per population)

With PopvVax (continent, location, date, population, new_vaccinations, RollingVaxxed)
as 
(
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as bigint)) OVER (Partition by death.location
order by death.location, death.date) as RollingVaxxed
From PortfolioProject.dbo.CovidDeath death
JOIN PortfolioProject.dbo.CovidVax vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not NULL
--order by 2,3
)

Select *, (RollingVaxxed/population)*100 as PctVaxPop
From PopvVax

--Creating Temp Table
Drop table if exists #PercentPopVaxxed --drops anything previously existing 
Create table #PercentPopVaxxed
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingVaxxed numeric
)
Insert into #PercentPopVaxxed
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as bigint)) OVER (Partition by death.location
order by death.location, death.date) as RollingVaxxed
From PortfolioProject.dbo.CovidDeath death
JOIN PortfolioProject.dbo.CovidVax vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not NULL
--order by 2,3
Select *, (RollingVaxxed/population)*100 as PctVaxPop
From #PercentPopVaxxed

--Creating a view

Create View PercentPopVac as 
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as bigint)) OVER (Partition by death.location
order by death.location, death.date) as RollingVaxxed
From PortfolioProject.dbo.CovidDeath death
JOIN PortfolioProject.dbo.CovidVax vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not NULL
--order by 2,3
