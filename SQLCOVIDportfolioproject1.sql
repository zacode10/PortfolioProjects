--select*
--from portfolioproject..coviddeaths
--order by 3,4

--select *
--from portfolioproject..covidvaccinations
--order by 3,4

--select data that we are going to be using
--select Location, date, total_cases, new_cases, total_deaths, population
--from portfolioproject..coviddeaths
--order by 1,2

--looking at total cases vs total deaths
--shows likelihood of dying if you contract covid in your country
SELECT
  location,
  MAX(total_cases) as Highest_infectioncount,
  population,
  CASE 
    WHEN MAX(total_cases) = 0 THEN NULL
    ELSE (CAST(MAX(total_cases) AS float) / population) * 100
  END AS InfectedpopulationPercentage
FROM PortfolioProject..coviddeaths
GROUP BY location, population
ORDER BY InfectedpopulationPercentage

--looking at total cases vs population
SELECT
  location,
  MAX(total_cases) as Highest_infectioncount,
  population,
  CASE 
    WHEN MAX(total_cases) = 0 THEN NULL
    ELSE (CAST(MAX(total_cases) AS float) / population) * 100
  END AS InfectedpopulationPercentage
FROM PortfolioProject..coviddeaths
--where location like '%guyana%'
GROUP BY location, population
ORDER BY InfectedpopulationPercentage desc

--showing countries with highest death count per population
SELECT
  location,
  MAX(total_deaths) as TotalDeathcount,
  population,
  CASE 
    WHEN MAX(total_cases) = 0 THEN NULL
    ELSE (CAST(MAX(total_deaths) AS float) / population) * 100
  END AS DeathPercentage
FROM PortfolioProject..coviddeaths
--where location like '%guyana%'
GROUP BY location, population
ORDER BY DeathPercentage desc

--continent breakdown by death count
SELECT
  continent, MAX(cast(total_deaths as int)) as TotalDeathcount
from portfolioproject..coviddeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeathcount desc

--global numbers
SELECT
  date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, Nullif(sum(new_deaths), 0)/nullif(sum(new_cases), 0)*100 as deathpercentage
from portfolioproject..coviddeaths
GROUP BY date
ORDER BY 1,2

--looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
from portfolioproject..coviddeaths dea
join portfolioproject..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--use CTE
with PopvsVac (Continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(convert(bigint,vac.new_vaccinations)) over (Partition By DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM [portfolioproject]..CovidDeaths as DEA
JOIN [portfolioproject]..CovidVaccinations as VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null
--ORDER BY 2, 3
)
select *, (rollingpeoplevaccinated/population)*100
from PopvsVac

--temp table
DROP table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(convert(bigint,vac.new_vaccinations)) over (Partition By DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM [portfolioproject]..CovidDeaths as DEA
JOIN [portfolioproject]..CovidVaccinations as VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null
--ORDER BY 2, 3
select *, (rollingpeoplevaccinated/population)*100
from #PercentPopulationVaccinated

--creating view to store data for later visualizations
create view PercentPopulationVaccinated as
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(convert(bigint,vac.new_vaccinations)) over (Partition By DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM [portfolioproject]..CovidDeaths as DEA
JOIN [portfolioproject]..CovidVaccinations as VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null
--ORDER BY 2, 3
