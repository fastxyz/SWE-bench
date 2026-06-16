"""Tests for fvk_bench.instances — written before implementation (TDD)."""

import dataclasses
import json
import re
import sys
import types
from dataclasses import FrozenInstanceError
from pathlib import Path

import pytest

FIXTURE_PATH = Path(__file__).parent / "fixtures" / "instances_fixture.json"
FIXTURE_IDS = ["demo__demo-1", "demo__demo-2"]


# ---------------------------------------------------------------------------
# 1. load_instances round-trip
# ---------------------------------------------------------------------------

def test_load_instances_roundtrip(monkeypatch):
    """load_instances returns a dict of 2 frozen Instance objects from the fixture."""
    import fvk_bench.instances as mod

    monkeypatch.setattr(mod, "submodule_instance_ids", lambda: list(FIXTURE_IDS))

    result = mod.load_instances(FIXTURE_PATH)

    assert set(result.keys()) == set(FIXTURE_IDS)

    inst1 = result["demo__demo-1"]
    assert inst1.instance_id == "demo__demo-1"
    assert inst1.repo == "demo/demo"
    assert inst1.base_commit == "abc123"
    assert inst1.version == "1.0"
    assert inst1.problem_statement == "Fix the bug in demo one."
    assert inst1.hints_text == "Look at the constructor."
    assert inst1.fail_to_pass_count == 2
    assert inst1.pass_to_pass_count == 3

    inst2 = result["demo__demo-2"]
    assert inst2.instance_id == "demo__demo-2"
    assert inst2.hints_text == ""
    assert inst2.fail_to_pass_count == 1
    assert inst2.pass_to_pass_count == 5

    # Must be frozen dataclasses
    with pytest.raises(FrozenInstanceError):
        inst1.instance_id = "mutated"  # type: ignore[misc]

    # All field types
    assert isinstance(inst1.fail_to_pass_count, int)
    assert isinstance(inst1.pass_to_pass_count, int)


# ---------------------------------------------------------------------------
# 2. load_instances id mismatch raises
# ---------------------------------------------------------------------------

def test_load_instances_id_mismatch_raises(monkeypatch):
    """load_instances raises RuntimeError when submodule ids don't match json ids."""
    import fvk_bench.instances as mod

    # Return 45 fake ids that are different from the fixture's ids
    different_ids = [f"other__other-{i}" for i in range(1, 46)]  # 45 different ids
    monkeypatch.setattr(mod, "submodule_instance_ids", lambda: different_ids)

    with pytest.raises(RuntimeError) as exc_info:
        mod.load_instances(FIXTURE_PATH)

    # Error message must name at least one missing id
    msg = str(exc_info.value)
    # The fixture ids are "extra" from submodule's perspective, and the
    # different_ids are "missing" from the json. Either direction is valid to mention.
    assert any(word in msg for word in ["demo__demo", "other__other", "missing", "extra"]), (
        f"Error message should mention specific ids but got: {msg!r}"
    )


def test_load_verified500_accepts_exact_500_without_submodule_check(tmp_path, monkeypatch):
    """The full Verified set is validated by count, not by the 45-prompt submodule."""
    import fvk_bench.instances as mod

    rows = [
        {
            "instance_id": f"repo__repo-{i:03d}",
            "repo": "repo/repo",
            "base_commit": "abc123",
            "version": "1.0",
            "problem_statement": "Fix it.",
            "hints_text": "",
            "fail_to_pass_count": 1,
            "pass_to_pass_count": 2,
        }
        for i in range(500)
    ]
    path = tmp_path / "verified.json"
    path.write_text(json.dumps(rows), encoding="utf-8")
    monkeypatch.setattr(
        mod,
        "submodule_instance_ids",
        lambda: pytest.fail("verified500 must not read prompt submodule ids"),
    )

    loaded = mod.load_instances(path, instance_set="verified500")

    assert len(loaded) == 500
    assert "repo__repo-499" in loaded


def test_load_verified500_rejects_non_500_file(tmp_path):
    import fvk_bench.instances as mod

    path = tmp_path / "too-small.json"
    path.write_text("[]", encoding="utf-8")

    with pytest.raises(RuntimeError) as exc_info:
        mod.load_instances(path, instance_set="verified500")

    assert "Expected exactly 500" in str(exc_info.value)


# ---------------------------------------------------------------------------
# 3. submodule_instance_ids — real submodule, no monkeypatching
# ---------------------------------------------------------------------------

def test_submodule_instance_ids_real():
    """submodule_instance_ids returns exactly 45 sorted ids from the real submodule."""
    import fvk_bench.instances as mod

    ids = mod.submodule_instance_ids()

    assert len(ids) == 45
    assert ids == sorted(ids), "ids must be sorted"

    assert "sympy__sympy-12489" in ids
    assert "django__django-14011" in ids

    pattern = re.compile(r"^[A-Za-z0-9_.-]+__[A-Za-z0-9_.-]+-\d+$")
    for iid in ids:
        assert pattern.match(iid), f"id {iid!r} does not match expected pattern"


# ---------------------------------------------------------------------------
# 4. vendor_instances never leaks patch/test_patch
# ---------------------------------------------------------------------------

