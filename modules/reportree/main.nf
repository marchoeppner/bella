process REPORTREE {
    tag "${meta.sample_id}"

    label 'short_serial'

    container "docker://mhoeppner/reportree:2.5.3"

    input:
    tuple val(meta), path(alleles)
    val(nomenclature)
    val(metadata)

    output:
    tuple val(meta), path('*partitions_summary.tsv')    , optional: true, emit: summary
    tuple val(meta), path('*partitions.tsv')            , emit: partitions
    tuple val(meta), path('*metrics.tsv')               , optional: true, emit: metrics
    tuple val(meta), path('*nomenclature_changes.tsv')  , optional: true, emit: nomenclature_changes
    tuple val(meta), path('*loci_report.tsv')           , optional: true, emit: report
    tuple val(meta), path('*.log')                      , optional: true, emit: log
    tuple val(meta), path('*dist.tsv')                  , optional: true, emit: dist
    tuple val(meta), path('*grapetree.tsv')             , optional: true, emit: grapetree
    tuple val(meta), path('*hamming.tsv')               , optional: true, emit: hamming
    tuple val(meta), path('*missing_matrix.tsv')        , optional: true, emit: missing
    tuple val(meta), path('*clusterComposition.tsv')    , optional: true, emit: cluster_composition
    tuple val(meta), path('*.tre')                      , optional: true, emit: tre
    tuple val(meta), path('*.nwk')                      , optional: true, emit: newick
    path('versions.yml')                                , emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id
    n = (nomenclature != false) ? "--nomenclature-file $nomenclature" : ""
    m = (metadata != false) ? "--metadata $metadata" : ""
    
    """
    reportree.py \\
    $args \\
    -a $alleles \\
    $n $m \\
    -out $prefix 2> /dev/null

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree.py --version 2>&1 | head -n1 | sed -e "s/version: //g")
    END_VERSIONS

    """
}
