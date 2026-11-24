# Build the static figures for the introduction of the scRNA-seq lecture.
#
# 1. The lego figure (image credit: Bo Xia), composed once from the four photos in figs/
#    and downscaled, so that the lecture includes a single compact image. Drawing the
#    photos in the lecture itself would embed them uncompressed in the PDF (~29 MB).
# 2. The Kang UMAP: the introduction shows the Kang data before the workflow is
#    introduced, so the figure is made once with the same steps as in the
#    multi-sample section.
#
# Run from the root of the repository: Rscript R/make_scrnaseq_figs.R
#
# Output: figs/sc_lego.jpeg, figs/sc_kangUMAP.png

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(scrapper)
  library(tidyverse)
  library(patchwork)
})

# 1. Lego figure -----------------------------------------------------------------

legoImg <- lapply(c("organ", "bulk", "sc", "spatial"), function(x)
  grid::rasterGrob(jpeg::readJPEG(paste0("figs/sc_lego_", x, ".jpeg")), interpolate = TRUE))
jpeg("figs/sc_lego.jpeg", width = 10, height = 5, units = "in", res = 200, quality = 90)
gridExtra::grid.arrange(
  grobs = legoImg,
  top = "Organ",
  bottom = "Bulk RNA-seq                                  scRNA-seq                                  Spatial RNA-seq",
  layout_matrix = rbind(
    c(NA, NA, NA, NA, 1, 1, 1, NA, NA, NA, NA),
    c(2, 2, 2, NA, 3, 3, 3, NA, 4, 4, 4)))
invisible(dev.off())

# 2. Kang UMAP -------------------------------------------------------------------

kang <- readRDS("scrnaseqData/kang.rds")
kangExpl <- normalizeRnaCounts.se(kang, size.factors = colSums(counts(kang)))
kangExpl <- chooseRnaHvgs.se(kangExpl)
kangExpl <- runPca.se(kangExpl, features = rowData(kangExpl)$hvg)
set.seed(1234)
kangExpl <- runAllNeighborSteps.se(kangExpl, tsne.output.name = NULL, cluster.output.name = NULL)

plotDims <- function(dims, color, colorName, title) {
  tibble(dim1 = dims[, 1], dim2 = dims[, 2], color = color) |>
    ggplot(aes(dim1, dim2, color = color)) +
    geom_point(size = 0.3) +
    labs(color = colorName, title = title) +
    theme_bw() +
    theme(legend.text = element_text(size = 6), legend.key.size = unit(0.3, "cm"))
}

p <- plotDims(reducedDim(kangExpl, "UMAP"), kangExpl$celltype, "Cell type", "UMAP") +
  plotDims(reducedDim(kangExpl, "UMAP"), kangExpl$stim, "Condition", "UMAP") +
  plotDims(reducedDim(kangExpl, "UMAP"), kangExpl$patient, "Patient", "UMAP")
ggsave("figs/sc_kangUMAP.png", p, width = 15, height = 4.5, dpi = 150)
