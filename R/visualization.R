#' Visualization layer: histogram and gradient-map PNG generation.
#'
#' All plotting logic is isolated here. Column access uses safe bracket
#' notation (df[[col]]) instead of eval(parse(...)).

generate_histogram <- function(df_all, sub_df, farmer, herbicide_idx, config) {
  herbicide <- config$herbicides[herbicide_idx]
  colour    <- config$colors[herbicide_idx]

  resistance <- df_all[[herbicide]]
  resistance <- resistance[!is.na(resistance)]

  sub_resistance <- sub_df[[herbicide]]
  sub_resistance <- sub_resistance[order(sub_resistance, decreasing = FALSE, na.last = NA)]

  safe_farmer <- sanitize_name(farmer)
  farmer_dir  <- file.path(config$img_dir, safe_farmer)
  ensure_dir(farmer_dir)
  png(filename = file.path(farmer_dir, paste0("hist_", herbicide, ".png")))

  if (length(sub_resistance) == 0) {
    par(xpd = TRUE)
    plot(x = 0:1, y = 0:1, type = "n", xlab = herbicide, ylab = "")
    text(x = 0.5, y = 0.5, lab = "NO DATA")
  } else {
    par(xpd = TRUE)
    h    <- hist(resistance, plot = FALSE)
    ymax <- max(h$counts) + 2

    hist(resistance * 100, col = rgb(0.5, 0.5, 0.5, alpha = 0.6),
         labels = FALSE, freq = TRUE, breaks = 10, bord = FALSE,
         main = paste0("\n\n\n Histogram of ", herbicide, "  resistance"),
         col.main = colour,
         xlim = c(-2, 102), xlab = paste0(herbicide, " Resistance (%)"),
         ylim = c(0, ymax), ylab = "Number of Farms")

    par(xpd = FALSE); grid()

    x <- sub_resistance * 100
    y <- rev(seq(from = 1, to = max(h$counts) - 1, length = 10))[seq_along(sub_resistance)]

    for (j in seq_along(sub_resistance)) {
      lines(x = c(x[j], x[j]), y = c(0, y[j]), lwd = 2, col = colour)
      points(x = x[j], y = y[j], bg = colour, pch = 25)
      v_pct <- compute_percentile(sub_resistance[j], resistance)
      text(x = x[j], y = y[j], lab = paste0(j, ": ", format_percentile(v_pct)), pos = 3)
    }
  }
  dev.off()
}

