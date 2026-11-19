# jamovi analysis class: coefficient stability and selection on unobservables (Oster, 2019).

osterClass <- R6::R6Class(
    "osterClass",
    inherit = osterBase,
    private = list(

        .init = function() {
            tb <- self$results$est
            tb$addRow(rowKey = 1, values = list(model = "Without controls"))
            tb$addRow(rowKey = 2, values = list(model = "With controls"))
        },

        .run = function() {
            opts <- self$options
            sv_show_text(self$results, opts, "oster")
            if (is.null(opts$outcome) || is.null(opts$treat) || length(opts$covs) == 0) {
                self$results$notes$setContent("<p>Select an outcome, a treatment and at least one control to begin.</p>")
                return()
            }
            notes <- character(0)
            pp <- sv_guard(sv_prepare(self$data, opts$outcome, opts$treat, opts$covs, NULL))
            if (pp$n_drop > 0) notes <- c(notes, sprintf("%d observation(s) with missing values were dropped.", pp$n_drop))
            p <- sv_guard(sv_oster_inputs(pp$y, pp$d, pp$X))
            if (abs(p$b0 - p$b1) < 1e-10 * max(1, abs(p$b1)))
                jmvcore::reject("The coefficient does not change when the controls are added, so the bounds are not defined.", code = "")
            if (p$R21 <= p$R20 + 1e-12)
                jmvcore::reject("The controls do not raise the R2, so the bounds are not defined.", code = "")
            rmax <- if (identical(opts$rmaxType, "multiple")) min(opts$rmax * p$R21, 1) else opts$rmax
            if (rmax <= p$R21 + 1e-12) {
                jmvcore::reject(sprintf("Rmax (%s) must exceed the R2 of the controlled regression (%s).", sv_fmt(rmax, 3), sv_fmt(p$R21, 3)), code = "")
            }
            if (rmax > 1) jmvcore::reject("Rmax cannot exceed 1.", code = "")
            if (identical(opts$rmaxType, "multiple") && opts$rmax * p$R21 > 1)
                notes <- c(notes, sprintf("%s times the R2 of the controlled regression exceeds 1; Rmax was set to 1.", sv_fmt(opts$rmax, 2)))

            tb <- self$results$est
            tb$setRow(rowNo = 1, values = list(coef = p$b0, r2 = p$R20))
            tb$setRow(rowNo = 2, values = list(coef = p$b1, r2 = p$R21))

            dstar <- sv_guard(sv_oster_delta(p, rmax, opts$beta0))
            bstar <- sv_guard(sv_oster_beta(p, rmax, opts$delta))
            lo <- min(p$b1, bstar); hi <- max(p$b1, bstar)
            rs <- self$results$res
            rs$deleteRows()
            rows <- list(c("Rmax used", rmax), c(sprintf("Delta that gives a coefficient of %s", sv_fmt(opts$beta0, 3)), dstar),
                         c(sprintf("Coefficient at delta = %s", sv_fmt(opts$delta, 2)), bstar),
                         c("Bounds: lower", lo), c("Bounds: upper", hi))
            for (i in seq_along(rows)) rs$addRow(rowKey = i, values = list(item = rows[[i]][1], value = as.numeric(rows[[i]][2])))
            excl <- (opts$beta0 < lo || opts$beta0 > hi)
            rs$setNote("r", paste0(
                "Bounds run between the controlled coefficient and the coefficient at the chosen delta. ",
                if (excl) sprintf("They exclude the target value %s", sv_fmt(opts$beta0, 3)) else sprintf("They include the target value %s", sv_fmt(opts$beta0, 3)),
                if (is.finite(dstar)) sprintf("; unobservables would have to be %s times as important as the observed controls (delta = %s) to bring the coefficient to the target. ", sv_fmt(abs(dstar), 2), sv_fmt(dstar, 2)) else "; delta is not defined here. ",
                "Oster suggests that a result is robust when the bounds, at Rmax = 1.3 times the controlled R2 and delta = 1, exclude zero."))

            gr <- self$results$grid
            gr$deleteRows()
            mult <- c(1.1, 1.3, 1.5, 2, Inf)
            vals <- pmin(mult * p$R21, 1)
            lab <- ifelse(is.infinite(mult), "Rmax = 1", sprintf("%s x R2", sv_fmt(mult, 1)))
            ok <- vals > p$R21 + 1e-12
            vals <- vals[ok]; lab <- lab[ok]
            keep <- !duplicated(vals); vals <- vals[keep]; lab <- lab[keep]
            for (i in seq_along(vals)) {
                gr$addRow(rowKey = i, values = list(rmax = vals[i], label = lab[i], dstar = sv_oster_delta(p, vals[i], opts$beta0),
                                                    bstar = sv_oster_beta(p, vals[i], opts$delta)))
            }
            if (isTRUE(opts$plot)) {
                rg <- seq(p$R21 + 0.02 * (1 - p$R21), 1, length.out = 60)
                self$results$dPlot$setState(list(rmax = rg, d = vapply(rg, function(r) sv_oster_delta(p, r, opts$beta0), numeric(1)), cur = c(rmax, dstar), r21 = p$R21))
            }
            notes <- c(notes, "The method assumes that the unobserved variables are related to the treatment as the observed controls are, scaled by delta, and that the regression with all variables would reach Rmax. It uses the whole sample and ordinary least squares.")
            self$results$notes$setContent(paste0("<p>", paste(notes, collapse = " "), "</p>"))
        },

        .plotDelta = function(image, ggtheme, theme, ...) {
            st <- image$state
            if (is.null(st)) return(FALSE)
            df <- data.frame(rmax = st$rmax, d = st$d)
            df <- df[is.finite(df$d), , drop = FALSE]
            if (nrow(df) < 2) return(FALSE)
            g <- ggplot2::ggplot(df, ggplot2::aes(x = rmax, y = d)) +
                ggplot2::geom_hline(yintercept = 1, linetype = "dashed", colour = "grey40") +
                ggplot2::geom_line(linewidth = 0.8) +
                ggplot2::labs(x = "Rmax", y = "Delta that gives the target value") + ggtheme
            if (is.finite(st$cur[2])) g <- g + ggplot2::geom_point(data = data.frame(rmax = st$cur[1], d = st$cur[2]), size = 3, colour = "red")
            print(g)
            TRUE
        }
    )
)
