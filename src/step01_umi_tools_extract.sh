#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step1_umi_tools_extract
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step1_umi_tools_extract.sh -s SAMPLE_NAME -i INPUT_DIR -f FASTQ_R1 -g FASTQ_R2 -u UMI1_PATTERN -v UMI2_PATTERN -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Using UMI-tools to extract out UMI from FASTQ reads and place it in FASTQ header."
    echo
    echo "Usage: bash step1_umi_tools_extract.sh -s SAMPLE_NAME -i INPUT_DIR -f FASTQ_R1 -g FASTQ_R2 -u UMI1_PATTERN -v UMI2_PATTERN -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with fastqs (full path)"
    echo "-f   [REQUIRED]  filename of FASTQ R1"
    echo "-g   [REQUIRED]  filename of FASTQ R2"
    echo "-u   [REQUIRED]  UMI1 pattern, 3 UMI + 2 linker (e.g. NNNNN)"
    echo "-v   [REQUIRED]  UMI2 pattern, 3 UMI + 2 linker (e.g. NNNNN)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}
## Get the options
while getopts ":hs:i:f:g:u:v:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        f) FASTQ_R1_F=${OPTARG};;
        g) FASTQ_R2_F=${OPTARG};;
        u) UMI1_PATTERN=${OPTARG};;
        v) UMI2_PATTERN=${OPTARG};;
        o) OUT_DIR=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

echo "Processing umi_tools UMI extraction... " 
echo "Job started at "$(date) 
time1=$(date +%s)

#source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual

R1_EXTRACTED_F="${SAMPLE_NAME}.R1.umiExtd.fq.gz"
R2_EXTRACTED_F="${SAMPLE_NAME}.R2.umiExtd.fq.gz"

umi_tools extract \
    --extract-method=string \
    --bc-pattern=${UMI1_PATTERN} \
    --bc-pattern2=${UMI2_PATTERN} \
    -I ${INPUT_DIR}/${FASTQ_R1_F} \
    --read2-in=${INPUT_DIR}/${FASTQ_R2_F} \
    -S ${OUT_DIR}/${R1_EXTRACTED_F} \
    --read2-out=${OUT_DIR}/${R2_EXTRACTED_F}

#    -L extract.log \

echo "Finished processing umi_tools UMI extraction."


time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"
echo ""

## EOF
