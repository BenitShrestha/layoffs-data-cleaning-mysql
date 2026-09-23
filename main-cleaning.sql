-- Layoffs Dataset Cleaning

-- 1. Create staging database: Keep original data untouched
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs; 

-- 2. DUPLICATE REMOVAL
-- Checking for duplicates
WITH duplicate_cte AS (
	SELECT *,
    ROW_NUMBER() OVER(
		PARTITION BY 
			company,
            location,
            industry,
            total_laid_off,
            percentage_laid_off,
            `date`, -- DATE is a keyword
            stage,
            country,
            funds_raised_millions
    ) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- Note: We can't remove rows from a CTE so make a new staging database with extra column (row_num)

-- Making second staging database
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` bigint DEFAULT NULL,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER(
		PARTITION BY 
			company,
            location,
            industry,
            total_laid_off,
            percentage_laid_off,
            `date`, -- DATE is a keyword
            stage,
            country,
            funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

-- Removal of duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- 3. DATA STANDARDIZATION
SELECT -- Checking for whitespaces
	company, 
	TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company); -- Trim whitespaces

SELECT DISTINCT -- Checking for irregularities 
	industry
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2 -- Update similar industry names (Crypto Currency to Crypto)
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT location FROM layoffs_staging2 ORDER BY 1; -- No issues

SELECT DISTINCT country FROM layoffs_staging2 ORDER BY 1; -- `United States` and `United States.` found

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country) -- Remove trailing unwanted symbols
WHERE country LIKE 'United States%';

DESC layoffs_staging2; -- `date` is in TEXT

UPDATE layoffs_staging2 -- Convert from string to standard date format
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; -- Data type conversion

-- 4. NULL/BLANK HANDLING
SELECT * 
FROM layoffs_staging2 
WHERE industry IS NULL 
OR industry = ''; -- Some companies were found to have NULL or missing industries

SELECT * -- Checking if other entries of those companies have industries
FROM layoffs_staging2
WHERE company = 'Airbnb' 
   OR company = 'Carvana'
   OR company = 'Juul'
   OR company = 'Bally\'s Interactive'
ORDER BY company;

SELECT -- Use self-join to investigate
    t1.company,
    t1.industry,
    t2.company,
    t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
    AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 -- Standard Practice
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1 -- Replacing NULLs with appropriate values
JOIN layoffs_staging2 t2
    ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
    AND t2.industry IS NOT NULL;

-- Checking numerical values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL; 
-- Rows with both absent are better off removed

-- Create next staging, since we are deleting some rows
CREATE TABLE `layoffs_staging3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` bigint DEFAULT NULL,
  `date` date DEFAULT NULL,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging3
SELECT *
FROM layoffs_staging2; 

DELETE 
FROM layoffs_staging3
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL; 

ALTER TABLE layoffs_staging3
DROP COLUMN row_num; -- Redundant row from duplicate removal 

-- Completion of cleaning 
ALTER TABLE layoffs_staging3 RENAME TO layoffs_cleaned;

-- Comparision
SELECT *
FROM layoffs;

SELECT * 
FROM layoffs_cleaned;