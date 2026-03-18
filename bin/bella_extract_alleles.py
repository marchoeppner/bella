#!/usr/bin/env python
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output", "-o")
parser.add_argument("--sample", "-s")
parser.add_argument("--tsv", "-t")

args = parser.parse_args()


def parse_alleles_tsv(lines):

    data = {}
    header = lines.pop(0)
    data["header"] = header

    for line in lines:

        elements = line.split("\t")
        sample = elements[0]

        data[sample] = line

    return data


def main(sample, tsv_file, output):

    with open(tsv_file, "r") as f:
        lines = [line.rstrip() for line in f]

    data = parse_alleles_tsv(lines)

    header = data["header"]
    alleles = data[sample]

    with open(output, "w", encoding="utf-8") as output_file:
        output_file.write(header + "\n")
        output_file.write(alleles + "\n")


if __name__ == '__main__':
    main(args.sample, args.tsv, args.output)
