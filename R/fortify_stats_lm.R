#' Autoplot \code{stats::lm}.
#' 
#' @param data \code{stats::lm} instance
#' @param which If a subset of the plots is required, specify a subset of the numbers 1:6.
#' @param fill Point fill colour
#' @param colour Point line colour
#' @param label.n Number of points to be laeled in each plot, starting with the most extreme
#' @param label.colour Text colour for point labels
#' @param label.size Text size for point labels
#' @param smooth.colour Line colour for smoother lines
#' @param smooth.linetype Line type for smoother lines
#' @param ad.colour Line colour for additional lines
#' @param ad.linetype Line type for additional lines
#' @param ad.size Fill colour for additional lines
#' @param nrow Number of facet/subplot rows
#' @param ncol Number of facet/subplot columns 
#' @return ggplot
#' @examples
#' ggplot2::autoplot(lm(Petal.Width ~ Petal.Length, data= iris))
#' ggplot2::autoplot(glm(Petal.Width ~ Petal.Length, data= iris), which = 1:6)
#' 
#' ggplot2::autoplot(lm(Petal.Width~Petal.Length, data = iris)) + ggplot2::theme_bw()
#' ggplot2::autoplot(lm(Petal.Width~Petal.Length, data = iris)) + ggplot2::scale_colour_brewer()
#' @export
autoplot.lm <- function(data, which=c(1:3, 5),
                        fill = '#444444', colour = '#444444',
                        label.colour = '#000000', label.size = 4,  
                        label.n = 3,
                        smooth.colour = '#0000FF', smooth.linetype = 'solid',
                        ad.colour = '#888888', ad.linetype = 'dashed', ad.size = .2, 
                        nrow = NULL, ncol = NULL) {
  library(ggplot2)

  # initialization
  p1 <- p2 <- p3 <- p4 <- p5 <- p6 <- NULL
  
  dropInf <- function(x, h) {
    if (any(isInf <- h >= 1)) {
      warning(gettextf("not plotting observations with leverage one:\n  %s", 
                       paste(which(isInf), collapse = ", ")), call. = FALSE, 
              domain = NA)
      x[isInf] <- NaN
    }
    x
  }
  
  show <- rep(FALSE, 6)
  show[which] <- TRUE
  
  plot.data <- ggplot2::fortify(data)
  n <- nrow(plot.data)
  
  plot.data$.index <- 1:n
  if (show[2L]) {
    ylim <- range(plot.data$.stdresid, na.rm = TRUE)
    ylim[2L] <- ylim[2L] + diff(ylim) * 0.075
    qn <- stats::qqnorm(plot.data$.stdresid, ylim = ylim, plot.it = FALSE)
    plot.data$.qqx <- qn$x
    plot.data$.qqy <- qn$y
  }

  is_glm <- inherits(data, "glm")
  s <- if (inherits(data, "rlm")) {
    data$s
  } else if (is_glm) {
    sqrt(summary(data)$dispersion) 
  } else {
    sqrt(deviance(data)/stats::df.residual(data))
  }
  label.fitted <- ifelse(is_glm, 'Predicted values', 'Fitted values')
  label.y23 <- ifelse(is_glm, 'Std. deviance resid.', 'Standardized residuals')
  hii <- lm.influence(data, do.coef = FALSE)$hat
  
  if (is.null(label.n)) 
    label.n <- 0
  else {
    label.n <- as.integer(label.n)
    if (label.n < 0L || label.n > n) 
      stop(gettextf("'label.n' must be in {1,..,%d}", n), 
           domain = NA)
  }
  if (label.n > 0L) {
    r.data <- dplyr::arrange_(plot.data, 'dplyr::desc(abs(.resid))')
    r.data <- head(r.data, label.n)
    cd.data <- dplyr::arrange_(plot.data, 'dplyr::desc(abs(.cooksd))')
    cd.data <- head(cd.data, label.n)
  }
  
  .smooth <- function(x, y) {
    stats::lowess(x, y, f = 2/3, iter = 3)
  }
  
  .decorate.label <- function(p, d) {
    if (label.n > 0) {
      mapping = ggplot2::aes_string(label = '.index')
      p <- p + ggplot2::geom_text(data = d, mapping = mapping,
                                  colour = label.colour, size = label.size)
    }
    p
  }
  
  .decorate.plot <- function(p, xlab = NULL, ylab = NULL, title = NULL) {
    p + 
      ggplot2::xlab(xlab) +
      ggplot2::ylab(ylab) +
      ggplot2::ggtitle(title)
  }
  
  if (show[1L]) {
    t1 <- 'Residuals vs Fitted'
    mapping <- ggplot2::aes_string(x = '.fitted', y = '.resid')
    smoother <- .smooth(plot.data$.fitted, plot.data$.resid)
    p1 <- ggplot2::ggplot(plot.data, mapping = mapping) +
      ggplot2::geom_point(fill = fill, colour = colour)  + 
      # geom_smooth and stat_smooth result in different from standard plot
      ggplot2::geom_line(x = smoother$x, y = smoother$y,
                         colour = smooth.colour, linetype = smooth.linetype) +
      ggplot2::geom_hline(linetype = ad.linetype, size = ad.size,
                          colour = ad.colour)
    p1 <- .decorate.label(p1, r.data)
    p1 <- .decorate.plot(p1, xlab = label.fitted, ylab = 'Residuals',
                       title = t1)
  }
  
  if (show[2L]) {
    t2 <- 'Normal Q-Q'
    qprobs <- c(0.25, 0.75)
    qy <- quantile(plot.data$.stdresid, probs = qprobs, names = FALSE,
                   type = 7, na.rm = TRUE)
    qx <- qnorm(qprobs)
    slope <- diff(qy) / diff(qx)
    int <- qy[1L] - slope * qx[1L]

    mapping <- ggplot2::aes_string(x = '.qqx', y = '.qqy')
    p2 <- ggplot2::ggplot(plot.data, mapping = mapping) +
      # Do not use stat_qq here for labeling
      ggplot2::geom_point(fill = fill, colour = colour)  + 
      ggplot2::geom_abline(intercept=int, slope=slope, 
                           linetype = ad.linetype, size = ad.size,
                           colour = ad.colour)
    p2 <- .decorate.label(p2, r.data)
    p2 <- .decorate.plot(p2, xlab = 'Theoretical Quantiles',
                         ylab = label.y23, title = t2)
  }
  
  if (show[3L]) {
    t3 <- 'Scale-Location'
    mapping <- ggplot2::aes_string(x = '.fitted', y = 'sqrt(abs(.stdresid))')
    smoother <- .smooth(plot.data$.fitted, sqrt(abs(plot.data$.stdresid)))
    p3 <- ggplot2::ggplot(plot.data, mapping = mapping) +
      ggplot2::geom_point(fill = fill, colour = colour) +
      ggplot2::geom_line(x = smoother$x, y = smoother$y,
                         colour = smooth.colour, linetype = smooth.linetype)
    p3 <- .decorate.label(p3, r.data)
    label.y3 <- ifelse(is_glm, expression(sqrt(abs(`Std. deviance resid.`))), 
                       expression(sqrt(abs(`Standardized residuals`))))
    p3 <- .decorate.plot(p3, xlab = label.fitted, ylab = label.y3, 
                         title = t3)
  }
  
  if (show[4L]) {
    t4 <- "Cook's distance"
    mapping <- ggplot2::aes_string(x = '.index', y = '.cooksd',
                                   ymin = 0, ymax = '.cooksd')
    p4 <-  ggplot2::ggplot(plot.data, mapping = mapping) + 
      ggplot2::geom_linerange(colour = colour)
    p4 <- .decorate.label(p4, cd.data)
    p4 <- .decorate.plot(p4, xlab = 'Obs. Number',
                         ylab = "Cook's distance", title = t4)
  }
  
  if (show[5L]) {
    t5 <- 'Residuals vs Leverage'
    mapping <- ggplot2::aes_string(x = '.hat', y = '.stdresid')
    smoother <- .smooth(plot.data$.hat, plot.data$.stdresid)
    p5 <- ggplot2::ggplot(plot.data, mapping = mapping) +
      ggplot2::geom_point(fill = fill, colour = colour) +
      ggplot2::geom_line(x = smoother$x, y = smoother$y,
                         colour = smooth.colour, linetype = smooth.linetype) +
      ggplot2::geom_hline(linetype = ad.linetype, size = ad.size,
                          colour = ad.colour) +
      ggplot2::expand_limits(x = 0)
    p5 <- .decorate.label(p5, cd.data)
    label.y5 <- ifelse(is_glm, 'Std. Pearson resid.', 'Standardized Residuals')
    p5 <- .decorate.plot(p5, xlab = 'Leverage', ylab = label.y5, title = t5)
  }
  
  if (show[6L]) {
    t6 <- "Cook's dist vs Leverage"
    mapping <- ggplot2::aes_string(x = '.hat', y = '.cooksd')
    smoother <- .smooth(plot.data$.hat, plot.data$.cooksd)
    p6 <- ggplot2::ggplot(plot.data, mapping = mapping) +
      ggplot2::geom_point(fill = fill, colour = colour) +
      ggplot2::geom_line(x = smoother$x, y = smoother$y,
                         colour = smooth.colour, linetype = smooth.linetype) +
      ggplot2::expand_limits(x = 0, y = 0)
    p6 <- .decorate.label(p6, cd.data)
    p6 <- .decorate.plot(p6, xlab = 'Leverage', ylab = "Cook's distance",
                         title = t6)
  
    g <- dropInf(hii/(1 - hii), hii)
    p <- length(coef(data))
    bval <- pretty(sqrt(p * plot.data$.cooksd / g), 5)
    for (i in seq_along(bval)) {
      bi2 <- bval[i]^2
      p6 <- p6 + ggplot2::geom_abline(intercept=0, slope=bi2,
                                      linetype = ad.linetype, size = ad.size,
                                      colour = ad.colour)
    }
  }
  
  if (is.null(ncol)) { ncol <- 0 }
  if (is.null(nrow)) { nrow <- 0 }
  
  plot.list <- list(p1, p2, p3, p4, p5, p6)[which]
  new('ggmultiplot', plots = plot.list, nrow = nrow, ncol = ncol)
} 

#' @export
autoplot.glm <- autoplot.lm