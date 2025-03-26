process REPORTREE {
    tag "${meta.sample_id}"

    label 'short_serial'

    container "docker://mhoeppner/reportree:2.5.3"

    input:
    tuple val(meta), path(alleles)
    val(nomenclature)
    val(metadata)

    output:
    tuple val(meta), path('*partitions_summary.tsv')    , emit: summary
    tuple val(meta), path('partitions.tsv')             , emit: partitions
    tuple val(meta), path('metrics.tsv')                , emit: metrics
    tuple val(meta), path('*nomenclature_changes.tsv')  , optional: true, emit: nomenclature_changes
    tuple val(meta), path('*.tre')                      , optional: true, emit: newick
    path('versions.yml')                                , emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id
    n = (nomenclature != false) ? "--nomenclature $nomenclature" : ""
    m = (metadata != false) ? "--metadta $metadata" : ""
    
    """
    reportree.py \\
    $args \\
    -a $alleles \\
    $n $m \\
    -out $prefix 2> /dev/null

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree --version 2>&1 | head -n1 | sed -e "s/version: //g")
    END_VERSIONS

    """
}
