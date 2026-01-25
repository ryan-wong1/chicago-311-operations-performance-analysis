USE [311chicago];
GO

/* Run all 1.5M rows*/
select *
from dbo.Chicago311_raw;

/* Run X rows*/
select top(200) *
from dbo.Chicago311_raw;

/*
DATA CLEANING TO DO:
- Update 'create_date', 'last_modified_date', 'closed_date' into DATETIME format. Currently string. Create new columns w/ reflected values.
- How many days it took to complete task [closed_date - created date = days resolved]
- How many days has this issue been unresolved ['2024-09-30'(MAX) - created date = days unresolved]
- Check for spelling inconsistancies for values for X columns (EX: 'Check for Leak' vs 'CHECK LEAK' needs to be converted to same exact value)
- Closed_date_dt has either 1. datetime (closed) or 2. NULL (open/not solved). Create new is_open and is_closed columns, add either 0 or 1 as value. is_open = 1 (open/true) or 2 (closed/false). is_closed = 1 (closed/true) or 2 (open/ false)
- Categorize 'days_unresolved' into groups (0-1 week, 2-4 weeks, 1-3 months, over 3 months). Name this column 'days_unresolved_groups' 
- Create new column and convert 'COMMUNITY AREA' column codes (1-77) into actual area name. EX: 19 = 'Belmont Cragin', 30 = 'South Lawndale')
- Delete unnecessary columns (if needed)
*/


/* 1. Update 'create_date', 'last_modified_date', 'closed_date' into DATETIME format. Currently string. Create new columns w/ reflected values. */

SELECT top (50)
	CREATED_DATE, try_convert(datetime2, REPLACE(LTRIM(CREATED_DATE), '"', '')) AS created_date_convert
FROM dbo.Chicago311_raw;


select top(50) 
	last_modified_date, try_convert(datetime2, replace(trim(last_modified_date),'"','')) as last_modified_date_convert
from dbo.chicago311_raw;
	

select top(50)
	closed_date, try_convert(datetime2, replace(ltrim(closed_date),'"','')) as closed_date_convert
from dbo.chicago311_raw;

Alter table dbo.chicago311_raw
add 
	created_date_dt datetime2,
	last_modified_date_dt datetime2,
	closed_date_dt datetime2;

update dbo.chicago311_raw
set
	created_date_dt = try_convert(datetime2, REPLACE(LTRIM(CREATED_DATE), '"', '')),
	last_modified_date_dt = try_convert(datetime2, replace(trim(last_modified_date),'"','')),
	closed_date_dt = try_convert(datetime2, replace(ltrim(closed_date),'"',''));


/* 2. How many days it took to complete task [closed_date - created date = days resolved] */

select created_date_dt 
from dbo.Chicago311_raw
where created_date_dt is NULL;        /*0 values*/

select count(*)
from dbo.Chicago311_raw
where closed_date_dt is NULL;         /*29k values*/

select top(1000) created_date_dt, closed_date_dt, DATEDIFF(day, created_date_dt, closed_date_dt) as days_resolved
from dbo.Chicago311_raw

alter table dbo.chicago311_raw
add days_resolved int;

update dbo.Chicago311_raw
set days_resolved = DATEDIFF(day, created_date_dt, closed_date_dt)

select days_resolved
from dbo.Chicago311_raw
where days_resolved < 0;       /*no negative values*/


/* 3. How many days has this issue been unresolved ['2024-09-30'(MAX) - created date = days unresolved]
closed_date_dt = NULL value means this request has been unsolved and is still open */

alter table dbo.chicago311_raw
add days_unresolved int;

update dbo.Chicago311_raw
set days_unresolved = DATEDIFF(day, created_date_dt, '2024-09-30')
where closed_date_dt is NULL;

select days_unresolved, count(days_unresolved) as cnt
from dbo.Chicago311_raw
group by days_unresolved
order by days_unresolved;


/* 4. Check for spelling inconsistancies for values for X columns (EX: 'Check for Leak' vs 'CHECK LEAK' needs to be converted to same exact value)
PRIORITY: SR_TYPE, CREATED_DEPARTMENT, OWNER_DEPARTMENT, STATUS, ORIGIN  */

select trim(SR_TYPE) as sr_type, count(*) as cnt       /* PASS */
from dbo.Chicago311_raw
group by trim(SR_TYPE)
order by count(*) desc;

select trim(CREATED_DEPARTMENT) as created_dept, count(*) as cnt      /* PASS */
from dbo.Chicago311_raw
group by trim(CREATED_DEPARTMENT)
order by count(*) desc;

select trim(OWNER_DEPARTMENT) as owner_dept, count(*) as cnt      /* PASS */
from dbo.Chicago311_raw
group by trim(OWNER_DEPARTMENT)
order by count(*) desc;

select trim(STATUS) as status, count(*) as cnt      /* PASS */
from dbo.Chicago311_raw
group by trim(STATUS)
order by count(*) desc;

