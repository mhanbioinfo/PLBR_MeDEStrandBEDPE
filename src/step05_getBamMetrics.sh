#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step5_getBamMetrics 
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step5_getBamMetrics.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_BAM -r REFERENCE_FASTA -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Calling Picard CollectMultipleMetrics and CollectGcBiasMetrics QC metrics."
    echo
    echo "Usage: bash step5_getBamMetrics.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_BAM -r REFERENCE_FASTA -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with bam (full path)"
    echo "-b   [REQUIRED]  input bam (full path)"
    echo "-r   [REQUIRED]  reference fasta file (full path)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}

## Get the options
while getopts ":hs:i:b:r:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        b) INPUT_BAM=${OPTARG};;
        r) REF_FASTA_F=${OPTARG};;
        o) OUT_DIR=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

echo "Processing step3_filterBadAlignments..."
echo "Job started at "$(date) 
time1=$(date +%s)

source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual

ALIGNER="BWA"

picard CollectMultipleMetrics \
    R=${REF_FASTA_F} \
    I=${INPUT_DIR}/${INPUT_BAM} \
    O="${OUT_DIR}/${SAMPLE_NAME}.${ALIGNER}" \
    VALIDATION_STRINGENCY=SILENT

picard CollectGcBiasMetrics \
    R=${REF_FASTA_F} \
    I=${INPUT_DIR}/${INPUT_BAM} \
    O="${OUT_DIR}/${SAMPLE_NAME}.${ALIGNER}.gc_bias_metrics.txt" \
    S="${OUT_DIR}/${SAMPLE_NAME}.${ALIGNER}.summary_gc_bias_metrics.txt" \
    CHART="${OUT_DIR}/${SAMPLE_NAME}.${ALIGNER}.gc_bias_metrics.pdf"

echo "Finished processing picard CollectMultipleMetrics and CollectGcBiasMetrics." 

time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"
echo ""

## EOF
