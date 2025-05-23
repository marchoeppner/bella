process CHEWBBACA_DOWNLOADSCHEMA {
    maxForks 1

    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0' :
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), val(species_id), val(schema_id)

    output:
    tuple val(meta), path('*MLST*'), path("*MLST*/*.trn")   , emit: schema
    path('versions.yml')                                    , emit: versions

    script:

    def args = task.ext.args ?: ''

    """
    chewBBACA.py DownloadSchema \\
    -sp $species_id \\
    -sc $schema_id \\
    -o download $args

    mv download/* . 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewBBACA: \$(chewBBACA.py --version 2>&1 | sed -e "s/*.wersion: //g")
    END_VERSIONS

    """
}
