# Batch Runs + Instance Parallelism Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Five fixed 9-problem batches runnable via `--batch batchN`, optional rolling parallelism via `run --max-parallel N`, documented in START.md; plus a read-only targeted review of cross-arm result collection.

**Architecture:** New `fvk_bench/batches.py` is the single source of truth for batch membership; `cli.py` wires `--batch` into run/validate-gold/list and replaces the sequential run loop with a ThreadPoolExecutor fan-out (default max_workers=1 ≡ today's behavior); `scaffold.ensure_mirror` gets a thread-unique temp suffix and `run` pre-warms mirrors before fan-out.

**Tech Stack:** Python stdlib (`concurrent.futures`, `threading`, `uuid`), pytest, existing fake-claude test harness.

**Authoritative spec:** `docs/superpowers/specs/2026-06-13-batch-runs-and-parallelism-design.md`. Conventions identical to the 2026-06-12 plan (venv pytest, TDD, stdlib-only, no prints outside cli.py, commit trailer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`).

---

### Task B1: `fvk_bench/batches.py`

**Files:** Create `fvk_bench/batches.py`, `tests/fvk_bench/test_batches.py`.

- [ ] **Step 1: Failing tests** (`test_batches.py`):

```python
from fvk_bench import batches, instances

def test_five_batches_of_nine_disjoint_covering_all_45():
    assert sorted(batches.BATCHES) == ["batch1", "batch2", "batch3", "batch4", "batch5"]
    all_ids = [iid for ids in batches.BATCHES.values() for iid in ids]
    assert all(len(ids) == 9 for ids in batches.BATCHES.values())
    assert len(all_ids) == 45 == len(set(all_ids))
    assert set(all_ids) == set(instances.submodule_instance_ids())

def test_hard_instances_subset():
    assert batches.HARD_INSTANCES <= set(
        iid for ids in batches.BATCHES.values() for iid in ids)
    assert len(batches.HARD_INSTANCES) == 6

def test_batch_instances_accessor():
    assert batches.batch_instances("batch5")[0] == "pydata__xarray-6992"
    try:
        batches.batch_instances("batch9")
        assert False, "expected KeyError"
    except KeyError as e:
        assert "batch1" in str(e)
```

- [ ] **Step 2: Run** `.venv/bin/python -m pytest tests/fvk_bench/test_batches.py -q` → FAIL (no module).
- [ ] **Step 3: Implement** — module docstring: owner-specified division, 2026-06-13; membership is contract, `[H]` documentation-only. Exact data:

```python
BATCHES: dict[str, tuple[str, ...]] = {
    "batch1": ("astropy__astropy-13398", "django__django-10554", "django__django-11138",
               "django__django-11400", "django__django-11885", "django__django-12325",
               "django__django-12708", "django__django-13128", "django__django-13212"),
    "batch2": ("astropy__astropy-13579", "django__django-13344", "django__django-13449",
               "django__django-13837", "django__django-14007", "django__django-14011",
               "django__django-14631", "django__django-15128", "django__django-15268"),
    "batch3": ("astropy__astropy-14369", "django__django-15503", "django__django-15629",
               "django__django-15957", "django__django-16263", "django__django-16560",
               "django__django-16631", "pylint-dev__pylint-4551", "pylint-dev__pylint-8898"),
    "batch4": ("pydata__xarray-3993", "pytest-dev__pytest-10356", "pytest-dev__pytest-5787",
               "pytest-dev__pytest-6197", "sphinx-doc__sphinx-11510", "sphinx-doc__sphinx-7590",
               "sphinx-doc__sphinx-8548", "sphinx-doc__sphinx-9229", "sphinx-doc__sphinx-9461"),
    "batch5": ("pydata__xarray-6992", "scikit-learn__scikit-learn-25102", "sympy__sympy-12489",
               "sympy__sympy-13852", "sympy__sympy-13878", "sympy__sympy-14248",
               "sympy__sympy-16597", "sympy__sympy-17630", "sympy__sympy-18199"),
}
HARD_INSTANCES = frozenset({
    "astropy__astropy-13398", "astropy__astropy-13579", "astropy__astropy-14369",
    "pydata__xarray-3993", "pydata__xarray-6992", "scikit-learn__scikit-learn-25102",
})

def batch_instances(name: str) -> tuple[str, ...]:
    try:
        return BATCHES[name]
    except KeyError:
        raise KeyError(f"unknown batch {name!r}; valid: {', '.join(sorted(BATCHES))}") from None
```

- [ ] **Step 4: Run** → PASS. **Step 5: Commit** `feat(fvk_bench): five fixed 9-problem batches`.

### Task B2: parallel-safe mirror clone + CLI wiring + rolling executor

**Files:** Modify `fvk_bench/scaffold.py` (temp suffix), `fvk_bench/cli.py` (selection group, pre-warm, executor, `--max-parallel`, list annotation), `fvk_bench/harvest.py` ONLY if recording max_parallel needs a param (preferred: cli writes `run_manifest` then injects `"max_parallel"` — NO: cleaner, add optional `extra: dict | None = None` param to `write_run_manifest` merged into the manifest top level). Tests: extend `tests/fvk_bench/test_scaffold.py`, `tests/fvk_bench/test_cli.py`.

- [ ] **Step 1: Failing tests**
  - `test_scaffold.py::test_mirror_tmp_suffix_thread_unique`: call the private suffix helper (factor `_clone_tmp_path(dst)`) twice → different paths; both contain `.tmp-`.
  - `test_cli.py::test_run_batch_selection`: monkeypatch `load_instances` to return 45 fixture instances whose ids = `submodule_instance_ids()` (reuse pattern; build Instances cheaply with same repo/base_commit from `fixture_remote_repo`); monkeypatch `arms.run_instance` and `harvest.harvest_instance` to record calls; `main(["run","--batch","batch5","--run-id","t",...])` → exactly the 9 batch5 ids dispatched, in order, exit 0.
  - `test_cli.py::test_run_rejects_batch_with_instances`: argparse error (exit 2) when both `--batch` and `--instances` given.
  - `test_cli.py::test_validate_gold_batch`: monkeypatch `evaluate.gold_eval` capturing ids → batch3 ids.
  - `test_cli.py::test_run_max_parallel_rolling`: 3 fixture instances (demo repo, distinct ids), fake-claude happy wrapper, `--max-parallel 2`; assert all 3 completed + harvested; assert max concurrency observed ≥... (hard to assert true overlap robustly with fake speed — instead monkeypatch `arms.run_instance` with a function using a `threading.Barrier(2, timeout=10)` on first two calls to PROVE two run concurrently, recording thread names; third call passes through; assert barrier didn't time out, exit 0).
  - `test_cli.py::test_run_max_parallel_records_manifest`: run with `--max-parallel 3` → `run_manifest.json` contains `"max_parallel": 3`.
  - `test_cli.py::test_run_prewarms_mirrors_once`: monkeypatch `scaffold.ensure_mirror` counting calls per repo; 3 same-repo instances with `--max-parallel 3` → pre-warm called once for the repo BEFORE any run_instance (record ordering via a shared list).
  - `test_cli.py::test_list_batch_filter`: `list --batch batch4` prints only those 9 ids; plain `list` output annotates batch names.
- [ ] **Step 2: RED.** **Step 3: Implement**
  - `scaffold.py`: `_clone_tmp_path(dst) = dst.with_name(f"{dst.name}.tmp-{os.getpid()}-{uuid.uuid4().hex[:8]}")`; ensure_mirror uses it (stale-cleanup glob unchanged: `*.tmp-*`).
  - `cli.py` run: selection resolution helper `_resolve_selection(args) -> list[str]` shared by run/validate-gold (`--instances` xor `--all` xor `--batch`); pre-warm: `for repo in unique repos of selection (preserving order): scaffold.ensure_mirror(repo, cache_dir)` before fan-out (cache_dir derived exactly as `arms.run_instance` derives it: `workspace_root/"cache"/"repos"` honoring `--workspace-root`); executor:
    ```python
    print_lock = threading.Lock()
    def _one(iid):
        inst = insts[iid]
        try:
            state = arms.run_instance(...)
            harvest.harvest_instance(ws_path, run_id, inst, ...)
        except (RuntimeError, OSError) as exc:
            _write_stub_manifest(...); state = stub
        with print_lock: print(per-instance status line)
        return iid, state
    with ThreadPoolExecutor(max_workers=max(1, args.max_parallel)) as ex:
        results = list(ex.map(_one, selected_ids))
    ```
    (keep submission order; `ex.map` preserves result order and rolls naturally). run_manifest: `write_run_manifest(run_id, extra={"max_parallel": args.max_parallel})`.
  - `harvest.write_run_manifest(run_id, results_dir=..., extra=None)`: `manifest.update(extra or {})`.
  - `list`: annotate `[batchN]` per instance (reverse lookup), `[H]` marker from HARD_INSTANCES; `--batch` filters.
- [ ] **Step 4: GREEN** (full `tests/fvk_bench`). **Step 5: Commit** `feat(fvk_bench): --batch selection and --max-parallel rolling execution`.

### Task B3: START.md batch section

**Files:** Modify `START.md` (add "Run a batch" section + batch table after the single-problem happy path), `docs` only.

- [ ] **Step 1:** Add the batch table (5 rows, short names + `[H]` markers as in the spec) and instructions:
  ```bash
  .venv/bin/python -m fvk_bench validate-gold --run-id batch1-$(hostname) --batch batch1
  .venv/bin/python -m fvk_bench run --run-id batch1-$(hostname) --batch batch1 --max-parallel 3
  .venv/bin/python -m fvk_bench evaluate --run-id batch1-$(hostname)
  .venv/bin/python -m fvk_bench report --run-id batch1-$(hostname)
  git add results/ && git commit -m "results: batch1 run on $(hostname)" && git push
  ```
  Notes: `--max-parallel 1` (default) = sequential canonical mode; parallel runs contend for machine resources and subscription rate limits — use the same setting across runs you compare; resuming after interruption = rerun the same command (completed arms skip); `--retry-failed` for failed arms. Mention expected duration (9 problems × 3 arms, sequential ≈ a working day; `--max-parallel 3` ≈ a few hours, machine/limits permitting).
- [ ] **Step 2:** Verify documented flags against `--help`; suite still green. **Step 3: Commit** `docs: batch run instructions in START.md`.

### Task R1 (independent, read-only): cross-arm collection/comparison review

No files unless bugs found. Read `evaluate.py`, `report.py`, `harvest.py`, `arms.py` state keys, plus the live run artifacts in `results/20260612T170620Z-XC-MINI-PRO-AHP/`. Questions: per-arm predictions/`model_name_or_path` separation; harness run-id dotting collisions; report.json keying per instance per arm; collect_scores arm keying; flip logic correctness (up/down sets, denominators, empty-patch semantics); INDEX aggregation; any place arm A's result could overwrite/shadow arm B's. Deliverable: findings list with verdicts; fix ONLY real bugs (with tests), no refactoring.

## Self-review
- Spec coverage: batches module (B1), CLI batch+parallel+pre-warm+tmp-suffix+manifest recording (B2), START.md+fairness note (B3), review subtask (R1). ✓
- No placeholders; data is exact (45 ids cross-checkable in B1 test). ✓
- Type consistency: `batch_instances` used only in cli; `write_run_manifest(extra=)` defined and used in B2. ✓
