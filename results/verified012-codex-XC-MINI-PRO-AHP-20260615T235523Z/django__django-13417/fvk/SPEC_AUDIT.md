# Spec Audit

| Claim | Intent coverage | Result |
| --- | --- | --- |
| C1 | Matches I1 by comparing `ordered` to a compiler-derived semantic ordering model rather than to candidate output alone. | Pass |
| C2 | Matches I5 and the concrete issue example E2/E3. | Pass |
| C3 | Matches I3 and avoids over-fixing grouped queries by preserving explicit ordering. | Pass |
| C4 | Matches I4 and the existing property contract for default ordering when it is effective. | Pass |
| C5 | Matches I1 by ensuring no ordering source reports unordered. | Pass |
| C6 | Matches I6; no changed signature, return shape, or mutation obligation. | Pass |

No formal-English claim is candidate-derived without public evidence. The only
implementation-derived abstraction is the six-boolean `QueryState`, and it is
used to model branch conditions directly visible in the public source trail:
`EmptyQuerySet`, `extra_order_by`, `order_by`, `default_ordering`,
`Meta.ordering`, and `group_by`.
