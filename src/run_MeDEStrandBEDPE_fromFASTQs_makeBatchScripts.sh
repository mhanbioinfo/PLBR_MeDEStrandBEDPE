#!/bin/bash

# getopts ###################################################

usage(){
    echo 
    echo "Usage: bash run_MeDEStrandBEDPE_fromFASTQs_makeBatchScripts.sh -s SAMPLESHEET_PATH -p PROJ_DIR -u UMI1_PATTERN -v UMI2_PATTERN -r REF_BWA -f REF_FASTA_F -w WINDOW_SIZE -c CHR_SELECT_F" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Write out batch script for each sample and run MeDEStrandBEDPE with FASTQs as input."
    echo
    echo "Usage: bash run_MeDEStrandBEDPE_fromFASTQs_makeBatchScripts.sh -s SAMPLESHEET_PATH -p PROJ_DIR -u UMI1_PATTERN -v UMI2_PATTERN -r REF_BWA -f REF_FASTA_F -w WINDOW_SIZE -c CHR_SELECT_F"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  samplesheet.csv (full path)"
    echo "-p   [REQUIRED]  project directory for writing outputs to (full path)"
    echo "-u   [REQUIRED]  UMI1 pattern, 3 UMI + 2 linker (e.g. NNNNN)"
    echo "-v   [REQUIRED]  UMI2 pattern, 3 UMI + 2 linker (e.g. NNNNN)"
    echo "-r   [REQUIRED]  hg38 and F19K16_F24B22 BWA index reference (full path)" 
    echo "-f   [REQUIRED]  hg38 and F19K16_F24B22 concatenated fasta (full path)"
    echo "-w   [REQUIRED]  window size (e.g. 200)"
    echo "-c   [REQUIRED]  file for selecting which chromosomes to process (full path)"
    echo
}

## Get the options
while getopts ":hs:p:u:v:r:f:w:c:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLESHEET_PATH=${OPTARG};;
        p) PROJ_DIR=${OPTARG};;
        u) UMI1_PATTERN=${OPTARG};;
        v) UMI2_PATTERN=${OPTARG};;
        r) REF_BWA=${OPTARG};;
        f) REF_FASTA_F=${OPTARG};;
        w) WINDOW_SIZE=${OPTARG};;
        c) CHR_SELECT_F=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

### define these in config.yml later
#PROJ_DIR="/cluster/projects/pughlab/projects/cfMeDIP_compare_pipelines/cfmedip_medestrand_bedpe/try08_multipleSamples"
#SAMPLESHEET_PATH="/cluster/projects/pughlab/projects/cfMeDIP_compare_pipelines/cfmedip_medestrand_bedpe/try08_multipleSamples/samplesheet_MeDEStrandBEDPE_test1.csv"
#
#UMI1_PATTERN="NNNNN"
#UMI2_PATTERN="NNNNN"
##REF_BWA="/cluster/projects/pughlab/projects/ezhao/assets/reference/genomes/hg38_arabidopsis_chr_1_3/BWA_index/hg38_arabidopsis"
#REF_BWA="/cluster/projects/pughlab/references/cfMeDIPseq_refs/hg38_F19K16_F24B22/BWA_index/hg38_F19K16_F24B22"
##REF_FASTA_F="/cluster/projects/pughlab/projects/ezhao/assets/reference/genomes/hg38_arabidopsis_chr_1_3/hg38_arabidopsis_chr_1_3.fa"
#REF_FASTA_F="/cluster/projects/pughlab/references/cfMeDIPseq_refs/hg38_F19K16_F24B22/hg38_F19K16_F24B22.fa"
#CHR_SELECT_F="/cluster/projects/pughlab/projects/cfMeDIP_compare_pipelines/cfmedip_medestrand_bedpe/scripts/src/chr_select.txt"
#WINDOW_SIZE=200

SRC_DIR="$(pwd)/src"
echo "Creating tmp/ in project directory."
TMP_DIR=${PROJ_DIR}/tmp
mkdir -p ${TMP_DIR}
echo "Creating BAM output directory."
BAM_OUT_DIR=${PROJ_DIR}/bam_out
mkdir -p ${BAM_OUT_DIR}
echo "Creating BEDPE output directory."
BEDPE_OUT_DIR=${PROJ_DIR}/bedpe_out
mkdir -p ${BEDPE_OUT_DIR}
echo "Creating MeDEStrand output directory."
LEANBEDPE_OUT_DIR=${PROJ_DIR}/bedpelean_out
mkdir -p ${LEANBEDPE_OUT_DIR}
MEDE_OUT_DIR=${PROJ_DIR}/medestrand_out
mkdir -p ${MEDE_OUT_DIR}
echo "Creating QC metrics directory."
QC_METRICS_DIR=${PROJ_DIR}/QC_metrics
mkdir -p ${QC_METRICS_DIR}

