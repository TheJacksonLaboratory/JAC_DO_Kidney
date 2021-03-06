# qsub -v script=Phs_Intscan188b Rsubmit_args.sh
library(qtl2convert)
library(qtl2)
library(dplyr)
setwd("/projects/korstanje-lab/ytakemon/JAC_DO_Kidney")
load("./RNAseq_data/DO1045_kidney.Rdata")
load("./RNAseq_data/DO188b_kidney.RData")

# Subset pheontype: Phs
pheno <- Upheno[Upheno$study == "Cross-sectional",]
pheno <- pheno[-1,]
pheno_cr <- pheno[,c("Mouse.ID", "cr.u.6", "cr.u.12", "cr.u.18")]
pheno_phs <- pheno[,c("Mouse.ID", "phs.u.6", "phs.u.12", "phs.u.18")]

# colapse to one column and combine
pheno_cr <- pheno_cr %>% mutate(
              cr.u.all = log(coalesce(cr.u.6, cr.u.12, cr.u.18))
            )
pheno_phs <- pheno_phs %>% mutate(
              phs.u.all = log(coalesce(phs.u.6, phs.u.12, phs.u.18))
            )

pheno <- pheno_cr[,c("Mouse.ID","cr.u.all")]
pheno$phs.u.all <- pheno_phs$phs.u.all
pheno <- pheno[!is.na(pheno[,2] & pheno[,3]),]
rownames(pheno) <- pheno$Mouse.ID

# Subset dataset total : 159
genoprobs <- genoprobs[rownames(genoprobs) %in% pheno$Mouse.ID,,]
annot.samples <- annot.samples[rownames(annot.samples) %in% pheno$Mouse.ID,]
pheno <- pheno[pheno$Mouse.ID %in% rownames(annot.samples),]
annot.samples$cr.u.all <- pheno$cr.u.all

# prepare data for qtl2
snps$chr <- as.character(snps$chr)
probs <- probs_doqtl_to_qtl2(genoprobs, snps, pos_column = "pos")
K <- calc_kinship(probs, type = "loco", cores = 20)
map <- map_df_to_list(map = snps, pos_column = "pos")
addcovar <- model.matrix(~ Sex + Age + Generation + cr.u.all , data = annot.samples)
intcovar <- model.matrix(~ Age, data = annot.samples)

# scan
lod <- scan1(genoprobs=probs,
             kinship=K,
             pheno=as.data.frame(pheno$phs.u.all, row.names = rownames(pheno)),
             addcovar=addcovar[,-1],
             intcovar=intcovar[,-1],
             cores=20,
             reml=TRUE)
# save lod
saveRDS(lod, file = "./QTLscan/addscan_urine/Intscan_phs_188b.rds")

perm <- scan1perm(genoprobs=probs,
                     kinship=K,
                     pheno=as.data.frame(pheno$phs.u.all, row.names = rownames(pheno)),
                     addcovar=addcovar[,-1],
                     intcovar=intcovar[,-1],
                     cores=20,
                     n_perm = 1000,
                     reml = TRUE)
# save permutation
saveRDS(perm, file = "./QTLscan/addscan_urine/Intperm_phs_188b.rds")

# Get coef
# get max lod
chr <- max(lod, map)$chr
# calc coef
coef <- scan1coef(genoprobs = probs[,chr],
                  kinship = K[chr],
                  pheno = as.data.frame(pheno$phs.u.all, row.names = rownames(pheno)),
                  addcovar = addcovar[,-1],
                  intcovar=intcovar[,-1],
                  reml = TRUE)
# save coef
saveRDS(coef, file = "./QTLscan/addscan_urine/Intcoef_phs_188b.rds")

# Get genes in lod peak interval
query_variants <- create_variant_query_func("./qtl2_sqlite/cc_variants.sqlite")
peak_Mbp <- (max(lod, map)$pos) / 1e6
peak_chr <- max(lod, map)$chr
map <- map_df_to_list(map = snps, pos_column = "bp") # needs Mbp as input for query
out_snps <- scan1snps(genoprobs = probs,
                      map = map,
                      pheno = as.data.frame(pheno$phs.u.all, row.names = rownames(pheno)),
                      kinship =K[[peak_chr]],
                      addcovar = addcovar[,-1],
                      intcovar=intcovar[,-1],
                      query_func=query_variants,
                      chr=peak_chr,
                      start=peak_Mbp-1,
                      end=peak_Mbp+1,
                      keep_all_snps=TRUE,
                      cores = 20)
saveRDS(out_snps, file = "./QTLscan/addscan_urine/Intsnps_phs_188b.rds")
