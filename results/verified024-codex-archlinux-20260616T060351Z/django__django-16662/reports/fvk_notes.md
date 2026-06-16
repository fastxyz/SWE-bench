# FVK Notes

## Decision

V1 stands unchanged. No additional production source edit is justified by the
FVK audit.

The original defect is captured as F-1: module-only sorting can emit
`import datetime`, then `from django.db ...`, then `import time`. PO-2 and PO-3
show that V1 changes the sort key to rank plain imports before from-imports, and
PO-6 discharges the concrete issue witness. That resolves the public bug.

## Files and decisions

`repo/django/db/migrations/writer.py`

Kept unchanged from V1. PO-2 confirms the current source key is
`(i.split()[0] == "from", i.split()[1])`. PO-3 proves this places all generated
plain imports before generated from-imports, and PO-4 proves the previous
module-token ordering is preserved within each import style. F-5 records the
confirmation finding.

`fvk/SPEC.md`

Added the intent-first specification and public evidence ledger for the import
ordering behavior. It scopes the proof to generated migration import lines and
records the non-obligations from F-2 and F-3.

`fvk/FINDINGS.md`

Added the audit findings. F-1 is the resolved original bug; F-2 rejects full
isort grouping as outside this public issue; F-3 records equal-key tie ordering
as under-specified; F-4 records the generated-import-line domain precondition;
F-5 confirms that V1 satisfies the intended contract.

`fvk/PROOF_OBLIGATIONS.md`

Added the proof obligations used to audit V1. PO-1 through PO-7 are the traceable
checks behind the no-change decision.

`fvk/PROOF.md`

Added the constructed proof sketch and the exact K commands that would be run in
a K-enabled environment. Per the task constraints, those commands were not
executed.

`fvk/ITERATION_GUIDANCE.md`

Added the next-step guidance. It states that no V2 source edit is needed, and it
separates future full-isort work from this issue.

`fvk/mini-migration-imports.k` and `fvk/migration-imports-spec.k`

Added the constructed K core required by the FVK method. The model abstracts the
finite import-line list and the key-based sort observable; it does not attempt to
model all Python execution or all migration rendering.

`fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

Added the adequacy and compatibility audit artifacts required by the FVK method.
These artifacts confirm that the formal claims match the public issue intent and
that V1 changes no public API or dispatch contract.

## Rejected alternatives

Adding blank lines between import groups was rejected because F-2 ties that
behavior to full isort compatibility, while the public hint asks for a small
tweak. This is recorded as non-obligation N-1.

Adding a full-line tie-breaker was rejected because F-3 shows no public evidence
for ordering distinct import lines that share the same style and module token.
This is recorded as non-obligation N-2.

Refactoring the V1 lambda into a helper was rejected because it would not change
any proof obligation. PO-2 through PO-6 already discharge the intended behavior
against the existing source.

## Verification status

No tests, Python code, or K tooling were run. The proof is constructed, not
machine-checked, and test removal is not recommended in this benchmark.
