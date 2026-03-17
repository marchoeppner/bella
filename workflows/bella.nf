// Modules
include { INPUT_CHECK }                     from './../modules/input_check'
include { INPUT_CHECK as INPUT_CHECK_PROFILES } from './../modules/input_check'
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
include { CHEWBBACA_ALLELECALLING }         from './../subworkflows/chewbbaca_allelecalling'

workflow BELLA {

    main:

    // Subworkflows
    ch_multiqc_config   = params.multiqc_config   ? channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : channel.value([])
    ch_multiqc_logo     = params.multiqc_logo     ? channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : channel.value([])
    ch_bella_template   = params.template         ? channel.fromPath(params.template, checkIfExists: true).collect() : channel.value([])
    ch_previous_profiles = Channel.from([])

    samplesheet         = params.input ? channel.fromPath(params.input, checkIfExists:true ).collect() : channel.from([])
    existing_profiles   = params.alleles ? channel.fromPath(params.alleles, checkIfExists: true). collect() : channel.from([])

    /*
    Get the corect schema to use - either from a pre-configured species or as user-provided path
    */
    if (params.species) {
        if (params.references.keySet().contains(params.species)) {
            ch_distance = params.references[params.species].distance
            if (params.efsa) {
                if (params.references[params.species].efsa) {
                    ch_chewie_schema = channel.fromPath(params.references[params.species].efsa)
                } else {
                    log.warn "No EFSA schema defined for ${params.species} - falling back to default schema."
                    ch_chewie_schema = channel.fromPath(params.references[params.species].db)
                }
            } else {
                ch_chewie_schema = channel.fromPath(params.references[params.species].db)
            }
        } else {
            log.warn "Could not find a pre-configured schema for ${params.species}\nValid schemas are: ${params.references.keySet().join(' ')}\nExiting!"
            System.exit(1)
        }
    } else {
        ch_chewie_schema = params.schema ? channel.fromPath(params.schema, checkIfExists: true).collect() : channel.from([])
    }
    
    if (params.distance) {
        ch_distance = params.distance
    }
    
    ch_nomenclature     = params.nomenclature ? file(params.nomenclature, checkIfExists: true) : channel.from(false)
    ch_metadata         = params.metadata ? file(params.metadata, checkIfExists: true) : channel.from(false)

    ch_versions = channel.from([])
    multiqc_files = channel.from([])
    ch_chewie_stats = Channel.from([ [[sample_id: params.run_name],file("${baseDir}/assets/email_template.txt")] ])

    pipeline_info = channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

    /*
    Check that the samplesheet is valid and create channels
    */
    INPUT_CHECK(samplesheet)
    INPUT_CHECK_PROFILES(existing_profiles)

    ch_previous_profiles = ch_previous_profiles.mix(INPUT_CHECK_PROFILES.out.profiles)

    /*
    Run allele calling on all new assemblies and merge with pre-existing profiles
    */
    CHEWBBACA_ALLELECALLING(
        INPUT_CHECK.out.assembly,
        ch_previous_profiles,
        ch_chewie_schema.collect(),
    )
    ch_matrix = CHEWBBACA_ALLELECALLING.out.matrix
    ch_chewie_stats = ch_chewie_stats.mix(CHEWBBACA_ALLELECALLING.out.stats.mix(CHEWBBACA_ALLELECALLING.out.logs))
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALLING.out.versions)
    
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
            tuple([sample_id: params.run_name], s)
        }
    ).join(
        CUSTOM_DUMPSOFTWAREVERSIONS.out.yml.map { y ->
            tuple([sample_id: params.run_name], y)
        }
    ).join(
        ch_chewie_stats.map { m ,s ->
            tuple([sample_id: params.run_name], s)
        }
    ).set { ch_summary_input }
    
    // Summarize results as JSON
    SUMMARY(
        ch_summary_input,
        pipeline_info
    )
    ch_versions = ch_versions.mix(SUMMARY.out.versions)

    // Generate HTML report
    REPORT(
        SUMMARY.out.json,
        ch_bella_template,
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

// turn the summaryMap to a JSON file
def dumpParametersToJSON(outdir) {
    def timestamp = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
    def filename  = "params_${timestamp}.json"
    def temp_pf   = new File(workflow.launchDir.toString(), ".${filename}")
    def jsonStr   = groovy.json.JsonOutput.toJson(params)
    temp_pf.text  = groovy.json.JsonOutput.prettyPrint(jsonStr)

    nextflow.extension.FilesEx.copyTo(temp_pf.toPath(), "${outdir}/pipeline_info/params_${timestamp}.json")
    temp_pf.delete()
    return file("${outdir}/pipeline_info/params_${timestamp}.json")
}