# The Price of Education: Estimating Wage Returns with Instrumental Variables
### Microeconomic Analysis of Returns to Schooling

Estimates the private returns to education using the Mincerian earnings function. The analysis addresses the core empirical challenge in this literature — ability bias in OLS estimates of schooling returns — through instrumental variables estimation, and extends the baseline model to examine heterogeneity across the wage distribution and between demographic groups.

---

## What This Script Does

The analysis proceeds in nine steps:

**1. Descriptive Statistics**
Summary statistics and visualizations of the wage and schooling distributions, including mean log wages by years of schooling.

**2. Baseline OLS — Mincer Equation**
Three OLS specifications of increasing complexity: classic Mincer (schooling + experience quadratic), extended controls (gender, race, marital status, union, urban, region), and full model with tenure. Results are presented in a side-by-side comparison table.

**3. Experience-Earnings Profile**
Estimates the peak of the experience-earnings profile using the quadratic specification and plots predicted wages over the experience range at mean schooling.

**4. Heteroskedasticity Diagnostics**
Breusch-Pagan and White tests for non-constant variance. Residual-vs-fitted plot. Motivates the use of robust standard errors throughout.

**5. IV Estimation (2SLS)**
Addresses the endogeneity of schooling due to unobserved ability. Instruments: geographic proximity to a four-year college (Card 1995), father's education, and mother's education. Reports first-stage F-statistic, overidentification test, and endogeneity test. Compares OLS and IV estimates directly.

**6. Returns by Subgroup**
Separate regressions for men and women with a formal test of equality of returns to schooling across gender.

**7. Oaxaca-Blinder Decomposition**
Decomposes the raw gender wage gap into an explained component (differences in characteristics) and an unexplained component (differences in returns to those characteristics).

**8. Quantile Regression**
Estimates returns to schooling at the 25th, 50th, 75th, and 90th percentiles of the wage distribution. Reveals whether high-wage workers benefit more or less from an additional year of schooling.

**9. Summary Table**
Side-by-side comparison of OLS basic, OLS extended, and IV 2SLS estimates.

---

## Key Variables

| Variable | Description |
|----------|-------------|
| `ln_wage` | Log hourly wage (outcome) |
| `educ` | Years of schooling (key regressor) |
| `exper` | Potential labor market experience |
| `exper2` | Experience squared |
| `female` | Female indicator |
| `black` | Black indicator |
| `married` | Married indicator |
| `union` | Union member indicator |
| `nearc4` | Near 4-year college — instrument |
| `fatheduc` | Father's years of schooling — instrument |
| `motheduc` | Mother's years of schooling — instrument |

---

## Econometric Methods

| Section | Method | Purpose |
|---------|--------|---------|
| 2 | OLS with robust SEs | Baseline returns estimate |
| 4 | Breusch-Pagan, White test | Detect heteroskedasticity |
| 5 | 2SLS IV | Correct for ability bias |
| 5 | Sargan-Hansen overid test | Validate instrument exogeneity |
| 5 | Hausman-type endogeneity test | Confirm OLS inconsistency |
| 7 | Oaxaca-Blinder | Decompose gender wage gap |
| 8 | Quantile regression | Distributional heterogeneity |

---

## Outputs Generated

| File | Description |
|------|-------------|
| `fig1_wage_dist.png` | Histogram of log wages with normal overlay |
| `fig2_educ_dist.png` | Schooling distribution |
| `fig3_wage_by_educ.png` | Mean log wage by education level |
| `fig4_experience_profile.png` | Predicted wage over experience range |
| `fig5_rvf_plot.png` | Residuals vs fitted values |
| `mincer_returns.log` | Full Stata log file |

---

## Requirements

**Stata packages** (install via `ssc install`):
```stata
ssc install esttab       // or: ssc install estout
ssc install oaxaca
```

**Compatible datasets:** NLSY79, Current Population Survey (CPS), Card (1995) replication data. The script includes a synthetic dataset for immediate replication — replace the data-generation block with a `use` or `import` command when using real data.

---

## Usage

```stata
do 01_mincer_education_returns.do
```

All sections run sequentially. To run a single section, execute the code between the section comment headers. Log output is saved to `mincer_returns.log` in the working directory.

---

## Interpretation Notes

- The **OLS return to schooling** is typically upward-biased due to unobserved ability. IV estimates using geographic instruments are generally lower, reflecting a local average treatment effect (LATE) for compliers — individuals whose schooling decision was influenced by college proximity.
- **First-stage F > 10** is the conventional threshold for instrument relevance. Weak instruments inflate IV standard errors and can cause finite-sample bias toward OLS.
- The **Oaxaca-Blinder unexplained gap** captures both discrimination and the effect of any unobserved characteristics that differ by gender. It should not be interpreted as pure discrimination.
- **Quantile regression** coefficients do not require distributional assumptions and are robust to outliers in the tails.

---

## References

- Mincer, J. (1974). *Schooling, Experience, and Earnings.* NBER.
- Card, D. (1995). Using geographic variation in college proximity to estimate the return to schooling. In *Aspects of Labour Market Behaviour.* University of Toronto Press.
- Oaxaca, R. (1973). Male-female wage differentials in urban labor markets. *International Economic Review*, 14(3), 693–709.
