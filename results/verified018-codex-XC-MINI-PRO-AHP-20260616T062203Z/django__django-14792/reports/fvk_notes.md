# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were executed.

## Decisions

### D1: Keep V1's named-timezone preservation strategy

V1 changed PostgreSQL, MySQL, Oracle, and SQLite so `Etc/GMT-10` is treated as a timezone name rather than a numeric offset. The FVK audit confirms this strategy.

- Findings: `F1`
- Proof obligations: `PO1`, `PO2`, `PO4`, `PO5`
- Decision: keep the V1 backend structure.

### D2: Refine V1's offset classifier

FVK found that V1's `_split_tzname_delta()` classified any string starting with `+`, `-`, `UTC+`, or `UTC-` as an offset. The intent-derived contract is narrower: only numeric fixed-offset strings are offsets.

- Findings: `F2`
- Proof obligations: `PO1`, `PO6`
- Code change: `repo/django/db/backends/base/operations.py` now uses `_tzname_delta_re` to match only `^(UTC)?[+-]\d{2}(?::?\d{2})?$` before returning offset components.

### D3: Keep backend-specific fixed-offset behavior

The issue describes PostgreSQL's prior numeric `+10` to `-10` behavior as correct, and existing backend code intentionally treats fixed offsets specially. V2 preserves that behavior after numeric classification.

- Findings: `F3`
- Proof obligations: `PO3`, `PO4`, `PO5`
- Decision: no further changes to PostgreSQL, MySQL, Oracle, or SQLite fixed-offset preparation beyond routing through the stricter classifier.

### D4: Do not change public APIs or tests

The public compatibility audit found no need to change method signatures or public model-function APIs. The task also forbids test edits.

- Findings: `F5`
- Proof obligations: `PO7`
- Decision: no test files changed; suggested tests are documented in `fvk/ITERATION_GUIDANCE.md`.

### D5: Do not attempt to prove database timezone-table semantics

The reported defect is in Django's prepared timezone string before the database executes it. Whether a specific database installation has timezone tables is an existing backend feature concern.

- Findings: `F4`
- Proof obligations: `PO7`
- Decision: no code change; record as residual risk in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

## Artifact map

- `fvk/SPEC.md`: human-readable contract and public intent ledger.
- `fvk/FINDINGS.md`: issue findings, V1 audit finding, residual risks, and test guidance.
- `fvk/PROOF_OBLIGATIONS.md`: obligations used to justify V2.
- `fvk/PROOF.md`: constructed proof and commands to machine-check later.
- `fvk/ITERATION_GUIDANCE.md`: next-step guidance.
- `fvk/mini-tzname.k` and `fvk/tzname-spec.k`: formal core required by FVK, constructed but not run.
- Adequacy files: `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
