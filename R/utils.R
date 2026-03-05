#' Shared utility functions.

ensure_dir <- function(path) {
  if (!file.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

sanitize_name <- function(name) {
  gsub("/", " ", name)
}
