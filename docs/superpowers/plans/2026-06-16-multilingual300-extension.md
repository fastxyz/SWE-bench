# multilingual300 Benchmark Extension — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `multilingual300` instance set (SWE-bench Multilingual, 300 tasks / 9 languages) to `fvk_bench`, runnable through the existing baseline/fvk/control flow with both agents, scored offline from a git submodule — without changing fvk45/verified500 behavior.

**Architecture:** Replace scattered per-set `if/elif` branches with a single **instance-set registry** in `config.py`. fvk45/verified500 become registry entries reproducing today's exact values. Eval resolves the dataset from each run's recorded `instance_set` (portable). The multilingual dataset ships as a fastxyz-owned submodule containing `test.parquet`, which the in-repo SWE-bench harness loads locally (no HF at runtime, zero harness changes).

**Tech Stack:** Python 3.10, `fvk_bench` package, in-repo `swebench` harness v4.1.0, pytest, git submodules, HuggingFace `datasets` (vendoring only).

**Spec:** `docs/superpowers/specs/2026-06-16-multilingual300-extension-design.md`

**Always-green strategy:** Task 1 adds the registry but keeps a temporary `config.DATASET_NAME` alias so existing consumers keep working. Tasks 2/4/5 migrate each consumer to the registry. Task 6 removes the alias once `grep` shows no references. The full `pytest tests/fvk_bench/` suite must pass after every task.

**Branch:** `multilingual300-extension` (already created). All commits land here.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `fvk_bench/config.py` | `InstanceSet` dataclass + `REGISTRY` + `resolve_dataset`/`dataset_identity`; paths | Modify |
| `fvk_bench/instances.py` | registry-driven path/count/vendor | Modify |
| `fvk_bench/batches.py` | multilingual batch generator + scheme selector | Modify |
| `fvk_bench/harvest.py` | record portable dataset identity in manifest | Modify |
| `fvk_bench/evaluate.py` | thread `dataset` into harness calls | Modify |
| `fvk_bench/cli.py` | resolve dataset for eval/validate-gold; list batches by scheme | Modify |
| `fvk_bench/data/instances_multilingual300.json` | vendored visible metadata (300) | Create (Task 8) |
| `third_party/swe-bench-multilingual` + `.gitmodules` | dataset submodule | Create (Task 7) |
| `START.md` / `START-PROMPT.md` | docs | Modify / Delete (Task 9) |
| `tests/fvk_bench/test_*.py` | unit coverage | Modify |

---

## Task 1: Instance-set registry in config.py

**Files:**
- Modify: `fvk_bench/config.py`
- Test: `tests/fvk_bench/test_config.py`

- [ ] **Step 1: Write failing tests** — append to `tests/fvk_bench/test_config.py`:

```python
def test_registry_backward_compat_fvk45_and_verified500():
    from fvk_bench import config
    fvk = config.REGISTRY["fvk45"]
    assert fvk.dataset_identity == "princeton-nlp/SWE-bench_Verified"
    assert fvk.dataset_local is None
    assert fvk.expected_count == 45
    assert fvk.data_file == config.INSTANCES_JSON
    assert fvk.batch_scheme == "fvk45_fixed5"

    ver = config.REGISTRY["verified500"]
    assert ver.dataset_identity == "princeton-nlp/SWE-bench_Verified"
    assert ver.dataset_local is None
    assert ver.expected_count == 500
    assert ver.data_file == config.VERIFIED_INSTANCES_JSON
    assert ver.batch_scheme == "verified_sorted10"


def test_registry_multilingual300_entry():
    from fvk_bench import config
    ml = config.REGISTRY["multilingual300"]
    assert ml.dataset_identity == "SWE-bench/SWE-bench_Multilingual"
    assert ml.dataset_local == "third_party/swe-bench-multilingual"
    assert ml.expected_count == 300
    assert ml.data_file == config.MULTILINGUAL_INSTANCES_JSON
    assert ml.batch_scheme == "multilingual_sorted10"


def test_instance_sets_and_default():
    from fvk_bench import config
    assert config.INSTANCE_SETS == ("fvk45", "verified500", "multilingual300")
    assert config.DEFAULT_INSTANCE_SET == "fvk45"


def test_resolve_dataset_and_identity():
    from fvk_bench import config
    assert config.resolve_dataset("verified500") == "princeton-nlp/SWE-bench_Verified"
    assert config.dataset_identity("multilingual300") == "SWE-bench/SWE-bench_Multilingual"
    local = config.resolve_dataset("multilingual300")
    assert local.endswith("third_party/swe-bench-multilingual")
    assert local.startswith("/")  # absolute, resolved against REPO_ROOT
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_config.py -q`
Expected: FAIL (`AttributeError: module 'fvk_bench.config' has no attribute 'REGISTRY'`).

