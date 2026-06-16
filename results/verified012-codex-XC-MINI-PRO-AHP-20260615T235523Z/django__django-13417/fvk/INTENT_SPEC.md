# Intent Spec

Status: intent-first, constructed from public benchmark evidence and source
comments. Current implementation behavior is treated as candidate behavior, not
as the oracle.

## Required behaviors

I1. `QuerySet.ordered` is an introspection property that should report whether
the queryset will be semantically ordered.

I2. Empty querysets remain reported as ordered, preserving the existing public
property contract.

I3. Explicit ordering sources, `query.extra_order_by` and `query.order_by`, must
make `QuerySet.ordered` return `True`.

I4. Default model `Meta.ordering` must make `QuerySet.ordered` return `True`
only when that default ordering will affect the generated SQL ordering.

I5. Default model `Meta.ordering` must not make grouped aggregate queries report
ordered, because the compiler suppresses default meta ordering for `GROUP BY`
queries.

I6. The fix must not change the public API shape of `QuerySet.ordered`; it
remains a no-argument property returning a boolean.
