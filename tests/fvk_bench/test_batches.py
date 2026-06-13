"""Tests for fvk_bench.batches — written before implementation (TDD).

The batch division is an owner-specified contract: exactly five batches of
nine, pairwise disjoint, whose union is the 45 submodule-derived instance ids.
"""

from fvk_bench import batches, instances


def test_five_batches_of_nine_disjoint_covering_all_45():
    assert sorted(batches.BATCHES) == ["batch1", "batch2", "batch3", "batch4", "batch5"]
    all_ids = [iid for ids in batches.BATCHES.values() for iid in ids]
    assert all(len(ids) == 9 for ids in batches.BATCHES.values())
    assert len(all_ids) == 45 == len(set(all_ids))
    assert set(all_ids) == set(instances.submodule_instance_ids())


def test_batch_instances_accessor():
    assert batches.batch_instances("batch5")[0] == "pydata__xarray-6992"
    try:
        batches.batch_instances("batch9")
        assert False, "expected KeyError"
    except KeyError as e:
        assert "batch1" in str(e)