- [ ] **Step 3: Edit config.py — add dataclass import.** Change the import block at the top:

```python
import os
from dataclasses import dataclass
from pathlib import Path
```

- [ ] **Step 4: Edit config.py — remove the three old constants.** Delete these lines from the "Pinned invocation constants" section:

```python
DATASET_NAME: str = "princeton-nlp/SWE-bench_Verified"
INSTANCE_SETS: tuple[str, ...] = ("fvk45", "verified500")
DEFAULT_INSTANCE_SET: str = "fvk45"
```

(Leave `ARM_TIMEOUT_SECONDS`, the `assert set(MAX_TURNS) == set(ARMS)`, etc. intact.)

- [ ] **Step 5: Edit config.py — add paths + registry after the Filesystem paths block.** Immediately after the `RESULTS_DIR: Path = REPO_ROOT / "results"` line, insert:

```python
MULTILINGUAL_INSTANCES_JSON: Path = PACKAGE_DIR / "data" / "instances_multilingual300.json"
MULTILINGUAL_SUBMODULE: Path = REPO_ROOT / "third_party" / "swe-bench-multilingual"

# ---------------------------------------------------------------------------
# Instance-set registry (single source of truth for each runnable set)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class InstanceSet:
    """One runnable instance set. Authoritative description of a benchmark set."""

    name: str
    dataset_identity: str       # portable logical name recorded in run manifests
    dataset_local: str | None   # repo-relative dir holding test.parquet, or None (HF)
    expected_count: int
    data_file: Path             # vendored *visible* metadata JSON (agent inputs)
    id_source: str              # "submodule45" | "count"
    batch_scheme: str           # "fvk45_fixed5" | "verified_sorted10" | "multilingual_sorted10"


REGISTRY: dict[str, "InstanceSet"] = {
    "fvk45": InstanceSet(
        name="fvk45",
        dataset_identity="princeton-nlp/SWE-bench_Verified",
        dataset_local=None,
        expected_count=45,
        data_file=INSTANCES_JSON,
        id_source="submodule45",
        batch_scheme="fvk45_fixed5",
    ),
    "verified500": InstanceSet(
        name="verified500",
        dataset_identity="princeton-nlp/SWE-bench_Verified",
        dataset_local=None,
        expected_count=500,
        data_file=VERIFIED_INSTANCES_JSON,
        id_source="count",
        batch_scheme="verified_sorted10",
    ),
    "multilingual300": InstanceSet(
        name="multilingual300",
        dataset_identity="SWE-bench/SWE-bench_Multilingual",
        dataset_local="third_party/swe-bench-multilingual",
        expected_count=300,
        data_file=MULTILINGUAL_INSTANCES_JSON,
        id_source="count",
        batch_scheme="multilingual_sorted10",
    ),
}

INSTANCE_SETS: tuple[str, ...] = tuple(REGISTRY)
DEFAULT_INSTANCE_SET: str = "fvk45"

# TEMPORARY backward-compat alias — removed in Task 6 once all consumers migrate.
DATASET_NAME: str = REGISTRY[DEFAULT_INSTANCE_SET].dataset_identity


def resolve_dataset(instance_set: str) -> str:
    """Return the dataset arg for the harness/loader for ``instance_set``.

    Sets with a local mirror return the absolute submodule dir (the harness loads
    ``<dir>/test.parquet``); others return the HuggingFace dataset name.
    """
    s = REGISTRY[instance_set]
    if s.dataset_local:
        return str((REPO_ROOT / s.dataset_local).resolve())
    return s.dataset_identity


def dataset_identity(instance_set: str) -> str:
    """Return the portable logical dataset name recorded in run manifests."""
    return REGISTRY[instance_set].dataset_identity
```

