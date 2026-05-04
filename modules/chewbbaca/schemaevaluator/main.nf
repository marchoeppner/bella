process CHEWBBACA_SCHEMAEVALUATOR {

    tag "${meta.sample_id}|${filter}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0' :
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(schema)

    output:
    tuple val(meta), path('schema_stats')   , emit: stats
    path('versions.yml')                    , emit: versions

    script:

    def args = task.ext.args ?: ''
    def sname = "schema_stats"
    """
    chewBBACA.py SchemaEvaluator \\
    -g ${schema} \\
    --cpu ${task.cpus} \\
    -o ${sname} $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewBBACA: \$(chewBBACA.py --version 2>&1 | sed -e "s/*.version: //g")
    END_VERSIONS

    """
}
