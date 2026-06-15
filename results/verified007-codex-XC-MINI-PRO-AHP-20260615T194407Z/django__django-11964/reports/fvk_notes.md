# FVK Notes

## Decision

V1 stands unchanged. No additional source edits were made under `repo/`.

## Trace to FVK findings and proof obligations

- `fvk/FINDINGS.md` F1 identifies the public `TextChoices` failure: a created model instance stored the enum member and `str(field_value)` produced the enum name instead of `"first"`. `fvk/PROOF_OBLIGATIONS.md` PO2 and PO5 discharge this with the V1 rule `Choices.__str__() -> str(self.value)`.

- `fvk/FINDINGS.md` F2 extends the issue to the named `IntegerChoices` family. `fvk/PROOF_OBLIGATIONS.md` PO2 covers both modeled value families (`SVal` and `IVal`), which is why the fix remains on base `Choices` rather than only `TextChoices`.

- `fvk/FINDINGS.md` F3 rejects assignment-time primitive coercion. `fvk/PROOF_OBLIGATIONS.md` PO3 and PO4 show the required observable is created/retrieved string equivalence, not identical `__dict__` storage. This is why no changes were made to model descriptors, `Model.__init__()`, or field preparation methods.

- `fvk/FINDINGS.md` F4 records the compatibility impact of adding `__str__` on base `Choices`. `fvk/PROOF_OBLIGATIONS.md` PO6 and PO7, plus `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, justify keeping the base-class placement because public metadata, lookup, and `repr()` behavior remain unchanged and no public evidence requires enum-name `str()` output.

- `fvk/PROOF_OBLIGATIONS.md` PO1 is discharged by the adequacy files: `fvk/INTENT_SPEC.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, and `fvk/SPEC_AUDIT.md`. Those artifacts confirm the spec does not preserve the reported legacy bug.

- `fvk/PROOF_OBLIGATIONS.md` PO8 records task compliance: no tests were edited and no tests, Python, or K tooling were run.

## Artifact decisions

The requested FVK files were written:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK methodology also requires formal and adequacy artifacts, so these were added:

- `fvk/mini-python-enum.k`
- `fvk/choices-str-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All proof artifacts are labeled constructed, not machine-checked. The emitted `kompile`, `kast`, and `kprove` commands are recorded for a future environment but were not executed.
