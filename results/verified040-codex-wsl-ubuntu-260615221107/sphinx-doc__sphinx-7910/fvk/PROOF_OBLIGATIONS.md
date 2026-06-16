# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | K claim | Result |
| --- | --- | --- | --- | --- |
| PO1 | Eligibility gate: only documented non-`__weakref__` members of module/class/exception are candidates. | I5-I6 | C5, C8 | Discharged by `skipMember` rules. |
| PO2 | Decorated method: wrapper globals are not required when module+qualname resolves owner. | I1-I3 | C1 | Discharged. |
| PO3 | Nested class: dotted qualname paths remain resolved through module attributes. | I4 | C3 | Discharged. |
| PO4 | Decorated class: `unwrap(cls)` owner candidate can establish ownership. | I7 | C2 | Discharged by V2; V1 was incomplete. |
| PO5 | Top-level fallback: if module lookup fails, preserve old globals lookup for non-dotted class paths. | I4/I8 | C4 | Discharged by V2; V1 was compatibility-risky. |
| PO6 | Config gate: ownership and docstring are not enough when the relevant include setting is false. | I1/I5/I6 | C6 | Discharged. |
| PO7 | Module private/special behavior is independent of class ownership. | I6 | C7 | Discharged. |
| PO8 | No-owner behavior returns `None` rather than force-including. | I5 | C5 | Discharged. |
| PO9 | Public API compatibility: callback signature and return protocol remain unchanged. | I8 | Compatibility audit | Discharged by static callsite audit. |

Open proof boundary:

- PO10: Full Python import, descriptor, and object-wrapper semantics are not
  machine-modeled. This is an integration-test obligation, not a code finding
  against V2.
