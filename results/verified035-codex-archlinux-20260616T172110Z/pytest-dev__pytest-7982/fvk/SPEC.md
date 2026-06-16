# FVK Spec: pytest Symlink Directory Collection

Status: constructed, not machine-checked.

Target under audit: V1 change in `repo/src/_pytest/pathlib.py`, function `_pytest.pathlib.visit`, plus direct collection callsites in `repo/src/_pytest/main.py` and `repo/src/_pytest/python.py`.

## Public Intent Ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E3: the issue says symlinked directories are skipped, should be followed and collected, and the `follow_symlinks=False` behavior should be removed.
- E5: existing recursion filters are still part of collection behavior.
- E6-E7: pytest should not resolve symlink paths during collection; node IDs can preserve symlink spelling.
- E8: broken symlinks are not traversal roots.

## Contract

For any finite acyclic directory graph and stable recursion predicate `recurse`, `visit(path, recurse)` must:

1. call `os.scandir(path)`;
2. sort entries by `entry.name`;
3. yield all entries at that directory level in sorted order;
4. for each sorted entry, recursively visit `entry.path` exactly when `entry.is_dir()` under default symlink-following semantics is true and `recurse(entry)` is true.

This contract is partial-correctness only: if traversal terminates, the emitted sequence must satisfy the contract. Termination through recursive symlink cycles is not proved.

## Precondition

- `path` identifies a directory accepted by the caller.
- The reachable directory graph under `entry.is_dir()` and `recurse(entry)` is finite and acyclic for the partial proof.
- `recurse(entry)` is stable for the same `os.DirEntry` during the traversal.

## Postcondition

Let `entries(path)` be `sorted(os.scandir(path), key=lambda entry: entry.name)`.

`visit(path, recurse)` emits:

`entries(path)` followed by `visit(entry.path, recurse)` for each `entry` in `entries(path)` where `entry.is_dir()` and `recurse(entry)` are both true.

For a symlink entry whose target is a directory, `entry.is_dir()` is true by default Python `DirEntry` semantics, so it is traversed when `recurse(entry)` is true.

## Frame Conditions

- The function signature and yielded object type do not change.
- Recursion filters remain authoritative.
- Symlink path spelling is preserved by recursing into `entry.path`; no `realpath` or `Path.resolve()` step is introduced.
- Non-directory entries and broken symlinks are not recursive roots.

## K Artifacts

- `mini-pytest-visit.k`: mini filesystem traversal semantics for the relevant `visit` fragment.
- `pytest-visit-spec.k`: K reachability claims with provenance comments.

