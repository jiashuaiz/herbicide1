#!/usr/bin/env Rscript
#' Single entry point for the herbicide resistance analysis pipeline.
#'
#' Usage:
#'   Rscript run_pipeline.R              # run all steps
#'   Rscript run_pipeline.R merge        # merge data only
#'   Rscript run_pipeline.R images       # generate PNGs only
#'   Rscript run_pipeline.R reports      # generate HTML reports only

# ── Load modules ──────────────────────────────────────────────────────────────
source("R/config.R")
source("R/utils.R")
source("R/data_loader.R")
source("R/analysis.R")
source("R/visualization.R")
source("R/report.R")

config <- get_config()

# ── Parse arguments ───────────────────────────────────────────────────────────
args  <- commandArgs(trailingOnly = TRUE)
steps <- if (length(args) == 0) c("merge", "images", "reports") else tolower(args)

# ── Step 1: Merge ─────────────────────────────────────────────────────────────
if ("merge" %in% steps) {
  message("\n=== Step 1: Merging resistance and sample-size data ===")
  df_combined <- merge_resistance_data(config)
  message("  Rows: ", nrow(df_combined), "  Columns: ", ncol(df_combined))
}

# ── Step 2: Images ────────────────────────────────────────────────────────────
if ("images" %in% steps) {
  message("\n=== Step 2: Generating histogram and map PNGs ===")
  generate_all_images(config)
}

# ── Step 3: Reports ───────────────────────────────────────────────────────────
if ("reports" %in% steps) {
  message("\n=== Step 3: Generating per-farmer HTML reports ===")
  farmers <- generate_all_reports(config, progress_fn = function(f) {
    message("  Report: ", f)
  })
}

message("\n=== Pipeline complete ===")
