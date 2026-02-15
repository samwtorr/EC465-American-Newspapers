********************************************************************************
* Multi-Treatment DiD — Callaway & Sant'Anna (2021) Staggered Estimator
* Editor & Publisher Change (Same Year) only
* Three outcome measures: Y_it, Y_lifecycle, Y_vol
* Drops treated cohorts with fewer than MIN_COHORT newspapers
********************************************************************************

clear all
set more off

local MIN_COHORT 5

* ── 1. LOAD DATA ─────────────────────────────────────────────────────────────
import delimited "data/panel_structural_drift.csv", clear

* ── 2. RENAME TRUNCATED VARIABLES ────────────────────────────────────────────
rename is_publisher_~y  is_pub
rename is_editor_cha~y  is_ed
rename is_editor_and~s  is_both
rename post_x_publis~y  Post_x_pub
rename post_x_editor~y  Post_x_ed
rename post_x_editor~n  Post_x_both
rename anchor_cutoff~r  anchor_year

gen treated = (is_treated == "True")
drop is_treated
rename treated is_treated

* ── 3. CONSTRUCT COHORT VARIABLE FOR CSDID ───────────────────────────────────
gen gvar = 0
replace gvar = anchor_year + 1 if is_treated == 1

* Keep only editor+publisher (same year) treated + never-treated controls
keep if is_both == 1 | is_treated == 0

* ── 3b. DROP SMALL TREATED COHORTS ───────────────────────────────────────────
* Count unique newspapers per cohort
bysort gvar newspaper_id: gen _tag = (_n == 1)
bysort gvar: egen cohort_n = total(_tag)
drop _tag

display _newline "Cohort sizes before filter:"
tab gvar if cohort_n > 0 & gvar > 0, sort

* Drop treated cohorts below threshold (keep all controls, gvar==0)
drop if gvar > 0 & cohort_n < `MIN_COHORT'
drop cohort_n

display _newline "Remaining treated cohorts:"
preserve
bysort gvar newspaper_id: keep if _n == 1
tab gvar if gvar > 0
restore

display _newline "Total obs: " _N
display "Unique newspapers: " 
codebook newspaper_id, compact


********************************************************************************
* ── 4. Y_it: ORIGINAL DRIFT FROM PRE-CUTOFF ANCHOR ──────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "Y_it — Drift from Pre-Cutoff Anchor"
display "=================================================================="

quietly csdid y_it, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_yit)


********************************************************************************
* ── 5. Y_lifecycle: DRIFT FROM FIRST-3-YEARS ANCHOR ─────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "Y_lifecycle — Drift from Lifecycle Anchor"
display "=================================================================="

quietly csdid y_lifecycle, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_lifecycle)


********************************************************************************
* ── 6. Y_vol: YEAR-OVER-YEAR VOLATILITY ─────────────────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "Y_vol — Year-over-Year Volatility"
display "=================================================================="

* Drop obs with missing Y_vol (first year per paper has no lag)
preserve
drop if missing(y_vol)

quietly csdid y_vol, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_vol)

restore


********************************************************************************
* ── 7. COMBINED EVENT-STUDY PLOT ─────────────────────────────────────────────
********************************************************************************

coefplot ///
    (cs_yit,       label("Pre-Cutoff Anchor (Y_it)")           ///
        mcolor(blue) ciopts(color(blue)))                       ///
    (cs_lifecycle, label("Lifecycle Anchor (Y_lifecycle)")       ///
        mcolor(cranberry) ciopts(color(cranberry)))             ///
    (cs_vol,       label("YoY Volatility (Y_vol)")              ///
        mcolor(green) ciopts(color(green))),                    ///
    vertical                                                    ///
    offset(0.15)                                                ///
    yline(0, lcolor(black) lpattern(solid))                     ///
    xline(5.5, lcolor(red) lpattern(dash))                     ///
    ytitle("ATT")                                               ///
    xtitle("Years Relative to Treatment")                       ///
    title("Editor & Publisher Change (Same Year)")              ///
    subtitle("Callaway & Sant'Anna (2021), DR-IPW, cohort n≥`MIN_COHORT'") ///
    legend(order(2 4 6) rows(1) size(small) pos(6))             ///
    graphregion(margin(r=2))

graph export "figures/structural_drift_event_study_3outcomes.png", replace width(1800)

display _newline "Done."