- [ ] **Step 6: Update any existing config assertions.** Run `grep -n "DATASET_NAME\|INSTANCE_SETS" tests/fvk_bench/test_config.py`. If an existing test asserts `config.INSTANCE_SETS == ("fvk45", "verified500")`, update it to the 3-tuple above. Keep any `DATASET_NAME == "princeton-nlp/SWE-bench_Verified"` assertion (still true via the alias).

- [ ] **Step 7: Run tests, verify pass**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_config.py -q`
Expected: PASS.

- [ ] **Step 8: Full suite green**

Run: `.venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS (alias keeps consumers working).

- [ ] **Step 9: Commit**

```bash
git add fvk_bench/config.py tests/fvk_bench/test_config.py
git commit -m "feat(config): instance-set registry with multilingual300 entry"
```

---

## Task 2: instances.py uses the registry

**Files:**
- Modify: `fvk_bench/instances.py`
- Test: `tests/fvk_bench/test_instances.py`

- [ ] **Step 1: Write failing test** — append to `tests/fvk_bench/test_instances.py`:

```python
def test_instance_set_path_and_count_from_registry():
    from fvk_bench import config, instances
    assert instances._instance_set_path("multilingual300") == config.MULTILINGUAL_INSTANCES_JSON
    assert instances._expected_count("multilingual300") == 300
    assert instances._instance_set_path("verified500") == config.VERIFIED_INSTANCES_JSON
    assert instances._expected_count("verified500") == 500
```

- [ ] **Step 2: Run test, verify it fails**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_instances.py::test_instance_set_path_and_count_from_registry -q`
Expected: FAIL (`RuntimeError: unknown instance set 'multilingual300'`).

- [ ] **Step 3: Replace `_instance_set_path` and `_expected_count`** with registry lookups:

```python
def _instance_set_path(instance_set: str) -> Path:
    try:
        return config.REGISTRY[instance_set].data_file
    except KeyError:
        raise RuntimeError(
            f"unknown instance set {instance_set!r}; choose from {', '.join(config.INSTANCE_SETS)}"
        )


def _expected_count(instance_set: str) -> int:
    try:
        return config.REGISTRY[instance_set].expected_count
    except KeyError:
        raise RuntimeError(
            f"unknown instance set {instance_set!r}; choose from {', '.join(config.INSTANCE_SETS)}"
        )
```

- [ ] **Step 4: Generalize the count-validation branch in `load_instances`.** Replace the `if instance_set == "verified500":` block with a registry-driven check (fvk45 keeps its submodule cross-check):

```python
    if config.REGISTRY[instance_set].id_source == "count":
        expected_count = _expected_count(instance_set)
        if len(instances) != expected_count:
            raise RuntimeError(
                f"Expected exactly {expected_count} instances in {path} "
                f"for {instance_set}, found {len(instances)}."
            )
        return instances
```

(The subsequent fvk45 submodule-id cross-check stays as-is; it now runs only for `id_source == "submodule45"`.)

- [ ] **Step 5: Point vendoring at the registry dataset.** In `vendor_instances`, replace the existing load line `ds = datasets.load_dataset(config.DATASET_NAME, split="test")` with registry-driven loading (uses `dataset_local` directly — no string-sniffing):

```python
    iset = config.REGISTRY[instance_set]
    if iset.dataset_local:
        pq = str((config.REPO_ROOT / iset.dataset_local / "test.parquet").resolve())
        ds = datasets.load_dataset("parquet", data_files=pq, split="train")
    else:
        ds = datasets.load_dataset(iset.dataset_identity, split="test")
