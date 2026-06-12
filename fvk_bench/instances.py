"""Instance metadata loading and vendoring for the fvk benchmark.

This module provides three public functions:

- ``submodule_instance_ids``: read the 45 instance ids from the reproducibility
  submodule prompt files (no network required).
- ``load_instances``: load the vendored JSON file into a dict of frozen
  :class:`Instance` dataclasses, cross-checking against the submodule ids.
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


def load_instances(path: Path = config.INSTANCES_JSON) -> dict[str, "Instance"]:
    """Load instances from a vendored JSON file.

    Args:
        path: Path to the JSON file (list of instance dicts).

    Returns:
        Mapping of ``instance_id`` → :class:`Instance`.

    Raises:
        RuntimeError: if the JSON cannot be parsed, if a required field is
            missing or has the wrong type, or if the set of ids in the file
            does not exactly match the set returned by
            :func:`submodule_instance_ids`.
    """
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


def vendor_instances(out_path: Path = config.INSTANCES_JSON) -> int:
    """Download instance metadata from HuggingFace and write vendored JSON.

    This function requires network access and the ``datasets`` package.

    Args:
        out_path: Destination path for the JSON file.

    Returns:
        Number of instances written.

    Raises:
        RuntimeError: if any submodule instance id is absent from the dataset.
    """
    import datasets  # noqa: PLC0415 — intentional late import; avoids hard dep at module level

    out_path = Path(out_path)
    target_ids = set(submodule_instance_ids())

    ds = datasets.load_dataset(config.DATASET_NAME, split="test")

    rows = []
    for row in ds:
        if row["instance_id"] not in target_ids:
            continue

        # Resolve FAIL_TO_PASS — dataset stores these as JSON-encoded strings or real lists
        ftp = row["FAIL_TO_PASS"]
        if isinstance(ftp, str):
            ftp = json.loads(ftp)

        ptp = row["PASS_TO_PASS"]
        if isinstance(ptp, str):
            ptp = json.loads(ptp)

        rows.append({
            "instance_id": row["instance_id"],
            "repo": row["repo"],
            "base_commit": row["base_commit"],
            "version": row["version"],
            "problem_statement": row["problem_statement"],
            "hints_text": row["hints_text"] or "",
            "fail_to_pass_count": len(ftp),
            "pass_to_pass_count": len(ptp),
        })

    written_ids = {r["instance_id"] for r in rows}
    absent = target_ids - written_ids
    if absent:
        listed = ", ".join(sorted(absent))
        raise RuntimeError(
            f"The following submodule instance ids were not found in the dataset: {listed}"
        )

    rows.sort(key=lambda r: r["instance_id"])

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(rows, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    return len(rows)
