# Layoffs Exploratory Data Analysis

## Table of Contents
- [Project Overview](project-overview)
- [Data Analysis](data-analysis)
- [Results/Findings](results-findings)
- [Recommendations](recommendations)

### Project Overview
This data analysis project aims to provide insights about layoffs across 6 years. By analyzing various aspects of the layoffs data, we seek to identify trends, make data-driven recommendations, and gain a deeper understanding about the companies and industries.

### Data Sources
The primary dataset used for this analysis is the "Layoffs_data.csv" file, containing detailed information about layoffs made by each industry and company.

### Tools
- MySQL - Data Cleaning and EDA
- Tableau - Reporting/Visualization

### Data Cleaning/Preparation
In the initial data preparation phase, we performed the following tasks:
1. Data loading and inspection
2. Handling missing values
3. Data Cleaning and formating

### Exploratory Data Analysis
EDA involved exploring th layoffs data to answer key questions such as:
- What are the top 10 companies and industries by layoffs?
- Which countries have the most layoffs?
- Which stages have the most layoffs?
- What does the monthly layoff trend look like?
- does funding in millions guarentee low layoffs?

### Data Analysis
Interesting codes worked with

```sql
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
```

### Results/Findings
The anlysis results are summarized as follows:
1. Layoffs were heavily concentrated in a few industries. Technology companies accounted for the largest share of layoff across the dataset.
2. Layoffs were geographically concentrated . A small number of countries represented most reported layoffs.
3. Later-stage companies experienced substantial layoffs. Post-IPO and mature companies contributed a significant portion of total layoffs.
4. Layoffs occured in waves. Monthly analysis revealed cleat=r spikes during specific periods rather than a steady trend.
5. Hign funding did not  guarantee workforce stability. Several highly funded companies still conducted large layoffs.

### Recommendations
- Monitor workforce expansion during rapid funding periods.
- Evaluate operational efficiency alongside growth metrics.
- Diversify hiring strategies during periods of economic uncertainity.

### Limitations
We had to remove the nulls and blanks because they would have affected the accuracy of our conclusions from the analysis. There are a few outliers even after the omissions.

### References
-- SQL for Data Analysis by Cathy Tanimura








