# Spec Audit

Status: constructed adequacy audit, not machine-checked.

| Formal claim | Intent coverage | Audit result |
| --- | --- | --- |
| DEFAULT | Matches intent item 1 and evidence E1/E4. | Pass |
| TEMP-DEFAULT | Covers the `TemporaryUploadedFile` side of intent items 2 and 3. | Pass |
| MEMORY-DEFAULT | Covers the `MemoryUploadedFile` side of intent items 2 and 3. | Pass |
| TEMP-NONE | Matches intent item 4 and evidence E5. It is not used to preserve the old default. | Pass |
| MEMORY-NONE | Matches intent item 4 and evidence E5. It is not used to preserve the old default. | Pass |
| Directory frame condition | Matches intent item 6 and evidence E7. | Pass |
| Documentation obligation | Matches intent item 5 and evidence E6. | Pass after V2 wording improvement in `docs/ref/settings.txt`. |

## Adequacy Result

The formal claims are neither weaker nor stronger than the public issue for the
audited source slice. They cover both named upload paths, distinguish the
explicit `None` restoration behavior from the new default, and do not assert a
directory-permission change the public hints reject.

No claim is based solely on candidate behavior. Implementation facts are used
only to model how Django applies a concrete setting through the existing final
`os.chmod()` step.
