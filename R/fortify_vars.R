#' Convert \code{vars::varprd} to data.frame.
#' 
#' @param data \code{vars::varprd} instance
#' @param is.date Logical frag indicates whether the \code{stats::ts} is date or not.
#' If not provided, regard the input as date when the frequency is 4 or 12. 
#' @param ts.connect Logical frag indicates whether connects original time-series and predicted values
#' @param melt Logical flag indicating whether to melt each timeseries as variable
#' @return data.frame
#' @examples
#' data(Canada, package = 'vars')
#' d.vselect <- vars::VARselect(Canada, lag.max = 5, type = 'const')$selection[1]
#' d.var <- vars::VAR(Canada, p = d.vselect, type = 'const')
#' ggplot2::fortify(stats::predict(d.var, n.ahead = 50))
#' @export
fortify.varprd <- function(data, is.date = NULL, ts.connect = FALSE, melt = FALSE){  
  fitted <- ggplot2::fortify(data$model$y)

  fcst <- data$fcst
  dtindex.cont <- get.dtindex.continuous(data$model$y, length = nrow(fcst[[1]]),
                                         is.date = is.date)
  cols <- names(fcst)
  
  if (melt) {
    # for autoplot conversion
    for (col in cols){
      pred <- data.frame(fcst[[col]])
      pred$Index <- dtindex.cont
      obs <- fitted[, c('Index', col)]
      colnames(obs) <- c('Index', 'Data')
      binded <- ggfortify::rbind_ts(pred, obs, ts.connect = ts.connect)  
      binded$variable <- col
      fcst[[col]] <- binded
    }
    return(dplyr::rbind_all(fcst))
  } else {
    for (col in cols){
      colnames(fcst[[col]]) <- paste0(col, '.', colnames(fcst[[col]]))
    }
    pred <- data.frame(do.call(cbind, fcst))
    pred$Index <- dtindex.cont
    binded <- ggfortify::rbind_ts(pred, fitted, ts.connect = ts.connect)
    return(binded)
  }
}

#' Autoplot \code{vars::varprd}.
#' 
#' @param data \code{vars::varpred} instance
#' @param is.date Logical frag indicates whether the \code{stats::ts} is date or not.
#' If not provided, regard the input as date when the frequency is 4 or 12. 
#' @param ts.connect Logical frag indicates whether connects original time-series and predicted values
#' @param scales Scale value passed to \code{ggplot2}
#' @param predict.colour Line colour for predicted time-series
#' @param predict.linetype Line type for predicted time-series
#' @param conf.int Logical flag indicating whether to plot confidence intervals
#' @param conf.int.colour Line colour for confidence intervals
#' @param conf.int.linetype Line type for confidence intervals
#' @param conf.int.fill Fill colour for confidence intervals
#' @param conf.int.alpha Alpha for confidence intervals
#' @param ... Keywords passed to autoplot.ts
#' @return ggplot
#' @examples
#' data(Canada, package = 'vars')
#' d.vselect <- vars::VARselect(Canada, lag.max = 5, type = 'const')$selection[1]
#' d.var <- vars::VAR(Canada, p = d.vselect, type = 'const')
#' ggplot2::autoplot(stats::predict(d.var, n.ahead = 50), is.date = TRUE)
#' ggplot2::autoplot(stats::predict(d.var, n.ahead = 50), conf.int = FALSE)
#' @export
autoplot.varprd <- function(data, is.date = NULL, ts.connect = TRUE,
                            scales = 'free_y',
                            predict.colour = '#0000FF', predict.linetype = 'solid',
                            conf.int = TRUE,
                            conf.int.colour = '#0000FF', conf.int.linetype = 'none',
                            conf.int.fill = '#000000', conf.int.alpha = 0.3,
                            ...) {
  plot.data <- ggplot2::fortify(data, is.date = is.date,
                                ts.connect = ts.connect, melt = TRUE)
  
  # Filter existing values to avoid warnings
  original.data <- dplyr::filter(plot.data, !is.na(Data))
  predict.data <- dplyr::filter(plot.data, !is.na(fcst))

  p <- autoplot.ts(original.data, columns = 'Data', ...)
  p <- autoplot.ts(predict.data, columns = 'fcst', p = p,
                   ts.colour = predict.colour,
                   ts.linetype = predict.linetype)

  p <- p + ggplot2::facet_grid(variable ~ ., scales = scales)
  
  p <- plot.conf.int(p, data = predict.data, conf.int = conf.int,
                     conf.int.colour = conf.int.colour,
                     conf.int.linetype = conf.int.linetype,
                     conf.int.fill = conf.int.fill,
                     conf.int.alpha = conf.int.alpha)
  p 
}