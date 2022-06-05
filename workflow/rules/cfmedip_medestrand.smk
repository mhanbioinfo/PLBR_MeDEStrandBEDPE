# ----------------------------------------------- #
# Infer methylation profile using MeDEStrandBEDPE #
# ----------------------------------------------- #

bam_or_bedpe = config['pipeline_params']['bam_or_bedpe']

def get_cfmedip_medestrand_input(bam_or_bedpe):
    if bam_or_bedpe == 'bam':
        return(path_to_data + '/{cohort}/results/bam_dedupd/{sample}.aligned.sorted.filt3.dedupd.bam')
    elif bam_or_bedpe == 'bedpe': 
        return(path_to_data + '/{cohort}/results/bedpelean_out/{sample}.filt3.dedupd_coordSortd_4mede.bedpe')

def get_cfmedip_medestrand_output(bam_or_bedpe):
    if bam_or_bedpe == 'bam':
        return(path_to_data + '/{cohort}/results/bam_cfmedip_medestrand/bam_{sample}_medestrand.bedgraph')
    elif bam_or_bedpe == 'bedpe':
        return(path_to_data + '/{cohort}/results/bedpe_cfmedip_medestrand/bedpe_{sample}_medestrand.bedgraph')

chromosomes = {}
for c in config['data']['cohorts']:
    if config['data']['cohorts'][c]['active']:
        chr_data = get_cohort_config(c)['chromosomes']
        chromosome_tuples = [(species, chrom) for species in chr_data for chrom in chr_data[species].split(',')]
        chromosomes[c] = chromosome_tuples

# This is the currently used negative binomial GLM approach to fitting
rule cfmedip_medestrand:
    input:
        get_cfmedip_medestrand_input(bam_or_bedpe)
    output:
        get_cfmedip_medestrand_output(bam_or_bedpe)
    resources: cpus=1, time_min='1-00:00:00', mem_mb=lambda wildcards, attempt: 16000 if attempt == 1 else 30000
    params:
        winsize = config['pipeline_params']['window_size'],
        chr_select = lambda wildcards: [a[1] for a in chromosomes[wildcards.cohort] if a[0]=="human"]
    conda: '../conda_env/cfmedip_r.yml'
    shell:
        'Rscript src/R/MeDEStrandBEDPE.R --inputFile {input} --outputFile {output} --windowSize {params.winsize} --chr_select "{params.chr_select}"'

## EOF
