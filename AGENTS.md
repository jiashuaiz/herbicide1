# AGENTS.md

## Cursor Cloud specific instructions

### Project overview
Shiny web application for herbicide resistance reporting in South-East Australian farms. Users upload data, analysis runs on the backend, and farmers view their personalised reports in-browser.

**Architecture layers:**
- **Service** (`app.R`): Shiny web app — handles uploads, runs pipeline, serves reports
- **Analysis** (`R/analysis.R`, `R/data_loader.R`): Data merging, validation, statistics
- **Visualization** (`R/visualization.R`): Histogram and gradient-map PNG generation
- **Reports** (`R/report.R`): Per-farmer HTML report rendering via Rmd templates
- **Display** (`Report_html/`, `templates/`): Report templates and CSS
- **Config** (`R/config.R`, `R/utils.R`): Centralized paths, settings, utilities
- **Sample data** (`sample_data/`): Bundled example files for demo mode

### Running the service
```bash
cd /workspace && Rscript -e 'shiny::runApp("app.R", port = 3838, host = "0.0.0.0")'
```

### CLI pipeline (still available)
```bash
cd /workspace && Rscript run_pipeline.R             # all steps
cd /workspace && Rscript run_pipeline.R merge        # step 1 only
cd /workspace && Rscript run_pipeline.R images       # step 2 only
cd /workspace && Rscript run_pipeline.R reports      # step 3 only
```

### Key gotchas
- `R/config.R` auto-detects the project root via `.git`. The Shiny app passes session-specific temp directories for `data_dir`, `img_dir`, and `report_dir` to isolate concurrent users.
- The report template (`Report per farmer4.Rmd`) is rendered in a `new.env(parent = globalenv())`. Functions from `R/analysis.R` and `R/utils.R` must be sourced into the global environment before rendering.
- Chunk labels in the template are prefixed `template-` to avoid conflicts with the batch Rmd.
- Landscape gradient RDS files are optional for upload; sample gradient files are used as fallback.
- Column access throughout uses safe bracket notation (`df[[col]]`) instead of `eval(parse(...))`.
- No automated test framework exists. Validation is by running the Shiny app and checking generated reports.

### System dependencies
R (>= 4.x), pandoc, and R packages: `shiny`, `knitr`, `rmarkdown`, `tidyverse`, `maps`, `png` (plus `grid` from base R).
