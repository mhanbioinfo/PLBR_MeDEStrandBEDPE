#!/bin/bash

#SBATCH --mail-type=ALL
#SBATCH --mail-user=ming.han@uhn.ca
#SBATCH -t 5-00:00:00
#SBATCH -D ./
#SBATCH --mem=60G
#SBATCH -J run_MeDEStrandBEDPE
#SBATCH -p himem
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -o ./%j-%x.out
#SBATCH -e ./%j-%x.err

## usage
## sbatch/bash run_MeDEStrandBEDPE.sh config_MeDEStrandBEDPE.yml

if [ $# != 1 ]; then
    echo "Please specify a config.yml file."
    exit 1
fi

## PARSE CONFIG ######################################################

## https://github.com/ash-shell/yaml-parse/blob/master/lib/yaml_parse.sh
## yml file must be 2 spaces indented
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         gsub(/\s*#.*$/, "", $3);
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

CONFIG_F=$1
params=($(parse_yaml $CONFIG_F))

for param in "${params[@]}"; do
   #echo $param
   lhs=${param%=*}
   rhs=${param#*=}
   rhs="${rhs%%\#*}"    # Del in line right comments
   rhs="${rhs%%*( )}"   # Del trailing spaces
   rhs="${rhs%\"*}"     # Del opening string quotes 
   rhs="${rhs#\"*}"     # Del closing string quotes 
   declare $lhs=$rhs
done


## CALL run_MeDEStrandBEDPE_from_... ############################### 

SRC_DIR="$(pwd)/src"

if [ $INPUT_FILE_TYPE_FASTQ = "Yes" ]; then
    echo "Input filetype is FASTQ."
    bash $SRC_DIR/run_MeDEStrandBEDPE_fromFASTQs_makeBatchScripts.sh \
        -s ${SAMPLESHEET_PATH} \
        -p ${PROJ_DIR} \
        -u ${MeDEStrandBEDPE_UMI1_PATTERN} \
        -v ${MeDEStrandBEDPE_UMI2_PATTERN} \
        -r ${REF_BWA} \
        -f ${REF_FASTA_F} \
        -w ${MeDEStrandBEDPE_WINDOW_SIZE} \
        -c ${BEDPE2LEANBEDPE_CHR_SELECT_F}
elif [$INPUT_FILE_TYPE_BAM = "Yes" ]; then
   echo "Input filetype is BAM."
elif [$INPUT_FILE_TYPE_BEDPE = "Yes" ]; then
   echo "Input filetype is BAM."
else
   echo "Please specify input filetype."
fi




#echo $PROJ_DIR
#echo $SAMPLESHEET_PATH
#echo $INPUT_FILE_TYPE_FASTQ
#echo $INPUT_FILE_TYPE_BAM
#echo $INPUT_FILE_TYPE_BEDPE
#echo $REMOVE_TMP
#
## references
#echo $REF_BWA
#echo $REF_FASTA_F
#
## tool specific parameters
#echo $MeDEStrandBEDPE_UMI1_PATTERN
#echo $MeDEStrandBEDPE_UMI2_PATTERN
#echo $MeDEStrandBEDPE_WINDOW_SIZE
#
#echo $BEDPE2LEANBEDPE_CHR_SELECT_F
#echo $BEDPE2LEANBEDPE_REMOVE_TMP






## EOF
