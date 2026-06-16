"""Instance metadata loading and vendoring for the fvk benchmark.

This module provides three public functions:

- ``submodule_instance_ids``: read the 45 instance ids from the reproducibility
  submodule prompt files (no network required).
- ``load_instances``: load the vendored JSON file into a dict of frozen
  :class:`Instance` dataclasses, cross-checking the 45-instance set against
  the submodule ids and exact-count checking the full Verified set.
- ``vendor_instances``: download fresh metadata from HuggingFace and write the
  vendored JSON file (requires network and the ``datasets`` package).

Note: test NAMES are hidden benchmark data; only COUNTS are vendored, which is
why FAIL_TO_PASS/PASS_TO_PASS lists are reduced to lengths.
"""

import json
from dataclasses import dataclass
from pathlib import Path

from fvk_bench import config


@dataclass(frozen=True)
class Instance:
    """Immutable snapshot of one SWE-bench Verified instance."""

    instance_id: str
    repo: str
    base_commit: str
    version: str
    problem_statement: str
    hints_text: str
    fail_to_pass_count: int
    pass_to_pass_count: int


def submodule_instance_ids() -> list[str]:
    """Return sorted list of instance ids from the reproducibility submodule.

    Reads the stems of ``<REPRO_SUBMODULE>/prompts/*.md``.

    Raises:
        RuntimeError: if the prompts directory is missing (submodule not
            initialised) or if the count is not exactly 45.
    """
    prompts_dir = config.REPRO_SUBMODULE / "prompts"
    if not prompts_dir.is_dir():
        raise RuntimeError(
            f"Prompts directory not found: {prompts_dir}. "
            "Run `git submodule update --init` to initialise the submodule."
        )
    ids = sorted(p.stem for p in prompts_dir.glob("*.md"))
    if len(ids) != 45:
        raise RuntimeError(
            f"Expected exactly 45 prompt files in {prompts_dir}, found {len(ids)}."
        )
    return ids


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


def _visible_row(row: dict) -> dict:
    # Resolve FAIL_TO_PASS/PASS_TO_PASS: dataset stores these as JSON-encoded
    # strings or real lists depending on version/cache.
    ftp = row["FAIL_TO_PASS"]
    if isinstance(ftp, str):
        ftp = json.loads(ftp)

    ptp = row["PASS_TO_PASS"]
    if isinstance(ptp, str):
        ptp = json.loads(ptp)

    return {
        "instance_id": row["instance_id"],
        "repo": row["repo"],
        "base_commit": row["base_commit"],
        "version": row["version"],
        "problem_statement": row["problem_statement"],
        "hints_text": row["hints_text"] or "",
        "fail_to_pass_count": len(ftp),
        "pass_to_pass_count": len(ptp),
    }


