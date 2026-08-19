include { CHEWBBACA_DOWNLOADSCHEMA }            from './../modules/chewbbaca/downloadschema'
include { CHEWBBACA_PREPEXTERNALSCHEMA }        from './../modules/chewbbaca/prepexternalschema'
include { CHEWBBACA_ALLELECALL_INSTALL }        from './../modules/chewbbaca/allelecall_install'
include { GUNZIP }                              from './../modules/gunzip'

workflow BUILD_REFERENCES {

    def schemas = []
    def filters = []
    def final_schemas = []

    // Get a list of species from chewieNS
    def species_list = get_species_list()

    /* 
    Building a list of schemas to download, pre-configured in the resources.config file
    */
    params.references.keySet().each { k ->
        def species = params.references[k].species
        if (species_list[species]) {
            schemas << [ [ sample_id: k] , species_list[species], params.references[k].schema_id ]
            final_schemas << [ [ sample_id: k], file(params.references[k].db)]
            if (params.references[k].filter ) {
                filters << [ [ sample_id: k], params.references[k].filter ]
                final_schemas << [ [ sample_id: k], file(params.references[k].efsa) ]
            }
        } else {
            log.warn "Missing schema for ${species}!!!"
        }
    }

    ch_schemas = channel.fromList(schemas)
    ch_filters = channel.fromList(filters)
    //ch_filters = channel.empty()

    // Download the schema by id
    CHEWBBACA_DOWNLOADSCHEMA(
        ch_schemas
    )

    // join the schema with a filter list, if any, to create filtered schema
    CHEWBBACA_DOWNLOADSCHEMA.out.schema.join(
        ch_filters
    ).set { schema_with_filter }

    /* Reformat the schema to limit loci to the filter list
    We do this to use the built-in filter function instead of
    manually filtering the locus list. This also accepts 2-column
    filter lists and will rename loci based on column 2.
    */
    CHEWBBACA_PREPEXTERNALSCHEMA(
        schema_with_filter
    )

}

def get_species_list() {

    def j = new groovy.json.JsonSlurper().parseText(new URL("https://chewbbaca.online/NS/api/species/list").getText())

    def species = [:]
    
    j.each { s ->
        def url = s.species.value
        def name = s.name.value
        species[name] = url.split("/")[-1]
    }

    return species
}