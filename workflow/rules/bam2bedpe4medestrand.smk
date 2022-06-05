# -------------------- #
# convert bam to bedpe #
# -------------------- #

chromosomes = {}
for c in config['data']['cohorts']:
    if config['data']['cohorts'][c]['active']:
        chr_data = get_cohort_config(c)['chromosomes']
        chromosome_tuples = [(species, chrom) for species in chr_data for chrom in chr_data[species].split(',')]
        chromosomes[c] = chromosome_tuples

rule bam2bedpe:
    input:
        path_to_data + '/{cohort}/results/bam_dedupd/{sample}.aligned.sorted.filt3.dedupd.bam',
    output:
        bedpe = path_to_data + '/{cohort}/results/bedpe_out/{sample}.aligned.sorted.filt3.dedupd_coordSortd.bedpe.gz',
    params:
        slurm_local = config['pipeline_params']['slurm_local'],
        chunks = config['pipeline_params']['chunks'],
        out_dir = path_to_data + '/{cohort}/results/bedpe_out',
        conda_activate = config['pipeline_params']['conda_activate'],
        conda_env = config['pipeline_params']['conda_env'],
    resources: cpus=1, mem_mb=60000, time_min='3-00:00:00'
    conda: '../conda_env/samtools.yml'
    shell:
        'bash src/bam2bedpe_scripts/bam2bedpe.sh -s {params.slurm_local} -c {params.chunks} -b {input} -o {params.out_dir} -a {params.conda_activate} -e {params.conda_env}'

rule get_clean_bedpe4medestrand:
    input:
        path_to_data + '/{cohort}/results/bedpe_out/{sample}.aligned.sorted.filt3.dedupd_coordSortd.bedpe.gz'
    output:
        path_to_data + '/{cohort}/results/bedpelean_out/{sample}.filt3.dedupd_coordSortd_4mede.bedpe'
    params:
        out_dir = path_to_data + '/{cohort}/results/bedpelean_out'
    resources: cpus=4, mem_mb=32000, time_min='1-00:00:00'
    shell:
        'bash src/bam2bedpe_scripts/bedpe2leanbedpe_for_MeDEStrand.sh -i {input} -o {params.out_dir} -m {output} -t'








