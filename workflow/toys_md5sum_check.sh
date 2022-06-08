#!/bin/bash

PROJ_DIR="/cluster/projects/pughlab/projects/cfMeDIP_compare_pipelines/cfmedip_medestrand_bedpe/try12_medestrand_bedpe_smk"

## .bedgraph
echo "Writing to ${PROJ_DIR}/md5sum.bedgraph"
find ${PROJ_DIR} -type f -name "*.bedgraph" -exec md5sum {} \; | sort > ${PROJ_DIR}/md5sum.bedgraph

## qc_full
echo "Writing to ${PROJ_DIR}/md5sum.qc_full.txt"
find ${PROJ_DIR} -type f -name "*qc_full.txt" -exec sh -c 'echo "$(sed -n "5,83p" $1 | md5sum), $1"' _ {} \; | sort > ${PROJ_DIR}/md5sum.qc_full.txt


## EOF
