# Build the single-cell datasets of the scRNA-seq lecture and tutorial.
#
# The files are published as a release of the course repository (tag scrnaseq-v1),
# so that students download preprocessed data with one call, as for the airway data.
# Run from the root of the repository: Rscript R/make_scrnaseq_data.R
#
# Output (in scrnaseqData/):
# - chimera_sample5.rds: mouse chimeric embryo, sample 5 (Pijuan-Sala et al. 2019,
#   ArrayExpress E-MTAB-7324, via MouseGastrulationData), cell-containing droplets
#   after emptyDrops, before QC.
# - embryo_atlas_ref.rds: labelled reference for SingleR, mouse gastrulation atlas
#   sample 29 (EmbryoAtlasData), subsampled to 2000 cells.
# - kang.rds: PBMCs of 8 lupus patients, control vs IFN-beta stimulated
#   (Kang et al. 2018, GEO GSE96583, via muscData), multiplets removed.

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(MouseGastrulationData)
  library(DropletUtils)
  library(muscData)
  library(Matrix)
})

outDir <- "scrnaseqData"
dir.create(outDir, showWarnings = FALSE)
set.seed(20261116)

asSparse <- function(sce) {
  counts(sce) <- as(as(counts(sce), "CsparseMatrix"), "dgCMatrix")
  sce
}

# 1. Chimeric embryo, sample 5 ------------------------------------------------

raw <- WTChimeraData(samples = 5, type = "raw")[[1]]
raw <- asSparse(raw)
ncol(raw)

# Empty droplets: test every barcode against the ambient RNA profile.
# emptyDrops uses Monte Carlo p-values, hence the seed above.
ed <- emptyDrops(counts(raw))
isCell <- !is.na(ed$FDR) & ed$FDR <= 0.001
chimera <- raw[, isCell]
colData(chimera) <- cbind(colData(chimera), ed[isCell, c("Total", "LogProb", "PValue", "FDR")])

# Chromosome of every gene, so that mitochondrial genes can be found without EnsDb.
# The mitochondrial genes of the mouse have symbols starting with "mt-".
rowData(chimera)$chr_mito <- grepl("^mt-", rowData(chimera)$SYMBOL)

# Cell type labels of the original publication, for comparison with the clusters.
# Cells that the authors removed in their QC or as doublets get NA.
processed <- WTChimeraData(samples = 5)
# The raw data are indexed by barcode, the processed data by cell identifier.
matched <- match(colnames(chimera), processed$barcode)
chimera$celltype.published <- processed$celltype.mapped[matched]

metadata(chimera) <- list(
  source = "MouseGastrulationData::WTChimeraData(samples = 5, type = 'raw')",
  emptyDrops = "DropletUtils::emptyDrops, FDR <= 0.001",
  reference = "Pijuan-Sala et al. 2019, Nature 566:490-495"
)
saveRDS(chimera, file.path(outDir, "chimera_sample5.rds"))

# 2. Reference atlas for SingleR ------------------------------------------------

ref <- EmbryoAtlasData(samples = 29)
ref <- asSparse(ref)
ref <- ref[, !is.na(ref$celltype)]
ref <- ref[, sample(ncol(ref), min(2000, ncol(ref)))]
ref <- ref[, ref$celltype %in% names(which(table(ref$celltype) >= 10))]
colData(ref) <- colData(ref)[, c("cell", "sample", "stage", "celltype")]
metadata(ref) <- list(
  source = "MouseGastrulationData::EmbryoAtlasData(samples = 29), 2000 random cells",
  reference = "Pijuan-Sala et al. 2019, Nature 566:490-495"
)
saveRDS(ref, file.path(outDir, "embryo_atlas_ref.rds"))

# 3. Kang data -------------------------------------------------------------------

kang <- Kang18_8vs8()
kang <- asSparse(kang)
kang <- kang[, kang$multiplets == "singlet" & !is.na(kang$cell)]
kang <- kang[rowSums(counts(kang)) > 0, ]
colData(kang) <- DataFrame(
  patient = factor(kang$ind),
  stim = factor(kang$stim, levels = c("ctrl", "stim")),
  celltype = factor(kang$cell),
  row.names = colnames(kang)
)
reducedDims(kang) <- list()
metadata(kang) <- list(
  source = "muscData::Kang18_8vs8(), singlets with a cell type label",
  reference = "Kang et al. 2018, Nature Biotechnology 36:89-94"
)
saveRDS(kang, file.path(outDir, "kang.rds"))

# Summary -------------------------------------------------------------------------

for (f in list.files(outDir, pattern = "rds$", full.names = TRUE)) {
  x <- readRDS(f)
  cat(sprintf("%-25s %6d genes %6d cells %7.1f MB\n", basename(f), nrow(x), ncol(x),
              file.size(f) / 1e6))
}
sessionInfo()
