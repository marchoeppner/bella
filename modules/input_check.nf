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
        .set { assembly }

    emit:
    assembly // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, assembly ]
def assembly_channel(LinkedHashMap row) {
    def meta = [:]
    meta.sample_id    = row.sample

    if (!file(row.assembly).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> the assembly does not exist!\n${row.assembly}"
    }
  
    def array = [ meta, file(row.assembly) ]
    return array
}
