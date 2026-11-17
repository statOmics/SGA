# Build the COVID-19 B-cell dataset of the scRNA-seq tutorial.
#
# Published as a release asset of the course repository (tag scrnaseq-v1), next to
# the files of R/make_scrnaseq_data.R.
# Run from the root of the repository: Rscript R/make_covid_data.R
#
# Source: Zenodo record 10391097 (doi:10.5281/zenodo.10391097, CC BY 4.0), the data of
# Gilis et al. 2025, BMC Genomics 26:886 (doi:10.1186/s12864-025-12102-x), case study
# "Covid". The object sce_Covid_Bcells.rds contains the B cells of the COVID-19 PBMC
# atlas of Stephenson et al. 2021, Nature Medicine 27:904-916, retrieved with
# CuratedAtlasQueryR. Its counts were converted back from the scanpy-normalised values
# to raw integer counts (see 1_CovidCase_getdata.Rmd in github.com/statOmics/DD_cases).
#
# As in the case study of Gilis et al., we keep
# - the five B-cell types (plasma cells and plasmablasts are removed),
# - COVID-19 patients and healthy donors,
# - the sites Cambridge and Ncl (Sanger has few patients and no healthy donors).
#
# Output: scrnaseqData/covid_bcells.rds

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(Matrix)
})

outDir <- "scrnaseqData"
dir.create(outDir, showWarnings = FALSE)

# 1. Download -----------------------------------------------------------------------

zipFile <- file.path(tempdir(), "Covid_case.zip")
if (!file.exists(zipFile)) {
  options(timeout = 3600)
  download.file("https://zenodo.org/records/10391097/files/Covid_case.zip?download=1",
                zipFile, mode = "wb")
}
objectInZip <- "Covid_case/objects/sce_Covid_Bcells.rds"
unzip(zipFile, files = objectInZip, exdir = tempdir())
sce <- readRDS(file.path(tempdir(), objectInZip))
sce

# 2. Selection ------------------------------------------------------------------------

bcellTypes <- c("naive B cell", "immature B cell", "unswitched memory B cell",
                "class switched memory B cell", "B cell")
keepCells <- sce$cell_type_curated %in% bcellTypes &
  sce$Status %in% c("Covid", "Healthy") &
  sce$Site %in% c("Cambridge", "Ncl")
sce <- sce[, keepCells]
counts(sce) <- as(as(counts(sce), "CsparseMatrix"), "dgCMatrix")
sce <- sce[rowSums(counts(sce)) > 0, ]

# 3. Metadata -------------------------------------------------------------------------

statusLevels <- c("Healthy", "Asymptomatic", "Mild", "Moderate", "Severe", "Critical")
ageLevels <- paste(c("third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth",
                     "tenth"), "decade human stage")
stopifnot(all(sce$Status_on_day_collection_summary %in% statusLevels),
          all(sce$development_stage %in% ageLevels))

colData(sce) <- DataFrame(
  donor = factor(sce$donor_id),
  site = factor(sce$Site),
  sex = factor(sce$sex),
  age = factor(sub(" decade human stage", "", sce$development_stage),
               levels = sub(" decade human stage", "", ageLevels)),
  status = factor(sce$Status_on_day_collection_summary, levels = statusLevels),
  celltype = factor(sce$cell_type_curated, levels = bcellTypes),
  row.names = colnames(sce)
)
colData(sce) <- droplevels(colData(sce))
reducedDims(sce) <- list()
metadata(sce) <- list(
  source = "Zenodo 10391097, Covid_case/objects/sce_Covid_Bcells.rds",
  selection = "5 B-cell types, COVID-19 and healthy, sites Cambridge and Ncl",
  reference = c("Stephenson et al. 2021, Nature Medicine 27:904-916",
                "Gilis et al. 2025, BMC Genomics 26:886")
)

# Every donor belongs to a single site, status, sex and age group.
donorInfo <- unique(as.data.frame(colData(sce))[, c("donor", "site", "sex", "age", "status")])
stopifnot(!anyDuplicated(donorInfo$donor))
print(table(donorInfo$site, donorInfo$status))
print(table(sce$celltype))

saveRDS(sce, file.path(outDir, "covid_bcells.rds"))
cat(sprintf("covid_bcells.rds %d genes %d cells %.1f MB\n", nrow(sce), ncol(sce),
            file.size(file.path(outDir, "covid_bcells.rds")) / 1e6))
sessionInfo()
