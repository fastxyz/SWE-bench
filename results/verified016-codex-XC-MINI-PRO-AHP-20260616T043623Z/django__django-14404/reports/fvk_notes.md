# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original bug as F1 and confirmed that the V1 source change discharges the relevant proof obligations.

## Trace from findings to decisions

F1 identifies the real defect: the pre-V1 append-slash branch redirected to `request.path_info + "/"`, which drops `FORCE_SCRIPT_NAME`. PO-1 requires the successful branch to redirect to `request.path + "/"`, and V1 satisfies that at `repo/django/contrib/admin/sites.py:430`.

F2 explains why no additional resolver change is needed. PO-2 requires URL resolution to remain based on `request.path_info + "/"`; V1 leaves `repo/django/contrib/admin/sites.py:423-425` unchanged. I rejected the alternative of resolving `request.path + "/"` because that would include the script prefix in URLconf lookup.

F3 records the query-string question as a non-obligation for this issue. PO-5 requires the formal spec to follow the public issue's stated replacement, `request.path`, without strengthening it to `request.get_full_path()`. I therefore kept V1's path-only redirect instead of changing it to `request.get_full_path(force_append_slash=True)`.

F4 and PO-4 confirm compatibility. V1 does not change `catch_all_view()`'s signature, decorators, wrapper dispatch, response class family, or `Http404` fallthrough behavior, so no additional source edits are justified.

## Artifacts produced

The required FVK artifacts are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also produced the supporting FVK adequacy and formal-core files required by the FVK docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-admin-redirect.k`
- `fvk/admin-catch-all-spec.k`

## Verification limits

No tests, Python, `kompile`, `kast`, or `kprove` were run. The proof is constructed only, as required by the benchmark constraints.
