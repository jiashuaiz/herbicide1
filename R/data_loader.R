#' Data loading and validation layer.
#'
#' All data ingestion passes through validation to catch missing columns
#' or files before they cause cryptic errors downstream.

validate_columns <- function(df, required, file_desc) {
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop(
      file_desc, " is missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  invisible(df)
}

load_pheno_data <- function(config) {
  path <- file.path(config$data_dir, "POP_PHENO_DATA.txt")
  if (!file.exists(path)) stop("Phenotype data file not found: ", path)

  df <- read.delim(path, header = TRUE, na.strings = c("#N/A", "-"))
  validate_columns(df, c("Farmer_Agronomist", "Accession_Name"), "POP_PHENO_DATA.txt")
  df
}

load_sample_sizes <- function(config) {
  path <- file.path(config$data_dir, "SAMPLE_SIZES.txt")
  if (!file.exists(path)) stop("Sample sizes file not found: ", path)

  df <- read.delim(path, header = TRUE, na.strings = c("#N/A", "-"))
  validate_columns(df, c("Accession_Name", "HERBICIDE", "SAMPLE_SIZE"), "SAMPLE_SIZES.txt")
  df
}

load_combined_data <- function(config) {
  path_csv <- file.path(config$data_dir, "combined_dataframe.csv")
  path_txt <- file.path(config$data_dir, "combined_dataframe.txt")

  if (file.exists(path_csv)) {
    df <- read.csv(path_csv, header = TRUE, na.strings = c("#N/A", "-"))
  } else if (file.exists(path_txt)) {
    first_line <- readLines(path_txt, n = 1)
    reader <- if (grepl("\t", first_line)) read.delim else read.csv
    df <- reader(path_txt, header = TRUE, na.strings = c("#N/A", "-"))
  } else {
    stop("Combined dataframe not found in: ", config$data_dir)
  }

  for (c_idx in seq_len(ncol(df))) {
    if (c_idx >= 13) df[, c_idx] <- as.numeric(df[, c_idx])
  }
  df
}

load_commercial_names <- function(config) {
  path <- file.path(config$data_dir, "Commercial name of herbicides.csv")
  if (!file.exists(path)) stop("Commercial names file not found: ", path)
  read.csv(path, header = TRUE)
}

load_landscape_gradient <- function(config, herbicide) {
  path <- file.path(config$data_dir, paste0("landscape_surfaces_gradient_data_", herbicide, ".rds"))
  if (!file.exists(path)) stop("Landscape gradient not found: ", path)
  readRDS(path)
}
