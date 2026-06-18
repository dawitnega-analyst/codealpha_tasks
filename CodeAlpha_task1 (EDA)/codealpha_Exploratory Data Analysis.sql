/*

Cleaning Data in MySQL Queries

*/

-------------------------------------------------------------------------------------------------------------
-- Creating a Copy to Clean the Data

SELECT *
FROM layoffs;

CREATE TABLE layoffs_cleaned
LIKE layoffs;

INSERT layoffs_cleaned
SELECT *
FROM layoffs;

-------------------------------------------------------------------------------------------------------------
-- giving them unique identifier

SELECT *,
		ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
					`date`, stage, country, funds_raised_millions
                    ) AS row_num
FROM layoffs_cleaned;

-------------------------------------------------------------------------------------------------------------
-- identifiying duplicates

WITH duplicate_rows AS (
	SELECT *,
			ROW_NUMBER() OVER(
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
						`date`, stage, country, funds_raised_millions
                        ) AS row_num
			FROM layoffs_cleaned)
SELECT *
FROM duplicate_rows
WHERE row_num > 1;

-------------------------------------------------------------------------------------------------------------
-- creating a new table to remove the duplicates

CREATE TABLE `layoffs_cleaned2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- populating the new table

INSERT INTO layoffs_cleaned2
SELECT *,
ROW_NUMBER() OVER (
					PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
                    `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_cleaned;

-------------------------------------------------------------------------------------------------------------
-- removing the duplicates

DELETE
FROM layoffs_cleaned2
WHERE row_num > 1;

-------------------------------------------------------------------------------------------------------------
-- Standardizing data

UPDATE layoffs_cleaned2
SET company = TRIM(company);

UPDATE layoffs_cleaned2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_cleaned2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

UPDATE layoffs_cleaned2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_cleaned2
MODIFY COLUMN `date` DATE;

-------------------------------------------------------------------------------------------------------------
-- Populating Nulls and Blank Values

UPDATE layoffs_cleaned2
SET industry = NULL 
WHERE industry = '';

UPDATE layoffs_cleaned2 t1
JOIN layoffs_cleaned2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Removing Null, Blank Values, and Unneccessary Column

 DELETE
 FROM layoffs_cleaned2
 WHERE total_laid_off IS NULL
 AND percentage_laid_off IS NULL;
 
 DELETE
 FROM layoffs_cleaned2
 WHERE industry IS NULL
 AND total_laid_off IS NULL;

ALTER TABLE layoffs_cleaned2
DROP COLUMN row_num;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

/*

Exploratory Data Analysis

*/

--------- Overall Layoffs Impact --------

-- Total number of layoffs

SELECT SUM(total_laid_off) total_laid_offs
FROM layoffs_cleaned2;

-- Number of companies affected

SELECT COUNT(DISTINCT company) num_companies
FROM layoffs_cleaned2;

-- Number of  industries affected

SELECT COUNT(DISTINCT industry) num_industries
FROM layoffs_cleaned2;

-- Average layoffs size

SELECT AVG(total_laid_off) AS avg_layoff_size
FROM layoffs_cleaned2;

-- Largest layoff company

SELECT company, 
		total_laid_off
FROM layoffs_cleaned2
ORDER BY total_laid_off DESC
LIMIT 10;

--------------------------------------------------------------------------------------------------------------------

------------------ Company Analysis ---------------

-- companies with most layoffs

SELECT company, 
		SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
GROUP BY company
ORDER BY layoffs DESC;

-- Companies with multiple layoff rounds

SELECT company,
		COUNT(*) AS layoff_events
FROM layoffs_cleaned2
GROUP BY company
ORDER BY layoff_events DESC;

---------------- Industry Analysis -------------------------

-- Layoffs by industry

SELECT industry,
		SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
GROUP BY industry
ORDER BY layoffs DESC;

-- Average layoff size by industry

SELECT industry,
		AVG(total_laid_off) AS avg_layoff
FROM layoffs_cleaned2
GROUP BY industry
ORDER BY avg_layoff DESC;

--------------------- Geographic Analysis ------------------------

-- Layoffs by country

SELECT country,
		SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
GROUP BY country
ORDER BY layoffs DESC;

SELECT location,
		SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
GROUP BY location
ORDER BY layoffs DESC;

--------------------------- Funding Stage Analysis ------------------------------------

-- Layoffs by stage

SELECT stage,
		SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY layoffs DESC;

-- Average layoffs

SELECT stage,
		AVG(total_laid_off) AS avg_layoff
FROM layoffs_cleaned2
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY avg_layoff DESC;

--------------------------- Funding Analysis --------------------------------

-- Companies with the highest funding

SELECT company,
		SUM(funds_raised_millions) AS funds_raised_in_millions
FROM layoffs_cleaned2
GROUP BY company
ORDER BY funds_raised_in_millions DESC;

-- Funding vs Layoffs

SELECT company,
		funds_raised_millions,
        total_laid_off
FROM layoffs_cleaned2
WHERE funds_raised_millions IS NOT NULL
AND total_laid_off IS NOT NULL;

--------------------------- Time_Series Analysis --------------------------------------

-- Monthly layoffs

SELECT 
	YEAR(`date`) AS year,
    MONTH(`date`) AS month,
    SUM(total_laid_off) AS layoff
FROM layoffs_cleaned2
WHERE YEAR(`date`) IS NOT NULL 
AND MONTH(`date`) IS NOT NULL
GROUP BY YEAR(`date`), MONTH(`date`) 
ORDER BY year, month;

-- Yearly layoffs

SELECT
	YEAR(`date`) AS year,
    SUM(total_laid_off) AS layoffs
FROM layoffs_cleaned2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`) 
ORDER BY year;

-- Top 5 industries per year by total_layoffs

WITH total_layoffs_per_year AS (
	SELECT YEAR(`date`) AS year,
			company,
			SUM(total_laid_off) AS layoffs
	FROM layoffs_cleaned2
	WHERE total_laid_off IS NOT NULL
	GROUP BY year, company),
	ranked_companies AS (
    SELECT company,
			layoffs,
            year,
			RANK() OVER (PARTITION BY year ORDER BY layoffs DESC) AS ranking
	FROM total_layoffs_per_year)
SELECT year,
		company,
		layoffs,
        ranking
FROM ranked_companies
WHERE ranking <= 5
AND year IS NOT NULL;

-- Country contribution to layoffs by percent

WITH total_layoffs AS (
	SELECT country,
			SUM(total_laid_off) AS layoffs
	FROM layoffs_cleaned2
    GROUP BY country),
    overall_totals AS ( 
    SELECT country,
			layoffs,
            SUM(layoffs) OVER() AS overall_total
	FROM total_layoffs),
    percentages AS (
    SELECT country,
			layoffs,
            overall_total,
            layoffs * 100.0/ overall_total AS perc_contribution
	FROM overall_totals)
SELECT *
FROM percentages
WHERE layoffs IS NOT NULL 
AND perc_contribution IS NOT NULL
ORDER BY perc_contribution DESC;

-- Funding quartiles

WITH total_layoffs AS (
	SELECT company,
			SUM(funds_raised_millions) AS tot_fund_raised_in_millions
	FROM layoffs_cleaned2
    GROUP BY company),
    quartile_funding AS (
    SELECT company, 
			tot_fund_raised_in_millions,
            NTILE(4) OVER(ORDER BY tot_fund_raised_in_millions DESC) AS quartile
	FROM total_layoffs)
SELECT *
FROM quartile_funding;


			
















