#!/usr/bin/env python
from datetime import datetime
import os
import glob
import json
import re
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output", "-o")
parser.add_argument("--yaml", "-y")
parser.add_argument("--schema", "-s")

args = parser.parse_args()


def parse_json(lines):
    data = json.loads(" ".join(lines))
    return data


def parse_csv(lines):
    header = lines.pop(0).strip().split(",")
    data = []
    for line in lines:
        this_data = {}
        elements = line.strip().split(",")
        for idx, h in enumerate(header):
            entry = elements[idx]
            if re.match(r"^[0-9]*$", entry):
                entry = int(entry)
            elif re.match(r"^[0-9]*\.[0-9]*$", entry):
                entry = float(entry)
            this_data[h] = entry
        data.append(this_data)
    return data

def parse_matrix(lines):

    data = []
    bucket = {}
    header = lines.pop(0).split("\t")
    bucket["x"] = header[1:]
    bucket["y"] = []

    for line in lines:
        elements = line.strip().split("\t")
        y = elements.pop(0)
        bucket["y"].append(y)
        data.append(elements)

    bucket["data"] = data
    return bucket

def parse_tabular(lines):
    header = lines.pop(0).strip().split("\t")
    data = []
    for line in lines:
        this_data = {}
        elements = line.strip().split("\t")
        for idx, h in enumerate(header):
            if idx < len(elements):
                entry = elements[idx]
                # value is an integer
                if re.match(r"^[0-9]+$", entry):
                    entry = int(entry)
                # value is a float
                elif re.match(r"^[0-9]+\.[0-9]+$", entry):
                    entry = float(entry)
                # value is a file path (messes up md5 fingerprinting)
                elif re.match(r"^\/.*\/.*$", entry):
                    entry = entry.split("/")[-1]
                this_data[h] = entry
        data.append(this_data)

    return data

def parse_partitions(lines):

    data = {}
    header = lines.pop(0).strip().split("\t")

    # we only store the first 30 partitions
    for dist in list(range(30)):
        partition = header.index(f"MST-{dist}x1.0")

        this_data = {}
        for line in lines:
            values = line.split("\t")
            cluster = values[partition]
            sample = values.pop(0)
            this_data[sample] = cluster

        data[dist] = this_data

    return data

def parse_yaml(lines):

    data = {}
    key = ""

    for line in lines:

        line = line.replace(":", "")
        if re.match(r"^\s+.*", line):
            tool, version = line.strip().split()
            data[key][tool] = version
        else:
            key = line.strip().replace("\"", "")
            data[key] = {}

    return data


def main(yaml_file, schema, output):

    files = [os.path.abspath(f) for f in glob.glob("*.*")]
    files_in_folders = [os.path.abspath(f) for f in glob.glob("*/*")]
    for f in files_in_folders:
        files.append(f)
    print(files)

    date = datetime.today().strftime('%Y-%m-%d')

    with open(yaml_file, "r") as f:
        yaml_lines = [line.rstrip() for line in f]

    versions = parse_yaml(yaml_lines)

    matrix = {
        "date": date,
        "schema": schema, 
        "software": versions,
        "chewbbaca_stats": []
    }

    for file in files:

        with open(file, "r") as f:
            lines = [line.rstrip() for line in f]

        if re.search(".dist_hamming.tsv", file):
            matrix["distance"] = parse_matrix(lines)
        elif re.search(".nwk", file):
            matrix["tree"] = "\n".join(lines)
        elif re.search(".partitions.tsv", file):
            matrix["clusters"] = parse_partitions(lines)
        elif re.search(".loci_report.tsv", file):
            matrix["loci_report"] = parse_tabular(lines)
        elif re.search("results_statistics.tsv", file):
            info = parse_tabular(lines)
            for i in info:
                matrix["chewbbaca_stats"].append(i)
    with open(output, "w") as fo:
        json.dump(matrix, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.yaml, args.schema, args.output)
