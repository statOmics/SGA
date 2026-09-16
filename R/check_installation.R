## ------------------------------------------------------------------------
## Check that your R installation for the msqrob2 course is set up correctly
##
## Run this script (source it, or run it line by line) in RStudio/R after
## following the installation instructions on the course website:
## https://statomics.github.io/PDA/
## ------------------------------------------------------------------------

cat("== Checking your msqrob2 course installation ==\n\n")

problems <- character(0)

## 1. R version ------------------------------------------------------------
cat("R version:", R.version.string, "\n")
if (getRversion() < "4.6") {
  problems <- c(problems, "R version is older than 4.6. Please update R.")
} else {
  cat("  -> OK\n")
}
cat("\n")

## 2. BiocManager ------------------------------------------------------------
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  stop(
    "BiocManager is not installed.\n",
    "  -> install it with: install.packages(\"BiocManager\")"
  )
}
cat("Bioconductor version:", as.character(BiocManager::version()), "\n\n")

## 3. Required course packages ------------------------------------------------
required_pkgs <- c(
  "arrow", "BiocParallel", "BiocFileCache", "ComplexHeatmap", "dplyr",
  "ExploreModelMatrix", "ggpattern", "ggplot2", "ggrepel", "impute",
  "MsDataHub", "patchwork", "scater", "tidyr", "bookdown", "iq",
  "QFeatures", "msqrob2", "kableExtra", "data.table", "ggcorrplot",
  "ggpubr", "callr", "curl", "httpuv"
)

installed_ok <- vapply(
  required_pkgs, requireNamespace, logical(1), quietly = TRUE
)
missing_pkgs <- required_pkgs[!installed_ok]

if (length(missing_pkgs)) {
  problems <- c(
    problems,
    paste0(
      "Missing package(s): ", paste(missing_pkgs, collapse = ", "), "\n",
      "  -> install with: BiocManager::install(c(",
      paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))"
    )
  )
  cat("Missing required package(s):", paste(missing_pkgs, collapse = ", "), "\n\n")
} else {
  cat("All required course packages are installed.\n\n")
}

## 4. msqrob2: is it the current Bioconductor release? ------------------------
if ("msqrob2" %in% rownames(utils::installed.packages())) {
  msqrob2_version <- as.character(utils::packageVersion("msqrob2"))
  cat("msqrob2 version installed:", msqrob2_version, "\n")

  latest_msqrob2 <- tryCatch(
    {
      repo <- utils::available.packages(
        repos = BiocManager::repositories()["BioCsoft"]
      )
      if ("msqrob2" %in% rownames(repo)) repo["msqrob2", "Version"] else NA
    },
    error = function(e) NA
  )

  if (is.na(latest_msqrob2)) {
    cat("  -> could not reach Bioconductor to verify this is the latest release",
        "(check your internet connection).\n\n")
  } else if (package_version(msqrob2_version) < package_version(latest_msqrob2)) {
    problems <- c(
      problems,
      paste0(
        "msqrob2 is outdated (installed: ", msqrob2_version,
        ", latest release: ", latest_msqrob2, ").\n",
        "  -> update with: BiocManager::install(\"msqrob2\")"
      )
    )
    cat("  -> OUTDATED: latest Bioconductor release is", latest_msqrob2, "\n\n")
  } else {
    cat("  -> OK, this is the latest Bioconductor release.\n\n")
  }
} else {
  problems <- c(problems, "msqrob2 is not installed.")
}

## 5. msqrob2gui (optional, for the GUI tutorial) -----------------------------
## Expected minimum version corresponds to the release used in this course;
## update this if a newer msqrob2gui release is announced.
min_msqrob2gui_version <- "0.0.9"

