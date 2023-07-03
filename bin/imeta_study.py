import os.path
import argparse
import logging
from typing import List, Set
from baton.api import connect_to_irods_with_baton
from baton.models import DataObject, SearchCriterion, ComparisonOperator

logging.basicConfig(level=logging.INFO)
fields_to_extract = ('sample', 'study_id', 'id_run', 'lane', 'is_paired_read', 'alignment',
                     'tag_index', 'total_reads', 'md5', 'sample_supplier_name', 'study')


def read_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baton', required=True, type=str, help='Path to folder with baton binaries')
    parser.add_argument('--study_id', required=True, type=int)
    parser.add_argument('--run_id', type=int, nargs='*')
    parser.add_argument('--dev', action='store_true', help='Query dev zone')
    parser.add_argument('--outdir', default='./')
    args = parser.parse_args()
    logging.info(args)
    return args


def submit_baton_query(bins: str, study_id: int, run_ids: List[int] = None, dev=False) -> List[DataObject]:
    """
    Search iRODS objects for specified study and/or run
    """
    irods = connect_to_irods_with_baton(bins, skip_baton_binaries_validation=True)

    # The speed of this query is dependent on the order of the attributes
    search_criterions = [
        SearchCriterion("study_id", str(study_id), ComparisonOperator.EQUALS),
        SearchCriterion("type", 'cram', ComparisonOperator.EQUALS),
        SearchCriterion("target", "1", ComparisonOperator.EQUALS)
    ]
    # adding this condition to the query slows down it drastically so doing post-filtering instead
    # SearchCriterion("manual_qc", "1", ComparisonOperator.EQUALS)

    if run_ids is not None and len(run_ids) == 1:  # to speed up some queries
        search_criterions.append(
            SearchCriterion("id_run", str(run_ids[0]), ComparisonOperator.EQUALS)
        )

    zone = 'seq-dev' if dev else 'seq'
    out = irods.data_object.get_by_metadata(search_criterions, zone=zone, load_metadata=True)

    data = []
    logging.info('Filtering baton output by manual_qc = 1')
    for data_object in out:
        if data_object.metadata.get("manual_qc") == {'1'}:
            data.append(data_object)

    if run_ids is not None:
        data = [x for x in data if set(map(int, x.metadata.get('id_run', {}))).intersection(run_ids)]

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
    data = submit_baton_query(args.baton, args.study_id, args.run_id, args.dev)
    validate_sanity(data)
    metadata = extract_metadata(data)
    save_data(metadata, outfile=os.path.join(args.outdir, 'samples.tsv'))


if __name__ == '__main__':
    main()
