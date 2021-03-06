#!/usr/bin/env Rscript

# Relationship between input parameters and the ones used here
inputargs = commandArgs(trailingOnly=TRUE)
outputdir = inputargs[1]
fdr = as.numeric(inputargs[2])
grnainfofiles = inputargs[3:length(inputargs)]

# Open pdf
pdf(paste(outputdir, "/outputs/Log_counts.pdf", sep = ""))


#############################
## Plot useful information ##
#############################

for (gfile in grnainfofiles[1:(length(grnainfofiles))]) {

  # Check the test number
  savename = gsub(".*results_MAGeCK_", "", gfile)
  savename = gsub(".sgrna_summary.txt", "", savename)

  # Import the gRNA info files
  ginfo = read.table(gfile, header = T, stringsAsFactors = F)
  ginfo$p.low[ginfo$p.low < 1E-10] = 1E-10
  ginfo$p.high[ginfo$p.high < 1E-10] = 1E-10

  # Import hits
  hitspath = gsub("results_MAGeCK_.*", "", gfile)
  hits = read.table(
    paste(hitspath, "hits.all_MAGeCK_", savename, ".txt", sep = ""),
    header = T, stringsAsFactors = F)
  hitstwo = read.table(
    paste(hitspath, "hits.all_PBNPA_", savename, ".txt", sep = ""),
    header = T, stringsAsFactors = F)

  # Import the normalized count files
  countspath = gsub("sgrna_summary", "normalized", gfile)
  counts = read.table(countspath, header = T, stringsAsFactors = F)
  counts_second = counts

  ## DEFINE LAYOUT FOR THE PLOTS
  m <- matrix(c(1,1, 2,3), nrow = 2, ncol = 2, byrow=TRUE)
  layout(m)

  # Define used colors for the hits
  used_colors =  rainbow(nrow(hits)+nrow(hitstwo))


  ## CREATE 1st PLOT ##
  # Set graph limits
  minval = min(ginfo$LFC)
  maxval = max(ginfo$LFC)

  # Sort the dataframe by the log2 fold change
  ginfoordered = ginfo[as.numeric(order(ginfo$LFC)),]

  # Plot figures
  # Open an empty plot that allows to add lines afterwards
  plot(1,minval, type = "n",
       xlim = c(1, nrow(ginfoordered)),
       ylim = c(minval, maxval),
       xlab = "",
       axes = F,
       ylab = "Log2 fold-change",
       main = paste("Log2 fold-change, test ", savename, sep =""))
  # Plot a line following all of the gRNAs
  lines(seq(1,nrow(ginfoordered)), ginfoordered$LFC)
  # Add 0 y-axis
  abline(0,0, col = "dimgray", lty = 5)
  # Write y-axis
  axis(side=2,
       at = seq(minval, maxval, length.out = 5),
       labels = round(seq(minval, maxval, length.out = 5), 1))
  # Write x-label
  mtext(side=1, line=0, "Ranked gRNAs")
  # Add position of guides targeting hits to the plot
  for (j in 1:nrow(hits)){
    points(seq(1,nrow(ginfoordered))[ginfoordered$Gene %in% hits$group_id[j]],
           ginfoordered$LFC[ginfoordered$Gene %in% hits$group_id[j]],
           pch = 19, col = used_colors[j], cex = 0.7)
  }
  for (k in 1:nrow(hitstwo)){
    points(seq(1,nrow(ginfoordered))[ginfoordered$Gene %in% hitstwo$Gene[k]],
           ginfoordered$LFC[ginfoordered$Gene %in% hitstwo$Gene[k]],
           pch = 19, col = used_colors[j+k], cex = 0.7)
  }
  # Add legend
  legend(x = "topleft", bty = "n", pch = 19,
         legend = c("gRNAs of selected genes"),
         col = c("red"), x.intersp= 0.7, cex = 0.5)


  ## CREATE 2nd PLOT ##
  # Replace 0s from counts file to avoid problems with log2
  for (jcol in 3:ncol(counts)) {
    counts[counts[,jcol] == 0,jcol] = 1
  }

  # Determine how many samples appear in the counts table
  numcols = ncol(counts)
  numsamples = numcols - 2

  # Determine how many samples are treatments or controls
  numtreated = numsamples/2
  dayzero = 3:(numtreated+2)
  daytreated = (numtreated+3):numcols

  # Compute the log2
  counts[,3:numcols] = log2(counts[,3:numcols])

  # Separate controls from treatments
  if (length(dayzero) > 1) {
    logcontrol = rowSums(counts[,dayzero])
    logtreated = rowSums(counts[,daytreated])
  } else {
    logcontrol = counts[,dayzero]
    logtreated = counts[,daytreated]
  }
  names(logcontrol) = counts$Gene
  names(logtreated) = counts$Gene

  # Plot log2 counts
  plot(logcontrol, logtreated,
       main = paste("Log2 counts, test", savename, sep = ""),
       pch = 19, col = "dimgray",
       xlab = "Log2 counts, untreated",
       ylab = "Log2 counts, treated")
  for (j in 1:nrow(hits)){
    points(logcontrol[names(logcontrol) %in% hits$group_id[j]],
           logtreated[names(logtreated) %in% hits$group_id[j]],
           pch = 19, col = used_colors[j], cex = 0.7)
  }
  for (k in 1:nrow(hitstwo)){
    points(logcontrol[names(logcontrol) %in% hitstwo$Gene[k]],
           logtreated[names(logtreated) %in% hitstwo$Gene[k]],
           pch = 19, col = used_colors[k+j], cex = 0.7)
  }
  # Add legend
  legend(x = "topleft", bty = "n", pch = 19,
         legend = c("gRNAs of selected genes"),
         col = c("red"), x.intersp= 0.7, cex = 0.5)


  ## CREATE 3rd PLOT ##
  # Define how many colors will be used
  used_colors_3 = rainbow(ncol(counts_second)-2)

  # Open an empty plot that allows to add lines afterwards
  plot(0,0, type = "n",
       xlim = c(1, nrow(counts_second)),
       ylim = c(0, 100),
       xlab = "gRNAs",
       ylab = "Percentage of total counts (%)",
       main = paste("Cumulative counts, test ", savename, sep = ""))

  # Add lines for all the different samples
  used_legend = numeric()
  for (jcol in 3:ncol(counts_second)) {
    # Compute and plot cumulative distribution
    cumul_ctr = cumsum(sort(counts_second[,jcol], decreasing = T))
    cumul_dist = (cumul_ctr/sum(counts_second[,jcol]))*100
    lines(seq(1,length(cumul_dist), by = 1), cumul_dist,
          col = used_colors_3[jcol-2])
    used_legend[jcol-2] = colnames(counts_second)[jcol]
    if (nchar(used_legend[jcol-2]) > 10) {
      used_legend[jcol-2] = paste(
        substr(used_legend[jcol-2], 1, 7), "...", sep="")
    }
  }
  legend(x = "topleft", bty = "n", pch = 19,
         legend = used_legend,
         col = used_colors_3,
         x.intersp=0.5,
         inset = c(0, -0.1), xpd = T,
         horiz = T, cex = 0.5)


   ## CREATE SEPARATED VOLCANO PLOTS ## ______________________

   # Define layout
   m <- matrix(c(1,2), nrow = 2, ncol = 1, byrow=TRUE)
  layout(m)

   # Volcano 1
   # Import information of genes
   genespath = gsub("intermediate/results_MAGeCK_.*", "", gfile)
   genesinfo = read.table(
     paste(genespath, "/outputs/comb_result_",
           savename, ".txt", sep = ""),
     header = T, stringsAsFactors = F, dec = ".")
   genesinfo$neg.pval[genesinfo$neg.pval < 1E-10] = 1E-10
   genesinfo$pos.pval[genesinfo$pos.pval < 1E-10] = 1E-10

   # Create Volcano plot
   plot(genesinfo$lfc[genesinfo$neg.pval < genesinfo$pos.pval],
        -log10(genesinfo$neg.pval)[
                genesinfo$neg.pval < genesinfo$pos.pval],
        main = paste(
              "Volcano plot of genes, test", savename, sep = ""),
        pch = 19, col = "gray",
        xlim = c(min(genesinfo$lfc), max(genesinfo$lfc)),
        ylim = c(0, min(10,
                -log10(min(genesinfo$neg.pval, genesinfo$pos.pval)))),
        xlab = "Log2 fold-change",
        ylab = "-Log10(p-value)")
   points(genesinfo$lfc[genesinfo$pos.pval < genesinfo$neg.pval],
          -log10(genesinfo$pos.pval)[
                  genesinfo$pos.pval < genesinfo$neg.pval],
          pch = 19, col = "gray")
   abline(v=0, col = "dimgray", lty = 5)

   # Add hits to the graph
   # Add MAGeCK hits for negative selection
   points(genesinfo$lfc[genesinfo$Gene %in% hits$group_id &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          -log10(genesinfo$neg.pval)[genesinfo$Gene %in% hits$group_id &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          pch = 19, col = "red", cex = 0.7)
   # Add MAGeCK hits for positive selection
   points(genesinfo$lfc[genesinfo$Gene %in% hits$group_id &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          -log10(genesinfo$pos.pval)[genesinfo$Gene %in% hits$group_id &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          pch = 19, col = "red", cex = 0.7)
   # Add PBNPA hits for negative selection
   points(genesinfo$lfc[genesinfo$Gene %in% hitstwo$Gene &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          -log10(genesinfo$neg.pval)[genesinfo$Gene %in% hitstwo$Gene &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          pch = 19, col = "blue", cex = 0.7)
   # Add PBNPA hits for positive selection
   points(genesinfo$lfc[genesinfo$Gene %in% hitstwo$Gene &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          -log10(genesinfo$pos.pval)[genesinfo$Gene %in% hitstwo$Gene &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          pch = 19, col = "blue", cex = 0.7)
   # Add hits common in both for negative selection
   points(genesinfo$lfc[genesinfo$Gene %in% intersect(hits$group_id,
          hitstwo$Gene) & genesinfo$neg.pval < genesinfo$pos.pval],
          -log10(genesinfo$neg.pval)[genesinfo$Gene %in% intersect(
            hits$group_id, hitstwo$Gene) &
            genesinfo$neg.pval < genesinfo$pos.pval],
          pch = 19, col = "green", cex = 0.7)
   # Add hits common in both for positive selection
   points(genesinfo$lfc[genesinfo$Gene %in% intersect(hits$group_id,
            hitstwo$Gene) & genesinfo$pos.pval < genesinfo$neg.pval],
           -log10(genesinfo$pos.pval)[genesinfo$Gene %in% intersect(
             hits$group_id, hitstwo$Gene) &
             genesinfo$pos.pval < genesinfo$neg.pval],
           pch = 19, col = "green", cex = 0.7)
   # Add legend
   legend(x = "bottomleft", bty = "n", pch = 19,
          legend = c(
            "Selected genes MAGeCK",
            "Selected genes PBNPA",
            "Selected genes M + P"),
          col = c("red", "blue", "green"), x.intersp= 0.7, cex = 0.5)

   # Volcano 2
   # Determine hits from combined outputs
   hits_comb = genesinfo[genesinfo$neg.fdr < fdr | genesinfo$pos.fdr < fdr, 1]

   # Create Volcano plot
   plot(genesinfo$lfc[genesinfo$neg.pval < genesinfo$pos.pval],
        -log10(genesinfo$neg.pval)[
                genesinfo$neg.pval < genesinfo$pos.pval],
        main = paste(
              "Volcano plot of genes, test", savename, sep = ""),
        pch = 19, col = "gray",
        xlim = c(min(genesinfo$lfc), max(genesinfo$lfc)),
        ylim = c(0, min(10,
                -log10(min(genesinfo$neg.pval, genesinfo$pos.pval)))),
        xlab = "Log2 fold-change",
        ylab = "-Log10(p-value)")
   points(genesinfo$lfc[genesinfo$pos.pval < genesinfo$neg.pval],
          -log10(genesinfo$pos.pval)[
                  genesinfo$pos.pval < genesinfo$neg.pval],
          pch = 19, col = "gray")
   abline(v=0, col = "dimgray", lty = 5)

   # Add hits to the graph for negative selection
   points(genesinfo$lfc[genesinfo$Gene %in% hits_comb &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          -log10(genesinfo$neg.pval)[genesinfo$Gene %in% hits_comb &
                  genesinfo$neg.pval < genesinfo$pos.pval],
          pch = 19, col = "purple", cex = 0.7)
   # Add hits to the graph for positive selection
   points(genesinfo$lfc[genesinfo$Gene %in% hits_comb &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          -log10(genesinfo$pos.pval)[genesinfo$Gene %in% hits_comb &
                  genesinfo$pos.pval < genesinfo$neg.pval],
          pch = 19, col = "purple", cex = 0.7)

   # Add legend
   legend(x = "bottomleft", bty = "n", pch = 19,
          legend = c("Selected genes with combined FDRs"),
          col = c("purple"), x.intersp= 0.7, cex = 0.5)
}

message = dev.off()

##########
## DONE ##
##########
