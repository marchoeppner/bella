// Modules
include { INPUT_CHECK }                     from './../modules/input_check'
include { CHEWBBACA_ALLELECALL }            from './../modules/chewbbaca/allelecall'
include { REPORTREE }                       from './../modules/reportree'
include { CHEWBBACA_JOINPROFILES }          from './../modules/chewbbaca/joinprofiles'
include { MULTIQC }                         from './../modules/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS }     from './../modules/custom/dumpsoftwareversions'
include { CHEWBBACA_ALLELECALLEVALUATOR }   from './../modules/chewbbaca/allelecallevaluator'
include { SUMMARY }                         from './../modules/helper/summary'
include { REPORT }                          from './../modules/helper/report'

/*
Include sub workflows
*/
include { CHEWBBACA_PARALLEL }              from './../subworkflows/chewbbaca_parallel'
include { CHEWBBACA_SERIAL }                from './../subworkflows/chewbbaca_serial'


workflow SPREAD {

    main:

    // Subworkflows
    ch_multiqc_config   = params.multiqc_config   ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : Channel.value([])
    ch_multiqc_logo     = params.multiqc_logo     ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : Channel.value([])
    ch_spread_template  = params.template         ? Channel.fromPath(params.template, checkIfExists: true).collect() : Channel.value([])

    samplesheet         = params.input ? Channel.fromPath(params.input, checkIfExists:true ).collect() : Channel.from([])

    /*
    Get the corect schema to use - either from a pre-configured species or as user-provided path
    */
    if (params.species) {
        if (params.references.keySet().contains(params.species)) {
            ch_distance = params.references[params.species].distance
            if (params.efsa) {
                if (params.references[params.species].efsa) {
                    ch_chewie_schema = Channel.fromPath(params.references[params.species].efsa)
                } else {
                    log.warn "No EFSA schema defined for ${params.species} - falling back to default schema."
                    ch_chewie_schema = Channel.fromPath(params.references[params.species].db)
                }
            } else {
                ch_chewie_schema = Channel.fromPath(params.references[params.species].db)
            }
        } else {
            log.warn "Could not find a pre-configured schema for ${params.species}\nValid schemas are: ${params.references.keySet().join(' ')}\nExiting!"
            System.exit(1)
        }
    } else {
        ch_chewie_schema = params.schema ? Channel.fromPath(params.schema, checkIfExists: true).collect() : Channel.from([])
    }
    
    if (params.distance) {
        ch_distance = params.distance
    }
    
    ch_nomenclature     = params.nomenclature ? file(params.nomenclature, checkIfExists: true) : Channel.from(false)
    ch_metadata         = params.metadata ? file(params.metadata, checkIfExists: true) : Channel.from(false)

    ch_versions = Channel.from([])
    multiqc_files = Channel.from([])

    /*
    Check that the samplesheet is valid
    */
    INPUT_CHECK(samplesheet)

    if (params.parallel_calling) {

        /*
        Run chewbbaca allele calling in parallel on each assembly and then merge
        This option is useful on very large data sets on a distributed compute infrastructure
        */
        CHEWBBACA_PARALLEL(
            INPUT_CHECK.out.assembly,
            ch_chewie_schema.collect()
        )
        ch_matrix = CHEWBBACA_PARALLEL.out.matrix
        ch_versions = ch_versions.mix(CHEWBBACA_PARALLEL.out.versions)
    } else {
        /*
        Combine all assemblies and perform joint allele calling
        This option is preferrable on smaller data sets
        */
        CHEWBBACA_SERIAL(
            INPUT_CHECK.out.assembly,
            ch_chewie_schema.collect()
        )
        ch_matrix = CHEWBBACA_SERIAL.out.matrix
        ch_versions = ch_versions.mix(CHEWBBACA_SERIAL.out.versions)
    }
    
    /*
    Use the matrix from chewbbaca to perform clustering 
    */
    REPORTREE(
        ch_matrix,
        ch_nomenclature,
        ch_metadata

    )
    ch_versions = ch_versions.mix(REPORTREE.out.versions)
    
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    REPORTREE.out.results.join(
        ch_chewie_schema.map { s ->
            [
                [ sample_id: params.run_name],
                s
            ]
        }
    ).join(
        CUSTOM_DUMPSOFTWAREVERSIONS.out.yml.map { y ->
            [
                [ sample_id: params.run_name],
                y
            ]
        }
    ).set { ch_summary_input }

    // Summarize results as JSON
    SUMMARY(
        ch_summary_input
    )
    ch_versions = ch_versions.mix(SUMMARY.out.versions)

    // Generate HTML report
    REPORT(
        SUMMARY.out.json,
        ch_spread_template,
        ch_distance
    )
    ch_versions = ch_versions.mix(REPORT.out.versions)

    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.report
}

def combine_partitions(partitions,dist) {
    def parts = partitions.tokenize(",")
    if (!parts.contains(dist)) {
        parts.add(dist)
    }

    return parts.join(",")
}