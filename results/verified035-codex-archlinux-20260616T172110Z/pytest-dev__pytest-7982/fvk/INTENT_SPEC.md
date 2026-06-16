# Intent Spec

Scope: the V1 change to `_pytest.pathlib.visit` and its direct use by pytest collection.

Status: constructed from public issue text, public in-repository docs/tests, and the current source. This is an intent-first spec; current implementation behavior is checked later and is not used as the source of expected behavior.

## Required Behaviors

I1. Symlinked directories under a collected test directory are in domain and must be traversed.

Evidence: `benchmark/PROBLEM.md` says, "When there is a symlink to a directory in a test directory, is is just skipped over, but it should be followed and collected as usual."

Obligation: if `os.scandir(path)` returns an entry `e` whose target is a directory, and the normal collection recursion predicate accepts `e`, `visit(path, recurse)` must recursively visit `e.path`.

I2. The regression mechanism must be removed.

Evidence: `benchmark/PROBLEM.md` says the regressing change added `follow_symlinks=False` and "it does not match the previous behavior and should be removed."

Obligation: directory classification for traversal must use the default `DirEntry.is_dir()` behavior, which follows directory symlinks, rather than `DirEntry.is_dir(follow_symlinks=False)`.

I3. Existing recursion filters must still apply.

Evidence: `repo/src/_pytest/main.py` and `repo/src/_pytest/python.py` pass `_recurse` into `visit`; `_recurse` enforces `__pycache__`, `pytest_ignore_collect`, and `norecursedirs`.

Obligation: following a symlinked directory must not bypass `_recurse(entry)`.

I4. Symlink traversal must not imply path resolution.

Evidence: `repo/doc/en/changelog.rst` records that symlinks are no longer resolved during collection; public tests such as `test_collect_symlink_file_arg` assert symlink spelling in node IDs.

Obligation: recursive traversal through a symlinked directory must proceed using the symlink path `entry.path`, not a resolved real path.

I5. Non-directory entries, including broken symlinks, are not traversal roots.

Evidence: `repo/src/_pytest/python.py` comments that broken symlinks or invalid/missing files are skipped at package collection time; public `test_collect_sub_with_symlinks` covers broken symlink files not being collected as tests.

Obligation: `visit` may yield non-directory entries at their containing level, but it must not recurse into entries that are not directories under default `is_dir()` semantics.

## Default-Domain Assumptions

D1. Partial correctness is the target. The FVK proof assumes the reachable directory graph accepted by `recurse` is finite and acyclic. Termination over recursive symlink cycles is not proved.

D2. `os.scandir(path)` returns entries whose `.path` preserves the spelling of the scanned path joined to the entry name. This is a standard Python filesystem API behavior needed for the path-preservation obligation.

