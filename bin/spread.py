#!/usr/bin/env python
import plotly.express as px
from jinja2 import Template
import datetime
import pandas as pd
import json
import getpass
import argparse


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--input", help="An input option")
parser.add_argument("--template", help="A JINJA2 template")
parser.add_argument("--version", help="Pipeline version")
parser.add_argument("--call", help="Command line call")
parser.add_argument("--wd", help="work directory")
parser.add_argument("--output")

args = parser.parse_args()

status = {
    "pass": "pass",
    "warn": "warn",
    "fail": "fail",
    "missing": "missing"
}

def main(json_file, template, output, version, call, wd):

    data = {}

    data["user"] = getpass.getuser()
    data["date"] = datetime.datetime.now()
    data["version"] = version
    data["call"] = call
    data["wd"] = wd

    data["summary"] = []

    with open(json_file) as f:
        jdata = json.load(f)
        f.close

    data["nwk"] = jdata["tree"]

    matrix = jdata["distance"]

    #############
    # Plots
    #############

    # hamming distance heat map
    hdata = matrix["data"]
    fig = px.imshow(hdata, 
                    labels = dict( color="Allele distance"),
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
    main(args.input, args.template, args.output, args.version, args.call, args.wd)
