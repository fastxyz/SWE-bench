# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found no open code bug after V1 and
discharged the relevant proof obligations over the year-normalization slice.
No tests, Python code, or K tooling were run.

## Decisions traced to FVK artifacts

### Keep the current-year-relative rollover

Decision: keep the V1 replacement of the fixed `70` cutoff with
`current_century + parsed_year`, followed by a one-century rollback when the
candidate is more than 50 years ahead.

Trace: Finding F-001 identifies the legacy fixed cutoff as the code bug.
PO-002 and PO-003 define the two symbolic branches, and PO-004 gives the
discriminator `CY=2018, YY=69 -> 1969` rather than `2069`.

### Keep UTC as the current-year source

Decision: keep `datetime.datetime.utcnow().year`.

Trace: Finding F-002 records local date as a boundary bug risk. PO-005 requires
the current-year source to be UTC/GMT-aligned because HTTP dates are GMT.

### Keep the strict boundary comparison

Decision: keep `if year > current_year + 50`, not `>=`.

Trace: Finding F-003 records the boundary rule. PO-002 covers the non-rollover
case when the candidate is exactly `CY + 50`; PO-003 covers only the strict
future case.

### Keep the broad `year < 100` branch

Decision: do not narrow the normalization to only the RFC850 regex.

Trace: Finding F-004 records that RFC850 provides the primary intent, while the
existing public asctime test for `0037` is compatibility evidence for preserving
the broader branch. PO-007 captures this as a compatibility obligation.

### Do not edit callsites or wrappers

Decision: leave `parse_http_date_safe()` and all callsites unchanged.

Trace: PO-006 frames parser behavior outside the changed arithmetic branch, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no signature, dispatch, return-shape,
or exception-shape incompatibility.

## Artifact decisions

The five requested artifacts are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method also requires adequacy and formal-core artifacts, so I added:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-http-date.k`
- `fvk/http-date-spec.k`

The `.k` artifacts model only the arithmetic normalization slice. This is
intentional: the defect axis is whether a current-year-relative candidate rolls
back, and the abstraction distinguishes the legacy failing value from the
required value. Regex parsing, date validation, and epoch conversion are frame
conditions under PO-006.

## Residual caveat

The proof is constructed, not machine-checked. The commands emitted in
`fvk/PROOF.md` must return `#Top` before the proof is described as
machine-verified or any test is considered redundant.
