% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/plotlib.R
\name{plot.conf.int}
\alias{plot.conf.int}
\title{Attach confidence interval to \code{ggplot2::ggplot}}
\usage{
\method{plot}{conf.int}(p, data = NULL, lower = "lower", upper = "upper",
  conf.int = TRUE, conf.int.colour = "#0000FF",
  conf.int.linetype = "none", conf.int.fill = "#000000",
  conf.int.alpha = 0.3)
}
\arguments{
\item{p}{\code{ggplot2::ggplot} instance}

\item{data}{Data contains lower and upper confidence intervals}

\item{lower}{Column name for lower confidence interval}

\item{upper}{Column name for upper confidence interval}

\item{conf.int}{Logical flag indicating whether to plot confidence intervals}

\item{conf.int.colour}{Line colour for confidence intervals}

\item{conf.int.linetype}{Line type for confidence intervals}

\item{conf.int.fill}{Fill colour for confidence intervals}

\item{conf.int.alpha}{Alpha for confidence intervals}
}
\value{
ggplot
}
\description{
Attach confidence interval to \code{ggplot2::ggplot}
}
\examples{
d <- ggplot2::fortify(stats::acf(AirPassengers, plot = FALSE))
p <- ggplot2::ggplot(data = d, mapping = ggplot2::aes(x = Lag))
ggfortify:::plot.conf.int(p)
}

