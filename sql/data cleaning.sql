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


/* 7. DELETE UNNECESSARY COLUMNS (DID NOT EXECUTE)

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN CREATED_DATE;

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN LAST_MODIFIED_DATE;

ALTER TABLE dbo.Chicago311_raw
DROP COLUMN CLOSED_DATE;

*/

