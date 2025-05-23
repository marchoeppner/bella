include { CHEWBBACA_DOWNLOADSCHEMA }            from './../modules/chewbbaca/downloadschema'
include { CHEWBBACA_PREPEXTERNALSCHEMA }        from './../modules/chewbbaca/prepexternalschema'
include { CHEWBBACA_ALLELECALL_INSTALL }        from './../modules/chewbbaca/allelecall_install'
include { GUNZIP }                               from './../modules/gunzip'

workflow BUILD_REFERENCES {

    def schemas = []
    def filters = []
    def assemblies = []
    def final_schemas = []
    /* 
    Building a list of schemas to download, pre-configured in the resources.config file
    */
    params.references.keySet().each { k ->
        schemas << [ [ sample_id: k] , params.references[k].species_id, params.references[k].schema_id ]
        assemblies << [ [ sample_id: k], file(params.references[k].ref) ]
        final_schemas << [ [ sample_id: k], file(params.references[k].db)]
        if (params.references[k].filter ) {
            filters << [ [ sample_id: k], params.references[k].filter ]
            final_schemas << [ [ sample_id: k], file(params.references[k].efsa) ]
        }
    }

    ch_schemas = Channel.fromList(schemas)
    ch_filters = Channel.fromList(filters)
    ch_assemblies = Channel.fromList(assemblies)
    ch_final_schemas = Channel.fromList(final_schemas)

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

    // decompress assemblies
    GUNZIP(
        ch_assemblies
    )

    CHEWBBACA_DOWNLOADSCHEMA.out.schema.map { m, s, t ->
        tuple(m,s)
    }.concat(
        CHEWBBACA_PREPEXTERNALSCHEMA.out.filtered_schema
    ).set { ch_processed_schemas }


    /*
    We combine all the schemas with the assemblies based on matching keys
    and then run each assembly against each schema to seed it for subsequent use
    */

    ch_schema_with_assemblies = GUNZIP.out.gunzip.combine(ch_processed_schemas, by: 0)
   
    CHEWBBACA_ALLELECALL_INSTALL(
        ch_schema_with_assemblies
    )
}