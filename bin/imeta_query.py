import os.path
import argparse
import logging
import subprocess

from typing import List, Set
from baton.api import connect_to_irods_with_baton
from baton.models import DataObject, SearchCriterion, ComparisonOperator

logging.basicConfig(level=logging.INFO)
fields_to_extract = ['sample', 'study_id', 'id_run', 'lane', 'is_paired_read', 'alignment',
                     'tag_index', 'total_reads', 'md5', 'sample_supplier_name', 'study']


def read_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baton', required=False, type=str, help='Path to folder with baton binaries')
    parser.add_argument('--study_id', required=False, type=int)
    parser.add_argument('--run_ids', type=int, nargs='*')
    parser.add_argument('--samples_file', type=str, help='Path to file with list of sample names (one per line)')
    parser.add_argument('--include_failing_samples', action="store_true", default=False,
                        help="Include samples failing sequencing QC (i.e. remove `manual_qc = 1` from iRODS query)")
    parser.add_argument('--dev', action='store_true', help='Query dev zone')
    parser.add_argument('--outdir', default='./')
    args = parser.parse_args()
    logging.info(args)
    return args


def get_baton() -> str:
    """
    Check if baton binaries are available
    :return: path to folder with baton binaries
    """
    try:
        result = subprocess.run(['which', 'baton'], check=True, stdout=subprocess.PIPE, text=True)
        baton_path = result.stdout.strip()
        return os.path.dirname(baton_path)

    except subprocess.CalledProcessError:
        raise FileNotFoundError("The 'baton' executable was not found in PATH.")


def make_baton_query(study_id: int = None, run_ids: List[int] = None, samples_file: str = None):
    if (study_id is None) == (samples_file is None):
        raise ValueError("Either study_id or samples_file must be provided.")

    # The speed of this query is dependent on the order of the attributes
    search_criterions = [
        SearchCriterion("type", 'cram', ComparisonOperator.EQUALS),
        SearchCriterion("target", "1", ComparisonOperator.EQUALS)
    ]
    # adding this condition to the query slows down it drastically so doing post-filtering instead
    # SearchCriterion("manual_qc", "1", ComparisonOperator.EQUALS)

    if study_id is not None:
        search_criterions.insert(0, SearchCriterion("study_id", str(study_id), ComparisonOperator.EQUALS))

    if run_ids is not None:
        search_criterions.append(
            SearchCriterion("id_run", [str(x) for x in run_ids], ComparisonOperator.CONTAINS)
        )

    if samples_file is not None:
        with open(samples_file) as f:
            samples = f.read().splitlines()
        search_criterions.insert(0, SearchCriterion("sanger_sample_id", samples, ComparisonOperator.CONTAINS))

    return search_criterions


def submit_baton_query(bins: str, query: List[SearchCriterion],
                       failing_samples=False, dev=False) -> List[DataObject]:
    """
    Search iRODS objects using specified query
    """
    irods = connect_to_irods_with_baton(bins, skip_baton_binaries_validation=True)

    zone = 'seq-dev' if dev else 'seq'
    out = irods.data_object.get_by_metadata(query, zone=zone, load_metadata=True)

    if failing_samples:
        fields_to_extract.append('manual_qc')
    else:
        logging.info('Filtering baton output by manual_qc = 1')

    data = []
    for data_object in out:
        if failing_samples or data_object.metadata.get("manual_qc") == {'1'}:
            data.append(data_object)

    return data


class InvalidMetadata(Exception):
    def __init__(self, obj: DataObject, value: Set[str]):
        message = f'Object {obj.path} has unexpected metadata value length: {value}'
        super().__init__(message)


def validate_sanity(data: List[DataObject]):
    if len(data) == 0:
        raise ValueError('No objects found in iRODS')


def extract_metadata(data: List[DataObject]) -> List[List[str]]:
    """
    Simplify objects to nested list of target fields
    """
    metadata = []
    logging.info('Extracting metadata')
    for obj in data:
        values = [obj.path, *map(lambda x: obj.metadata.get(x, ''), fields_to_extract)]
        for value in values:  # we expect only one value for each field, raise error otherwise
            if isinstance(value, set):
                if len(value) != 1:
                    raise InvalidMetadata(obj, value)
        values = [v.pop() if isinstance(v, set) else v for v in values]
        metadata.append(values)
    return metadata


def save_data(data, outfile: str):
    with open(outfile, 'w') as f:
        f.write('\t'.join(['object'] + list(fields_to_extract)) + '\n')
        for element in data:
            line = '\t'.join(element) + '\n'
            f.write(line)


def main():
    args = read_args()
    query = make_baton_query(study_id=args.study_id, run_ids=args.run_ids, samples_file=args.samples_file)
    data = submit_baton_query(bins=args.baton, query=query, failing_samples=args.include_failing_samples, dev=args.dev)
    validate_sanity(data)
    metadata = extract_metadata(data)
    save_data(metadata, outfile=os.path.join(args.outdir, 'samples.tsv'))


if __name__ == '__main__':
    main()
