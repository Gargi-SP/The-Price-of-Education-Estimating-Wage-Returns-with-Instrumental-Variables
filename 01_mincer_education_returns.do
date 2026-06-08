/* ============================================================
   THE PRICE OF EDUCATION: ESTIMATING WAGE RETURNS WITH INSTRUMENTAL VARIABLES
   
   Estimates the private returns to education using the 
   Mincerian earnings function. Covers OLS baseline, 
   experience-earnings profiles, heteroskedasticity-robust 
   inference, IV estimation (addressing endogeneity of 
   schooling), and Oaxaca-Blinder decomposition by gender.
   
   Expected dataset variables:
     ln_wage      - log hourly wage
     educ         - years of schooling
     exper        - potential labor market experience
     exper2       - experience squared (create below)
     female       - dummy: 1 = female
     black        - dummy: 1 = Black
     married      - dummy: 1 = married
     tenure       - years with current employer
     union        - dummy: 1 = union member
     urban        - dummy: 1 = urban residence
     south        - dummy: 1 = southern state
     nearc4       - proximity to 4-year college (IV)
     fatheduc     - father's years of schooling (IV)
     motheduc     - mother's years of schooling (IV)
   
   Compatible with: NLSY79, CPS, Card (1995) dataset
   ============================================================ */


/* ── 0. SETUP ─────────────────────────────────────────────── */

clear all
set more off
capture log close
log using "mincer_returns.log", replace

* Load data (replace path as needed)
* use "nlsy79.dta", clear
* use "https://yourpath/card1995.dta", clear

* ── Synthetic data for replication (remove if using real data) ──
set seed 432
set obs 3000

gen educ      = round(rnormal(13, 2.5))
replace educ  = max(6, min(20, educ))
gen exper     = round(rnormal(18, 10))
replace exper = max(0, min(45, exper))
gen exper2    = exper^2
gen female    = (runiform() < 0.48)
gen black     = (runiform() < 0.12)
gen married   = (runiform() < 0.60)
gen union     = (runiform() < 0.15)
gen urban     = (runiform() < 0.70)
gen south     = (runiform() < 0.35)
gen tenure    = round(runiform(0, 20))

* True wage equation with noise
gen ln_wage = 1.0 + 0.10*educ + 0.04*exper - 0.0007*exper2 ///
              - 0.22*female + 0.08*married + 0.12*union      ///
              + 0.10*urban  - 0.05*south  + rnormal(0, 0.35)

* Instruments
gen nearc4   = (runiform() < 0.55)
gen fatheduc = round(rnormal(11, 3.5))
gen motheduc = round(rnormal(11, 3.5))
replace fatheduc = max(0, min(20, fatheduc))
replace motheduc = max(0, min(20, motheduc))

label var ln_wage  "Log hourly wage"
label var educ     "Years of schooling"
label var exper    "Potential experience"
label var exper2   "Experience squared"
label var female   "Female (=1)"
label var black    "Black (=1)"
label var married  "Married (=1)"
label var union    "Union member (=1)"
label var urban    "Urban residence (=1)"
label var south    "Southern state (=1)"
label var nearc4   "Near 4-year college (=1)"
label var fatheduc "Father's education (years)"
label var motheduc "Mother's education (years)"


/* ── 1. DESCRIPTIVE STATISTICS ────────────────────────────── */

di _newline(2) "=== DESCRIPTIVE STATISTICS ==="

summarize ln_wage educ exper female black married union urban south

* Wage distribution
histogram ln_wage, normal                                      ///
    title("Distribution of Log Hourly Wages")                  ///
    xtitle("Log Hourly Wage") ytitle("Density")                ///
    scheme(s2color)
graph export "fig1_wage_dist.png", replace

* Schooling distribution
histogram educ, discrete                                       ///
    title("Years of Schooling Distribution")                   ///
    xtitle("Years of Schooling") ytitle("Frequency")
graph export "fig2_educ_dist.png", replace

* Mean wages by education level
graph bar ln_wage, over(educ)                                  ///
    title("Mean Log Wage by Years of Schooling")               ///
    ytitle("Mean Log Wage")
graph export "fig3_wage_by_educ.png", replace


/* ── 2. BASELINE OLS: MINCER EQUATION ─────────────────────── */

di _newline(2) "=== BASELINE MINCER EQUATION (OLS) ==="

* Specification 1: Classic Mincer — schooling + experience quadratic
reg ln_wage educ exper exper2

estimates store mincer_basic
di "Return to one year of schooling: " _b[educ]*100 "% "

* Specification 2: Extended controls
reg ln_wage educ exper exper2 female black married union urban south, robust

estimates store mincer_extended
di "Return to schooling (extended): " _b[educ]*100 "% "

* Specification 3: With tenure
reg ln_wage educ exper exper2 tenure female black married union urban south, robust

estimates store mincer_full

* ── Display comparison table ──
esttab mincer_basic mincer_extended mincer_full,                ///
    title("Mincer Earnings Equations")                          ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)                   ///
    mtitles("Basic" "Extended" "Full")                          ///
    stats(N r2 r2_a, labels("Observations" "R²" "Adj. R²"))    ///
    note("Robust standard errors in parentheses (cols 2-3).")


/* ── 3. EXPERIENCE-EARNINGS PROFILE ───────────────────────── */

di _newline(2) "=== EXPERIENCE-EARNINGS PROFILE ==="

