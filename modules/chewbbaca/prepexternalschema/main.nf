process CHEWBBACA_PREPEXTERNALSCHEMA {

    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0' :
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(schema), path(filter)

    output:
    tuple val(meta), path('*EFSA*')     , emit: filtered_schema
    path('versions.yml')                , emit: versions

    script:

    def args = task.ext.args ?: ''
    def sname = schema.getBaseName() + "_EFSA"
    """
    chewBBACA.py PrepExternalSchema \\
    -g ${schema} \\
    --gl $filter \\
    --cpu ${task.cpus} \\
    -o ${sname} $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewBBACA: \$(chewBBACA.py --version 2>&1 | sed -e "s/*.wersion: //g")
    END_VERSIONS

    """
}
