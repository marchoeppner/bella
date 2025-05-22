// Modules
include { INPUT_CHECK }                 from './../modules/input_check'
include { CHEWBBACA_ALLELECALL }        from './../modules/chewbbaca/allelecall'
include { REPORTREE }                   from './../modules/reportree'
include { MULTIQC }                     from './../modules/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

workflow SPREAD {

    main:

    // Subworkflows
    ch_multiqc_config   = params.multiqc_config   ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : Channel.value([])
    ch_multiqc_logo     = params.multiqc_logo     ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : Channel.value([])

    samplesheet         = params.input ? Channel.fromPath(params.input, checkIfExists:true ).collect() : Channel.from([])

    /*
    Get the corect schema to use - either from a pre-configured species or as user-provided path
    */
    if (params.species) {
        if (params.references.keySet().contains(params.species)) {
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
    
    ch_nomenclature     = params.nomenclature ? file(params.nomenclature, checkIfExists: true) : Channel.from(false)
    ch_metadata         = params.metadata ? file(params.metadata, checkIfExists: true) : Channel.from(false)

    ch_versions = Channel.from([])
    multiqc_files = Channel.from([])

    /*
    Check that the samplesheet is valid
    */
    INPUT_CHECK(samplesheet)

    /*
    Perform joint allele calling - this may be too slow for large data sets, may need adjusting
    */
    CHEWBBACA_ALLELECALL(
        INPUT_CHECK.out.assembly.map { m,a ->
            a
        }.collect()
        .map { a ->
            [
                [ sample_id: "all"],
                a
            ]
        },
        ch_chewie_schema
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)

    /*
    Use the matrix from chewbbaca to perform clustering 
    */
    REPORTREE(
        CHEWBBACA_ALLELECALL.out.profile,
        ch_nomenclature,
        ch_metadata

    )
    ch_versions = ch_versions.mix(REPORTREE.out.versions)
    
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.report
}