reg ln_wage educ exper exper2 female black married union urban south, robust

* Peak experience = -b_exper / (2 * b_exper2)
scalar peak_exper = -_b[exper] / (2 * _b[exper2])
di "Peak experience: " peak_exper " years"

* Plot predicted wage profile at mean schooling
quietly summarize educ
scalar mean_educ = r(mean)

margins, at(exper = (0(2)40) educ = `=mean_educ') noatlegend
marginsplot,                                                    ///
    title("Predicted Log Wage by Experience (at Mean Schooling)")  ///
    xtitle("Years of Experience") ytitle("Predicted Log Wage")
graph export "fig4_experience_profile.png", replace


/* ── 4. HETEROSKEDASTICITY DIAGNOSTICS ────────────────────── */

di _newline(2) "=== HETEROSKEDASTICITY TESTS ==="

* Re-run without robust for tests
reg ln_wage educ exper exper2 female black married union urban south

* Breusch-Pagan test
estat hettest
di "H0: Constant variance. Reject → use robust SEs."

* White test
estat imtest, white

* Residual-vs-fitted plot
rvfplot, yline(0)                                              ///
    title("Residuals vs Fitted Values")                        ///
    xtitle("Fitted Values") ytitle("Residuals")
graph export "fig5_rvf_plot.png", replace


/* ── 5. IV ESTIMATION (2SLS) ──────────────────────────────── */

/* Motivation: schooling is endogenous due to ability bias.
   Instruments: 
     nearc4   — geographic proximity to 4-year college (Card 1995)
     fatheduc — father's education
     motheduc — mother's education                              */

di _newline(2) "=== INSTRUMENTAL VARIABLES (2SLS) ==="

* First stage: relevance of instruments
reg educ nearc4 fatheduc motheduc exper exper2                 ///
        female black married urban south, robust

di "First-stage F-statistic (rule of thumb > 10):"
test nearc4 fatheduc motheduc
di "F = " r(F)

estimates store first_stage

* 2SLS estimation
ivregress 2sls ln_wage (educ = nearc4 fatheduc motheduc)       ///
    exper exper2 female black married urban south, robust first

estimates store iv_2sls
di "IV return to schooling: " _b[educ]*100 "% "

* Overidentification test (instruments must be exogenous)
estat overid
di "H0: All instruments are exogenous (p > 0.05 → do not reject)."

* Endogeneity test: is OLS inconsistent?
estat endogenous
di "H0: educ is exogenous. Reject → IV preferred."

* Compare OLS vs IV
esttab mincer_extended iv_2sls,                                ///
    title("OLS vs IV Estimates of Returns to Schooling")       ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)                   ///
    mtitles("OLS" "IV (2SLS)")                                 ///
    keep(educ exper exper2 female black married union)         ///
    note("Instruments: nearc4, fatheduc, motheduc")


/* ── 6. RETURNS BY SUBGROUP ────────────────────────────────── */

di _newline(2) "=== RETURNS TO EDUCATION BY SUBGROUP ==="

* By gender
forvalues g = 0/1 {
    reg ln_wage educ exper exper2 black married union urban south ///
        if female == `g', robust
    local label = cond(`g'==1, "Female", "Male")
    di "`label' return to schooling: " _b[educ]*100 "% (SE: " _se[educ] ")"
}

* Test equality of returns across gender
reg ln_wage c.educ##female exper exper2 black married union urban south, robust
test c.educ#1.female
di "Test: equal returns by gender — p-value = " r(p)


/* ── 7. OAXACA-BLINDER DECOMPOSITION ──────────────────────── */

di _newline(2) "=== OAXACA-BLINDER WAGE DECOMPOSITION ==="

/* Decomposes the gender wage gap into:
     Endowments  (explained)   — differences in X characteristics
     Coefficients (unexplained) — differences in returns to X      */

* Requires oaxaca package
* ssc install oaxaca, replace

oaxaca ln_wage educ exper exper2 black married union urban south, ///
    by(female) robust noisily

di "Unexplained gap = discrimination + unobserved heterogeneity"


/* ── 8. QUANTILE REGRESSION ────────────────────────────────── */

di _newline(2) "=== QUANTILE REGRESSION: RETURNS ACROSS WAGE DISTRIBUTION ==="

* Returns to schooling may differ at different points of the distribution
qreg ln_wage educ exper exper2 female black married union urban south, q(25)
estimates store qr_25

qreg ln_wage educ exper exper2 female black married union urban south, q(50)
estimates store qr_50

qreg ln_wage educ exper exper2 female black married union urban south, q(75)
estimates store qr_75

qreg ln_wage educ exper exper2 female black married union urban south, q(90)
estimates store qr_90

esttab qr_25 qr_50 qr_75 qr_90,                               ///
    title("Quantile Regression: Returns to Education")         ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)                   ///
    mtitles("Q25" "Q50" "Q75" "Q90")                           ///
    keep(educ) note("Bootstrap standard errors.")


/* ── 9. SUMMARY TABLE ──────────────────────────────────────── */

di _newline(2) "=== FINAL SUMMARY ==="

esttab mincer_basic mincer_extended iv_2sls,                   ///
    title("Education Returns: OLS and IV Estimates")           ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)                   ///
    mtitles("OLS Basic" "OLS Extended" "IV 2SLS")              ///
    stats(N r2, labels("N" "R²"))                              ///
    note("Robust SEs. IV instruments: college proximity, parental education.")

log close
