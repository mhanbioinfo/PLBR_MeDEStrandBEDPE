#!/bin/bash

module load samtools/1.14

input="/cluster/home/t110409uhn/git/cfmedip_medremix_bedpe_git/toy_files/toy01.bam"
slurm_local="local"
chunks=5
out_dir="/cluster/projects/pughlab/projects/cfMeDIP_compare_pipelines/cfmedip_medremix_bedpe/analysis006_bam2pe_pyscript"
src_dir="/cluster/home/t110409uhn/git/cfmedip_medremix_bedpe_git/workflow/src/bam2bedpe_scripts"
picard_dir="/cluster/tools/software/picard/2.10.9"
conda_activate="/cluster/home/t110409uhn/bin/miniconda3/bin/activate"
conda_env="MedRemixBEDPE"


bash bam2bedpe.sh \
-s ${slurm_local} \
-c ${chunks} \
-b ${input} \
-o ${out_dir} \
-x ${src_dir} \
-p ${picard_dir} \
-a ${conda_activate} \
-e ${conda_env} \
-t
