# -------------------------- #
#  Pre-process input FASTQs  #
# -------------------------- #

def get_fastq_path(cohort, sample, library, read_in_pair=1):
    """Retrieves the path to the fastq file.

    Keyword arguments:
        cohort -- name of the cohort whose samplesheet should be accessed.
        sample -- identifier of the sample as specified in the samplesheet.
        library -- integer representing the library index as specified in the samplesheet.
        read_in_pair -- 1 or 2 - representing read 1 or read 2 in paired end data.
    """
    library = int(library)
    cohort_data = get_cohort_data(cohort)
    sample_line = cohort_data[
        (cohort_data.sample_name == sample) &
        (cohort_data.library_index == library) &
        (cohort_data.read_in_pair == read_in_pair)
    ]
    return(sample_line.path.to_list()[0])

# Extract Barcodes using UMI-tools
rule extract_barcodes:
    input:
        R1_fastqc = path_to_data + '/{cohort}/qc/fastqc_input_fastq/{sample}_lib{lib}_R1_fastqc.html',
        R2_fastqc = path_to_data + '/{cohort}/qc/fastqc_input_fastq/{sample}_lib{lib}_R2_fastqc.html',
        R1 = lambda wildcards: get_fastq_path(wildcards.cohort, wildcards.sample, int(wildcards.lib), 1), 
        R2 = lambda wildcards: get_fastq_path(wildcards.cohort, wildcards.sample, int(wildcards.lib), 2),
    output:
        #R1 = temp(path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R1.fastq'),
        R1 = path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R1.fastq.gz',
        #R2 = temp(path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R2.fastq')
        R2 = path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R2.fastq.gz'
    params:
        umi_pat1 = config['pipeline_params']['umi_pattern1'],
        umi_pat2 = config['pipeline_params']['umi_pattern2']
    resources: cpus=1, mem_mb=16000, time_min='2-00:00:00'
    conda: '../conda_env/umi_tools.yml'
    shell:
        'umi_tools extract --extract-method=string --bc-pattern={params.umi_pat1} --bc-pattern2={params.umi_pat2} -I {input.R1} --read2-in={input.R2} -S {output.R1} --read2-out={output.R2}'
