process CHEWBBACA_ALLELECALL {

    maxForks 1

    tag "${meta.sample_id}"

    label 'medium_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0' :
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(assemblies, stageAs: 'assemblies/')
    path(db)

    output:
    tuple val(meta), path(results)                          , emit: report
    tuple val(meta), path("*results_alleles.tsv")           , emit: profile
    tuple val(meta), path("*results_alleles_hashed.tsv")    , emit: hashed_profile, optional: true
    tuple val(meta), path("${results}/results_statistics.tsv"), emit: stats
    tuple val(meta), path("${results}/logging_info.txt")    , emit: logs
    path('versions.yml')                                    , emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id
    def db_name = file(db).getSimpleName()
    results = "results_${prefix}_${db_name}"

    """

    if [ -f $db/bella.lock ]; then
        echo "Database directory is locked!"
        echo "Please remove \$(realpath $db)/bella.lock"
        exit 17
    fi

    touch $db/bella.lock

    chewBBACA.py AlleleCall \\
    -i assemblies \\
    -g $db \\
    -o $results \\
    $args \\
    --cpu ${task.cpus}

    cp ${results}/results_alleles.tsv ${prefix}_results_alleles.tsv
    if [ -f ${results}/results_alleles_hashed.tsv ]; then
        cp ${results}/results_alleles_hashed.tsv ${prefix}_results_alleles_hashed.tsv
    fi

    rm -f $db/bella.lock

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewBBACA: \$(chewBBACA.py --version 2>&1 | sed -e "s/chewBBACA version: //g")
    END_VERSIONS

    """
}