```

This also removes a `config.DATASET_NAME` consumer (so the Task 6 alias removal stays clean).

- [ ] **Step 6: Run target test + full suite**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_instances.py -q && .venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add fvk_bench/instances.py tests/fvk_bench/test_instances.py
git commit -m "feat(instances): registry-driven paths/counts/vendoring"
```

---

## Task 3: batches.py multilingual generator

**Files:**
- Modify: `fvk_bench/batches.py`
- Test: `tests/fvk_bench/test_batches.py`

- [ ] **Step 1: Write failing tests** — append to `tests/fvk_bench/test_batches.py`:

```python
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
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_batches.py -q`
Expected: FAIL (`AttributeError: ... 'multilingual_batch_names'`).

- [ ] **Step 3: Add constants + generators** after `VERIFIED_BATCH_COUNT = 50`:

```python
MULTILINGUAL_BATCH_SIZE = 10
MULTILINGUAL_BATCH_COUNT = 30


def multilingual_batch_names() -> tuple[str, ...]:
    """Return generated multilingual300 batch names in order."""
    return tuple(f"multilingual{i:03d}" for i in range(1, MULTILINGUAL_BATCH_COUNT + 1))


def batch_names_for_scheme(scheme: str) -> tuple[str, ...]:
    """Return the ordered batch names for an instance set's batch scheme."""
    if scheme == "fvk45_fixed5":
        return tuple(BATCHES)
    if scheme == "verified_sorted10":
        return verified_batch_names()
    if scheme == "multilingual_sorted10":
        return multilingual_batch_names()
    raise KeyError(f"unknown batch scheme {scheme!r}")
```

- [ ] **Step 4: Extend `batch_instances`** — insert this block immediately before the final `raise KeyError(...)`:

```python
    multilingual_names = multilingual_batch_names()
    if name in multilingual_names:
        ids = tuple(instance_ids or ())
        required = MULTILINGUAL_BATCH_SIZE * MULTILINGUAL_BATCH_COUNT
        if len(ids) != required:
            raise KeyError(
                f"{name} requires exactly {required} ordered multilingual300 instance ids; "
                f"got {len(ids)}"
            )
        idx = int(name.removeprefix("multilingual")) - 1
        start = idx * MULTILINGUAL_BATCH_SIZE
        return ids[start:start + MULTILINGUAL_BATCH_SIZE]
```

And update the final `raise KeyError` message to: `f"unknown batch {name!r}; valid: {', '.join(sorted(BATCHES))}, verified001..verified050, or multilingual001..multilingual030"`.

- [ ] **Step 5: Run tests + full suite**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_batches.py -q && .venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add fvk_bench/batches.py tests/fvk_bench/test_batches.py
git commit -m "feat(batches): multilingual001..030 (30 groups of 10) + scheme selector"
```

---

## Task 4: harvest.py records portable dataset identity

**Files:**
- Modify: `fvk_bench/harvest.py:298`
- Test: `tests/fvk_bench/test_harvest.py`

- [ ] **Step 1: Write failing test** — append to `tests/fvk_bench/test_harvest.py`. Signature is `write_run_manifest(run_id, results_dir=..., extra=None)` (`harvest.py:177`):

```python
def test_run_manifest_records_portable_dataset_identity(tmp_path):
    import json
    from fvk_bench import harvest
    out = harvest.write_run_manifest(
        run_id="t-ml", results_dir=tmp_path,
        extra={"instance_set": "multilingual300", "arms": ["baseline"], "agent": "codex"},
    )
    m = json.loads(out.read_text())
    assert m["dataset"] == "SWE-bench/SWE-bench_Multilingual"  # portable logical name
    assert not m["dataset"].startswith("/")                   # never an absolute path
    assert m["instance_set"] == "multilingual300"             # extra merged through
```

- [ ] **Step 2: Run test, verify it fails**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_harvest.py::test_run_manifest_records_portable_dataset_identity -q`
Expected: FAIL (`dataset` == `princeton-nlp/SWE-bench_Verified`).

- [ ] **Step 3: Edit harvest.py.** In `write_run_manifest`, just before the `manifest = {` dict literal, add:

