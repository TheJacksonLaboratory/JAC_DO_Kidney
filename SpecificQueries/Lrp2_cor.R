library(ggplot2)
library(dplyr)
library(broom)
library(GGally)
setwd("/projects/korstanje-lab/ytakemon/JAC_DO_Kidney")
load("./shiny_annotation.RData")
load("./RNAseq_data/DO188b_kidney.RData")
pheno <- read.delim("./Phenotype/phenotypes/formatted/JAC_CS_urine_chem_v1.txt", sep = "\t")

# Subset pheno to match count for animal id
pheno$duplicated <- (duplicated(pheno$mouse.id) | duplicated(pheno$mouse.id, fromLast = TRUE))
pheno <- pheno[pheno$duplicated == FALSE,]
pheno <- pheno[pheno$mouse.id %in% annot.samples$Mouse.ID,] # only 176 animals with phenotypes
pheno <- arrange(pheno, mouse.id)
pheno$log.ma.cr.u <- log(pheno$ma.cr.u)
for( i in 1:length(pheno$log.ma.cr.u)){
  if(is.na(pheno$log.ma.cr.u[i])){
    pheno$log.ma.cr.u[i] <- NA
  } else if(pheno$log.ma.cr.u[i] == -Inf){
    pheno$log.ma.cr.u[i] <- 0
  } else if (pheno$log.ma.cr.u[i] < 0){
    pheno$log.ma.cr.u[i] <- NA
  } else {
    pheno$log.ma.cr.u[i] <- pheno$log.ma.cr.u[i]
  }
}

annot.samples <- annot.samples[annot.samples$Mouse.ID %in% pheno$mouse.id,]
expr.mrna <- expr.mrna[rownames(expr.mrna) %in% pheno$mouse.id,]
expr.protein <- expr.protein[rownames(expr.protein) %in% pheno$mouse.id,]

# Identify gene name
gene1 <- "Lrp2"
other.ids <- function(gene.name, level) {
  if (level == "mRNA") {
    sel <- which(mRNA.list$symbol == gene.name)[1]
    if (!is.na(sel)) return(mRNA.list[sel,]) else return(c(NA,NA,NA))
  }
  if (level == "protein") {
    sel <- which(protein.list$symbol == gene.name)[1]
    if (!is.na(sel)) return(protein.list[sel,]) else return(c(NA,NA,NA))
  }
}
gene1 <- other.ids(gene1, "mRNA")

# new df
df <- annot.samples[,1:4]
df <- cbind(df, expr.mrna[, gene1$id], expr.protein[, gene1$protein_id], pheno$log.ma.cr.u)
colnames(df)[5:7] <- c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U")
df$Age <- as.factor(df$Age)

upper_fn <- function(data, mapping, ...) {

  # get the x and y data to use the other code
  # Total
  x <- eval(mapping$x, data)
  y <- eval(mapping$y, data)
  # 6mo.
  x6 <- eval(mapping$x, data[data$Age == 6,])
  y6 <- eval(mapping$y, data[data$Age == 6,])
  # 10mo.
  x12 <- eval(mapping$x, data[data$Age == 12,])
  y12 <- eval(mapping$y, data[data$Age == 12,])
  # 18mo.
  x18 <- eval(mapping$x, data[data$Age == 18,])
  y18 <- eval(mapping$y, data[data$Age == 18,])

  # Correlation
  # Total
  ct <- cor.test(x,y)
  sig <- symnum(
    ct$p.value, corr = FALSE, na = FALSE,
    cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
    symbols = c("***", "**", "*", "+", " ")
  )
  r <- unname(ct$estimate)
  rt <- format(r, digits=2)[1]

  # 6mo.
  ct6 <- cor.test(x6,y6)
  sig6 <- symnum(
    ct6$p.value, corr = FALSE, na = FALSE,
    cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
    symbols = c("***", "**", "*", "+", " ")
  )
  r6 <- unname(ct6$estimate)
  rt6 <- format(r6, digits=2)[1]

  # 12mo.
  ct12 <- cor.test(x12,y12)
  sig12 <- symnum(
    ct12$p.value, corr = FALSE, na = FALSE,
    cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
    symbols = c("***", "**", "*", "+", " ")
  )
  r12 <- unname(ct12$estimate)
  rt12 <- format(r12, digits=2)[1]

  # 6mo.
  ct18 <- cor.test(x18,y18)
  sig18 <- symnum(
    ct18$p.value, corr = FALSE, na = FALSE,
    cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
    symbols = c("***", "**", "*", "+", " ")
  )
  r18 <- unname(ct18$estimate)
  rt18 <- format(r18, digits=2)[1]

  rt_out <- paste("All:",rt, "\n", "6mo.:",rt6, "\n","12mo.:", rt12, "\n","18mo.:", rt18)
  sig_out <- paste(sig, "\n", sig6, "\n", sig12, "\n", sig18)
  # plot the cor value
  ggally_text(
    label = as.character(rt_out),
    mapping = aes(),
    xP = 0.5, yP = 0.55,
    ...
  ) +
    # add the sig stars
    geom_text(
      aes_string(
        x = 0.75,
        y = 0.6
      ),
      label = sig_out,
      ...
    ) +
    # remove all the background stuff and wrap it with a dashed line
    theme_classic() +
    theme(
      panel.background = element_rect(
        color = "grey",
        linetype = "longdash"
      ),
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      axis.text.y = element_blank(),
      axis.text.x = element_blank()
    )
}

