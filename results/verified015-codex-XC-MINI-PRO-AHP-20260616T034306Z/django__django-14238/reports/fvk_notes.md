# FVK Notes

## Decision

V1 stands unchanged. No additional source files were edited during the FVK
phase.

## Trace To Findings And Proof Obligations

Finding F1 identified the original bug as exact membership rejecting a custom
`BigAutoField` subclass. Proof obligations O1, O5, and O10 show that V1 removes
that defect: `legacyExactTupleCheck(customBigAutoField)` is false, while
`autoFieldSubclassCheck(customBigAutoField)` is true and default primary-key
validation accepts it.

Finding F2 required the fix to cover the full compatibility root family, not
only the reproducer. Proof obligations O1, O2, O6, and O7 cover direct and
indirect subclasses of both `BigAutoField` and `SmallAutoField`. This supports
keeping the V1 use of Python's tuple-form `issubclass()` because it is
subclass-aware for all roots in `_subclasses`.

Finding F3 required non-auto field classes to remain rejected. Proof
obligations O4 and O8 show `textField` still reaches the ValueError branch.
This is why I did not widen `_get_default_pk_class()` beyond the
metaclass-defined compatibility contract.

Finding F4 required import-failure and empty-path handling to stay unchanged.
Proof obligation O9 covers those branches, and the V1 source diff does not
touch `Options._get_default_pk_class()`.

Finding F5 audited possible follow-up edits and found none justified. The issue
and proof obligations O1-O3 localize the required change to
`AutoFieldMeta.__subclasscheck__()`, while O11 and the compatibility audit show
the public method signature and existing `isinstance(..., AutoField)` behavior
are preserved.

Finding F6 records the only residual caveat: the proof is constructed, not
machine-checked, because this session forbids running K tooling. That caveat
does not justify withholding the source fix, but it does mean no tests should be
removed based on the proof.

## Artifacts Added

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-autofield.k`
- `fvk/autofield-meta-spec.k`

## Commands Recorded But Not Run

```sh
kompile fvk/mini-python-autofield.k --backend haskell
kast --backend haskell fvk/autofield-meta-spec.k
kprove fvk/autofield-meta-spec.k
```