```python
    instance_set = extra.get("instance_set", config.DEFAULT_INSTANCE_SET)
    dataset_value = (
        config.dataset_identity(instance_set)
        if instance_set in config.REGISTRY
        else config.DATASET_NAME
    )
```

Then change the manifest line `"dataset": config.DATASET_NAME,` to `"dataset": dataset_value,`.

- [ ] **Step 4: Run test + full suite**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_harvest.py -q && .venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add fvk_bench/harvest.py tests/fvk_bench/test_harvest.py
git commit -m "feat(harvest): record portable dataset identity per instance set"
```

---

## Task 5: evaluate.py + cli eval/validate-gold dataset resolution

**Files:**
- Modify: `fvk_bench/evaluate.py` (`run_official_eval`, `gold_eval`/`run_gold`)
- Modify: `fvk_bench/cli.py` (`_cmd_validate_gold`, `_cmd_evaluate`, add `_manifest_dataset`)
- Test: `tests/fvk_bench/test_evaluate.py`, `tests/fvk_bench/test_cli.py`

- [ ] **Step 1: Write failing test** — append to `tests/fvk_bench/test_cli.py`:

```python
def test_manifest_dataset_resolution(tmp_path):
    import json
    from fvk_bench import cli, config
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    # multilingual run -> local submodule path resolved at read time
    (run_dir / "run_manifest.json").write_text(json.dumps({"instance_set": "multilingual300"}))
    assert cli._manifest_dataset(run_dir) == config.resolve_dataset("multilingual300")
    # verified run -> HF name
    (run_dir / "run_manifest.json").write_text(json.dumps({"instance_set": "verified500"}))
    assert cli._manifest_dataset(run_dir) == "princeton-nlp/SWE-bench_Verified"
    # legacy manifest (no instance_set) -> recorded dataset field
    (run_dir / "run_manifest.json").write_text(json.dumps({"dataset": "princeton-nlp/SWE-bench_Verified"}))
    assert cli._manifest_dataset(run_dir) == "princeton-nlp/SWE-bench_Verified"
```

- [ ] **Step 2: Run test, verify it fails**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_cli.py::test_manifest_dataset_resolution -q`
Expected: FAIL (`AttributeError: ... '_manifest_dataset'`).

- [ ] **Step 3: Add `dataset` param to `run_official_eval`.** Change its signature to add `dataset: str,` as the first keyword-only param (right after the `*,`):

```python
def run_official_eval(
    run_id: str,
    arm: str,
    instance_ids: list[str],
    *,
    dataset: str,
    results_dir: Path = config.RESULTS_DIR,
    max_workers: int = 4,
    namespace: str | None = "swebench",
    timeout: int | None = None,
) -> int:
```

Replace **both** occurrences of `"--dataset_name", config.DATASET_NAME,` (the main argv and the retry argv) with `"--dataset_name", dataset,`.

- [ ] **Step 4: Add `dataset` param to `gold_eval`.** Change its signature to add `dataset: str,` after the `*,`:

```python
def gold_eval(
    run_id: str,
    instance_ids: list[str],
    *,
    dataset: str,
    max_workers: int = 4,
    results_dir: Path = config.RESULTS_DIR,
    repo_root: Path = config.REPO_ROOT,
) -> dict:
```

In the inner `run_gold`, replace `"--dataset_name", config.DATASET_NAME,` with `"--dataset_name", dataset,`.

- [ ] **Step 5: Add `_manifest_dataset` helper to cli.py** (near `_manifest_arms`):

```python
def _manifest_dataset(run_dir: Path) -> str:
    """Resolve the dataset for a completed run, portably, from its manifest."""
    manifest_path = run_dir / "run_manifest.json"
    if manifest_path.is_file():
        try:
            m = json.loads(manifest_path.read_text(encoding="utf-8"))
        except ValueError:
            m = {}
        iset = m.get("instance_set")
        if iset in config.REGISTRY:
            return config.resolve_dataset(iset)
        if m.get("dataset"):  # legacy manifest recorded a literal dataset name
            return m["dataset"]
    return config.resolve_dataset(config.DEFAULT_INSTANCE_SET)
```

- [ ] **Step 6: Pass `dataset` from both cli call sites.**

