********************************************************************************
* Multi-Treatment DiD with Wild Cluster Bootstrap
********************************************************************************

clear all
set more off

* ── 0. INSTALL REQUIRED PACKAGES ──────────────────────────────────
* ssc install reghdfe, replace
* ssc install ftools, replace
* ssc install boottest, replace
* ssc install coefplot, replace

* ── 1. LOAD DATA ─────────────────────────────────────────────────────────────
import delimited "data/panel_structural_drift.csv", clear

* ── 2. RENAME TRUNCATED VARIABLES────────────────────────────
* Stata truncated the long CSV column names. Rename to short usable names.

rename is_publisher_~y  is_pub
rename is_editor_cha~y  is_ed
rename is_editor_and~s  is_both
rename post_x_publis~y  Post_x_pub
rename post_x_editor~y  Post_x_ed
rename post_x_editor~n  Post_x_both
rename anchor_cutoff~r  anchor_year

* is_treated came in as string "True"/"False" — convert to numeric
gen treated = (is_treated == "True")
drop is_treated
rename treated is_treated

* ── 2b. CREATE YEAR DUMMIES (needed for boottest compatibility) ──────────────
* boottest doesn't work after reghdfe with >1 set of absorbed FEs.
* Workaround: absorb only newspaper_id, include year dummies explicitly.

tab year, gen(yr_)

* Collect all year dummy names into a local macro for reuse
unab year_dummies : yr_*

* ── 3. MODEL 1: STATIC DiD ──────────────────────────────────────────────────

display _newline(2)
display "=================================================================="
display "MODEL 1: STATIC DiD — Treatment Effects by Group"
display "=================================================================="

