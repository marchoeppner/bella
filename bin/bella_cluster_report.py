#!/usr/bin/env python
import plotly.express as px
from jinja2 import Template
import datetime
import csv
import getpass
import argparse
import colorsys

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--input", help="An input option")
parser.add_argument("--template", help="A JINJA2 template")
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


def main(partitions, template, output, distance):

    data = {}

    data["user"] = getpass.getuser()
    data["date"] = datetime.datetime.now()
    data["cluster_distance"] = distance
    data["clusters"] = {}

    with open(partitions) as f:
        records = csv.DictReader(f, delimiter="\t")
        f.close

    summary = {}

    for record in records.items():
        cluster = "none"
        if data[f"MST-{distance}x1.0"]:
            cluster = data[f"MST-{distance}x1.0"]

        if cluster in summary:
            summary[cluster].append(record)
        else:
            summary[cluster] = [record]

    data["clusters"] = summary

    ########################
    # Render Jinja2 template
    ########################

    with open(output, "w", encoding="utf-8") as output_file:
        with open(template) as template_file:
            j2_template = Template(template_file.read())
            output_file.write(j2_template.render(data))


if __name__ == '__main__':
    main(args.input, args.template, args.output, args.distance)
