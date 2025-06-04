//
// This file holds functions to validate user-supplied arguments
//

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise( worfklow, params, log) {
         
        if (params.input && !params.run_name) {
            log.info 'Must provide a run_name (--run_name)'
            System.exit(1)
        }
        if (!params.input && !params.build_references) {
            log.info "Pipeline requires a sample sheet as input (--input)"
            System.exit(1)
        }
        if (!params.build_references && params.species && params.schema) {
            log.info "May only use one: --species or --schema\nExiting!"
            System.exit(1)
        }
        if (!params.build_references && !params.species && !params.schema) {
            log.info "Must provide path to a valid Chewbbaca schema folder"
            System.exit(1)
        }
        if (!params.species && !params.distance) {
            log.info "Must provide a clustering distance to use as default (int)."
            System.exit(1)
        }
       
    }

}
