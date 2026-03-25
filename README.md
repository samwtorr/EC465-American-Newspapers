# Newspaper Owner Financial Interests (1870-1890)

A research project analyzing the relationship between American newspaper owners' financial interests and editorial content during the Gilded Age (1870-1890). Combines historical newspaper directories, digitized newspaper text, and biographical data.

**Status:** Work in progress (March 2026)

## Repository Structure

```
.
├── data/
│   ├── raw/                        # Immutable source data (not modified by code)
│   │   ├── american_stories/       # Melissa Dell's American Stories dataset (tar.gz by year)
│   │   ├── census/                 # NHGIS county-level population data (1870, 1880, 1890)
│   │   ├── chronicling_america/    # Scraped newspaper metadata and essays from LoC
│   │   └── rowells_directories/    # Rowell's American Newspaper Directory (1869-1890)
│   │       ├── pdfs/               # Scanned directory pages
│   │       ├── ocr_text/           # OCR-extracted text
│   │       └── extracted_csv/      # Structured CSV extractions
│   ├── intermediate/               # Constructed during pipeline execution
│   │   ├── american_stories_analysis/   # Headline extractions and topic counts
│   │   ├── american_stories_merging/    # Linkage between directories and American Stories
│   │   └── personnel_coding/       # Owner/editor biographical coding
│   └── processed/                  # Final analysis-ready datasets
│       ├── master.csv              # Newspaper-year panel with metadata
│       └── newspapers.db           # SQLite database of newspaper records
│
├── data_assembly/                  # Stage 1: Data construction
│   ├── 01_registry_data_extraction.ipynb   # Extract structured data from Rowell's directories
│   ├── 02_chronicling_america_scraper.ipynb # Scrape newspaper metadata from Chronicling America
│   ├── 03_american_stories_merger.ipynb     # Link directory data with American Stories text
│   └── 04_combine_personnel_coding.ipynb    # Merge hand-coded and LLM-extracted biographies
│
├── sentiment_analysis/             # Stage 2: NLP pipeline
│   ├── 01_classify_labor_railroad.ipynb     # Classify articles as labor/railroad-related
│   ├── 02_create_verification_dataset.ipynb # Build human-verification sample
│   ├── 03_finetune_sentiment_model.ipynb    # Fine-tune sentiment classifier
│   ├── 04_sentiment_inference.ipynb         # Run inference on full corpus
│   ├── 05_integrate_sentiment_results.ipynb # Merge sentiment scores into panel
│   └── data/                                # Sentiment pipeline inputs/outputs
│
├── data_analysis/                  # Stage 3: Econometric analysis
│   ├── 01_data_preparation.ipynb            # Build analysis sample from processed data
│   ├── 02_main_regressions.ipynb            # Primary DiD and event study specifications
│   ├── 03_circulation_and_distributions.ipynb # Circulation-weighted analysis
│   ├── 04_uncoded_owner_prioritization.ipynb  # Identify high-priority uncoded owners
│   ├── 05_robustness_tests.ipynb            # Alternative specifications and sensitivity
│   └── intermediate/                        # Analysis-stage intermediate outputs
│
├── other_analysis/                 # Supplemental specifications
│   ├── editor_publisher_change_did.ipynb    # Editor/publisher turnover DiD (Python)
│   └── pub_change_did.do                    # Publisher change DiD (Stata)
│
├── output/
│   ├── figures/                    # Generated plots and event studies
│   └── tables/                     # Generated regression tables
│
├── replication/                    # Self-contained replication package
│   ├── README.md
│   ├── data/
│   ├── figures/
│   ├── editor_publisher_change_did.ipynb
│   └── pub_change_did.do
│
└── data/archive/                   # Superseded files (kept for reference)
```

## Data Sources

- **Rowell's American Newspaper Directory** (1869-1890): 14 scanned editions of Geo. P. Rowell and Co.'s directory of US newspapers and periodicals, containing location, circulation, frequency, and editor/owner information.
- **[American Stories Dataset](https://github.com/dell-research-harvard/americanstories)** (Dell et al.): OCR-processed full text of digitized newspapers from Chronicling America.
- **[Chronicling America](https://chroniclingamerica.loc.gov/)**: Library of Congress digital archive of historical American newspapers; used for newspaper metadata and biographical essays.
- **NHGIS** (IPUMS): County-level census data for 1870, 1880, and 1890.

## Methodology

Cross-sectional and panel OLS regressions estimate the association between newspaper owners' railroad financial ties and the anti-labor share of labor coverage, controlling for owner political affiliation, county population, and year fixed effects. Robustness checks include WLS weighted by article volume with newspaper-clustered standard errors, editor/publisher role splits, and non-LLM keyword and TF-IDF analyses. Labor sentiment is classified from full-text articles using a fine-tuned LLM pipeline validated against hand labels and a second LLM.

## Preliminary Results

Railroad-tied ownership is positively associated with anti-labor editorial slant across all specifications. Republican affiliation shows an independent positive association. Railroad ties do not appear to affect the volume of labor coverage, only its direction. These results are preliminary -- the sample is small, identification is cross-sectional, and the outcome depends on classifier accuracy. See [regression_results_summary.md](data_analysis/regression_results_summary.md) for details.

## Setup

```bash
git clone <repo-url>
cd extended_essay

python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

pip install -r requirements.txt
```

## Pipeline Execution Order

1. **Data assembly** (`data_assembly/01_` through `04_`): Builds the master dataset from raw sources.
2. **Sentiment analysis** (`sentiment_analysis/01_` through `05_`): Classifies newspaper articles and produces sentiment scores.
3. **Data analysis** (`data_analysis/01_` through `05_`): Constructs the analysis sample and runs regressions.

## Contact

s.torres4@lse.ac.uk

---
*This is an active research project. Code and documentation will be updated regularly.*
