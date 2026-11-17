# Single-cell data of the scRNA-seq lecture and tutorial

The files are `SingleCellExperiment` objects with sparse raw counts (`counts` assay),
saved with `saveRDS`. They were built with `R/make_scrnaseq_data.R` in the course
repository from the Bioconductor data packages MouseGastrulationData and muscData, and
with `R/make_covid_data.R` from Zenodo record 10391097.

## chimera_sample5.rds

Mouse chimeric embryos at E8.5, sample 5 (tdTomato-positive cells injected into a
wild-type host embryo; Pijuan-Sala et al. 2019, Nature 566:490-495; ArrayExpress
E-MTAB-7324). 10x Genomics, droplet-based with UMIs.

- The raw data contain 522,554 barcodes. Barcodes with a profile that differs from
  the ambient RNA (`DropletUtils::emptyDrops`, FDR <= 0.001) are retained: 3,388 cells.
- No quality control or doublet removal has been performed.
- `colData`: the emptyDrops results (`Total`, `LogProb`, `PValue`, `FDR`) and
  `celltype.published`, the cell type of the original publication. Cells that the
  authors removed in their QC or as doublets have `NA`.
- `rowData`: `ENSEMBL`, `SYMBOL` and `chr_mito` (`TRUE` for the 13 mitochondrial genes).
  The last row, `tomato-td`, is the tdTomato transgene.

## embryo_atlas_ref.rds

Labelled reference for cell type annotation with SingleR: mouse gastrulation atlas,
sample 29 (`EmbryoAtlasData`), 2,000 random cells with a cell type label, cell types
with fewer than 10 cells removed (1,975 cells, 20 cell types).

## kang.rds

Peripheral blood mononuclear cells (PBMCs) of 8 lupus patients, untreated (`ctrl`) or
stimulated with interferon beta for 6 hours (`stim`) (Kang et al. 2018, Nature
Biotechnology 36:89-94; GEO GSE96583). The cells of all patients were pooled per
condition and assigned to a patient with demuxlet, based on their genotype.

- 24,673 singlets with a cell type label; genes with zero counts in all cells removed
  (18,464 genes).
- `colData`: `patient`, `stim` and `celltype` (8 cell types, as annotated by the authors).
- The data contain no counts for mitochondrial genes, so mitochondrial QC is not possible.

## covid_bcells.rds

B cells from the peripheral blood of COVID-19 patients and healthy donors (Stephenson
et al. 2021, Nature Medicine 27:904-916), as used in the case study of Gilis et al.
2025, BMC Genomics 26:886. Source: `Covid_case/objects/sce_Covid_Bcells.rds` of Zenodo
record 10391097 (doi:10.5281/zenodo.10391097, CC BY 4.0), with counts converted back to
raw integer counts from the normalised values of the atlas.

- 51,735 cells of five B-cell types (naive, immature, unswitched memory, class switched
  memory and other B cells) of 110 donors from two sites (Cambridge and Ncl);
  genes with zero counts in all cells removed (17,423 genes).
- `colData`: `donor`, `site`, `sex`, `age` (decade), `status` (Healthy, Asymptomatic,
  Mild, Moderate, Severe, Critical, on the day of sample collection) and `celltype`.
  Every donor belongs to a single site.
- The data contain no counts for mitochondrial genes.

## Download in R

```r
url <- "https://github.com/statOmics/SGA/releases/download/scrnaseq-v1/"
dir.create("scrnaseqData", showWarnings = FALSE)
for (f in c("chimera_sample5.rds", "embryo_atlas_ref.rds", "kang.rds", "covid_bcells.rds")) {
  if (!file.exists(file.path("scrnaseqData", f))) {
    download.file(paste0(url, f), file.path("scrnaseqData", f), mode = "wb")
  }
}
sce <- readRDS("scrnaseqData/chimera_sample5.rds")
```
