# ==============================================================================
# Herbicide Resistance Analysis Service
# ==============================================================================
# Shiny web application that accepts farmer data uploads, runs the
# analysis pipeline (merge → visualizations → reports), and displays
# per-farmer herbicide resistance reports automatically.
# ==============================================================================

library(shiny)
library(tidyverse)
library(maps)
library(png)
library(grid)
library(rmarkdown)

source("R/config.R")
source("R/utils.R")
source("R/data_loader.R")
source("R/analysis.R")
source("R/visualization.R")
source("R/report.R")

SAMPLE_DIR <- normalizePath("sample_data", mustWork = FALSE)

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "app.css"),
    tags$title("Herbicide Resistance Analyzer")
  ),

  navbarPage(
    title = "Herbicide Resistance Analyzer",
    id    = "main_nav",

    # ── Tab 1: Instructions ──────────────────────────────────────────────────
    tabPanel("Instructions", value = "instructions",
      fluidRow(column(10, offset = 1,

        div(class = "instructions-hero",
          h2("Herbicide Resistance Analysis Tool"),
          p("Upload your farm data and get personalised resistance reports
             for Clethodim, Glyphosate, Sulfometuron, and Terbuthylazine.")
        ),

        div(class = "step-card",
          h4("How It Works"),
          tags$ol(
            tags$li(tags$b("Prepare"), " your data files following the format described below."),
            tags$li(tags$b("Upload"), " them in the ", tags$em("Upload & Analyse"), " tab",
                    " — or click ", tags$em("Try with Sample Data"), " to see a demo."),
            tags$li(tags$b("View results"), " in the ", tags$em("Results"),
                    " tab — select a farmer from the dropdown to see their report.")
          )
        ),

        h3("Required Data Files", style = "margin-top:1.5rem;"),

        div(class = "file-spec",
          h4("1. Phenotype Data — POP_PHENO_DATA.txt"),
          p("Tab-delimited text file with one row per farm accession."),
          tags$table(
            tags$thead(tags$tr(
              tags$th("Column"), tags$th("Type"), tags$th("Description"), tags$th("Example")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$code("Farmer_Agronomist")), tags$td("Text"),
                      tags$td("Farmer or agronomist name"), tags$td("Farmer A")),
              tags$tr(tags$td(tags$code("Accession_Name")), tags$td("Text"),
                      tags$td("Unique sample identifier"), tags$td("ACC001")),
              tags$tr(tags$td(tags$code("Location")), tags$td("Text"),
                      tags$td("Farm location"), tags$td("Horsham VIC")),
              tags$tr(tags$td(tags$code("Coordinates_E")), tags$td("Numeric"),
                      tags$td("Longitude (decimal degrees)"), tags$td("142.2")),
              tags$tr(tags$td(tags$code("Coordinates_N")), tags$td("Numeric"),
                      tags$td("Latitude (decimal degrees)"), tags$td("-36.7")),
              tags$tr(tags$td(tags$code("Clethodim")), tags$td("0 – 1"),
                      tags$td("Resistance value"), tags$td("0.915")),
              tags$tr(tags$td(tags$code("Glyphosate")), tags$td("0 – 1"),
                      tags$td("Resistance value"), tags$td("0.705")),
              tags$tr(tags$td(tags$code("Sulfometuron")), tags$td("0 – 1"),
                      tags$td("Resistance value"), tags$td("0.475")),
              tags$tr(tags$td(tags$code("Terbuthylazine")), tags$td("0 – 1"),
                      tags$td("Resistance value"), tags$td("0.906")),
              tags$tr(tags$td(tags$code("*_SURVI")), tags$td("0 – 1"),
                      tags$td("Survival value per herbicide (4 columns)"), tags$td("0.566"))
            )
          )
        ),

        div(class = "file-spec",
          h4("2. Sample Sizes — SAMPLE_SIZES.txt"),
          p("Tab-delimited text file linking accessions to per-herbicide sample sizes."),
          tags$table(
            tags$thead(tags$tr(
              tags$th("Column"), tags$th("Type"), tags$th("Description"), tags$th("Example")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$code("Accession_Name")), tags$td("Text"),
                      tags$td("Must match phenotype file"), tags$td("ACC001")),
              tags$tr(tags$td(tags$code("HERBICIDE")), tags$td("Text"),
                      tags$td("Herbicide name (uppercase)"), tags$td("CLETHODIM")),
              tags$tr(tags$td(tags$code("SAMPLE_SIZE")), tags$td("Integer"),
                      tags$td("Number of samples tested"), tags$td("47"))
            )
          )
        ),

        div(class = "file-spec",
          h4("3. Commercial Names — Commercial name of herbicides.csv"),
          p("CSV file mapping active ingredients to product names."),
          tags$table(
            tags$thead(tags$tr(
              tags$th("Column"), tags$th("Example")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$code("Active.Ingredient..a.i..")), tags$td("Clethodim")),
              tags$tr(tags$td(tags$code("Product.Name")), tags$td("Status Clethodim 240"))
            )
          )
        ),

        div(class = "file-spec",
          h4("4. Landscape Gradient Files (Optional)"),
          p("RDS files for spatial resistance maps — one per herbicide.",
            tags$br(),
            "If not provided, the sample gradient data will be used for map backgrounds."),
          p(tags$code("landscape_surfaces_gradient_data_{Herbicide}.rds"),
            " — each containing a list with ", tags$code("predx"),
            ", ", tags$code("predy"), ", ", tags$code("Z"), ".")
        ),

        div(class = "step-card", style = "margin-top:1rem;",
          h4("Download Sample Data"),
          p("Use the sample dataset to try the tool before uploading your own data."),
          downloadButton("download_sample", "Download Sample Data (.zip)",
                         class = "btn-download")
        )
      ))
    ),

    # ── Tab 2: Upload & Analyse ──────────────────────────────────────────────
    tabPanel("Upload & Analyse", value = "upload",
      fluidRow(
        column(4,
          div(class = "upload-panel",
            h4("Upload Your Data"),
            fileInput("pheno_file", "Phenotype Data (.txt)",
                      accept = c(".txt", ".tsv", ".csv")),
            fileInput("sample_file", "Sample Sizes (.txt)",
                      accept = c(".txt", ".tsv", ".csv")),
            fileInput("commercial_file", "Commercial Names (.csv)",
                      accept = ".csv"),
            fileInput("gradient_files", "Gradient Files (.rds) — optional",
                      accept = ".rds", multiple = TRUE),
            actionButton("run_btn", "Run Analysis",
                         class = "btn-run", icon = icon("play")),
            tags$hr(),
            actionButton("sample_btn", "Try with Sample Data",
                         class = "btn-sample", icon = icon("flask"))
          )
        ),
        column(8,
          div(class = "status-box",
            h4("Analysis Status"),
            uiOutput("pipeline_status")
          )
        )
      )
    ),

    # ── Tab 3: Results ───────────────────────────────────────────────────────
    tabPanel("Results", value = "results",
      fluidRow(
        column(3,
          div(class = "results-sidebar",
            h4("Select Farmer"),
            selectInput("farmer_select", NULL, choices = NULL,
                        width = "100%"),
            downloadButton("download_report", "Download This Report",
                           class = "btn-download"),
            tags$hr(),
            downloadButton("download_all", "Download All Reports (.zip)",
                           class = "btn-download",
                           style = "background:#555;")
          )
        ),
        column(9,
          uiOutput("report_display")
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  rv <- reactiveValues(
    status       = list(),
    farmers      = NULL,
    report_dir   = NULL,
    report_id    = NULL,
    config       = NULL
  )

  # ── helpers ────────────────────────────────────────────────────────────────

  add_status <- function(msg, type = "ok") {
    rv$status <- c(rv$status, list(list(msg = msg, type = type)))
  }

  run_pipeline <- function(data_dir) {
    rv$status <- list()

    session_dir <- file.path(tempdir(), paste0("session_", as.integer(Sys.time())))
    img_dir     <- file.path(session_dir, "img")
    report_dir  <- file.path(session_dir, "reports")
    dir.create(session_dir, recursive = TRUE)
    dir.create(img_dir, recursive = TRUE)
    dir.create(report_dir, recursive = TRUE)

    config <- get_config(data_dir = data_dir, img_dir = img_dir,
                         report_dir = report_dir)
    rv$config <- config

    # Step 1: Merge
    add_status("Merging resistance and sample-size data...", "wait")
    tryCatch({
      df <- merge_resistance_data(config)
      add_status(paste0("Data merged — ", nrow(df), " rows, ",
                        length(unique(df$Farmer_Agronomist)), " farmers"), "ok")
    }, error = function(e) {
      add_status(paste("Merge failed:", e$message), "fail")
      return(NULL)
    })

    # Step 2: Images
    add_status("Generating histograms and gradient maps...", "wait")
    tryCatch({
      generate_all_images(config)
      add_status("All visualisation PNGs generated", "ok")
    }, error = function(e) {
      add_status(paste("Image generation failed:", e$message), "fail")
      return(NULL)
    })

    # Step 3: Reports
    add_status("Rendering per-farmer HTML reports...", "wait")
    tryCatch({
      farmers <- generate_all_reports(config, progress_fn = function(f) {
        add_status(paste0("  Report ready: ", f), "ok")
      })
      add_status(paste0("All ", length(farmers), " reports generated"), "ok")
    }, error = function(e) {
      add_status(paste("Report generation failed:", e$message), "fail")
      return(NULL)
    })

    # Serve reports
    report_id <- paste0("rpt_", as.integer(Sys.time()))
    addResourcePath(report_id, report_dir)
    rv$report_id  <- report_id
    rv$report_dir <- report_dir

    # Populate farmer dropdown
    df <- load_combined_data(config)
    farmers <- unique(df$Farmer_Agronomist)
    farmers <- farmers[farmers != "None"]
    rv$farmers <- farmers
    updateSelectInput(session, "farmer_select", choices = farmers)

    add_status("Pipeline complete — switch to the Results tab!", "ok")
    updateNavbarPage(session, "main_nav", selected = "results")
  }

  # ── Run with uploaded data ─────────────────────────────────────────────────

  observeEvent(input$run_btn, {
    req(input$pheno_file, input$sample_file, input$commercial_file)

    upload_dir <- file.path(tempdir(), paste0("upload_", as.integer(Sys.time())))
    dir.create(upload_dir, recursive = TRUE)

    file.copy(input$pheno_file$datapath,
              file.path(upload_dir, "POP_PHENO_DATA.txt"))
    file.copy(input$sample_file$datapath,
              file.path(upload_dir, "SAMPLE_SIZES.txt"))
    file.copy(input$commercial_file$datapath,
              file.path(upload_dir, "Commercial name of herbicides.csv"))

    # Gradient files: use uploaded if provided, else fall back to sample data
    if (!is.null(input$gradient_files)) {
      for (i in seq_len(nrow(input$gradient_files))) {
        file.copy(input$gradient_files$datapath[i],
                  file.path(upload_dir, input$gradient_files$name[i]))
      }
    } else {
      grad_files <- list.files(SAMPLE_DIR, pattern = "^landscape_.*\\.rds$",
                               full.names = TRUE)
      file.copy(grad_files, upload_dir)
    }

    run_pipeline(upload_dir)
  })

  # ── Run with sample data ───────────────────────────────────────────────────

  observeEvent(input$sample_btn, {
    sample_copy <- file.path(tempdir(), paste0("sample_", as.integer(Sys.time())))
    dir.create(sample_copy, recursive = TRUE)
    file.copy(list.files(SAMPLE_DIR, full.names = TRUE), sample_copy)
    run_pipeline(sample_copy)
  })

  # ── Pipeline status display ────────────────────────────────────────────────

  output$pipeline_status <- renderUI({
    if (length(rv$status) == 0) {
      div(class = "placeholder-msg",
          p("Upload your data files and click ", tags$b("Run Analysis"), ","),
          p("or click ", tags$b("Try with Sample Data"), " for a demo."))
    } else {
      tags$div(
        lapply(rv$status, function(s) {
          icon_class <- switch(s$type,
            ok   = "ok",
            fail = "fail",
            wait = "wait"
          )
          prefix <- switch(s$type,
            ok   = "\u2714 ",
            fail = "\u2718 ",
            wait = "\u23f3 "
          )
          div(class = "status-item",
              span(class = icon_class, prefix), s$msg)
        })
      )
    }
  })

  # ── Results display ────────────────────────────────────────────────────────

  output$report_display <- renderUI({
    if (is.null(rv$report_id) || is.null(input$farmer_select) ||
        input$farmer_select == "") {
      div(class = "placeholder-msg",
        p("Run the analysis first, then select a farmer to view their report.")
      )
    } else {
      report_file <- paste0(sanitize_name(input$farmer_select), ".html")
      report_url  <- paste0(rv$report_id, "/", URLencode(report_file, reserved = TRUE))
      tags$iframe(
        src    = report_url,
        width  = "100%",
        height = "850px",
        class  = "report-frame"
      )
    }
  })

  # ── Downloads ──────────────────────────────────────────────────────────────

  output$download_sample <- downloadHandler(
    filename = function() "sample_data.zip",
    content  = function(file) {
      owd <- setwd(SAMPLE_DIR)
      on.exit(setwd(owd))
      utils::zip(file, list.files("."))
    },
    contentType = "application/zip"
  )

  output$download_report <- downloadHandler(
    filename = function() paste0(sanitize_name(input$farmer_select), ".html"),
    content  = function(file) {
      req(rv$report_dir, input$farmer_select)
      src <- file.path(rv$report_dir,
                       paste0(sanitize_name(input$farmer_select), ".html"))
      if (file.exists(src)) file.copy(src, file)
    },
    contentType = "text/html"
  )

  output$download_all <- downloadHandler(
    filename = function() "all_reports.zip",
    content  = function(file) {
      req(rv$report_dir)
      owd <- setwd(rv$report_dir)
      on.exit(setwd(owd))
      utils::zip(file, list.files(".", pattern = "\\.html$"))
    },
    contentType = "application/zip"
  )
}

shinyApp(ui, server)
