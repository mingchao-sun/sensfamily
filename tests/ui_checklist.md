# sensfamily: checklist for testing in jamovi

Menu: Sensitivity > Regression. Install: `jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")`.
Open sample data from File > Open > Data Library > Sensitivity Analysis Family: "Darfur: violence and attitudes towards peace".
In the Data tab, set `village` to Nominal (690 levels; skip it for a quick first look) and check that `peacefactor`, `directlyharmed` and the other numbers are Continuous or Nominal-with-numbers as you prefer.

## 1. Omitted Variable Bias, quick look (no village)
Outcome `peacefactor`; Treatment `directlyharmed`; Covariates `age`, `farmer_dar`, `herder_dar`, `pastvoted`, `hhsize_darfur`; Benchmark covariates `female`. Leave the options as they are.
Expect: estimate 0.0489 (s.e. 0.0184, t 2.658, df 1268); robustness value 7.2% (reduce by 100%) and 1.9% (make it insignificant);
bounds table for `female`: 1x 0.0368, 2x 0.0247, 3x 0.0126 (the last t is 0.875, CI -0.016 to 0.041); a contour plot with the dashed red zero contour, three red diamonds labelled `1x female`, `2x female`, `3x female`, and a triangle at the origin.

## 2. Omitted Variable Bias, with village effects
Add `village` (Nominal) to Covariates (it can take a few seconds).
Expect: estimate 0.0973 (s.e. 0.0233, t 4.184, df 783); RV 13.9% and 7.6%; `female` bounds 0.0752, 0.0529, 0.0304 (the 3x CI includes zero: -0.006 to 0.067).

## 3. Omitted Variable Bias, options
- Sensitivity group: Reduce the estimate by 50 -> the robustness value falls and the dashed contour moves; direction "Away from zero"; multiples `0.5, 1, 2`; null value 0.05; confidence level 90.
- Plot group: Contours show "Adjusted t statistic"; largest partial R2 0.2; untick Contour plot (the plot disappears).
- Move `female` out of Benchmark covariates: the bounds table disappears; only the first two tables remain.
- Type `abc` in the multiples box: a message asks for positive numbers. Type `1000`: a message says the multiple is too large.
- Tick Method notes and Data and setup guide: both open with headed sections.

## 4. Coefficient Stability (Oster)
Outcome `peacefactor`; Treatment `directlyharmed`; Controls `age`, `farmer_dar`, `herder_dar`, `pastvoted`, `hhsize_darfur`, `female`.
Expect: coefficient 0.0634 (R2 0.008) without controls and 0.0489 (R2 0.152) with controls; Rmax 0.197; delta for a zero coefficient 9.23; coefficient at delta = 1 is 0.0442;
bounds 0.0442 to 0.0489; the Rmax table has five rows (1.1, 1.3, 1.5, 2 times R2, and Rmax = 1 with delta 0.543 and coefficient -0.0447); the plot is a falling curve with a red dot and a dashed line at delta = 1.
With `village` added to Controls: coefficients 0.0634 and 0.0973 (R2 0.512), delta 22.6, coefficient at delta = 1 is 0.120.

## 5. Coefficient Stability, options and messages
- Rmax is "A fixed value" 0.9; delta 2; target value 0.05.
- Rmax fixed value 0.05: a message says Rmax must exceed the controlled R2 (0.152).
- Remove all controls: the screen asks for at least one control instead of showing an error.
- Tick Method notes and Data and setup guide.

## Things to look at in the interface
- Variable boxes accept the right types (the treatment box takes a nominal two-level variable); a variable can be in one box only (the benchmark variable is not also a covariate: a message appears if it is).
- Collapsed groups open and close; tables fill in as variables are dropped in and clear when one is removed.
- Number formats, p-values, long variable names; both plots with the dark theme and with a different jamovi palette (the contour fill must stay a blue-white-red gradient).
- The ribbon shows the Sens group (the icon needs `dev/icon_preview.ps1`).
