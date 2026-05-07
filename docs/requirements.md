# Requirements

## Computing

Bella is a relatively light-weight pipeline, so a typical (modern) Laptop or Desktop computer should work. The pipeline is however developed primarily for powerful workstations and computing clusters, so should work best on such a system. The limiting factor will most likely be RAM, which will increase with the number of samples. That said, for most users with dozens or hundreds of samples, Bella should run fine with 4-8 CPU cores and 16GB RAM. 

## Contamination

Please make sure that your assemblies are free of contaminations. This not only includes inter-species contaminations, but especially intra-species contaminations. Contaminated assemblies may lied to incorrect conclusions!

*Inter-species*: Such contaminations may happen when the culture for sequencing was not produced from a single (clonal) colony or when principles of clean working are not strictly followed. The main consequence of such contaminations are "mixed" assemblies, meaning that the resulting contigs are a mix of two or more species. While such contaminations are relatively straight-forward to detect (by size, or gc content, or taxonomic identity of the individual contigs), the data should not be used for cgMLST analysis.

*Intra-species*: These contaminations are often hard to spot just by looking at the final assembly. Mixing data from two or more individuals from the same species may produce seemingly correct assemblies (in terms of overall size and taxonomic signal), but could produce per-base information that does not reflect one or the other isolate exactly. Detection of these kinds of contaminations requires a careful analysis of sequence variability, using for example [ConfindR](https://github.com/OLC-Bioinformatics/ConFindr). Performing cgMLST analysis with assemblies contaminated in this way would potentially not yield the true genetic distances to other isolates in the analysis and thus produce incorrect conclusions. 

Please only use assemblies produced with a pipeline that performs thourough contamination checks! We recommend [bio-raum/gabi](https://github.com/bio-raum/gabi).

## Species 

A cgMLST schema is specific to a species. Please make sure that your assemblies match the species of the schema you want to use, as Bella does not perform a sanity check for this. 