In `_cmd_validate_gold`, change the `evaluate.gold_eval(...)` call to:

```python
    results = evaluate.gold_eval(
        args.run_id, ids,
        dataset=config.resolve_dataset(args.instance_set),
        max_workers=args.max_workers, results_dir=config.RESULTS_DIR,
    )
```

In `_cmd_evaluate`, resolve once before the arm loop and pass it:

```python
    dataset = _manifest_dataset(run_dir)
```

and change the `evaluate.run_official_eval(...)` call to include `dataset=dataset,`:

```python
        rc = evaluate.run_official_eval(
            args.run_id, arm, ids,
            dataset=dataset,
            results_dir=results_dir, max_workers=args.max_workers,
        )
```

- [ ] **Step 7: Update existing evaluate tests** that call `run_official_eval`/`gold_eval`. Run `grep -n "run_official_eval\|gold_eval" tests/fvk_bench/test_evaluate.py`; add `dataset="princeton-nlp/SWE-bench_Verified"` (or a tmp parquet path) to each call.

- [ ] **Step 8: Run tests + full suite**

Run: `.venv/bin/python -m pytest tests/fvk_bench/test_cli.py tests/fvk_bench/test_evaluate.py -q && .venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add fvk_bench/evaluate.py fvk_bench/cli.py tests/fvk_bench/test_cli.py tests/fvk_bench/test_evaluate.py
git commit -m "feat(eval): resolve dataset per-run from manifest instance_set"
```

---

## Task 6: cli list-by-scheme + `--batch` help + remove DATASET_NAME alias

**Files:**
- Modify: `fvk_bench/cli.py` (`_cmd_list` non-fvk45 branch; `--batch` help strings)
- Modify: `fvk_bench/config.py` (remove alias)
- Test: `tests/fvk_bench/test_cli.py`

- [ ] **Step 1: Write failing test** — append to `tests/fvk_bench/test_cli.py`:

```python
def test_list_multilingual_batches(capsys):
    from fvk_bench import cli
    rc = cli.main(["list", "--instance-set", "multilingual300"])
    out = capsys.readouterr().out
    # tolerate "not vendored yet" message; the point is no crash + correct routing
    assert rc in (0, 1)
```

- [ ] **Step 2: Run test, verify behavior** (it may pass trivially; the real assertion is the scheme routing below). Run: `.venv/bin/python -m pytest tests/fvk_bench/test_cli.py::test_list_multilingual_batches -q`

- [ ] **Step 3: Make `_cmd_list` pick batch names by scheme.** Replace the `else:` branch that loops `batches.verified_batch_names()` with:

```python
    else:
        ordered_ids = tuple(all_ids)
        scheme = config.REGISTRY[args.instance_set].batch_scheme
        for name in batches.batch_names_for_scheme(scheme):
            try:
                for iid in batches.batch_instances(name, instance_ids=ordered_ids):
                    batch_of[iid] = name
            except KeyError:
                pass
```

- [ ] **Step 4: Update `--batch` help text** (both occurrences in `cli.py`, ~lines 518 and 542) to:

```python
        help=f"process one batch ({', '.join(sorted(batches.BATCHES))}, verified001..verified050, or multilingual001..multilingual030)",
```

- [ ] **Step 5: Remove the DATASET_NAME alias.** Confirm no remaining consumers:

Run: `grep -rn "config.DATASET_NAME\|DATASET_NAME" fvk_bench/`
Expected: only the alias definition line in `config.py` (and possibly a test). Delete the alias line:

```python
# TEMPORARY backward-compat alias — removed in Task 6 once all consumers migrate.
DATASET_NAME: str = REGISTRY[DEFAULT_INSTANCE_SET].dataset_identity
```

If `grep` shows any test asserting `config.DATASET_NAME`, update that test to use `config.dataset_identity("verified500")` instead.

- [ ] **Step 6: Full suite green**

