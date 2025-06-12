#!/usr/bin/env python
import plotly.express as px
from jinja2 import Template
import datetime
import json
import getpass
import argparse
import colorsys

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--input", help="An input option")
parser.add_argument("--template", help="A JINJA2 template")
parser.add_argument("--version", help="Pipeline version")
parser.add_argument("--call", help="Command line call")
parser.add_argument("--wd", help="work directory")
parser.add_argument("--distance", help="Distance for clustering")
parser.add_argument("--output")

args = parser.parse_args()

status = {
    "pass": "pass",
    "warn": "warn",
    "fail": "fail",
    "missing": "missing"
}


def generate_distinct_colors(n):
    colors = []
    for i in range(n):
        # Generate a color in HSL 
        hue = i / n  # evenly spaced hues 
        lightness = 0.7  # fixed lightness 
        saturation = 0.7  # 70% saturation for a pastelle palette
        rgb = colorsys.hls_to_rgb(hue, lightness, saturation) 
        # Convert from [0, 1] to [0, 255] and round 
        rgb = tuple(int(c * 255) for c in rgb) 
        # and turn into a hex color
        colors.append('#%02x%02x%02x' % rgb)
    return colors


def main(json_file, template, output, version, call, wd, distance):

    data = {}

    data["user"] = getpass.getuser()
    data["date"] = datetime.datetime.now()
    data["version"] = version
    data["call"] = call
    data["wd"] = wd
    data["cluster_distance"] = distance
    data["summary"] = []

    with open(json_file) as f:
        jdata = json.load(f)
        f.close

    data["nwk"] = jdata["tree"]
    summary = {}

    # ReporTree Cluster information
    if distance in jdata["clusters"]:
        samples = jdata["clusters"][distance]
        sample_color = {}
        cluster_color = {}
        cluster_samples = {}
        unique_clusters = []
        counter = {}
        # check how many clusters have more than one sample
        # this is so singletons don't get a color.
        for sample, cluster in samples.items():
            if cluster in counter:
                counter[cluster] += 1
            else:
                counter[cluster] = 1

        for cluster, count in counter.items():
            if count > 1:
                unique_clusters.append(cluster)

        color_map = generate_distinct_colors(len(unique_clusters))
        default_color = "#9fa8ad"

        for sample, cluster in samples.items():
            if cluster not in cluster_color:
                # this is a cluster with multiple samples
                if counter[cluster] > 1:
                    color = color_map.pop()
                # this is a singleton, color it grey
                else:
                    color = default_color
                cluster_color[cluster] = color
            sample_color[sample] = cluster_color[cluster]

            summary[sample] = {"cluster": cluster, "distance": distance, "color": sample_color[sample]}
            if cluster in cluster_samples:
                cluster_samples[cluster].append(sample)
            else:
                cluster_samples[cluster] = [sample]

        data["sample_color"] = sample_color
        data["cluster_color"] = cluster_color
        data["cluster_samples"] = dict(sorted(cluster_samples.items()))

    # subsetting distance matrix per cluster
    distances = jdata["distance"]["data"]
    for cluster, samples in cluster_samples.items():
        indices = []
        for sample in samples:
            indices.append(jdata["distance"]["x"].index(sample))
        for sample in samples:
            this_distances = distances[jdata["distance"]["x"].index(sample)]
            dmatrix = [this_distances[i] for i in indices]
            summary[sample]["matrix"] = dmatrix

    # reporTree Locus report
    for locus in jdata["loci_report"]:
        sample = locus["samples"]
        summary[sample]["called"] = locus["called"]
        summary[sample]["missing"] = locus["missing"]
        pct_called = round(float(locus["pct_called"]) * 100, 2)

        summary[sample]["pct_called"] = pct_called

        sample_status = status["missing"]
        if (pct_called < 0.85):
            sample_status = status["fail"]
        elif (pct_called < 0.95):
            sample_status = status["warn"]
        else:
            sample_status = status["pass"]

        summary[sample]["status"] = sample_status

    # Chewbbaca allele calling stats
    for cstats in jdata["chewbbaca_stats"]:
        sample = cstats["FILE"]
        summary[sample]["classified_cds"] = cstats["Classified_CDSs"]
        summary[sample]["invalid_cds"] = cstats["Invalid CDSs"]
        summary[sample]["total_cds"] = cstats["Total_CDSs"]
        summary[sample]["perc_classified"] = round(float(cstats["Classified_CDSs"]) / (float(cstats["Total_CDSs"])) * 100, 2)

    data["summary"] = summary

    matrix = jdata["distance"]

    #############
    # Plots
    #############

    # hamming distance heat map
    hdata = matrix["data"]
    fig = px.imshow(hdata,
                    labels=dict(color="Allele distance"),
                    x=matrix["x"],
                    y=matrix["y"]
                    )
    data["distances"] = fig.to_html(full_html=False)

    ##############################
    # Software versions
    ##############################

    data["packages"] = jdata["software"]

    ########################
    # Render Jinja2 template
    ########################

    with open(output, "w", encoding="utf-8") as output_file:
        with open(template) as template_file:
            j2_template = Template(template_file.read())
            output_file.write(j2_template.render(data))


if __name__ == '__main__':
    main(args.input, args.template, args.output, args.version, args.call, args.wd, args.distance)
