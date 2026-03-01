# AGENTS.md

## Cursor Cloud specific instructions

### Project overview
R-based data analysis project for herbicide resistance reporting in South-East Australian farms. Separated into three layers:

- **Analysis** (`R/analysis.R`, `R/data_loader.R`): Data merging, validation, statistics
- **Visualization** (`R/visualization.R`): Histogram and gradient-map PNG generation
- **Display** (`Report_html/`, `templates/`): Per-farmer HTML report templates and CSS
- **Configuration** (`R/config.R`, `R/utils.R`): Centralized paths, settings, utilities

### Running the pipeline
The single entry point is `run_pipeline.R`:
```bash
cd /workspace
Rscript run_pipeline.R              # all steps
Rscript run_pipeline.R merge        # step 1 only
Rscript run_pipeline.R images       # step 2 only
Rscript run_pipeline.R reports      # step 3 only
```

Individual Rmd files still work standalone:
```bash
cd /workspace && Rscript -e 'rmarkdown::render("Merge.Rmd")'
cd /workspace && Rscript -e 'rmarkdown::render("Output_PNG.Rmd")'
cd /workspace/Report_html && Rscript -e 'rmarkdown::render("Report_html_batch.Rmd")'
```

### Data files
The project expects data in `../data/` relative to the project root. On the cloud VM the data lives in `/data/` with a symlink at `/workspace/data -> /data`. Similarly, generated images go to `/img/` with `/workspace/img -> /img`.

### Key gotchas
- `R/config.R` auto-detects the project root via `.git` directory. All file paths flow from config — no hardcoded paths in analysis/visualization code.
- The `Report per farmer4.Rmd` template is rendered as a standalone document (not a child Rmd). Variables (`farmer`, `df`, `config`, etc.) are passed via a `new.env()` render environment.
- Chunk labels in the template are prefixed `template-` to avoid conflicts with the batch file's labels.
- `Report_html_batch.Rmd` reads `combined_dataframe.txt` but `merge_resistance_data()` writes `.csv`. Copy/rename if running the batch Rmd standalone without `run_pipeline.R`.
- Column access uses safe bracket notation (`df[[col]]`) instead of `eval(parse(...))` to prevent code injection.
- No automated test framework exists. Validation is done by rendering each Rmd or running `run_pipeline.R` and checking outputs.

### System dependencies
R (>= 4.x), pandoc, and R packages: `knitr`, `rmarkdown`, `tidyverse`, `maps`, `png` (plus `grid` from base R).
