// Modules
include { INPUT_CHECK }                     from './../modules/input_check'
include { REPORTREE }                       from './../modules/reportree'
include { MULTIQC }                         from './../modules/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS }     from './../modules/custom/dumpsoftwareversions'
include { SUMMARY }                         from './../modules/helper/summary'
include { REPORT }                          from './../modules/helper/report'
include { HELPER_EXTRACT_ALLELES }          from './../modules/helper/extract_alleles'
include { CHEWBBACA_ALLELECALL }            from './../modules/chewbbaca/allelecall'
include { CHEWBBACA_JOINPROFILES }          from './../modules/chewbbaca/joinprofiles'
include { CHEWBBACA_EXTRACTCGMLST }         from './../modules/chewbbaca/extractcgmlst'
include { CHEWBBACA_ALLELECALLEVALUATOR  }  from './../modules/chewbbaca/allelecallevaluator'

/*
Include sub workflows
*/
// include { CHEWBBACA_ALLELECALLING }         from './../subworkflows/chewbbaca_allelecalling'

workflow BELLA {

    main:

    ch_multiqc_config   = params.multiqc_config   ? channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : channel.value([])
    ch_multiqc_logo     = params.multiqc_logo     ? channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : channel.value([])
    ch_bella_template   = params.template         ? channel.fromPath(params.template, checkIfExists: true).collect() : channel.value([])
    ch_profiles         = Channel.from([])
    ch_assemblies       = Channel.from([])
    
    samplesheet         = params.input      ? channel.fromPath(params.input, checkIfExists:true ).collect()     : channel.from([])
    existing_profiles   = params.alleles    ? channel.fromPath(params.alleles, checkIfExists: true). collect()  : channel.from([])
    
    /*
    Get the corect schema to use - either from a pre-configured species or as user-provided path
    We use this as a value since the the locking/unlocking modifies the folder
    */
    schema_dir          = get_schema_dir(params)
    if (!schema_dir) {
        log.info "No schema defined - exiting!"
        System.exit(1)
    } else {
        schema_file = file(schema_dir, checkIfExists: true)
    }
    
    ch_nomenclature     = params.nomenclature ? file(params.nomenclature, checkIfExists: true) : channel.from(false)
    ch_metadata         = params.metadata ? file(params.metadata, checkIfExists: true) : channel.from(false)

    ch_versions     = channel.from([])
    multiqc_files   = channel.from([])

    // Dummy value for stats 
    ch_chewie_stats = channel.from([ [[sample_id: params.run_name],file("${baseDir}/assets/email_template.txt")] ])

    pipeline_info = channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

    /* Check if schema directory is locked
    and unlock if requested
    */
    lockfile = file("${schema_dir.toString()}/bella.lock")
    if (lockfile.exists()) {
        log.info "Schema directory appears locked."
        if (params.unlock) {
            log.info "Unlocking!"
            lockfile.delete()
        } else {
            log.info "Cannot run pipeline while schema is locked!\n"
            log.info "If you are sure that it is safe to do so, please use --unlock"
            System.exit(1)
        }
    }

    /*
    Check that the samplesheet is valid and create channels
    */
    INPUT_CHECK(samplesheet.mix(existing_profiles))

    ch_assemblies = ch_assemblies.mix(INPUT_CHECK.out.assembly)
    ch_profiles = ch_profiles.mix(INPUT_CHECK.out.profiles)
    ch_metas = ch_assemblies.map {m, a -> m }

    /*
    Run allele calling on all new assemblies and merge with pre-existing profiles
    */

    // Perform allele calling on assemblies

    // Optional: combine all assemblies into one calling job
    if (params.joint_calling) {
        ch_assemblies = ch_assemblies.map { m, a -> tuple([sample_id: params.run_name], a)}.groupTuple()
    }

    CHEWBBACA_ALLELECALL(
        ch_assemblies,
        schema_dir
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)    
    
    // Extract individual allele profiles if joint calling was performed
    if (params.joint_calling) {
        HELPER_EXTRACT_ALLELES(
            ch_metas.combine(
                CHEWBBACA_ALLELECALL.out.profile.mix(CHEWBBACA_ALLELECALL.out.hashed_profile).map { m, p -> p }
            )
        )
    }
    // combine computed profiles with pre-computed profiles - hashed or unhashed
    if (params.hashed) {
        ch_profiles = ch_profiles.mix(CHEWBBACA_ALLELECALL.out.hashed_profile)
    } else {
        ch_profiles = ch_profiles.mix(CHEWBBACA_ALLELECALL.out.profile)
    }

    // Evaluate allele calls 
    CHEWBBACA_ALLELECALLEVALUATOR(
        CHEWBBACA_ALLELECALL.out.report,
        schema_dir
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALLEVALUATOR.out.versions)

    // Join profiles, if applicable (i.e. we have pre-computed alleles and/or the assemblies were called individually)
    if (params.alleles || !params.joint_calling) {
        // Join allele calls across samples
        CHEWBBACA_JOINPROFILES(
            ch_profiles.map { m,r ->
                [[ sample_id: params.run_name ], r]
            }.groupTuple()
        )
        ch_versions = ch_versions.mix(CHEWBBACA_JOINPROFILES.out.versions)
        ch_joint_profiles = CHEWBBACA_JOINPROFILES.out.report
    } else {
        ch_joint_profiles = ch_profiles
    }
    
    // Filter matrix for valid positions
    CHEWBBACA_EXTRACTCGMLST(
        ch_joint_profiles
    )
    ch_versions = ch_versions.mix(CHEWBBACA_EXTRACTCGMLST.out.versions)

    ch_matrix       = CHEWBBACA_EXTRACTCGMLST.out.report
    ch_chewie_stats = ch_chewie_stats.mix(CHEWBBACA_ALLELECALL.out.stats)
    ch_chewie_stats = ch_chewie_stats.mix(CHEWBBACA_ALLELECALL.out.logs)
    
    ch_chewie_stats.map { m ,s ->
        tuple([sample_id: params.run_name], s)
    }.set { ch_grouped_stats }

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
        CUSTOM_DUMPSOFTWAREVERSIONS.out.yml.map { y ->
            tuple([sample_id: params.run_name], y)
        }
    ).join(
       ch_grouped_stats.groupTuple()
    ).set { ch_summary_input }
    
    // Summarize results as JSON
    SUMMARY(
        ch_summary_input,
        schema_dir,
        pipeline_info
    )
    ch_versions = ch_versions.mix(SUMMARY.out.versions)

    // Generate HTML report
    REPORT(
        SUMMARY.out.json,
        ch_bella_template
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

def get_schema_dir(params) {

    def schema_dir = null

    // Validation happens in lib/WorkflowPipeline
    if (params.species) {
        if (params.efsa) {
            if (params.references[params.species].efsa) {
                schema_dir = params.references[params.species].efsa
            } else {
                log.warn "No EFSA schema defined for ${params.species} - falling back to default schema."
                schema_dir = params.references[params.species].db
            }
        } else {
            schema_dir = params.references[params.species].db
        }
    } else if (params.schema) {
        schema_dir = params.schema
    }

    return schema_dir
}