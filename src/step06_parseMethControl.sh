#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J step6_parseMethControl 
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash step6_parseMethControl.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_BAM -o OUT_DIR" 
    echo 
}
no_args="true"

## Help 
Help()
{   
    # Display Help
    echo 
    echo "Parse methylation control QC metrics from UMI deduplicated bam file."
    echo
    echo "Usage: bash step6_parseMethControl.sh -s SAMPLE_NAME -i INPUT_DIR -b INPUT_BAM -o OUT_DIR"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  short and unique sample name without file extensions"
    echo "-i   [REQUIRED]  input directory with bam (full path)"
    echo "-b   [REQUIRED]  input bam (full path)"
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
        b) INPUT_BAM=${OPTARG};;
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

SEQMETH="F19K16"
SEQUMETH="F24B22"
QC_METRICS_DIR="${OUT_DIR}/QC_metrics"
mkdir -p ${QC_METRICS_DIR}

echo "Processing step6_parseMethControl..." 

samtools view ${INPUT_DIR}/${INPUT_BAM} | \
    cut -f 3 | sort | uniq -c | sort -nr | \
    sed -e 's/^ *//;s/ /\t/' | \
    awk 'OFS="\t" {print $2,$1}' | \
    sort -n -k1,1 \
    > ${QC_METRICS_DIR}/meth_ctrl.counts

total=$(samtools view ${INPUT_DIR}/${INPUT_BAM} | wc -l)
unmap=$(cat ${QC_METRICS_DIR}/meth_ctrl.counts | grep '^\*' | cut -f2); if [[ -z $unmap ]]; then unmap="0"; fi
methyl=$(cat ${QC_METRICS_DIR}/meth_ctrl.counts | grep ${SEQMETH} | cut -f2); if [[ -z $methyl ]]; then methyl="0"; fi
unmeth=$(cat ${QC_METRICS_DIR}/meth_ctrl.counts | grep ${SEQUMETH} | cut -f2); if [[ -z $unmeth ]]; then unmeth="0"; fi
pct_meth_ctrl=$(echo "scale=3; ($methyl + $unmeth)/$total * 100" | bc -l); if [[ -z $pct_meth_ctrl ]]; then pct_meth_ctrl="0"; fi
bet_meth_ctrl=$(echo "scale=3; $methyl/($methyl + $unmeth)" | bc -l); if [[ -z $bet_meth_ctrl ]]; then bet_meth_ctrl="0"; fi
echo -e "total\tunmap\tmethyl\tunmeth\tPCT_METH_CTRL\tMETH_CTRL_BETA" > ${QC_METRICS_DIR}/meth_ctrl_summary.txt
echo -e "$total\t$unmap\t$methyl\t$unmeth\t$pct_meth_ctrl\t$bet_meth_ctrl" >> ${QC_METRICS_DIR}/meth_ctrl_summary.txt

echo "Finished processing parsing methylation controls."


time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"

## EOF
