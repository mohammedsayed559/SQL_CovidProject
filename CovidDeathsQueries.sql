/*select * from covidDB..CovidDeaths
order by 3,4

select * from covidDB..CovidVaccinations
order by 3,4*/


-- Select Data that we are gonna be using 
declare @ColumnNamesVaccination varchar(MAX);
SET @ColumnNamesVaccination = (
select STRING_AGG(COLUMN_NAME,'
')  
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'CovidVaccinations'
);
PRINT @ColumnNamesVaccination;

-- Select Data that we are gonna be using 
declare @ColumnNamesDeath varchar(MAX);
SET @ColumnNamesDeath = (
select STRING_AGG(COLUMN_NAME,'	,  ') 
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'CovidDeaths'
);
PRINT @ColumnNamesDeath;

select location	,  date	,  total_cases , new_cases,total_deaths ,  population
from CovidDeaths
order by 1,2
--Looking for total deaths Vs total cases
-- shows likelihood of dying if you contract covid in your country
select location	,  date	,  total_cases ,total_deaths , population, (total_deaths/total_cases)*100 as 'totalDeathToTotalCases' 
from CovidDeaths
where location like '%egyp%'
order by 1,2

-- Total Cases Vs Population 
--shows the percent of population that got the covid
select location	,  date	,  total_cases ,total_deaths , population, (total_cases/population)*100 as 'totalCasesToPopulation' 
from CovidDeaths
where location like '%gyp%'
order by 1,2;


--Get the MAX() of total cases and its % of the population 
select MAX(total_cases), MAX((total_cases/population)*100)
from CovidDeaths 

-- what country has the highest infection rate
select location,population, MAX(total_cases) as maxTotalCases, MAX((total_cases/population)*100) as maxInfectedPercent
from CovidDeaths
where population is not null
group by location,population
having MAX(total_cases) is not null
order by maxInfectedPercent desc
/*
#GROUP BY Clause
	The GROUP BY location, population groups the rows in the CovidDeaths table by unique combinations of location and population.
	Each unique pair of location and population will form a group.	
	This ensures that aggregate functions like MAX() are applied within these groups.
#Aggregated Columns
	MAX(total_cases) AS maxTotalCases:
	For each group, it calculates the maximum value of total_cases.
	Example: If the group contains multiple rows for a location/population pair, it picks the largest total_cases.
	Example Table and Output
Suppose the CovidDeaths table has the following data:
location	population	total_cases
USA			330000000	10000000
USA			330000000	20000000
India		1390000000	5000000
India		1390000000	7000000
Italy		60000000	3000000
After Grouping and Aggregation:
location	population	maxTotalCases	maxPercent
USA			330000000	20000000		6.06
India		1390000000	7000000			0.50
Italy		60000000	3000000			5.00

/*ALTER table CovidDeaths
ALTER COLUMN new_deaths int
ALTER table CovidDeaths
ALTER COLUMN date date
*/

*/

-- Showing the country that has the highest DeathCount per population
	-- COUNT() counts the number of rows in a group, but it doesn't directly calculate DeathCount per population.
	-- TypeCasting in SQL as The following: MAX(cast(total_deaths as int))

select location, MAX(total_deaths) as MaxTotalDeaths
from CovidDeaths
where continent is not null AND continent = 'North America'
group by location
having  MAX(total_deaths) is not null 
order by MaxTotalDeaths desc


select location, MAX(total_deaths) as MaxTotalDeaths
from CovidDeaths
where continent is null and location = 'North America'
group by location
order by MaxTotalDeaths desc

-- there are daily records for each continent  
select location
from CovidDeaths
where continent is null and location = 'North America'


/*select DISTINCT continent from CovidDeaths
select DISTINCT location from CovidDeaths where continent like '%orth%r%ca' order by location
*/

--Showing the highest cases over continents 
select location,MAX(total_cases) as maxTotalCases, SUM(new_cases) as totalNewCases, MAX(total_cases) - SUM(new_cases) as diff
from CovidDeaths
where continent is null
group by location

--Showing the highest Deaths cases
SELECT location,max(total_deaths) as totalDeaths 
from CovidDeaths 
where continent is null 
group by location 
order by 2 DESC
--select location,new_cases,new_deaths,continent from CovidDeaths where location = 'International'
SELECT location,max(total_deaths) as totalDeaths 
from CovidDeaths 
where continent is not null AND continent like '%orth%r%ca'
group by location 
order by 2 DESC
-----------------------
select date from CovidDeaths group by date

--showing totalSumCasesOverTheWorld
select sum(SumGlobalNewCases) as SumTotalCasesOverTheWorld 
	from 
	(
	select date, sum(new_cases) as SumGlobalNewCases,sum(new_deaths) as SumGlobalNewDeaths 
	from CovidDeaths 

	group by date 
	having sum(new_cases) is not null  
	

	)
	as groupedData




	select sum(new_cases) as SumGlobalNewCases,sum(new_deaths) as SumGlobalNewDeaths,sum(new_deaths)/sum(new_cases) *100 as PercentOfDeaths
	from CovidDeaths 
	having sum(new_cases) <> 0 

	--Covid Vaccinations

	Select * from CovidVaccinations
	where continent is not null 

	select * from CovidDeaths dea join CovidVaccinations vac
	on dea.date = vac.date and dea.location = vac.location
	order by dea.location
	


	--looking at total population vs vaccination
	select d.date,d.location,d.population,v.total_vaccinations,v.new_vaccinations from CovidDeaths d join CovidVaccinations v
	on d.date = v.date and d.location = v.location
	where d.continent is not null AND v.new_vaccinations is not null
	order by 2	

	--Showing the cummulative vaccinations per day rollingCount for the sum of vaccination per day then add the total poputlation VS total vaccinations ->create either Temp Table or CTE
/*
	select d.date,d.location,v.new_vaccinations,SUM(CONVERT(int,v.new_vaccinations)) OVER (partition by d.location order by d.location,v.new_vaccinations) as RollingCountVaccinations
	from CovidDeaths d join CovidVaccinations v 
	on d.date = v.date and d.location = v.location
	where d.continent is not null and new_vaccinations is not null
*/


 --sum() gives a one record but what if i want to calculate a cumulative column values???,
 -- You have to use this window function(sum()) with over then partition and order by some column
 -- in our case the partition is based on the location but in this case it will sum all the new cases and add the end value at every single cell;
 -- we need to calculate the cumulative new cases row by row so how??
 /*
 PARTITION BY location → The data is grouped by location (each country or region gets its own independent calculation).
 ORDER BY date, location → Within each location, the data is sorted by date (and then by location for tie-breaking).
 Unlike GROUP BY, the OVER function keeps all rows, adding a calculated column (cumNewCases). 
 GROUP BY would collapse rows, showing only one row per (date, location).
 	SELECT date, location,new_cases, SUM(new_cases) 
	FROM CovidDeaths
	GROUP BY date, location,new_cases;
PARTITION BY location → Resets calculations per location.
ORDER BY date → Ensures SUM() accumulates chronologically.
Window Function (OVER()) → Keeps all rows intact while calculating a running total.
*/
/*select date, location,new_cases,sum(new_cases) over (partition by location order by date, location) as cumNewCases
from CovidDeaths*/

 -- Using CTE -- Common Table Expression -- to use RollingCountForNewVaccinations in new calculation (RollingCountForNewVaccinations/population)*100

 with popVsVacPercent (date,location,population,new_vaccinations,RollingCountForNewVaccinations)
 as (
	 select d.date,d.location,d.population,v.new_vaccinations,
	 sum(CONVERT(INT,v.new_vaccinations)) over(Partition by v.location order by d.date,d.location) as RollingCountForNewVaccinations
	 
	 from CovidVaccinations v join CovidDeaths d 
	 on v.date = d.date and v.location = d.location 
	 where v.new_vaccinations is not null and d.continent is not null 
  )
  select * ,(CAST(RollingCountForNewVaccinations AS FLOAT) / population) * 100 as VaccinatedPeopleToPopulationPercent
  from popVsVacPercent


  -- Using Temp Table:
   create table VaccinatedPopulationPercent
   (
    date date
   ,location nvarchar(60)
   ,population numeric
   ,new_vaccinations numeric
   ,RollingCountForNewVaccinations numeric)


   insert into VaccinatedPopulationPercent
   select d.date,d.location,d.population,v.new_vaccinations,
	 sum(CONVERT(INT,v.new_vaccinations)) over(Partition by v.location order by d.date,d.location) as RollingCountForNewVaccinations
	 
	 from CovidVaccinations v join CovidDeaths d 
	 on v.date = d.date and v.location = d.location 
	 where v.new_vaccinations is not null and d.continent is not null 


	 select * from VaccinatedPopulationPercent