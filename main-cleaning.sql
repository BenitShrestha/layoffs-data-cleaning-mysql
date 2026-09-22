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
