# SPEC AUDIT

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| `FITS-NONEXT-EMPTY-ARGS` | Covers intent items 1 and 2 from `INTENT_SPEC.md` and evidence E-001/E-002/E-003. | Pass |
| `FITS-SUFFIX-PATH` | Covers preservation item 3 and evidence E-007. | Pass |
| `FITS-FILEOBJ-SIGNATURE` | Covers preservation item 3 and evidence E-005. | Pass |
| `FITS-FILEOBJ-NONSIGNATURE` | Covers predicate behavior for a non-FITS file signature and preserves branch precedence. | Pass |
| `FITS-HDU-ARG` | Covers preservation item 3 and evidence E-006. | Pass |
| `FITS-NONHDU-ARG` | Covers predicate non-match behavior from E-005. | Pass |

No formal claim contradicts the intent spec. No claim relies only on the V1
implementation for the reported empty-args behavior.
