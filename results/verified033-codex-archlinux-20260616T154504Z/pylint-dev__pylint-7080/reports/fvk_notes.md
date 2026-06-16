## FVK decision notes

Status: constructed, not machine-checked. I did not run tests, Python code,
`kompile`, `kast`, or `kprove`.

## Source change made during FVK

Changed `repo/pylint/lint/expand_modules.py` to replace the V1 post-resolution
`continue` with an `is_ignored` boolean that only suppresses the direct module
description append.

Reason: FVK Finding F-002 showed that V1 over-skipped package trees when a
package resolved to an ignored `__init__.py`. Proof obligations PO-004 and
PO-005 require the ignored resolved file not to be emitted while package
submodules are still traversed and filtered independently.

## V1 decisions confirmed

Kept the V1 normalized-path fallback in
`_is_in_ignore_list_re_with_normalized_path`.

Reason: FVK Finding F-001 identifies mixed separators as the operative bug for
the reported `pylint --recursive=y src/` case. PO-001 proves raw regex behavior
is preserved, and PO-002 proves the normalized fallback catches candidates such
as `src/gen\about.py` against `^src/gen/.*$`.

Kept routing `ignore-paths` through `_is_ignored_file` and using `_is_ignored_file`
for submodule filtering.

Reason: PO-003 preserves basename ignore behavior, while PO-005 requires each
submodule to be filtered independently with the same ignore predicate.

Did not modify `PyLinter._discover_files`.

Reason: FVK Finding F-003 classifies discovery-level filtering as a possible
optimization, not required for the user-visible linting behavior. PO-006 shows
that recursive candidates pass through `_iterate_file_descrs` and the patched
`expand_modules` before `_check_file` can run.

## Verification limits

No tests were changed or removed.

Reason: FVK Finding F-004 and PO-007 require the proof to remain labeled
constructed, not machine-checked. The emitted commands in `fvk/SPEC.md`,
`fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` are for a later environment with
K installed.

## Artifacts produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-pylint-ignore.k`
- `fvk/pylint-ignore-paths-spec.k`
