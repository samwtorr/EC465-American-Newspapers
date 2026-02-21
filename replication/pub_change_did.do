********************************************************************************
* Multi-Treatment DiD — Callaway & Sant'Anna (2021) Staggered Estimator
* Editor & Publisher Change (Same Year) only
* Three outcome measures: Y_it, Y_lifecycle, Y_vol
********************************************************************************

clear all
set more off

* ── 1. LOAD DATA ──────────────────────────────────────────────────────────────
import delimited "data/panel_structural_drift2.csv", clear

* ── 2. RENAME TRUNCATED VARIABLES ─────────────────────────────────────────────
rename is_editor_and~s  is_both
rename anchor_cutoff~r  anchor_year

gen treated = (is_treated == "True")
drop is_treated
rename treated is_treated

* ── 3. CONSTRUCT COHORT VARIABLE & KEEP ONLY BOTH-CHANGE + CONTROLS ──────────
gen gvar = 0
replace gvar = anchor_year + 1 if is_treated == 1

keep if is_both == 1 | is_treated == 0

********************************************************************************
* ── 4. Y_it: DRIFT FROM PRE-CUTOFF ANCHOR ────────────────────────────────────
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

* Check stored coefficient names
matrix list e(b)

* ── Figure 1 ──
coefplot cs_yit,                                                    ///
    vertical                                                        ///
    keep(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)            ///
    order(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)           ///
    rename(Tm5 = "-5" Tm4 = "-4" Tm3 = "-3" Tm2 = "-2" Tm1 = "-1" ///
           Tp0 = "0"  Tp1 = "1"  Tp2 = "2"  Tp3 = "3"             ///
           Tp4 = "4"  Tp5 = "5")                                   ///
    mcolor(navy) msymbol(circle)                                    ///
    ciopts(lcolor(navy) lwidth(medium))                             ///
    yline(0, lcolor(gs8) lpattern(solid) lwidth(thin))              ///
    xline(5.5, lcolor(red) lpattern(dash) lwidth(medium))           ///
    ytitle("ATT", size(medium))                                     ///
    xtitle("Years Relative to Treatment", size(medium))             ///
    title("Pre-Cutoff Anchor (Y{subscript:it})", size(large))       ///
    subtitle("Editor & Publisher Change (Same Year)" "Callaway & Sant'Anna (2021), DR-IPW", size(medsmall)) ///
    legend(off)                                                     ///
    graphregion(color(white) margin(r=2))                           ///
    plotregion(color(white))                                        ///
    xlabel(, labsize(small) angle(0))                               ///
    ylabel(, labsize(small) angle(0) nogrid)

graph export "figures/event_study_y_it.png", replace width(1800)

********************************************************************************
* ── 5. Y_lifecycle: DRIFT FROM FIRST-3-YEARS ANCHOR ──────────────────────────
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

* ── Figure 2 ──
coefplot cs_lifecycle,                                              ///
    vertical                                                        ///
    keep(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)            ///
    order(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)           ///
    rename(Tm5 = "-5" Tm4 = "-4" Tm3 = "-3" Tm2 = "-2" Tm1 = "-1" ///
           Tp0 = "0"  Tp1 = "1"  Tp2 = "2"  Tp3 = "3"             ///
           Tp4 = "4"  Tp5 = "5")                                   ///
    mcolor(cranberry) msymbol(circle)                               ///
    ciopts(lcolor(cranberry) lwidth(medium))                        ///
    yline(0, lcolor(gs8) lpattern(solid) lwidth(thin))              ///
    xline(5.5, lcolor(red) lpattern(dash) lwidth(medium))           ///
    ytitle("ATT", size(medium))                                     ///
    xtitle("Years Relative to Treatment", size(medium))             ///
    title("Lifecycle Anchor (Y{subscript:lifecycle})", size(large))  ///
    subtitle("Editor & Publisher Change (Same Year)" "Callaway & Sant'Anna (2021), DR-IPW", size(medsmall)) ///
    legend(off)                                                     ///
    graphregion(color(white) margin(r=2))                           ///
    plotregion(color(white))                                        ///
    xlabel(, labsize(small) angle(0))                               ///
    ylabel(, labsize(small) angle(0) nogrid)

graph export "figures/event_study_y_lifecycle.png", replace width(1800)

********************************************************************************
* ── 6. Y_vol: YEAR-OVER-YEAR VOLATILITY ──────────────────────────────────────
********************************************************************************
display _newline(3)
display "=================================================================="
display "Y_vol — Year-over-Year Volatility"
display "=================================================================="

preserve
drop if missing(y_vol)

quietly csdid y_vol, ivar(newspaper_id) time(year) gvar(gvar) method(dripw) notyet

display _newline "— Simple ATT —"
csdid_estat simple

display _newline "— Pre-trend Test —"
csdid_estat pretrend

display _newline "— Event Study —"
csdid_estat event, window(-5 5) estore(cs_vol)

* ── Figure 3 ──
coefplot cs_vol,                                                    ///
    vertical                                                        ///
    keep(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)            ///
    order(Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4 Tp5)           ///
    rename(Tm5 = "-5" Tm4 = "-4" Tm3 = "-3" Tm2 = "-2" Tm1 = "-1" ///
           Tp0 = "0"  Tp1 = "1"  Tp2 = "2"  Tp3 = "3"             ///
           Tp4 = "4"  Tp5 = "5")                                   ///
    mcolor(forest_green) msymbol(circle)                            ///
    ciopts(lcolor(forest_green) lwidth(medium))                     ///
    yline(0, lcolor(gs8) lpattern(solid) lwidth(thin))              ///
    xline(5.5, lcolor(red) lpattern(dash) lwidth(medium))           ///
    ytitle("ATT", size(medium))                                     ///
    xtitle("Years Relative to Treatment", size(medium))             ///
    title("Year-over-Year Volatility (Y{subscript:vol})", size(large)) ///
    subtitle("Editor & Publisher Change (Same Year)" "Callaway & Sant'Anna (2021), DR-IPW", size(medsmall)) ///
    legend(off)                                                     ///
    graphregion(color(white) margin(r=2))                           ///
    plotregion(color(white))                                        ///
    xlabel(, labsize(small) angle(0))                               ///
    ylabel(, labsize(small) angle(0) nogrid)

graph export "figures/event_study_y_vol.png", replace width(1800)

restore

display _newline "Done."