# FVK Findings

Status: constructed from public intent and source inspection; not machine-checked.

## F1: V1 removes the reported sliced-query filter failure for covered collection prefetches

- Evidence: SPEC I1, PO1.
- Input: `Category.objects.prefetch_related(Prefetch("post_set", queryset=Post.objects.all()[:3], to_attr="example_posts"))`.
- V0 observed behavior: prefetch relation filtering calls `.filter()` on a sliced queryset and raises `TypeError: Cannot filter a query once a slice has been taken.`
- V1/V2 expected behavior: relation filtering is applied after the slice has been rewritten into row-number predicates and the original limits have been cleared.
- Classification: fixed code bug.
- Status: discharged by `_filter_prefetch_queryset()` and reverse many-to-one prefetch call-site changes.

## F2: V1 did not handle unordered sliced querysets on every supported window backend

- Evidence: SPEC I5 and PO4. The issue example uses `Post.objects.all()[:3]`, and existing Django tests note that Oracle requires `ORDER BY` in `ROW_NUMBER()`.
- Input: sliced prefetch queryset with no explicit ordering and no model default ordering, on Oracle.
- V1 observed behavior by source reasoning: `_filter_prefetch_queryset()` built `Window(RowNumber(), partition_by=..., order_by=[])`. Oracle supports `OVER` clauses but rejects `ROW_NUMBER()` without an ordering clause.
- Expected behavior: the public `all()[:3]` example should not fail solely because no ordering is present. Since unordered querysets promise no specific order, a primary-key fallback is a valid deterministic order for the row-number implementation.
- Classification: code bug in V1, fixed in V2.
- V2 change: when resolved ordering is empty, `_filter_prefetch_queryset()` now uses `queryset.model._meta.pk.name` as the `ROW_NUMBER()` ordering.
- Proof obligation: PO4.

## F3: V1/V2 intentionally raise `NotSupportedError` on backends without window support

- Evidence: SPEC I3, I4, I8 and PO5.
- Input: sliced collection prefetch on a database where `supports_over_clause` is false.
- Observed behavior by source reasoning: `_filter_prefetch_queryset()` raises `NotSupportedError`.
- Expected behavior: do not silently fetch all related rows and slice in Python, because that contradicts the performance intent in the issue.
- Classification: accepted precondition / explicit backend capability guard.
- Status: discharged by PO5.

## F4: Single-valued prefetch relations remain outside the implemented contract

- Evidence: SPEC scope and PO8.
- Input: `Prefetch()` with a sliced queryset on a forward foreign key or reverse one-to-one relation.
- Observed behavior by source reasoning: those paths still call `.filter()` directly and can raise the sliced-query guard.
- Expected behavior under this spec: no obligation, because the public issue describes bounded collections per parent and the top-N-per-group interpretation is meaningful for multi-valued relations.
- Classification: scoped non-change, not a V2 bug against the current intent.
- Residual risk: if Django chooses to define sliced querysets for single-valued prefetches, a separate intent decision is required because "first N per parent" does not apply.

## F5: Manager cache construction without `to_attr` needed the same rewrite

- Evidence: SPEC C5 and PO6.
- Input: `Category.objects.prefetch_related(Prefetch("post_set", queryset=Post.objects.order_by("id")[:3]))` with no `to_attr`.
- V1 audit observation: `prefetch_one_level()` constructs a per-parent cached related-manager queryset through `manager._apply_rel_filters(lookup.queryset)`. Without updating manager filters, the original sliced `lookup.queryset` would still trip the guard.
- Expected behavior: the cache queryset construction must not call public `.filter()` while the custom queryset is still sliced.
- Classification: fixed code bug in V1 work, retained in V2.
- Status: discharged by reverse many-to-one, many-to-many, and generic relation `_apply_rel_filters()` changes.

## F6: Generic relation prefetches require a two-field partition

- Evidence: SPEC C4 and PO3.
- Input: reverse generic relation prefetch where two parent models can share the same object id under different content types.
- Potential incorrect behavior: partitioning only by `object_id` would mix rows from different concrete parent types.
- Expected behavior: partition by `(content_type, object_id)`.
- Classification: correctness condition discharged by V1/V2.
- Status: generic relation call sites pass `(self.content_type_field_name, self.object_id_field_name)`.

## F7: Formal proof is constructed, not machine-checked

- Evidence: FVK methodology and no-execution task constraint.
- Input: all proof claims in `fvk/django-prefetch-spec.k`.
- Observed status: commands are written in `fvk/PROOF.md`, but `kompile`, `kast`, and `kprove` were not run.
- Expected handling: do not delete tests or claim machine-checked certainty.
- Classification: proof/tooling limitation, not a code bug.
- Status: reflected in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
