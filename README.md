# sensfamily — sensitivity analysis in jamovi

A jamovi module for asking how much an unobserved confounder would matter for a regression estimate. It has two post-estimation tools for a linear
regression of an outcome on a treatment and controls. Chinese summary: [README.zh.md](README.zh.md).

## Analyses (jamovi menu: Sensitivity > Regression)

| Analysis | What it answers | Reference |
|---|---|---|
| **Omitted Variable Bias** | How strong would an unobserved confounder have to be, in terms of partial R2 with the treatment and the outcome, to bring the estimate to zero (or make it insignificant)? Robustness values, bounds that use an observed covariate as a benchmark, and a contour plot. | Cinelli and Hazlett (2020) |
| **Coefficient Stability** | How much does the treatment coefficient move if selection on unobservables is delta times selection on the observed controls? The delta that gives a target value, the bias-adjusted coefficient, and bounds. | Oster (2019) |

The E-value and Rosenbaum bounds for matched or weighted estimates are in `matchfamily` (Sensitivity to Unobserved Confounding). Every analysis has *Method notes*
and *Data and setup guide* in its Output section.

## Install
- **jamovi library**: in jamovi open the modules button (top right), *jamovi library*, find *Sensitivity Analysis Family* and install (once the module is listed).
- **Sideload**: download the `.jmo` file and use *Install from file* in the same menu. A `.jmo` works only on the operating system, processor type and jamovi version it was built for.
- **From source** (needs R and the jamovi compiler `jmvtools`; adjust the path to your jamovi folder):
```r
jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")
```

## Use from R (Rj editor, scripts)
Every analysis is also an R function, for example
```r
sensfamily::ovb(data = d, outcome = "peacefactor", treat = "directlyharmed",
                covs = c("age", "farmer_dar", "herder_dar", "pastvoted", "hhsize_darfur", "female", "village"), bench = "female")
```

## Data format
One row per observation. A numeric outcome, a treatment (numeric or binary) and numeric or categorical control variables. Rows with missing values are dropped and reported.

## Example data
Shown in jamovi under **Open > Data Library > Sensitivity Analysis Family**. `data/darfur.csv`: the Darfur survey of the `sensemakr` package (1,276 refugees in Chad;
outcome `peacefactor`, treatment `directlyharmed`); the entry says which variable goes where.

## References
Papers and R packages behind each analysis appear in the References section of the jamovi output (defined in `jamovi/00refs.yaml`).

## Validation
The engines use base R only. `tests/reference.R` compares them with the R packages `sensemakr` and `robomit`: robustness values, bounds, bias-adjusted coefficients and the
delta that gives a target value agree to rounding error. The Stata commands `sensemakr` and `psacalc` are compared in `../stata_validation/`. `tests/smoke.R` runs both
analyses headless, including bad input.

## Known limitations
- Linear regression only; no logit or other nonlinear models.
- The robustness value and the Oster bounds assume the stated benchmark or proportionality (R-max) assumptions; they describe how fragile a result is and cannot prove that there is no confounding.
- Oster's bounds depend on the choice of the maximum R2 (R-max) of the full model.

## Notes for developers
- Layout: `R/engine_*.R` is plain R with no jamovi dependency; `R/*.b.R` and `jamovi/*.yaml` are the jamovi front end.
- Tests: `Rscript tests/smoke.R`, `tests/reference.R` (needs `sensemakr` and `robomit`); `tests/ui_checklist.md` lists what to check by hand in jamovi.
- Ribbon icon: `icon/analysis-sens.svg` (74 x 44): contours of the adjusted estimate against the strength of the confounder, with an observed benchmark covariate near the origin. jmvtools 28.17 cannot attach an icon to a module, so `dev/icon_preview.ps1` adds one CSS rule for the menu group to jamovi's client stylesheet (administrator PowerShell, restart jamovi afterwards).

## How to cite
Sun, M. *sensfamily: Sensitivity Analysis Family for jamovi* (jamovi module). https://github.com/mingchao-sun/sensfamily. Please also cite Cinelli and Hazlett (2020) and Oster (2019).

## License
GPL-3, as stated in `DESCRIPTION`; third-party code and data are listed in `NOTICE.md`. Bug reports and suggestions: https://github.com/mingchao-sun/sensfamily/issues
