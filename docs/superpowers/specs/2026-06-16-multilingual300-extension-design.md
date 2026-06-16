# Design — Extend fvk_bench to SWE-bench Multilingual (multilingual300)

- **Date:** 2026-06-16
- **Status:** Approved for planning
- **Scope:** Infrastructure + data + docs only (no FVK methodology changes)

## 1. Goal

Add a third instance set, `multilingual300`, backed by **SWE-bench Multilingual**
(300 tasks, 42 repositories, 9 languages: C, C++, Go, Java, JavaScript, TypeScript,
PHP, Ruby, Rust), runnable through the existing `fvk_bench` 3-arm flow
(baseline / fvk / control) with either agent (Claude or Codex), scored by the
in-repo SWE-bench harness.

## 2. Requirements (from the user)

1. **Nothing breaks.** The existing `fvk45` and `verified500` sets keep working
   exactly as today, for both `--agent claude` and `--agent codex`.
2. **Docs.** `START.md` documents how to run `verified500` and `multilingual300`.
   `multilingual300` uses a 10-instance batch like verified500, giving **30 batches**.
   `START-PROMPT.md` is deleted once its content is folded into `START.md`.
3. **Self-contained.** The multilingual tests are added to the repo; a git submodule
   is the preferred mechanism. No HuggingFace dependency at run/eval time.

## 3. Decisions (locked during brainstorming)

- **D1 — Data storage:** the full SWE-bench Multilingual dataset lives in a
  fastxyz-owned git submodule; eval reads it **locally/offline**. (verified500 and
  fvk45 keep pulling `princeton-nlp/SWE-bench_Verified` from HuggingFace — unchanged.)
- **D2 — Scope:** **infra-only.** baseline/fvk/control RUN on multilingual300 using the
  **existing FVK materials unchanged**. Whether FVK helps on non-Python is what the
  benchmark will measure; adapting FVK materials is explicitly out of scope.
- **D3 — Architecture:** replace the scattered per-set `if/elif` branches with a single
  **instance-set registry** (Approach A). fvk45/verified500 become registry entries that
  reproduce today's exact values, so backward-compatibility is checkable.

## 4. Architecture

### 4.1 Instance-set registry (`fvk_bench/config.py`)

Introduce a frozen dataclass and a registry keyed by set name:

```text
InstanceSet:
  name           : str
  dataset        : str   # HF dataset name OR local path (harness-loadable)
  expected_count : int   # canonical instance count
  data_file      : Path  # vendored *visible* JSON (agent inputs)
  id_source      : str   # "submodule45" | "count"
  batch_scheme   : str   # "fvk45_fixed5" | "verified_sorted10" | "multilingual_sorted10"
```

| field | fvk45 | verified500 | multilingual300 |
|---|---|---|---|
| `dataset` | `princeton-nlp/SWE-bench_Verified` | `princeton-nlp/SWE-bench_Verified` | local submodule path |
| `expected_count` | 45 | 500 | 300 |
| `data_file` | `instances.json` | `instances_verified500.json` | `instances_multilingual300.json` |
| `id_source` | submodule45 | count | count |
| `batch_scheme` | fvk45_fixed5 | verified_sorted10 (50) | multilingual_sorted10 (30) |

The global `DATASET_NAME` constant is **removed**; all readers use the registry.
`INSTANCE_SETS` becomes `tuple(REGISTRY)`. `DEFAULT_INSTANCE_SET` stays `fvk45`.

### 4.2 Call sites that switch to the registry

- `instances.py`: `_instance_set_path`, `_expected_count`, the count/id validation in
  `load_instances`, and the dataset used by `vendor_instances` all read the registry.
- `cli.py`: `--instance-set` choices = `tuple(REGISTRY)` (adding a registry entry
  auto-exposes the choice); `--batch` accepts `multilingualNNN` when the set is
  multilingual300.
- `batches.py`: add the multilingual batch generator (4.3).
- `harvest.py`: the manifest already records `instance_set` and a `"dataset"` field;
  record the set's **logical dataset identity** for provenance (the HF name, or the
  canonical `SWE-bench/SWE-bench_Multilingual` name for multilingual) — **never a
  machine-specific filesystem path**, so committed manifests stay portable.
- `evaluate.py`: stop reading the removed global; resolve the dataset as in 4.4.

### 4.3 Batches (`fvk_bench/batches.py`)

Mirror the verified500 generator: `MULTILINGUAL_BATCH_COUNT = 30`,
`MULTILINGUAL_BATCH_SIZE = 10`, `multilingual_batch_names()` →
`multilingual001` … `multilingual030`, and extend `batch_instances()` to chunk the
sorted 300 instance ids into tens (identical logic to `verifiedNNN`). Sorted-id
chunking yields a clean 30×10; because ids sort by repo, batches stay mostly
single-language as a side benefit.

### 4.4 Offline eval & dataset resolution

The in-repo harness `load_swebench_dataset` (`swebench/harness/utils.py`) already
accepts a local `.json` / `.jsonl` / `parquet` file or a `load_from_disk` directory in
addition to HF names — so **no harness changes** are needed.

Dataset resolution per command:
- `validate-gold`: has `--instance-set`; uses `registry[instance_set].dataset`
  (local submodule path resolved relative to `REPO_ROOT`).
- `run` → `harvest`: records `instance_set` + the logical dataset identity in the
  manifest (provenance only; see 4.2).
