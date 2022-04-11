#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step10_runMeDEStrandBEDPE
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step10_runMeDEStrandBEDPE.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_FILE -r RSCRIPTS_DIR -w WINDOW_SIZE -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{ 
    # Display Help
    echo 
    echo "Run MeDEStrand package."
    echo
    echo "Usage: step10_runMeDEStrandBEDPE.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_FILE -r RSCRIPTS_DIR -w WINDOW_SIZE -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with bam or lean.bedpe.gz (full path)"
    echo "-b   [REQUIRED]  .bam or lean version of .bedpe.gz ready for input into MeDEStrandBEDPE (filename)"
    echo "-r   [REQUIRED]  R script directory with R script for running MeDEStrandBEDPE"
    echo "-w   [REQUIRED]  window size (e.g. 200)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo
}

## Get the options
while getopts ":hs:i:b:r:w:o:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLE_NAME=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        b) INPUT_FILE=${OPTARG};;
        r) RSCRIPTS_DIR=${OPTARG};;
        w) WINDOW_SIZE=${OPTARG};;
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

echo "Processing step10_runMeDEStrandBEDPE... " 

source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual

Rscript ${RSCRIPTS_DIR}/MeDEStrandBEDPE.r \
    --inputFile ${INPUT_DIR}/${INPUT_FILE} \
    --outputDir ${OUT_DIR}/ \
    --windowSize ${WINDOW_SIZE}

echo "Finished processing running MeDEStrand."


time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"

## EOF
