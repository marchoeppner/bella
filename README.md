# BELLA Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![run with apptainer](https://img.shields.io/badge/apptainer-run?logo=apptainer&logoColor=3EB049&label=run%20with&labelColor=000000)](https://apptainer.org/)

![schema](images/bella_schema_v1.png)

This pipeline takes assembled bacterial genomes (as well as previously computed allele profiles) as input and performs a clustering analysis to support epidemiological inqueries into outbreak scenarios. It uses [Chewbbaca](https://chewbbaca.readthedocs.io/en/latest/) to perform cgMLST calling and then reconstructs the relationship of your samples with [ReporTree](https://github.com/insapathogenomics/ReporTree). ReporTree performs clustering of samples using a range of (pre-configured) distances, so makes it easy to adopt a pre-configured distance or inspect a range of distances. ReporTree allows you to feed your own nomenclature and metadata into the analysis. 

BELLA is primarily meant to be used with foodborne pathogens, such as *Campylobacter jejuni*, *E. coli*, *Listeria monocytogenes* and *Salmonella enteria* (i.e. it comes with allele schemas for these four species). Other species are supported of course, if you provide a compatible schema database (Chewbbaca v3.3x).

## Documentation 

1. [What happens in this pipeline?](docs/pipeline.md)
2. [Installation and configuration](docs/installation.md)
3. [Running the pipeline](docs/usage.md)
4. [Output](docs/output.md)
5. [Software](docs/software.md)
5. [Troubleshooting](docs/troubleshooting.md)
6. [Developer guide](docs/developer.md)
