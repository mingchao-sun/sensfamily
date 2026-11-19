# sensfamily: sensitivity analysis for jamovi

Menu: Sensitivity > Regression

| Analysis | What it answers | Reference |
|---|---|---|
| **Omitted Variable Bias** | How strong would an unobserved confounder have to be, in terms of partial R2 with the treatment and the outcome, to bring the estimate to zero (or make it insignificant)? Robustness values, bounds that use an observed covariate as a benchmark, and a contour plot. | Cinelli and Hazlett (2020) |
| **Coefficient Stability** | How much does the treatment coefficient move if selection on unobservables is delta times selection on the observed controls? delta that gives a target value, bias-adjusted coefficient, and bounds. | Oster (2019) |

Both are post-estimation tools for a linear regression of an outcome on a treatment and controls. The E-value and Rosenbaum bounds for matched or weighted estimates are in `matchfamily` (Sensitivity to Unobserved Confounding).

The engines use base R only. Results equal the R packages `sensemakr` and `robomit` and the Stata commands `sensemakr` and `psacalc`
(`tests/reference.R`; the Stata comparison is in `../stata_validation`).

Example data: the Darfur survey of the `sensemakr` package (`data/darfur.csv`).

## Ribbon icon

`icon/analysis-sens.svg` (74 x 44, same size and colours as the other families): the contours of the adjusted estimate against the strength of the confounder, the orange contour where the conclusion changes and an observed benchmark covariate near the origin. jmvtools 28.17 cannot attach an icon to a module, so `dev/icon_preview.ps1` adds one CSS rule for the menu group Sensitivity to jamovi's client stylesheet (run it in an administrator PowerShell, see the comments at the top; restart jamovi afterwards).
