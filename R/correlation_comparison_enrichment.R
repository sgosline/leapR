#' correlation_comparison_enrichment
#'
#' correlation_comparison_enrichment function description is...
#'
#' @param geneset is...
#' @param abundance is...
#' @param set1 is...
#' @param set2 is...
#' @param mapping_column default is an NA
#' @param tag default is an NA
#' @param mode default is 'original'
#'
#' @examples
#' dontrun{
#'
#'
#' }
#'
#' @export
#'

correlation_comparison_enrichment <- function(geneset, abundance, set1, set2, mapping_column=NA, tag=NA, mode="original") {
  allgenes = unique(unlist(as.list(geneset$matrix)))

  if (!is.na(tag)) allgenes = sapply(allgenes, function (n) paste(tag, n, sep="_"))

  # fixme: add support for an id column
  ids = rownames(abundance)
  cols = 1:ncol(abundance)
  map = NA
  if (!is.na(mapping_column)) {
    allgenes = rownames(abundance)[which(abundance[,1] %in% allgenes)]

    # NOTE: assumes that the mapping column is 1 and everything else
    #       is valid data- which may not be the case
    cols = 2:ncol(abundance)
    map = abundance
  }
  cols1 = colnames(abundance)[which(colnames(abundance) %in% set1)]
  cols2 = colnames(abundance)[which(colnames(abundance) %in% set2)]

  allgenes_present = allgenes[which(allgenes %in% ids)]
  allgenes_cor1 = cor(t(abundance[allgenes_present,cols1]), use="p")
  allgenes_cor2 = cor(t(abundance[allgenes_present,cols2]), use="p")

  return(enrichment=difference_enrichment_in_relationships(geneset, allgenes_cor1, allgenes_cor2, idmap=map, tag=tag, mode=mode))
}