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

  library(png)
  library(grid)

  df <- load_combined_data(config)
  list_farmers    <- unique(df$Farmer_Agronomist)
  list_Herbicides <- config$herbicides
  list_colours    <- config$colors
  df_commercial_name_of_herbicide <- load_commercial_names(config)

  template_path <- file.path(config$project_root, "Report_html", "Report per farmer4.Rmd")
  ensure_dir(config$report_dir)

  for (farmer in list_farmers) {
    if (farmer == "None") next
    safe_name   <- sanitize_name(farmer)
    output_path <- file.path(config$report_dir, paste0(safe_name, ".html"))

    render_env <- new.env(parent = globalenv())
    render_env$farmer      <- farmer
    render_env$df          <- df
    render_env$config      <- config
    render_env$list_Herbicides <- list_Herbicides
    render_env$list_colours    <- list_colours
    render_env$df_commercial_name_of_herbicide <- df_commercial_name_of_herbicide

    rmarkdown::render(
      template_path,
      output_file = output_path,
      envir       = render_env,
      quiet       = TRUE
    )
    message("  Report: ", output_path)
  }
}

message("\n=== Pipeline complete ===")
