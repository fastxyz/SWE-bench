# FVK Notes

## Source decision: keep the V1 sliced-query rewrite

I kept the V1 `_filter_prefetch_queryset()` structure because FVK FINDINGS F1
and proof obligations PO1 and PO2 show it addresses the reported failure:
relation predicates are no longer applied through public `.filter()` while the
queryset is still sliced, and the original slice is represented as per-parent
row-number predicates.

## Source decision: keep reverse FK, M2M, and generic relation coverage

I kept the V1 call-site coverage for reverse many-to-one, many-to-many, and
reverse generic relations. FINDINGS F5 and F6 plus PO3 and PO6 show these are
needed for both `to_attr` and non-`to_attr` prefetches, and that generic
relations must partition by both content type and object id.

## Source change: add primary-key fallback ordering

The FVK audit found one V1 problem: FINDINGS F2 and PO4 show that unordered
sliced querysets were still problematic on Oracle because `ROW_NUMBER()` needs
an `ORDER BY`. The issue's public example uses `Post.objects.all()[:3]`, so this
case is in scope even though unordered querysets do not promise a specific
ordering. I changed `_filter_prefetch_queryset()` so an empty resolved ordering
falls back to `queryset.model._meta.pk.name`.

## Source decision: keep explicit unsupported-backend error

I kept the `NotSupportedError` path for databases without window support.
FINDINGS F3 and PO5 justify this: silently fetching all related rows and slicing
in Python contradicts the issue's performance intent.

## Source decision: leave single-valued relations unchanged

I did not modify forward foreign key or reverse one-to-one prefetching. FINDINGS
F4 and PO8 classify this as a scope decision: the public issue is about bounded
collections per parent, and top-N-per-group semantics do not naturally apply to
single-valued relations.

## Artifact decisions

I wrote the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added `fvk/mini-django-prefetch.k` and `fvk/django-prefetch-spec.k` as
the abstract formal core referenced by the proof. Per the task constraints,
these are constructed artifacts only; no K tooling was run.

## Verification limits

No tests, Python code, or K tooling were executed. FINDINGS F7 records that the
proof is constructed, not machine-checked, so no test removal is recommended.
