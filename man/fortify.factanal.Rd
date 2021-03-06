% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/fortify_stats.R
\name{fortify.factanal}
\alias{fortify.factanal}
\title{Convert \code{stats::factanal} to data.frame.}
\usage{
\method{fortify}{factanal}(data, original = NULL)
}
\arguments{
\item{data}{\code{stats::factanal} instance}

\item{original}{Joined to Factanal result if provided.}
}
\value{
data.frame
}
\description{
Convert \code{stats::factanal} to data.frame.
}
\examples{
d.factanal <- stats::factanal(state.x77, factors = 3, scores = 'regression')
ggplot2::fortify(d.factanal)
ggplot2::fortify(d.factanal, original = state.x77)
}

