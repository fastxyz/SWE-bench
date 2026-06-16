# Iteration Guidance

Decision: V1 stands unchanged.

Rationale:

- F1 identified the original bug and PO-4 shows V1 fixes it.
- F2 and PO-3 show V1 does not over-correct explicit grouped ordering.
- PO-5 and PO-6 show V1 preserves the neighboring default-ordering and
  no-ordering cases.
- F3 and PO-7 show no public compatibility change.
- F4 and PO-8 require keeping the proof honesty label and not deleting tests.

No source edit is recommended for V2.

Recommended future checks, without editing tests in this benchmark:

- Add or keep a regression test for `annotate(Count(...))` on a model with
  `Meta.ordering`, asserting `ordered is False`.
- Add or keep a neighboring regression test asserting explicit `order_by()` on
  such a grouped queryset reports `ordered is True`.
- Run the emitted K commands when a K environment is available; require `#Top`
  before treating any unit test as proof-subsumed.
