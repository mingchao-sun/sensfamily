# The engines against the reference packages sensemakr (Cinelli-Hazlett) and robomit (Oster), on the Darfur data.
# Run from the module root:  Rscript tests/reference.R
for (f in c("R/engine_ovb.R", "R/engine_oster.R")) source(f)
nfail <- 0
chk <- function(name, got, want, tol) {
    d <- max(abs(got - want)); ok <- is.finite(d) && d < tol
    cat(sprintf("%-58s %s  max |diff| = %.1e (tol %.0e)\n", name, if (ok) "ok  " else "FAIL", d, tol))
    if (!ok) nfail <<- nfail + 1
}
dat <- read.csv("data/darfur.csv", stringsAsFactors = TRUE)
covs <- c("age", "farmer_dar", "herder_dar", "pastvoted", "hhsize_darfur", "female", "village")
X <- model.matrix(reformulate(covs), dat)[, -1, drop = FALSE]
asg <- attr(model.matrix(reformulate(covs), dat), "assign")[-1]
grp <- function(v) which(asg == match(v, covs))

if (requireNamespace("sensemakr", quietly = TRUE)) {
    suppressMessages(library(sensemakr))
    m <- lm(peacefactor ~ directlyharmed + age + farmer_dar + herder_dar + pastvoted + hhsize_darfur + female + village, data = dat)
    for (q in c(1, 0.5)) {
        ref <- sensemakr(m, treatment = "directlyharmed", benchmark_covariates = c("female", "age"), kd = 1:3, q = q)
        ours <- sv_ovb(dat$peacefactor, dat$directlyharmed, X, list(female = grp("female"), age = grp("age")), kd = 1:3, q = q)
        s <- ref$sensitivity_stats
        chk(sprintf("q=%g estimate, se, t, partial R2", q), c(ours$stats$estimate, ours$stats$se, ours$stats$t, ours$stats$r2yd.x),
            c(s$estimate, s$se, s$t_statistic * 0 + s$estimate / s$se, s$r2yd.x), 1e-9)
        chk(sprintf("q=%g robustness value RV_q", q), ours$stats$rv_q, s$rv_q, 1e-9)
        chk(sprintf("q=%g robustness value RV_q,alpha", q), ours$stats$rv_qa, s$rv_qa, 1e-9)
        chk(sprintf("q=%g partial f2", q), ours$stats$f2, s$f2yd.x, 1e-9)
        b <- ref$bounds
        ob <- ours$bounds[order(match(ours$bounds$benchmark, c("female", "age")), ours$bounds$k), ]
        rb <- b[order(match(sub("^[0-9]x ", "", b$bound_label), c("female", "age")), as.numeric(sub("x .*", "", b$bound_label))), ]
        chk(sprintf("q=%g bounds: r2dz.x", q), ob$r2dz.x, rb$r2dz.x, 1e-9)
        chk(sprintf("q=%g bounds: r2yz.dx", q), ob$r2yz.dx, rb$r2yz.dx, 1e-9)
        chk(sprintf("q=%g bounds: adjusted estimate", q), ob$estimate, rb$adjusted_estimate, 1e-9)
        chk(sprintf("q=%g bounds: adjusted se", q), ob$se, rb$adjusted_se, 1e-9)
        chk(sprintf("q=%g bounds: adjusted CI", q), c(ob$lo, ob$hi), c(rb$adjusted_lower_CI, rb$adjusted_upper_CI), 1e-9)
    }
} else cat("sensemakr not installed: skipped\n")

if (requireNamespace("robomit", quietly = TRUE) && requireNamespace("dplyr", quietly = TRUE)) {
    suppressMessages(library(robomit))
    d2 <- dat; d2$village <- as.character(d2$village)
    con <- paste(covs, collapse = " + ")
    p <- sv_oster_inputs(dat$peacefactor, dat$directlyharmed, X)
    for (rm in c(1.3 * p$R21, 1)) {
        refd <- o_delta(y = "peacefactor", x = "directlyharmed", con = con, beta = 0, R2max = rm, type = "lm", data = d2)
        chk(sprintf("delta* for beta = 0, Rmax = %.3f", rm), sv_oster_delta(p, rm, 0), refd$Value[refd$Name == "delta*"], 5e-6)
        for (dl in c(1, 0.5, 2)) {
            refb <- o_beta(y = "peacefactor", x = "directlyharmed", con = con, delta = dl, R2max = rm, type = "lm", data = d2)
            chk(sprintf("beta* for delta = %g, Rmax = %.3f", dl, rm), sv_oster_beta(p, rm, dl), refb$Value[refb$Name == "beta*"], 5e-6)
        }
    }
} else cat("robomit not installed: skipped\n")
cat(if (nfail == 0) "\nAll reference checks passed.\n" else sprintf("\n%d reference check(s) FAILED.\n", nfail))
if (nfail > 0) quit(status = 1)
