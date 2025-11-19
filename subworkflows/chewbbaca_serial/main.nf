include { CHEWBBACA_ALLELECALL }            from './../../modules/chewbbaca/allelecall'
include { CHEWBBACA_ALLELECALLEVALUATOR }   from './../../modules/chewbbaca/allelecallevaluator'
include { CHEWBBACA_EXTRACTCGMLST }         from './../../modules/chewbbaca/extractcgmlst'

workflow CHEWBBACA_SERIAL {
    
    take:
    assemblies
    chewie_db

    main:

    ch_versions = channel.from([])

    /*
    Perform joint allele calling - this may be too slow for large data sets, may need adjusting
    */
    CHEWBBACA_ALLELECALL(
        assemblies.map { m,a ->
            [
                [ sample_id: params.run_name],
                a
            ]
        }.groupTuple().collect(),
        chewie_db.collect()
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)

    // Evaluate the call performance
    CHEWBBACA_ALLELECALLEVALUATOR(
        CHEWBBACA_ALLELECALL.out.report,
        chewie_db
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALLEVALUATOR.out.versions)

    // Filter matrix for valid positions, this removes Chewbbaca codes that have no use here
    CHEWBBACA_EXTRACTCGMLST(
        CHEWBBACA_ALLELECALL.out.profile
    )
    ch_versions = ch_versions.mix(CHEWBBACA_EXTRACTCGMLST.out.versions)

    emit:
    versions = ch_versions
    matrix = CHEWBBACA_EXTRACTCGMLST.out.report
    logs = CHEWBBACA_ALLELECALL.out.logs
    stats = CHEWBBACA_ALLELECALL.out.stats

}