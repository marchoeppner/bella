process REPORT {

    tag "All"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dajin2:0.5.5--pyhdfd78af_0' :
        'quay.io/biocontainers/dajin2:0.5.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(json)
    path(template)
    val(cluster_distance)

    output:
    path('*.html')          , emit: html
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: params.run_name
    def result = prefix + '.html'

    def version = workflow.manifest.version
    def call = workflow.commandLine
    def wd = workflow.workDir

    """
    spread.py --template $template \
    --input $json \
    --version $version \
    --call '$call' \
    --wd $wd \
    --distance $cluster_distance \
    $args \
    --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
