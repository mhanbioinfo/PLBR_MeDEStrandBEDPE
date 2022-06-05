#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step7_getFilterMetrics
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step7_getFilterMetrics.sh -s SAMPLE_NAME -i INPUT_DIR -t TMP_DIR -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{   
    # Display Help
    echo 
    echo "Get how many reads were removed during each filtering step."
    echo
    echo "Usage: bash step7_getFilterMetrics.sh -s SAMPLE_NAME -i INPUT_DIR -t TMP_DIR -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with bam (full path)"
    echo "-t   [REQUIRED]  temp directory with files needed for QC metrics"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}

## Get the options
while getopts ":hs:i:t:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        t) TMP_DIR=${OPTARG};;
        o) OUT_DIR=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

echo "Processing step7_getFilterMetrics..." 
echo "Job started at "$(date) 
time1=$(date +%s)

#source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual

R1_EXTRACTED_F="${SAMPLE_NAME}.R1.umiExtd.fq.gz"
BAM_F="${SAMPLE_NAME}.bam"
BAM_FILT1="${BAM_F%.*}.filter1.bam"
BAM_FILT2="${BAM_F%.*}.filter2.bam"
BAM_FILT3="${BAM_F%.*}.filter3.bam"
UMI_DEDUP="${BAM_FILT3%.*}.dedup.bam"

total=`echo "$(zcat ${TMP_DIR}/${R1_EXTRACTED_F} | wc -l)/2" | bc`
filter1=$(samtools view ${TMP_DIR}/${BAM_FILT1} | wc -l)
filter2=$(samtools view ${TMP_DIR}/${BAM_FILT2} | wc -l)
filter3=$(samtools view ${TMP_DIR}/${BAM_FILT3} | wc -l)
dedup=$(samtools view ${INPUT_DIR}/${UMI_DEDUP} | wc -l)
echo -e "total\tfilter1\tfilter2\tfilter3\tdedup" > ${OUT_DIR}/filter_metrics.txt
echo -e "$total\t$filter1\t$filter2\t$filter3\t$dedup" >> ${OUT_DIR}/filter_metrics.txt

echo "Finished processing getting filtering metrics."

time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"
echo ""

## EOF
