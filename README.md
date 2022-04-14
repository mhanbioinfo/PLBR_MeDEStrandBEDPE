# PLBR_MeDEStrandBEDPE

## Summary

- Run MeDEStrand with bedpe input as part of PLBR database workflow.
- Pipeline is an extension of OICR cfMeDIPseq analysis pipeline (https://github.com/oicr-gsi/wf_cfmedip)
- Pipeline can take FASTQs, BAM or BEDPE as input, 
  - runs modified version of MeDEStrand (https://github.com/mhanbioinfo/MeDEStrand) (identical output as original MeDEStrand, except is able to take in .bedpe.gz as input, in addition to .bam input)
  - and outputs methylation profile.
- Pipeline is designed to run on SLURM, but can run locally as well

## Workflow overview

![MeDEStrandBEDPE](https://user-images.githubusercontent.com/98410560/163442593-0d60e05f-b5a9-4fd4-bb97-c3cfe46d629a.png)

## Workflow execution

### step1 - define samplesheet.txt

- different samplesheet format for FASTQ, BAM and BEDPE
- see examples/ for details

```
SAMPLE_NAME,FASTQ_GZ_PATH
sample001,/absolute/path/to/data_fastq/sample001_ABC_R1.fastq.gz
sample001,/absolute/path/to/data_fastq/sample001_ABC_R2.fastq.gz
sample002,/absolute/path/to/data_fastq/sample001_ABC_R1.fastq.gz
sample002,/absolute/path/to/data_fastq/sample001_ABC_R2.fastq.gz
```

### step2 - define config_MeDEStrandBEDPE.yml

- see examples/ for details

```
## configuration for running MeDEStrandBEDPE

# common parameters
PROJ_DIR: "/absolute/path/to/project_directory"
SAMPLESHEET_PATH: "/absolute/path/to/samplesheet_MeDEStrandBEDPE_test1.csv"
INPUT_FILE_TYPE:
  FASTQ_GZ: "Yes"
  BAM: "No"
  BEDPE_GZ: "No"
SLURM_OR_LOCAL: "local"
KEEP_TMP: "true"
...
```

### step3 - execute workflow

```{bash}
bash run_MeDEStrandBEDPE.sh /full/path/to/config_MeDEStrandBEDPE.yml
```

## BEDPE specifications

- .bedpe.gz file should have the following columns in this exact order

## Full .bedpe file structure

```
read1                   read2                                        read1   read2   read1   read2   read1   read2       read1   read2  read1   read2   read1   read2
CHR     STAR    END     CHR     START   END     FRAGMENT ID          MAPQ    MAPQ    STRAND  STRAND  CIGAR   CIGAR       FLAG    FLAG   TLEN    TLEN    NM_TAG  NM_TAG
chr1    10028   10098   chr1    10152   10221   NB551056:129:H7...   0       0       +       -       70M     24M1I45M    99      147    193     -193    3       2
chr1    10035   10105   chr1    10174   10230   NB551056:129:H7...   0       0       +       -       70M     14S56M      99      147     195    -195    1       0
chr1    10175   10245   chr1    10257   10328   NB551056:129:H7...   9       9       +       -       70M     28M1D42M    99      147     153    -153    5       4
...
```

## BEDPE rationale

- .bam large size prohibitive for storing in PLBR database
- .bedpe.gz retains essential .bam information while having 6x size reduction
- bedtools bam2bedpe conversion cannot handle secondary alignments,
  - bam2bedpe module in this workflow preserves all alignments,
  - able to do custom alignment filtering of .bedpe file and rerun MeDEStrand analysis in PLBR
