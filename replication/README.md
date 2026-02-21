# Replication Package: Editor/Publisher Change and Newspaper Content

This package replicates the staggered difference-in-differences analysis of how simultaneous editor and publisher changes affected newspaper topic coverage in 19th-century American newspapers, using the Callaway & Sant'Anna (2021) estimator.

## Contents

```
replication/
├── README.md
├── pub_change_did.do                    # Stata regression and event-study plots
├── editor_publisher_change_did.ipynb    # Panel construction (Python)
├── data/
│   ├── panel_structural_drift2.csv      # Final analysis panel (input to .do file)
│   ├── master.csv                       # Newspaper metadata from Rowell's directories
│   ├── matches.csv                      # Linking table: Rowell's directories ↔ American Stories
│   └── topic_counts.json               # Topic distributions by newspaper-year (from American Stories)
└── figures/                             # Output directory for event-study plots
```

## Data Description

| File | Rows | Description |
|------|------|-------------|
| `panel_structural_drift2.csv` | 2,977 | Newspaper-year panel with outcome variables. 313 newspapers, 1869-1890. |
| `master.csv` | 48,138 | Newspaper metadata extracted from Rowell's American Newspaper Directory (14 editions, 1869-1890). Includes editor/publisher names, circulation, political affiliation, and detected change years. |
| `matches.csv` | 607 | Links newspapers in `master.csv` (by `master_id`) to the American Stories dataset (by ISSN). |
| `topic_counts.json` | — | Nested JSON (year → ISSN → topic counts). Contains headline topic classifications and totals for each newspaper-year. |

## Replication Instructions

### Step 1: Panel Construction (Optional)

The final panel (`panel_structural_drift2.csv`) is provided. To reconstruct it from the underlying data, run `editor_publisher_change_did.ipynb` in order:

1. **Cell 1** — Detects first editor and publisher changes in `master.csv` using fuzzy string matching (Levenshtein distance ≤ 1) with single-entry blip removal.
2. **Cell 2** — Filters to newspapers matched to the American Stories dataset, producing `final_list.csv`.
3. **Cell 3** — Builds the analysis panel: computes topic rates per 1,000 headlines (10 topics), defines anchor cutoffs, and calculates three outcome variables.

**Requirements:** Python 3, pandas, numpy.

### Step 2: Econometric Analysis

Run `pub_change_did.do` in Stata from the `replication/` directory:

```stata
cd "path/to/replication"
do pub_change_did.do
```

**Requirements:** Stata 16+, `csdid` package (Callaway & Sant'Anna), `coefplot`.

To install required Stata packages:
```stata
ssc install csdid
ssc install coefplot
```

### What the Do File Does

1. Loads `data/panel_structural_drift2.csv`
2. Keeps only newspapers with simultaneous editor + publisher changes (treated) and no-change newspapers (control)
3. Estimates ATT using Callaway & Sant'Anna (2021) with doubly-robust IPW (`dripw`), using not-yet-treated units as controls
4. Runs pre-trend tests and event-study estimates (window: -5 to +5 years)
5. Exports three event-study figures to `figures/`

### Outcome Variables

| Variable | Description |
|----------|-------------|
| `Y_it` | Euclidean distance of a newspaper's topic distribution from its pre-cutoff mean (drift from baseline) |
| `Y_lifecycle` | Euclidean distance from the newspaper's first-3-years mean topic distribution (lifecycle anchor) |
| `Y_vol` | Year-over-year Euclidean distance in topic distributions (volatility) |

### Output

Three event-study plots saved to `figures/`:
- `event_study_y_it.png`
- `event_study_y_lifecycle.png`
- `event_study_y_vol.png`

## Data Sources

- **Rowell's American Newspaper Directory** (1869-1890): Metadata on U.S. newspapers including editors, publishers, circulation, and political affiliation.
- **American Stories** (Dell & Fredrickson, 2024): OCR-extracted headlines from digitized newspapers in Chronicling America, classified into 10 topics via LLM pipeline.
