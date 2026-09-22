-- Layoffs Dataset Cleaning

-- 1. Create staging database: Keep original data untouched
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs; 

