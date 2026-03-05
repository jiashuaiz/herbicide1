#' Centralized configuration for the herbicide resistance analysis pipeline.
#'
#' All paths, herbicide definitions, and display settings are managed here
#' to eliminate hardcoded values from analysis and visualization code.

find_project_root <- function(start_dir = getwd()) {
  dir <- normalizePath(start_dir)
  while (dir != dirname(dir)) {
    if (file.exists(file.path(dir, ".git"))) return(dir)
    dir <- dirname(dir)
  }
  stop("Could not find project root (no .git directory found)")
}

get_config <- function(data_dir = NULL, img_dir = NULL, report_dir = NULL) {
  root <- find_project_root()

  if (is.null(data_dir))   data_dir   <- normalizePath(file.path(root, "..", "data"), mustWork = FALSE)
  if (is.null(img_dir))    img_dir    <- normalizePath(file.path(root, "..", "img"),  mustWork = FALSE)
  if (is.null(report_dir)) report_dir <- file.path(root, "Report_html", "report")

  list(
    project_root = root,
    data_dir     = data_dir,
    img_dir      = img_dir,
    report_dir   = report_dir,
    herbicides   = c("Clethodim", "Glyphosate", "Sulfometuron", "Terbuthylazine"),
    colors       = c("#BF7EBE", "#f0a55b", "#8BA5F2", "#FF7F7E", "#78C679")
  )
}
