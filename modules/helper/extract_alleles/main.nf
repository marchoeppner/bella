process HELPER_EXTRACT_ALLELES {

    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dajin2:0.5.5--pyhdfd78af_0' :
        'quay.io/biocontainers/dajin2:0.5.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(tsv_file, stageAs: "report/")

    output:
    tuple val(meta), path('*.tsv')  , emit: tsv
    path 'versions.yml'             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id
    def suffix = tsv_file.toString().contains("_hashed.tsv") ? "_results_alleles_hashed.tsv" : "_results_alleles.tsv"
    def result = prefix + suffix

    """
    bella_extract_alleles.py \
    --sample $meta.sample_id \
    --tsv $tsv_file \
    $args \
    --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}