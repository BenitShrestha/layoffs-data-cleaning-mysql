# Layoffs Dataset Cleaning

This script cleans a raw layoffs dataset using SQL, working on a copy so the original data stays untouched.

## What it does

1. **Copies the data** into a staging table.
2. **Removes duplicate rows.**
3. **Standardizes messy values** by  fixing inconsistent text, trimming extra spaces, and correcting the date format.
4. **Fixes missing values** by converting blanks to proper NULLs, and some missing data is filled in from related rows. Rows with no useful data at all are removed.

## Result

A clean, consistent version of the dataset (`layoffs_cleaned`), ready for analysis.