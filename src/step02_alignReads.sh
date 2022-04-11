#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step2_alignReads 
#SBATCH -p himem
#SBATCH -c 8
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step2_alignReads.sh -s SAMPLE_NAME -i INPUT_DIR -f FASTQ_R1 -g FASTQ_R2 -r REFERENCE -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Align reads using bwa mem."
    echo
    echo "Usage: bash step2_alignReads.sh -s SAMPLE_NAME -i INPUT_DIR -f FASTQ_R1 -g FASTQ_R2 -r REFERENCE -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with fastqs (full path)"
    echo "-f   [REQUIRED]  filename of FASTQ R1"
    echo "-g   [REQUIRED]  filename of FASTQ R2"
    echo "-r   [REQUIRED]  REFERENCE BWA INDEX (full path)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}

## Get the options
while getopts ":hs:i:f:g:r:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        f) FASTQ_R1_F=${OPTARG};;
        g) FASTQ_R2_F=${OPTARG};;
        r) REF_BWA=${OPTARG};;
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

BWA_MAPPED_SAM="${SAMPLE_NAME}.bwa.sam"
BAM_F="${SAMPLE_NAME}.bwa.bam"

echo "Processing step2_alignReads..." 

bwa mem -t 8 \
    ${REF_BWA} \
    ${INPUT_DIR}/${FASTQ_R1_F} \
    ${INPUT_DIR}/${FASTQ_R2_F} \
    > ${OUT_DIR}/${BWA_MAPPED_SAM}

samtools view -b \
    ${INPUT_DIR}/${BWA_MAPPED_SAM} | \
    samtools sort \
    -o ${OUT_DIR}/${BAM_F}

echo "Finished processing bwa alignReads."


time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"

## EOF