diag_fn <- function(data, mapping, ...){
  p <- ggplot(data = data, mapping = mapping) +
       geom_density()+
       theme(panel.background = element_blank(),
             panel.grid.minor = element_blank(),
             panel.grid.major = element_blank(),
             panel.border = element_blank(),
             axis.line = element_line(color = "black"))
  p
}

lower_fn <- function(data, mapping, ...){
  p <- ggplot(data = data, mapping = mapping) +
       geom_point() +
       geom_smooth(method = lm, se = FALSE, ...) +
       theme(panel.background = element_blank(),
             panel.grid.minor = element_blank(),
             panel.grid.major = element_blank(),
             panel.border = element_blank(),
             axis.line = element_line(color = "black"))
  p
}

pdf("./Plot/Lrp2_logAlbCr.pdf", height = 6, width = 6)
ggpairs(df,
        mapping = aes(color = Age, alpha = 0.2),
        columns = c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U"),
        upper = list (continuous = upper_fn),
        diag = list (continuous = diag_fn),
        lower = list(continuous = lower_fn))
dev.off()

# Test Pearson cor for p-values ---------------------------------------------
# Total
pval <- data.frame( Lrp2_mRNA = integer(),
                    Lrp2_protein = integer(),
                    Log.Alb.Cre.U = integer())
col <- c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U")
for (r in 1:length(col)){
  for (c in 1:length(col)){
      pval[r,c] <- cor.test(df[,(4+r)], df[,(4+c)], alternative = "two.sided", method = "pearson")$p.value
  }
}
rownames(pval) <- col
write.csv(pval, file = "./SpecificQ/Lrp2_logAlbCr_pval.csv", row.names = FALSE, quote = FALSE)

# 6mo.
df6 <- df[df$Age == 6,]
pval <- data.frame( Lrp2_mRNA = integer(),
                    Lrp2_protein = integer(),
                    Log.Alb.Cre.U = integer())
col <- c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U")
for (r in 1:length(col)){
  for (c in 1:length(col)){
      pval[r,c] <- cor.test(df6[,(4+r)], df6[,(4+c)], alternative = "two.sided", method = "pearson")$p.value
  }
}
rownames(pval) <- col
write.csv(pval, file = "./SpecificQ/Lrp2_logAlbCr_pval6.csv", row.names = FALSE, quote = FALSE)

# 12mo.
df12 <- df[df$Age == 12,]
pval <- data.frame( Lrp2_mRNA = integer(),
                    Lrp2_protein = integer(),
                    Log.Alb.Cre.U = integer())
col <- c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U")
for (r in 1:length(col)){
  for (c in 1:length(col)){
      pval[r,c] <- cor.test(df12[,(4+r)], df12[,(4+c)], alternative = "two.sided", method = "pearson")$p.value
  }
}
rownames(pval) <- col
write.csv(pval, file = "./SpecificQ/Lrp2_logAlbCr_pval12.csv", row.names = FALSE, quote = FALSE)

# 18mo.
df18 <- df[df$Age == 18,]
pval <- data.frame( Lrp2_mRNA = integer(),
                    Lrp2_protein = integer(),
                    Log.Alb.Cre.U = integer())
col <- c("Lrp2_mRNA", "Lrp2_protein", "Log.Alb.Cre.U")
for (r in 1:length(col)){
  for (c in 1:length(col)){
      pval[r,c] <- cor.test(df18[,(4+r)], df18[,(4+c)], alternative = "two.sided", method = "pearson")$p.value
  }
}
rownames(pval) <- col
write.csv(pval, file = "./SpecificQ/Lrp2_logAlbCr_pval18.csv", row.names = FALSE, quote = FALSE)
