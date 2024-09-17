process REPORTREE {
    tag "${db}"

    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "docker://insapathogenomics/reportree:v2.0.2"

    input:
    tuple val(meta), path(alleles)

    output:
    tuple val(meta), path('*mlst.tsv')  , emit: report
    path('versions.yml')                , emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    reportree.py \\
    $args \\
    -a $alleles \\
    -out $prefix \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree --version 2>&1 | head -n1 | sed -e "s/version: //g")
    END_VERSIONS

    """
}
