#' Analysis functions: data merging and statistical computations.
#'
#' Pure functions with no side effects beyond writing the combined CSV.
#' Column access uses safe bracket notation instead of eval(parse(...)).

merge_resistance_data <- function(config) {
  df_resistance  <- load_pheno_data(config)
  df_sample_size <- load_sample_sizes(config)

  df_ss_wide <- tidyr::pivot_wider(
    df_sample_size,
    names_from  = HERBICIDE,
    values_from = SAMPLE_SIZE
  )

  herbs_raw  <- unique(df_sample_size$HERBICIDE)
  herbs_fmt  <- paste0(toupper(substring(tolower(herbs_raw), 1, 1)),
                        substring(tolower(herbs_raw), 2))
  colnames(df_ss_wide) <- c("Accession_Name", paste0(herbs_fmt, "_sampleSize"))

  df_combined <- merge(df_resistance, df_ss_wide, by = "Accession_Name", all = TRUE)

  output_path <- file.path(config$data_dir, "combined_dataframe.csv")
  write.csv(df_combined, output_path, row.names = FALSE)
  message("Combined dataframe written to: ", output_path)

  df_combined
}

compute_percentile <- function(value, all_values) {
  round((sum(all_values <= value) / length(all_values)) * 100)
}

format_percentile <- function(v) {
  suffix <- if ((v %% 10) == 1 && (v > 20 || v < 10)) {
    "st"
  } else if ((v %% 10) == 2 && (v > 20 || v < 10)) {
    "nd"
  } else if ((v %% 10) == 3 && (v > 20 || v < 10)) {
    "rd"
  } else {
    "th"
  }
  paste0(v, suffix)
}
