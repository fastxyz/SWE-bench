# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not find a remaining behavior bug in the
standard-duration sign-placement family described by the issue.

## Trace from findings and proof obligations

- Finding F1 and PO-1 show that the original defect was component-local sign
  handling. V1 addresses this by moving the standard-format sign into a single
  `sign` group and applying it to the whole `timedelta(**kw)`.
- Finding F2 explains why existing public tests for `-15:30` and `-1:15:30`
  were not preserved as authoritative: they encode the legacy behavior that
  conflicts with the issue's final intent evidence.
- Finding F3 and PO-2 through PO-5 confirm the important concrete cases:
  leading negative no-day values are whole-negative durations, while signs after
  colons are invalid.
- Finding F4 and PO-6/PO-7 justify leaving ISO 8601, PostgreSQL interval
  parsing, public call sites, and the `parse_duration(value)` signature
  unchanged.
- Finding F5 identifies an unreachable legacy microsecond-sign branch after V1.
  I kept it because it is harmless and removing it would be cleanup rather than
  a change required by any proof obligation.

## Artifacts

The FVK package is under `fvk/`. It includes the five requested artifacts plus
the adequacy and K files required by the FVK documentation:

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
- `fvk/mini-python-duration.k`
- `fvk/parse-duration-spec.k`

No tests, Python, or K tooling were run.
