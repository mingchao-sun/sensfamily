# "Data and setup guide" and "Method notes" for each analysis.

sv_settings <- function(rows) {
    paste0("<table style='border-collapse:collapse;margin:4px 0 8px 0'>",
           "<tr><th style='text-align:left;padding:2px 14px 2px 0;border-bottom:1px solid #999'>Field</th>",
           "<th style='text-align:left;padding:2px 0;border-bottom:1px solid #999'>Set to</th></tr>",
           paste0("<tr><td style='padding:2px 14px 2px 0'>", names(rows), "</td><td style='padding:2px 0'>",
                  unlist(rows), "</td></tr>", collapse = ""), "</table>")
}

sv_guide_raw <- function(key) {
    switch(key,
    ovb = paste0(
        "<h3>Omitted Variable Bias: data and setup</h3>",
        "<p>Asks how strong an unobserved confounder would have to be to change the conclusion of a linear regression, and compares that with the strength of covariates you did observe.</p>",
        "<h4>Sample data</h4>",
        sv_settings(list("Dataset" = "<b>Darfur: violence and attitudes towards peace</b>", "Outcome" = "peacefactor", "Treatment" = "directlyharmed",
                         "Covariates" = "age, farmer_dar, herder_dar, pastvoted, hhsize_darfur, village (Nominal; village has 690 levels, so leave it out for a quick look)",
                         "Benchmark covariates" = "female")),
        "<p>Expected with all those covariates: estimate 0.0973 (s.e. 0.0233, t 4.18, 783 df); robustness value 13.9% for a full reduction and 7.6% to make it insignificant. ",
        "A confounder as strong as <i>female</i> would leave an estimate of 0.075, twice as strong 0.053, three times as strong 0.030 (no longer significant).</p>",
        "<h4>Data layout</h4><p>One row per unit. The outcome is numeric. The treatment is numeric (continuous or 0/1) or a nominal variable with two levels (the second level is 1). ",
        "Covariates and benchmark covariates may be numeric or nominal; a benchmark variable belongs only in the benchmark box and is in the regression like the other covariates. Rows with missing values are dropped and counted.</p>",
        "<h4>Options</h4><ul><li><b>Reduce the estimate by</b>: 100 means the confounder brings the estimate to zero; 50 halves it.</li>",
        "<li><b>Multiples of the benchmark strength</b>: how many times as strongly as the benchmark the confounder is related to the treatment and to the outcome; separate by commas.</li>",
        "<li><b>Contour plot</b>: adjusted estimate (or t) for every strength of the confounder; the dashed line is the value that changes the conclusion; markers show the benchmarks.</li></ul>"),
    oster = paste0(
        "<h3>Coefficient Stability: data and setup</h3>",
        "<p>Asks how much the treatment coefficient would move if unobserved variables mattered as much as the controls already in the model (Oster, 2019).</p>",
        "<h4>Sample data</h4>",
        sv_settings(list("Dataset" = "<b>Darfur: violence and attitudes towards peace</b>", "Outcome" = "peacefactor", "Treatment" = "directlyharmed",
                         "Controls" = "age, farmer_dar, herder_dar, pastvoted, hhsize_darfur, female, village (Nominal)", "Rmax" = "1.3 times the controlled R2 (default)", "Delta" = "1")),
        "<p>Expected: coefficient 0.0634 without controls (R2 0.008) and 0.0973 with controls (R2 0.512). With Rmax = 0.665 (1.3 x 0.512), the delta that brings the coefficient to zero is 22.6, ",
        "and the coefficient at delta = 1 is 0.120. Because the coefficient rises with controls, a hidden variable like the observed ones would not explain the effect away.</p>",
        "<h4>Data layout</h4><p>One row per unit; numeric outcome; numeric or two-level nominal treatment; controls numeric or nominal. Missing values are dropped and counted.</p>"),
    stop("unknown guide: ", key))
}

sv_notes_raw <- function(key) {
    switch(key,
    ovb = paste0(
        "<h3>Omitted Variable Bias: method notes</h3>",
        "<p><b>What it does.</b> Cinelli and Hazlett (2020) express the bias from omitting a variable Z from a linear regression through two partial R2 values: ",
        "R2(D~Z|X), how much of the residual variance of the treatment Z explains, and R2(Y~Z|D,X), how much of the residual variance of the outcome. ",
        "The adjusted estimate and standard error follow exactly from these two numbers.</p>",
        "<p><b>Robustness value.</b> RV is the strength of association with both treatment and outcome that makes the estimate fall by the chosen percentage (RV for the estimate) or makes it insignificant (RV for significance). ",
        "A confounder that explains less than RV of the residual variance of both cannot do that; one that explains more can.</p>",
        "<p><b>Benchmarks.</b> Strength is easier to judge relative to an observed covariate. ",
        "'k times as strong' means the confounder has k times the partial R2 with the treatment of the benchmark, and the outcome association implied by the same multiple (Cinelli and Hazlett, 2020, Section 6).</p>",
        "<p><b>Limits.</b> Linear model; the analysis says how strong a confounder would have to be, not whether one exists. A benchmark comparison is only as good as the argument that the confounder is no stronger than the benchmark.</p>",
        "<p>Results equal the R package sensemakr (and the Stata command of the same name).</p>"),
    oster = paste0(
        "<h3>Coefficient Stability: method notes</h3>",
        "<p><b>What it does.</b> Compares the treatment coefficient without controls with the coefficient with controls, together with the change in R2, to infer how selection on unobservables would move it. ",
        "It assumes that selection on unobservables is delta times selection on observables (proportional selection) and that a regression with all variables would reach R2 = Rmax.</p>",
        "<p><b>Outputs.</b> <i>Delta</i> that brings the coefficient to a target (usually zero): values above 1 mean the unobservables would have to matter more than the controls. ",
        "<i>Bounds</i>: the controlled coefficient and the coefficient at delta = 1 and the chosen Rmax. Oster (2019) proposes Rmax = 1.3 times the controlled R2 and treats a result as robust when the bounds exclude zero.</p>",
        "<p><b>Limits.</b> Rmax is a judgement: Rmax = 1 is the most conservative choice. Proportional selection is an assumption, not a test. The calculation is for a linear regression with a single treatment variable, using the exact formulas of Oster (2019, Proposition 1), as in Stata psacalc and R robomit.</p>"),
    stop("unknown notes: ", key))
}

sv_guide_html <- function(key) sv_guide_raw(key)
sv_notes_html <- function(key) sv_notes_raw(key)
