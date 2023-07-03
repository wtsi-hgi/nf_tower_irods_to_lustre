import pytest

from contextlib import nullcontext
from baton.models import DataObject
from baton.collections import IrodsMetadata
from hgicommon.collections import Metadata

from bin.imeta_study import submit_baton_query
from bin.imeta_study import validate_sanity
from bin.imeta_study import extract_metadata

data_object = DataObject(
    path='/dummy/path',
    metadata=IrodsMetadata.from_metadata(Metadata([['sample', 'dummy_sample']]))
)


@pytest.fixture(scope='session')
def baton_bins(conf='confs/sanger.conf') -> str:
    with open(conf) as f:
        for line in f:
            if 'BATON_PATH' in line:
                path = line.split()[-1].strip("'")
                return path
    raise ValueError(f'BATON_PATH not found in {conf}')


@pytest.mark.parametrize(
    'run_id,expected_length',
    [
        (None, 1),
        ([1111], 0)
    ]
)
def test_submit_baton_query(baton_bins, run_id, expected_length):
    data = submit_baton_query(bins=baton_bins, study_id=7777, run_ids=run_id, dev=True)
    assert len(data) == expected_length
    if len(data) > 0:
        assert isinstance(data[0], DataObject)


@pytest.mark.parametrize(
    'data,expectation',
    [
        ([], pytest.raises(ValueError)),
        ([data_object], nullcontext())
    ]
)
def test_validate_sanity(baton_bins, data, expectation):
    with expectation:
        validate_sanity(data)


def test_extract_metadata():
    metadata = extract_metadata([data_object])


if __name__ == '__main__':
    pass
