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


def test_verified500_batches_are_50_groups_of_10():
    ids = tuple(f"repo__repo-{i:03d}" for i in range(500))

    assert batches.verified_batch_names()[:2] == ("verified001", "verified002")
    assert batches.verified_batch_names()[-1] == "verified050"
    assert batches.batch_instances("verified001", instance_ids=ids) == ids[:10]
    assert batches.batch_instances("verified050", instance_ids=ids) == ids[490:500]

    all_batched = [
        iid
        for name in batches.verified_batch_names()
        for iid in batches.batch_instances(name, instance_ids=ids)
    ]
    assert len(all_batched) == 500
    assert len(set(all_batched)) == 500
    assert tuple(all_batched) == ids
    for name in batches.verified_batch_names():
        assert len(batches.batch_instances(name, instance_ids=ids)) == 10


def test_verified500_batch_rejects_non_500_input():
    try:
        batches.batch_instances("verified001", instance_ids=("one", "two"))
        assert False, "expected KeyError"
    except KeyError as e:
        assert "requires exactly 500" in str(e)


def test_multilingual300_batches_are_30_groups_of_10():
    ids = tuple(f"repo__repo-{i:03d}" for i in range(300))
    assert batches.multilingual_batch_names()[:2] == ("multilingual001", "multilingual002")
    assert batches.multilingual_batch_names()[-1] == "multilingual030"
    assert batches.batch_instances("multilingual001", instance_ids=ids) == ids[:10]
    assert batches.batch_instances("multilingual030", instance_ids=ids) == ids[290:300]
    all_batched = [
        iid for name in batches.multilingual_batch_names()
        for iid in batches.batch_instances(name, instance_ids=ids)
    ]
    assert tuple(all_batched) == ids and len(set(all_batched)) == 300


def test_multilingual_batch_rejects_non_300_input():
    try:
        batches.batch_instances("multilingual001", instance_ids=("one", "two"))
        assert False, "expected KeyError"
    except KeyError as e:
        assert "requires exactly 300" in str(e)


def test_batch_names_for_scheme():
    assert batches.batch_names_for_scheme("fvk45_fixed5") == tuple(batches.BATCHES)
    assert batches.batch_names_for_scheme("verified_sorted10") == batches.verified_batch_names()
    assert batches.batch_names_for_scheme("multilingual_sorted10") == batches.multilingual_batch_names()
