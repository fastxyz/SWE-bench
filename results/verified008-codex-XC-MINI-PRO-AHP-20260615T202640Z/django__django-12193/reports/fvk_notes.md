# FVK Notes

## Decision: keep V1 source unchanged

I kept the V1 source patch in `repo/django/forms/widgets.py` unchanged. `fvk/FINDINGS.md` F1 identifies the original code bug as generated `checked` leaking through the shared attrs dictionary, and `fvk/PROOF_OBLIGATIONS.md` PO2 shows that V1 discharges the root no-mutation obligation by copying non-`None` attrs before `attrs['checked'] = True`. PO3 and PO7 then show that split-array checkbox rendering is per-index independent, including the concrete `[False, True, False]` reproduction.

## Decision: do not edit SplitArrayWidget

I did not add a fresh-copy change to `repo/django/contrib/postgres/forms/array.py`. `fvk/FINDINGS.md` F3 records that alternative and rejects it for this issue because PO2 fixes the mutation at the source and PO3 proves the split-array obligation with the existing array widget loop. A SplitArrayWidget edit would be optional hardening for hypothetical mutating child widgets, not a required fix for the public issue.

## Decision: preserve explicit checked attrs behavior

I did not try to remove `checked` from false values when the caller explicitly supplied it. `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO4 show that explicit caller attrs are preserved intentionally; the bug is only generated cross-iteration mutation.

## Decision: no tests or K commands were run

I did not run tests, Python, `kompile`, `kast`, or `kprove`, following the task's no-execution rule. `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO8 record the honesty gate: the proof is constructed, not machine-checked, and no test removal is recommended.

## Artifacts produced

The five requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also produced the supporting adequacy and formal-core artifacts required by the FVK docs: `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-django-widgets.k`, and `fvk/checkbox-splitarray-spec.k`.
