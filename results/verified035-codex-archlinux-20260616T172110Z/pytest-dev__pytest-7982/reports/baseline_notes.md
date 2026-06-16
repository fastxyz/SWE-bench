# Baseline Notes

## Root cause

Directory traversal for collection goes through `_pytest.pathlib.visit`. That helper yields entries from `os.scandir`, then recursively descends into entries that are directories and pass the collection recursion predicate.

The regression was caused by using `DirEntry.is_dir(follow_symlinks=False)` for that descent check. A symlink to a real directory is yielded as an entry, but is not considered a directory with `follow_symlinks=False`, so pytest never recurses into it. The later collection code only sees the symlink entry itself and therefore skips the tests inside the linked directory.

## Files changed

`repo/src/_pytest/pathlib.py`

Restored the default `DirEntry.is_dir()` behavior in `visit`, which follows symlinks. This makes symlinked directories eligible for normal recursion again, while preserving the existing `recurse(entry)` filtering for `norecursedirs`, ignore hooks, and related collection rules.

`reports/baseline_notes.md`

Added this required implementation note describing the cause, the source change, and the assumptions considered.

## Assumptions and rejected alternatives

I assumed the intended behavior is the one described in the issue: symlinked directories inside a collected test directory should be followed and collected like ordinary directories.

I considered adding special symlink handling in the session or package collectors, but rejected that because both paths already share `_pytest.pathlib.visit`; fixing the traversal helper restores the behavior consistently with a smaller change.

I also considered adding loop detection for recursive symlink cycles, but rejected that as out of scope for this issue. The reported regression is specifically that pytest stopped following symlinked directories; restoring the previous follow behavior is the targeted fix.
