#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 5-00:00:00
#SBATCH -D ./
#SBATCH --mem=1G
#SBATCH -J run_MeDEStrandBEDPE_fromBEDPEs
#SBATCH -p all
#SBATCH -c 1
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err


# getopts ###################################################

usage(){
    echo 
    echo "Usage: bash run_MeDEStrandBEDPE_fromBEDPEs_makeBatchScripts.sh -s SAMPLESHEET_PATH -p PROJ_DIR -w WINDOW_SIZE -l SLURM_OR_LOCAL -c CHR_SELECT_F -x SRC_DIR -t KEEP_TMP" 
    echo 
}
no_args="true"

## Help 
Help()
{
    # Display Help
    echo 
    echo "Write out batch script for each sample and run MeDEStrandBEDPE with BEDPEs as input."
    echo
    echo "Usage: bash run_MeDEStrandBEDPE_fromBEDPEs_makeBatchScripts.sh -s SAMPLESHEET_PATH -p PROJ_DIR -w WINDOW_SIZE -l SLURM_OR_LOCAL -c CHR_SELECT_F -x SRC_DIR -t KEEP_TMP"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-s   [REQUIRED]  samplesheet.csv (full path)"
    echo "-p   [REQUIRED]  project directory for writing outputs to (full path)"
    echo "-w   [REQUIRED]  window size (e.g. 200)"
    echo "-l   [REQUIRED]  run pipeline on HPC or local (slurm or local)"
    echo "-c   [REQUIRED]  file for selecting which chromosomes to process (full path)"
    echo "-x   [REQUIRED]  src directory with pipeline scripts (full path)"
    echo "-t   [REQUIRED]  keep tmp_dir (true or false)"
    echo
}

## Get the options
while getopts ":hs:p:w:l:c:x:t:" option; do
    case "${option}" in
        h) Help
           exit;;
        s) SAMPLESHEET_PATH=${OPTARG};;
        p) PROJ_DIR=${OPTARG};;
        w) WINDOW_SIZE=${OPTARG};;
        l) SLURM_OR_LOCAL=${OPTARG};;
        c) CHR_SELECT_F=${OPTARG};;
        x) SRC_DIR=${OPTARG};;
        t) KEEP_TMP=${OPTARG};;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }


# Main program ##############################################

echo "Creating lean bedpe output directory."
LEANBEDPE_OUT_DIR=${PROJ_DIR}/bedpelean_out
mkdir -p ${LEANBEDPE_OUT_DIR}
echo "Creating MeDEStrand output directory."
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

## write out batch script for each sample ###################

echo ""
OLDIFS=$IFS
IFS=','
[ ! -f $SAMPLESHEET_PATH ] && { echo "$SAMPLESHEET_PATH file not found"; exit 99; }
sed 1d $SAMPLESHEET_PATH | \
while read -r SAMPLE_NAME BEDPE_GZ_PATH; do
    echo "Processing sample: ${SAMPLE_NAME} ..."
    
    ## get .bedpe.gz filename
    BEDPE_GZ_FNAME=${BEDPE_GZ_PATH##*/}
    
    ## get .bedpe.gz directory
    BEDPE_GZ_DIR=${BEDPE_GZ_PATH%/*}
    
    echo "Writing out '${SAMPLE_NAME}_sbatch_script.sh'"
    echo ""
    ## write out '{samplename}_sbatch_script.sh'
    cat <<- EOF > "${SLURM_SCRIPTS_DIR}/${SAMPLE_NAME}_sbatch_script.sh"
	#!/bin/bash
	#SBATCH -t 3-00:00:00
	#SBATCH -J cfMeDIP_MeDEStrandBEDPE_${SAMPLE_NAME}
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
	
	echo "Processing MeDEStrandBEDPE for ${SAMPLE_NAME}"
	
	source /cluster/home/t110409uhn/bin/miniconda3/bin/activate wf_cfmedip_manual
	
	SAMPLE_NAME="${SAMPLE_NAME//-/_}"
	INPUT_DIR="${BEDPE_GZ_DIR}"
	OUT_DIR="${PROJ_DIR}"
	LEANBEDPE_OUT_DIR="${LEANBEDPE_OUT_DIR}"
	MEDE_OUT_DIR="${MEDE_OUT_DIR}"
	SRC_DIR="${SRC_DIR}"
	QC_METRICS_DIR="${QC_METRICS_DIR}"
	
	SLURM_OR_LOCAL="${SLURM_OR_LOCAL}"
	KEEP_TMP_SAMPLE_DIR="${KEEP_TMP}"
	
	CHR_SELECT_F="${CHR_SELECT_F}"
	WINDOW_SIZE=${WINDOW_SIZE}
	
	BEDPE_GZ_FNAME="${BEDPE_GZ_FNAME}"
	LEAN_BEDPE_GZ="\${BEDPE_GZ_FNAME%.bedpe.gz}_4mede_chrSelect.bedpe"
	
	## Process .bedpe into a lean .bedpe for input into MeDEStrandBEDPE R package
	bash \${SRC_DIR}/step09_bedpe2leanbedpe_for_MeDEStrand.sh -i \${INPUT_DIR} -b \${BEDPE_GZ_FNAME} -c \${CHR_SELECT_F} -o \${LEANBEDPE_OUT_DIR} -t
	
	## Run MeDEStrand package with .bedpe input
	bash \${SRC_DIR}/step10_runMeDEStrandBEDPE.sh -s \${SAMPLE_NAME} -i \${LEANBEDPE_OUT_DIR} -b \${LEAN_BEDPE_GZ} -r \${SRC_DIR} -w \${WINDOW_SIZE} -o \${MEDE_OUT_DIR}
	
	time2=\$(date +%s)
	echo "Job ended at "\$(date) 
	echo "Job took \$(((time2-time1)/3600)) hours \$((((time2-time1)%3600)/60)) minutes \$(((time2-time1)%60)) seconds"
	
	EOF
done
echo "Finished writing all scripts."


## sbatch batch scripts for each sample ###################

echo ""
if [ "$SLURM_OR_LOCAL" = "slurm" ]; then
    echo "sbatch all sbatch_script.sh"
    for sbatch_script in ${SLURM_SCRIPTS_DIR}/*; do
        echo "${sbatch_script##*/}"
        sbatch ${sbatch_script}
    done
elif [ "$SLURM_OR_LOCAL" = "local" ]; then
    echo "bash all sbatch_script.sh"
    for sbatch_script in ${SLURM_SCRIPTS_DIR}/*; do
        echo "${sbatch_script##*/}"
        bash ${sbatch_script}
    done
fi

echo "Finished processing pipeline."

IFS=$OLDIFS
## EOF

