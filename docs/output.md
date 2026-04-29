# Outputs 

## Reports

<details markdown=1>
<summary>reports</summary>

BELLA generates the following outputs:

`chewbbaca` - contains results from the Chewbbaca analysis to percm cgMLST calling
`reportree` - contains results from the ReporTree clustering analysis
`report` - contains a graphical report of this analysis with some useful metrics and visualizations in HTML format. 

</details>

<details markdown=1>
<summary>html</summary>

Bella generates an interactive report in HTML file, summarizing the relevant per-sample metrics as well as resulting clustering using the pre-configured or user-specified clustering distance. 

Summary

![summary](../images/bella_report_summary.png)

Hamming distances

![distances](../images/bella_report_hamming.png)

Minimum spanning tree

![tree](../images/bella_report_tree.png)

</details>

## Pipeline run metrics

<details markdown=1>
<summary>pipeline_info</summary>

This folder contains the pipeline run metrics

- pipeline_dag.svg - the workflow graph (only available if GraphViz is installed)
- pipeline_report.html - the (graphical) summary of all completed tasks and their resource usage
- pipeline_report.txt - a short summary of this analysis run in text format
- pipeline_timeline.html - chronological report of compute tasks and their duration
- pipeline_trace.txt - Detailed trace log of all processes and their various metrics

</details>
