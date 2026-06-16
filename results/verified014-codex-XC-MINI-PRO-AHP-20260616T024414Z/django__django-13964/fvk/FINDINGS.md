# Findings

Status: constructed, not machine-checked. Findings are based on public intent
and source inspection only.

## F1: V1 Fix Addresses The Reported Data-Loss Path

Input trace:

`order.product = Product(); order.product.sku = "foo"; order.product.save(); order.save()`

Observed before V1:

`order.product_id` remains `""` because `_prepare_related_fields_for_save()`
only refreshed from the cached related object when the local relation attname
was `None`.

Expected:

`order.product_id == "foo"` before the database write.

Evidence and obligations:

E1-E7, O1, C1.

Status:

Resolved by V1. `getattr(self, field.attname) in field.empty_values` covers
the CharField empty-string value identified by the public issue and hint.

## F2: Unsaved-Related-Object Guard Remains Intact

Input trace:

A cached related object is truthy but `obj.pk is None`.

Observed/expected after V1:

The existing `ValueError` is still raised before any empty-value refresh can
run.

Evidence and obligations:

E8, O2, C2.

Status:

No code change needed. V1 does not move or weaken the `obj.pk is None` branch.

## F3: Non-Empty Stale Values Still Clear The Cache

Input trace:

A cached related object has a non-`None` primary key, the local relation
attname is not empty, and the related object's target value differs from it.

Observed/expected after V1:

The local attname is not overwritten by this fix, and the owner-side cached
relation is cleared.

Evidence and obligations:

E9, O3, C3.

Status:

No code change needed. The comparison and `field.delete_cached_value(self)`
remain after the refresh opportunity.

## F4: Formalization Boundary Is Per-Field, Not Full Django Runtime

Input trace:

Any model save with multiple concrete fields.

Observed/expected:

The proof core models one relation-field iteration. The full source loop is
handled by the frame/independence obligation: each field iteration either skips,
raises, or mutates only the current field's relation value/cache.

Evidence and obligations:

D1-D3, O4.

Status:

Accepted abstraction. It distinguishes the failing state (`att == ""`, target
`"foo"`) from the passing state (`att == "foo"`), so it doesn't abstract away
the property under test.

## F5: No V2 Source Edit Justified

Audit result:

All proof obligations needed for the public issue are discharged by V1 and the
unchanged surrounding source structure.

Evidence and obligations:

F1-F4, O1-O6.

Status:

V1 stands unchanged. Further broadening, such as changing descriptor assignment
semantics, would exceed the evidence-backed repair and risk unrelated behavior.

## Tests

No tests were run or modified. A useful public test would cover the issue trace
with `CharField(primary_key=True)` and assert that `order.product_id` equals
the saved related object's primary key after `order.save()`. Existing tests
should be kept until the emitted K claims are actually machine-checked.
