# FVK Notes

## Decision

V1 stands unchanged.

## Trace to findings and proof obligations

The audit confirmed the context-copy edit through O1. `FINDINGS.md` F1 shows
that the reported `mod.submod` wrong-target case depends on missing
`py:module`, and V1's `PythonDomain.process_field_xref()` discharges that
obligation by using the existing domain hook.

The audit confirmed the `refspecific` edit through O2 and O5. `FINDINGS.md` F3
shows that unconditional `refspecific` caused non-module-scope suffix lookup,
while V1 limits that mode to leading-dot targets.

The audit rejected preserving the old missing-context doctree shape. F2 marks
the relevant in-repo public test expectations as SUSPECT because they conflict
with the issue's explicit comparison to `:py:class:` role behavior.

The audit considered whether to change `PythonDomain.find_obj()` instead. O3-O5
show the issue behavior is discharged by correcting node metadata and search
mode before the existing resolver runs, so a global resolver change would be
broader than necessary.

The audit also considered whether V1 overcorrected prefix behavior. O6 and F4
show leading-dot behavior is preserved, while tilde remains display-only, so no
additional source edit is justified.

## Execution constraints

No tests, Python code, or K tooling were run. The FVK proof is constructed, not
machine-checked, and the exact future commands are recorded in `fvk/PROOF.md`
and `fvk/SPEC.md`.
