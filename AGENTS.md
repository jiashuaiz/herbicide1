# AGENTS.md

## Cursor Cloud specific instructions

### Project overview
R-based data analysis project for herbicide resistance reporting in South-East Australian farms. The pipeline has 3 stages executed in order via R Markdown files:

1. `Merge.Rmd` — Merges resistance phenotype data with sample sizes (requires `tidyverse` pre-loaded: `Rscript -e 'library(tidyverse); rmarkdown::render("Merge.Rmd")'`)
2. `Output_PNG.Rmd` — Generates histogram and map PNG images per farmer per herbicide
3. `Report_html/Report_html_batch.Rmd` — Renders per-farmer HTML reports using `Report per farmer4.Rmd` as a child template

### Data files
The project expects data files in `../data/` relative to the workspace root. Since the workspace is at `/workspace/`, data lives in `/data/`. The `Report_html/` subdirectory also references `../data/` (resolving to `/workspace/data/`), so a symlink at `/workspace/data -> /data` is needed if running from the `Report_html/` directory.

Similarly, generated images go to `../img/` (i.e., `/img/`), with a symlink at `/workspace/img -> /img` for cross-directory access.

### Key gotchas
- `Merge.Rmd` does not call `library(tidyverse)` itself; `pivot_wider` will fail unless tidyverse is loaded before rendering. Use: `Rscript -e 'library(tidyverse); rmarkdown::render("Merge.Rmd")'`
- `Report_html_batch.Rmd` reads `combined_dataframe.txt` but `Merge.Rmd` writes `combined_dataframe.csv`. You may need to copy/rename the `.csv` to `.txt` for the batch report to work.
- The `Report_html_batch.Rmd` must be rendered from within the `Report_html/` directory (its working directory matters for relative paths).
- No linting or automated test framework exists in this repository. Validation is done by rendering each `.Rmd` file and checking the output.

### Running the pipeline
```bash
# Step 1: Merge data
cd /workspace && Rscript -e 'library(tidyverse); rmarkdown::render("Merge.Rmd")'

# Step 2: Generate PNG images
cd /workspace && Rscript -e 'rmarkdown::render("Output_PNG.Rmd")'

# Step 3: Generate HTML reports
cd /workspace/Report_html && Rscript -e 'rmarkdown::render("Report_html_batch.Rmd")'
```

### System dependencies
- R (>= 4.x), pandoc
- R packages: `knitr`, `rmarkdown`, `tidyverse`, `maps`, `png` (plus `grid` from base R)
- System libraries for building R packages: `libcurl4-openssl-dev`, `libssl-dev`, `libxml2-dev`, `libfontconfig1-dev`, `libharfbuzz-dev`, `libfribidi-dev`, `libfreetype6-dev`, `libpng-dev`, `libtiff5-dev`, `libjpeg-dev`