def test_vendor_never_leaks_hidden_fields(monkeypatch, tmp_path):
    """vendor_instances writes only the 8 Instance fields; patch/test_patch are never emitted."""
    import fvk_bench.instances as mod

    # Monkeypatch submodule_instance_ids to return the 2 fixture ids
    monkeypatch.setattr(mod, "submodule_instance_ids", lambda: list(FIXTURE_IDS))

    # Build fake dataset rows — FAIL_TO_PASS as a JSON string, PASS_TO_PASS as a real list
    fake_rows = [
        {
            "instance_id": "demo__demo-1",
            "repo": "demo/demo",
            "base_commit": "abc123",
            "version": "1.0",
            "problem_statement": "Fix the bug in demo one.",
            "hints_text": "Look at the constructor.",
            "FAIL_TO_PASS": '["t1", "t2"]',      # JSON string form
            "PASS_TO_PASS": ["p1", "p2", "p3"],   # real list form
            "patch": "patch-content",              # decoy — must NOT appear in output
            "test_patch": "test-patch-content",    # decoy — must NOT appear in output
        },
        {
            "instance_id": "demo__demo-2",
            "repo": "demo/demo",
            "base_commit": "def456",
            "version": "1.1",
            "problem_statement": "Fix the bug in demo two.",
            "hints_text": None,   # should default to ""
            "FAIL_TO_PASS": ["u1"],               # real list form
            "PASS_TO_PASS": '["v1","v2","v3","v4","v5"]',  # JSON string form
            "patch": "patch-content",              # decoy
            "test_patch": "test-patch-content",    # decoy
        },
    ]

    # Build a fake datasets module that will be injected into sys.modules
    fake_datasets = types.ModuleType("datasets")

    def fake_load_dataset(name, split):
        assert name == "princeton-nlp/SWE-bench_Verified"
        assert split == "test"
        return fake_rows

    fake_datasets.load_dataset = fake_load_dataset  # type: ignore[attr-defined]

    # Inject before calling vendor_instances
    monkeypatch.setitem(sys.modules, "datasets", fake_datasets)

    out_path = tmp_path / "out.json"
    count = mod.vendor_instances(out_path)

    assert count == 2, f"Expected 2, got {count}"

    # Read back and check structure
    written = json.loads(out_path.read_text())
    assert isinstance(written, list)
    assert len(written) == 2

    # Sort by instance_id to get deterministic order
    written_sorted = sorted(written, key=lambda r: r["instance_id"])
    row1, row2 = written_sorted

    # Exactly the 8 Instance fields, nothing else
    expected_keys = {
        "instance_id", "repo", "base_commit", "version",
        "problem_statement", "hints_text",
        "fail_to_pass_count", "pass_to_pass_count",
    }
    assert set(row1.keys()) == expected_keys, f"row1 keys: {set(row1.keys())}"
    assert set(row2.keys()) == expected_keys, f"row2 keys: {set(row2.keys())}"

    # Counts are correct
    assert row1["fail_to_pass_count"] == 2   # len(["t1","t2"])
    assert row1["pass_to_pass_count"] == 3   # len(["p1","p2","p3"])
    assert row2["fail_to_pass_count"] == 1   # len(["u1"])
    assert row2["pass_to_pass_count"] == 5   # len(["v1"..."v5"])

    # hints_text None -> ""
    assert row2["hints_text"] == ""

    # Decoy values must not appear anywhere in the file text
    file_text = out_path.read_text()
    assert "patch-content" not in file_text, "patch-content leaked into output!"
    assert "test-patch-content" not in file_text, "test-patch-content leaked into output!"

    # Sorted by instance_id, indent=2, trailing newline
    assert file_text.endswith("\n"), "output must end with trailing newline"
    reparsed = json.loads(file_text)
    assert [r["instance_id"] for r in reparsed] == sorted(
        r["instance_id"] for r in reparsed
    ), "output must be sorted by instance_id"


def test_vendor_verified500_writes_all_dataset_rows(monkeypatch, tmp_path):
    """verified500 vendoring uses the whole Verified test split, still hiding patches."""
    import fvk_bench.instances as mod

    monkeypatch.setattr(
        mod,
        "submodule_instance_ids",
        lambda: pytest.fail("verified500 vendoring must not use the 45-prompt ids"),
    )
    fake_rows = [
        {
            "instance_id": f"repo__repo-{i:03d}",
            "repo": "repo/repo",
            "base_commit": "abc123",
            "version": "1.0",
            "problem_statement": "Fix it.",
            "hints_text": None,
            "FAIL_TO_PASS": ["f"],
            "PASS_TO_PASS": ["p1", "p2"],
            "patch": "secret",
            "test_patch": "secret-test",
        }
        for i in range(500)
    ]
    fake_datasets = types.ModuleType("datasets")
    fake_datasets.load_dataset = lambda name, split: fake_rows  # type: ignore[attr-defined]
    monkeypatch.setitem(sys.modules, "datasets", fake_datasets)

    out_path = tmp_path / "verified.json"
    count = mod.vendor_instances(out_path, instance_set="verified500")

    assert count == 500
    text = out_path.read_text(encoding="utf-8")
    assert "secret" not in text
    written = json.loads(text)
    assert written[0]["instance_id"] == "repo__repo-000"
    assert written[-1]["instance_id"] == "repo__repo-499"


def test_instance_set_path_and_count_from_registry():
    from fvk_bench import config, instances
    assert instances._instance_set_path("multilingual300") == config.MULTILINGUAL_INSTANCES_JSON
    assert instances._expected_count("multilingual300") == 300
    assert instances._instance_set_path("verified500") == config.VERIFIED_INSTANCES_JSON
    assert instances._expected_count("verified500") == 500
