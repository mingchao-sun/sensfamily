# Engine for the Cinelli-Hazlett sensitivity analysis of omitted variable bias in linear regression.
# Base R only. Formulas follow Cinelli and Hazlett (2020, JRSS-B); cross-checked against sensemakr.

sv_bf  <- function(r2yz.dx, r2dz.x) sqrt(r2yz.dx * r2dz.x / (1 - r2dz.x))
sv_sef <- function(r2yz.dx, r2dz.x) sqrt((1 - r2yz.dx) / (1 - r2dz.x))

sv_partial_r2 <- function(t, dof) t^2 / (t^2 + dof)

# Robustness value RV_{q,alpha}: strength of association (partial R2 with both treatment and outcome) that a
# confounder needs to reduce the estimate by 100q% (alpha = 1) or to make it insignificant at level alpha.
sv_rv <- function(t, dof, q = 1, alpha = 1) {
    fq <- q * abs(t / sqrt(dof))
    fcrit <- if (alpha >= 1) 0 else abs(stats::qt(alpha / 2, df = dof - 1)) / sqrt(dof - 1)
    fqa <- fq - fcrit
    if (fqa <= 0) return(0)
    if (fcrit > 0 && fq > 1 / fcrit) {                      # extreme robustness value
        f1 <- fq^2; f2 <- fcrit^2
        return((f1 - f2) / (1 + f1))
    }
    2 / (1 + sqrt(1 + 4 / fqa^2))
}

sv_adjust <- function(est, se, dof, r2dz.x, r2yz.dx, reduce = TRUE, h0 = 0) {
    bias <- sv_bf(r2yz.dx, r2dz.x) * se * sqrt(dof)
    adj <- sign(est) * (abs(est) + if (reduce) -bias else bias)
    adj_se <- sv_sef(r2yz.dx, r2dz.x) * se * sqrt(dof / (dof - 1))
    list(estimate = adj, se = adj_se, t = (adj - h0) / adj_se, bias = bias)
}

# Bounds on the strength of a confounder, as multiples (kd, ky) of the strength of an observed benchmark covariate.
sv_bound <- function(r2dxj.x, r2yxj.dx, kd = 1, ky = kd) {
    r2dz.x <- kd * (r2dxj.x / (1 - r2dxj.x))
    if (any(r2dz.x >= 1)) stop("The multiplier is too large: the implied partial R2 with the treatment is 1 or more.", call. = FALSE)
    r2zxj.xd <- kd * (r2dxj.x^2) / ((1 - kd * r2dxj.x) * (1 - r2dxj.x))
    if (any(r2zxj.xd >= 1)) stop("The multiplier is too large for this benchmark covariate.", call. = FALSE)
    r2yz.dx <- ((sqrt(ky) + sqrt(r2zxj.xd)) / sqrt(1 - r2zxj.xd))^2 * (r2yxj.dx / (1 - r2yxj.dx))
    list(r2dz.x = r2dz.x, r2yz.dx = min(r2yz.dx, 1), capped = r2yz.dx > 1)
}

# Partial R2 of a group of columns (one benchmark variable, possibly several dummies) after the other columns.
sv_group_r2 <- function(y, Xfull, cols) {
    if (length(cols) == 0 || length(cols) >= ncol(Xfull)) stop("Invalid benchmark group.", call. = FALSE)
    r1 <- stats::lm.fit(Xfull, y)$residuals
    r0 <- stats::lm.fit(Xfull[, -cols, drop = FALSE], y)$residuals
    (sum(r0^2) - sum(r1^2)) / sum(r0^2)
}

# y: outcome; d: treatment; X: matrix of other covariates (no intercept); groups: list(name = column indices of X).
sv_ovb <- function(y, d, X, groups = list(), kd = 1, ky = NULL, q = 1, alpha = 0.05, reduce = TRUE, h0 = 0) {
    n <- length(y)
    Xc <- cbind(1, d, X)
    fit <- stats::lm.fit(Xc, y)
    dof <- n - ncol(Xc)
    if (dof < 3) stop("Too few observations for the number of covariates.", call. = FALSE)
    rss <- sum(fit$residuals^2)
    XtXi <- chol2inv(chol(crossprod(Xc)))
    est <- unname(fit$coefficients[2]); se <- sqrt(rss / dof * XtXi[2, 2]); t <- est / se
    stats_tab <- list(estimate = est, se = se, t = t, dof = dof, r2yd.x = sv_partial_r2(t, dof), f2 = t^2 / dof,
                      rv_q = sv_rv(t, dof, q, 1), rv_qa = sv_rv(t, dof, q, alpha))
    bounds <- NULL
    if (length(groups)) {
        Xd <- cbind(1, X)                                       # treatment regressed on the covariates
        crit <- stats::qt(1 - alpha / 2, df = dof)               # as sensemakr: residual degrees of freedom of the original model
        for (g in names(groups)) {
            r2d <- sv_group_r2(d, Xd, groups[[g]] + 1)          # +1: intercept column
            r2y <- sv_group_r2(y, Xc, groups[[g]] + 2)          # +2: intercept and treatment
            for (k in kd) {
                b <- sv_bound(r2d, r2y, k, if (is.null(ky)) k else ky)
                a <- sv_adjust(est, se, dof, b$r2dz.x, b$r2yz.dx, reduce, h0)
                bounds <- rbind(bounds, data.frame(benchmark = g, k = k, r2dxj = r2d, r2yxj = r2y, r2dz.x = b$r2dz.x, r2yz.dx = b$r2yz.dx,
                                                   capped = b$capped, estimate = a$estimate, se = a$se, t = a$t,
                                                   lo = a$estimate - crit * a$se, hi = a$estimate + crit * a$se, stringsAsFactors = FALSE))
            }
        }
    }
    list(stats = stats_tab, bounds = bounds, est = est, se = se, dof = dof, q = q, reduce = reduce, h0 = h0, alpha = alpha)
}

# Adjusted estimate and t over a grid of (r2dz.x, r2yz.dx), for the contour plot.
sv_grid <- function(est, se, dof, lim = c(0.4, 0.4), n = 41, reduce = TRUE, h0 = 0) {
    g <- expand.grid(r2dz.x = seq(0, lim[1], length.out = n), r2yz.dx = seq(0, lim[2], length.out = n))
    a <- sv_adjust(est, se, dof, g$r2dz.x, g$r2yz.dx, reduce, h0)
    g$estimate <- a$estimate; g$t <- a$t
    g
}
