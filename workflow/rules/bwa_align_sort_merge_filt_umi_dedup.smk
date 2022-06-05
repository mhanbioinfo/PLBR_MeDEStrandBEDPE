# --------------------------- #
#  Align FASTQs to reference  #
# --------------------------- #

# Run BWA mem on FASTQs after extracting barcodes.
rule bwa_mem:
    input:
        path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R1.fastq.gz',
        path_to_data + '/{cohort}/tmp/extract_barcodes/{sample}_lib{lib}_extract_barcode_R2.fastq.gz',
    output:
        #temp(path_to_data + '/{cohort}/tmp/bwa_mem/{sample}_lib{lib}.sam')
        path_to_data + '/{cohort}/tmp/bwa_mem/{sample}_lib{lib}.sam'
    resources: cpus=8, mem_mb=16000, time_min='72:00:00'
    params:
        bwa_index = lambda wildcards: get_cohort_config(wildcards.cohort)['bwa_index']
    conda: '../conda_env/samtools.yml'
    shell:
        'bwa mem -t 8 {params.bwa_index} {input} > {output}'

# Converts SAM to BAM and sort
rule sam_to_bam:
    input:
        path_to_data + '/{cohort}/tmp/bwa_mem/{sample}_lib{lib}.sam'
    output:
        #bam = temp(path_to_data + '/{cohort}/tmp/bwa_mem/{sample}_lib{lib}.sorted.bam'),
        bam = path_to_data + '/{cohort}/tmp/bwa_mem/{sample}_lib{lib}.sorted.bam',
    resources: cpus=16, mem_mb=30000, time_min='72:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        'samtools view -b {input} | samtools sort -o {output}'

def get_libraries_of_sample(sample):
    """Returns all library indices of a sample based on samplesheet."""
    filtered_table = get_all_samples()[get_all_samples().sample_name == sample]
    return(list(set(filtered_table.library_index.to_list())))

# If there are multiple libraries for a given sample, as specified in samplesheet,
# these libraries are automatically merged at this step into a single unified BAM.
rule merge_bam:
    input:
        lambda wildcards: expand(
                path_to_data + '/{{cohort}}/tmp/bwa_mem/' + wildcards.sample + '_lib{lib}.sorted.bam',
                lib=get_libraries_of_sample(wildcards.sample)
        )
    output:
        #temp(path_to_data + '/{cohort}/tmp/merge_bam/{sample}.aligned.sorted.bam')
        path_to_data + '/{cohort}/tmp/merge_bam/{sample}.aligned.sorted.bam'
    resources: cpus=1, mem_mb=8000, time_min='24:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        'samtools merge {output} {input} && samtools index {output}'


# Filter1 - remove unmapped and secondary reads
rule bam_filter1:
    input:
        path_to_data + '/{cohort}/tmp/merge_bam/{sample}.aligned.sorted.bam'
    output:
        path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt1.bam'
    resources: cpus=1, mem_mb=16000, time_min='24:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        'samtools view -b -F 260 {input} -o {output}'

# Filter2 - remove reads belonging to inserts shorter than 119nt or greater than 501nt
rule bam_filter2:
    input:
        path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt1.bam'
    output:
        ## mapped and proper pair reads ( 199<TLEN<501 ) 
        mpp_reads = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt1.mapped_proper_pair.txt',
        filt2_bam = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt2.bam'
    resources: cpus=1, mem_mb=16000, time_min='24:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        "samtools view {input} | awk 'sqrt($9*$9)>119 && sqrt($9*$9)<501' | awk '{{print $1}}' > {output.mpp_reads} && picard FilterSamReads -I {input} -O {output.filt2_bam} -READ_LIST_FILE {output.mpp_reads} -FILTER includeReadList -WRITE_READS_FILES false"

# Filter3 - remove reads with edit distance > 7 from reference
rule bam_filter3:
    input:
        path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt2.bam'
    output:
        HiMM_reads = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt2.high_mismatch.txt',
        filt3_bam = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt3.bam',
        filt3_bam_index = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt3.bam.bai',
    resources: cpus=1, mem_mb=16000, time_min='24:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        "samtools view {input} | awk '{{read=$0;sub(/.*NM:i:/,X,$0);sub(/\t.*/,X,$0);if(int($0)>7) {{print read}}}}' | awk '{{print $1}}' > {output.HiMM_reads} && picard FilterSamReads -I {input} -O {output.filt3_bam} -READ_LIST_FILE {output.HiMM_reads} -FILTER excludeReadList -WRITE_READS_FILES false && samtools index {output.filt3_bam}"


# umi-tools deduplication
rule umi_tools_dedup:
    input:
        path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt3.bam'
    output:
        dedupd_bam = path_to_data + '/{cohort}/results/bam_dedupd/{sample}.aligned.sorted.filt3.dedupd.bam',
        #dedup_stats = path_to_data + '/{cohort}/results/bam_dedupd/{sample}.aligned.sorted.filt3.dedupd'
    resources: cpus=1, mem_mb=16000, time_min='24:00:00'
    conda: '../conda_env/umi_tools.yml'
    shell:
        'umi_tools dedup --paired -I {input} -S {output.dedupd_bam}'


