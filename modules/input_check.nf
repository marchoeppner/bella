//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.tsv

    main:

    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> assembly_channel(row) }
        .set { assembly_out }

    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> profile_channel(row) }
        .set { profiles_out }

    emit:
    assembly = assembly_out // channel: [ val(meta), [ reads ] ]
    profiles = profiles_out
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
