# FVK Notes

## Summary

The FVK audit confirms V1 should stand unchanged. No additional source edits
were made after the baseline fix.

## Decisions Traced to Findings and Obligations

Kept `repo/django/conf/global_settings.py` as changed in V1.

Reason: F-001 identifies the pre-fix bug as the `None` default suppressing the
header. PO-1 proves the V1 default is `same-origin`; PO-2 proves that global
setting is the effective fallback for projects without an override; PO-3 and
PO-4 prove the middleware path emits `Referrer-Policy: same-origin`.

Kept `repo/django/middleware/security.py` unchanged.

Reason: PO-3 and PO-4 show the existing middleware already implements the
needed behavior once the setting has the new default. F-002 and F-003 also
depend on preserving the existing `setdefault()` and falsey-`None` behavior.

Kept explicit opt-out behavior unchanged.

Reason: F-003 ties this decision to the compatibility risk named in the public
issue. PO-5 proves `SECURE_REFERRER_POLICY = None` still disables the header and
custom policies still work.

Kept the security check implementation and W022 wording unchanged.

Reason: F-004 records the legacy wording concern, but PO-6 shows the new
default is a valid policy and does not trigger W022. The warning still applies
to the effective disabled state when a project explicitly sets the setting to
`None`, so this is not a blocker for the issue's intent.

Kept the V1 documentation changes.

Reason: PO-7 ties the release note directly to the public hint requiring BC
documentation. `docs/ref/settings.txt` documents the new default and opt-out,
which supports F-003.

## FVK Artifacts

The required artifacts are:

* `fvk/SPEC.md`
* `fvk/FINDINGS.md`
* `fvk/PROOF_OBLIGATIONS.md`
* `fvk/PROOF.md`
* `fvk/ITERATION_GUIDANCE.md`

Supporting constructed K artifacts are:

* `fvk/mini-django-referrer.k`
* `fvk/referrer-policy-spec.k`

Per the task constraints and FVK honesty gate, these proofs are constructed,
not machine-checked. No tests, Python code, or K tooling were run.
