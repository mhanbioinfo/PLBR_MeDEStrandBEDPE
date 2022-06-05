# ------------------ #
# BAM filter metrics #
# ------------------ #

# Get read count after each BAM filtering
rule bam_filt_metrics:
    input:
        bam_raw = path_to_data + '/{cohort}/tmp/merge_bam/{sample}.aligned.sorted.bam',
        bam_filt1 = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt1.bam',
        bam_filt2 = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt2.bam',
        bam_filt3 = path_to_data + '/{cohort}/tmp/bam_filt/{sample}.aligned.sorted.filt3.bam',
        bam_dedupd = path_to_data + '/{cohort}/results/bam_dedupd/{sample}.aligned.sorted.filt3.dedupd.bam',
    output:
        path_to_data + '/{cohort}/qc/bam_filt_metrics/{sample}.bam_filt_metrics.txt'
    resources: cpus=1, mem_mb=8000, time_min='5:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        'sh src/QC/getFilterMetrics.sh -r {input.bam_raw} -a {input.bam_filt1} -b {input.bam_filt2} -c {input.bam_filt3} -d {input.bam_dedupd} -o {output}'