select trim(ORIGIN) as origin, count(*) as cnt       /* PASS */
from dbo.Chicago311_raw
group by trim(ORIGIN)
order by count(*) desc;


/* 5. closed_date_dt has either 1. datetime (closed) or 2. NULL (open/not solved). Create new is_open and is_closed columns, add either 0 or 1 as value. is_open = 1 (open/true) or 2 (closed/false). is_closed = 1 (closed/true) or 2 (open/ false) */

alter table dbo.chicago311_raw
add is_open int;

alter table dbo.chicago311_raw
add is_closed int;

update dbo.Chicago311_raw
set
	is_open = iif(closed_date_dt is NULL, 1, 0),
	is_closed = iif(closed_date_dt is NULL, 0, 1);


/* 6. Categorize 'days_unresolved' into groups (0-1 week, 2-4 weeks, 1-3 months, over 3 months). Name this column 'days_unresolved_groups' */

alter table dbo.chicago311_raw
add days_unresolved_groups varchar(50);

update dbo.Chicago311_raw
set 
	days_unresolved_groups = 
	case
		when days_unresolved between 0 and 7 then '0 - 1 week'
		when days_unresolved between 8 and 30 then '1 - 4 weeks'
		when days_unresolved between 31 and 90 then '1 - 3 months'
		when days_unresolved > 90 then '3+ months'
		else NULL
	end;

alter table dbo.chicago311_raw
add community_area_name varchar(50);


/* 7. Create new column and convert 'COMMUNITY AREA' column codes (1-77) into actual area name. EX: 19 = 'Belmont Cragin', 30 = 'South Lawndale') */

update dbo.Chicago311_raw
set community_area_name =
    case try_cast(replace(community_area, '"', '') as int)
        when 1 then 'Rogers Park'
        when 2 then 'West Ridge'
        when 3 then 'Uptown'
        when 4 then 'Lincoln Square'
        when 5 then 'North Center'
        when 6 then 'Lake View'
        when 7 then 'Lincoln Park'
        when 8 then 'Near North Side'
        when 9 then 'Edison Park'
        when 10 then 'Norwood Park'
        when 11 then 'Jefferson Park'
        when 12 then 'Forest Glen'
        when 13 then 'North Park'
        when 14 then 'Albany Park'
        when 15 then 'Portage Park'
        when 16 then 'Irving Park'
        when 17 then 'Dunning'
        when 18 then 'Montclare'
        when 19 then 'Belmont Cragin'
        when 20 then 'Hermosa'
        when 21 then 'Avondale'
        when 22 then 'Logan Square'
        when 23 then 'Humboldt Park'
        when 24 then 'West Town'
        when 25 then 'Austin'
        when 26 then 'West Garfield Park'
        when 27 then 'East Garfield Park'
        when 28 then 'Near West Side'
        when 29 then 'North Lawndale'
        when 30 then 'South Lawndale'
        when 31 then 'Lower West Side'
        when 32 then 'Loop'
        when 33 then 'Near South Side'
        when 34 then 'Armour Square'
        when 35 then 'Douglas'
        when 36 then 'Oakland'
        when 37 then 'Fuller Park'
        when 38 then 'Grand Boulevard'
        when 39 then 'Kenwood'
        when 40 then 'Washington Park'
        when 41 then 'Hyde Park'
        when 42 then 'Woodlawn'
        when 43 then 'South Shore'
        when 44 then 'Chatham'
        when 45 then 'Avalon Park'
        when 46 then 'South Chicago'
        when 47 then 'Burnside'
        when 48 then 'Calumet Heights'
        when 49 then 'Roseland'
        when 50 then 'Pullman'
        when 51 then 'South Deering'
        when 52 then 'East Side'
        when 53 then 'West Pullman'
        when 54 then 'Riverdale'
        when 55 then 'Hegewisch'
        when 56 then 'Garfield Ridge'
        when 57 then 'Archer Heights'
        when 58 then 'Brighton Park'
        when 59 then 'McKinley Park'
        when 60 then 'Bridgeport'
        when 61 then 'New City'
        when 62 then 'West Elsdon'
        when 63 then 'Gage Park'
        when 64 then 'Clearing'
        when 65 then 'West Lawn'
        when 66 then 'Chicago Lawn'
        when 67 then 'West Englewood'
        when 68 then 'Englewood'
        when 69 then 'Greater Grand Crossing'
        when 70 then 'Ashburn'
        when 71 then 'Auburn Gresham'
        when 72 then 'Beverly'
        when 73 then 'Washington Heights'
        when 74 then 'Mount Greenwood'
        when 75 then 'Morgan Park'
        when 76 then 'O’Hare'
        when 77 then 'Edgewater'
        else 'Unknown'
    end;

	
/* 8. DELETE UNNECESSARY COLUMNS (DID NOT EXECUTE)

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN CREATED_DATE;

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN LAST_MODIFIED_DATE;

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN CLOSED_DATE;

*/

