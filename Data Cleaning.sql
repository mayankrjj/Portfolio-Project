-- Create a staging table for cleaning
CREATE TABLE world_layoffs.layoffs_staging LIKE world_layoffs.layoffs;
INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

-- Remove Duplicates
WITH DELETE_CTE AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
    FROM DELETE_CTE
) AND row_num > 1;

-- Standardize Data
UPDATE world_layoffs.layoffs_staging 
SET industry = NULL 
WHERE industry = '';

UPDATE world_layoffs.layoffs_staging t1
JOIN world_layoffs.layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;

-- Remove unnecessary data
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
