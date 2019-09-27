#' enrichment_in_abundance
#'
#' enrichment_in_abundance function description is...
#'
#' @param geneset is...
#' @param abundance is...
#' @param mapping_column defaults to NULL
#' @param abundance_column defaults to NULL
#' @param fdr defaults to 0
#' @param matchset defaults to NULL
#' @param longform is a logical. Defaults to FALSE
#' @param sample_comparison defaults to NULL
#' @param background_comparison defaults to NULL
#' @param min_p_threshold defaults to NULL
#' @param tag defaults to an NA
#' @param sample_n defaults to NULL
#'
#' @examples
#' dontrun{
#'         data("shortlist")
#'         data("longlist")
#'
#'         #in this example we lump a bunch of patients together (the 'short survivors') and compare them to another group (the 'long survivors')
#'         protdata.enrichment.svl = enrichment_in_abundance(ncipid, protdata, abundance_column=shortlist, sample_comparison=longlist)
#'
#'         #I generally output these files and then view them in Excel afterward
#'         write.table(protdata.enrichment.svl, file="protdata.enrichment.svl.txt", sep="\t", quote=F)
#'
#'         #another application is to compare just one patient against another (this would be the equivalent of comparing one time point to another)
#'         protdata.enrichment.svl.ovo = enrichment_in_abundance(ncipid, protdata, abundance_column=shortlist[1], sample_comparison=longlist[1])
#'
#' }
#'
#' @export
#'

enrichment_in_abundance <- function(geneset, abundance, mapping_column=NULL, abundance_column=NULL,
                                    fdr=0, matchset=NULL, longform=F, sample_comparison=NULL,
                                    background_comparison=NULL, min_p_threshold=NULL, tag=NA, sample_n=NULL) {
  # for each category in geneset calculates the abundance level
  #     of the genes/proteins in the category versus those
  #     not in the category and calculate a pvalue based on a
  #     two sided t test
  # If the sample_comparison variable is set then do a comparison between this
  #     abundance and sample comparison set which is vector of valid column (sample) ids
  results = matrix(nrow=length(geneset$names), ncol=8)
  rownames(results) = geneset$names
  colnames(results) = c("ingroup_mean", "outgroup_mean", "ingroup_n", "outgroup_n", "pvalue", "BH_pvalue", "count_above", "count_below")

  if (!is.null(mapping_column)) groupnames = unique(abundance[,mapping_column])

  for (i in 1:length(geneset$names)) {
    thisname = geneset$names[i]
    if (!is.null(matchset) && matchset != thisname) next

    thissize = geneset$size[i]
    thisdesc = geneset$desc[i]
    #cat(thisname, thissize, "\n")
    grouplist = geneset$matrix[i,1:thissize]
    if (!is.na(tag)) grouplist = sapply(grouplist, function (n) paste(tag, n, sep="_"))

    if (!is.null(mapping_column)) {
      ingroupnames = grouplist[which(grouplist %in% groupnames)]
      outgroupnames = groupnames[which(!groupnames %in% grouplist)]

      if (!is.null(sample_n)) {
        if (sample_n > length(ingroupnames) || sample_n > length(outgroupnames)) {
          next
        }
        #cat(sample_n, length(ingroupnames), length(outgroupnames), "\n")
        ingroupnames = sample(ingroupnames, sample_n)
        outgroupnames = sample(outgroupnames, sample_n)
      }

      ingroup = abundance[which(abundance[,mapping_column] %in% ingroupnames),
                          abundance_column[which(abundance_column %in% colnames(abundance[,2:ncol(abundance)]))]]

      if (!is.null(sample_comparison)) outgroup = abundance[which(abundance[,mapping_column] %in% ingroupnames),
                                                            sample_comparison[which(sample_comparison %in% colnames(abundance[,2:ncol(abundance)]))]]
      else outgroup = abundance[which(abundance[,mapping_column] %in% outgroupnames), abundance_column]
    }
    else {
      # I changed this to make it easier to use- may break old code!
      # ingroup = abundance[grouplist[which(grouplist %in% names(abundance))]]
      # outgroup = abundance[which(!names(abundance) %in% grouplist)]
      ingroup = unlist(abundance[grouplist[which(grouplist %in% rownames(abundance))],
                                 abundance_column[which(abundance_column %in% colnames(abundance))]])

      if (!is.null(sample_comparison)) outgroup = abundance[which(rownames(abundance) %in% grouplist),
                                                            sample_comparison[which(sample_comparison %in% colnames(abundance))]]
      else outgroup = abundance[which(!rownames(abundance) %in% grouplist),
                                abundance_column[which(abundance_column %in% colnames(abundance))]]
    }
    #cat(length(ingroup), length(outgroup), "\n")
    in_mean = mean(unlist(ingroup), na.rm=T)
    out_mean = mean(unlist(outgroup), na.rm=T)
    pvalue = NA
    if (length(ingroup)>1) {
      pvalue = try(t.test(unlist(ingroup), unlist(outgroup))$p.value, silent=T);
      if (class(pvalue)=="try-error") pvalue = NA;

      # we step through all components to calculate the number
      #    that are above/below the threshold
      if (!is.null(min_p_threshold)) {
        count_above = 0
        count_below = 0
        # this works with sample_comparison
        for (this_bit in rownames(ingroup)) {
          petevalue = try(t.test(ingroup[this_bit,], outgroup[this_bit,])$p.value, silent=F);
          if (class(petevalue)=="try-error" || is.na(petevalue)) {
            petevalue = NA;
          }
          else {
            if (petevalue > min_p_threshold) count_above = count_above + 1
            if (petevalue <= min_p_threshold) count_below = count_below + 1
          }
        }
        results[thisname,"count_above"] = count_above
        results[thisname,"count_below"] = count_below
      }
    }

    delta = in_mean - out_mean
    if (fdr) {
      background = c()
      abundances = c(ingroup, outgroup)
      for (i in 1:fdr) {
        # randomly sample genes for fdr times
        ingroup = sample(1:length(abundances), length(ingroup))
        outgroup = which(!1:length(abundances) %in% ingroup)
        ingroup = abundances[ingroup]
        outgroup = abundances[outgroup]
        in_mean = mean(ingroup, na.rm=T)
        out_mean = mean(outgroup, na.rm=T)
        delta_r = in_mean - out_mean
        background = c(background, delta_r)
      }
      pvalue = sum(abs(background)>abs(delta))/length(background)
    }

    this = c(in_mean, out_mean, length(unlist(ingroup)), length(unlist(outgroup)), pvalue, NA)

    results[thisname,1:6] = this
  }
  results[,"BH_pvalue"] = p.adjust(results[,"pvalue"], method="BH")
  if (!is.null(matchset)) {
    results = results[matchset,]
    if (longform==T) results = list(results, ingroup, outgroup)
  }
  return(results)
}