generate_map <- function(df_all, sub_df, farmer, herbicide_idx, config) {
  herbicide <- config$herbicides[herbicide_idx]
  colour    <- config$colors[herbicide_idx]

  landscape <- load_landscape_gradient(config, herbicide)
  predx <- landscape$predx
  predy <- landscape$predy
  Z     <- landscape$Z

  dx    <- c(min(predx), max(predx))
  dy    <- c(min(predy), max(predy))
  xaxis <- seq(round(min(predx)), round(max(predx)), 2)
  yaxis <- seq(round(min(predy)) - 2, round(max(predy)) + 2, 2)

  ncolors        <- 25
  color_gradient <- rev(colorRampPalette(
    c("#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE08B",
      "#FFFFBF", "#D9EF8B", "#A6D96A", "#66BD63", "#1A9850", "#006837")
  )(ncolors))

  safe_farmer <- sanitize_name(farmer)
  farmer_dir  <- file.path(config$img_dir, safe_farmer)
  ensure_dir(farmer_dir)
  png(filename = file.path(farmer_dir, paste0("map_", herbicide, ".png")),
      width = 480, height = 480, units = "px", pointsize = 12)

  # Heatmap
  par(fig = c(0, 0.9, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE)
  image(x = predx, y = predy, z = Z,
        col = color_gradient[round(min(Z) * ncolors):round(max(Z) * ncolors)],
        xlab = "Longitude", ylab = "Latitdue", asp = 1,
        xaxt = "n", yaxt = "n", frame.plot = FALSE)

  # Title overlay
  par(fig = c(0, 0.9, 0, 0.9), mar = c(5, 5, 1, 2), xpd = FALSE, new = TRUE)
  plot(0, xlim = dx, ylim = dy, asp = 1, type = "n", bty = "n",
       xlab = "", ylab = "",
       main = paste0(herbicide, " Resistance Gradient"),
       col.main = colour, cex.main = 1.2,
       xaxt = "n", yaxt = "n", frame.plot = FALSE)

  # Map outline with ocean fill
  outline <- maps::map("world", plot = FALSE)
  xrange <- range(outline$x, na.rm = TRUE)
  yrange <- range(outline$y, na.rm = TRUE)
  xbox   <- xrange + c(-2, 2)
  ybox   <- yrange + c(-2, 2)
  par(fig = c(0, 0.9, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE)
  polypath(c(outline$x, NA, c(xbox, rev(xbox))),
           c(outline$y, NA, rep(ybox, each = 2)),
           col = "light blue", rule = "evenodd")

  # Axis ticks with degree symbols
  par(fig = c(0, 0.9, 0, 0.85), mar = c(5, 5, 0, 2), xpd = FALSE, new = TRUE)
  axis(side = 1, at = xaxis, labels = paste0(xaxis, "\U00B0"))
  axis(side = 2, at = yaxis, labels = paste0(yaxis, "\U00B0"), las = 2)

  par(fig = c(0, 0.9, 0, 0.85), mar = c(5, 5, 2, 2), xpd = FALSE, new = TRUE)
  grid(col = "darkgray")

  # Farm location points
  survi_col   <- paste0(herbicide, "_SURVI")
  sub_df_herb <- sub_df[order(sub_df[[survi_col]], decreasing = FALSE, na.last = NA), ]

  par(fig = c(0, 0.9, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE, new = TRUE)
  plot(0, xlim = dx, ylim = dy, asp = 1, type = "n", bty = "n",
       xlab = "", ylab = "", main = "", xaxt = "n", yaxt = "n", frame.plot = FALSE)

  if (nrow(sub_df_herb) != 0) {
    coords_e <- sub_df_herb$Coordinates_E
    coords_e <- coords_e[!is.na(coords_e)]
    median_e <- median(coords_e)

    for (j in seq_len(nrow(sub_df_herb))) {
      x <- sub_df_herb$Coordinates_E[j]
      if (is.na(x)) x <- median_e
      y <- sub_df_herb$Coordinates_N[j]
      if (is.na(y)) y <- median_e

      r <- sub_df_herb[[herbicide]][j]
      points(x, y, col = "black", bg = color_gradient[round(r * ncolors) + 1], pch = 19)

      x1 <- x - (j * 0.75)
      y1 <- y - (median(seq_len(nrow(sub_df_herb))) - (j * 0.75))
      arrows(x0 = x, y0 = y, x1 = x1, y1 = y1, length = 0.15, col = "black")
      text(x1, y1, lab = j, pos = 3)
    }
  }

  # Legend
  legend_x <- seq(0, 1, length = length(color_gradient))
  legend_y <- seq(0, 100, length = length(color_gradient))
  legend_z <- matrix(rep(legend_x, length(color_gradient)),
                     byrow = TRUE, nrow = length(color_gradient))

  par(fig = c(0.88, 0.93, 0.148, 0.775), mar = rep(0, 4), xpd = FALSE, new = TRUE)
  image(x = legend_x, y = legend_y, z = legend_z,
        col = color_gradient, xlab = "", ylab = "", main = "", axes = FALSE)

  par(fig = c(0.88, 0.93, 0.148, 0.775), mar = rep(0, 4), xpd = FALSE, new = TRUE)
  axis(4, at = seq(0, 100, by = 20), lty = 1, las = 2, cex.axis = 0.8)
  mtext("Completely\nResistant",   side = 3, line = 0.5, at = 0.5, cex = 0.9)
  mtext("Completely\nSusceptible", side = 1, line = 1.5, at = 0.5, cex = 0.9)

  dev.off()
}

generate_farmer_images <- function(df_all, farmer, config) {
  sub_df <- df_all[df_all$Farmer_Agronomist == farmer, ]
  for (i in seq_along(config$herbicides)) {
    generate_histogram(df_all, sub_df, farmer, i, config)
    generate_map(df_all, sub_df, farmer, i, config)
  }
}

generate_all_images <- function(config) {
  df_all   <- load_pheno_data(config)
  farmers  <- unique(df_all$Farmer_Agronomist)

  for (farmer in farmers) {
    if (farmer == "None") next
    message("Generating images for: ", farmer)
    generate_farmer_images(df_all, farmer, config)
  }
  message("All images generated in: ", config$img_dir)
}
