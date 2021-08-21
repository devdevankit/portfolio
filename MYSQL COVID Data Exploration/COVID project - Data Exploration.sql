/*
Covid 19 Data Exploration 

Skills used: 
Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

use covid;

select * from covid.coviddeaths;

select * from covid.covidvaccinations;

select * from covid.coviddeaths where continent is not null
order by Location,date;

select Location, date, total_cases, new_cases, total_deaths, population
from covid.coviddeaths
where continent is not null 
order by Location,date;


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from covid.coviddeaths
where location like '%india%'
and continent is not null 
order by Location,date;


-- Total Cases vs Population
-- Shows what percentage of population infected with covid

select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
from covid.coviddeaths
-- where location like '%india%'
order by Location,date;


-- Countries with highest infection rate compared to population

select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
from covid.coviddeaths
-- where location like '%india%'
group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

select Location, MAX(cast(Total_deaths as decimal)) as TotalDeathCount
from covid.coviddeaths
where continent is not null 
group by Location
order by TotalDeathCount desc;


-- Showing contintents with the highest death count per population

select continent, MAX(cast(Total_deaths as decimal)) as TotalDeathCount
from covid.coviddeaths
where continent is not null 
group by continent
order by TotalDeathCount desc;


-- World Total

select (new_cases) as total_cases, SUM(cast(new_deaths as decimal)) as total_deaths, 
		SUM(cast(new_deaths as decimal))/SUM(New_Cases)*100 as DeathPercentage
from covid.coviddeaths
where continent is not null 
-- group By date
order by total_cases,total_deaths;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations,decimal)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from covid.coviddeaths dea
join covid.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by continent,location;


-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations,decimal)) OVER (Partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
from covid.coviddeaths dea
join covid.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
select *, (RollingPeopleVaccinated/Population)*100 from PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

-- DROP Table if exists PercentPopulationVaccinated;
create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);


insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations,decimal)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from covid.coviddeaths dea
join covid.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date ;

select *, (RollingPeopleVaccinated/Population)*100
from PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations,decimal)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from covid.coviddeaths dea
join covid.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;

