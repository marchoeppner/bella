#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
===============================
bio-raum/bella
===============================

Bacterial Epidemiological Linkage and Analysis 

This Pipeline performs cgMLST clustering given assembled bacterial genomes and an existing
Chewbbaca-compatible clustering schema.

### Homepage / git
git@github.com:marchoeppner/bella.git

**/

// Pipeline version
params.version = workflow.manifest.version

include { BELLA }               from './workflows/bella'
include { BUILD_REFERENCES }    from './workflows/build_references'
include { PIPELINE_COMPLETION } from './subworkflows/pipeline_completion'

include { paramsSummaryLog }    from 'plugin/nf-schema'

workflow {

    // Print summary of supplied parameters
    log.info paramsSummaryLog(workflow)

    WorkflowMain.initialise(workflow, params, log)
    WorkflowPipeline.initialise(workflow, params, log)

    if (params.build_references) {
        BUILD_REFERENCES()
    } else {
        BELLA()
    }

    PIPELINE_COMPLETION()

}