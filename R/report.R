#' Report generation layer.
#'
#' Renders per-farmer HTML reports using the Rmd template.
#' Each report is self-contained (images are base64-embedded).

generate_all_reports <- function(config, progress_fn = NULL) {
  library(png)
  library(grid)

  df <- load_combined_data(config)
  list_farmers    <- unique(df$Farmer_Agronomist)
  list_Herbicides <- config$herbicides
  list_colours    <- config$colors
  df_commercial   <- load_commercial_names(config)

  template_path <- file.path(config$project_root, "Report_html", "Report per farmer4.Rmd")
  ensure_dir(config$report_dir)

  farmers_generated <- character(0)

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
    render_env$df_commercial_name_of_herbicide <- df_commercial

    rmarkdown::render(
      template_path,
      output_file = output_path,
      envir       = render_env,
      quiet       = TRUE
    )
    farmers_generated <- c(farmers_generated, farmer)
    if (!is.null(progress_fn)) progress_fn(farmer)
  }

  farmers_generated
}
