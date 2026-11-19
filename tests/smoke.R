# Headless run of both analyses (the .b.R classes). Run from the module root. Best run in jamovi's own R with the jamovi libraries.
suppressMessages({library(jmvcore); library(R6); library(ggplot2)})
for (f in c("R/00jmv.R", "R/common.R", "R/engine_ovb.R", "R/engine_oster.R", "R/guide.R",
            list.files("R", "[.]h[.]R$", full.names = TRUE), list.files("R", "[.]b[.]R$", full.names = TRUE))) source(f)
d <- read.csv("data/darfur.csv", stringsAsFactors = TRUE)
bad <- 0
run <- function(label, fn, ...) {
    a <- list(...)
    fm <- formals(fn)
    for (n in setdiff(names(fm)[vapply(fm, function(z) identical(z, quote(expr = )), logical(1))], c("data", names(a)))) a[n] <- list(NULL)
    r <- tryCatch({ res <- do.call(fn, c(list(data = d), a)); print(res); "ok" }, error = function(e) paste("ERROR:", conditionMessage(e)))
    cat(sprintf("%-44s %s\n", label, substr(r, 1, 110))); if (r != "ok" && !grepl("^ERROR", r)) bad <<- bad + 1
    invisible(r)
}
ok <- function(label, ...) { r <- run(label, ...); if (r != "ok") bad <<- bad + 1 }
err <- function(label, ...) { r <- run(label, ...); if (!grepl("^ERROR", r)) { cat("  expected an error\n"); bad <<- bad + 1 } }
covs <- c("age", "farmer_dar", "herder_dar", "pastvoted", "hhsize_darfur")
ok("ovb basic", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = c(covs, "village"), bench = "female", plot = FALSE)
ok("ovb no benchmark", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = covs, plot = FALSE)
ok("ovb plot + notes + t", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = covs, bench = "female", plotStat = "t", showGuide = TRUE, showHelp = TRUE)
ok("ovb increase, q = 50, kd list", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = setdiff(covs, "age"), bench = c("female", "age"), direction = "increase", q = 50, kd = "0.5; 1, 2", plot = FALSE)
ok("ovb continuous treatment", ovb, outcome = "peacefactor", treat = "age", covs = c("farmer_dar", "herder_dar"), bench = "female", plot = FALSE)
ok("ovb missing treatment (shows a hint)", ovb, outcome = "peacefactor", treat = NULL, plot = FALSE)
err("ovb bad kd", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = covs, bench = "female", kd = "abc", plot = FALSE)
err("ovb huge kd", ovb, outcome = "peacefactor", treat = "directlyharmed", covs = covs, bench = "female", kd = "1000", plot = FALSE)
ok("oster basic", oster, outcome = "peacefactor", treat = "directlyharmed", covs = c(covs, "female", "village"), plot = FALSE)
ok("oster plot + notes", oster, outcome = "peacefactor", treat = "directlyharmed", covs = c(covs, "female"), showGuide = TRUE, showHelp = TRUE)
ok("oster Rmax value, delta 2, target 0.05", oster, outcome = "peacefactor", treat = "directlyharmed", covs = c(covs, "female"), rmaxType = "value", rmax = 0.9, delta = 2, beta0 = 0.05, plot = FALSE)
err("oster Rmax below R2", oster, outcome = "peacefactor", treat = "directlyharmed", covs = c(covs, "female"), rmaxType = "value", rmax = 0.05, plot = FALSE)
ok("oster no controls (shows a hint)", oster, outcome = "peacefactor", treat = "directlyharmed", covs = NULL, plot = FALSE)
cat(if (bad == 0) "\nAll checks passed.\n" else sprintf("\n%d check(s) failed.\n", bad))
if (bad > 0) quit(status = 1)