def load_instances(
    path: Path | None = None, *, instance_set: str = config.DEFAULT_INSTANCE_SET
) -> dict[str, "Instance"]:
    """Load instances from a vendored JSON file.

    Args:
        path: Path to the JSON file (list of instance dicts). Defaults to the
            pinned file for ``instance_set``.
        instance_set: ``fvk45`` or ``verified500``.

    Returns:
        Mapping of ``instance_id`` → :class:`Instance`.

    Raises:
        RuntimeError: if the JSON cannot be parsed, if a required field is
            missing or has the wrong type, or if the set of ids in the file
            does not satisfy the selected instance-set invariants.
    """
    if instance_set not in config.INSTANCE_SETS:
        raise RuntimeError(
            f"unknown instance set {instance_set!r}; choose from {', '.join(config.INSTANCE_SETS)}"
        )
    if path is None:
        path = _instance_set_path(instance_set)
    path = Path(path)
    try:
        raw: list[dict] = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON from {path}: {exc}") from exc
    try:
        instances = {
            r["instance_id"]: Instance(
                instance_id=r["instance_id"],
                repo=r["repo"],
                base_commit=r["base_commit"],
                version=r["version"],
                problem_statement=r["problem_statement"],
                hints_text=r["hints_text"],
                fail_to_pass_count=int(r["fail_to_pass_count"]),
                pass_to_pass_count=int(r["pass_to_pass_count"]),
            )
            for r in raw
        }
    except KeyError as exc:
        raise RuntimeError(
            f"Missing required field {exc} in {path}"
        ) from exc
    except TypeError as exc:
        raise RuntimeError(
            f"Invalid field type in {path}: {exc}"
        ) from exc

    if config.REGISTRY[instance_set].id_source == "count":
        expected_count = _expected_count(instance_set)
        if len(instances) != expected_count:
            raise RuntimeError(
                f"Expected exactly {expected_count} instances in {path} "
                f"for {instance_set}, found {len(instances)}."
            )
        return instances

    submodule_ids = set(submodule_instance_ids())
    json_ids = set(instances.keys())

    missing = submodule_ids - json_ids
    extra = json_ids - submodule_ids

    if missing or extra:
        parts = []
        if missing:
            listed = ", ".join(sorted(missing)[:5])
            suffix = f" (and {len(missing) - 5} more)" if len(missing) > 5 else ""
            parts.append(f"missing from JSON: {listed}{suffix}")
        if extra:
            listed = ", ".join(sorted(extra)[:5])
            suffix = f" (and {len(extra) - 5} more)" if len(extra) > 5 else ""
            parts.append(f"extra in JSON not in submodule: {listed}{suffix}")
        raise RuntimeError(
            f"Instance id mismatch between JSON file and submodule. "
            + "; ".join(parts)
        )

    return instances


def vendor_instances(
    out_path: Path | None = None, *, instance_set: str = config.DEFAULT_INSTANCE_SET
) -> int:
    """Download instance metadata from HuggingFace and write vendored JSON.

    This function requires network access and the ``datasets`` package.

    Args:
        out_path: Destination path for the JSON file. Defaults to the pinned
            file for ``instance_set``.
        instance_set: ``fvk45`` vendors only the submodule-backed 45 ids;
            ``verified500`` vendors the entire SWE-bench Verified test split.

    Returns:
        Number of instances written.

    Raises:
        RuntimeError: if the selected dataset invariant is not satisfied.
    """
    if instance_set not in config.INSTANCE_SETS:
        raise RuntimeError(
            f"unknown instance set {instance_set!r}; choose from {', '.join(config.INSTANCE_SETS)}"
        )
    import datasets  # noqa: PLC0415 — intentional late import; avoids hard dep at module level

    if out_path is None:
        out_path = _instance_set_path(instance_set)
    out_path = Path(out_path)
    target_ids = set(submodule_instance_ids()) if instance_set == "fvk45" else None

    iset = config.REGISTRY[instance_set]
    if iset.dataset_local:
        pq = str((config.REPO_ROOT / iset.dataset_local / "test.parquet").resolve())
        ds = datasets.load_dataset("parquet", data_files=pq, split="train")
    else:
        ds = datasets.load_dataset(iset.dataset_identity, split="test")

    rows = []
    for row in ds:
        if target_ids is not None and row["instance_id"] not in target_ids:
            continue

        rows.append(_visible_row(row))

    written_ids = {r["instance_id"] for r in rows}
    if target_ids is not None:
        absent = target_ids - written_ids
        if absent:
            listed = ", ".join(sorted(absent))
            raise RuntimeError(
                f"The following submodule instance ids were not found in the dataset: {listed}"
            )

    expected_count = len(target_ids) if target_ids is not None else _expected_count(instance_set)
    if len(written_ids) != expected_count:
        raise RuntimeError(
            f"Expected exactly {expected_count} instances for {instance_set}, "
            f"dataset produced {len(written_ids)}."
        )

    rows.sort(key=lambda r: r["instance_id"])

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(rows, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    return len(rows)
