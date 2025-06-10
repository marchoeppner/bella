process SUMMARY {
    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.27.1--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reportree), val(schema), path(yaml), path(stats, stageAs: '?/')

    output:
    tuple val(meta), path('*.json') , emit: json
    path 'versions.yml'             , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id
    result = prefix + '.json'

    """
    bella_json.py --schema $schema \\
    --yaml $yaml \\
    --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
