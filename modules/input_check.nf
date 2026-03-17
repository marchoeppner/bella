//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.tsv

    main:

    ch_profiles = Channel.from([])
    ch_assemblies = Channel.from([])

    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> assembly_channel(row) }
        .set { assembly_out }

    ch_assemblies = ch_assemblies.mix(assembly_out)

    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> profile_channel(row) }
        .set { profiles_out }

    ch_profiles = ch_profiles.mix(profiles_out)

    emit:
    assembly = ch_assemblies // channel: [ val(meta), [ reads ] ]
    profiles = ch_profiles
}

def profile_channel(LinkedHashMap row) {

    def meta = [:]
    meta.sample_id  = row.sample

    if (row.profile) {

        if (!file(row.profile).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> the cgMLST profile does not exist!\n${row.profile}"
        }

        def array = [ meta, file(row.profile)]
        return array

    }

}
// Function to get list of [ meta, assembly ]
def assembly_channel(LinkedHashMap row) {
    def meta = [:]
    meta.sample_id    = row.sample

    if (row.assembly) {

        if (!file(row.assembly).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> the assembly does not exist!\n${row.assembly}"
        }
  
        def array = [ meta, file(row.assembly) ]
        return array
    }

}
