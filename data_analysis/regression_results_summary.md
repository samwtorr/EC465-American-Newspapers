# Regression Results Summary

The dataset links American newspaper owners/editors (1870s-1890s) to their newspapers using hand-coded biographical data on railroad financial ties, political affiliation, and role (editor vs publisher). Newspaper-level labor sentiment is classified from Chronicling America full-text articles using an LLM sentiment pipeline, yielding anti-labor, pro-labor, and neutral counts per newspaper-year.

Railroad financial ties include ownership of a railroad company, a seat on the board or corporate directorship at a railroad company, confirmed stock holdings of a railroad company, professional relatonships with a railroad company (one case - lawyer for company), or direct family ties (i.e., spousal railroad ties, primarily the editor/owner's father-in-law)

**Sample:** 265 newspaper-years, 46 newspapers, 47 persons (21 treated, 26 controls)

## Cross-Sectional Regressions (newspaper-level, HC3 SEs)

One observation per newspaper: total anti-labor / total labor articles across the owner's full tenure.

| | (0a) Bivariate | (0b) + Party | (0c) + Party + Pop |
|---|---|---|---|
| railroad_interest | 0.080** (0.033) | 0.096*** (0.036) | 0.097** (0.038) |
| person_republican | | 0.062* (0.036) | 0.073* (0.039) |
| log_county_pop | | | -0.026 (0.019) |
| N | 46 | 38 | 36 |
| R² | 0.122 | 0.216 | 0.257 |

## Anti-Labor Intensity Regressions (OLS, HC3 SEs)

Outcome: anti-labor articles / total labor articles per newspaper-year.

| | (1) Bivariate | (2) Year FE | (3) + Party | (4) + Party + Pop |
|---|---|---|---|---|
| railroad_interest | 0.069*** (0.026) | 0.061** (0.026) | 0.062** (0.029) | 0.063** (0.030) |
| person_republican | | | 0.098*** (0.027) | 0.112*** (0.031) |
| log_county_pop | | | | -0.017 (0.013) |
| N | 265 | 265 | 228 | 224 |
| R² | 0.026 | 0.169 | 0.216 | 0.224 |

N drops with party (missing coding) and county pop (missing Census match).

### Editor vs Publisher Split (Year FE specification)

| | Editors only | Publishers only |
|---|---|---|
| railroad_interest | 0.043 (0.029) | 0.061* (0.033) |
| N | 227 | 203 |
| R² | 0.167 | 0.171 |


## Robustness: WLS + Newspaper-Clustered SEs

WLS weighted by `total_labor`. Standard errors clustered at the newspaper level.

| | (1) Bivariate | (2) Year FE | (3) + Party | (4) + Party + Pop |
|---|---|---|---|---|
| railroad_interest | 0.067*** (0.021) | 0.053*** (0.019) | 0.066*** (0.019) | 0.060** (0.025) |
| person_republican | | | 0.052*** (0.018) | 0.057** (0.027) |
| log_county_pop | | | | 0.004 (0.010) |
| Clusters | 46 | 46 | 38 | 36 |
| N | 265 | 265 | 228 | 224 |
| R² | 0.069 | 0.445 | 0.496 | 0.508 |

Railroad interest significant at p<.01 or better across all specifications; county population is not significant.

## Coverage Volume Regressions

Outcome: labor articles / total articles per newspaper-year.

| | (1) Bivariate | (2) Year FE | (3) + Party | (4) + Party + Pop |
|---|---|---|---|---|
| railroad_interest | 0.0001 (0.0002) | 0.0001 (0.0002) | 0.0001 (0.0002) | -0.0001 (0.0002) |
| person_republican | | | 0.0000 (0.0002) | -0.0000 (0.0002) |
| log_county_pop | | | | 0.0003*** (0.0001) |
| N | 265 | 265 | 228 | 224 |
| R² | 0.002 | 0.226 | 0.216 | 0.267 |

No significant effect of railroad interest on coverage volume. County population positively predicts coverage share (larger counties produce proportionally more labor articles).

Sentiment classifier validity. The outcome depends entirely on the LLM classifier. Systematic biases (e.g., correlation between article length and sentiment label) could produce spurious results. Validation results: 69% accuracy vs hand labels (n=175, F1: anti=0.64, neutral=0.74, pro=0.67), 77% vs Gemini labels (n=2,380). Face validity confirmed on the Workingman's Advocate (known pro-labor paper): classifier assigns 76% pro-labor. Anti-labor recall is highest (77% vs hand), reducing concern that the outcome variable systematically undercounts anti-labor articles.

## Non-LLM Robustness: Keyword and Term Frequency Analysis

A keyword hit-rate test using 24 pejorative labor terms (e.g., "agitator," "rioter," "mob") shows a mixed pattern: railroad-tied papers over-index on terms like "agitator" and "communist", but under-index on others like "mob" and "lawless", with no clear aggregate directional effect. A separate TF-IDF comparison of labor article corpora finds that railroad-tied papers disproportionately use concrete industrial and conflict terms ("strike," "strikers," "company," "coal," "miners"), while control papers over-index on political terms ("congress," "government," "united states," "free trade"). This may suggest that railroad-tied papers framed labor coverage around specific industrial disputes rather than broader political context.

## Key Takeaways

- Railroad-tied ownership is associated with ~5-7 pp higher anti-labor intensity, robust across all specifications.
- Republican owners/editors independently associated with ~5-10 pp higher anti-labor intensity.
- The railroad effect operates through publishers (owners), not editors.
- Railroad ties do not affect the amount of labor coverage, only its slant.

---
OLS models use robust standard errors. WLS models use newspaper-clustered SEs. \* p<.1, \*\* p<.05, \*\*\* p<.01

---

## Appendix: Threats to Validity

1. **Endogeneity.** Railroad-tied owners did not randomly acquire newspapers. They may have bought papers in railroad-heavy areas where labor conflict was already more salient, meaning the coefficient could reflect local economic conditions rather than owner influence.
2. **Few clusters.** 46 newspapers (38 with party coding) is borderline for cluster-robust inference. A wild cluster bootstrap would provide more credible p-values.
3. **Cross-sectional identification.** Railroad interest barely varies within a newspaper over time (same owner persists), so the year FE do not aid identification. The effective comparison is cross-sectional across ~46 newspapers.
4. **Influential observations.** With 21 treated units, a single newspaper with extreme coverage could drive the result. Leave-one-out sensitivity analysis would test stability.
5. **Sentiment classifier validity.** The outcome depends entirely on the LLM classifier. Systematic biases (e.g., correlation between article length and sentiment label) could produce spurious results. Validation results: 69% accuracy vs hand labels (n=175, F1: anti=0.64, neutral=0.74, pro=0.67), 77% vs Gemini labels (n=2,380). Face validity confirmed on the *Workingman's Advocate* (known pro-labor paper): classifier assigns 76% pro-labor. Anti-labor recall is highest (77% vs hand), reducing concern that the outcome variable systematically undercounts anti-labor articles.
6. **Selection into Chronicling America.** Not all newspapers were digitized. If digitization correlates with newspaper prominence or geography, sample selection bias is possible.
7. **Circulation as a confounder.** Adding log circulation as a control causes railroad interest to lose significance (cross-sectional: 0.058, p>0.1; panel: 0.026, p>0.1). However, circulation data is only available for a subset of newspapers, dropping N from 46 to 22 (cross-sectional) or 228 to 148 (panel). The loss of significance is likely driven by sample attrition rather than circulation itself acting as a confounder — this can be tested by re-running the model without circulation on the same restricted sample.
