# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

`astropy.units.core.UnrecognizedUnit.__eq__(self, other)`

## Compatibility Checks

| Area | Audit | Result |
| --- | --- | --- |
| Signature | V1 did not change parameters or return protocol. | Compatible. |
| Caller expectations | Equality operators continue to call `__eq__` and `__ne__` normally. | Compatible. |
| `__ne__` | Still delegates to `not (self == other)`. | Compatible and now inherits non-throwing conversion-failure behavior. |
| Direct `Unit(None)` | Constructor branch still raises `TypeError`; only equality catches it. | Compatible with existing public test. |
| Unknown-unit equality | Same-name and different-name unknown comparisons are unchanged. | Compatible with existing public test. |
| Arithmetic/order operations | `_unrecognized_operator` assignments are unchanged. | Compatible. |

No public callsite or override requires an additional code change.
