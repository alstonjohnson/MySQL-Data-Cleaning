-- Data Cleaning

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any columns


-- Let's see what the data looks like
SELECT *
FROM layoffs;

-- As an Accountant, I've learned when working with data, you don't want to manipulate your original table.
-- Alsways work inside a duplicate "layoffs" table. A "working table" if you will so in case something happens, your original isn't messed up.
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Switching to the newly created duplicate table
SELECT *
FROM layoffs_staging;

-- Inserting the data from the original "layoffs" table into the new working table. 
INSERT layoffs_staging
SELECT *
FROM layoffs;





-- 1. Remove Duplicates

-- Running a query return any duplicate companies.
-- "row_num" is important here as this is how we identify the duplicates.
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- When running the above, Casper was one of the companies that returned as having a duplicate.
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Lets create a new table that has the "row_num" as part of the main table
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Adding the "layoffs_staging" data into the newly created "layoffs_staging2" table.
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Pulling up the companies with duplicates like in the last table
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Deleting the returned values with numbers greater than 1 (duplicate values).
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Shwoing the full data set without duplicates
SELECT *
FROM layoffs_staging2;







-- 2. Standardize the Data

-- I noticed some white space around some of the company names, so this takes care of that.
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Now let's look at the industries
SELECT DISTINCT industry
FROM layoffs_staging2
;

-- I found some different namings for Cryptocurrency. The most common name was "Crypto"
-- So I updated the others to be more uniform
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Now let's look at the different countries
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- I noticed that there was a "." after some of the United States.
-- The below selects those and trims that trailing "." from the country. 
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Updating our month column to the standard MySQL format.
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Updating the date
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- Updating the date column type form "text" to "date".
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;




-- 3. Null Values or blank values


-- I notcied that "NULL" in the date column was a string instead of a value. 
-- The below updates to a value recognized by MySQL
SELECT *
FROM layoffs_staging2
WHERE `date` = 'NULL';

UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = 'NULL';


-- SELECT *
-- FROM layoffs_staging2
-- WHERE total_laid_off = 'null'
-- AND percentage_laid_off = 'null';

-- Selecting all values where the industry is NULL, blank or 'null'.
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
OR industry = 'null';

-- Bally and Airbnb were two of those companies.
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'bally%';

SELECT *
FROM layoffs_staging2
WHERE company = 'airbnb';

-- Creating a join on the same table. This join will be populating an industry if one of the values is blank but the other isn't.
-- We're joining on the company column
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;

-- Selecting and deleting any companies where total laid off and percetenge laid off are 'null'.
-- This is helpful/important because those companies likely didn't have any layoffs which isn't helpful in this exercise.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off = 'null'
AND percentage_laid_off = 'null';

DELETE 
FROM layoffs_staging2
WHERE total_laid_off = 'null'
AND percentage_laid_off = 'null';


-- 4. Remove any columns

-- Deleting the "row_num" column as it is no longer needed. It was only useful in calling out duplicate companies.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

