include { CHEWBBACA_DOWNLOADSCHEMA }            from './../modules/chewbbaca/downloadschema'
include { CHEWBBACA_PREPEXTERNALSCHEMA }        from './../modules/chewbbaca/prepexternalschema'


workflow BUILD_REFERENCES {

    def schemas = []
    def filters = []

    /* 
    Building a list of schemas to download, pre-configured in the resources.config file
    */
    params.references.keySet().each { k ->
        schemas << [ [ sample_id: k] , params.references[k].species_id, params.references[k].schema_id ]
        if (params.references[k].filter ) {
            filters << [ [ sample_id: k], params.references[k].filter ]
        }
    }

    ch_schemas = Channel.fromList(schemas)
    ch_filters = Channel.fromList(filters)

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
    manually filtering the locus list
    */
    CHEWBBACA_PREPEXTERNALSCHEMA(
        schema_with_filter
    )
}