Run: `.venv/bin/python -m pytest tests/fvk_bench/ -q`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add fvk_bench/cli.py fvk_bench/config.py tests/fvk_bench/test_cli.py
git commit -m "feat(cli): list batches by scheme; drop temporary DATASET_NAME alias"
```

---

## Task 7: Create fastxyz/SWE-bench_Multilingual mirror + add submodule

> **Outward-facing / needs operator confirmation:** creates a public GitHub repo and pushes dataset payload. Requires `gh` auth and network. Pause for the user before pushing.

**Files:** `.gitmodules`, `third_party/swe-bench-multilingual` (new submodule)

- [ ] **Step 1: Build the mirror content locally** (single normalized parquet the harness loads by convention):

```bash
mkdir -p /tmp/ml-mirror && cd /tmp/ml-mirror && git init -q
.venv/bin/python - <<'PY'
import datasets
ds = datasets.load_dataset("SWE-bench/SWE-bench_Multilingual", split="test")
assert len(ds) == 300, len(ds)
ds.to_parquet("test.parquet")
print("rows:", len(ds))
PY
```

- [ ] **Step 2: Create the GitHub repo and push** (confirm with user first):

```bash
cd /tmp/ml-mirror
git lfs install && git lfs track "*.parquet" && git add .gitattributes
git add test.parquet && git commit -q -m "SWE-bench Multilingual test split (mirror of SWE-bench/SWE-bench_Multilingual)"
gh repo create fastxyz/SWE-bench_Multilingual --public --source=. --remote=origin --push
```

- [ ] **Step 3: Add the submodule** (back in the repo root):

```bash
cd /home/xc/Projects/fastxyz-SWE-bench
git submodule add git@github.com:fastxyz/SWE-bench_Multilingual.git third_party/swe-bench-multilingual
git submodule update --init third_party/swe-bench-multilingual
ls -la third_party/swe-bench-multilingual/test.parquet
```

- [ ] **Step 4: Verify the harness loads it locally**

```bash
.venv/bin/python - <<'PY'
from swebench.harness.utils import load_swebench_dataset
ds = load_swebench_dataset("third_party/swe-bench-multilingual", "test")
print("loaded:", len(ds), "first:", ds[0]["instance_id"])
assert len(ds) == 300
PY
```
Expected: `loaded: 300 ...`.

- [ ] **Step 5: Commit the submodule wiring**

```bash
git add .gitmodules third_party/swe-bench-multilingual
git commit -m "feat: add SWE-bench Multilingual dataset submodule (offline eval)"
```

---

## Task 8: Vendor the visible metadata JSON

**Files:** `fvk_bench/data/instances_multilingual300.json` (create)

- [ ] **Step 1: Vendor from the submodule**

```bash
.venv/bin/python -m fvk_bench vendor-instances --instance-set multilingual300
```
Expected: writes `fvk_bench/data/instances_multilingual300.json` with 300 rows (visible fields only).

- [ ] **Step 2: Verify load + count**

```bash
.venv/bin/python - <<'PY'
from fvk_bench import instances
d = instances.load_instances(instance_set="multilingual300")
print("loaded:", len(d))
assert len(d) == 300
PY
.venv/bin/python -m fvk_bench list --instance-set multilingual300 --batch multilingual001
```
Expected: 300 loaded; `multilingual001` lists 10 instances.

- [ ] **Step 3: Commit the vendored data**

```bash
git add fvk_bench/data/instances_multilingual300.json
git commit -m "data: vendor multilingual300 visible instance metadata (300)"
```

---

## Task 9: START.md restructure + delete START-PROMPT.md

**Files:** `START.md` (modify), `START-PROMPT.md` (delete)

- [ ] **Step 1:** Read both files in full (`START.md`, `START-PROMPT.md`).

- [ ] **Step 2: Restructure §6 of START.md** to document three sets side by side. Add a `multilingual300` subsection with the 4-command flow:

```bash
.venv/bin/python -m fvk_bench validate-gold --instance-set multilingual300 --run-id mlNNN-$(hostname) --batch multilingualNNN --max-workers 3
.venv/bin/python -m fvk_bench run --instance-set multilingual300 --run-id mlNNN-$(hostname) --batch multilingualNNN --agent codex --arms baseline,fvk --max-parallel 3
.venv/bin/python -m fvk_bench evaluate --run-id mlNNN-$(hostname) --arms baseline,fvk
.venv/bin/python -m fvk_bench report --run-id mlNNN-$(hostname)
```

State explicitly: 300 instances / 30 batches of 10 (`multilingual001`..`multilingual030`); `git submodule update --init` now also pulls the dataset submodule; eval is offline (no HuggingFace at runtime); both `--agent claude` and `--agent codex` work; first eval may build Docker images locally if prebuilt images aren't pullable. Update §2–§3 setup notes to mention the new submodule.

- [ ] **Step 3: Fold START-PROMPT.md into START.md.** Add a "Letting a session drive a batch" subsection containing the parameterized ready-made prompt (instance-set / batch / arms / parallelism / agent / run-id) and the "what to expect / send `status?`" note from START-PROMPT.md.

- [ ] **Step 4: Verify coverage, then delete START-PROMPT.md.** Confirm the prompt + parameter list + "what to expect" all appear in START.md, then:

```bash
git rm START-PROMPT.md
grep -rn "START-PROMPT" START.md README.md 2>/dev/null   # expect no dangling references; remove any
```

- [ ] **Step 5: Commit**

```bash
git add START.md
git commit -m "docs: document verified500 + multilingual300 in START.md; drop START-PROMPT.md"
```

---

## Task 10: Bring-up validation (offline eval works end-to-end)

> **Expensive / outward-facing:** runs the Docker harness and (in the smoke batch) real gpt-5.5 sessions. Pause for the user before the smoke batch.

- [ ] **Step 1: Regression — existing sets untouched**

```bash
.venv/bin/python -m pytest tests/fvk_bench/ -q
.venv/bin/python -m fvk_bench list --instance-set fvk45 | tail -3
.venv/bin/python -m fvk_bench list --instance-set verified500 --batch verified001 | tail -3
```
Expected: suite PASS; fvk45 and verified500 listings unchanged.

- [ ] **Step 2: Gold validation across languages.** Pick one instance id per language from `list --instance-set multilingual300`, then:

```bash
.venv/bin/python -m fvk_bench validate-gold --instance-set multilingual300 \
  --run-id ml-goldcheck-$(date -u +%Y%m%dT%H%M%SZ) --instances <id_c> <id_cpp> <id_go> <id_java> <id_js> <id_ts> <id_php> <id_ruby> <id_rust> --max-workers 3
