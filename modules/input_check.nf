//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep:',')
        .map { row -> fastq_channel(row) }
        .set { assembly }

    emit:
    assembly // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, assembly ]
def fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.sample_id    = row.sample_id

    if (!file(row.fasta).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> the assembly does not exist!\n${row.fasta}"
    }
  
    def array = [ meta, file(row.fasta) ]
    return array
}
