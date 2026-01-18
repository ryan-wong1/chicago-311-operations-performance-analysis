## Data Source

This project uses public 311 Service Requests data from the City of Chicago Open Data Portal.

Dataset:  
Chicago 311 Service Requests  
https://data.cityofchicago.org/Service-Requests/311-Service-Requests/v6vf-nfxy

## Scope Used in This Project
- Timeframe analyzed: January 2024 – Sept 2024
- Filter applied on the `CREATED_DATE` column (2024-01-01 to 2024-09-30)
- Around ~1.5 million records

## Data Availability
Due to GitHub file size limits, the raw and cleaned datasets are not stored in this repository.

The cleaned and analysis-ready dataset can be fully reproduced by:
1. Accessing the source dataset via the City of Chicago Open Data Portal
2. Filtering records on `CREATED_DATE` between 2024-01-01 and 2024-09-30
3. Running my SQL cleaning script located at `/sql/data cleaning.sql`
