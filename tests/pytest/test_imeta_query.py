import os.path
import stat
import pytest

from contextlib import nullcontext
from baton.models import DataObject
from baton.collections import IrodsMetadata
from hgicommon.collections import Metadata

from bin.imeta_query import make_baton_query, submit_baton_query
from bin.imeta_query import validate_sanity
from bin.imeta_query import extract_metadata
from bin.imeta_query import get_baton

data_object = DataObject(
    path='/dummy/path',
    metadata=IrodsMetadata.from_metadata(Metadata([['sample', 'dummy_sample']]))
)


@pytest.fixture()
def purge_path(monkeypatch):
    monkeypatch.setenv("PATH", "")


@pytest.fixture()
def fake_baton(tmp_path, monkeypatch):
    baton_path = tmp_path / "baton"
    baton_path.write_text("#!/bin/sh\necho 'Fake baton'")
    baton_path.chmod(baton_path.stat().st_mode | stat.S_IXUSR)

    monkeypatch.setenv("PATH", f"{tmp_path}:{os.environ['PATH']}")

    return baton_path


def test_get_baton_failure(purge_path):
    with pytest.raises(FileNotFoundError):
        get_baton()


def test_get_baton(fake_baton):
    result = get_baton()
    assert result == os.path.dirname(fake_baton)


def test_make_baton_query_failure():
    with pytest.raises(ValueError):
        make_baton_query(study_id=0, samples_file="")


@pytest.fixture(scope='session')
def baton_bins() -> str:
    return get_baton()


@pytest.mark.parametrize(
    'run_id,expected_length',
    [
        (None, 2),
        ([1111], 1),
        ([3333], 0)
    ]
)
def test_submit_baton_query_study(baton_bins, run_id, expected_length):
    query = make_baton_query(study_id=7777, run_ids=run_id)
    data = submit_baton_query(bins=baton_bins, query=query, dev=True)
    assert len(data) == expected_length
    if len(data) > 0:
        assert isinstance(data[0], DataObject)


@pytest.fixture()
def samples_file(tmp_path) -> str:
    file_path = tmp_path / 'samples.txt'
    with open(file_path, 'w') as f:
        f.write('sample1\nsample2\n')
    return str(file_path)


def test_submit_baton_query_samples(baton_bins, samples_file):
    query = make_baton_query(samples_file=samples_file)
    data = submit_baton_query(bins=baton_bins, query=query, dev=True)
    assert len(data) == 2
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
