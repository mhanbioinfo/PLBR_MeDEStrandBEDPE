#Adapted from: https://github.com/oicr-gsi/wf_cfmedip
#Adapted from: https://github.com/AdaZED/medestrand/blob/master/medestrand_counts_generator.R
library(docopt)

doc <- "Usage:
MeDEStrandBEDPE.r --inputFile <FILE> --outputFile <FILE> --windowSize <SIZE> --chr_select <CHRS>

--inputFile FILE     Aligned, sorted, filtered bam, or bedpelean
--outputFile FILE    Bedgraph methylation profile
--windowSize SIZE    Size of genomic windows for methylation profiling
--chr_select CHRS    Chromosomes to analyze
--help               show this help text"
opt <- docopt(doc)

#if (!file.exists(opt$inputFile)){
#  stop(paste0("bam or bedpe file not found ",opt$inputFile), call.=FALSE)
#}
#if (!file.exists(opt$outputDir)){
#  dir.create(opt$outputDir)
#}

library(MeDEStrandBEDPE)
library("BSgenome.Hsapiens.UCSC.hg38")
library(GenomicRanges)

args=(commandArgs(TRUE))

# Retrieve user parameters
sample <- opt$inputFile
output <- opt$outputFile
ws <- as.numeric(opt$windowSize)
paired <- TRUE

#  Adapted from: https://github.com/jxu1234/MeDEStrand/blob/master/R/MeDEStrand.createSet.R
#  The original function  uses hardcoded hg19; here, we switch to hg38
MeDEStrand.binMethyl_hg38 <- function(MSetInput=NULL, CSet=NULL, ccObj=NULL, Granges = FALSE){
  for (i in 1:2) {
    if(is.list(MSetInput)){
      MSet=MSetInput[[i]]
    }
    signal =  genome_count(MSet)
    coupling = genome_CF(CSet)
    ccObj = MeDEStrand.calibrationCurve(MSet=MSet, CSet=CSet, input=F)
    index.max = which(ccObj$mean_signal== max(ccObj$mean_signal[1:ccObj$max_index]))
    MS = ccObj$mean_signal[1:index.max]
    CF = ccObj$coupling_level[1:index.max]
    model.data = data.frame( model.MS =  MS/max( MS), model.CF = CF)
    logistic.fit = glm(model.MS ~ model.CF, family=binomial(logit), data = model.data)
    if (i == 1) { cat("Estimating and correcting CG bias for reads mapped to the DNA positive strand...\n") }
    if (i == 2) { cat("Estimating and correcting CG bias for reads mapped to the DNA negative strand...\n") }
    estim=numeric(length(ccObj$mean_signal))  # all 0's
    low_range=1:index.max
    estim[low_range]=ccObj$mean_signal[low_range]
    high_range = ( length(low_range)+1 ):length(estim)
    y.predict = predict(logistic.fit, 
                        data.frame(model.CF = ccObj$coupling_level[high_range]), 
                        type ="response")*ccObj$mean_signal[ccObj$max_index]
    estim[high_range] = y.predict
    signal=signal/estim[coupling+1]
    signal[coupling==0]=0
    signal = log2(signal)
    signal[is.na(signal)] = 0
    minsignal=min(signal[signal!=-Inf])
    signal[signal!=-Inf]=signal[signal!=-Inf]+abs(minsignal)
    maxsignal = quantile(signal[signal!=Inf], 0.9995  )
    signal[signal!=Inf & signal>maxsignal]=maxsignal
    signal=round((signal/maxsignal), digits=2)
    signal[signal==-Inf | signal ==Inf]=0
    if (i == 1) {pos.signal = signal}
    if (i == 2) {neg.signal = signal}
  }
  merged.signal = (pos.signal+neg.signal)/2
  if(!Granges) {
    return(merged.signal)}else{
      chr.select = MSet@chr_names
      window_size = window_size(MSet)
      chr_lengths=unname(seqlengths(BSgenome.Hsapiens.UCSC.hg38)[ seqnames(BSgenome.Hsapiens.UCSC.hg38@seqinfo)%in%chr.select])
      no_chr_windows = ceiling(chr_lengths/window_size)
      supersize_chr = cumsum(no_chr_windows)
      chromosomes=chr.select
      all.Granges.genomeVec = MEDIPS.GenomicCoordinates(supersize_chr, no_chr_windows, chromosomes, chr_lengths, window_size)
      all.Granges.genomeVec$CF = CS@genome_CF
      all.Granges.genomeVec$binMethyl= merged.signal
      return( all.Granges.genomeVec )
    }
}

# Disables the scientific notation to avoid powers in genomic coordinates (i.e. 1e+10)
options(scipen = 999)

# Set global variables for importing short reads. For details, in R console, type "?MeDEStrand.createSet"
BSgenome="BSgenome.Hsapiens.UCSC.hg38"
uniq = 1
extend = 200
shift = 0
## { change this later to be dynamic }
chr.select = strsplit(opt$chr_select, " ")[[1]]
print(chr.select)
#chr.select = paste0("chr", c(1:22,"X","Y"))

#fname <- unlist(strsplit(basename(opt$inputFile),split="\\."))[1]
#df_for_wig <- NULL
#bed_wig_output <- paste0(opt$outputDir,"/MeDEStrand_hg38_",fname,"_ws",ws,"_wig.bed")

output_df = NULL

tryCatch({
  
  # Create a MeDIP set
  MeDIP_seq = MeDEStrand.createSet(file=opt$inputFile, BSgenome=BSgenome, extend=extend, shift=shift, uniq=uniq, window_size=ws, chr.select=chr.select, paired=paired)
  
  #  Count CpG pattern in the bins
  CS = MeDEStrand.countCG(pattern="CG", refObj=MeDIP_seq)
  
  # Infer genome-wide absolute methylation levels:
  #result.methylation = MeDEStrand.binMethyl(MSetInput = MeDIP_seq, CSet = CS, Granges = TRUE)
  result.methylation = MeDEStrand.binMethyl_hg38(MSetInput = MeDIP_seq, CSet = CS, Granges = TRUE)
  
  # Create a dataframe from the previous GRanges object.
  # Warning: GRanges and UCSC BED files use different conventions for the genomic coordinates
  # GRanges use 1-based intervals (chr1:2-8 means the 2nd till and including the 8th base of chr1, i.e. a range of length of 7 bases)
  # UCSC bed-files use 0-based coordinates (chr1:2-8 means the 3rd base till and including the 8th base, i.e. a range of length of 6 bases)
  
  # Dataframe for generating a bed file used to generate then a wig file
  output_df <- data.frame(seqnames=seqnames(result.methylation),
                          starts=start(result.methylation)-1,
                          ends=end(result.methylation),
                          scores=elementMetadata(result.methylation)$binMethyl)

}, error = function(e){
  message("Error: MeDEStrand CpG density normalization failed due to small number of reads")
})

write.table(output_df, file = output, quote=F, sep="\t", row.names=F, col.names=F)

## EOF
