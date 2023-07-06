# iRODS to lustre pipeline

This pipeline is designed to be run using Nextflow Tower but it should work as a standalone.

The pipeline can accept various different inputs

1. Study_id - get all CRAMS from a specific iRODS study based on its ID
2. Study_id and Run id - get all CRAMS from a specific run in a study based on their  IDs
3. csv_samples - will iget samples listed one-per-line in input file "samples.tsv"
4. google_spreadsheet - will iget samples listed one-per-line in google spreadsheet

## How to use
Tutorial is available [here](https://hgi-projects.pages.internal.sanger.ac.uk/documentation/docs/tutorials/irods-to-lustre/)

## Development
### Setup
Create and activate an environment
```bash
python -m venv ./venv
source ./venv/bin/activate
```

Install both library dependencies and the dependencies needed for testing:
```bash
pip install -r requirements/imeta_study.txt
pip install -r tests/pytest/requirements.txt
```

Install nextflow and nf-test
```bash
curl -s https://get.nextflow.io | bash
mv nextflow ./venv/bin/
```
```bash
curl -fsSL https://code.askimed.com/install/nf-test | bash
mv nf-test ./venv/bin/
```

You also need iRODS access to `/seq` and `/seq-dev` zones.

### Testing
Currently, tests rely on iRODS state, proper encapsulation needed.

Test python scripts
```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)
export IRODS_ENVIRONMENT_FILE=$(ls ~/.irods/irods_environment.seq-dev.json)
# iinit if you use PAM auth
pytest tests/pytest/
```

Test nextflow scripts
```bash
export IRODS_ENVIRONMENT_FILE=$(ls ~/.irods/irods_environment.json)
# iinit if you use PAM auth
nf-test test tests/nf-test/
```