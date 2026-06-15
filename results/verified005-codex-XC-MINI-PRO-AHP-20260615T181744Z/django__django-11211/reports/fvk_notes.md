# FVK Notes

The FVK audit confirmed V1 and did not justify further production-code changes.

Decision D-001: Keep `UUIDField.get_prep_value()` as the fix. This traces to F-001 and F-003, and to PO-001, PO-002, and PO-003. The reported failure is a Python-side prefetch join-key mismatch: source object id is text, related UUID primary key is `uuid.UUID`. V1 normalizes the source side through `UUIDField.to_python()`, making the keys equal.

Decision D-002: Do not edit `GenericForeignKey.get_prefetch_queryset()`. This traces to F-003 and PO-007. The generic algorithm already delegates source-key normalization to the target primary key field; the defect was that UUIDField did not implement that preparation step.

Decision D-003: Do not add or alter direct `GenericForeignKey` filtering behavior. This traces to F-002 and PO-006. The checkout docs support GFK prefetch but still document that direct `filter()` / `exclude()` on a GFK is unsupported.

Decision D-004: Treat the public hint as stale or overbroad for this checkout. This traces to F-002. Allowed source docs and tests show GFK prefetch support, so the hint cannot veto the issue's prefetch obligation.

Decision D-005: Do not run tests or K tooling and do not recommend test removal. This traces to F-004 and PO-008. The FVK proof is constructed, not machine-checked, and the task forbids executing tests, Python, or K framework commands.

Decision D-006: Record a future test recommendation but do not edit tests. This traces to F-005. Visible tests do not cover the exact UUID-GFK-forward-prefetch case, but test files are fixed and hidden for this task.
