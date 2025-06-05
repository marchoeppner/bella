include { CHEWBBACA_ALLELECALL }    from './../../modules/chewbbaca/allelecall'
include { CHEWBBACA_JOINPROFILES }  from './../../modules/chewbbaca/joinprofiles'
include { CHEWBBACA_EXTRACTCGMLST } from './../../modules/chewbbaca/extractcgmlst'

workflow CHEWBBACA_PARALLEL {

    take:
    assemblies
    chewie_db

    main:

    ch_versions = Channel.from([])

    // Perform allele calling per assembly
    CHEWBBACA_ALLELECALL(
        assemblies,
        chewie_db.collect()
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)

    // Join allele calles across samples
    CHEWBBACA_JOINPROFILES(
        CHEWBBACA_ALLELECALL.out.profile.map { m,r ->
            [
                [ sample_id: params.run_name ],
                r
            ]
        }.groupTuple()
    )
    ch_versions = ch_versions.mix(CHEWBBACA_JOINPROFILES.out.versions)
    
    // Filter matrix for valid positions
    CHEWBBACA_EXTRACTCGMLST(
        CHEWBBACA_JOINPROFILES.out.report
    )
    ch_versions = ch_versions.mix(CHEWBBACA_EXTRACTCGMLST.out.versions)

    emit:
    versions = ch_versions
    matrix = CHEWBBACA_EXTRACTCGMLST.out.report
    stats = CHEWBBACA_ALLELECALL.out.stats

}