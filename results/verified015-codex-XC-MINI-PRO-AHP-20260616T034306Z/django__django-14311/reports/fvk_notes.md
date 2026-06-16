# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional production-code edit that
is justified by public intent and the proof obligations.

## Trace to Findings and Obligations

The main issue behavior is Finding F1. It is discharged by PO1:
`moduleSpec(NAME)` returns `BASE + ["-m", NAME] + TAIL`. This traces directly to
the V1 branch in `repo/django/utils/autoreload.py` where non-`.__main__` specs
use `spec.name`.

The named corner case from the public hint is Finding F2. It is discharged by
PO1 and PO2 because V1 distinguishes package entry points with exact
`__main__` or suffix `.__main__`; a module named `foo.my__main__` stays on PO1
and is not stripped to its parent.

Existing package-entry behavior is Finding F3. It is discharged by PO2, so no
follow-up edit was made for `python -m django` or package `__main__` fixtures.

Fallback compatibility is Finding F4. It is discharged by PO3 through PO7. The
important V1 detail is the `if module_name:` guard and early return: when there
is no usable `-m` module name, control still reaches the previous script, `.exe`,
`-script.py`, and RuntimeError branches.

Finding F5 is not a code defect; it records that the proof is constructed but
not machine-checked because this task forbids running K, Python, or tests. For
that reason, I did not remove tests and only recorded future test suggestions in
`fvk/ITERATION_GUIDANCE.md`.

## Files Written

The required FVK artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.

To satisfy the FVK formal-core and adequacy requirements, I also wrote
`fvk/mini-python-argv.k`, `fvk/get-child-arguments-spec.k`,
`fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