## make sbatch script directory for sbatch scripts for all samples
echo "Creating slurm script directory."
SLURM_SCRIPTS_DIR="${PROJ_DIR}/slurm_scripts"
mkdir -p ${SLURM_SCRIPTS_DIR}
echo "Creating slurm log directory."
SLURM_LOG_DIR="${PROJ_DIR}/slurm_log"
mkdir -p ${SLURM_LOG_DIR}

echo ""
OLDIFS=$IFS
IFS=','
[ ! -f $SAMPLESHEET_PATH ] && { echo "$SAMPLESHEET_PATH file not found"; exit 99; }
sed 1d $SAMPLESHEET_PATH | \
while read -r SAMPLE_NAME_R1 PATH_R1; do
    echo "Processing sample: ${SAMPLE_NAME_R1} ..."
    
    ## read 2 lines at once for R1 and R2
    read -r SAMPLE_NAME_R2 PATH_R2
    
    ## get fastq name only
    R1_FASTQ_FNAME=${PATH_R1##*/}
    R2_FASTQ_FNAME=${PATH_R2##*/}
    
    ## get fastq directory
    R1_FASTQ_DIR=${PATH_R1%/*}
    
    echo "Writing out '${SAMPLE_NAME_R1}_sbatch_script.sh'"
    echo ""
    ## write out '{samplename}_sbatch_script.sh'
    cat <<- EOF > "${SLURM_SCRIPTS_DIR}/${SAMPLE_NAME_R1}_sbatch_script.sh"
	#!/bin/bash
	#SBATCH -t 3-00:00:00
	#SBATCH -J cfMeDIP_MeDEStrandBEDPE_${SAMPLE_NAME_R1}
	#SBATCH -D ${SLURM_LOG_DIR}	
	#SBATCH --mail-type=ALL
	#SBATCH --mail-user=ming.han@uhn.ca
	#SBATCH -p himem
	#SBATCH -c 4
	#SBATCH --mem=60G
	#SBATCH -o ./%j-%x.out
	#SBATCH -e ./%j-%x.err
	
	echo "Job started at "\$(date) 
	time1=\$(date +%s)
	
	source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual
	
	SAMPLE_NAME="${SAMPLE_NAME_R1//-/_}"
	INPUT_DIR="${R1_FASTQ_DIR}"
	OUT_DIR="${PROJ_DIR}"
	BAM_OUT_DIR="${BAM_OUT_DIR}"
	BEDPE_OUT_DIR="${BEDPE_OUT_DIR}"
	LEANBEDPE_OUT_DIR="${LEANBEDPE_OUT_DIR}"
	MEDE_OUT_DIR="${MEDE_OUT_DIR}"
	SRC_DIR="${SRC_DIR}"
	TMP_SAMPLE_DIR="${TMP_DIR}/\${SAMPLE_NAME}"
	mkdir -p "\${TMP_SAMPLE_DIR}"
	QC_METRICS_DIR="${QC_METRICS_DIR}"
	
	FASTQ_R1_F="${R1_FASTQ_FNAME}"
	FASTQ_R2_F="${R2_FASTQ_FNAME}"
	UMI1_PATTERN="${UMI1_PATTERN}"
	UMI2_PATTERN="${UMI2_PATTERN}"
	REF_BWA="${REF_BWA}"
	REF_FASTA_F="${REF_FASTA_F}"
	CHR_SELECT_F="${CHR_SELECT_F}"
	WINDOW_SIZE=${WINDOW_SIZE}
	
	R1_EXTRACTED_F="\${SAMPLE_NAME}.R1.umiExtd.fq.gz"
	R2_EXTRACTED_F="\${SAMPLE_NAME}.R2.umiExtd.fq.gz"
	BAM_F="\${SAMPLE_NAME}.bwa.bam"
	BAM_FILT3="\${BAM_F%.*}.filter3.bam"
	UMI_DEDUP="\${BAM_FILT3%.*}.dedup.bam"
	BEDPE_GZ_FNAME="\${UMI_DEDUP%.*}_coordSortd.bedpe.gz"
	LEAN_BEDPE_GZ="\${BEDPE_GZ_FNAME%.bedpe.gz}_4mede_chrSelect.bedpe"
	
	## UMI-tools extract
	bash \${SRC_DIR}/step01_umi_tools_extract.sh -s \${SAMPLE_NAME} -i \${INPUT_DIR} -f \${FASTQ_R1_F} -g \${FASTQ_R2_F} -u \${UMI1_PATTERN} -v \${UMI2_PATTERN} -o \${TMP_SAMPLE_DIR}
	
	## bwa alignReads
	bash \${SRC_DIR}/step02_alignReads.sh -s \${SAMPLE_NAME} -i \${TMP_SAMPLE_DIR} -f \${R1_EXTRACTED_F} -g \${R2_EXTRACTED_F} -r \${REF_BWA} -o \${TMP_SAMPLE_DIR}
	
	## filter out bad alignments
	bash \${SRC_DIR}/step03_filterBadAlignments.sh -s \${SAMPLE_NAME} -i \${TMP_SAMPLE_DIR} -b \${BAM_F} -o \${TMP_SAMPLE_DIR}
	
	## Remove duplicates based on UMI extracted with UMI-tools
	bash \${SRC_DIR}/step04_removeDuplicates.sh -s \${SAMPLE_NAME} -i \${TMP_SAMPLE_DIR} -b \${BAM_FILT3} -o \${BAM_OUT_DIR}
	
	## Calling Picard CollectMultipleMetrics and CollectGcBiasMetrics get QC metrics
	bash \${SRC_DIR}/step05_getBamMetrics.sh -s \${SAMPLE_NAME} -i \${BAM_OUT_DIR} -b \${UMI_DEDUP} -r \${REF_FASTA_F} -o \${QC_METRICS_DIR}
	
	## Parse methylation control QC metrics from UMI deduplicated bam file
	bash \${SRC_DIR}/step06_parseMethControl.sh -s \${SAMPLE_NAME} -i \${BAM_OUT_DIR} -b \${UMI_DEDUP} -o \${QC_METRICS_DIR}
	
	## Get how many reads were removed during each filtering step
	bash \${SRC_DIR}/step07_getFilterMetrics.sh -s \${SAMPLE_NAME} -i \${BAM_OUT_DIR} -o \${QC_METRICS_DIR}
	
	## Processes bam to bedpe in chunks, preserving FLAG and TLEN info
	bash \${SRC_DIR}/step08_bam2bedpe.sh -s slurm -c 25 -b \${BAM_OUT_DIR}/\${UMI_DEDUP} -o \${BEDPE_OUT_DIR}
	
	## Process .bedpe into a lean .bedpe for input into MeDEStrandBEDPE R package
	bash \${SRC_DIR}/step09_bedpe2leanbedpe_for_MeDEStrand.sh -i \${BEDPE_OUT_DIR} -b \${BEDPE_GZ_FNAME} -c \${CHR_SELECT_F} -o \${LEANBEDPE_OUT_DIR} -t
	
	## Run MeDEStrand package with .bedpe input
	bash \${SRC_DIR}/step10_runMeDEStrandBEDPE.sh -s \${SAMPLE_NAME} -i \${LEANBEDPE_OUT_DIR} -b \${LEAN_BEDPE_GZ} -r \${SRC_DIR} -w \${WINDOW_SIZE} -o \${MEDE_OUT_DIR}
	
	## Run MeDEStrand package with .bam input
	bash \${SRC_DIR}/step10_runMeDEStrandBEDPE.sh -s \${SAMPLE_NAME} -i \${BAM_OUT_DIR} -b \${UMI_DEDUP} -r \${SRC_DIR} -w \${WINDOW_SIZE} -o \${TMP_SAMPLE_DIR}	
	
	## remove tmp_sample, bam_out etc if specified in config.yml
	
	
	
	
	
	
	
	
	
	time2=\$(date +%s)
	echo "Job ended at "\$(date) 
	echo "Job took \$(((time2-time1)/3600)) hours \$((((time2-time1)%3600)/60)) minutes \$(((time2-time1)%60)) seconds"
	
	EOF

done
IFS=$OLDIFS


echo "Finished writing all scripts."

## EOF

