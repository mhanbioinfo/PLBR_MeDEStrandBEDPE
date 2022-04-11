#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=32G
#SBATCH -J step4_removeDuplicates 
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step4_removeDuplicates.sh -s SAMPLE_NAME -i INPUT_DIR -b FILT_BAM -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Remove duplicates based on UMI extracted with UMI-tools."
    echo
    echo "Usage: bash step4_removeDuplicates.sh -s SAMPLE_NAME -i INPUT_DIR -b FILT_BAM -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with bam (full path)"
    echo "-b   [REQUIRED]  filtered bam (full path)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}

## Get the options
while getopts ":hs:i:b:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        b) BAM_FILT3=${OPTARG};;
        o) OUT_DIR=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

echo "Job started at "$(date) 
time1=$(date +%s)

#source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual

UMI_DEDUP="${BAM_FILT3%.*}.dedup.bam"

echo "Processing step4_removeDuplicates..." 

samtools index ${INPUT_DIR}/${BAM_FILT3}

umi_tools dedup --paired \
    -I ${INPUT_DIR}/${BAM_FILT3} \
    -S ${OUT_DIR}/${UMI_DEDUP} \
    --output-stats=${OUT_DIR}/deduplicated 

echo "Finished processing removing UMI based duplicates."


time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"

## EOF
