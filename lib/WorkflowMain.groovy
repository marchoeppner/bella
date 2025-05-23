//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//
class WorkflowMain {

    //
    // Check and validate parameters
    //
    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {
        log.info header(workflow)


        if (!workflow.containerEngine) {
            log.warn "This pipeline cannot be used with Conda or Spack, sorry! Please use a supported container engine. Exiting..."
            System.exit(1)
        }

    }

    // TODO: Change name of the pipeline below
    public static String header(workflow) {
        def headr = ''
        def infoLine = "${workflow.manifest.description} | version ${workflow.manifest.version}"
        headr = """
    ===============================================================================
    ${infoLine}
    ===============================================================================
    """
        return headr
    }

}
