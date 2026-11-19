# Helpers shared by the sensitivity analyses.

sv_fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, drop0trailing = TRUE)

# Turn engine errors into readable jamovi messages.
sv_guard <- function(expr) tryCatch(expr, error = function(e) jmvcore::reject(conditionMessage(e), code = ""))

sv_show_text <- function(results, opts, key) {
    if (isTRUE(opts$showGuide)) results$guide$setContent(sv_guide_html(key))
    if (isTRUE(opts$showHelp)) results$helpText$setContent(sv_notes_html(key))
}

sv_bt <- function(v) paste0("`", v, "`")

# Outcome, treatment and covariates from the jamovi data frame. Rows with a missing value are dropped and counted.
# bench: variables used for benchmarking; they are in the regression like any covariate and their columns are
# returned as groups (a nominal variable is one group of dummies).
sv_prepare <- function(data, outcome, treat, covs = NULL, bench = NULL) {
    if (is.null(outcome) || is.null(treat)) stop("Select an outcome and a treatment.", call. = FALSE)
    both <- intersect(covs, bench)
    if (length(both)) stop("A variable cannot be both a covariate and a benchmark covariate.", call. = FALSE)
    vars <- unique(c(outcome, treat, covs, bench))
    df <- data[, vars, drop = FALSE]
    keep <- stats::complete.cases(df)
    n_drop <- sum(!keep)
    df <- df[keep, , drop = FALSE]
    if (nrow(df) < 20) stop("Fewer than 20 complete observations.", call. = FALSE)
    num <- function(v, label) {
        if (is.factor(v)) stop(sprintf("The %s must be a numeric variable (set its type to Continuous in the Data tab).", label), call. = FALSE)
        out <- as.numeric(v)
        if (any(!is.finite(out))) stop(sprintf("The %s has infinite values.", label), call. = FALSE)
        out
    }
    y <- num(df[[outcome]], "outcome")
    tv <- df[[treat]]
    d <- if (is.factor(tv)) {
        if (nlevels(droplevels(tv)) != 2) stop("A nominal treatment must have exactly two levels (the second level is treated as 1).", call. = FALSE)
        as.numeric(droplevels(tv) == levels(droplevels(tv))[2])
    } else num(tv, "treatment")
    if (stats::sd(y) == 0) stop("The outcome has no variation.", call. = FALSE)
    if (stats::sd(d) == 0) stop("The treatment has no variation.", call. = FALSE)
    allc <- c(covs, bench)
    X <- matrix(numeric(0), nrow(df), 0)
    groups <- list()
    if (length(allc)) {
        for (v in allc) if (is.factor(df[[v]])) df[[v]] <- droplevels(df[[v]]) else df[[v]] <- num(df[[v]], paste("variable", v))
        mm <- stats::model.matrix(stats::reformulate(sv_bt(allc)), df)
        asg <- attr(mm, "assign")
        X <- mm[, -1, drop = FALSE]; asg <- asg[-1]
        for (v in bench) groups[[v]] <- which(asg == match(v, allc))
    }
    Xc <- cbind(1, d, X)
    if (qr(Xc)$rank < ncol(Xc))
        stop("The covariates are collinear with each other or with the treatment; remove the redundant variables.", call. = FALSE)
    list(y = y, d = d, X = X, groups = groups, n = length(y), n_drop = n_drop, binary = all(d %in% c(0, 1)))
}
