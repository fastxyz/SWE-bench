# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-code change justified beyond the existing patch in `repo/django/db/models/base.py`.

## Trace to Findings and Proof Obligations

- Kept V1's final-lookup branch because F-001 identifies the original bug and PO-1 states the required fix: a final unresolved segment registered as a lookup on the previously resolved field must not emit `models.E015`. The V1 code satisfies this with `index == len(parts) - 1 and get_lookup and get_lookup(part) is not None`.
- Kept V1's transform branch because F-003 and PO-2 require preserving pre-existing transform ordering support. The V1 code still accepts `get_transform(part) is not None`.
- Kept V1's final-position guard because F-002 and PO-3 reject the over-broad alternative of accepting lookup names at arbitrary unresolved segments. This is why the lookup check remains guarded by `index == len(parts) - 1`.
- Made no API or check-message edits because F-004 and PO-5 found no compatibility issue and require preserving `_check_ordering()`'s signature, return type, `models.E015` ID, and error-message shape.
- Made no test or execution-based changes because F-005 records that this workspace forbids running Django tests, Python, or K tooling. The K commands are recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` for a later execution-capable environment.

## Source Changes in This Phase

No source files under `repo/` were changed during the FVK phase. The only files added were FVK artifacts under `fvk/` and this report.
