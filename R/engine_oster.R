# Engine for coefficient stability and the bounds of Oster (2019, JBES). Base R only.
# Formulas as implemented in Stata psacalc and the R package robomit.

# y: outcome; x: treatment (numeric); C: matrix of controls (no intercept).
sv_oster_inputs <- function(y, x, C) {
    m0 <- stats::lm.fit(cbind(1, x), y)
    m1 <- stats::lm.fit(cbind(1, x, C), y)
    aux <- stats::lm.fit(cbind(1, C), x)
    r2 <- function(f) 1 - sum(f$residuals^2) / sum((y - mean(y))^2)
    list(b0 = unname(m0$coefficients[2]), b1 = unname(m1$coefficients[2]), R20 = r2(m0), R21 = r2(m1),
         syy = stats::var(y), sxx = stats::var(x), tx = stats::var(aux$residuals), n = length(y))
}

# delta* that moves the treatment coefficient to `beta` for a given Rmax.
sv_oster_delta <- function(p, Rmax, beta = 0) {
    bt <- p$b1 - beta; rt <- (p$R21 - p$R20) * p$syy; b01 <- p$b0 - p$b1; rm <- (Rmax - p$R21) * p$syy
    tx <- p$tx; sxx <- p$sxx
    num <- bt * rt * tx + bt * sxx * tx * b01^2 + 2 * bt^2 * (tx * b01 * sxx) + bt^3 * (tx * sxx - tx^2)
    den <- rm * b01 * sxx + bt * rm * (sxx - tx) + bt^2 * (tx * b01 * sxx) + bt^3 * (tx * sxx - tx^2)
    num / den
}

# beta* (bias-adjusted treatment effect) for a given delta and Rmax: the root nearest to the controlled estimate
# on the side of the change from the uncontrolled one.
sv_oster_beta <- function(p, Rmax, delta = 1) {
    rt <- (p$R21 - p$R20) * p$syy; b01 <- p$b0 - p$b1; rm <- (Rmax - p$R21) * p$syy; tx <- p$tx; sxx <- p$sxx
    if (abs(delta - 1) < 1e-12) {
        th <- rm * (sxx - tx) - rt * tx - sxx * tx * b01^2
        d1 <- 4 * rm * b01^2 * sxx^2 * tx
        d2 <- -2 * tx * b01 * sxx
        s <- c((-th - sqrt(th^2 + d1)) / d2, (-th + sqrt(th^2 + d1)) / d2)
        b <- p$b1 - s
        b <- b[order((b - p$b1)^2)]
        if (sign(b[1] - p$b1) != sign(p$b1 - p$b0)) b <- rev(b)
        return(b[1])
    }
    den <- (delta - 1) * (tx * sxx - tx^2)
    A <- tx * b01 * sxx * (delta - 2) / den
    B <- (delta * rm * (sxx - tx) - rt * tx - sxx * tx * b01^2) / den
    C <- rm * delta * b01 * sxx / den
    Q <- (A^2 - 3 * B) / 9; R <- (2 * A^3 - 9 * A * B + 27 * C) / 54; D <- R^2 - Q^3
    if (D < 0) {
        th <- acos(R / sqrt(Q^3))
        s <- c(-2 * sqrt(Q) * cos(th / 3) - A / 3, -2 * sqrt(Q) * cos((th + 2 * pi) / 3) - A / 3,
               -2 * sqrt(Q) * cos((th - 2 * pi) / 3) - A / 3)
        b <- p$b1 - s
        dist <- (b - p$b1)^2
        dist[sign(b - p$b1) != sign(p$b1 - p$b0)] <- max(dist) + 1
        return(b[which.min(dist)])
    }
    t1 <- -R + sqrt(D); t2 <- -R - sqrt(D)
    p$b1 - (sign(t1) * abs(t1)^(1 / 3) + sign(t2) * abs(t2)^(1 / 3) - A / 3)
}
