include { CHEWBBACA_DOWNLOADSCHEMA }            from './../modules/chewbbaca/downloadschema'
include { CHEWBBACA_PREPEXTERNALSCHEMA }        from './../modules/chewbbaca/prepexternalschema'


workflow BUILD_REFERENCES {

    def schemas = []
    def filters = []

    params.references.keySet().each { k ->
        schemas << [ [ sample_id: k] , params.references[k].species_id, params.references[k].schema_id ]
        if (params.references[k].filter ) {
            filters << [ [ sample_id: k], params.references[k].filter ]
        }
    }

    ch_schemas = Channel.fromList(schemas)
    ch_filters = Channel.fromList(filters)

    CHEWBBACA_DOWNLOADSCHEMA(
        ch_schemas
    )

    CHEWBBACA_DOWNLOADSCHEMA.out.schema.join(
        ch_filters
    ).set { schema_with_filter }

    schema_with_filter.view()

    CHEWBBACA_PREPEXTERNALSCHEMA(
        schema_with_filter
    )
}