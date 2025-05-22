# Usage information

[Basic execution](#basic-execution)

[Pipeline version](#specifying-pipeline-version)

## Basic execution

Please see our [installation guide](installation.md) to learn how to set up this pipeline first. 

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run marchoeppner/spread -profile singularity --input samples.tsv \\
--reference_base /path/to/references \\
--run_name pipeline-test
```

where `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references (this can be omitted to trigger an on-the-fly temporary installation, but is not recommended in production). 

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Available options to provision software are:

`-profile singularity`

`-profile docker` 

`-profile podman` 

`-profile conda` 

Additional software provisioning tools as described [here](https://www.nextflow.io/docs/latest/container.html) may also work, but have not been tested by us. Please note that conda may not work for all packages on all platforms. If this turns out to be the case for you, please consider switching to one of the supported container engines. 

b) with a site-specific config file

```bash
nextflow run marchoeppner/spread -profile lsh --input samples.tsv \\
--run_name pipeline-test 
```

In this example, both `--reference_base` and the choice of software provisioning are already set in the local configuration `lsh` and don't have to be provided as command line argument. 

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run marchoeppner/spread -profile lsh -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/marchoeppner/gabi/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Options

### `--input` [default = null]

A list of assemblies to analyze in TSV format

```TSV
sample  assembly
sampleA /path/to/sampleA.fasta
sampleB /path/to/sampleB.fasta
...
```

Assemblies should come from an assembly workflow with proper quality control - such as [GABI](https://github.com/bio-raum/gabi) or [AQUAMIS](https://gitlab.com/bfr_bioinformatics/AQUAMIS).

You have to provide all assemblies you want to analyse, every time you run the workflow.

### `--nomenclature` [ default = null]

A nomenclature for your clusters and singletons to carry over between analyses. This option is useful if you want the clusters to follow some specific naming pattern instead of the build-in schema (cluster_1, singleton_1).

The easiest approach is to use the partitions.tsv file from your very first analysis, rename clusters and contigs (optionally per partition) and feed that edited file into the next analysis via this command line option. This process has to be repeated on subsequent runs to continue the naming pattern. There is currently no way to force ReportTree to adopt a specific naming strategy by itself.  

```TSV
sequence	MST-1x1.0	MST-4x1.0	MST-7x1.0
sample_0504	MyCluster_35	MyCluster_82	MyCluster_65
sample_0525	MyCluster_35	MyCluster_82	MyCluster_65
sample_0526	MyCluster_35	MyCluster_82	MyCluster_65
sample_0534	MyCluster_35	MyCluster_82	MyCluster_65
sample_0544	MyCluster_35	MyCluster_82	MyCluster_65
```

Some more information on how nomenclatures in ReporTree work [here](https://github.com/insapathogenomics/ReporTree/wiki/3.-Nomenclature).

### `--metadata` [defualt = null]

A metadata file that associates samples with relevant information about e.g. date of sampling, sampling context (e.g. clinical vs food_processing etc). The choice of metadata keys is up to you and they do not have an influence on the analysis as such, but can be used during visualization etc to reveal patterns.

The file must be in TSV format:

```TSV
sample	country	region	source	date	ST	note
sample_0001	A	A1	clinical	21/11/2021	na	not_real_data_test_only
sample_0002	B	B1	clinical	10/11/2021	na	not_real_data_test_only
sample_0003	C	B1	clinical	24/10/2021	388	not_real_data_test_only
sample_0004	A	A2	clinical	18/10/2021	77	not_real_data_test_only
sample_0005	B	B2	clinical	03/10/2021	3	not_real_data_test_only
sample_0006	C	B2	clinical	23/09/2021	217	not_real_data_test_only
sample_0007	A	A3	clinical	18/09/2021	388	not_real_data_test_only
sample_0008	B	B3	clinical	12/09/2021	217	not_real_data_test_only
```
### `--species` [ default = null]

A schema for a pre-configured species. Currently supported options are:

- campylobacter
- escherichia
- listeria
- salmonella

May optionally be combined with `--efsa`. Mutually exclusive with `--schema`. 

### `--schema` [ default = null ]

A path to a chewbbaca 3.3.x compatible cg/wgMLST schema. May be used instead of `--species`.

### `--efsa` [ default = false]

Use a modified version of a pre-configured schema following EFSA recommendations. This is only available for select species. 