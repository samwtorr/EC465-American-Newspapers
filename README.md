# Newspaper Owner Financial Interests (1870-1890)
A Python-based research project analyzing the financial interests of American newspaper owners during the Gilded Age (1870-1890).
## Project Overview
This repository contains code and analysis for investigating the economic ties and financial interests of newspaper proprietors in late 19th-century America. The project combines historical data sources with modern computational methods to explore questions about media ownership and potential conflicts of interest during this formative period in American journalism.
**Status:** Work in progress (as of February 10, 2026)
## Current Components
### Data Collection
- **Newspaper Directory Scraping**: Code for extracting information from historical newspaper directories
- **Chronicling America Scraping**: Code for scraping data from the Chronicling America digital archive
- **American Stories Integration**: Tools for working with Melissa Dell's American Stories dataset
- **Owner Bio Scraping**: Tools for collecting biographical information on newspaper owners
### Analysis
- **Difference-in-Differences**: Statistical models examining the effect of changes in newspaper editors/publishers
- **Stata Analysis**: Supporting econometric analysis via Stata do-files
## Repository Structure
```
.
├── data/                      # Data files (not tracked in git)
├── figures/                   # Generated plots and visualizations
├── registry_data_extraction.ipynb        # Scripts for extracting structured data from Rowell's American Newspaper Directories (1869-1890)
├── editor_publisher_change_did.ipynb     # Script for building panel data and running DiD on newspapers with changes in editor/owner
├── american_stories_merger.ipynb         # Scripts for linking Newspaper directory data with American Stories
├── chronicling_america_scraper.ipynb     # Scripts for scraping Chronicling America
├── owner_bio_scraping.ipynb              # Scripts for scraping owner biographical data
├── pub_change_did.do                     # Stata do-file for publisher change DiD analysis
├── Extended_Essay.pdf                    # Extended essay write-up
├── .gitignore
└── README.md
```
## Data Sources
- [Melissa Dell's American Stories Dataset](https://github.com/dell-research-harvard/americanstories)
- Historical newspaper directories (1870-1890)

Geo. P. Rowell and Co.'s American Newspaper Directory was a directory to US newspapers and periodicals published in the mid-to-late 19th century, first published in 1869. 14 total scanned editions were used to assemble a dataset of American newspapers over
time from 1869 to 1890. This contains newspapers listed in Rowell's, with their location, circulation, frequency of distribution, and most importantly, editors and owners for each year in the dataset.
## Setup
```bash
# Clone the repository
git clone [your-repo-url]
cd [repo-name]

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
# TODO: Add requirements.txt
pip install -r requirements.txt
```
## Usage
N/A
## Methodology
I employ a Difference-in-Differences design using a "structural drift" metric (Euclidean distance between a newspaper's post-treatment topic distribution and its pre-treatment baseline) as the dependent variable, with newspaper and year fixed effects. These results are preliminary; owner biographical coding is ongoing and will inform future extensions of the analysis.
## Results
Preliminary results show that publisher/editor turnover causes a statistically significant increase in structural drift of approximately 10.42 units (p < 0.001), with an event study confirming no pre-treatment trends and a sharp, sustained break at the time of transition. These findings are subject to revision as owner biographical data collection is completed.
## To-Do
- **Expand Chronicling America scraper**: Rewrite to scrape all entries in `newspapers_all_years_updated.csv`, not just unmatched newspapers.
- **LLM-based bio extraction pipeline**: Write a script to query the Claude API to convert Chronicling America essay results into structured JSON. This is likely best done in two stages: a first pass to extract editor/publisher timelines, then a second pass to convert those into structured JSON.
- **Merge new data onto master**: Write a script to merge the newly extracted data onto the master dataset. Key challenges:
  - Ensure newspapers with data from both Rowell's and Chronicling America are merged correctly.
  - Resolve name-matching issues — currently, some JSON entries fail to match back onto master due to slight name discrepancies. New entries need to carry the exact same identifying information as those in `newspapers_all_years_updated.csv`.
## Citation
N/A
## License
N/A
## Contact
s.torres4@lse.ac.uk
---
*This is an active research project. Code and documentation will be updated regularly.*

