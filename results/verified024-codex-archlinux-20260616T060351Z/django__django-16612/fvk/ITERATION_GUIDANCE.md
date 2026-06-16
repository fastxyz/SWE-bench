# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

Keep V1 unchanged.

The FVK audit found the same root defect as the baseline notes: the legacy
redirect target used `request.path`, which cannot preserve `QUERY_STRING`.
The proof obligations require the fix to preserve the query string for every
non-empty query while keeping the existing redirect gates. V1 already does this
by calling `request.get_full_path(force_append_slash=True)`.

## Code Changes

No additional source edits are justified by the FVK findings.

- F-001 is resolved by the existing V1 edit.
- F-002 confirms the redirect gates remain unchanged.
- F-003 is an abstraction boundary, not a production-code defect.

## Suggested Follow-up Outside This Task

- Add or keep a regression test for an admin catch-all APPEND_SLASH redirect
  with a non-empty query string, such as `/admin/auth/foo?id=123`.
- Keep tests until the K artifacts are machine-checked and return `#Top`.
- If a future audit targets URI escaping or resolver semantics, replace the
  abstract `escapedPath`, `encodedQuery`, and `SLASH_RESOLVES` model with a
  richer Django/Python semantics fragment.

## Commands for Later Machine Checking

Do not run these in the current benchmark session. They are recorded for a
future environment with K installed.

```sh
kompile fvk/mini-django-admin.k --backend haskell
kast --backend haskell fvk/admin-catch-all-spec.k
kprove fvk/admin-catch-all-spec.k
```
