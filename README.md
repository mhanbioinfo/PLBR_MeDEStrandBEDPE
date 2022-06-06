# PLBR_MeDEStrandBEDPE

## Summary

- Run MeDEStrand methylation profiler with bedpe input as part of PLBR database workflow.
- Pipeline is an extension of OICR cfMeDIPseq analysis pipeline (https://github.com/oicr-gsi/wf_cfmedip)
  - same bam preprocessing (filtering) steps
- Pipeline can take FASTQs, BAM or BEDPE as input, 
  - runs modified version of MeDEStrand (https://github.com/mhanbioinfo/MeDEStrandBEDPE) (identical output as original MeDEStrand, except is able to take in .bedpe.gz as input, in addition to .bam input)
  - and outputs methylation profile
- For full specifications of BEDPE7+12 file format, please visit https://github.com/pughlab/bam2bedpe
- Pipeline is written in Snakemake, designed to run on SLURM cluster, but can run locally as well

## Workflow overview

![MeDEStrandBEDPE_workflow_diagram](https://user-images.githubusercontent.com/98410560/172213778-c2471ca5-192d-4021-82ec-75d3f3395ab8.png)

Please see wiki for tutorial on settings up and running pipeline.

Questions please contact ming.han@uhn.ca.
