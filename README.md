# Personalization through Memories Results in Gender Bias in ChatGPT Generations of Images of its User

**Course:** GOVT 20.12 (Politics and AI), Dartmouth College  
**Author:** Andrew Heller

[View the poster](poster.pdf)

## Overview

This project investigates whether ChatGPT's memory personalization feature introduces gender bias in AI-generated images. A synthetic user memory ("The user is studying ___ in college") is injected into the system prompt, and the model is asked to generate an image of what the user looks like. The gender of the resulting images is then compared against real-world enrollment statistics for each major.

Across 16 academic interests (400 images total), male figures are significantly overrepresented in 15/16 majors at FDR-adjusted p < 0.05 in a one-sample proportion test, and in all 16 majors in a chi-square goodness-of-fit test.

## Pipeline

```
image_generation.ipynb   →   analysis.ipynb   →   visualizations.R
  (generate images &           (parse demographic      (statistical tests
   demographic analysis)        text files into CSV)    & poster plots)
```

**1. `image_generation.ipynb`**  
Prompts GPT-4.1-mini with a synthetic user memory for each academic interest and generates 25 images. Each image is then passed to a second GPT-4.1-mini call that extracts demographic information (race, gender, age, etc.) in a structured text format.

**2. `analysis.ipynb`**  
Parses the demographic text files, normalizes free-text responses into standard categories, and aggregates counts per academic interest into `folder_counts_detailed_academic.csv`.

**3. `visualizations.R`**  
Loads `academicDemographics.csv` (derived from the analysis output), runs one-sample proportion tests and chi-square goodness-of-fit tests with Benjamini-Hochberg FDR correction, and produces the three plots used in the poster.

## Requirements

### Python

Install dependencies with:

```bash
pip install -r requirements.txt
```

An OpenAI API key is required. Set it as an environment variable before running the notebooks:

```bash
export OPENAI_API_KEY="your-key-here"
```

### R

Install the required packages by running the following in R:

```r
install.packages(c("tidyverse", "glue", "gt", "scales"))
```

## Data

The `output/` directory (generated images and analysis text files) is excluded from this repo due to file size. The summary CSVs used for statistical analysis are included.

## Results

Men are overrepresented across nearly all majors tested. The gap is largest for nursing, women and gender studies, and computer science. See the poster for full results and visualizations.