- `evaluate`: takes only `--run-id`; resolves the dataset by reading the manifest's
  recorded **`instance_set`** and looking it up in the registry, resolving any local
  submodule path relative to `REPO_ROOT` **at eval time**. This keeps committed manifests
  portable (no absolute paths) and is backward-compatible: existing verified500 manifests
  record `instance_set=verified500` → Verified HF name. Fallback for older manifests
  lacking `instance_set`: use the recorded `dataset` field, else the default set.

### 4.5 Submodule + visible JSON

- New submodule `third_party/swe-bench-multilingual` (fastxyz-owned mirror of
  `SWE-bench/SWE-bench_Multilingual`), added to `.gitmodules` alongside the existing two.
  The registry's multilingual `dataset` points at the harness-loadable artifact inside it
  (resolved relative to `REPO_ROOT`).
- `fvk_bench/data/instances_multilingual300.json` — vendored **visible fields only**
  (`instance_id, repo, base_commit, version, problem_statement, hints_text`, and
  FAIL/PASS **counts**), same schema as the other sets, derived **from the submodule
  dataset** by `vendor-instances --instance-set multilingual300`.
- **Integrity:** the submodule contains full test specs (incl. hidden test names), but
  the runner only ever feeds agents the visible subset (PROBLEM.md + visible
  instance.json). Same guarantee as today — the eval dataset has always contained test
  names; we are only changing *where* it lives.

## 5. Documentation changes

- **`START.md`:** restructure §6 to document three sets side by side — fvk45 (45 / 5
  batches), verified500 (500 / 50 batches), multilingual300 (300 / 30 batches) — each
  with its 4-command flow and overnight loop. New multilingual300 subsection covers:
  `git submodule update --init` now also pulls the dataset submodule;
  `--instance-set multilingual300 --batch multilingualNNN`; both agents work unchanged;
  offline eval (no HF at runtime); and a note that the first eval may **build Docker
  images locally** if prebuilt images aren't pullable. Update §2–§3 setup notes for the
  new submodule.
- **`START-PROMPT.md`:** fold its essentials (the parameterized ready-made batch prompt +
  "what to expect") into a `START.md` subsection, then **delete** the file and remove its
  link. Net result: a single onboarding document.

## 6. Backward-compatibility & testing

- **Additive by construction:** fvk45/verified500 registry entries reproduce today's
  exact dataset/counts/batch logic; **zero** changes to the agent run paths, so Claude and
  Codex behave identically on existing sets.
- **Tests (`tests/fvk_bench/`):**
  - New: assert `registry["fvk45"]` and `registry["verified500"]` equal the historical
    values (dataset name, expected counts, batch names & sizes).
  - New: multilingual300 unit tests — `multilingual_batch_names()` returns 30 names;
    `batch_instances("multilingual015", ids)` returns the correct 10-id slice;
    `load_instances("multilingual300")` enforces count 300.
  - Existing suite must stay green; update any test that referenced the removed
    `config.DATASET_NAME`.
  - Non-destructive smoke: `list` for all three sets.

## 7. Validation / bring-up sequence (post-implementation)

1. Create the fastxyz mirror repo and add the submodule; `git submodule update --init`.
2. `vendor-instances --instance-set multilingual300` → assert 300 visible rows.
3. `doctor` (unchanged; host is x86_64).
4. `validate-gold` on **one instance per language (~9)** — proves the local-dataset path
   end-to-end and reveals pull-vs-build per toolchain.
5. One smoke batch: `run --instance-set multilingual300 --batch multilingual001
   --agent codex --arms baseline,fvk --max-parallel 3` → `evaluate` → `report`.
6. Then ready to scale to all 30 batches.

## 8. Files touched (for the implementation plan)

- `fvk_bench/config.py` — registry + `InstanceSet`; remove `DATASET_NAME`.
- `fvk_bench/instances.py` — registry-driven paths/counts/vendoring.
- `fvk_bench/batches.py` — multilingual batch generator.
- `fvk_bench/cli.py` — set choices from registry; accept `multilingualNNN`.
- `fvk_bench/harvest.py` — record resolved dataset in manifest.
- `fvk_bench/evaluate.py` — resolve dataset via manifest `instance_set` → registry (3 call sites).
- `fvk_bench/data/instances_multilingual300.json` — new vendored visible JSON.
- `.gitmodules` + `third_party/swe-bench-multilingual` — new submodule.
- `START.md` — restructure; `START-PROMPT.md` — delete.
- `tests/fvk_bench/` — backward-compat + multilingual tests.

## 9. Dependencies & risks

- **Setup dependency:** the submodule needs a fastxyz-owned repo to point at (mirror of
  `SWE-bench/SWE-bench_Multilingual`), created the same way the FVK kit was mirrored.
- **Docker images:** prebuilt multilingual images may not exist under the `swebench`
  namespace; `evaluate.py` already falls back to local builds (`--namespace none`), so
  eval still works but the first run may be slower / use more disk. Confirmed by step 4
  of the bring-up sequence.
- **Mid-stream comparability:** unrelated to existing verified500 runs (different set,
  different manifest); no impact on in-flight or past Python results.

## 10. Out of scope

- Any change to FVK materials / prompts for non-Python (D2).
- Changes to the SWE-bench harness itself (local-dataset + multilingual already supported).
- Pinning/mirroring Docker images into the repo (images are not git artifacts).
