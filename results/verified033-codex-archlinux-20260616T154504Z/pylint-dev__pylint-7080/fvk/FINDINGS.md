# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
intent, source inspection, and proof-obligation construction only.

## F-001: Mixed recursive path separators bypassed `ignore-paths`

Classification: code bug in the baseline and V1 target area.

Input: recursive linting with `pylint --recursive=y src/` and
`ignore-paths = ["^src/gen/.*$"]`.

Observed before the fix: a recursively discovered candidate can have a mixed
runtime path such as `src/gen\about.py`. The configured regex parser creates an
all-Windows alternative and an all-Posix alternative, but a mixed candidate
matches neither. The issue output shows generated files under `src\gen` being
linted.

Expected: any generated file under `src/gen/` must be ignored, regardless of
whether the runtime candidate uses `/`, `\`, or a mixture created during
recursive walking.

Resolution: keep raw regex matching and add normalized Posix-style path matching
before applying `ignore-paths`. This is captured by PO-001 and PO-002.

## F-002: V1 over-skipped package trees when only resolved `__init__.py` was ignored

Classification: code bug introduced by V1 and found during FVK audit.

Input: a package argument such as `pkg/` with files `pkg/__init__.py` and
`pkg/sub.py`, and an ignore pattern that matches only `pkg/__init__.py`.

Observed in V1: after resolving `pkg/` to `pkg/__init__.py`, V1 used `continue`
when that resolved file was ignored. That skipped the expansion loop entirely,
so `pkg/sub.py` was not considered even though it did not match the ignore rule.

Expected: the ignored resolved file should not be emitted, but package traversal
should continue and every submodule should be filtered independently.

Resolution: V2 records `is_ignored` for the resolved file and suppresses only
that module description. It still enters the package traversal branch. This is
captured by PO-004 and PO-005.

## F-003: Discovery-level filtering remains a possible optimization, not a required fix

Classification: non-blocking design note.

Input: recursive discovery may still yield an ignored file candidate before
module expansion filters it.

Observed: `_discover_files` is a private discovery helper and `_check_file`
receives only `FileItem`s produced after `_iterate_file_descrs` calls
`expand_modules`. The user-visible bug is lint output for ignored files, and the
proof obligation is discharged at the module-description boundary.

Expected: no ignored file reaches `_check_file`. Earlier pruning would reduce
intermediate candidates but is not necessary for the specified observable.

Resolution: no additional source edit. PO-006 records the boundary where the
observable behavior is proven.

## F-004: Proof is constructed, not machine-checked

Classification: proof capability gap.

Input: the constructed K-style claims in `fvk/pylint-ignore-paths-spec.k`.

Observed: the task forbids running `kompile`, `kast`, or `kprove`.

Expected: the proof commands should be emitted for later checking, and no test
removal or machine-checked confidence should be claimed now.

Resolution: commands are listed in `SPEC.md` and `PROOF.md`; tests are kept.
This is captured by PO-007.
