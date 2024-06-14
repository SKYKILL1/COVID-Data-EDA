SELECT * FROM CovidDeaths$

SELECT * FROM CovidVaccinations$

-- FINDING DISTINCT COUNTIRES 

SELECT DISTINCT location
FROM CovidDeaths$
ORDER BY location;

SELECT COUNT(DISTINCT location)
FROM CovidDeaths$

--total cases vs total deaths

SELECT location,date , total_cases,total_deaths , (total_deaths/total_cases)*100 as percentage
FROM CovidDeaths$
order by 1 ,2 


SELECT location,date , total_cases,total_deaths , (total_deaths/total_cases)*100 as percentage
FROM CovidDeaths$
WHERE location = 'India'
order by 5 desc


--looking at countries with highest infection rate compared to population

SELECT location ,population,MAX(total_cases) as highest_infection_count , MAX(total_cases)/population*100 as percatage_pop_infected
FROM CovidDeaths$
GROUP BY location, population
ORDER BY 4 desc


--Showing countries with highest death count per population

SELECT location , MAX(cast(total_deaths as int)) as highest_death_count , MAX(cast(total_deaths as int))/population *100 
FROM CovidDeaths$
where continent is not null
GROUP BY location ,population
ORDER BY 2 desc , 3 desc

-- showing continent with highest death count per population

SELECT continent , MAX(cast(total_deaths as int)) as highest_death_count 
FROM CovidDeaths$
where continent is not null
GROUP BY continent
ORDER BY 2 desc 


--Global Numbers

SELECT date , sum(new_cases) new_cases ,sum(cast(total_cases as int)) as total_cases, sum(cast(total_deaths as int)) as total_deaths, sum(cast(total_deaths as int))/sum(cast(total_cases as int))*100
FROM CovidDeaths$
where continent is not null
GROUP BY date
order by date

SELECT sum(new_cases) as new_cases ,sum(cast(total_cases as int)) as total_cases, sum(cast(total_deaths as int)) as total_deaths
FROM CovidDeaths$
where continent is not null
	
--looking at totalpopulation vs vaccinations

SELECT * FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location 
AND CD.date = CV.date

SELECT cd.continent , cd.location, cd.date , cd.population , cv.new_vaccinations
, sum(cast(cv.new_vaccinations as int)) OVER (PARTITION BY cv.location order by cv.location,cv.date) as rollingpeoplevaccinated
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location 
AND CD.date = CV.date
WHERE cd.continent is not null
order by 2, 3

With rollingpeoplevaccinated as(
SELECT cd.continent , cd.location, cd.date , cd.population , cv.new_vaccinations
, sum(cast(cv.new_vaccinations as int)) OVER (PARTITION BY cv.location order by cv.location,cv.date) as rollingpeoplevaccinated
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location 
AND CD.date = CV.date
WHERE cd.continent is not null
--order by 2, 3
)
SELECT *, rollingpeoplevaccinated/population*100 as percentage_people_vaccinated_per_population
FROM rollingpeoplevaccinated
order by 2 , 3

DROP TABLE IF EXISTS #rollingpeoplevaccinated
CREATE TABLE #rollingpeoplevaccinated(
continent nvarchar(255),
location nvarchar (255),
date DATETIME,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #rollingpeoplevaccinated
SELECT cd.continent , cd.location, cd.date , cd.population , cv.new_vaccinations
, sum(cast(cv.new_vaccinations as int)) OVER (PARTITION BY cv.location order by cv.location,cv.date) as rollingpeoplevaccinated
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location 
AND CD.date = CV.date
WHERE cd.continent is not null
--order by 2, 3

SELECT *,rollingpeoplevaccinated/population*100 as percentage_people_vaccinated_per_population
FROM #rollingpeoplevaccinated;

--CREATING view to store data for later vizualizations

CREATE VIEW rollingpeoplevaccinated as
SELECT cd.continent , cd.location, cd.date , cd.population , cv.new_vaccinations
, sum(cast(cv.new_vaccinations as int)) OVER (PARTITION BY cv.location order by cv.location,cv.date) as rollingpeoplevaccinated
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location 
AND CD.date = CV.date
WHERE cd.continent is not null
--order by 2, 3


SELECT *,rollingpeoplevaccinated/population*100 as percentage_people_vaccinated_per_population
FROM rollingpeoplevaccinated;


 
--Compare the growth rate of cases between two countries:

SELECT a.location,a.date ,a.cases , b.location,b.date , b.cases
FROM (SELECT location,date,sum(new_cases) as cases FROM CovidDeaths$ WHERE location = 'India' GROUP BY date,location) a 
JOIN
(SELECT location,date, sum(new_cases) as cases FROM CovidDeaths$ WHERE location = 'South America' GROUP BY date,location) b 
ON a.date = b.date

--Calculate cumulative cases, deaths over time for each country


SELECT * FROM CovidDeaths$

SELECT location,date,sum(cast(total_cases as int)) as total_cases,sum(cast(total_deaths as int)) as total_deaths
FROM CovidDeaths$ CD 
GROUP BY date,location


--Calculate the daily percentage change in cases for each country

SELECT location , date, new_cases , LAG(new_cases,1) OVER (PARTITION BY location ORDER BY date) as previous_day_cases,
(new_cases - LAG(new_cases,1) OVER (PARTITION BY location ORDER BY date))/LAG(new_cases,1) OVER (PARTITION BY location ORDER BY date)*100 as percentage_change_in_cases FROM CovidDeaths$
WHERE new_cases > 0 
ORDER BY location,date;

--Identify the country with the highest number of new cases on each day

WITH rank_cases as (select location, date, new_cases , RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) as rank
FROM CovidDeaths$)
SELECT location , date , new_cases 
FROM rank_cases
where rank = 1


--Find the top 5 countries with the highest average daily cases
WITH AVG_CASES AS (
SELECT location , AVG(new_cases) as avg_cases 
FROM CovidDeaths$ 
Group BY location
)
SELECT top 5 location , avg_cases 
FROM AVG_CASES
ORDER BY avg_cases desc


--calculate cases per capita

SELECT location , date , new_cases, total_cases ,population,(total_cases/population) as cases_per_capita
FROM CovidDeaths$
ORDER BY cases_per_capita desc

