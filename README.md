# nextflow_tower version

This pipeline is designed to be run using Nextflow Tower but it should work as a standalone.

The pipeline can accept various different inputs

1. Study_id - get all CRAMS from a specific iRODS study based on its ID
2. Study_id and Lane id - get all CRAMS from a specific iRODS lane in a study based on their  IDs
3. csv_samples - will iget samples listed one-per-line in input file "samples.tsv"
4. google_spreadsheet - will iget samples listed one-per-line in google spreadsheet

