-- Creating a staging table to store a temporary copy of layoffs data for cleaning and transformation
CREATE TABLE world_layoffs.layoffs_staging LIKE world_layoffs.layoffs;

-- Inserting all records from the original layoffs table into the staging table
INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

-- Removing duplicate records based on key attributes using a CTE with ROW_NUMBER
WITH DELETE_CTE AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM world_layoffs.layoffs_staging
)
-- Keeping only the first occurrence of duplicate records and deleting the rest
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
    FROM DELETE_CTE
) AND row_num > 1;

-- Standardizing missing industry values by converting empty strings to NULL
UPDATE world_layoffs.layoffs_staging 
SET industry = NULL 
WHERE industry = '';

-- Filling missing industry values based on the same company’s existing industry data
UPDATE world_layoffs.layoffs_staging t1
JOIN world_layoffs.layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Standardizing industry names by grouping similar values under one category
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Ensuring consistency in country names by removing trailing periods
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- Converting date column from string format to proper DATE format
UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Altering the column to explicitly store date values in DATE type
ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;

-- Removing records with no layoff data to maintain data relevance
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
