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
  png(filename = file.path(farmer_dir, paste0("hist_", herbicide, ".png")),
      width = 580, height = 480)

  if (length(sub_resistance) == 0) {
    par(xpd = TRUE)
    plot(x = 0:1, y = 0:1, type = "n", xlab = herbicide, ylab = "")
    text(x = 0.5, y = 0.5, lab = "NO DATA")
  } else {
    h    <- hist(resistance, plot = FALSE)
    ymax <- max(h$counts) + 4

    par(xpd = TRUE, mar = c(5, 4.5, 3, 1))
    hist(resistance * 100, col = rgb(0.5, 0.5, 0.5, alpha = 0.6),
         labels = FALSE, freq = TRUE, breaks = 10, bord = FALSE,
         main = paste0("Histogram of ", herbicide, " resistance"),
         col.main = colour,
         xlim = c(-5, 108), xlab = paste0(herbicide, " Resistance (%)"),
         ylim = c(0, ymax), ylab = "Number of Farms")

    par(xpd = FALSE); grid()
    par(xpd = TRUE)

    n <- length(sub_resistance)
    x <- sub_resistance * 100

    # Stagger y-positions with generous spacing above histogram bars
    y_ceiling <- ymax - 0.8
    y_floor   <- max(h$counts) + 1.0
    if (n == 1) {
      y <- (y_ceiling + y_floor) / 2
    } else {
      y <- seq(from = y_ceiling, to = y_floor, length.out = n)
    }

    # Compute labels and smart text positioning
    labels   <- character(n)
    text_pos <- integer(n)
    for (j in seq_len(n)) {
      v_pct     <- compute_percentile(sub_resistance[j], resistance)
      labels[j] <- paste0(j, ": ", format_percentile(v_pct))
      text_pos[j] <- 3
    }

    # For closely-spaced x-values, alternate label direction to avoid collision
    for (j in seq_len(n)) {
      if (j > 1 && abs(x[j] - x[j - 1]) < 20) {
        text_pos[j] <- if (j %% 2 == 0) 4 else 2
      }
      if (x[j] > 90) text_pos[j] <- 2
      if (x[j] < 10) text_pos[j] <- 4
    }

    for (j in seq_len(n)) {
      lines(x = c(x[j], x[j]), y = c(0, y[j]), lwd = 2, col = colour)
      points(x = x[j], y = y[j], bg = colour, pch = 25)
      text(x = x[j], y = y[j], lab = labels[j],
           pos = text_pos[j], cex = 0.85, offset = 0.5)
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
      width = 520, height = 480, units = "px", pointsize = 12)

  # Heatmap
  par(fig = c(0, 0.88, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE)
  image(x = predx, y = predy, z = Z,
        col = color_gradient[round(min(Z) * ncolors):round(max(Z) * ncolors)],
        xlab = "Longitude", ylab = "Latitude", asp = 1,
        xaxt = "n", yaxt = "n", frame.plot = FALSE)

  # Title overlay
  par(fig = c(0, 0.88, 0, 0.9), mar = c(5, 5, 1, 2), xpd = FALSE, new = TRUE)
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
  par(fig = c(0, 0.88, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE)
  polypath(c(outline$x, NA, c(xbox, rev(xbox))),
           c(outline$y, NA, rep(ybox, each = 2)),
           col = "light blue", rule = "evenodd")

  # Axis ticks with degree symbols
  par(fig = c(0, 0.88, 0, 0.85), mar = c(5, 5, 0, 2), xpd = FALSE, new = TRUE)
  axis(side = 1, at = xaxis, labels = paste0(xaxis, "\U00B0"))
  axis(side = 2, at = yaxis, labels = paste0(yaxis, "\U00B0"), las = 2)

  par(fig = c(0, 0.88, 0, 0.85), mar = c(5, 5, 2, 2), xpd = FALSE, new = TRUE)
  grid(col = "darkgray")

  # Farm location points
  survi_col   <- paste0(herbicide, "_SURVI")
  sub_df_herb <- sub_df[order(sub_df[[survi_col]], decreasing = FALSE, na.last = NA), ]

  par(fig = c(0, 0.88, 0, 1), mar = c(5, 5, 0, 2), xpd = FALSE, new = TRUE)
  plot(0, xlim = dx, ylim = dy, asp = 1, type = "n", bty = "n",
       xlab = "", ylab = "", main = "", xaxt = "n", yaxt = "n", frame.plot = FALSE)

  if (nrow(sub_df_herb) != 0) {
    n_farms <- nrow(sub_df_herb)

    # Collect farm coordinates (fill NA with median)
    farm_x <- sub_df_herb$Coordinates_E
    farm_y <- sub_df_herb$Coordinates_N
    valid_x <- farm_x[!is.na(farm_x)]
    median_x <- if (length(valid_x) > 0) median(valid_x) else mean(dx)
    median_y <- if (length(valid_x) > 0) median(farm_y[!is.na(farm_y)]) else mean(dy)
    farm_x[is.na(farm_x)] <- median_x
    farm_y[is.na(farm_y)] <- median_y

    # Draw farm points
    for (j in seq_len(n_farms)) {
      r <- sub_df_herb[[herbicide]][j]
      points(farm_x[j], farm_y[j], col = "black",
             bg = color_gradient[round(r * ncolors) + 1], pch = 19)
    }

    # Compute label positions: radial placement from cluster centroid
    centroid_x <- mean(farm_x)
    centroid_y <- mean(farm_y)
    label_dist <- 2.5
    angles <- seq(from = 3 * pi / 4, to = -pi / 4, length.out = max(n_farms, 2))[seq_len(n_farms)]

    for (j in seq_len(n_farms)) {
      lx <- centroid_x + label_dist * cos(angles[j])
      ly <- centroid_y + label_dist * sin(angles[j])

      # Clamp to plot bounds with margin
      lx <- max(dx[1] + 0.5, min(dx[2] - 0.5, lx))
      ly <- max(dy[1] + 0.5, min(dy[2] - 0.5, ly))

      arrows(x0 = farm_x[j], y0 = farm_y[j], x1 = lx, y1 = ly,
             length = 0.12, col = "black")
      text(lx, ly, lab = j, pos = 3, cex = 0.9, font = 2)
    }
  }

  # Legend
  legend_x <- seq(0, 1, length = length(color_gradient))
  legend_y <- seq(0, 100, length = length(color_gradient))
  legend_z <- matrix(rep(legend_x, length(color_gradient)),
                     byrow = TRUE, nrow = length(color_gradient))

  par(fig = c(0.86, 0.91, 0.148, 0.775), mar = rep(0, 4), xpd = FALSE, new = TRUE)
  image(x = legend_x, y = legend_y, z = legend_z,
        col = color_gradient, xlab = "", ylab = "", main = "", axes = FALSE)

  par(fig = c(0.86, 0.91, 0.148, 0.775), mar = rep(0, 4), xpd = FALSE, new = TRUE)
  axis(4, at = seq(0, 100, by = 20), lty = 1, las = 2, cex.axis = 0.8)
  mtext("Completely\nResistant",   side = 3, line = 0.5, at = 0.5, cex = 0.8)
  mtext("Completely\nSusceptible", side = 1, line = 1.5, at = 0.5, cex = 0.8)

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
