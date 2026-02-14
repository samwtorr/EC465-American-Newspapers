********************************************************************************
* Multi-Treatment DiD — Callaway & Sant'Anna (2021) Staggered Estimator
* Clean output: only aggregated results, no group×time ATT tables
********************************************************************************

clear all
set more off

* ── 0. INSTALL REQUIRED PACKAGES ──────────────────────────────────
* ssc install csdid, replace
* ssc install drdid, replace
* ssc install reghdfe, replace
* ssc install ftools, replace
* ssc install coefplot, replace

* ── 1. LOAD DATA ─────────────────────────────────────────────────────────────
import delimited "data/panel_structural_drift.csv", clear

* ── 2. RENAME TRUNCATED VARIABLES────────────────────────────
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

* Subsample indicators: each treatment type + never-treated controls
gen sample_pub  = (is_pub == 1 | is_treated == 0)
gen sample_ed   = (is_ed == 1 | is_treated == 0)
gen sample_both = (is_both == 1 | is_treated == 0)


********************************************************************************
* ── 4. PUBLISHER CHANGE ONLY ─────────────────────────────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "PUBLISHER CHANGE ONLY"
display "=================================================================="

preserve
keep if sample_pub == 1

quietly csdid y_it, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_pub)

coefplot cs_pub, vertical yline(0) ///
    title("Publisher Change Only (CS 2021)") ///
    xtitle("Years Relative to Treatment") ///
    ytitle("ATT: Drift from Historical Baseline")
graph export "figures/cs_event_study_pub.png", replace width(1800)

restore


********************************************************************************
* ── 5. EDITOR CHANGE ONLY ───────────────────────────────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "EDITOR CHANGE ONLY"
display "=================================================================="

preserve
keep if sample_ed == 1

quietly csdid y_it, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_ed)

coefplot cs_ed, vertical yline(0) ///
    title("Editor Change Only (CS 2021)") ///
    xtitle("Years Relative to Treatment") ///
    ytitle("ATT: Drift from Historical Baseline")
graph export "figures/cs_event_study_ed.png", replace width(1800)

restore


********************************************************************************
* ── 6. EDITOR & PUBLISHER CHANGE (SAME YEAR) ────────────────────────────────
********************************************************************************

display _newline(3)
display "=================================================================="
display "EDITOR & PUBLISHER CHANGE (SAME YEAR)"
display "=================================================================="

preserve
keep if sample_both == 1

quietly csdid y_it, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_both)

coefplot cs_both, vertical yline(0) ///
    title("Editor & Publisher Change, Same Year (CS 2021)") ///
    xtitle("Years Relative to Treatment") ///
    ytitle("ATT: Drift from Historical Baseline")
graph export "figures/cs_event_study_both.png", replace width(1800)

restore


********************************************************************************
* ── 7. COMBINED EVENT-STUDY PLOT ─────────────────────────────────────────────
********************************************************************************

coefplot ///
    (cs_pub, label("Publisher Change Only")                    ///
        mcolor(blue) ciopts(color(blue)))                      ///
    (cs_ed, label("Editor Change Only")                        ///
        mcolor(cranberry) ciopts(color(cranberry)))            ///
    (cs_both, label("Editor & Pub (Same Year)")                ///
        mcolor(green) ciopts(color(green))),                   ///
    vertical                                                   ///
    offset(0.15)                                               ///
    yline(0, lcolor(black) lpattern(solid))                    ///
    xline(5.5, lcolor(red) lpattern(dash))                    ///
    ytitle("ATT: Drift from Historical Baseline")              ///
    xtitle("Years Relative to Treatment")                      ///
    title("Event Study: Structural Drift by Treatment Type")   ///
    subtitle("Callaway & Sant'Anna (2021), DR-IPW")            ///
    legend(order(2 4 6) rows(1) size(small) pos(6))            ///
    graphregion(margin(r=2))

graph export "figures/structural_drift_event_study_csdid.png", replace width(1800)

display _newline "Done."