```
Expected: all resolve. This proves the local-dataset path end-to-end and reveals pull-vs-build per toolchain.

- [ ] **Step 3: Smoke batch** (confirm with user; ~hours):

```bash
CODEX=$(ls -1t "$HOME"/.vscode/extensions/openai.chatgpt-*/bin/*/codex 2>/dev/null | head -1)
RID=multilingual001-codex-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ)
.venv/bin/python -m fvk_bench validate-gold --instance-set multilingual300 --run-id "$RID" --batch multilingual001 --max-workers 3
.venv/bin/python -m fvk_bench run --instance-set multilingual300 --run-id "$RID" --batch multilingual001 --agent codex --arms baseline,fvk --max-parallel 3 --codex-bin "$CODEX"
.venv/bin/python -m fvk_bench evaluate --run-id "$RID" --arms baseline,fvk
.venv/bin/python -m fvk_bench report --run-id "$RID"
```
Expected: gold 10/10; 20/20 arms complete; scores written; `run_manifest.json` records `instance_set: multilingual300` and `dataset: SWE-bench/SWE-bench_Multilingual`.

- [ ] **Step 4: Final commit (smoke results, if kept)**

```bash
git add results/$RID results/INDEX.md && git commit -m "results: multilingual001 smoke (codex baseline fvk)"
```

---

## Done criteria

- `pytest tests/fvk_bench/` green; fvk45 & verified500 behavior provably unchanged (registry backward-compat test).
- `multilingual300` runs end-to-end offline with both agents; manifests portable.
- START.md documents all three sets; START-PROMPT.md removed with no dangling references.
- All work committed on `multilingual300-extension`.