reghdfe y_it Post_x_pub Post_x_ed Post_x_both `year_dummies', ///
    absorb(newspaper_id) vce(cluster newspaper_id)

estimates store static_did

* Wild cluster bootstrap p-values for each treatment coefficient
display _newline
display "Wild Cluster Bootstrap p-values (Rademacher, 9999 reps):"
display "------------------------------------------------------------------"
display "Publisher Change Only:"
boottest Post_x_pub,  boottype(wild) weight(rademacher) reps(9999) seed(42) nograph
display _newline "Editor Change Only:"
boottest Post_x_ed,   boottype(wild) weight(rademacher) reps(9999) seed(42) nograph
display _newline "Editor & Publisher (Same Year):"
boottest Post_x_both, boottype(wild) weight(rademacher) reps(9999) seed(42) nograph


* ── 4. BUILD EVENT-STUDY VARIABLES ──────────────────────────────────────────

* Time to treatment (may already exist as rel_year — verify they match)
gen time_to_treat = year - anchor_year

* Bin endpoints at -5 and +5
gen event_k = time_to_treat
replace event_k = -5 if event_k < -5 & !missing(event_k)
replace event_k =  5 if event_k >  5 & !missing(event_k)

* Reference period: k = -1
* Create interaction dummies: event_k × treatment group
* Loop over k = -5 to 5, skipping k = -1

foreach cat in pub ed both {
    forvalues k = -5/5 {
        if `k' == -1 continue

        * Create clean variable name (replace minus with "n")
        if `k' < 0 {
            local klab = "n" + string(abs(`k'))
        }
        else {
            local klab = string(`k')
        }

        gen ev_`cat'_k`klab' = (event_k == `k') * is_`cat'
    }
}

* ── 5. MODEL 2: EVENT STUDY ─────────────────────────────────────────────────

display _newline(2)
display "=================================================================="
display "MODEL 2: EVENT STUDY — Dynamic Effects by Treatment Group"
display "=================================================================="

* Collect all event-study interaction variables
local es_vars ""
foreach cat in pub ed both {
    forvalues k = -5/5 {
        if `k' == -1 continue
        if `k' < 0 {
            local klab = "n" + string(abs(`k'))
        }
        else {
            local klab = string(`k')
        }
        local es_vars "`es_vars' ev_`cat'_k`klab'"
    }
}

reghdfe y_it `es_vars' `year_dummies', ///
    absorb(newspaper_id) vce(cluster newspaper_id)

estimates store event_study

* ── 6. WILD CLUSTER BOOTSTRAP FOR EVENT-STUDY COEFFICIENTS ──────────────────

display _newline
display "Wild Cluster Bootstrap p-values for event-study coefficients:"
display "------------------------------------------------------------------"

foreach cat in pub ed both {
    if "`cat'" == "pub"  display _newline "Publisher Change Only:"
    if "`cat'" == "ed"   display _newline "Editor Change Only:"
    if "`cat'" == "both" display _newline "Editor & Publisher (Same Year):"

    forvalues k = -5/5 {
        if `k' == -1 continue
        if `k' < 0 {
            local klab = "n" + string(abs(`k'))
        }
        else {
            local klab = string(`k')
        }
        display "  k = `k':"
        boottest ev_`cat'_k`klab', ///
            boottype(wild) weight(rademacher) reps(9999) seed(42) nograph
    }
}

* ── 7. PRE-TREND JOINT F-TESTS ──────────────────────────────────────────────

display _newline(2)
display "=================================================================="
display "PRE-TREND JOINT F-TESTS (H0: all pre-treatment coeffs = 0)"
display "=================================================================="

* Publisher change only: k = -5, -4, -3, -2
display _newline "Publisher Change Only:"
testparm ev_pub_kn5 ev_pub_kn4 ev_pub_kn3 ev_pub_kn2

boottest ev_pub_kn5 ev_pub_kn4 ev_pub_kn3 ev_pub_kn2, ///
    boottype(wild) weight(rademacher) reps(9999) seed(42) nograph

display _newline "Editor Change Only:"
testparm ev_ed_kn5 ev_ed_kn4 ev_ed_kn3 ev_ed_kn2

boottest ev_ed_kn5 ev_ed_kn4 ev_ed_kn3 ev_ed_kn2, ///
    boottype(wild) weight(rademacher) reps(9999) seed(42) nograph

display _newline "Editor & Publisher (Same Year):"
testparm ev_both_kn5 ev_both_kn4 ev_both_kn3 ev_both_kn2

boottest ev_both_kn5 ev_both_kn4 ev_both_kn3 ev_both_kn2, ///
    boottype(wild) weight(rademacher) reps(9999) seed(42) nograph

* ── 8. EVENT-STUDY PLOT ─────────────────────────────────────────────────────

coefplot ///
    (event_study, keep(ev_pub_k*)                              ///
        rename(ev_pub_kn5=k_n5 ev_pub_kn4=k_n4                ///
               ev_pub_kn3=k_n3 ev_pub_kn2=k_n2                ///
               ev_pub_k0=k_0   ev_pub_k1=k_1                  ///
               ev_pub_k2=k_2   ev_pub_k3=k_3                  ///
               ev_pub_k4=k_4   ev_pub_k5=k_5)                 ///
        label("Publisher Change Only")                         ///
        mcolor(blue) ciopts(color(blue)))                      ///
    (event_study, keep(ev_ed_k*)                               ///
        rename(ev_ed_kn5=k_n5 ev_ed_kn4=k_n4                  ///
               ev_ed_kn3=k_n3 ev_ed_kn2=k_n2                  ///
               ev_ed_k0=k_0   ev_ed_k1=k_1                    ///
               ev_ed_k2=k_2   ev_ed_k3=k_3                    ///
               ev_ed_k4=k_4   ev_ed_k5=k_5)                   ///
        label("Editor Change Only")                            ///
        mcolor(cranberry) ciopts(color(cranberry)))            ///
    (event_study, keep(ev_both_k*)                             ///
        rename(ev_both_kn5=k_n5 ev_both_kn4=k_n4              ///
               ev_both_kn3=k_n3 ev_both_kn2=k_n2              ///
               ev_both_k0=k_0   ev_both_k1=k_1                ///
               ev_both_k2=k_2   ev_both_k3=k_3                ///
               ev_both_k4=k_4   ev_both_k5=k_5)               ///
        label("Editor & Pub (Same Year)")                      ///
        mcolor(green) ciopts(color(green))),                   ///
    vertical                                                   ///
    offset(0.15)                                               ///
    order(k_n5 k_n4 k_n3 k_n2 k_0 k_1 k_2 k_3 k_4 k_5)     ///
    coeflabels(k_n5="-5" k_n4="-4" k_n3="-3" k_n2="-2"       ///
               k_0="0" k_1="1" k_2="2" k_3="3"               ///
               k_4="4" k_5="5")                                ///
    yline(0, lcolor(black) lpattern(solid))                    ///
    xline(4.5, lcolor(red) lpattern(dash))                    ///
    ytitle("Drift from Historical Baseline ({&beta}{sub:k})") ///
    xtitle("Years Relative to Anchor Cutoff (k)")             ///
    title("Event Study: Structural Drift by Treatment Type")  ///
    subtitle("CIs = cluster-robust; see output for WCB p-values") ///
    legend(order(2 4 6) rows(1) size(small) pos(6))           ///
    graphregion(margin(r=2))

graph export "figures/structural_drift_event_study.png", replace width(1800)

display _newline "Done."