if (requireNamespace("msqrob2gui", quietly = TRUE)) {
  msqrob2gui_version <- as.character(utils::packageVersion("msqrob2gui"))
  cat("msqrob2gui version installed:", msqrob2gui_version, "\n")

  if (package_version(msqrob2gui_version) < package_version(min_msqrob2gui_version)) {
    problems <- c(
      problems,
      paste0(
        "msqrob2gui is outdated (installed: ", msqrob2gui_version,
        ", required: >= ", min_msqrob2gui_version, ").\n",
        "  -> update with: BiocManager::install(\"remotes\"); ",
        "remotes::install_github(\"statomics/msqrob2gui\")"
      )
    )
    cat("  -> OUTDATED: please update (required >=", min_msqrob2gui_version, ")\n\n")
  } else {
    cat("  -> OK\n\n")
  }
} else {
  cat(
    "msqrob2gui is not installed. This is only needed for the GUI tutorial.\n",
    "  -> install with: BiocManager::install(\"remotes\"); ",
    "remotes::install_github(\"statomics/msqrob2gui\")\n\n"
  )
}

## 6. Does the msqrob2gui Shiny app launch? -----------------------------------
if (requireNamespace("msqrob2gui", quietly = TRUE)) {
  cat("Checking whether the msqrob2gui app launches...\n")

  app <- tryCatch(
    msqrob2gui::launchMsqrob2App(launch.browser = FALSE),
    error = function(e) {
      problems <<- c(problems, paste0(
        "msqrob2gui app failed to build: ", conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(app) || !inherits(app, "shiny.appobj")) {
    cat("  -> FAILED to build the app (see problem above).\n\n")
  } else {
    cat("  -> app object built successfully (ui/server construction OK)\n")

    port <- httpuv::randomPort()
    bg <- callr::r_bg(
      function(port) {
        app <- msqrob2gui::launchMsqrob2App(launch.browser = FALSE)
        shiny::runApp(app, port = port, launch.browser = FALSE)
      },
      args = list(port = port),
      package = TRUE
    )

    up <- FALSE
    for (i in seq_len(20)) {
      Sys.sleep(0.5)
      status <- tryCatch(
        curl::curl_fetch_memory(paste0("http://127.0.0.1:", port))$status_code,
        error = function(e) NA
      )
      if (!is.na(status) && status == 200) {
        up <- TRUE
        break
      }
      if (!bg$is_alive()) break
    }

    bg_err <- tryCatch(bg$read_error_lines(), error = function(e) character(0))
    bg$kill()

    if (up) {
      cat("  -> app launched and responded on http://127.0.0.1:", port, "\n\n", sep = "")
    } else {
      problems <- c(
        problems,
        paste0(
          "msqrob2gui app did not respond after launching.",
          if (length(bg_err)) paste0(
            "\n  Shiny process output:\n  ", paste(bg_err, collapse = "\n  ")
          ) else ""
        )
      )
      cat("  -> FAILED: app did not respond within the timeout.\n\n")
    }
  }
} else {
  cat("Skipping msqrob2gui launch check (msqrob2gui not installed).\n\n")
}

## 7. Smoke test: can the packages actually be loaded? ------------------------
smoke_test_pkgs <- intersect(c("QFeatures", "msqrob2"), rownames(utils::installed.packages()))
for (pkg in smoke_test_pkgs) {
  loaded <- tryCatch(
    {
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
      TRUE
    },
    error = function(e) {
      problems <<- c(problems, paste0("Failed to load ", pkg, ": ", conditionMessage(e)))
      FALSE
    }
  )
  cat(pkg, "loads correctly:", loaded, "\n")
}
cat("\n")

## ------------------------------------------------------------------------
## Summary
## ------------------------------------------------------------------------
cat("== Summary ==\n")
if (length(problems) == 0) {
  cat("Your installation looks good. You are ready for the course!\n")
} else {
  cat("The following issue(s) were found:\n\n")
  for (p in problems) cat("- ", p, "\n\n", sep = "")
  cat("Please fix the issue(s) above. If you get stuck, post an issue on GitHub:\n")
  cat("https://github.com/statOmics/PDA/issues\n")
}
