# Usage information

[Basic execution](#basic-execution)

[Pipeline version](#specifying-pipeline-version)

## Basic execution

Please see our [installation guide](installation.md) to learn how to set up this pipeline first. 

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run marchoeppner/bella -profile singularity -r 1.0 --input samples.tsv \\
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
nextflow run marchoeppner/bella -profile lsh -r 1.0 --input samples.tsv \\
--run_name pipeline-test 
```

In this example, both `--reference_base` and the choice of software provisioning are already set in the local configuration `lsh` and don't have to be provided as command line argument. 

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run marchoeppner/bella -profile lsh -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/marchoeppner/bella/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Testing

The pipeline has a built-in test, which you can use to verify your installation. 

```bash
nextflow run marchoeppner/bella -profile singularity,test --reference_base /path/to/references 
```

where `singularity` may be replaced with whatever is appropriate for your system (including a site-specific config, which then makes the `--reference_base` argument obsolete).

This test will download 10 Listeria monocytogenes assemblies from a recent ring trial, which includes 3 clusters of 2 samples at a clustering distance of 10.

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

You have to provide all assemblies you want to analyse, every time you run the workflow. There is currently no way to do this incrementally; although the pipeline will re-use previously computed allele profiles if you run with the `--parallel_calling` (see below).

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

Alternatively, you can provide a simpler format without information on the partition levels like so:

```TSV
sequence	group
sample_0241	Lm_1
sample_0212	Lm_1
sample_0168	Lm_1
sample_0253	Lm_1
sample_0613	Lm_1
sample_0652	Lm_2
sample_0644	Lm_2
sample_0651	Lm_2
```

Note that ReporTree will always fall back to the built-in nomenclature system when it encounters new clusters. 

Some more information on how nomenclatures in ReporTree work [here](https://github.com/insapathogenomics/ReporTree/wiki/3.-Nomenclature).

### `--metadata` [default = null]

A metadata file that associates samples with relevant information about e.g. date of sampling, sampling context (e.g. clinical vs food_processing etc). The choice of metadata keys is up to you and they do not have an influence on the analysis as such, but can be used during visualization etc to reveal patterns.

The file must be in TSV format, for example:

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
### `--parallel_calling` [ default = false ]

BELLA will run Chewbbaca in bulk mode by default (i.e. all assemblies are analysed in the same process). This saves startup time and is recommended for smaller data sets (< 100 samples). If you are analyzing very large data sets, it can instead be preferrable to compute allele profiles per assembly in parallel to make full use of larger compute infrastructures. For that, use this option. This has the added advantage of allowing you to add additional assemblies later without the need to recompute all the allele profiles. 

### `--species` [ default = null]

A schema for a pre-configured species. Currently supported options are:

| species/genus | Source | Description | Has EFSA schema | Default cluster distance |
| ------------- | ------ | ----------- | --------------- | ------------------------ |
| campylobacter | [ChewieNS](https://chewbbaca.online/species/4/schemas/1) | INNUENDO whole genome MLST schema for Campylobacter jejuni | No | 7 |
| escherichia   | [ChewieNS](https://chewbbaca.online/species/5/schemas/1) | INNUENDO whole genome MLST schema for Escherichia coli | Yes | 10 |
| listeria      | [ChewieNS](https://chewbbaca.online/species/6/schemas/1) | Listeria monocytogenes cgMLST scheme from BIGSdb-Pasteur | No | 10 |
| salmonella    | [ChewieNS](https://chewbbaca.online/species/8/schemas/1) | INNUENDO whole genome MLST schema for Salmonella enterica | Yes | 10 |

Where available, `--species` may optionally be combined with `--efsa`. Mutually exclusive with `--schema`. 

### `--distance` [ default = null ]

A custom clustering distance to use in the graphical report (the full results are available in TSV format for downstream processing). Pre-configured schema (--species) use a pre-set distance (which you can override with this option).

### `--schema` [ default = null ]

A path to a chewbbaca 3.3.x compatible cg/wgMLST schema (i.e. the folder holding the allele fasta files). May be used instead of `--species`. Schemas can be downloaded from [chewie-ns](https://chewbbaca.readthedocs.io/en/latest/user/modules/DownloadSchema.html) or may instead be produced from compatible input data using [Chewbbaca PrepExternalSchema](https://chewbbaca.readthedocs.io/en/latest/user/modules/PrepExternalSchema.html).

### `--efsa` [ default = false]

Use a modified version of a pre-configured schema following [EFSA](https://www.efsa.europa.eu/en) recommendations. This is only available for select species. 

## Expert options

These are options that you normally wouldn't need to change. 

### `--partitions`  [default = stablity_regions ]

Partitions refer to the allele distance for clustering samples together. By default, this option is set to `stablity_regions` to analyse the range of values under which clusters remain stable.