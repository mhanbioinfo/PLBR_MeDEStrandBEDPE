#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 1-00:00:00
#SBATCH -D ./logs_slurm/
#SBATCH --mem=60G
#SBATCH -J bedpe2leanbedpe_for_MeDEStrand
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o %j-%x.out
#SBATCH -e %j-%x.err

# getopts ###################################################
usage(){
    echo 
    echo "Usage: bash bedpe2leanbedpe_for_MeDEStrand.sh -i input_directory -b full_bedpe_gz_filename -c [chromosome_select_file] -o output_directory -s [keep_secondary_reads] -t [keep_tmp/bedpe2leanbedpe]" 
    echo 
}
no_args="true"
KEEP_TMP=false
KEEP_SECONDARY_READS=false

## Help 
Help()
{
    # Display Help
    echo 
    echo "Process .bedpe into a lean .bedpe for input into MeDEStrandBEDPE R package."
    echo
    echo "Usage: Usage: bash bedpe2leanbedpe_for_MeDEStrand.sh -i input_directory -b full_bedpe_gz_filename -c [chromosome_select_file] -o output_directory -s [keep_secondary_reads] -t [keep_tmp/bedpe2leanbedpe]"
    echo "options:"
    echo "-h   [HELP]      print help"
    echo "-i   [REQUIRED]  input directory (full path)" 
    echo "-b   [REQUIRED]  filename of full bedpe.gz (must end in .bedpe.gz)"
    echo "-c   [OPTIONAL]  chr select file (full path, if specified will select these chromosomes)"
    echo "-o   [REQUIRED]  output directory (full path)"
    echo "-s   [OPTIONAL]  keep secondary reads (default false)"
    echo "-t   [OPTIONAL]  keep temporary directory (default false)"
    echo
}

## function that allows optional argument
getopts_get_optional_argument() {
  eval next_token=\${$OPTIND}
  if [[ -n $next_token && $next_token != -* ]]; then
    OPTIND=$((OPTIND + 1))
    OPTARG=$next_token
  else
    OPTARG=""
  fi
}

## Get the options
while getopts ":hi:b:co:st" option; do
    case "${option}" in
        h) Help
           exit;;
        i) INPUT_DIR=${OPTARG};;
        b) FULL_BEDPE_FNAME=${OPTARG};;
        c) getopts_get_optional_argument $@
           CHR_SELECT=${OPTARG};;
        o) OUT_DIR=${OPTARG};;
        s) KEEP_SECONDARY_READS=true;;
        t) KEEP_TMP=true;;
       \?) echo "Error: Invalid option"
           exit;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }

echo "input directory:           $INPUT_DIR"
echo "full .bedpe.gz filename:   $FULL_BEDPE_FNAME"
echo "chromosome selection file: $CHR_SELECT"
echo "output path:               $OUT_DIR"
echo "keep secondary reads?      $KEEP_SECONDARY_READS"
echo "keep temporary directory?  $KEEP_TMP"

# Main program ##############################################

echo ""
echo "Job started at "$(date) 
time1=$(date +%s)
echo ""

BEDPE_M_ONLY="${FULL_BEDPE_FNAME%.*}_Monly.bedpe"
BEDPE_NO_UNMAPPED="${BEDPE_M_ONLY%.*}_noUnmapped.bedpe"
BEDPE_NO_SEC="${BEDPE_NO_UNMAPPED%.*}_no256.bedpe"
BEDPE_PP="${BEDPE_NO_SEC%.*}_pp.bedpe"
BEDPE_4MEDE="${FULL_BEDPE_FNAME%.bedpe.gz}_4mede.bedpe"
BEDPE_4MEDE_CHR_SELECT="${BEDPE_4MEDE%.*}_chrSelect.bedpe"

mkdir -p "${OUT_DIR}/tmp/bedpe2leanbedpe"

echo "Getting fragments with only M in CIGAR..."
zcat ${INPUT_DIR}/${FULL_BEDPE_FNAME} \
    | awk '$12!~/[HIDNSP=X]/' \
    > ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_M_ONLY}

echo "Removing fragments with unmapped reads..."
cat ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_M_ONLY} \
    | awk '(!and($14,0x4)) {print}' \
    | awk '(!and($14,0x8)) {print}' \
    | awk '(!and($15,0x4)) {print}' \
    | awk '(!and($15,0x8)) {print}' \
    > ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_NO_UNMAPPED}

if [ "$KEEP_SECONDARY_READS" != true ]; then
    echo "Removing fragments that have secondary reads..."
    cat ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_NO_UNMAPPED} \
        | gawk '(!and($14,0x100)) {print}' \
        | gawk '(!and($15,0x100)) {print}' \
        > ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_NO_SEC}
fi

#echo "Removing fragments that have supplementary reads..."
### { skip for now }

echo "Removing fragments that are not proper pair..."
cat ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_NO_SEC} \
    | gawk '(and($14,0x2)) {print}' \
    > ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_PP}

### { no need for this, MeDEStrand does not need qwidth } 
#echo "Get qwidth for sample..."
#QWIDTH=$(cut -f12 ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_PP} | sort | uniq | sed 's/.$//')
#echo $QWIDTH

echo "Getting only necessary columns for MeDEStrand input..."
cat ${OUT_DIR}/tmp/bedpe2leanbedpe/${BEDPE_PP} \
    | awk 'BEGIN{OFS="\t"} {print $1,$10,$2+1,"1",$5+1,sqrt($17*$17)}' \
    > ${OUT_DIR}/${BEDPE_4MEDE}

if [ ! -z "$CHR_SELECT" ]; then
    echo "Getting only selected chromosomes..."
    grep -wf ${CHR_SELECT} ${OUT_DIR}/${BEDPE_4MEDE} \
        > ${OUT_DIR}/${BEDPE_4MEDE_CHR_SELECT}
    rm ${OUT_DIR}/${BEDPE_4MEDE}
fi

if [ "$KEEP_TMP" != true ]; then
    echo "Removing tmp/bedpe2leanbedpe directory..."
    rm -r ${OUT_DIR}/tmp/bedpe2leanbedpe/
fi

echo ""
time2=$(date +%s)
echo "Job ended at "$(date) 
echo "Job took $(((time2-time1)/3600)) hours $((((time2-time1)%3600)/60)) minutes $(((time2-time1)%60)) seconds"

## EOF

