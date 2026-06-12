# Design: 9-Problem Batch Runs + Optional Instance Parallelism

**Date:** 2026-06-13
**Status:** Approved under standing owner authorization (2026-06-12: "you don't need my approval for anything")
**Extends:** `2026-06-12-fvk-3arm-benchmark-design.md` — everything not mentioned here is unchanged.

## Goal

1. Let people run a fixed 9-problem batch (one of five) in one session, with the usual
   evaluate/report/commit/push flow.
2. Let a batch's instances run in parallel with a user-chosen cap (`--max-parallel N`,
   1 = fully sequential, 9 = all at once), since the infra permits it.
3. (Separate subtask, not part of this feature) a targeted code review of cross-arm result
   collection/comparison; fix only real bugs, no refactoring.

## Batch division (owner-specified, verbatim mapping to instance IDs)

`[H]` marks the instances the owner labeled hard. Membership is the contract; the marker is
documentation only.

| batch | instances |
|---|---|
| batch1 | astropy__astropy-13398 [H], django__django-10554, -11138, -11400, -11885, -12325, -12708, -13128, -13212 |
| batch2 | astropy__astropy-13579 [H], django__django-13344, -13449, -13837, -14007, -14011, -14631, -15128, -15268 |
| batch3 | astropy__astropy-14369 [H], django__django-15503, -15629, -15957, -16263, -16560, -16631, pylint-dev__pylint-4551, pylint-dev__pylint-8898 |
| batch4 | pydata__xarray-3993 [H], pytest-dev__pytest-10356, -5787, -6197, sphinx-doc__sphinx-11510, -7590, -8548, -9229, -9461 |
| batch5 | pydata__xarray-6992 [H], scikit-learn__scikit-learn-25102 [H], sympy__sympy-12489, -13852, -13878, -14248, -16597, -17630, -18199 |

Invariants (test-enforced): exactly 5 batches × 9 instances, pairwise disjoint, union equals
the 45 submodule-derived IDs.

## Components

### `fvk_bench/batches.py` (new)
- `BATCHES: dict[str, tuple[str, ...]]` — `"batch1"…"batch5"` → full instance IDs in the
  owner's listed order.
- `HARD_INSTANCES: frozenset[str]` — the six `[H]` IDs (documentation/reporting use).
- `batch_instances(name) -> tuple[str, ...]` — KeyError with the valid names on miss.

### CLI changes (`fvk_bench/cli.py`)
- `run` and `validate-gold`: `--batch <name>` joins the existing mutually-exclusive
  selection group (`--instances | --all | --batch`).
- `list`: optional `--batch <name>` filter; the full listing annotates each instance's
  batch membership.
- `run --max-parallel N` (default 1, min 1): rolling execution via
  `concurrent.futures.ThreadPoolExecutor(max_workers=N)` — one future per instance running
  `arms.run_instance` + `harvest.harvest_instance`; as one finishes, the next starts.
  Chosen over wave scheduling: simpler with the executor and strictly better utilization.
  - Per-instance completion lines print under a lock (no interleaving).
  - The existing per-instance error-stub path is preserved inside each future.
  - `run_manifest` written once after all futures complete (unchanged).
  - Exit-code semantics unchanged (0 only if every requested arm completed).

### Parallel-safety fixes (required for `--max-parallel > 1`)
1. **Mirror pre-warm:** before the fan-out, `run` sequentially calls `ensure_mirror` for each
   unique repo among the selected instances, so workers always hit the cache. (batch1 has
   8 django instances; without this, 8 concurrent django mirror clones race.)
2. **Thread-unique clone temp dir:** `ensure_mirror`'s atomic-clone temp suffix currently uses
   the pid only; threads share a pid. Suffix becomes pid + uuid4 fragment.
3. Already-safe (verified): no `os.chdir` anywhere (all subprocess calls pass explicit `cwd`);
   workspaces/session transcript dirs/results dirs are disjoint per instance; arms within an
   instance stay sequential by design (session resume dependencies).

### Fairness note (recorded here and in START.md)
Sequential (`--max-parallel 1`, the default) remains the canonical mode for cross-machine
comparison: parallel sessions contend for CPU/RAM and subscription rate limits, which can
affect session behavior (e.g. retries, latency-induced differences). Parallelism is a
wall-clock convenience; runs intended for comparison should use the same setting, and
`--max-parallel` is recorded in `run_manifest.json`.

### START.md additions
- The batch table above (with `[H]` markers).
- A "Run a batch" section: `validate-gold --batch batchN` → `run --batch batchN
  [--max-parallel 3]` → `evaluate` → `report` → `git add results/ && git commit && git push`,
  with suggested run-id convention `batchN-<hostname>` and duration expectations.
- No shell scripts needed — the CLI flags cover everything.

## Subtask 2: targeted review (no code unless bugs found)

Scope: are the three arms' results for the same instance collected, keyed, and compared
correctly? Files: `evaluate.py` (predictions per arm `<run_id>__<arm>`, harness run-id dotting,
report harvesting/keying), `report.py` (collect_scores keying, flip logic, denominators,
empty-patch semantics), `harvest.py` (per-arm artifact/manifest paths), `arms.py` (per-arm
state keys). Outcome: either "no issues" recorded in the task log, or minimal bug fixes with
tests. Explicitly out of scope: refactoring, optimization, style.

## Out of scope (YAGNI)
- Parallelism across batches or for `evaluate` (the harness has its own `--max_workers`).
- Dynamic/custom batch definitions; resumable cross-machine batch splitting.
- Per-instance progress UI beyond completion lines.
