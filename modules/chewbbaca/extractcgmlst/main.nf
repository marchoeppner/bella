process CHEWBBACA_EXTRACTCGMLST {

    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0' :
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(report)

    output:
    tuple val(meta), path("filtered/cgMLST0.tsv") , emit: report
    path('versions.yml')                        , emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    chewBBACA.py ExtractCgMLST \\
    -i $report \\
    --t 0 \\
    -o filtered $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewBBACA: \$(chewBBACA.py --version 2>&1 | sed -e "s/chewBBACA version: //g")
    END_VERSIONS

    """
}
