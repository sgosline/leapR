% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enrichment_in_groups.R
\name{enrichment_in_groups}
\alias{enrichment_in_groups}
\title{enrichment_in_groups}
\usage{
enrichment_in_groups(
  geneset,
  targets = NULL,
  background = NULL,
  method = "fishers",
  minsize = 5,
  mapping_column = NULL,
  abundance_column = NULL,
  randomize = F
)
}
\description{
Calculate the enrichment in pathways using Fisher's exact or Kolgmorov-Smirnov test
# access through leapr wrapper
}
