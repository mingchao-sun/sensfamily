# jamovi analysis class: sensitivity of a regression coefficient to omitted variable bias (Cinelli and Hazlett, 2020).

ovbClass <- R6::R6Class(
    "ovbClass",
    inherit = ovbBase,
    private = list(

        .run = function() {
            opts <- self$options
            sv_show_text(self$results, opts, "ovb")
            if (is.null(opts$outcome) || is.null(opts$treat)) {
                self$results$notes$setContent("<p>Select an outcome and a treatment (and covariates) to begin.</p>")
                return()
            }
            notes <- character(0)
            pp <- sv_guard(sv_prepare(self$data, opts$outcome, opts$treat, opts$covs, opts$bench))
            if (pp$n_drop > 0) notes <- c(notes, sprintf("%d observation(s) with missing values were dropped.", pp$n_drop))
            kd <- suppressWarnings(as.numeric(strsplit(gsub("[;[:space:]]+", ",", trimws(opts$kd)), ",")[[1]]))
            kd <- kd[!is.na(kd)]
            if (length(pp$groups) && (length(kd) == 0 || any(kd <= 0)))
                jmvcore::reject("Enter positive multiples of the benchmark strength, for example 1, 2, 3.", code = "")
            alpha <- 1 - opts$level / 100
            reduce <- identical(opts$direction, "reduce")
            r <- sv_guard(sv_ovb(pp$y, pp$d, pp$X, pp$groups, kd = kd, q = opts$q / 100, alpha = alpha, reduce = reduce, h0 = opts$h0))
            s <- r$stats

            self$results$coef$setRow(rowNo = 1, values = list(
                estimate = s$estimate, se = s$se, t = s$t, p = 2 * stats::pt(-abs(s$t), s$dof), df = s$dof, r2 = s$r2yd.x, f2 = s$f2))
            self$results$coef$setNote("n", sprintf("%d observations; ordinary least squares with the usual standard errors. The treatment is %s.", pp$n,
                                                   if (pp$binary) "binary" else "continuous"))

            tb <- self$results$rv
            tb$deleteRows()
            pct <- function(x) sprintf("%.1f%%", 100 * x)
            tb$addRow(rowKey = 1, values = list(item = sprintf("RV (reduce the estimate by %s%%)", sv_fmt(opts$q, 1)), rv = s$rv_q, pct = pct(s$rv_q)))
            tb$addRow(rowKey = 2, values = list(item = sprintf("RV (make it insignificant at %s%%)", sv_fmt(100 * alpha, 1)), rv = s$rv_qa, pct = pct(s$rv_qa)))
            tb$setNote("rv", paste0("A confounder that explains less than this share of the residual variance of both the treatment and the outcome ",
                                    "cannot change the estimate by the stated amount, however it is related to them. ",
                                    sprintf("Partial R2 of the treatment with the outcome: %s.", pct(s$r2yd.x))))

            bt <- self$results$bounds
            bt$deleteRows()
            if (!is.null(r$bounds)) {
                bt$setVisible(TRUE)
                for (i in seq_len(nrow(r$bounds))) {
                    b <- r$bounds[i, ]
                    bt$addRow(rowKey = i, values = list(bench = b$benchmark, k = b$k, r2d = b$r2dz.x, r2y = b$r2yz.dx, est = b$estimate,
                                                        se = b$se, t = b$t, lo = b$lo, hi = b$hi))
                }
                if (any(r$bounds$capped)) notes <- c(notes, "For some multiples the implied partial R2 with the outcome exceeded 1 and was set to 1.")
                bt$setNote("b", paste0("The confounder is assumed to explain k times as much of the treatment and of the outcome as the benchmark covariate does ",
                                       "(partial R2 given the other covariates), and to move the estimate ",
                                       if (reduce) "towards zero." else "away from zero."))
            }
            if (isTRUE(opts$plot)) {
                lim <- c(opts$plotLim, opts$plotLim)
                grid <- sv_grid(r$est, r$se, r$dof, lim, 41, reduce, opts$h0)
                thr <- if (identical(opts$plotStat, "estimate")) r$est * (1 - opts$q / 100) else stats::qt(1 - alpha / 2, r$dof - 1)
                self$results$contour$setState(list(grid = grid, bounds = r$bounds, stat = opts$plotStat, thr = thr, est = r$est, h0 = opts$h0,
                                                   lim = lim, q = opts$q))
            }
            notes <- c(notes, "The analysis assumes a linear model; the robustness value and the bounds describe how strong an omitted variable would have to be, not whether one exists.")
            self$results$notes$setContent(paste0("<p>", paste(notes, collapse = " "), "</p>"))
        },

        .plotContour = function(image, ggtheme, theme, ...) {
            st <- image$state
            if (is.null(st)) return(FALSE)
            gr <- st$grid
            gr$z <- if (identical(st$stat, "estimate")) gr$estimate else gr$t
            lab <- if (identical(st$stat, "estimate")) "Adjusted estimate" else "Adjusted t statistic"
            # The jamovi theme may carry discrete fill scales; adding it first lets the continuous fill scale below replace them.
            g <- ggplot2::ggplot(gr, ggplot2::aes(x = r2dz.x, y = r2yz.dx, z = z)) + ggtheme +
                ggplot2::geom_raster(ggplot2::aes(fill = z), interpolate = TRUE) +
                ggplot2::scale_fill_gradient2(low = "#B2182B", mid = "white", high = "#2166AC", midpoint = st$thr, name = lab) +
                ggplot2::geom_contour(colour = "grey35", linewidth = 0.3, bins = 10) +
                ggplot2::geom_contour(breaks = st$thr, colour = "red", linetype = "dashed", linewidth = 0.9) +
                ggplot2::annotate("point", x = 0, y = 0, shape = 24, fill = "black", size = 2.5) +
                ggplot2::coord_cartesian(xlim = c(0, st$lim[1]), ylim = c(0, st$lim[2]), expand = FALSE) +
                ggplot2::labs(x = "Partial R2 of the confounder with the treatment", y = "Partial R2 of the confounder with the outcome")
            if (!is.null(st$bounds)) {
                b <- st$bounds
                b$lab <- sprintf("%gx %s", b$k, b$benchmark)
                b <- b[b$r2dz.x <= st$lim[1] & b$r2yz.dx <= st$lim[2], , drop = FALSE]
                if (nrow(b))
                    g <- g + ggplot2::geom_point(data = b, ggplot2::aes(x = r2dz.x, y = r2yz.dx), inherit.aes = FALSE, shape = 23, fill = "red", size = 2.5) +
                        ggplot2::geom_text(data = b, ggplot2::aes(x = r2dz.x, y = r2yz.dx, label = lab), inherit.aes = FALSE, hjust = -0.1, vjust = -0.5, size = 3)
            }
            print(g)
            TRUE
        }
    )
)
